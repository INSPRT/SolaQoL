local ADDON_NAME, NS = ...

local L = NS.L
local HasText = NS.HasText


NS.TooltipILvlCache = {}
NS.TooltipInspectTarget = nil
local TooltipInspectTime = 0

local function SafeMatchGUID(u, g)
    if not UnitExists(u) then return false end
    local ok, res = pcall(function() return UnitGUID(u) == g end)
    return ok and res
end

local UNIT_CANDIDATES = { "mouseover", "target", "player", "focus", "party1", "party2", "party3", "party4" }

function NS.FindUnitByGUID(g)
    if not g then return nil end
    for i = 1, #UNIT_CANDIDATES do
        if SafeMatchGUID(UNIT_CANDIDATES[i], g) then return UNIT_CANDIDATES[i] end
    end
    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid"..i
            if SafeMatchGUID(unit, g) then return unit end
        end
    end
    return nil
end


local SCAN_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }
local TWO_HAND_WEAPONS = { ["INVTYPE_2HWEAPON"] = true, ["INVTYPE_RANGED"] = true, ["INVTYPE_RANGEDRIGHT"] = true }
local SPECIAL_ILVL_OVERRIDES = {
    ["Reshii Wraps"] = 170,
    ["Durable Information Securing Container"] = 141,
}

function NS.ComputeUnitItemLevel(u)
    if not UnitExists(u) or not UnitIsPlayer(u) then return nil end

    if UnitIsUnit(u, "player") then
        local _, equipped = GetAverageItemLevel()
        if equipped and equipped > 0 then return equipped end
    end

    if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel and CanInspect(u) then
        local inspectIlvl = C_PaperDollInfo.GetInspectItemLevel(u)
        if inspectIlvl and inspectIlvl > 0 then return inspectIlvl end
    end

    local sumIlvl = 0
    local loadedItems = 0
    local missingSlots = 0

    for i = 1, #SCAN_SLOTS do
        local sIdx = SCAN_SLOTS[i]
        local link = GetInventoryItemLink(u, sIdx)

        if link then
            local dIlvl = GetDetailedItemLevelInfo(link)
            local iName = GetItemInfo(link)

            if iName and SPECIAL_ILVL_OVERRIDES[iName] then
                dIlvl = SPECIAL_ILVL_OVERRIDES[iName]
            end

            if dIlvl then
                sumIlvl = sumIlvl + dIlvl
                loadedItems = loadedItems + 1
            else
                missingSlots = missingSlots + 1
            end
        end
    end

    if missingSlots > 2 then return nil end

    if loadedItems > 0 then
        local divisor = 16
        local mHand = GetInventoryItemLink(u, 16)
        local oHand = GetInventoryItemLink(u, 17)

        if mHand and not oHand then
            local _, _, _, _, _, _, _, _, eqLoc = GetItemInfo(mHand)
            if eqLoc and TWO_HAND_WEAPONS[eqLoc] then divisor = 15 end
        end
        return sumIlvl / divisor
    end
    return 0
end

function NS.RequestTooltipInspect(unit, guid)
    if not CanInspect(unit) then return end
    local now = GetTime()
    if (now - TooltipInspectTime) < 1.5 then return end
    if InspectFrame and InspectFrame:IsShown() then return end

    NS.TooltipInspectTarget = guid
    TooltipInspectTime = now
    NotifyInspect(unit)
end


