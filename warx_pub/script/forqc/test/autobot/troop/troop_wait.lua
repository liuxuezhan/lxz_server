local TroopWait = {}

function TroopWait:onInit()
end

function TroopWait:onEnter()
    self.host.eventBusyTroopStarted:add(newFunctor(self, TroopWait._onTroopStarted))
    self.host.eventBusyTroopFinished:add(newFunctor(self, TroopWait._onTroopFinished))

    -- TODO: 注册计时器，超时取消（注意：若计时器到时后，状态已切走的情况处理）
end

function TroopWait:onExit()
    self.host.eventBusyTroopStarted:del(newFunctor(self, TroopWait.onTroopStarted))
    self.host.eventBusyTroopFinished:del(newFunctor(self, TroopWait._onTroopFinished))
end

function TroopWait:_onTroopStarted(player, index, troop)
    if nil ~= self.index then
        return
    end

    INFO("[Autobot|TroopWait|%d] A new troop %d|%d|%d has started.",
        self.host.player.pid,
        index,
        troop._id,
        math.floor(troop.action/100))
    self.index = index
    self.troop = troop
end

function TroopWait:_onTroopFinished(player, index, troop)
    if nil == self.index or self.index ~= index then
        return
    end

    local troop_type = math.floor(troop.action/100)
    INFO("[Autobot|TroopWait|%d] A troop %d|%d|%d has finished.",
        self.host.player.pid,
        index,
        troop._id,
        troop_type)
    if 3 == troop_type then -- 300 < action < 400 means troop back
        self.fsm:translate("Rest")
    end
end

return makeState(TroopWait)

