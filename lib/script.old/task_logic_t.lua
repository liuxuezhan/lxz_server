module("task_logic_t")

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
    local task_data_array = player:get_task_by_action(task_action)
    for k, v in pairs(task_data_array) do
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
    player:do_save_task()
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

function update_task_process(task_data, con_num, num)
    if task_data.task_current_num < num then
        task_data.task_current_num = num
    end
    if task_data.task_current_num >= con_num then
        task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    end
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

--攻击等级怪物
do_task[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(player, task_data, con_type, con_level, con_num, con_acc, real_mid, real_num)
    if con_acc == 1 then
        --sanshimark判断成就
    end
    if real_mid == nil or real_num == nil then
        return false
    end

    local monster_info = resmng.prop_world_unit[real_mid]
    if monster_info == nil then
        return false
    end
    local real_type = monster_info.Mode 
    local real_level = monster_info.Lv
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
do_task[TASK_ACTION.BATTLE_LIANGDONG] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.BATTLE_LIANGDONG]") == false then
        add_task_process(player, task_data, con_num, con_num)
    end
    --------------
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--单场战斗战损比
do_task[TASK_ACTION.BATTLE_DAMAGE] = function(player, task_data, con_ratio, real_ratio)
    if real_ratio == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.BATTLE_DAMAGE]") == false then
        add_task_process(player, task_data, 1, 1)
    end
    --------------
    if real_ratio > con_ratio then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--侦查玩家城堡
do_task[TASK_ACTION.SPY_PLAYER_CITY] = function(player, task_data, con_num, con_acc, real_num)
    if con_acc == 1 then
        --sanshimark判断成就
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
        --sanshimark判断成就
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
        --sanshimark判断成就
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

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--攻击系统城市
do_task[TASK_ACTION.ATTACK_NPC_CITY] = function(player, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        --sanshimark判断成就
    end
    if real_type == nil or real_num == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.ATTACK_NPC_CITY]") == false then
        add_task_process(player, task_data, con_num, real_num)
    end
    --------------
    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--占领系统城市
do_task[TASK_ACTION.OCC_NPC_CITY] = function(player, task_data, con_type, real_type)
    if real_type == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.OCC_NPC_CITY]") == false then
        add_task_process(player, task_data, 1, 1)
    end
    --------------
    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--持有英雄数量
do_task[TASK_ACTION.HAS_HERO_NUM] = function(player, task_data, con_quality, con_star, con_num)
    local real_num = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        if con_quality == 0 and con_star == 0 then
            real_num = real_num + 1
        elseif con_quality == 0 and con_star ~= 0 then
            if con_star <= v.star then
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
        update_task_process(task_data, con_num, real_num)
        return true
    else
        return false
    end
end

--提升英雄等级
do_task[TASK_ACTION.HERO_LEVEL_UP] = function(player, task_data, con_level)
    local highest = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        if v.lv > highest then
            highest = v.lv
        end
    end
    if highest > con_level then
        highest = con_level
    end
    if highest > 0 then
        update_task_process(task_data, con_level, highest)
        return true
    end
    return false
end

--学习英雄技能
do_task[TASK_ACTION.LEARN_HERO_SKILL] = function(player, task_data, con_pos)
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        local skill = v.basic_skill[con_pos]
        if skill ~= nil and skill[1] > 0 then
            update_task_process(task_data, 1, 1)
            return true
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
                    highest = lv
                end
            end
        end
    end
    if highest > 0 then
        update_task_process(task_data, con_level, highest)
        return true
    end
    return false
end

--加入玩家军团
do_task[TASK_ACTION.JOIN_PLAYER_UNION] = function(player, task_data)
    local union = unionmng.get_union(player:get_uid())
    if union == nil or union.new_union_sn ~= nil then
        return false
    end

    update_task_process(task_data, 1, 1)
    return true
end

--参与军团集结
do_task[TASK_ACTION.JOIN_MASS] = function(player, task_data, con_type, con_num, con_acc, real_type, real_num)
    if con_acc == 1 then
        --sanshimark判断成就
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

