-- QuestExpandAll.lua
-- Interface: 16001

local addon = CreateFrame("Frame")

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function AreAllHeadersExpanded()

local numEntries = C_QuestLog.GetNumQuestLogEntries()

--------------------------------------------------
-- Resize search box to fit button
--------------------------------------------------

local function ResizeSearchBox()
    local sb = QuestScrollFrame and QuestScrollFrame.SearchBox
    if sb then
        sb:SetWidth(150)
    end
end

if QuestScrollFrame and QuestScrollFrame.SearchBox then
    QuestScrollFrame.SearchBox:HookScript("OnShow", ResizeSearchBox)
end
ResizeSearchBox()

for i = 1, numEntries do
    local info = C_QuestLog.GetInfo(i)

    if info and info.isHeader and info.isCollapsed then
        return false
        end
        end

        return true
        end

        local function UpdateButton(button)
        if AreAllHeadersExpanded() then
            button:SetText("- All")
            else
                button:SetText("+ All")
                end
                end

                --------------------------------------------------
                -- Create Button
                --------------------------------------------------

                local function CreateExpandButton()

                if QuestExpandAllButton then
                    return
                    end

                    -- Wait until the Quest Map exists
                    if not QuestMapFrame or not QuestMapFrame.QuestsFrame then
                        return
                        end

                        local parent = QuestMapFrame.QuestsFrame

                        local button = CreateFrame(
                            "Button",
                            "QuestExpandAllButton",
                            parent,
                            "UIPanelButtonTemplate"
                        )

                        button:SetSize(50,20)
                        button:SetPoint("RIGHT", QuestLogQuestCount, "RIGHT", 54, 0)
                        button:SetScript("OnClick", function(self)

                        if AreAllHeadersExpanded() then
                            CollapseQuestHeader(0)
                            else
                                ExpandQuestHeader(0)
                                end

                                C_Timer.After(0, function()
                                UpdateButton(self)
                                end)

                                end)

                        button:SetScript("OnEnter", function(self)

                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine("Quest Headers")
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Left Click to toggle all zone headers.",1,1,1,true)
                        GameTooltip:Show()

                        end)

                        button:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                        end)

                        UpdateButton(button)

                        end

                        --------------------------------------------------
                        -- Events
                        --------------------------------------------------

                        addon:RegisterEvent("PLAYER_LOGIN")
                        addon:RegisterEvent("QUEST_LOG_UPDATE")

                        addon:SetScript("OnEvent", function(self, event)

                        if event == "PLAYER_LOGIN" then

                            CreateExpandButton()

                            elseif event == "QUEST_LOG_UPDATE" then

                                if QuestExpandAllButton then
                                    UpdateButton(QuestExpandAllButton)
                                    end

                                    end

                                    end)
