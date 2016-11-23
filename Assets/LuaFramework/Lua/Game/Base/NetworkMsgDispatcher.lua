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
        if msg.gameInfo then
            Game.otherPlayers = {}
            for i = 1, 4 do
                local playerInfo = msg.gameInfo.players[i]
                if playerInfo.id ~= Game.player:GetID() then
                    local player = Game.Player.Create(playerInfo)
                    Game.otherPlayers[playerInfo.id] = player
                end
            end
        end
        if msg.gameBegin then
            Battle.cardOperationQueue = Battle.CardOperationQueue.Create()

            Battle.Desk:GameBegin()
            Battle.Engine:GameBegin(msg.gameBegin.battleId)
        end
        if msg.battleInfo then
            for _, handCard in ipairs(msg.battleInfo.handCards) do
--                logWarn("handCard:\n"..TableToString(handCard))
                Battle.Desk:InitOtherPlayerHandCard(handCard)
            end
            Battle.Desk:RefreshPlayerCardLeftCount()
        end
        if msg.battleBegin then
            Battle.Desk:BattleBegin()
            Battle.Engine:BattleBegin(msg.battleBegin.battleId)
        end
        if msg.handCard then
            local player = Battle.Desk:GetPlayer(msg.handCard.seat)
            player:SupplyHandCards(msg.handCard.cardIds)
            Battle.Desk:RefreshPlayerCardLeftCount()
        end
        if msg.buyCard then
            -- Buy card info to CardQueue.
--            log("buyCard player:["..msg.buyCard.seat.."] card:["..msg.buyCard.classId.."]")
            local player = Battle.Desk:GetPlayer(msg.buyCard.seat)
            local card = Card.Card.Create(msg.buyCard.classId, player)
            if player:GetCamp() == Game.player:GetCamp() then
                if msg.buyCard.cardEffectTargetCamp then
                    local minion = Battle.Engine:GetMinion(msg.buyCard.cardEffectTargetCamp, msg.buyCard.cardEffectTargetSlot)
                    card:SetTargetMinion(minion)
                end
            end
            local extraInfo =
            {
                cardEffectTargetCamp = msg.buyCard.cardEffectTargetCamp,
                cardEffectTargetSlot = msg.buyCard.cardEffectTargetSlot,
            }
            local operationItem = Battle.CardOperationItem.Create("buy", card, player, extraInfo)
            Battle.cardOperationQueue:AddItem(operationItem)
        end
        if msg.buyEnd then
            local player = Battle.Desk:GetPlayer(msg.buyEnd.seat)
            Battle.Desk:ShowDialog(player:GetLocalSeat())
            player:SetLastBattleOperation("buy")
        end
        if msg.playCard then
            -- Play card info to CardQueue.
            local player = Battle.Desk:GetPlayer(msg.playCard.seat)
            local card = player:GetHandCard(msg.playCard.cardId)

            if player:GetCamp() == Game.player:GetCamp() then
                card:InitAppearance(Battle.Desk:GetOtherPlayerCardNode(), Vector3.zero, true)
                card.gameObject.transform.localScale = Vector3.New(0.35, 0.35, 0.35)

                local slot = Battle.Desk:GetMinionSlotBg(msg.playCard.targetCamp, msg.playCard.targetSlot)
                if slot:GetCardToPlay() then
                    UI.ButtonDesk:OnClick()
                end
                slot:SetCardToPlay(card)
                card:SetTargetSlot(slot)
                card:SetTag("playAfter")
                if msg.playCard.cardEffectTargetCamp then
                    local minion = Battle.Engine:GetMinion(msg.playCard.cardEffectTargetCamp, msg.playCard.cardEffectTargetSlot)
                    card:SetTargetMinion(minion)
                end
            end
            local extraInfo =
            {
                targetCamp = msg.playCard.targetCamp,
                targetSlot = msg.playCard.targetSlot,
                cardEffectTargetCamp = msg.playCard.cardEffectTargetCamp,
                cardEffectTargetSlot = msg.playCard.cardEffectTargetSlot,
            }
            local operationItem = Battle.CardOperationItem.Create("play", card, player, extraInfo)
            Battle.cardOperationQueue:AddItem(operationItem)
        end
        if msg.playEnd then
            local player = Battle.Desk:GetPlayer(msg.playEnd.seat)
            Battle.Desk:ShowDialog(player:GetLocalSeat())
            player:SetLastBattleOperation("play")
        end
        if msg.cardOperationEnd then
            Battle.Desk:CloseShop()
            local countOperation = Battle.Desk:StartShowOperation()
            coroutine.start(delayCall, Battle.DeltaTimeOperationShow*countOperation,
                function()
                    Battle.Engine:StartBattleBalance(msg.cardOperationEnd.battleId)
                end)
            coroutine.start(delayCall, Battle.DeltaTimeOperationShow*(countOperation+1),
                function()
                    local flagClearHandCard = Battle.Desk:FinishBattleBalance()
                    Battle.Engine:FinishBattleBalance()
                    Battle.Engine:SendBattleBalanceEnd(flagClearHandCard)
                end)
        end
    end
    local flag, error = pcall(dispatch, msg)
    if flag == false then
        logError(error)
    end
end