module("task_logic_t", package.seeall)

gPendingTask = gPendingTask or {}

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
    if not player then return end
    if player._cur_task_list then
        do_process_task( player, task_action, ... )
    else
        local pid = player.pid
        local node = gPendingTask[ pid ]
        if not node then
            node = {}
            gPendingTask[ pid ] = node
            action( handle_pending_task, pid )
        end
        table.insert( node, { task_action, ... } )
    end
end

function handle_pending_task( pid )
    local p = getPlayer( pid )
    if p then
        local node = gPendingTask[ pid ]
        gPendingTask[ pid ] = nil
        for _, v in pairs( node ) do
            do_process_task( p, table.unpack( v ) )
        end
    end
end

function do_process_task( player, task_action, ... )
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
                --local con_tab = copyTab(task_info.FinishCondition)
                --for i, j in pairs({...}) do
                --    table.insert(con_tab, j)
                --end

                --INFO( "[TASK], pid=%d, process=%s, key=%s", player.pid, v.task_id, con_tab[1])
                --local res = distribute_operation(player, v, unpack(con_tab))
                --if res then
                --    player:add_save_task_id(v.task_id)
                --end

                local cond = task_info.FinishCondition
                INFO( "[TASK], pid=%d, process=%s, key=%s", player.pid, v.task_id, cond[1])
                local res = distribute_operation(player, v, cond, ... )
                if res then
                    player:add_save_task_id(v.task_id)
                end

            end
        end
    end
    player:do_save_task()
end


function distribute_operation(player, task_data, cond, ...)
    local key = g_task_func_relation[cond[1]]
    if do_task[key] ~= nil then
        return do_task[key](player, task_data, cond, ...)
    end
end

function add_task_process(player, task_data, con_num, num)
    task_data.task_current_num = task_data.task_current_num + num
    if task_data.task_current_num >= con_num then
        --如果是日常任务判断不一样
        if task_data.task_type == TASK_TYPE.TASK_TYPE_DAILY then
            local prop = resmng.prop_task_daily[task_data.task_id]
            local limit = prop.FinishNum
            for i = task_data.task_daily_num, limit, 1 do
                if task_data.task_current_num >= con_num then
                    task_data.task_current_num = task_data.task_current_num - con_num
                    task_data.task_daily_num = task_data.task_daily_num + 1
                    player:add_activity(task_data.task_id)
                    Rpc:tips(player, 1, resmng.COMMON_TIPS_DAILYQUEST, {
                        prop.Name,
                        task_data.task_daily_num,
                        limit,
                        prop.ActiveNum})
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
do_task[TASK_ACTION.ATTACK_SPECIAL_MONSTER] = function(player, task_data, cond, real_mid, real_hp, real_eid)
    if not real_mid then return end
    if not real_hp then return end

    local con_mid = cond[2]
    if con_mid ~= real_mid then return false end

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
do_task[TASK_ACTION.ATTACK_SPECIAL_PLY] = function(player, task_data, cond, real_id, num)
    if real_id == nil then return false end
    local con_id = cond[2]
    local con_num = cond[3]
    if con_id ~= real_id then return false end

    Rpc:rm_fake_ply(player, real_id)
    task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    return true
end

--侦查特定ID的fake ply
do_task[TASK_ACTION.SPY_SPECIAL_PLY] = function(player, task_data, cond, real_id, num)
    if real_id == nil then return false end
    local con_id = cond[2]
    local con_num = cond[3]
    if con_id ~= real_id then return false end

    task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    return true
end

