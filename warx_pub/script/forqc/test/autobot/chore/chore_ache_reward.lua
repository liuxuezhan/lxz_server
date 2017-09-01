local ChoreAcheReward = {}

local CLAIM_INTERVAL = config.Autobot.ClaimAchievementInterval or 2

function ChoreAcheReward:init(player)
    self.player = player
    self.eventAcquireAchievement = newEventHandler()
    self.eventClaimedAchievement = newEventHandler()

    player.eventAcheUpdated:add(newFunctor(self, self._onAcheUpdated))
    player.eventDisplayNotify:add(newFunctor(self, self._onDisplayNotify))

    self:_initAches()
    self:_start()
end

function ChoreAcheReward:uninit()
    self.player.eventAcheUpdated:del(newFunctor(self, self._onAcheUpdated))
    self.player.eventDisplayNotify:del(newFunctor(self, self._onDisplayNotify))
    self:_stop()
end

local achievement_func = {}

achievement_func.count = function(player, id, param)
    return player._ache.count[id] or 0
end

achievement_func.castle_lv = function(player, id, param)
    return player:get_castle_lv()
end

achievement_func.player_lv = function(player, id, param)
    return player.lv
end

achievement_func.count_equip = function(player, id, param)
    local count = 0
    local props = resmng.prop_equip
    for k, v in pairs(player._equip or {}) do
        if props[v.propid].Class >= param then
            count = count + 1
        end
    end
    return count
end

achievement_func.count_hero = function(player, id, param)
    local count = 0
    for k, v in pairs(player._hero or{}) do
        count = count + 1
    end
    return count
end

achievement_func.count_hero_quality = function(player, id, param)
    local count = 0
    local props = resmng.prop_hero_basic
    for k, v in pairs(player._hero or{}) do
        if props[v.propid].Quality >= param then
            count = count + 1
        end
    end
    return count
end

achievement_func.count_hero_lv = function(player, id, param)
    local count = 0
    for k, v in pairs(player._hero or{}) do
        if v.lv >= param then
            count = count + 1
        end
    end
    return count
end

achievement_func.count_hero_skill = function(player, id, param)
    local count = 0
    for k, v in pairs(player._hero or{}) do
        local num = 0
        for _, skill in pairs(v.basic_skill) do
            if skill[1] > 0 then
                num = num + 1
            end
        end
        if num >= param then
            count = count + 1
        end
    end
    return count
end

achievement_func.count_hero_star = function(player, id, param)
    local count = 0
    local props = resmng.prop_hero_star_up
    for k, v in pairs(player._hero or{}) do
        local prop = props[v.star]
        if prop then
            if prop.StarStatus[1] >= param then
                count = count + 1
            end
        end
    end
    return count
end

function ChoreAcheReward:_initAches()
    local claimable_ache = {}
    local ache = self.player._ache.ache
    local count = self.player._ache.count
    local ache_count = 0
    for k, v in pairs(resmng.prop_achievement) do
        if not ache[k] then
            local var = v.Var
            local var_prop = resmng.prop_achievement_var[var]
            local func = achievement_func[var_prop.Way]
            local real_count = func(self.player, var, var_prop.Param)
            if real_count >= v.Count then
                claimable_ache[k] = true
                ache_count = ache_count + 1
            else
            end
        end
    end
    self.claimable_ache = claimable_ache
    INFO("[Autobot|AchievementReward|%d] I have %d unclaimed achievements", self.player.pid, ache_count)
end

function ChoreAcheReward:_onAcheUpdated(player, idx, time)
    self.claimable_ache[idx] = nil
    self.eventClaimedAchievement(idx)
end

function ChoreAcheReward:_onDisplayNotify(player, pack)
    if pack.mode ~= DISPLY_MODE.ACHEVEMENT then
        return
    end
    if nil == pack.ache_id then
        return
    end
    self.claimable_ache[pack.ache_id] = true
    self.eventAcquireAchievement(pack.ache_id)
end

function ChoreAcheReward:_claimAchievement()
    local idx = next(self.claimable_ache)
    if nil == idx then
        return
    end
    INFO("[Autobot|AchievementReward|%d] Try to claim achievement %d", self.player.pid, idx)
    Rpc:get_ache_reward(self.player, idx)
    return idx
end

local Watching = makeState({})
function Watching:onEnter()
    self.host.eventAcquireAchievement:add(newFunctor(self, self._onNewAchievement))
end

function Watching:onExit()
    self.host.eventAcquireAchievement:del(newFunctor(self, self._onNewAchievement))
end

function Watching:_onNewAchievement()
    self:translate("Claim")
end

local Claim = makeState({})
function Claim:onInit()
    self.timer_func = newFunctor(self, self._claimAchievement)
    self.claimed_func = newFunctor(self, self._onClaimedAchievement)
end

function Claim:onEnter()
    self.timer_id = AutobotTimer:addTimer(self.timer_func, CLAIM_INTERVAL)
    self.host.eventClaimedAchievement:add(self.claimed_func)
end

function Claim:onExit()
    self.host.eventClaimedAchievement:del(self.claimed_func)
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

function Claim:_claimAchievement()
    local idx = self.host:_claimAchievement()
    if nil == idx then
        INFO("[Autobot|AchievementReward|%d] all achievement has been claimed", self.host.player.pid)
        self:translate("Watching")
        return
    end
end

function Claim:_onClaimedAchievement(idx)
    INFO("[Autobot|AchievementReward|%d] Achievement %d has been claimed", self.host.player.pid, idx)
    self.timer_id = AutobotTimer:addTimer(self.timer_func, CLAIM_INTERVAL)
end

function ChoreAcheReward:_start()
    local have_achievement = (nil ~= next(self.claimable_ache))
    local runner = StateMachine:createInstance(self)
    runner:addState("Watching", Watching, not have_achievement)
    runner:addState("Claim", Claim, have_achievement)

    self.runner = runner
    runner:start()
end

function ChoreAcheReward:_stop()
    if nil ~= self.runner then
        self.runner:stop()
        self.runner = nil
    end
end

return makeChoreClass("AcheReward", ChoreAcheReward)

