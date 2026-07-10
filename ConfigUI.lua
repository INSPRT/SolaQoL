-- Config UI panel with glassmorphism style
local ADDON_NAME, NS = ...
local L = NS.L

local pairs, ipairs        = pairs, ipairs
local unpack               = unpack
local math_floor           = math.floor
local math_min, math_max   = math.min, math.max
local string_find          = string.find
local string_format        = string.format
local pcall                = pcall


local MASK_PATH = "Interface\\AddOns\\SolaQoL\\RoundMask"


local C = {
    -- Backgrounds (RGBA)
    bgMain     = { 0.078, 0.071, 0.067, 0.80 },
    bgSidebar  = { 0.050, 0.047, 0.043, 0.90 },
    bgSelected = { 0.165, 0.153, 0.145, 0.90 },
    bgInput    = { 0.098, 0.090, 0.086, 1.00 },
    bgHover    = { 0.130, 0.122, 0.114, 0.70 },
    bgBtn      = { 0.250, 0.240, 0.230, 0.90 },

    -- Foregrounds (RGB)
    fgMain     = { 0.941, 0.929, 0.910 },
    fgDim      = { 0.541, 0.522, 0.502 },
    fgDisabled = { 0.480, 0.460, 0.440 },

    -- Accents (RGB)
    gold       = { 0.831, 0.655, 0.271 },
    goldBeige  = { 0.825, 0.725, 0.485 },
    goldMuted  = { 0.623, 0.491, 0.203 },
    teal       = { 0.353, 0.749, 0.690 },
    mint       = { 0.420, 0.749, 0.541 },
    rose       = { 0.812, 0.400, 0.475 },
    amber      = { 0.878, 0.565, 0.314 },
    lavender   = { 0.608, 0.557, 0.769 },

    -- Glass effects (RGBA)
    rimLight   = { 1.0, 1.0, 1.0, 0.07 },
    glassLine  = { 1.0, 1.0, 1.0, 0.06 },
}


local FRAME_W     = 700
local FRAME_H     = 520
local SIDEBAR_W   = 160
local TITLE_H     = 38
local FOOTER_H    = 44
local CONTENT_W   = FRAME_W - SIDEBAR_W - 1
local CONTENT_H   = FRAME_H - TITLE_H - FOOTER_H
local BTN_H       = 34
local PAD         = 20
local INDENT      = 24

-- Apply round mask to target texture
local ModernConfig  -- forward

local function ApplyRoundMask(texture)
    local mask = ModernConfig:CreateMaskTexture()
    mask:SetAllPoints(ModernConfig)
    mask:SetTexture(MASK_PATH, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    texture:AddMaskTexture(mask)
end


local function CreateCheck(parent, label)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(14, 14)

    local border = btn:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(1, 1, 1, 0.10)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.8)
    btn._bg = bg

    local check = btn:CreateTexture(nil, "ARTWORK")
    check:SetPoint("CENTER")
    check:SetSize(8, 8)
    check:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
    check:Hide()

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    text:SetText(label)
    text:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])
    btn.text = text

    btn.check     = check
    btn.isChecked = false

    btn:SetScript("OnClick", function(self)
        self.isChecked = not self.isChecked
        if self.isChecked then check:Show() else check:Hide() end
        if self.onClick then self.onClick(self.isChecked) end
    end)

    btn:SetScript("OnEnter", function()
        if not btn.isChecked and btn:IsEnabled() then
            bg:SetColorTexture(C.bgHover[1], C.bgHover[2], C.bgHover[3], 0.8)
        end
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.8)
    end)

    function btn:SetChecked(state)
        self.isChecked = state
        if state then check:Show() else check:Hide() end
    end

    function btn:SetEnabledState(enabled)
        if enabled then
            self:Enable()
            text:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])
            check:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
            border:SetColorTexture(1, 1, 1, 0.10)
        else
            self:Disable()
            text:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])
            check:SetColorTexture(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3], 0.5)
            border:SetColorTexture(1, 1, 1, 0.04)
        end
    end

    function btn:GetChecked() return self.isChecked end

    return btn
end


local function CreateEditBox(parent, width)
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(width, 26)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlight")
    eb:SetTextInsets(8, 8, 0, 0)
    eb:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    eb:SetBackdropColor(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.9)
    eb:SetBackdropBorderColor(1, 1, 1, 0.08)

    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C.teal[1], C.teal[2], C.teal[3], 0.6)
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 0.08)
    end)

    return eb
end


local function PlaySoundPreview(val, defaultSoundKit)
    if not val or val == "" or val == "custom" then return end
    
    if val == "default" and defaultSoundKit then
        PlaySound(defaultSoundKit, "Master")
        return
    end

    local SOUND_PRESETS = {
        whisper      = 3081,    -- gentle ding
        ready_check  = 843,
        raid_warning = 8959,
        level_up     = 1422,
        alarm        = 11466,
    }

    if SOUND_PRESETS[val] then
        PlaySound(SOUND_PRESETS[val], "Master")
    else
        local path = val
        local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
        if lsm then
            path = lsm:Fetch("sound", val) or val
        end
        if path == "KeywordSound" then
            path = "Interface\\AddOns\\SolaQoL\\Media\\KeywordSound.mp3"
        end
        if path and path ~= "" then
            local lowerPath = string.lower(path)
            if string.find(lowerPath, "\\") or string.match(lowerPath, "%.mp3$") or string.match(lowerPath, "%.ogg$") or string.match(lowerPath, "%.wav$") then
                PlaySoundFile(path, "Master")
            else
                local kitId = tonumber(path)
                if kitId then
                    PlaySound(kitId, "Master")
                end
            end
        end
    end
end


local function CreateDropdown(parent, width, getOptionsFunc, isSound, defaultSoundKit)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 26)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.9)
    btn:SetBackdropBorderColor(1, 1, 1, 0.08)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", btn, "LEFT", 8, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])
    btn.text = text

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    arrow:SetText("▼")
    arrow:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
    btn.arrow = arrow

    btn:SetScript("OnClick", function(self)
        if self.menu and self.menu:IsShown() then
            self.menu:Hide()
            return
        end
        if self.menu then
            self.menu:Show()
            return
        end

        local options = getOptionsFunc()
        local menu = CreateFrame("Frame", nil, self, "BackdropTemplate")
        menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        menu:SetWidth(width)
        menu:SetHeight(math.min(#options * 22 + 4, 180))
        menu:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        menu:SetBackdropColor(C.bgMain[1], C.bgMain[2], C.bgMain[3], 0.95)
        menu:SetBackdropBorderColor(0, 0, 0, 0.65)
        menu:SetFrameStrata("TOOLTIP")

        local scrollFrame = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -2)
        scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -26, 2)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(width - 28, #options * 22)
        scrollFrame:SetScrollChild(scrollChild)

        local lastBtn = nil
        for _, opt in ipairs(options) do
            local item = CreateFrame("Button", nil, scrollChild)
            item:SetSize(width - 28, 22)
            if not lastBtn then
                item:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            else
                item:SetPoint("TOPLEFT", lastBtn, "BOTTOMLEFT", 0, 0)
            end

            local itemBg = item:CreateTexture(nil, "BACKGROUND")
            itemBg:SetAllPoints()
            itemBg:SetColorTexture(C.bgSelected[1], C.bgSelected[2], C.bgSelected[3], 0.8)
            itemBg:Hide()

            local itemText = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            itemText:SetPoint("LEFT", item, "LEFT", 8, 0)
            if isSound and opt.value ~= "custom" and opt.value ~= "" then
                itemText:SetPoint("RIGHT", item, "RIGHT", -24, 0)
            else
                itemText:SetPoint("RIGHT", item, "RIGHT", -2, 0)
            end
            itemText:SetJustifyH("LEFT")
            itemText:SetText(opt.name)
            itemText:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])

            item:SetScript("OnEnter", function() itemBg:Show() end)
            item:SetScript("OnLeave", function() itemBg:Hide() end)
            item:SetScript("OnClick", function()
                btn.text:SetText(opt.name)
                menu:Hide()
                if btn.onSelect then btn.onSelect(opt.value) end
            end)

            if isSound and opt.value ~= "custom" and opt.value ~= "" then
                local playBtn = CreateFrame("Button", nil, item)
                playBtn:SetSize(20, 18)
                playBtn:SetPoint("RIGHT", item, "RIGHT", -4, 0)

                local playText = playBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                playText:SetPoint("CENTER")
                playText:SetText("▶")
                playText:SetTextColor(0.8, 0.6, 0.4)
                playBtn.text = playText

                playBtn:SetScript("OnEnter", function()
                    playText:SetTextColor(1, 0.8, 0.6)
                    itemBg:Show()
                end)
                playBtn:SetScript("OnLeave", function()
                    playText:SetTextColor(0.8, 0.6, 0.4)
                    itemBg:Hide()
                end)
                playBtn:SetScript("OnClick", function()
                    PlaySoundPreview(opt.value, defaultSoundKit)
                end)
            end

            lastBtn = item
        end
        self.menu = menu
    end)

    function btn:SetValue(val)
        local options = getOptionsFunc()
        for _, opt in ipairs(options) do
            if opt.value == val then
                self.text:SetText(opt.name)
                return
            end
        end
        self.text:SetText(options[1] and options[1].name or "Select")
    end

    function btn:SetEnabledState(enabled)
        if enabled then
            self:Enable()
            self.text:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])
            self.arrow:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
            self:SetBackdropBorderColor(1, 1, 1, 0.08)
        else
            self:Disable()
            self.text:SetTextColor(0.4, 0.4, 0.4)
            self.arrow:SetTextColor(0.4, 0.4, 0.4)
            self:SetBackdropBorderColor(1, 1, 1, 0.03)
            if self.menu and self.menu:IsShown() then self.menu:Hide() end
        end
    end

    return btn
end


local function CreateBtn(parent, text, width, colorKey)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 26)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    local r, g, b = C.bgBtn[1], C.bgBtn[2], C.bgBtn[3]
    -- Muted palette color keys
    if colorKey == "brown" then       -- Save / Confirm
        r, g, b = 0.40, 0.22, 0.22
    elseif colorKey == "amber" then   -- Play / Media
        r, g, b = 0.46, 0.36, 0.26
    elseif colorKey == "mint" then    -- Active / ON
        r, g, b = 0.22, 0.42, 0.32
    elseif colorKey == "rose" then    -- Danger / OFF
        r, g, b = 0.48, 0.22, 0.26
    elseif colorKey == "gold" then    -- Generic gold accent
        r, g, b = C.gold[1] * 0.48, C.gold[2] * 0.48, C.gold[3] * 0.48
    elseif colorKey == "teal" then    -- Legacy teal
        r, g, b = C.teal[1] * 0.42, C.teal[2] * 0.42, C.teal[3] * 0.42
    end
    btn._r, btn._g, btn._b = r, g, b

    btn:SetBackdropColor(r, g, b, 0.85)
    btn:SetBackdropBorderColor(0, 0, 0, 0.65)

    local t = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t:SetPoint("CENTER")
    t:SetText(text)
    t:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])
    btn.label = t

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(
            math_min(1, self._r * 1.5),
            math_min(1, self._g * 1.5),
            math_min(1, self._b * 1.5), 0.95)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(self._r, self._g, self._b, 0.85)
    end)

    return btn
end


