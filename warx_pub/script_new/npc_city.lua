--module("npc_city", package.seeall)
--
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
    kw_buff = {}
    --atk_troops= {},    --攻击该城市的部队
    --leave_troops = {},  --从该城市出发的部队
})

local zset = require "frame/zset"

citys = citys or {}
have = have or {}

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
end

function get_defender_info(data)
    if data.uid == 0 or data.uid == data.propid then
        return {data.propid}
    else
        local union = unionmng.get_union(data.uid)
        if union then
            return {union.uid, union.name, union.flag, union.alias}
        end
    end
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

    init_npc_citys(have)
    --init_redis_list()
   --test_npc()
end

function get_npc_eid_by_propid(propid)
    return have[propid]  -- return npc city eid
end

function on_day_pass()
    for k, v in pairs(citys or {}) do
        local npc = get_ety(v)
        if npc then
            if npc.uid ~= 0 then
                local prop = resmng.prop_world_unit[npc.propid]
                if prop then
                    local score = prop.Boss_point or 0
                    update_union_score(npc.uid, score, 14)
                end
            end
        end
    end
end

function update_act_tag()
    act_tag = gTime
end

function update_union_score(key, level, rank_id)
    rank_id = rank_id or 13
    local unionId = tostring(key)
    local score  = level -- to do

    local org_score = rank_mng.get_score(rank_id, key) or 0
    score = score + org_score

    if score <= 0 then
        rank_mng.rem_data( rank_id, key )
    else
        rank_mng.add_data(rank_id, key, {score})
    end
end

function update_ply_score(key, level)
    local pid = tostring(key)
    local score  = level -- to do

    local org_score = rank_mng.get_score(12, key) or 0
    score = score + org_score
    if score < 0 then
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

function reset_npc(self)
    self.uid = 0
    --self.pid = 0
    self.my_troop_id = nil
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

function init_npc_state(npcCity)
    local state, startTime, endTime = get_npc_state()
    npcCity.state = state
    npcCity.endTime = endTime
    npcCity.startTime = startTime
end

function get_npc_state()
    local now = os.date("*t", gTime)
    local startHour = resmng.prop_tw_stage[TW_STATE.DECLARE].Start.hour
    local endHour = resmng.prop_tw_stage[TW_STATE.DECLARE].End.hour
    local startMin = resmng.prop_tw_stage[TW_STATE.DECLARE].Start.min
    local endMin = resmng.prop_tw_stage[TW_STATE.DECLARE].End.min
    local startTime = 0
    local endTime = 0
    local state = 1
    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0, sec=0 }
    if now.hour >= startHour and now.hour < endHour then
        state = TW_STATE.DECLARE
        temp.hour = startHour
        temp.min = startMin
        startTime = os.time(temp)
        temp.hour = endHour
        endTime = os.time(temp) 
    elseif now.hour >= endHour then 
        state = TW_STATE.PACE
        temp.hour = endHour
        temp.min = endMin
        startTime = os.time(temp)
        temp.hour = startHour
        endTime = os.time(temp) + 24 * 3600
    elseif now.hour < startHour then
        state = TW_STATE.PACE
        startTime = gTime
        temp.hour = startHour
        temp.min = startMin
        endTime = os.time(temp)
    end
    return state, startTime, endTime
end

function declare_state(npcCity)
    local state, startTime, endTime = get_npc_state()
    npcCity.hold_troop = {}
    npcCity.state = TW_STATE.DECLARE
    npcCity.startTime = startTime
    npcCity.endTime = endTime
    reset_declare(npcCity.eid, npcCity.declareUnions or {})
    npcCity.declareUnions = {}
    format_union(npcCity)
    del_timer(npcCity)
    etypipe.add(npcCity)
    update_act_tag()
    --mark(ncpCity)
end

function prepare_state(npcCity)
    local level = resmng.prop_world_unit[npcCity.propid].Lv
    npcCity.state = TW_STATE.PREPARE
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
    npcCity.state = TW_STATE.FIGHT
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
    npcCity.state = TW_STATE.PACE
    npcCity.endTime = endTime
    npcCity.startTime = startTime
    npcCity.dmg = {}
    npcCity.declareUnions = {}
    format_union(npcCity)
    etypipe.add(npcCity)
    update_act_tag()
    --mark(npcCity)
end

function start_tw()
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
            npcCity.declareUnions = nil
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
    for k, v in pairs(citys or {}) do
        local npcCity = gEtys[ k ]
        if npcCity then
            pace_state(npcCity)
        end
    end

    clear_declare_state()
    -- 发奖
    send_end_tw_award()

    king_city.try_unlock_kw()
end

function clear_declare_state()
    local unions = unionmng.get_all()
    if unions then
        for k, union in pairs(unions or {}) do
            union.declare_wars = nil
        end
    end
end

