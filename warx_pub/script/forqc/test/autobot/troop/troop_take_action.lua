local TroopTakeAction = {}

function TroopTakeAction:onInit()
end

function TroopTakeAction:onEnter()
    self.host:activateTroopQueue(self.fsm, gTime)
    while true do
        if not self.host:isActive() then
            self.fsm:translate("Deactive")
            return
        end
        -- 获取行军线数据
        local job = self.host:getTroopJob()
        if nil == job then
            self.fsm:translate("Idle")
            return
        end
        -- take action
        local action = SiegeAction.createAction(job.action.name, self.host.player, unpack(job.action.params))
        if action then
            INFO("[Autobot|TroopTakeAction|%d] troop action: %s.", self.host.player.pid, job.action.name)
            self.action = action
            self.job = job
            self.action.eventAccomplished:add(newFunctor(self, self._onAccomplished))
            self.fsm.troop_action = self.action:getTroopAction()
            self:_startAction()
            break
        else
            INFO("[Autobot|TroopTakeAction|%d] Not implemented troop action: %s.", self.host.player.pid, job.action.name)
        end
    end
end

function TroopTakeAction:onExit()
    self.fsm.troop_action = TroopAction.DefultFollow
    if nil ~= self.action then
        self.action.eventAccomplished:del(newFunctor(self, self._onAccomplished))
        self.action:uninit()
        self.action = nil
    end
    self.host:activateTroopQueue(self.fsm)
end

function TroopTakeAction:_startAction()
    if self.host:checkTroopAction(self.fsm) then
        INFO("[Autobot|TroopTakeAction|%d] start.", self.host.player.pid)
        self.action:start()
    else
        INFO("[Autobot|TroopTakeAction|%d] Troop need to wait other troop.", self.host.player.pid)
        self.host:addWaitingTroopAction(function()
            INFO("[Autobot|TroopTakeAction|%d] Restart troop's action.", self.host.player.pid)
            self:_startAction()
        end)
    end
end

function TroopTakeAction:_onAccomplished(...)
    if nil ~= self.job.functor then
        self.job.functor(...)
    end
    self.host:clearTroopAction(self.fsm)
    self.fsm:translate("Rest")
end

return makeState(TroopTakeAction)

