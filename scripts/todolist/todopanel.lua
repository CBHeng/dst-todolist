-- 常駐在 HUD 上的待辦面板：標題列點一下收合 / 展開，「＋ 新增」彈出輸入框。

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/redux/templates"
local TodoInputScreen = require "todolist/todoinputscreen"

local PANEL_W = 300
local HEADER_H = 40
local ROW_H = 32
local VISIBLE_ROWS = 6
local LIST_H = ROW_H * VISIBLE_ROWS + 20
local FOOTER_H = 50
local BODY_H = LIST_H + FOOTER_H

-- 面板的原點是「標題列中心」，內容往下長
local TodoPanel = Class(Widget, function(self, owner, store)
    Widget._ctor(self, "TodoPanel")

    self.owner = owner
    self.store = store
    self.expanded = false

    self.header = self:AddChild(TEMPLATES.StandardButton(function() self:SetExpanded(not self.expanded) end, "", { PANEL_W, HEADER_H }))

    self.body = self:AddChild(Widget("todolist_body"))
    self.body:SetPosition(0, -HEADER_H / 2 - BODY_H / 2)

    self.bg = self.body:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(PANEL_W, BODY_H)
    self.bg:SetTint(0, 0, 0, 0.6)

    self.list_root = self.body:AddChild(Widget("todolist_list_root"))
    self.list_root:SetPosition(-10, FOOTER_H / 2)
    self.scroll_list = self.list_root:AddChild(ScrollableList({}, PANEL_W - 30, LIST_H, ROW_H, 0))

    self.empty_text = self.list_root:AddChild(Text(CHATFONT, 24, "目前沒有待辦事項", UICOLOURS.GREY))

    self.add_button = self.body:AddChild(TEMPLATES.StandardButton(function() self:OpenInput() end, "＋ 新增", { 140, 38 }))
    self.add_button:SetPosition(0, -BODY_H / 2 + FOOTER_H / 2)

    self:Refresh()
    -- 有還沒做完的事就攤開提醒，沒有就收起來不佔畫面
    self:SetExpanded(store:CountUnfinished() > 0)
end)

function TodoPanel:SetExpanded(expanded)
    self.expanded = expanded
    if expanded then
        self.body:Show()
    else
        self.body:Hide()
    end
    self:RefreshHeader()
end

function TodoPanel:RefreshHeader()
    local n = self.store:CountUnfinished()
    self.header:SetText(string.format("待辦 (%d)　%s", n, self.expanded and "收合" or "展開"))
end

function TodoPanel:OpenInput()
    TheFrontEnd:PushScreen(TodoInputScreen(function(text)
        if self.store:Add(text) then
            self:Refresh()
            self.scroll_list:Scroll(#self.store:GetItems(), true)
            return true
        end
        return false
    end))
end

function TodoPanel:BuildRow(index, item)
    -- ScrollableList 以 widget 的原點當作左緣
    local row = Widget("todolist_row")
    local list_w = PANEL_W - 30

    row.checkbox = row:AddChild(TEMPLATES.StandardCheckbox(function()
        local done = self.store:ToggleDone(index)
        self:RefreshDeferred()
        return done
    end, 26, item.done))
    row.checkbox:SetPosition(16, 0)

    row.label = row:AddChild(Text(CHATFONT, 22, nil, item.done and UICOLOURS.GREY or UICOLOURS.WHITE))
    row.label:SetHAlign(ANCHOR_LEFT)
    row.label:SetTruncatedString(item.text, list_w - 90, nil, true)
    local w = row.label:GetRegionSize()
    row.label:SetPosition(36 + w / 2, 0)

    row.delete_button = row:AddChild(TEMPLATES.StandardButton(function()
        self.store:Remove(index)
        self:RefreshDeferred()
    end, "刪", { 34, 28 }))
    row.delete_button:SetPosition(list_w - 26, 0)

    return row
end

function TodoPanel:Refresh()
    local rows = {}
    for i, item in ipairs(self.store:GetItems()) do
        table.insert(rows, self:BuildRow(i, item))
    end
    self.scroll_list:SetList(rows, false, self.scroll_list.view_offset)

    if #rows == 0 then
        self.empty_text:Show()
    else
        self.empty_text:Hide()
    end
    self:RefreshHeader()
end

-- 按鈕的 onclick 執行完後還會操作自己，不能在 callback 裡直接把它 Kill 掉
function TodoPanel:RefreshDeferred()
    self.inst:DoTaskInTime(0, function() self:Refresh() end)
end

return TodoPanel
