local Entity = {}

local SINEW_UPDATE_INTERVAL = config.Autobot.SinewUpdateInterval or 300

local ZONE_WIDTH = 16
local ZONE_COUNT_X = 1280 / ZONE_WIDTH
local ZONE_COUNT_Y = 1280 / ZONE_WIDTH

Entity.__index = function(t, k)
    if Entity[k] then
        return Entity[k]
    end
    local player = rawget(t, "player")
    if nil == player then
        return
    end
    return player[k]
end

--Entity.__newindex = function(t, k, v)
--    if nil == t.player then
--        rawset(t, k, v)
--    else
--        t.player[k] = v
--    end
--end

function Entity.createEntity(...)
    local entity = setmetatable({}, Entity)
    entity:init(...)
    return entity
end

function Entity:init(idx)
    self.idx = idx
    self.bot = Bot:createInstance(self)
    self.update_states = {}
    self.eventPlayerLoaded = newEventHandler()
end

function Entity:start(...)
    self.bot:start(...)
end

function Entity:stop()
    self.bot:stop()
    self.player = nil
end

-- Player 相关方法
local function _addEventHandler(player, handler_name)
    if not player[handler_name] then
        player[handler_name] = newEventHandler()
    end
end

local function _initEventHandler(self)
    local player = self.player
    _addEventHandler(player, "eventConnectionClosed")

    _addEventHandler(player, "eventFieldUpdated")
    _addEventHandler(player, "eventRoleLevelUpdated")
    _addEventHandler(player, "eventRoleNameUpdated")
    _addEventHandler(player, "eventGeniusUpdated")
    _addEventHandler(player, "eventTechUpdated")
    _addEventHandler(player, "eventBufUpdated")
    _addEventHandler(player, "eventEffectUpdated")
    _addEventHandler(player, "eventHurtsUpdated")
    _addEventHandler(player, "eventCuresUpdated")
    _addEventHandler(player, "eventBuildUpdated")
    _addEventHandler(player, "eventNewBuild")
    _addEventHandler(player, "eventHeroUpdated")
    _addEventHandler(player, "eventNewHero")
    _addEventHandler(player, "eventTaskInfoUpdated")
    _addEventHandler(player, "eventTroopDeleted")
    _addEventHandler(player, "eventTroopUpdated")
    _addEventHandler(player, "eventFightInfo")
    _addEventHandler(player, "eventSinewUpdated")
    _addEventHandler(player, "eventNewEntity")
    _addEventHandler(player, "eventNewEntities")
    _addEventHandler(player, "eventDelEntity")
    _addEventHandler(player, "eventRpcError")
    _addEventHandler(player, "eventAcheInfoUpdated")
    _addEventHandler(player, "eventAcheUpdated")
    _addEventHandler(player, "eventAcheCountUpdated")
    _addEventHandler(player, "eventDisplayNotify")
    _addEventHandler(player, "eventTargetAwardIndexUpdated")
    _addEventHandler(player, "eventActivityUpdated")
    _addEventHandler(player, "eventActivityBoxUpdated")
    _addEventHandler(player, "eventMailLoad")
    _addEventHandler(player, "eventAllMailLoaded")
    _addEventHandler(player, "eventNewMail")
    _addEventHandler(player, "eventMailFetchResponse")
    _addEventHandler(player, "eventEyeInfo")
    _addEventHandler(player, "eventHeroRoadUpdated")
    _addEventHandler(player, "eventCurHeroRoadUpdated")
    _addEventHandler(player, "eventArmyUpdated")
    _addEventHandler(player, "eventItemUpdated")
    _addEventHandler(player, "eventEquipAdd")
    _addEventHandler(player, "eventEquipRem")
    -- union
    _addEventHandler(player, "eventUnionInfoUpdated")
    _addEventHandler(player, "eventUnionBuildUpdated")
    _addEventHandler(player, "eventUnionIdChanged")
    _addEventHandler(player, "eventUnionChanged")
    _addEventHandler(player, "eventBuildQueueUpdated")
    _addEventHandler(player, "eventGotUnionList")
    _addEventHandler(player, "eventUnionReply")
    _addEventHandler(player, "eventAddUnionMember")
    _addEventHandler(player, "eventUnionHelpGet")
    _addEventHandler(player, "eventUnionHelpAdd")
    _addEventHandler(player, "eventUnionHelpDel")
    _addEventHandler(player, "eventUnionLoaded")
    _addEventHandler(player, "eventUnionTechInfo")
    _addEventHandler(player, "eventUnionDonateInfo")
    _addEventHandler(player, "eventUnionBuildlvDonate")
    -- misc
    _addEventHandler(player, "eventNpcInfoByPropid")

