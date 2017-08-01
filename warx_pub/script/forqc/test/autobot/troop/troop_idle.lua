local TroopIdle = {}

function TroopIdle:onInit()
end

function TroopIdle:onEnter()
    self.host.eventNewTroopJob:add(newFunctor(self, TroopIdle._onNewTroopJob))
end

function TroopIdle:onExit()
    self.host.eventNewTroopJob:del(newFunctor(self, TroopIdle._onNewTroopJob))
end

function TroopIdle:_onNewTroopJob()
    self.fsm:translate("TakeAction")
end

return makeState(TroopIdle)

