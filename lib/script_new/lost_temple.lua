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
    born = 0,
    --atk_troops= {},    --攻击该城市的部队
    --leave_troops = {},  --从该城市出发的部队
}
)

local zset = require "frame/zset"

start_time = start_time or 0  --本期活动开始世界
end_time = end_time or 0  --本期活动开始世界

unionLtRank = unionLtRank or {}
actTimer = actTimer or 0
actState = actState or 0
cityPool = cityPool or {}
citys = citys or {}
seq_citys = seq_citys or {}
initRedisList = {
    "unionLtRank"
}



poolRule = {
    {2, 4},
    {2, 4},
    {1, 4},
    {1, 2},
}


initedisList =
{
    "unionLtRank",
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
    for k, v in pairs(resmng.prop_world_unit) do
        local pool = cityPool[v.Lv] or {}
        if v.Class == CLASS_UNIT.NPC_CITY then
            for i = 1, poolRule[v.Lv][1] do
                table.insert(pool, v.ID)
            end
            cityPool[v.Lv] = pool
        end
    end
    if citys then
        for k, v in pairs(citys) do
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
        for k, v in pairs(cityPool[prop.Lv]) do
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
    start_time = gPendingSave.status["lostTemple"].start_time or 0
    end_time = gPendingSave.status["lostTemple"].end_time or 0
    actState = gPendingSave.status["lostTemple"].actState or 0

end

function add_seq_citys(city)
    local prop = resmng.prop_world_unit[city.propid]
    if prop then
        local citys = seq_citys[prop.Mode] or {}
        table.insert(citys, city.eid)
        seq_citys[prop.Mode] = citys
    end
end

function clear_citys_timer()
    for k, v in pairs(citys) do 
        local city = get_ety(k)
        if city then
            clear_timer(city)
        end
    end
end

function clean_timer()
    timer.del(timerId)
end

function init_db(key)
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = key})
    --dumpTap(info, Key)
    if not info then
        info = {_id = key}
        db.status:insert(info)
    end
    return info
end

function init_redis_list()
    for k, v in pairs(initRedisList) do
        local info = init_db(v)
        lost_temple[ v ] = init_redis(v, info) 
    end
end

function init_redis(key, info)
    local zset = zset.new()
    for k, v in pairs(info) do
        if k ~= "_id" and v ~= {} then
            zset:add(v, tostring(k))
        end
    end
    return zset
end

function update_ply_score(key, score)
    local org_score = rank_mng.get_score(10, key) or 0
    score = score + org_score
    rank_mng.add_data(10, key, {score})
end

function update_union_score(key, score)
    local org_score = rank_mng.get_score(9, key) or 0
    score = score + org_score
    rank_mng.add_data(9, key, {score})


    local unionId = tostring(key)
    local unionScore = unionLtRank:score(unionId) or 0
    unionLtRank:add(unionScore + score, unionId)
    gPendingSave.status[ "unionLtRank" ][ unionId ] = score + unionScore
end

function try_start_lt()
    local id = actState
    local prop = resmng.prop_lt_stage[id]
    if prop then
        local prepare_time =  1800
        if not  player_t.debug_tag then
            if actState == LT_STATE.LOCK then
                if ( gTime + prepare_time - _G.gSysStatus.start) >= prop.Spantime  then
                    timer.new("start_lt", prepare_time)
                    lt_ntf(resmng.LT_OPEN)
                end
            end

            if actState == LT_STATE.DOWN then
                if ( gTime + prepare_time - end_time) >= prop.Spantime  then
                    timer.new("start_lt", prepare_time)
                    lt_ntf(resmng.LT_OPEN)
                end
            end
        else
            prepare_time = 10
            timer.new("start_lt", prepare_time)
            lt_ntf(resmng.LT_OPEN)
        end
    end
end

function lt_ntf(notify_id)
    local prop = resmng.get_conf("prop_act_notify", notify_id)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
        end

        if prop.Chat1 then 
    --Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "lost temple begin", 0,{})
            Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", prop.Chat1, {})
        end

    end

end

function start_lt()
    lt_ntf(resmng.LT_START)
    --Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "lost temple begin")
    gPendingSave.status["lostTemple"].start_time  = gTime
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
end

function gen_lost_temples()
    gen_normal_temples()
    gen_elite_temples()
end

function gen_temple_by_propid(propid)
    local prop = resmng.prop_world_unit[propid]

    if not prop then
        return
    end

    local lv = prop.Lv
    local bandId = get_band_city(lv)
    local prop = resmng.prop_world_unit[bandId]
    local grade = 1
    if lv <= 3 then grade = 2 else grade = 3 end
    respawn(math.floor(prop.X/16), math.floor(prop.Y/16), grade, bandId)

end

function gen_normal_temples()
    local num = 300
    local index = math.floor(math.sqrt(6400 * 16 * 16 / num))
    for i = 1, 80 * 16 , index do
        for j = 1, 80 * 16, index  do
            respawn(math.floor(i/16), math.floor(j/16), 1)
        end
    end
