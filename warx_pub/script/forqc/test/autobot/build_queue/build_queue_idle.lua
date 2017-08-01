local BuildQueueIdle = {}

function BuildQueueIdle:onInit()
end

local function _getBuildingIdx(self)
    return self.player.build_queue[self.which_queue]
end

local function _getBuild(self, propid)
    local prop = resmng.prop_build[propid]
    for k, v in pairs(self.player._build or {}) do
        local build_prop = resmng.prop_build[v.propid]
        if build_prop.Class == prop.Class and
            build_prop.Mode == prop.Mode then
            return v, build_prop.Lv <= prop.Lv
        end
    end
end

local RESULT = {}
RESULT.OK = 0
RESULT.WRONG_PROPID = 1
RESULT.COND_FAILED = 2

local function _constructBuilding(player, propid)
    local node = resmng.prop_build[propid]
    if not node then
        return RESULT.WRONG_PROPID
    end
    if not Autobot.condCheck(player, node.Cond) then
        return RESULT.COND_FAILED
    end
    local max_seq = (BUILD_MAX_NUM[node.Class] and BUILD_MAX_NUM[node.Class][node.Mode]) or 1
    local x = 0
    if max_seq > 1 then
        x = find_enabled_pos(player)
    end
    INFO("[Autobot|BuildQueue|%d]Start to construct building %d", player.pid, propid)
    Rpc:construct(player, x, 0, node.ID)
    sync(player)
    return RESULT.OK, propid
end

local function _upgradeBuilding(player, idx, propid)
    local node = resmng.prop_build[propid]
    if not node.Dura then
        return RESULT.WRONG_PROPID
    end
    if not Autobot.condCheck(player, node.Cond) then
        return RESULT.COND_FAILED
    end
    INFO("[Autobot|BuildQueue|%d]Start to upgrade building %d|%d", player.pid, idx, propid)
    Rpc:upgrade(player, idx)
    sync(player)
    return RESULT.OK, propid
end

local function _onConstructBuilding(self, result, propid)
    INFO("[Autobot|BuildQueue|%d|%d] _onConstructBuilding: %d, %d", self.player.pid, self.which_queue, result, propid or 0)
    if RESULT.OK == result then
        self.fsm:translate("Building")
    end
end

local function _onUpgradeBuilding(self, result, propid)
    INFO("[Autobot|BuildQueue|%d|%d] _onUpgradeBuilding: %d, %d", self.player.pid, self.which_queue, result, propid or 0)
    if RESULT.OK == result then
        self.fsm:translate("Building")
    end
end

local function _onNewBuilding(self)
    self:_startBuild()
end

local function _buildSomething(self)
    local build, propid = self.player.wanted_building:getNextBuilding()
    if nil == propid then
        INFO("[Autobot|BuildQueue|%d|%d]There is no build to build.", self.player.pid, self.which_queue)
        self.player.wanted_building.eventNewBuilding:add(newFunctor(self, _onNewBuilding))
        return
    end
    if nil == build then
        TaskMng:createTask(_constructBuilding, newFunctor(self, _onConstructBuilding), self.player, propid)
    else
        TaskMng:createTask(_upgradeBuilding, newFunctor(self, _onUpgradeBuilding), self.player, build.idx, propid)
    end
end

function BuildQueueIdle:_startBuild()
    local build_idx = _getBuildingIdx(self)
    if nil == build_idx then
        -- the build queue need purchase, purchase it
    elseif 0 == build_idx then
        -- it's idle, make a new building progress
        _buildSomething(self)
    else
        -- it's building something, translate to building state
        INFO("[Autobot|BuildQueue|%d|%d]The build %d is under construction", self.player.pid, self.which_queue, build_idx)
        self.fsm:translate("Building")
    end
end

function BuildQueueIdle:onEnter()
    self.which_queue = self.host.which_queue
    self.player = self.host.entity.player

    self:_startBuild()
end

function BuildQueueIdle:onUpdate()
end

function BuildQueueIdle:onExit()
    self.player.wanted_building.eventNewBuilding:del(newFunctor(self, _onNewBuilding))
end

return makeState(BuildQueueIdle)

