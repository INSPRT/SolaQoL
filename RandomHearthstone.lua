local ADDON_NAME, NS = ...

-- Hardcoded list of known Hearthstone toys
local HEARTHSTONE_TOYS = {
    54452,  -- Ethereal Portal
    64488,  -- The Innkeeper's Daughter
    93672,  -- Dark Portal
    142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
    180290, -- Night Fae Hearthstone
    182773, -- Necrolord Hearthstone
    183716, -- Venthyr Sinner's Hearthstone
    184353, -- Kyrian Hearthstone
    188952, -- Domination's Calling
    190196, -- Enlightened Hearthstone
    190237, -- Broker Translocation Matrix
    193588, -- Timewalker's Hearthstone
    200630, -- Ohn'ir Windsage's Hearthstone
    206195, -- Path of the Naaru
    208704, -- Deepdweller's Earthen Hearthstone
    209035, -- Hearthstone of the Flame
    212337, -- Stone of the Hearth
    228940, -- Notorious Thread's Hearthstone
    235016, -- Redeployment Module
    265100, -- Corewarden's Hearthstone
}

-- Invisible SecureActionButton for casting
local btn = CreateFrame("Button", "PGRandomHearthstoneBtn", UIParent, "SecureActionButtonTemplate")
btn:RegisterForClicks("AnyUp", "AnyDown")

local lastToyID = nil
local DYNAMIC_HEARTHSTONES = {}
local hasScannedToys = false

local isScanning = false
local pendingToys = {}

local function ScanForHearthstones()
    if hasScannedToys or isScanning then return end
    isScanning = true
    
    -- Instantly verify hardcoded toys first so they are immediately available
    for _, i in ipairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy(i) then
            local _, toyName = C_ToyBox.GetToyInfo(i)
            if not toyName then
                if C_Item and C_Item.RequestLoadItemDataByID then
                    C_Item.RequestLoadItemDataByID(i)
                end
            end
        end
    end

    local currentID = 1
    local maxItemID = 350000
    local CHUNK_SIZE = 5000

    -- Asynchronously scan for unknown/future hearthstone toys without freezing the client
    C_Timer.NewTicker(0.05, function(ticker)
        local limit = currentID + CHUNK_SIZE
        if limit > maxItemID then limit = maxItemID end
        
        for i = currentID, limit do
            if PlayerHasToy(i) then
                if i ~= 140192 and i ~= 110560 then -- Exclude Dalaran & Garrison
                    local _, toyName = C_ToyBox.GetToyInfo(i)
                    local _, spellID = GetItemSpell(i)
                    
                    if not toyName then
                        if C_Item and C_Item.RequestLoadItemDataByID then
                            C_Item.RequestLoadItemDataByID(i)
                        end
                        table.insert(pendingToys, i)
                    else
                        if spellID ~= 1299515 then -- Exclude non-standard return beacons
                            if string.find(toyName, "귀환") or string.find(toyName, "Hearthstone") or string.find(toyName, "Portal") or spellID == 1299014 then
                                local isKnown = false
                                for _, knownID in ipairs(HEARTHSTONE_TOYS) do
                                    if knownID == i then isKnown = true break end
                                end
                                if not isKnown then
                                    local inDynamic = false
                                    for _, dID in ipairs(DYNAMIC_HEARTHSTONES) do
                                        if dID == i then inDynamic = true break end
                                    end
                                    if not inDynamic then
                                        table.insert(DYNAMIC_HEARTHSTONES, i)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        currentID = limit + 1
        if currentID > maxItemID then
            ticker:Cancel()
            
            if #pendingToys > 0 then
                -- Periodically check pending toys until their data loads from the server
                C_Timer.NewTicker(1.0, function(retryTicker)
                    for idx = #pendingToys, 1, -1 do
                        local toyID = pendingToys[idx]
                        local _, toyName = C_ToyBox.GetToyInfo(toyID)
                        local _, spellID = GetItemSpell(toyID)
                        
                        if toyName then
                            table.remove(pendingToys, idx)
                            if spellID ~= 1299515 then
                                if string.find(toyName, "귀환") or string.find(toyName, "Hearthstone") or string.find(toyName, "Portal") or spellID == 1299014 then
                                    local isKnown = false
                                    for _, knownID in ipairs(HEARTHSTONE_TOYS) do
                                        if knownID == toyID then isKnown = true break end
                                    end
                                    if not isKnown then
                                        local inDynamic = false
                                        for _, dID in ipairs(DYNAMIC_HEARTHSTONES) do
                                            if dID == toyID then inDynamic = true break end
                                        end
                                        if not inDynamic then
                                            table.insert(DYNAMIC_HEARTHSTONES, toyID)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if #pendingToys == 0 then
                        retryTicker:Cancel()
                        hasScannedToys = true
                        isScanning = false
                        
                        local popup = _G["SolaQoLHearthstonePopup"]
                        if popup and popup:IsShown() then
                            -- Soft hint to reopen
                        end
                    end
                end)
            else
                hasScannedToys = true
                isScanning = false
            end
        end
    end)
