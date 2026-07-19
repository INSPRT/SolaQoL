-- Portal overlay with secure action button to teleport to dungeon when party fills
local ADDON_NAME, NS = ...
local L = NS.L

local InCombatLockdown = InCombatLockdown
local IsPlayerSpell    = IsPlayerSpell
local IsSpellKnown     = IsSpellKnown
local IsInInstance     = IsInInstance
local string_find      = string.find
local string_format    = string.format
local pairs, ipairs    = pairs, ipairs
local math_floor, math_ceil, math_min, math_max = math.floor, math.ceil, math.min, math.max


local DungeonPortals    = L.DungeonPortals or {}
local DungeonShortNames = L.DungeonShortNames or {}

-- Sort longest name first to avoid false substring matches
local sortedPortals = {}
for name, spellID in pairs(DungeonPortals) do

    local pattern = name:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
    sortedPortals[#sortedPortals + 1] = { name = name, spellID = spellID, pattern = pattern }
end
table.sort(sortedPortals, function(a, b) return #a.name > #b.name end)

local function FindPortalMatch(title)
    for i = 1, #sortedPortals do
        local entry = sortedPortals[i]
        if string_find(title, entry.pattern) then
            return entry.spellID, entry.name
        end
    end
    return nil, nil
end

local pendingPortalData = nil   -- Queue portal load for post-combat
local pendingHide       = false -- Queue hide request for post-combat


if not SolaQoL_ErrorFrame then
    local ef = CreateFrame("MessageFrame", "SolaQoL_ErrorFrame", UIParent)
    ef:SetSize(800, 60)
    ef:SetPoint("TOP", UIParent, "TOP", 0, -270)
    local efFontFile, efFontSize, efFontFlags = UIErrorsFrame:GetFont()
    ef:SetFont(efFontFile, (efFontSize or 16) + 6, "OUTLINE")
    ef:SetInsertMode("TOP")
    ef:SetFading(true)
    ef:SetTimeVisible(3.0)
    ef:SetFadeDuration(0.5)
end


local PortalBtn = CreateFrame("Button", "SolaQoL_PortalBtn", UIParent, "SecureActionButtonTemplate, BackdropTemplate")
PortalBtn:SetSize(200, 40)
if SolaQoLDB.portalOverlayPoint and SolaQoLDB.portalOverlayX and SolaQoLDB.portalOverlayY then
    PortalBtn:SetPoint(SolaQoLDB.portalOverlayPoint, UIParent, SolaQoLDB.portalOverlayPoint, SolaQoLDB.portalOverlayX, SolaQoLDB.portalOverlayY)
else
    PortalBtn:SetPoint("TOP", 0, -160)
end
PortalBtn:Hide()

PortalBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
PortalBtn:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
PortalBtn:SetBackdropBorderColor(0, 0, 0, 1)

PortalBtn.Label = PortalBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
do
    local pf, _, pflags = PortalBtn.Label:GetFont()
    PortalBtn.Label:SetFont(pf, SolaQoLDB.portalOverlayFontSize or 40, pflags)
end

PortalBtn.IconBorder = PortalBtn:CreateTexture(nil, "OVERLAY", nil, 1)
PortalBtn.IconBorder:SetColorTexture(0, 0, 0, 1)

PortalBtn.Icon = PortalBtn:CreateTexture(nil, "OVERLAY", nil, 2)
PortalBtn.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

PortalBtn.TopBar = PortalBtn:CreateTexture(nil, "OVERLAY")
PortalBtn.TopBar:SetColorTexture(212/255, 167/255, 69/255, 1)
PortalBtn.TopBar:SetHeight(2)
PortalBtn.TopBar:SetPoint("TOPLEFT", 1, -1)
PortalBtn.TopBar:SetPoint("TOPRIGHT", -1, -1)

PortalBtn:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
PortalBtn:SetFrameStrata("HIGH")
PortalBtn:EnableMouse(true)

PortalBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
end)
PortalBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
end)

