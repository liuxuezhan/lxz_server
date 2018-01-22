local RecruitWorking = {}

local REDUNDANT_TIME = 3
local CASTLE_OF_SEPARATOR = 4

function RecruitWorking:onEnter(functor, acc_type)
    local build = get_build(self.host.player, BUILD_CLASS.ARMY, self.fsm.mode)
    if nil == build then
        -- no building, don't kidding me
        self.fsm:translate("Idle")
        return
    end
    self.functor = functor
    self.acc_type = acc_type

    if BUILD_STATE.WORK == build.state then
        self:_refreshWaitTime(build)
    end
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
end

function RecruitWorking:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
    self.last_overtime = nil
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    if self.functor then
        self.functor()
        self.functor = nil
    end
end

function RecruitWorking:_refreshWaitTime(build)
    local overtime = build.tmOver
    local wait_time = REDUNDANT_TIME
    if overtime > gTime then
        wait_time = overtime - gTime + REDUNDANT_TIME
    else
        self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    end

    if nil == self.timer_id then
        INFO("[Autobot|Recruit|%d|%d] Recruit will spend %d seconds.", self.host.player.pid, self.fsm.mode, wait_time)
        self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._onTimesUp), wait_time)
        self:_tryAccelerate(build)
    elseif self.last_overtime ~= build.tmOver then
        INFO("[Autobot|Recruit|%d|%d] Recruit has been reset and will spend %d seconds.", self.host.player.pid, self.fsm.mode, wait_time)
        AutobotTimer:adjustTimer(self.timer_id, wait_time)
    end
    self.last_overtime = build.tmOver
end

function RecruitWorking:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if prop.Class ~= BUILD_CLASS.ARMY or prop.Mode ~= self.fsm.mode then
        return
    end
    if build.state == BUILD_STATE.WORK then
        self:_refreshWaitTime(build)
    else
        if nil == self.last_overtime then
            return
        else
            INFO("[Autobot|Recruit|%d|%d] Recruit has finished (build updated).", self.host.player.pid, self.fsm.mode)
            self:translate("Rest")
        end
    end
end

function RecruitWorking:_onTimesUp()
    local build = get_build(self.host.player, BUILD_CLASS.ARMY, self.fsm.mode)
    if build.state == BUILD_STATE.WORK then
        self:_refreshWaitTime(build)
    else
        INFO("[Autobot|Recruit|%d|%d] Recruit has finished.", self.host.player.pid, self.fsm.mode)
        self:translate("Rest")
    end
end

function RecruitWorking:_tryAccelerate(build)
    if self.acc_type ~= ACC_TYPE.ITEM then
        INFO("[Autobot|Recruit|%d|%d] acc failed %s.", self.host.player.pid, self.fsm.mode, self.acc_type)
        return
    end

    local player = self.host.player
    local castle_lv = player:get_castle_lv()

    local overtime = build.tmOver
    if overtime <= gTime then
        return
    end

    local items = {}
    local working_time = overtime - gTime
    for k, v in pairs(player._item or {}) do
        local prop = resmng.prop_item[v[2]]
        if nil ~= prop then
            if prop.Class == ITEM_CLASS.SPEED and prop.Mode == ITEM_SPEED_MODE.TRAIN then
                table.insert(items, {v, prop})
            end
        end
    end
    table.sort(items, function(a, b) return a[2].Param > b[2].Param end)

    local use_item = {}
    for k, v in ipairs(items) do
        if v[2].Param <= working_time then
            local count = 0
            if v[2].Param == 300 and castle_lv < CASTLE_OF_SEPARATOR then
                count = math.ceil(working_time / v[2].Param)
            else
                count = math.floor(working_time / v[2].Param)
            end
            if count > v[1][3] then
                count = v[1][3]
            end
            table.insert(use_item, {v[1], count})
        elseif v[2].Param == 300 and castle_lv < CASTLE_OF_SEPARATOR then
            table.insert(use_item, {v[1], 1})
        end
    end

    for k, v in pairs(use_item) do
        INFO("[Autobot|Recruit|%d|%d] Accelerate recruit with %d|%d item %d.", self.host.player.pid, self.fsm.mode, v[1][1], v[1][2], v[2])
        Rpc:item_acc_build(player, build.idx, v[1][1], v[2])
    end
end

return makeState(RecruitWorking)

