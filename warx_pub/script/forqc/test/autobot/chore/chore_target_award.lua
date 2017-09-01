local TargetAward = {}

local CLAIM_INTERVAL = config.Autobot.ClaimTargetAwardInterval or 5

function TargetAward:init(player)
    self.player = player
    self.eventClaimableAwardUpdated = newEventHandler()
    self.eventTargetAwardUpdated = newEventHandler()
    self:_initTaskData()
    player.eventTaskInfoUpdated:add(newFunctor(self, self._onTaskInfoUpdated))
    player.eventTargetAwardIndexUpdated:add(newFunctor(self, self._onTargetAwardIndex))

    self:_start()
end

function TargetAward:uninit()
    self:_stop()

    self.player.eventTaskInfoUpdated:del(newFunctor(self, self._onTaskInfoUpdated))
    self.player.eventTargetAwardIndexUpdated:del(newFunctor(self, self._onTargetAwardIndex))
end

function TargetAward:_initTaskData()
    local player = self.player

    local watching_tasks = {}
    local claimable_group = {}
    for index, task_list in pairs(TASK_TARGET_ID) do
        if 1 ~= player.task_target_all_award_index[index] then
            local watching_list = {}
            for _, task_id in pairs(task_list) do
                if player:isTaskAccepted(task_id) then
                    table.insert(watching_list, task_id)
                end
            end
            if #watching_list > 0 then
                watching_tasks[index] = watching_list
            else
                claimable_group[index] = true
            end
        end
    end
    self.watching_tasks = watching_tasks
    self.claimable_group = claimable_group
end

function TargetAward:_onTaskInfoUpdated(task_data)
    if task_data.task_type ~= TASK_TYPE.TASK_TYPE_TARGET then
        return
    end
    if task_data.task_status ~= TASK_STATUS.TASK_STATUS_CAN_FINISH then
        return
    end
    local task_id = task_data.task_id
    for index, watching_list in pairs(self.watching_tasks) do
        for k, v in pairs(watching_list) do
            if v == task_id then
                table.remove(watching_list, k)
                break
            end
        end
        if 0 == #watching_list then
            self.claimable_group[index] = true
            self.watching_tasks[index] = nil
            self.eventClaimableAwardUpdated(index)
        end
    end
end

function TargetAward:_onTargetAwardIndex(player)
    local indexes = {}
    for k, v in pairs(player.task_target_all_award_index) do
        if 1 == v then
            if self.claimable_group[k] then
                self.claimable_group[k] = nil
                table.insert(indexes, k)
            end
        end
    end
    self.eventTargetAwardUpdated(indexes)
end

function TargetAward:_claimAward()
    local index = next(self.claimable_group)
    if nil == index then
        return
    end
    INFO("[Autobot|TargetAward|%d] Try to claim target award %d", self.player.pid, index)
    Rpc:get_target_all_award(self.player, index)
    return index
end

local Watching = makeState({})
function Watching:onEnter()
    self.host.eventClaimableAwardUpdated:add(newFunctor(self, self._onClaimableAwardUpdated))
end

function Watching:onExit()
    self.host.eventClaimableAwardUpdated:del(newFunctor(self, self._onClaimableAwardUpdated))
end

function Watching:_onClaimableAwardUpdated(index)
    if next(self.host.claimable_group) then
        self:translate("Ready")
        return
    end
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
    local index = self.host:_claimAward()
    if nil == index then
        INFO("[Autobot|TargetAward|%d] All target award has been claimed", self.host.player.pid)
        self:translate("Watching")
        return
    end
    self.host.eventTargetAwardUpdated:add(self.claimed_func)
end

function Claim:onExit()
    self.host.eventTargetAwardUpdated:del(self.claimed_func)
end

function Claim:_onClaimed()
    INFO("[Autobot|TargetAward|%d] Target award is claimed", self.host.player.pid)
    self:translate("Ready")
end

function TargetAward:_start()
    local claimable = (nil ~= next(self.claimable_group))
    local runner = StateMachine:createInstance(self)
    runner:addState("Watching", Watching, not claimable)
    runner:addState("Ready", Ready, claimable)
    runner:addState("Claim", Claim)

    self.runner = runner
    runner:start()
end

function TargetAward:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("TargetAward", TargetAward)

