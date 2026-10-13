-- 面板位置：所有世界共用一份，存成「標題列中心佔螢幕寬 / 高的比例」，
-- 換解析度或視窗大小時才不會跑到畫面外。

local FILENAME = "mod_todolist_layout"

local Layout = {}

-- cb(pos)：pos 為 { x = 0~1, y = 0~1 }，沒存過則為 nil
function Layout.Load(cb)
    TheSim:GetPersistentString(FILENAME, function(success, str)
        local pos = nil
        if success and str ~= nil and str ~= "" then
            local ok, data = pcall(json.decode, str)
            if ok and type(data) == "table" and type(data.x) == "number" and type(data.y) == "number" then
                pos = { x = data.x, y = data.y }
            end
        end
        cb(pos)
    end)
end

-- 傳 nil 代表清除，下次回到預設位置
function Layout.Save(pos)
    local str = pos ~= nil and json.encode({ x = pos.x, y = pos.y }) or ""
    TheSim:SetPersistentString(FILENAME, str, false)
end

return Layout
