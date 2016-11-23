using LuaInterface;

namespace LuaFramework
{
    public class LuaComponent: Base
    {
        protected static bool initialize = false;
        public static void Initailize()
        {
            initialize = true;
        }
        protected LuaTable m_LuaObject;
		public string m_LuaClassName;

        /// <summary>
        /// 执行Lua方法
        /// </summary>
        protected object[] CallMethod(string func, params object[] args)
        {
            if (!initialize)
            {
                return null;
            }

			return Util.CallMethod(m_LuaClassName, func, m_LuaObject, args);
        }

        public void Destroy()
        {
            m_LuaObject = null;
            Util.ClearMemory();
            Destroy(gameObject);
        }

        public void SetLuaObject(LuaTable luaObject)
        {
            m_LuaObject = luaObject;
        }


        public LuaTable GetLuaObject()
        {
            return m_LuaObject;
        }
    }
}
