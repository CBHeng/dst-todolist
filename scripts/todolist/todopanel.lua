-- 常駐在 HUD 上的待辦面板：拖曳標題列移動，工具列按鈕收合 / 清空清單，「＋ 新增」彈出輸入框。

local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ScrollableList = require "widgets/scrollablelist"
local TEMPLATES = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TodoInputScreen = require "todolist/todoinputscreen"
local Layout = require "todolist/layout"
local L = require "todolist/i18n"

local PANEL_W = 240
local HEADER_H = 28
local ROW_H = 32
-- 清單高度跟著項目數長，最多長到這麼多列，再多就捲動
local MAX_VISIBLE_ROWS = 6
local LIST_PAD = 4
local FOOTER_H = 32
local MIN_BODY_H = 80
-- ScrollableList 會把第一列放在「頂端往下 20」的位置（半個箭頭按鈕高），
-- 往上補回來讓列剛好貼齊清單頂端
local LIST_Y_INIT = 20 - ROW_H / 2

local TOOL_BUTTON_W, TOOL_BUTTON_H = 50, 22
-- StandardButton 會依按鈕高度自動算字級，按鈕扁了字會太小，這裡固定字級
local TOOL_TEXT_SIZE = 14
-- 工具列按鈕、刪除按鈕離面板右緣的距離，兩者右緣對齊
local RIGHT_MARGIN = 6
local DELETE_W, DELETE_H = 34, 26

-- 捲軸畫在清單寬度的右緣；把清單加寬讓捲軸落在面板外側，才不會蓋住刪除按鈕。
-- 列本身仍從面板左緣開始排，寬度等於面板寬。
local SCROLLBAR_OUTSET = 14
local LIST_W = PANEL_W + SCROLLBAR_OUTSET * 2
local ROW_X_OFFSET = SCROLLBAR_OUTSET

-- 沒存過位置時：螢幕右緣往左 170、垂直中線往上 260（單位為 HUD 座標）
local DEFAULT_OFFSET_X, DEFAULT_OFFSET_Y = -170, 260

-- 父節點座標換算成螢幕像素時用的量測距離
local PROBE_DIST = 100

