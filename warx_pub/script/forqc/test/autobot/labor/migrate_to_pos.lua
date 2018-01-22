local MigrateToPos = {}

local INTERVAL = config.Autobot.MoveEyeInterval or 2

function MigrateToPos:onStart(player, pos_x, pos_y, range)
    self.player = player
    self.pos_x = pos_x
    self.pos_y = pos_y
    self.range = range
    player.troop_manager:deactiveTroop()

    self:_start()
    return true
end

function MigrateToPos:onStop()
    self:_stop()
    self.player.troop_manager:activeTroop()
end

function MigrateToPos:_finish()
    self.player.labor_manager:deleteLabor(self)
end

function MigrateToPos:checkEyeZone(x, y)
    if self.last_eye_x and self.last_eye_y then
        local last_zone_x = math.floor(self.last_eye_x / 16)
        local last_zone_y = math.floor(self.last_eye_y / 16)
        local new_zone_x = math.floor(x / 16)
        local new_zone_y = math.floor(y / 16)
        if last_zone_x == new_zone_x and last_zone_y == new_zone_y then
            return true
        end
    end
end

function MigrateToPos:setEyePos(x, y)
    self.last_eye_x = x
    self.last_eye_y = y
    self.player:moveEye(x, y)
end

function MigrateToPos:_initBlockInfo()
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

function MigrateToPos:_onNewEntity(player, entity)
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

function MigrateToPos:_onDelEntity(player, entity)
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

function MigrateToPos:_checkPos(sx, sy, size)
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
    if not self.host.player.troop_manager:hasTroopQueueWorking() then
        self:translate("FindPos")
        return
    end
    INFO("[Autobot|MigrateToPos|%d] There is some troop, wait.", self.host.player.pid)
    self.host.player.troop_manager.eventTroopQueueActivating:add(newFunctor(self, self._onTroopQueueActivate))
end

function WaitTroop:onExit()
    self.host.player.troop_manager.eventTroopQueueActivating:del(newFunctor(self, self._onTroopQueueActivate))
end

function WaitTroop:_onTroopQueueActivate()
    if not self.host.player.troop_manager:hasTroopQueueWorking() then
        INFO("[Autobot|MigrateToPos|%d] All troop has returned.", self.host.player.pid)
        self:translate("FindPos")
    end
end

local FindPos = makeState({})
function FindPos:onInit()
    self.spinner = spin_zones(self.host.range)
end

function FindPos:onEnter()
    for off_x, off_y in self.spinner do
        local x, y = self.host.pos_x + off_x, self.host.pos_y + off_y
        if self.host.player:can_move_to(x, y) then
            if self.host:checkEyeZone(x, y) then
                if self.host:_checkPos(x, y, 4) then
                    self:translate("Migrate", x, y)
                    return
                end
            else
                self:translate("MoveEye", x, y)
                return
            end
        end
    end
    INFO("[Autobot|MigrateToPos|%d] Not found suitable migrate position.", self.host.player.pid)
    self.host:_finish(false)
end

local MoveEye = makeState({})
function MoveEye:onEnter(x, y)
    INFO("[Autobot|MigrateToPos|%d] Move eye to %d,%d", self.host.player.pid, x, y)
    self.host:setEyePos(x, y)
    AutobotTimer:addTimer(function() 
        if self.host:_checkPos(x, y, 4) then
            self:translate("Migrate", x, y)
        else
            self:translate("FindPos")
        end
    end, INTERVAL)
end

local Migrate = makeState({})
function Migrate:onEnter(x, y)
    self:_doMigrate(x, y)
end

function Migrate:onExit()
    self.host.player:delRpcErrorHandler("migrate", newFunctor(self, self._onError))
end

function Migrate:_doMigrate(x, y)
    self.host.player:sync(function() end)
    Rpc:migrate(self.host.player, x, y)
    self.host.player:sync(function() self:_onMigrate() end)
    self.host.player:addRpcErrorHandler("migrate", newFunctor(self, self._onError))
end

function Migrate:_onMigrate()
    if self.success then
        INFO("[Autobot|MigrateToPos|%d] migrate finish", self.host.player.pid)
        self.host:_finish(true)
    else
        self:translate("FindPos")
    end
end

function Migrate:_onError(code, reason)
    if code ~= resmng.E_OK then
        return
    end
    INFO("[Autobot|MigrateToPos|%d] migrate success", self.host.player.pid)
    self.success = true
end

function MigrateToPos:_start()
    self:_initBlockInfo()

    local runner = StateMachine:createInstance(self)
    runner:addState("WaitTroop", WaitTroop, true)
    runner:addState("FindPos", FindPos)
    runner:addState("MoveEye", MoveEye)
    runner:addState("Migrate", Migrate)
    self.runner = runner

    runner:start()
end

function MigrateToPos:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("MigrateToPos", MigrateToPos)

