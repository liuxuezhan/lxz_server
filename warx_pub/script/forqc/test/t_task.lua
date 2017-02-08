
local t1 = {}

function t1.action(_idx)
    local p = get_one(true)
    loadData(p)

  --  chat(p, "@all")
    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@fieldtop" )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addallitem" )
--    chat( p, "@addbuf=1=-1" )
    --chat( p, "@addarm=1=999999999" )
    chat( p, "@initarm" )
    chat(p, "@debug1")


    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)
    do_test_task(p, 1)
    --wait_for_ack( p, "union_on_create" )

   -- buy_item(p, 39, 100)

   -- chat(p, "@all")
   -- local arms = {}
   -- chat( p, "@addarm=1001010=999999999" )
   -- for id, num in pairs(p._arm) do
   --     if num >  force_tb[city_lv][1] then
   --         arms[ id ] = force_tb[city_lv][1]
   --         break
   --     end
   -- end
   -- Rpc:siege(p, eid, {live_soldier = arms})
   -- WARN("siege npc  %d ", eid)
   -- sync(p)

   -- tid = 0
   -- for k, v in pairs(p._troop) do
   --     if v.target == eid then
   --         tid = k
   --         break
   --     end
   -- end

   -- if tid == 0 then
   --     WARN("no troop")
   --     return
   -- end

   -- ts = p._troop
   -- while true do
   --     local flag = false
   --     local t = ts[tid]
   --     if t then
   --         print(t.tmOver,get_tm(p))
   --         if t.tmOver > get_tm(p) + 1 then
   --              Rpc:troop_acc( p, tid, 7014001 )
   --              sync(p)
   --              flag = true
   --         end
   --     end
   --     if not flag then break end
   -- end

   -- wait_for_ack( p, "stateTroop" ) 

   -- Rpc:qry_troop_info(p, tid)
   -- --sync(p)
   -- wait_for_ack(p, "ack_troop_info")

   -- local left = p.arm_count - force_tb[city_lv][2]

   -- print(left, force_tb[city_lv][3])

   -- if left > force_tb[city_lv][3] or left < -force_tb[city_lv][3] then
   --     return "fight error"
   -- end

    return "ok"
end

function do_test_task(ply, num)
    if num > 1000 then
        return "do to much task"
    end

    Rpc:loadData(ply, "task")  --- loadtask
    wait_for_ack(ply, "loadData")
    if process_tasks(ply) == "ok" then  -- 处理身上所有任务
        print("do test task ", num)
        return do_test_task(ply, num + 1)
    else
        return "error"
    end
end

function process_tasks(ply)    --处理身上的所有任务
    for k, v in pairs(ply._task or {}) do
        local prop = resmng.prop_task_detail[v.task_id]
        if  process_task(ply, v) == "error" then
            return "error"
        end
    end
    return "ok"
end

local branch_list =
{
    130020114,
    130020228,
    130020325,
    130020431,
    130020526,
    130020644,
    130020764,
    130020819,
    130020906,
}

function process_task(ply, task)  --处理身上的单个任务
    if task.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
        print("process task ", task.task_id, task.task_status)
        do_task(ply, task)
    elseif task.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
        if get_table_valid_count(ply.branch_list or {}) == 6 and ply.trunk_id == 130011548 then
            return "ok"
        end

        if task.task_id == 130011548 then
            ply.trunk_id = 130011548
        end

        if branch_list[task.task_id] then
            local list = ply.branch_list or {}
            if not list[task.task_id] then
                list[task.task_id] = task.task_id
            end
        end

        print("finish task ", task.task_id)
        finish_task(ply, task)
    end
end

function finish_task(ply, task)
    Rpc:finish_task(ply, task.task_id)
    wait_for_ack(ply, "finish_task_resp")
    if ply.task_resp ~= 0 then
        WARN("task finish resp error ", task.task_id)
        return "error"
    end
    ply.task_resp = nil
    gen_next_task(ply, task)
end

