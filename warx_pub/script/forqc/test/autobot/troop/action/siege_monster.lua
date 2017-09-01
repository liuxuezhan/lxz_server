local SiegeMonster = {}

local SIEGE_RANGE = config.Autobot.SiegeMonsterRange or 2
local MONSTER_COUNT = config.Autobot.SiegeMonsterMinCount or 5
local SEARCH_INTERVAL = config.Autobot.SiegeMonsterSearchInterval or 3

local ZONE_WIDTH = 16

function SiegeMonster:init(player, type, min_level, max_level)
    self.player = player
    self.type = type
    self.targets = {}
    self.min_level = min_level
    self.max_level = max_level or min_level
    if self.min_level > self.max_level then
        self.max_level = min_level
    end

    self:_start()
end

function SiegeMonster:uninit()
    self:_stop()
end

function SiegeMonster:_isTargetEntity(entity)
    if not is_monster(entity) then
        return
    end
    local prop = resmng.prop_world_unit[entity.propid]
    if not prop then
        return
    end
    if prop.Clv < self.min_level or prop.Clv > self.max_level then
        return
    end
    if not self.player:can_move_to(entity.x, entity.y) then
        return
    end
    return 0 == self.type or get_monster_type(prop.Mode) == self.type
end

function SiegeMonster:_addTargetEntity(entity)
    for k, v in pairs(self.targets) do
        if v[1] == entity.eid then
            return
        end
    end
    local diff_x = math.abs(self.player.x - entity.x)
    local diff_y = math.abs(self.player.y - entity.y)
    local distance = diff_x * diff_x + diff_y * diff_y
    table.insert(self.targets, {entity.eid, distance})
    return true
end

function SiegeMonster:_delTargetEntity(entity)
    for k, v in pairs(self.targets) do
        if v[1] == entity.eid then
            table.remove(self.targets, k)
            return
        end
    end
end

function SiegeMonster:_clearTargetEntity()
    self.targets = {}
end

function SiegeMonster:_getTargetCount()
    return #self.targets
end

function SiegeMonster:_pickTarget()
    local distance = math.huge
    local target
    for k, v in ipairs(self.targets) do
        if v[2] < distance then
            target = v[1]
            distance = v[2]
        end
    end
    return target

    --[[
    local count = #self.targets
    if 0 == count then
        return
    end
    local index = math.random(count)
    return self.targets[index]
    --]]
end

local HuntDown = makeState({})
function HuntDown:onEnter()
    self.search_func = self.search_func or newFunctor(self, self._searchEntities)

    self.host:_clearTargetEntity()
    for k, v in pairs(self.host.player._etys) do
        if self.host:_isTargetEntity(v) then
            self.host:_addTargetEntity(v)
        end
    end
    if self.host:_getTargetCount() >= MONSTER_COUNT then
        self:translate("Siege")
    else
        self.spin_zones = spin_zones(SIEGE_RANGE)
        self.zone_x, self.zone_y = self.host.player:getZonePos()
        self:_searchEntities()
        self.host.player.eventNewEntity:add(newFunctor(self, self._onNewEntity))
        self.host.player.eventDelEntity:add(newFunctor(self, self._onDelEntity))
    end
end

function HuntDown:onExit()
    self.host.player.eventNewEntity:del(newFunctor(self, self._onNewEntity))
    self.host.player.eventDelEntity:del(newFunctor(self, self._onDelEntity))
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
    self.search_end = nil
end

function HuntDown:_searchEntities()
    for x, y in self.spin_zones do
        local zone_x = self.zone_x + x
        local zone_y = self.zone_y + y
        x = zone_x * ZONE_WIDTH + math.floor(ZONE_WIDTH / 2)
        y = zone_y * ZONE_WIDTH + math.floor(ZONE_WIDTH / 2)
        if self.host.player:can_move_to(x, y) then
            INFO("[Autobot|SiegeMonster|%d] search monster in zone(%d, %d)", self.host.player.pid, zone_x, zone_y)
            self.host.player:moveEye(x, y)
            self.timer_id = AutobotTimer:addTimer(self.search_func, SEARCH_INTERVAL)
            return
        end
    end
    self.search_end = true
    if self.host:_getTargetCount() > 0 then
        self:translate("Siege")
    end
