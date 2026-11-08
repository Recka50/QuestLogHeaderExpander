-- QuestLogHeaderExpander.lua
-- Interface: 16001

local addon = CreateFrame("Frame")
local button
local untrackButton
local modeSetting
local untrackSetting
local zoneTrackSetting

--------------------------------------------------
-- Saved variables / modes
--------------------------------------------------

local DEFAULTS = {
    mode = "default",
    showUntrack = false,
    showZoneTrack = false,
    seenWelcome = false,
}

local MODES = {
    { value = "default",   label = "Default" },
    { value = "collapsed", label = "Always collapsed" },
    { value = "expanded",  label = "Always expanded" },
    { value = "remember",  label = "Remember previous state" },
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

local function IsZoneTrackEnabled()
    return QuestLogHeaderExpanderDB and QuestLogHeaderExpanderDB.showZoneTrack
end

local SEARCH_BOX_WIDTH = 150
local UNTRACK_BUTTON_WIDTH = 54

local function IsUntrackEnabled()
    return QuestLogHeaderExpanderDB and QuestLogHeaderExpanderDB.showUntrack
end

local function GetSearchBoxWidth()
    if IsUntrackEnabled() then
        return SEARCH_BOX_WIDTH - UNTRACK_BUTTON_WIDTH - 4
    end
    return SEARCH_BOX_WIDTH
end

local searchBoxHooked = false
local resizing = false

local function ResizeSearchBox()
    local sb = QuestScrollFrame and QuestScrollFrame.SearchBox
    if not sb or resizing then return end

    -- Guard against re-entrancy: SetWidth can fire OnSizeChanged synchronously
    resizing = true
    local width = GetSearchBoxWidth()
    if math.abs(sb:GetWidth() - width) > 0.5 then
        sb:SetWidth(width)
    end
    resizing = false

    if not searchBoxHooked then
        searchBoxHooked = true
        

        -- Sets placeholder text to 1 line, truncating instead of wrapping
        local placeholder = sb.Instructions
        if placeholder then
            if placeholder.SetWordWrap then placeholder:SetWordWrap(false) end
            if placeholder.SetMaxLines then placeholder:SetMaxLines(1) end
        end

        sb:HookScript("OnShow", ResizeSearchBox)
        -- Blizzard re-lays-out the quest log (e.g. when hovering a quest POI on the map) without hiding/showing the box, so also re-apply whenever its size changes.
        sb:HookScript("OnSizeChanged", ResizeSearchBox)

        -- Belt and braces: re-apply after Blizzard's own quest log refreshes.
        for _, fname in ipairs({ "QuestLogQuests_Update", "QuestMapFrame_UpdateAll" }) do
            if type(_G[fname]) == "function" then
                hooksecurefunc(fname, ResizeSearchBox)
            end
        end
    end
end

local function UpdateUntrackButton()
    if not untrackButton then return end
    untrackButton:SetShown(IsUntrackEnabled() and true or false)
end

--------------------------------------------------
-- Per-zone "Track" buttons on quest log headers
--------------------------------------------------

local HEADER_BUTTON_WIDTH = 52
local HEADER_BUTTON_RIGHT_OFFSET = -30

local RefreshHeaderButtons   -- forward declaration, defined below
local zoneFullyTracked = {}  -- last known state per zone title

local function FindHeader(title)
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and info.isHeader and info.title == title then
            return i, info
        end
    end
end

-- Returns the zone's quest IDs and whether every one is tracked.
-- Only sees quests that are visible, so the header must be expanded.
local function ScanZone(headerIndex)
    local ids, allTracked = {}, true
    for i = headerIndex + 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if not info or info.isHeader then break end

        if info.questID and not info.isHidden then
            ids[#ids + 1] = info.questID
            if not C_QuestLog.GetQuestWatchType(info.questID) then
                allTracked = false
            end
        end
    end
    return ids, (allTracked and #ids > 0)
end

local function TrackZone(title)
    local maxWatches = (Constants and Constants.QuestWatchConsts and Constants.QuestWatchConsts.MAX_QUEST_WATCHES)
        or MAX_WATCHABLE_QUESTS or 25

    -- Look the header up by title: indices shift whenever headers expand/collapse
    local headerIndex, header = FindHeader(title)
    if not headerIndex then return end

    -- A collapsed header hides its quests from the log, so open it temporarily
    local wasCollapsed = header.isCollapsed
    if wasCollapsed then ExpandQuestHeader(headerIndex) end

    local ids, allTracked = ScanZone(headerIndex)
    local full = false

    if allTracked then
        for _, questID in ipairs(ids) do
            C_QuestLog.RemoveQuestWatch(questID)
        end
    else
        for _, questID in ipairs(ids) do
            if not C_QuestLog.GetQuestWatchType(questID) then
                if C_QuestLog.GetNumQuestWatches() >= maxWatches
                    or C_QuestLog.AddQuestWatch(questID) == false then
                    full = true
                    break
                end
            end
        end
    end

    local _, nowAllTracked = ScanZone(headerIndex)
    zoneFullyTracked[title] = nowAllTracked

    if wasCollapsed then CollapseQuestHeader(headerIndex) end

    if full then
        print("|cffffd100Quest Log Header Expander:|r tracking limit reached (" .. maxWatches .. " quests).")
    end

    RefreshHeaderButtons()
end

local function GetHeaderTitle(frame, data)
    local info = type(data) == "table" and (data.info or data) or nil
    if info and info.isHeader and info.title then
        return info.title
    end
    if frame.questLogIndex then
        local logInfo = C_QuestLog.GetInfo(frame.questLogIndex)
        if logInfo and logInfo.isHeader then
            return logInfo.title
        end
    end
end

local function GetHeaderTrackButton(frame)
    if frame.QLHETrackButton then return frame.QLHETrackButton end

    local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    b:SetSize(HEADER_BUTTON_WIDTH, 16)
    b:SetPoint("RIGHT", frame, "RIGHT", HEADER_BUTTON_RIGHT_OFFSET, 0)
    b:SetFrameLevel(frame:GetFrameLevel() + 5)
    b:SetNormalFontObject(GameFontNormalSmall)
    b:SetHighlightFontObject(GameFontHighlightSmall)
    b:SetText("Track")
    b:SetScript("OnClick", function(self)
        if self.zoneTitle then TrackZone(self.zoneTitle) end
end)
    b:SetScript("OnEnter", function(self)
    local untracking = self:GetText() == "Untrack"
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(untracking and "Untrack Zone" or "Track Zone")
    GameTooltip:AddLine(
        untracking and "Stops tracking every quest in this zone."
                    or "Tracks every quest in this zone.",
        1, 1, 1, true
    )
    GameTooltip:Show()
end)
    b:SetScript("OnLeave", GameTooltip_Hide)

    frame.QLHETrackButton = b
    return b
end

-- Header frames are recycled by the scroll box, so (re)assign buttons every refresh
local function ApplyHeaderButton(frame, title)
    local b = frame.QLHETrackButton
    if title and IsZoneTrackEnabled() then
        b = b or GetHeaderTrackButton(frame)
        b.zoneTitle = title

        -- Exact for expanded zones; collapsed zones keep their last known state
        local index, header = FindHeader(title)
        if index and header and not header.isCollapsed then
            local _, allTracked = ScanZone(index)
            zoneFullyTracked[title] = allTracked
        end

        local text = zoneFullyTracked[title] and "Untrack" or "Track"
        if b:GetText() ~= text then
            b:SetText(text)
        end
        b:Show()
    elseif b then
        b:Hide()
    end
end

-- Header frames are recycled, so (re)assign buttons every refresh
function RefreshHeaderButtons()
    local sf = QuestScrollFrame
    if not sf then return end

    -- Newer-style scroll box
    local box = sf.ScrollBox
    if box and box.ForEachFrame then
        box:ForEachFrame(function(frame, data)
            ApplyHeaderButton(frame, GetHeaderTitle(frame, data))
        end)
        return
    end

    -- Classic-style scroll frame: the headers are children of the scroll child
    local contents = sf.Contents or (sf.GetScrollChild and sf:GetScrollChild())
    if not contents then return end

    for _, child in ipairs({ contents:GetChildren() }) do
        if child:IsShown() then
            ApplyHeaderButton(child, GetHeaderTitle(child))
        elseif child.QLHETrackButton then
            child.QLHETrackButton:Hide()
        end
    end
end

-- Header frames are recycled, so (re)assign buttons every refresh
local function RefreshHeaderButtons()
    local sf = QuestScrollFrame
    if not sf then return end

    -- Newer-style scroll box
    local box = sf.ScrollBox
    if box and box.ForEachFrame then
        box:ForEachFrame(function(frame, data)
            ApplyHeaderButton(frame, GetHeaderTitle(frame, data))
        end)
        return
    end

    -- Classic-style scroll frame: the headers are children of the scroll child
    local contents = sf.Contents or (sf.GetScrollChild and sf:GetScrollChild())
    if not contents then return end

    for _, child in ipairs({ contents:GetChildren() }) do
        if child:IsShown() then
            ApplyHeaderButton(child, GetHeaderTitle(child))
        elseif child.QLHETrackButton then
            child.QLHETrackButton:Hide()
        end
    end
end

local hookedFunctions = {}
local scrollBoxHooked = false

local function HookScrollBox()
    -- Re-run after Blizzard rebuilds the quest log. Each function is only marked
    -- as hooked once it actually exists, so this retries until it does.
    for _, fname in ipairs({ "QuestLogQuests_Update", "QuestMapFrame_UpdateAll" }) do
        if not hookedFunctions[fname] and type(_G[fname]) == "function" then
            hookedFunctions[fname] = true
            hooksecurefunc(fname, RefreshHeaderButtons)
        end
    end

    -- Only exists on clients that use a scroll box
    local box = QuestScrollFrame and QuestScrollFrame.ScrollBox
    local events = ScrollBoxListMixin and ScrollBoxListMixin.Event
    if not scrollBoxHooked and box and box.RegisterCallback and events and events.OnDataRangeChanged then
        scrollBoxHooked = true
        box:RegisterCallback(events.OnDataRangeChanged, RefreshHeaderButtons, addon)
    end
end

local function UpdateButton()
    if not button then return end

    ResizeSearchBox()
    UpdateUntrackButton()
    HookScrollBox()
    RefreshHeaderButtons()

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

local function UntrackAllQuests()
    -- Collect IDs first: removing a watch shifts the watch indices
    local ids = {}
    for i = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        if questID then
            ids[#ids + 1] = questID
        end
    end

    for _, questID in ipairs(ids) do
        C_QuestLog.RemoveQuestWatch(questID)
    end
end

local function SnapshotHeaders()
    local state = {}
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and info.isHeader then
            state[info.title] = info.isCollapsed and true or false
        end
    end
    QuestLogHeaderExpanderDB.headerState = state
end

local function RestoreHeaders()
    local saved = QuestLogHeaderExpanderDB.headerState
    if not saved then return end

    -- Go backwards: expanding/collapsing shifts the indices after it
    for i = C_QuestLog.GetNumQuestLogEntries(), 1, -1 do
        local info = C_QuestLog.GetInfo(i)
        if info and info.isHeader then
            local wantCollapsed = saved[info.title]
            if wantCollapsed ~= nil and wantCollapsed ~= info.isCollapsed then
                if wantCollapsed then
                    CollapseQuestHeader(i)
                else
                    ExpandQuestHeader(i)
                end
            end
        end
    end
end

local function ApplyDefaultState()
    local mode = GetMode()

    if mode == "expanded" or mode == "collapsed" then
        SetAllHeaders(mode == "expanded")
    elseif mode == "remember" then
        RestoreHeaders()
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

    untrackSetting = Settings.RegisterAddOnSetting(
        category,
        "QuestLogHeaderExpander_SHOW_UNTRACK",
        "showUntrack",
        QuestLogHeaderExpanderDB,
        Settings.VarType.Boolean,
        "Show Untrack All button",
        DEFAULTS.showUntrack
    )

    zoneTrackSetting = Settings.RegisterAddOnSetting(
        category,
        "QuestLogHeaderExpander_SHOW_ZONE_TRACK",
        "showZoneTrack",
        QuestLogHeaderExpanderDB,
        Settings.VarType.Boolean,
        "Show zone Track buttons",
        DEFAULTS.showZoneTrack
    )

    zoneTrackSetting:SetValueChangedCallback(function()
        UpdateButton()
    end)

    Settings.CreateCheckbox(
        category,
        zoneTrackSetting,
        "Adds a Track button to each zone header that tracks every quest in that zone, or untracks them if they're all already tracked."
    )

    untrackSetting:SetValueChangedCallback(function()
        UpdateButton()
    end)

    Settings.CreateCheckbox(
        category,
        untrackSetting,
        "Adds an Untrack button next to the + All button that stops tracking every quest at once."
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

    QuestMapFrame:HookScript("OnShow", function()
        C_Timer.After(0, function()
            ApplyDefaultState()
            RefreshHeaderButtons()
        end)
    end)

    QuestMapFrame:HookScript("OnHide", function() 
        if GetMode() == "remember" then
            SnapshotHeaders()
        end
    end)

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
        -- QuestLogHeaderExpanderDB.lastState = expanding and "expanded" or "collapsed"
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Quest Headers")
        GameTooltip:AddLine("Left click to toggle all zone headers.", 1, 1, 1, true)
        GameTooltip:AddLine("Right click for options.", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", GameTooltip_Hide)

    untrackButton = CreateFrame("Button", "QuestLogHeaderExpanderUntrackButton", parent, "UIPanelButtonTemplate")
    untrackButton:SetSize(UNTRACK_BUTTON_WIDTH, 20)
    untrackButton:SetPoint("LEFT", button, "RIGHT", 2, 0)
    untrackButton:SetText("Untrack")
    untrackButton:SetScript("OnClick", UntrackAllQuests)
    untrackButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Untrack All")
        GameTooltip:AddLine("Stops tracking every quest.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    untrackButton:SetScript("OnLeave", GameTooltip_Hide)
    untrackButton:Hide()

    -- Re-apply the chosen state whenever the map opens. Deferred a frame so it runs after Blizzard's own "expand current zone" logic.
    QuestMapFrame:HookScript("OnShow", function()
        C_Timer.After(0, ApplyDefaultState)
    end)

    UpdateButton()
end

--------------------------------------------------
-- Slash commands
--------------------------------------------------

local PREFIX = "|cffffd100Quest Log Header Expander:|r "

local function Say(msg)
    print(PREFIX .. msg)
end

local function OpenOptions()
    if not (addon.category and Settings and Settings.OpenToCategory) then
        Say("options aren't available on this client.")
        return
    end
    if InCombatLockdown() then
        Say("can't open the options during combat.")
        return
    end
    Settings.OpenToCategory(addon.category:GetID())
end

local COMMANDS = {
    { "options",       "Opens the addon's options." },
    { "toggleuntrack", "Toggles the Untrack All button." },
    { "toggletrack",   "Toggles the zone Track buttons." },
    { "untrackall",    "Untracks every quest, even if the button is disabled." },
}

local function ShowHelp()
    Say("commands")
    print("  |cffffd100/qlhe|r - Shows this list.")
    for _, cmd in ipairs(COMMANDS) do
        print("  |cffffd100/qlhe " .. cmd[1] .. "|r - " .. cmd[2])
    end
end

-- Goes through the Settings object when we have one so the checkbox stays in sync
local function ToggleOption(setting, key)
    if setting then
        setting:SetValue(not setting:GetValue())
    else
        QuestLogHeaderExpanderDB[key] = not QuestLogHeaderExpanderDB[key]
        UpdateButton()
    end
    return QuestLogHeaderExpanderDB[key]
end

local function OnOff(value)
    return value and "|cff00ff00enabled|r" or "|cffff4040disabled|r"
end

SLASH_QLHE1 = "/qlhe"

SlashCmdList["QLHE"] = function(msg)
    local cmd = strlower(strtrim(msg or ""))

    if cmd == "" or cmd == "help" then
        ShowHelp()

    elseif cmd == "options" then
        OpenOptions()

    elseif cmd == "toggleuntrack" then
        Say("Untrack All button " .. OnOff(ToggleOption(untrackSetting, "showUntrack")))

    elseif cmd == "toggletrack" then
        Say("Zone Track buttons " .. OnOff(ToggleOption(zoneTrackSetting, "showZoneTrack")))

    elseif cmd == "untrackall" then
        UntrackAllQuests()
        Say("all quests untracked.")

    else
        Say("unknown command '" .. cmd .. "'.")
        ShowHelp()
    end
end

--------------------------------------------------
-- One-time welcome popup
--------------------------------------------------

StaticPopupDialogs["QLHE_WELCOME"] = {
    text = "|cffffd100Quest Log Header Expander|r\n\n"
        .. "There are now optional extras: an |cffffd100Untrack All|r button and per-zone |cffffd100Track|r buttons. "
        .. "Both are off by default and can be enabled in the addon's options.\n\n"
        .. "Type |cffffd100/qlhe|r for a list of commands.",
    button1 = "Open Options",
    button2 = "Close",
    OnAccept = OpenOptions,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function ShowWelcomeIfNeeded()
    if QuestLogHeaderExpanderDB.seenWelcome then return end
    QuestLogHeaderExpanderDB.seenWelcome = true   -- set before showing so it can never repeat
    StaticPopup_Show("QLHE_WELCOME")
end

--------------------------------------------------
-- Events
--------------------------------------------------

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("QUEST_LOG_UPDATE")
pcall(addon.RegisterEvent, addon, "QUEST_WATCH_LIST_CHANGED")
addon:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        InitDB()
        CreateOptionsPanel()
        CreateExpandButton()
        C_Timer.After(3, ShowWelcomeIfNeeded)
    else
        UpdateButton()
    end
end)
