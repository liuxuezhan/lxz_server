local ScavengerMonsterTakeAction = {}

local MIN_SINEW = config.Autobot.ScavengeMonsterMinSinew or 20

function ScavengerMonsterTakeAction:onEnter()
    if 0 == self.host:getTroopCount("Battle") then
        self.host.eventBusyTroopStarted:add(newFunctor(self, ScavengerMonsterTakeAction._onTroopStarted))
        self:_initiateRequest()
    else
        self.host.eventBusyTroopFinished:add(newFunctor(self, ScavengerMonsterTakeAction._onTroopFinished))
    end
end

function ScavengerMonsterTakeAction:onExit()
    self.host.eventBusyTroopStarted:del(newFunctor(self, ScavengerMonsterTakeAction._onTroopStarted))
    self.host.eventBusyTroopFinished:del(newFunctor(self, ScavengerMonsterTakeAction._onTroopFinished))
end

function ScavengerMonsterTakeAction:_initiateRequest()
    if math.floor(self.host.player.sinew) <= MIN_SINEW then
        self.fsm:translate("Recover")
        return
    end
    local level = self.host.player:get_castle_lv()
    local min_level = level < 3 and 1 or math.floor((level - 2) / 3) * 3 + 1
    local max_level = level
    local action = {}
    action.name = "AttackLevelMonster"
    action.params = {1, min_level, max_level}
    INFO("[Autobot|ScavengerMonster|%d] initiate a sieget monster(%d|%d) action.", self.host.player.pid, min_level, max_level)
    self.host:requestTroop(action, 500)
end

function ScavengerMonsterTakeAction:_onTroopStarted(player, index, troop)
    if 0 == self.host:getTroopCount("Battle") then
        return
    end
    self.host.eventBusyTroopStarted:del(newFunctor(self, ScavengerMonsterTakeAction._onTroopStarted))
    self.host.eventBusyTroopFinished:add(newFunctor(self, ScavengerMonsterTakeAction._onTroopFinished))
end

function ScavengerMonsterTakeAction:_onTroopFinished()
    if self.host:getTroopCount("Battle") > 0 then
        return
    end
    self.fsm:translate("Rest")
end

return makeState(ScavengerMonsterTakeAction)

