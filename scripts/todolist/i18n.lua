-- 介面文字。語言由 modmain 依模組設定呼叫 SetLanguage 決定，預設英文。

local STRINGS =
{
    en =
    {
        TITLE = "To-Do (%d)",
        COLLAPSE = "Hide",
        EXPAND = "Show",
        CLEAR = "Clear",
        ADD = "+ Add",
        DELETE = "Del",
        EMPTY = "Nothing to do",
        CLEAR_TITLE = "Clear To-Do List",
        CLEAR_BODY = "Delete all %d items?",
        CANCEL = "Cancel",
        INPUT_TITLE = "New To-Do",
        INPUT_HINT = "Enter to add, Esc to close",
        INPUT_ADD = "Add",
    },
    zht =
    {
        TITLE = "待辦 (%d)",
        COLLAPSE = "收合",
        EXPAND = "展開",
        CLEAR = "清空",
        ADD = "＋ 新增",
        DELETE = "刪",
        EMPTY = "目前沒有待辦事項",
        CLEAR_TITLE = "清空待辦",
        CLEAR_BODY = "確定要刪除全部 %d 筆待辦嗎？",
        CANCEL = "取消",
        INPUT_TITLE = "新增待辦",
        INPUT_HINT = "Enter 新增，Esc 關閉",
        INPUT_ADD = "新增",
    },
}

local current = STRINGS.en

local I18n = {}

function I18n.SetLanguage(lang)
    current = STRINGS[lang] or STRINGS.en
end

-- 找不到的 key 退回英文，再找不到就直接顯示 key，方便發現漏翻
function I18n.Get(key)
    return current[key] or STRINGS.en[key] or key
end

return I18n
