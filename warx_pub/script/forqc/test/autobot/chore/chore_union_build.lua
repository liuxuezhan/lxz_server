local ChoreUnionBuild = {}

local REST_TIME = config.Autobot.UnionBuildRestTime or 10
local CASTLE_LV = config.Autobot.UnionBuildCastleLv or 6
local CASTLE_ZONE = config.Autobot.UnionBuildCastleZone or 2
local SEARCH_INTERVAL = 3

local UNION_BUILD_NAME = {"UnionCastle", "UnionWarehouse", "UnionRes", "WTF"}
local UNION_BUILD_PROPID = {
    resmng.UNION_BUILD_CASTLE_EAST_1,
    resmng.UNION_BUILD_RESTORE_1,
    resmng.UNION_BUILD_FARM_1,
    resmng.UNION_BUILD_MARCKET_1,
}

function ChoreUnionBuild:init(player)
    self.player = player
    self.player.eventUnionChanged:add(newFunctor(self, self._onUnionChanged))

    if player.union then
        self:_start()
    end
end

function ChoreUnionBuild:uninit()
    self:_stop()
    self.player.eventUnionChanged:del(newFunctor(self, self._onUnionChanged))
end

function ChoreUnionBuild:_onUnionChanged(player, uid, union)
    if 0 == uid then
        self:_stop()
    else
        self:_start()
    end
end

local Idle = makeState({})
function Idle:onEnter()
    self.timer_id = AutobotTimer:addTimer(function() self:translate("CheckCondition") end, REST_TIME)
end

function Idle:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local CheckCondition = makeState({})
function CheckCondition:onEnter()
    if self.host.player:get_castle_lv() >= CASTLE_LV then
        self:_dispatch()
        return
    end
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
end

function CheckCondition:onExit()
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

function CheckCondition:_onBuildUpdated(player, build)
    local prop = resmng.prop_build[build.propid]
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.CASTLE ~= prop.Mode then
        return
    end
    if prop.Lv >= CASTLE_LV then
        self:_dispatch()
    end
end

function CheckCondition:_dispatch()
    if not self.host.player.union then
        return
    end
    local union = self.host.player.union
    for k, v in pairs(union.build) do
        if v.state == BUILD_STATE.CREATE then
            INFO("[Autobot|ChoreUnionBuild|%d] Union building %d is under-construct, assemble team directly.", self.host.player.pid, v.idx)
            self:translate("Migrate", v.idx, v)
            return
        end
    end

    if resmng.UNION_RANK_5 == self.host.player:get_union_rank() then
        self:translate("WaitMigrate")
    else
        self:translate("NoBuilding")
    end
end

-- 军团长专用状态
local WaitMigrate = makeState({})
function WaitMigrate:onEnter()
    local zone_lv = self:_getZoneLv()
    if zone_lv >= CASTLE_ZONE then
        self:translate("LackOfMember")
        return
    end
    INFO("[Autobot|ChoreUnionBuild|%d] Union leader wait to migrate castle to zone %d", self.host.player.pid, CASTLE_ZONE)
    self.host.player:addRpcErrorHandler("migrate", newFunctor(self, self._onError))
end

function WaitMigrate:onExit()
    self.host.player:delRpcErrorHandler("migrate", newFunctor(self, self._onError))
end

function WaitMigrate:_onError(code, reason)
    if code ~= resmng.E_OK then
        return
    end
    local zone_lv = self:_getZoneLv()
    INFO("[Autobot|ChoreUnionBuild|%d] Union leader has migrated castle to zone %d", self.host.player.pid, zone_lv)
    if zone_lv >= CASTLE_ZONE then
        self:translate("LackOfMember")
        return
    end
end

function WaitMigrate:_getZoneLv()
    local zone_x = math.floor(self.host.player.x / 16)
    local zone_y = math.floor(self.host.player.y / 16)
    return c_get_zone_lv(zone_x, zone_y)
end

local LackOfMember = makeState({})
function LackOfMember:onEnter()
    self.host.player.eventUnionInfoUpdated:add(newFunctor(self, self._onUnionInfoUpdated))

    self:_checkBuild()
end

function LackOfMember:onExit()
    self.host.player.eventUnionInfoUpdated:del(newFunctor(self, self._onUnionInfoUpdated))
    self.membercount = nil
end

function LackOfMember:_checkBuild()
    local union = self.host.player.union
    if self.membercount and self.membercount == union.membercount then
        return
    end
    self.membercount = union.membercount
    -- 建筑数量
    local build_count = {0, 0, 0, 0}
    for k, v in pairs(union.build) do
        if v.state ~= BUILD_STATE.DESTROY and v.state ~= BUILD_STATE.CREATE then
            local prop = resmng.prop_world_unit[v.propid]
            build_count[prop.BuildMode] = build_count[prop.BuildMode] + 1
        end
    end
    -- 目前只修建奇迹
    for mode = 1, 1 do
        --local max_count = get_castle_count(union.membercount)
        local max_count = 1
        INFO("[Autobot|ChoreUnionBuild|%d] Union has %d members and %d|%d union building %d", self.host.player.pid, union.membercount, build_count[mode], max_count, mode)
        if build_count[mode] < max_count then
            self:translate("FindOpenArea", mode)
            return
        end
    end