end

local function IsHearthstoneDisabled(idStr)
    if not SolaQoLDB then return idStr == "6948" end
    if not SolaQoLDB.disabledHearthstones then return idStr == "6948" end
    
    local disabled = SolaQoLDB.disabledHearthstones[idStr]
    if disabled == nil then
        return idStr == "6948"
    end
    return disabled
end

local history = {}

local function UpdateRandomHearthstone(targetBtn)
    targetBtn = targetBtn or btn
    if not hasScannedToys then
        ScanForHearthstones()
    end
    
    local ownedItems = {}
    if GetItemCount(6948) > 0 and not IsHearthstoneDisabled("6948") then
        table.insert(ownedItems, "item:6948")
    end
    
    for _, itemID in ipairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy(itemID) and not IsHearthstoneDisabled(tostring(itemID)) then
            table.insert(ownedItems, "toy:" .. itemID)
        end
    end
    for _, itemID in ipairs(DYNAMIC_HEARTHSTONES) do
        if PlayerHasToy(itemID) and not IsHearthstoneDisabled(tostring(itemID)) then
            table.insert(ownedItems, "toy:" .. itemID)
        end
    end
    
    if #ownedItems == 0 then
        targetBtn:SetAttribute("type", "macro")
        targetBtn:SetAttribute("macrotext", "/use item:6948")
        if targetBtn.icon then targetBtn.icon:SetTexture(134414) end
        if targetBtn.label then targetBtn.label:SetText("귀환석") end
        return
    end
    
    if #ownedItems == 1 then
        local prefix, id = strsplit(":", ownedItems[1])
        targetBtn:SetAttribute("type", "macro")
        targetBtn:SetAttribute("macrotext", "/use item:" .. id)
        if targetBtn.icon then
            local itemID = tonumber(id)
            local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
            if not itemName then
                local _, toyName, icon = C_ToyBox.GetToyInfo(itemID)
                itemName = toyName
                itemIcon = icon
            end
            targetBtn.icon:SetTexture(itemIcon or 134414)
            if targetBtn.label then 
                targetBtn.label:SetText(itemName or (prefix == "toy" and "장난감 귀환석" or "귀환석")) 
            end
        end
        return
    end
    
    local maxHistory = 1
    if #ownedItems >= 4 then
        maxHistory = math.floor(#ownedItems / 2)
    end
    
    local validItems = {}
    for _, val in ipairs(ownedItems) do
        local inHistory = false
        for i = 1, maxHistory do
            if history[i] == val then
                inHistory = true
                break
            end
        end
        if not inHistory then
            table.insert(validItems, val)
        end
    end
    
    if #validItems == 0 then
        validItems = ownedItems
    end
    
    local randIdx = math.random(1, #validItems)
    local nextItem = validItems[randIdx]
    
    table.insert(history, 1, nextItem)
    while #history > maxHistory do
        table.remove(history)
    end
    
    local prefix, id = strsplit(":", nextItem)
    targetBtn:SetAttribute("type", "macro")
    targetBtn:SetAttribute("macrotext", "/use item:" .. id)
    if targetBtn.icon then
        local itemID = tonumber(id)
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
        if not itemName then
            local _, toyName, icon = C_ToyBox.GetToyInfo(itemID)
            itemName = toyName
            itemIcon = icon
        end
        targetBtn.icon:SetTexture(itemIcon or 134414)
        if targetBtn.label then 
            targetBtn.label:SetText(itemName or (prefix == "toy" and "장난감 귀환석" or "귀환석")) 
        end
    end
end

btn:SetScript("PreClick", function(self, button, down)
    if not down then return end
    if InCombatLockdown() then return end
    if SolaQoLDB and SolaQoLDB.enableRandomHearthstone == false then
        self:SetAttribute("macrotext", "")
        return
    end
    
    -- Prevent client lockouts by neutering the macro if casting would fail
    if UnitIsDeadOrGhost("player") or UnitCastingInfo("player") or UnitChannelInfo("player") then
        self:SetAttribute("macrotext", "")
        return
    end
    
    local now = GetTime()
    local gcdStart, gcdDuration
    if C_Spell and C_Spell.GetSpellCooldown then
        local cdInfo = C_Spell.GetSpellCooldown(61304)
        if cdInfo then
            gcdStart = cdInfo.startTime
            gcdDuration = cdInfo.duration
        end
    elseif GetSpellCooldown then
        gcdStart, gcdDuration = GetSpellCooldown(61304)
    end
    if gcdStart and gcdDuration and gcdDuration > 0 and (gcdStart + gcdDuration > now) then
        self:SetAttribute("macrotext", "")
        return
    end
    
    local start, duration
    if C_Container and C_Container.GetItemCooldown then
        start, duration = C_Container.GetItemCooldown(6948)
    elseif GetItemCooldown then
        start, duration = GetItemCooldown(6948)
    end
    if start and duration and duration > 0 and (start + duration > now) then
        self:SetAttribute("macrotext", "")
        return
    end
    
    UpdateRandomHearthstone()
end)

function NS.GetOwnedHearthstones()
    if not hasScannedToys then
        ScanForHearthstones()
    end
    
    local list = {}
    
    if GetItemCount(6948) > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(6948)
        table.insert(list, {
            id = 6948,
            type = "item",
            name = itemName or "귀환석",
            icon = itemIcon or 134414,
        })
    end
    
    local function AddToy(itemID)
        if PlayerHasToy(itemID) then
            local _, toyName, icon = C_ToyBox.GetToyInfo(itemID)
            table.insert(list, {
                id = itemID,
                type = "toy",
                name = toyName or ("장난감 " .. itemID),
                icon = icon or 134414,
            })
        end
    end
    
    for _, itemID in ipairs(HEARTHSTONE_TOYS) do
        AddToy(itemID)
    end
    
    for _, itemID in ipairs(DYNAMIC_HEARTHSTONES) do
        AddToy(itemID)
    end
    
    return list
end

-- ===== Mythic+ Clear Popup Button =====
local popupBtn = CreateFrame("Button", "PGRandomHearthstonePopupBtn", UIParent, "SecureActionButtonTemplate, BackdropTemplate")
popupBtn:SetSize(144, 85)
popupBtn:SetPoint("CENTER", 0, 120)
popupBtn:SetFrameStrata("DIALOG")
popupBtn:Hide()

popupBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
popupBtn:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
popupBtn:SetBackdropBorderColor(0, 0, 0, 1)

local goldLine = popupBtn:CreateTexture(nil, "OVERLAY")
goldLine:SetHeight(2)
goldLine:SetPoint("TOPLEFT", popupBtn, "TOPLEFT", 1, -1)
goldLine:SetPoint("TOPRIGHT", popupBtn, "TOPRIGHT", -1, -1)
goldLine:SetColorTexture(0.996, 0.792, 0.341, 1)

popupBtn.icon = popupBtn:CreateTexture(nil, "ARTWORK")
popupBtn.icon:SetSize(38, 38)
popupBtn.icon:SetPoint("TOP", 0, -14)
popupBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local label = popupBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
label:SetPoint("TOP", popupBtn.icon, "BOTTOM", 0, -8)
popupBtn.label = label

popupBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
end)
popupBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
end)

