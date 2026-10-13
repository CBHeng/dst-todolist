local G = GLOBAL
local TheNet = G.TheNet

local Widget = G.require("widgets/widget")
local Store = G.require("todolist/store")
local Layout = G.require("todolist/layout")
local I18n = G.require("todolist/i18n")
local TodoPanel = G.require("todolist/todopanel")

I18n.SetLanguage(GetModConfigData("language"))

-- Controls 是 HUD 的主體，每次進入世界（含進出洞穴）都會重新建立
AddClassPostConstruct("widgets/controls", function(controls)
    -- 錨在左下角，面板位置由 TodoPanel 依螢幕座標自行換算
    local root = controls:AddChild(Widget("todolist_hud_root"))
    root:SetHAnchor(G.ANCHOR_LEFT)
    root:SetVAnchor(G.ANCHOR_BOTTOM)
    root:SetScaleMode(G.SCALEMODE_PROPORTIONAL)
    root:SetMaxPropUpscale(G.MAX_HUD_SCALE)
    root:SetScale(G.TheFrontEnd:GetHUDScale())

    -- 跟著遊戲的「HUD 大小」設定縮放
    local old_SetHUDSize = controls.SetHUDSize
    controls.SetHUDSize = function(self, ...)
        old_SetHUDSize(self, ...)
        root:SetScale(G.TheFrontEnd:GetHUDScale())
    end

    local store = Store(TheNet:GetSessionIdentifier())
    store:Load(function(s)
        Layout.Load(function(pos)
            if not root.inst:IsValid() then
                return
            end
            local panel = root:AddChild(TodoPanel(controls.owner, s, pos))
            panel:ApplyPosition()
        end)
    end)
end)
