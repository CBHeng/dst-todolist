-- 按「＋ 新增」彈出的小輸入框。Enter 或「新增」成功後自動關閉，Esc 或點視窗外取消。

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local L = require "todolist/i18n"

local WINDOW_W, WINDOW_H = 460, 160
-- RectangleWindow 會把自己縮成 0.7 倍，這裡先放大回來讓外框貼齊
local WINDOW_SCALE = 0.7

local TodoInputScreen = Class(Screen, function(self, onsubmit)
    Screen._ctor(self, "TodoInputScreen")

    -- onsubmit(text) 回傳 true 代表成功新增
    self.onsubmit = onsubmit

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    -- 點視窗外面就關閉
    self.black = self:AddChild(TEMPLATES.BackgroundTint(0.3))
    self.black.OnMouseButton = function(_, button, down)
        if button == MOUSEBUTTON_LEFT and down then
            self:Close()
            return true
        end
    end

    self.root = self:AddChild(Widget("todolist_input_root"))
    self.root:SetScale(TheFrontEnd:GetHUDScale())

    self.window = self.root:AddChild(TEMPLATES.RectangleWindow(WINDOW_W / WINDOW_SCALE, WINDOW_H / WINDOW_SCALE, L.Get("INPUT_TITLE")))

    self.input = self.root:AddChild(TEMPLATES.StandardSingleLineTextEntry(nil, 400, 44, CHATFONT, 28, L.Get("INPUT_HINT")))
    self.input:SetPosition(0, 15)
    self.input.textbox:SetTextLengthLimit(80)
    self.input.textbox:EnableWordWrap(false)
    -- 編輯中按 Esc 直接交給 Screen 關閉，不用按兩次
    self.input.textbox:SetPassControlToScreen(CONTROL_CANCEL, true)
    self.input.textbox.OnTextEntered = function(text)
        self:Submit(text)
    end

    self.add_button = self.root:AddChild(TEMPLATES.StandardButton(function()
        self:Submit(self.input.textbox:GetString())
    end, L.Get("INPUT_ADD"), { 120, 40 }))
    self.add_button:SetPosition(0, -45)

    self.default_focus = self.input.textbox
    SetAutopaused(true)
end)

function TodoInputScreen:OnBecomeActive()
    TodoInputScreen._base.OnBecomeActive(self)
    self.input.textbox:SetFocus()
    self.input.textbox:SetEditing(true)
end

function TodoInputScreen:Submit(text)
    if self.onsubmit(text) then
        self:Close()
        return
    end
    -- 空白沒新增成功，留在輸入狀態
    self.input.textbox:SetEditing(true)
end

function TodoInputScreen:OnControl(control, down)
    if TodoInputScreen._base.OnControl(self, control, down) then
        return true
    end

    if not down and control == CONTROL_CANCEL then
        self:Close()
        return true
    end
end

function TodoInputScreen:Close()
    if self.closed then
        return
    end
    self.closed = true
    self.input.textbox:SetEditing(false)
    SetAutopaused(false)
    TheFrontEnd:PopScreen(self)
end

return TodoInputScreen
