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
    startTime = 0,
    endTime = 0,
    my_troop_id = 0,
    timers = {},
    size = 0,
    band_id = 0,
}
)

local zset = require "frame/zset"

unionLtRank = unionLtRank or {}
actTimer = actTimer or 0
cityPool = cityPool or {}
citys = citys or {}
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
                cityPool[v.Lv] = pool
            end
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
        local m = lost_temple.new(info:next())
        gEtys[m.eid] = m
        mark_eid(m.eid)
        citys[m.eid] = m.eid
        print("lost temple eid = ", m.eid)
        etypipe.add(m)
    end

    --init_activity()
    init_redis_list()
    init_pool()

    test()

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
            zset:add(v, k)
        end
    end
    return zset
end

function update_union_score(key, score)
    local unionId = tostring(key)
    local unionScore = unionLtRank:score(unionId) or 0
    unionLtRank:add(unionScore + score, unionId)
    gPendingSave.status[ "unionLtRank" ][ unionId ] = score + unionScore
end

function get_union_rank(key)
    local unionId = tostring(key)
    local top = unionLtRank:range(1, 200) or {}
    local myScore = unionLtRank:score(unionId) or 0
    local myRank = unionLtRank:rank(unionId) or 0
    --print( topKillers, {myScore, myRank})
    return top, myScore, myRank
end

function start_lt()
    init_pool()
    gen_lost_temples()
    clear_timer()
    -- debug
    --set_timer(2)
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
    if lv <= 3 then grade = 1 else grade = 2 end
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
            print("gen lt ", k, i, v[2])
            local bandId = get_band_city(k)
            local prop = resmng.prop_world_unit[bandId]
            local grade = 1
            if i <= 3 then grade = 1 else grade = 2 end
            respawn(math.floor(prop.X/16), math.floor(prop.Y/16), grade, bandId)
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
        if v.Class == CLASS_UNIT.LOST_TEMPLE and v.Lv == grade  then
            return v
        end
    end
end

function get_pos_by_grade(tx, ty, prop,  grade)
    local x, y
    local r = math.floor(math.sqrt(prop.Size)) or 1
    x, y = c_get_pos_in_zone(tx + math.random(-3, 3), ty + math.random(-3, 3), r, r)

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
            local m = new({})
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
            gEtys[ eid ] = m
            citys[eid] = eid
            if bandId then
                m.band_id = bandId
                remove_pool(bandId)
            end
            print("lost temple pos ", m.x, m.y, m.eid)
            -- debug
            mark(m)
            etypipe.add(m)
        end
    end
end

function end_lt()
    for k, v in pairs(citys) do
        local city = get_ety(v)
        if city then
            close_temple(city)
        end
    end
    clear_timer()
    send_score_reward()
    -- debug
    --set_timer(1)
end

function close_temple(city)
    clear_timer(city)
    citys[city.eid] = nil
    local tr = get_my_troop(city)
    if tr and tr.owner_uid ~= 0 then
        king_city.troop_back(tr)
    end
    rem_ety(city.eid)
end

function after_fight(ackTroop, defenseTroop)
    deal_dead_troop(ackTroop)
    deal_dead_troop(defenseTroop)
    local city = get_ety(ackTroop.targe_eid) 
    if check_atk_win(ackTroop, defenseTroop) then
        city.uid = ackTroop.owner_uid
        city.my_troop_id = ackTroop.eid
        new_defender_state(city)
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
    if union then
        local res = resmng.prop_world_unit[self.propid].Fix_award
        update_union_score(union.uid, res)
        
    end
    clear_timer(self)
    set_timer(2, self)
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
        gPendingSave.status["lostTemple"].timer = nil
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
        time = resmng.prop_lt_stage[state].Spantime
    end
    time = 10
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

    local  conf = resmng.get_conf("prop_world_unit", self.propid)
    if conf then
        local sx, sy = get_ety_pos(self)
        tr = troop_mng.create_troop(self.eid, self.eid, TroopAction.Npc, sx, sy, sx, sy)
        if conf.Arms then
            local arm = {}
            for _, v in pairs(conf.Arms) do
                arm[ v[1] ] = v[ 2 ]
            end
            --tr:add_arm(self.propid, {live_soldier = arm})
            tr:add_arm(0, {live_soldier = arm,heros = {0,0,0,0}})
        end
    end
    if tr then
        self.my_troop_id = tr._id
        tr.owner_uid = 0
        return tr
    end
end

function test()
    local time = 10
    local timerId = timer.new("lost_temple", time, 1)

end

function get_score_reward(uid, score)
    local reward = {}
    for k, v in pairs(resmng.prop_lt_reward) do
        if score >= v.Cond then
            table.insert(reward, v.Reward)
        end
    end
    return reward
end


function send_score_reward()
    local Rank = unionLtRank:dump()
    if rank then
        for k, v in pairs(rank) do
            local reward = get_score_reward(v[1], v[2])
            print("do lt reward ", k)
        end
    end
end
