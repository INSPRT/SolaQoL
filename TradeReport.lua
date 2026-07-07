local ADDON_NAME, NS = ...
local L = NS.L

-- Track trades and announce results to chat

local TradeData = {
    targetName = "",
    playerMoney = 0,
    targetMoney = 0,
    playerItems = {},
    targetItems = {},
    statusTag = ""
}

local ERR_EVENTS = {
    [ERR_TRADE_BAG] = true, [ERR_TRADE_BAG_FULL] = true,
    [ERR_TRADE_BLOCKED_S] = true, [ERR_TRADE_BOUND_ITEM] = true,
    [ERR_TRADE_GROUND_ITEM] = true, [ERR_TRADE_MAX_COUNT_EXCEEDED] = true,
    [ERR_TRADE_QUEST_ITEM] = true, [ERR_TRADE_REQUEST_S] = true,
    [ERR_TRADE_TARGET_BAG_FULL] = true, [ERR_TRADE_TARGET_DEAD] = true,
    [ERR_TRADE_TOO_FAR] = true, [ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED] = true,
}



local function FormatNumberWithComma(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function FormatMoney(amount)
    if not amount or amount == 0 then return nil end
    local g = math.floor(amount / 10000)
    local s = math.floor((amount % 10000) / 100)
    local c = amount % 100
    local str = ""
    if g > 0 then str = str .. FormatNumberWithComma(g) .. L.TRADE_GOLD end
    if s > 0 then str = str .. s .. L.TRADE_SILVER end
    if c > 0 then str = str .. c .. L.TRADE_COPPER end
    return str:match("^%s*(.-)%s*$")
end

local function GetItemsString(items)
    local counts = {}
    local order = {}
    for i = 1, 6 do
        if items[i] then
            local name = items[i].name
            if not counts[name] then
                counts[name] = 0
                table.insert(order, name)
            end
            counts[name] = counts[name] + items[i].count
        end
    end
    if #order == 0 then return nil end
    
    local results = {}
    for _, name in ipairs(order) do
        if counts[name] > 1 then
            table.insert(results, name .. "x" .. counts[name])
        else
            table.insert(results, name)
        end
    end
    return table.concat(results, ", ")
end



local function UpdateTradeData()
    TradeData.playerMoney = GetPlayerTradeMoney()
    TradeData.targetMoney = GetTargetTradeMoney()
    wipe(TradeData.playerItems)
    wipe(TradeData.targetItems)
    for i = 1, 6 do
        local pName, _, pNum = GetTradePlayerItemInfo(i)
        if pName then TradeData.playerItems[i] = { name = pName, count = pNum or 1 } end
        
        local tName, _, tNum = GetTradeTargetItemInfo(i)
        if tName then TradeData.targetItems[i] = { name = tName, count = tNum or 1 } end
    end
end

local function BuildTradeSummary()
    local pMoney = FormatMoney(TradeData.playerMoney)
    local tMoney = FormatMoney(TradeData.targetMoney)
    local pItems = GetItemsString(TradeData.playerItems)
    local tItems = GetItemsString(TradeData.targetItems)
    
    local gaveStr = ""
    local recvStr = ""
    
    if pMoney or pItems then
        gaveStr = (pMoney or "") .. (pMoney and pItems and " + " or "") .. (pItems or "")
    end
    
    if tMoney or tItems then
        recvStr = (tMoney or "") .. (tMoney and tItems and " + " or "") .. (tItems or "")
    end
    
    local summary = ""
    if gaveStr ~= "" and recvStr ~= "" then
        summary = string.format(L.TRADE_SUMMARY_BOTH, recvStr, gaveStr)
    elseif gaveStr ~= "" then
        summary = string.format(L.TRADE_SUMMARY_GAVE, gaveStr)
    elseif recvStr ~= "" then
        summary = string.format(L.TRADE_SUMMARY_RECV, recvStr)
    else
        summary = L.TRADE_SUMMARY_EMPTY
    end
    return summary
end

local function AnnounceTrade(statusLabel, summaryStr)
    if not SolaQoLDB.enableTradeReport then return end
    
    local target = TradeData.targetName or L.TRADE_WITH_UNKNOWN
    local msgForChat = string.format("%s %s - %s", statusLabel, target, summaryStr)
    local finalMsg = string.format("|cff00ccff[SolaQoL]|r %s", msgForChat)
    
    local isSentToOthers = false
    
    if SolaQoLDB.tradeWhisper and TradeData.targetName and TradeData.targetName ~= "" then
        SendChatMessage(string.format("[SolaQoL] %s", msgForChat), "WHISPER", nil, TradeData.targetName)
        isSentToOthers = true
    end
    
    if SolaQoLDB.tradeParty then
        if IsInRaid() then
            SendChatMessage(string.format("[SolaQoL] %s", msgForChat), "RAID")
            isSentToOthers = true
        elseif IsInGroup() then
            SendChatMessage(string.format("[SolaQoL] %s", msgForChat), "PARTY")
            isSentToOthers = true
        end
    end
    
    -- Only print to self if we didn't already send it to group or whisper.
    if not isSentToOthers then
        print(finalMsg)
    end

    -- Save trade log to DB
    if NS.AddTradeLog then
        NS.AddTradeLog(msgForChat)
    end
end

-- Event processor dispatched from main loop

local function HandleTradeEvent(ev, arg1, arg2)
    if ev == "TRADE_SHOW" then
        local initialName = GetUnitName("npc", true)
        TradeData.targetName = (initialName and initialName ~= "") and initialName or ""
        
        C_Timer.After(0.1, function()
            if not TradeData.targetName or TradeData.targetName == "" then
                local tName = GetUnitName("npc", true)
                if not tName or tName == "" then
                    if TradeFrameRecipientNameText then tName = TradeFrameRecipientNameText:GetText() end
                end
                if not tName or tName == "" then tName = L.TRADE_WITH_UNKNOWN or "알 수 없음" end
                TradeData.targetName = tName
            end
        end)
        TradeData.playerMoney = 0
        TradeData.targetMoney = 0
        wipe(TradeData.playerItems)
        wipe(TradeData.targetItems)
        TradeData.statusTag = ""

    elseif ev == "TRADE_CLOSED" then
        TradeData.statusTag = TradeData.statusTag .. "1"

    elseif ev == "TRADE_REQUEST_CANCEL" then
        TradeData.statusTag = TradeData.statusTag .. "2"

    elseif ev == "TRADE_ACCEPT_UPDATE" or ev == "TRADE_PLAYER_ITEM_CHANGED" or ev == "TRADE_TARGET_ITEM_CHANGED" then
        UpdateTradeData()

    elseif ev == "UI_INFO_MESSAGE" then
        local errorName = GetGameMessageInfo(arg1)
        if errorName == "ERR_TRADE_COMPLETE" then
            local summary = BuildTradeSummary()
            AnnounceTrade(L.TRADE_SUCCESS, summary)
        elseif errorName == "ERR_TRADE_CANCELLED" then
            local reason = L.TRADE_REASON_UNKNOWN
            local lastTag = string.sub(TradeData.statusTag, -1)
            
            if lastTag == "2" then reason = UnitName("player") .. " " .. L.TRADE_REASON_ME
            elseif lastTag == "1" then reason = (TradeData.targetName or "") .. " " .. L.TRADE_REASON_TARGET
            end
            
            AnnounceTrade(L.TRADE_CANCELLED, "<" .. reason .. ">")
        end

    elseif ev == "UI_ERROR_MESSAGE" then
        if ERR_EVENTS[arg2] then
            AnnounceTrade(L.TRADE_ERROR_HDR, "<" .. arg2 .. ">")
        end
    end
end


NS.TradeData        = TradeData
NS.UpdateTradeData  = UpdateTradeData
NS.BuildTradeSummary = BuildTradeSummary
NS.AnnounceTrade    = AnnounceTrade
NS.HandleTradeEvent = HandleTradeEvent
