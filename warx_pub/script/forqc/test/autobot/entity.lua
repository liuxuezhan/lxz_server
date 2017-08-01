local Entity = {}

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
    _addEventHandler(player, "eventTaskInfoUpdated")
    _addEventHandler(player, "eventTroopDeleted")
    _addEventHandler(player, "eventTroopUpdated")
end

function Entity:initPlayer(player)
    self.player = player

    self:_updateEffect()
    _initEventHandler(self)

    self:_initManager()
    self:_registerHandler()
end

function Entity:start()
    self.bot:start()
end

function Entity:stop()
    self.player = nil
    self.bot:stop()
end

-- Player 相关方法
function Entity:_initManager()
    local player = self.player

    local wanted_building = WantedBuilding.create(self)
    wanted_building:init()
    player.wanted_building = wanted_building
    player.recruit_manager = RecruitManager.create(self)
    player.tech_manager = TechManager.create(self)
    player.troop_manager = TroopManager.create(self)

    player.task_manager = TaskManager.create(self)
end

function Entity:_registerHandler()
    self.eventGeniusUpdated:add(newFunctor(self, Entity._onGeniusUpdated))
    self.eventTechUpdated:add(newFunctor(self, Entity._onTechUpdated))
    self.eventBufUpdated:add(newFunctor(self, Entity._onBufUpdated))
    self.eventBuildUpdated:add(newFunctor(self, Entity._onBuildUpdated))
    self.eventNewBuild:add(newFunctor(self, Entity._onBuildUpdated))
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

return Entity