end

function LackOfMember:_onUnionInfoUpdated()
    self:_checkBuild()
end

local FindOpenArea = makeState({})
function FindOpenArea:onInit()
    self.search_func = newFunctor(self, self._searchOpenArea)
end

function FindOpenArea:onEnter(mode)
    if resmng.UNION_RANK_5 ~= self.host.player:get_union_rank() then
        self:translate("NoBuilding")
        return
    end
    INFO("[Autobot|ChoreUnionBuild|%d] start to find open area for build %d", self.host.player.pid, mode)
    self.mode = mode
    self.zone_x, self.zone_y = self.host.player:getZonePos()
    self.spin_zones = spin_zones(3)
    self:_initBlockInfo()
    self:_moveEye()
end

function FindOpenArea:onExit()
    self.blocks = nil
    self.host.player.eventNewEntity:del(newFunctor(self, self._onNewEntity))
    self.host.player.eventDelEntity:del(newFunctor(self, self._onDelEntity))
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function FindOpenArea:_getZonePos(mode)
    if mode == 1 then
    else
    end
end

function FindOpenArea:_initBlockInfo()
    local player = self.host.player

    self.blocks = {}
    for k, v in pairs(player._etys) do
        local prop = resmng.prop_world_unit[v.propid]
        local origin = v.x + v.y * 1280
        if nil ~= prop.Size then
            for x = 0, prop.Size - 1  do
                for y = 0, prop.Size - 1 do
                    self.blocks[origin + x + y * 1280] = true
                end
            end
        end
    end

    player.eventNewEntity:add(newFunctor(self, self._onNewEntity))
    player.eventDelEntity:add(newFunctor(self, self._onDelEntity))
end

function FindOpenArea:_onNewEntity(player, entity)
    local prop = resmng.prop_world_unit[entity.propid]
    if nil == prop.Size then
        return
    end
    local origin = entity.x + entity.y * 1280
    for x = 0, prop.Size - 1  do
        for y = 0, prop.Size - 1 do
            self.blocks[origin + x + y * 1280] = true
        end
    end
end

function FindOpenArea:_onDelEntity(player, entity)
    local prop = resmng.prop_world_unit[entity.propid]
    if nil == prop.Size then
        return
    end
    local origin = entity.x + entity.y * 1280
    for x = 0, prop.Size - 1  do
        for y = 0, prop.Size - 1 do
            self.blocks[origin + x + y * 1280] = nil
        end
    end
end

function FindOpenArea:_checkPos(sx, sy, size)
    if 0 ~= c_map_test_pos_for_ply(sx, sy, size) then
        return
    end
    local origin = sx + sy * 1280
    for x = 0, size - 1 do
        for y = 0, size - 1 do
            if self.blocks[origin + x + y * 1280] then
                return
            end
        end
    end
    return true
end

function FindOpenArea:_moveEye()
    for x, y in self.spin_zones do
        local zone_x = self.zone_x + x
        local zone_y = self.zone_y + y
        x = zone_x * 16 + 8
        y = zone_y * 16 + 8
        if self.host.player:can_move_to(x, y) then
            INFO("[Autobot|ChoreUnionBuild|%d] Find opening area for union build %d in zone %d|%d|%d|%d", self.host.player.pid, self.mode, zone_x, zone_y, x, y)
            self.host.player:moveEye(x, y)
            self.timer_id = AutobotTimer:addTimer(self.search_func, SEARCH_INTERVAL, zone_x, zone_y)
            return
        end
    end
    INFO("[Autobot|ChoreUnionBuild|%d] not found valid open area", self.host.player.pid)
end

function FindOpenArea:_searchOpenArea(zone_x, zone_y)
    local positions = {}
    local start_x, start_y = zone_x * 16, zone_y * 16
    local end_x, end_y = start_x + 15, start_y + 15
    for x = start_x, end_x do
        for y = start_y, end_y do
            if self:_checkPos(x, y, 4) then
                self:translate("CreateBuild", self.mode, x, y)
                return
            end
        end
    end
    self.timer_id = AutobotTimer:addTimer(self.search_func, SEARCH_INTERVAL, zone_x, zone_y)
end

local CreateBuild = makeState({})
function CreateBuild:onEnter(mode, x, y)
    INFO("[Autobot|ChoreUnionBuild|%d] create union build %d at %d, %d", self.host.player.pid, mode, x, y)
    Rpc:union_build_setup(self.host.player, 0, UNION_BUILD_PROPID[mode], x, y, UNION_BUILD_NAME[mode])
    self.host.player.eventUnionBuildUpdated:add(newFunctor(self, self._onUnionBuildUpdated))
    self.host.player:sync(function() self:_checkResult() end)
end

function CreateBuild:onExit()
    self.host.player.eventUnionBuildUpdated:del(newFunctor(self, self._onUnionBuildUpdated))
    self.build_updated = nil
