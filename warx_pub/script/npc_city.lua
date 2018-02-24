module( "npc_city", package.seeall )
module_class("npc_city", 
{
    _id = 0,
    lv = 1,
    x = 0,
    y = 0,
    eid = 0,
    propid = 0,
    defender = 0,
    uid = 0,
    last_uid = 0,
    pid = 0,
    state = 1,
    startTime = 0,
    endTime = 0,
    my_troop_id = 0,
    timers = {},
    dmg = {},
    declareUnions = {},
    getAwardMember = {},
    randomAward = {},
    --size = 0,
    kw_buff = {},
    royal = ROYAL_STATE.NO_ROYAL,
    --atk_troops= {},    --攻击该城市的部队
    --leave_troops = {},  --从该城市出发的部队
})

local zset = require "frame/zset"

citys = citys or {}
have = have or {}
map_pack = map_pack -- 不要加{}
do_mc_citys = do_mc_citys -- 不要加{}
npc_logs = npc_logs or {} -- 攻城掠地记录
start_tm = start_tm or 0  --本期活动开始世界
end_tm = end_tm or 0  --本期活动开始世界
actTimer = actTimer or 0
actState = actState or 0
active_day = active_day or 0
season = season or 0
rank_end_tm = rank_end_tm or 0

function reset_map_pack()
    map_pack = nil
    union_rank = nil
end

function reset_do_mc_citys()
    do_mc_citys = nil
end

function kaifu_tw()
    start_tm = 0
    end_tm = 0
    timer.del(actTimer)
    actTimer = 0
    rank_end_tm = 0
    npc_logs = {}
    season = 0
    actState = 0
    gPendingDelete.status["npc_city"] = 0
end

function init()
    -- to do

end

--function on_wrap(db, _id, chgs)
--    db.npc_city:update({_id = _id}, {["$set"] = chgs})
--end

function format_union(data)
    local unions =  {}
    local defender = get_defender_info(data)
    if defender then
        table.insert(unions, defender)
    end
    get_atk_info(unions ,data)
    data.unions = unions

end

function get_atk_info(unions, data)
    if data.declareUnions then
        for k, v in pairs(data.declareUnions or {}) do
            local union = unionmng.get_union(k)
            if union then
                table.insert(unions, {k, union.name, union.flag or 1, union.alias})
            end
        end
    end
    if data.state == TW_STATE.PREPARE  or data.state == TW_STATE.FIGHT then
        local declares = npc_city.cur_declares or {} 
        if declares[data.propid] then 
            table.insert(unions, {declares[data.propid][1] or 104 , ["is_fake"] = true})
        end
    end
end

function get_defender_info(data)
    --if data.uid == 0 or data.uid == data.propid then
    --    return {data.propid}
    --else
    --    local union = unionmng.get_union(data.uid)
    --    if union then
    --        return {union.uid, union.name, union.flag, union.alias}
    --    else
    --        return {data.propid}
    --    end
    --end

    if data.uid > 0 then
        local union = unionmng.get_union(data.uid)
        if union then
            return {union.uid, union.name, union.flag, union.alias}
        end
        return { data.eid % 5 + 1 }
    end

   -- if data.state == TW_STATE.PREPARE  or data.state == TW_STATE.FIGHT then
   --     local declares = npc_city.cur_declares or {}
   --     if declares[data.propid] then
   --         return {declares[data.propid][1], ["is_fake"] = true}
   --     end
   -- end

    if data.state == TW_STATE.PACE then
        local occupys = npc_city.monster_occupys
        if occupys then
            local uid = occupys[ data.propid ]
            if uid then
                return { uid , ["is_fake"] = true}
            end
        end
    end

    if data.last_uid == 0 then
        local conf = resmng.get_conf( "prop_world_unit", data.propid )
        if conf then
            local uid = conf.Flag and conf.Flag[ 4 ]
            if uid then return { uid } end
        end
    end

    return { data.eid % 5 + 1 }
end


function load_npc_city()
    local db = dbmng:getOne()
    local info = db.npc_city:find({})
    while info:hasNext() do
        local m = npc_city.wrap( info:next() )
        gEtys[m.eid] = m
        citys[m.eid] = m.eid
        have[m.propid] = m.eid
        format_union(m)
        etypipe.add(m)
    end

    load_tw_state()
    init_npc_citys(have)
    --init_redis_list()
   --test_npc()
end

function load_tw_state()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "npc_city"})
    if not info then
        info = {_id = "npc_city"}
        db.status:insert(info)
    end
    npc_logs = info.npc_logs or {}

    if info.actState then
        actState = info.actState
        start_tm = info.start_tm
        end_tm = info.end_tm
        actTimer = info.actTimer
        season = info.season or 0
        rank_end_tm = info.rank_end_tm
    end
end

function get_npc_eid_by_propid(propid)
    return have[propid]  -- return npc city eid
end

function on_day_pass()
 --   for k, v in pairs(citys or {}) do
 --       local npc = get_ety(v)
 --       if npc then
 --           if npc.uid ~= 0 then
 --               local prop = resmng.prop_world_unit[npc.propid]
 --               if prop then
 --                   local score = prop.Boss_point or 0
 --                   update_union_score(npc.uid, score, 14)
 --               end
 --           end
 --       end
 --   end
end

function update_act_tag()
    act_tag = gTime
end

function update_union_score(key, level, rank_id)
    local union = unionmng.get_union(key)
    if check_union_cross(union) then
        return
    end

    rank_id = rank_id or 13
    local unionId = tostring(key)
    local score  = level -- to do

    local org_score = rank_mng.get_score(rank_id, key) or 0
    INFO("rankid %d key %d org score %d and add score %d ", rank_id, key, org_score, score)
    score = score + org_score

    if score <= 0 then
        rank_mng.rem_data( rank_id, key )
    else
        rank_mng.add_data(rank_id, key, {score})
    end
end

function update_ply_score(key, level)
    local score  = level -- to do

    local ply = getPlayer(key)
    if ply then
        if check_ply_cross(ply) then
            return
        end
        local u = ply:get_union()
        if u then
            u:add_score_in_u(key, ACT_TYPE.NPC, score)
        end
    end

    local org_score = rank_mng.get_score(12, key) or 0
    score = score + org_score
    if score <= 0 then
        socre = 0
        rank_mng.rem_data( 12, key )
    else
        rank_mng.add_data(12, key, {score})
    end
end

function init_npc_citys(have)
    for k, v in pairs(resmng.prop_world_unit or {}) do
        if v.Class == CLASS_UNIT.NPC_CITY and have[v.ID] == nil then
            local eid = get_eid_npc_city()
            local npcCity = init_npc_city(v, eid)
            have[npcCity.propid] = npcCity.eid
            gEtys[npcCity.eid] = npcCity
            citys[eid] = eid
            format_union(npcCity)
            etypipe.add(npcCity)
            --mark(npcCity)
        end
    end
end

function reset_all_npc()
    for k, v in pairs(citys) do
        local city = get_ety(v)
        if city then
            city:reset_npc()
        end
    end
end

function reset_npc(self)
    self:drop_city(self.uid) -- post to cross center
    change_city_uid(self, 0)
    --self.pid = 0
    troop_mng.delete_troop(self.my_troop_id)
    self.my_troop_id = 0
    format_union(self)
    etypipe.add(self)
end

function init_npc_city(prop, eid)
    local npcCity = {}
    npcCity._id = eid
    npcCity.eid = eid
    npcCity.propid = prop.ID
    npcCity.x = prop.X
    npcCity.y = prop.Y
    npcCity.lv = prop.Lv
    npcCity.size = prop.Size


    npcCity = new( npcCity )
    init_npc_state(npcCity)
    return npcCity
end

function clear_npcs_by_uid(uid)
    for k, v in pairs(citys or {}) do
        local city = get_ety(k)
        if city.uid == uid then
            city:clear_npc()
        end
    end
end

function clear_npc(self)  -- union destory
    local tr = troop_mng.get_troop(self.my_troop_id)
    if tr then
        if tr.owner_uid == self.uid then
            tr:back()
        end
    end
    self.my_troop_id = 0
    self:drop_city(self.uid) -- post to cross center
    change_city_uid(self, 0)
    init_npc_state(self)
    format_union(self)
    etypipe.add(self)
