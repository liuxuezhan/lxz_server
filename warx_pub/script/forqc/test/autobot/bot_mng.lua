local bot_mng = {}

-- all entities
bot_mng.entities = bot_mng.entities or {}

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

    _load("executor/attack_level_monster", "AttackLevelMonster")

    _load("workline", "Workline")
    -- task
    _load("task/task_manager", "TaskManager")
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
    -- recruit
    _load("recruit/recruit_manager", "RecruitManager")
    _load("recruit/recruit_idle", "RecruitIdle")
    _load("recruit/recruit_take_action", "RecruitTakeAction")
    _load("recruit/recruit_working", "RecruitWorking")
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
    _load("chore/chore_mail", "ChoreMail")
    _load("chore/chore_building", "ChoreBuilding")
    _load("chore/chore_union_help", "ChoreUnionHelp")
    _load("chore/chore_union_tech_donate", "ChoreUnionTechDonate")
    _load("chore/chore_union_buildlv_donate", "ChoreUnionBuildlvDonate")

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
    _load("labor/move_to_zone")

    c_roi_init()
    c_roi_set_block("common/mapBlockInfo.bytes")
end

local function _loadAllEntity(self)
    if not config.Autobot.EnableMassivePlayer then
        if nil ~= config.Autobot.MultiPlayerIdx then
            for _, idx in pairs(config.Autobot.MultiPlayerIdx) do
                local entity = Entity.createEntity(idx)
                table.insert(self.entities, entity)
            end
        else
            local entity = Entity.createEntity(config.Autobot.SinglePlayerIdx)
            table.insert(self.entities, entity)
        end
    else
        action(function()
            local pre_idx = config.Autobot.Massive_PreIdx
            local batch_count = config.Autobot.Massive_BatchCount
            local loop_count = config.Autobot.Massive_LoopCount
            local interval = config.Autobot.Massive_Interval
            WARN("[Autobot|BotMng] Start to load player [%d * 1000000 + %d * 1000 + %d|%d].",
                pre_idx,
                batch_count,
                loop_count,
                interval)
            for i = 1, batch_count do
                for j = 1, loop_count do
                    local idx = pre_idx * 1000000 + i * 1000 + j
                    local entity = Entity.createEntity(idx)
                    table.insert(self.entities, entity)
                    entity:start()
                end
                wait_for_time(interval)
            end
            WARN("[Autobot|BotMng] All player have been started.")
        end)
    end
end

local function _startAllEntity(self)
    for k, v in ipairs(self.entities) do
        v:start()
    end
end

function bot_mng:init(root_path)
    root_path_ = root_path
    _loadAllModule(self)

    TaskMng:init()
    _loadAllEntity(self)
    _startAllEntity(self)
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

return bot_mng

