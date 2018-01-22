local RoleLevelUp = {}

function RoleLevelUp:onStart()
    self.player.eventRoleLevelUpdated:add(newFunctor(self, self._check))
end

function RoleLevelUp:onStop()
    self.player.eventRoleLevelUpdated:del(newFunctor(self, self._check))
end

function RoleLevelUp:onProcess(task_data, level)
    self.level = level

    self:_check()
end

function RoleLevelUp:_check()
    if self.player.lv >= self.level then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.ROLE_LEVEL_UP, RoleLevelUp)

