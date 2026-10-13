local G = GLOBAL
local TheNet = G.TheNet

local Widget = G.require("widgets/widget")
local Store = G.require("todolist/store")
local TodoPanel = G.require("todolist/todopanel")

-- 每個位置對應：HUD 錨點，以及面板標題列中心相對錨點的偏移
local POSITIONS =
{
    right   = { h = G.ANCHOR_RIGHT, v = G.ANCHOR_MIDDLE, x = -170, y = 260 },
    top     = { h = G.ANCHOR_MIDDLE, v = G.ANCHOR_TOP, x = 0, y = -40 },
    topleft = { h = G.ANCHOR_LEFT, v = G.ANCHOR_TOP, x = 170, y = -200 },
}

local position = POSITIONS[GetModConfigData("panel_position")] or POSITIONS.right

-- Controls 是 HUD 的主體，每次進入世界（含進出洞穴）都會重新建立
AddClassPostConstruct("widgets/controls", function(controls)
    local root = controls:AddChild(Widget("todolist_hud_root"))
    root:SetHAnchor(position.h)
    root:SetVAnchor(position.v)
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
        if not root.inst:IsValid() then
            return
        end
        local panel = root:AddChild(TodoPanel(controls.owner, s))
        panel:SetPosition(position.x, position.y)
    end)
end)
