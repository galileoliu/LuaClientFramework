--
-- Copyright (c) galileoliu
-- Date: 2016/2/19
-- Time: 10:30
--

module("Game", package.seeall)

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 系统事件的定义和实现

local SystemEvent = Event:new()

-- 系统事件的名称
SystemEvent.name = ""
-- 系统事件的时间控制器
SystemEvent.timer = nil
-- 该系统事件的代理，外面得到只是这个代理
SystemEvent.proxy = nil

function SystemEvent:Error(title, msg)
    Error("Event ("..tostring(self.name)..")["..title.."] execution error: "..msg)
end

-- 给系统事件绑定一个计时器
function SystemEvent:SetTimer(timer)
    if nil == timer then
        self.timer = nil
    elseif timer.symbol == "Timer" then
        self.timer = timer
    end
end

-- 更新系统事件
function SystemEvent:Update(deltTime)
    local timer = self.timer
    if timer == nil then
        return
    end
    if timer.always == true then
        timer:UpdateAlways(self, deltTime)
    elseif timer.count > 0 then
        timer:UpdateTimes(self, deltTime)
    elseif timer.count <= 0 then
        EventSystem.Close(self.name)
    end
end

-- 打印整个事件的描述
function SystemEvent:Print()
    Print("event name:"..self.name)
    Print("event scope:"..self.scope.name)
    Print("event responsers:"..self.responsers:Size())
    Print("event triggers:"..self.triggers:Size())
    if self.timer ~= nil then
        Print("event Timer:")
        Print("\tinterval:"..self.timer.interval)
        Print("\tcount:"..self.timer.count)
        Print("\talways:"..tostring(self.timer.always))
        Print("\tcurrent:"..self.timer.current)
    end
end

-----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 事件系统中使用到的计时器的定义和实现

Timer = {}
-- 定时器的间隔事件定义
Timer.interval = 0
-- 定时器可重复次数的定义
Timer.count = 0
-- 定时器是否可以一直重复的定义
Timer.always = false
-- 定时器当前的计时
Timer.current = 0
-- 定时器经过的所有时间
Timer.total = 0
-- 定时器的类型信息
Timer.symbol = "Timer"

-- 定时器的构造函数
function Timer:new(object)
    object = object or {}
    setmetatable(object, self)
    self.__index = self
    return object
end

-- 定时器的克隆函数
function Timer:Clone()
    local newTimer = Timer:new()
    newTimer.interval = self.interval
    newTimer.always = self.always
    if not self.always then
        newTimer.count = self.count
    end
    return newTimer
end

-- 创建一直执行的定时器
function Timer:Always(interval)
    if interval == nil then
        interval = 0
    end
    local timer = Timer:new()
    timer.interval = interval
    timer.always = true
    return timer
end

-- 创建执行多次的定时器
function Timer:Times(interval, count)
    local timer = Timer:new()
    timer.interval = interval
    timer.always = false
    timer.count = count
    return timer
end

-- 创建只执行一次的定时器
function Timer:Once(interval)
    return Timer:Times(interval, 1)
end

-- 定时器的更新，每个定时器都应该对应一个事件
-- 如果定时器到了间隔点上的时候需要触发一次事件
-- 有定时次数限制，那么需要对应的处理次数问题
function Timer:UpdateTimes(event, deltTime)
    self.current = self.current + deltTime
    self.total = self.total + deltTime
    if self.current >= self.interval then
        if event ~= nil and event:Fire(self.current, self.total) then
            self.count = self.count - 1
        end
        self.current = 0
    end
end

-- 定时器的更新，每个定时器都应该对应一个事件
-- 如果定时器到了间隔点上的时候需要触发一次事件
-- 没有定时次数限制，可以一直触发事件
function Timer:UpdateAlways(event, deltTime)
    self.current = self.current + deltTime
    self.total = self.total + deltTime
    if self.current >= self.interval then
        if event ~= nil then
            event:Fire(self.current, self.total)
        end
        self.current = 0
    end
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 事件系统的逻辑定义和实现
EventSystem = {}

