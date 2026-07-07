-- Auto-release spirit on death, modeled after Sola_MiscSet's proven approach
local _, NS = ...

NS.AutoRelease = {}

local UnitIsDead  = UnitIsDead
local UnitIsGhost = UnitIsGhost
local RepopMe     = RepopMe

local function TryRelease()
    if not SolaQoLDB or not SolaQoLDB.enableAutoRelease then return end
    if not UnitIsDead("player") or UnitIsGhost("player") then return end

    local hasSelfRes = false
    if C_DeathInfo and C_DeathInfo.GetSelfResurrectOptions then
        local options = C_DeathInfo.GetSelfResurrectOptions()
        if options and #options > 0 then
            hasSelfRes = true
        end
    elseif HasSoulstone and HasSoulstone() then
        hasSelfRes = true
    end

    if hasSelfRes then return end

    RepopMe()
    local count = 0
    local ticker
    ticker = C_Timer.NewTicker(0.05, function()
        count = count + 1
        if UnitIsDead("player") and not UnitIsGhost("player") then
            RepopMe()
        end
        if count >= 6 and ticker then
            ticker:Cancel()
        end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    if not SolaQoLDB or not SolaQoLDB.enableAutoRelease then return end
    if UnitIsDead("player") and not UnitIsGhost("player") then
        TryRelease()
    end
end)
