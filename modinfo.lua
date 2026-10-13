name = "TODO List"
description = [[
個人待辦清單（僅客戶端）。

- 每個世界各自保存一份清單，存在你自己的電腦上
- 常駐在畫面上，有未完成事項時自動展開
- 點標題列收合 / 展開，點「＋ 新增」輸入
]]
author = "boheng"
version = "0.1.0"

api_version = 10

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
        name = "panel_position",
        label = "面板位置",
        options =
        {
            { description = "右側中間", data = "right" },
            { description = "畫面正上方", data = "top" },
            { description = "左上角", data = "topleft" },
        },
        default = "right",
    },
}