function gen_next_task(ply, task)
    local task_id_array = {}
    for k, v in pairs(resmng.prop_task_detail) do
        if v.PreTask == task.task_id then
            table.insert(task_id_array, k)
        end
    end

    table.insert(task_id_array, 130020101)
    --table.insert(task_id_array, 130020201)
    table.insert(task_id_array, 130020301)
    table.insert(task_id_array, 130020401)
    table.insert(task_id_array, 130020501)
    --table.insert(task_id_array, 130020601)
    table.insert(task_id_array, 130020701)
    table.insert(task_id_array, 130020801)
    --table.insert(task_id_array, 130020901)
    Rpc:accept_task(ply, task_id_array)
    sync(ply)
end

function do_task(ply, task_info)
    local prop = resmng.prop_task_detail[task_info.task_id]
    if not prop then
        return "error"
    end

    unpack_action(ply, task_info.task_id, unpack(prop.FinishCondition or {}))

end

function unpack_action(ply, task_id, func, ...)
    local key = g_task_func_relation[func]
    if do_action[key] ~= nil then
        return do_action[key](ply, task_id, ...)
    end
end

do_action = {}
do_action[TASK_ACTION.OCC_NPC_CITY] = function(ply, task_id, con_type)
    if con_type == 5 then
        atk_king(ply, 1)
    else
        atk_npc(ply, con_type)
    end
end

do_action[TASK_ACTION.ATTACK_SPECIAL_MONSTER] = function(ply, task_id, monster_id)
    chat(ply, "@initarm")
    chat(ply, "@all")
    --chat( ply, "@addarm=1001010=999999999" ) 
    local arms = {}
    for id, num in pairs(ply._arm) do
        arms[id] = num
    end
    print("siege task npc ", monster_id)
    chat( ply, "@addbuf=1=-1" )
    chat( ply, "@addbuf=1=-1" )
    Rpc:siege_task_npc(ply, task_id, ply.eid, ply.x + 10, ply.y + 10, {live_soldier = arms})
    acc_troop(ply, ply.eid)
end

do_action[TASK_ACTION.OPEN_UI] = function(ply, task_id, ui_id)
    Rpc:finish_open_ui(ply, ui_id)
    sync(ply)
end

do_action[TASK_ACTION.RECRUIT_SOLDIER] = function(ply, task_id, con_type, con_level, con_num, con_acc)
    if con_level == 0 then
        con_level = 1
    end
    if con_type == 0 then
        con_type = 1
    end
    chat( ply, "@set_val=gold=100000000" )
    local arm_id = get_arm_id_by_mode_lv(con_type, con_level, ply.culture)
    chat(ply, "@buildall")
    local b = get_build(ply, 2, con_type)
    chat(ply, "@all")
    for i = 1 , math.ceil(con_num / 1000), 1 do
        local train_num =  1000
        if con_num < 1000 then
            train_num = con_num
        end
        Rpc:train(ply, b.idx,  arm_id, train_num, 1)
        sync(ply)
    end
end

do_action[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(ply, task_id, con_type, con_num, con_level)

    chat(ply, "@taskbuild")
   -- local cur_num = 0

   -- for k, v in pairs(ply._build or {}) do
   --     local prop_build = resmng.prop_build[v.propid]
   --     local cur_type = con_type
   --     if con_type == 15 or con_type == 20 then -- 箭塔有两个
   --         if prop_build.Specific == 15 or prop_build.Specific == 20 then
   --             cur_type = prop_build.Specific
   --         end
   --     end

   --     if cur_type == prop_build.Specific then
   --         if prop_build.Lv > cur_level then
   --             cur_level = prop_build.Lv
   --         end
   --         if prop_build.Lv >= con_level then
   --              cur_num = cur_num + 1 
   --          end
   --      end
   --  end

   --  if cur_num >= con_num then
   --      chat(ply, "@taskbuild")
   --      chat(ply, "@buildtop")
   --  else
   --      build_and_upgrade(ply, con_type, con_level, con_num - cru_num)
   --  end

 end


do_action[TASK_ACTION.MONTH_AWARD] = function(ply, task_id, num)
    Rpc:month_award_get_award(ply)
    sync(ply)
end

do_action[TASK_ACTION.UNION_TECH_DONATE] = function(ply, task_id, con_num, con_acc, real_num)
    local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_TECH_DONATE) .. "=" .. tostring(con_num)
    chat(ply, cmd)
