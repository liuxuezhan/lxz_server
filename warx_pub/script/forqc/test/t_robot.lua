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
        local ply = get_account()
        loadData(ply)
        --wait_for_ack(ply, "loadData")
        if get_castle_lv(ply) <= 3 then
            do_action[6](ply)
        elseif get_castle_lv(ply) > 3 and  get_castle_lv(ply) <= 6 then
            do_action[6](ply)
            do_action[1](ply)
        else
            do_action[1](ply)
            do_action[2](ply)
            random_num = math.random(1, 7)
            if do_action[random_num] then
                print("ply pos", ply.x, ply.y, random_num)
                --do_action[random_num](ply)
            end
        end
    end

    return "ok"
end

pre_upgrade_list = {
    2,
    2002,
    3,
    2003,
    4,
    2004,
    5,
    1002001,
    1002002,
    1002003,
    1002004,
    1002005,
    2005,
    6,
    10001,
    10002,
    10003,
    10004,
    10005,
    10006,
    2006,
    7,
    2007,
    12007,
    8,
}

function do_first_build(p)
    if get_castle_lv(p) >= 6 then
        return 
    end

    for k, v in pairs(pre_upgrade_list or {}) do
        build_or_upgrade(p, v)
    end
end


do_action = {}

-- 城建
do_action[1] = function(p)
   -- Rpc:loadData(p, "build")
   -- wait_for_ack(p, "loadData")
    if is_building(p) then
        do_action[4](p)
        return 
    end

    do_first_build(p)

    if is_building(p) then
        do_action[4](p)
        return 
    end

    for k, v in pairs(p._build or {}) do
        local prop = resmng.prop_build[ v.propid + 1]
        if prop then
            upgrade(p, k, v.propid + 1)
        end
    end

    for k, v in pairs(resmng.prop_build or {}) do
        if not is_already_build(p, k) and v.Lv == 1 and v.Mode < 21 then
            --print("construct ", p.pid, k)
            construct(p, k)
        end
    end
end

-- 采集
do_action[2] = function(p)
    local etys = get_eye(p, 20)
    local obj = {}
    for k, v in pairs( p._etys or {} ) do
        if is_res(v) then
            local prop = resmng.prop_world_unit[v.propid]
            if prop then
                if get_castle_lv(p) < Gather_Level[ prop.ResMode ] then
                    local arms = {}
                    local count = get_val_by("CountSoldier", p._ef)
                    for id, num in pairs(p._arm) do
                        if num < count then
                            arms[id] = num
                            count = count - num 
                        else
                            arms[id] = count
                            count = 0
                        end
                    end
                    Rpc:gather(p, v.eid, {live_soldier=arms} )
                    sync(p)
                    return 
                end
            end
        end
    end
end

function get_castle_lv(p)
    local build = p._build
    if not build then
        return 1
    end
    local castle = build[1]
    if not castle then
        return 1
    end
    local conf = resmng.get_conf("prop_build", castle.propid)
    return conf.Lv
end

-- 打怪
do_action[3] = function(p)
    local etys = get_eye(p, 20)
    for k, v in pairs( p._etys or {} ) do
        if is_monster(v) then
            local prop = resmng.prop_world_unit[v.propid]
            loadData(p)
            local castle = p._build[1]
            local conf = resmng.get_conf("prop_build", castle.propid)
            if prop and (prop.Clv + 1) > conf.Lv then
                local arms = {}
                local count = get_val_by("CountSoldier", p._ef)
                for id, num in pairs(p._arm) do
                    if num < count then
                        arms[id] = num
                        count = count - num 
                    else
                        arms[id] = count
                        count = 0
                    end
                end
                Rpc:siege(p, v.eid, {live_soldier = arms})
                sync(p)
                return
            end
        end
    end
end

function is_building(p)
    for k, v in pairs(p._build or {}) do
        if v.state == BUILD_STATE.CREATE or v.state == BUILD_STATE.UPGRADE then
            -- or v.state == BUILD_STATE.WAIT then
            return true
        end
    end
    return false
end