-- Close button (takes combat lockdown into account)
PortalBtn.CloseBtn = CreateFrame("Button", nil, PortalBtn, "BackdropTemplate")
PortalBtn.CloseBtn:SetSize(16, 16)
PortalBtn.CloseBtn:SetPoint("TOPRIGHT", PortalBtn, "TOPRIGHT", -1, -4)
PortalBtn.CloseBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
PortalBtn.CloseBtn:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
PortalBtn.CloseBtn:SetBackdropBorderColor(0, 0, 0, 1)
PortalBtn.CloseBtn.Text = PortalBtn.CloseBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
PortalBtn.CloseBtn.Text:SetPoint("CENTER", 0, 0)
PortalBtn.CloseBtn.Text:SetText("X")
PortalBtn.CloseBtn.Text:SetTextColor(0.8, 0.8, 0.8)

PortalBtn.CloseBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.8, 0.2, 0.2, 0.9)
    self.Text:SetTextColor(1, 1, 1)
end)
PortalBtn.CloseBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    self.Text:SetTextColor(0.8, 0.8, 0.8)
end)
PortalBtn.CloseBtn:SetScript("OnClick", function()
    PortalBtn.isTestMode = false
    PortalBtn.isFullTestMode = false
    pendingPortalData = nil
    if InCombatLockdown() then
        PortalBtn:SetAlpha(0)   -- Hide visually immediately since Hide() is blocked in combat
        pendingHide = true
        return
    end
    PortalBtn:Hide()
end)


PortalBtn.AnnounceBtn = CreateFrame("Button", nil, PortalBtn, "BackdropTemplate")
PortalBtn.AnnounceBtn:SetSize(90, 86)
PortalBtn.AnnounceBtn:SetPoint("TOP", PortalBtn, "BOTTOM", 0, -4)
PortalBtn.AnnounceBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
PortalBtn.AnnounceBtn:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
PortalBtn.AnnounceBtn:SetBackdropBorderColor(0, 0, 0, 1)

PortalBtn.AnnounceBtn.Icon = PortalBtn.AnnounceBtn:CreateTexture(nil, "OVERLAY")
PortalBtn.AnnounceBtn.Icon:SetPoint("TOP", -4, -6)
PortalBtn.AnnounceBtn.Icon:SetSize(55, 55)
PortalBtn.AnnounceBtn.Icon:SetTexture("Interface\\AddOns\\SolaQoL\\AnnounceIcon.tga")

PortalBtn.AnnounceBtn.Text = PortalBtn.AnnounceBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
PortalBtn.AnnounceBtn.Text:SetPoint("BOTTOM", 0, 8)
PortalBtn.AnnounceBtn.Text:SetText(L.ANNOUNCE_DESTINATION or "Announce")
PortalBtn.AnnounceBtn.Text:SetTextColor(0.533, 0.533, 0.533)
do
    local af, afs, aflags = PortalBtn.AnnounceBtn.Text:GetFont()
    if af and afs then PortalBtn.AnnounceBtn.Text:SetFont(af, afs + 3, aflags) end
end

PortalBtn.AnnounceBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.2, 0.8, 0.2, 0.9)
end)
PortalBtn.AnnounceBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
end)
PortalBtn.AnnounceBtn:SetScript("OnClick", function()
    if PortalBtn.lastTitle and (PortalBtn.isTestMode or (IsInGroup() and UnitIsGroupLeader("player"))) then
        local fmt     = L.ANNOUNCE_MSG_FMT or "%1$s 입니다 출발해 주세요!"
        local short   = PortalBtn.shortName or PortalBtn.lastTitle
        local full    = PortalBtn.lastTitle
        local dungeon = PortalBtn.dungeonName or short
        local msg     = string_format(fmt, short, full, dungeon)
        -- Strip Blizzard kstring escape codes that cause SendChatMessage to reject the message
        msg = msg:gsub("|K[^|]*|k", "")
        msg = msg:gsub("%s*:%s*$", "")
        msg = msg:gsub("%s+$", "")
        if PortalBtn.isTestMode and not (IsInGroup() and UnitIsGroupLeader("player")) then
            print("|cff00ccff[SolaQoL Test]|r 파티 채팅 시뮬레이션: " .. msg)
        elseif msg ~= "" then
            SendChatMessage(msg, "PARTY")
        end
    end
end)



