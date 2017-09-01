local JoinUnion_Accomplish = {}

function JoinUnion_Accomplish:onEnter(memeber)
    AutobotTimer:addTimer(newFunctor(self, self._finishJob), 1)
end

function JoinUnion_Accomplish:onExit()
end

function JoinUnion_Accomplish:_finishJob(member)
    self.host.player.labor_manager:deleteLabor(self.host)
end

return makeState(JoinUnion_Accomplish)

