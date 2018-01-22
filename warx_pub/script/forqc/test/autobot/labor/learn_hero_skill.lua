local LearnHeroSkill = {}

function LearnHeroSkill:onStart(player, hero_id, pos)
    self.player = player
    if 0 == hero_id then
        self.hero_id = get_born_heroid(player)
    else
        self.hero_id = hero_id
    end
    self.skill_pos = pos

    self:_start()
    return true
end

function LearnHeroSkill:onStop()
    self:_stop()
end

function LearnHeroSkill:_finish()
    self.player.labor_manager:deleteLabor(self)
end

local TakeAction = makeState()
function TakeAction:onEnter()
    local player = self.host.player

    local hero = player:get_hero(self.host.hero_id)
    if nil == hero then
        self:translate("CallHero", self.host.hero_id)
        return
    end

    local skill_pos = self.host.skill_pos
    if skill_pos == 0 then
        for k, v in ipairs(hero.basic_skill) do
            if 0 == v[1] then
                skill_pos = k
                break
            end
        end
        if 0 == skill_pos then
            self:translate("NoSlot")
            return
        end
    else
        local skill = hero.basic_skill[skill_pos]
        if nil == skill then
            self:translate("NoSlot")
            return
        end
        if 0 ~= skill[1] then
            self:translate("ExistSkill")
            return
        end
    end

    local learned_skills = {}
    for k, v in ipairs(hero.basic_skill) do
        if 0 ~= v[1] then
            local prop = resmng.prop_skill[v[1]]
            table.insert(learned_skills, prop.Mode)
        end
    end

    local item
    for k, v in pairs(player._item) do
        local prop = resmng.prop_item[v[2]]
        if prop.Class == ITEM_CLASS.SKILL and prop.Mode == ITEM_SKILL_MODE.SPECIAL_BOOK and prop.Lv < 200 then
            local skill_prop = resmng.prop_skill[prop.Param[1]]
            if not is_in_table(learned_skills, skill_prop.Mode) then
                item = v
                break
            end
        end
    end

    if nil == item then
        self:translate("NoItem")
        return
    end

    Rpc:use_hero_skill_item(player, hero.idx, skill_pos, item[1], 1)
    self.hero_idx = hero.idx
    self.skill_pos = skill_pos
    player.eventHeroUpdated:add(newFunctor(self, self._onHeroUpdated))
end

function TakeAction:onExit()
    self.host.player.eventHeroUpdated:del(newFunctor(self, self._onHeroUpdated))
    self.hero_idx = nil
    self.skill_pos = nil
end

function TakeAction:_onHeroUpdated(player, hero)
    if hero.idx ~= self.hero_idx then
        return
    end
    local skill = hero.basic_skill[self.skill_pos]
    if nil == skill or 0 == skill[1] then
        return
    end
    INFO("[Autobot|LearnHeroSkill|%d] Hero %d|%d has learned skill %d at pos %d", self.host.player.pid, hero.idx, hero.propid, skill[1], self.skill_pos)
    self.host:_finish()
end

local CallHero = makeState()
function CallHero:onEnter(hero_id)
    self.host.player.labor_manager:createLabor("CallHero", newFunctor(self, self._onCallHero), self.host.player, hero_id)
end

function CallHero:_onCallHero()
    self:translate("TakeAction")
end

local ExistSkill = makeState()
function ExistSkill:onEnter()
    self.timer_id = AutobotTimer:addTimer(function() self:_finish() end, 1)
end

function ExistSkill:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

local NoSlot = makeState()
function NoSlot:onEnter()
    -- TODO：添加处理策略
    INFO("[Autobot|LearnHeroSkill|%d] There is no skill slot", self.host.player.pid)
end

local NoItem = makeState()
function NoItem:onEnter()
    INFO("[Autobot|LearnHeroSkill|%d] No skill item, wait it.", self.host.player.pid)
    self.host.player.eventItemUpdated:add(newFunctor(self, self._onItemUpdated))
end

function NoItem:onExit()
    self.host.player.eventItemUpdated:del(newFunctor(self, self._onItemUpdated))
end

function NoItem:_onItemUpdated(player)
    self:translate("TakeAction")
end

function LearnHeroSkill:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("TakeAction", TakeAction, true)
    runner:addState("CallHero", CallHero)
    runner:addState("ExistSkill", ExistSkill)
    runner:addState("NoSlot", NoSlot)
    runner:addState("NoItem", NoItem)

    self.runner = runner
    runner:start()
end

function LearnHeroSkill:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("LearnHeroSkill", LearnHeroSkill)