end

function Entity:initPlayer(player)
    self.player = player

    self:_updateEffect()
    _initEventHandler(self)

    self:_initManager()
    self:_registerHandler()

    self.sinew_update_timer = AutobotTimer:addPeriodicTimer(newFunctor(self, Entity._updateSinew), SINEW_UPDATE_INTERVAL)

    self:addEye(player.x, player.y)
    self.rpcErrorHandlers = {}
    player.eventRpcError:add(newFunctor(self, self._onRpcError))
    player.eventConnectionClosed:add(newFunctor(self, self._onConnectionClosed))

    bot_mng.eventPlayerOnline(self)
end

function Entity:uninitPlayer()
    local player = self.player
    INFO("[Autobot|Entity|%d] Uninitializing player", player.pid)

    player.eventConnectionClosed:del(newFunctor(self, self._onConnectionClosed))
    player.eventRpcError:del(newFunctor(self, self._onRpcError))
    AutobotTimer:delPeriodicTimer(self.sinew_update_timer)
    self:_unregisterHandler()
    self:_uninitManager()

    logout(player)
    bot_mng.eventPlayerOffline(self)
    gHavePlayers[player.idx] = nil
end

function Entity:_initManager()
    local player = self.player

    player.labor_manager = LaborManager.create(self)
    player.build_manager = BuildManager.create(self)
    player.recruit_manager = RecruitManager.create(self)
    player.tech_manager = TechManager.create(self)
    player.troop_manager = TroopManager.create(self)

    player.task_manager = TaskManager.create(self)
    player.task_action_manager = TaskActionManager.create(self)

    player.union_help_manager = UnionHelpManager.create(self)
     -- union
     if 0 ~= player.uid then
         self.union = UnionManager:getUnion(player.uid)
         player.eventUnionLoaded:add(newFunctor(self, self._onUnionLoaded))
         if nil ~= self.union then
             Rpc:union_load(player, "build")
             Rpc:union_load(player, "member")
             Rpc:union_load(player, "relation")
             Rpc:union_load(player, "tech")
             Rpc:union_load(player, "mars")
             Rpc:union_load(player, "buf")
             Rpc:union_load(player, "mall")
         end
     end
     player.eventUnionIdChanged:add(newFunctor(self, self._onUnionIdChanged))
end

function Entity:_uninitManager()
    local player = self.player

    player.eventUnionIdChanged:del(newFunctor(self, self._onUnionIdChanged))

    player.union_help_manager:uninit()
    player.task_action_manager:uninit()
    player.task_manager:uninit()
    player.troop_manager:uninit()
    player.tech_manager:uninit()
    player.recruit_manager:uninit()
    player.build_manager:uninit()
    player.labor_manager:uninit()
end

function Entity:_registerHandler()
    self.eventGeniusUpdated:add(newFunctor(self, Entity._onGeniusUpdated))
    self.eventTechUpdated:add(newFunctor(self, Entity._onTechUpdated))
    self.eventBufUpdated:add(newFunctor(self, Entity._onBufUpdated))
    self.eventBuildUpdated:add(newFunctor(self, Entity._onBuildUpdated))
    self.eventNewBuild:add(newFunctor(self, Entity._onBuildUpdated))
end

function Entity:_unregisterHandler()
    self.eventGeniusUpdated:del(newFunctor(self, Entity._onGeniusUpdated))
    self.eventTechUpdated:del(newFunctor(self, Entity._onTechUpdated))
    self.eventBufUpdated:del(newFunctor(self, Entity._onBufUpdated))
    self.eventBuildUpdated:del(newFunctor(self, Entity._onBuildUpdated))
    self.eventNewBuild:del(newFunctor(self, Entity._onBuildUpdated))
