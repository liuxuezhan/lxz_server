local ScavengerMonsterRecover = {}

local RESTART_SINEW = config.Autobot.ScavengeMonsterRestartSinew or 70

function ScavengerMonsterRecover:onEnter()
    local player = self.host.player
    INFO("[Autobot|ScavengerMonster|%d] Wait for sinew recover from %d to %d.",
        player.pid,
        math.floor(player.sinew),
        RESTART_SINEW)
    self.host.player.eventSinewUpdated:add(newFunctor(self, ScavengerMonsterRecover._onSinewUpdated))
end

function ScavengerMonsterRecover:onExit()
    self.host.player.eventSinewUpdated:del(newFunctor(self, ScavengerMonsterRecover._onSinewUpdated))
end

function ScavengerMonsterRecover:_onSinewUpdated()
    local player = self.host.player
    if player.sinew < RESTART_SINEW then
        return
    end
    INFO("[Autobot|ScavengerMonster|%d] sinew have recovered to %d.", player.pid, math.floor(player.sinew))
    self.fsm:translate("Rest")
end

return makeState(ScavengerMonsterRecover)

