module("task_logic_t", package.seeall)

--[[
local task_info = {}
task_info.task_id = 0
task_info.task_status = TASK_STATUS.TASK_STATUS_INVALID
task_info.task_type = TASK_TYPE.TASK_TYPE_INVALID
task_info.task_action = TASK_ACTION.INVALID
task_info.task_current = 0
task_info.task_daily_num = 0
--]]

function process_task(player, task_action, ...)
    if player == nil then
        return
    end
    local st = c_msec()
    local task_data_array = player:get_task_by_action(task_action)
    for k, v in pairs(task_data_array or {}) do
        if v.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            local task_info = nil
            if v.task_type == TASK_TYPE.TASK_TYPE_DAILY then
                task_info = resmng.prop_task_daily[v.task_id]
            else
                task_info = resmng.prop_task_detail[v.task_id]
            end
            if task_info ~= nil then
                local con_tab = copyTab(task_info.FinishCondition)
                for i, j in pairs({...}) do
                    table.insert(con_tab, j)
                end
                local res = distribute_operation(player, v, unpack(con_tab))
                if res == true then
                    player:add_save_task_id(v.task_id)
                end
            end
        end
    end
    player:do_save_task()
    LOG("taskstatics:process action:"..task_action.." time:"..(c_msec()-st))
end



function distribute_operation(player, task_data, func, ...)
    local key = g_task_func_relation[func]
    if do_task[key] ~= nil then
        return do_task[key](player, task_data, ...)
    end
end

function add_task_process(player, task_data, con_num, num)
    task_data.task_current_num = task_data.task_current_num + num
    if task_data.task_current_num >= con_num then
        --如果是日常任务判断不一样
        if task_data.task_type == TASK_TYPE.TASK_TYPE_DAILY then
            local limit = resmng.prop_task_daily[task_data.task_id].FinishNum
            for i = task_data.task_daily_num, limit, 1 do
                if task_data.task_current_num >= con_num then
                    task_data.task_current_num = task_data.task_current_num - con_num
                    task_data.task_daily_num = task_data.task_daily_num + 1
                    player:add_activity(task_data.task_id)
                end
                if task_data.task_daily_num >= limit then
                    task_data.task_current_num = con_num
                    task_data.task_daily_num = limit
                    task_data.task_status = TASK_STATUS.TASK_STATUS_FINISHED
                    break
                end
            end
        else
            task_data.task_current_num = con_num
            task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
        end
    end
end

function update_get_task_item_process(task_data, con_num, num)
    task_data.task_current_num = num
    if task_data.task_current_num >= con_num then
        task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
        return true
    end
    return false
end

function update_task_process(task_data, con_num, num)
    local need_save = false
    if task_data.task_current_num < num then
        task_data.task_current_num = num
        need_save = true
    end
    if task_data.task_current_num >= con_num then
        task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
        need_save = true
    end
    return need_save
end

function task_warning(func_name)
    if func_name == nil then
        return true
    else
        WARN("task:%s logic is null", func_name)
        return false
    end
end

------------------------------------------------------------------------------------
------以下是任务具体逻辑
------------------------------------------------------------------------------------

do_task = {}

--攻击特定ID的怪物
do_task[TASK_ACTION.ATTACK_SPECIAL_MONSTER] = function(player, task_data, con_mid, real_mid, real_hp, real_eid)
    if real_mid == nil or real_hp == nil then
        return false
    end

    if con_mid ~= real_mid then
        return false
    end
    task_data.monster_eid = real_eid
    task_data.hp = real_hp
    if task_data.hp <= 0 then
        task_data.task_current_num = 1
        task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
        Rpc:rm_npc_monster(player, real_eid)
    end
    return true
end

--攻击特定ID的fake ply
do_task[TASK_ACTION.ATTACK_SPECIAL_PLY] = function(player, task_data, con_id, con_num, real_id, num)
    if real_id == nil then
        return false
    end

    if con_id ~= real_id then
        return false
    end
    Rpc:rm_fake_ply(player, real_id)
    task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    return true
end

--侦查特定ID的fake ply
do_task[TASK_ACTION.SPY_SPECIAL_PLY] = function(player, task_data, con_id, con_num, real_id, num)
    if real_id == nil then
        return false
    end

    if con_id ~= real_id then
        return false
    end
    task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    return true
end