end

function gen_elite_temples()
    for k, v in pairs(poolRule) do
        for i = 1, v[2] do
            -- debug
            local bandId = get_band_city(k)
            local prop = resmng.prop_world_unit[bandId]
            local grade = 1
            if k == 1 then grade = 3 else grade = 2 end
            print("gen lt ", k, i, v[2], grade)
            if prop then
                print("npc city band pos ", prop.X, prop.Y, prop.ID)
                respawn(math.floor(prop.X/16), math.floor(prop.Y/16), grade, bandId)
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
    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.LOST_TEMPLE and v.Mode == grade  then
            return v
        end
    end
end

function get_pos_by_grade(tx, ty, prop,  grade)
    local x, y
    local r = prop.Size or 1
    x, y = monster_city.get_pos_in_range(tx, ty, 3, 3, r)

    return x, y

end

function respawn(tx, ty, grade, bandId)
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
            print("lost temple pos ", m.x, m.y, m.eid)
            -- debug
            mark(m)
            local union = unionmng.get_union(m.uid)
            if union then
                m.uname = union.alias
            end
            new_lt_notify(m)
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
    --Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "lost temple begin", 0,{})
            Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", prop.Chat1, {self.x, self.y, self.x, self.y})
        end

    end
end

function reset_lt(city)
    city.uid = 0
    --city.pid = 0
    city.uname = ""
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
    for k, v in pairs(citys) do
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
    send_score_reward()
    -- debug
    --set_timer(LT_STATE.ACTIVE)
end

function close_temple(city)
    clear_timer(city)
    citys[city.eid] = nil
    --local tr = get_my_troop(city)
    local tr = troop_mng.get_troop(city.my_troop_id)
    if tr and tr.owner_uid ~= 0 then
        king_city.troop_back(tr)
    end
    rem_ety(city.eid)
end

function after_fight(ackTroop, defenseTroop)

    local city = get_ety(ackTroop.target_eid) 

    if check_atk_win(ackTroop, defenseTroop) then
        city.uid = ackTroop.owner_uid
        --city.pid = ackTroop.owner_pid
        city.my_troop_id = nil
        local union = unionmng.get_union(city.uid)
        if union then
            city.uname = union.alias
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

        new_defender_state(city)
        union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, city)
        etypipe.add(city)
    end
    --mark(npcCity)
end

function check_atk_win(ackTroop, defenseTroop)
    return (ackTroop.win or 0) == 1
end

function deal_dead_troop(troop)
    for pid, arm in pairs(troop.arms) do
        for k, v  in pairs(arm.dead_soldier) do
            arm.live_soldier[k] = (arm.live_soldier[k] or 0 ) + math.floor(v * 0.95)
            arm.hurt_soldier[k] = (arm.hurt_soldier[k] or 0 ) + math.floor(v * 0.05)
        end
    end
end

function finish_grap_state(self)
    local union = unionmng.get_union(self.uid)
    local res = resmng.prop_world_unit[self.propid].Fix_award

    if union then
        update_union_score(union.uid, res)
    end

    local tr = self:get_my_troop()
    if tr then
        local all_pow = tr:get_tr_pow()
        for k, v in pairs(tr.arms or {}) do
            local pow = tr:calc_pow(k)
            local score = res * pow / all_pow
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
    end
    rem_ety(self.eid)
    citys[self.eid] = nil
    add_pool(self.band_id)
end

function new_defender_state(self)
    self.startTime = gTime
    local time = resmng.prop_world_unit[self.propid].Spantime
    -- to do
    self.endTime = gTime + time 
    clear_timer(self)
    set_timer(1, self)
end

function clear_timer(self)
    if self then
        timer.del(self.timers)
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
        local timerId = timer.new("lost_temple", time, state)
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
            tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self)
            if conf.Arms then
                local arm = {}
                for _, v in pairs(conf.Arms) do
                    arm[ v[1] ] = v[ 2 ]
                end
                --tr:add_arm(self.propid, {live_soldier = arm})
                tr:add_arm(0, {live_soldier = arm,heros = conf.Heros or {0,0,0,0}})
            end
        end
        self.my_troop_id = tr._id
    else
        tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self)
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


function send_score_reward()
    local prop = resmng.prop_lt_rank_award
    if prop then
        for k, v in pairs(prop) do
            local plys = rank_mng.get_range(10, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(10, tonumber(pid)) or 0
                if score > v.Cond then
                    local ply = getPlayer(tonumber(pid))
                    if ply then
                        ply:send_system_notice(10011, {}, {idx}, v.Award)
                    end
                end
            end
        end
    end

    local u_award = resmng.prop_lt_union_award
    if not u_award then return end
    local node = rank_mng.get_node(9)
    if node then
        for uid, data in pairs(node.alls) do
            local score = data[2] or 0
            for k, conf in pairs(u_award) do
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