end

function init_npc_state(npcCity)
    local state, startTime, endTime = get_npc_state()
    change_city_state(npcCity, state)
    npcCity.endTime = endTime
    npcCity.startTime = startTime
end

function get_npc_state()
    return actState, start_tm, end_tm
end

--function get_npc_state()
--    local now = os.date("*t", gTime)
--    local startHour = resmng.prop_tw_stage[TW_STATE.DECLARE].Start.hour
--    local endHour = resmng.prop_tw_stage[TW_STATE.DECLARE].End.hour
--    local startMin = resmng.prop_tw_stage[TW_STATE.DECLARE].Start.min
--    local endMin = resmng.prop_tw_stage[TW_STATE.DECLARE].End.min
--    local startTime = 0
--    local endTime = 0
--    local state = 1
--    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0, sec=0 }
--    if now.hour >= startHour and now.hour < endHour then
--        state = TW_STATE.DECLARE
--        temp.hour = startHour
--        temp.min = startMin
--        startTime = os.time(temp)
--        temp.hour = endHour
--        endTime = os.time(temp) 
--    elseif now.hour >= endHour then 
--        state = TW_STATE.PACE
--        temp.hour = endHour
--        temp.min = endMin
--        startTime = os.time(temp)
--        temp.hour = startHour
--        endTime = os.time(temp) + 24 * 3600
--    elseif now.hour < startHour then
--        state = TW_STATE.PACE
--        startTime = gTime
--        temp.hour = startHour
--        temp.min = startMin
--        endTime = os.time(temp)
--    end
--    return state, startTime, endTime
--end

function declare_state(npcCity)
    local state, startTime, endTime = get_npc_state()
    change_city_state(npcCity, TW_STATE.DECLARE)
    npcCity.startTime = startTime
    npcCity.endTime = endTime
    reset_npc_troop(npcCity)
    reset_declare(npcCity.eid, npcCity.declareUnions or {})
    npcCity.declareUnions = {}
    format_union(npcCity)
    del_timer(npcCity)
    etypipe.add(npcCity)
    update_act_tag()
    --mark(ncpCity)
end

function reset_npc_troop(npc)
    if npc.uid == 0 then
        if npc.my_troop_id then
            local tr = troop_mng.get_troop(npc.my_troop_id) 
            if tr then
                if tr.owner_pid == 0 then
                    troop_mng.delete_troop(npc.my_troop_id)
                    npc.my_troop_id = 0
                end
            end
        end
    end
end

function prepare_state(npcCity)
    local level = resmng.prop_world_unit[npcCity.propid].Lv
    change_city_state(npcCity, TW_STATE.PREPARE)
    npcCity.startTime =  gTime 
    npcCity.endTime = gTime + resmng.prop_tw_stage[npcCity.state].Spantime[level]
    set_timer(npcCity)
    format_union(npcCity)
    etypipe.add(npcCity)
    update_act_tag()
    --mark(npcCity)
end

function fight_state(npcCity)
    local level = get_npc_city_lv(npcCity.propid)
    change_city_state(npcCity, TW_STATE.FIGHT)

    local pro = resmng.prop_world_unit[npcCity.propid]
    if pro then
        king_city.common_ntf(resmng.TW_FIGHT, {pro.Name})
    end

    local pack = {}
    pack.mode = DISPLY_MODE.NPC
    pack.state = TW_ACTION.FIGHT
    pack.npc_id = npcCity.propid

    local def_union = unionmng.get_union(npcCity.uid)
    if def_union then
        local _members = def_union:get_members()
        for k, ply in pairs(_members or {}) do
            player_t.send_system_notice(ply, resmng.MAIL_10057, {pro.Name},{pro.Name})
            offline_ntf.post(resmng.OFFLINE_NOTIFY_BE_FIGHT, ply, pro.NameOffline)
        end
    end

    if def_union then
        pack.def_info = {u_name = def_union.name, u_alias = def_union.alias, u_flag = def_union.flag}
        for k, v in pairs(npcCity.declareUnions or {}) do
            local union = unionmng.get_union(v)
            if union then
                pack.atk_info = {u_name = union.name, u_alias = union.alias, u_flag = union.flag}
                pack.atk_num = get_table_valid_count(npcCity.declareUnions or {})
                break
            end
        end
        local def_members = def_union:get_members()
        for k, v in pairs(def_members or {}) do
            v:add_to_do("display_ntf", pack)
        end
    end

    for k, v in pairs(npcCity.declareUnions or {}) do
        local union = unionmng.get_union(v)
        if union then
            pack.atk_info = {u_name = union.name, u_alias = union.alias, u_flag = union.flag}
            pack.atk_num = get_table_valid_count(npcCity.declareUnions or {})
            local _members = union:get_members()
            for k, ply in pairs(_members or {}) do
                player_t.send_system_notice(ply, resmng.MAIL_10057, {pro.Name},{pro.Name})
                offline_ntf.post(resmng.OFFLINE_NOTIFY_FIGHT, ply, pro.NameOffline)
                ply:add_to_do("display_ntf", pack)
            end
            union:reset_npc_info_pack()
        end
    end

    npcCity.startTime =  gTime 
    npcCity.endTime = gTime + resmng.prop_tw_stage[npcCity.state].Spantime[level]
    set_timer(npcCity)
    format_union(npcCity)
    etypipe.add(npcCity)
    update_act_tag()
    --mark(npcCity)
end


function set_timer(npcCity, state)
    if state == nil then state = npcCity.state end
    local level = get_npc_city_lv(npcCity.propid)
    local time = resmng.prop_tw_stage[state].Spantime[level]
    local nextState = resmng.prop_tw_stage[state].NextStage
    del_timer(npcCity)
    local timerId = timer.new("npc_city", time, npcCity.eid, nextState)
    local node = npcCity.timers or {}
    table.insert(node, timerId)
    npcCity.timers = node
end

function del_timer(npcCity)
    if npcCity.timers then
        for k, v in pairs(npcCity.timers or {}) do
            INFO("del timer %d %d", npcCity.eid, v)
            timer.del(v)
        end
        npcCity.timers= {}
    end
end

function pace_state(npcCity)
-- 设置玩家怪物攻城活动
    local union = unionmng.get_union(npcCity.uid)
    if union then
       union_t.set_default_start(union)
    end
    del_timer(npcCity)
    local state, startTime, endTime = get_npc_state()
    change_city_state(npcCity, TW_STATE.PACE)
    npcCity.endTime = endTime
    npcCity.startTime = startTime
    npcCity.dmg = {}
    npcCity.declareUnions = {}
    format_union(npcCity)
    etypipe.add(npcCity)
    update_act_tag()
  --  local prop = resmng.prop_world_unit[npcCity.propid]
  --  if union and prop then
  --      local _members = union:get_members()
  --      for _, ply in pairs(_members or {}) do
  --          player_t.send_system_notice(ply, resmng.MAIL_10059, {prop.Name},{prop.Name, union.name})
  --      end
  --  end
    --mark(npcCity)
end

function def_success(npc)
    local union = unionmng.get_union(npc.uid)
    local prop = resmng.prop_world_unit[npc.propid]
    if union and prop then
        local _members = union:get_members()
        for _, ply in pairs(_members or {}) do
            player_t.send_system_notice(ply, resmng.MAIL_10059, {prop.Name},{prop.Name, union.name})
        end
    end
end

