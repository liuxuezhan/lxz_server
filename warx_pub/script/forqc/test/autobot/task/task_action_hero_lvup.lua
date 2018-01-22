local HeroLvup = {}

function HeroLvup:onStart()
    self.player.eventHeroUpdated:add(newFunctor(self, self._check))
end

function HeroLvup:onStop()
    self.player.eventHeroUpdated:del(newFunctor(self, self._check))
end

function HeroLvup:onProcess(task_data, level)
    self.level = level

    self:_check()
end

function HeroLvup:_check()
    for k, v in pairs(self.player._hero) do
        if v.lv >= self.level then
            self:_finishTask()
            return
        end
    end
end

return makeTaskActionHandler(TASK_ACTION.HERO_LEVEL_UP, HeroLvup)

