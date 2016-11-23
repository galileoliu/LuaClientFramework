--
-- Copyright (c) galileoliu
-- Date: 2016/1/27
-- Time: 16:19
--

local sub = string.sub
local gmatch = string.gmatch
local insert = table.insert
local select = select
local tonumber = tonumber
local toboolean = function(var)
	if var == nil or var == false then return false end
	if type(var) == "string" then
		local lower = string.lower(var)
		return lower == "yes" or lower == "true" or lower == "y"
	elseif type(var) == "number" then
		return var ~= 0
	else
		return true
	end
end
local lower = string.lower

local reduceTable = {
	["a"] = "UI/alpha/HVGA/",
}

local protected_list =
{
	"Unit",
}

DataTable = {}

local function csvLineSplit(s)
	s = s .. ','      -- ending comma
	local t = {}      -- table to collect fields
	local fieldstart = 1
	repeat
		-- next field is quoted? (start with `"'?)
		if string.find(s, '^"', fieldstart) then
			local a, c
			local i = fieldstart
			repeat
				-- find closing quote
				a, i, c = string.find(s, '"("?)', i+1)
			until c ~= '"'    -- quote not followed by quote?
			if not i then error('unmatched "') end
			local f = string.sub(s, fieldstart+1, i-1)
			table.insert(t, (string.gsub(f, '""', '"')))
			fieldstart = string.find(s, ',', i) + 1
		else              -- unquoted; find next comma
			local nexti = string.find(s, ',', fieldstart)
			table.insert(t, string.sub(s, fieldstart, nexti - 1))
			fieldstart = nexti + 1
		end
	until fieldstart > string.len(s)
	return t
end

function DataTable.recoverColum(value)
    if not value then return nil end
    local str = string.sub(value,1,1)
    for i,v in pairs(reduceTable) do
        if str == i and not string.match(value,v) then
            value = string.gsub(value,i,v,1)
            return value
        end
    end
end

function DataTable.reduceValue(v)
    if type(v) ~= "string" then error("try reduce a type that is not  string:",v) end
    local isString = true
    v = (v ~= "" and v or nil)
    if not v then return nil,isString end
    for i,str in pairs(reduceTable) do
        if (string.match(v,str)) then
            v = string.gsub(v,str,i)
            break
        end
    end
    return v ,isString
end

local function parseValue(v, t)
	local char = sub(t, 1, 1)
	t = sub(t, 2)
	local iskey = false
	local isString = false
    local isIgnore = false
	if char == "K" then
		iskey = true
		char = sub(t, 1, 1)
		t = sub(t, 2)
    end

	if char == "A" then
		local ret = {}
		for token in gmatch(v, "[^;]*") do
            	if token ~= "" then
		        local e = parseValue(token, t)
		        insert(ret, e)
            	end
		end
		v = ret
	elseif char == "S" then
		isString = true
		v = (v ~= "" and v or nil)
	elseif char == "N" then
		v = tonumber(v) or 0
	elseif char == "B" then
		v = toboolean(lower(v))
	elseif char == "O" then
        isIgnore = true
		v = nil
	elseif char == "X" then
		isIgnore = true
		v = nil
    elseif char == "R" then
        v,isString = DataTable.reduceValue(v)
    end

	return v, iskey, isString ,isIgnore
end

local function setValueForKeyChain(t, chain, v, table_name)
	if #chain == 0 then Debugger.LogError("Primary key not found on table: " .. table_name) end
	local k = chain[1]
	if #chain == 1 then
		if t[k] then Debugger.LogError("Primary key '" .. (k or "nil") .. "' duplicated on table: " .. table_name)	end
		t[k] = v
	else
		if not t[k] then t[k] = {} end
		table.remove(chain, 1)
		setValueForKeyChain(t[k], chain, v, table_name)
	end
end

local data_table_cache = {}
local ref_count_list = {}

function loadCSV(path)
	local ret = {}
	-- TODO: Replace EDGetFileData with Unity API.
	local file_content = Util.LoadCsv(path)
	local column_list = nil
	local type_list = nil
    if not file_content then
		print(path)
    end

	for line in gmatch(file_content, "[^\r\n]*") do
		if line ~= "" then
			local value_list = csvLineSplit(line)
			if not type_list then
				type_list = value_list
			elseif not column_list then
				column_list = value_list
            else
				local line_table = {}
                local key = {}
				for i = 1 , #column_list do
					local t = type_list[i]	
					if t and #t > 0 then
						local k = column_list[i]
						local v = value_list[i]
						local vv, iskey, isString, isIgnore = parseValue(v, t)
                        if not isIgnore then
                            line_table[k] = vv
                            if iskey then key[#key + 1] = vv end
                        end
					end
				end
				setValueForKeyChain(ret, key, line_table, path)
				local name = line_table["Name"]
				if name then ret[name] = line_table end
			end
		end
	end

	local table_name = string.match(path , "[^/\\]*$")
	table_name = string.gsub(table_name , ".csv" , "")
	data_table_cache[table_name] = ret

	return ret
end

local resetDatatableReleaseCount = function(name)
	ref_count_list[name] = ref_release_gap
end

function getDataTable(table_name)
	-- look up in cache
	local ret = data_table_cache[table_name]
	resetDatatableReleaseCount(table_name)

	if ret then return ret end

	if not ret then
		-- load from csv
		-- TODO:New csv file path.
		local path = "csv/"..table_name
		ret = loadCSV(path)
	end
	
	ret.name = table_name

	return ret
end

--
-- 变长参数列表(...)为查询的key。可使用多键，按顺序列出
-- 参数2 column_name 可以为空，表示获取整行数据
--
function lookupDataTable(table_name, column_name, ...)
	local dt = getDataTable(table_name)
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		dt = dt[key]
		if not dt then return end
	end
	if column_name then
		return dt[column_name]
	else
		return dt
	end
end

local ref_collect_gap = 999999
local ref_release_gap = 999999
local collect_count = 0

initDatatableGCGap = function(gap)
	ref_collect_gap = gap
end

initDatatableReleaseGap = function(gap)
	ref_release_gap = gap
end

local checkDatatableReleaseCount = function()
	local bRelease
	for k,v in pairs(data_table_cache) do
		ref_count_list[k] = math.max(ref_count_list[k] - ref_collect_gap , 0)
		if ref_count_list[k] <= 0 then
			if not IsElementInTable(k , protected_list) then
				data_table_cache[k] = nil
				bRelease = true
			end
		end
	end

	if bRelease then
	local temp = {}
	for k,v in pairs(data_table_cache) do
		temp[k] = v
	end
	data_table_cache = temp
	end
	-- collectgarbage("collect")
end

datatableGC = function(dt)
	collect_count = collect_count + dt
	if collect_count > ref_collect_gap then
		checkDatatableReleaseCount()
		collect_count = collect_count - ref_collect_gap
	end
end
