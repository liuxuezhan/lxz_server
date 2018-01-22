local FinishDailyTask = {}

function FinishDailyTask:onStart()
    self.player.eventActivityUpdated:add(newFunctor(self, self._check))
end

function FinishDailyTask:onStop()
    self.player.eventActivityUpdated:del(newFunctor(self, self._check))
end

function FinishDailyTask:onProcess(task_data, activity)
    self.activity = activity

    self:_check()
end

function FinishDailyTask:_check()
    if self.player.activity >= self.activity then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.FINISH_DAILY_TASK, FinishDailyTask)

