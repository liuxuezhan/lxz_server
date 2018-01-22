local EphemeraRush = {}

function EphemeraRush:onInit()
    self.prefix = config.Autobot.EphemeraRush.Prefix
    self.alive_time = config.Autobot.EphemeraRush.AliveTime
    self.loop_count = config.Autobot.EphemeraRush.LoopCount
    self.interval = config.Autobot.EphemeraRush.Interval
    self.max_count = config.Autobot.EphemeraRush.MaxCount
    self.wait_count = config.Autobot.EphemeraRush.WaitCount
    self.max_id = config.Autobot.EphemeraRush.MaxId
end

function EphemeraRush:onStart()
    AutobotTimer:addPeriodicTimer(function() self:_run() end, self.interval)
    bot_mng.eventPlayerOnline:add(function(player) self:_onPlayerOnline(player) end)
    bot_mng.eventPlayerOffline:add(function(player) self:_onPlayerOffline(player) end)
    self.online_count = 0
    self.rush_count = 0
end

local last_report_time = 0
local last_report_tps = 0
function EphemeraRush:_run()
    local count = bot_mng:getEntityCount()

    if gTime > last_report_time + 10 then
        last_report_time = gTime
        INFO("[Autobot|EphemeraRush|Statistic] There are %d entities which has %d player is online", count, self.online_count)
    end

    if count >= self.max_count then
        return
    end

    local login_count = self.loop_count
    if count + login_count > self.max_count then
        login_count = self.max_count - count
    end

    if count >= self.online_count + self.wait_count then
        return
    end

    for i = 1, login_count do
        self:_createEntity()
    end
end

function EphemeraRush:_createEntity()
    local idx = self.prefix * 1000000 + math.floor(self.rush_count % self.max_id)
    self.rush_count = self.rush_count + 1
    local entity = Entity.createEntity(idx)
    bot_mng:addEntity(entity)
    entity:start()
    entity.eventPlayerLoaded:add(newFunctor(self, self._onPlayerLoaded))
    INFO("[Autobot|EphemeraRush] Entity %s is created", idx)
end

function EphemeraRush:_onPlayerLoaded(player)
    AutobotTimer:addTimer(function(idx)
        local entity = bot_mng:getEntity(idx)
        if nil == entity then
            return
        end
        bot_mng:delEntity(entity)
    end, self.alive_time, player.idx)
end

function EphemeraRush:_onPlayerOnline(player)
    self.online_count = self.online_count + 1
end

function EphemeraRush:_onPlayerOffline()
    self.online_count = self.online_count - 1
end

return makeShuttle("EphemeraRush", EphemeraRush)

