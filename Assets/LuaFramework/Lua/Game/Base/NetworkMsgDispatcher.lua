--
-- Copyright (c) galileoliu
-- Date: 2016/2/19
-- Time: 10:41
--

module("NetworkMsgDispatcher", package.seeall)

function DispatchMsg(msg)
    function dispatch(msg)
        if msg.loginResponse then
            Util.LoadScene("battle2")
            local info = msg.loginResponse.playerInfo
            Game.player = Game.Player.Create(info)
        end
    end
    local flag, error = pcall(dispatch, msg)
    if flag == false then
        logError(error)
    end
end