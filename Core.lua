-- Namespace setup, defaults, database hooks, and common helper functions
local ADDON_NAME, NS = ...
local L = SolaQoL_L
NS.L = L

local issecretvalue = issecretvalue                    -- may be nil
local pcall, type, pairs, ipairs = pcall, type, pairs, ipairs
local string_find, string_gsub, string_gmatch = string.find, string.gsub, string.gmatch
local string_format, table_insert = string.format, table.insert
local GetTime, IsInGroup, IsInRaid = GetTime, IsInGroup, IsInRaid
local UnitGUID, UnitExists = UnitGUID, UnitExists

NS.DB_DEFAULTS = {
    enableHello            = true,
    enableGG               = true,
    msgHello               = L.MSG_HELLO_DEFAULT,
    msgGG                  = L.MSG_GG_DEFAULT,
    enableRaidSound        = true,
    showIlevelToSelf       = true,
    onlyGreetOnceAsMember  = true,
    enableTooltipIlvl      = true,
    enableAutoPortal       = true,
    showSpecOnEnter        = true,
    customSoundNewMember   = "FreeNotification7",
    customSoundFullParty   = "FreeNotification5",
    customSoundNewApplicant = "FreeNotification2",
    muteNewMember          = false,
    muteFullParty          = false,
    muteNewApplicant       = false,
    enableTradeReport      = true,
    tradeWhisper           = false,
    tradeParty             = false,
    portalOverlayPoint     = "TOP",
    portalOverlayX         = 0,
    portalOverlayY         = -160,
    portalOverlayFontSize  = 40,
    enableLust             = true,
    lustBarWidth           = 800,
    lustBarHeight          = 28,
    configScale            = 1.0,
    minimapButton          = true,
    minimapAngle           = 45,
    enableKeywordAlert     = true,
    keywordAlertList        = "",
    keywordAlertSound       = "KeywordSound",
    keywordAutoAddPlayer    = true,
    enableAutoRelease      = false,
    disableAutoReleaseHUD  = false,
    lastReadChangelog      = "",
    disabledHearthstones   = {},
    enableRandomHearthstone= true,
    enableHearthstoneOnClear= true,
}

-- Init DB with defaults and run schema migrations
function NS.InitDB()
    if not SolaQoLDB then SolaQoLDB = {} end
    for k, v in pairs(NS.DB_DEFAULTS) do
        if SolaQoLDB[k] == nil then
            SolaQoLDB[k] = v
        end
    end
    -- Migration: reset corrupted overlay font sizes from legacy versions
    local fs = SolaQoLDB.portalOverlayFontSize
    if fs and (fs <= 24 or fs == 200 or fs == 60) then
        SolaQoLDB.portalOverlayFontSize = 40
    end

    -- Apply saved position and font size to Portal overlay UI elements after SavedVariables load
    if NS.PortalBtn and not InCombatLockdown() then
        NS.PortalBtn:ClearAllPoints()
        NS.PortalBtn:SetPoint(SolaQoLDB.portalOverlayPoint or "TOP", UIParent, SolaQoLDB.portalOverlayPoint or "TOP", SolaQoLDB.portalOverlayX or 0, SolaQoLDB.portalOverlayY or -160)
    end
    if NS.PortalTestUI then
        NS.PortalTestUI:ClearAllPoints()
        NS.PortalTestUI:SetPoint(SolaQoLDB.portalOverlayPoint or "TOP", UIParent, SolaQoLDB.portalOverlayPoint or "TOP", SolaQoLDB.portalOverlayX or 0, SolaQoLDB.portalOverlayY or -160)
    end
    local curFS = SolaQoLDB.portalOverlayFontSize or 40
    if NS.PortalBtn and NS.PortalBtn.Label then
        local pf, _, pflags = NS.PortalBtn.Label:GetFont()
        if pf then NS.PortalBtn.Label:SetFont(pf, curFS, pflags) end
    end
    if NS.PortalTestUI and NS.PortalTestUI.Label then
        local tf, _, tflags = NS.PortalTestUI.Label:GetFont()
        if tf then NS.PortalTestUI.Label:SetFont(tf, curFS, tflags) end
    end

    if NS.UpdateMinimapButton then NS.UpdateMinimapButton() end
