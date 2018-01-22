local ActivityBox = {}

local CLAIM_INTERVAL = config.Autobot.ClaimActivityBoxInterval or 5

function ActivityBox:init(player)
    self.player = player
    self.eventAddClaimableActivity = newEventHandler()
    self.eventDelClaimableActivity = newEventHandler()

    player.eventActivityUpdated:add(newFunctor(self, self._onActivityUpdated))
    player.eventActivityBoxUpdated:add(newFunctor(self, self._onActivityBoxUpdated))
    self:_initData()
    self:_start()
end

function ActivityBox:uninit()
    local player = self.player

    self:_stop()
    player.eventActivityUpdated:del(newFunctor(self, self._onActivityUpdated))
    player.eventActivityBoxUpdated:del(newFunctor(self, self._onActivityBoxUpdated))
end

function ActivityBox:_initData()
    local activity = self.player.activity
    local activity_box = self.player.activity_box
    local claimable_activity = {}
    for k, v in pairs(TASK_ACTIVITY) do
        if activity >= v then
            if not activity_box[k] then
                claimable_activity[k] = true
                INFO("[Autobot|ActivityBox|%d] claimable activity box %d", self.player.pid, k)
            end
        end
    end

    self.claimable_activity = claimable_activity
end

function ActivityBox:_onActivityUpdated(player, activity)
    local activity_box = self.player.activity_box
    local claimable_activity = self.claimable_activity
    local flag
    for k, v in pairs(TASK_ACTIVITY) do
        if activity >= v then
            if not activity_box[k] then
                if not claimable_activity[k] then
                    claimable_activity[k] = true
                    flag = true
                end
            end
        end
    end
    if flag then
        self.eventAddClaimableActivity()
    end
end

function ActivityBox:_onActivityBoxUpdated()
    local claimed_activity = {}
    for k, v in pairs(self.player.activity_box) do
        if self.claimable_activity[k] then
            self.claimable_activity[k] = nil
            table.insert(claimed_activity, k)
        end
    end
    if #claimed_activity > 0 then
        self.eventDelClaimableActivity()
    end
end

function ActivityBox:_claimActivityBox()
    local id = next(self.claimable_activity)
    if nil == id then
        return
    end
    INFO("[Autobot|ActivityBox|%d] Try to claim activity box %d", self.player.pid, id)
    Rpc:get_activity_box(self.player, id)
    return id
end

local Watching = makeState({})
function Watching:onInit()
    self.add_func = function() self:translate("Ready") end
end

function Watching:onEnter()
    self.host.eventAddClaimableActivity:add(self.add_func)
end

function Watching:onExit()
    self.host.eventAddClaimableActivity:del(self.add_func)
end

local Ready = makeState({})
function Ready:onInit()
    self.timer_func = function() self:translate("Claim") end
end

function Ready:onEnter()
    self.timer_id = AutobotTimer:addTimer(self.timer_func, CLAIM_INTERVAL)
end

function Ready:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local Claim = makeState({})
function Claim:onInit()
    self.claimed_func = newFunctor(self, self._onClaimed)
end

function Claim:onEnter()
    local id = self.host:_claimActivityBox()
    if nil == id then
        INFO("[Autobot|ActivityBox|%d] All activity box has been claimed", self.host.player.pid)
        self:translate("Watching")
        return
    end
    self.host.eventDelClaimableActivity:add(self.claimed_func)
end

function Claim:onExit()
    self.host.eventDelClaimableActivity:del(self.claimed_func)
end

function Claim:_onClaimed()
    INFO("[Autobot|ActivityBox|%d] Activity box is claimed", self.host.player.pid)
    self:translate("Ready")
end

function ActivityBox:_start()
    local claimable = (nil ~= next(self.claimable_activity))
    local runner = StateMachine:createInstance(self)
    runner:addState("Watching", Watching, not claimable)
    runner:addState("Ready", Ready, claimable)
    runner:addState("Claim", Claim)

    self.runner = runner
    runner:start()
end

function ActivityBox:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("ActivityBox", ActivityBox)