function send_end_tw_award()
    local us = unionmng.get_all()
    for k, v in pairs(us or {}) do
        if check_union_cross(v) then
            local award = each_union_award(v)
            if get_table_valid_count(award or {}) >= 1 then
                local _members = v:get_members()
                for pid, ply in pairs(_members or {}) do
                    if check_ply_can_award(ply) then
                        ply:send_system_notice(10012, {}, {}, award)
                    end
                end
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
                for _, rewards in pairs(prop.Fix_award or {}) do
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
    print(countTb(list))
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
    npcCity.randomAward = nil
    npcCity.getAwardMember = {}
end

function declare_war(atkEid, npcEid)
    if player_t.debug_tag == 1 then
        do_declare_war(atkEid, npcEid)
        declare_notify(atkEid, npcEid)
    end

    if can_npc_be_declare(npcEid) and can_union_declare(atkEid, npcEid) then
        if check_unio_can_dcl(atkEid, npcEid) then
            do_declare_war(atkEid, npcEid)
            declare_notify(atkEid, npcEid)
            -- for debug
            print("declare ", atkEid, npcEid)
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
        Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{union.name, npc_conf.Name})
    end

    if conf.Chat then
        Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", conf.Chat, {npc_conf.X, npc_conf.Y, union.name, npc_conf.Name})
    end
end

function declare_notify(atk_eid, npc_eid)
    local ply = get_ety(atk_eid)
    if not is_ply(ply) then return end

    local npc = get_ety(npc_eid)
    if not npc then return end

    local union = unionmng.get_union(ply.uid)
    if not union then return end

    local npc_conf = resmng.prop_world_unit[npc.propid]
    if not npc_conf then return end

    local conf = resmng.prop_tw_declare_notify[resmng.TW_DECLARE_NOTIFY_1]
    if not conf then return end
    
    local time = npc.endTime - gTime
    time = format_time(time)

    local unions = {}
    
    for k, v in pairs(npc.declareUnions or {}) do
        local union = unionmng.get_union(v)
        if union then
            table.insert(unions, union.name)
        end
    end

    if conf.Mail then
    for k, v in pairs(npc.declareUnions or {}) do
        local union = unionmng.get_union(v)
        if union then
            local _members = union:get_members()
            for k, ply in pairs(_members or {}) do
                --ply:send_system_notice(conf.Mail, {npc_conf.Name},{unions, npc_conf.Name})
                player_t:send_system_notice(ply, conf.Mail, {npc_conf.Name},{unions, npc_conf.Name})
            end
               -- player_t.send_system_to_all(conf.Mail, {},{unions, npc_conf.Name})
        end
    end
end

    if conf.Notify then
        Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{unions, npc_conf.Name, time})
    end

    if conf.Chat then
        Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", conf.Chat, {npc_conf.X, npc_conf.Y, unions, npc_conf.Name, time})
    end
end

function can_union_declare(atkEid, npcEid)
    local ply = get_ety(atkEid)
    local union = ply:union()
    if union then
        return union_t.can_declare_war(union, npcEid)
    end
end

function can_npc_be_declare(npcEid)
    print("in declare state or not")
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
    print("is npc full or not")
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
        union_t.do_declare_tw(union, npcEid)
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
    if self.my_troop_id then
        tr = troop_mng.get_troop(self.my_troop_id)
        if tr then return tr end
    end
    -- npc 守城
    if self.uid == 0 or self.uid == self.propid then
        local  conf = resmng.get_conf("prop_world_unit", self.propid)
        if conf then
            local sx, sy = get_ety_pos(self)
            tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self)

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
        tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self)
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
    if check_atk_win(ackTroop, defenseTroop) then
        if (is_npc_city(defenseTroop.owner_eid)) then
            troop_mng.delete_troop(defenseTroop._id)
        end
        make_new_defender(ackTroop, defenseTroop, npcCity)
        declare_state(npcCity)
    end
    --mark(npcCity)
end

function deal_troop(atkTroop, defenseTroop)
    if check_atk_win(atkTroop, defenseTroop) then
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
    if not timerId then timer:del(timeId) end
    npcCity.timers = {}
end

function save_npc_dmg(self, ackTroop, defenseTroop)
    local dmg = self.dmg or {}
    local mkdmg = ackTroop.mkdmg or 0
    dmg[ackTroop.owner_uid] = (dmg[ackTroop.owner_uid] or 0) + mkdmg
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

function check_atk_win(ackTroop, defenseTroop)
    return (ackTroop.win or 0) == 1
end

