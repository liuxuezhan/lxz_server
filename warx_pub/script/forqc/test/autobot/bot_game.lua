local BotGame = {}
local HeartInterval = 60

local function _createBuildQueue(self, which_queue)
    local data = {entity = self.host, player = self.host.player, which_queue = which_queue}
    local line = Workline:createInstance(data)
    line:addState("Idle", BuildQueueIdle, true)
    line:addState("Building", BuildQueueBuilding)
    line:addState("Accelerate", BuildQueueAccelerate)
    self:_addWorkline(line)
    return line
end

local function _createTroopWorkline(self)
    local troop_manager = self.host.player.troop_manager
    local line = Workline:createInstance(troop_manager)
    --line.__debug = true
    line:addState("Idle", TroopIdle, true)
    line:addState("TakeAction", TroopTakeAction)
    line:addState("Wait", TroopWait)
    line:addState("Rest", TroopRest)
    self:_addWorkline(line)
    return line
end

local function _createRecruitWorkline(self, mode)
    local recruit_manager = self.host.player.recruit_manager
    local line = Workline:createInstance(recruit_manager)
    line.mode = mode
    line:addState("Idle", RecruitIdle, true)
    line:addState("TakeAction", RecruitTakeAction)
    line:addState("Working", RecruitWorking)
    self:_addWorkline(line)
    return line
end

local function _createTechWorkline(self)
    local tech_manager = self.host.player.tech_manager
    local line = Workline:createInstance(tech_manager)
    line:addState("Idle", TechIdle, true)
    line:addState("TakeAction", TechTakeAction)
    line:addState("Studying", TechStudying)
    self:_addWorkline(line)
    return line
end

local function _createChoreWorkline(self)
    local line = Workline:createInstance(self.host.player)
    line:addState("Chore", Chore, true)
    self:_addWorkline(line)
    return line
end


------------------ start scavenger ------------------
local function _createTaskScavenger(self)
    local task_manager = self.host.player.task_manager
    local scavenger = Workline:createInstance(task_manager)
    scavenger:addState("Main", ScavengerTask, true)
    self:_addWorkline(scavenger)
    return scavenger
end

local function _createTechScavenger(self)
    local scavenger = Workline:createInstance(self.host.player.tech_manager)
    scavenger:addState("Main", ScavengerTech, true)
    self:_addScavenger(scavenger)
    return line
end
------------------ end scavenger ------------------

local function _startAllWorkline(self)
    for k, v in ipairs(self.worklines) do
        v:start()
    end
end

function BotGame:onInit()
    self.needUpdate = true
    self.worklines = {}
end

function BotGame:onEnter()
    local player = self.host
    INFO("[Autobot|InGame|%d]Player enter game.", player.pid)

    -- 心跳处理
    local id, node = timer.new_ignore("BotGame_HeartBeat", HeartInterval, self)
    node.cycle = HeartInterval

    -- 建筑修建工作线
    _createBuildQueue(self, 1)
    --_createBuildQueue(self, 2)

    -- 招兵工作线
    _createRecruitWorkline(self, BUILD_ARMY_MODE.BARRACKS)
    _createRecruitWorkline(self, BUILD_ARMY_MODE.STABLES)
    _createRecruitWorkline(self, BUILD_ARMY_MODE.RANGE)
    _createRecruitWorkline(self, BUILD_ARMY_MODE.FACTORY)

    -- 研究工作线
    _createTechWorkline(self)

    -- 铁匠工作线

    -- 行军工作线
    _createTroopWorkline(self)
    --_createTroopWorkline(self)

    -- 特殊工作线

    -- 杂项事情工作线
    _createChoreWorkline(self)

    -- 军团工作线

    -- Scavengers
    _createTechScavenger(self)
    _createTaskScavenger(self)

    _startAllWorkline(self)
end

function BotGame:onUpdate()
    Workline.updateState(self.host)
end

function BotGame:onExit()
end

function BotGame:_addWorkline(line)
    table.insert(self.worklines, line)
end

function BotGame:_addScavenger(scavenger)
    table.insert(self.worklines, scavenger)
end

timer._funs["BotGame_HeartBeat"] = function(sn, self)
    --INFO("[Autobot|HeartBeat|%d]Heartbeat", self.host.player.pid)
    Rpc:ping(self.host.player)
    return 1
end

return makeState(BotGame)
