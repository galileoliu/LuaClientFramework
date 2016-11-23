require "Game/Project"

--管理器--
GameManager = {}
local this = GameManager

local game 
local transform
local gameObject

function GameManager.Awake()
    --logWarn('Awake--->>>')
end

--启动事件--
function GameManager.Start()
    --logWarn('Start--->>>')
end

--初始化完成，发送链接服务器信息--
function GameManager.OnInitOK()
    Network.Connect()
       
    log('SimpleFramework InitOK--->>>')
end

--销毁--
function GameManager.OnDestroy()
    --logWarn('OnDestroy--->>>')
end
