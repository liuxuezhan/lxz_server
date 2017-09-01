local ScavengerTask = {}
local executing_interval = 2
local task_action = {}

function ScavengerTask:onInit()
    local player = self.host.player
    self.executors = {}
end

function ScavengerTask:onEnter()
    self.last_execute_time = gTime
    self.periodic_id = AutobotTimer:addPeriodicTimer(newFunctor(self, ScavengerTask._processTask), executing_interval)
end

local function _executeTask(self, task, func, ...)
    local key = g_task_func_relation[func]
    if nil ~= task_action[key] then
        task_action[key](self, task, ...)
    else
        INFO("[Autobot|ScavengerTask|%d] Not implemented task %s!!!!!!!!!!!!!!!!!!!!!!!!!!!!", self.host.player.pid, func)
    end
end

function ScavengerTask:delExecutor(executor)
    for k, v in ipairs(self.executors) do
        if v == executor then
            table.remove(self.executors, k)
            return
        end
    end
end

local _prop_map = {
    [TASK_TYPE.TASK_TYPE_TRUNK] = resmng.prop_task_detail,
    [TASK_TYPE.TASK_TYPE_BRANCH] = resmng.prop_task_detail,
    [TASK_TYPE.TASK_TYPE_DAILY] = resmng.prop_task_daily,
    [TASK_TYPE.TASK_TYPE_TARGET] = resmng.prop_task_detail,
    [TASK_TYPE.TASK_TYPE_HEROROAD] = resmng.prop_task_detail,
}

local TASK_PRIORITY = {
    [TASK_TYPE.TASK_TYPE_TRUNK] = 10000,
    [TASK_TYPE.TASK_TYPE_BRANCH] = 8000,
    [TASK_TYPE.TASK_TYPE_DAILY] = 4000,
    [TASK_TYPE.TASK_TYPE_TARGET] = 500,
    [TASK_TYPE.TASK_TYPE_HEROROAD] = 6000,
}

local function _getTaskProp(task)
    return _prop_map[task.task_type][task.task_id]
end

local function _getTaskPriority(task)
    return TASK_PRIORITY[task.task_type]
end

local function _handleTask(self, task)
    local task_id = task.task_id
    _executeTask(self, task, unpack(_prop_map[task.task_type][task_id].FinishCondition))
end

function ScavengerTask:onUpdate()
    local player = self.host.player
    if gTime < self.last_execute_time + executing_interval then
        return
    end
    self.last_execute_time = gTime
    _processTask()
end

function ScavengerTask:_processTask()
    local player = self.host.player
    local task = player.task_manager:fetchPendingTask()
    if nil == task then
        return
    end

    --INFO("[Autobot|ScavengerTask|%d] Got a  pending task: %d|%d", player.pid, task.task_id, self.host:getPendingTaskCount())
    if task.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
        INFO("[Autobot|ScavengerTask|%d]handle task %d", player.pid, task.task_id)
        _handleTask(self, task)
    elseif task.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
        INFO("[Autobot|ScavengerTask|%d]Finish task %d", player.pid, task.task_id)
        Rpc:finish_task(player, task.task_id)
    --elseif new_data.task_status == TASK_STATUS.TASK_STATUS_UPDATE then
    end
end

function ScavengerTask:onExit()
    AutobotTimer:delPeriodicTimer(self.periodic_id)
end

-- 打开UI
task_action[TASK_ACTION.OPEN_UI] = function(self, task, ui_id)
    Rpc:finish_open_ui(self.host.player, ui_id)
end

-- 签到
task_action[TASK_ACTION.MONTH_AWARD] = function(self, task, num)
    Rpc:month_award_get_award(self.host.player)
end

-- 开启野地
task_action[TASK_ACTION.OPEN_RES_BUILD] = function(self, task, con_pos)
    -- TODO: 检查条件，若不满足则需要根据前续条件创建相关任务并监听相关事件以最后完成任务
    Rpc:open_field(self.host.player, self.host.player.field + 1)
end

-- 攻击特殊怪物
task_action[TASK_ACTION.ATTACK_SPECIAL_MONSTER] = function(self, task, monster_id)
    local action = {}
    action.name = "AttackSpecialMonster"
    action.params = {task.task_id, monster_id}
    self.host.player.troop_manager:requestTroop(action, _getTaskPriority(task))
end

task_action[TASK_ACTION.SPY_SPECIAL_PLY] = function(self, task, con_id)
    local player = self.host.player
    local x = player.x + math.random(5, 10)
    local y = player.y + math.random(5, 10)
    Rpc:spy_task_ply(player, task.task_id, player.eid, x, y)
end

task_action[TASK_ACTION.ATTACK_SPECIAL_PLY] = function(self, task, monster_id)
    local action = {}
    action.name = "AttackSpecialPlayer"
    action.params = {task.task_id, monster_id}
    self.host.player.troop_manager:requestTroop(action, _getTaskPriority(task)) 
