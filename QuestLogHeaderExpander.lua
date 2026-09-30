-- QuestLogHeaderExpander.lua
-- Interface: 16001

local addon = CreateFrame("Frame")
local button
local modeSetting

--------------------------------------------------
-- Saved variables / modes
--------------------------------------------------

local DEFAULTS = {
    mode = "default",   
    lastState = nil,    
}

local MODES = {
    { value = "default",   label = "Default" },
    { value = "collapsed", label = "Always collapsed" },
    { value = "expanded",  label = "Always expanded" },
    -- Not working, to fix later
    -- { value = "remember",  label = "Remember previous state" },
}

local function InitDB()
    QuestLogHeaderExpanderDB = QuestLogHeaderExpanderDB or {}
    for k, v in pairs(DEFAULTS) do
        if QuestLogHeaderExpanderDB[k] == nil then
            QuestLogHeaderExpanderDB[k] = v
        end
    end
end

local function GetMode()
    return QuestLogHeaderExpanderDB.mode
end

local function SetMode(value)
    if modeSetting then
        modeSetting:SetValue(value)
    else
        QuestLogHeaderExpanderDB.mode = value
    end
end

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function AreAllHeadersExpanded()
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and info.isHeader and info.isCollapsed then
            return false
        end
    end
    return true
end

local searchBoxHooked = false

local function ResizeSearchBox()
    local sb = QuestScrollFrame and QuestScrollFrame.SearchBox
    if not sb then return end

    if sb:GetWidth() ~= 150 then
        sb:SetWidth(150)
    end

    if not searchBoxHooked then
        searchBoxHooked = true
        sb:HookScript("OnShow", ResizeSearchBox)
    end
end

local function UpdateButton()
    if not button then return end

    ResizeSearchBox()

    local text = AreAllHeadersExpanded() and "- All" or "+ All"
    if button:GetText() ~= text then
        button:SetText(text)
    end
end

local function SetAllHeaders(expand)
    if expand then
        ExpandQuestHeader(0)
    else
        CollapseQuestHeader(0)
    end
end

local function ApplyDefaultState()
    local mode = GetMode()
    local target

    if mode == "expanded" or mode == "collapsed" then
        target = mode
   -- elseif mode == "remember" then
   --     target = QuestLogHeaderExpanderDB.lastState
    end

    if target then
        SetAllHeaders(target == "expanded")
    end
end

--------------------------------------------------
-- Context menu and options menu
--------------------------------------------------

local function ShowContextMenu(owner)
    if not MenuUtil then return end

    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("When the map opens")

        for _, opt in ipairs(MODES) do
            root:CreateRadio(
                opt.label,
                function() return GetMode() == opt.value end,
                function() SetMode(opt.value) end
            )
        end
    end)
end

local function CreateOptionsPanel()
    if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end

    local category = Settings.RegisterVerticalLayoutCategory("Quest Log Header Expander")

    modeSetting = Settings.RegisterAddOnSetting(
        category,
        "QuestLogHeaderExpander_MODE",
        "mode",
        QuestLogHeaderExpanderDB,
        Settings.VarType.String,
        "Quest header behaviour",
        DEFAULTS.mode
    )

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        for _, opt in ipairs(MODES) do
            container:Add(opt.value, opt.label)
        end
        return container:GetData()
    end

    Settings.CreateDropdown(
        category,
        modeSetting,
        GetOptions,
        "What the quest log headers do each time the map is opened."
    )

    Settings.RegisterAddOnCategory(category)
    addon.category = category
end

--------------------------------------------------
-- Create Button
--------------------------------------------------

local function CreateExpandButton()
    if button then return end

    local parent = QuestMapFrame and QuestMapFrame.QuestsFrame
    if not parent then return end

    button = CreateFrame("Button", "QuestLogHeaderExpanderButton", parent, "UIPanelButtonTemplate")
    button:SetSize(50, 20)

    if QuestLogQuestCount then
        button:SetPoint("RIGHT", QuestLogQuestCount, "RIGHT", 54, 0)
    else
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, 24)
    end

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            ShowContextMenu(self)
            return
        end

        local expanding = not AreAllHeadersExpanded()
        SetAllHeaders(expanding)
        QuestLogHeaderExpanderDB.lastState = expanding and "expanded" or "collapsed"
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Quest Headers")
        GameTooltip:AddLine("Left click to toggle all zone headers.", 1, 1, 1, true)
        GameTooltip:AddLine("Right click for options.", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", GameTooltip_Hide)

    -- Re-apply the chosen state whenever the map opens. Deferred a frame so it runs after Blizzard's own "expand current zone" logic.
    QuestMapFrame:HookScript("OnShow", function()
        C_Timer.After(0, ApplyDefaultState)
    end)

    UpdateButton()
end

--------------------------------------------------
-- Events
--------------------------------------------------

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("QUEST_LOG_UPDATE")

addon:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        InitDB()
        CreateOptionsPanel()
        CreateExpandButton()
    else
        UpdateButton()
    end
end)