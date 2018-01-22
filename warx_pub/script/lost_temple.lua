module( "lost_temple", package.seeall )
module_class("lost_temple",
{
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    propid = 0,
    state = 0,
    defender = 0,
    uid = 0,
    pid = 0,
    startTime = 0,
    endTime = 0,
    my_troop_id = 0,
    timers = {},
    size = 0,
    band_id = 0,
    uname = "",
    ualias = "",
    born = 0,
    --atk_troops= {},    --攻击该城市的部队
    --leave_troops = {},  --从该城市出发的部队
}
)

local zset = require "frame/zset"

start_time = start_time or gTime  --本期活动开始世界
end_time = end_time or gTime  --本期活动开始世界
actTimer = actTimer or 0
actState = actState or 0
cityPool = cityPool or {}
citys = citys or {}
seq_citys = seq_citys or {}
map_lts = map_lts -- 不要加 {}

function send_rank_award_tm()
    if actState == 1 then
        return end_time
    end
    if actState == 0 or actState == 2 then
        local st_tm, end_tm = get_next_active_tm()
        return end_tm
    end
end

function get_next_active_tm()
    local prepare_time =  1800
    if actState == 1 then
        local prop_off =  resmng.get_conf("prop_lt_stage", 0) 
        local prop_on = resmng.get_conf("prop_lt_stage", 1)
        return end_time + prop_off.Spantime + prepare_time, end_time + prop_on.Spantime + prop_off.Spantime
    else
        local prop = resmng.get_conf("prop_lt_stage", 1)
        if prop then
            return end_time, end_time + prop.Spantime
        end
    end
end

function reset_map_lt_info()
    map_lts = nil
end

--每个npccity 的 lv  等于 poolRule k 的
poolRule = {
    {1, 4},
    {2, 10},
    {1, 10},
    {1, 10},
}

function mark(m)
    local db = dbmng:getOne(m.eid)
    if not m.marktm then
        m.marktm = gTime
        db.lost_temple:insert(m._pro)
    else
        m.marktm = gTime
        db.lost_temple:update({_id = m._id}, m._pro)
    end
end

--初始化随机池用于选择lt 出生点
function init_pool()
    for k, v in pairs(resmng.prop_world_unit or {}) do
        local pool = cityPool[v.Lv] or {}
        if v.Class == CLASS_UNIT.NPC_CITY then
            for i = 1, poolRule[v.Lv][1] do
                table.insert(pool, v.ID)
            end
            cityPool[v.Lv] = pool
        end
    end
    if citys then
        for k, v in pairs(citys or {}) do
            local lt = get_ety(k)
            if lt then
                if lt.band_id ~= 0 then
                    remove_pool(lt.band_id)
                end
            end
        end
    end
end

function remove_pool(id)
    local prop = resmng.prop_world_unit[id]
    if prop then
        for k, v in pairs(cityPool[prop.Lv] or {}) do
            if v == id then
                table.remove(cityPool[prop.Lv], k)
            end
        end
    end
end

function add_pool(id)
    if id ~= 0 then
        local prop = resmng.prop_world_unit[id]
        if prop then
            table.insert(cityPool[prop.Lv], id)
        end
    end
end

--初始化活动 跟进策划需求 
function init_activity()
    if not actTimer or actTimer == 0 then
        local time = 10
        local timerId = timer.new("lost_temple", time, 1)
        actTimer = timerId
        gPendingSave.status["lostTemple"].timer = timerId
    end
end

function load_lost_temple()
    local db = dbmng:getOne()
    local info = db.lost_temple:find({})
    while info:hasNext() do
        local m = lost_temple.wrap(info:next())
        gEtys[m.eid] = m
        citys[m.eid] = m.eid
        add_seq_citys(m)
        local tr = troop_mng:get_troop(m.my_troop_id)
        if tr then
            local owner = get_ety(tr.owner_eid)
            if owner and is_ply(owner) then
                local lt_citys = owner.lt_citys or {}
                lt_citys[m.eid] = nil
                owner.lt_citys = lt_citys
            end
        end
        etypipe.add(m)
    end

    --init_activity()
    --init_redis_list()
    init_pool()
    load_lt_state()
