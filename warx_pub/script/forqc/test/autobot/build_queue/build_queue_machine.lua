local BuildQueueMachine = {}

function BuildQueueMachine:onStart()
    self.host.player.eventBuildQueueUpdated:add(newFunctor(self, self._onBuildQueueUpdated))
    self.build_idx = self.host.player.build_queue[self.queue_index] or 0
    self.initState = (0 == self.build_idx and "Idle" or "Working")
end

function BuildQueueMachine:onStop(init_state)
    self.host.player.eventBuildQueueUpdated:del(newFunctor(self, self._onBuildQueueUpdated))
end

function BuildQueueMachine:_onBuildQueueUpdated(player, build_queue)
    local last_idx = self.build_idx
    self.build_idx = build_queue[self.queue_index] or 0
    if last_idx == self.build_idx then
        return
    end
    local current_state = self:getCurrentState()
    local state = 0
    if 0 == self.build_idx then
        state = state + 10
        if "Idle" ~= current_state.name then
            self:translate("Idle")
            state = state + 1
        end
    else
        state = state + 1000
        if "Idle" == current_state.name then
            self:translate("Working")
            state = state + 100
        end
    end
end

return makeFSM(BuildQueueMachine)