--攻击等级怪物
do_task[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(player, task_data, con_type, con_level, con_num, real_mid, real_num)
    local function get_type(mode)
        if mode <= 30 then --普通
            return 1
        elseif mode > 30 and mode <= 40 then --精英
            return 2
        elseif mode > 40 and mode <= 50 then --首领
            return 3
        elseif mode > 50 and mode <= 100 then --超级首领
            return 4
        else -- 任务
            return 5
        end
    end

    if real_mid == nil or real_num == nil then
        return false
    end

    local monster_info = resmng.prop_world_unit[real_mid]
    if monster_info == nil then
        return false
    end
    local real_type = get_type(monster_info.Mode)
    local real_level = monster_info.Clv
    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    if con_level ~= 0 and con_level ~= real_level then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--单场战斗进行联动
do_task[TASK_ACTION.BATTLE_LIANDONG] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--单场战斗战损比
do_task[TASK_ACTION.BATTLE_DAMAGE] = function(player, task_data, con_ratio, real_ratio)
    if real_ratio == nil then
        return false
    end

    if real_ratio > con_ratio then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--侦查玩家城堡
do_task[TASK_ACTION.SPY_PLAYER_CITY] = function(player, task_data, con_num, con_acc, real_num)
    if con_acc == 1 then
        local cur = player:get_count(resmng.ACH_TASK_SPY_PLAYER)
        return update_task_process(task_data, con_num, cur)
    end
    if real_num == nil or real_num == 0 then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--单次行军加速减少时间
do_task[TASK_ACTION.SLOW_SPEED] = function(player, task_data, con_time, real_time)
    if real_time == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.SLOW_SPEED]") == false then
        add_task_process(player, task_data, 1, 1)
    end
    --------------
    if con_time > real_time then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return false
end

--攻击玩家城堡
do_task[TASK_ACTION.ATTACK_PLAYER_CITY] = function(player, task_data, con_num, con_win, con_acc, real_num, real_win)
    if con_acc == 1 then
        local cur = 0
        if con_win == 0 then
            cur = player:get_count(resmng.ACH_TASK_ATK_PLAYER_WIN) + player:get_count(resmng.ACH_TASK_ATK_PLAYER_FAIL)
        else
            cur = player:get_count(resmng.ACH_TASK_ATK_PLAYER_WIN)
        end

        return update_task_process(task_data, con_num, cur)
    end

    if real_num == nil or real_win == nil then
        return false
    end

    if con_win ~= 0 and con_win ~= real_win then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--抢夺资源数量
