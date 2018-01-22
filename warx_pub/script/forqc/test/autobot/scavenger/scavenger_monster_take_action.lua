local ScavengerMonsterTakeAction = {}

local MIN_SINEW = config.Autobot.ScavengeMonsterMinSinew or 20

function ScavengerMonsterTakeAction:onEnter()
    if self.host:getTroopCount("Battle") > 0 then
        self:translate("Rest")
        return
    end
    self:_initiateRequest()
end

function ScavengerMonsterTakeAction:onExit()
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
    action.name = "SiegeMonster"
    action.params = {1, min_level, max_level}
    INFO("[Autobot|ScavengerMonster|%d] initiate a siege monster(%d|%d) action.", self.host.player.pid, min_level, max_level)
    self.host:requestTroop(action, 500, newFunctor(self, self._onAccomplished))
end

function ScavengerMonsterTakeAction:_onAccomplished(flag)
    INFO("[Autobot|ScavengerMonster|%d] siege finished %s.", self.host.player.pid, flag)
    self:translate("Rest")
end

return makeState(ScavengerMonsterTakeAction)

