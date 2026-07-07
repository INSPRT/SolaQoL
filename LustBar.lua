-- Bloodlust/Heroism/Time Warp duration bar (runs OnUpdate only when active)
local ADDON_NAME, NS = ...

local TARGET_DEBUFFS = {
    80354,  -- Time Warp
    390435, -- Exhaustion
    57724,  -- Sated
    264689, -- Exhaustion
    95809,  -- Insanity
    57723,  -- Exhaustion
    160455, -- Fatigued
}

local TrackerSettings = {
    Colors = {
        {1.0, 0.5, 0.8}, -- Soft Pink
        {1.0, 0.8, 0.5}, -- Soft Peach
        {0.6, 1.0, 0.7}, -- Soft Mint
        {0.5, 0.8, 1.0}, -- Soft Sky Blue
        {0.8, 0.6, 1.0}  -- Soft Lilac
    },
    Duration = 40,
    SparkOffsets = { 16, 8, 0, -8, -16 }
}

local LustModule = {
    IsActive = false,
    ExpirationMark = 0,
    Visuals = {},
    SystemReady = false,
    CurrentAuraState = false,
    Simulating = false
}

local Dispatcher = CreateFrame("Frame")
Dispatcher:RegisterEvent("PLAYER_LOGIN")
Dispatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
Dispatcher:RegisterEvent("UNIT_AURA")


local _cachedSec = -1

local function OnUpdateHandler()
    if not LustModule.IsActive then

        Dispatcher:SetScript("OnUpdate", nil)
        return
    end

    local timeLeft = LustModule.ExpirationMark - GetTime()
    if timeLeft <= 0 then
        LustModule.IsActive = false
        LustModule.Visuals.Container:Hide()
        Dispatcher:SetScript("OnUpdate", nil)
        return
    end

    local ratio = timeLeft / TrackerSettings.Duration
    LustModule.Visuals.StatusBar:SetValue(ratio)

    local fullWidth = LustModule.Visuals.Container:GetWidth() - 2
    local pctComplete = 1.0 - ratio
    local offset = fullWidth * pctComplete

    LustModule.Visuals.MaskCanvas:SetPoint("TOPLEFT", LustModule.Visuals.Container, "TOPLEFT", 1 + offset, -1)
    LustModule.Visuals.MaskCanvas:SetPoint("BOTTOMLEFT", LustModule.Visuals.Container, "BOTTOMLEFT", 1 + offset, 1)
    LustModule.Visuals.MaskCanvas:SetHorizontalScroll(offset)

    local activeWidth = fullWidth * ratio
    for i, spark in ipairs(LustModule.Visuals.Glows) do
        spark:SetPoint("CENTER", LustModule.Visuals.StatusBar, "RIGHT", -activeWidth, TrackerSettings.SparkOffsets[i])
    end

    local displayValue = math.ceil(timeLeft)
    if displayValue ~= _cachedSec then
        _cachedSec = displayValue
        LustModule.Visuals.TimerLabel:SetText(displayValue)
    end
end


local function StartOnUpdate()
    _cachedSec = -1
    Dispatcher:SetScript("OnUpdate", OnUpdateHandler)
end

local function StopOnUpdate()
    Dispatcher:SetScript("OnUpdate", nil)
end

local L = SolaQoL_L
local ready_msg = L.MSG_BLOODLUST_READY or "Bloodlust Ready"
local start_msg = L.MSG_BLOODLUST_START or "Bloodlust Start"
local ready_sound = L.SOUND_BLOODLUST_READY or "LustRdy.mp3"
local start_sound = L.SOUND_BLOODLUST_START or "LustOn.mp3"

local function IsLustClass()
    local _, classFile = UnitClass("player")
    return classFile == "SHAMAN" or classFile == "MAGE" or classFile == "HUNTER" or classFile == "EVOKER"
end

