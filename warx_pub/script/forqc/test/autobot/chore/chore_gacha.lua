local ChoreGacha = {}

local PRE_TASK_ID = 130010121
local REST_TIME = config.Autobot.ChoreRestTime or 5

local GACHA_TYPE_LIST = 
{
    GACHA_TYPE.YINBI_ONE,
    GACHA_TYPE.JINBI_ONE,
}

function ChoreGacha:init(player)
    self.player = player

    if self:_canStart() then
        INFO("[Autobot|Gacha|%d] start gacha routine.", self.player.pid)
        self:_start()
    else
        INFO("[Autobot|Gacha|%d] watch gacha pre-condition.", self.player.pid)
        self:_startWatch()
    end
end

function ChoreGacha:uninit()
    self.timer_id = nil
    self:_stopWatch()
end

function ChoreGacha:_canStart()
    local prop = resmng.prop_build[resmng.BUILD_HALLOFHERO_1]
    if nil == prop then
        return
    end
    return Autobot.condCheck(self.player, prop.Cond)
end

function ChoreGacha:_start()
    -- wait for a while to start the actual work
    self:_waitFreeTime()
end

local function _claimGachaPoint(self)
    local player = self.player

    if player.gacha_box >= resmng.GACHA_PIONT_3 then
        return
    end
    local index = player.gacha_box + 1
    local prop = resmng.prop_gacha_piont[index]
    if nil == prop then
        return
    end
    if player.gacha_gift < prop.Require then
        return
    end
    INFO("[Autobot|Gacha|%d] claim gacha box %d", self.player.pid, index)
    Rpc:get_gacha_box(player)
end

function ChoreGacha:_doGacha()
    _claimGachaPoint(self)

    local prop_jinbi = resmng.prop_gacha_gacha[resmng.GACHA_GACHA_2]
    if self.player.gacha_jinbi_free_num < prop_jinbi.Free and gTime >= self.player.gacha_jinbi_cd then
        INFO("[Autobot|Gacha|%d] free claim gacha jinbi", self.player.pid)
        Rpc:do_gacha(self.player, GACHA_TYPE.JINBI_ONE)
    end

    local prop_yinbi = resmng.prop_gacha_gacha[resmng.GACHA_GACHA_1]
    if self.player.gacha_yinbi_free_num < prop_yinbi.Free then
        if gTime >= self.player.gacha_yinbi_cd then
            INFO("[Autobot|Gacha|%d] free claim gacha yinbi %d", self.player.pid, self.player.gacha_yinbi_free_num)
            Rpc:do_gacha(self.player, GACHA_TYPE.YINBI_ONE)
        end
        self:_waitFreeTime()
    else
        INFO("[Autobot|Gacha|%d] No more free yinbi gacha", self.player.pid)
    end
end

function ChoreGacha:_waitFreeTime()
    local wait_time
    if gTime < self.player.gacha_yinbi_cd then
        wait_time = self.player.gacha_yinbi_cd - gTime + REST_TIME
    else
        wait_time = REST_TIME
    end
    INFO("[Autobot|Gacha|%d] wait %d seconds for next gacha", self.player.pid, wait_time)
    self.timer_id = timer.new_ignore("ChoreGacha", wait_time, self)
end

timer._funs["ChoreGacha"] = function(id, self)
    if id ~= self.timer_id then
        return
    end
    self:_doGacha()
end

local function _onBuildingUpdated(self, player, build)
    if BUILD_HALLOFHERO_1 == build.propid then
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
    if PRE_TASK_ID ~= task.task_id then
        return
    end
    if TASK_STATUS.TASK_STATUS_ACCEPTED ~= task.task_status then
        return
    end
    INFO("[Autobot|ChoreGacha|%d] Finished task, start to claim free gacha", self.player.pid)
    self:_start()
    self:_stopWatch()
end

function ChoreGacha:_startWatch()
    self.is_watching = true

    self.build_functor = newFunctor(self, _onBuildingUpdated)
    self.player.eventBuildUpdated:add(self.build_functor)
    self.player.eventNewBuild:add(self.build_functor)

    self.task_functor = newFunctor(self, _onTaskInfoUpdated)
    self.player.eventTaskInfoUpdated:add(self.task_functor)
end

function ChoreGacha:_stopWatch()
    if not self.is_watching then
        return
    end
    self.player.eventBuildUpdated:del(self.build_functor)
    self.player.eventNewBuild:del(self.build_functor)
    self.build_functor = nil

    self.player.eventTaskInfoUpdated:del(self.task_functor)
    self.task_functor = nil
end

return makeClass(ChoreGacha)

