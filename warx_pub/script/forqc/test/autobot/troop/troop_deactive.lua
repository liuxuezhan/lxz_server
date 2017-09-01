local TroopDeactive = {}

function TroopDeactive:onEnter()
    if self.host:isActive() then
        self:translate("Rest")
    end
    INFO("[Autobot|TroopDeactive|%d] wait troop active", self.host.player.pid)
    self.host.eventStateChanged:add(newFunctor(self, self._onStateChanged))
end

function TroopDeactive:onExit()
    self.host.eventStateChanged:del(newFunctor(self, self._onStateChanged))
end

function TroopDeactive:_onStateChanged(active)
    if active then
        INFO("[Autobot|TroopDeactive|%d] troop is active now", self.host.player.pid)
        self:translate("Rest")
    else
        INFO("[Autobot|TroopDeactive|%d] troop isn't active", self.host.player.pid)
    end
end

return makeState(TroopDeactive)