local function CreateSlider(parent, label, minVal, maxVal, step, isInteger)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(180, 48)

    local labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])

    local valText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valText:SetPoint("TOPRIGHT", 0, 0)
    valText:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

    local slider = CreateFrame("Slider", nil, frame)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("BOTTOMLEFT", 0, 14)
    slider:SetPoint("BOTTOMRIGHT", 0, 14)
    slider:SetHeight(8)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local sliderBg = slider:CreateTexture(nil, "BACKGROUND")
    sliderBg:SetAllPoints()
    sliderBg:SetColorTexture(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.8)

    local sliderFill = slider:CreateTexture(nil, "ARTWORK")
    sliderFill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    sliderFill:SetHeight(8)
    sliderFill:SetColorTexture(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.35)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 16)
    thumb:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
    slider:SetThumbTexture(thumb)

    local lowText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    lowText:SetText(isInteger and tostring(minVal) or string_format("%.2fx", minVal))
    lowText:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])

    local highText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    highText:SetText(isInteger and tostring(maxVal) or string_format("%.2fx", maxVal))
    highText:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])

    local function UpdateFill(value)
        local mn, mx = slider:GetMinMaxValues()
        local ratio = (mx > mn) and ((value - mn) / (mx - mn)) or 0
        local w = slider:GetWidth()
        if w and w > 0 then sliderFill:SetWidth(math_max(1, w * ratio)) end
    end

    slider:SetScript("OnValueChanged", function(_, value)
        local displayVal
        if isInteger then displayVal = math_floor(value / step + 0.5) * step
        else displayVal = math_floor(value * 20 + 0.5) / 20 end
        valText:SetText(isInteger and tostring(displayVal) or string_format("%.2fx", displayVal))
        UpdateFill(displayVal)
        if frame.onValueChanged then frame.onValueChanged(displayVal) end
    end)

    slider:SetScript("OnSizeChanged", function(self) UpdateFill(self:GetValue()) end)

    function frame:SetValue(val)
        slider:SetValue(val)
        local displayVal
        if isInteger then displayVal = math_floor(val / step + 0.5) * step
        else displayVal = math_floor(val * 20 + 0.5) / 20 end
        valText:SetText(isInteger and tostring(displayVal) or string_format("%.2fx", displayVal))
        UpdateFill(displayVal)
    end

    frame.slider = slider
    return frame
end


local function CreateSectionHeader(parent, text)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(20)

    local t = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("LEFT", 0, 0)
    t:SetText(text)
    t:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

    local line = frame:CreateTexture(nil, "BACKGROUND")
    line:SetHeight(1)
    line:SetPoint("LEFT", t, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    line:SetColorTexture(1, 1, 1, 0.06)

    return frame
end


local function CreateSoundRow(parent, labelText, dbKeyPath, dbKeyMute,
                              defaultSoundKit, savedMsg, onMsg, offMsg)
    local row = {}

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetText(labelText)
    label:SetTextColor(1, 1, 1)
    row.label = label

    local function GetOptions()
        local opts = {
            { name = L.SOUND_OPT_CUSTOM or "Custom Path", value = "custom" },
            { name = L.SOUND_OPT_DEFAULT or "Default Sound", value = "default" },
        }
        for i = 1, 9 do
            table.insert(opts, {
                name = string.format(L.SOUND_NOTIFICATION_FMT or "Sound %d", i),
                value = "FreeNotification" .. i
            })
        end
        local seen = {}
        for _, o in ipairs(opts) do
            seen[o.name] = true
            seen[o.value] = true
        end

        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            for _, name in ipairs(LSM:List("sound")) do
                if not seen[name] then
                    seen[name] = true
                    local path = LSM:Fetch("sound", name)
                    if path and not seen[path] then
                        seen[path] = true
                        table.insert(opts, { name = name, value = name })
                    end
                end
            end
        end
        return opts
    end

    local dd = CreateDropdown(parent, 180, GetOptions, true, defaultSoundKit)
    dd:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    row.dd = dd

    local box = CreateEditBox(parent, 210)
    box:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -6)
    row.box = box

    local saveBtn = CreateBtn(parent, L.SAVE, 50, "brown")
    saveBtn:SetPoint("LEFT", box, "RIGHT", 4, 0)
    row.saveBtn = saveBtn

    saveBtn:SetScript("OnClick", function()
        local text = box:GetText() or ""
        text = string.gsub(text, "^%s*(.-)%s*$", "%1")
        text = string.gsub(text, "/", "\\")
        
        if text == "" then
            print("|cffff0000[SolaQoL]|r " .. (L.SOUND_ERROR_EMPTY or "사운드 경로를 입력해 주세요."))
            return
        end
        
        local lowerPath = string.lower(text)
        local isValid = false
        if string.find(lowerPath, "^interface\\") then
            if string.match(lowerPath, "%.mp3$") or string.match(lowerPath, "%.ogg$") or string.match(lowerPath, "%.wav$") then
                isValid = true
            end
        end
        
        if not isValid then
            print("|cffff0000[SolaQoL]|r " .. (L.SOUND_ERROR_INVALID or "올바르지 않은 사운드 경로 형식입니다."))
            return
        end
        
        box:SetText(text)
        SolaQoLDB[dbKeyPath] = text
        box:ClearFocus()
        print("|cff00ccff[SolaQoL]|r " .. savedMsg)
    end)

    dd.onSelect = function(val)
        if val == "custom" then
            box:Show()
            saveBtn:Show()
            SolaQoLDB[dbKeyPath] = box:GetText()
        elseif val == "default" then
            box:Hide()
            saveBtn:Hide()
            SolaQoLDB[dbKeyPath] = ""
        else
            box:Hide()
            saveBtn:Hide()
            SolaQoLDB[dbKeyPath] = val
        end
    end

    local playBtn = CreateBtn(parent, L.PLAY, 55, "amber")
    playBtn:SetPoint("LEFT", dd, "RIGHT", 6, 0)
    playBtn:SetScript("OnClick", function()
        local soundVal = SolaQoLDB[dbKeyPath]
        if not soundVal or soundVal == "" or soundVal == "default" then
            PlaySound(defaultSoundKit, "Master")
        else
            NS.SafePlaySoundFile(soundVal, "Master", true)
        end
    end)

    -- Mute toggle button
    local muteBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    muteBtn:SetSize(55, 26)
    muteBtn:SetPoint("LEFT", playBtn, "RIGHT", 6, 0)
    muteBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    muteBtn:SetBackdropBorderColor(0, 0, 0, 0.65)
    muteBtn.label = muteBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    muteBtn.label:SetPoint("CENTER")
    row.muteBtn = muteBtn

    local function updateVisual()
        if SolaQoLDB[dbKeyMute] then
            muteBtn:SetBackdropColor(0.48, 0.22, 0.26, 0.88)
            muteBtn.label:SetText(L.TOGGLE_OFF)
        else
            muteBtn:SetBackdropColor(0.22, 0.42, 0.32, 0.88)
            muteBtn.label:SetText(L.TOGGLE_ON)
        end

        local currentVal = SolaQoLDB[dbKeyPath] or ""
        local options = GetOptions()
        local isPreset = false
        if currentVal == "" then
            isPreset = true
            dd:SetValue("default")
            box:Hide()
            saveBtn:Hide()
        else
            for _, opt in ipairs(options) do
                if opt.value == currentVal and currentVal ~= "custom" then
                    isPreset = true
                    dd:SetValue(currentVal)
                    box:Hide()
                    saveBtn:Hide()
                    break
                end
            end
        end

        if not isPreset then
            dd:SetValue("custom")
            box:SetText(currentVal)
            box:Show()
            saveBtn:Show()
        end
    end
    row.updateVisual = updateVisual
    updateVisual()

    muteBtn:SetScript("OnEnter", function()
        if SolaQoLDB[dbKeyMute] then
            muteBtn:SetBackdropColor(0.72, 0.33, 0.39, 1.0)
        else
            muteBtn:SetBackdropColor(0.33, 0.63, 0.48, 1.0)
        end
    end)
    muteBtn:SetScript("OnLeave", function() updateVisual() end)
    muteBtn:SetScript("OnClick", function()
        SolaQoLDB[dbKeyMute] = not SolaQoLDB[dbKeyMute]
        updateVisual()
        if SolaQoLDB[dbKeyMute] then
            print("|cff00ccff[SolaQoL]|r " .. offMsg)
        else
            print("|cff00ccff[SolaQoL]|r " .. onMsg)
        end
    end)

    return row
end


ModernConfig = CreateFrame("Frame", "SolaQoL_ModernConfig", UIParent)
ModernConfig:SetSize(FRAME_W, FRAME_H)
ModernConfig:SetPoint("CENTER")
ModernConfig:SetFrameStrata("HIGH")
ModernConfig:EnableMouse(true)
ModernConfig:SetMovable(true)
ModernConfig:RegisterForDrag("LeftButton")
ModernConfig:SetScript("OnDragStart", function(self) self:StartMoving() end)
ModernConfig:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
ModernConfig:SetClampedToScreen(true)
ModernConfig:Hide()

-- Add config to special frames so ESC closes it
tinsert(UISpecialFrames, "SolaQoL_ModernConfig")


local mainBg = ModernConfig:CreateTexture(nil, "BACKGROUND")
mainBg:SetAllPoints()
mainBg:SetTexture("Interface\\Buttons\\WHITE8X8")
mainBg:SetVertexColor(C.bgMain[1], C.bgMain[2], C.bgMain[3], C.bgMain[4])

-- Lighter top and darker bottom gives that glass look
if mainBg.SetGradient and CreateColor then
    pcall(function()
        mainBg:SetGradient("VERTICAL",
            CreateColor(C.bgMain[1] * 0.75, C.bgMain[2] * 0.75, C.bgMain[3] * 0.75, C.bgMain[4]),
            CreateColor(C.bgMain[1] * 1.2,  C.bgMain[2] * 1.2,  C.bgMain[3] * 1.2,  C.bgMain[4]))
    end)
end

ApplyRoundMask(mainBg)


local rimTop = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 6)
rimTop:SetPoint("TOPLEFT", 0, 0)
rimTop:SetPoint("TOPRIGHT", 0, 0)
rimTop:SetHeight(1)
rimTop:SetColorTexture(C.rimLight[1], C.rimLight[2], C.rimLight[3], 0.12)
ApplyRoundMask(rimTop)

local rimLeft = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 6)
rimLeft:SetPoint("TOPLEFT", 0, 0)
rimLeft:SetPoint("BOTTOMLEFT", 0, 0)
rimLeft:SetWidth(1)
rimLeft:SetColorTexture(C.rimLight[1], C.rimLight[2], C.rimLight[3], 0.08)
ApplyRoundMask(rimLeft)

local rimRight = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 6)
rimRight:SetPoint("TOPRIGHT", 0, 0)
rimRight:SetPoint("BOTTOMRIGHT", 0, 0)
rimRight:SetWidth(1)
rimRight:SetColorTexture(C.rimLight[1], C.rimLight[2], C.rimLight[3], 0.05)
ApplyRoundMask(rimRight)

local rimBottom = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 6)
rimBottom:SetPoint("BOTTOMLEFT", 0, 0)
rimBottom:SetPoint("BOTTOMRIGHT", 0, 0)
rimBottom:SetHeight(1)
rimBottom:SetColorTexture(C.rimLight[1], C.rimLight[2], C.rimLight[3], 0.03)
ApplyRoundMask(rimBottom)

-- Edge gloss highlight
local shine = ModernConfig:CreateTexture(nil, "BORDER")
shine:SetPoint("TOPLEFT", 2, -2)
shine:SetPoint("TOPRIGHT", -2, -2)
shine:SetHeight(30)
shine:SetColorTexture(1, 1, 1, 0.03)
ApplyRoundMask(shine)