--攻击等级怪物
do_task[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(player, task_data, cond, real_mid, real_num)
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

    if real_mid == nil or real_num == nil then return false end

    local con_type = cond[2]
    local con_level = cond[3]
    local con_num = cond[4]

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
do_task[TASK_ACTION.BATTLE_LIANDONG] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--单场战斗战损比
do_task[TASK_ACTION.BATTLE_DAMAGE] = function(player, task_data, cond, real_ratio)
    if real_ratio == nil then return false end

    local con_ratio = cond[2]

    if real_ratio > con_ratio then return false end

    add_task_process(player, task_data, 1, 1)
    return true
end

--侦查玩家城堡
do_task[TASK_ACTION.SPY_PLAYER_CITY] = function(player, task_data, cond, real_num)
    local con_num = cond[2]
    local con_acc = cond[3]

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
do_task[TASK_ACTION.SLOW_SPEED] = function(player, task_data, cond, real_time)
    if real_time == nil then return false end

    local con_time = cond[2]

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
do_task[TASK_ACTION.ATTACK_PLAYER_CITY] = function(player, task_data, cond, real_num, real_win)
    local con_num = cond[2]
    local con_win = cond[3]
    local con_acc = cond[4]

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
do_task[TASK_ACTION.LOOT_RES] = function(player, task_data, cond, real_type, real_num)
    local con_type = cond[2]
    local con_num = cond[3]
    local con_acc = cond[4]

    if con_acc == 1 then
        local cur = 0
        for i = 1, 4, 1 do
            cur = cur + player:get_count(resmng["ACH_TASK_ATK_RES"..i])
        end
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
do_task[TASK_ACTION.SPY_NPC_CITY] = function(player, task_data, cond, real_type)
    if real_type == nil then return false end
    local con_type = cond[2]

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--攻击系统城市
do_task[TASK_ACTION.ATTACK_NPC_CITY] = function(player, task_data, cond, real_type, real_num)
    local con_type = cond[2]
    local con_num = cond[3]
    local con_acc = cond[4]

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
do_task[TASK_ACTION.OCC_NPC_CITY] = function(player, task_data, cond, real_type)
    local union = unionmng.get_union(player:get_uid())
    if union == nil then return false end

    local con_type = cond[2]

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
do_task[TASK_ACTION.HAS_HERO_NUM] = function(player, task_data, cond)
    local con_quality = cond[2]
    local con_star = cond[3]
    local con_num = cond[4]

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
do_task[TASK_ACTION.HERO_LEVEL_UP] = function(player, task_data, cond)
    local con_level = cond[2]
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
do_task[TASK_ACTION.LEARN_HERO_SKILL] = function(player, task_data, cond)
    local con_pos = cond[2]
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list) do
        if con_pos == 0 then
            for _, s in pairs(v.basic_skill or {}) do
                if s ~= nil and s[1] > 0 then
                    return update_task_process(task_data, 1, 1)
                end
            end
        else
            local skill = v.basic_skill[con_pos]
            if skill ~= nil and skill[1] > 0 then
                return update_task_process(task_data, 1, 1)
            end
        end
    end
    return false
end

--英雄技能等级
do_task[TASK_ACTION.SUPREME_HERO_LEVEL] = function(player, task_data, cond)
    local con_level = cond[2]
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
do_task[TASK_ACTION.JOIN_MASS] = function(player, task_data, cond, real_type, real_num)
    if real_type == nil or real_num == nil then
        return false
    end

    local con_type = cond[2]
    local con_num = cond[3]

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团科技捐献
do_task[TASK_ACTION.UNION_TECH_DONATE] = function(player, task_data, cond, real_num)
    local con_num = cond[2]
    local con_acc = cond[3]

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
do_task[TASK_ACTION.UNION_SHESHI_DONATE] = function(player, task_data, cond, real_num)
    local con_num = cond[2]
    local con_acc = cond[3]

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
do_task[TASK_ACTION.UNION_HELP_NUM] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end
    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--军团援助
do_task[TASK_ACTION.UNION_AID] = function(player, task_data, cond, real_type)
    if real_type == nil then return false end

    local con_type = cond[2]

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--采集资源
do_task[TASK_ACTION.GATHER] = function(player, task_data, cond, real_type, real_num)
    local con_type = cond[2]
    local con_num = cond[3]
    local con_acc = cond[4]

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
    local count = real_num * (RES_RATE[real_type] or 1)
    add_task_process(player, task_data, con_num, count)
    return true
end

--收集物品
do_task[TASK_ACTION.GET_ITEM] = function(player, task_data, cond, real_id, real_num)
    local con_id = cond[2]
    local con_num = cond[3]

    local items = player:get_item()
    for k, v in pairs(items) do
        if con_id == v[2] then
            return update_task_process(task_data, con_num, v[3])
        end
    end
    return false
end

--收集上缴任务物品
do_task[TASK_ACTION.GET_TASK_ITEM] = function(player, task_data, cond, real_id, real_num)
    local con_id = cond[2]
    local con_num = cond[3]

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
do_task[TASK_ACTION.GET_EQUIP] = function(player, task_data, cond, equip_id, real_num)
    local con_grade = cond[2]
    local con_num = cond[3]

    local num = 0

    --遍历找一下满足条件的装备
    local equips = player:get_equip()
    if equips == nil then return end

    for k, v in pairs(equips) do
        local prop_tab = resmng.prop_equip[v.propid]
        if prop_tab ~= nil then
            if con_grade <= prop_tab.Class then
                num = num + 1
            end
        end
    end

    return update_task_process( task_data, con_num, num )