-- 需要进行更新的事件集合，只有设置了Timer和Bind了一个以上的Responser的
-- 事件才需要进行Update，其他的都不需要进行更新的
local NeedUpdateEvents = {}
local NeedUpdateKeys = {}
local NeedUpdateKeysCount = 0;

-- 不需要进行更新的事件集合，但是可以被触发，没有设置Timer但是Bind了一个
-- 以上的Responser的事件
local NoNeedUpdateEvents = {}

-- 所有新建的事件的集合，不需要更新，也不能够被触发
local NewCreatedEvents = {}

-- 对有变化的系统事件，进行不同队列的管理分配
-- 情况1.   事件有Timer，而且有一个以上的Responser需要转入到NeedUpdateEvents中
-- 情况2.   事件没有Timer，但有一个以上的Responser需要转入到NoNeedUpdateEvents中
-- 情况3.   事件没有一个Responser的时候该事件就可以结束了，重新放入到新加列表中
local SystemEventDispatcher = function(event)
    if event == nil then
        return
    end
    if event.timer ~= nil and event:ResponserCount() > 0 then
        NeedUpdateEvents[event.name] = event
        NoNeedUpdateEvents[event.name] = nil
        NewCreatedEvents[event.name] = nil
    elseif event:ResponserCount() > 0 then
        NeedUpdateEvents[event.name] = nil
        NoNeedUpdateEvents[event.name] = event
        NewCreatedEvents[event.name] = nil
    elseif event.timer ~= nil or event:TriggerCount() > 0 then
        NeedUpdateEvents[event.name] = nil
        NoNeedUpdateEvents[event.name] = nil
        NewCreatedEvents[event.name] = event
    else
        -- 什么都没有了，那么就可以关闭该事件了
        EventSystem.Close(event.name)
    end
end

-- 通过事件系统打开一个事件，如果事件已经存在，那么就直接返回存在的事件
-- 并且支持作用域使用，会在有效的作用域中记录创建的该事件
function EventSystem.Open(name)
    if nil == name then
        return nil
    end
    local event = NeedUpdateEvents[name] or NoNeedUpdateEvents[name] or NewCreatedEvents[name]
    if nil ~= event then
        return event
    end
    local event = Event:new()
    event.name = name
    NewCreatedEvents[name] = event
    return event
end

-- 关闭一个事件，直接将管理集合中的该事件清空就可以了
function EventSystem.Close(name)
    if nil == name then
        return
    end
    local event = EventSystem.Find(name)
    if nil == event then
        return
    end
    for rsp in rilist(event.responsers) do
        if rsp ~= nil then
            EventSystem.Unbind(name, rsp.func, rsp.scope)
        end
    end
    event:ClearResponsers()
    NeedUpdateEvents[name] = nil
    NoNeedUpdateEvents[name] = nil
    NewCreatedEvents[name] = nil
end

-- 搜索一个事件，如果不存在直接返回nil
function EventSystem.Find(name)
    if nil == name then
        return nil
    end
    return (NeedUpdateEvents[name] or NoNeedUpdateEvents[name] or NewCreatedEvents[name])
end

-- 向事件系统中某个事件绑定一个函数执行器
function EventSystem.Bind(name, func, scope)
    local event = EventSystem.Find(name)
    if event ~= nil then
        -- 避免重复绑定
        local rsps = event.responsers
        for v in ilist(rsps) do
            if v ~= nil and v.func == func and v.scope == scope then
                return true
            end
        end
        local rsp = Responser:new()
        rsp.func = func
        rsp.scope = scope
        event:Bind(rsp)
        SystemEventDispatcher(event)
        local binds = scope.Events[name] or List.New()
        scope.Events[name] = binds
        binds:PushBack(func)
        return true
    end
    return false