local _preClickLastTime = 0
PortalBtn:HookScript("PreClick", function(self)
    local now = GetTime()
    if (now - _preClickLastTime) < 0.2 then return end
    _preClickLastTime = now

    local spellID   = self.spellID
    local spellName = self:GetAttribute("spell1")
    if spellID and spellName then
        local start, duration
        if C_Spell and C_Spell.GetSpellCooldown then
            local cd = C_Spell.GetSpellCooldown(spellID)
            if cd then start = cd.startTime; duration = cd.duration end
        elseif GetSpellCooldown then
            start, duration = GetSpellCooldown(spellID)
        end
        if start and duration and duration > 1.5 then
            local remaining = start + duration - GetTime()
            if remaining > 0 then
                local mins = math_floor(remaining / 60)
                local secs = math_ceil(remaining % 60)
                local timeStr = mins > 0 and (mins .. "분 " .. secs .. "초") or (secs .. "초")
                SolaQoL_ErrorFrame:AddMessage(spellName .. " 재사용 대기시간 중! (" .. timeStr .. " 남음)", 1.0, 0.1, 0.1, 1.0)
                print("|cffff0000[SolaQoL]|r " .. spellName .. " 재사용 대기시간 중! (" .. timeStr .. " 남음)")
            end
        end
    end
end)


local PortalTestUI = CreateFrame("Frame", "SolaQoL_PortalTestUI", UIParent, "BackdropTemplate")
PortalTestUI:SetSize(200, 40)
if SolaQoLDB.portalOverlayPoint and SolaQoLDB.portalOverlayX and SolaQoLDB.portalOverlayY then
    PortalTestUI:SetPoint(SolaQoLDB.portalOverlayPoint, UIParent, SolaQoLDB.portalOverlayPoint, SolaQoLDB.portalOverlayX, SolaQoLDB.portalOverlayY)
else
    PortalTestUI:SetPoint("TOP", 0, -160)
end
PortalTestUI:Hide()
PortalTestUI:SetFrameStrata("DIALOG")
PortalTestUI:SetMovable(true)
PortalTestUI:EnableMouseWheel(true)
PortalTestUI:EnableMouse(true)
PortalTestUI:SetClampedToScreen(true)

PortalTestUI:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
PortalTestUI:SetBackdropColor(0.0, 0.4, 0.0, 0.85)
PortalTestUI:SetBackdropBorderColor(0, 1, 0, 1)

PortalTestUI.Label = PortalTestUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
do
    local tf, _, tflags = PortalTestUI.Label:GetFont()
    PortalTestUI.Label:SetFont(tf, SolaQoLDB.portalOverlayFontSize or 40, tflags)
end
PortalTestUI.Label:SetText(L.TEST_MODE_LABEL or "Test Mode")

PortalTestUI.IconBorder = PortalTestUI:CreateTexture(nil, "OVERLAY", nil, 1)
PortalTestUI.IconBorder:SetColorTexture(0, 0, 0, 1)

PortalTestUI.Icon = PortalTestUI:CreateTexture(nil, "OVERLAY", nil, 2)
PortalTestUI.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
PortalTestUI.Icon:SetTexture(134400)

PortalTestUI.TopBar = PortalTestUI:CreateTexture(nil, "OVERLAY")
PortalTestUI.TopBar:SetColorTexture(212/255, 167/255, 69/255, 1)
PortalTestUI.TopBar:SetHeight(2)
PortalTestUI.TopBar:SetPoint("TOPLEFT", 1, -1)
PortalTestUI.TopBar:SetPoint("TOPRIGHT", -1, -1)