--build acc
do_action[4] = function(p)
    for k, v in pairs(p._build or {}) do
        if v.state == BUILD_STATE.CREATE or  v.state == BUILD_STATE.UPGRADE  then
            --or v.state == BUILD_STATE.WAIT then
            Rpc:acc_build(p, k, ACC_TYPE.FREE)
        end
    end

  --  for k, v in pairs(p._build or {}) do
  --      if v.tmOver - gTime > 600 then
  --          local item_idx =  find_acc_item(p)
  --          if item_idx ~= 0 then
  --              Rpc:item_acc_build(p, k, item_idx, 1)
  --              sync(p)
  --          end
  --      end
  --  end
end

function find_acc_item(p)
    Rpc:loadData(p, "item")
    wait_for_ack(p, "loadData")
    for k, v in pairs(p._item or {}) do
        local conf =  resmng.get_conf("prop_item" ,v[2])
        if  conf.Class == ITEM_CLASS.SPEED then
            return k
        end
    end
    return 0
end

--reap
do_action[5] = function(p)
    for k, v in pairs(p._build or {}) do
        local prop = resmng.prop_build[v.propid]
        if prop then
            if prop.Class == 1 then
                Rpc:reap(p, k)
            end
        end
    end
end

-- task
do_action[6] = function(p)
    if is_building(p) then
        do_action[4](p)
    end
    Rpc:loadData(p, "task")  --- loadtask
    wait_for_ack(p, "loadData")
    process_tasks(p)
end

-- day_award
do_action[7] = function(p)
    do_task[TASK_ACTION.DAY_AWARD](p)
end

function process_tasks(ply)    --处理身上的所有任务
    for k, v in pairs(ply._task.cur or {}) do
        local prop = resmng.prop_task_detail[v.task_id]
        if prop then
            if prop.TaskType == 1 then
                process_task(ply, v)
            end
        end
    end
    for k, v in pairs(ply._task.finish or {}) do
        local prop = resmng.prop_task_detail[v]
        process_task(ply, v)
    end

end

function process_task(ply, task)  --处理身上的单个任务
    if type(task) ~= "number" then
        if task.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            print("process task ", ply.pid, task.task_id, task.task_status)
            handle_task(ply, task)
        end
        if task.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
            print("finish task ", ply.pid, task.task_id,  get_table_valid_count(ply.branch_list or {}))
            finish_task(ply, task)
        end
    else
     --   finish_task(ply, task)
    end
end

function finish_task(ply, task)
    if  type(task) ~= "number" then
        Rpc:finish_task(ply, task.task_id)
        if task.task_id == 130010138 then
            Rpc:buy_item(ply, 76, 1, 1)
        end
    else
        Rpc:finish_task(ply, task)
    end
    --wait_for_ack(ply, "finish_task_resp")
    --if ply.task_resp ~= 0 then
    --    WARN("task finish resp error ", task.task_id)
    --end
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

   -- table.insert(task_id_array, 130020101)
   -- table.insert(task_id_array, 130020201)
   -- table.insert(task_id_array, 130020301)
   -- table.insert(task_id_array, 130020401)
   -- table.insert(task_id_array, 130020501)
   -- table.insert(task_id_array, 130020601)
   -- table.insert(task_id_array, 130020701)
   -- table.insert(task_id_array, 130020801)
    --table.insert(task_id_array, 130020901)
    Rpc:accept_task(ply, task_id_array)
    sync(ply)
end

function handle_task(ply, task_info)
    local prop = resmng.prop_task_detail[task_info.task_id]
    if not prop then
        return "error"
    end

    unpack_action(ply, task_info.task_id, unpack(prop.FinishCondition or {}))

end

function unpack_action(ply, task_id, func, ...)
    local key = g_task_func_relation[func]
    if do_task[key] ~= nil then
        return do_task[key](ply, task_id, ...)
    end
end

do_task = {}

do_task[TASK_ACTION.OPEN_UI] = function(ply, task_id, ui_id)
    Rpc:finish_open_ui(ply, ui_id)
    sync(ply)
end 

