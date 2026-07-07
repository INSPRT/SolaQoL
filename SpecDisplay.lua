local ADDON_NAME, NS = ...
local L = NS.L

-- Overlay showing active talent spec/loadout on entering instances


local specDisplayFrame = CreateFrame("Frame", "SolaQoL_SpecDisplay", UIParent)
specDisplayFrame:SetSize(500, 80)
specDisplayFrame:SetPoint("TOP", UIParent, "TOP", 0, -290)
specDisplayFrame:Hide()
specDisplayFrame:SetMovable(true)
specDisplayFrame:SetClampedToScreen(true)

local specDisplayText = specDisplayFrame:CreateFontString(nil, "OVERLAY")
local fontPath, _, _ = GameFontNormalHuge:GetFont()
specDisplayText:SetFont(fontPath, 32, "THICKOUTLINE")
specDisplayText:SetPoint("CENTER")
specDisplayText:SetShadowColor(0, 0, 0, 0.8)
specDisplayText:SetShadowOffset(2, -2)

specDisplayFrame:EnableMouse(true)
specDisplayFrame:EnableMouseWheel(true)
if specDisplayFrame.SetPassThroughButtons then
    specDisplayFrame:SetPassThroughButtons("LeftButton")
end

local isAltActive = false

local function UpdateAltState(self)
    local alt = IsAltKeyDown()
    if alt ~= isAltActive then
        isAltActive = alt
        self:EnableMouseWheel(alt)
        if self.SetPassThroughButtons and not InCombatLockdown() then
            if alt then
                self:SetPassThroughButtons()
            else
                self:SetPassThroughButtons("LeftButton")
            end
        end
    end
end

specDisplayFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
specDisplayFrame:SetScript("OnEvent", function(self, event, key, state)
    if event == "MODIFIER_STATE_CHANGED" and (key == "LALT" or key == "RALT") then
        if self:IsShown() then
            UpdateAltState(self)
        end
    end
end)

specDisplayFrame:SetScript("OnShow", function(self)
    UpdateAltState(self)
end)

specDisplayFrame:RegisterForDrag("LeftButton")
specDisplayFrame:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() then
        self:StartMoving()
    end
end)

specDisplayFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
    SolaQoLDB.specPosPoint = point
    SolaQoLDB.specPosRelPoint = relativePoint
    SolaQoLDB.specPosX = xOfs
    SolaQoLDB.specPosY = yOfs
end)

specDisplayFrame:SetScript("OnMouseWheel", function(self, delta)
    if IsAltKeyDown() then
        local currentFontPath, currentFontSize, currentFontFlags = specDisplayText:GetFont()
        if not currentFontPath or currentFontPath == "" then
            currentFontPath = GameFontNormalHuge:GetFont()
        end
        if not currentFontSize then currentFontSize = 32 end
        
        if delta > 0 then
            currentFontSize = math.min(64, currentFontSize + 2)
        else
            currentFontSize = math.max(12, currentFontSize - 2)
        end
        
        specDisplayText:SetFont(currentFontPath, currentFontSize, currentFontFlags)
        SolaQoLDB.specFontSize = currentFontSize
        
        local textWidth = specDisplayText:GetStringWidth()
        local textHeight = specDisplayText:GetStringHeight()
        self:SetSize(textWidth + 20, textHeight + 10)
    end
end)

local animGroup = specDisplayFrame:CreateAnimationGroup()

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetTarget(specDisplayFrame)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.5)
fadeIn:SetOrder(1)

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetTarget(specDisplayFrame)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(1.0)
fadeOut:SetStartDelay(20.0)
fadeOut:SetOrder(2)

animGroup:SetScript("OnFinished", function()
    specDisplayFrame:Hide()
end)

local dismissGroup = specDisplayFrame:CreateAnimationGroup()
local dismissFade = dismissGroup:CreateAnimation("Alpha")
dismissFade:SetTarget(specDisplayFrame)
dismissFade:SetFromAlpha(1)
dismissFade:SetToAlpha(0)
dismissFade:SetDuration(0.3)
dismissGroup:SetScript("OnFinished", function()
    specDisplayFrame:Hide()
end)

specDisplayFrame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        animGroup:Stop()
        dismissGroup:Stop()
        dismissGroup:Play()
    end
end)

local function ShowSpecDisplay()
    local displayName
    local specIndex = GetSpecialization()
    if specIndex then
        local specID, specName = GetSpecializationInfo(specIndex)
        if specID then

            local configID = C_ClassTalents and C_ClassTalents.GetLastSelectedSavedConfigID and C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            if configID then
                local configInfo = C_Traits and C_Traits.GetConfigInfo and C_Traits.GetConfigInfo(configID)
                if configInfo and configInfo.name and configInfo.name ~= "" then
                    displayName = configInfo.name
                end
            end
        end

        if not displayName or displayName == "" then
            displayName = specName
        end
    end
    if not displayName or displayName == "" then
        displayName = select(1, UnitClass("player"))
    end
    
    if displayName and displayName ~= "" then
        local currentFontPath, _, currentFontFlags = specDisplayText:GetFont()
        if not currentFontPath or currentFontPath == "" then
            currentFontPath = GameFontNormalHuge:GetFont()
        end
        local savedSize = SolaQoLDB.specFontSize or 32
        specDisplayText:SetFont(currentFontPath, savedSize, currentFontFlags)
        
        specDisplayText:SetText(string.format(L.SPEC_DISPLAY_FORMAT, displayName))
        
        local _, classFile = UnitClass("player")
        local color = RAID_CLASS_COLORS[classFile] or { r = 1, g = 0.82, b = 0 }
        specDisplayText:SetTextColor(color.r, color.g, color.b)
        
        local textWidth = specDisplayText:GetStringWidth()
        local textHeight = specDisplayText:GetStringHeight()
        specDisplayFrame:SetSize(textWidth + 20, textHeight + 10)
        
        if SolaQoLDB.specPosX and SolaQoLDB.specPosY then
            specDisplayFrame:ClearAllPoints()
            specDisplayFrame:SetPoint(SolaQoLDB.specPosPoint or "TOP", UIParent, SolaQoLDB.specPosRelPoint or "TOP", SolaQoLDB.specPosX, SolaQoLDB.specPosY)
        else
            specDisplayFrame:ClearAllPoints()
            specDisplayFrame:SetPoint("TOP", UIParent, "TOP", 0, -290)
        end
        
        specDisplayFrame:Show()
        animGroup:Stop()
        dismissGroup:Stop()
        specDisplayFrame:SetAlpha(1) -- Reset alpha if reshown during fade.
        animGroup:Play()
    end
end


NS.ShowSpecDisplay  = ShowSpecDisplay
NS.specDisplayFrame = specDisplayFrame
NS.specAnimGroup    = animGroup
NS.specDismissGroup = dismissGroup
