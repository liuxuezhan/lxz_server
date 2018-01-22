local RankupHero = {}

local REST_TIME = 2

function RankupHero:onStart(player, hero_id, target_star)
    self.player = player
    self.hero_id = hero_id
    self.target_star = target_star

    self:_start()
    return true
end

function RankupHero:onStop()
    self:_stop()
end

function RankupHero:_finish(result)
    self.success = result
    self.player.labor_manager:deleteLabor(self)
end

local RankUp = makeState({})
function RankUp:onEnter()
    local hero_id = self.host.hero_id
    if 0 ~= hero_id then
        local hero = self.host.player:get_hero(hero_id)
        if nil == hero then
            self:translate("Recruit")
            return
        end
        if self:_doRankUp(hero) then
            self:translate("RankUping", hero)
        else
            self:translate("WaitItem")
        end
    else
        local hero = nil
        for k, v in pairs(self.host.player._hero) do
            if self:_doRankUp(v) then
                hero = v
                break
            end
        end
        if hero then
            self:translate("RankUping", hero)
        else
            self:translate("WaitItem")
        end
    end
end

function RankUp:_doRankUp(hero)
    local prop = resmng.prop_hero_basic[hero.propid]
    if nil == prop then
        INFO("[Autobot|RankUpHero|%d] no hero %d prop.", self.host.player.pid, hero_id)
        return false
    end

    local star_prop = resmng.prop_hero_star_up[hero.star +1]
    if nil == star_prop then
        INFO("[Autobot|RankUpHero|%d] no hero %d star up prop.", self.host.player.pid, hero.star + 1)
        return false
    end

    local item = self.host.player:get_item(prop.PieceID)
    if nil == item or item[3] < star_prop.StarUpPrice then
        return false
    end

    INFO("[Autobot|RankUpHero|%d] rank up hero %d.", self.host.player.pid, hero.propid)
    Rpc:hero_star_up(self.host.player, hero.idx)
    return true
end

local RankUping = makeState({})

function RankUping:onEnter(hero)
    self.hero = hero
    self.host.player.eventHeroUpdated:add(newFunctor(self, self._onHeroUpdated))
end

function RankUping:onExit()
    self.host.player.eventHeroUpdated:del(newFunctor(self, self._onHeroUpdated))
end

function RankUping:_onHeroUpdated(player, hero)
    if hero.idx ~= self.hero.idx then
        return
    end
    if hero.star >= self.host.target_star then
        self.host:_finish(true)
    else
        self:translate("Rest")
    end
end

local WaitItem = makeState({})
function WaitItem:onEnter()
    self.host.player.eventItemUpdated:add(newFunctor(self, self._onItemUpdated))
    if 0 == self.host.hero_id then
        self.host.player.eventHeroUpdated:add(newFunctor(self, self._onHeroUpdated))
        self.host.player.eventNewHero:add(newFunctor(self, self._onHeroUpdated))
    end
end

function WaitItem:onExit()
    self.host.player.eventItemUpdated:del(newFunctor(self, self._onItemUpdated))
    if 0 == self.host.hero_id then
        self.host.player.eventHeroUpdated:del(newFunctor(self, self._onHeroUpdated))
        self.host.player.eventNewHero:del(newFunctor(self, self._onHeroUpdated))
    end
end

function WaitItem:_onItemUpdated()
    self:translate("Rest")
end

function WaitItem:_onHeroUpdated()
    self:translate("Rest")
end

local Recruit = makeState({})
function Recruit:onEnter()
    if 0 == self.host.hero_id then
        self:translate("Rest")
        return
    end
    self.host.player.labor_manager:createLabor("CallHero", newFunctor(self, self._onCallHero), self.host.player, self.host.hero_id)
end
function Recruit:_onCallHero(player)
    self:translate("Rest")
end

local Rest = makeState({})
function Rest:onEnter()
    self.timer_id = AutobotTimer:addTimer(function() self:translate("RankUp") end, REST_TIME)
end

function Rest:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function RankupHero:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("RankUp", RankUp, true)
    runner:addState("RankUping", RankUping)
    runner:addState("WaitItem", WaitItem)
    runner:addState("Recruit", Recruit)
    runner:addState("Rest", Rest)
    self.runner = runner

    runner:start()
end

function RankupHero:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("RankupHero", RankupHero)

