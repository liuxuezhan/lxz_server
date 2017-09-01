local BuildQueueWorking = {}

local REDUNDANT_TIME = config.Autobot.BuildQueueRedundantTime or 3

function BuildQueueWorking:onEnter()
    local build_idx = self.host.player.build_queue[self.fsm.queue_index] or 0
    if 0 == build_idx then
        WARN("[Autobot|BuildQueue|%d|%d] build queue shouldn't be zero or empty", self.host.player.pid, self.fsm.queue_index)
        self:translate("Idle")
        return
    end
    self.build_idx = build_idx
    local build = self.host.player._build[build_idx]
    if nil == build then
        WARN("[Autobot|BuildQueue|%d|%d] building %d doesn't exist.", self.host.player.pid, self.fsm.queue_index, build_idx)
        return
    end
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))

    if build.state == BUILD_STATE.CREATE or build.state == BUILD_STATE.UPGRADE then
        self:_refreshWaitTime(build)
    end
end

function BuildQueueWorking:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
    self.asked_help = nil
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

function BuildQueueWorking:_checkUnionHelp(build)
    if not self.host.player:is_in_union() then
        return
    end
    local help_pid = self.host.player.union_help_manager:getHelp(build.tmSn)
    if nil ~= help_pid then
        -- asked help
        return
    end
    INFO("[Autobot|BuildQueue|%d|%d] Ask help", self.host.player.pid, self.fsm.queue_index)
    Rpc:union_help_add(self.host.player, build.tmSn)
end

function BuildQueueWorking:_refreshWaitTime(build)
    -- calculate remain time
    local free_time = self.host.player:get_val("BuildFreeTime") or 0
    local over_time = build.tmOver
    local wait_time = REDUNDANT_TIME
    if over_time > gTime + free_time then
        wait_time = over_time - (gTime + free_time) + REDUNDANT_TIME
        self:_checkUnionHelp(build)
    else
        self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    end
    -- has no timer yet
    if nil == self.timer_id then
        INFO("[Autobot|BuildQueue|%d|%d] Building %d will spend %d|%d seconds.", self.host.player.pid, self.fsm.queue_index, build.idx, wait_time, build.tmOver)
        self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._onTimesUp), wait_time)
    elseif self.last_overtime ~= build.tmOver then
        INFO("[Autobot|BuildQueue|%d|%d] Reset building %d and will spend %d|%d seconds now.", self.host.player.pid, self.fsm.queue_index, build.idx, wait_time, build.tmOver)
        AutobotTimer:adjustTimer(self.timer_id, wait_time)
    end
    self.last_overtime = build.tmOver
end

function BuildQueueWorking:_getBuild()
    --local build_idx = self.host.player.build_queue[self.fsm.queue_index] or 0
    --if 0 == build_idx then
    --    return
    --end
    return self.host.player._build[self.build_idx]
end

function BuildQueueWorking:_onBuildUpdated(player, build)
    if self.build_idx ~= build.idx then
        return
    end
    if build.state ~= BUILD_STATE.CREATE and build.state ~= BUILD_STATE.UPGRADE then
        return
    end
    self:_refreshWaitTime(build)
end

function BuildQueueWorking:_onTimesUp()
    local build = self:_getBuild()
    if build.state ~= BUILD_STATE.CREATE and build.state ~= BUILD_STATE.UPGRADE then
        return
    end
    local free_time = self.host.player:get_val("BuildFreeTime") or 0
    local over_time = build.tmOver
    if over_time > gTime + free_time then
        self:_refreshWaitTime()
    else
        self:translate("Accelerate")
    end
end

return makeState(BuildQueueWorking)