end

task_action[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(self, task, con_type, con_level, con_num)
    local action = {}
    action.name = "AttackLevelMonster"
    action.params = {con_type, con_level}
    self.host.player.troop_manager:requestTroop(action, _getTaskPriority(task))
end

-- 招募士兵
task_action[TASK_ACTION.RECRUIT_SOLDIER] = function(self, task, con_type, con_level, con_num, con_acc)
    if con_level == 0 then
        con_level = 1
    end
    if con_type == 0 then
        con_type = 1
    end
    --self.host.player.recruit_manager:addRecruitJob(con_type, con_level, con_num, 10000, 1 == con_acc)
    self.host.player.recruit_manager:addRecruitJob(con_type, con_level, con_num, _getTaskPriority(task), true)
end

-- 城建
task_action[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(self, task, con_type, con_num, con_level)
    local cur_num = 0
    local cur_level = 0
    local idx = 0
    local propid = 0
    for k, v in pairs(self.host.player._build or {}) do
        local prop = resmng.prop_build[v.propid]
        if nil == prop then
            INFO("[Autobot|ScavengerTask|%d] The building %d prop isn't found", self.host.player.pid, v.propid)
            return
        end
        local cur_type = con_type
        if 15 == con_type or 20 == con_type then
            if 15 == prop.Specific or 20 == prop.Specific then
                cur_type = prop.Specific
            end
        end

        if cur_type == prop.Specific then
            if prop.Lv > cur_level then
                cur_level = prop.Lv
            end
            if prop.Lv >= con_level then
                cur_num = cur_num + 1
            else
                idx = k
                propid = v.propid
            end
        end
    end

    if con_num > cur_num then
        local propid = con_type * 1000 + con_level
        self.host.player.build_manager:addBuilding(propid, _getTaskPriority(task), con_num)
    end
end

-- 收取资源
task_action[TASK_ACTION.GET_RES] = function(self, task, con_type)
    local build = get_build(self.host.player, 1, con_type - 4)
    Rpc:reap(self.host.player, build.idx)
end

-- 飞艇资源（居然不用先修建筑）
task_action[TASK_ACTION.DAY_AWARD] = function(self, task, con_num)
    Rpc:require_online_award(self.host.player)
end

-- 抽卡
task_action[TASK_ACTION.GACHA_MUB] = function(self, task, con_num)
    self.host.player.gacha_num = self.host.player.gacha_num or 0
    local prop = _getTaskProp(task)
    if not prop then
        return
    end
    if 1 == con_type then
        if self.host.player.gacha_num < con_num then
            Rpc:do_gacha(self.host.player, 1)
            self.host.player.gacha_num = self.host.player.gacha_num + 1
        end
    else
        if self.host.player.gacha_num < con_num then
            Rpc:do_gacha(self.host.player, 3)
            self.host.player.gacha_num = self.host.player.gacha_num + 1
        end
    end
end

-- 科技升级
task_action[TASK_ACTION.STUDY_TECH] = function(self, task, con_id, con_level)
    self.host.player.tech_manager:addStudyJob(con_id, _getTaskPriority(task))
end

task_action[TASK_ACTION.VISIT_HERO] = function(self, task)
    local armys = {}
    Rpc:task_visit(self.host.player, task.task_id, 0, self.host.player.x + 10, self.host.player.y + 10, {live_soldier = armys})
end

task_action[TASK_ACTION.HERO_LEVEL_UP] = function(self, task, level)
    local prop = _getTaskProp(task)
    if nil == prop then
        return
    end
    local hero = get_born_hero(self.host.player)
    --for k, v in pairs(self.host.player._hero or {}) do
    --    hero = v
    --    break
    --end
    if nil == hero then
        INFO("[Autobot|TaskAction|HeroLvUp|%d] no hero found", self.host.player.pid)
        return
    end
    action(hero_lv_up, self.host.player, hero, level)
end

task_action[TASK_ACTION.GET_TASK_ITEM] = function(self, task, con_id, con_num)
    local prop = resmng.prop_item[con_id]
    if not prop then
        return
    end
    local mode, lv = unpack(prop.Param or {})
    task_action[TASK_ACTION.ATTACK_LEVEL_MONSTER](self, task, mode, lv)
end

task_action[TASK_ACTION.LEARN_HERO_SKILL] = function(self, task, con_pos)
    local hero = get_born_hero(self.host.player)
    --for k, v in pairs(self.host.player._hero or {}) do
    --    hero = v
    --    break
    --end
    if nil == hero then
        return
    end
    local player = self.host.player
    --[[
    for k, v in pairs(player._item or{}) do
        local prop = resmng.prop_item[ v[2] ]
        if ITEM_CLASS.SKILL == prop.Class then
            INFO("[Autobot|TaskAction|LearnHeroSkill|%d]\t\titem %d", self.host.player.pid, v[2])
        end
    end
    --]]
    local item_list =
    {
        5001101,
        5001102,
        5001103,
        5001104,
        5001105,
        5001106,
    }
    for i = 1, con_pos do
        --hero_star_up(player, hero, i)
        --use_hero_skill_item(player, hero, item_list[i], 1, i)
        local item = get_item(player, item_list[i])
        if item then
            Rpc:use_hero_skill_item(player, hero.idx, i, item[1], 1)
        else
            INFO("[Autobot|TaskAction|LearnHeroSkill|%d] no item  %d", player.pid, item_list[i])
        end
    end
end

local function _getHeroBigStarProp(big_star)
    for k, v in pairs(resmng.prop_hero_star_up) do
        if big_star == v.StarStatus[1] and 0 == v.StarStatus[2] then
            return k, v
        end
    end
end

local function _upgradeHeroStar(player, hero, star)
    local target_star, target_prop = _getHeroBigStarProp(star)

    local basic_prop = resmng.prop_hero_basic[hero.propid]

    local item_id = basic_prop.PieceID
    local item_num = 0
    for i = hero.star + 1, target_star do
        local prop = resmng.prop_hero_star_up[i]
        item_num = item_num + prop.StarUpPrice
    end
    local item = get_item(player, item_id)
    if nil == item or item[3] < item_num then
        return
    end
    for i = hero.star + 1, target_star do
        Rpc:hero_star_up(player, hero.idx)
    end
    return true
end

task_action[TASK_ACTION.HAS_HERO_NUM] = function(self, task, con_quality, con_star, con_num)
    local real_num = 0
    local quality_num = 0
    local heroes = {}
    for k, v in pairs(self.host.player._hero or {}) do
        local star_prop = resmng.prop_hero_star_up[v.star]
        if con_quality <= v.quality then
            -- 只有品质满足才需要升星级
            quality_num = quality_num + 1
            if con_star <= star_prop.StarStatus[1] then
                real_num = real_num + 1
            else
                heroes[k] = v
            end
        end
    end
    if real_num >= con_num then
        return
    end
    if quality_num < con_num then
        -- TODO: 品质英雄数量不足，需要启动获取英雄流程
        INFO("[Autobot|TaskAction|HasHeroNum|%d] lack of quality hero %d|%d.", con_quality, con_num - quality_num)
        return
    end
    local remain_count = con_num - real_num
    for k, v in pairs(heroes) do
        if _upgradeHeroStar(self.host.player, v, con_star) then
            INFO("[Autobot|TaskAction|HasHeroNum|%d] star up hero %d from %d to %d.",
            self.host.player.pid,
            v.propid,
            v.star,
            _getHeroBigStarProp(con_star))
            remain_count = remain_count - 1
        end
        if 0 == remain_count then
            break
        end
    end
end

task_action[TASK_ACTION.MOVE_TO_ZONE] = function(self, task, con_lv)
    self.host.player.labor_manager:createLabor("MoveToZone", nil, self.host.player, con_lv)
end

task_action[TASK_ACTION.JOIN_PLAYER_UNION] = function(self, task)
    local labor = self.host.player.labor_manager:createLabor("JoinUnion", nil, self.host.player)
end

task_action[TASK_ACTION.SPECIAL_HERO_LEVEL] = function(self, task, con_id, con_lv)
    self.host.player.labor_manager:createLabor("LevelupHero", nil, self.host.player, con_id, con_lv)
end

task_action[TASK_ACTION.UNION_TECH_DONATE] = function(self, task, con_num, con_acc)
    -- 该任务由ChoreUnionTechDonate自动完成，该处暂时无需处理
end

local function _isBuyableRes(id, castle_lv)
    if id == 3 then
        return castle_lv >= 10
    elseif id == 4 then
        return castle_lv >= 15
    else
        return true
    end
end

task_action[TASK_ACTION.MARKET_BUY_NUM] = function(self, task, con_type, con_num)
    local player = self.host.player
    if 1 == con_type then
        -- 黑市
    elseif 2 == con_type then
        -- 物资市场
        local market = get_build(player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.RESOURCESMARKET)
        local castle_lv = player:get_castle_lv()
        if nil ~= market then
            local id
            local buy_count = math.huge
            local combo = 0
            for k, v in pairs(market.extra) do
                if _isBuyableRes(v[1], castle_lv) then
                    if v[3] < buy_count then
                        id = v[1]
                        buy_count = v[3]
                        combo = v[4]
                    elseif v[3] == buy_count then
                        if v[4] > combo then
                            id = v[1]
                            combo = v[4]
                        end
                    end
                end
            end
            INFO("[Autobot|ScavengerTask|%d] buy res %d", player.pid, id)
            Rpc:buy_res(self.host.player, id)
        end
    end
end

return makeState(ScavengerTask)