local function UpdateTestUILayout(self)
    local fontSize = SolaQoLDB.portalOverlayFontSize or 40
    local iconSize = fontSize * 1.15
    local gap = 12
    local labelWidth = self.Label:GetStringWidth()
    local totalWidth = labelWidth + gap + iconSize

    self.Label:ClearAllPoints()
    self.Label:SetPoint("CENTER", -(iconSize + gap) / 2, -2)

    self.IconBorder:ClearAllPoints()
    self.IconBorder:SetSize(iconSize, iconSize)
    self.IconBorder:SetPoint("LEFT", self.Label, "RIGHT", gap, 3)

    self.Icon:ClearAllPoints()
    self.Icon:SetSize(iconSize - 2, iconSize - 2)
    self.Icon:SetPoint("CENTER", self.IconBorder, "CENTER")

    self:SetSize(totalWidth + 60, self.Label:GetStringHeight() + 30)
end

PortalTestUI:SetScript("OnShow", UpdateTestUILayout)

PortalTestUI:RegisterForDrag("LeftButton")
PortalTestUI:SetScript("OnDragStart", function(self) self:StartMoving() end)
PortalTestUI:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, xOfs, yOfs = self:GetPoint(1)
    SolaQoLDB.portalOverlayPoint = point
    SolaQoLDB.portalOverlayX = xOfs
    SolaQoLDB.portalOverlayY = yOfs
    if not InCombatLockdown() then
        PortalBtn:ClearAllPoints()
        PortalBtn:SetPoint(point, UIParent, point, xOfs, yOfs)
    end
end)

PortalTestUI:SetScript("OnMouseWheel", function(self, delta)
    local curFontPath, curSize, curFlags = PortalTestUI.Label:GetFont()
    if not curFontPath or curFontPath == "" then curFontPath = GameFontNormalHuge:GetFont() end
    if not curSize then curSize = 40 end
    if delta > 0 then curSize = math_min(80, curSize + 2)
    else curSize = math_max(16, curSize - 2) end

    SolaQoLDB.portalOverlayFontSize = curSize
    PortalTestUI.Label:SetFont(curFontPath, curSize, curFlags)
    UpdateTestUILayout(self)

    local pf, _, pflags = PortalBtn.Label:GetFont()
    if pf then PortalBtn.Label:SetFont(pf, curSize, pflags) end
end)