end

-- 向事件系统中某个事件解除一个函数执行器
function EventSystem.Unbind(name, func, scope)
    local event = EventSystem.Find(name)
    if event ~= nil then
        local binds = scope.Events[name]
        if binds ~= nil then
            for v, itr in rilist(binds) do
                if v == func then
                    binds:Erase(itr)
                    break
                end
            end
        end
        event:Unbind(func)
        SystemEventDispatcher(event)
        return true
    end
    return false
end

-- 触发事件系统中某个事件，这种方式只能够触发非更新事件
-- 因为更新事件都是自动触发的
function EventSystem.Fire(name, ...)
    if nil == name then
        return
    end
    local event = NoNeedUpdateEvents[name]
    if event ~= nil then
        event:Fire(...)
    end
    return false
end

-- 向事件系统中某个事件绑定一个函数检查器
function EventSystem.BindTrigger(name, func)
    local event = EventSystem.Find(name)
    if event ~= nil then
        event:BindTrigger(func)
        return true
    end
    return false
end

-- 向事件系统中某个事件解除一个函数检查器
function EventSystem.UnbindTrigger(name, func)
    local event = EventSystem.Find(name)
    if event ~= nil then
        event:UnbindTrigger(func)
        return true
    end
    return false
end

-- 向事件系统中某个事件绑定一个计时器
function EventSystem.SetTimer(name, timer)
    local event = EventSystem.Find(name)
    if event ~= nil then
        event:SetTimer(timer)
        SystemEventDispatcher(event)
        return true
    end
    return false
end

-- 打印整个事件系统中的事件情况
function EventSystem.Print()
    local getAvaliable = function(pre, events)
        local result = "\n"..pre
        local count = 0
        for k, v in pairs(events) do
            result = result.."\n    "..k..": ("..v:ResponserCount()..")"
        end
        return result
    end
    local getNewCreated = function(pre, events)
        local result = "\n"..pre
        local count = 0
        for k, v in pairs(events) do
            result = result.."\n    "..k..""
        end
        return result
    end
    Error(getAvaliable("Need-Update-Events' list ", NeedUpdateEvents))
    Alert(getAvaliable("No-Need-Update-Events' list ", NoNeedUpdateEvents))
    Print(getNewCreated("New-Created-Events' list ", NewCreatedEvents))
end


-- 更新事件系统，如果事件的Timer不存在，那么不进行事件更新
-- 如果Timer存在，那么就更新Timer，同时检查Timer是否到事件点
-- 上了，如果到了那么就触发一次事件，同时减少一次RepeatCount
-- 当RepeatCount小于0的时候那么这个事件就结束了，需要从EventSystem
-- 中删除掉，如果RepeatCount大于0那么就触发一次Event，如果触发成功
-- 那么需要减去一次RepeatCount，如果AlwaysRepeat那么就直接触发不需要关心
-- RepeatCount的次数

function EventSystem.Update(deltTime)
    NeedUpdateKeysCount = 0
    for k, event in pairs(NeedUpdateEvents) do
        NeedUpdateKeysCount = NeedUpdateKeysCount + 1
        NeedUpdateKeys[NeedUpdateKeysCount] = k
    end
    for i = 1, NeedUpdateKeysCount do
        local key = NeedUpdateKeys[i]
        local event = NeedUpdateEvents[key]
        if event ~= nil then
            event:Update(deltTime)
        end
    end
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 简易调用接口的实现

-- 更新事件系统
function _G.UpdateEventSystem(deltTime)
    EventSystem.Update(deltTime)
    ExcuteDelayProcessQueue()
end

-- 打开某个事件
function EventOpen(name, timer, trigger)
    local event = EventSystem.Open(name)
    if nil == event then
        return nil
    end
    if timer ~= nil then
        EventSystem.SetTimer(name, timer)
    end
    if trigger ~= nil then
        EventSystem.BindTrigger(name, trigger)
    end
    return event
