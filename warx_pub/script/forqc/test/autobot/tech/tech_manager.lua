local TechManager = {}

TechManager.__index = TechManager

function TechManager.create(...)
    local obj = setmetatable({}, TechManager)
    obj:init(...)
    return obj
end

function TechManager:init(player)
    self.player = player
    self.study_jobs = {}
    self.eventJobAccepted = newEventHandler()
    self.eventPriorityChanged = newEventHandler()
    self.tech_priority = 0
    self.building_priority = 0
    self.player.wanted_building.eventNewBuilding:add(newFunctor(self , self._onNewBuilding))
    self.player.wanted_building.eventBuildingCompleted:add(newFunctor(self , self._onBuildingCompleted))

    self.learned_tech = {}
    for k, v in pairs(player.tech) do
        local prop = resmng.prop_tech[v]
        local tech_type_id = prop.Class * 1000 + prop.Mode
        self.learned_tech[tech_type_id] = prop.Lv
    end
    self.eventTechUpdated = newEventHandler()
    player.eventTechUpdated:add(newFunctor(self, TechManager._onTechUpdated))
end

function TechManager:uninit()
    player.eventTechUpdated:del(newFunctor(self, TechManager._onTechUpdated))
    self.player.wanted_building.eventNewBuilding:del(newFunctor(self , self._onNewBuilding))
    self.player.wanted_building.eventBuildingCompleted:del(newFunctor(self , self._onBuildingCompleted))
    self.eventJobAccepted = nil
    self.eventPriorityChanged = nil
end

function TechManager:setTechPriority(priority)
    self.tech_priority = priority or 0
    self.eventPriorityChanged(self, "tech")
end

function TechManager:setBuildingPriority(priority)
    self.building_priority = priority or 0
    self.eventPriorityChanged(self, "building")
end

function TechManager:canStudyTech()
    return self.tech_priority > self.building_priority
end

function TechManager:addStudyJob(tech_id, priority, functor)
    local job = {
        tech_id = tech_id,
        priority = priority,
        functor = functor,
    }
    if self.tech_priority < priority then
        self:setTechPriority(priority)
    end
    table.insert(self.study_jobs, job)
    self:_resortJobs()
    self.eventJobAccepted(self, tech_id)
end

function TechManager:getStudyJob()
    for k, v in ipairs(self.study_jobs) do
        local prop = resmng.prop_tech[v.tech_id]
        if Autobot.condCheck(self.player, prop.Cond) then
            table.remove(self.study_jobs, k)
            self:_updatePriority(false)
            return v
        else
            -- TODO: 可以在这里检查前置条件并发起升级请求
        end
    end
end

function TechManager:hasStudyJob()
    return #self.study_jobs > 0
end

function TechManager:_resortJobs()
    table.sort(self.study_jobs, function(a, b)
        return a.priority > b.priority
    end)
end

function TechManager:_updatePriority(resort)
    if resort then
        self:_resortJobs()
    end
    local priority = 0
    if #self.study_jobs > 0 then
        priority = self.study_jobs[1].priority
    end
    self:setTechPriority(priority)
end

function TechManager:_updateBuildingPriority(propid)
    local prop = resmng.prop_build[propid]
    if nil == prop or
        BUILD_CLASS.FUNCTION ~= prop.Class or
        BUILD_FUNCTION_MODE.ACADEMY ~= prop.Mode then
        return
    end
    self:setBuildingPriority(self.player.wanted_building:getMaxPriority(propid))
end

function TechManager:_onNewBuilding(_, propid)
    self:_updateBuildingPriority(propid)
end

function TechManager:_onBuildingCompleted(_, propid)
    self:_updateBuildingPriority(propid)
end

function TechManager:_onTechUpdated(player, techs)
    for k, v in pairs(player.tech) do
        local prop = resmng.prop_tech[v]
        local tech_type_id = prop.Class * 1000 + prop.Mode

        if nil == self.learned_tech[tech_type_id] then
            self.learned_tech[tech_type_id] = prop.Lv
            self.eventTechUpdated(player, v, true)
        else
            -- 已学会该科技
            if self.learned_tech[tech_type_id] < prop.Lv then
                self.learned_tech[tech_type_id] = prop.Lv
                self.eventTechUpdated(player, v, false)
            end
        end

    end
end

function TechManager:getLearnedTechLevel(tech_type_id)
    return self.learned_tech[tech_type_id]
end

function TechManager:condCheck(propid)
    local prop = resmng.prop_tech[propid]
    if nil == prop then
        return
    end
    return Autobot.condCheck(self.player, prop.Cond)
end

return TechManager

