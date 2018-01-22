local TroopManager = {}

local ActionGroup = {}
ActionGroup.Battle = {
    [TroopAction.SiegePlayer] = true,
    [TroopAction.JoinMass] = true,
    [TroopAction.HoldDefense] = true,
    [TroopAction.Mass] = true,
    [TroopAction.SiegeMonster] = true,
    [TroopAction.Monster] = true,
    [TroopAction.Spy] = true,
    [TroopAction.SiegeCamp] = true,
    [TroopAction.SupportArm] = true,
    [TroopAction.Camp] = true,
    [TroopAction.Declare] = true,
    [TroopAction.SiegeNpc] = true,
    [TroopAction.King] = true,
    [TroopAction.SiegeTaskNpc] = true,
    [TroopAction.AtkMC] = true,
    [TroopAction.SiegeUnion] = true,
    [TroopAction.LostTemple] = true,
    [TroopAction.Refugee] = true,
    [TroopAction.HoldDefenseNPC] = true,
    [TroopAction.HoldDefenseKING] = true,
    [TroopAction.HoldDefenseLT] = true,
    [TroopAction.TaskSpyPly] = true,
    [TroopAction.TaskAtkPly] = true,
    [TroopAction.SiegeDig] = true,
}

function TroopManager:init(player)
    self.player = player
    self.march_jobs = {}
    self.eventNewTroopJob = newEventHandler()
    self.waiting_battle_queue = {}

    local troop_count = self:_getMaxTroopCount()
    self.troop_queue = {}
    for i = 1, troop_count do
        self:_createTroopQueue()
    end

    self.troops = {}
    self.player.eventTroopUpdated:add(newFunctor(self, TroopManager._onTroopUpdated))
    self.player.eventTroopDeleted:add(newFunctor(self, TroopManager._onTroopDeleted))
    self.player.eventEffectUpdated:add(newFunctor(self, TroopManager._onEffectUpdated))
    self.eventBusyTroopStarted = newEventHandler()
    self.eventBusyTroopFinished = newEventHandler()
    self.eventStateChanged = newEventHandler()
    self.eventTroopQueueActivating = newEventHandler()
    self:_initTroops()
end

function TroopManager:uninit()
    self.player.eventTroopUpdated:del(newFunctor(self,TroopManager._onTroopUpdated))
    self.player.eventTroopDeleted:del(newFunctor(self,TroopManager._onTroopDeleted))
    self.player.eventEffectUpdated:del(newFunctor(self, TroopManager._onEffectUpdated))

    for k, v in pairs(self.troop_queue) do
        v:stop()
    end
    self.troop_queue = nil
    self.march_jobs = nil
    self.waiting_battle_queue = nil
end

function TroopManager:requestTroop(action, priority, functor)
    local job = {
        action = action,
        priority = priority,
        functor = functor,
    }
    table.insert(self.march_jobs, job)
    self:_resortJobs()
    self.eventNewTroopJob(self)
end

function TroopManager:getTroopJob()
    if #self.march_jobs > 0 then
        local job = table.remove(self.march_jobs, 1)
        return job
    end
end

function TroopManager:_resortJobs()
    table.sort(self.march_jobs, function(a, b)
        return a.priority > b.priority
    end)
end

function TroopManager:checkTroopAction(troop_queue)
    if ActionGroup["Battle"][troop_queue.troop_action] then
        if nil ~= self.current_battle_queue then
            return false
        end
        self.current_battle_queue = troop_queue
        return true
    end

    return true
end

function TroopManager:addWaitingTroopAction(functor)
    table.insert(self.waiting_battle_queue, functor)
end

function TroopManager:clearTroopAction(troop_queue)
    if ActionGroup["Battle"][troop_queue.troop_action] then
        self.current_battle_queue = nil
        local functor = table.remove(self.waiting_battle_queue, 1)
        if functor then
            functor()
        end
    end
end

function TroopManager:getTroopCount(group)
    local count = 0
    for k, v in pairs(self.troop_queue) do
        local action = v.troop_action
        if nil == group or ActionGroup[group][action] then
            count = count + 1
        end
    end
    return count
end

function TroopManager:checkTroopQueue(queue)
    local troop_count = self:_getMaxTroopCount()
    if #self.troop_queue <= troop_count then
        return true
    end
    for k, v in ipairs(self.troop_queue) do
        if queue == v then
            queue:stop()
            table.remove(self.troop_queue, k)
            return
        end
    end
end

function TroopManager:_getMaxTroopCount()
    return self.player:get_val("CountTroop")
    --return 1
end

function TroopManager:_onEffectUpdated()
    local troop_limit = self:_getMaxTroopCount()
    local count = #self.troop_queue
    if count < troop_limit then
        for i = 1, troop_limit - count do
            self:_createTroopQueue()
        end
    end
end

function TroopManager:_createTroopQueue()
    local queue = Workline:createInstance(self)
    queue:addState("Idle", TroopIdle, true)
    queue:addState("TakeAction", TroopTakeAction)
    queue:addState("Wait", TroopWait)
    queue:addState("Rest", TroopRest)
    queue:addState("Deactive", TroopDeactive)
    table.insert(self.troop_queue, queue)
    queue:start()
end

function TroopManager:_getTroopQueue(index)
    if index <= 0 then
        return
    end
    if index > #self.troop_queue then
        self:_createTroopQueue()
        return _getTroopQueue(index)
    end
    return self.troop_queue[index]
end

function TroopManager:_initTroops()
    local count = 0
    for k, v in pairs(self.player._troop) do
        for pid, army in pairs(v.arms) do
            if pid == self.player.pid then
                count = count + 1
                local data = {}
                data.troop_id = k
                data.troop = v
                self.troops[k] = data

                -- bind to troop queue
                local queue = self:_getTroopQueue(count)
                queue:translate("Wait", v)

                INFO("[Autobot|TroopManager|%d] I have a busy troop %d|%d have %d seconds remaining.",
                    self.player.pid,
                    v._id,
                    v.action,
                    v.tmOver - gTime)
                break
            end
        end
    end
end

function TroopManager:activeTroop()
    self.inactive = nil
    self.eventStateChanged(true)
end

function TroopManager:deactiveTroop()
    self.inactive = true
    self.eventStateChanged(false)
end

function TroopManager:isActive()
    return not self.inactive
end

function TroopManager:activateTroopQueue(queue, time)
    queue.activate_time = time
    self.eventTroopQueueActivating(self, queue)
end

function TroopManager:hasTroopQueueWorking()
    for k, v in pairs(self.troop_queue) do
        if v.activate_time and v.activate_time > 0 then
            return true
        end
    end
end

function TroopManager:_onTroopUpdated(player, troop_id, troop)
    for k, v in pairs(self.troops) do
        if troop_id == v.troop_id then
            -- ignore troop info update, like accelerate
            self.troops[k].troop = troop
            return
        end
    end
    local data = {}
    data.troop_id = troop_id
    data.troop = troop
    self.troops[troop_id] = data
    self.eventBusyTroopStarted(self.player, troop_id, troop)
end

function TroopManager:_onTroopDeleted(player, troop_id)
    for k, v in pairs(self.troops) do
        if troop_id == v.troop_id then
            self.troops[k] = nil
            self.eventBusyTroopFinished(self.player, k, v.troop)
            break
        end
    end
end

function TroopManager:hasBusyTroop()
    return (nil ~= next(self.troops))
end

return makeClass(TroopManager)

