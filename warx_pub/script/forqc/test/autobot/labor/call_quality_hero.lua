local CallQualityHero = {}

local BREAK_TIME = 2

function CallQualityHero:onStart(player, quality, star, num)
    self.player = player
    self.quality = quality
    self.star = star
    self.num = num

    local count, upgradable_heroes = self:_check()
    if count >= num then
        return false
    end

    self.count = count
    self.rankup_labors = {}
    self.rankup_func = newFunctor(self, self._onRankup)
    for k, v in pairs(upgradable_heroes) do
        local labor = player.labor_manager:createLabor("RankupHero", self.rankup_func, player, player._hero[k].propid, star)
        table.insert(self.rankup_labors, labor)
    end

    -- TODO：召唤新英雄处理
    -- 1、搜寻当前可用于召唤新英雄的物品
    -- 2、监控物品变化

    return true
end

function CallQualityHero:onStop()
    local player = self.player
    for k, v in pairs(self.rankup_labors) do
        player.labor_manager:deleteLabor(v)
    end
    self.rankup_labors = nil
end

function CallQualityHero:_finish()
    self.player.labor_manager:deleteLabor(self)
end

function CallQualityHero:_check()
    local count = 0
    local upgradable_heroes = {}
    for k, v in pairs(self.player._hero or {}) do
        local prop = resmng.prop_hero_star_up[v.star]
        if self.quality <= v.quality then
            if self.star <= prop.StarStatus[1] then
                count = count + 1
            else
                table.insert(upgradable_heroes, k)
            end
        end
    end
    return count, upgradable_heroes
end

function CallQualityHero:_onRankup(labor)
    if nil == self.rankup_labors then
        return
    end
    if labor.success then
        self.count = self.count + 1
    end
    for k, v in pairs(self.rankup_labors) do
        if v == labor then
            table.remove(self.rankup_labors, k)
            break
        end
    end
    if self.count >= self.num then
        self:_finish(true)
    end
end

return makeLabor("CallQualityHero", CallQualityHero)

