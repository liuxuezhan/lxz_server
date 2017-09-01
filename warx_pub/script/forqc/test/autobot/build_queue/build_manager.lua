local BuildManager = {}

local _predefined_buildings = {
    --{2001004, 1},
    --{1001003, 3},
}

function BuildManager:init(player)
    self.player = player
    self.buildings = {}
    self.upgrading_build = {}
    self:_initPredefinedBuildings()
    self.eventJobAccepted = newEventHandler()
    self.eventBuildingCompleted = newEventHandler()
    self.eventUpgradingBuildCompleted = newEventHandler()
    self:_initBuildQueue()
    self.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
end

function BuildManager:uninit()
    self.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

-- 添加需要修改/升级的建筑
function BuildManager:addBuilding(propid, priority, num, functor)
    --local build, need_upgrade = self:_getBuild(propid)
    --if nil == build or need_upgrade then
        return self:_addBuilding(propid, priority, num, functor)
    --end
end

local function _getConstructBuilding(self, propid)
    propid = propid - propid % 100 + 1
    local prop = resmng.prop_build[propid]
    if Autobot.condCheck(self.player, prop.Cond) then
        --INFO("[Autobot|BuildManager|%d]_getConstructBuilding %d cond check ok.", self.player.pid, propid)
        return nil, propid
    else
        local pre_propid = self:_getPrereqBuilding(propid)
        if nil ~= pre_propid then
            --INFO("[Autobot|BuildManager|%d]_getConstructBuilding %d cond check not ok, pre %d.", self.player.pid, propid, pre_propid)
            local build = self:_getMaxLvBuild(pre_propid)
            if nil == build then
                return _getConstructBuilding(self, pre_propid)
            else
                return build, build.propid + 1
            end
        end
    end
end

local function _isBuildingUpgradable(build)
    if BUILD_STATE.WAIT == build.state then
        return true
    end
    local prop = resmng.prop_build[build.propid]
    if build.state == BUILD_STATE.WORK then
        if prop.Class == BUILD_CLASS.RESOURCE then
            return true
        end
        if prop.Class == BUILD_CLASS.FUNCTION and prop.Mode == BUILD_FUNCTION_MODE.HOSPITAL then
            return true
        end
    end
end

function BuildManager:getNextBuilding()
    local index = 1
    while nil ~= self.buildings[index] do
        if self.buildings[index].completed then
            table.remove(self.buildings, index)
        else
            index = index + 1
        end
    end
    for k, v in ipairs(self.buildings) do
        --local has_built
        local prop = resmng.prop_build[v.propid]
        local count = 0
        local valid_count = 0
        local upgradable_buildings = {}
        for k, v1 in pairs(self.player._build or {}) do
            local build_prop = resmng.prop_build[v1.propid]
            if build_prop.Class == prop.Class and build_prop.Mode == prop.Mode then
                count = count + 1
                if build_prop.Lv >= prop.Lv then
                    valid_count = valid_count + 1
                else
                    table.insert(upgradable_buildings, v1)
                end
            end
        end
        if count < v.num then
            local build, propid = _getConstructBuilding(self, v.propid)
            if nil == build or _isBuildingUpgradable(build) then
                return build, propid
            else
                self:_addUpgradingBuilding(build)
            end
        elseif valid_count < v.num then
            for _, b in pairs(upgradable_buildings) do
                local build_prop = resmng.prop_build[b.propid + 1]
                if Autobot.condCheck(self.player, build_prop.Cond) then
                    if _isBuildingUpgradable(b) then
                        return b, b.propid + 1
                    else
                        self:_addUpgradingBuilding(b)
                    end
                else
                    local pre_propid = self:_getPrereqBuilding(v.propid)
                    if nil ~= pre_propid then
                        local build = self:_getMaxLvBuild(pre_propid)
                        if nil == build then
                            local build, propid = _getConstructBuilding(self, pre_propid)
                            if nil == build or _isBuildingUpgradable(build) then
                                return build, propid
                            else
                                self:_addUpgradingBuilding(build)
                            end
                        elseif _isBuildingUpgradable(build) then
                            return build, build.propid + 1
                        else
                            self:_addUpgradingBuilding(build)
                        end
                    end
                end
            end
        else
            -- 通知外部修建完成
            if v.functor then
                v.functor(v.propid, v.num)
            end
            -- 设定删除标记
            v.completed = true

            self.eventBuildingCompleted(self, v.propid)
        end
    end
end

