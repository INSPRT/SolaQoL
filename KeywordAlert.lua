-- Play sound alerts when keywords show up in chat, ignoring self
local _, NS = ...
local L = NS.L

NS.KeywordAlert = {}

local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local PlaySound = PlaySound
local PlaySoundFile = PlaySoundFile
local pcall = pcall
local type = type
local string_lower = string.lower
local string_find  = string.find
local string_gmatch = string.gmatch
local string_gsub   = string.gsub
local InCombatLockdown = InCombatLockdown

local parsedKeywords = {}

local SOUND_PRESETS = {
    whisper      = 3081,    -- gentle ding
    ready_check  = 843,
    raid_warning = 8959,
    level_up     = 1422,
    alarm        = 11466,
}

-- Register alert sound with LSM
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if LSM then
    LSM:Register("sound", "KeywordSound", "Interface\\AddOns\\SolaQoL\\Media\\KeywordSound.mp3")
end

-- Check if a string is a combat-protected secret string
local function IsSecretString(val)
    if val == nil then return false end
    if type(val) ~= "string" then return true end
    -- Sandboxed check to catch taint errors safely
    local ok = pcall(string_lower, val)
    return not ok
end

-- Split keywords by comma and lowercase them
function NS.KeywordAlert.UpdateKeywords()
    wipe(parsedKeywords)
    local raw = SolaQoLDB and SolaQoLDB.keywordAlertList or ""
    local seen = {}
    for word in string_gmatch(raw, "([^,]+)") do
        word = string_gsub(word, "^%s*(.-)%s*$", "%1")
        if word ~= "" then
            local ok, lower = pcall(string_lower, word)
            if ok and lower and not seen[lower] then
                seen[lower] = true
                parsedKeywords[#parsedKeywords + 1] = lower
            end
        end
    end

    if SolaQoLDB and SolaQoLDB.keywordAutoAddPlayer then
        local myName = UnitName("player")
        if myName and myName ~= "" and myName ~= "Unknown" and myName ~= "UNKNOWN" then
            local ok, lowerName = pcall(string_lower, myName)
            if ok and lowerName and not seen[lowerName] then
                seen[lowerName] = true
                parsedKeywords[#parsedKeywords + 1] = lowerName
            end
        end
    end
end

function NS.KeywordAlert.PlayAlertSound()
    local soundValue = SolaQoLDB and SolaQoLDB.keywordAlertSound or "KeywordSound"
    
    if SOUND_PRESETS[soundValue] then
        PlaySound(SOUND_PRESETS[soundValue], "Master")
    else
        local path = soundValue
        local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
        if lsm then
            path = lsm:Fetch("sound", soundValue) or soundValue
        end
        if path == "KeywordSound" then
            path = "Interface\\AddOns\\SolaQoL\\Media\\KeywordSound.mp3"
        end
        if path and path ~= "" then
            PlaySoundFile(path, "Master")
        end
    end
end

-- Scan incoming chat messages for keywords
function NS.KeywordAlert.OnChatMessage(msg, sender, guid, channelName, channelString)
    if not SolaQoLDB or not SolaQoLDB.enableKeywordAlert then return end
    if not msg or #parsedKeywords == 0 then return end

    -- Discard restricted secret strings immediately to prevent taint
    if IsSecretString(msg) then return end

    -- Ignore own messages except in pgkeyword channel
    local isTestChannel = false
    if not IsSecretString(channelName) and channelName then
        if string_lower(channelName) == "pgkeyword" then
            isTestChannel = true
        end
    end
    if not isTestChannel and not IsSecretString(channelString) and channelString then
        if string_find(string_lower(channelString), "pgkeyword", 1, true) then
            isTestChannel = true
        end
    end

    local isMyGuid = false
    -- C++ UnitIsUnit is faster than string matching
    if sender and not IsSecretString(sender) then
        local ok, match = pcall(UnitIsUnit, sender, "player")
        if ok and match then
            isMyGuid = true
        end
    end

    if not isMyGuid and guid and not IsSecretString(guid) then
        local ok, match = pcall(function() return guid == UnitGUID("player") end)
        if ok and match then
            isMyGuid = true
        end
    end

    if not isTestChannel and isMyGuid then return end

    local lowerMsg = string_lower(msg)
    for i = 1, #parsedKeywords do
        if string_find(lowerMsg, parsedKeywords[i], 1, true) then
            NS.KeywordAlert.PlayAlertSound()
            return
        end
    end
end



-- O(1) table dispatch is faster than regex
local CHAT_EVENTS = {
    CHAT_MSG_SAY                   = true,
    CHAT_MSG_YELL                  = true,
    CHAT_MSG_WHISPER               = true,
    CHAT_MSG_BN_WHISPER            = true,
    CHAT_MSG_PARTY                 = true,
    CHAT_MSG_PARTY_LEADER          = true,
    CHAT_MSG_RAID                  = true,
    CHAT_MSG_RAID_LEADER           = true,
    CHAT_MSG_INSTANCE_CHAT         = true,
    CHAT_MSG_INSTANCE_CHAT_LEADER  = true,
    CHAT_MSG_GUILD                 = true,
    CHAT_MSG_OFFICER               = true,
    CHAT_MSG_CHANNEL               = true,
    CHAT_MSG_EMOTE                 = true,
}

local f = CreateFrame("Frame")
for ev in pairs(CHAT_EVENTS) do
    f:RegisterEvent(ev)
end
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        NS.KeywordAlert.UpdateKeywords()
        return
    end
    if CHAT_EVENTS[event] then
        local msg, sender, _, channelString, _, _, _, _, channelName, _, _, guid = ...
        NS.KeywordAlert.OnChatMessage(msg, sender, guid, channelName, channelString)
    end
end)