local accentBar = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 7)
accentBar:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.7)
accentBar:SetPoint("TOPLEFT", 2, -2)
accentBar:SetPoint("TOPRIGHT", -2, -2)
accentBar:SetHeight(1)
ApplyRoundMask(accentBar)

local title = ModernConfig:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", ModernConfig, "TOP", 0, -12)
title:SetText("|cffD4A745SolaQoL|r")

local closeBtn = CreateFrame("Button", nil, ModernConfig, "BackdropTemplate")
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", -10, -8)
closeBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
closeBtn:SetBackdropColor(1, 1, 1, 0.04)
closeBtn:SetBackdropBorderColor(0, 0, 0, 0.65)
local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
closeTxt:SetPoint("CENTER", 0, 0)
closeTxt:SetText("X")
closeTxt:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
closeBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(C.rose[1] * 0.5, C.rose[2] * 0.5, C.rose[3] * 0.5, 0.9)
    closeTxt:SetTextColor(1, 1, 1)
end)
closeBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(1, 1, 1, 0.04)
    closeTxt:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
end)
closeBtn:SetScript("OnClick", function() ModernConfig:Hide() end)


local minimapBtn = CreateFrame("Button", "SolaQoLMinimapButton", Minimap)
minimapBtn:SetSize(32, 32)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)

local minimapIcon = minimapBtn:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetSize(20, 20)
minimapIcon:SetPoint("TOPLEFT", 7, -6)
minimapIcon:SetTexture("Interface\\AddOns\\SolaQoL\\PG_Logo.png")

local minimapBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(54, 54)
minimapBorder:SetPoint("TOPLEFT")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

function NS.UpdateMinimapButton()
    if SolaQoLDB.minimapButton ~= false then
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
    local angle = SolaQoLDB.minimapAngle or 45
    local rad = math.rad(angle)
    local radius = (Minimap:GetWidth() / 2) + 10
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    if ModernConfig.minimapToggle then
        ModernConfig.minimapToggle:SetChecked(SolaQoLDB.minimapButton ~= false)
    end
end

minimapBtn:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then return end
    self.isDragging = true
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - mx
        local dy = cy - my
        local angle = math.deg(math.atan2(dy, dx))
        if angle < 0 then angle = angle + 360 end
        SolaQoLDB.minimapAngle = angle
        NS.UpdateMinimapButton()
    end)
end)
minimapBtn:SetScript("OnMouseUp", function(self, button)
    if self.isDragging then
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end
end)
minimapBtn:SetScript("OnClick", function(self, button)
    if self.isDragging then return end
    if button == "LeftButton" then
        if ModernConfig:IsShown() then
            ModernConfig:Hide()
        else
            ModernConfig:Show()
        end
    end
end)
minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("|cffD4A745SolaQoL|r", 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP or "클릭하여 설정 창 열기\n드래그하여 위치 이동", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

local minimapToggle = CreateCheck(ModernConfig, L.MINIMAP or "미니맵")
minimapToggle:SetPoint("RIGHT", closeBtn, "LEFT", -12, 0)
minimapToggle.text:ClearAllPoints()
minimapToggle.text:SetPoint("RIGHT", minimapToggle, "LEFT", -8, 0)
minimapToggle.onClick = function(isChecked)
    SolaQoLDB.minimapButton = isChecked
    NS.UpdateMinimapButton()
end
ModernConfig.minimapToggle = minimapToggle

-- Separation line below title
local titleSep = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 5)
titleSep:SetHeight(1)
titleSep:SetPoint("TOPLEFT", 1, -TITLE_H)
titleSep:SetPoint("TOPRIGHT", -1, -TITLE_H)
titleSep:SetColorTexture(C.glassLine[1], C.glassLine[2], C.glassLine[3], C.glassLine[4])


local sidebar = CreateFrame("Frame", nil, ModernConfig)
sidebar:SetPoint("TOPLEFT", 1, -(TITLE_H + 1))
sidebar:SetSize(SIDEBAR_W, FRAME_H - TITLE_H - 2)

local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND", nil, 1)
sidebarBg:SetAllPoints()
sidebarBg:SetColorTexture(C.bgSidebar[1], C.bgSidebar[2], C.bgSidebar[3], C.bgSidebar[4])
ApplyRoundMask(sidebarBg)

-- Separation line next to sidebar
local sidebarSep = ModernConfig:CreateTexture(nil, "ARTWORK", nil, 5)
sidebarSep:SetWidth(1)
sidebarSep:SetPoint("TOPLEFT", SIDEBAR_W + 1, -TITLE_H)
sidebarSep:SetPoint("BOTTOMLEFT", SIDEBAR_W + 1, 1)
sidebarSep:SetColorTexture(C.glassLine[1], C.glassLine[2], C.glassLine[3], C.glassLine[4])


local contentArea = CreateFrame("Frame", nil, ModernConfig)
contentArea:SetPoint("TOPLEFT", SIDEBAR_W + 2, -TITLE_H)
contentArea:SetSize(CONTENT_W, CONTENT_H)

local scrollFrame = CreateFrame("ScrollFrame", nil, contentArea)
scrollFrame:SetAllPoints()
scrollFrame:EnableMouseWheel(true)

local scrollChild = CreateFrame("Frame")
scrollChild:SetWidth(CONTENT_W)
scrollChild:SetHeight(CONTENT_H)
scrollFrame:SetScrollChild(scrollChild)

local function ScrollHandler(_, delta)
    local cur = scrollFrame:GetVerticalScroll()
    local maxS = math_max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
    scrollFrame:SetVerticalScroll(math_max(0, math_min(cur - delta * 30, maxS)))
end
scrollFrame:SetScript("OnMouseWheel", ScrollHandler)


local categoryList = {
    { key = "greetings_main", label = L.CAT_GREETINGS },
    { key = "greetings",      label = L.CAT_GREETINGS_SUB or "인사말", isChild = true },
    { key = "sound",          label = L.SOUND_TITLE_SETTINGS or "사운드 설정", isChild = true },
    { key = "convenience",    label = L.CAT_CONVENIENCE },
    { key = "portal_lust",    label = L.CAT_COMBAT_PARTY or "전투 및 파티플레이", isChild = true },
    { key = "ilvl",           label = L.CAT_PLAYER_INFO or "플레이어 정보", isChild = true },
    { key = "trade",          label = L.CAT_TRADE_RESULT_ALERTS or "거래 결과 알림", isChild = true },
}

local sidebarBtns    = {}
local contentPanels  = {}
local activeCategory = nil
local builders       = {}
local SelectCategory

-- Helper to lazily fetch addon version from TOC metadata
local cachedAddonVer
local function GetAddonVersion()
    if not cachedAddonVer then
        local fn = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
        cachedAddonVer = fn and fn("SolaQoL", "Version") or "0.0.0"
    end
    return cachedAddonVer
end

-- Update changelog badge visibility
local function UpdateChangelogBadge()
    for _, btn in ipairs(sidebarBtns) do
        if btn.key == "changelog" and btn.badge then
            if SolaQoLDB and SolaQoLDB.lastReadChangelog ~= GetAddonVersion() then
                btn.badge:Show()
            else
                btn.badge:Hide()
            end
        end
    end
end


local yPos = 8
for i, cat in ipairs(categoryList) do
    local bh = cat.isChild and 26 or BTN_H
    local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
    btn:SetSize(SIDEBAR_W - 2, bh)
    btn:SetPoint("TOPLEFT", 1, -yPos)
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    btn:SetBackdropColor(0, 0, 0, 0)
    btn.key = cat.key
    btn.isChild = cat.isChild

    -- Left accent indicator
    local indicator = btn:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(3, bh - 8)
    indicator:SetPoint("LEFT", cat.isChild and 12 or 0, 0)
    indicator:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.9)
    indicator:Hide()
    btn.indicator = indicator

    local fontObj = cat.isChild and "GameFontNormalSmall" or "GameFontNormal"
    local lbl = btn:CreateFontString(nil, "OVERLAY", fontObj)
    lbl:SetPoint("LEFT", cat.isChild and 24 or 16, 0)
    lbl:SetText(cat.label)
    local cColor = cat.isChild and C.fgMain or C.goldBeige
    lbl:SetTextColor(cColor[1], cColor[2], cColor[3])
    btn.label = lbl

    btn:SetScript("OnEnter", function(self)
        if self.key ~= activeCategory and self.key ~= "convenience" and self.key ~= "greetings_main" then
            self:SetBackdropColor(C.bgHover[1], C.bgHover[2], C.bgHover[3], 0.35)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.key ~= activeCategory then
            self:SetBackdropColor(0, 0, 0, 0)
        end
    end)
    btn:SetScript("OnClick", function(self) SelectCategory(self.key) end)

    sidebarBtns[i] = btn
    yPos = yPos + bh
end

-- Changelog button sits at the bottom
do
    local changelogCat = { key = "changelog", label = L.CAT_CHANGELOG or "업데이트 내역" }
    local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
    btn:SetSize(SIDEBAR_W - 2, BTN_H)
    btn:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 1, FOOTER_H + 4)
    btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    btn:SetBackdropColor(0, 0, 0, 0)
    btn.key = changelogCat.key
    btn.isChild = false

    -- Left accent indicator
    local indicator = btn:CreateTexture(nil, "OVERLAY")
    indicator:SetSize(3, BTN_H - 8)
    indicator:SetPoint("LEFT", 0, 0)
    indicator:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.9)
    indicator:Hide()
    btn.indicator = indicator

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", 16, 0)
    lbl:SetText(changelogCat.label)
    lbl:SetTextColor(C.goldBeige[1], C.goldBeige[2], C.goldBeige[3])
    btn.label = lbl

    -- Unread changelog badge (red asterisk)
    local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    badge:SetPoint("LEFT", lbl, "RIGHT", 4, 2)
    badge:SetText("*")
    badge:SetTextColor(1.0, 0.2, 0.2, 1.0)
    badge:Hide()
    btn.badge = badge

    btn:SetScript("OnEnter", function(self)
        if self.key ~= activeCategory then
            self:SetBackdropColor(C.bgHover[1], C.bgHover[2], C.bgHover[3], 0.35)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.key ~= activeCategory then
            self:SetBackdropColor(0, 0, 0, 0)
        end
    end)
    btn:SetScript("OnClick", function(self) SelectCategory(self.key) end)

    -- Insert at the end of sidebarBtns
    table.insert(sidebarBtns, btn)
end


SelectCategory = function(key)
    if key == "greetings_main" then key = "greetings" end
    if key == "convenience" then key = "portal_lust" end
    if activeCategory == key then return end

    -- Mark changelog as read and hide badge
    if key == "changelog" then
        SolaQoLDB.lastReadChangelog = GetAddonVersion()
        for _, btn in ipairs(sidebarBtns) do
            if btn.key == "changelog" and btn.badge then
                btn.badge:Hide()
            end
        end
    end

    for _, btn in ipairs(sidebarBtns) do
        if btn.key == key then
            btn.indicator:Show()
            btn:SetBackdropColor(C.bgSelected[1], C.bgSelected[2], C.bgSelected[3], 0.5)
            btn.label:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
        else
            btn.indicator:Hide()
            btn:SetBackdropColor(0, 0, 0, 0)
            local cColor = btn.isChild and C.fgMain or C.goldBeige
            btn.label:SetTextColor(cColor[1], cColor[2], cColor[3])
        end
    end

    for _, panel in pairs(contentPanels) do
        if panel.container then panel.container:Hide() end
    end

    local isNewPanel = not contentPanels[key]
    if isNewPanel and builders[key] then
        contentPanels[key] = builders[key](scrollChild)
    end

    local panel = contentPanels[key]
    if panel and panel.container then
        panel.container:Show()
        local ch = panel.container.contentHeight or CONTENT_H
        scrollChild:SetHeight(math_max(ch, CONTENT_H))
        scrollFrame:SetVerticalScroll(0)
        -- Refresh DB options on tab switch
        if panel.refresh then panel.refresh() end
    end

    activeCategory = key
