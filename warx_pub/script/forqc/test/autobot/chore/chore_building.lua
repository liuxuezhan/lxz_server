local Building = {}

local PRIORITY = 500

function Building:init(player)
    self.player = player

    self.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
    self.player.eventFieldUpdated:add(newFunctor(self, self._onFieldUpdated))
    local castle, prop = get_build(player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.CASTLE)
    self.castle_lv = prop.Lv
    self.timer_id = AutobotTimer:addTimer(function() self:_constructBuild() end, 5)
end

function Building:uninit()
    self.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    self.player.eventFieldUpdated:del(newFunctor(self, self._onFieldUpdated))
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function Building:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.CASTLE ~= prop.Mode then
        return
    end
    if prop.Lv == self.castle_lv then
        return
    end
    self.castle_lv = prop.Lv

    local field_prop = resmng.prop_open_field[player.field + 1]
    if nil == field_prop or field_prop.Cond[1][2] > self.castle_lv then
        self:_upgradeBuild()
    else
        Rpc:open_field(player, player.field + 1)
    end
end

function Building:_onFieldUpdated(player, field)
    self:_constructBuild()
end


-- 1001 农田    Lv1 Castle
-- 1002 伐木场  Lv1 Castle
-- 1003 铁矿    Lv10 Castle
-- 1004 能量矿  Lv15 Castle
-- 18   训练营  Lv3 Castle
-- 19   医院    Lv4 Castle

local building_list = {
    [2] = {{1001, 4}, {1002, 4}},
    [3] = {{1001, 6}, {1002, 6}, {18, 1}, {19, 1}},
    [4] = {{1001, 6}, {1002, 6}, {18, 4}, {19, 4}},
    [5] = {{1001, 6}, {1002, 6}, {1003, 5}, {18, 4}, {19, 4}},
    [6] = {{1001, 8}, {1002, 8}, {1003, 6}, {18, 4}, {19, 4}},
    [7] = {{1001, 8}, {1002, 8}, {1003, 6}, {1004, 5}, {18, 4}, {19, 4}},
}

function Building:_constructBuild()
    local list = building_list[self.player.field]
    if nil == list then
        return
    end
    for k, v in pairs(list) do
        local propid = v[1] * 1000 + self.castle_lv
        INFO("[Autobot|ChoreBuilding|%d] Construct build %d|%d", self.player.pid, propid, v[2])
        self.player.build_manager:addBuilding(propid, PRIORITY, v[2])
    end
end

function Building:_upgradeBuild()
    local buildings = {
        [1001] = 0,
        [1002] = 0,
        [1003] = 0,
        [1004] = 0,
        [18] = 0,
        [19] = 0,
    }
    for _, build in pairs(self.player._build) do
        local prop = resmng.prop_build[build.propid]
        if buildings[prop.Specific] then
            buildings[prop.Specific] = buildings[prop.Specific] + 1
        end
    end
    for k, v in pairs(buildings) do
        if v > 0 then
            local propid = k * 1000 + self.castle_lv
            INFO("[Autobot|ChoreBuilding|%d] Upgrade building %d|%d", self.player.pid, propid, v)
            self.player.build_manager:addBuilding(propid, PRIORITY, v)
        end
    end
end

return makeChoreClass("Building", Building)

