module("DelayProcessQueue", package.seeall)

local FuncList = {}

function Error(errorTitle, errorMsg)
    logError(errorTitle .. "：" .. errorMsg)
end

-- 添加函数到执行器中
function Enqueue(func, ...)
    local arg = {... }
    local funcListItem =
    {
        Func = func,
        Arg = arg,
    }

    table.insert(FuncList, funcListItem)
end

-- 执行所有函数
function Exe()
    for i, funcListItem in ipairs(FuncList) do
        local func = funcListItem.Func
        local arg = funcListItem.Arg
        if func == nil or type(func) ~= "function" then
            LuaLog("DelayProcessQueue - illegal func type!")
            break
        end

        local status, errorMsg = pcall(func, unpack(arg))

        if not status then
            local errorTitle = "DelayProcessQueue [" .. tostring(func) .. "] 调用失败"
            Error(errorTitle , errorMsg)
        end

        FuncList[i] = nil
    end
end

-- 全局调用接口
_G.EnqueueDelayProcess = Enqueue
_G.ExcuteDelayProcessQueue = Exe