end

function Entity:_onConnectionClosed(player)
    INFO("[Autobot|Entity|%d] Player disconnected", self.player.pid)
    bot_mng:delEntity(self)
end

function Entity:_updateSinew()
    local player = self.player
    local last_sinew = player.sinew
    local sinew = recalc_sinew(player.sinew, player.sinew_tm, gTime, 1 + player.sinew_speed * 0.0001)
    if math.floor(last_sinew) ~= math.floor(sinew) then
        player.sinew = sinew
        player.sinew_tm = gTime
        player.eventSinewUpdated(player, player.sinew, last_sinew)
    end
end

function Entity:_updateEffect()
    local ef = {}
    -- base effect
    local props = resmng.prop_effect_type
    for k, v in pairs(props) do
        if v.Default and v.Default ~= 0 then
            ef[k] = v.Default
        end
    end
    -- build
    local builds = self._build
    if builds then
        local props = resmng.prop_build
        for _, v in pairs(builds) do
            local prop = props[ v.propid ]
            if prop then
                for ek, ev in pairs(prop.Effect or {}) do
                    ef[ek] = (ef[ek] or 0) + ev
                end
            end
        end
    end
    -- equip
    local equips = self._equip
    if equips then
        local props = resmng.prop_equip
        for k, v in pairs(equips) do
            if v.pos > 0 then
                local prop = props[ v.propid ]
                if prop then
                    for ek, ev in pairs(prop.Effect or {}) do
                        ef[ ek ] = ( ef[ ek ] or 0 ) + ev
                    end
                end
            end
        end
    end
    -- tech
    local props = resmng.prop_tech
    for _, v in pairs(self.tech or {}) do
        local prop = props[ v ]
        if prop then
            for ek, ev in pairs( prop.Effect ) do
                ef[ ek ] = ( ef[ ek ] or 0 ) + ev
            end
        end
    end
    -- genius
    local props = resmng.prop_genius
    for _, v in pairs(self.genius or {}) do
        local prop = props[ v ]
        if prop and prop.Effect then
            for ek, ev in pairs( prop.Effect ) do
                ef[ ek ] = ( ef[ ek ] or 0 ) + ev
            end
        end
    end
    -- bufs
    local props = resmng.prop_buff
    for k, v in pairs(self.bufs or {}) do
        local bufid = v[1]
        local over = v[3] or 0
        if over >= gTime or over == -1 then
            local prop = props[ bufid ]
            if prop and prop.Value then
                for ek, ev in pairs( prop.Value ) do
                    ef[ ek ] = ( ef[ ek ] or 0 ) + ev
                end
            end
        end
    end
    self._effects = ef
    if self.eventEffectUpdated then
        self.eventEffectUpdated(self)
    end
end

function Entity:sync(functor)
    sync(self.player, functor)
end

function Entity:get_num(what, ...)
    --local ef_u,ef_ue = player:get_union_ef()
    local ef_u, ef_ue = {}, {}
    local ef_s = self._effects
    local ef_gs = {}
    --local ef_gs = kw_mall.gsEf or {} -- globle buff
    if ... == nil then
        return get_num_by(what, ef_s, ef_u, ef_ue, ef_gs)
    else
        return get_num_by(what, ef_s, ef_u, ef_ue, ef_gs, ...)
    end
end

function Entity:get_val(what, ...)
    --local ef_u,ef_ue = player:get_union_ef()
    local ef_u, ef_ue = {}, {}
    local ef_s = self._effects
    local ef_gs = {}
    --local ef_gs = kw_mall.gsEf or {} -- globle buff
    if ... == nil then
        return get_val_by(what, ef_s, ef_u, ef_ue, ef_gs)
    else
        return get_val_by(what, ef_s, ef_u, ef_ue, ef_gs, ...)
    end
end

function Entity:get_castle()
    return self:get_build(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.CASTLE)
end

function Entity:get_castle_lv()
    return math.floor(self.propid % 1000)
end