do_task[TASK_ACTION.LOOT_RES] = function(player, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        local ach_index = "ACH_TASK_ATK_RES"..con_type
        local cur = player:get_count(resmng[ach_index])
        return update_task_process(task_data, con_num, cur)
    end

    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--侦查系统城市
do_task[TASK_ACTION.SPY_NPC_CITY] = function(player, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--攻击系统城市
do_task[TASK_ACTION.ATTACK_NPC_CITY] = function(player, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        local cur = 0
        if con_type == 0 then
            for i = 1, 5, 1 do
                cur = cur + player:get_count(resmng["ACH_TASK_ATK_NPC"..i])
            end
        else
            cur = player:get_count(resmng["ACH_TASK_ATK_NPC"..con_type])
        end
        return update_task_process(task_data, con_num, cur)
    end
    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--占领系统城市
do_task[TASK_ACTION.OCC_NPC_CITY] = function(player, task_data, con_type, real_type)
    local union = unionmng.get_union(player:get_uid())
    if union == nil then
        return false
    end
    local valid = false
    local city_type = nil
    for k, v in pairs(union.npc_citys) do
        local city = get_ety(v)
        if city then
            local prop_build = resmng.get_conf("prop_world_unit", city.propid)
            if prop_build ~= nil and prop_build.Class == 3 then
                city_type = prop_build.Lv
            elseif prop_build ~= nil and prop_build.Class == 4 and prop_build.Mode == 1 and prop_build.Lv == 1 then
                city_type = 5
            end
            if con_type == city_type then
                valid = true
            end
        end
    end

    local king = king_city.get_king()
    if king and king.uid == union.uid then
        city_type = 5
        if con_type == city_type then
            valid = true
        end
    end

    if valid == true then
        add_task_process(player, task_data, 1, 1)
        return true
    else
        return false
    end
end

--持有英雄数量
do_task[TASK_ACTION.HAS_HERO_NUM] = function(player, task_data, con_quality, con_star, con_num)
    
    player:try_add_tit_point(resmng.ACH_NUM_HERO)
    player:try_add_tit_point(resmng.ACH_HERO_QUALITY_1)
    player:try_add_tit_point(resmng.ACH_HERO_QUALITY_2)
    player:try_add_tit_point(resmng.ACH_HERO_QUALITY_3)
    player:try_add_tit_point(resmng.ACH_HERO_QUALITY_4)
    player:try_add_tit_point(resmng.ACH_HERO_QUALITY_5)
    player:try_add_tit_point(resmng.ACH_HERO_QUALITY_6)
    player:try_add_tit_point(resmng.ACH_HERO_STAR_1)
    player:try_add_tit_point(resmng.ACH_HERO_STAR_2)
    player:try_add_tit_point(resmng.ACH_HERO_STAR_3)
    player:try_add_tit_point(resmng.ACH_HERO_STAR_4)
    player:try_add_tit_point(resmng.ACH_HERO_STAR_5)
    player:try_add_tit_point(resmng.ACH_HERO_STAR_6)
    
    local real_num = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        if con_quality == 0 and con_star == 0 then
            real_num = real_num + 1
        elseif con_quality == 0 and con_star ~= 0 then
            local prop_star = resmng.get_conf("prop_hero_star_up", v.star)
            if con_star <= prop_star.StarStatus[1] then
                real_num = real_num + 1
            end
        elseif con_quality ~= 0 and con_star == 0 then
            if con_quality <= v.quality then
                real_num = real_num + 1
            end
        elseif con_quality ~= 0 and con_star ~= 0 then
            if con_quality <= v.quality and con_star <= v.star then
                real_num = real_num + 1
            end
        end
    end

    if real_num > 0 then
        return update_task_process(task_data, con_num, real_num)
    else
        return false
    end
end

--提升英雄等级
do_task[TASK_ACTION.HERO_LEVEL_UP] = function(player, task_data, con_level)

    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_1)
    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_2)
    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_3)
    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_4)
    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_5)

    local highest = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        if v.lv > highest then
            highest = v.lv
        end
    end
    if highest > 0 then
        return update_task_process(task_data, con_level, highest)
    end
    return false
end

--学习英雄技能
do_task[TASK_ACTION.LEARN_HERO_SKILL] = function(player, task_data, con_pos)

    player:try_add_tit_point(resmng.ACH_HERO_SKILL_1)
    player:try_add_tit_point(resmng.ACH_HERO_SKILL_2)
    player:try_add_tit_point(resmng.ACH_HERO_SKILL_3)
    player:try_add_tit_point(resmng.ACH_HERO_SKILL_4)
    player:try_add_tit_point(resmng.ACH_HERO_SKILL_5)
    player:try_add_tit_point(resmng.ACH_HERO_SKILL_6)

    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        local skill = v.basic_skill[con_pos]
        if skill ~= nil and skill[1] > 0 then
            return update_task_process(task_data, 1, 1)
        end
    end
    return false
end

--英雄技能等级
do_task[TASK_ACTION.SUPREME_HERO_LEVEL] = function(player, task_data, con_level)
    local hero_list = player:get_hero()
    local highest = 0
    for k, v in pairs(hero_list) do
        for i, j in pairs(v.basic_skill) do
            local prop_tab = resmng.prop_skill[j[1]]
            if prop_tab ~= nil then
                if prop_tab.Lv > highest then
                    highest = prop_tab.Lv
                end
            end
        end
    end
    if highest > 0 then
        return update_task_process(task_data, con_level, highest)
    end
    return false
end

--加入玩家军团
do_task[TASK_ACTION.JOIN_PLAYER_UNION] = function(player, task_data)
    local union = unionmng.get_union(player:get_uid())
    if union == nil or union:is_new() then
        return false
    end

    return update_task_process(task_data, 1, 1)
end