end

function HuntDown:_onNewEntity(player, entity)
    if self.host:_isTargetEntity(entity) then
        self.host:_addTargetEntity(entity)
        if self.search_end or self.host:_getTargetCount() >= MONSTER_COUNT then
            self:translate("Siege")
        end
    end
end

function HuntDown:_onDelEntity(player, entity)
    self.host:_delTargetEntity(entity)
end

local Siege = makeState({})
function Siege:onInit()
    self.up_troop_func = newFunctor(self, self._onTroopUpdated)
    self.rm_troop_func = newFunctor(self, self._onTroopDeleted)
    self.fight_func = newFunctor(self, self._onFightInfo)
end

function Siege:onEnter()
    local target = self.host:_pickTarget()
    if nil == target then
        self.host:accomplish(false)
        return
    end
    if self.host.player.sinew < 5 then
        self:translate("NoSinew")
        return
    end
    INFO("[Autobot|SiegeMonster|%d] siege monster %d", self.host.player.pid, target)
    Rpc:siege(self.host.player, target, self.host.player:fallInTroop())
    self.target = target
    self.host.player.eventTroopUpdated:add(self.up_troop_func)
end

function Siege:onExit()
    self.host.player.eventTroopUpdated:del(self.up_troop_func)
    self.host.player.eventTroopDeleted:del(self.rm_troop_func)
    self.host.player.eventFightInfo:del(self.fight_func)

    self.target = nil
    self.troop_id = nil
    self.troop_eid = nil
    self.queried = nil
    self.win = nil
end

function Siege:_onTroopUpdated(player, troop_id, troop)
    if troop.target ~= self.target then
        return
    end
    if nil ~= self.troop_id and self.troop_id ~= troop_id then
        return
    end
    local dir = math.floor(troop.action / 100)
    INFO("[Autobot|SiegeMonster|%d] siege troop %d|%d|%d", self.host.player.pid, troop_id, troop.action, troop.tmOver - gTime)
    if dir == 1 then
        if nil == self.troop_id then -- 排除行军加速等后续的更新
            self.troop_id = troop_id
            self.troop_eid = troop.eid
            self.host.player.eventTroopDeleted:add(self.rm_troop_func)
            self.host.player.eventFightInfo:add(self.fight_func)
        end
    elseif dir == 3 then
        -- back, get battle info
        if not self.queried then
            self.queried = true
            Rpc:query_fight_info(self.host.player, self.troop_eid)
        end
    end
end

function Siege:_onTroopDeleted(player, troop_id)
    if troop_id ~= self.troop_id then
        return
    end
    if nil == self.win then
        -- 没攻击到
        INFO("[Autobot|SiegeMonster|%d] siege failed, hunt other monster", self.host.player.pid)
        self:translate("HuntDown")
        return
    end
    INFO("[Autobot|SiegeMonster|%d] siege accomplish %s", self.host.player.pid, self.win)
    self.host:accomplish(true)
end

function Siege:_onFightInfo(player, info)
    if self.troop_eid ~= info[1][3] then
        return
    end
    if info[1][4] ~= player.eid and info[1][5] ~= self.target then
        return
    end
    local count = #info
    local win = info[count].win
    self.win = 1 == win
end

local NoSinew = makeState({})
function NoSinew:onEnter()
    INFO("[Autobot|SiegeMonster|%d] out of sinew", self.host.player.pid)
end

function NoSinew:onExit()
end

function SiegeMonster:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("HuntDown", HuntDown, true)
    runner:addState("Siege", Siege)
    runner:addState("NoSinew", NoSinew)

    self.runner = runner
    runner:start()
end

function SiegeMonster:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return SiegeAction.makeClass(SiegeMonster, TroopAction.SiegeMonster)