--军团科技捐献
do_task[TASK_ACTION.UNION_TECH_DONATE] = function(player, task_data, con_num, con_acc, real_num)
    if con_acc == 1 then
        --sanshimark判断成就
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
        --sanshimark判断成就
    end
    if real_num == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.UNION_SHESHI_DONATE]") == false then
        add_task_process(player, task_data, con_num, real_num)
    end
    --------------
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团帮助次数
do_task[TASK_ACTION.UNION_HELP_NUM] = function(player, task_data, con_num, real_num)
    if real_num == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.UNION_HELP_NUM]") == false then
        add_task_process(player, task_data, con_num, real_num)
    end
    --------------
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
        --sanshimark判断成就
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
do_task[TASK_ACTION.GET_ITEM] = function(player, task_data, con_id, con_num, con_deduct, real_id, real_num)
    if real_id == nil or real_num == nil then
        local items = player:get_item()
        for k, v in pairs(items) do
            if con_id == v[2] then
                update_task_process(task_data, con_num, v[3])
                return true
            end
        end
    else
        if real_id ~= con_id then
            return false
        end
        add_task_process(player, task_data, con_num, real_num)
    end
    return true   
end

--收集品质装备
do_task[TASK_ACTION.GET_EQUIP] = function(player, task_data, con_grade, con_num, equip_id, real_num)
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
do_task[TASK_ACTION.USE_ITEM] = function(player, task_data, con_type, con_id, con_num, real_id, real_num)
    if real_id == nil or real_num == nil then
        return false
    end

    local real_type = 0
    if con_id ~= 0 and con_id ~= real_id then
        return false
    end
    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
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

--升级城建的逻辑
function do_build_level_Up(build, con_type, con_level)
    if con_type ~= build.Specific then
        return false
    end
    if con_level > build.Lv then
        return false
    end

    return true
end
--升级城建
do_task[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(player, task_data, con_type, con_num, con_level)
    local builds = player:get_build()
    local cur_num = 0
    for k, v in pairs(builds) do
        local b = resmng.prop_build[v.propid]
        if b == nil then
            return false
        end
        if do_build_level_Up(b, con_type, con_level) == true then
            cur_num = cur_num + 1
        end

    end
    update_task_process(task_data, con_num, cur_num)
    return true
end

--开启野地
do_task[TASK_ACTION.OPEN_RES_BUILD] = function(player, task_data, con_pos, real_pos)
    if real_pos == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.OPEN_RES_BUILD]") == false then
        add_task_process(player, task_data, 1, 1)
    end
    --------------

    if con_pos ~= real_pos then
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
        update_task_process(task_data, con_num, real_num)
        return true
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
        update_task_process(task_data, con_level, real_lv)
        return true
    end
    return false
end

--招募士兵
do_task[TASK_ACTION.RECRUIT_SOLDIER] = function(player, task_data, con_type, con_level, con_num, con_acc, real_type, real_level, real_num)
    if con_acc == 1 then
        --sanshimark判断成就
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
do_task[TASK_ACTION.MONTH_AWARD] = function(player, task_data)
    if player:month_award_is_checked() == true then
        add_task_process(player, task_data, 1, 1)
        return true
    end
    return false
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

--拜访NPC
do_task[TASK_ACTION.VISIT_NPC] = function(player, task_data, con_id, real_id)
    if real_id == nil then
        return false
    end

    --临时通过
    if task_warning("do_task[TASK_ACTION.VISIT_NPC]") == false then
        add_task_process(player, task_data, 1, 1)
    end
    --------------

    if con_id ~= real_id then
        return false
    end
    add_task_process(player, task_data, 1, 1)
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
    update_task_process(task_data, con_level, player.lv)
    return true
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
        --sanshimark判断成就
    end
    if real_level == nil or real_num == nil then
        return false
    end

    if con_level ~= 0 and con_level ~= real_level then
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

