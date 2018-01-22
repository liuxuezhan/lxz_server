local SpecialHeroLevel = {}

function SpecialHeroLevel:onStart()
    self.player.eventHeroUpdated:add(newFunctor(self, self._check))
end

function SpecialHeroLevel:onStop()
    self.player.eventHeroUpdated:del(newFunctor(self, self._check))
end

function SpecialHeroLevel:onProcess(task_data, heroid, level)
    self.heroid = heroid
    self.level = level

    self:_check()
end

function SpecialHeroLevel:_check()
    local hero = self.player:get_hero(self.heroid)
    if nil == hero then
        return
    end
    if hero.lv < self.level then
        return
    end
    self:_finishTask()
end

return makeTaskActionHandler(TASK_ACTION.SPECIAL_HERO_LEVEL, SpecialHeroLevel)