-- 面板的原點是「標題列中心」，內容往下長。
-- 標題列像視窗的標題列：按住空白處拖曳移動，右側按鈕各自點擊。
local TodoPanel = Class(Widget, function(self, owner, store, saved_pos)
    Widget._ctor(self, "TodoPanel")

    self.owner = owner
    self.store = store
    self.expanded = false
    -- 標題列中心佔螢幕寬 / 高的比例，nil 代表用預設位置
    self.pos = saved_pos

    self.header = self:AddChild(Widget("todolist_header"))

    self.header_bg = self.header:AddChild(Image("images/global.xml", "square.tex"))
    self.header_bg:SetSize(PANEL_W, HEADER_H)
    self.header_bg:SetTint(0.15, 0.13, 0.1, 0.55)
    self.header_bg.OnMouseButton = function(_, button, down)
        if button == MOUSEBUTTON_LEFT and down then
            self:StartDrag()
            return true
        end
    end

    -- 標題文字不吃滑鼠，按在字上也算按在標題列上
    self.title = self.header:AddChild(Text(CHATFONT, 18, nil, UICOLOURS.GOLD))
    self.title:SetHAlign(ANCHOR_LEFT)
    self.title:SetClickable(false)

    self.toggle_button = self.header:AddChild(TEMPLATES.StandardButton(function()
        self:SetExpanded(not self.expanded)
    end, "", { TOOL_BUTTON_W, TOOL_BUTTON_H }))
    self.toggle_button:SetPosition(PANEL_W / 2 - RIGHT_MARGIN - TOOL_BUTTON_W / 2, 0)
    self.toggle_button:SetTextSize(TOOL_TEXT_SIZE)

    self.clear_button = self.header:AddChild(TEMPLATES.StandardButton(function()
        self:ConfirmClear()
    end, L.Get("CLEAR"), { TOOL_BUTTON_W, TOOL_BUTTON_H }))
    self.clear_button:SetPosition(PANEL_W / 2 - RIGHT_MARGIN - 4 - TOOL_BUTTON_W * 1.5, 0)
    self.clear_button:SetTextSize(TOOL_TEXT_SIZE)

    -- 內容區的高度跟著項目數變動，實際排版在 LayoutBody
    self.body = self:AddChild(Widget("todolist_body"))

    self.bg = self.body:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetTint(0, 0, 0, 0.6)

    self.list_root = self.body:AddChild(Widget("todolist_list_root"))

    self.empty_text = self.list_root:AddChild(Text(CHATFONT, 18, L.Get("EMPTY"), UICOLOURS.GREY))

    self.add_button = self.body:AddChild(TEMPLATES.StandardButton(function() self:OpenInput() end, L.Get("ADD"), { TOOL_BUTTON_W, TOOL_BUTTON_H }))
    self.add_button:SetTextSize(TOOL_TEXT_SIZE)

    self:Refresh()
    -- 有還沒做完的事就攤開提醒，沒有就收起來不佔畫面
    self:SetExpanded(store:CountUnfinished() > 0)

    -- 偵測解析度 / HUD 大小變化，重新套用位置
    self:StartUpdating()
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
    self.title:SetString(string.format(L.Get("TITLE"), self.store:CountUnfinished()))
    local w = self.title:GetRegionSize()
    self.title:SetPosition(-PANEL_W / 2 + 12 + w / 2, 0)
    self.toggle_button:SetText(self.expanded and L.Get("COLLAPSE") or L.Get("EXPAND"))
end

---------------------------------------------------------------------------
-- 位置與拖曳
-- 面板的父節點錨在螢幕左下角；滑鼠座標是螢幕像素，
-- 所以在兩者之間換算時要用父節點實際的縮放倍率。

-- 父節點的 1 單位等於多少螢幕像素（含 HUD 大小與解析度縮放）
function TodoPanel:GetParentScale()
    if self.scale_probe == nil then
        self.scale_probe = self.parent:AddChild(Widget("todolist_scale_probe"))
        self.scale_probe:SetPosition(PROBE_DIST, 0)
    end
    local s = (self.scale_probe:GetWorldPosition().x - self.parent:GetWorldPosition().x) / PROBE_DIST
    return s > 0 and s or 1
end

-- 把標題列中心放到螢幕座標 (x, y)，並夾在畫面內讓標題列整條看得到
function TodoPanel:SetScreenPosition(x, y)
    local sw, sh = TheSim:GetScreenSize()
    local s = self:GetParentScale()
    local half_w, half_h = PANEL_W / 2 * s, HEADER_H / 2 * s
    x = math.clamp(x, half_w, math.max(half_w, sw - half_w))
    y = math.clamp(y, half_h, math.max(half_h, sh - half_h))

    local origin = self.parent:GetWorldPosition()
    self:SetPosition((x - origin.x) / s, (y - origin.y) / s)
    return x / sw, y / sh
end

function TodoPanel:ApplyPosition()
    local sw, sh = TheSim:GetScreenSize()
    local s = self:GetParentScale()
    self.last_sw, self.last_sh, self.last_scale = sw, sh, s

    if self.pos ~= nil then
        self:SetScreenPosition(self.pos.x * sw, self.pos.y * sh)
    else
        self:SetScreenPosition(sw + DEFAULT_OFFSET_X * s, sh / 2 + DEFAULT_OFFSET_Y * s)
    end
end

function TodoPanel:StartDrag()
    if self.dragging then
        return
    end
    self.dragging = true

    -- 記住按下的點離標題列中心多遠，拖曳時維持這個距離，面板才不會「跳」到滑鼠上
    local mouse = TheInput:GetScreenPosition()
    local center = self:GetWorldPosition()
    local dx, dy = center.x - mouse.x, center.y - mouse.y

    self.drag_move_handler = TheInput:AddMoveHandler(function(x, y)
        local fx, fy = self:SetScreenPosition(x + dx, y + dy)
        self.pos = { x = fx, y = fy }
    end)
    -- 放開的偵測掛在全域：拖太快時滑鼠可能已經不在標題列上
    self.drag_release_handler = TheInput:AddMouseButtonHandler(function(button, down)
        if button == MOUSEBUTTON_LEFT and not down then
            self:StopDrag()
        end
    end)
end

function TodoPanel:StopDrag()
    if not self.dragging then
        return
    end
    self.dragging = false
    self.drag_move_handler:Remove()
    self.drag_release_handler:Remove()
    self.drag_move_handler, self.drag_release_handler = nil, nil

    if self.pos ~= nil then
        Layout.Save(self.pos)
    end
end

function TodoPanel:OnUpdate()
    if self.dragging then
        return
    end
    local sw, sh = TheSim:GetScreenSize()
    if sw ~= self.last_sw or sh ~= self.last_sh or self:GetParentScale() ~= self.last_scale then
        self:ApplyPosition()
    end
end

function TodoPanel:Kill()
    self:StopDrag()
    TodoPanel._base.Kill(self)
end

---------------------------------------------------------------------------

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

-- 一次刪掉全部，先跳確認框免得誤按
function TodoPanel:ConfirmClear()
    local n = #self.store:GetItems()
    if n == 0 then
        return
    end
    TheFrontEnd:PushScreen(PopupDialogScreen(L.Get("CLEAR_TITLE"), string.format(L.Get("CLEAR_BODY"), n),
    {
        { text = L.Get("CLEAR"), cb = function()
            TheFrontEnd:PopScreen()
            self.store:Clear()
            self:Refresh()
        end },
        { text = L.Get("CANCEL"), cb = function() TheFrontEnd:PopScreen() end },
    }))
end

function TodoPanel:BuildRow(index, item)
    -- ScrollableList 以 widget 的原點當作左緣
    local row = Widget("todolist_row")

    row.checkbox = row:AddChild(TEMPLATES.StandardCheckbox(function()
        local done = self.store:ToggleDone(index)
        self:RefreshDeferred()
        return done
    end, 26, item.done))
    row.checkbox:SetPosition(16, 0)

    row.label = row:AddChild(Text(CHATFONT, 18, nil, item.done and UICOLOURS.GREY or UICOLOURS.WHITE))
    row.label:SetHAlign(ANCHOR_LEFT)
    row.label:SetTruncatedString(item.text, PANEL_W - RIGHT_MARGIN - DELETE_W - 6 - 36, nil, true)
    local w = row.label:GetRegionSize()
    row.label:SetPosition(36 + w / 2, 0)

    row.delete_button = row:AddChild(TEMPLATES.StandardButton(function()
        self.store:Remove(index)
        self:RefreshDeferred()
    end, L.Get("DELETE"), { DELETE_W, DELETE_H }))
    row.delete_button:SetPosition(PANEL_W - RIGHT_MARGIN - DELETE_W / 2, 0)
    row.delete_button:SetTextSize(TOOL_TEXT_SIZE)

    return row
end

-- ScrollableList 的高度建立後就固定了，可見列數改變時整個重建，並重排內容區
function TodoPanel:LayoutBody(visible_rows)
    if self.visible_rows == visible_rows then
        return
    end
    self.visible_rows = visible_rows

    local list_h = ROW_H * visible_rows
    local body_h = math.max(MIN_BODY_H, LIST_PAD + list_h + FOOTER_H)

    self.body:SetPosition(0, -HEADER_H / 2 - body_h / 2)
    self.bg:SetSize(PANEL_W, body_h)

    local view_offset = 0
    if self.scroll_list ~= nil then
        view_offset = self.scroll_list.view_offset
        self.scroll_list:Kill()
    end
    self.scroll_list = self.list_root:AddChild(ScrollableList({}, LIST_W, list_h, ROW_H, 0,
        nil, nil, ROW_X_OFFSET, nil, nil, LIST_Y_INIT))
    self.list_root:SetPosition(0, body_h / 2 - LIST_PAD - list_h / 2)

    self.add_button:SetPosition(0, -body_h / 2 + FOOTER_H / 2)
    return view_offset
end

function TodoPanel:Refresh()
    local items = self.store:GetItems()
    local view_offset = self:LayoutBody(math.clamp(#items, 1, MAX_VISIBLE_ROWS)) or self.scroll_list.view_offset

    local rows = {}
    for i, item in ipairs(items) do
        table.insert(rows, self:BuildRow(i, item))
    end
    self.scroll_list:SetList(rows, false, view_offset)

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