end

function load_lt_state()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "lostTemple"})
    if not info then
        info = {_id = "lostTemple"}
        db.status:insert(info)
    end
    start_time = info.start_time or 0
    end_time = info.end_time or 0
    actState = info.actState or 0
end

function add_seq_citys(city)
    local prop = resmng.prop_world_unit[city.propid]
    if prop then
        local citys = seq_citys[prop.Mode] or {}
        table.insert(citys, city.eid)
        seq_citys[prop.Mode] = citys
    end
    reset_map_lt_info()
end

function clear_citys_timer()
    for k, v in pairs(citys or {}) do 
        local city = get_ety(k)
        if city then
            clear_timer(city)
        end
    end
end

function clean_timer()
    timer.del(timerId)
end

function update_ply_score(key, score)
    local ply = getPlayer(key)
    if ply then
        local u = ply:get_union()
        if u then
            u:add_score_in_u(key, ACT_TYPE.LT, score)
        end
    end

    local org_score = rank_mng.get_score(10, key) or 0
    score = score + org_score
    rank_mng.add_data(10, key, {score})
    --任务
    local ply = getPlayer(key)
    task_logic_t.process_task(ply, TASK_ACTION.LOSTTEMPLE_SCORE, score)
end

function update_union_score(key, score)
    local org_score = rank_mng.get_score(9, key) or 0
    score = score + org_score
    rank_mng.add_data(9, key, {score})
end

function try_start_lt()
    local id = actState
    local prop = resmng.prop_lt_stage[id]
    if prop then
        local prepare_time =  0
       -- if not  player_t.debug_tag then
            if actState == LT_STATE.LOCK then
                if ( gTime + prepare_time - act_mng.start_act_tm) >= prop.Spantime - 30 then
                    timer.new("start_lt", prepare_time + 1)
                   -- lt_ntf(resmng.LT_OPEN)
                end
                start_time = act_mng.start_act_tm
                end_time = start_time + prop.Spantime + prepare_time
                gPendingSave.status["lostTemple"].start_time = start_time
                gPendingSave.status["lostTemple"].end_time = end_time
            end

            if actState == LT_STATE.DOWN then
                if ( gTime + prepare_time - end_time) >= prop.Spantime - 30 then
                    timer.new("start_lt", prepare_time + 1)
                  --  lt_ntf(resmng.LT_OPEN)
                end
            end
       -- else
         --   prepare_time = 10
           -- timer.new("start_lt", prepare_time)
           -- lt_ntf(resmng.LT_OPEN)
       -- end
    end
end

function init_lt()
    for k, v in pairs(citys or {}) do
        local city = get_ety(v)
        if city then
            close_temple(city)
        end
    end
    seq_citys = {}
    actState = 0
    gPendingSave.status["lostTemple"].actState  = actState
    start_time = gTime
    gPendingSave.status["lostTemple"].end_time = start_time
    end_time = gTime
    gPendingSave.status["lostTemple"].end_time = end_time
    clear_timer()
    reset_map_lt_info()
end

function lt_ntf(notify_id)
    local prop = resmng.get_conf("prop_act_notify", notify_id)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
        end

        if prop.Chat1 then 
            player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", prop.Chat1, {})
        end

    end

end

function start_lt()
    lt_ntf(resmng.LT_START)
    start_time = get_zero_tm(gTime)
    gPendingSave.status["lostTemple"].start_time  = start_time
    actState = LT_STATE.ACTIVE
    gPendingSave.status["lostTemple"].actState  = actState

    local prop = resmng.prop_lt_stage[actState]
    if prop then
        end_time = gTime + prop.Spantime
        gPendingSave.status["lostTemple"].end_time = end_time
    end

    init_pool()
    gen_lost_temples()


    rank_mng.clear(10)-- 清楚排行榜
    rank_mng.clear(9)

    clear_timer()
    -- debug
    set_timer(LT_STATE.DOWN)

    --offline ntf
    offline_ntf.post(resmng.OFFLINE_NOTIFY_TOWER)

    update_lt_ntf()  -- 推送更新通知