do_task[TASK_ACTION.RECRUIT_SOLDIER] = function(ply, task_id, con_type, con_level, con_num, con_acc)
    if con_level == 0 then
        con_level = 1
    end
    if con_type == 0 then
        con_type = 1
    end
    local arm_id = get_arm_id_by_mode_lv(con_type, con_level, ply.culture)
    local b = get_build(ply, 2, con_type)
    for i = 1 , math.ceil(con_num / 1000), 1 do
        local train_num =  1000
        if con_num < 1000 then
            train_num = con_num
        end
        if con_acc == 1 then
            Rpc:train(ply, b.idx,  arm_id, train_num, 1)
            sync(ply)
        else
            Rpc:train(ply, b.idx,  arm_id, train_num, 0)
            sync(ply)
        end
    end
end

do_task[TASK_ACTION.ATTACK_SPECIAL_MONSTER] = function(ply, task_id, monster_id)
    local arms = {}
    local count = get_val_by("CountSoldier", ply._ef)
    for id, num in pairs(ply._arm) do
        if num < count then
            arms[id] = num
            count = count - num 
        else
            arms[id] = count
            count = 0
        end
    end
    Rpc:siege_task_npc(ply, task_id, ply.eid, ply.x + 10, ply.y + 10, {live_soldier = arms})
    sync(ply)
end

do_task[TASK_ACTION.ATTACK_LEVEL_MONSTER] = function(ply, task_id, con_type, con_level, con_num)
    local etys = get_eye(ply, 30)
    local obj = {}
    for k, v in pairs( ply._etys or {} ) do
        if is_monster(v) then
            local prop = resmng.prop_world_unit[v.propid]
            if prop then
                if prop.Clv == con_level then
                    local arms = {}
                    local count = get_val_by("CountSoldier", ply._ef)
                    for id, num in pairs(ply._arm) do
                        if num < count then
                            arms[id] = num
                            count = count - num 
                        else
                            arms[id] = count
                            count = 0
                        end
                    end
                    Rpc:siege(ply, v.eid, {live_soldier = arms})
                    sync(ply)
                    return 
                end
            end
        end
    end

    Rpc:gen_boss_req(ply, con_type, con_level)
    wait_for_ack(ply, "gen_boss_eid_ack")
    local arms = {}
    local count = get_val_by("CountSoldier", ply._ef)
    for id, num in pairs(ply._arm) do
        if num < count then
            arms[id] = num
            count = count - num 
        else
            arms[id] = count
            count = 0
        end
    end
    Rpc:siege( ply, ply.boss_eid, { live_soldier=arms } )
    sync(ply)
    ply.boss_eid = nil
    print("atk monster ", con_level)
end

do_task[TASK_ACTION.VISIT_HERO] = function(ply, task_id, con_id, ply_id, real_num)
    local arms = {}
    local count = get_val_by("CountSoldier", ply._ef)
    for id, num in pairs(ply._arm) do
        if num < count then
            arms[id] = num
            count = count - num 
        else
            arms[id] = count
            count = 0
        end
    end
    print("visit hero ", ply_id)
    Rpc:task_visit(ply, task_id, 0, ply.x + 10, ply.y + 10, {live_soldier = arms})
end

do_task[TASK_ACTION.VISIT_NPC] = function(ply, task_id, con_id, con_num)
    local arms = {}
    local count = get_val_by("CountSoldier", ply._ef)
    for id, num in pairs(ply._arm) do
        if num < count then
            arms[id] = num
            count = count - num 
        else
            arms[id] = count
            count = 0
        end
    end
    Rpc:get_city_for_robot_req(p, ACT_NAME.NPC_CITY, 1, {npc_id = con_id })
    wait_for_ack(p, "get_city_for_robot_ack")
    local eid =  p.npc_eid
    print("visit npc", con_id, eid)
    Rpc:task_visit(ply, task_id, eid, ply.x + 10, ply.y + 10, {live_soldier = arms})
end

do_task[TASK_ACTION.MONTH_AWARD] = function(ply, task_id, num)
    Rpc:month_award_get_award(ply) 
    sync(ply)
end