end

function CreateBuild:_onUnionBuildUpdated(player, build)
    --if build.state ~= BUILD_STATE.CREATE then
    --    return
    --end
    --self.build_idx = build.idx
    self.build_updated = true
end

function CreateBuild:_checkResult()
    if nil == self.build_updated then
        self:translate("Idle")
    else
        self:translate("SelectBuild")
    end
end

-- 军团成员专用状态
local NoBuilding = makeState({})
function NoBuilding:onEnter()
    INFO("[Autobot|ChoreUnionBuild|%d] No union building need to build, wait.", self.host.player.pid)
    self.host.player.eventUnionBuildUpdated:add(newFunctor(self, self._onUnionBuildUpdated))
end

function NoBuilding:onExit()
    self.host.player.eventUnionBuildUpdated:del(newFunctor(self, self._onUnionBuildUpdated))
end

function NoBuilding:_onUnionBuildUpdated(player, build)
    --if build.state ~= BUILD_STATE.CREATE then
    --    return
    --end
    --self:translate("Migrate", build.idx, build)
    self:translate("SelectBuild")
end

local SelectBuild = makeState({})
function SelectBuild:onEnter()
    Rpc:union_load(self.host.player, "build")
    self.host.player.eventUnionLoaded:add(newFunctor(self, self._onUnionLoaded))
end

function SelectBuild:onExit()
    self.host.player.eventUnionLoaded:del(newFunctor(self, self._onUnionLoaded))
end

function SelectBuild:_onUnionLoaded(player, what)
    if "build" ~= what then
        return
    end

    local union = self.host.player.union
    for k, v in pairs(union.build) do
        if v.state == BUILD_STATE.CREATE then
            INFO("[Autobot|ChoreUnionBuild|%d] Found under-construct building %d.", self.host.player.pid, v.idx)
            self:translate("Migrate", v.idx, v)
            return
        end
    end

    if resmng.UNION_RANK_5 == self.host.player:get_union_rank() then
        self:translate("WaitMigrate")
    else
        self:translate("NoBuilding")
    end
end

local Migrate = makeState({})
function Migrate:onEnter(build_idx, build)
    local distance = calc_line_length(self.host.player.x, self.host.player.y, build.x, build.y)
    if distance < 40 then
        self:translate("AssembleTeam", build_idx)
    else
        local function _onMigrate(labor)
            INFO("[Autobot|ChoreUnionBuild|%d] Migrate job done", self.host.player.pid)
            self:translate("AssembleTeam", build_idx)
        end
        self.host.player.labor_manager:createLabor("MigrateToPos", _onMigrate, self.host.player, build.x, build.y, 30)
    end
end

local AssembleTeam = makeState({})
function AssembleTeam:onEnter(build_idx)
    self.build_idx = build_idx

    local troop_count = self.host.player:get_val("CountTroop")
    INFO("[Autobot|ChoreUnionBuild|%d] Ready to assemble team to build union build with %d troops", self.host.player.pid, troop_count)
    if troop_count <= 1 then
        self:_watchingTroopCount()
    else
        self:_initialRequest()
    end
end

function AssembleTeam:onExit()
    self.host.player.eventEffectUpdated:del(newFunctor(self, self._onEffectUpdated))
end

function AssembleTeam:_watchingTroopCount()
    self.host.player.eventEffectUpdated:add(newFunctor(self, self._onEffectUpdated))
end

function AssembleTeam:_onEffectUpdated()
    local troop_count = self.host.player:get_val("CountTroop")
    if troop_count <= 1 then
        return
    end
    self.host.player.eventEffectUpdated:del(newFunctor(self, self._onEffectUpdated))
    self:_initialRequest()
end

function AssembleTeam:_initialRequest()
    INFO("[Autobot|ChoreUnionBuild|%d] request union build quest for build %d", self.host.player.pid, self.build_idx)
    local action = {}
    action.name = "UnionBuild"
    action.params = {self.build_idx}
    self.host.player.troop_manager:requestTroop(action, 1000, newFunctor(self, self._onUnionBuildFinished))
end

function AssembleTeam:_onUnionBuildFinished()
    INFO("[Autobot|ChoreUnionBuild|%d] build %d has been created", self.host.player.pid, self.build_idx)
    self:translate("Idle")
end

function ChoreUnionBuild:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("Idle", Idle, true)
    runner:addState("CheckCondition", CheckCondition)
    runner:addState("LackOfMember", LackOfMember)
    runner:addState("WaitMigrate", WaitMigrate)
    runner:addState("FindOpenArea", FindOpenArea)
    runner:addState("CreateBuild", CreateBuild)
    runner:addState("NoBuilding", NoBuilding)
    runner:addState("SelectBuild", SelectBuild)
    runner:addState("Migrate", Migrate)
    runner:addState("AssembleTeam", AssembleTeam)

    self.runner = runner
    runner:start()
end

function ChoreUnionBuild:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("UnionBuild", ChoreUnionBuild)