end


local function EnableContentScroll(ct)
    ct:EnableMouseWheel(true)
    ct:SetScript("OnMouseWheel", ScrollHandler)
end


builders.greetings = function(parent)
    local ct = CreateFrame("Frame", nil, parent)
    ct:SetPoint("TOPLEFT")
    ct:SetWidth(CONTENT_W)
    EnableContentScroll(ct)

    local y = -PAD
    local oChk

    local hChk = CreateCheck(ct, L.OPT_AUTO_GREET)
    hChk:SetPoint("TOPLEFT", PAD, y)
    y = y - 28

    local hBox = CreateEditBox(ct, 280)
    hBox:SetPoint("TOPLEFT", PAD + INDENT, y)
    local hBtn = CreateBtn(ct, L.SAVE, 50, "brown")
    hBtn:SetPoint("LEFT", hBox, "RIGHT", 4, 0)

    local function SaveHello()
        local text = hBox:GetText()
        if text and text ~= "" then
            SolaQoLDB.msgHello = text
            hBox:ClearFocus()
            local hasC = string_find(text, ",")
            local fmt = hasC and (L.GREETING_CHANGED_RAND_FMT or L.GREETING_CHANGED_FMT)
                             or L.GREETING_CHANGED_FMT
            print("|cff00ccff[SolaQoL]|r " .. string_format(fmt, text))
        end
    end
    hBtn:SetScript("OnClick", SaveHello)
    hBox:SetScript("OnEnterPressed", function() SaveHello(); hBox:ClearFocus() end)
    y = y - 35

    oChk = CreateCheck(ct, L.OPT_GREET_ONCE)
    oChk:SetPoint("TOPLEFT", PAD + INDENT, y)
    oChk.onClick = function(state)
        SolaQoLDB.onlyGreetOnceAsMember = state
        NS.PrintToggleMsg(L.OPT_GREET_ONCE, state)
    end
    y = y - 35

    hChk.onClick = function(state)
        SolaQoLDB.enableHello = state
        NS.PrintToggleMsg(L.OPT_AUTO_GREET_MSG or "파티 자동 인사", state)
        oChk:SetEnabledState(state)
    end

    local gChk = CreateCheck(ct, L.OPT_GG_COMPLETE)
    gChk:SetPoint("TOPLEFT", PAD, y)
    y = y - 28

    local gBox = CreateEditBox(ct, 280)
    gBox:SetPoint("TOPLEFT", PAD + INDENT, y)
    local gBtn = CreateBtn(ct, L.SAVE, 50, "brown")
    gBtn:SetPoint("LEFT", gBox, "RIGHT", 4, 0)

    local function SaveGG()
        local text = gBox:GetText()
        if text and text ~= "" then
            SolaQoLDB.msgGG = text
            gBox:ClearFocus()
            local hasC = string_find(text, ",")
            local fmt = hasC and (L.GG_CHANGED_RAND_FMT or L.GG_CHANGED_FMT)
                             or L.GG_CHANGED_FMT
            print("|cff00ccff[SolaQoL]|r " .. string_format(fmt, text))
        end
    end
    gBtn:SetScript("OnClick", SaveGG)
    gBox:SetScript("OnEnterPressed", function() SaveGG(); gBox:ClearFocus() end)

    gChk.onClick = function(state)
        SolaQoLDB.enableGG = state
        NS.PrintToggleMsg(L.OPT_GG_COMPLETE_MSG or "쐐기 던전 완료 인사", state)
    end
    y = y - 40

    ct.contentHeight = math.abs(y) + PAD

    ct.Refresh = function()
        hChk:SetChecked(SolaQoLDB.enableHello)
        oChk:SetChecked(SolaQoLDB.onlyGreetOnceAsMember)
        gChk:SetChecked(SolaQoLDB.enableGG)
        oChk:SetEnabledState(SolaQoLDB.enableHello)
        if SolaQoLDB.msgHello then hBox:SetText(SolaQoLDB.msgHello) end
        if SolaQoLDB.msgGG    then gBox:SetText(SolaQoLDB.msgGG)    end
    end

    ct:SetHeight(ct.contentHeight)
    return { container = ct, refresh = ct.Refresh }
end


builders.portal_lust = function(parent)
    local ct = CreateFrame("Frame", nil, parent)
    ct:SetPoint("TOPLEFT")
    ct:SetWidth(CONTENT_W)
    EnableContentScroll(ct)

    local y = -PAD

    local ptChk = CreateCheck(ct, L.OPT_AUTO_PORTAL)
    ptChk:SetPoint("TOPLEFT", PAD, y)
    ptChk.onClick = function(state)
        SolaQoLDB.enableAutoPortal = state
        NS.PrintToggleMsg(L.OPT_AUTO_PORTAL, state)
    end

    local testModeBtn = CreateBtn(ct, L.BTN_TEST_MODE or "Test Mode", 120, "amber")
    testModeBtn:SetPoint("TOPRIGHT", -PAD, y + 6)
    testModeBtn:SetScript("OnClick", function(self)
        if SolaQoL_PortalTestUI:IsShown() then
            SolaQoL_PortalTestUI:Hide()
            self.label:SetText(L.BTN_TEST_MODE or "Test Mode")
        else
            SolaQoL_PortalTestUI:Show()
            self.label:SetText(L.BTN_TEST_MODE_OFF or "End Test Mode")
        end
    end)
    y = y - 38

    local spChk = CreateCheck(ct, L.OPT_SHOW_SPEC_ON_ENTER)
    spChk:SetPoint("TOPLEFT", PAD, y)
    spChk.onClick = function(state)
        SolaQoLDB.showSpecOnEnter = state
        NS.PrintToggleMsg(L.OPT_SHOW_SPEC_ON_ENTER, state)
    end
    y = y - 22

    local spDesc = ct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    spDesc:SetPoint("TOPLEFT", PAD + INDENT, y)
    spDesc:SetJustifyH("LEFT")
    spDesc:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])
    spDesc:SetText(L.OPT_SHOW_SPEC_ON_ENTER_DESC)
    y = y - (spDesc:GetStringHeight() or 28) - 18

    local lbChk = CreateCheck(ct, L.OPT_LUST_BAR_ENABLE or "Enable Bloodlust Bar")
    lbChk:SetPoint("TOPLEFT", PAD, y)
    lbChk.onClick = function(state)
        SolaQoLDB.enableLust = state
        NS.PrintToggleMsg(L.OPT_LUST_BAR_ENABLE, state)
    end

    local lbTestBtn = CreateBtn(ct, L.BTN_TEST_LUST_BAR or "Test Bloodlust Bar", 130, "amber")
    lbTestBtn:SetPoint("TOPRIGHT", -PAD, y + 6)
    lbTestBtn:SetScript("OnClick", function(self)
        if NS.TestLustBar then
            local isActive = NS.TestLustBar()
            if isActive then
                self.label:SetText(L.BTN_TEST_STOP or "Stop Test")
            else
                self.label:SetText(L.BTN_TEST_LUST_BAR or "Test Bloodlust Bar")
            end
        end
    end)

    NS.ResetTestLustBarButton = function()
        if lbTestBtn and lbTestBtn.label then
            lbTestBtn.label:SetText(L.BTN_TEST_LUST_BAR or "Test Bloodlust Bar")
        end
    end
    y = y - 38

    local lbWSlider = CreateSlider(ct, L.LUST_BAR_WIDTH or "Width",
                                   200, 1600, 10, true)
    lbWSlider:SetPoint("TOPLEFT", PAD + INDENT, y)
    lbWSlider.onValueChanged = function(val)
        SolaQoLDB.lustBarWidth = val
        if NS.UpdateLustBarOptions then NS.UpdateLustBarOptions() end
    end

    local lbHSlider = CreateSlider(ct, L.LUST_BAR_HEIGHT or "Height",
                                   10, 100, 2, true)
    lbHSlider:SetPoint("LEFT", lbWSlider, "RIGHT", 30, 0)
    lbHSlider.onValueChanged = function(val)
        SolaQoLDB.lustBarHeight = val
        if NS.UpdateLustBarOptions then NS.UpdateLustBarOptions() end
    end
    y = y - 76

    local function GetLustModeOptions()
        return {
            {name = L.OPT_LUST_MODE_BOTH or "Text & Audio Alert", value = "both"},
            {name = L.OPT_LUST_MODE_TEXT or "Text Alert Only", value = "text"},
            {name = L.OPT_LUST_MODE_AUDIO or "Audio Alert Only", value = "audio"},
            {name = L.OPT_LUST_MODE_OFF or "Disabled", value = "off"},
        }
    end

    local lbaChk = CreateCheck(ct, L.OPT_BLOODLUST_ALERT_ENABLE or "Enable Bloodlust Text & Audio Alert")
    lbaChk:SetPoint("TOPLEFT", PAD, y)
    
    local lbaStartLabel = ct:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbaStartLabel:SetPoint("TOPLEFT", PAD + INDENT + 2, y - 32)
    lbaStartLabel:SetText(L.OPT_BLOODLUST_START_ALERT or "Bloodlust Start Alert")
    
    local lbaStartDropdown = CreateDropdown(ct, 160, GetLustModeOptions)
    lbaStartDropdown:SetPoint("LEFT", lbaStartLabel, "RIGHT", 10, 0)
    
    local lbaReadyLabel = ct:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbaReadyLabel:SetPoint("TOPLEFT", PAD + INDENT + 2, y - 62)
    lbaReadyLabel:SetText(L.OPT_BLOODLUST_READY_ALERT or "Bloodlust Ready Alert (Lust Classes Only)")
    
    local lbaReadyDropdown = CreateDropdown(ct, 160, GetLustModeOptions)
    lbaReadyDropdown:SetPoint("LEFT", lbaReadyLabel, "RIGHT", 10, 0)
    
    local lbaPersistChk = CreateCheck(ct, L.OPT_BLOODLUST_ALERT_PERSIST or "Keep 'Ready' Text Visible Until Next Cast")
    lbaPersistChk:SetPoint("TOPLEFT", PAD + INDENT * 2, y - 90)
    
    lbaStartDropdown.onSelect = function(val)
        SolaQoLDB.lustStartAlertMode = val
        if NS.UpdateBloodlustReadyDisplay then NS.UpdateBloodlustReadyDisplay() end
    end
    
    lbaReadyDropdown.onSelect = function(val)
        SolaQoLDB.lustReadyAlertMode = val
        lbaPersistChk:SetEnabledState(SolaQoLDB.enableBloodlustAlert and (val ~= "off" and val ~= "audio"))
        if NS.UpdateBloodlustReadyDisplay then NS.UpdateBloodlustReadyDisplay() end
    end
    
    lbaPersistChk.onClick = function(state)
        SolaQoLDB.persistBloodlustReady = state
        if NS.UpdateBloodlustReadyDisplay then NS.UpdateBloodlustReadyDisplay() end
    end
    
    lbaChk.onClick = function(state)
        SolaQoLDB.enableBloodlustAlert = state
        lbaStartDropdown:SetEnabledState(state)
        lbaReadyDropdown:SetEnabledState(state)
        lbaPersistChk:SetEnabledState(state and (SolaQoLDB.lustReadyAlertMode ~= "off" and SolaQoLDB.lustReadyAlertMode ~= "audio"))
        if NS.UpdateBloodlustReadyDisplay then NS.UpdateBloodlustReadyDisplay() end
    end
    
    local lbaTestBtn = CreateBtn(ct, L.BTN_TEST_BLOODLUST_ALERT or "Test Bloodlust Alert", 130, "amber")
    lbaTestBtn:SetPoint("TOPRIGHT", -PAD, y + 6)
    lbaTestBtn:SetScript("OnClick", function(self)
        if NS.TestBloodlustAlert then
            if self.isTesting then
                NS.TestBloodlustAlert("off", true)
                self.isTesting = false
                self.label:SetText(L.BTN_TEST_BLOODLUST_ALERT or "Test Bloodlust Alert")
            else
                NS.TestBloodlustAlert("test_mode", true)
                self.isTesting = true
                self.label:SetText(L.BTN_TEST_STOP or "Stop Test")
            end
        end
    end)
    y = y - 108

    -- Auto-Release Spirit
    local arHeader = CreateSectionHeader(ct, L.OPT_AUTO_RELEASE_SHORT or "Auto-Release Spirit")
    arHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - 28

    local arChk = CreateCheck(ct, L.OPT_AUTO_RELEASE)
    arChk:SetPoint("TOPLEFT", PAD, y)
    y = y - 22

    local arDesc = ct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    arDesc:SetPoint("TOPLEFT", PAD + INDENT, y)
    arDesc:SetWidth(CONTENT_W - PAD * 2 - INDENT)
    arDesc:SetJustifyH("LEFT")
    arDesc:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])
    arDesc:SetText(L.OPT_AUTO_RELEASE_DESC)
    y = y - (arDesc:GetStringHeight() or 40) - 12

    local arHudDisableChk = CreateCheck(ct, L.OPT_DISABLE_AUTO_RELEASE_HUD or "Disable HUD Indicator")
    arHudDisableChk:SetPoint("TOPLEFT", PAD + INDENT, y)
    arHudDisableChk.onClick = function(state)
        SolaQoLDB.disableAutoReleaseHUD = state
        if NS.UpdateAutoReleaseHUD then NS.UpdateAutoReleaseHUD() end
    end
    y = y - 28

    arChk.onClick = function(state)
        SolaQoLDB.enableAutoRelease = state
        NS.PrintToggleMsg(L.OPT_AUTO_RELEASE_SHORT, state)
        if NS.UpdateAutoReleaseHUD then NS.UpdateAutoReleaseHUD() end
        arHudDisableChk:SetEnabledState(state)
    end

    ct.contentHeight = math.abs(y) + PAD

    ct.Refresh = function()
        ptChk:SetChecked(SolaQoLDB.enableAutoPortal)
        spChk:SetChecked(SolaQoLDB.showSpecOnEnter)
        lbChk:SetChecked(SolaQoLDB.enableLust)
        
        -- Migration for older settings
        if type(SolaQoLDB.enableBloodlustStartAlert) == "boolean" then
            SolaQoLDB.lustStartAlertMode = SolaQoLDB.enableBloodlustStartAlert and "both" or "off"
            SolaQoLDB.enableBloodlustStartAlert = nil
        end
        if type(SolaQoLDB.enableBloodlustReadyAlert) == "boolean" then
            SolaQoLDB.lustReadyAlertMode = SolaQoLDB.enableBloodlustReadyAlert and "both" or "off"
            SolaQoLDB.enableBloodlustReadyAlert = nil
        end
        
        if not SolaQoLDB.lustStartAlertMode then SolaQoLDB.lustStartAlertMode = "both" end
        if not SolaQoLDB.lustReadyAlertMode then SolaQoLDB.lustReadyAlertMode = "both" end
        
        lbaChk:SetChecked(SolaQoLDB.enableBloodlustAlert)
        lbaStartDropdown:SetValue(SolaQoLDB.lustStartAlertMode)
        lbaReadyDropdown:SetValue(SolaQoLDB.lustReadyAlertMode)
        lbaPersistChk:SetChecked(SolaQoLDB.persistBloodlustReady)
        
        lbaStartDropdown:SetEnabledState(SolaQoLDB.enableBloodlustAlert)
        lbaReadyDropdown:SetEnabledState(SolaQoLDB.enableBloodlustAlert)
        lbaPersistChk:SetEnabledState(SolaQoLDB.enableBloodlustAlert and (SolaQoLDB.lustReadyAlertMode ~= "off" and SolaQoLDB.lustReadyAlertMode ~= "audio"))
        lbWSlider:SetValue(SolaQoLDB.lustBarWidth or 800)
        lbHSlider:SetValue(SolaQoLDB.lustBarHeight or 28)
        arChk:SetChecked(SolaQoLDB.enableAutoRelease)
        arHudDisableChk:SetChecked(SolaQoLDB.disableAutoReleaseHUD)
        arHudDisableChk:SetEnabledState(SolaQoLDB.enableAutoRelease)
    end

    ct:SetHeight(ct.contentHeight)
    return { container = ct, refresh = ct.Refresh }
