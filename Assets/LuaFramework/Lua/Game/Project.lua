--
-- Copyright (c) galileoliu
-- Date: 2015/11/19
-- Time: 10:46
--

GameProjectFiles =
{
    "Base.Event",
    "Base.Scope",
    "Base.EventSystem",
    "Base.DelayProcessQueue",
    "Base.NetworkMsgDispatcher",

    "Data.CsvLoader",
    "Data.DataTable",
}

for _, file in ipairs(GameProjectFiles) do
    require("Game."..file)
end