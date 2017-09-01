local LevelupHero = {}

local REST_TIME = 2

function LevelupHero:onStart(player, hero_id, target_level)
    self.player = player
    self.hero = player:get_hero(hero_id)
    self.hero_id = hero_id
    self.target_level = target_level

    self:_start()
    return true
end

function LevelupHero:onStop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

function LevelupHero:_finish()
    self.player.labor_manager:deleteLabor(self)
end

local LevelUp = makeState({})
function LevelUp:onEnter()
    if nil == self.host.hero then
        self:translate("Recruit")
        return
    end
    -- found items
    local items = {}
    for k, v in pairs(self.host.player._item) do
        local prop = resmng.prop_item[v[2]]
        if nil ~= prop and prop.Class == ITEM_CLASS.HERO and prop.Mode == ITEM_HERO_MODE.EXP_BOOK then
            if v[3] > 0 then
                table.insert(items, {v,prop})
            end
        end
    end
    table.sort(items, function(a, b) return a[2].Param < b[2].Param end)

    if 0 == #items then
        self:translate("WaitItem")
        return
    end

    local need_exp = 0
    for i = self.host.hero.lv +1, self.host.target_level do
        local lvup_conf = resmng.prop_hero_lv_exp[i]
        need_exp = need_exp + lvup_conf.NeedExp[self.host.hero.quality]
    end
    local item, prop = items[1][1], items[1][2]
    local num = math.ceil(need_exp / prop.Param)
    if num > item[3] then
        num = item[3]
    end
    INFO("[Autobot|LevelUpHero|%d] level up hero %d with item %d|%d.", self.host.player.pid, self.host.hero.propid, item[2], num)
    Rpc:hero_lv_up(self.host.player, self.host.hero.idx, item[1], num)
    self.host.player.eventHeroUpdated:add(newFunctor(self, self._onHeroUpdated))
end

function LevelUp:onExit()
    self.host.player.eventHeroUpdated:del(newFunctor(self, self._onHeroUpdated))
end

function LevelUp:_onHeroUpdated(player, hero)
    if hero.idx ~= self.host.hero.idx then
        return
    end
    if hero.lv >= self.host.target_level then
        self.host:_finish()
    else
        self:translate("Rest")
    end
end

local WaitItem = makeState({})
function WaitItem:onEnter()
    WARN("[Autobot|LevelUpHero|%d] WaitItem isn't implemented now.", self.host.player.pid)
end

function WaitItem:onExit()
end

local Recruit = makeState({})
function Recruit:onEnter()
    -- Recurit hero could create a recruit labor
    if nil ~= self.host.hero then
        self:translate("Rest")
        return
    end
    local prop = resmng.prop_hero_basic[self.host.hero_id]
    local item_id, item_num = prop.PieceID, prop.CallPrice

    local item = self.host.player:get_item(item_id)
    if nil == item or item[3] < item_num then
        -- wait hero recruit item
        return
    end
    INFO("[Autobot|LevelUpHero|%d] recruit hero %d with piece.", self.host.player.pid, self.host.hero_id)
    Rpc:call_hero_by_piece(self.host.player, self.host.hero_id)
    self.host.player.eventNewHero:add(newFunctor(self, self._onNewHero))
end

function Recruit:onExit()
    self.host.player.eventNewHero:del(newFunctor(self, self._onNewHero))
end

function Recruit:_onNewHero(player, hero)
    if hero.propid ~= self.host.hero_id then
        return
    end
    self.host.hero = hero
    self:translate("LevelUp")
end

local Rest = makeState({})
function Rest:onEnter()
    AutobotTimer:addTimer(function() self:translate("LevelUp") end, REST_TIME)
end

function LevelupHero:_start()
    local hero = self.player:get_hero(self.hero_id)
    if nil ~= hero and hero.lv >= self.target_level then
        self:_finish()
        return
    end

    local runner = StateMachine:createInstance(self)
    runner:addState("LevelUp", LevelUp, true)
    runner:addState("WaitItem", WaitItem)
    runner:addState("Recruit", Recruit)
    runner:addState("Rest", Rest)
    self.runner = runner

    runner:start()
end

return makeLabor("LevelupHero", LevelupHero)

