local TroopTakeAction = {}

function TroopTakeAction:onInit()
end

function TroopTakeAction:onEnter()
    while true do
        -- 获取行军线数据
        local job = self.host:getTroopJob()
        if not self.host:isActive() then
            self.fsm:translate("Deactive")
            return
        end
        if nil == job then
            self.fsm:translate("Idle")
            return
        end
        -- take action
        local func = TroopTakeAction[job.action.name]
        if func then
            INFO("[Autobot|TroopTakeAction|%d] troop action: %s.", self.host.player.pid, job.action.name)
            self.commander = func(self, unpack(job.action.params))
            if nil ~= self.commander then
                self.job = job
                self.commander.eventAccomplished:add(newFunctor(self, self._onAccomplished))
                self.fsm.troop_action = self.commander:getTroopAction()
                break
            end
        else
            INFO("[Autobot|TroopTakeAction|%d] Not implemented troop action: %s.", self.host.player.pid, job.action.name)
        end
    end
end

function TroopTakeAction:onExit()
    self.fsm.troop_action = TroopAction.DefultFollow
    if nil ~= self.commander then
        self.commander.eventAccomplished:del(newFunctor(self, self._onAccomplished))
        self.commander:uninit()
        self.commander = nil
    end
end

function TroopTakeAction:_onAccomplished(...)
    if nil ~= self.job.functor then
        self.job.functor(...)
    end
    self.fsm:translate("Rest")
end

function TroopTakeAction:AttackLevelMonster(type, min_level, max_level)
    return SiegeMonster.create(self.host.player, type, min_level, max_level)
end

function TroopTakeAction:AttackSpecialMonster(task_id, monster_id)
    return SiegeTaskNpc.create(self.host.player, task_id, monster_id)
end

function TroopTakeAction:AttackSpecialPlayer(task_id, monster_id)
    return SiegeTaskPlayer.create(self.host.player, task_id, monster_id)
end

return makeState(TroopTakeAction)

