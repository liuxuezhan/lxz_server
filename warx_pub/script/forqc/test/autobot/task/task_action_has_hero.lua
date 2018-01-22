local HasHero = {}

function HasHero:onStart()
    self.player.eventHeroUpdated:add(newFunctor(self, self._check))
    self.player.eventNewHero:add(newFunctor(self, self._check))
end

function HasHero:onStop()
    self.player.eventHeroUpdated:del(newFunctor(self, self._check))
    self.player.eventNewHero:del(newFunctor(self, self._check))
end

function HasHero:onProcess(task_data, quality, star, num)
    self.quality = quality
    self.star = star
    self.num = num

    self:_check()
end

function HasHero:_check()
    local num = 0
    for k, v in pairs(self.player._hero) do
        if 0 == self.quality and 0 == self.star then
            num = num + 1
        elseif 0 == self.quality and 0 ~= self.star then
            local prop = resmng.prop_hero_star_up[v.star]
            if self.star <= prop.StarStatus[1] then
                num = num + 1
            end
        elseif 0 ~= self.quality and 0 == self.star then
            if self.quality <= v.quality then
                num = num + 1
            end
        elseif 0 ~= self.quality and 0 ~= self.star then
            if self.quality <= v.quality and self.star <= v.star then
                num = num + 1
            end
        end
    end
    if num >= self.num then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.HAS_HERO_NUM, HasHero)