do_task[TASK_ACTION.OPEN_RES_BUILD] = function(ply, task_id, num )  
    Rpc:open_field(ply, ply.field + 1)
    sync(ply)
end

do_task[TASK_ACTION.GET_RES] = function(ply, task_id, con_type) 
    local build = get_build(ply, 1, con_type - 4)
    Rpc:reap(ply, build.idx)
    sync(ply)
end

do_task[TASK_ACTION.DAY_AWARD] = function(ply, task_id, con_num)
    Rpc:require_online_award(ply)
    sync(ply)
end

do_task[TASK_ACTION.UNION_TECH_DONATE] = function(ply, task_id, con_num, con_acc)
    --local u = gTime % 1000000
    --Rpc:union_create(ply, tostring(u), tostring(u % 1000),40,1000)
    --WARN("create u %d ", u)
    --sync(ply)
    for i=1, con_num , 1 do
        Rpc:union_donate(ply, 1001, 1)
        sync(ply)
    end
end

do_task[TASK_ACTION.GET_TASK_ITEM] = function(ply, task_id, con_id, con_num, real_id, real_num)
    local prop = resmng.prop_item[con_id]
    if prop then
        local mode , lv = unpack(prop.Param or {})
        do_task[TASK_ACTION.ATTACK_LEVEL_MONSTER](ply, task_id, mode, lv)
    end
end

do_task[TASK_ACTION.STUDY_TECH] = function(ply, task_id, con_id, con_level)
    learn_tech(ply, con_id)
end

function learn_tech(ply, tech_id)
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
    Rpc:learn_tech(ply, build.idx, tech_id, 0)
end

--抽卡次数
do_task[TASK_ACTION.GACHA_MUB] = function(ply, task_id, con_type, con_num)
    ply.gacha_num = ply.gacha_num or 0
    local prop = resmng.prop_task_detail[task_id]
    if prop then
        if con_type == 1 then
            if  ply.gacha_num < con_num then
                Rpc:do_gacha(ply, 1)
                ply.gacha_num = ply.gacha_num  + 1
                sync(ply)
            end
        else
            if  ply.gacha_num < con_num then
                print("do gacha 3",  ply.gacha_num)
                Rpc:do_gacha(ply, 3)
                ply.gacha_num = ply.gacha_num  + 1
                sync(ply)
            end
        end
    end
end

do_task[TASK_ACTION.LEARN_HERO_SKILL] = function(ply, task_id, con_pos)
    local item_list = 
    {
        5001101,
        5001102,
        5001103,
        5001104,
        5001105,
        5001106,
    }
    local hero = get_hero( ply, 1 )
    if not hero then return "nohero" end 
    for i= 1, con_pos, 1 do
        hero_star_up( ply, hero, i )
        use_hero_skill_item( ply, hero, item_list[i], 1 , i)
    end
end

do_task[TASK_ACTION.HERO_LEVEL_UP] = function(ply, task_id, level)
    local prop = resmng.prop_task_detail[task_id]
    if prop then
        local hero = get_hero( ply, 1 )
        if not hero then return "nohero" end 
        hero_lv_up(ply, hero, level)
    end
    --hero_star_up( ply, hero, 3 )
--     local item = get_item( p, 5001206 )
   --  if not item then return "no item "end 
end

do_task[TASK_ACTION.CITY_BUILD_LEVEL_UP] = function(player, task_id, con_type, con_num, con_level)
    local cur_num = 0
    local cur_level = 0
    local idx = 0
    local propid = 0
    for k, v in pairs(player._build or {}) do 
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
            else
                idx = k
                propid = v.propid
            end
        end
    end

    if con_num > cur_num then 
        if idx ~= 0 then
            upgrade(player, idx, propid + 1)
        else
            propid = build_propid_by_type(con_type)
            construct(player, propid)
        end
    end
    sync(player)
    do_action[4](player)

end

function build_propid_by_type(con_type)
    for k, v in pairs(resmng.prop_build or {})  do
        if con_type == v.Specific and v.Lv == 1 then
            return v.ID
        end
    end
end

return t1
