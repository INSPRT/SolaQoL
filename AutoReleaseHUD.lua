-- HUD overlay showing Auto-Release status
local _, NS = ...

local hudFrame = CreateFrame("Frame", "SolaQoL_AutoReleaseHUD", UIParent)
hudFrame:SetSize(120, 30)
hudFrame:Hide()
hudFrame:SetMovable(true)
hudFrame:SetClampedToScreen(true)

-- Green dot status texture
local greenDot = hudFrame:CreateTexture(nil, "BACKGROUND")
greenDot:SetSize(30, 30)
greenDot:SetPoint("LEFT")
greenDot:SetTexture("Interface\\COMMON\\Indicator-Green")

-- Larger '영전' label with outline
local hudText = hudFrame:CreateFontString(nil, "OVERLAY")
local fontPath, _, _ = GameFontNormal:GetFont()
hudText:SetFont(fontPath, 20, "THICKOUTLINE")
hudText:SetPoint("LEFT", greenDot, "RIGHT", -2, 0)
hudText:SetText(SolaQoL_L.HUD_AUTO_RELEASE or "Auto-Rel")
hudText:SetTextColor(1, 1, 1, 1)
hudText:SetShadowColor(0, 0, 0, 0.9)
hudText:SetShadowOffset(1, -1)

hudFrame:EnableMouse(true)
if hudFrame.SetPassThroughButtons then
    hudFrame:SetPassThroughButtons("LeftButton")
end

local isAltActive = false

local function UpdateAltState(self)
    local alt = IsAltKeyDown()
    if alt ~= isAltActive then
        isAltActive = alt
        if self.SetPassThroughButtons and not InCombatLockdown() then
            if alt then
                self:SetPassThroughButtons()
            else
                self:SetPassThroughButtons("LeftButton")
            end
        end
    end
end

hudFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
hudFrame:SetScript("OnEvent", function(self, event, key, state)
    if event == "MODIFIER_STATE_CHANGED" and (key == "LALT" or key == "RALT") then
        if self:IsShown() then
            UpdateAltState(self)
        end
    end
end)

hudFrame:SetScript("OnShow", function(self)
    UpdateAltState(self)
end)

hudFrame:RegisterForDrag("LeftButton")
hudFrame:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() then
        self:StartMoving()
    end
end)

hudFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
    if SolaQoLDB then
        SolaQoLDB.hudPosPoint = point
        SolaQoLDB.hudPosRelPoint = relativePoint
        SolaQoLDB.hudPosX = xOfs
        SolaQoLDB.hudPosY = yOfs
    end
end)

local function LoadPosition()
    if SolaQoLDB and SolaQoLDB.hudPosX then
        hudFrame:ClearAllPoints()
        hudFrame:SetPoint(SolaQoLDB.hudPosPoint, UIParent, SolaQoLDB.hudPosRelPoint, SolaQoLDB.hudPosX, SolaQoLDB.hudPosY)
    else
        hudFrame:ClearAllPoints()
        hudFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end
end

local function UpdateHUDShown()
    if SolaQoLDB and SolaQoLDB.enableAutoRelease and not SolaQoLDB.disableAutoReleaseHUD then
        LoadPosition()
        hudFrame:Show()
    else
        hudFrame:Hide()
    end
end


NS.UpdateAutoReleaseHUD = UpdateHUDShown

-- Initialize on login
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    UpdateHUDShown()
end)