if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if not SolaQoLDB.enableTooltipIlvl then return end
        if not data or not data.guid then return end

        local guid = data.guid
        if not guid then return end

        local unit = NS.FindUnitByGUID(guid)
        if not unit or not UnitIsPlayer(unit) then return end
        local cachedVal = NS.TooltipILvlCache[guid]

        local cleanedMythicPrefix = L.MYTHIC_SCORE_PREFIX:gsub("[:%s]+$", "")

        for i = tooltip:NumLines(), 1, -1 do
            local line = _G[tooltip:GetName() .. "TextLeft" .. i]
            if line then
                local t = line:GetText()
                if t and (t:find(L.ILVL_COLON) or t:find(L.ILVL_LOADING) or t:find(cleanedMythicPrefix)) then
                    line:SetText(nil)
                    local rLine = _G[tooltip:GetName() .. "TextRight" .. i]
                    if rLine then rLine:SetText(nil) end
                end
            end
        end

        if cachedVal then
            tooltip:AddDoubleLine(L.ILVL_COLON, math.floor(cachedVal), 1, 0.82, 0, 1, 0.82, 0)
        else
            tooltip:AddDoubleLine(L.ILVL_COLON, L.ILVL_LOADING, 1, 0.82, 0, 0.6, 0.6, 0.6)
            NS.RequestTooltipInspect(unit, guid)
        end

        if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
            local info = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
            local score = info and info.currentSeasonScore
            if score and score > 0 then
                local sColor = C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor and C_ChallengeMode.GetDungeonScoreRarityColor(score)
                local r, g, b = 1, 1, 1
                if sColor then r, g, b = sColor.r, sColor.g, sColor.b end
                local scorePrefix = L.MYTHIC_SCORE_PREFIX:gsub("[:%s]+$", "") .. ":"
                tooltip:AddDoubleLine(scorePrefix, math.floor(score), 1, 1, 1, r, g, b)
            end
        end
    end)
end


NS.ScanData = {}
NS.targetCount = 0
NS.scanLoop = nil
NS.inspectingGUID = nil

function NS.SaveLFGInfo()
    if not C_LFGList.HasActiveEntryInfo() then return end
    local apps = C_LFGList.GetApplicants()
    if apps then
        for _, id in ipairs(apps) do
            local info = C_LFGList.GetApplicantInfo(id)
            if info and info.numMembers then
                for i = 1, info.numMembers do
                    local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dungeonScore, pvpItemLevel, factionGroup, raceID, specID = C_LFGList.GetApplicantMemberInfo(id, i)
                    if name and itemLevel and itemLevel > 0 then
                        local specName = ""
                        if specID and type(specID) == "number" and specID > 0 then
                            specName = select(2, GetSpecializationInfoByID(specID)) or ""
                        end
                        NS.LFGMemory[name] = { ilvl = itemLevel, spec = specName }
                    end
                end
            end
        end
    end
end

function NS.GetRoleIcon(unit)
    local r = UnitGroupRolesAssigned(unit)
    if r == "TANK" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:0:19:22:41|t"
    elseif r == "HEALER" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:1:20|t"
    elseif r == "DAMAGER" then return "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:14:14:0:0:64:64:20:39:22:41|t"
    end
    return ""
end

function NS.IsAllScanned()
    for _, v in pairs(NS.ScanData) do
        if not v.isDone then return false end
    end
    return true
end

function NS.PrintResult()
    local title = NS.GetGroupTitle()
    if HasText(title) then
        print("|cff00ccff" .. L.PARTY_JOIN_HEADER .. " - " .. title .. "|r")
    else
        print("|cff00ccff" .. L.PARTY_ILVL_HEADER .. "|r")
    end

    local line = string.rep("-", 32)
    DEFAULT_CHAT_FRAME:AddMessage(line, 1, 0.64, 0)
    for _, v in pairs(NS.ScanData) do
        if v.isDone or v.ilvl > 0 then
            local specStr = v.spec and ("("..v.spec..")") or ""
            local classColor = select(4, GetClassColor(v.class))
            DEFAULT_CHAT_FRAME:AddMessage(format("  %s %.1f |c%s%s|r |cffcccccc%s|r", NS.GetRoleIcon(v.unit), v.ilvl, classColor, v.name, specStr), 1, 0.82, 0)
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(line, 1, 0.64, 0)
end

function NS.FinishScan()
    if NS.scanLoop then NS.scanLoop:Cancel(); NS.scanLoop = nil end
    if SolaQoLDB.showIlevelToSelf then NS.PrintResult() end