function try_start_tw()
    local id = actState
    local prop = resmng.prop_tw_open[id]
    if  actState == 0 then
        season = 0
        if gTime < act_mng.start_act_tm then
            actState = TW_STATE.PACE
            start_tm = get_zero_tm(gTime)
            end_tm = act_mng.start_act_tm + prop.Span
            rank_end_tm = act_mng.start_act_tm + prop.Awardtm
        else
            local tm = act_mng.start_act_tm + prop.Span - gTime
            if tm <= 0 then
                start_tw(act_mng.start_act_tm + prop.Span)
            else
                actState = TW_STATE.PACE
                start_tm = act_mng.start_act_tm
                end_tm = start_tm + prop.Span
                actTimer = timer.new("tw_stage", tm, TW_STATE.DECLARE, end_tm)
            end
            rank_end_tm = act_mng.start_act_tm + prop.Awardtm
        end
        for k, v in pairs(citys) do
            local city = get_ety(v)
            if city then
                city:init_npc_state()
                etypipe.add(city)
            end
        end
    else
        if actState == TW_STATE.PACE then
            if get_zero_tm(gTime + 10) - start_tm >= prop.Wait then
                local tm = get_zero_tm(gTime) + prop.CountDown - gTime
                if tm < 0 then
                     start_tw(get_zero_tm(gTime) + prop.CountDown)
                else
                    actTimer = timer.new("tw_stage", tm, TW_STATE.DECLARE, get_zero_tm(gTime) + prop.CountDown)
                end
            end
        end
    end
    gPendingSave.status["npc_city"].actTimer  = actTimer
    gPendingSave.status["npc_city"].actState = actState
    gPendingSave.status["npc_city"].start_tm  = start_tm
    gPendingSave.status["npc_city"].end_tm  = end_tm
    gPendingSave.status["npc_city"].rank_end_tm = rank_end_tm 
    gPendingSave.status["npc_city"].season = season
end

function start_tw(tm)
    start_tm = tm or gTime
    actState = TW_STATE.DECLARE
    gPendingSave.status["npc_city"].actState = actState
    gPendingSave.status["npc_city"].start_tm = start_tm
    local stage_prop = resmng.prop_tw_open[actState]
    if stage_prop then
        end_tm = start_tm + stage_prop.CountDown
        gPendingSave.status["npc_city"].end_tm  = end_tm
    end
    local left_tm = end_tm - gTime
    actTimer = timer.new("tw_stage", left_tm, TW_STATE.PACE)
    gPendingSave.status["npc_city"].actTimer  = actTimer

    if season % 2 == 0 then
        rank_mng.clear(12)
        rank_mng.clear(14)
    end

    season = season + 1
    gPendingSave.status["npc_city"].season = season

    local prop = resmng.get_conf("prop_act_notify", resmng.TW_START)
    if prop then
         if prop.Notify then
             Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
         end

         if prop.Chat1 then
             player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", prop.Chat1,{})
         end
    end

    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            declare_state(npcCity)
        end
    end
end

function clear_union()
    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            npcCity.declareUnions = {}
        end
    end
end

function fight_tw()
    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            fight_state(npcCity)
        end
    end
end

function end_tw()
    actState = TW_STATE.PACE
    gPendingSave.status["npc_city"].actState = actState
    start_tm = end_tm
    gPendingSave.status["npc_city"].start_tm  = start_tm
    local stage_prop = resmng.prop_tw_open[actState]
    if stage_prop then
        end_tm = start_tm + stage_prop.Span
        gPendingSave.status["npc_city"].end_tm  = end_tm
    end
    timer.del(actTimer)
    actTimer = 0
    gPendingSave.status["npc_city"].actTimer  = actTimer

    local prop = resmng.get_conf("prop_act_notify", resmng.TW_END)
    if prop then
         if prop.Notify then
             Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
         end

         if prop.Chat1 then
             player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", prop.Chat1,{})
         end
    end

    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            pace_state(npcCity)
            if npcCity.uid ~= 0 then
                local prop = resmng.prop_world_unit[npcCity.propid]
                if prop then
                    local score = prop.Boss_point or 0
                    update_union_score(npcCity.uid, score, 14)
                end
            end
        end
    end

    clear_declare_state()
    -- 发奖
    send_end_tw_award()

    add_cross_score()

    king_city.try_unlock_kw()

    if season % 2 == 0 then
        crontab.send_tw_award()
        rank_end_tm = start_tm + stage_prop.Awardtm
        gPendingSave.status["npc_city"].rank_end_tm = rank_end_tm 
    end
end

function add_cross_score()
    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            cross_score.process_score(RANK_ACTION.NPC_ACT, npcCity.uid, npcCity.propid)
        end
    end
end

function clear_declare_state()
    local unions = unionmng.get_all()
    if unions then
        for k, union in pairs(unions or {}) do
            union.declare_wars = {}
            union.declare_tm = 0
        end
    end
end

function send_end_tw_award()
    local us = unionmng.get_all()
    for k, v in pairs(us or {}) do
        local award = each_union_award(v)
        if get_table_valid_count(award or {}) >= 1 then
            if not check_union_cross(v) then
                local _members = v:get_members()
                for pid, ply in pairs(_members or {}) do
                    if check_ply_can_award(ply) then
                        ply:send_system_notice(10012, {}, {}, award)
                    end
                end
            else
                Rpc:callAgent(v.map_id, "send_end_tw_award", v.uid, award)
            end
        end
    end
end

function check_ply_can_award(ply)
    local lv_castle = ply:get_castle_lv() or 0
    return true
    --return (lv_castle >= 6 and (ply.tm_union ~= 0) and (gTime - ply.tm_union) >= 12 * 60 * 60)
end

function each_union_award(union)
    local pool = {}
    for k, v in pairs(union.npc_citys or {}) do
        local city = get_ety(k)
        if city then
            local prop = resmng.prop_world_unit[city.propid]
            if prop then
                local rewards = prop.Fix_award
                if rewards then
                    local award = player_t.bonus_func[ rewards[1] ](prop, rewards[2])
                    add_reward_pool(pool, award)
                end
            end
        end
    end
    return pool
end

function add_reward_pool(pool, rewards) 
    for k, v in pairs(rewards or {}) do

        local award = pool[v[2]]
        if award then
            award[3] = award[3] + v[3]
        else
            award = v
        end
        pool[v[2]] = award
        
    end
end


function get_npc_city_lv(propid)
    return resmng.prop_world_unit[ propid ].Lv
end

function get_random_award(pid, eid)
    local ply = getPlayer(pid)
    local npcCity = get_ety(eid)
    if ply.uid == npcCity.uid and npcCity.getAwardMember[pid] then
        ply:add_debug("npc city get random reward")
        ply:add_bonus("mutex_award", npcCity.randomAward, VALUE_CHANGE_REASON.REASON_NPC)
        npcCity.getAwardMember[pid] = nil
        etypipe.add(npcCity)
    else

    end
end

function tw_random_award()
    local seqList = {}
    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            clear_award(npcCity)
            table.insert(seqList, k)
        end
    end
    local awardCitys = gen_random_list(seqList)
    for k, v in pairs(awardCitys or {}) do
        local npcCity = get_ety(v)
        if npcCity then
            local union = unionmng.get_union(npcCity.uid)
            if union and (not check_union_cross(union)) then
                local pids = {}
                local _members = union:get_members()
                for k, v in pairs(_members or {}) do
                    pids[k] = k
                end
                local prop = resmng.prop_world_unit[npcCity.propid]
                if prop then
                    local award = player_t.bonus_func[ prop.Final_award[1] ](prop, prop.Final_award[2])
                    npcCity.randomAward = award
                    npcCity.getAwardMember = pids
                    etypipe.add(npcCity)
                end
            end
        end
    end
end

function gen_random_list(seqList)
    local list = {}
    local index = 0
    local num = 2

    if player_t.debug_tag then
        num = 40
    end
    
    while countTb(list) < num do
        index = math.random(#seqList)
        if not list[ index ] then
            list[index] = seqList[ index ]
        end
    end
    return list
end

function countTb(list)
    local count = 0
    for k, v in pairs(list or {}) do
        count = count + 1
    end
    return count
end


function clear_award(npcCity)
    npcCity.randomAward = {}
    npcCity.getAwardMember = {}
end

function declare_war(atkEid, npcEid)
    if player_t.debug_tag == 1 then
        do_declare_war(atkEid, npcEid)
        declare_notify(atkEid, npcEid)

        local ply = get_ety(atkEid)
        if not is_ply(ply) then return end

        local union = unionmng.get_union(ply.uid)
        if not union then return end
        for _, p in pairs(union._members) do
            if p then
                Rpc:declare_tw_ack(p, npcEid, 1)
            end
        end
    end

    if can_npc_be_declare(npcEid) and can_union_declare(atkEid, npcEid) then
        if check_unio_can_dcl(atkEid, npcEid) then
            do_declare_war(atkEid, npcEid)
            declare_notify(atkEid, npcEid)

            local ply = get_ety(atkEid)
            if not is_ply(ply) then return end

            local union = unionmng.get_union(ply.uid)
            if not union then return end
            for _, p in pairs(union._members) do
                if p then
                    Rpc:declare_tw_ack(p, npcEid, 1)
                end
            end
        end
    else
    end
end

function occupy_notify(self)

    local union = unionmng.get_union(self.uid)
    if not union then return end

    local npc_conf = resmng.prop_world_unit[self.propid]
    if not npc_conf then return end

    local conf = resmng.prop_tw_declare_notify[resmng.TW_DECLARE_NOTIFY_2]
    if not conf then return end
    
    if conf.Notify then
        Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{union.name, npc_conf.Name, union.alias})
    end

    if conf.Chat then
        player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat, {npc_conf.X, npc_conf.Y, union.name, npc_conf.Name, union.alias})
    end
