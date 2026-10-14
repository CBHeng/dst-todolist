-- 遊戲把目前的語系放在 locale（例如 "zht"、"zh"），用來決定說明文字與預設語言
local is_chinese = locale == "zh" or locale == "zht" or locale == "zhr"

name = "TODO List"
description = is_chinese and [[
個人待辦清單（僅客戶端）。

- 每個世界各自保存一份清單，存在你自己的電腦上
- 常駐在畫面上，有未完成事項時自動展開
- 按住標題列拖曳移動，位置會記住；「清空」一次刪除全部
- 「收合 / 展開」切換清單，點「＋ 新增」輸入
]] or [[
A personal to-do list (client only).

- Each world keeps its own list, saved on your computer
- Stays on screen and opens automatically when items are unfinished
- Drag the title bar to move it; the position is remembered
- "Hide / Show" toggles the list, "Clear" removes everything, "+ Add" adds an item
]]
author = "boheng"
version = "1.0.0"

api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

-- 只在自己的遊戲裡執行，進任何伺服器都能用，房主不需要安裝
client_only_mod = true
all_clients_require_mod = false

server_filter_tags = {}

configuration_options =
{
    {
        name = "language",
        label = is_chinese and "語言" or "Language",
        options =
        {
            { description = "English", data = "en" },
            { description = "繁體中文", data = "zht" },
        },
        default = is_chinese and "zht" or "en",
    },
}
