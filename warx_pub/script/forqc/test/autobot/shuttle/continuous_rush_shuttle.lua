local ContinuousRush = {}

function ContinuousRush:onInit()
    self.prefix = config.Autobot.ContinuousRush.Prefix
    self.max_count = config.Autobot.ContinuousRush.MaxCount
    self.wait_count = config.Autobot.ContinuousRush.WaitCount
    self.loop_count = config.Autobot.ContinuousRush.LoopCount
    self.dying_time = config.Autobot.ContinuousRush.DyingTime
    self.task_id = config.Autobot.ContinuousRush.TaskId

    bot_mng.eventPlayerOnline:add(function(player) self:_onPlayerOnline(player) end)
    bot_mng.eventPlayerOffline:add(function(player) self:_onPlayerOffline(player) end)
    self.online_count = 0
    self.rush_count = 0
    self.tps = {}
end

function ContinuousRush:onStart()
    gFrameListener:add(function() self:_run() end)
end

local last_report_time = 0
local last_report_tps = 0
function ContinuousRush:_run()
    local count = bot_mng:getEntityCount()

    if gTime > last_report_time + 10 then
        last_report_time = gTime
        INFO("[Autobot|ContinuousRush|Statistic] There are %d entities which has %d player is online", count, self.online_count)
    end

    if 0 == last_report_tps then
        last_report_tps = gTime
    end
    if gTime > last_report_tps then
        INFO("[Autobot|ContinuousRush|Statistic] %d player is waiting", count - self.online_count)
        for t = last_report_tps, gTime - 1 do
            if self.tps[t] then
                INFO("[Autobot|ContinuousRush|Statistic] %d has %d player login", t, self.tps[t])
            end
        end
        last_report_tps = gTime
    end

    if self.online_count >= self.max_count then
        --wait_for_time(1)
        return
    end

    if count >= self.online_count + self.wait_count then
        --wait_for_time(1)
        return
    end

    for i = 1, self.loop_count do
        self:_createEntity()
    end
end

function ContinuousRush:_createEntity()
    local idx = self.prefix * 1000000 + self.rush_count
    self.rush_count = self.rush_count + 1
    local entity = Entity.createEntity(idx)
    bot_mng:addEntity(entity)
    entity:start(true)
    entity.eventPlayerLoaded:add(newFunctor(self, self._onPlayerLoaded))
    INFO("[Autobot|ContinuousRush] Entity %s is created", idx)
end

function ContinuousRush:_onPlayerOnline(player)
    self.online_count = self.online_count + 1
    self.tps[gTime] = (self.tps[gTime] or 0) + 1
end

function ContinuousRush:_onPlayerOffline()
    self.online_count = self.online_count - 1
end

function ContinuousRush:_onPlayerLoaded(player)
    player.eventTaskInfoUpdated:add(newFunctor(self, self._onTaskUpdated))
end

function ContinuousRush:_onTaskUpdated(player, task_data)
    if task_data.task_status ~= TASK_STATUS.TASK_STATUS_FINISHED then
        return
    end
    if not is_in_table(self.task_id, task_data.task_id) then
        return
    end
    player.eventTaskInfoUpdated:del(newFunctor(self, self._onTaskUpdated))
    local dying_time = math.random(self.dying_time, self.dying_time * 2)
    AutobotTimer:addTimer(function(idx)
        local entity = bot_mng:getEntity(idx)
        if nil == entity then
            return
        end
        bot_mng:delEntity(entity)
    end, dying_time, player.idx)
end

return makeShuttle("ContinuousRush", ContinuousRush)

