local ChoreUnionBuildlvDonate = {}

local DONATE_REST_TIME = 1
local BOOT_TIME = 6

function ChoreUnionBuildlvDonate:init(player)
    self.player = player
    player.eventUnionChanged:add(newFunctor(self, self._onUnionChanged))

    if nil ~= player.union then
        self:_start()
    end
end

function ChoreUnionBuildlvDonate:uninit()
    player.eventUnionChanged:del(newFunctor(self, self._onUnionChanged))
end

function ChoreUnionBuildlvDonate:_onUnionChanged(player, uid)
    if 0 == uid then
        self:_stop()
    else
        self:_start()
    end
end

local Starter = makeState({})
function Starter:onEnter()
    self.func = self.func or function() self:translate("LoadBuild") end
    local wait_time = math.random(math.floor(BOOT_TIME/2), BOOT_TIME)
    self.timer_id = AutobotTimer:addTimer(self.func, wait_time)
end

function Starter:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local LoadBuild = makeState({})
function LoadBuild:onEnter()
    self.func = self.func or function(player, what)
        if "build" ~= what then
            return
        end
        self:translate("Donate")
    end
    self.host.player.eventUnionLoaded:add(self.func)
    Rpc:union_load(self.host.player, "build")
end

function LoadBuild:onExit()
    self.host.player.eventUnionLoaded:del(self.func)
end

local Donate = makeState({})
function Donate:onEnter()
    self.func = self.func or function() self:translate("Rest") end
    self.host.player.eventUnionBuildlvDonate:add(self.func)

    local mode = self.host.player:getDonatableBuildlvMode()
    if nil == mode then
        self:translate("Exhausted")
        return
    end
    INFO("[Autobot|UnionBuildlvDonate|%d] donate buildlv %d", self.host.player.pid, mode)
    Rpc:union_buildlv_donate(self.host.player, mode)
end

function Donate:onExit()
    self.host.player.eventUnionBuildlvDonate:del(self.func)
end

local Rest = makeState({})
function Rest:onEnter()
    self.func = self.func or function() self:translate("Donate") end
    self.timer_id = AutobotTimer:addTimer(self.func, DONATE_REST_TIME)
end

function Rest:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local Exhausted = makeState({})
function Exhausted:onEnter()
    self.func = self.func or function() self:translate("Starter") end

    local wait_time = get_next_day_stamp(gTime) - gTime
    self.timer_id = AutobotTimer:addTimer(self.func, wait_time)
    INFO("[Autobot|UnionBuildlvDonate|%d] donate exhausted, wait %d seconds", self.host.player.pid, wait_time)
end

function Exhausted:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function ChoreUnionBuildlvDonate:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("Starter", Starter, true)
    runner:addState("LoadBuild", LoadBuild)
    runner:addState("Donate", Donate)
    runner:addState("Rest", Rest)
    runner:addState("Exhausted", Exhausted)

    self.runner = runner
    runner:start()
end

function ChoreUnionBuildlvDonate:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("UnionBuildlvDonate", ChoreUnionBuildlvDonate)