local function _getCondBuilding(self, class, mode, lv)
    if class == resmng.CLASS_BUILD then
        local prop = resmng.prop_build[mode]
        if prop then
            local c = prop.Class
            local m = prop.Mode
            local l = prop.Lv

            local build = self:_getMaxLvBuild(prop.ID)
            if nil ~= build then
                local build_prop = resmng.prop_build[build.propid]
                if build_prop.Lv < l then
                    local pre_propid = self:_getPrereqBuilding(v.propid + 1)
                    if nil ~= pre_propid then
                        return pre_propid
                    else
                        return v.propid + 1
                    end
                end
            else
                return prop.ID - math.floor(prop.ID % 1000) + 1
            end

            --[[
            for _, v in pairs(self.player._build or{}) do
                local build_prop = resmng.prop_build[v.propid]
                if build_prop and build_prop.Class == c and build_prop.Mode == m then
                    if build_prop.Lv < l then
                        local pre_propid = self:_getPrereqBuilding(v.propid + 1)
                        if nil ~= pre_propid then
                            return pre_propid
                        else
                            return v.propid + 1
                        end
                    end
                end
            end
            ]]
        end
    end
end

local function _getLogicalBuilding(self, operator, ...)
    if "OR" == operator then
        for k, v in pairs({...}) do
            local class, mode, lv = unpack(v)
            if class == resmng.CLASS_BUILD then
                local pre_propid = _getCondBuilding(self, class, mode, lv)
                if nil ~= pre_propid then
                    return pre_propid
                end
            end
        end
    elseif "AND" == operator then
    end
end

function BuildManager:_getPrereqBuilding(propid)
    local prop = resmng.prop_build[propid]
    for k, v in pairs(prop.Cond) do
        local class, mode, lv = unpack(v)
        if "OR" == class or "AND" == class then
            local pre_propid = _getLogicalBuilding(self, unpack(v))
            if nil ~= pre_propid then
                return pre_propid
            end
        else
            local pre_propid = _getCondBuilding(self, class, mode, lv)
            if nil ~= pre_propid then
                return pre_propid
            end
        end
    end
end

function BuildManager:_getMaxLvBuild(propid)
    local build
    local max_level = 0
    for k, v in pairs(self.player._build or {}) do
        local build build_prop = resmng.prop_build[v.propid]
        if build_prop.Class == prop.Class and build_prop.Mode == prop.Mode then
            if max_level < build_prop.Lv then
                build = v
                max_level = build_prop.Lv
            end
        end
    end
    return build
end

function BuildManager:_getBuild(propid)
    local prop = resmng.prop_build[propid]
    for k, v in pairs(self.player._build or {}) do
        local build build_prop = resmng.prop_build[v.propid]
        if build_prop.Class == prop.Class and
            build_prop.Mode == prop.Mode then
            return v, build_prop.Lv <= prop.Lv
        end
    end
end

function BuildManager:_initPredefinedBuildings()
    for k, v in ipairs(_predefined_buildings) do
        self:addBuilding(v[1], 1, v[2])
    end
end

function BuildManager:getMaxPriority(propid)
    local prop = resmng.prop_build[propid]
    local max_priority = 0
    for k, v in pairs(self.buildings) do
        if not v.completed then
            local tmp_prop = resmng.prop_build[v.propid]
            if prop.Class == tmp_prop.Class and prop.Mode == tmp_prop.Mode then
                if v.priority > max_priority then
                    max_priority = v.priority
                end
            end
        end
    end
    return max_priority
end

function BuildManager:_addBuilding(propid, priority, num, functor)
    local resort = false
    num = num or 1

    table.insert(self.buildings, {propid = propid, priority = priority, num = num, functor=functor})
    resort = true
    -- 
    if resort then
        table.sort(self.buildings, function(a, b)
            return a.priority > b.priority
        end)
    end

    self.eventJobAccepted(propid)
end

function BuildManager:_addUpgradingBuilding(build)
    self.upgrading_build[build.idx] = true
end

function BuildManager:_onBuildUpdated(player, build)
    if self.upgrading_build[build.idx] then
        self.upgrading_build[build.idx] = nil
        self.eventUpgradingBuildCompleted(build)
    end
end

local WaitJob = makeState({})
function WaitJob:onEnter()
    self.host.eventJobAccepted:add(newFunctor(self, self._onJobAccepted))
    self.host.eventUpgradingBuildCompleted:add(newFunctor(self, self._onBuildingCompleted))
end

function WaitJob:onExit()
    self.host.eventJobAccepted:del(newFunctor(self, self._onJobAccepted))
    self.host.eventUpgradingBuildCompleted:del(newFunctor(self, self._onBuildingCompleted))
end

function WaitJob:_onJobAccepted(propid)
    if self.host:_hasActiveBuildQueue() then
        self:translate("Initiator")
    else
        self:translate("WaitBuildQueue")
    end