end


builders.ilvl = function(parent)
    local ct = CreateFrame("Frame", nil, parent)
    ct:SetPoint("TOPLEFT")
    ct:SetWidth(CONTENT_W)
    EnableContentScroll(ct)

    local y = -PAD

    local sChk = CreateCheck(ct, L.OPT_SHOW_ILVL)
    sChk:SetPoint("TOPLEFT", PAD, y)
    sChk.onClick = function(state)
        SolaQoLDB.showIlevelToSelf = state
        NS.PrintToggleMsg(L.OPT_SHOW_ILVL_SHORT, state)
    end
    y = y - 35

    local ttChk = CreateCheck(ct, L.OPT_TOOLTIP_ILVL)
    ttChk:SetPoint("TOPLEFT", PAD, y)
    ttChk.onClick = function(state)
        SolaQoLDB.enableTooltipIlvl = state
        NS.PrintToggleMsg(L.OPT_TOOLTIP_ILVL, state)
    end
    y = y - 30

    -- Keyword Alert
    local kwHeader = CreateSectionHeader(ct, L.OPT_KEYWORD_ALERT_SHORT or "Keyword Alert")
    kwHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - 28

    local kwAutoPlayerChk -- forward declare

    local kwChk = CreateCheck(ct, L.OPT_KEYWORD_ALERT)
    kwChk:SetPoint("TOPLEFT", PAD, y)
    kwChk.onClick = function(state)
        SolaQoLDB.enableKeywordAlert = state
        NS.PrintToggleMsg(L.OPT_KEYWORD_ALERT_SHORT, state)
        if kwAutoPlayerChk then
            kwAutoPlayerChk:SetEnabledState(state)
        end
    end
    y = y - 32

    local kwLabel = ct:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kwLabel:SetPoint("TOPLEFT", PAD + INDENT, y)
    kwLabel:SetText(L.OPT_KEYWORD_LIST or "Alert keywords (comma separated):")
    y = y - 18

    local kwEditBox = CreateEditBox(ct, CONTENT_W - PAD * 2 - INDENT)
    kwEditBox:SetPoint("TOPLEFT", PAD + INDENT, y)
    kwEditBox:SetScript("OnEnterPressed", function(self)
        SolaQoLDB.keywordAlertList = self:GetText()
        if NS.KeywordAlert then NS.KeywordAlert.UpdateKeywords() end
        self:ClearFocus()
    end)
    kwEditBox:SetScript("OnEditFocusLost", function(self)
        SolaQoLDB.keywordAlertList = self:GetText()
        if NS.KeywordAlert then NS.KeywordAlert.UpdateKeywords() end
    end)
    y = y - 34

    kwAutoPlayerChk = CreateCheck(ct, L.OPT_KEYWORD_AUTO_PLAYER or "Automatically add current character name to alert keywords")
    kwAutoPlayerChk:SetPoint("TOPLEFT", PAD + INDENT, y)
    kwAutoPlayerChk.onClick = function(state)
        SolaQoLDB.keywordAutoAddPlayer = state
        NS.PrintToggleMsg(L.OPT_KEYWORD_AUTO_PLAYER_SHORT or "Auto Add Character Name", state)
        if NS.KeywordAlert then NS.KeywordAlert.UpdateKeywords() end
    end
    y = y - 32

    -- Sound selector: label + dropdown + test button
    local kwSndLabel = ct:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    kwSndLabel:SetPoint("TOPLEFT", PAD + INDENT, y)
    kwSndLabel:SetText(L.OPT_KEYWORD_SOUND or "Alert Sound:")

    local function GetSoundOptions()
        local opts = {
            {name = "KeywordSound (기본)", value = "KeywordSound"},
            {name = "귓속말 (Whisper)", value = "whisper"},
        }
        for i = 1, 9 do
            table.insert(opts, {
                name = string.format(L.SOUND_NOTIFICATION_FMT or "Sound %d", i),
                value = "FreeNotification" .. i
            })
        end
        local seen = {}
        for _, o in ipairs(opts) do
            seen[o.name] = true
            seen[o.value] = true
        end

        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            for _, name in ipairs(LSM:List("sound")) do
                if not seen[name] then
                    seen[name] = true
                    local path = LSM:Fetch("sound", name)
                    if path and not seen[path] then
                        seen[path] = true
                        table.insert(opts, {name = name, value = name})
                    end
                end
            end
        end
        return opts
    end

    local kwSndDropdown = CreateDropdown(ct, 180, GetSoundOptions, true)
    kwSndDropdown:SetPoint("LEFT", kwSndLabel, "RIGHT", 8, 0)
    kwSndDropdown.onSelect = function(val)
        SolaQoLDB.keywordAlertSound = val
    end

    local kwTestBtn = CreateBtn(ct, L.BTN_KEYWORD_TEST or "\226\150\182 Test", 70, "amber")
    kwTestBtn:SetPoint("LEFT", kwSndDropdown, "RIGHT", 6, 0)
    kwTestBtn:SetScript("OnClick", function()
        if NS.KeywordAlert then NS.KeywordAlert.PlayAlertSound() end
    end)
    y = y - 34

    -- Random Hearthstone
    local rhHeader = CreateSectionHeader(ct, L.CAT_RANDOM_HEARTHSTONE)
    rhHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - 28

    local rhChk = CreateCheck(ct, L.OPT_RANDOM_HEARTHSTONE)
    rhChk:SetPoint("TOPLEFT", PAD, y)
    rhChk.onClick = function(state)
        SolaQoLDB.enableRandomHearthstone = state
        NS.PrintToggleMsg(L.OPT_RANDOM_HEARTHSTONE, state)
    end
    y = y - 32

    local function FormatBindingText(bind)
        if not bind then return L.BIND_NOT_SET end
        local b = bind
        b = string.gsub(b, "CTRL%-", "C-")
        b = string.gsub(b, "ALT%-", "A-")
        b = string.gsub(b, "SHIFT%-", "S-")
        b = string.gsub(b, "MOUSEWHEELUP", "WU")
        b = string.gsub(b, "MOUSEWHEELDOWN", "WD")
        b = string.gsub(b, "MiddleButton", "M3")
        b = string.gsub(b, "BUTTON3", "M3")
        b = string.gsub(b, "BUTTON4", "M4")
        b = string.gsub(b, "BUTTON5", "M5")
        b = string.gsub(b, "NUMPAD", "N")
        b = string.gsub(b, "SPACE", "Spc")
        b = string.gsub(b, "DELETE", "Del")
        b = string.gsub(b, "INSERT", "Ins")
        b = string.gsub(b, "HOME", "Hm")
        b = string.gsub(b, "END", "End")
        b = string.gsub(b, "PAGEUP", "PgUp")
        b = string.gsub(b, "PAGEDOWN", "PgDn")
        b = string.gsub(b, "CAPSLOCK", "Caps")
        return b
    end

    local rhManageBtn = CreateBtn(ct, L.BTN_HEARTHSTONE_LIST, 130, "lavender")
    rhManageBtn:SetPoint("TOPLEFT", PAD + INDENT, y)

    local rhBindBtn = CreateBtn(ct, FormatBindingText(GetBindingKey("CLICK PGRandomHearthstoneBtn:LeftButton")), 160, "teal")
    rhBindBtn:SetPoint("LEFT", rhManageBtn, "RIGHT", 10, 0)

    local rhUnbindBtn = CreateBtn(ct, L.BTN_UNBIND, 50, "rose")
    rhUnbindBtn:SetPoint("LEFT", rhBindBtn, "RIGHT", 4, 0)
    
    y = y - 38
    
    local rhClearChk = CreateCheck(ct, L.OPT_HEARTHSTONE_ON_CLEAR)
    rhClearChk:SetPoint("TOPLEFT", PAD + INDENT - 6, y)
    rhClearChk.onClick = function(state)
        SolaQoLDB.enableHearthstoneOnClear = state
        NS.PrintToggleMsg(L.OPT_HEARTHSTONE_ON_CLEAR, state)
    end
    
    local rhPopup = nil
    local function ShowHearthstonePopup()
        if not rhPopup then
            rhPopup = CreateFrame("Frame", "SolaQoLHearthstonePopup", UIParent, "BackdropTemplate")
            rhPopup:SetSize(320, 400)
            rhPopup:SetPoint("CENTER")
            rhPopup:SetFrameStrata("DIALOG")
            rhPopup:EnableMouse(true)
            rhPopup:SetMovable(true)
            rhPopup:RegisterForDrag("LeftButton")
            rhPopup:SetScript("OnDragStart", rhPopup.StartMoving)
            rhPopup:SetScript("OnDragStop", rhPopup.StopMovingOrSizing)
            
            rhPopup:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            rhPopup:SetBackdropColor(C.bgMain[1], C.bgMain[2], C.bgMain[3], 0.98)
            rhPopup:SetBackdropBorderColor(0, 0, 0, 0.65)
            rhPopup:EnableKeyboard(true)
            rhPopup:SetScript("OnKeyDown", function(self, key)
                if key == "ESCAPE" then
                    self:SetPropagateKeyboardInput(false)
                    self:Hide()
                else
                    self:SetPropagateKeyboardInput(true)
                end
            end)
            
            local title = rhPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
            title:SetPoint("TOP", 0, -12)
            title:SetText(L.HEARTHSTONE_POPUP_TITLE)
            
            local closeBtn = CreateFrame("Button", nil, rhPopup, "BackdropTemplate")
            closeBtn:SetSize(22, 22)
            closeBtn:SetPoint("TOPRIGHT", -10, -8)
            closeBtn:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            closeBtn:SetBackdropColor(1, 1, 1, 0.04)
            closeBtn:SetBackdropBorderColor(0, 0, 0, 0.65)
            local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            closeTxt:SetPoint("CENTER", 0, 0)
            closeTxt:SetText("X")
            closeTxt:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
            closeBtn:SetScript("OnEnter", function(self)
                self:SetBackdropColor(C.rose[1] * 0.5, C.rose[2] * 0.5, C.rose[3] * 0.5, 0.9)
                closeTxt:SetTextColor(1, 1, 1)
            end)
            closeBtn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(1, 1, 1, 0.04)
                closeTxt:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
            end)
            closeBtn:SetScript("OnClick", function() rhPopup:Hide() end)
            
            local scrollFrame = CreateFrame("ScrollFrame", nil, rhPopup, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 12, -40)
            scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)
            
            local content = CreateFrame("Frame", nil, scrollFrame)
            content:SetSize(270, 10)
            scrollFrame:SetScrollChild(content)
            
            rhPopup.content = content
            rhPopup.rows = {}
        end
        
        local owned = NS.GetOwnedHearthstones()
        local yOffset = -5
        
        for i, item in ipairs(owned) do
            local row = rhPopup.rows[i]
            if not row then
                row = CreateFrame("Frame", nil, rhPopup.content)
                row:SetSize(270, 30)
                
                local cb = CreateCheck(row, "")
                cb:SetPoint("LEFT", 0, 0)
                row.cb = cb
                
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(24, 24)
                icon:SetPoint("LEFT", cb, "RIGHT", 8, 0)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                row.icon = icon
                
                local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("LEFT", icon, "RIGHT", 8, 0)
                text:SetJustifyH("LEFT")
                text:SetWidth(180)
                text:SetWordWrap(false)
                text:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])
                row.text = text
                
                rhPopup.rows[i] = row
            end
            
            row:SetPoint("TOPLEFT", 10, yOffset)
            row.icon:SetTexture(item.icon)
            row.text:SetText(item.name)
            
            local isEnabled = true
            if SolaQoLDB.disabledHearthstones then
                local disabled = SolaQoLDB.disabledHearthstones[tostring(item.id)]
                if disabled == nil then
                    isEnabled = (tostring(item.id) ~= "6948")
                else
                    isEnabled = not disabled
                end
            else
                isEnabled = (tostring(item.id) ~= "6948")
            end
            row.cb:SetChecked(isEnabled)
            row.cb.onClick = function(state)
                if not SolaQoLDB.disabledHearthstones then
                    SolaQoLDB.disabledHearthstones = {}
                end
                SolaQoLDB.disabledHearthstones[tostring(item.id)] = not state
            end
            
            row:Show()
            yOffset = yOffset - 30
        end
        
        for i = #owned + 1, #rhPopup.rows do
            rhPopup.rows[i]:Hide()
        end
        
        rhPopup.content:SetHeight(math.abs(yOffset) + 10)
        rhPopup:Show()
    end
    
    rhManageBtn:SetScript("OnClick", function()
        ShowHearthstonePopup()
    end)
    local function UpdateBindLabel()
        if rhBindBtn and rhBindBtn.label then
            local currentKey = GetBindingKey("CLICK PGRandomHearthstoneBtn:LeftButton")
            if currentKey then
                rhBindBtn.label:SetText(FormatBindingText(currentKey))
                rhBindBtn:SetBackdropColor(C.mint[1]*0.42, C.mint[2]*0.42, C.mint[3]*0.42, 0.85)
                rhUnbindBtn:Enable()
                rhUnbindBtn:SetAlpha(1)
            else
                rhBindBtn.label:SetText(L.BIND_NOT_SET)
                rhBindBtn:SetBackdropColor(C.teal[1]*0.42, C.teal[2]*0.42, C.teal[3]*0.42, 0.85)
                rhUnbindBtn:Disable()
                rhUnbindBtn:SetAlpha(0.5)
            end
        end
    end
    
    local function ApplyBinding(keyStr)
        local modifier = ""
        if IsAltKeyDown() then modifier = modifier .. "ALT-" end
        if IsControlKeyDown() then modifier = modifier .. "CTRL-" end
        if IsShiftKeyDown() then modifier = modifier .. "SHIFT-" end
        
        local bindString = modifier .. keyStr
        
        local oldKeys = {GetBindingKey("CLICK PGRandomHearthstoneBtn:LeftButton")}
        for _, k in ipairs(oldKeys) do
            SetBinding(k)
        end
        
        local ok = SetBindingClick(bindString, "PGRandomHearthstoneBtn")
        if ok then
            SaveBindings(GetCurrentBindingSet())
            print("|cff00ccff[SolaQoL]|r 단축키 저장됨: " .. FormatBindingText(bindString))
        else
            print("|cffff0000[SolaQoL]|r 단축키 저장 실패")
        end
    end

    local function StopWaiting(self)
        self.isWaiting = false
        self:EnableKeyboard(false)
        self:EnableMouseWheel(false)
        self:SetScript("OnKeyDown", nil)
        self:SetScript("OnMouseWheel", nil)
        self:SetScript("OnMouseDown", nil)
        UpdateBindLabel()
    end

    rhBindBtn:SetScript("OnClick", function(self, button)
        if self.isWaiting then
            StopWaiting(self)
            return
        end
        
        self.isWaiting = true
        self.label:SetText("키 입력 (ESC 취소)")
        self:SetBackdropColor(C.amber[1]*0.42, C.amber[2]*0.42, C.amber[3]*0.42, 0.85)
        
        self:EnableKeyboard(true)
        self:EnableMouseWheel(true)
        
        self:SetScript("OnKeyDown", function(self, key)
            if key == "UNKNOWN" then return end
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then return end
            if key == "ESCAPE" then
                StopWaiting(self)
                return
            end
            ApplyBinding(key)
            StopWaiting(self)
        end)
        
        self:SetScript("OnMouseWheel", function(self, delta)
            local key = delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"
            ApplyBinding(key)
            StopWaiting(self)
        end)
        
        self:SetScript("OnMouseDown", function(self, mouseBtn)
            if mouseBtn == "LeftButton" or mouseBtn == "RightButton" then
                return
            end
            local keyMap = {
                MiddleButton = "BUTTON3",
                Button4 = "BUTTON4",
                Button5 = "BUTTON5",
            }
            local key = keyMap[mouseBtn] or mouseBtn:upper()
            ApplyBinding(key)
            StopWaiting(self)
        end)
    end)
    
    rhUnbindBtn:SetScript("OnClick", function()
        local oldKeys = {GetBindingKey("CLICK PGRandomHearthstoneBtn:LeftButton")}
        for _, k in ipairs(oldKeys) do
            SetBinding(k)
        end
        SaveBindings(GetCurrentBindingSet())
        UpdateBindLabel()
        print("|cff00ccff[SolaQoL]|r " .. L.MSG_UNBOUND)
    end)
    
    rhBindBtn:SetScript("OnHide", function(self)
        if self.isWaiting then
            StopWaiting(self)
        end
    end)
    
    y = y - 30

    ct.contentHeight = math.abs(y) + PAD

    ct.Refresh = function()
        if rhChk then rhChk:SetChecked(SolaQoLDB.enableRandomHearthstone ~= false) end
        if rhClearChk then rhClearChk:SetChecked(SolaQoLDB.enableHearthstoneOnClear ~= false) end
        sChk:SetChecked(SolaQoLDB.showIlevelToSelf)
        ttChk:SetChecked(SolaQoLDB.enableTooltipIlvl)
        kwChk:SetChecked(SolaQoLDB.enableKeywordAlert)
        kwAutoPlayerChk:SetChecked(SolaQoLDB.keywordAutoAddPlayer)
        kwAutoPlayerChk:SetEnabledState(SolaQoLDB.enableKeywordAlert)
        kwEditBox:SetText(SolaQoLDB.keywordAlertList or "")
        kwSndDropdown:SetValue(SolaQoLDB.keywordAlertSound or "KeywordSound")
        UpdateBindLabel()
    end

    ct:SetHeight(ct.contentHeight)
    return { container = ct, refresh = ct.Refresh }
