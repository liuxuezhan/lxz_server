local t1 = {}

function t1.action()
    local online_num = 100
    local cur_num = 0
    local random_num = 0
    local num_pre_60 = 0
    local start_time = gTime
    while true do
        if gTime - start_time > 10 then
            start_time = gTime
            print("test do action pre 60 num = ", num_pre_60, gTime)
            num_pre_60 = 0
        end
        num_pre_60 = num_pre_60 + 1
        local p = {}
        p = get_one()
        chat(p, "@all")
        random_num = math.random(1, 100)
        if do_action[random_num] then
            do_action[random_num](p)
        end
    end

    return "ok"
end

do_action = {}
--do_action[TASK_ACTION.OCC_NPC_CITY] = function(ply)
do_action[1] = function(ply)
    local con_type = math.random(5)
    if con_type == 5 then
        atk_king(ply, 1, true)
    else
        atk_npc(ply, con_type)
    end
end

--do_action[TASK_ACTION.OPEN_UI] = function(ply)
do_action[2] = function(ply)
    local ui_id = math.random(10)
    Rpc:finish_open_ui(ply, ui_id)
    sync(ply)
end

--do_action[TASK_ACTION.RECRUIT_SOLDIER] = function(ply)
do_action[3] = function(ply)
    local con_level = 0
    local con_type = 0
    local con_num = 1000
    if con_level == 0 then
        con_level = 1
    end
    if con_type == 0 then
        con_type = 1
    end
    
    local arm_id = get_arm_id_by_mode_lv(con_type, con_level, ply.culture)
    --chat(ply, "@buildall")
    local b = get_build(ply, 2, con_type)
    if not b then
        return
    end
    chat(ply, "@all")
    chat( ply, "@set_val=gold=100000000" )
    for i = 1 , math.ceil(con_num / 1000), 1 do
        local train_num =  1000
        if con_num < 1000 then
            train_num = con_num
        end
        Rpc:train(ply, b.idx,  arm_id, train_num, 1)
        sync(ply)
    end
end

