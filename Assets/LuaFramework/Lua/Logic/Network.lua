require "Common/define"
require "Common/protocal"
require "Common/functions"
require "events"
require "3rd/luapb/pb"

AppConst.SocketPort = 2012
AppConst.SocketAddress = "192.168.2.79"

--网络包流水号
local sequenceIndex = 0

Proto = {}
local up = pb_loader("up")()
local down = pb_loader("down")()
local upmsg = up.UpMsg
local downmsg = down.DownMsg
Proto.up = up
Proto.down = down

Network = {}
local this = Network
this.isConnected = false

function Network.Start() 
    log("Network.Start!!")
    Event.AddListener(Protocal.Connect, this.OnConnect)
    Event.AddListener(Protocal.Exception, this.OnException)
    Event.AddListener(Protocal.Disconnect, this.OnDisconnect)
    Event.AddListener(Protocal.Down, this.OnDown)
end

--Socket消息--
function Network.OnSocket(key, data)
    local temp = function(key, data)
        Event.Brocast(tostring(key), data)
    end
    local flag, error = pcall(temp, key, data)
    if not flag then
        logError(error)
    end
end

--异常断线--
function Network.OnException()
    this.isConnected = false
    networkMgr:SendConnect()
    logError("OnException------->>>>")
end

--连接中断，或者被踢掉--
function Network.OnDisconnect()
    this.isConnected = false
    logError("OnDisconnect------->>>>")
end

function Network.Connect()
    networkMgr:SendConnect()
end

--当连接建立时--
function Network.OnConnect() 
    log("Game server connected!!")
    this.isConnected = true
    ListenEvent("NetworkDownMsg", NetworkMsgDispatcher.DispatchMsg)
end

function Network.SendMsg(msgType, msgObject)
    local datagram = this.PackageMsg(msgType, msgObject)
    if datagram then
        local buffer = ByteBuffer.New()
        buffer:WriteShort(Up)
        buffer:WriteByte(EnabledProtoType)
        buffer:WriteString(datagram)
        networkMgr:SendMessage(buffer)
    end
end

function Network.PackageMsg(msgType, msgObject)
    local msg = upmsg()
    msg.sequence = sequenceIndex
    msg.repeatFlag = 0
    local firstLetter = string.sub(msgType, 1, 1)
    firstLetter = string.lower(firstLetter)
    local fieldName = firstLetter..string.sub(msgType, 2)
    msg[fieldName] = msgObject

    local datagram, error = msg:Serialize()
    if not datagram then
        logError(string.format("ERROR | Network PackageMsg Serialize failed! | "..tostring(error)))
        return
    end

    sequenceIndex = sequenceIndex + 1

    return datagram
end

function Network.OnDown(buffer)
    local protoType = buffer:ReadByte()
--    log("protoType:"..protoType)
    local datagram = buffer:ReadString()
    local msg = this.ParseMsg(datagram)
    if msg then
        this.DispachMsg(msg)
    end
end

function Network.ParseMsg(datagram)
    local msg, error = downmsg():Parse(datagram)
    if msg == nil then
        logError("ERROR | Network ParseMsg Parse failed! | "..tostring(error))
    else
        return msg
    end
end

function Network.DispachMsg(msg)
    if msg == nil then
        logError("ERROR | Network DispachMsg msg is nil!")
        return
    end
    for k, v in pairs(msg[".data"]) do
        log(">>> Network down msg: " .. k)
        log(">>> >>>: "..TableToString(v))
    end
    FireEvent("NetworkDownMsg", msg)
end

--卸载网络监听--
function Network.Unload()
    Event.RemoveListener(Protocal.Connect)
    Event.RemoveListener(Protocal.Exception)
    Event.RemoveListener(Protocal.Disconnect)
    Event.RemoveListener(Protocal.Down)
    logWarn('Unload Network...')
end