end

function update_lt_ntf()
    local lts = player_t.get_lt_map_info()
    if lts then
        subscribe_ntf.send_sub_ntf( "map_info", "lt_map_info_req", lts)
    end
end

function gen_lost_temples()
    gen_normal_temples()
    gen_elite_temples()
end

function gen_temple_by_propid(propid)
    if actState ~= LT_STATE.ACTIVE then
        return
    end

    local prop = resmng.prop_world_unit[propid]

    if not prop then
        return
    end

    local lv = prop.Lv
    local bandId = get_band_city(lv)
    local lt_prop = resmng.prop_world_unit[bandId]
    local grade = 1
    if lv > 1 then grade = 2 else grade = 3 end
    if lt_prop then
        respawn(math.floor(lt_prop.X/16), math.floor(lt_prop.Y/16), grade, bandId)
    else
         WARN("lost temple not find band npc prop %d", bandId)
    end

end

function gen_normal_temples()
    local num = 600
    local index = math.floor(math.sqrt(6400 * 16 * 16 / num))
    for i = 1, 80 * 16 , index do
        for j = 1, 80 * 16, index  do
            respawn(math.floor(i/16), math.floor(j/16), 1)
        end
    end
end

function gen_elite_temples()
    for k, v in pairs(poolRule or {}) do
        for i = 1, v[2] do
            -- debug
            local bandId = get_band_city(k)
            local prop = resmng.prop_world_unit[bandId]
            local grade = 1
            if k == 1 then grade = 3 else grade = 2 end
           -- INFO("[LT] gen lt ", k, i, v[2], grade)
            if prop then
                INFO("[LT] npc city band pos %d %d %d", prop.X, prop.Y, prop.ID)
                respawn(math.floor(prop.X/16), math.floor(prop.Y/16), grade, bandId, false)
            end
        end
    end
end

function get_band_city(lv)
    local list = cityPool[lv] or {}
    if #list >= 1 then
        local index = math.random(#list)
        return  list[index]
    end
end

function get_prop(grade)
    for k, v in pairs(resmng.prop_world_unit or {}) do
        if v.Class == CLASS_UNIT.LOST_TEMPLE and v.Mode == grade  then
            return v
        end
    end
end

function get_pos_by_grade(tx, ty, prop,  grade)
    local x, y
    local r = prop.Size or 1
    x, y = monster_city.get_pos_in_range(tx, ty, 2, 2, r)

    return x, y

end

function respawn(tx, ty, grade, bandId, ntf_tag)
    local prop = get_prop(grade)
    if not prop then
        return 
    end

    local x, y = get_pos_by_grade(tx, ty, prop, grade)
    if x then
        local eid = get_eid_lost_temple()
        if eid then
            local m = {}
            m._id = eid
            m.eid = eid
            m.x = x
            m.y = y
            m.zx = tx
            m.zy = ty
            m.born = gTime
            m.grade = grade
            m.size = prop.Size
            m.propid = prop.ID
            m = new(m)
            gEtys[ eid ] = m
            citys[eid] = eid
            add_seq_citys(m)
            if bandId then
                m.band_id = bandId
                remove_pool(bandId)
            end
            INFO("[LT] lost temple pos x = %d, y = %d, eid = %d", m.x, m.y, m.eid)
            mark(m)
            local union = unionmng.get_union(m.uid)
            if union then
                m.uname = union.name
                m.ualias = union.alias
            end

            if ntf_tag == nil or ntf_tag == true then
                new_lt_notify(m)
            end

            etypipe.add(m)
        end
    end
end

function new_lt_notify(self)
    local notify_id = 0
    if self.grade == 2 then
        notify_id = resmng.MIDDLE_LT_REFRESH
    end

    if self.grade == 3 then
        notify_id = resmng.BIG_LT_REFRESH
    end

    if notify_id == 0 then
        return
    end

    local prop = resmng.get_conf("prop_act_notify", notify_id)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{self.x, self.y})
        end

        if prop.Chat1 then 
            player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", prop.Chat1, {self.x, self.y, self.x, self.y})
        end

    end