end

NS.CHAR_DB_DEFAULTS = {
    enableTradeLog = true,
    tradeLog       = {},
}

function NS.InitCharDB()
    if not SolaQoLCharDB then SolaQoLCharDB = {} end

    for k, v in pairs(NS.CHAR_DB_DEFAULTS) do
        if SolaQoLCharDB[k] == nil then
            if type(v) == "table" then
                SolaQoLCharDB[k] = {}
            else
                SolaQoLCharDB[k] = v
            end
        end
    end
end

-- Trade log helpers using djb2 hashing to detect manual file tampering
local LOG_SALT = "PG_SALT_2026_TRADE"
local LOG_MAX  = 100

local function HashString(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + string.byte(s, i)) % 2147483647
    end
    return tostring(h)
end

function NS.SignLog(text, ts)
    return HashString(text .. "|" .. ts .. "|" .. LOG_SALT)
end

function NS.VerifyLog(entry)
    if not entry or not entry.msg or not entry.ts or not entry.sig then
        return false
    end
    return entry.sig == NS.SignLog(entry.msg, entry.ts)
end

-- Log trade action and rotate logs to keep memory low
function NS.AddTradeLog(msg)
    if not SolaQoLCharDB then return end
    if not SolaQoLCharDB.enableTradeLog then return end
    if not SolaQoLCharDB.tradeLog then SolaQoLCharDB.tradeLog = {} end

    local ts = date("%y/%m/%d %H:%M")

    local entry = {
        ts  = ts,
        msg = msg,
        sig = NS.SignLog(msg, ts),
    }

    local log = SolaQoLCharDB.tradeLog
    table_insert(log, entry)
    -- Trim oldest entries when over limit
    while #log > LOG_MAX do
        table.remove(log, 1)
    end
end


-- Pre-instantiate DB table early to prevent UI positioning errors on load
SolaQoLDB = SolaQoLDB or {}

NS.State = {
    prevType      = "solo",
    prevMems      = {},
    prevCount     = 0,
    lastClear     = 0,
    lastChange    = 0,
    prevAppCount  = 0,
    isInit        = false,
    lastInstanceID = nil,
    shouldGreet   = false,
}

NS.ActiveTitleCache = ""
NS.AppliedTitles    = {}
NS.LFGMemory        = {}

function NS.Now()
    return GetTime() or 0
end

function NS.SafePlaySoundFile(path, channel, showFeedback)
    if not path or path == "" then return false end
    local actualPath = path
    
    local lowerPath = string.lower(path)
    if not string.find(lowerPath, "^interface\\") then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            actualPath = LSM:Fetch("sound", path) or path
        end
    end
    
    local ok, willPlay, handle = pcall(PlaySoundFile, actualPath, channel or "Master")
    if not ok or not willPlay then
        if showFeedback then
            print("|cffff0000[SolaQoL]|r Sound file not found: |cffcccccc" .. tostring(path) .. "|r")
        end
        return false
    end
    return true, handle
end

-- Check for text presence while supporting Blizzard's issecretvalue
function NS.HasText(s)
    if not s then return false end
    if issecretvalue and issecretvalue(s) then return true end
    return s ~= ""
end

-- Strip raw localization placeholders (like UNKNOWN) injected by Blizzard
function NS.CleanGarbage(s)
    if not NS.HasText(s) then return "" end
    if issecretvalue and issecretvalue(s) then return s end
    if string_find(s, L.GARBAGE_UNKNOWN1, 1, true) then return "" end
    if string_find(s, L.GARBAGE_UNKNOWN2, 1, true) then return "" end
    return s
end

function NS.GetGrpType()
    if IsInRaid() then return "raid" end
    if IsInGroup() then return "party" end
    return "solo"
end

function NS.GetCurrentMembers()
    local mems, count = {}, 0
    if not IsInGroup() then return mems, count end
    local isRaid = IsInRaid()
    local maxCount = isRaid and GetNumGroupMembers() or GetNumSubgroupMembers()
    local prefix   = isRaid and "raid" or "party"
    local myGuid = UnitGUID("player")
    if myGuid then mems[myGuid] = true; count = count + 1 end
    for i = 1, maxCount do
        local unit = prefix .. i
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then mems[guid] = true; count = count + 1 end
        end
    end
    return mems, count
