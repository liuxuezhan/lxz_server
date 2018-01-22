local LearnHeroSkill = {}

function LearnHeroSkill:onStart()
    self.player.eventHeroUpdated:add(newFunctor(self, self._onHeroUpdated))
end

function LearnHeroSkill:onStop()
    self.player.eventHeroUpdated:del(newFunctor(self, self._onHeroUpdated))
end

function LearnHeroSkill:onProcess(task_data, pos)
    self.pos = pos

    self:_check()
end

function LearnHeroSkill:_check()
    if 0 == self.pos then
        for k, v in pairs(self.player._hero) do
            for _, skill in pairs(v.basic_skill or {}) do
                if nil ~= skill and skill[1] > 0 then
                    self:_finishTask()
                    return
                end
            end
        end
    else
        for k, v in pairs(self.player._hero) do
            local skill = v.basic_skill[self.pos]
            if nil ~= skill and skill[1] > 0 then
                self:_finishTask()
                return
            end
        end
    end
end

function LearnHeroSkill:_onHeroUpdated(player, hero)
    self:_check()
end

return makeTaskActionHandler(TASK_ACTION.LEARN_HERO_SKILL, LearnHeroSkill)