end

--使用道具
do_task[TASK_ACTION.USE_ITEM] = function(player, task_data, cond, real_id, real_num)
    local con_class = cond[2]
    local con_mode = cond[3]
    local con_id = cond[4]
    local con_num = cond[5]

    if real_id == nil or real_num == nil then return false end

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
do_task[TASK_ACTION.MARKET_BUY_NUM] = function(player, task_data, cond, real_type, real_num)
    if real_type == nil or real_num == nil then return false end

    local con_type = cond[2]
    local con_num = cond[3]

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--升级城建
do_task[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(player, task_data, cond)
    local bidx = cond[2]
    local bnum = cond[3]
    local blvl = cond[4]

    local builds = player:get_build()
    if bnum > 1 then
        local count = 0
        for _, build in pairs( builds ) do
            local propid = build.propid
            if math.floor( propid * 0.001 ) == bidx then
                if math.floor( propid % 1000 ) >= blvl then
                    count = count + 1
                end
            end
        end
        if count >= bnum then
            task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
            return true
        end
    else
        if bidx == BUILD_FUNCTION_MODE.TUTTER_LEFT or bidx == BUILD_FUNCTION_MODE.TUTTER_RIGHT then
            local build = player:get_build( BUILD_FUNCTION_MODE.TUTTER_LEFT * 100 + 1 )
            if build and math.floor( build.propid % 1000 ) >= blvl then 
                task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
                return true 
            end

            local build = player:get_build( BUILD_FUNCTION_MODE.TUTTER_RIGHT * 100 + 1 )
            if build and math.floor( build.propid % 1000 ) >= blvl then 
                task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
                return true 
            end

            return false
        else
            for _, build in pairs( builds ) do
                local propid = build.propid
                if math.floor( propid * 0.001 ) == bidx then
                    if math.floor( propid % 1000 ) >= blvl then
                        task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
                        return true
                    end
                end
            end
        end
    end
end


--开启野地
do_task[TASK_ACTION.OPEN_RES_BUILD] = function(player, task_data, cond, real_pos)
    local con_pos = cond[2]
    return update_task_process( task_data, con_pos, player.field - 2 ) 
end

--资源产量
do_task[TASK_ACTION.RES_OUTPUT] = function(player, task_data, cond)
    local con_type = cond[2]
    local con_num = cond[3]

    local builds = player:get_build()
    local real_num = 0
    for k, v in pairs(builds or {}) do
        local class = math.floor(v.propid / 1000000)
        local mode = math.floor((v.propid - (class * 1000000)) / 1000)
        if class == 1 and mode == con_type then
            real_num = real_num + (v:get_extra("speed") or 0)
        end
    end
    if real_num > 0 then
        return update_task_process(task_data, con_num, real_num)
    end
    return false
end

--研究科技
do_task[TASK_ACTION.STUDY_TECH] = function(player, task_data, cond)
    local bid = cond[2]
    local blvl = cond[3]

    local dconf = resmng.get_conf( "prop_tech", bid )
    if dconf then
        local class = dconf.Class
        local mode = dconf.Mode
        local techs = player.tech
        for _, id in pairs( techs ) do
            local sconf = resmng.get_conf( "prop_tech", id )
            if sconf then
                if sconf.Class == class and sconf.Mode == mode and sconf.Lv >= blvl then
                    task_data.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
                    return true
                end
            end
        end
    end
end

--招募士兵
do_task[TASK_ACTION.RECRUIT_SOLDIER] = function(player, task_data, cond, real_type, real_level, real_num)
    if real_type == nil or real_level == nil or real_num == nil then return false end

    local con_type = cond[2]
    local con_level = cond[3]
    local con_num = cond[4]
    local con_acc = cond[5]

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
do_task[TASK_ACTION.CURE] = function(player, task_data, cond, real_type, real_num)
    if real_type == nil or real_num == nil then return false end

    local con_type = cond[2]
    local con_num = cond[3]

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--铸造装备
do_task[TASK_ACTION.MAKE_EQUIP] = function(player, task_data, cond, equip_id, real_num)
    local con_grade = cond[2]
    local con_num = cond[3]

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
do_task[TASK_ACTION.SYN_MATERIAL] = function(player, task_data, cond, material_id, real_num)
    if real_num == nil then return false end

    local con_grade = cond[2]
    local con_num = cond[3]

    local prop_tab = resmng.prop_item[material_id]
    if prop_tab == nil then
        return false
    end
    local real_grade = prop_tab.Color

    if con_grade ~= 0 and con_grade ~= real_grade then
        return false
    end

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--签到
do_task[TASK_ACTION.MONTH_AWARD] = function(player, task_data, cond, real_num)
    if get_diff_days( gTime, player.month_award_cur ) == 0 then
        add_task_process(player, task_data, 1, 1)
    end
    return true
end

--飞艇（码头）领取
do_task[TASK_ACTION.DAY_AWARD] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--打开界面
do_task[TASK_ACTION.OPEN_UI] = function(player, task_data, cond, real_id)
    if real_id == nil then return false end
    local con_id = cond[2]

    if con_id ~= real_id then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--拜访HERO
do_task[TASK_ACTION.VISIT_HERO] = function(player, task_data, cond, real_id, real_num)
    if real_id == nil then return false end

    local con_id = cond[2]

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
do_task[TASK_ACTION.VISIT_NPC] = function(player, task_data, cond, real_id, real_num)
    if real_id == nil then return false end
    local con_id = cond[2]
    local con_num = cond[3]

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
do_task[TASK_ACTION.GET_RES] = function(player, task_data, cond, real_type)
    if real_type == nil then return false end

    local con_type = cond[2]

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, 1, 1)
    return true
