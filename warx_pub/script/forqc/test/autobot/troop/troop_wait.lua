local TroopWait = {}

function TroopWait:onInit()
end

function TroopWait:onEnter(troop)
    self.host.eventBusyTroopStarted:add(newFunctor(self, TroopWait._onTroopStarted))
    self.host.eventBusyTroopFinished:add(newFunctor(self, TroopWait._onTroopFinished))

    if nil ~= troop then
        self.troop_id = troop._id
        self.troop = troop
    end
    -- TODO: 注册计时器，超时取消（注意：若计时器到时后，状态已切走的情况处理）
end

function TroopWait:onExit()
    self.host.eventBusyTroopStarted:del(newFunctor(self, TroopWait._onTroopStarted))
    self.host.eventBusyTroopFinished:del(newFunctor(self, TroopWait._onTroopFinished))
    self.troop_id = nil
    self.troop = nil
end

function TroopWait:_onTroopStarted(player, troop_id, troop)
    if nil ~= self.troop_id then
        return
    end

    INFO("[Autobot|TroopWait|%d] A new troop %d|%d has started.",
        self.host.player.pid,
        troop_id,
        math.floor(troop.action/100))
    self.troop_id = troop_id
    self.troop = troop
end

function TroopWait:_onTroopFinished(player, troop_id, troop)
    if nil == self.troop_id or self.troop_id ~= troop_id then
        return
    end

    local troop_type = math.floor(troop.action/100)
    INFO("[Autobot|TroopWait|%d] A troop %d|%d has finished.",
        self.host.player.pid,
        troop_id,
        troop_type)
    if 3 == troop_type then -- 300 < action < 400 means troop back
        self.fsm:translate("Rest")
    end
end

return makeState(TroopWait)