--参与军团集结
do_task[TASK_ACTION.JOIN_MASS] = function(player, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团科技捐献
do_task[TASK_ACTION.UNION_TECH_DONATE] = function(player, task_data, con_num, con_acc, real_num)
    if con_acc == 1 then
        local cur = player:get_count(resmng.ACH_TASK_TECH_DONATE)
        return update_task_process(task_data, con_num, cur)
    end

    if real_num == nil then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团设施捐献
do_task[TASK_ACTION.UNION_SHESHI_DONATE] = function(player, task_data, con_num, con_acc, real_num)
    if con_acc == 1 then
        local cur = player:get_count(resmng.ACH_TASK_SHESHI_DONATE)
        return update_task_process(task_data, con_num, cur)
    end
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团帮助次数
do_task[TASK_ACTION.UNION_HELP_NUM] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团援助
do_task[TASK_ACTION.UNION_AID] = function(player, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--采集资源
do_task[TASK_ACTION.GATHER] = function(player, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        local ach_index = "ACH_TASK_GATHER_RES"..con_type
        if con_type == 0 then
            ach_index = "ACH_COUNT_GATHER"
        end
        local cur = player:get_count(resmng[ach_index])
        return update_task_process(task_data, con_num, cur)
    end
    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--收集物品
do_task[TASK_ACTION.GET_ITEM] = function(player, task_data, con_id, con_num, real_id, real_num)
    local items = player:get_item()
    for k, v in pairs(items) do
        if con_id == v[2] then
            return update_task_process(task_data, con_num, v[3])
        end
    end
    return false
end

--收集上缴任务物品
do_task[TASK_ACTION.GET_TASK_ITEM] = function(player, task_data, con_id, con_num, real_id, real_num)
    if con_id ~= real_id then
        return
    end
    if update_get_task_item_process(task_data, con_num, player:get_item_num(con_id)) then
        player:dec_item_by_item_id(con_id, con_num, VALUE_CHANGE_REASON.REASON_DEC_RES_TASK)
        return true
    end
    if real_num > 0 then
        return true
    end

    return false
end

--收集品质装备
do_task[TASK_ACTION.GET_EQUIP] = function(player, task_data, con_grade, con_num, equip_id, real_num)

    player:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_1)
    player:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_2)
    player:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_3)
    player:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_4)
    player:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_5)
    player:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_6)

    local num = 0
    if equip_id == nil or real_num == nil then
        --遍历找一下满足条件的装备
        local equips = player:get_equip()
        if equips == nil then
            return
        end
        for k, v in pairs(equips) do
            local prop_tab = resmng.prop_equip[v.propid]
            if prop_tab ~= nil then
                if con_grade <= prop_tab.Class then
                    num = num + 1
                end
            end
        end
    else
        local prop_tab = resmng.prop_equip[equip_id]
        if prop_tab ~= nil then
            if con_grade <= prop_tab.Class then
                num = num + 1
            end
        end
    end

    add_task_process(player, task_data, con_num, num)
    return true
end

--使用道具
do_task[TASK_ACTION.USE_ITEM] = function(player, task_data, con_class, con_mode, con_id, con_num, real_id, real_num)
    if real_id == nil or real_num == nil then
        return false
    end

    if con_id == 0 then
        --比较类别
        local prop_tab = resmng.get_conf("prop_item", real_id)
        if prop_tab == nil then
            return false
        end
        if con_mode == 0 then
            if prop_tab.Class == con_class then
                add_task_process(player, task_data, con_num, real_num)
            end
        else
            if prop_tab.Class == con_class and con_mode == prop_tab.Mode then
                add_task_process(player, task_data, con_num, real_num)
            end
        end

    else
        --比较ID
        if con_id == real_id then
            add_task_process(player, task_data, con_num, real_num)
        end
    end

    return true
end

