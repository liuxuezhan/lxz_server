local TroopManager = {}

function TroopManager:init(player)
    self.player = player
    self.march_jobs = {}
    self.eventNewTroopJob = newEventHandler()

    self.max_troop_index = 2
    self.troops = {}
    self.player.eventTroopUpdated:add(newFunctor(self,TroopManager._onTroopUpdated))
    self.player.eventTroopDeleted:add(newFunctor(self,TroopManager._onTroopDeleted))
    self:_initTroops()
    self.eventBusyTroopStarted = newEventHandler()
    self.eventBusyTroopFinished = newEventHandler()
end

function TroopManager:uninit()
    self.player.eventTroopUpdated:del(newFunctor(self,TroopManager._onTroopUpdated))
    self.player.eventTroopDeleted:del(newFunctor(self,TroopManager._onTroopDeleted))
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
        return a.priority >= b.priority
    end)
end

function TroopManager:getTroopData(index)
    return self.troops[index]
end

function TroopManager:_initTroops()
    for k, v in pairs(self.player._troop) do
        for pid, army in pairs(v.arms) do
            if pid == self.player.pid then
                local data = {}
                data.index = #self.troops + 1
                data.troop_id = k
                datao.troop = v
                self.troops[data.index] = data
                break
            end
        end
    end
    INFO("[Autobot|TroopManager|%d] I have %d busy troop.", self.player.pid, #self.troops)
end

function TroopManager:_getEmptyIndex()
    for index = 1, self.max_troop_index do
       if nil == self.troops[index] then
           return index
       end
    end
end

function TroopManager:_onTroopUpdated(player, troop_id, troop)
    for index, v in pairs(self.troops) do
        if troop_id == v.troop_id then
            -- ignore troop info update, like accelerate
            self.troops[index].troop = troop
            return
        end
    end
    local data = {}
    data.index = self:_getEmptyIndex()
    data.troop_id = troop_id
    data.troop = troop
    self.troops[data.index] = data
    self.eventBusyTroopStarted(self.player, data.index, data.troop)
end

function TroopManager:_onTroopDeleted(player, troop_id)
    for index, v in pairs(self.troops) do
        if troop_id == v.troop_id then
            self.eventBusyTroopFinished(self.player, index, v.troop)
            self.troops[index] = nil
            break
        end
    end
end

return makeClass(TroopManager)

