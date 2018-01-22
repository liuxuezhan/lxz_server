local OpenResBuild = {}

function OpenResBuild:onStart()
    self.player.eventFieldUpdated:add(newFunctor(self, self._onFieldUpdated))
end

function OpenResBuild:onStop()
    self.player.eventFieldUpdated:del(newFunctor(self, self._onFieldUpdated))
end

function OpenResBuild:onProcess(task_data, level)
    self.level = level

    if self.player.field >= level then
        self:_finishTask()
    end
end

function OpenResBuild:_onFieldUpdated(self, field)
    if field >= self.level then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.OPEN_RES_BUILD, OpenResBuild)

