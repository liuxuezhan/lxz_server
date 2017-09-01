local ChoreUnionHelp = {}

local HELP_MIN_INTERVAL = config.Autobot.UnionHelpMinInterval or 10
local HELP_MAX_INTERVAL = config.Autobot.UnionHelpMaxInterval or 30

function ChoreUnionHelp:init(player)
    self.player = player
    player.eventUnionChanged:add(newFunctor(self, self._onUnionChanged))

    self:_start(0 ~= player.uid)
end

function ChoreUnionHelp:uninit()
    self:_stop()
    self.player.eventUnionChanged:del(newFunctor(self, self._onUnionChanged))
end

function ChoreUnionHelp:_onUnionChanged(player, uid)
    local current_state = self.runner:getCurrentState()
    if 0 == player.uid then
        if "NoUnion" ~= current_state.name then
            self.runner:translate("NoUnion")
        end
    else
        if "WaitHelp" ~= current_state.name then
            self.runner:translate("WaitHelp")
        end
    end
end

-- not in union
local NoUnion = makeState({})
-- wait for new helps
local WaitHelp = makeState({})
function WaitHelp:onEnter()
    if self.host.player.union_help_manager:hasHelp() then
        self:translate("DoHelp")
        return
    end
    --INFO("[Autobot|UnionHelp|%d] Wait for incoming help", self.host.player.pid)
    self.func = self.func or newFunctor(self, self._onHelpChanged)
    self.host.player.union_help_manager.eventHelpChanged:add(self.func)
end

function WaitHelp:onExit()
    self.host.player.union_help_manager.eventHelpChanged:del(self.func)
end

function WaitHelp:_onHelpChanged()
    if self.host.player.union_help_manager:hasHelp() then
        self:translate("DoHelp")
    end
end
-- do help
local DoHelp = makeState({})
function DoHelp:onEnter()
    self.func = self.func or newFunctor(self, self._doHelp)

    local interval = math.random(HELP_MIN_INTERVAL, HELP_MAX_INTERVAL)
    self.timer_id = AutobotTimer:addTimer(self.func, interval)
    --INFO("[Autobot|UnionHelp|%d] Wait %d seconds to help other members", self.host.player.pid, interval)
end

function DoHelp:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function DoHelp:_doHelp()
    self.host.player.union_help_manager:doHelp()
    self:translate("WaitHelp")
end

function ChoreUnionHelp:_start(has_union)
    local runner = StateMachine:createInstance(self)
    runner:addState("NoUnion", NoUnion, not has_union)
    runner:addState("WaitHelp", WaitHelp, has_union)
    runner:addState("DoHelp", DoHelp)
    self.runner = runner

    runner:start()
end

function ChoreUnionHelp:_stop()
    self.runner:stop()
    self.runner = nil
end

return makeChoreClass("UnionHelp", ChoreUnionHelp)