--    chat(ply, "@all")
 --   for i=1, con_num , 1 do
  --      Rpc:union_donate(ply, 1001, 1)
  --      sync(ply)
  --  end
end

do_action[TASK_ACTION.OPEN_RES_BUILD] = function(ply, task_id, num )
    chat(ply, "@all")
    Rpc:open_field(ply, ply.field + 1)
    sync(ply)
end

do_action[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(ply, task_id, con_type, con_level, con_num)
    if con_level >= 30 and con_level < 200 then
        chat( ply, "@addscore=9999999" )
        chat( ply, "@daypass" )
    end

    if con_level == 200 then
        chat( ply, "@endkw" )
    end

    local cmd = "@genboss" .. "=" .. tostring(con_type) .. "=" ..tostring(con_level)
    Rpc:chat( ply, 0, cmd, 0 )
    wait_for_ack(ply, "gen_boss_eid_ack")
    chat( ply, "@initarm" )
    local arms = {}
    for id, num in pairs(ply._arm) do
        arms[id] = num
    end
    chat( ply, "@addbuf=1=-1" )
    Rpc:siege( ply, ply.boss_eid, { live_soldier=arms } )
    sync(ply)
    acc_troop(ply, ply.boss_eid)
    ply.boss_eid = nil
end

function acc_troop(ply, eid)
    chat( ply, "@set_val=gold=100000000" )
    buy_item(ply, 39, 100)
    local tid = 0
    for k, v in pairs(ply._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    local ts = ply._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
         --   print(t.tmOver,get_tm(ply))
            if t.tmOver > get_tm(ply) + 1 then
                 Rpc:troop_acc( ply, tid, 7014001 )
                 sync(ply)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack(ply, "stateTroop")
end

do_action[TASK_ACTION.DAY_AWARD] = function(ply, task_id, con_num)
    Rpc:require_online_award(ply)
    sync(ply)
end

do_action[TASK_ACTION.GET_RES] = function(ply, task_id, con_type) 
   local build = get_build(ply, 1, con_type - 4) 
   Rpc:reap(ply, build.idx)
   sync(ply)
end

do_action[TASK_ACTION.STUDY_TECH] = function(ply, task_id, con_id, con_level)
    learn_tech(ply, con_id)
end

function learn_tech(ply, tech_id)
    chat(ply, "@all")
    local build = get_build(ply, 0, 10)
    local tech = ply.tech or {}
    local prop = resmng.prop_tech[tech_id]
    for k, v in pairs(prop.Cond or {}) do
        if v[1] == 5 then
            local is_has = false
            for idx, id in pairs(tech) do
                if id == v[2] then
                    is_has = true
                    break
                end
            end
            if is_has == false then
                learn_tech(ply, v[2])
            end
        end
    end
    if prop.Lv > 1 then
        local t_id = prop.Class * 1000000 + prop.Mode * 1000 + prop.Lv - 1
        local is_has = false
        for idx, id in pairs(tech) do
            if id == t_id then
                is_has = true
                break
            end
        end
        if is_has == false then
            learn_tech(ply, t_id)
        end
    end
    Rpc:learn_tech(ply, build.idx, tech_id, 1)
end

do_action[TASK_ACTION.HERO_LEVEL_UP] = function(ply, task_id, level)
    local hero = get_hero( ply, 1 )
    if not hero then return "nohero" end 
    if level >= ply.lv then
        local lv = ply.lv
        local tot_exp = resmng.prop_level[level].Exp or 1000000
        local need_exp = tot_exp - ply.exp
        local cmd = "@addexp=" .. tostring(need_exp)
        chat(ply, cmd)
    end
    hero_lv_up(ply, hero, level)
    --hero_star_up( ply, hero, 3 )
--     local item = get_item( p, 5001206 )
   --  if not item then return "no item "end 
end

do_action[TASK_ACTION.LEARN_HERO_SKILL] = function(ply, task_id, con_pos)
    local hero = get_hero( ply, 1 )
    if not hero then return "nohero" end 
    local item = get_item(ply, 5001206)
    if not item then return "no item" end
    use_hero_skill_item( ply, hero, con_pos, item[1], 1 )
    local item = get_item(ply, 5001206)
    if not item then return "no item" end
    use_hero_skill_item( ply, hero, con_pos, item[1], 1 )
end

do_action[TASK_ACTION.GET_EQUIP] = function(ply, task_id, con_grade, con_num)
    if con_grade == 0 then con_grade = 1 end
    for k, v in pairs(resmng.prop_equip or {}) do
        if v.Class >= con_grade then
            for i = 1, con_num, 1 do
                local cmd = "@addequip=" .. tostring(k)
                chat(ply, cmd)
            end
            break
        end
    end
end

do_action[TASK_ACTION.MAKE_EQUIP] = function(ply, task_id, con_grade, con_num) 
    if con_grade == 0 then con_grade = 1 end
    for k, v in pairs(resmng.prop_equip or {}) do
        if v.Class >= con_grade then
            for i = 1, con_num, 1 do
                local cmd = "@addequip=" .. tostring(k)
                chat(ply, cmd)
            end
            break
        end
    end
end

do_action[TASK_ACTION.SYN_MATERIAL] = function(ply, task_id, con_grade, con_num)
    for k, v in pairs(resmng.prop_item or {}) do
        local grade = v.Color
        if grade == con_grade and v.Class == 6 then
            for i = 1, con_num, 1 do
                local node = resmng.get_conf("prop_item", k)
                local cons = node.Param
                cons = cons.Cons or {cons}
                if not cons then return end 

                for idx, val in pairs(cons) do
                    cmd = "@additem=" .. tostring(val[1]) .. "=" .. tostring(val[2] + 1) 
                    chat( ply, cmd ) 
                    sync(ply)
                end
                Rpc:material_compose2(ply, k, 1)
                sync(ply)
            end
            break
        end
    end
end

do_action[TASK_ACTION.ROLE_LEVEL_UP] = function(ply, task_id, con_level)
    local lv = ply.lv
    local tot_exp = resmng.prop_level[con_level].Exp or 1000000
    local need_exp = tot_exp - ply.exp
    local cmd = "@addexp=" .. tostring(need_exp)
    chat(ply, cmd)
end

do_action[TASK_ACTION.SPY_PLAYER_CITY] = function(ply, task_id, con_num, con_acc)
    --local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_SPY_PLAYER) .. "=" .. tostring(con_num)
    --chat(ply, cmd)
    for i = 1, con_num , 1 do
        chat( ply, "@all" )
        chat( ply, "@addbuf=1=-1" )
        spy_ply(ply)
    end
end

do_action[TASK_ACTION.ATTACK_PLAYER_CITY] = function(ply, task_id, con_num, con_win, con_acc)
    for i = 1, con_num , 1 do
        chat( ply, "@all" )
        chat( ply, "@addbuf=1=-1" )
        atk_ply(ply)
    end
end

do_action[TASK_ACTION.GATHER] = function(ply, task_id, con_type, con_num, con_acc)
    if con_acc == 1 then
        local ach_index = "ACH_TASK_GATHER_RES"..con_type
        if con_type == 0 then
            ach_index = "ACH_COUNT_GATHER"
        end
        local cmd = "@addcount=" .. tostring(resmng[ach_index]) .. "=" .. tostring(con_num)
        chat(ply, cmd)
    end
end

do_action[TASK_ACTION.LOOT_RES] = function(ply, task_id, con_type, con_num, con_acc)
    if con_acc == 1 then
        local ach_index = "ACH_TASK_ATK_RES"..con_type
        local cmd = "@addcount=" .. tostring(resmng[ach_index]) .. "=" .. tostring(con_num)
        chat(ply, cmd)
    end
end

do_action[TASK_ACTION.CAPTIVE_HERO] = function(ply, task_id, con_num)
    local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_CAPTIVE_HERO) .. "=" .. tostring(con_num)
    chat(ply, cmd)
