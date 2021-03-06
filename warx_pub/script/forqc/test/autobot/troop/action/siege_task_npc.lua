local SiegeTaskNpc = {}

function SiegeTaskNpc:init(player, task_id, monster_id)
    self.player = player
    self.task_id = task_id
    self.monster_id = monster_id

    self.up_troop_func = newFunctor(self, self._onTroopUpdated)
    self.rm_troop_func = newFunctor(self, self._onTroopDeleted)
    self.fight_func = newFunctor(self, self._onFightInfo)
    self.x = player.x + math.random(5, 10)
    self.y = player.y + math.random(5, 10)
end

function SiegeTaskNpc:start()
    self:_initiateSiege()
end

function SiegeTaskNpc:uninit()
    self.player.eventTroopUpdated:del(self.up_troop_func)
    self.player.eventTroopDeleted:del(self.rm_troop_func)
    self.player.eventFightInfo:del(self.fight_func)
end

function SiegeTaskNpc:_initiateSiege()
    self:_clearSiege()

    local player = self.player
    INFO("[Autobot|SiegeTaskNpc|%d] Siege task npc %d|%d", player.pid, self.task_id, self.monster_id)
    Rpc:siege_task_npc(player, self.task_id, player.eid, self.x, self.y, player:fallInTroop())
    player.eventTroopUpdated:add(self.up_troop_func)
end

function SiegeTaskNpc:_clearSiege()
    self.troop_id = nil
    self.troop_eid = nil
    self.queried = nil
    self.win = nil

    self.player.eventTroopUpdated:del(self.up_troop_func)
    self.player.eventTroopDeleted:del(self.rm_troop_func)
    self.player.eventFightInfo:del(self.fight_func)
end

function SiegeTaskNpc:_onTroopUpdated(player, troop_id, troop)
    if troop.target ~= self.player.eid then
        return
    end
    local base_action = math.floor(troop.action % 100)
    if base_action ~= TroopAction.SiegeTaskNpc then
        return
    end
    if nil ~= self.troop_id and self.troop_id ~= troop_id then
        return
    end
    local dir = math.floor(troop.action / 100)
    INFO("[Autobot|SiegeTaskNpc|%d] update troop %d|%d|%d", self.player.pid, troop_id, troop.action, troop.tmOver - gTime)
    if dir == 1 then
        if nil == self.troop_id then -- 排除行军加速等后续的更新
            self.troop_id = troop_id
            self.troop_eid = troop.eid
            self.player.eventTroopDeleted:add(self.rm_troop_func)
            self.player.eventFightInfo:add(self.fight_func)
        end
    elseif dir == 3 then
        -- back, get battle info
        if not self.queried then
            if self.troop_eid then
                self.queried = true
                Rpc:query_fight_info(self.player, self.troop_eid)
            end
        end
    end
end

function SiegeTaskNpc:_onTroopDeleted(player, troop_id)
    if troop_id ~= self.troop_id then
        return
    end
    if nil == self.win then
        -- 没攻击到
        INFO("[Autobot|SiegeTaskNpc|%d] siege failed, hunt other monster", self.player.pid)
        self:_initiateSiege()
        return
    end
    INFO("[Autobot|SiegeTaskNpc|%d] siege complete with %s", self.player.pid, self.win)
    if not self.win then
        self:_initiateSiege()
        return
    end
    self:accomplish(true)
end

function SiegeTaskNpc:_onFightInfo(player, info)
    if self.troop_eid ~= info[1][3] then
        return
    end
    if info[1][4] ~= player.eid then
        return
    end
    local count = #info
    local win = info[count].win
    self.win = 1 == win
    INFO("[Autobot|SiegeTaskNpc|%d] siege npc result: %s", self.player.pid, self.win)
end

return SiegeAction.makeClass("SiegeTaskNpc", SiegeTaskNpc, TroopAction.SiegeTaskNpc)