local function CreateAlertFrame(frameName, modeStr)
    local f = CreateFrame("Frame", frameName, UIParent)
    f:SetSize(400, 100)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(false)
    f:EnableMouseWheel(true)
    f.animMode = modeStr
    
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetFont(STANDARD_TEXT_FONT, 30, "THICKOUTLINE")
    f.text = text
    
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    bg:Hide()
    f.bg = bg
    
    f:SetScript("OnMouseDown", function(selfFrame, button)
        if button == "LeftButton" and selfFrame.isTesting then
            selfFrame:StartMoving()
            selfFrame.isMoving = true
        end
    end)
    
    f:SetScript("OnMouseUp", function(selfFrame)
        if selfFrame.isMoving then
            selfFrame:StopMovingOrSizing()
            selfFrame.isMoving = false
            
            local centerX = selfFrame:GetLeft() + selfFrame:GetWidth() / 2 - UIParent:GetWidth() / 2
            local centerY = selfFrame:GetBottom() + selfFrame:GetHeight() / 2 - UIParent:GetHeight() / 2
            
            if not SolaQoLDB then SolaQoLDB = {} end
            if selfFrame.animMode == "start" then
                SolaQoLDB.lustStartTextX = math.floor(centerX + 0.5)
                SolaQoLDB.lustStartTextY = math.floor(centerY + 0.5)
                selfFrame:ClearAllPoints()
                selfFrame:SetPoint("CENTER", UIParent, "CENTER", SolaQoLDB.lustStartTextX, SolaQoLDB.lustStartTextY)
            else
                SolaQoLDB.lustReadyTextX = math.floor(centerX + 0.5)
                SolaQoLDB.lustReadyTextY = math.floor(centerY + 0.5)
                selfFrame:ClearAllPoints()
                selfFrame:SetPoint("CENTER", UIParent, "CENTER", SolaQoLDB.lustReadyTextX, SolaQoLDB.lustReadyTextY)
            end
        end
    end)
    
    f:SetScript("OnMouseWheel", function(selfFrame, delta)
        if not selfFrame.isTesting then return end
        if not SolaQoLDB then SolaQoLDB = {} end
        local size = (selfFrame.animMode == "start" and SolaQoLDB.lustStartTextFontSize) or SolaQoLDB.lustReadyTextFontSize or 30
        size = size + (delta * 2)
        if size < 10 then size = 10 end
        if size > 100 then size = 100 end
        
        if selfFrame.animMode == "start" then
            SolaQoLDB.lustStartTextFontSize = size
        else
            SolaQoLDB.lustReadyTextFontSize = size
        end
        selfFrame.text:SetFont(STANDARD_TEXT_FONT, size, "THICKOUTLINE")
        print("|cff00ccff[SolaQoL]|r 알림 텍스트 크기 (" .. selfFrame.animMode .. "): " .. size)
    end)
    
    f:SetScript("OnUpdate", function(selfFrame, elapsed)
        if selfFrame.animMode == "start" then
            selfFrame.colorSwapTimer = (selfFrame.colorSwapTimer or 0) + elapsed
            if selfFrame.colorSwapTimer > 0.15 then
                selfFrame.colorSwapTimer = 0
                selfFrame.isColorRed = not selfFrame.isColorRed
                if selfFrame.isColorRed then
                    selfFrame.text:SetTextColor(1, 0.2, 0.2)
                else
                    selfFrame.text:SetTextColor(1, 1, 0.2)
                end
            end
        elseif selfFrame.animMode == "ready" then
            selfFrame.velocityY = (selfFrame.velocityY or 0) - (800 * elapsed)
            selfFrame.posY = (selfFrame.posY or 100) + (selfFrame.velocityY * elapsed)
            
            if selfFrame.posY <= 0 then
                selfFrame.posY = 0
                selfFrame.velocityY = -selfFrame.velocityY * 0.85
                if selfFrame.velocityY < 20 then
                    selfFrame.velocityY = 0
                end
            end
            selfFrame.text:SetPoint("CENTER", 0, selfFrame.posY)
        end
    end)
    
    f:Hide()
    return f
end

function LustModule:AssembleTextAlert()
    if self.Visuals.StartAlertFrame and self.Visuals.ReadyAlertFrame then return end
    
    self.Visuals.StartAlertFrame = CreateAlertFrame("SolaQoLLustStartAlert", "start")
    self.Visuals.StartAlertFrame.text:SetText(start_msg)
    
    self.Visuals.ReadyAlertFrame = CreateAlertFrame("SolaQoLLustReadyAlert", "ready")
    self.Visuals.ReadyAlertFrame.text:SetText(ready_msg)
    self.Visuals.ReadyAlertFrame.text:SetTextColor(0.2, 1, 0.2)
end