end

function reset_lt(city)
    npc_city.change_city_uid(city, 0)
    --city.pid = 0
    city.uname = ""
    city.ualias = ""
    city.startTime = 0
    city.endTime = 0
    clear_timer(city)
    local tr = city:get_my_troop()
    if tr then
        local owner = get_ety(tr.owner_eid)
        if owner and is_ply(owner) then
            local lt_citys = owner.lt_citys or {}
            lt_citys[city.eid] = nil
            owner.lt_citys = lt_citys
        end
    end
    etypipe.add(city)
end

function end_lt()
    lt_ntf(resmng.LT_END)
    for k, v in pairs(citys or {}) do
        local city = get_ety(v)
        if city then
            close_temple(city)
        end
    end
    seq_citys = {}
    actState = LT_STATE.DOWN
    gPendingSave.status["lostTemple"].actState  = actState
    end_time = gTime
    gPendingSave.status["lostTemple"].end_time = end_time
    clear_timer()
    send_score_award()
    -- debug
    --set_timer(LT_STATE.ACTIVE)
    reset_map_lt_info()
    update_lt_ntf()  -- 推送更新通知
end

function close_temple(city)
    clear_timer(city)
    --local tr = get_my_troop(city)
    local tr = troop_mng.get_troop(city.my_troop_id)
    if tr and tr.owner_uid ~= 0 then
        king_city.troop_back(tr)
    end

    citys[city.eid] = nil
    rem_ety(city.eid)
end

function after_fight(ackTroop, defenseTroop)

    local city = get_ety(ackTroop.target_eid) 

    if check_atk_win(defenseTroop) then
        npc_city.change_city_uid(city, ackTroop.owner_uid)
        --city.pid = ackTroop.owner_pid
        city.my_troop_id = 0
        local union = unionmng.get_union(city.uid)
        if union then
            city.uname = union.name
            city.ualias = union.alias
        end

        local owner = get_ety(ackTroop.owner_eid)
        if owner and is_ply(owner) then
            local lt_citys = owner.lt_citys or {}
            lt_citys[ackTroop.target_eid] = ackTroop.target_eid
            owner.lt_citys = lt_citys
        end

        local defer = get_ety(defenseTroop.owner_eid)
        if defer and is_ply(defer) then
            local lt_citys = defer.lt_citys or {}
            lt_citys[defer.eid] = nil
            defer.lt_citys = lt_citys
        end

        --npc_city.try_hold_troop(city, ackTroop)

        new_defender_state(city, ackTroop)
        etypipe.add(city)

        union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, city)
        local conf
        if city.grade == 3 then
            conf = resmng.prop_act_notify[resmng.LT_OCCUPY] 
        elseif city.grade == 2 then
            conf = resmng.prop_act_notify[resmng.LT_OCCUPY_MID] 
        end
        if conf then
            if conf.Notify then
                Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{city.x, city.y, union.alias, union.name})
            end

            if conf.Chat1 then
                player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat1, {city.x, city.y, union.alias, union.name})
            end
        end
    end
end

function deal_cross(self)
    clear_timer(self)
    set_timer(2, self)
    rem_ety(self.eid)
end

function deal_troop(atkTroop, defenseTroop)
    if check_atk_win(defenseTroop) then
        local city = get_ety(atkTroop.target_eid) 
        if is_ply(defenseTroop.owner_eid) then 
            --troop_t.dead_to_live_and_hurt( defenseTroop, 0.95 )
            defenseTroop:back()
        else
            troop_mng.delete_troop(defenseTroop._id)
        end

        if city.uid ~= atkTroop.owner_uid then
            --troop_t.dead_to_live_and_hurt( atkTroop, 0.95 )
            atkTroop:back()
        else
            --atkTroop:home_hurt_tr()
            local union = unionmng.get_union(atkTroop.owner_uid)
            if check_union_cross(union) then
                atkTroop:back()
                city:deal_cross()
            else
                npc_city.try_hold_troop(city, atkTroop)
            end
        end
    else
        if is_ply(atkTroop.owner_eid) then
            --troop_t.dead_to_live_and_hurt( atkTroop, 0.95 )
            atkTroop:back()
        else
            troop_mng.delete_troop(atkTroop._id)
        end
        --defenseTroop:home_hurt_tr()
    end