end

function declare_notify(atk_eid, npc_eid)
    local p = get_ety(atk_eid)
    if not is_ply(p) then return end

    local npc = get_ety(npc_eid)
    if not npc then return end

    local union = unionmng.get_union(p.uid)
    if not union then return end

    local npc_conf = resmng.prop_world_unit[npc.propid]
    if not npc_conf then return end

    local conf = resmng.prop_tw_declare_notify[resmng.TW_DECLARE_NOTIFY_1]
    if not conf then return end
    
    local time = npc.endTime - gTime
    time = format_time(time)

    local unions = {union.name}
    local u_alias = {union.alias}
    
    --for k, v in pairs(npc.declareUnions or {}) do
    --    local union = unionmng.get_union(v)
    --    if union then
    --        table.insert(unions, union.name)
    --        table.insert(u_alias, union.alias)
    --    end
    --end

    if conf.Mail then
        for k, v in pairs(npc.declareUnions or {}) do
            local union = unionmng.get_union(v)
            if union then
                local _members = union:get_members()
                for k, ply in pairs(_members or {}) do
                    --ply:send_system_notice(conf.Mail, {npc_conf.Name},{unions, npc_conf.Name})
                    player_t.send_system_notice(ply, conf.Mail, {npc_conf.Name},{unions, npc_conf.Name, time, u_alias, p.name})

                    --offline ntf
                    offline_ntf.post(resmng.OFFLINE_NOTIFY_DECLARE, ply, npc_conf.NameOffline)

                end
                -- player_t.send_system_to_all(conf.Mail, {},{unions, npc_conf.Name})
            end
        end
    end

    if conf.Notify then
        Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{unions, npc_conf.Name, time, u_alias, p.name})
    end

    if conf.Chat then
        player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat, {npc_conf.X, npc_conf.Y, unions, npc_conf.Name, time, u_alias, p.name})
    end

    local def_union = unionmng.get_union(npc.uid)
    if def_union then
        local _members = def_union:get_members()
        for k, ply in pairs(_members or {}) do
            --offline ntf
            player_t.send_system_notice(ply, conf.Mail, {npc_conf.Name},{unions, npc_conf.Name, time, u_alias, p.name})
            offline_ntf.post(resmng.OFFLINE_NOTIFY_BE_DECLARE, ply, npc_conf.NameOffline, unions)
        end
    end

    local pack = {}
    pack.mode = DISPLY_MODE.NPC
    pack.state = TW_ACTION.DECLARE
    pack.npc_id = npc.propid
    pack.atk_info = {u_name = union.name, u_alias = union.alias, u_flag = union.flag}
    pack.atk_num = get_table_valid_count(npc.declareUnions or {})
    if def_union then
        pack.def_info = {u_name = def_union.name, u_alias = def_union.alias, u_flag = def_union.flag}
        local def_members = def_union:get_members()
        for k, v in pairs(def_members or {}) do
            v:add_to_do("display_ntf", pack)
        end
    end
    local _members = union:get_members()
    for k, v in pairs(_members or {}) do
        v:add_to_do("display_ntf", pack)
    end

end

function can_union_declare(atkEid, npcEid)
    local ply = get_ety(atkEid)
    local union = ply:union()
    if union then
        return union:can_declare_war(npcEid)
    end
end

function can_npc_be_declare(npcEid)
    --print("in declare state or not")
    if is_in_declare_state(npcEid) then
        if is_npc_full(npcEid) then
            return false
        else
            return true
        end
    else
        return false
    end
end

function is_in_declare_state(npcEid)
    local npcCity = gEtys[ npcEid ] 
    if npcCity then
        return npcCity.state == TW_STATE.DECLARE or npcCity.state == TW_STATE.PREPARE
    else
        return false
    end
end

function is_npc_full(npcEid)
    --print("is npc full or not")
    local npcCity = gEtys[ npcEid ] 
    if not npcCity then
        return true
    end
    local num = 0
    for k, v in pairs(npcCity.declareUnions or {}) do
        num = num + 1
    end
    return num >= 5
end

function check_unio_can_dcl(atkEid, npcEid)
    -- to do
    return true
end

function do_declare_war(atkEid, npcEid)
    do_unio_declare(atkEid, npcEid)
    do_npc_declare(atkEid, npcEid)
end

function do_npc_declare(atkEid, npcEid)
    local npcCity = gEtys[ npcEid ]
    local ply = get_ety(atkEid)
    local declares = npcCity.declareUnions or {}
    declares[ply.uid] = ply.uid

    npc_log(TW_ACTION.DECLARE, {atk_uid = ply.uid, def_uid = npcCity.uid, npc_id = npcCity.propid})

    npcCity.declareUnions = declares
    if npcCity.state == TW_STATE.DECLARE then
        prepare_state(npcCity)
    end
    format_union(npcCity)
    etypipe.add(npcCity)
    --table.insert(npcCity.declareUnions, ply.uid)
    --mark(npcCity)
end

function do_unio_declare(atkEid, npcEid)

    local ply = get_ety(atkEid)
    local union = ply:union()
    if union then
        union:do_declare_tw(npcEid)
    end
end

function getPlyByEid(Eid)
    return getPlayer(get_ety(eid).pid)
end

function fight_war(atkpid, npcId)
    
end

function retreat()
end

function get_my_troop(self)
    local tr = false
    if self.my_troop_id and self.my_troop_id ~= 0 then
        tr = troop_mng.get_troop(self.my_troop_id)
        if tr then return tr end
    end
    -- npc 守城
    if self.uid == 0 or self.uid == self.propid then
        local  conf = resmng.get_conf("prop_world_unit", self.propid)
        if conf then
            local sx, sy = get_ety_pos(self)
            tr = troop_mng.create_troop(TroopAction.HoldDefenseNPC, self, self)

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
        --军团无人守城
        tr = troop_mng.create_troop(TroopAction.HoldDefenseNPC, self, self)
        troop_mng.delete_troop(tr)
        --tr:add_arm(0,{live_soldier = {[3002] = 0}, heros = {0,0,0,0}})
    end
    if tr then
        tr.owner_uid = self.uid
        return tr
    end
end

function is_npc_defense(eid)
    local npcCity = gEtys[ eid ]
    if npcCity then
        return npcCity.defense == npcCity.propid
    end
    return false
end

function can_atk_npc(ply, npcEid)
    local npcCity = get_ety(npcEid)
    if  npcCity.state ~= TW_STATE.FIGHT then
        return false
    end
    if not npcCity.declareUnions[ply.uid] then
        return false
    end
    return true
end

function calc_ply_score(troop)
    local num = 0
    for pid, arm in pairs(troop.arms or {}) do
        for k, v in pairs(arm.hurt_soldier or {}) do
            num = num + v
        end
    end
    return num
end

function after_fight(ackTroop, defenseTroop)
    if  ackTroop.mkdmg == 0 then
         ackTroop.mkdmg = 1
    end

    local score = math.floor(defenseTroop.lost)
    for pid, arm in pairs(ackTroop.arms or {}) do
        local point = score * arm.mkdmg / ackTroop.mkdmg
        update_ply_score(pid, math.floor(point))
    end

    --deal_dead_troop(ackTroop)
    --deal_dead_troop(defenseTroop)
    --ackTroop:dead_to_live_and_hurt( 0.95 )
    --local def = getPlayer(defenseTroop.owner_pid) 
    --if is_ply(def) then
    --    defenseTroop:dead_to_live_and_hurt( 0.95 )
    --end
    
    local npcCity = get_ety(ackTroop.target_eid) 
    save_npc_dmg(npcCity, ackTroop, defenseTroop)
    if check_atk_win(defenseTroop) then
        if (is_npc_city(defenseTroop.owner_eid)) then
            troop_mng.delete_troop(defenseTroop._id)
        end
        make_new_defender(ackTroop, defenseTroop, npcCity)
        declare_state(npcCity)
        deal_union_new_defender(npcCity.uid, npcCity) 
    end
    --mark(npcCity)
