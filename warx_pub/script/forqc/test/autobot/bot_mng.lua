local bot_mng = {}

-- all entities
bot_mng.entities = bot_mng.entities or {}
bot_mng.entity_count = 0

local root_path_ = nil
local function _load(module_name, name)
    local source = string.format("%s/%s", root_path_, module_name)
    if nil ~= name then
        doLoadMod(name, source)
    else
        do_load(source)
    end
end

local function _loadAllModule(self)
    -- load aux first
    if config.Autobot.Debugger then
        require("frame/debugger") 
    end
    _load("auxiliary/fsm")
    _load("auxiliary/object_creator")
    _load("auxiliary/tools")
    _load("auxiliary/task_mng", "TaskMng")
    _load("auxiliary/autobot_timer", "AutobotTimer")
    _load("auxiliary/autobot", "Autobot")
    _load("state_machine", "StateMachine")

    _load("entity", "Entity")
    _load("bot", "Bot")
    _load("bot_stand_by", "BotStandBy")
    _load("bot_login", "BotLogin")
    _load("bot_game", "BotGame")

    _load("shuttle/shuttle", Shuttle)
    _load("shuttle/solo_shuttle")
    _load("shuttle/multi_player_shuttle")
    _load("shuttle/massive_player_shuttle")
    _load("shuttle/endless_rush_shuttle")
    _load("shuttle/continuous_rush_shuttle")
    _load("shuttle/ephemera_rush_shuttle")

    _load("executor/attack_level_monster", "AttackLevelMonster")

    _load("workline", "Workline")
    -- task
    _load("task/task_manager", "TaskManager")
    _load("task/task_action_manager", "TaskActionManager")
    _load("task/task_action_city_build_lvup")
    _load("task/task_action_study_tech")
    _load("task/task_action_open_res_build")
    _load("task/task_action_hero_lvup")
    _load("task/task_action_learn_hero_skill")
    _load("task/task_action_has_hero")
    _load("task/task_action_supreme_hero_level")
    _load("task/task_action_get_equip")
    _load("task/task_action_join_union")
    _load("task/task_action_special_hero_level")
    _load("task/task_action_special_hero_star")
    _load("task/task_action_res_output")
    _load("task/task_action_role_level_up")
    _load("task/task_action_finish_daily_task")
    _load("task/task_action_lord_rename")
    _load("task/task_action_get_item")
    -- build queue
    _load("build_queue/build_manager", "BuildManager")
    _load("build_queue/build_queue_machine", "BuildQueueMachine")
    _load("build_queue/build_queue_idle", "BuildQueueIdle")
    _load("build_queue/build_queue_working", "BuildQueueWorking")
    _load("build_queue/build_queue_accelerate", "BuildQueueAccelerate")
    -- troop
    _load("troop/troop_manager", "TroopManager")
    _load("troop/troop_idle", "TroopIdle")
    _load("troop/troop_take_action", "TroopTakeAction")
    _load("troop/troop_wait", "TroopWait")
    _load("troop/troop_rest", "TroopRest")
    _load("troop/troop_deactive", "TroopDeactive")
    _load("troop/action/siege_action", "SiegeAction")
    _load("troop/action/siege_monster", "SiegeMonster")
    _load("troop/action/siege_task_npc", "SiegeTaskNpc")
    _load("troop/action/siege_task_player", "SiegeTaskPlayer")
    _load("troop/action/union_build", "UnionBuild")
    -- recruit
    _load("recruit/recruit_manager", "RecruitManager")
    _load("recruit/recruit_idle", "RecruitIdle")
    _load("recruit/recruit_take_action", "RecruitTakeAction")
    _load("recruit/recruit_working", "RecruitWorking")
    _load("recruit/recruit_rest", "RecruitRest")
    -- tech
    _load("tech/tech_manager", "TechManager")
    _load("tech/tech_idle", "TechIdle")
    _load("tech/tech_take_action", "TechTakeAction")
    _load("tech/tech_studying", "TechStudying")
    -- union
    _load("union/union_help_manager", "UnionHelpManager")
    _load("union/union_manager", "UnionManager")
    _load("union/union", "Union")
    -- chore
    _load("chore/chore", "Chore")
    _load("chore/chore_reap", "ChoreReap")
    _load("chore/chore_gacha", "ChoreGacha")
    _load("chore/chore_day_award", "ChoreDayAward")
    _load("chore/chore_ache_reward", "ChoreAcheReward")
    _load("chore/chore_target_award", "ChoreTargetAward")
    _load("chore/chore_activity_box", "ChoreActivityBox")
    _load("chore/chore_cure", "ChoreCure")
    _load("chore/chore_recruit", "ChoreRecruit")
    _load("chore/chore_mail", "ChoreMail")
    _load("chore/chore_building", "ChoreBuilding")
    _load("chore/chore_union_help", "ChoreUnionHelp")
    _load("chore/chore_union_tech_donate", "ChoreUnionTechDonate")
    _load("chore/chore_union_buildlv_donate", "ChoreUnionBuildlvDonate")
    _load("chore/chore_union_build", "ChoreUnionBuild")
    _load("chore/chore_lv_gift", "ChoreLevelGift")

    -- scavenger
    _load("scavenger/scavenger_tech", "ScavengerTech")
    _load("scavenger/scavenger_task", "ScavengerTask")
    _load("scavenger/scavenger_monster_rest", "ScavengerMonsterRest")
    _load("scavenger/scavenger_monster_take_action", "ScavengerMonsterTakeAction")
    _load("scavenger/scavenger_monster_recover", "ScavengerMonsterRecover")

    -- labor
    _load("labor/labor_manager", "LaborManager")
    _load("labor/union/join_union")
    _load("labor/union/join_union_get_unions", "JoinUnion_GetUnions")
    _load("labor/union/join_union_apply_union", "JoinUnion_ApplyUnion")
    _load("labor/union/join_union_create_union", "JoinUnion_CreateUnion")
    _load("labor/union/join_union_accomplish", "JoinUnion_Accomplish")
    _load("labor/levelup_hero")
    _load("labor/rankup_hero")
    _load("labor/learn_hero_skill")
    _load("labor/level_up_hero_skill")
    _load("labor/call_hero")
    _load("labor/call_quality_hero")
    _load("labor/move_to_zone")
    _load("labor/migrate_to_pos")
    _load("labor/visit_npc")

    c_roi_init()
    c_roi_set_block("common/mapBlockInfo.bytes")
