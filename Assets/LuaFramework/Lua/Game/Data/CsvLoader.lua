--
-- Copyright (c) galileoliu
-- Date: 2015/11/19
-- Time: 10:26
--

CsvLoader = {}

function CsvLoader.Create(componentCsvLoader)
    CsvLoader.component = componentCsvLoader

    return CsvLoader
end

function CsvLoader.Start()
    Debugger.Log("CsvLoader-->> Start")
    local list =
    {
        "Hero",
        "Card",
    }

    for _,v in ipairs(list) do
        loadCSV("csv/"..v)
    end
--    local example_table = getDataTable("Hero")
--    log(TableToString(example_table))
--    example_table = getDataTable("Card")
--    log(TableToString(example_table))
end