end

--提升领主等级
do_task[TASK_ACTION.ROLE_LEVEL_UP] = function(player, task_data, cond)
    local con_level = cond[2]
    return update_task_process(task_data, con_level, player.lv)
end

--抽卡次数
do_task[TASK_ACTION.GACHA_MUB] = function(player, task_data, cond, real_type, real_num)
    if real_type == nil or real_num == nil then return false end
    
    local con_type = cond[2]
    local con_num = cond[3]

    if con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--俘虏英雄
do_task[TASK_ACTION.CAPTIVE_HERO] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--提升英雄技能
do_task[TASK_ACTION.PROMOTE_HERO_LEVEL] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--提升英雄经验
do_task[TASK_ACTION.HERO_EXP] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--研发科技次数
do_task[TASK_ACTION.STUDY_TECH_MUB] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--升级城建次数
do_task[TASK_ACTION.CITY_BUILD_MUB] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--击杀士兵数量
do_task[TASK_ACTION.KILL_SOLDIER] = function(player, task_data, cond, real_level, real_num)
    local con_level = cond[2]
    local con_num = cond[3]
    local con_acc = cond[4]
    
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
do_task[TASK_ACTION.WORSHIP_GOD] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--金币加速
do_task[TASK_ACTION.GOLD_ACC] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--提升战力途径
do_task[TASK_ACTION.PROMOTE_POWER] = function(player, task_data, cond, real_type, real_num)
    if real_type == nil or real_num == nil then return false end

    local con_type = cond[2]
    local con_num = cond[3]

    if con_type ~= 0 and con_type ~= real_type then
        return false
    end
    add_task_process(player, task_data, con_num, real_num)
    return true
end

--阵亡士兵数量
do_task[TASK_ACTION.DEAD_SOLDIER] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num =cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--派遣驻守英雄
do_task[TASK_ACTION.HERO_STATION] = function(player, task_data, cond, real_num)
    if real_num == nil then
        return false
    end

    add_task_process(player, task_data, 1, real_num)
    return true
end




--世界频道说话
do_task[TASK_ACTION.WORLD_CHAT] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]

    add_task_process(player, task_data, con_num, real_num)
    return true
end

--完成日常任务
do_task[TASK_ACTION.FINISH_DAILY_TASK] = function(player, task_data, cond)
    local con_activity = cond[2]
    return update_task_process(task_data, con_activity, player.activity)
end

--完成军团任务
do_task[TASK_ACTION.FINISH_UNION_TASK] = function(player, task_data, cond, real_score)
    if real_score == nil then return false end

    local con_score = cond[2]
    return update_task_process(task_data, con_score, real_score)
end

--迁城到资源带
do_task[TASK_ACTION.MOVE_TO_ZONE] = function(player, task_data, cond, real_lv)
    local con_lv = cond[2]
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
do_task[TASK_ACTION.PANJUN_SCORE] = function(player, task_data, cond, real_score)
    if real_score == nil then return false end

    local con_score = cond[2]

    --return update_task_process(task_data, con_score, real_score)
    add_task_process(player, task_data, con_score, real_score)
    return true
