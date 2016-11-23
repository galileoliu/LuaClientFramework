--
-- Copyright (c) galileoliu
-- Date: 2016/2/19
-- Time: 10:30
--

module("Game", package.seeall)

Print = log
Alert = logWarn
Error = logError

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 事件系统中触发器的定义和实现
Trigger = {}

Trigger.func = nil

function Trigger:new(object)
    object = object or {}
    setmetatable(object, self)
    self.__index = self
    return object
end

function Trigger:Check(event, ...)
    return self.func(event, self, ...)
end

-- 当触发某个Trigger错误的时候会使用该函数替换Check函数
local function TriggerErrorReplace()
    return false
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 事件系统中响应者的定义和实现
Responser = {}

Responser.func = nil
Responser.filter = nil

function Responser:new(object)
    object = object or {}
    setmetatable(object, self)
    self.__index = self
    return object
end

function Responser:Fire(event, ...)
    if self.filter ~= nil  and
            not self.filter(event, self, ...) then
        return
    end

--    self.func(event, self, ...)
    local bOK, error = pcall(self.func, ...)
    return bOK, error
end

-- 当触发某个Responser错误的时候会使用该函数替换Fire函数
local function ResponserErrorReplace()
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 通用事件的定义和实现
Event = {symbol = "Event"}

-- 事件内部执行错误的报告
function Event:Error(title, msg)
    Alert("事件中("..title..")执行错误："..msg)
end

-- 事件的构造函数
function Event:new()
    local object = {}
    setmetatable(object, self)
    self.__index = self

    -- 事件对应的响应器列表
    object.responsers = List.New()
    -- 事件对应的触发器列表
    object.triggers = List.New()

    return object
end

-- 给事件绑定一个响应器，可以是一个function也可以是Responser
function Event:Bind(exe)
    if nil == exe then
        return
    end

    local newExe = exe

    -- 如果绑定的执行器是一个function，那么内部自动转换为Responser
    if type(exe) == "function" then
        newExe = Responser:new()
        newExe.func = exe
    end

    -- 一次只像队列的尾端添加一个响应器
    self.responsers:PushBack(newExe)
end

-- 给事件解除一个响应器，可以是一个function也可以是Responser
function Event:Unbind(exe)
    if exe == nil then
        return
    end

    local isFunc = (type(exe) == "function")

    -- 一次只解除一个响应器
    for _responser, itr in rilist(self.responsers) do
        if _responser ~= nil then
            if (isFunc == true and _responser.func == exe) or
                    (isFunc == false and _responser == exe) then
                self.responsers:Erase(itr)
                return
            end
        end
    end
end

-- 触发事件的时候首先检查触发器列表，如果全部通过那么就触发所有的响应器
function Event:Fire(...)

    -- 首先检查条件
    if not self:Check(...) then
        return false
    end

    -- 然后执行每个响应器，执行失败的都会被从执行列表中清除掉
    -- 并且会给出对应的错误提示
    for responser in ilist(self.responsers) do
        if responser ~= nil then
            local bOk, msg = responser:Fire(self, ...)
            if not bOk then
                responser.Fire = ResponserErrorReplace
                self:Error("Responser", msg)
            end
        end
    end

    return true
end

-- 给事件绑定一个触发器，可以绑定一个function或者一个Trigger
function Event:BindTrigger(func)
    if func == nil then
        return
    end

    local newTrigger = func

    -- 如果绑定的是一个function，那么内部自动转换为Trigger
    if type(func) == "function" then
        newTrigger = Trigger:new()
        newTrigger.func = func
    end

    -- 一次只像队列的尾端添加一个触发器
    self.triggers:PushBack(newTrigger)
end

-- 给事件解除一个触发器，可以解除一个function或者一个Trigger
function Event:UnbindTrigger(func)
    if func == nil then
        return
    end

    local isFunc = (type(func) == "function")

    -- 一次只解除一个触发器
    for _trigger, itr in rilist(self.triggers) do
        if  _trigger ~= nil then
            if (isFunc == true and _trigger.func == func)
                    or (isFunc == false and _trigger == func) then
                self.triggers:Erase(itr)
                return
            end
        end
    end
end

-- 检查事件的触发条件是否满足
function Event:Check(...)
    -- 只要有一个触发器不成功，那么整体就不能够触发了
    -- 如果其中某个触发器发生了错误，那么会报告错误
    -- 同时会将这个触发器清除
    for trigger in ilist(self.triggers) do
        if trigger ~= nil then
            local bOk, bResult = pcall(trigger.Check, trigger, self, ...)
            if not bOk then
                -- 如果Trigger执行异常，那么清除该Trigger，并且报错
                trigger.Check = TriggerErrorReplace
                self:Error("Trigger", bResult)
                return false
            end

            if not bResult then
                return false
            end
        end
    end

    return true
end

-- 获得当前事件绑定的响应器的个数
function Event:ResponserCount()
    return self.responsers:Size()
end

-- 获得当前事件绑定的触发器的个数
function Event:TriggerCount()
    return self.triggers:Size()
end

function Event:ClearResponsers()
    self.responsers:Clear()
end
