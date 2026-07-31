-- Event dispatcher, roster updates, and slash commands
local ADDON_NAME, NS = ...
local L  = NS.L
local St = NS.State

local pairs, ipairs       = pairs, ipairs
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local InCombatLockdown    = InCombatLockdown
local UnitGUID            = UnitGUID
local GetNumSubgroupMembers = GetNumSubgroupMembers
local string_format       = string.format

-- Cache LFG group title on signup for overlay lookup
if C_LFGList and C_LFGList.ApplyToGroup then
    hooksecurefunc(C_LFGList, "ApplyToGroup", function(id)
        if id then
            local info = C_LFGList.GetSearchResultInfo(id)
            if info then
                local fullTitle, hasCat, aID, rawName = NS.BuildLFGTitle(info.name, info.activityIDs, info.activityID)
                if NS.HasText(fullTitle) then
                    NS.AppliedTitles[id] = { title = fullTitle, hasCat = hasCat, aID = aID, rawName = rawName }
                end
            end
        end
    end)
end

-- Clear cached title on manual invite
local function ClearOldTitleOnManualInvite()
    if not C_LFGList.HasActiveEntryInfo() then
        NS.ActiveTitleCache = ""
    end
end
hooksecurefunc(C_PartyInfo, "InviteUnit", ClearOldTitleOnManualInvite)
if InviteUnit then hooksecurefunc("InviteUnit", ClearOldTitleOnManualInvite) end


local rosterTimer = nil
local applicantTimer = nil

local function OnRosterUpdate()
    if not St.isInit then
        St.prevType = NS.GetGrpType()
        St.prevMems, St.prevCount = NS.GetCurrentMembers()
        return
    end

    local oType, oMems, oCount = St.prevType, St.prevMems, St.prevCount
    local nType, nMems, nCount = NS.GetGrpType(), NS.GetCurrentMembers()
    local myGuid = UnitGUID("player")
    local hasNew = false

    -- Clear title and hide portal if we go solo
    if nType == "solo" then
        NS.ActiveTitleCache = ""
        wipe(NS.AppliedTitles)
        wipe(NS.LFGMemory)
        NS.HidePortal()
    end


    if nType ~= "solo" then
        for g in pairs(nMems) do
            if not oMems[g] and g ~= myGuid then
                hasNew = true; break
            end
        end
    end


    if hasNew then
        local shouldPlay = (nType == "party") or (nType == "raid" and SolaQoLDB.enableRaidSound)
        if shouldPlay and not SolaQoLDB.muteNewMember then
            if SolaQoLDB.customSoundNewMember and SolaQoLDB.customSoundNewMember ~= "" then
                NS.SafePlaySoundFile(SolaQoLDB.customSoundNewMember, "Master", false)
            else
                PlaySound(SOUNDKIT.IG_PLAYER_INVITE, "Master")
            end
        end
    end


    if nType == "party" and nCount >= 5 and oCount < 5 then
        NS.FlashClientIcon()
        if not SolaQoLDB.muteFullParty then
            if SolaQoLDB.customSoundFullParty and SolaQoLDB.customSoundFullParty ~= "" then
                NS.SafePlaySoundFile(SolaQoLDB.customSoundFullParty, "Master", false)
            else
                PlaySound(SOUNDKIT.READY_CHECK, "Master")
            end
        end
        local t = NS.GetGroupTitle()
        if NS.HasText(t) then
            print("|cffffff00" .. L.NOTICE .. " " .. L.MSG_FULL .. " - " .. t .. "|r")
            NS.ShowPortalIfAvailable(t)
        else
            print("|cffffff00" .. L.NOTICE .. " " .. L.MSG_FULL .. "|r")
        end
    end


    if nType == "party" and oType == "solo" then
        St.shouldGreet = true
        local t = NS.GetGroupTitle()
        if NS.HasText(t) then
            NS.ShowPortalIfAvailable(t)
        end
    end


    if SolaQoLDB.enableHello and nType == "party" and nCount >= 2 then
        if St.shouldGreet then
            St.shouldGreet = false
            St.lastChange = NS.Now()
            NS.DelayChat(SolaQoLDB.msgHello, "PARTY", nil, nil, true)
        elseif (NS.Now() - St.lastChange) > 5.0 then
            if hasNew then
                if not SolaQoLDB.onlyGreetOnceAsMember or UnitIsGroupLeader("player") then
                    St.lastChange = NS.Now()
                    NS.DelayChat(SolaQoLDB.msgHello, "PARTY", nil, nil, true)
                end
            end
        end
    end


    if nType == "party" and not IsInRaid() then
        local subCount = GetNumSubgroupMembers()
        if subCount > NS.targetCount then
            NS.RefreshRoster(subCount)
            NS.ScanData[myGuid] = {
                name    = UnitName("player"),
                class   = select(2, UnitClass("player")),
                ilvl    = select(2, GetAverageItemLevel()),
                isDone  = true,
                unit    = "player",
                spec    = select(2, GetSpecializationInfo(GetSpecialization() or 0)) or "",
            }
            if NS.scanLoop then NS.scanLoop:Cancel() end
            local tickCount = 0
            NS.scanLoop = C_Timer.NewTicker(1, function()
                tickCount = tickCount + 1
                if GetNumSubgroupMembers() == 0 or IsInRaid() then
                    NS.scanLoop:Cancel()
                    return
                end
                if NS.IsAllScanned() or tickCount >= 30 then
                    NS.FinishScan()
                else
                    NS.TryInspect()
                end
            end, 30)
        end
        NS.targetCount = subCount
    elseif nType == "solo" or nType == "raid" then
        NS.targetCount = 0
        if NS.scanLoop then NS.scanLoop:Cancel(); NS.scanLoop = nil end
    end

    St.prevType, St.prevMems, St.prevCount = nType, nMems, nCount
