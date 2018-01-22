local SupremeHeroLevel = {}

function SupremeHeroLevel:onStart()
    self.player.eventHeroUpdated:add(newFunctor(self, self._check))
end

function SupremeHeroLevel:onStop()
    self.player.eventHeroUpdated:del(newFunctor(self, self._check))
end

function SupremeHeroLevel:onProcess(task_data, level)
    self.level = level

    self:_check()
end

function SupremeHeroLevel:_check()
    local max_level = 0
    for k, v in pairs(self.player._hero) do
        for _, skill in pairs(v.basic_skill) do
            local prop = resmng.prop_skill[skill[1]]
            if nil ~= prop then
                if prop.Lv > max_level then
                    max_level = prop.Lv
                end
            end
        end
    end
    if max_level >= self.level then
        self:_finishTask()
    end
end

return makeTaskActionHandler(TASK_ACTION.SUPREME_HERO_LEVEL, SupremeHeroLevel)

