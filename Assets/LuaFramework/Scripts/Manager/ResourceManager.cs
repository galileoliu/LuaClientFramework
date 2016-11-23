using UnityEngine;
using System.IO;
using System;

namespace LuaFramework
{
    public class ResourceManager : Base
    {
        private AssetBundle shared;

        /// <summary>
        /// 初始化
        /// </summary>
        public void initialize(Action func)
        {
            if (func != null)
            {
                func();    //资源初始化完成，回调游戏管理器，执行后续操作 
            }
        }

        /// <summary>
        /// 载入素材
        /// </summary>
        public AssetBundle LoadBundle(string name)
        {
            byte[] stream = null;
            AssetBundle bundle = null;
            string uri = Util.DataPath + name.ToLower() + AppConst.ExtName;
            stream = File.ReadAllBytes(uri);
            bundle = AssetBundle.LoadFromMemory(stream); //关联数据的素材绑定
            return bundle;
        }

        /// <summary>
        /// 销毁资源
        /// </summary>
        void OnDestroy()
        {
            if (shared != null)
            {
                shared.Unload(true);
            }
            Debug.Log("~ResourceManager was destroy!");
        }
    }
}