end

function NS.FlashClientIcon()
    if FlashClientIcon then FlashClientIcon() end
end

local DelayChat_LastMsg = {}

function NS.DelayChat(msg, chatType, delayMin, delayMax, showFeedback)
    if not msg or msg == "" or not chatType then return end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return end

    local items = {}
    for s in string_gmatch(msg, "([^,]+)") do
        s = string_gsub(s, "^%s*(.-)%s*$", "%1")
        if s ~= "" then table_insert(items, s) end
    end
    if #items == 0 then return end

    local selectedMsg
    if #items == 1 then
        selectedMsg = items[1]
    else
        local pool = {}
        local last = DelayChat_LastMsg[msg]
        for _, item in ipairs(items) do
            if item ~= last then table_insert(pool, item) end
        end
        if #pool == 0 then pool = items end
        selectedMsg = pool[fastrandom(1, #pool)]
        DelayChat_LastMsg[msg] = selectedMsg
    end

    local minSec = (delayMin or 30) / 10
    local maxSec = (delayMax or 70) / 10
    local randomDelay = minSec + fastrandom() * (maxSec - minSec)

    C_Timer.After(randomDelay, function()
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return end
        if chatType == "PARTY" and NS.GetGrpType() ~= "party" then return end
        SendChatMessage(selectedMsg, chatType)
        if showFeedback then
            print("|cff00ccff[SolaQoL]|r " .. string_format(L.AUTO_GREET_FEEDBACK_FMT, string_format("%.1f", randomDelay)))
        end
    end)
end

-- Patch InspectPVPFrame to prevent nil errors when inspect target disappears
function NS.PatchInspectPVPFrame()
    if InspectPVPFrame_Update then
        local orig = InspectPVPFrame_Update
        InspectPVPFrame_Update = function(...)
            if not INSPECTED_UNIT then return end
            return orig(...)
        end
    end
end
NS.PatchInspectPVPFrame()

function NS.BuildLFGTitle(name, activityIDs, activityID)
    name = NS.CleanGarbage(name)
    if not NS.HasText(name) then return "", false, nil, name end

    local actStr = ""
    local hasCat = false
    local aID    = nil

    if type(activityIDs) == "table" then
        local success, val = pcall(function() return activityIDs[1] end)
        if success then aID = val end
    end
    if not aID then aID = activityID end

    if aID and aID > 0 then
        local actInfo = C_LFGList.GetActivityInfoTable(aID)
        if actInfo then
            local cat = NS.CleanGarbage(actInfo.fullName)
            if not NS.HasText(cat) then cat = NS.CleanGarbage(actInfo.shortName) end
            if NS.HasText(cat) then
                actStr = cat .. " : "
                hasCat = true
            end
        end
    end
    return actStr .. name, hasCat, aID, name
end

function NS.UpdateActiveTitle(newTitle, force)
    if not NS.HasText(newTitle) then return end
    if force or not NS.HasText(NS.ActiveTitleCache) then
        NS.ActiveTitleCache = newTitle
    end
end

function NS.GetGroupTitle()
    if NS.HasText(NS.ActiveTitleCache) then return NS.ActiveTitleCache end
    if C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo() then
        local entry = C_LFGList.GetActiveEntryInfo()
        if entry then
            local fullTitle = NS.BuildLFGTitle(entry.name, entry.activityIDs, entry.activityID)
            if NS.HasText(fullTitle) then
                NS.ActiveTitleCache = fullTitle
                return fullTitle
            end
        end
    end
    return ""
end

function NS.PrintToggleMsg(optionName, isEnabled)
    local stateStr   = isEnabled and L.TOGGLE_ON_MSG or L.TOGGLE_OFF_MSG
    local colorStr   = isEnabled and "|cff88ff88" or "|cffff8888"
    local coloredSt  = colorStr .. stateStr .. "|r"
    print("|cff00ccff[SolaQoL]|r " .. string_format(L.TOGGLE_MSG_FMT, optionName, coloredSt))
end

-- Add a quick alias for ReloadUI
SLASH_RELOADUI_KOR1 = "/기"
SlashCmdList["RELOADUI_KOR"] = ReloadUI
