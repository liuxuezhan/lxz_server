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
end

function Entity:start()
    self.bot:start()
end

function Entity:stop()
    self.player = nil
    self.bot:stop()
end

-- Player 相关方法
local function _addEventHandler(player, handler_name)
    if not player[handler_name] then
        player[handler_name] = newEventHandler()
    end
end

local function _initEventHandler(self)
    local player = self.player
    _addEventHandler(player, "eventGeniusUpdated")
    _addEventHandler(player, "eventTechUpdated")
    _addEventHandler(player, "eventBufUpdated")
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
    -- union
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
end

function Entity:uninitPlayer()
    player.eventRpcError:del(newFunctor(self, self._onRpcError))
    AutobotTimer:delPeriodicTimer(self.sinew_update_timer)
    self:_unregisterHandler()
    self:_uninitManager()
end

function Entity:_initManager()
    local player = self.player

    player.labor_manager = LaborManager.create(self)
    player.build_manager = BuildManager.create(self)
    player.recruit_manager = RecruitManager.create(self)
    player.tech_manager = TechManager.create(self)
    player.troop_manager = TroopManager.create(self)

    player.task_manager = TaskManager.create(self)

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
end

function Entity:_uninitManager()
    local player = self.player

    player.task_manager:uninit()
    player.troop_manager:uninit()
    player.tech_manager:uninit()
    player.recruit_manager:uninit()
    player.build_manager:uninit()
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
    self._etys = {}
end

function Entity:addEye(x, y)
    Rpc:addEye(self.player, x, y)
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
                if item[3] < v[3] then
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

function Entity:fallInTroop()
    local armys = {}
    local count = self:get_val("CountSoldier")
    for id, num in pairs(self.player._arm) do
        if num < count then
            armys[id] = num
            count = count - num
        else
            armys[id] = count
            count = 0
            break
        end
    end
    local heroes = {}

    return {live_soldier = armys}
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

return Entity

