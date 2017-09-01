local State = {}

State.__index = State

function State:getName()
    return self.name
end

function State:getFSM()
    return self.fsm
end

function State:getHost()
    return self.host
end

function State:update()
    if self.onUpdate then
        self:onUpdate()
    end
end

function State:enter(...)
    local is_debug = self.fsm:isDebug()
    if is_debug then
        WARN("[StateMachine]%sEnter state begin: %s", self.fsm:_dbgPrefix(), self.name)
    end
    if self.onEnter then
        self:onEnter(...)
    end
    if is_debug then
        WARN("[StateMachine]%sEnter state end: %s", self.fsm:_dbgPrefix(), self.name)
    end
    if self.needUpdate and self.fsm.updateState then
        self.fsm.addUpdateState(self.fsm)
    end
end

function State:exit()
    local is_debug = self.fsm:isDebug()
    if is_debug then
        WARN("[StateMachine]%sExit state begin: %s", self.fsm:_dbgPrefix(), self.name)
    end
    if self.onExit then
        self:onExit()
    end
    if is_debug then
        WARN("[StateMachine]%sExit state end: %s", self.fsm:_dbgPrefix(), self.name)
    end
    if self.needUpdate and self.fsm.updateState then
        self.fsm.delUpdateState(self.fsm)
    end
end

function State:translate(name, ...)
    self.fsm:translate(name, ...)
end

-- Finite State Machine
local StateMachine = {}

StateMachine.__index = StateMachine

function StateMachine:getHost()
    return self.host
end

function StateMachine:addState(name, state, default)
    assert(nil ~= name, "state name can't be nil.")
    assert(nil ~= state, "state can't be nil.")
    assert(nil == self.states[state.name], string.format("exist state: %s", name))
    local instance = state:createInstance(self, name)
    self.states[name] = instance
    if instance.onInit then
        instance:onInit()
    end
    if default then
        self.initState = instance.name
    end
end

function StateMachine:delState(name)
    assert(false, "Not implemented")
end

function StateMachine:update()
    local state = self.currentState
    assert(nil ~= state, "state machine didn't start")
    state:update()
end

function StateMachine:start()
    if self.onStart then
        self:onStart()
    end
    assert(nil == self.currentState, "state machine has started")
    assert(nil ~= self.initState, "state machine can't start because the initState is nil")
    local state = self.states[self.initState]
    assert(nil ~= state, "state machine can't start because the initState doesn't exist")
    self.prevState = nil
    self.currentState = state
    self.currentState:enter()
end

function StateMachine:stop()
    local state = self.currentState
    assert(nil ~= state, "state machine didn't start")
    self.currentState = nil
    self.prevState = nil
    state:exit()
    if self.onStop then
        self:onStop(state)
    end
end

function StateMachine:translate(name, ...)
    local state = self.currentState
    assert(nil ~= state, "state machine didn't start")
    local nextState = self.states[name]
    assert(nil ~= nextState, "the next state doesn't exist")
    assert(state ~= nextState, "the next state is same as the current state")
    if self:isDebug() then
        self.__dbg_depth = self.__dbg_depth or 1
        WARN("[StateMachine]%sTranslating state from %s to %s.", self:_dbgPrefix(), state.name, nextState.name)
        self.__dbg_depth = self.__dbg_depth + 1
    end
    self.prevState = state
    self.currentState = nextState
    state:exit()
    nextState:enter(...)
    if self:isDebug() then
        self.__dbg_depth = self.__dbg_depth - 1
        WARN("[StateMachine]%sTranslat state from %s to %s, done.", self:_dbgPrefix(), state.name, nextState.name)
    end
end

function StateMachine:getCurrentState()
    return self.currentState
end

function StateMachine:getPreviousState()
    return self.prevState
end

function StateMachine:isDebug()
    return self.__debug
end

local dbg_prefixes = 
{
    "",
    "    ",
    "        ",
    "            ",
    "                ",
    "                    ",
}

function StateMachine:_dbgPrefix()
    return dbg_prefixes[self.__dbg_depth] or ">>>>"
end

local function createStateMachine(self, host)
    local instance = {states = {}, host=host}
    setmetatable(instance, self)
    if instance.onInit then
        instance:onInit()
    end
    return instance
end

-- 
function makeFSM(module)
    module.createInstance = createStateMachine
    module.__index = module

    return setmetatable(module, StateMachine)
end

local function createState(self, fsm, name)
    local instance = {name = name, fsm=fsm, host=fsm.host}
    setmetatable(instance, self)

    return instance
end

function makeState(module)
    module.createInstance = createState
    module.__index = module

    return setmetatable(module, State)
end