end


builders.trade = function(parent)
    local ct = CreateFrame("Frame", nil, parent)
    ct:SetPoint("TOPLEFT")
    ct:SetWidth(CONTENT_W)
    EnableContentScroll(ct)

    local y = -PAD
    local twChk, tpChk


    local trChk = CreateCheck(ct, L.OPT_TRADE_ENABLE)
    trChk:SetPoint("TOPLEFT", PAD, y)
    trChk.onClick = function(state)
        SolaQoLDB.enableTradeReport = state
        NS.PrintToggleMsg(L.OPT_TRADE_ENABLE, state)
        if twChk then twChk:SetEnabledState(state) end
        if tpChk then tpChk:SetEnabledState(state) end
    end
    y = y - 32

    twChk = CreateCheck(ct, L.OPT_TRADE_WHISPER)
    twChk:SetPoint("TOPLEFT", PAD + INDENT - 6, y)
    twChk.onClick = function(state)
        SolaQoLDB.tradeWhisper = state
        NS.PrintToggleMsg(L.OPT_TRADE_WHISPER, state)
    end
    y = y - 30

    tpChk = CreateCheck(ct, L.OPT_TRADE_PARTY)
    tpChk:SetPoint("TOPLEFT", PAD + INDENT - 6, y)
    tpChk.onClick = function(state)
        SolaQoLDB.tradeParty = state
        NS.PrintToggleMsg(L.OPT_TRADE_PARTY, state)
    end
    y = y - 40


    local sep = ct:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  PAD, y)
    sep:SetPoint("TOPRIGHT", -PAD, y)
    sep:SetColorTexture(C.glassLine[1], C.glassLine[2], C.glassLine[3], C.glassLine[4])
    y = y - 16


    local logChk = CreateCheck(ct, L.TRADE_LOG_ENABLE or "이전 거래 내역")
    logChk:SetPoint("TOPLEFT", PAD, y)
    logChk.onClick = function(state)
        if SolaQoLCharDB then
            SolaQoLCharDB.enableTradeLog = state
        end
        NS.PrintToggleMsg(L.TRADE_LOG_ENABLE or "이전 거래 내역", state)
    end

    local clearBtn = CreateBtn(ct, L.TRADE_LOG_CLEAR or "내역 지우기", 90, "rose")
    clearBtn:SetPoint("RIGHT", ct, "RIGHT", -PAD, 0)
    clearBtn:SetPoint("TOP",   ct, "TOP",   0,    y + 7)
    clearBtn:SetScript("OnClick", function()
        if SolaQoLCharDB then
            SolaQoLCharDB.tradeLog = {}
        end
        -- refresh log display
        if ct.RefreshLog then ct.RefreshLog() end
    end)

    local countLabel = ct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countLabel:SetPoint("LEFT", logChk.text, "RIGHT", 8, 0)
    countLabel:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])

    y = y - 24


    local LOG_BOX_H = 200

    local logBorder = CreateFrame("Frame", nil, ct, "BackdropTemplate")
    logBorder:SetPoint("TOPLEFT",  PAD,  y)
    logBorder:SetPoint("TOPRIGHT", -PAD, y)
    logBorder:SetHeight(LOG_BOX_H)
    logBorder:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    logBorder:SetBackdropColor(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.60)
    logBorder:SetBackdropBorderColor(C.glassLine[1], C.glassLine[2], C.glassLine[3], 0.25)
    y = y - LOG_BOX_H - 12

    -- Inner scroll frame
    local logScroll = CreateFrame("ScrollFrame", nil, logBorder)
    logScroll:SetPoint("TOPLEFT",     4, -4)
    logScroll:SetPoint("BOTTOMRIGHT", -4, 4)
    logScroll:EnableMouseWheel(true)
    logScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math_min(math_max(cur - delta * 18, 0), max))
    end)

    -- Hardcode inner width since logScroll:GetWidth() is 0 before frame layout
    local LOG_INNER_W = CONTENT_W - PAD * 2 - 16  -- border padding (4px*2) + inner margin (4px*2)

    local logChild = CreateFrame("Frame", nil, logScroll)
    logChild:SetWidth(LOG_INNER_W)
    logChild:SetHeight(LOG_BOX_H)  -- Initial height so scroll works even without text.
    logScroll:SetScrollChild(logChild)

    -- FontString for all log text
    local logText = logChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    logText:SetPoint("TOPLEFT", 6, -4)
    logText:SetWidth(LOG_INNER_W - 12)  -- Explicit width for word wrapping.
    logText:SetJustifyH("LEFT")
    logText:SetJustifyV("TOP")
    logText:SetNonSpaceWrap(true)


    ct.RefreshLog = function()
        local log = SolaQoLCharDB and SolaQoLCharDB.tradeLog or {}
        local count = #log

        -- Update counter label
        countLabel:SetText(string.format("%d / 100", count))

        if count == 0 then
            logText:SetText("|cff555555" .. (L.TRADE_LOG_EMPTY or "기록된 거래 내역이 없습니다.") .. "|r")
            logChild:SetHeight(40)
            return
        end

        local lines = {}
        for i = count, 1, -1 do   -- Print newest first.
            local entry = log[i]
            local verified = NS.VerifyLog and NS.VerifyLog(entry)
            local prefix   = "|cff5ABFB0[" .. (entry.ts or "?") .. "]|r "
            local body     = entry.msg or ""
            local tamper   = ""
            if not verified then
                tamper = " |cffff4444" .. (L.TRADE_LOG_TAMPERED or "[변조됨]") .. "|r"
            end
            table.insert(lines, prefix .. body .. tamper)
        end

        local fullText = table.concat(lines, "\n")
        logText:SetText(fullText)

        -- Resize logChild to fit content
        C_Timer.After(0, function()
            local h = logText:GetStringHeight()
            logChild:SetHeight(math_max(h + 12, LOG_BOX_H - 8))
        end)
    end


    ct.contentHeight = math.abs(y) + PAD + 10

    ct.Refresh = function()
        trChk:SetChecked(SolaQoLDB.enableTradeReport)
        twChk:SetChecked(SolaQoLDB.tradeWhisper)
        tpChk:SetChecked(SolaQoLDB.tradeParty)
        twChk:SetEnabledState(SolaQoLDB.enableTradeReport)
        tpChk:SetEnabledState(SolaQoLDB.enableTradeReport)

        -- Sync checkbox only when character DB is ready
        if SolaQoLCharDB then
            logChk:SetChecked(SolaQoLCharDB.enableTradeLog ~= false)
        end
        ct.RefreshLog()
    end

    ct:SetHeight(ct.contentHeight)

    -- Namespace hook to refresh logs externally
    NS.RefreshTradePanel = function()
        if ct.RefreshLog then ct.RefreshLog() end
    end

    return { container = ct, refresh = ct.Refresh }
