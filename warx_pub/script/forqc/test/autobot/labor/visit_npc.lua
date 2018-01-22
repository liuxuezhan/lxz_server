local VisitNpc = {}

local WAIT_TIME = 3

function VisitNpc:onStart(player, task_id, propid)
    self.player = player
    self.task_id = task_id
    self.propid = propid

    self:_start()
    return true
end

function VisitNpc:onStop()
    self:_stop()
end

function VisitNpc:_finish()
    self.player.labor_manager:deleteLabor(self)
end

local MoveEye = makeState({})
function MoveEye:onEnter()
    for k, v in pairs(self.host.player._etys) do
        if v.propid == self.host.propid then
            self:translate("Visit", v)
            return
        end
    end

    local prop = resmng.prop_world_unit[self.host.propid]
    if nil == prop then
        INFO("[Autobot|VisitNpc|%d] The propid %d isn't exist in prop_world_unit", self.host.player.pid, self.host.propid)
        return
    end
    self.host.player:moveEye(prop.X, prop.Y)
    self.host.player.eventNewEntity:add(newFunctor(self, self._onNewEntity))
    self.timer_id = AutobotTimer:addTimer(function() self:translate("NotFound") end, WAIT_TIME)
end

function MoveEye:onExit()
    self.host.player.eventNewEntity:del(newFunctor(self, self._onNewEntity))
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function MoveEye:_onNewEntity(player, entity)
    if entity.propid ~= self.host.propid then
        return
    end
    self:translate("Visit", entity)
end

local NotFound = makeState({})
function NotFound:onEnter()
    AutobotTimer:addTimer(function() self:translate("MoveEye") end, WAIT_TIME)
end

local Visit = makeState({})
function Visit:onEnter(entity)
    INFO("[Autobot|VisitNpc|%d] Ready to visit npc %d|%d at %d,%d.", self.host.player.pid, entity.eid, entity.propid, entity.x, entity.y)
    Rpc:task_visit(self.host.player, self.host.task_id, entity.eid, entity.x, entity.y, {live_soldier = {}})
    self.host.player.eventTroopUpdated:add(newFunctor(self, self._onTroopUpdated))
end

function Visit:onExit()
    self.host.player.eventTroopUpdated:del(newFunctor(self, self._onTroopUpdated))
end

function Visit:_onTroopUpdated(player, troop_id, troop)
    local base_action = math.floor(troop.action % 100)
    if base_action ~= TroopAction.VisitNpc then
        return
    end
    if nil == troop.target_propid or self.host.propid ~= troop.target_propid then
        return
    end
    INFO("[Autobot|VisitNpc|%d] The visit troop %d is on the way.", self.host.player.pid, troop_id)
    self.host:_finish()
end

function VisitNpc:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("MoveEye", MoveEye, true)
    runner:addState("NotFound", NotFound)
    runner:addState("Visit", Visit)
    self.runner = runner

    runner:start()
end

function VisitNpc:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("VisitNpc", VisitNpc)

