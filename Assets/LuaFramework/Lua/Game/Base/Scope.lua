--
-- Copyright (c) galileoliu
-- Date: 2016/2/19
-- Time: 10:30
--

module("Game", package.seeall)

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- 脚本作用域管理，主要用来管理资源的释放等等问题，在主要的资源系统中，
-- 如事件管理系统等等，可能都会涉及到作用域的问题

local GameScope = {}

-- 当前作用域的名称
GameScope.name = ""

-- 当前作用域下的子作用域
GameScope.subs = nil

-- 当前作用域的类型信息
GameScope.symbol = "Scope"

-- 游戏作用域的构造函数
function GameScope:new(name, parentpath)
	local object = {}
	setmetatable(object, self)
	self.__index = self

	object.subs = {}
	object.name = name
    if parentpath == nil then
        object.path = name
    else
        object.path = parentpath.."."..name
    end
	Scope.CreateEvent:Fire(object)

	return object
end

-- 向当前作用域中添加一个新的子作用域
function GameScope:AddSub(name)
	if nil == name then
		return nil
	end

    -- 子作用域名字为小写字母
	name = tostring(name)
	name = string.lower(name)

	if nil == self.subs[name] then
		self.subs[name] = GameScope:new(name, self.path)
    end
	return self.subs[name]
end

-- 从当前作用域中移除一个子作用域
function GameScope:DelSub(name)
	if nil == name then
		return
	end

	name = tostring(name)
	name = string.lower(name)

	self.subs[name] = nil
end

-- 在当前作用域中创建一系列子作用域，如("a.b.c.d")
function GameScope:Create(path)
	if nil == path then
		return nil
	end

	local current = self
	for token in string.gmatch(path, "[^\\/.]+") do
		current = current:AddSub(token)
    end

	return current
end

-- 在当前作用域中删除子作用域，如("a.b.c.d")
function GameScope:Remove(path)
    local current = self
	local parent
	for token in string.gmatch(path, "[^\\/.]+") do
		token = string.lower(token)
		if current.subs[token] ~= nil then
			parent = current
			current = current.subs[token]
		else
			return false, "该Path("..path..")不存在"
		end
	end

	if parent ~= nil then
        current:RemoveAllSubs()
        current:Clear()
        Scope.RemoveEvent:Fire(current)
        parent:DelSub(current.name)
		return true
	end

	return false, "Path不能够为空"
end

function GameScope:RemoveAllSubs()
    local subs = self.subs
    for k, _ in pairs(subs) do
        self:Remove(k)
    end
end

-- 在当前作用域中搜索某一系列子作用域，如("a.b.c.d")
function GameScope:Search(path)
	local current = self
	for token in string.gmatch(path, "[^\\/.]+") do
		token = string.lower(token)
		if current.subs[token] ~= nil then
			current = current.subs[token]
		else
			return nil
		end
	end

	return current
end

-- 打印当前作用域，以及子作用域
function GameScope:Print()
    Scope.PrintEvent:Fire(self)

    for _, v in pairs(self.subs) do
        if v ~= nil then
            v:Print()
        end
    end
end

-- 清理当前作用域
function GameScope:Clear()
	Scope.ClearEvent:Fire(self)

	for _, v in pairs(self.subs) do
		if v ~= nil then
			v:Clear()
		end
	end
end

-- 作用域系统
Scope = Scope or {}

-- 作用域的创建事件
Scope.CreateEvent = Event:new()

-- 作用域的打印事件
Scope.PrintEvent = Event:new()

-- 作用域的清除事件
Scope.ClearEvent = Event:new()

-- 作用域的销毁事件
Scope.RemoveEvent = Event:new()

-- 作用域的根作用域
Scope.Root = Scope.Root or GameScope:new("root")


-- 在全局Scope下创建一个子Scope
Scope.Create = function(path)
	if nil == path then
		return nil
	end

	path = tostring(path)
	local scope = Scope.Root:Create(path)

	return scope
end

-- 在全局Scope下搜索某个子Scope
Scope.Search = function(path)
	if nil == path then
		return nil
	end

	path = tostring(path)
	return Scope.Root:Search(path)
end

-- 在全局Scope下销毁某个子Scope
Scope.Remove = function(path)
	if nil == path then
		return false, "需要一个存在的Path"
	end

	path = tostring(path)
	return Scope.Root:Remove(path)
end

-- 在全局Scope下清除某个子Scope
Scope.Clear = function(path)
	if nil == path then
		return false, "需要一个存在的Path"
	end

	path = tostring(path)
	local scope = Scope.Search(path)
	if scope ~= nil then
		scope:Clear()
	end

	return true
end

-- 在全局Scope下打印某个子Scope下所有的信息
Scope.Print = function(path)
	if nil == path then
		return false, "需要一个存在的Path"
	end

	path = tostring(path)
	local scope = Scope.Search(path)

    if scope ~= nil then
        scope:Print()
    end

	return true
end
