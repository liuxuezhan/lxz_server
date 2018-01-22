local JoinUnion_Accomplish = {}

function JoinUnion_Accomplish:onEnter(memeber)
    self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._finishJob), 1)
end

function JoinUnion_Accomplish:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function JoinUnion_Accomplish:_finishJob(member)
    self.host.player.labor_manager:deleteLabor(self.host)
end

return makeState(JoinUnion_Accomplish)

