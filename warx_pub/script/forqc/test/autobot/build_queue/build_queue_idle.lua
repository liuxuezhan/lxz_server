local BuildQueueIdle = {}

local REST_TIME = config.Autobot.BuildQueueRestTime or 3

function BuildQueueIdle:onEnter()
    self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._wakeUp), REST_TIME)
end

function BuildQueueIdle:onExit()
    self.host:deactiveBuildQueue(self.fsm.queue_index)
    AutobotTimer:delTimer(self.timer_id)
end

function BuildQueueIdle:_wakeUp()
    self.host:activeBuildQueue(self.fsm.queue_index)
end

return makeState(BuildQueueIdle)

