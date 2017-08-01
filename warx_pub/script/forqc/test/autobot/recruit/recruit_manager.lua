local RecruitManager = {}
local ARMY_BUILD_COUNT = 4

RecruitManager.__index = RecruitManager

function RecruitManager.create(...)
    local obj = setmetatable({}, RecruitManager)
    obj:init(...)
    return obj
end

function RecruitManager:init(player)
    self.player = player
    self.eventJobAccepted = newEventHandler()
    self.eventPriorityChanged = newEventHandler()
    self.player.wanted_building.eventNewBuilding:add(newFunctor(self , self._onNewBuilding))
    self.player.wanted_building.eventBuildingCompleted:add(newFunctor(self , self._onBuildingCompleted))
    self.recruit_priority = {
        [BUILD_ARMY_MODE.BARRACKS] = 0,
        [BUILD_ARMY_MODE.STABLES] = 0,
        [BUILD_ARMY_MODE.RANGE] = 0,
        [BUILD_ARMY_MODE.FACTORY] = 0,
    }
    self.building_priority = {
        [BUILD_ARMY_MODE.BARRACKS] = 0,
        [BUILD_ARMY_MODE.STABLES] = 0,
        [BUILD_ARMY_MODE.RANGE] = 0,
        [BUILD_ARMY_MODE.FACTORY] = 0,
    }
    self.recruit_jobs = {
        [BUILD_ARMY_MODE.BARRACKS] = {},
        [BUILD_ARMY_MODE.STABLES] = {},
        [BUILD_ARMY_MODE.RANGE] = {},
        [BUILD_ARMY_MODE.FACTORY] = {},
    }
end

function RecruitManager:uninit()
    self.player.wanted_building.eventNewBuilding:del(newFunctor(self , self._onNewBuilding))
    self.player.wanted_building.eventBuildingCompleted:del(newFunctor(self , self._onBuildingCompleted))
    self.eventJobAccepted = nil
    self.eventPriorityChanged = nil
end

function RecruitManager:setRecruitPriority(mode, priority)
    assert(mode > 0 and mode <= ARMY_BUILD_COUNT, "Wrong mode in RecruitManager:setRecruitPriority")
    self.recruit_priority[mode] = priority or 0
    self.eventPriorityChanged(self, mode, "recruit")
end

function RecruitManager:setBuildingPriority(mode, priority)
    assert(mode > 0 and mode <= ARMY_BUILD_COUNT, "Wrong mode in RecruitManager:setBuildingPriority")
    self.building_priority[mode] = priority or 0
    self.eventPriorityChanged(self, mode, "building")
end

function RecruitManager:getRecruitPermit(mode)
    assert(mode > 0 and mode <= ARMY_BUILD_COUNT, "Wrong mode in RecruitManager:getRecruitPermit")
    return self.recruit_priority[mode] > self.building_priority[mode]
end

function RecruitManager:addRecruitJob(mode, level, num, priority, is_accelerate)
    assert(mode > 0 and mode <= ARMY_BUILD_COUNT, "Wrong mode in RecruitManager:addRecruitRequest")
    if priority > self.recruit_priority[mode] then
        self:setRecruitPriority(mode, priority)
    end
    level = level or -1 -- -1 means the highest level
    is_accelerate = is_accelerate and true or false
    local found
    for k, v in ipairs(self.recruit_jobs[mode]) do
        if v.level == level and v.accelerate == is_accelerate then
            if v.num < num then
                v.num = num
            end
            if v.priority < priority then
                v.priority = priority
            end
            found = true
        end
    end
    if not found then
        local request = {mode = mode, level = level, num = num, priority=priority, accelerate = is_accelerate}
        table.insert(self.recruit_jobs[mode], request)
    end
    self:_resortJobs(mode)
    self.eventJobAccepted(self, mode)
end

function RecruitManager:getRecruitJob(mode)
    assert(mode > 0 and mode <= ARMY_BUILD_COUNT, "Wrong mode in RecruitManager:getRecruitJob")
    local jobs = self.recruit_jobs[mode]
    if #jobs <= 0 then
        return
    end
    local job = jobs[1]
    table.remove(jobs, 1)
    self:_updatePriority(mode, false)

    return job
end

function RecruitManager:hasRecruitJob(mode)
    assert(mode > 0 and mode <= ARMY_BUILD_COUNT, "Wrong mode in RecruitManager:hasRecruitJob")
    return #self.recruit_jobs[mode] > 0
end

function RecruitManager:_resortJobs(mode)
    table.sort(self.recruit_jobs[mode], function(a, b) return a.priority >= b.priority end)
end

function RecruitManager:_updatePriority(mode, resort)
    if resort then
        self:_resortJobs(mode)
    end
    local priority = 0
    if #self.recruit_jobs[mode] > 0 then
        priority = self.recruit_jobs[mode][1].priority
    end
    self:setRecruitPriority(mode, priority)
end

function RecruitManager:_updateBuildingPriority(propid)
    local prop = resmng.prop_build[propid]
    if nil == prop or BUILD_CLASS.ARMY ~= prop.Class then
        return
    end
    self:setBuildingPriority(prop.Mode, self.player.wanted_building:getMaxPriority(propid))
end

function RecruitManager:_onNewBuilding(_, propid)
    self:_updateBuildingPriority(propid)
end

function RecruitManager:_onBuildingCompleted(_, propid)
    self:_updateBuildingPriority(propid)
end

return RecruitManager

