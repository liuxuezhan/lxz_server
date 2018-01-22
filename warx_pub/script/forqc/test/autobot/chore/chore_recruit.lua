local ChoreRecruit = {}

local RECRUIT_COUNT = config.Autobot.RecruitCount or 25
local REST_TIME = 1
local MIN_TRAIN_LV = config.Autobot.RecruitMinLv or 7
local MAX_WATER_LIMIT = 1.1
local MIN_WATER_LIMIT = 0.9
local FULL_WAIT_TIME = 30

function ChoreRecruit:init(player)
    self.player = player

    self:_start()
end

function ChoreRecruit:uninit()
    self:_stop()
end

local Watching = makeState({})
function Watching:onEnter()
    local build, prop = self.host.player:get_build(BUILD_CLASS.ARMY, self.fsm.mode)
    if nil == build then
        self:translate("NoBuilding")
        return
    end
    if build.state == BUILD_STATE.WAIT and prop.TrainLv >= MIN_TRAIN_LV then
        self:translate("Recruit")
        return
    end
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
end

function Watching:onExit()
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

function Watching:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if prop.Class ~= BUILD_CLASS.ARMY or prop.Mode ~= self.fsm.mode then
        return
    end
    if build.state == BUILD_STATE.WAIT and prop.TrainLv >= MIN_TRAIN_LV then
        self:translate("Recruit")
    end
end

local Recruit = makeState({})
function Recruit:onEnter()
    local max_train = self.host.player:get_val("CountTrain")
    local num = RECRUIT_COUNT > max_train and max_train or RECRUIT_COUNT
    INFO("[Autobot|ChoreRecruit|%d|%d] initial recruit job", self.host.player.pid, self.fsm.mode)
    self.host.player.recruit_manager:addRecruitJob(self.fsm.mode, 0, num, 100, ACC_TYPE.ITEM, function()
        self:translate("Rest")
    end)
end

local NoBuilding = makeState({})
function NoBuilding:onEnter()
    self.host.player.eventNewBuild:add(newFunctor(self, self._onNewBuild))
end

function NoBuilding:onExit()
    self.host.player.eventNewBuild:del(newFunctor(self, self._onNewBuild))
end

function NoBuilding:_onNewBuild(player, build)
    local prop = resmng.prop_build[build.propid]
    if prop.Class == BUILD_CLASS.ARMY and prop.Mode == self.fsm.mode then
        self:translate("Watching")
    end
end

local Rest = makeState({})
function Rest:onEnter()
    self.timer_id = AutobotTimer:addTimer(function() self:translate("Watching") end, REST_TIME)
end

function Rest:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local Full = makeState({})
function Full:onEter()
    self.timer_id = Autobot:addPeriodicTimer(newFunctor(self, self._checkArmy), FULL_WAIT_TIME)
end

function Full:onExit()
    AutobotTimer:delPeriodicTimer(self.timer_id)
    self.timer_id = nil
end

function Full:_checkArmy()
    local max_train = self.host.player:get_val("CountTrain")
    local soldier_count = self.host.player:getSoldierCount()
    if soldier_count < max_train * MIN_WATER_LIMIT then
        self:translate("Watching")
    end
end

function ChoreRecruit:_create(mode)
    local runner = StateMachine:createInstance(self)
    runner:addState("Watching", Watching, true)
    runner:addState("Recruit", Recruit)
    runner:addState("NoBuilding", NoBuilding)
    runner:addState("Rest", Rest)
    runner:addState("Full", Full)
    runner.mode = mode
    runner:start()

    table.insert(self.runners, runner)
end

function ChoreRecruit:_start()
    self.runners = {}
    for k, v in pairs(BUILD_ARMY_MODE) do
        self:_create(v)
    end
end

function ChoreRecruit:_stop()
    if nil ~= self.runners then
        for k, v in pairs(self.runners) do
            v:stop()
        end
        self.runners = nil
    end
end

return makeChoreClass("Recruit", ChoreRecruit)