end


local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("GROUP_LEFT")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
f:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
f:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
f:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
f:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
f:RegisterEvent("LFG_LIST_JOINED_GROUP")
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("TRADE_SHOW")
f:RegisterEvent("TRADE_CLOSED")
f:RegisterEvent("TRADE_REQUEST_CANCEL")
f:RegisterEvent("TRADE_ACCEPT_UPDATE")
f:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
f:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
f:RegisterEvent("UI_INFO_MESSAGE")
f:RegisterEvent("UI_ERROR_MESSAGE")

f:SetScript("OnEvent", function(_, ev, arg1, arg2)


    if ev == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            NS.InitDB()
            NS.InitCharDB()
        elseif arg1 == "Blizzard_InspectUI" then
            NS.PatchInspectPVPFrame()
        end


    elseif ev == "PLAYER_ENTERING_WORLD" then
        if arg1 or arg2 then
            local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
            local ver = getMetadata and getMetadata("SolaQoL", "Version") or "1.0.0"
            local fmt = L.WELCOME_MSG_FMT or "|cff00ccff[SolaQoL]|r %s Activated."
            print(string_format(fmt, ver))
        end

        St.isInit       = false
        St.shouldGreet  = false
        St.prevType     = NS.GetGrpType()
        St.prevMems, St.prevCount = NS.GetCurrentMembers()
        St.prevAppCount = 0
        NS.targetCount  = GetNumSubgroupMembers()


        NS.HidePortal()

        -- Wipe caches to prevent memory leaks on zone changes.
        wipe(NS.TooltipILvlCache)
        NS.TooltipInspectTarget = nil


        local inInstance, instanceType = IsInInstance()
        local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
        if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
            if instanceID and instanceID ~= St.lastInstanceID then
                if not arg1 and not arg2 then
                    if SolaQoLDB.showSpecOnEnter then
                        NS.ShowSpecDisplay()
                    end
                end
                St.lastInstanceID = instanceID
            end
        else
            St.lastInstanceID = nil
            if NS.specDisplayFrame then
                NS.specDisplayFrame:Hide()
                if NS.specAnimGroup then NS.specAnimGroup:Stop() end
                if NS.specDismissGroup then NS.specDismissGroup:Stop() end
            end
        end

        C_Timer.After(5, function() St.isInit = true end)


    elseif ev == "GROUP_ROSTER_UPDATE" then
        -- Wait a bit for WoW to sync GUIDs so we don't get nil
        if rosterTimer then rosterTimer:Cancel() end
        rosterTimer = C_Timer.NewTimer(0.2, OnRosterUpdate)

    elseif ev == "GROUP_JOINED" then
        if St.isInit then
            St.shouldGreet = true
        end

    elseif ev == "GROUP_LEFT" then
        St.shouldGreet = false
        NS.ActiveTitleCache = ""
        wipe(NS.AppliedTitles)
        wipe(NS.LFGMemory)


    elseif ev == "CHALLENGE_MODE_COMPLETED" then
        NS.ActiveTitleCache = ""
        if SolaQoLDB.enableGG and IsInGroup() and not IsInRaid() and (NS.Now() - St.lastClear) > 10.0 then
            St.lastClear = NS.Now()
            NS.DelayChat(SolaQoLDB.msgGG, "PARTY", 80, 120, true)
        end


    elseif ev == "LFG_LIST_APPLICANT_LIST_UPDATED" or ev == "LFG_LIST_APPLICANT_UPDATED" then
        NS.SaveLFGInfo()
        -- Wait a bit for group state sync and data loading during join transition
        if applicantTimer then applicantTimer:Cancel() end
        applicantTimer = C_Timer.NewTimer(0.3, function()
            if IsInRaid() and SolaQoLDB.disableApplicantAlertInRaid then
                return
            end
            if not IsInGroup() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or SolaQoLDB.enableApplicantAlertAll then
                if C_LFGList.HasActiveEntryInfo() then
                    local _, numAct = C_LFGList.GetNumApplicants()
                    numAct = numAct or 0
                    if numAct > St.prevAppCount then
                        NS.FlashClientIcon()
                        if not SolaQoLDB.muteNewApplicant then
                            if SolaQoLDB.customSoundNewApplicant and SolaQoLDB.customSoundNewApplicant ~= "" then
                                NS.SafePlaySoundFile(SolaQoLDB.customSoundNewApplicant, "Master", false)
                            else
                                PlaySound(SOUNDKIT.RAID_WARNING, "Master")
                            end
                        end
                        print("|cff00ff00" .. L.PARTY_RECRUIT .. "|r " .. L.MSG_NEW_APPLICANT .. string_format(L.APPLICANT_WAITING_FMT, numAct))
                        if PVEFrame and not PVEFrame:IsShown() then
                            if LFGListUtil_OpenBestWindow then
                                LFGListUtil_OpenBestWindow()
                            end
                        end
                    end
                    St.prevAppCount = numAct
                end
            end
        end)

    elseif ev == "LFG_LIST_SEARCH_RESULT_UPDATED" then
        local id = arg1
        if id then
            local info = C_LFGList.GetSearchResultInfo(id)
            if info then
                local fullTitle, hasCat, aID, rawName = NS.BuildLFGTitle(info.name, info.activityIDs, info.activityID)
                if NS.HasText(fullTitle) then
                    if hasCat or not NS.AppliedTitles[id] then
                        NS.AppliedTitles[id] = { title = fullTitle, hasCat = hasCat, aID = aID, rawName = rawName }
                    end
                end
            end
        end

    elseif ev == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        if C_LFGList.HasActiveEntryInfo() then
            local entry = C_LFGList.GetActiveEntryInfo()
            if entry then
                local fullTitle = NS.BuildLFGTitle(entry.name, entry.activityIDs, entry.activityID)
                NS.UpdateActiveTitle(fullTitle, false)
            end
        end

    elseif ev == "LFG_LIST_JOINED_GROUP" then
        local id, name = arg1, arg2
        local resolved = false

        if id and NS.AppliedTitles[id] then
            local data = NS.AppliedTitles[id]
            if data.hasCat then
                NS.UpdateActiveTitle(data.title, true)
                resolved = true
            else
                local catPrefix = ""
                if data.aID and data.aID > 0 then
                    local actInfo = C_LFGList.GetActivityInfoTable(data.aID)
                    if actInfo then
                        local cat = NS.CleanGarbage(actInfo.fullName)
                        if not NS.HasText(cat) then cat = NS.CleanGarbage(actInfo.shortName) end
                        if NS.HasText(cat) then catPrefix = cat .. " : " end
                    end
                end
                NS.UpdateActiveTitle(catPrefix .. data.rawName, true)
                resolved = true
            end
        end

        if not resolved and id then
            local info = C_LFGList.GetSearchResultInfo(id)
            if info then
                local fullTitle = NS.BuildLFGTitle(info.name, info.activityIDs, info.activityID)
                if NS.HasText(fullTitle) then
                    NS.UpdateActiveTitle(fullTitle, true)
                    resolved = true
                end
            end
        end

        if not resolved then
            local cleanName = NS.CleanGarbage(name)
            if NS.HasText(cleanName) then
                NS.UpdateActiveTitle(cleanName, true)
            end
        end

        if NS.GetGrpType() == "party" then
            local t = NS.GetGroupTitle()
            if NS.HasText(t) then
                NS.ShowPortalIfAvailable(t)
            end
        end


    elseif ev == "INSPECT_READY" then
        NS.HandleInspectReady(arg1)


    elseif ev == "TRADE_SHOW" or ev == "TRADE_CLOSED" or ev == "TRADE_REQUEST_CANCEL"
        or ev == "TRADE_ACCEPT_UPDATE" or ev == "TRADE_PLAYER_ITEM_CHANGED" or ev == "TRADE_TARGET_ITEM_CHANGED"
        or ev == "UI_INFO_MESSAGE" or ev == "UI_ERROR_MESSAGE" then
        NS.HandleTradeEvent(ev, arg1, arg2)
    end
end)