end



builders.sound = function(parent)
    local ct = CreateFrame("Frame", nil, parent)
    ct:SetPoint("TOPLEFT")
    ct:SetWidth(CONTENT_W)
    EnableContentScroll(ct)

    local y = -PAD

    local hint = ct:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", PAD, y)
    hint:SetText(L.SOUND_HINT)
    hint:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])
    y = y - 24

    local sndRow1 = CreateSoundRow(ct, L.SOUND_NEW_LABEL,
        "customSoundNewMember", "muteNewMember",
        SOUNDKIT.IG_PLAYER_INVITE, L.SOUND_NEW_SAVED,
        L.SOUND_NEW_ON, L.SOUND_NEW_OFF)
    sndRow1.label:SetPoint("TOPLEFT", PAD, y)
    y = y - 90

    local sndRow2 = CreateSoundRow(ct, L.SOUND_FULL_LABEL,
        "customSoundFullParty", "muteFullParty",
        SOUNDKIT.READY_CHECK, L.SOUND_FULL_SAVED,
        L.SOUND_FULL_ON, L.SOUND_FULL_OFF)
    sndRow2.label:SetPoint("TOPLEFT", PAD, y)
    y = y - 90

    local sndRow3 = CreateSoundRow(ct, L.SOUND_APP_LABEL,
        "customSoundNewApplicant", "muteNewApplicant",
        SOUNDKIT.RAID_WARNING, L.SOUND_APP_SAVED,
        L.SOUND_APP_ON, L.SOUND_APP_OFF)
    sndRow3.label:SetPoint("TOPLEFT", PAD, y)
    y = y - 100

    local rChk = CreateCheck(ct, L.OPT_RAID_SOUND)
    rChk:SetPoint("TOPLEFT", PAD, y)
    rChk.onClick = function(state)
        SolaQoLDB.enableRaidSound = state
        NS.PrintToggleMsg(L.OPT_RAID_SOUND, state)
    end
    y = y - 35

    local guide1 = ct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    guide1:SetPoint("TOPLEFT", PAD, y)
    guide1:SetText(L.SOUND_GUIDE1)
    guide1:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])
    y = y - 16

    local guide2 = ct:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    guide2:SetPoint("TOPLEFT", PAD, y)
    guide2:SetText(L.SOUND_GUIDE2)
    guide2:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])
    y = y - 22

    local warning = ct:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warning:SetPoint("TOPLEFT", PAD, y)
    warning:SetText(L.SOUND_WARNING)
    warning:SetTextColor(C.rose[1], C.rose[2], C.rose[3])
    y = y - 20

    ct.contentHeight = math.abs(y) + PAD

    ct.Refresh = function()
        sndRow1.updateVisual()
        sndRow2.updateVisual()
        sndRow3.updateVisual()
        rChk:SetChecked(SolaQoLDB.enableRaidSound)
    end

    ct:SetHeight(ct.contentHeight)
    return { container = ct, refresh = ct.Refresh }
end


builders.changelog = function(parent)
    local ct = CreateFrame("Frame", nil, parent)
    ct:SetPoint("TOPLEFT")
    ct:SetWidth(CONTENT_W)
    EnableContentScroll(ct)

    local y = -PAD

    local header = ct:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", PAD, y)
    header:SetText(L.CAT_CHANGELOG or "Changelog")
    header:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
    y = y - 28

    local text = ct:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", PAD, y)
    text:SetWidth(CONTENT_W - PAD * 2)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetSpacing(6)
    text:SetText(L.CHANGELOG_TEXT)
    y = y - (text:GetStringHeight() or 200) - 20

    ct.contentHeight = math.abs(y) + PAD

    ct.Refresh = function()
    end

    ct:SetHeight(ct.contentHeight)
    return { container = ct, refresh = ct.Refresh }
end


local footer = CreateFrame("Frame", nil, ModernConfig)
footer:SetPoint("BOTTOMLEFT", 1, 1)
footer:SetPoint("BOTTOMRIGHT", -1, 1)
footer:SetHeight(FOOTER_H)

local footerSep = footer:CreateTexture(nil, "ARTWORK")
footerSep:SetHeight(1)
footerSep:SetPoint("TOPLEFT", 0, 0)
footerSep:SetPoint("TOPRIGHT", 0, 0)
footerSep:SetColorTexture(C.glassLine[1], C.glassLine[2], C.glassLine[3], C.glassLine[4])

local versionText = footer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
versionText:SetPoint("LEFT", 16, -2)
local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local addonVerRaw = getMetadata and
                 getMetadata("SolaQoL", "Version") or "1.0.0"
local addonVer = string.match(addonVerRaw, "^(%d+%.%d+%.%d+)") or addonVerRaw
versionText:SetText(addonVer)
versionText:SetTextColor(C.teal[1], C.teal[2], C.teal[3])

-- Scale slider
local scaleSlider = CreateFrame("Slider", "SolaQoL_ScaleSlider", footer)
scaleSlider:SetOrientation("HORIZONTAL")
scaleSlider:SetSize(100, 8)
scaleSlider:SetPoint("RIGHT", footer, "RIGHT", -15, 0)
scaleSlider:SetMinMaxValues(0.5, 2.0)
scaleSlider:SetValueStep(0.05)
scaleSlider:SetObeyStepOnDrag(true)