-- Bind portal spell & update visuals (must run out of combat)
local function ApplyPortalUI(spellID, dungeonName, title)
    local isNewPortal = not PortalBtn:IsShown() or PortalBtn.spellID ~= spellID
    local spellName, spellIcon, isKnown
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then spellName = info.name; spellIcon = info.iconID end
    end
    if not spellName and GetSpellInfo then
        spellName, _, spellIcon = GetSpellInfo(spellID)
    end
    isKnown = (IsPlayerSpell and IsPlayerSpell(spellID)) or (IsSpellKnown and IsSpellKnown(spellID))

    PortalBtn.lastTitle   = title
    PortalBtn.spellID     = spellID
    PortalBtn.shortName   = DungeonShortNames[dungeonName] or dungeonName
    PortalBtn.dungeonName = dungeonName


    if isKnown then
        PortalBtn:SetAttribute("type1", "spell")
        PortalBtn:SetAttribute("spell1", spellName)
    else
        PortalBtn:SetAttribute("type1", nil)
        PortalBtn:SetAttribute("spell1", nil)
    end


    local fontSize = SolaQoLDB.portalOverlayFontSize or 40
    local iconSize = fontSize * 1.15
    local gap      = 12
    local shortName   = DungeonShortNames[dungeonName] or dungeonName
    local displayText = string_format(L.OVERLAY_PORTAL_FMT or "%s", shortName)
    local labelColor  = isKnown and {1, 1, 1} or {0.6, 0.6, 0.6}

    PortalBtn.Label:SetText(displayText)
    PortalBtn.Label:SetTextColor(labelColor[1], labelColor[2], labelColor[3])

    local labelW = PortalBtn.Label:GetStringWidth()
    local totalW = labelW + gap + iconSize
    PortalBtn:SetSize(totalW + 60, PortalBtn.Label:GetStringHeight() + 30)

    PortalBtn.Label:ClearAllPoints()
    PortalBtn.Label:SetPoint("CENTER", -(iconSize + gap) / 2, -2)

    PortalBtn.IconBorder:ClearAllPoints()
    PortalBtn.IconBorder:SetSize(iconSize, iconSize)
    PortalBtn.IconBorder:SetPoint("LEFT", PortalBtn.Label, "RIGHT", gap, 3)

    PortalBtn.Icon:ClearAllPoints()
    PortalBtn.Icon:SetSize(iconSize - 2, iconSize - 2)
    PortalBtn.Icon:SetPoint("CENTER", PortalBtn.IconBorder, "CENTER")
    PortalBtn.Icon:SetTexture(spellIcon or 134400)

    PortalBtn.AnnounceBtn:SetSize(iconSize * 2, iconSize * 2 - 4)
    PortalBtn.AnnounceBtn.Icon:SetSize(iconSize * 1.15, iconSize * 1.15)

    -- Show announce only if we're leader and party is full (or testing)
    local isFull = false
    if PortalBtn.isTestMode then
        isFull = true
    else
        if not IsInRaid() and IsInGroup() and GetNumGroupMembers() >= 5 then
            isFull = true
        end
    end

    if (UnitIsGroupLeader("player") and isFull) or PortalBtn.isFullTestMode then
        PortalBtn.AnnounceBtn:Show()
    else
        PortalBtn.AnnounceBtn:Hide()
    end

    if isKnown then
        PortalBtn.TopBar:SetColorTexture(212/255, 167/255, 69/255, 1)
        PortalBtn:SetBackdropBorderColor(0, 0, 0, 1)
    else
        PortalBtn.TopBar:SetColorTexture(0.5, 0.5, 0.5, 1)
        PortalBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end

    PortalBtn:SetAlpha(1)   -- Restore alpha in case it was hidden during combat.
    PortalBtn:Show()


    if isNewPortal then
        print("|cff00ccff[SolaQoL]|r " .. string_format(L.PORTAL_ACTIVATED_FMT, dungeonName))
    end
end


function NS.ShowPortalIfAvailable(title)
    if not SolaQoLDB.enableAutoPortal then return end
    if not title then return end

    -- Skip if already inside unless testing.
    if IsInInstance() and not PortalBtn.isTestMode then return end

    PortalBtn.lastTitle = title

    local spellID, dungeonName = FindPortalMatch(title)
    if not spellID then return end

    -- Queue if we're in combat
    if InCombatLockdown() then
        pendingPortalData = { title = title, spellID = spellID, dungeonName = dungeonName }
        pendingHide = false   -- show supersedes a pending hide
        return
    end

    pendingHide = false
    ApplyPortalUI(spellID, dungeonName, title)
end

function NS.HidePortal()
    pendingPortalData = nil
    if not (PortalBtn and PortalBtn:IsShown()) then
        pendingHide = false
        return
    end
    if InCombatLockdown() then
        PortalBtn:SetAlpha(0)   -- Fade out immediately to avoid combat errors
        pendingHide = true
        return
    end
    pendingHide = false
    PortalBtn.isTestMode = false
    PortalBtn.isFullTestMode = false
    PortalBtn:Hide()
end


local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(_, event)
    if event ~= "PLAYER_REGEN_ENABLED" then return end
    if InCombatLockdown() then return end

    -- Show action overrides pending hide
    if pendingPortalData then
        local data = pendingPortalData
        pendingPortalData = nil
        pendingHide = false
        ApplyPortalUI(data.spellID, data.dungeonName, data.title)
        return
    end


    if pendingHide then
        pendingHide = false
        PortalBtn:SetAlpha(1)   -- Restore alpha before actually hiding the frame
        if PortalBtn:IsShown() then
            PortalBtn.isTestMode = false
            PortalBtn.isFullTestMode = false
            PortalBtn:Hide()
        end
    end
end)


NS.PortalBtn    = PortalBtn
NS.PortalTestUI = PortalTestUI