end

function NS.TryInspect()
    if InspectFrame and InspectFrame:IsShown() then return end
    for guid, d in pairs(NS.ScanData) do
        if not d.isDone and UnitIsConnected(d.unit) and CanInspect(d.unit) then
            NS.inspectingGUID = guid
            NotifyInspect(d.unit)
            return
        end
    end
end

function NS.RefreshRoster(count)
    local cur = {}
    for i = 1, count do
        local u = "party"..i
        local g = UnitGUID(u)
        if g then cur[g] = u end
    end

    for g in pairs(NS.ScanData) do
        if not cur[g] and g ~= UnitGUID("player") then
            NS.ScanData[g] = nil
        end
    end

    for g, u in pairs(cur) do
        if NS.ScanData[g] then
            NS.ScanData[g].isDone = false
            NS.ScanData[g].unit = u
            NS.ScanData[g].class = select(2, UnitClass(u))
        else
            NS.ScanData[g] = { isDone = false, unit = u, class = select(2, UnitClass(u)), ilvl = 0 }
        end
        NS.ScanData[g].name, NS.ScanData[g].realm = UnitName(u)
        if not NS.ScanData[g].realm then NS.ScanData[g].realm = GetRealmName() end

        local fullName = NS.ScanData[g].name
        if NS.ScanData[g].realm and NS.ScanData[g].realm ~= "" then
            fullName = fullName .. "-" .. NS.ScanData[g].realm
        end

        local cached = NS.LFGMemory[fullName] or NS.LFGMemory[NS.ScanData[g].name]
        if cached then
            if type(cached) == "table" and cached.ilvl and cached.ilvl > 0 and NS.ScanData[g].ilvl <= 0 then
                NS.ScanData[g].ilvl = cached.ilvl
                if cached.spec and cached.spec ~= "" then
                    NS.ScanData[g].spec = cached.spec
                end
                NS.ScanData[g].isDone = true
            elseif type(cached) == "number" and cached > 0 and NS.ScanData[g].ilvl <= 0 then
                NS.ScanData[g].ilvl = cached
                NS.ScanData[g].isDone = true
            end
        end
    end
end


function NS.HandleInspectReady(guid)
    if not guid then return end


    if guid == NS.inspectingGUID then
        local d = NS.ScanData[guid]
        if d then
            d.ilvl = C_PaperDollInfo.GetInspectItemLevel(d.unit) or 0
            local specID = GetInspectSpecialization(d.unit)
            if specID and specID > 0 then
                d.spec = select(2, GetSpecializationInfoByID(specID)) or ""
            end
            d.isDone = true
        end
    end


    if SolaQoLDB.enableTooltipIlvl and guid == NS.TooltipInspectTarget then
        local tUnit = NS.FindUnitByGUID(guid)
        if tUnit then
            local calcIlvl = NS.ComputeUnitItemLevel(tUnit)
            if calcIlvl then
                NS.TooltipILvlCache[guid] = calcIlvl
                NS.TooltipInspectTarget = nil

                if GameTooltip:IsShown() then
                    local hasReplaced = false
                    for i = GameTooltip:NumLines(), 1, -1 do
                        local line = _G["GameTooltipTextLeft"..i]
                        if line then
                            local ok, match = pcall(function()
                                local t = line:GetText()
                                return t and t:find(L.ILVL_COLON)
                            end)
                            if ok and match then
                                local rLine = _G["GameTooltipTextRight"..i]
                                if rLine then
                                    rLine:SetText(math.floor(calcIlvl))
                                    rLine:SetTextColor(1, 0.82, 0)
                                    rLine:Show()
                                else
                                    line:SetText(L.ILVL_PREFIX .. math.floor(calcIlvl))
                                end
                                line:SetTextColor(1, 0.82, 0)
                                hasReplaced = true
                                break
                            end
                        end
                    end
                    if hasReplaced then GameTooltip:Show() end
                end
            end
        end
    end
end