end

do_action[TASK_ACTION.WORLD_CHAT] = function(ply, task_id, con_num)
    chat(ply, "say a world")
end

do_action[TASK_ACTION.JOIN_PLAYER_UNION] = function(ply, task_id)
    local p = get_one(true)
    chat( p, "@buildtop" ) 
    chat( p, "@all" ) 

    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)

    Rpc:union_quit(ply)
    sync(ply)

    Rpc:union_apply(p, ply.uid)
    sync(p)
end

do_action[TASK_ACTION.UNION_SHESHI_DONATE] = function(ply, task_id, con_num, con_acc)
    local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_SHESHI_DONATE) .. "=" .. tostring(con_num)
    chat(ply, cmd)
    --Rpc:union_buildlv_donate(ply, mode)
    --sync(ply)
end

do_action[TASK_ACTION.MARKET_BUY_NUM] = function(ply, task_id, con_type, con_num)
    chat( ply, "@all" ) 
    for i = 1 , con_num, 1 do 
        if con_type == 1 then
            Rpc:black_market_buy(ply, 1)
        end
        if con_type == 2 then
            Rpc:buy_res(ply, 1)
        end
    end
end

do_action[TASK_ACTION.GET_ITEM] = function(ply, task_id, con_id, con_num)
    cmd = "@additem=" .. tostring(con_id) .. "=" .. tostring(con_num + 1) 
    chat( ply, cmd ) 
    sync(ply)