end

function deal_troop(atkTroop, defenseTroop)
    if check_atk_win(defenseTroop) then
        local npcCity = get_ety(atkTroop.target_eid) 
        if is_ply(defenseTroop.owner_eid) then 
            --troop_t.dead_to_live_and_hurt( defenseTroop, 0.95 )
            defenseTroop:back()
        else
            troop_mng.delete_troop(defenseTroop._id)
        end

        if npcCity.uid ~= atkTroop.owner_uid then
            --troop_t.dead_to_live_and_hurt( atkTroop, 0.95 )
            atkTroop:back()
        else
            --atkTroop:home_hurt_tr()
            try_hold_troop(npcCity, atkTroop)
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

function clear_timer(npcCity)
    local timeId = npcCity.timers[1]
    if not timerId then timer.del(timeId) end
    npcCity.timers = {}
end

function save_npc_dmg(self, ackTroop, defenseTroop)
    local dmg = self.dmg or {}
    local dmg_by_u = dmg.dmg_by_u or {}
    local dmg_by_ply = dmg.dmg_by_ply or {}
    local mkdmg = ackTroop.mkdmg or 0
    dmg_by_u[ackTroop.owner_uid] = (dmg_by_u[ackTroop.owner_uid] or 0) + mkdmg

    for k, arm in pairs(ackTroop.arms or {}) do
        dmg_by_ply[k] = (dmg_by_ply[k] or 0) + (arm.mkdmg or 0)
    end

    dmg.dmg_by_u = dmg_by_u
    dmg.dmg_by_ply = dmg_by_ply
    dmg.max_union = nil
    dmg.max_pid = nil

    self.dmg = dmg
end

function deal_dead_troop(troop)
    if troop then
        for pid, arm in pairs(troop.arms or {}) do
            if arm.dead_soldier then
                for k, v  in pairs(arm.dead_soldier or {}) do
                    if not arm.live_soldier then arm.live_soldier = {} end
                    if not arm.hurt_soldier then arm.hurt_soldier = {} end
                    --todo, can not fit the original live 
                    arm.live_soldier[k] = (arm.live_soldier[k] or 0 ) + math.floor(v * 0.95)
                    arm.hurt_soldier[k] = (arm.hurt_soldier[k] or 0 ) + math.floor(v * 0.05)
                end
            end
        end
    end
end

function check_atk_win(troop)
    return troop:is_no_live_arm()
   -- return (ackTroop.win or 0) == 1
end

function send_win_award(city, maxHurtUnion)
    local prop = resmng.prop_world_unit[city.propid]
    if prop then
        local award = prop.Base_award or {1, {{"item",2016004,50, 10000}}}

        local dmg = city.dmg or {}
        for k, v in pairs(dmg.dmg_by_u or {}) do
            if v >= (prop.Extra_award or 0)  then
                local u = unionmng.get_union(k)
                if u then
                    INFO("npc send union award to uid = %d", k )
                    local _members = u:get_members()
                    for _, mem in pairs(_members or {}) do
                        union_item.add(mem, award, UNION_ITEM.CITY, city.propid)
                    end
                end
            end
        end
    end

end

function make_new_defender(ackTroop, defenseTroop, npcCity)
    -- for test
    --local maxHurtUnion = 190002
    local maxHurtUnion = find_new_defender(npcCity)

    send_win_award(npcCity, maxHurtUnion)

    --add_score
    local prop = resmng.prop_world_unit[npcCity.propid]
    if prop then
        local score = prop.Boss_point or 0
        update_union_score(maxHurtUnion, score, 13)
        if npcCity.uid ~= 0 then
            update_union_score(npcCity.uid, -score, 13)
        end
    end

    deal_npc_old_defender(npcCity)
    npcCity:drop_city(npcCity.uid) -- post to cross center
    local maxUnion =  unionmng.get_union(maxHurtUnion)
    local def_u = unionmng.get_union(npcCity.uid)

    if maxUnion then
        if union_t.is_npc_city_full(maxUnion) then
            local _members = maxUnion:get_members()
            for _, ply in pairs(_members or {}) do
                player_t.send_system_notice(ply, resmng.MAIL_10069, {},{prop.Name})
            end
            change_city_uid(npcCity, 0)
            deal_npc_new_defender(npcCity.uid, npcCity)
        else
            if maxHurtUnion == ackTroop.owner_uid then
                deal_npc_new_defender(maxHurtUnion, npcCity, ackTroop)
            else
                deal_npc_new_defender(maxHurtUnion, npcCity)
            end

            if npcCity.lv == 1 then
                king_city.try_unlock_kw()
            end

            local _members = maxUnion:get_members()
            for _, ply in pairs(_members or {}) do
                player_t.send_system_notice(ply, resmng.MAIL_10058, {prop.Name},{prop.Name, maxUnion.name})
            end

        end
    end

    if def_u then
        local _members = def_u:get_members()
        local pack = {}
        pack.mode = DISPLY_MODE.NPC
        pack.state= TW_ACTION.LOST
        pack.npc_id = npcCity.propid
        if maxUnion then
            pack.atk_info = {u_name = maxUnion.name, u_alias = maxUnion.alias, u_flag = maxUnion.flag}
            if npcCity.dmg then
                pack.max_dmg_pid = find_max_dmg_ply(npcCity, maxHurtUnion)
            end
        end
        for _, ply in pairs(_members or {}) do
            player_t.send_system_notice(ply, resmng.MAIL_10058, {prop.Name},{prop.Name, maxUnion.name})
            ply:add_to_do("display_ntf", pack)
        end
    end
end

function deal_npc_old_defender(npcCity)
    local union = unionmng.get_union(npcCity.uid)
    if union then
        local npcCitys = union.npc_citys
        npcCitys[npcCity.eid] = nil
        union.npc_citys = npcCitys

    end
end

function npc_buff_ntf()
    for k, v in pairs(citys) do
        local npcCity = get_ety(v)

        if npcCity and npcCity.uid ~= 0 then

            local npc_conf = resmng.get_conf("prop_world_unit", npcCity.propid) or {}
            local buff = npcCity.kw_buff or {}
            local buf = {}
            if buff[1] then
                buf = resmng.get_conf("prop_buff", buff[1]) or {}
            end
            local ef_name = nil
            local ef_value = nil
            for k, v in pairs(buf.Value or {}) do
                local attr = string.split(k, "_")
                local ef_conf = resmng.prop_effect_type[attr[1]]
                if ef_conf then
                    ef_name = ef_conf.BuffName
                end
                if attr[2]  == "A" or not attr[2] then
                    ef_value = v
                elseif attr[2] == "R" then
                    ef_value = v * 0.0001 * 100
                    ef_value = tostring(ef_value).."%"
                end
            end

            local prop = resmng.get_conf("prop_act_notify", resmng.FORTRESS_BUFF)
            if prop and ef_name and npcCity.lv == 1 then
                local union = unionmng.get_union(npcCity.uid)
                if union then
                    if  prop.Chat2 then
                        union:union_chat("", prop.Chat2, {npc_conf.Name, ef_name, ef_value})
                    end
                end
            end
        end
    end
end