end

--遗迹塔获得贤者之石
do_task[TASK_ACTION.LOSTTEMPLE_SCORE] = function(player, task_data, cond, real_score)
    if real_score == nil then return false end
    local con_score = cond[2]
    return update_task_process(task_data, con_score, real_score)
end

--向王城行军
do_task[TASK_ACTION.TROOP_TO_KING_CITY] = function(player, task_data, cond, real_num)
    if real_num == nil then return false end

    local con_num = cond[2]
    return update_task_process(task_data, con_num, 1)
end

--特定英雄到达等级
do_task[TASK_ACTION.SPECIAL_HERO_LEVEL] = function(player, task_data, cond)
    local con_id = cond[2]
    local con_level = cond[3]

    local lv = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list or {}) do
        if v.propid == con_id then
            lv = v.lv
            break
        end
    end
    if lv > 0 then
        return update_task_process(task_data, con_level, lv)
    end
    return false
end

--特定英雄升星
do_task[TASK_ACTION.SPECIAL_HERO_STAR] = function(player, task_data, cond)
    local con_id = cond[2]
    local con_star = cond[3]

    local star = 0
    local hero_list = player:get_hero()
    for k, v in pairs(hero_list or {}) do
        if 0 == con_id then
            if star < v.star then
                star = v.star
            end
        elseif v.propid == con_id then
            star = v.star
            break
        end
    end
    if star > 0 then
        return update_task_process(task_data, con_star, star)
    end
    return false
end

--特定英雄性格重置
do_task[TASK_ACTION.HERO_NATURE_RESET] = function(player, task_data, cond, real_id, real_num)
    if real_num == nil then return false end

    local con_id = cond[2]
    local con_num = cond[3]

    if con_id ~= 0 and con_id ~= real_id then
        return false
    end
    add_task_process(player, task_data, con_num, 1)
    return true
end

-- 获得军团奇迹Buff
do_task[TASK_ACTION.UNION_CASTLE_EFFECT] = function(player, task_data, cond)
    local con_lv = cond[2]
    if 0 == player.ef_eid then
        return false
    end
    local entity = get_ety(player.ef_eid)
    if not entity then
        return false
    end
    if not is_union_miracal(entity.propid) then
        return false
    end
    if entity.uid ~= player.uid then
        return false
    end
    con_lv = con_lv > 0 and con_lv or 1
    local zone_lv = get_pos_lv(player.x, player.y)
    return update_task_process(task_data, con_lv, zone_lv)
end

-- 领主改名
do_task[TASK_ACTION.LORD_RENAME] = function(player, task_data, cond, real_num)
    if nil == real_num then
        local smap, pid = string.match(player.name, "^K(%d+)a(%d+)$")
        if tonumber(smap) == player.smap and tonumber(pid) == player.pid then
            return false
        end
    end
    add_task_process(player, task_data, 1, 1)
    return true
end


gTaskProcessByClient = {}
gTaskProcessByClient[ TASK_ACTION.CITY_BUILD_LEVEL_UP ] = 1
gTaskProcessByClient[ TASK_ACTION.STUDY_TECH ] = 1
gTaskProcessByClient[ TASK_ACTION.HAS_HERO_NUM ] = 1
gTaskProcessByClient[ TASK_ACTION.HERO_LEVEL_UP ] = 1
gTaskProcessByClient[ TASK_ACTION.SPECIAL_HERO_LEVEL ] = 1
gTaskProcessByClient[ TASK_ACTION.SPECIAL_HERO_STAR ] = 1
gTaskProcessByClient[ TASK_ACTION.LEARN_HERO_SKILL ] = 1
gTaskProcessByClient[ TASK_ACTION.JOIN_PLAYER_UNION ] = 1
gTaskProcessByClient[ TASK_ACTION.GET_ITEM ] = 1
gTaskProcessByClient[ TASK_ACTION.GET_EQUIP ] = 1
gTaskProcessByClient[ TASK_ACTION.OPEN_RES_BUILD ] = 1
gTaskProcessByClient[ TASK_ACTION.RES_OUTPUT ] = 1
gTaskProcessByClient[ TASK_ACTION.ROLE_LEVEL_UP ] = 1
gTaskProcessByClient[ TASK_ACTION.FINISH_DAILY_TASK ] = 1
gTaskProcessByClient[ TASK_ACTION.LORD_RENAME ] = 1
gTaskProcessByClient[ TASK_ACTION.SUPREME_HERO_LEVEL ] = 1

