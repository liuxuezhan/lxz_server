local EndlessRush = {}

function EndlessRush:onInit()
    self.prefix = config.Autobot.EndlessRush.Prefix
    self.batch_count = config.Autobot.EndlessRush.BatchCount
    self.loop_count = config.Autobot.EndlessRush.LoopCount
    self.interval = config.Autobot.EndlessRush.Interval
    self.dying_time = config.Autobot.EndlessRush.DyingTime
    self.task_id = config.Autobot.EndlessRush.TaskId

    self.batch_cursor = 0
    self.batch_index = self.batch_count + 1
    self.loop_index = 0
end

function EndlessRush:onStart()
    self.startup_timer = AutobotTimer:addPeriodicTimer(newFunctor(self, self._doBatchLogin), self.interval)
end

function EndlessRush:_doBatchLogin()
    local cursor = self.batch_cursor + 1
    local prefix = self.prefix

    INFO("[Autobot|EndlessRush] Start to load %dth batch players", cursor)
    for i = 1, self.loop_count do
        local idx = prefix * 1000000 + cursor * 1000 + i
        local entity = Entity.createEntity(idx)
        bot_mng:addEntity(entity)
        entity:start()
        entity.eventPlayerLoaded:add(newFunctor(self, self._onPlayerLoaded))
    end

    if cursor >= self.batch_count then
        AutobotTimer:delPeriodicTimer(self.startup_timer)
        self.startup_timer = nil
        INFO("[Autobot|EndlessRush] All players have been started")
    end
    self.batch_cursor = cursor
end

function EndlessRush:_onPlayerLoaded(player)
    player.eventTaskInfoUpdated:add(newFunctor(self, self._onTaskUpdated))
end

function EndlessRush:_onTaskUpdated(player, task_data)
    if task_data.task_status ~= TASK_STATUS.TASK_STATUS_FINISHED then
        return
    end
    if not is_in_table(self.task_id, task_data.task_id) then
        return
    end
    player.eventTaskInfoUpdated:del(newFunctor(self, self._onTaskUpdated))
    INFO("[Autobot|EndlessRush] Player %d finish task %d.", player.pid, task_data.task_id)
    local dying_time = math.random(self.dying_time, self.dying_time * 2)
    AutobotTimer:addTimer(function(idx)
        local entity = bot_mng:getEntity(idx)
        if nil == entity then
            return
        end
        INFO("[Autobot|EndlessRush] Player %d is logining out.", entity.pid)
        bot_mng:delEntity(entity)
    end, dying_time, player.idx)

    self:_loadNextPlayer()
end

function EndlessRush:_loadNextPlayer()
    local idx = self:_getNextIdx()
    INFO("[Autobot|EndlessRush] Start to load player %d", idx)
    self:_createEntity(idx)
end

function EndlessRush:_getNextIdx()
    local loop_index = self.loop_index + 1
    local idx = self.prefix * 1000000 + self.batch_index * 1000 + loop_index

    if loop_index >= self.loop_count then
        loop_index = 0
        self.batch_index = self.batch_index + 1
    end
    self.loop_index = loop_index

    return idx
end

function EndlessRush:_createEntity(idx)
    local entity = Entity.createEntity(idx)
    bot_mng:addEntity(entity)
    entity:start()
    entity.eventPlayerLoaded:add(newFunctor(self, self._onPlayerLoaded))
end

return makeShuttle("EndlessRush", EndlessRush)