popupBtn:RegisterForDrag("LeftButton")
popupBtn:SetMovable(true)
popupBtn:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() and not InCombatLockdown() then
        self:StartMoving()
    end
end)
popupBtn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    if SolaQoLDB then
        SolaQoLDB.hearthPopupPoint = point
        SolaQoLDB.hearthPopupRelative = relativePoint
        SolaQoLDB.hearthPopupX = xOfs
        SolaQoLDB.hearthPopupY = yOfs
    end
end)

popupBtn:RegisterForClicks("AnyDown")
popupBtn:SetScript("PreClick", function(self, button, down)
    if InCombatLockdown() then return end
    if button == "RightButton" then
        self:SetAttribute("type", nil)
        self:Hide()
    elseif button == "LeftButton" then
        if IsAltKeyDown() then
            self:SetAttribute("type", nil)
        else
            self:SetAttribute("type", "macro")
        end
    end
end)
popupBtn:SetScript("PostClick", function(self, button, down)
    -- Persists until successfully casted or right-clicked
end)

local pendingClearPopup = false
local eventFrame

local function ShowClearPopup()
    if SolaQoLDB and SolaQoLDB.enableHearthstoneOnClear ~= false and SolaQoLDB.enableRandomHearthstone ~= false then
        if InCombatLockdown() then
            pendingClearPopup = true
            if eventFrame then eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") end
            return
        end
        
        if SolaQoLDB.hearthPopupPoint then
            popupBtn:ClearAllPoints()
            popupBtn:SetPoint(SolaQoLDB.hearthPopupPoint, UIParent, SolaQoLDB.hearthPopupRelative or SolaQoLDB.hearthPopupPoint, SolaQoLDB.hearthPopupX or 0, SolaQoLDB.hearthPopupY or 120)
        else
            popupBtn:ClearAllPoints()
            popupBtn:SetPoint("CENTER", 0, 120)
        end
        UpdateRandomHearthstone(popupBtn)
        popupBtn:Show()
    end
end

eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
local lastRerollTime = 0
eventFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "CHALLENGE_MODE_COMPLETED" then
        if not hasScannedToys then
            ScanForHearthstones()
        end
        C_Timer.After(5, function()
            ShowClearPopup()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingClearPopup then
            pendingClearPopup = false
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            ShowClearPopup()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not hasScannedToys then
            ScanForHearthstones()
        end
        if popupBtn:IsShown() and not InCombatLockdown() then
            popupBtn:Hide()
        end
    elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED") and unit == "player" then
        if popupBtn:IsShown() and not InCombatLockdown() then
            local now = GetTime()
            if now - lastRerollTime > 0.5 then
                lastRerollTime = now
                UpdateRandomHearthstone(popupBtn)
            end
        end
    end
end)

function NS.TestClearPopup()
    ShowClearPopup()
end