local sBg = scaleSlider:CreateTexture(nil, "BACKGROUND")
sBg:SetAllPoints()
sBg:SetColorTexture(C.bgInput[1], C.bgInput[2], C.bgInput[3], 0.7)

-- Slider fill (toned-down gold, left side)
local sFill = scaleSlider:CreateTexture(nil, "ARTWORK")
sFill:SetPoint("LEFT", scaleSlider, "LEFT", 0, 0)
sFill:SetHeight(8)
sFill:SetColorTexture(C.goldMuted[1], C.goldMuted[2], C.goldMuted[3], 0.35)

local sThumb = scaleSlider:CreateTexture(nil, "ARTWORK", nil, 1)
sThumb:SetSize(8, 14)
sThumb:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
scaleSlider:SetThumbTexture(sThumb)

-- UI scale label
local sLabel = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sLabel:SetPoint("RIGHT", scaleSlider, "LEFT", -8, 0)
sLabel:SetTextColor(C.fgDim[1], C.fgDim[2], C.fgDim[3])

local function UpdateScaleLabel(value)
    local pct = math_floor(value * 100 + 0.5)
    sLabel:SetText((L.UI_SCALE or "UI 크기") .. " |cffD4A745" .. pct .. "%|r")
end

-- Low / High range text
local sLow = footer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
sLow:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -2)
sLow:SetText("50%")
sLow:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])

local sHigh = footer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
sHigh:SetPoint("TOPRIGHT", scaleSlider, "BOTTOMRIGHT", 0, -2)
sHigh:SetText("200%")
sHigh:SetTextColor(C.fgDisabled[1], C.fgDisabled[2], C.fgDisabled[3])

local function UpdateScaleFill(value)
    local ratio = (value - 0.5) / 1.5
    local w = scaleSlider:GetWidth()
    if w and w > 0 then sFill:SetWidth(math_max(1, w * ratio)) end
end

scaleSlider:SetScript("OnMouseUp", function(self)
    local value = self:GetValue()
    SolaQoLDB.configScale = value
    ModernConfig:SetScale(value)
end)
scaleSlider:SetScript("OnValueChanged", function(self, value)
    SolaQoLDB.configScale = value
    UpdateScaleLabel(value)
    UpdateScaleFill(value)
    if not IsMouseButtonDown("LeftButton") then
        ModernConfig:SetScale(value)
    end
end)
scaleSlider:SetScript("OnSizeChanged", function(self) UpdateScaleFill(self:GetValue()) end)


ModernConfig:SetScript("OnShow", function()
    local scale = SolaQoLDB.configScale or 1.0
    scaleSlider:SetValue(scale)
    ModernConfig:SetScale(scale)

    -- Refresh unread changelog badge
    UpdateChangelogBadge()

    if not activeCategory then
        -- Load first tab if nothing selected yet
        SelectCategory("greetings")
    else
        -- Refresh open tabs
        for _, panel in pairs(contentPanels) do
            if panel.refresh then panel.refresh() end
        end
    end
end)


local p = CreateFrame("Frame", "SolaQoLOptionsPanel", UIParent)
p.name = "SolaQoL"

local stubText = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
stubText:SetPoint("TOPLEFT", 16, -16)
stubText:SetText("SolaQoL")

local openBtn = CreateFrame("Button", nil, p, "BackdropTemplate")
openBtn:SetSize(600, 72)
openBtn:SetPoint("TOPLEFT", stubText, "BOTTOMLEFT", 0, -30)
openBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
openBtn:SetBackdropColor(C.bgSelected[1], C.bgSelected[2], C.bgSelected[3], 1)
openBtn:SetBackdropBorderColor(0, 0, 0, 0.65)

local openBtnText = openBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
openBtnText:SetPoint("CENTER")
openBtnText:SetText(L.OPEN_SETTINGS)
openBtnText:SetTextColor(C.fgMain[1], C.fgMain[2], C.fgMain[3])

openBtn:SetScript("OnEnter", function()
    openBtn:SetBackdropColor(C.bgHover[1], C.bgHover[2], C.bgHover[3], 1)
end)
openBtn:SetScript("OnLeave", function()
    openBtn:SetBackdropColor(C.bgSelected[1], C.bgSelected[2], C.bgSelected[3], 1)
end)
openBtn:SetScript("OnClick", function() ModernConfig:Show() end)

if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(p, p.name)
    Settings.RegisterAddOnCategory(category)
    p.category = category
else
    InterfaceOptions_AddCategory(p)
end

-- ==========================================================
-- Update Notice Popup (Shows once per version)
-- ==========================================================
local updatePopup
local function ShowUpdatePopup(ver)
    if not updatePopup then
        updatePopup = CreateFrame("Frame", "SolaQoLUpdatePopup", UIParent, "BackdropTemplate")
        updatePopup:SetSize(450, 320)
        updatePopup:SetScale(1.32) -- Increased by an additional 15% (1.15 * 1.15)
        updatePopup:SetPoint("CENTER", 0, 100)
        updatePopup:SetFrameStrata("DIALOG")
        
        -- Make it draggable like the main config window
        updatePopup:SetMovable(true)
        updatePopup:EnableMouse(true)
        updatePopup:RegisterForDrag("LeftButton")
        updatePopup:SetScript("OnDragStart", updatePopup.StartMoving)
        updatePopup:SetScript("OnDragStop", updatePopup.StopMovingOrSizing)
        
        updatePopup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        updatePopup:SetBackdropColor(C.bgMain[1], C.bgMain[2], C.bgMain[3], 0.95)
        updatePopup:SetBackdropBorderColor(0, 0, 0, 0.65)

        -- Header
        local header = CreateFrame("Frame", nil, updatePopup, "BackdropTemplate")
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(32)
        header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        header:SetBackdropColor(C.bgHover[1], C.bgHover[2], C.bgHover[3], 0.8)
        
        local topGoldLine = header:CreateTexture(nil, "OVERLAY")
        topGoldLine:SetPoint("TOPLEFT", 0, 0)
        topGoldLine:SetPoint("TOPRIGHT", 0, 0)
        topGoldLine:SetHeight(1.5)
        topGoldLine:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)

        local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("CENTER")
        title:SetText("|cffD4A745SolaQoL|r")
        updatePopup.title = title

        -- Content Text
        local dateLbl = updatePopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        dateLbl:SetPoint("TOPLEFT", 25, -60)
        dateLbl:SetJustifyH("LEFT")
        dateLbl:SetJustifyV("TOP")
        updatePopup.dateLbl = dateLbl

        local desc = updatePopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", dateLbl, "BOTTOMLEFT", 0, -10) -- 70% of a full newline spacing
        desc:SetPoint("BOTTOMRIGHT", -25, 55)
        desc:SetJustifyH("LEFT")
        desc:SetJustifyV("TOP")
        desc:SetSpacing(4)
        updatePopup.desc = desc

        -- Close Button (Modern Green Theme)
        local closeBtn = CreateFrame("Button", nil, updatePopup, "BackdropTemplate")
        closeBtn:SetSize(140, 30)
        closeBtn:SetPoint("BOTTOM", 0, 12)
        closeBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        -- Balanced confirm green (Tailwind green-400: #4ade80 -> ~0.29, 0.87, 0.50)
        local cR, cG, cB = 0.29, 0.87, 0.50
        local hR, hG, hB = 0.52, 0.93, 0.67 -- Hover: Tailwind green-300 (#86efac)

        -- Base color is dark green
        closeBtn:SetBackdropColor(cR * 0.2, cG * 0.2, cB * 0.2, 1)
        closeBtn:SetBackdropBorderColor(0, 0, 0, 0.8)

        local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeTxt:SetPoint("CENTER")
        closeTxt:SetText(L.BTN_CONFIRM_CLOSE or "Confirm & Close")
        
        -- Text: White with outline, no shadow
        local font, size = closeTxt:GetFont()
        closeTxt:SetFont(font, size, "OUTLINE")
        closeTxt:SetShadowColor(0, 0, 0, 0)
        closeTxt:SetTextColor(1, 1, 1)

        -- Animated fill
        local fill = closeBtn:CreateTexture(nil, "BORDER")
        fill:SetPoint("TOPLEFT", 1, -1)
        fill:SetPoint("BOTTOMLEFT", 1, 1)
        -- Fill is SOLID green
        fill:SetColorTexture(cR, cG, cB, 1)
        fill:SetWidth(1)

        closeBtn:SetScript("OnUpdate", function(self, elapsed)
            local targetWidth = self:GetWidth() - 2
            if not self.fillWidth then self.fillWidth = 1 end
            if self.fillWidth < targetWidth then
                self.fillWidth = self.fillWidth + (targetWidth / 1.5) * elapsed
                if self.fillWidth > targetWidth then self.fillWidth = targetWidth end
                fill:SetWidth(self.fillWidth)
            end
        end)

        closeBtn:SetScript("OnEnter", function(self)
            local targetWidth = self:GetWidth() - 2
            if self.fillWidth and self.fillWidth >= targetWidth then
                -- Bright green on hover if animation is done
                fill:SetColorTexture(hR, hG, hB, 1)
            end
        end)
        closeBtn:SetScript("OnLeave", function(self)
            -- Revert to solid green
            fill:SetColorTexture(cR, cG, cB, 1)
        end)

        closeBtn:SetScript("OnClick", function(self)
            local targetWidth = self:GetWidth() - 2
            if not self.fillWidth or self.fillWidth < targetWidth then
                return -- Do not close until the animation is completely full
            end
            SolaQoLDB.lastShownPopupVersion = ver
            updatePopup:Hide()
        end)
    end
    
    local text = L.UPDATE_POPUP_TEXT or "Placeholder Text"
    local p1, p2, p3 = string.match(text, "^(.-)\n\n%s*(.-)\n\n%s*(.+)$")
    
    if p1 and p2 and p3 then
        updatePopup.dateLbl:SetText(p1)
        
        if not updatePopup.titleLbl then
            updatePopup.titleLbl = updatePopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            updatePopup.titleLbl:SetJustifyH("LEFT")
            updatePopup.titleLbl:SetJustifyV("TOP")
        end
        
        updatePopup.titleLbl:ClearAllPoints()
        updatePopup.titleLbl:SetPoint("TOPLEFT", updatePopup.dateLbl, "BOTTOMLEFT", 0, -16)
        updatePopup.titleLbl:SetText(p2)
        updatePopup.titleLbl:Show()
        
        updatePopup.desc:ClearAllPoints()
        updatePopup.desc:SetPoint("TOPLEFT", updatePopup.titleLbl, "BOTTOMLEFT", 0, -6) -- Small gap
        updatePopup.desc:SetPoint("BOTTOMRIGHT", -25, 55)
        updatePopup.desc:SetText(p3)
    else
        updatePopup.dateLbl:SetText("")
        if updatePopup.titleLbl then updatePopup.titleLbl:Hide() end
        updatePopup.desc:ClearAllPoints()
        updatePopup.desc:SetPoint("TOPLEFT", updatePopup.dateLbl, "TOPLEFT", 0, 0)
        updatePopup.desc:SetPoint("BOTTOMRIGHT", -25, 55)
        updatePopup.desc:SetText(text)
    end
    
    updatePopup:Show()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    -- Only trigger the popup for specific major versions to avoid re-showing on minor hotfixes
    local targetPopupVersion = "0.5.2"
    if not SolaQoLDB.lastShownPopupVersion or SolaQoLDB.lastShownPopupVersion ~= targetPopupVersion then
        C_Timer.After(2, function() ShowUpdatePopup(targetPopupVersion) end)
    end
end)