function Entity:is_in_union()
    return 0 ~= self.player.uid
end

function Entity:can_move_to(x, y)
    if x < 0 or y < 0 then return false end
    if x >= 1280 or y >= 1280 then return false end
    local lv_castle = self:get_castle_lv()
    local lv_pos = c_get_zone_lv(math.floor(x/16), math.floor(y/16))
    return can_enter(lv_castle, lv_pos)
end

function Entity:_onGeniusUpdated()
    self:_updateEffect()
end

function Entity:_onTechUpdated()
    self:_updateEffect()
end

function Entity:_onBufUpdated()
    self:_updateEffect()
end

function Entity:_onBuildUpdated(build)
    self:_updateEffect()
end

function Entity:get_hero(hero_id)
    for k, v in pairs(self.player._hero or {}) do
        if v.propid == hero_id then
            return v
        end
    end
end

function Entity:get_item(item_id)
    for k, v in pairs(self.player._item or {}) do
        if v[2] == item_id then
            return v
        end
    end
end

function Entity:getZonePos()
    return math.floor(self.player.x / ZONE_WIDTH), math.floor(self.player.y / ZONE_WIDTH)
end

function Entity:getEyePos()
    return math.floor((self.eye_x or 0) / ZONE_WIDTH), math.floor((self.eye_y or 0) / ZONE_WIDTH)
end

local adjacent_zone = {
    {-1, -1},
    { 0, -1},
    { 1, -1},
    {-1,  0},
    { 0,  0},
    { 1,  0},
    {-1,  1},
    { 0,  1},
    { 1,  1},
}

local disappear_zone = {
    [-2] = {
        [-2] = {1, 4, 7, 2, 5, 8, 3, 6},
        [-1] = {1, 4, 7, 2, 5, 8, 3},
        [0]  = {1, 4, 7, 2, 5, 8},
        [1]  = {1, 4, 7, 2, 5, 8, 9},
        [2]  = {1, 4, 7, 2, 5, 8, 6, 9},
    },
    [-1] = {
        [-2] = {1, 4, 7, 2, 5, 3, 6},
        [-1] = {1, 4, 7, 2, 3},
        [0]  = {1, 4, 7},
        [1]  = {1, 4, 7, 8, 9},
        [2]  = {1, 4, 7, 5, 8, 6, 9},
    },
    [0] = {
        [-2] = {1, 4, 2, 5, 3, 6},
        [-1] = {1, 2, 3},
        [0]  = {},
        [1]  = {7, 8, 9},
        [2]  = {4, 7, 5, 8, 6, 9},
    },
    [1] = {
        [-2] = {1, 4, 2, 5, 3, 6, 9},
        [-1] = {1, 2, 3, 6, 9},
        [0]  = {3, 6, 9},
        [1]  = {7, 8, 3, 6, 9},
        [2]  = {4, 7, 5, 8, 3, 6, 9},
    },
    [2] = {
        [-2] = {1, 4, 2, 5, 8, 3, 6, 9},
        [-1] = {1, 2, 5, 8, 3, 6, 9},
        [0]  = {2, 5, 8, 3, 6, 9},
        [1]  = {7, 2, 5, 8, 3, 6, 9},
        [2]  = {4, 7, 2, 5, 8, 3, 6, 9},
    },
}

function Entity:_onMovEye(x, y)
    local my_x, my_y = self:getEyePos()
    self.eye_x = x
    self.eye_y = y
    local new_x, new_y = math.floor(x / ZONE_WIDTH), math.floor(y / ZONE_WIDTH)
    local dx = my_x - new_x
    local dy = my_y - new_y
    if disappear_zone[dx] then
        if disappear_zone[dx][dy] then
            local zones = {}
            for k, v in pairs(disappear_zone[dx][dy]) do
                local zone_index = (my_x + adjacent_zone[v][1]) * ZONE_COUNT_X + my_y + adjacent_zone[v][2]
                zones[zone_index] = true
            end
            for k, v in pairs(self.player._etys or {}) do
                local ex = math.floor(v.x / ZONE_WIDTH)
                local ey = math.floor(v.y / ZONE_WIDTH)
                local eindex = ex * ZONE_COUNT_X + ey
                if zones[eindex] then
                    self.player._etys[k] = nil
                else
                end
            end
            return
        end
    end
    -- clear all entities
    self.player._etys = {}
