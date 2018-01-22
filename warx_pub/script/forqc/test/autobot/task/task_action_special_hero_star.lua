local SpecialHeroStar = {}

function SpecialHeroStar:onStart()
    self.player.eventHeroUpdated:add(newFunctor(self, self._check))
end

function SpecialHeroStar:onStop()
    self.player.eventHeroUpdated:del(newFunctor(self, self._check))
end

function SpecialHeroStar:onProcess(task_data, heroid, star)
    self.heroid = heroid
    self.star = star

    self:_check()
end

function SpecialHeroStar:_check()
    if 0 ~= self.heroid then
        local hero = self.player:get_hero(self.heroid)
        if nil == hero then
            return
        end
        if self.star > hero.star then
            return
        end
        self:_finishTask()
    else
        for k, v in pairs(self.player._hero) do
            if v.star >= self.star then
                self:_finishTask()
                break
            end
        end
    end
end

return makeTaskActionHandler(TASK_ACTION.SPECIAL_HERO_STAR, SpecialHeroStar)