SLASH_PARTYGREETERLEAVE1 = "/ㅌㅌ"
SLASH_PARTYGREETERLEAVE2 = "/xx"
SlashCmdList["PARTYGREETERLEAVE"] = function()
    if IsInGroup() or IsInRaid() then
        C_PartyInfo.LeaveParty()
    else
        print("|cffff0000" .. L.NOTICE .. " " .. L.NO_GROUP .. "|r")
    end
end

SLASH_PARTYGREETERTEST1 = "/pgtest"
SlashCmdList["PARTYGREETERTEST"] = function(msg)
    local PortalBtn = NS.PortalBtn
    if msg == "full" then
        print("|cff00ccff[SolaQoL]|r 테스트 모드: 풀 파티 이벤트 시뮬레이션")
        NS.FlashClientIcon()
        if not SolaQoLDB.muteFullParty then
            if SolaQoLDB.customSoundFullParty and SolaQoLDB.customSoundFullParty ~= "" then
                NS.SafePlaySoundFile(SolaQoLDB.customSoundFullParty, "Master", false)
            else
                PlaySound(SOUNDKIT.READY_CHECK, "Master")
            end
        end
        local t = NS.GetGroupTitle()
        local testTitle = NS.HasText(t) and t or (PortalBtn and PortalBtn.lastTitle) or "하늘탑"
        print("|cffffff00" .. L.NOTICE .. " " .. L.MSG_FULL .. " - " .. testTitle .. "|r")
        if PortalBtn then
            PortalBtn.isTestMode = true
            PortalBtn.isFullTestMode = true
        end
        NS.ShowPortalIfAvailable(testTitle)
    elseif msg == "clear" then
        print(L.MSG_TEST_CLEAR or "|cff00ccff[SolaQoL]|r 테스트 모드: 쐐기 던전 완료 (귀환석 팝업)")
        if NS.TestClearPopup then
            NS.TestClearPopup()
        end
    elseif msg == "luston" then
        print("|cff00ccff[SolaQoL]|r " .. (SolaQoL_L.MSG_BLOODLUST_START or "Testing: Lust On"))
        PlaySoundFile("Interface\\AddOns\\SolaQoL\\Media\\" .. (SolaQoL_L.SOUND_BLOODLUST_START or "LustOn.mp3"), "Master")
    elseif msg == "lustoff" then
        if NS.AlertFrame_Show then
            NS.AlertFrame_Show(SolaQoL_L.MSG_BLOODLUST_READY or "Bloodlust Ready", {0.2, 1.0, 0.2})
        end
        print("|cff00ccff[SolaQoL]|r " .. (SolaQoL_L.MSG_BLOODLUST_READY or "Testing: Lust Ready"))
        if NS.TestBloodlustAlert then
            NS.TestBloodlustAlert("ready", false)
        end
    elseif msg and msg ~= "" then
        print(string_format(L.MSG_TEST_MODE or "|cff00ccff[SolaQoL]|r 테스트 모드: %s", msg))
        if PortalBtn then
            PortalBtn.isTestMode = true
            PortalBtn.isFullTestMode = false
        end
        NS.ShowPortalIfAvailable(msg)
    else
        print("|cff00ccff[SolaQoL]|r 사용법: /pgtest [던전명] | /pgtest full | /pgtest clear")
    end
