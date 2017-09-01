local UnionHelpManager = {}

function UnionHelpManager:init(player)
    self.player = player
    self.eventHelpChanged = newEventHandler()

    player.eventUnionChanged:add(newFunctor(self, self._onUnionChanged))
    self.player.eventUnionHelpGet:add(newFunctor(self, self._onUnionHelpGet))
    self.player.eventUnionHelpAdd:add(newFunctor(self, self._onUnionHelpAdd))
    self.player.eventUnionHelpDel:add(newFunctor(self, self._onUnionHelpDel))

    self:_initHelps()
end

function UnionHelpManager:uninit()
    self.player.eventUnionChanged:del(newFunctor(self, self._onUnionChanged))
    self.player.eventUnionHelpGet:del(newFunctor(self, self._onUnionHelpGet))
    self.player.eventUnionHelpAdd:del(newFunctor(self, self._onUnionHelpAdd))
    self.player.eventUnionHelpDel:del(newFunctor(self, self._onUnionHelpDel))
end

function UnionHelpManager:doHelp()
    local helps = {}
    local my_id = self.player.pid
    for k, v in pairs(self.helps) do
        if v ~= my_id then
            table.insert(helps, k)
        end
    end
    local count = #helps
    if count > 0 then
        INFO("[Autobot|UnionHelp|%d] Help %d union helps.", self.player.pid, count)
        Rpc:union_help_sets(self.player, helps)
        self.helps = {}
    else
        --INFO("[Autobot|UnionHelp|%d] no help need to help.", self.player.pid)
    end
end

function UnionHelpManager:hasHelp()
    return next(self.helps)
end

function UnionHelpManager:getHelp(sn)
    return self.helps[sn]
end

function UnionHelpManager:_onUnionChanged(player, uid)
    if 0 == uid then
        self:_clearHelps()
    else
        self:_initHelps()
    end
end

function UnionHelpManager:_initHelps()
    self.helps = {}
    if 0 == self.player.uid then
        return
    end
    Rpc:union_help_get(self.player)
end

function UnionHelpManager:_clearHelps()
    self.helps = {}
end

function UnionHelpManager:_onUnionHelpGet(player, helps)
    local count = 0
    for k, v in pairs(helps) do
        if self:_addHelp(v) then
            count = count + 1
        end
    end
    if count > 0 then
        self.eventHelpChanged()
    end
end

function UnionHelpManager:_onUnionHelpAdd(player, help)
    if self:_addHelp(help) then
        self.eventHelpChanged()
    end
end

function UnionHelpManager:_onUnionHelpDel(player, help)
    if self:_delHelp(help.id) then
        self.eventHelpChanged()
    end
end

function UnionHelpManager:_addHelp(help)
    --INFO("[Autobot|UnionHelp|%d] new help %d|%d", self.player.pid, help[1], help[2])
    self.helps[help[1]] = help[2]
    return true
end

function UnionHelpManager:_delHelp(sn)
    if nil == self.helps[sn] then
        return
    end
    --INFO("[Autobot|UnionHelp|%d] delete %d|%d", self.player.pid, sn, self.helps[sn])
    self.helps[sn] = nil
    return true
end

return makeClass(UnionHelpManager)