end

function WaitJob:_onBuildingCompleted(build)
    if self.host:_hasActiveBuildQueue() then
        self:translate("Initiator")
    else
        self:translate("WaitBuildQueue")
    end
end

local WaitBuildQueue = makeState({})
function WaitBuildQueue:onEnter()
    self.host.eventActiveBuildQueue:add(newFunctor(self, self._onActiveBuildQueue))
end

function WaitBuildQueue:onExit()
    self.host.eventActiveBuildQueue:del(newFunctor(self, self._onActiveBuildQueue))
end

function WaitBuildQueue:_onActiveBuildQueue()
    if self.host:_hasActiveBuildQueue() then
        self:translate("Initiator")
    end
end

local Initiator = makeState({})
function Initiator:onEnter()
    local queue_index, remain = self.host:_getBuildQueueInfo()
    if nil == queue_index then
        self:translate("WaitBuildQueue")
        return
    end
    local build, propid = self.host:getNextBuilding()
    if nil == propid then
        self:translate("WaitJob")
        return
    end
    -- TODO: 资源不够的处理可以交给getNextBuilding处理仅返回能修建的建筑，但需要添加资源变化的监控
    local prop = resmng.prop_build[propid]
    assert(prop, "[Autobot|BuildManager|%d] non-exist build propid %d", self.host.player.pid, propid)
    --if not Autobot.condCheck(self.host.player, prop.Cond) then
    --    self:translate("WaitJob")
    --    return
    --end
    local dura = math.ceil(prop.Dura / (1+self.host.player:get_num("SpeedBuild_R") * 0.0001))
    if dura > remain then
        self:translate("BuyBuildQueue", queue_index)
        return
    end
    if nil == build then
        local max_seq = (BUILD_MAX_NUM[prop.Class] and BUILD_MAX_NUM[prop.Class][prop.Mode]) or 1
        local x = 0
        if max_seq > 1 then
            x = find_enabled_pos(self.host.player)
        end
        INFO("[Autobot|BuildManager|%d] Construct building %d", self.host.player.pid, propid)
        Rpc:construct(self.host.player, x, 0, prop.ID)
        if dura <= 0 then
            -- 直接完成的建筑，需要等待建筑状态处理完成（从Create变更为WAIT或WORK）
            self:translate("SecConstruct", propid)
            return
        end
        self:translate("Construct", propid)
    else
        local upgradable = false
        if build.state == BUILD_STATE.WAIT then
            upgradable = true
        elseif build.state == BUILD_STATE.WORK then
            if prop.Class == BUILD_CLASS.RESOURCE then
                upgradable = true
            elseif prop.Class == BUILD_CLASS.FUNCTION then
                if prop.Mode == BUILD_FUNCTION_MODE.HOSPITAL then
                    upgradable = true
                elseif prop.Mode == BUILD_FUNCTION_MODE.ACADEMY then
                    self.host.player.eventBuildUpdated:add(newFunctor(self, self._handleAcademyUpgrade))
                    self.build_idx = build.idx
                    self.propid = propid
                    INFO("[Autobot|BuildManager|%d] Wait academy's research finish.", self.host.player.pid)
                    return
                end
            end
        end
        self:_upgradeBuilding(build, propid)
    end
end

function Initiator:onExit()
    self.build_idx = nil
    self.propid = nil
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._handleAcademyUpgrade))
end

function Initiator:_handleAcademyUpgrade(player, build)
    if build.idx ~= self.build_idx then
        return
    end
    if build.state ~= BUILD_STATE.WAIT then
        return
    end
    self:_upgradeBuilding(build, 0)
end

function Initiator:_upgradeBuilding(build, propid)
    INFO("[Autobot|BuildManager|%d] Upgrade building %d from %d to %d", self.host.player.pid, build.idx, build.propid, propid)
    Rpc:upgrade(self.host.player, build.idx)
    self:translate("Upgrade", build.idx)
end

local Upgrade = makeState({})
function Upgrade:onEnter(build_idx)
    self.build_idx = build_idx
    self.host.eventDeactiveBuildQueue:add(newFunctor(self, self._onDeactiveBuildQueue))
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
end

function Upgrade:onExit()
    self.host.eventDeactiveBuildQueue:del(newFunctor(self, self._onDeactiveBuildQueue))
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    self.queue_flag = nil
    self.build_idx = nil
    self.upgrade_flag = nil
end

function Upgrade:_onDeactiveBuildQueue(index)
    --INFO("[Autobot|BuildManager|%d] upgrade building build queue marked", self.host.player.pid)
    self.queue_flag = true
    self:_tryTranslate()
end

