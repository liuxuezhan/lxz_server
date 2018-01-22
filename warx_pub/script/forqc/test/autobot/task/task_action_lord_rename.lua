local LordRename = {}

function LordRename:onStart()
    self.player.eventRoleNameUpdated:add(newFunctor(self, self._check))
end

function LordRename:onStop()
    self.player.eventRoleNameUpdated:del(newFunctor(self, self._check))
end

function LordRename:onProcess(task_data)
    self:_check()
end

function LordRename:_check()
    if not is_sys_name(self.player.name) then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.LORD_RENAME, LordRename)