end

function Entity:addEye(x, y)
    Rpc:addEye(self.player, gMapID, x, y)
    self:_onMovEye(x, y)
end

function Entity:moveEye(x, y)
    Rpc:movEye(self.player, gMapID, x, y)
    self:_onMovEye(x, y)
end

function Entity:addRpcErrorHandler(name, functor)
    self.rpcErrorHandlers[name] = self.rpcErrorHandlers[name] or newEventHandler()
    self.rpcErrorHandlers[name]:add(functor)
end

function Entity:delRpcErrorHandler(name, functor)
    if nil == self.rpcErrorHandlers[name] then
        return
    end
    self.rpcErrorHandlers[name]:del(functor)
end

function Entity:_onRpcError(player, rpcf, code, reason)
    local handler = self.rpcErrorHandlers[rpcf.name]
    if nil == handler then
        return
    end
    handler(code, reason)
end

-- union
function Entity:_onUnionIdChanged(player, uid)
    if 0 ~= uid then
        self.union = UnionManager:getUnion(player.uid)
        INFO("[Autobot|Entity|%d] JoinUnion %d", player.pid, uid)
        player.eventUnionLoaded:add(newFunctor(self, self._onUnionLoaded))
        if nil ~= self.union then
            Rpc:union_load(player, "build")
            Rpc:union_load(player, "member")
            Rpc:union_load(player, "relation")
            Rpc:union_load(player, "tech")
            Rpc:union_load(player, "mars")
            Rpc:union_load(player, "buf")
            Rpc:union_load(player, "mall")
        end
    else
        self.union = nil
    end
    player.eventUnionChanged(player, uid, self.union)
end

function Entity:_onUnionLoaded(player, what, union)
    if nil == self.union then
        return
    end
    self.union.onUnionLoaded(player, what, union)
end

function Entity:getDonatableTechs()
    local techs = {}
    local total_lv = self:calcTechLv()
    for k, v in pairs(resmng.prop_union_tech) do
        if 0 == v.Lv then
            local tech = self.player.utech[v.Idx]
            if nil ~= tech then
                local prop = resmng.prop_union_tech[tech.id + 1]
                if nil ~= prop and tech.exp < prop.Exp * prop.Star then
                    table.insert(techs, tech.idx)
                end
            else
                if total_lv >= TechValidCond[v.Class] then
                    table.insert(techs, v.Idx)
                end
            end
        end
    end
    return techs
end

function Entity:calcTechLv()
    local lv = 0
    for k, v in pairs(self.player.utech or {}) do
        local prop = resmng.prop_union_tech[v.id]
        lv = lv + prop.Lv
    end
    return lv
end

function Entity:getTech(tech_idx)
    return self.player.utech[tech_idx]
end

function Entity:getDonatableBuildlvMode()
    for _, mode in pairs(UNION_CONSTRUCT_TYPE) do
        local log = self.player.buildlv.log
        if can_date(log[mode].tm, gTime) then
            local have_item = true
            for k, v in pairs(log[mode].cons) do
                local item = self:get_item(v[2])
                if nil == item or item[3] < v[3] then
                    have_item = false
                    break
                end
            end
            if have_item then
                return mode
            end
        end
    end
end

function Entity:get_build_by_idx(idx)
    return self.player._build[idx]
end

function Entity:get_build(class, mode)
    for _, build in pairs(self.player._build) do
        local prop = resmng.prop_build[build.propid]
        if class == prop.Class and mode == prop.Mode then
            return build, prop
        end
    end
end