function Upgrade:_onBuildUpdated(player, build)
    if build.idx ~= self.build_idx then
        return
    end
    if build.state ~= BUILD_STATE.UPGRADE then
        return
    end
    --INFO("[Autobot|BuildManager|%d] upgrade build state", self.host.player.pid)
    self.upgrade_flag = true
    self:_tryTranslate()
end

function Upgrade:_tryTranslate()
    if self.queue_flag and self.upgrade_flag then
        self:translate("Rest")
    end
end

local Construct = makeState({})
function Construct:onEnter()
    self.host.eventDeactiveBuildQueue:add(newFunctor(self, self._onDeactiveBuildQueue))
end

function Construct:onExit()
    self.host.eventDeactiveBuildQueue:del(newFunctor(self, self._onDeactiveBuildQueue))
end

function Construct:_onDeactiveBuildQueue(index)
    self:translate("Rest")
end

local Rest = makeState({})
function Rest:onEnter()
    AutobotTimer:addTimer(function() self:translate("Initiator") end, 1)
    --action(function()
    --    sync(self.host.player)
    --    self:translate("Initiator")
    --end)
end

local SecConstruct = makeState({})
function SecConstruct:onEnter(propid)
    local prop = resmng.prop_build[propid]
    self.propid = prop.StartLevel or propid
    self.host.player.eventNewBuild:add(newFunctor(self, self._onConstructBuilding))
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onUpdateBuilding))
end

function SecConstruct:onExit()
    self.propid = nil
    self.build_idx = nil
    self.host.player.eventNewBuild:del(newFunctor(self, self._onConstructBuilding))
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onUpdateBuilding))
end

function SecConstruct:_onConstructBuilding(player, build)
    if build.state ~= BUILD_STATE.CREATE or build.propid ~= self.propid then
        return
    end
    INFO("[Autobot|BuildManager|%d] wait the completion of build %d", self.host.player.pid, build.idx)
    self.build_idx = build.idx
end

function SecConstruct:_onUpdateBuilding(player, build)
    if self.build_idx ~= build.idx then
        return
    end
    if build.state == BUILD_STATE.CREATE then
        return
    end
    INFO("[Autobot|BuildManager|%d] Build %d has been constructed", self.host.player.pid, build.idx)
    self:translate("Rest")
end

local BuyBuildQueue = makeState({})
function BuyBuildQueue:onEnter()
    Rpc:buy_item(self.host.player, resmng.MALL_BUILD_QUEUE, 1, 1)
    self.last_remain = self.host.player:get_buf_remain(resmng.BUFF_COUNT_BUILD)
    self.host.player.eventBufUpdated:add(newFunctor(self, self._onBufUpdated))
end

function BuyBuildQueue:onExit()
    self.host.player.eventBufUpdated:del(newFunctor(self, self._onBufUpdated))
end

function BuyBuildQueue:_onBufUpdated()
    local remain = self.host.player:get_buf_remain(resmng.BUFF_COUNT_BUILD)
    if remain > self.last_remain then
        INFO("[Autobot|BuildManager|%d] The 2nd build queue has %d seconds left.", self.host.player.pid, remain)
        self:translate("Initiator")
    end
end

function BuildManager:_initBuildQueue()
    self.active_queue = {}
    self.eventActiveBuildQueue = newEventHandler()
    self.eventDeactiveBuildQueue = newEventHandler()

    local runner = StateMachine:createInstance(self)
    --runner.__debug = true
    runner:addState("WaitJob", WaitJob, true)
    runner:addState("WaitBuildQueue", WaitBuildQueue)
    runner:addState("Initiator", Initiator)
    runner:addState("SecConstruct", SecConstruct)
    runner:addState("Construct", Construct)
    runner:addState("Upgrade", Upgrade)
    runner:addState("Rest", Rest)
    runner:addState("BuyBuildQueue", BuyBuildQueue)
    runner:start()

    self.build_queue_runner = runner
end

function BuildManager:activeBuildQueue(index)
    self.active_queue[index] = true
    self.eventActiveBuildQueue(index)
end

function BuildManager:deactiveBuildQueue(index)
    self.active_queue[index] = nil
    self.eventDeactiveBuildQueue(index)
end

function BuildManager:_getBuildQueueInfo()
    --local build_queue = self.player.build_queue
    if self.active_queue[1] then
        return 1, math.huge
    end

    if self.active_queue[2] then
        -- 获取剩余的时间
        local remain = self.player:get_buf_remain(resmng.BUFF_COUNT_BUILD)
        return 2, remain
    end
end

function BuildManager:_hasActiveBuildQueue()
    return next(self.active_queue)
end


return makeClass(BuildManager)

