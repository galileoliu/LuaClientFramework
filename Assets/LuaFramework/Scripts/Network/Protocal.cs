namespace LuaFramework
{
    public class Protocal
    {
        ///BUILD TABLE
        public const int Connect = 101;     //连接服务器
        public const int Exception = 102;     //异常掉线
        public const int Disconnect = 103;     //正常断线
        public const int Up = 201;                  // 客户端上行协议
        public const int Down = 202;             // 客户端下行协议
    }
}