--协议类型--
ProtocalType = {
	BINARY = 0,
	PB_LUA = 1,
	PBC = 2,
	SPROTO = 3,
	LUA_PB = 4,
}
--当前使用的协议类型--
EnabledProtoType = ProtocalType.LUA_PB

Util = LuaFramework.Util
AppConst = LuaFramework.AppConst
LuaHelper = LuaFramework.LuaHelper
ByteBuffer = LuaFramework.ByteBuffer

resMgr = LuaHelper.GetResManager()
panelMgr = LuaHelper.GetPanelManager()
soundMgr = LuaHelper.GetSoundManager()
networkMgr = LuaHelper.GetNetManager()

WWW = UnityEngine.WWW
GameObject = UnityEngine.GameObject