end

do_action[TASK_ACTION.CURE] = function(ply, task_id, con_type, con_num)
    local arm_id =
    { 
        1003002,
        2003002,
        3003002,
        4003002,
    }
    chat( ply, "@all" ) 
    local cmd = "@hurt="..tostring(arm_id[ply.culture]).."=" .. tostring(con_num + 1)
    chat( ply, cmd ) 
    local arm = {
        [arm_id[ply.culture]] = con_num + 1,
    }
    Rpc:cure(ply, arm, 1)
    sync(ply)
end

do_action[TASK_ACTION.HAS_HERO_NUM] = function(ply, task_id, con_quality, con_star, con_num)
    add_all_hero(ply)
    chat( ply, "@all" ) 
    chat( ply, "@set_val=gold=100000000" )
    if con_star > 0 then
        local hero = get_hero( ply, 1 )
        if not hero then return "nohero" end 
        hero_star_up( ply, hero, con_star )
    end
end

function add_all_hero(ply)
    for k , v in pairs(resmng.prop_hero_basic) do
        get_hero(ply, k)
    end
end

function get_build_idx(ply, class, mode, max)
    for k, v in pairs(ply._build or {}) do
        local b_mode = math.floor(v.propid / 100) % 31
        local b_class = math.floor(v.propid / 1000000)
        if b_mode == mode and b_class == class then
            return k
        end
    end
end

function get_item_idx(ply, class, mode, lv)
    local propid = 0
        lv = lv or 1
    local arm = {[3001010] = con_num + 1}
    Rpc:cure(ply, arm, 1)
end

function get_build_idx(ply, class, mode, max)
    for k, v in pairs(ply._build or {}) do
        local b_mode = math.floor(v.propid / 100) % 31
        local b_class = math.floor(v.propid / 1000000)
        if b_mode == mode and b_class == class then
            return k
        end
    end
end

function get_item_idx(ply, class, mode, lv)
    local propid = 0
        lv = lv or 1
    local arm = {[3001010] = con_num + 1}
    Rpc:cure(ply, arm, 1)



end

function get_build_idx(ply, class, mode, max)
    for k, v in pairs(ply._build or {}) do
        local b_mode = math.floor(v.propid / 100) % 31
        local b_class = math.floor(v.propid / 1000000)
        if b_mode == mode and b_class == class then
            return k
        end
    end
end

function get_item_idx(ply, class, mode, lv)
    local propid = 0
        lv = lv or 1
        mode = mode  or 1
        class = class or 1
    if class and mode and lv then
        propid = class * 1000000 + mode * 1000 + lv
    end

    for k, v in pairs(ply._item or {}) do
        if propid ~= 0 then
            if v[2] == propid then
                return k
            end
        end
    end

end

function get_arm_id_by_mode_lv(mode, lv, class)
    for k, v in pairs(resmng.prop_arm or {}) do
        if v.Class == class and v.Mode == mode and v.Lv == lv then
            return k
        end
    end
end

return t1
