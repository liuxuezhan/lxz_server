local JoinUnion = {}

function JoinUnion:onStart()
    self.player.eventUnionChanged:add(newFunctor(self, self._onUnionChanged))
end

function JoinUnion:onStop()
    self.player.eventUnionChanged:del(newFunctor(self, self._onUnionChanged))
end

function JoinUnion:onProcess(task_data)
    if self.player.union then
        self:_finishTask()
    end
end

function JoinUnion:_onUnionChanged(player, uid, union)
    if 0 ~= uid then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.JOIN_PLAYER_UNION, JoinUnion)

