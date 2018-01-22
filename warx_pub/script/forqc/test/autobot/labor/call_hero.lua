local CallHero = {}

function CallHero:onStart(player, hero_id)
    self.player = player
    self.hero_id = hero_id

    self:_start()
    return true
end

function CallHero:onStop()
    self:_stop()
end

function CallHero:_finish()
    self.player.labor_manager:deleteLabor(self)
end

local TakeAction = makeState()
function TakeAction:onEnter()
    local player = self.host.player
    local hero_id = self.host.hero_id

    local hero = player:get_hero(self.host.hero_id)
    if nil ~= hero then
        ERROR("[Autobot|CallHero|%d] Hero %d is already exist", player.pid, self.host.hero_id)
        return
    end
    local prop = resmng.prop_hero_basic[hero_id]
    local item_id, item_num = prop.PieceID, prop.CallPrice

    local item = player:get_item(item_id)
    if nil == item or item[3] < item_num then
        self:translate("WaitItem", item_id, item_num)
        return
    end
    INFO("[Autobot|CallHero|%d] Call hero %d with piece %d|%d", player.pid, hero_id, item_id, item_num)
    Rpc:call_hero_by_piece(player, hero_id)
    self.host.player.eventNewHero:add(newFunctor(self, self._onNewHero))
end

function TakeAction:onExit()
    self.host.player.eventNewHero:del(newFunctor(self, self._onNewHero))
end

function TakeAction:_onNewHero(player, hero)
    if hero.propid ~= self.host.hero_id then
        return
    end
    self.host:_finish(hero)
end

local WaitItem = makeState()
function WaitItem:onEnter(item_id, item_num)
    INFO("[Autobot|CallHero|%d] Item %d|%d is insufficiency.", player.pid, item_id, item_num)
    self.item_id = item_id
    self.item_num = item_num
    self.host.player.eventItemUpdated:add(newFunctor(self, self._onItemUpdated))
end

function WaitItem:onExit()
    self.host.player.eventItemUpdated:del(newFunctor(self, self._onItemUpdated))
end

function WaitItem:_onItemUpdated(player)
    local item = player:get_item(self.item_id)
    if nil == item or item[3] < self.item_num then
        return
    end
    self:translate("TakeAction")
end

function CallHero:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("TakeAction", TakeAction, true)
    runner:addState("WaitItem", WaitItem)

    self.runner = runner
    runner:start()
end

function CallHero:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("CallHero", CallHero)