--do_action[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(ply)
do_action[4] = function(ply)

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


--do_action[TASK_ACTION.MONTH_AWARD] = function(ply)
do_action[5] = function(ply)
    Rpc:month_award_get_award(ply)
    sync(ply)
end

--do_action[TASK_ACTION.UNION_TECH_DONATE] = function(ply)
do_action[6] = function(ply)
    chat(ply, "@all")
    local con_num = math.random(10)
    for i=1, con_num , 1 do
        Rpc:union_donate(ply, 1001, 1)
        sync(ply)
    end
end

--do_action[TASK_ACTION.OPEN_RES_BUILD] = function(ply)
do_action[7] = function(ply)
    chat(ply, "@all")
    Rpc:open_field(ply, (ply.field or 0 )+ 1)
    sync(ply)
end

--do_action[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(ply)
do_action[8] = function(ply)
    chat( ply, "@addscore=999999999" )
    local con_level = math.random(25)
    local con_type = 1
    if con_level >= 30 and con_level < 200 then
        chat( ply, "@addscore=999999999" )
        chat( ply, "@daypass" )
    end

    if con_level == 200 then
        atk_king(ply, 1, true)
        chat( ply, "@addscore=100000005" )
        chat( ply, "@endkw" )
    end

    local cmd = "@genboss" .. "=" .. tostring(con_type) .. "=" ..tostring(con_level)
    Rpc:chat( ply, 0, cmd, 0 )
    wait_for_ack(ply, "gen_boss_eid_ack")
    --for i = 1, con_level, 30 do
      --  chat( ply, "@initarm" )
        chat( ply, "@all" )
        local arms = {}
        for id, num in pairs(ply._arm) do
            arms[id] = num
        end
        chat( ply, "@addsinew=10" )
        chat( ply, "@debug1" )
        chat( ply, "@addbuf=1=-1" )
        Rpc:siege( ply, ply.boss_eid, { live_soldier=arms } )
        sync(ply)
        acc_troop(ply, ply.boss_eid)
        acc_troop(ply, ply.boss_eid)
    --end
    ply.boss_eid = nil
    print("atk monster ", con_level)
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

--do_action[TASK_ACTION.DAY_AWARD] = function(ply)
do_action[9] = function(ply)
    Rpc:require_online_award(ply)
    sync(ply)
end

--do_action[TASK_ACTION.GET_RES] = function(ply) 
do_action[10] = function(ply)
    local con_type = math.random(4)
   local build = get_build(ply, 1, con_type - 4) 
   if build then
       Rpc:reap(ply, build.idx)
       sync(ply)
   end
end

--do_action[TASK_ACTION.STUDY_TECH] = function(ply)
do_action[11] = function(ply)
    learn_tech(ply)
end

function learn_tech(ply)
    local class = math.random(3)
    local mode = math.random(27)
    local lv = math.random(15)
    local tech_id = class * 1000000 + mode * 1000 + lv

    chat(ply, "@all")
    local build = get_build(ply, 0, 10)
    local tech = ply.tech or {}
    local prop = resmng.prop_tech[tech_id]
    if not prop then
        return
    end
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

--do_action[TASK_ACTION.HERO_LEVEL_UP] = function(ply)
do_action[12] = function(ply)
    local level = math.random(50)
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

--do_action[TASK_ACTION.LEARN_HERO_SKILL] = function(ply)
do_action[13] = function(ply)
    local con_pos = math.random(6)
    local item_list = 
    {
        5001101,
        5001102,
        5001103,
        5001104,
        5001105,
        5001106,
    }
    local hero = get_hero( ply, 21 )
    if not hero then return "nohero" end 
    for i= 1, con_pos, 1 do
        hero_star_up( ply, hero, i )
        use_hero_skill_item( ply, hero, item_list[i], 100 , i)
    end
end

--do_action[TASK_ACTION.GET_EQUIP] = function(ply)
do_action[14] = function(ply)
    local con_grade = math.random(4)
    local con_num = 1

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

--do_action[TASK_ACTION.MAKE_EQUIP] = function(ply) 
do_action[15] = function(ply)
    local con_grade = math.random(4)
    local con_num = 1
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

--do_action[TASK_ACTION.SYN_MATERIAL] = function(ply)
do_action[16] = function(ply)
    local con_grade = math.random(6)
    local con_num = 1
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

--do_action[TASK_ACTION.ROLE_LEVEL_UP] = function(ply)
do_action[17] = function(ply)
    local con_level = math.random(50)
    local lv = ply.lv
    local tot_exp = resmng.prop_level[con_level].Exp or 1000000
    local need_exp = (tot_exp - (ply.exp or 100)) or 100
    local cmd = "@addexp=" .. tostring(need_exp)
    chat(ply, cmd)
end

--do_action[TASK_ACTION.SPY_PLAYER_CITY] = function(ply)
do_action[18] = function(ply)
    --local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_SPY_PLAYER) .. "=" .. tostring(con_num)
    --chat(ply, cmd)
    chat( ply, "@all" )
    chat( ply, "@addbuf=1=-1" )
    spy_ply(ply)
end

--do_action[TASK_ACTION.ATTACK_PLAYER_CITY] = function(ply)
do_action[19] = function(ply)
    local con_num = 1
    if con_num >= 50 then
        con_num = 50
    end
    for i = 1, con_num , 1 do
        chat( ply, "@all" )
        chat( ply, "@addbuf=1=-1" )
        atk_ply(ply)
    end
end

--do_action[TASK_ACTION.GATHER] = function(ply)
do_action[20] = function(ply)
    local con_type = math.random(4)
    local con_acc = 1
    local con_num = 1
    if con_acc == 1 then
        local ach_index = "ACH_TASK_GATHER_RES"..con_type
        if con_type == 0 then
            ach_index = "ACH_COUNT_GATHER"
        end
        local cmd = "@addcount=" .. tostring(resmng[ach_index]) .. "=" .. tostring(con_num)
        chat(ply, cmd)
    end
end

--do_action[TASK_ACTION.LOOT_RES] = function(ply)
do_action[21] = function(ply)
    --if con_acc == 1 then
    --    local ach_index = "ACH_TASK_ATK_RES"..con_type
    --    local cmd = "@addcount=" .. tostring(resmng[ach_index]) .. "=" .. tostring(con_num)
    --    chat(ply, cmd)
    --end
    atk_ply(ply)
end

--do_action[TASK_ACTION.CAPTIVE_HERO] = function(ply)
do_action[22] = function(ply)
    local con_num = 1
    local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_CAPTIVE_HERO) .. "=" .. tostring(con_num)
    chat(ply, cmd)
end

--do_action[TASK_ACTION.WORLD_CHAT] = function(ply)
do_action[23] = function(ply)
    chat(ply, "say a world")
end

--do_action[TASK_ACTION.JOIN_PLAYER_UNION] = function(ply)
do_action[24] = function(ply)
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

--do_action[TASK_ACTION.UNION_SHESHI_DONATE] = function(ply)
do_action[25] = function(ply)
    local con_num = 1
    local cmd = "@addcount=" .. tostring(resmng.ACH_TASK_SHESHI_DONATE) .. "=" .. tostring(con_num)
    chat(ply, cmd)
    --Rpc:union_buildlv_donate(ply, mode)
    --sync(ply)
end

--do_action[TASK_ACTION.MARKET_BUY_NUM] = function(ply)
do_action[26] = function(ply)
    local con_type = math.random(1)
    local con_num = 1
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

--do_action[TASK_ACTION.GET_ITEM] = function(ply)
do_action[27] = function(ply)
    local con_id = 5001640
    local con_num = 1
    cmd = "@additem=" .. tostring(con_id) .. "=" .. tostring(con_num + 1) 
    chat( ply, cmd ) 
    sync(ply)
end

--do_action[TASK_ACTION.CURE] = function(ply)
do_action[28] = function(ply)
    local con_num = math.random(100)
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
    if arm_id [ply.culture] then
        local arm = {
            [arm_id[ply.culture]] = con_num + 1,
        }
        Rpc:cure(ply, arm, 1)
        sync(ply)
    end
end

--do_action[TASK_ACTION.HAS_HERO_NUM] = function(ply)
do_action[29] = function(ply)
    local con_star = math.random(5)
    local con_num = 1
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