function send_win_award(city, maxHurtUnion)
    local prop = resmng.prop_world_unit[city.propid]
    if prop then
        local award = prop.Base_award or {1, {{"item",2016004,50, 10000}}}

        for k, v in pairs(city.dmg or {}) do
            if  k == maxHurtUnion or v >= (prop.Extra_award or 0)  then
                local u = unionmng.get_union(k)
                if u then
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
    local maxunion = {}
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
    maxUnion =  unionmng.get_union(maxHurtUnion)
    if maxUnion then
        if union_t.is_npc_city_full(maxUnion) then
            npcCity.uid = 0
            --npcCity.pid = 0
            deal_npc_new_defender(npcCity.propid, npcCity)
        else
            if maxHurtUnion == ackTroop.owner_uid then
                deal_npc_new_defender(maxHurtUnion, npcCity, ackTroop)
                deal_union_new_defender(maxHurtUnion, npcCity) 
            else
                deal_npc_new_defender(maxHurtUnion, npcCity)
                deal_union_new_defender(maxHurtUnion, npcCity) 
            end

            if npcCity.lv == 1 then
                king_city.try_unlock_kw()
            end

            --任务
            local city_type = 0
            local prop_build = resmng.get_conf("prop_world_unit", npcCity.propid)
            if prop_build ~= nil and prop_build.Class == 3 then
                city_type = prop_build.Lv
            end
            local _members = maxUnion:get_members()
            for k, v in pairs(_members or {}) do
                task_logic_t.process_task(v, TASK_ACTION.OCC_NPC_CITY, city_type)
            end
        end
    end
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, npcCity)
end

function deal_npc_old_defender(npcCity)
    local union = unionmng.get_union(npcCity.uid)
    if union then
        local npcCitys = union.npc_citys
        npcCitys[npcCity.eid] = nil
        union.npc_citys = npcCitys
    end
end

function deal_npc_new_defender(newdefender, npcCity, ackTroop)
    reset_declare(npcCity.eid, {npcCity.uid})
    npcCity.uid = newdefender
    if ackTroop then
        --npcCity.pid = ackTroop.owner_pid
    end

    occupy_notify(npcCity)

    if king_city.state == KW_STATE.FIGHT then  -- notify only in fight state
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
    end

    npcCity.my_troop_id = nil
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
    end
end

function find_new_defender(npcCity)
    local max = 0
    local max_union = 0
    for k, v in pairs(npcCity.dmg or {}) do
        if v >= max then
            max_union = k
            max = v
        end
    end
    return max_union
end

function test_npc()
    local ply = getPlayer(70008)
    end_tw()
    start_tw()
    local npc = {}
    for k, v in pairs(gEtys or {}) do
        if is_npc_city(k) then
            print(ply.eid, v.eid)
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

    local mc = union_t.get_monster_city(self.eid)
    if mc then
        monster_city.send_act_award(mc)
        rem_ety(mc.eid)
    end

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

    self.uid = 0
    self.my_troop_id = 0
    --self.pid = 0
    format_union(self)
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, self)
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
    local num ,limit=0,0
    local u = unionmng.get_union(self.uid)
    if not u then return  0, 0 end

    local tr = troop_mng.get_troop(self.my_troop_id)
    if tr then 
        num = tr:get_troop_total_soldier()
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
    return num,limit
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

    for k, _ in pairs(self.hold_troop  or {}) do 
        local tm_troop = troop_mng.get_troop(k)
        if tm_troop then
            num = num + tm_troop:get_troop_total_soldier()
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
    elseif left > num then
        tr:split_tr_by_num_and_back(0, hold_tr)
        do_hold_troop(self, tr) 
    else
        tr:split_tr_by_num_and_back(num - left, hold_tr)
        do_hold_troop(self, tr) 
    end
    etypipe.add(self)
    
end

function do_hold_troop(self, troop)
    local tr = troop_mng.get_troop(self.my_troop_id)
    if (not tr) or tr.owner_eid == self.eid or tr:is_robot_troop() then 
        troop.action = TroopAction.HoldDefense
        troop:settle()
        self.my_troop_id = troop._id
    else
        troop:merge(tr) 
    end
end

function get_troop_info(self)
    local tr = self:get_my_troop()
    local pow
    if tr then
        pow = tr:get_tr_pow()
    end
    return pow
end

function send_score_reward()
    local prop = resmng.prop_tw_person_rank_award
    if prop then
        for k, v in pairs(prop or {}) do
            local plys = rank_mng.get_range(12, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(12, tonumber(pid)) or 0
                if score > v.Cond then
                    local ply = getPlayer(tonumber(pid))
                    if ply then
                        ply:send_system_notice(10013, {}, {idx}, v.Award)
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
                local union = unionmng.get_union(uid)
                if union then
                    local _members = union:get_members()
                    for pid, ply in pairs(_members or {}) do
                        local score = rank_mng.get_score(12, tonumber(pid)) or 0
                        if score > v.Cond then
                            local ply = getPlayer(tonumber(pid))
                            if ply then
                                ply:send_system_notice(10014, {}, {idx}, v.Award)
                            end
                        end

                    end
                end
            end
        end
    end
end

