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
    --INFO("[Autobot|BuildQueue|%d|%d] Build queue state: %d->%d", player.pid, self.queue_index, last_idx, self.build_idx)
    if last_idx == self.build_idx then
        return
    end
    local current_state = self:getCurrentState()
    if 0 == self.build_idx then
        self:translate("Idle")
    else
        if 0 == last_idx then
            self:translate("Working")
        else
            self:translate("Idle")
            self:translate("Working")
        end
    end
end

return makeFSM(BuildQueueMachine)