end

-- 关闭某个事件
function EventClose(name)
    EventSystem.Close(name)
end

-- 查找某个事件
function EventFind(name)
    return EventSystem.Find(name)
end

-- 给某个事件绑定Trigger
function EventTriggerBind(name, func)
    return EventSystem.BindTrigger(name, func)
end

-- 给某个事件解绑定Trigger
function EventTriggerUnbind(name, func)
    return EventSystem.BindTrigger(name, func)
end

-- 触发某个非更新事件
function _G.FireEvent(name, ...)
    return EventSystem.Fire(name, ...)
end

function EventSetTimer(name, timer)
    EventSystem.SetTimer(name, timer)
end

-- 打印某个事件的内容
function EventPrint(name)
    local event = EventSystem.Find(name)
    if event ~= nil then
        return event:Print()
    end
end

-- 监听一个事件
function _G.ListenEvent(eventName, func, scope)
    scope = scope or Scope.Root
    if nil == scope then
        Error( "listen event no scope")
        return
    end

    if nil == eventName then
        Error("listen event no event")
        return
    end

    if nil == func then
        Error("listen event no func")
        return
    end

    local event = EventSystem.Open(eventName)
    if event ~= nil then
        EventSystem.Bind(event.name, func, scope)
    end
    return event
end

--取消listen一个事件
function _G.StopListenEvent(eventName, func, scope)
    if nil == eventName then
        Error("listen event no event")
        return
    end

    if nil == func then
        Error("listen event no func")
        return
    end
    return EventSystem.Unbind(eventName, func, scope)
end

----------------------------------------------------------------
----------------------------------------------------------------
-- 以下是事件系统对Scope的直接支持


-- 当创建一个Scope的时候，就会主动向该Scope中注册SystemEvent相关的操作
local function OnScopeCreate(scope)
    scope.Events = {}

    scope.EventFind = function(_scope, name)
        if nil == _scope or _scope.symbol ~= "Scope" then
            return nil
        end
        local event = EventSystem.Find(name)
        if event ~= nil then
            local binds = scope.Events[name]
            if binds ~= nil and binds:Size() > 0 then
                return event
            end
        end
        return nil
    end

    scope.EventBind = function(_scope, name, func)
        if nil == _scope or _scope.symbol ~= "Scope" then
            return nil
        end
        return EventSystem.Bind(name, func, _scope)
    end

    scope.EventUnbind = function(_scope, name, func)
        if nil == _scope or _scope.symbol ~= "Scope" then
            return nil
        end
        return EventSystem.Unbind(name, func, _scope)
    end
end

-- 当清除一个Scope的时候，关闭该作用域中所有的运行着的SystemEvent
local function OnScopeClear(scope)
    if nil == scope or nil == scope.Events then
        return
    end
    local events = scope.Events
    for k, v in pairs(events) do
        for rsp in rilist(v) do
            if rsp ~= nil then
                EventSystem.Unbind(k, rsp, scope)
            end
        end
        v:Clear()
    end
    scope.Events = {}
end

-- 当打印一个Scope的时候，将该Scope中的所有Task打印出来
local function OnScopePrint(scope, sb, pre)
    if nil == scope or nil == scope.Events then
        return
    end
    if nil == sb then
        return
    end
    pre = pre or ""
    local events = scope.Events
    for k, v in pairs(events) do
        sb:Append(pre)
        sb:Append("<style|value=ChatStyle_Job>")
        sb:Append("事件接受者[")
        sb:Append(tostring(k))
        sb:Append(", 个数：")
        sb:Append(tostring(v:Size()))
        sb:AppendLine("]<br>")
    end
end

Scope.CreateEvent:Bind(OnScopeCreate)
Scope.ClearEvent:Bind(OnScopeClear)
Scope.PrintEvent:Bind(OnScopePrint)
OnScopeCreate(Scope.Root)