end

SLASH_SOLAQOLTEST1 = "/sqt"
SlashCmdList["SOLAQOLTEST"] = SlashCmdList["PARTYGREETERTEST"]

SLASH_PARTYGREETERRESET1 = "/pgreset"
SlashCmdList["PARTYGREETERRESET"] = function()
    SolaQoLDB.portalOverlayPoint    = "TOP"
    SolaQoLDB.portalOverlayX        = 0
    SolaQoLDB.portalOverlayY        = -160
    SolaQoLDB.portalOverlayFontSize = 40
    SolaQoLDB.configScale           = 1.0

    if NS.PortalTestUI then
        NS.PortalTestUI:ClearAllPoints()
        NS.PortalTestUI:SetPoint("TOP", 0, -160)
    end
    if NS.PortalBtn and not InCombatLockdown() then
        NS.PortalBtn:ClearAllPoints()
        NS.PortalBtn:SetPoint("TOP", 0, -160)
    end

    local cfg = _G["SolaQoL_ModernConfig"]
    if cfg then
        cfg:ClearAllPoints()
        cfg:SetPoint("CENTER")
        if cfg:IsShown() then
            cfg:SetScale(1.0)
            local slider = _G["SolaQoL_ScaleSlider"]
            if slider then slider:SetValue(1.0) end
        end
    end

    print("|cff00ccff[SolaQoL]|r 오버레이 위치/크기가 기본값으로 초기화되었습니다. 변경사항을 확실히 저장하려면 /reload 를 입력해 주세요.")
