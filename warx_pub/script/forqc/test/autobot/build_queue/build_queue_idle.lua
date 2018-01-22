local BuildQueueIdle = {}

local REST_TIME = config.Autobot.BuildQueueRestTime or 3

function BuildQueueIdle:onEnter()
    INFO("[Autobot|BuildQueue|%d|%d] Build queue enter idle", self.host.player.pid, self.fsm.queue_index)
    self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._wakeUp), REST_TIME)
end

function BuildQueueIdle:onExit()
    INFO("[Autobot|BuildQueue|%d|%d] Build queue exit idle", self.host.player.pid, self.fsm.queue_index)
    self.host:deactiveBuildQueue(self.fsm.queue_index)
    AutobotTimer:delTimer(self.timer_id)
end

function BuildQueueIdle:_wakeUp()
    INFO("[Autobot|BuildQueue|%d|%d] wake up build queue", self.host.player.pid, self.fsm.queue_index)
    self.host:activeBuildQueue(self.fsm.queue_index)
end

return makeState(BuildQueueIdle)