--市场购买次数
do_task[TASK_ACTION.MARKET_BUY_NUM] = function(player, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--升级城建
do_task[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(player, task_data, con_type, con_num, con_level)
    local builds = player:get_build()
    local cur_num = 0
    local cur_level = 0
    for k, v in pairs(builds) do
        local prop_build = resmng.prop_build[v.propid]
        if prop_build == nil then
            return false
        end

        local cur_type = con_type
        if con_type == 15 or con_type == 20 then -- 箭塔有两个
            if prop_build.Specific == 15 or prop_build.Specific == 20 then
                cur_type = prop_build.Specific
            end
        end

        if cur_type == prop_build.Specific then
            if prop_build.Lv > cur_level then
                cur_level = prop_build.Lv
            end
            if prop_build.Lv >= con_level then
                cur_num = cur_num + 1
            end
        end

    end

    if con_num > 1 then
        return update_task_process(task_data, con_num, cur_num)
    else
        return update_task_process(task_data, con_level, cur_level)
    end
end

--开启野地
do_task[TASK_ACTION.OPEN_RES_BUILD] = function(player, task_data, con_pos, real_pos)
    if (player.field - 2) < con_pos then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--资源产量
do_task[TASK_ACTION.RES_OUTPUT] = function(player, task_data, con_type, con_num)
    local builds = player:get_build()
    local real_num = 0
    for k, v in pairs(builds or {}) do
        local class = math.floor(v.propid / 1000000)
        local mode = math.floor((v.propid - (class * 1000000)) / 1000)
        if class == 1 and mode == con_type then
            real_num = real_num + v:get_extra("speed")
        end
    end
    if real_num > 0 then
        return update_task_process(task_data, con_num, real_num)
    end
    return false
end

--研究科技
do_task[TASK_ACTION.STUDY_TECH] = function(player, task_data, con_id, con_level)
    local con_prop = resmng.prop_tech[con_id]
    if con_prop == nil then
        return false
    end
    local con_class = con_prop.Class
    local con_mode = con_prop.Mode
    local real_lv = 0
    for k, v in pairs(player.tech) do
        local real_prop = resmng.prop_tech[v]
        if real_prop ~= nil then
            local class = real_prop.Class
            local mode = real_prop.Mode
            local lv = real_prop.Lv
            if class == con_class and mode == con_mode then
                real_lv = lv
                break
            end
        end
    end

    if real_lv > 0 then
        return update_task_process(task_data, con_level, real_lv)
    end
    return false
end

--招募士兵
do_task[TASK_ACTION.RECRUIT_SOLDIER] = function(player, task_data, con_type, con_level, con_num, con_acc, real_type, real_level, real_num)
    if con_acc == 1 then
        local ach_index = ""
        if con_type == 0 then
            ach_index = "ACH_COUNT_TRAIN"
        elseif con_level == 0 then
            local total = 0
            for i = 1, 10, 1 do
                local id = con_type * 1000 + i
                total = total + player:get_count(resmng["ACH_TASK_RECRUIT_SOLDIER"..id])
            end

            return update_task_process(task_data, con_num, total)
        else
            local id = con_type * 1000 + con_level
            ach_index = "ACH_TASK_RECRUIT_SOLDIER"..id
        end

        local cur = player:get_count(resmng[ach_index])
        return update_task_process(task_data, con_num, cur)
    end
    if real_type == nil or real_level == nil or real_num == nil then
        return false
    end

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    if con_level ~= 0 and con_level ~= real_level then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--治疗单位
do_task[TASK_ACTION.CURE] = function(player, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--铸造装备
do_task[TASK_ACTION.MAKE_EQUIP] = function(player, task_data, con_grade, con_num, equip_id, real_num)
    local prop_tab = resmng.prop_equip[equip_id]
    if prop_tab == nil then
        return false
    end
    local real_grade = prop_tab.Class
    if real_grade == nil or real_num == nil then
        return false
    end

    if con_grade ~= 0 and con_grade ~= real_grade then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--合成材料
do_task[TASK_ACTION.SYN_MATERIAL] = function(player, task_data, con_grade, con_num, material_id, real_num)
    local prop_tab = resmng.prop_item[material_id]
    if prop_tab == nil then
        return false
    end
    local real_grade = prop_tab.Color
    if real_grade == nil or real_num == nil then
        return false
    end

    if con_grade ~= 0 and con_grade ~= real_grade then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--签到
do_task[TASK_ACTION.MONTH_AWARD] = function(player, task_data, real_num)
    if get_diff_days( gTime, player.month_award_cur ) == 0 then
        add_task_process(player, task_data, 1, 1)
    end
    return true
end

--飞艇（码头）领取
do_task[TASK_ACTION.DAY_AWARD] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--打开界面
do_task[TASK_ACTION.OPEN_UI] = function(player, task_data, con_id, real_id)
    if real_id == nil then
        return false
    end

    if con_id ~= real_id then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--拜访HERO
do_task[TASK_ACTION.VISIT_HERO] = function(player, task_data, con_id, real_id, real_num)
    if real_id == nil then
        return false
    end

--临时通过
--    if task_warning("do_task[TASK_ACTION.VISIT_NPC]") == false then
--      add_task_process(player, task_data, 1, 1)
--   end
    --------------

    if con_id ~= real_id then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--拜访HERO
do_task[TASK_ACTION.VISIT_NPC] = function(player, task_data, con_id, con_num, real_id, real_num)
    if real_id == nil then
        return false
    end

--临时通过
--    if task_warning("do_task[TASK_ACTION.VISIT_NPC]") == false then
--      add_task_process(player, task_data, 1, 1)
--   end
    --------------

    if con_id ~= real_id then
        return false
    end
    add_task_process(player, task_data, con_num, 1)
    return true
end

--收获士兵/资源
do_task[TASK_ACTION.GET_RES] = function(player, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--提升领主等级
do_task[TASK_ACTION.ROLE_LEVEL_UP] = function(player, task_data, con_level)
    return update_task_process(task_data, con_level, player.lv)
end

--抽卡次数
do_task[TASK_ACTION.GACHA_MUB] = function(player, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end
    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--俘虏英雄
do_task[TASK_ACTION.CAPTIVE_HERO] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--提升英雄技能
do_task[TASK_ACTION.PROMOTE_HERO_LEVEL] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--提升英雄经验
do_task[TASK_ACTION.HERO_EXP] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--研发科技次数
do_task[TASK_ACTION.STUDY_TECH_MUB] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--升级城建次数
do_task[TASK_ACTION.CITY_BUILD_MUB] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--击杀士兵数量
do_task[TASK_ACTION.KILL_SOLDIER] = function(player, task_data, con_level, con_num, con_acc, real_level, real_num)
    if con_acc == 1 then
        local total = 0
        if con_level == 0 then
            for i = 1, 10, 1 do
                total = total + player:get_count(resmng["ACH_TASK_KILL_SOLDIER"..i])
            end
        else
            total = player:get_count(resmng["ACH_TASK_KILL_SOLDIER"..con_level])
        end
        return update_task_process(task_data, con_num, total)
    end

    if con_level ~= 0 and con_level ~= real_level then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--膜拜战神
do_task[TASK_ACTION.WORSHIP_GOD] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--金币加速
do_task[TASK_ACTION.GOLD_ACC] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--提升战力途径
do_task[TASK_ACTION.PROMOTE_POWER] = function(player, task_data, con_type, con_num, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end
    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--阵亡士兵数量
do_task[TASK_ACTION.DEAD_SOLDIER] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--派遣驻守英雄
do_task[TASK_ACTION.HERO_STATION] = function(player, task_data, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, 1, real_num)
    return true
end







--世界频道说话
do_task[TASK_ACTION.WORLD_CHAT] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--完成日常任务
do_task[TASK_ACTION.FINISH_DAILY_TASK] = function(player, task_data, con_activity)
    return update_task_process(task_data, con_activity, player.activity)
end

--完成军团任务
do_task[TASK_ACTION.FINISH_UNION_TASK] = function(player, task_data, con_score, real_score)
    if real_score == nil then
        return false
    end
    return update_task_process(task_data, con_score, real_score)
end

--迁城到资源带
do_task[TASK_ACTION.MOVE_TO_ZONE] = function(player, task_data, con_lv, real_lv)
    if real_lv == nil then
        local zone_lv = get_pos_lv(player.x, player.y)
        if con_lv == zone_lv then
            add_task_process(player, task_data, 1, 1)
            return true
        end
        return false
    end

    if con_lv ~= real_lv then
        return false
    end

    add_task_process(player, task_data, 1, 1)
    return true
end

--叛军突袭活动获得积分
do_task[TASK_ACTION.PANJUN_SCORE] = function(player, task_data, con_score, real_score)
    if real_score == nil then
        return false
    end
    --return update_task_process(task_data, con_score, real_score)
    add_task_process(player, task_data, con_score, real_score)
end

--遗迹塔获得贤者之石
do_task[TASK_ACTION.LOSTTEMPLE_SCORE] = function(player, task_data, con_score, real_score)
    if real_score == nil then
        return false
    end
    return update_task_process(task_data, con_score, real_score)
end

--向王城行军
do_task[TASK_ACTION.TROOP_TO_KING_CITY] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end
    return update_task_process(task_data, con_num, 1)
end