end

SLASH_PARTYGREETSCONFIG1 = "/pg"
SLASH_PARTYGREETSCONFIG2 = "/ㅔㅎ"
SlashCmdList["PARTYGREETSCONFIG"] = function()
    local cfg = _G["SolaQoL_ModernConfig"]
    if cfg then cfg:Show() end
end

SLASH_SOLAQOLCONFIG1 = "/sq"
SLASH_SOLAQOLCONFIG2 = "/sol"
SLASH_SOLAQOLCONFIG3 = "/sola"
SLASH_SOLAQOLCONFIG4 = "/ㄴㅂ"
SlashCmdList["SOLAQOLCONFIG"] = SlashCmdList["PARTYGREETSCONFIG"]

-- Toggle auto-release spirit with /rez
SLASH_PARTYGREETERREZ1 = "/rez"
SlashCmdList["PARTYGREETERREZ"] = function()
    if not SolaQoLDB then return end
    SolaQoLDB.enableAutoRelease = not SolaQoLDB.enableAutoRelease
    NS.PrintToggleMsg(L.OPT_AUTO_RELEASE_SHORT or "Auto-Release Spirit", SolaQoLDB.enableAutoRelease)
    if NS.UpdateAutoReleaseHUD then
        NS.UpdateAutoReleaseHUD()
    end
end

-- Slash command to simulate trade logs
SLASH_PARTYGREETSTRADE1 = "/pgtrade"
SlashCmdList["PARTYGREETSTRADE"] = function()

    local testTarget  = "Testuser"
    local testSummary = string_format(
        "%s %s - [TEST] %s",
        L.TRADE_SUCCESS or "[거래 완료]",
        testTarget,
        string_format(L.TRADE_SUMMARY_BOTH or "%s 받음 / %s 보냄",
            "100" .. (L.TRADE_GOLD or " 골드 "),
            "100" .. (L.TRADE_GOLD or " 골드 "))
    )


    print(string_format("|cff00ccff[SolaQoL]|r %s", testSummary))


    if NS.AddTradeLog then
        NS.AddTradeLog(testSummary)
    end


    local cfg = _G["SolaQoL_ModernConfig"]
    if cfg and cfg:IsShown() then
        -- contentPanels is local to ConfigUI, trigger update via NS namespace.
        if NS.RefreshTradePanel then NS.RefreshTradePanel() end
    end

    print("|cff00ccff[SolaQoL]|r |cffffff00[TEST]|r Trade log test complete! Check Settings → Trade Notifications.")
end