function LustModule:RefreshTextAlertMetrics()
    if not self.Visuals.StartAlertFrame or not self.Visuals.ReadyAlertFrame then return end
    if not SolaQoLDB then SolaQoLDB = {} end
    
    if SolaQoLDB.lustTextX and not SolaQoLDB.lustStartTextX then
        SolaQoLDB.lustStartTextX = SolaQoLDB.lustTextX
        SolaQoLDB.lustReadyTextX = SolaQoLDB.lustTextX
        SolaQoLDB.lustStartTextY = SolaQoLDB.lustTextY
        SolaQoLDB.lustReadyTextY = SolaQoLDB.lustTextY + 50
        SolaQoLDB.lustStartTextFontSize = SolaQoLDB.lustTextFontSize
        SolaQoLDB.lustReadyTextFontSize = SolaQoLDB.lustTextFontSize
    end
    
    local sx = SolaQoLDB.lustStartTextX or 0
    local sy = SolaQoLDB.lustStartTextY or 100
    local ssize = SolaQoLDB.lustStartTextFontSize or 30
    self.Visuals.StartAlertFrame:ClearAllPoints()
    self.Visuals.StartAlertFrame:SetPoint("CENTER", UIParent, "CENTER", sx, sy)
    self.Visuals.StartAlertFrame.text:SetFont(STANDARD_TEXT_FONT, ssize, "THICKOUTLINE")
    
    local rx = SolaQoLDB.lustReadyTextX or 0
    local ry = SolaQoLDB.lustReadyTextY or 150
    local rsize = SolaQoLDB.lustReadyTextFontSize or 30
    self.Visuals.ReadyAlertFrame:ClearAllPoints()
    self.Visuals.ReadyAlertFrame:SetPoint("CENTER", UIParent, "CENTER", rx, ry)
    self.Visuals.ReadyAlertFrame.text:SetFont(STANDARD_TEXT_FONT, rsize, "THICKOUTLINE")
end

function LustModule:ShowTextAlert(mode, isTest, silent)
    if not SolaQoLDB.enableBloodlustAlert and not isTest then return end
    
    local alertMode = "both"
    if not isTest then
        if mode == "start" then
            alertMode = SolaQoLDB.lustStartAlertMode or "both"
        elseif mode == "ready" then
            alertMode = SolaQoLDB.lustReadyAlertMode or "both"
            if not IsLustClass() then return end
        end
        if alertMode == "off" then return end
    end
    
    if alertMode == "audio" then
        if not silent then
            if mode == "start" then
                NS.SafePlaySoundFile(SolaQoL.SoundPath .. start_sound, "Master")
            elseif mode == "ready" then
                NS.SafePlaySoundFile(SolaQoL.SoundPath .. ready_sound, "Master")
            end
        end
        return
    end
    
    self:AssembleTextAlert()
    self:RefreshTextAlertMetrics()
    
    local function activateFrame(f, fMode)
        f.isTesting = isTest
        f:EnableMouse(isTest)
        if isTest then
            f.bg:Show()
        else
            f.bg:Hide()
        end
        
        if fMode == "start" then
            f.text:SetPoint("CENTER", 0, 0)
            f.colorSwapTimer = 0
            f.isColorRed = true
            
            self.Visuals.StartAlertFrame:Show()
            UIFrameFadeIn(self.Visuals.StartAlertFrame, 0.2, 0, 1)
            if not silent and alertMode ~= "text" then
                NS.SafePlaySoundFile("Interface\\AddOns\\SolaQoL\\Media\\" .. start_sound, "Master")
            end
        else
            f.posY = 100
            f.velocityY = 0
            f.text:SetPoint("CENTER", 0, f.posY)
            
            self.Visuals.ReadyAlertFrame.isTesting = isTest
            self.Visuals.ReadyAlertFrame:Show()
            UIFrameFadeIn(self.Visuals.ReadyAlertFrame, 0.2, 0, 1)
            if not silent and alertMode ~= "text" then
                NS.SafePlaySoundFile("Interface\\AddOns\\SolaQoL\\Media\\" .. ready_sound, "Master")
            end
        end
        
        f:Show()
        
        if f.fadeTimer then f.fadeTimer:Cancel(); f.fadeTimer = nil end
        if not isTest then
            if fMode == "ready" and SolaQoLDB and SolaQoLDB.persistBloodlustReady then
                -- Do not fade
            else
                local duration = (fMode == "ready") and 5 or 3
                f.fadeTimer = C_Timer.NewTimer(duration, function() f:Hide() end)
            end
        end
    end
    
    if mode == "test_mode" then
        activateFrame(self.Visuals.StartAlertFrame, "start")
        activateFrame(self.Visuals.ReadyAlertFrame, "ready")
    elseif mode == "start" then
        if self.Visuals.ReadyAlertFrame:IsShown() then
            self.Visuals.ReadyAlertFrame:Hide()
        end
        activateFrame(self.Visuals.StartAlertFrame, "start")
    elseif mode == "ready" then
        if self.Visuals.StartAlertFrame:IsShown() then
            self.Visuals.StartAlertFrame:Hide()
        end
        activateFrame(self.Visuals.ReadyAlertFrame, "ready")
    end
