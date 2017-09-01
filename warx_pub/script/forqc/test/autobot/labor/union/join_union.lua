local JoinUnion = {}

function JoinUnion:onStart(player)
    if 0 ~= player.uid then
        return
    end
    self.player = player
    self.fsm = self:_createFsm()
    self.player.eventAddUnionMember:add(newFunctor(self, self._onAddUnionMember))
    self.fsm:start()
    return true
end

function JoinUnion:onStop()
    self.fsm:stop()
    self.player.eventAddUnionMember:del(newFunctor(self, self._onAddUnionMember))
end

function JoinUnion:_createFsm()
    local fsm = StateMachine:createInstance(self)
    fsm:addState("GetUnions", JoinUnion_GetUnions, true)
    fsm:addState("ApplyUnion", JoinUnion_ApplyUnion)
    fsm:addState("CreateUnion", JoinUnion_CreateUnion)
    fsm:addState("Accomplish", JoinUnion_Accomplish)
    return fsm
end

function JoinUnion:_onAddUnionMember(player, member)
    if member.pid ~= self.player.pid then
        return
    end
    INFO("[Autobot|JoinUnion|%d] Player joined union %s", self.player.pid, member.title)
    self.fsm:translate("Accomplish", member)
end

return makeLabor("JoinUnion", JoinUnion)

