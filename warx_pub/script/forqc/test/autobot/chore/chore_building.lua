local Building = {}

local PRIORITY = 500

function Building:init(player)
    self.player = player

    self.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
    local castle, prop = get_build(player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.CASTLE)
    self.castle_lv = prop.Lv
end

function Building:uninit()
    self.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
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
    self:_initiateRequest()
end

-- 1001 农田
-- 1002 伐木场
-- 1003 铁矿
-- 1004 能量矿
-- 18   训练营
-- 19   医院

local building_list = {
    [4] = {{1001, 5, 4}, {1002, 5, 4}, {18, 2, 4}, {19, 2, 4}},
    [5] = {{1001, 5, 5}, {1002, 5, 5}},
    [6] = {{1001, 8, 6}, {1002, 8, 6}},
    [7] = {{1001, 8, 7}, {1002, 8, 7}, {18, 3, 6}, {19, 2, 6}},
}

function Building:_initiateRequest()
    local list = building_list[self.castle_lv]
    if nil == list then
        return
    end
    for k, v in pairs(list) do
        local propid = v[1] * 1000 + v[3]
        INFO("[Autobot|ChoreBuilding|%d] Initiate building quest %d|%d", self.player.pid, propid, v[2])
        self.player.build_manager:addBuilding(propid, PRIORITY, v[2])
    end
end

return makeChoreClass("Building", Building)