end



function LustModule:AssembleVisuals()
    if self.Visuals.Container then return end

    local config = SolaQoLDB or {}
    local width  = config.lustBarWidth or 800
    local height = config.lustBarHeight or 28

    local container = CreateFrame("Frame", "SolaLustTrackerContainer", UIParent)
    container:SetSize(width, height)
    container:SetFrameStrata("HIGH")
    container:SetClampedToScreen(true)
    container:SetMovable(true)
    container:EnableMouse(true)
    container:Hide()
    self.Visuals.Container = container

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
    self.Visuals.Background = bg

    self.Visuals.Borders = {}
    local function AddBorder(p1, r1, p2, r2, w, h)
        local b = container:CreateTexture(nil, "BORDER")
        b:SetColorTexture(0, 0, 0, 1)
        b:SetPoint(p1, container, r1)
        b:SetPoint(p2, container, r2)
        if w then b:SetWidth(w) end
        if h then b:SetHeight(h) end
        table.insert(self.Visuals.Borders, b)
    end
    AddBorder("TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 1)
    AddBorder("BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 1)
    AddBorder("TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 1, nil)
    AddBorder("TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 1, nil)

    local statusBar = CreateFrame("StatusBar", nil, container)
    statusBar:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
    statusBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
    local texPath = config.lustBarTexture or "Interface\\TargetingFrame\\UI-StatusBar"
    statusBar:SetStatusBarTexture(texPath)
    statusBar:GetStatusBarTexture():SetHorizTile(false)
    statusBar:SetStatusBarColor(0, 0, 0, 0)
    statusBar:SetMinMaxValues(0, 1)
    statusBar:SetValue(1)
    statusBar:SetReverseFill(true)
    self.Visuals.StatusBar = statusBar

    local maskCanvas = CreateFrame("ScrollFrame", nil, container)
    maskCanvas:SetPoint("TOPRIGHT", container, "TOPRIGHT", -1, -1)
    maskCanvas:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
    maskCanvas:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
    maskCanvas:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 1, 1)
    self.Visuals.MaskCanvas = maskCanvas

    local canvasChild = CreateFrame("Frame", nil, maskCanvas)
    canvasChild:SetSize(600, 30)
    maskCanvas:SetScrollChild(canvasChild)
    self.Visuals.CanvasChild = canvasChild

    self.Visuals.Gradients = {}
    for idx = 1, 4 do
        local segment = canvasChild:CreateTexture(nil, "BACKGROUND")
        segment:SetTexture("Interface\\Buttons\\WHITE8x8")
        local c1, c2 = TrackerSettings.Colors[idx], TrackerSettings.Colors[idx+1]
        if segment.SetGradient then
            segment:SetGradient("HORIZONTAL", CreateColor(c1[1], c1[2], c1[3], 1), CreateColor(c2[1], c2[2], c2[3], 1))
        else
            segment:SetVertexColor(c1[1], c1[2], c1[3], 1)
        end
        table.insert(self.Visuals.Gradients, segment)
    end

    local overlay = CreateFrame("Frame", nil, container)
    overlay:SetAllPoints(container)
    overlay:SetFrameLevel(maskCanvas:GetFrameLevel() + 5)
    self.Visuals.Overlay = overlay

    self.Visuals.Glows = {}
    for _, rgb in ipairs(TrackerSettings.Colors) do
        local spark = overlay:CreateTexture(nil, "OVERLAY")
        spark:SetSize(40, 50)
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("ADD")
        spark:SetVertexColor(rgb[1], rgb[2], rgb[3], 0.8)
        table.insert(self.Visuals.Glows, spark)
    end

    local timerLabel = overlay:CreateFontString(nil, "OVERLAY")
    timerLabel:SetFont(STANDARD_TEXT_FONT, 19, "OUTLINE")
    timerLabel:SetPoint("CENTER", container, "CENTER", 0, -1)
    timerLabel:SetTextColor(1, 1, 1, 1)
    self.Visuals.TimerLabel = timerLabel

    container:SetScript("OnMouseDown", function(selfFrame, button)
        if button == "LeftButton" and (LustModule.Simulating or IsAltKeyDown()) then
            selfFrame:StartMoving()
            selfFrame._dragInProgress = true
        end
    end)

    container:SetScript("OnMouseUp", function(selfFrame)
        if selfFrame._dragInProgress then
            selfFrame:StopMovingOrSizing()
            selfFrame._dragInProgress = false
            local centerX = selfFrame:GetLeft() + selfFrame:GetWidth() / 2 - UIParent:GetWidth() / 2
            local topY = selfFrame:GetTop() - UIParent:GetTop()
            if not SolaQoLDB then SolaQoLDB = {} end
            SolaQoLDB.lustBarX = math.floor(centerX + 0.5)
            SolaQoLDB.lustBarY = math.floor(topY + 0.5)
            selfFrame:ClearAllPoints()
            selfFrame:SetPoint("TOP", UIParent, "TOP", SolaQoLDB.lustBarX, SolaQoLDB.lustBarY)
        end
    end)

    container:SetScript("OnHide", function()
        LustModule.IsActive = false
        LustModule.Simulating = false
        StopOnUpdate()
        if NS.ResetTestLustBarButton then
            NS.ResetTestLustBarButton()
        end
    end)

    self:RefreshMetrics()
end

function LustModule:RefreshMetrics()
    if not self.Visuals.Container then return end

    local config = SolaQoLDB or {}
    local w = config.lustBarWidth or 800
    local h = config.lustBarHeight or 28

    self.Visuals.Container:SetSize(w, h)

    local innerW = w - 2
    local innerH = h - 2
    self.Visuals.CanvasChild:SetSize(innerW, innerH)

    local partitionWidth = innerW / 4
    for i, tex in ipairs(self.Visuals.Gradients) do
        local xOffset = (i - 1) * partitionWidth
        tex:SetPoint("TOPLEFT", self.Visuals.CanvasChild, "TOPLEFT", xOffset, 0)
        tex:SetPoint("BOTTOMLEFT", self.Visuals.CanvasChild, "BOTTOMLEFT", xOffset, 0)
        tex:SetWidth(partitionWidth)
    end

    local customTex = config.lustBarTexture or "Interface\\TargetingFrame\\UI-StatusBar"
    self.Visuals.StatusBar:SetStatusBarTexture(customTex)
end

function LustModule:InitiateDisplay()
    self:RefreshMetrics()
    self.Simulating = false
    self.IsActive = true
    self.ExpirationMark = GetTime() + TrackerSettings.Duration

    self.Visuals.StatusBar:SetValue(1)
    for i, spark in ipairs(self.Visuals.Glows) do
        spark:SetPoint("CENTER", self.Visuals.StatusBar, "LEFT", 0, TrackerSettings.SparkOffsets[i])
    end

    self.Visuals.Container:ClearAllPoints()
    local posX = (SolaQoLDB and SolaQoLDB.lustBarX) or 23
    local posY = (SolaQoLDB and SolaQoLDB.lustBarY) or -56
    self.Visuals.Container:SetPoint("TOP", UIParent, "TOP", posX, posY)
    self.Visuals.Container:Show()
    StartOnUpdate()
end

function LustModule:CheckForAuraMatches()
    for i = 1, #TARGET_DEBUFFS do
        local data = C_UnitAuras.GetPlayerAuraBySpellID(TARGET_DEBUFFS[i])
        if data then return data end
    end
    return nil
end

function LustModule:EvaluateAuraChanges()
    if not (SolaQoLDB and SolaQoLDB.enableLust) then return end

    local matchedAura = self:CheckForAuraMatches()

    if matchedAura then
        if not self.CurrentAuraState then
            self.CurrentAuraState = true

            local duration = matchedAura.duration or 0
            local expire   = matchedAura.expirationTime or 0

            if duration > 0 and expire > 0 then
                local appliedAt = expire - duration
                local timeSinceApplied = GetTime() - appliedAt
                if timeSinceApplied <= 5.0 then
                    self:InitiateDisplay()
                    self:ShowTextAlert("start")
                end
            end
        end
    else
        if self.CurrentAuraState then
            self.CurrentAuraState = false
            self:ShowTextAlert("ready")
            if self.Visuals.Container and self.Visuals.Container:IsShown() then
                self.Visuals.Container:Hide()
            end
        end
    end
end


Dispatcher:SetScript("OnEvent", function(_, eventName, arg1)
    if eventName == "PLAYER_LOGIN" then
        if not SolaQoLDB then SolaQoLDB = {} end
        LustModule:AssembleVisuals()
        LustModule.CurrentAuraState = (LustModule:CheckForAuraMatches() ~= nil)
        LustModule.SystemReady = true

    elseif eventName == "PLAYER_ENTERING_WORLD" and LustModule.SystemReady then
        if LustModule.Visuals.Container and LustModule.Visuals.Container:IsShown() then
            LustModule.Visuals.Container:Hide()
        end
        LustModule.CurrentAuraState = (LustModule:CheckForAuraMatches() ~= nil)
        
        if not LustModule.CurrentAuraState and SolaQoLDB and SolaQoLDB.enableBloodlustAlert and SolaQoLDB.persistBloodlustReady then
            LustModule:ShowTextAlert("ready", false, true) -- silent
        end

    elseif eventName == "UNIT_AURA" and arg1 == "player" and LustModule.SystemReady then
        LustModule:EvaluateAuraChanges()
    end
end)


NS.UpdateLustBarOptions = function()
    LustModule:RefreshMetrics()
end

NS.TestLustBar = function()
    if LustModule.Visuals.Container and LustModule.Visuals.Container:IsShown() and LustModule.IsActive then
        LustModule.IsActive = false
        LustModule.Simulating = false
        LustModule.Visuals.Container:Hide()
        return false
    else
        if not LustModule.Visuals.Container then LustModule:AssembleVisuals() end
        LustModule:RefreshMetrics()

        LustModule.Simulating = true
        LustModule.IsActive = true
        LustModule.ExpirationMark = GetTime() + TrackerSettings.Duration
        LustModule.Visuals.StatusBar:SetValue(1)

        for i, spark in ipairs(LustModule.Visuals.Glows) do
            spark:SetPoint("CENTER", LustModule.Visuals.StatusBar, "LEFT", 0, TrackerSettings.SparkOffsets[i])
        end

        LustModule.Visuals.Container:ClearAllPoints()
        local posX = (SolaQoLDB and SolaQoLDB.lustBarX) or 23
        local posY = (SolaQoLDB and SolaQoLDB.lustBarY) or -56
        LustModule.Visuals.Container:SetPoint("TOP", UIParent, "TOP", posX, posY)
        LustModule.Visuals.Container:Show()
        StartOnUpdate()

        return true
    end
end

NS.IsLustBarActive = function()
    return LustModule.Visuals.Container and LustModule.Visuals.Container:IsShown() and LustModule.IsActive
end


NS.ResetTestLustBarButton = nil

NS.TestBloodlustAlert = function(mode, isConfigTest)
    if mode == "off" then
        if LustModule.Visuals.StartAlertFrame then LustModule.Visuals.StartAlertFrame:Hide() end
        if LustModule.Visuals.ReadyAlertFrame then LustModule.Visuals.ReadyAlertFrame:Hide() end
        if SolaQoLDB and SolaQoLDB.persistBloodlustReady and SolaQoLDB.enableBloodlustAlert then
            if NS.UpdateBloodlustReadyDisplay then NS.UpdateBloodlustReadyDisplay() end
        end
        return false
    else
        -- If isConfigTest is true, we want silent mode so sound doesn't play
        LustModule:ShowTextAlert(mode, isConfigTest, isConfigTest)
        return true
    end
end

NS.UpdateBloodlustReadyDisplay = function()
    if not SolaQoLDB.enableBloodlustAlert or SolaQoLDB.lustReadyAlertMode == "off" or SolaQoLDB.lustReadyAlertMode == "audio" or not IsLustClass() then 
        if LustModule.Visuals.ReadyAlertFrame then LustModule.Visuals.ReadyAlertFrame:Hide() end
        return 
    end
    
    local hasAura = (LustModule:CheckForAuraMatches() ~= nil)
    if not hasAura and SolaQoLDB.persistBloodlustReady then
        LustModule:ShowTextAlert("ready", false, true)
    elseif not hasAura and not SolaQoLDB.persistBloodlustReady then
        if LustModule.Visuals.ReadyAlertFrame and not LustModule.Visuals.ReadyAlertFrame.isTesting then
            if not LustModule.Visuals.ReadyAlertFrame.fadeTimer then
                LustModule.Visuals.ReadyAlertFrame:Hide()
            end
        end
    end
end
