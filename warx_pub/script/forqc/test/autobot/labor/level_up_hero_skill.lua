local LevelUpHeroSkill = {}

function LevelUpHeroSkill:onStart(player, hero, skill_index, level)
    self.player = player
    self.hero = hero
    self.skill_index = skill_index
    self.level = level

    self:_start()
    return true
end

function LevelUpHeroSkill:onStop()
    self:_stop()
end

function LevelUpHeroSkill:_finish()
    self.player.labor_manager:deleteLabor(self)
end

local TakeAction = makeState()
function TakeAction:onEnter()
    local player = self.host.player

    local skill = self.host.hero.basic_skill[self.host.skill_index]
    local prop = resmng.prop_skill[skill[1]]
    local need_exp = 0
    for lv = prop.Lv + 1, self.host.level do
        local exp_prop = resmng.prop_hero_skill_exp[lv]
        need_exp = need_exp + exp_prop.NeedExp[prop.Class]
    end

    if 0 == need_exp then
        self:translate("Done")
        return
    end

    local items = {}
    for k, v in pairs(player._item) do
        local prop = resmng.prop_item[v[2]]
        if prop.Class == ITEM_CLASS.SKILL and v[3] > 0 then
            if prop.Mode == ITEM_SKILL_MODE.SPECIAL_BOOK or
                prop.Mode == ITEM_SKILL_MODE.COMMON_BOOK then
                table.insert(items, {v, prop})
            end
        end
    end

    table.sort(items, function(a, b)
        if a[2].Mode == b[2].Mode then
            return a[2].Param[2] > b[2].Param[2]
        else
            return a[2].Mode < b[2].Mode
        end
    end)
    for k, v in pairs(items) do
        self:translate("UseItem", v[1], need_exp)
        return
    end
    self:translate("NoItem")
end

local UseItem = makeState()
function UseItem:onEnter(item, need_exp)
    INFO("[Autobot|LevelUpHeroSkill|%d] ready to use item %d", self.host.player.pid, item[2])
    local prop = resmng.prop_item[item[2]]
    local count = math.ceil(need_exp / prop.Param[2])
    if count > item[3] then
        count = item[3]
    end
    INFO("[Autobot|LevelUpHeroSkill|%d] Upgrade hero %d|%d skill %d with item %d|%d", self.host.player.pid, self.host.hero.idx, self.host.hero.propid, self.host.skill_index, item[1], count)
    Rpc:hero_skill_up(self.host.player, self.host.hero.idx, self.host.skill_index, item[1], count)
    self.host.player.eventHeroUpdated:add(newFunctor(self, self._onHeroUpdated))
end

function UseItem:onExit()
    self.host.player.eventHeroUpdated:del(newFunctor(self, self._onHeroUpdated))
end

function UseItem:_onHeroUpdated(player, hero)
    if self.host.hero.idx ~= hero.idx then
        return
    end
    self:translate("TakeAction")
end

local NoItem = makeState()
function NoItem:onEnter()
    INFO("[Autobot|LevelUpHeroSkill|%d] No skill item, wait it.", self.host.player.pid)
    self.host.player.eventItemUpdated:add(newFunctor(self, self._onItemUpdated))
end

function NoItem:onExit()
    self.host.player.eventItemUpdated:del(newFunctor(self, self._onItemUpdated))
end

function NoItem:_onItemUpdated(player)
    self:translate("TakeAction")
end

local Done = makeState()
function Done:onEnter()
    INFO("[Autobot|LevelUpHeroSkill|%d] Upgrade done", self.host.player.pid)
    self.timer_id = AutobotTimer:addTimer(function() self.host:_finish() end, 1)
end

function Done:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function LevelUpHeroSkill:_start()
    local runner = StateMachine:createInstance(self)
    runner:addState("TakeAction", TakeAction, true)
    runner:addState("UseItem", UseItem)
    runner:addState("NoItem", NoItem)
    runner:addState("Done", Done)

    self.runner = runner
    runner:start()
end

function LevelUpHeroSkill:_stop()
    if self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeLabor("LevelUpHeroSkill", LevelUpHeroSkill)

