-- QuestExpandAll.lua
-- Interface: 16001

local addon = CreateFrame("Frame")
local button  -- set in CreateExpandButton

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

local function UpdateButton()
    if not button then return end

    local text = AreAllHeadersExpanded() and "- All" or "+ All"
    if button:GetText() ~= text then
        button:SetText(text)
    end
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

--------------------------------------------------
-- Create Button
--------------------------------------------------

local function CreateExpandButton()
    if button then return end

    local parent = QuestMapFrame and QuestMapFrame.QuestsFrame
    if not parent then return end

    button = CreateFrame("Button", "QuestExpandAllButton", parent, "UIPanelButtonTemplate")
    button:SetSize(50, 20)

    if QuestLogQuestCount then
        button:SetPoint("RIGHT", QuestLogQuestCount, "RIGHT", 54, 0)
    else
        button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, 24)
    end

    button:SetScript("OnClick", function()
        if AreAllHeadersExpanded() then
            CollapseQuestHeader(0)
        else
            ExpandQuestHeader(0)
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Quest Headers")
        GameTooltip:AddLine("Left click to toggle all zone headers.", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", GameTooltip_Hide)

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
        CreateExpandButton()
    else
        UpdateButton()
    end
end)