function Entity:fallInTroop()
    local count = self:get_val("CountSoldier")
    local avg_count = math.floor(count / 4)
    local rally_count = {avg_count, avg_count, avg_count, avg_count}
    rally_count[1] = rally_count[1] + count - avg_count * 4

    -- 构建部队数据
    local army_group = {}
    for id, num in pairs(self.player._arm) do
        local pos = math.floor((id % 1000000) / 1000)
        army_group[pos] = army_group[pos] or {count = 0, armys = {}, deploy = {}}
        table.insert(army_group[pos].armys, {id, num})
        army_group[pos].count = army_group[pos].count + num
    end

    -- 初始数据调整
    local remain_count = 0
    for pos = 1, 4 do
        local group = army_group[pos]
        if group then
            if group.count < rally_count[pos] then
                remain_count = remain_count + rally_count[pos] - group.count
                rally_count[pos] = group.count
            end
            -- 部队按等级从高到低排序
            table.sort(group.armys, function(a, b) return a[1] > b[1] end)
        else
            remain_count = remain_count + rally_count[pos]
            rally_count[pos] = 0
        end
    end

    -- 部队召集数量调整
    for pos = 1, 4 do
        if remain_count <= 0 then
            break
        end
        if army_group[pos] then
            local army_count = army_group[pos].count
            if army_count >= rally_count[pos] + remain_count then
                rally_count[pos] = rally_count[pos] + remain_count
                remain_count = 0
            elseif army_count > rally_count[pos] then
                remain_count = remain_count - (army_count - rally_count[pos])
                rally_count[pos] = army_count
            end
        end
    end

    -- 部队集结
    local armys = {}
    for pos, group in pairs(army_group) do
        local left_count = rally_count[pos]
        for _, info in ipairs(group.armys) do
            if info[2] < left_count then
                armys[info[1]] = info[2]
                left_count = left_count - info[2]
            else
                armys[info[1]] = left_count
                left_count = 0
                break
            end
        end
    end

    -- heroes
    local hero_group = {}
    for k, v in pairs(self.player._hero or {}) do
        if v.status == HERO_STATUS_TYPE.FREE or v.status == HERO_STATUS_TYPE.BUILDING then
            local prop = resmng.prop_hero_basic[v.propid]
            if prop then
                for _, pos in pairs(prop.Lean or {}) do
                    if army_group[pos] then
                        hero_group[pos] = hero_group[pos] or {}
                        table.insert(hero_group[pos], v)
                    end
                end
            end
        end
    end
    for k, v in pairs(hero_group) do
        table.sort(v, function(a, b) return a.fight_power > b.fight_power end)
    end
    local rallied_hero = {}
    local heroes = {}
    for pos = 1, 4 do
        if army_group[pos] then
            for _, hero in ipairs(hero_group[pos] or {}) do
                if not rallied_hero[hero.idx] then
                    heroes[pos] = hero.idx
                    rallied_hero[hero.idx] = pos
                end
            end
        end
    end

    return {live_soldier = armys, heros = heroes}
end

function Entity:getSoldierCount()
    local count = 0
    -- cure
    for id, num in pairs(self.player.cures) do
        count = count + num
    end
    INFO("[Autobot|Soldier|%d] cure %d", self.player.pid, count)
    -- hurt
    for id, num in pairs(self.player.hurts) do
        count = count + num
    end
    INFO("[Autobot|Soldier|%d] hurt %d", self.player.pid, count)
    -- army
    for id, num in pairs(self.player._arm) do
        count = count + num
    end
    -- in troop
    for id, troop in pairs(self.player._troop) do
        for pid, army in pairs(troop.arms) do
            if pid == self.player.pid then
                for k, v in pairs(army) do
    INFO("[Autobot|Soldier|%d] troop %d", self.player.pid, v)
                    count = count + v
                end
            end
        end
    end

    return count
end

function Entity:isTaskAccepted(task_id)
    for k, v in pairs(self.player._task.cur) do
        if v.task_id == task_id then
            return v.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED
        end
    end
end

function Entity:get_buf(bufid)
    for k, v in pairs(self.bufs or {}) do
        if v[1] == bufid then
            return v
        end
    end
end

function Entity:get_buf_remain(bufid)
    local buf = self:get_buf(bufid)
    if buf then
        return buf[3] - gTime
    end
    return 0
end

function Entity:get_union_rank()
    local member = self.player.union_member
    if not member then
        return resmng.UNION_RANK_0
    end
    return member.rank
end

return Entity

