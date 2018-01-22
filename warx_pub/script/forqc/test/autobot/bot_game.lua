local BotGame = {}
local HeartInterval = 60

local function _createBuildQueue(self, queue_index)
    local build_manager = self.host.player.build_manager
    local line = BuildQueueMachine:createInstance(build_manager)
    line.queue_index = queue_index
    line:addState("Idle", BuildQueueIdle)
    --line:addState("AskHelp", BuildAskHelp)
    line:addState("Working", BuildQueueWorking)
    line:addState("Accelerate", BuildQueueAccelerate)
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
    line:addState("Rest", RecruitRest)
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
    local line = Workline:createInstance(self.host)
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
    return scavenger
end

local function _createMonsterScavenger(self)
    local troop_manager = self.host.player.troop_manager
    local scavenger = Workline:createInstance(troop_manager)
    scavenger:addState("Rest", ScavengerMonsterRest, true)
    scavenger:addState("TakeAction", ScavengerMonsterTakeAction)
    scavenger:addState("Recover", ScavengerMonsterRecover)
    self:_addScavenger(scavenger)
    return scavenger
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
    self.heart_beat_timer = AutobotTimer:addPeriodicTimer(function() Rpc:ping(player) end, HeartInterval)

    -- 建筑修建工作线
    _createBuildQueue(self, 1)
    _createBuildQueue(self, 2)

    -- 招兵工作线
    _createRecruitWorkline(self, BUILD_ARMY_MODE.BARRACKS)
    _createRecruitWorkline(self, BUILD_ARMY_MODE.STABLES)
    _createRecruitWorkline(self, BUILD_ARMY_MODE.RANGE)
    _createRecruitWorkline(self, BUILD_ARMY_MODE.FACTORY)

    -- 研究工作线
    _createTechWorkline(self)

    -- 铁匠工作线

    -- 行军工作线
    --_createTroopWorkline(self)
    --_createTroopWorkline(self)

    -- 特殊工作线

    -- 杂项事情工作线
    if not config.Autobot.DisableWorkline.Chore then
        _createChoreWorkline(self)
    end

    -- 军团工作线

    -- Scavengers
    if not config.Autobot.DisableWorkline.TechScavenger then
        _createTechScavenger(self)
    end
    if not config.Autobot.DisableWorkline.TaskScavenger then
        _createTaskScavenger(self)
    end
    if not config.Autobot.DisableWorkline.MonsterScavenger then
        _createMonsterScavenger(self)
    end

    _startAllWorkline(self)

    player.eventPlayerLoaded(player)
end

function BotGame:onUpdate()
    Workline.updateState(self.host)
end

function BotGame:onExit()
    AutobotTimer:delPeriodicTimer(self.heart_beat_timer)
    self.heart_beat_timer = nil

    self:_clearScavengers()
    self:_clearWorklines()
    self.host:uninitPlayer()
end

function BotGame:_addWorkline(line)
    table.insert(self.worklines, line)
end

function BotGame:_addScavenger(scavenger)
    table.insert(self.worklines, scavenger)
end

function BotGame:_clearWorklines()
    for k, v in ipairs(self.worklines) do
        v:stop()
    end
    self.worklines = {}
end

function BotGame:_clearScavengers()
end

return makeState(BotGame)