function deal_npc_new_defender(newdefender, npcCity, ackTroop)
    local maxUnion = unionmng.get_union(newdefender)
    if maxUnion then
        local _members = maxUnion:get_members()
        local pack = {}
        pack.mode = DISPLY_MODE.NPC
        pack.state= TW_ACTION.WIN
        pack.npc_id = npcCity.propid
        if npcCity.dmg then
            pack.max_dmg_pid = find_max_dmg_ply(npcCity, maxHurtUnion)
        end
        for k, v in pairs(_members or {}) do
            v:add_to_do("display_ntf", pack)
        end
    end

    reset_declare(npcCity.eid, {npcCity.uid})
    change_city_uid(npcCity, newdefender)
    if type(newdefender) == "number" and newdefender > 0 then
        npcCity.last_uid = newdefender
    end

    npcCity:occu_city(npcCity.uid)  --- post to center

    if ackTroop then
        --npcCity.pid = ackTroop.owner_pid
    end

    occupy_notify(npcCity)

    --  if king_city.state == KW_STATE.FIGHT then  -- notify only in fight state
    local npc_conf = resmng.get_conf("prop_world_unit", npcCity.propid) or {}
    local buff = npcCity.kw_buff or {}
    local buf = {}
    if buff[1] then
        buf = resmng.get_conf("prop_buff", buff[1]) or {}
    end
    local ef_name = nil
    local ef_value = nil
    for k, v in pairs(buf.Value or {}) do
        local attr = string.split(k, "_")
        local ef_conf = resmng.prop_effect_type[attr[1]]
        if ef_conf then
            ef_name = ef_conf.BuffName
        end
        if attr[2]  == "A" or not attr[2] then
            ef_value = v
        elseif attr[2] == "R" then
            ef_value = v * 0.0001 * 100
            ef_value = tostring(ef_value).."%"
        end
    end

    local prop = resmng.get_conf("prop_act_notify", resmng.FORTRESS_BUFF)
    if prop and ef_name and npcCity.lv == 1 then
        local union = unionmng.get_union(newdefender)
        if union then
            if  prop.Chat2 then
                union:union_chat("", prop.Chat2, {npc_conf.Name, ef_name, ef_value})
            end
        end
    end

    npcCity.my_troop_id = 0
    npcCity.dmg = {}
    reset_declare(npcCity.eid, npcCity.declareUnions)
    npcCity.declareUnions = {}
end

function reset_declare(npcEid, unions)
    for k, v in pairs(unions or {}) do
        local union = unionmng.get_union(v)
        if union then
            local declare_wars = union.declare_wars
            if declare_wars then
                declare_wars[npcEid] = nil
            end
            union.declare_wars = declare_wars
        end
    end
end

function deal_union_new_defender(unionId, npcCity)
    local union =  unionmng.get_union(unionId)
    if union then
        union_t.deal_new_npc_city(union, npcCity.eid)

        --任务
        local _members = union:get_members() 
        local city_type = 0
        local prop_build = resmng.get_conf("prop_world_unit", npcCity.propid)
        if prop_build ~= nil and prop_build.Class == 3 then
            city_type = prop_build.Lv
        end
        for k, v in pairs(_members or {}) do
            task_logic_t.process_task(v, TASK_ACTION.OCC_NPC_CITY, city_type)
        end

        --世界事件
        if npcCity.last_uid > 0 then
            world_event.process_world_event(WORLD_EVENT_ACTION.OCCUPY_CITY, prop_build.Lv)
        end
    end
end

function find_new_defender(npcCity)
    local dmg = npcCity.dmg or {}
    local max_union = dmg.max_union
    if max_union then
        return max_union
    end

    local max = 0
    local max_union = 0
    for k, v in pairs(dmg.dmg_by_u or {}) do
        if v >= max then
            max_union = k
            max = v
        end
    end

    dmg.max_union = max_union
    npcCity.dmg = dmg
    return max_union
end

function find_max_dmg_ply(npcCity, uid)
    local dmg = npcCity.dmg or {}
    local max_pid = dmg.max_pid
    if max_pid then
        return max_pid
    end

    local max = 0
    local max_pid = 0
    for k, v in pairs(dmg.dmg_by_ply or {}) do
        if v >= max then
            if uid then
                local ply = getPlayer(k)
                if ply then
                    if ply.uid == uid then
                        max_pid = k
                        max = v
                    end
                end
            else
                max_pid = k
                max = v
            end
        end
    end

    dmg.max_pid = max_pid
    npcCity.dmg = dmg
    return max_pid
end

function test_npc()
    local ply = getPlayer(70008)
    end_tw()
    start_tw()
    local npc = {}
    for k, v in pairs(gEtys or {}) do
        if is_npc_city(k) then
            --print(ply.eid, v.eid)
            declare_war(ply.eid, v.eid)
            npc = v
            break

        end
    end
    local union = player_t.union(ply)
    --player_t.siege(ply, npc.eid)
    npc = get_ety(327681)
    fight_state(npc)
    --tw_random_award()
    print("location, ", npc.x,  npc.y)
end

function eye_info(city, pack) 
    pack.defender = city.uid
    pack.getAwardMember = city.getAwardMember
end

function abandon_npc(self)
    local union = unionmng.get_union(self.uid)

    local prop = resmng.prop_world_unit[self.propid]
    if prop then
        local score = prop.Boss_point or 0
        update_union_score(self.uid, -score, 13)
    end

    --local mc = union_t.get_monster_city(self.eid)
    --if mc then
    --    monster_city.send_act_award(mc)
    --    rem_ety(mc.eid)
    --end

    if union then
        local npcs = union.npc_citys
        npcs[self.eid] = nil
        union.npc_citys = npcs
        union.abd_city_time = gTime
    end

    local troop = self:get_my_troop()
    if troop and not troop:is_robot_troop() then
        troop:back()
    else
        if troop then
            troop_mng.delete_troop(troop._id)
        end
    end

    del_timer(self)

    self:drop_city(self.uid) -- post to cross center
    npc_city.npc_log(TW_ACTION.ABANDON, {uid = self.uid, npc_id = self.propid})
    if union then
        if get_table_valid_count(union.npc_citys or {}) == 0 then
            npc_city.npc_log(TW_ACTION.LOST_ALL, {uid = union.uid }) 
        end
    end

    change_city_uid(self, 0)
    self.my_troop_id = 0
    --self.pid = 0
    format_union(self)
    etypipe.add(self)
end

function get_city_num(citys, mode, opt)
    local num = 0
    for k, v in pairs(citys or {}) do
        local city = get_ety(k) 
        if city then
            local lv = resmng.prop_world_unit[city.propid].Lv
            if opt == OPT_TYPE.EQ then
                if lv == mode then
                    num = num + 1
                end
            elseif opt == OPT_TYPE.UE then
                if lv ~= mode then
                    num = num + 1
                end
            elseif opt == OPT_TYPE.LT then
                if lv <= mode then
                    num = num + 1
                end
            elseif opt == OPT_TYPE.GT then
                if lv >= mode then
                    num = num + 1
                end
            end
        end
    end
    return num
end

function hold_limit(self, ply)
    ply = ply or {}
    if not self then return end
    local num ,limit, pow =0,0 ,0
    local u = unionmng.get_union(self.uid)
    if not u then return  0, 0 , 0 end

    local tr = troop_mng.get_troop(self.my_troop_id)
    if tr then 
        num = tr:get_troop_total_soldier()
        pow = tr:get_tr_pow()
    end 

    local c = resmng.get_conf("prop_world_unit",self.propid)
    if c then
        limit = get_val_by("CountGarrison",c.Buff,u:get_ef(), ply._ef, kw_mall.gsEf or {})
        local b = resmng.get_conf("prop_effect_type", "CountGarrison")
        if b then
            limit = limit+b.Default
        end
    end
    limit = limit or 100
    return num,limit, pow
end

function get_hold_limit( self )
    local u = unionmng.get_union(self.uid)
    if not u then return 0 end
    local c = resmng.get_conf("prop_world_unit", self.propid)
    if c then
        return get_val_by("CountGarrison",u:get_ef(), kw_mall.gsEf or {}, c.Buff)
    else
        return get_val_by("CountGarrison",u:get_ef(), kw_mall.gsEf or {})
    end
end

function hold_num_limit(self, ply) --已驻守和将要驻守数量
    ply = ply or {}
    if not self then return end
    local num ,limit=0,0
    local u = unionmng.get_union(self.uid)
    if not u then return end

    local tr = troop_mng.get_troop(self.my_troop_id)
    if tr then 
        num = tr:get_troop_total_soldier()
    end 
    
    for tid, action in pairs( self.troop_comings or {} ) do
        local troop = troop_mng.get_troop( tid )
        if troop and troop:is_go() then
            if action == TroopAction.HoldDefense or 
                action == TroopAction.HoldDefenseNPC or
                action == TroopAction.HoldDefenseLT or
                action == TroopAction.HoldDefenseKING then
                num = num + troop:get_troop_total_soldier()
            end
        end
    end

    local c = resmng.get_conf("prop_world_unit",self.propid)
    if c then
        limit = get_val_by("CountGarrison",c.Buff,u:get_ef(), kw_mall.gsEf or {})
        local b = resmng.get_conf("prop_effect_type", "CountGarrison", ply._ef)
        if b then
            limit = limit+b.Default 
        end
    end
    return num,limit