end

function bot_mng:init(root_path)
    root_path_ = root_path
    _loadAllModule(self)
    self.eventPlayerOnline = newEventHandler()
    self.eventPlayerOffline = newEventHandler()

    TaskMng:init()
    self:_loadShuttle()
    self:_startShuttle()
end

function bot_mng:run()
    while true do
        TaskMng:update()
        Bot.updateState()
        wait_for_time(1)
    end
end

function bot_mng:uninit()
    TaskMng:uninit()
end

function bot_mng:_loadShuttle()
    local shuttle_name = config.Autobot.ShuttleName or "MassivePlayer"
    self.shuttle = createShuttle(shuttle_name, self)
    assert(self.shuttle, "Shuttle can't be created")
end

function bot_mng:_startShuttle()
    self.shuttle:start()
end

function bot_mng:addEntity(entity)
    local idx = entity.idx
    if nil ~= self.entities[idx] then
        ERROR("[Autobot|BotMng] Try to add a exist entity %d", idx)
        return
    end
    self.entities[idx] = entity
    self.entity_count = self.entity_count + 1
end

function bot_mng:delEntity(entity)
    local idx = entity.idx
    self.entities[idx] = nil
    self.entity_count = self.entity_count - 1
    entity:stop()
end

function bot_mng:getEntity(idx)
    return self.entities[idx]
end

function bot_mng:getEntityCount()
    return self.entity_count
end

return bot_mng

