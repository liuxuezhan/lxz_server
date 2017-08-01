local WantedBuilding = {}

WantedBuilding.__index = WantedBuilding

local _predefined_buildings = {
    --{2001004, 1},
    --{1001003, 3},
}

function WantedBuilding.create(player)
    local obj = {
        player = player,
        buildings = {},
    }
    return setmetatable(obj, WantedBuilding)
end

function WantedBuilding:init()
    self:_initPredefinedBuildings()
    self.eventNewBuilding = newEventHandler()
    self.eventBuildingCompleted = newEventHandler()
end

function WantedBuilding:uninit()
end

-- 添加需要修改/升级的建筑
function WantedBuilding:addBuilding(propid, priority, num, functor)
    --local build, need_upgrade = self:_getBuild(propid)
    --if nil == build or need_upgrade then
        return self:_addBuilding(propid, priority, num, functor)
    --end
end

local function _getConstructBuilding(self, propid)
    propid = propid - propid % 100 + 1
    local prop = resmng.prop_build[propid]
    if Autobot.condCheck(self.player, prop.Cond) then
        INFO("[Autobot|Building|%d]_getConstructBuilding %d cond check ok.", self.player.pid, propid)
        return nil, propid
    else
        local pre_propid = self:_getPrereqBuilding(propid)
        if nil ~= pre_propid then
            INFO("[Autobot|Building|%d]_getConstructBuilding %d cond check not ok, pre %d.", self.player.pid, propid, pre_propid)
            local build = self:_getBuild(pre_propid)
            if nil == build then
                return _getConstructBuilding(self, pre_propid)
            else
                return build, build.propid + 1
            end
        end
    end
end

function WantedBuilding:getNextBuilding()
    local count = #self.buildings
    local index = 1
    while nil ~= self.buildings[index] do
        if self.buildings[index].completed then
            table.remove(self.buildings, index)
        else
            index = index + 1
        end
    end
    for k, v in ipairs(self.buildings) do
        --local has_built
        local prop = resmng.prop_build[v.propid]
        local need_upgrade_build
        local count = 0
        for k, v1 in pairs(self.player._build or {}) do
            local build_prop = resmng.prop_build[v1.propid]
            if build_prop.Class == prop.Class and build_prop.Mode == prop.Mode then
                count = count + 1
                if build_prop.Lv >= prop.Lv then
                else
                    need_upgrade_build = v1
                end
            end
        end
        if nil ~= need_upgrade_build then
            local build_prop = resmng.prop_build[need_upgrade_build.propid + 1]
            if Autobot.condCheck(self.player, build_prop.Cond) then
                return need_upgrade_build, need_upgrade_build.propid + 1
            else
                local pre_propid = self:_getPrereqBuilding(v.propid)
                if nil ~= pre_propid then
                    local build = self:_getBuild(pre_propid)
                    if nil == build then
                        return _getConstructBuilding(self, pre_propid)
                    else
                        return build, build.propid + 1
                    end
                end
            end
        elseif count < v.num then
            return _getConstructBuilding(self, v.propid)
        else
            -- 通知外部修建完成
            if v.functor then
                v.functor(v.propid, v.num)
            end
            -- 设定删除标记
            v.completed = true

            self.eventBuildingCompleted(self, v.propid)
        end
    end
end

local function _getCondBuilding(self, class, mode, lv)
    if class == resmng.CLASS_BUILD then
        local prop = resmng.prop_build[mode]
        if prop then
            local c = prop.Class
            local m = prop.Mode
            local l = prop.Lv
            for _, v in pairs(self.player._build or{}) do
                local build_prop = resmng.prop_build[v.propid]
                if build_prop and build_prop.Class == c and build_prop.Mode == m then
                    if build_prop.Lv < l and v.state == BUILD_STATE.WAIT then
                        local pre_propid = self:_getPrereqBuilding(v.propid + 1)
                        if nil ~= pre_propid then
                            return pre_propid
                        else
                            return v.propid + 1
                        end
                    end
                end
            end
        end
    end
end

local function _getLogicalBuilding(self, operator, ...)
    if "OR" == operator then
        for k, v in pairs({...}) do
            local class, mode, lv = unpack(v)
            if class == resmng.CLASS_BUILD then
                local pre_propid = _getCondBuilding(self, class, mode, lv)
                if nil ~= pre_propid then
                    return pre_propid
                end
            end
        end
    elseif "AND" == operator then
    end
end

function WantedBuilding:_getPrereqBuilding(propid)
    local prop = resmng.prop_build[propid]
    for k, v in pairs(prop.Cond) do
        local class, mode, lv = unpack(v)
        if "OR" == class or "AND" == class then
            local pre_propid = _getLogicalBuilding(self, unpack(v))
            if nil ~= pre_propid then
                return pre_propid
            end
        else
            local pre_propid = _getCondBuilding(self, class, mode, lv)
            if nil ~= pre_propid then
                return pre_propid
            end
        end
    end
end

function WantedBuilding:_getBuild(propid)
    local prop = resmng.prop_build[propid]
    for k, v in pairs(self.player._build or {}) do
        local build build_prop = resmng.prop_build[v.propid]
        if build_prop.Class == prop.Class and
            build_prop.Mode == prop.Mode then
            return v, build_prop.Lv <= prop.Lv
        end
    end
end

function WantedBuilding:_initPredefinedBuildings()
    for k, v in ipairs(_predefined_buildings) do
        self:addBuilding(v[1], 1, v[2])
    end
end

function WantedBuilding:getMaxPriority(propid)
    local prop = resmng.prop_build[propid]
    local max_priority = 0
    for k, v in pairs(self.buildings) do
        if not v.completed then
            local tmp_prop = resmng.prop_build[v.propid]
            if prop.Class == tmp_prop.Class and prop.Mode == tmp_prop.Mode then
                if v.priority > max_priority then
                    max_priority = v.priority
                end
            end
        end
    end
    return max_priority
end

function WantedBuilding:_addBuilding(propid, priority, num, functor)
    local resort = false
    local found = false
    num = num or 1
    --for k, v in pairs(self.buildings) do
    --    if k == propid then
    --        if priority > v.priority then
    --            v.priority = priority
    --            resort = true
    --        end
    --        if num > v.num then
    --            v.num = num
    --        end
    --        found = true
    --    end
    --end
    --if not found then
    --    -- is there pre-building?
    --    for k, v in pairs(self.buildings) do
    --    end
    --end

    --if not found then
        table.insert(self.buildings, {propid = propid, priority = priority, num = num, functor=functor})
        resort = true
    --end
    -- 
    if resort then
        table.sort(self.buildings, function(a, b)
            return a.priority > b.priority
        end)
    end

    self.eventNewBuilding(self, propid)
end

return WantedBuilding

