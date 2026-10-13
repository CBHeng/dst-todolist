-- 待辦清單的資料層：一個世界（server session）對應一個存檔，
-- 透過 TheSim:SetPersistentString 寫進本機的 client_save 資料夾。

local FILE_PREFIX = "mod_todolist_"
local DATA_VERSION = 1

local function SanitizeKey(key)
    if key == nil or key == "" then
        return "default"
    end
    return (string.gsub(key, "[^%w_%-]", "_"))
end

local Store = Class(function(self, session_id)
    self.filename = FILE_PREFIX..SanitizeKey(session_id)
    self.items = {}
    self.loaded = false
end)

function Store:Load(cb)
    TheSim:GetPersistentString(self.filename, function(success, str)
        if success and str ~= nil and str ~= "" then
            local ok, data = pcall(json.decode, str)
            if ok and type(data) == "table" and type(data.items) == "table" then
                self.items = data.items
            else
                print("[TODO List] 無法讀取存檔，改用空清單: "..self.filename)
            end
        end
        self.loaded = true
        if cb ~= nil then
            cb(self)
        end
    end)
end

function Store:Save()
    local str = json.encode({ version = DATA_VERSION, items = self.items })
    TheSim:SetPersistentString(self.filename, str, false)
end

function Store:GetItems()
    return self.items
end

function Store:Add(text)
    text = text ~= nil and string.gsub(text, "^%s*(.-)%s*$", "%1") or ""
    if text == "" then
        return false
    end
    table.insert(self.items, { text = text, done = false })
    self:Save()
    return true
end

function Store:ToggleDone(index)
    local item = self.items[index]
    if item ~= nil then
        item.done = not item.done
        self:Save()
        return item.done
    end
    return false
end

function Store:Remove(index)
    if self.items[index] ~= nil then
        table.remove(self.items, index)
        self:Save()
    end
end

function Store:Clear()
    self.items = {}
    self:Save()
end

function Store:CountUnfinished()
    local n = 0
    for _, item in ipairs(self.items) do
        if not item.done then
            n = n + 1
        end
    end
    return n
end

return Store