end


function try_hold_troop(self, tr)

    local ply = getPlayer(tr.owner_pid)
    local sum, max = 0, 0

    if ply then
        sum, max = hold_limit(self, ply)
    else
        sum, max = hold_limit(self)
    end

    local hold_tr = troop_mng.get_troop(self.my_troop_id)
    if not hold_tr then
        hold_tr = {}
    end

    local left = max - sum
    local num =  tr:get_troop_total_soldier()
    if left <= 0 then
        tr:back()
        watch_tower.building_hold_full(self, tr)
    elseif left > num then
        tr:split_tr_by_num_and_back(0, hold_tr)
        do_hold_troop(self, tr) 
        watch_tower.building_recalc(self)
    else
        tr:split_tr_by_num_and_back(num - left, hold_tr)
        do_hold_troop(self, tr) 
        watch_tower.building_recalc(self)
    end
    etypipe.add(self)
end


function do_hold_troop(self, troop)
    local tr = troop_mng.get_troop(self.my_troop_id)
    local action = TroopAction.HoldDefense

    if is_npc_city(self) then
        action = TroopAction.HoldDefenseNPC
    end
    if is_king_city(self) then
        action = TroopAction.HoldDefenseKING
    end
    if is_lost_temple(self) then
        action = TroopAction.HoldDefenseLT
    end

    if (not tr) or tr.owner_eid == self.eid or tr:is_robot_troop() then 
        troop.action = action
        troop:settle()
        self.my_troop_id = troop._id
    else
        if tr.owner_pid ~= troop.owner_pid then
            tr.is_mass = 1
        end
        tr:try_make_leader(troop)
        troop:merge(tr) 
    end
end

function get_troop_info(self)
    local tr = self:get_my_troop()
    local pow
    if tr then
        pow = tr:get_tr_pow()
    end
    if  tr:is_robot_troop() then
        troop_mng.delete_troop(tr)
    end
    return pow
end

function send_score_award()
    local prop = resmng.prop_tw_person_rank_award
    if prop then
        for k, v in pairs(prop or {}) do
            local plys = rank_mng.get_range(12, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(12, tonumber(pid)) or 0
                INFO("npc person rank %d, %d, %d", v.Rank[1] + idx - 1, tonumber(pid), score)
                if score > v.Cond then
                    local ply = getPlayer(tonumber(pid))
                    if ply then
                        ply:send_system_notice(10013, {}, {v.Rank[1] + idx - 1}, v.Award)
                    end
                end
            end
        end
    end

    local u_award = resmng.prop_tw_union_rank_award
    if u_award then 
        for k, v in pairs(u_award or {}) do
            local unions = rank_mng.get_range(14, v.Rank[1], v.Rank[2])
            for idx, uid in pairs(unions or {}) do
                uid = tonumber(uid)
                local s = rank_mng.get_score(14, uid) or 0
                INFO("npc union rank %d, %d, %d", v.Rank[1] + idx - 1, uid, s)
                if s > v.Cond then
                    local union = unionmng.get_union(uid)
                    if union then
                        local _members = union:get_members()
                        for pid, ply in pairs(_members or {}) do
                           -- local score = rank_mng.get_score(12, tonumber(pid)) or 0
                           -- if score > v.Cond then
                                local ply = getPlayer(tonumber(pid))
                                if ply then
                                    ply:send_system_notice(10014, {}, {v.Rank[1] + idx - 1}, v.Award)
                                end
                           -- end
                        end
                    end
                end
            end
        end
    end
end

function get_royalty_by_class_lv(class, lv)
    for id, prop in pairs(resmng.prop_cross_royalty) do
        if prop.Class == class and prop.Lv == lv then
            return prop.ID, prop
        end
    end
end

function change_royal_state(self, uid, state)
    -- 无皇族成员
    if self.royal == ROYAL_STATE.NO_ROYAL then
        return
    end
    -- 皇族成员级别
    local prop = resmng.prop_world_unit[self.propid]
    if not prop then
        return
    end
    local royalty_id = get_royalty_by_class_lv(prop.Class, prop.Lv)
    if not royalty_id then
        return
    end
    -- 是跨服军团吗？
    local u = unionmng.get_union(uid)
    if not u or not check_union_cross(u) then
        return
    end

    self.royal = state
    etypipe.add(self)

    local tag = 0
    if state == ROYAL_STATE.ROYAL_FREE then
        tag = -1
    elseif state == ROYAL_STATE.ROYAL_JAIL then
        tag = 1
    end
    post_change(royalty_id, u.map_id, tag)
end

function drop_city(self, uid)
    change_royal_state(self, uid, ROYAL_STATE.ROYAL_FREE)
end

function occu_city(self, uid)
    change_royal_state(self, uid, ROYAL_STATE.ROYAL_JAIL)
end

function post_change(propid, map_id, tag)
    Rpc:callAgent(gCenterID, "post_npc_change", propid, map_id, tag)
end

function upload_royal_city_info(self, uid)
    local info = npc_city.pack_royal_city_info(self, uid)
    if not info then
        return
    end
    Rpc:callAgent(gCenterID, "cross_royal_city_info", {[info.propid] = info})
end

function first_pre_boss_atk_city()
    npc_city.monster_declares = nil
    npc_city.cur_declares = nil
    prepare_boss_attack_city( )
end

function prepare_boss_attack_city( )
    local cs = {}
    local declare_citys = npc_city.monster_declares or {} 
    for k, v in pairs( citys or {}) do
        local city = get_ety( k )
        if city then
            if city.uid == 0 then
                if not declare_citys[city.propid] then
                    table.insert( cs, {city.propid, city.eid} )
                end
            end
        end
    end
    if #cs < 3 then 
        if #declare_citys >= 3 then
            for i = #cs, 3, 1 do
                for k, v in pairs(declare_citys or {}) do
                    local eid = get_npc_eid_by_propid(k)
                    local city = get_ety(eid)
                    if city then
                        table.insert(cs, {city.propid, city.eid})
                    end
                end
            end
        end
    end

    if #cs < 3 then
        return
    end

    local gs = {}
    for k, v in pairs( resmng.prop_default_union ) do
        if k >= 100 then
            table.insert( gs, k )
        end
    end

    local monster_occupys = npc_city.monster_occupys or {}

    local infos = {}
    for i = 1, 3, 1 do
        local count = #cs
        local idx = math.random( 1, count )
        local ct = table.remove( cs, idx )
        local ety = get_ety(ct[2])

        local union_num = #gs
        idx = math.random(1, union_num)
        if ety then
            if monster_occupys[ ct[1] ] then
                while gs[idx] do
                    if monster_occupys[ ct[1] ] == gs[idx] then
                        idx = idx  % union_num + 1
                    else
                        break
                    end
                end
               infos[ ct[1] ] = { gs[idx] }
            else
               infos[ ct[1] ] = { gs[idx] }
            end
        end
    end

  --  for i = 2, 3, 1 do
  --      if #gs == 0 then break end
  --      for k, v in pairs( infos ) do
  --          if #gs == 0 then break end
  --          table.insert( v, table.remove( gs ) )
  --      end
  --  end

    for k, v in pairs(infos) do
        declare_citys[k] = v
    end

    npc_city.monster_declares = declare_citys
    npc_city.cur_declares = infos

    for k, v in pairs(infos or {}) do
        local eid = get_npc_eid_by_propid(k)
        local ety = get_ety(eid)
        if ety then
            prepare_state(ety)
            local conf = resmng.prop_act_notify[resmng.TW_PREPARE_SPECIAL]
            if conf then
                local npc_conf = resmng.prop_world_unit[ety.propid]
                local union_conf = resmng.prop_default_union[v[1]]
                if union_conf and npc_conf then
                    local time = ety.endTime - gTime
                    time = format_time(time) 
                    local unions = {union_conf.Name}
                    if conf.Notify then
                        Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{unions, npc_conf.Name, time})
                    end

                    if conf.Chat1 then
                        player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat1, {npc_conf.X,npc_conf.Y, unions, npc_conf.Name, time}) 
                    end

                end
            end
        end
    end

    --Rpc:monster_declare( {pid=-1, gid=_G.GateSid}, infos )
    reset_map_pack()
    dumpTab( infos, "prepare_boss_attack_city" )
