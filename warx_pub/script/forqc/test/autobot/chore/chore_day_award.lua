local ChoreDayAward = {}

local MY_TASK_ID = 130010120
local REST_TIME = config.Autobot.ChoreRestTime or 5

function ChoreDayAward:init(player)
    self.player = player

    if self:_canStart() then
        INFO("[Autobot|DayAward|%d] start claim day award.", self.player.pid)
        self:_start()
    else
        INFO("[Autobot|DayAward|%d] watch day award pre-condition.", self.player.pid)
        self:_startWatch()
    end
end

function ChoreDayAward:uninit()
    self.timer_id = nil
    self:_stopWatch()
end

function ChoreDayAward:_canStart()
    local prop = resmng.prop_build[resmng.BUILD_SHIPYARD_1]
    if nil == prop then
        return
    end
    return Autobot.condCheck(self.player, prop.Cond)
end

function ChoreDayAward:_start()
    self:_waitFreeTime()
end

function ChoreDayAward:_claimAward()
    INFO("[Autobot|DayAward|%d] claim %dth day award.", self.player.pid, self.player.online_award_num + 1)
    Rpc:require_online_award(self.player)
    self:_waitFreeTime()
end

local function _get_next_time(player)
    local award_num = #resmng.prop_online_award
    if award_num <= player.online_award_num then
        return get_next_day_stamp(gTime) - gTime
    end

    local prop = resmng.prop_online_award[player.online_award_num + 1]
    if nil == prop then
        return get_next_day_stamp(gTime) - gTime
    end
    if player.online_award_time + prop.Time >= gTime then
        return player.online_award_time + prop.Time - gTime
    else
        return 0
    end
end

function ChoreDayAward:_waitFreeTime()
    local wait_time = _get_next_time(self.player) + REST_TIME

    INFO("[Autobot|DayAward|%d] wait %d seconds for the next day award.", self.player.pid, wait_time)
    self.timer_id = timer.new_ignore("ChoreDayAward", wait_time, self)
end

timer._funs["ChoreDayAward"] = function(id, self)
    if id ~= self.timer_id then
        return
    end
    self:_claimAward()
end

local function _onBuildingUpdated(self, player, build)
    if BUILD_SHIPYARD_1 == build.propid then
        self:_start()
        self:_stopWatch()
        return
    end
    local prop = resmng.prop_build[build.propid]
    if not prop then
        return
    end
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.CASTLE ~= prop.Mode then
        return
    end
    if prop.Lv < 4 then
        return
    end
    self:_start()
    self:_stopWatch()
end

local function _onTaskInfoUpdated(self, player, task)
    -- 任务ID可以考虑从建筑的条件配置中获取
    if MY_TASK_ID ~= task.task_id then
        return
    end
    if TASK_STATUS.TASK_STATUS_ACCEPTED ~= task.task_status then
        return
    end
    INFO("[Autobot|ChoreDayAward|%d] Finished task, start to claim day award", self.player.pid)
    self:_start()
    self:_stopWatch()
end

function ChoreDayAward:_startWatch()
    self.is_watching = true

    self.build_functor = newFunctor(self, _onBuildingUpdated)
    self.player.eventBuildUpdated:add(self.build_functor)
    self.player.eventNewBuild:add(self.build_functor)

    self.task_functor = newFunctor(self, _onTaskInfoUpdated)
    self.player.eventTaskInfoUpdated:add(self.task_functor)
end

function ChoreDayAward:_stopWatch()
    if not self.is_watching then
        return
    end
    self.player.eventBuildUpdated:del(self.build_functor)
    self.player.eventNewBuild:del(self.build_functor)
    self.build_functor = nil

    self.player.eventTaskInfoUpdated:del(self.task_functor)
    self.task_functor = nil
end

return makeClass(ChoreDayAward)

