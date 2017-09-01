local MoveToZone = {}

local INTERVAL = config.Autobot.MoveEyeInterval or 2

function MoveToZone:onStart(player, zone_lv)
    self.player = player
    self.zone_lv = zone_lv
    local start_x = math.floor(player.x / 16)
    local start_y = math.floor(player.y / 16)
    self.cross_zones = cross_zones(start_x, start_y, 40, 40)
    player.troop_manager:deactiveTroop()
    self:_initBlockInfo()
    self:_start()
    return true
end

function MoveToZone:onStop()
    self:_stop()
    self.player.eventNewEntity:del(newFunctor(self, self._onNewEntity))
    self.player.eventDelEntity:del(newFunctor(self, self._onDelEntity))
    INFO("[Autobot|Migrate|%d] onStop.", self.player.pid)
    self.player.troop_manager:activeTroop()
    INFO("[Autobot|Migrate|%d] onStop 2.", self.player.pid)
end

function MoveToZone:_finish()
    INFO("[Autobot|Migrate|%d] finish labor %d.", self.player.pid, self.id)
    self.player.labor_manager:deleteLabor(self)
end

function MoveToZone:_getNextZone()
    if self.cross_zones then
        local x, y = self.cross_zones()
        if nil == x then
            self.cross_zones = nil
        end
        return x, y
    end
end

function MoveToZone:_initBlockInfo()
    local player = self.player

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

function MoveToZone:_onNewEntity(player, entity)
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

function MoveToZone:_onDelEntity(player, entity)
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

function MoveToZone:_checkPos(sx, sy, size)
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

local WaitTroop = makeState({})
function WaitTroop:onEnter()
    if not self.host.player.troop_manager:hasBusyTroop() then
        self:translate("MoveEye")
        return
    end
    INFO("[Autobot|Migrate|%d] There is some troop, wait.", self.host.player.pid)
    self.host.player.troop_manager.eventBusyTroopFinished:add(newFunctor(self, self._onTroopFinished))
end

function WaitTroop:onExit()
    self.host.player.troop_manager.eventBusyTroopFinished:del(newFunctor(self, self._onTroopFinished))
end

function WaitTroop:_onTroopFinished()
    if not self.host.player.troop_manager:hasBusyTroop() then
        INFO("[Autobot|Migrate|%d] All troop has returned.", self.host.player.pid)
        self:translate("MoveEye")
    end
end

local MoveEye = makeState({})
function MoveEye:onEnter()
    while true do
        local x, y = self.host:_getNextZone()
        if nil == x then
            return
        end
        local zone_lv = c_get_zone_lv(x, y)
        if zone_lv == self.host.zone_lv then
            self.host.player:moveEye(x * 16 + 8, y * 16 + 8)
            AutobotTimer:addTimer(function() self:translate("Migrate", x, y) end, INTERVAL)
            break
        end
    end
end

function MoveEye:onExit()
end

local Migrate = makeState({})
function Migrate:onEnter(zone_x, zone_y)
    INFO("[Autobot|Migrate|%d] find in zone %d, %d", self.host.player.pid, zone_x, zone_y)
    local positions = {}
    local start_x, start_y = zone_x * 16, zone_y * 16
    local end_x, end_y = start_x + 15, start_y + 15
    for x = start_x, end_x do
        for y = start_y, end_y do
            if self.host:_checkPos(x, y, 4) then
                table.insert(positions, {x, y})
            end
        end
    end
    if 0 == #positions then
        self:translate("Rest")
        return
    end
    local index = math.random(#positions)
    self:_doMigrate(positions[index][1], positions[index][2])
end

function Migrate:onExit()
    self.host.player:delRpcErrorHandler("migrate", newFunctor(self, self._onError))
end

function Migrate:_doMigrate(x, y)
    sync(self.host.player, true)
    Rpc:migrate(self.host.player, x, y)
    action(function()
        sync(self.host.player)
        self:_onMigrate()
    end)
    self.host.player:addRpcErrorHandler("migrate", newFunctor(self, self._onError))
end

function Migrate:_onMigrate()
    if self.success then
        INFO("[Autobot|Migrate|%d] migrate finish", self.host.player.pid)
        self.host:_finish()
    else
        self:translate("Rest")
    end
end

function Migrate:_onError(code, reason)
    if code ~= resmng.E_OK then
        return
    end
    INFO("[Autobot|Migrate|%d] migrate success", self.host.player.pid)
    self.success = true
end

local Rest = makeState({})
function Rest:onEnter()
    AutobotTimer:addTimer(function() self:translate("MoveEye") end, INTERVAL)
end

function MoveToZone:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("WaitTroop", WaitTroop, true)
    runner:addState("MoveEye", MoveEye)
    runner:addState("Migrate", Migrate)
    runner:addState("Rest", Rest)
    self.runner = runner

    runner:start()
end

function MoveToZone:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("MoveToZone", MoveToZone)