end

function check_atk_win(troop)
    return troop:is_no_live_arm()
end

function deal_dead_troop(troop)
    for pid, arm in pairs(troop.arms or {}) do
        for k, v  in pairs(arm.dead_soldier or {}) do
            arm.live_soldier[k] = (arm.live_soldier[k] or 0 ) + math.floor(v * 0.95)
            arm.hurt_soldier[k] = (arm.hurt_soldier[k] or 0 ) + math.floor(v * 0.05)
        end
    end
end

function finish_grap_state(self)
    local union = unionmng.get_union(self.uid)
    local res = resmng.prop_world_unit[self.propid].Fix_award

    --世界事件
    world_event.process_world_event(WORLD_EVENT_ACTION.GATHER_NUM, resmng.DEF_RES_SNAMAN_STONE, res)
    
    if union then
        update_union_score(union.uid, res)
    end

   -- local content={x = self.x, y = self.y, carry ={{"res", 20, math.ceil(res)}}, buildid=self.propid}
   -- local members = union:get_members()
   -- if members then
   --     for pid, ply in pairs(members) do
   --         ply:report_new( MAIL_REPORT_MODE.GATHER, content )
   --     end
   -- end

    local tr = self:get_my_troop()
    if tr then
        local all_pow = math.ceil(tr:get_tr_pow())

        if  all_pow == 0 then
            all_pow  = 1
        end

        for k, v in pairs(tr.arms or {}) do
            local pow = math.ceil(tr:calc_pow(k))
            local score = res * pow / all_pow
            local ply = getPlayer(k)
            if ply then
                local content={x = self.x, y = self.y, carry ={{"res", 20, math.ceil(score)}}, buildid=self.propid}
                ply:report_new( MAIL_REPORT_MODE.GATHER, content )
            end
            update_ply_score(k, score)
        end
    end

    clear_timer(self)
    set_timer(2, self)
    if tr then
        local owner = get_ety(tr.owner_eid)
        if owner and is_ply(owner) then
            local lt_citys = owner.lt_citys or {}
            lt_citys[self.eid] = nil
            owner.lt_citys = lt_citys
        end
        tr:back()
        watch_tower.building_def_clear(self, tr)
    end


    rem_ety(self.eid)
    citys[self.eid] = nil

    if self.grade == 3 then
        local conf = resmng.prop_act_notify[resmng.LT_GATHER] 
        if conf then
            if conf.Notify then
                Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{self.x, self.y, union.alias, union.name})
            end

            if conf.Chat1 then
                player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat1, {self.x, self.y, union.alias, union.name})
            end
        end
    end

    add_pool(self.band_id)
    update_act_tag() 

end

function new_defender_state(self, troop)
    clear_timer(self)
    set_timer(1, self)
    self.startTime = gTime
    local time = resmng.prop_world_unit[self.propid].Spantime
    self.endTime = gTime + time 

    troop.tmStart = gTime
    troop.tmOver = self.endTime
    troop:do_notify_owner({tmStart = troop.tmStart, tmOver = troop.tmOver})
    watch_tower.update_watchtower_speed(troop)

end

function clear_timer(self)
    if self then
        timer.del(self.timers)
        self.timers = nil
    else
        timer.del(actTimer)
        gPendingSave.status["lostTemple"].timer = 0
    end
end