end

function start_boss_attack_city( )
    local infos = npc_city.cur_declares or {}
    for k, v in pairs(infos ) do
        local eid = get_npc_eid_by_propid(k)
        local ety = get_ety(eid)
        if ety then
            fight_state(ety)
        end
    end

    Rpc:monster_declare( {pid=-1, gid=_G.GateSid}, infos )
    reset_map_pack()
end

function stop_boss_attack_city( )
    tmp_stop_boss_attack_city( ) 
    npc_city.monster_declares = nil
    npc_city.cur_declares = nil
    reset_map_pack()
end

function tmp_stop_boss_attack_city( )
    local infos = npc_city.cur_declares
    if not infos then return end

    local occupys = {}
    for k, v in pairs( infos ) do
        local count = #v
        if count > 0 then
            occupys[ k ] = table.remove( v, math.random( 1, count ) )
        end
    end

    local monster_occupys = npc_city.monster_occupys or {}
    for k, v in pairs(occupys or {}) do
        monster_occupys[k] = v
    end
    npc_city.monster_occupys = monster_occupys

    for k, v in pairs( citys ) do
        local npc = get_ety(v)
        if npc then
            if npc.uid == 0 then
                if occupys[ npc.propid ] then
                    --format_union( npc )
                    --etypipe.add( npc )
                    pace_state(npc)

                    local npc_conf = resmng.prop_world_unit[npc.propid] 
                    local conf = resmng.prop_act_notify[resmng.TW_FIGHT_SPECIAL]
                    local occu_conf = resmng.prop_default_union[ occupys[ npc.propid ]]

                    if npc_conf and conf and occu_conf then

                        if conf.Notify then
                            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{occu_conf.Name, npc_conf.Name, occu_conf.Shortname})
                        end

                        if conf.Chat1 then
                            player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat1, {npc_conf.X,npc_conf.Y, occu_conf.Name, npc_conf.Name, occu_conf.Shortname})
                        end
                    end
                end
            end
        end
    end

    Rpc:monster_declare( {pid=-1, gid=_G.GateSid}, {} )
end

function change_city_uid(self, uid)
    if is_npc_city(self) or is_king_city(self) then
        reset_map_pack()
        if is_npc_city(self) then
            local new_union = unionmng.get_union(uid)
            if new_union then
                new_union:reset_npc_info_pack()
            end
            local old_union = unionmng.get_union(self.uid)
            if old_union then
                old_union:reset_npc_info_pack()
            end
        elseif is_king_city(self) then
            if self.royal ~= ROYAL_STATE.NO_ROYAL then
                change_royal_state(self, self.uid, ROYAL_STATE.ROYAL_FREE)
                change_royal_state(self, uid, ROYAL_STATE.ROYAL_JAIL)
            end
        end
    end

    if is_lost_temple(self) then
        lost_temple.reset_map_lt_info()
    end

    union_hall_t.ety_rem_def(self)
    INFO("[ACT] change city uid last = %d, new = %d", self.uid, uid)
    self.uid = uid
    union_hall_t.ety_add_def(self)

    npc_city.upload_royal_city_info(self, uid)
end

function change_city_state(self, state)
    INFO("[ACT] change city state last = %d, new = %d", self.state, state)
    --if self._id == 1748995 then pause() end
    self.state = state
    reset_map_pack()
    local union = unionmng.get_union(self.uid)
    if union then
        union:reset_npc_info_pack()
    end
end

function npc_log(action, pack)
    if #npc_logs > 100 then
        table.remove(npc_logs)
    end
    local log = {}
    if action == TW_ACTION.DECLARE then
        log.action = TW_ACTION.DECLARE
        local union = unionmng.get_union(pack.atk_uid)
        if not union then
            return
        end
        log.atk_alias = union.alias
        log.atk_name = union.name
        log.npc_id = pack.npc_id
        log.tm = gTime
        local def_union = unionmng.get_union(pack.def_uid)
        if def_union then
            log.def_alias = def_union.alias
            log.def_name = def_union.name
        end
    end

    if action == TW_ACTION.FIGHT then
        log.action = TW_ACTION.FIGHT
        local union = unionmng.get_union(pack.atk_uid) 
        if not union then
            return
        end
        log.atk_alias =  union.alias
        log.atk_name = union.name
        log.npc_id = pack.npc_id
        log.tm = gTime
        local def_union = unionmng.get_union(pack.def_uid)
        if def_union then
            log.def_alias = def_union.alias
            log.def_name = def_union.name
        end
        log.is_win = pack.is_win
    end

    if action == TW_ACTION.ABANDON then
        log.action = TW_ACTION.ABANDON
        local union = unionmng.get_union(pack.uid)
        if not union then
            return
        end
        log.def_alias = union.alias
        log.def_name = union.name
        log.npc_id = pack.npc_id
        log.tm = gTime
    end

    if action == TW_ACTION.LOST_ALL then
        log.action = TW_ACTION.LOST_ALL
        local union = unionmng.get_union(pack.uid)
        if not union then
            return
        end
        log.def_alias = union.alias
        log.def_name = union.name
        log.tm = gTime
    end
    table.insert(npc_logs, 1, log)
    gPendingSave.status["npc_city"].npc_logs = npc_logs
end

function update_royal_data()
    local all_cities = {}
    for k, v in pairs(citys or {}) do
        local city = get_ety(v)
        if city then
            local prop = resmng.prop_world_unit[city.propid]
            if prop then
                local royalty_id = get_royalty_by_class_lv(prop.Class, prop.Lv)
                if royalty_id then
                    all_cities[royalty_id] = all_cities[royalty_id] or {}
                    table.insert(all_cities[royalty_id], city)
                end
            end
        end
    end
    for royalty_id, cities in pairs(all_cities) do
        local prop = resmng.prop_cross_royalty[royalty_id]
        if prop then
            for i = 1, prop.Num do
                local city_count = #cities
                if city_count <= 0 then
                    WARN("[CrossWar] There is no enough city to catch royal data in royal rank %d", royalty_id)
                    break
                end
                local index = math.random(city_count)
                local city = cities[index]
                table.remove(cities, index)
                city.royal = ROYAL_STATE.ROYAL_FREE
                etypipe.add(city)

                INFO("[CrossWar] City %d has royal member %d", city.propid, royalty_id)
            end
            for _, city in pairs(cities) do
                if city.royal ~= ROYAL_STATE.NO_ROYAL then
                    city.royal = ROYAL_STATE.NO_ROYAL
                    etypipe.add(city)
                end
            end
        end
    end
end

function clear_royal_data()
    for k, v in pairs(citys or {}) do
        local city = get_ety(v)
        if city and city.royal ~= ROYAL_STATE.NO_ROYAL then
            city.royal = ROYAL_STATE.NO_ROYAL
            etypipe.add(city)
        end
    end
end

function pack_royal_city_info(self, uid)
    if self.royal == ROYAL_STATE.NO_ROYAL then
        return
    end
    local info = {
        propid = self.propid
    }
    local prop = resmng.prop_world_unit[self.propid]
    local royalty_id = get_royalty_by_class_lv(prop.Class, prop.Lv)

    info.propid = self.propid
    info.royalty_id = royalty_id
    info.royal = self.royal

    local union = unionmng.get_union(uid)
    if union then
        local union_info = {}
        union_info.gid = union.map_id or gMapID
        union_info.uid = union.uid
        union_info.name = union.name
        union_info.flag = union.flag
        union_info.alias = union.alias
        union_info.leader = union.leader

        info.union = union_info
    end

    return info
end

function dump_royal_city()
    for k, v in pairs(citys or {}) do
        local city = get_ety(v)
        if city and city.royal ~= ROYAL_STATE.NO_ROYAL then
            local prop = resmng.prop_world_unit[city.propid]
            print(city.propid, city.royal, prop.Class, prop.Lv)
        end
    end
end