function set_timer(state, self)
    if state == nil then state = self.state end
    -- to do
    local time = 0
    if self then
        if state == 2 then --- 遗迹塔刷新
            time = resmng.prop_world_unit[self.propid].Reborntime
        elseif state == 1 then  -- 遗迹塔被领
            time = resmng.prop_world_unit[self.propid].Spantime
        end
    else
        time = resmng.prop_lt_stage[actState].Spantime
    end
    if self then
        local timerId = 0
        if state == 2 then
            timerId = timer.new("lost_temple", time, state, self.eid, self.band_id)
        else
            timerId = timer.new("lost_temple", time, state, self.eid)
        end
    
        self.timers= timerId
    else
        local deadline = start_time + time
        local left_tm = deadline - gTime
        local timerId = timer.new("lost_temple", left_tm, state)
        actTimer = timerId
        gPendingSave.status["lostTemple"].timer = timerId
    end
end

function get_my_troop(self)
    local tr = false
    if self.my_troop_id then
        tr = troop_mng.get_troop(self.my_troop_id)
        if tr then return tr end
    end

    if self.uid == 0 or self.uid == self.propid then

        local  conf = resmng.get_conf("prop_world_unit", self.propid)
        if conf then
            local sx, sy = get_ety_pos(self)
            tr = troop_mng.create_troop(TroopAction.HoldDefenseLT, self, self)
            if conf.Arms then
                local arm = {}
                for _, v in pairs(conf.Arms or {}) do
                    arm[ v[1] ] = v[ 2 ]
                end
                --tr:add_arm(self.propid, {live_soldier = arm})
                tr:add_arm(0, {live_soldier = arm,heros = conf.Heros or {0,0,0,0}})
            end
        end
        self.my_troop_id = tr._id
    else
        tr = troop_mng.create_troop(TroopAction.HoldDefenseLT, self, self)
        troop_mng.delete_troop(tr)
    end

    if tr then
        --tr.owner_uid = self.uid
        return tr
    end
end

function test(ply)
--    local time = 10
  --  local timerId = timer.new("lost_temple", time, 1)
   update_ply_score(ply.pid, 19999990)
   update_union_score(ply.uid, -102122220)

end

function find_rank_prop(rank, score, prop)
    while true do 
        local v = prop[rank]
        if not v then
            break
        end
        if score >= v.Cond then
            return v
        end
        rank = rank + 1
    end
    return
end


function send_score_award()
    local prop = resmng.prop_lt_rank_award
    if prop then
        local num = 1
        for k, v in pairs(prop or {}) do
            local plys = rank_mng.get_range(10, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local ply = getPlayer(tonumber(pid))
                local score = rank_mng.get_score(10, tonumber(pid)) or 0
                INFO("[LT] lost temple person rank %d, %d, %d", num, tonumber(pid), score) 
                if ply then
                    local Award = find_rank_prop(k, score, prop)
                    if Award then
                        ply:send_system_notice(10011, {}, {num}, Award.Award)
                        num = num + 1
                    end
                end

                --if score > v.Cond then
                --    local ply = getPlayer(tonumber(pid))
                --    if ply then
                --        ply:send_system_notice(10011, {}, {num}, v.Award)
                --        num = num + 1
                --    end
                --end
            end
        end
    end

    local u_award = resmng.prop_lt_union_award
    if not u_award then return end

    local _, tops = rank_mng.load_rank( 9 )
    if tops then
        for uid, data in pairs(tops or {}) do
            local score = data[3] or 0
            for k, conf in pairs(u_award or {}) do
                if score > conf.Cond[1] and score < conf.Cond[2] then
                    local union = unionmng.get_union(uid)
                    if union then
                        local _members = union:get_members()
                        for pid, ply in pairs(_members or {}) do
                            if (rank_mng.get_score(10, pid) or 0) > conf.Cond[3] then
                                ply:send_system_notice(10007, {}, {}, conf.Award)
                            end
                        end
                    end
                    break
                end
            end
        end
    end
end

function eye_info(self, pack)
    local tr = self:get_my_troop()
    if tr then
        pack.troop = tr:get_info()
    end
end

function update_act_tag()
    act_tag = gTime
end

