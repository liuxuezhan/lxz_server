module_class(
"monster_city",
{
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    band_eid = 0,
    propid = 0,
    atk_eid = 0,
    size = 0,
    state = 0,
    startTime = 1,
    endTime = 1,
    my_troop_id = 0,
    parent_id = 0,
    be_atk_tm = 0,
    class = 0, --区分大裂隙还是小裂隙
    remain_troop = {},  --每次反击时剩余的部队
    be_atk_list = {},   -- 被攻打的玩家列表
    reward_pool = {},   -- 奖励池在活动结束发放
    act_plys = {},      -- 参加活动的玩家

}
)

topKillerByPid = topKillerByPid or {}
topKillerByUid = topKillerByUid or {}

initRedisList =
{
    "topKillerByPid",
    "topKillerByUid"
}

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
        monster_city[ v ] = init_redis(v, info) 
    end
end

function init_redis(key, info)
    local zset = zset.new()
    for k, v in pairs(info) do
        if k ~= "_id" and v ~= {} then
            if key == "topKillerByPid" then
                zset:add(v, k)
             --   zset:add(v[ "hurt" ], v[ "pid" ])
            elseif key == "topKillerByUid" then
                zset:add(v[ "hurt" ], v[ "uid" ] )
              --  zset:add(v[2], v[1])
            end
        end
    end
    return zset
end

function try_update_ply_hurt(key, score)
    local pid = tostring(key)
    local topScore = topKillerByPid:score(pid) or 0
        topHurtByPid:add(topScore + score, pid)
        gPendingSave.status[ "topKillerByPid" ][ pid ] = {[ "pid" ] = pid, ["hurt"] = hurt}
end

function try_update_union_hurt(key, score)
    local uid = tostring(key)
    local topScore = topKillerByUid:score(uid) or 0
        topHurtByUid:add(topScore + score, uid)
        gPendingSave.status[ "topKillerByUid" ][ pid ] = {[ "pid" ] = pid, ["hurt"] = hurt}
end

function get_top_ply_rank(key)
    local pid = tostring(key)
    local topKillers = topKillerByPid:range(1, 200) or {}
    local myScore = topKillerByPid:score(pid) or 0
    local myRank = topKillerByPid:rank(pid) or 0
    --print( topKillers, {myScore, myRank})
    return topKillers, myScore, myRank
end

function get_top_union_rank(key)
    local uid = tostring(key)
    local topKillers = topKillerByUid:range(1, 200) or {}
    local myScore = topKillerByUid:score(pid) or 0
    local myRank = topKillerByUid:rank(pid) or 0
    --print( topKillers, {myScore, myRank})
    return topKillers, myScore, myRank
end


can_atk_stage =
{
    [6] = 1,
    [11] = 1,
    [18] = 1,
}

citys = citys or {}

function init()
    -- to do
end

function on_check_pending(db, _id, chgs)
    db.monster_city:update({_id = _id}, {["$set"] = chgs})
end

function load_monster_city()
    local db = dbmng:getOne()
    local info = db.monster_city:find({})
    while info:hasNext() do
        local m = monster_city.new(info:next())
        gEtys[m.eid] = m
        mark_eid(m.eid)
        citys[m.eid] = m.eid
        print("monster city eid = ", m.eid)
        etypipe.add(m)
    end
end

function can_atk_mc(self, ply)
    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    end

    if not can_akt_stage[union.monster_city_stage] then
        return false
    end

    if not self.be_atk_list[ply.pid] then
        return false
    end
    
    local npcCity = get_ety(self.atk_eid)
    if npcCity then
        return npcCity.uid == ply.uid
    end

end

function declare_atk_mc(self, ply)
    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    end
    local be_atk_list = self.be_atk_list or {}
    be_atk_list[ply.pid] = ply.pid
    self.be_atk_list = be_atk_list
end

function gen_monster_city(atkEid)
    local npcCity = gEtys[atkEid]
    if npcCity then
        local m = monster_city.new({})
        local prop = get_conf_by_npc(npcCity)
        if prop then
            m.eid = get_eid_monster_city()
            m._id = m.eid
            m.propid = prop.ID
            m.size = prop.Size or 4
           -- local x, y =  c_get_pos_in_zone(math.abs(math.floor(npcCity.x / 16) + math.random(-3, 3)), math.abs(math.floor(npcCity.y / 16) + math.random(-3, 3)), r, r)
            local x, y = get_pos_in_range(math.floor(npcCity.x/16), math.floor(npcCity.y/16), 3, 3, m.size)
            print("debug  city x y", x, y)
            m.x = x
            m.y = y
            m.endTime = gTime + 30 * 60
            m.atk_eid = npcCity.eid
            citys[m.atk_eid] = m.eid
            gEtys[m.eid] = m
            m.class =MC_TYPE.ATK_NPC   -- 大裂隙
            etypipe.add(m)
            return m
        end
    end
    return
end

function get_pos_in_range(x, y, offsetx, offsety, r)
    local i = 0
    local j = 0
    local list = {}
    for i = (x-offsetx), (x+offsetx) do
        for j = (y-offsety), (y+offsety) do
            table.insert(list, {i, j})
        end
    end
    local len = #list
    for i=1, len do
        local index = math.random(#list)
        local pos = list[index]
        table.remove(list, index)
        local x, y = c_get_pos_in_zone(math.abs(pos[1]), math.abs(pos[2]), r,r)
        if x and y then
            return x, y
        end
    end
end

function gen_small_city(pid, prop, parentId)
    local ply = getPlayer(pid)
    if ply then
        local m = monster_city.new({})
        local r = prop.Size  or 1
        m.eid = get_eid_monster_city()
        m._id = m.eid
        m.x, m.y = get_pos_in_range(math.floor(ply.x/16), math.floor(ply.y/16), 4, 4, r)
        m.endTime = gTime + 30 * 60
        m.propid= prop.City
        m.atk_eid = ply.eid
        citys[m.atk_eid] = m.eid
        m.parent_id = parentId
        m.class = MC_TYPE.ATK_PLY   -- 小裂隙
        gEtys[m.eid] = m
        etypipe.add(m)
    print("small city  atk ply  city x %d, y %d,  propid %d", m.x, m.y, prop.ID, prop.City)
        prop = resmng.prop_world_unit[prop.City]
        if prop then
            gen_monster_and_atk(m, prop)
        end
    end
end

function gen_defense_city(city, prop)
        local m = monster_city.new({})
        local r = prop.Size  or 1
        m.eid = get_eid_monster_city()
        m._id = m.eid
        m.size = r
        m.propid = prop.DefCity
        m.x, m.y = get_pos_in_range(math.floor(city.x/16), math.floor(city.y/16), 1, 1, r)
        --m.x, m.y =  c_get_pos_in_zone( math.abs(math.floor(city.x / 16) + math.random(-1, 1)), math.abs(math.floor(city.y / 16) + math.random(-1, 1)), r, r)
        m.startTime = gTime
        m.endTime = gTime + 30 * 60
        m.band_eid = city.eid
        --citys[m.atk_eid] = m.eid
        gEtys[m.eid] = m
        m.class = MC_TYPE.DEF_ATK   -- 防守裂隙
        print("defense city", m.x , m.y)
        etypipe.add(m)
        timer.new("remove_mc", 30 * 60, m.eid)
end

function remove_city(city)
    local bandCity = get_ety(city.band_eid)
    if bandCity then
        local remain_troop = bandCity.remain_troop
        table.insert(remain_troop, city.my_troop_id)
        bandCity.remain_troop = remain_troop
    end

    rem_ety(city.eid)

end

function gen_monster_prop(city)
    if city.class == MC_TYPE.ATK_NPC then
        local armId = city.propid % (1000 * 1000) * 1000 + city.state
        local prop = resmng.prop_monster_city[armId]
        return prop
    end
    if city.class == MC_TYPE.ATK_PLY or city.class == MC_TYPE.DEF_ATK then
        local prop = resmng.prop_world_unit[city.propid]
        return prop
    end
end

function monster_city_job(union, city, stage, time)
    -- to do 
    print("do monster job city %d, stage %d", city.propid, stage)
    city.state = stage
    local armId = city.propid % (1000 *1000) * 1000 + stage  
    local prop = resmng.prop_monster_city[armId]
    -- 生成小怪打玩家
    local plyList = get_atk_ply_list(city, union, stage)
    if plyList  then
        for k, v in pairs(plyList) do
            gen_small_city(v, prop, city.eid)
        end
    end

    -- 生产防守裂隙
    if can_atk_stage[stage] then
        gen_defense_city(city, prop)
    end

    
    if prop then
        gen_monster_and_atk(city, prop)
        set_next_state(city, prop, time)
    end
    etypipe.add(city)

end

function get_atk_ply_list(self, union, stage)
    local propid = self.propid % (1000 * 1000) * 1000 + stage
    local prop = resmng.prop_monster_city[propid]
    if not prop or prop.AtkPlyNum == 0 or (not prop.City) then
        return
    end
    local plyList = gen_atk_list(self, union, prop.AtkPlyNum)

    return plyList
end

function gen_atk_list(self, union, atkNum)
    local list = {}
    local num = 0
    if union then
        for k, v in pairs(union._members) do
            if num == atkNum then
                break
            end
            table.insert(list, k)
            num = num + 1
        end
    end
    if list == {} then return{70006} else return list end
end

function make_arm( prop )
    if prop.troop then return copyTab( prop.troop ) end
    --{{1301,22,2,{20104002,1001004}},
    for k, v in pairs( prop.Heros ) do
        local propid = v[1]
        local lv = v[2]
        local star = v[3]

        local basic_conf   = resmng.get_conf("prop_hero_basic", propid)
        if basic_conf then
            local quality_conf = resmng.get_conf("prop_hero_quality", basic_conf.Quality)
            local star_up_conf = resmng.get_conf("prop_hero_star_up", star)
            if quality_conf and star_up_conf then
                local basic_delta = basic_conf.GrowDelta
                local quality_rate = quality_conf.GrowRate and quality_conf.GrowRate[basic_conf.Type]
                local star_up_rate = star_up_conf.GrowRate and star_up_conf.GrowRate[basic_conf.Type]
                if basic_delta and quality_rate and star_up_rate then
                    local atk = math.ceil((basic_conf.Atk + basic_delta[1] * (lv - 1)) * quality_rate[1] * star_up_rate[1])
                    local def = math.ceil((basic_conf.Def + basic_delta[2] * (lv - 1)) * quality_rate[2] * star_up_rate[2])
                    self.max_hp = math.ceil((basic_conf.HP + basic_delta[3] * (lv - 1)) * quality_rate[3] * star_up_rate[3])
                    self.hp = max_hp

                    local h = {
                    
                    }

                end
            end
        end
    end
end

function gen_monster_and_atk(city, prop)
    local tr = false
    local destCity = gEtys[city.atk_eid]
    local action = 1
    if is_ply(destCity) then
        action = TroopAction.MonsterAtkPly
    end

    if is_npc_city(destCity) then
        action = TroopAction.SiegeMonsterCity
    end

    if destCity then
        local sx, sy = get_ety_pos(city)
        local dx, dy = get_ety_pos(destCity)
        
        --tr = troop_mng.create_troop(city.eid, destCity.eid, action, sx, sy, dx, dy)
        tr = troop_mng.create_troop(action, city, destCity) 
        tr.owner_id = city.eid
        local arm = {}
        for _, v in pairs(prop.Arms) do
            arm[v[1]] = v[2]
        end
        --tr:add_arm(0, {live_soldier = arm, heros = prop.Heros})
        tr:add_arm(0, {live_soldier = arm, heros = {0,0,0,0}})
    end


    if tr then
        tr:go()
        player_t.get_watchtower_info(tr)
    end

end
-- 防守玩家反攻时
function get_my_troop(self)
    local tr = false
    if self.my_troop_id then
        tr = troop_mng.get_troop(self.my_troop_id)
        if tr then return tr end
    end

    local conf = resmng.get_conf("prop_world_unit", self.propid)
    if conf then
        local sx, sy = get_ety_pos(self)
        --tr = troop_mng.create_troop(self.eid, self.eid, TroopAction.Monster, sx, sy, sx, sy)
        tr = troop_mng.create_troop(TroopAction.SiegeMonsterCity, self, self) 
        tr.speed = 2

        local arm = {}
        for _, v in pairs(conf.Arms) do
            arm[ v[1] ] = v[2]
        end
        tr:add_arm(0, {live_soldier=arm, heros={0,0,0,0}})
        self.my_troop_id = tr._id
    end
    if tr then 
        return tr
    end
end

function can_gen_small_monster(city, prop, union_id)
    local union = unionmng.get_union(union_id)
    if union.monster_city_stage == city.state then
        return false
    end
end

function get_atk_city(city, union_id)
    local num = get_atk_num(city)

end

function get_atk_num(city)
    return 0
end

function set_next_state(city, prop, time)
        city.startTime = gTime
        city.endTime = gTime + time
end

function set_timer(city, Time)
    local timeId = timer.new("monster_city", Time, city.eid)
    city.timer = timerId
end


function get_conf_by_npc(npcCity)
    --[[for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.MONSTER_CITY and v.Atk_propid == npcCity.propid then
            return resmng.prop_world_unit[v.ID]
        end
    end--]]
    local prop  = resmng.prop_world_unit[npcCity.propid]
    if prop then
        local List = prop.MonsterCrack or {}
        index=  math.random(#List)
        prop = resmng.prop_world_unit[List[index]]
        if prop then
            return prop
        else
            return  resmng.prop_world_unit[6002001]
        end
    end
end

function can_be_atk(city)
    return city.be_atk_tm == 0
end

--怪物城被攻击
function after_been_atk(atkTroop, defenseTroop)
    local mc = get_ety(atkTroop.target_eid)
    mc.be_atk_tm = gTime
    if check_atk_win(atkTroop, defenseTroop) then
        if mc then
            local parentCity = get_ety(mc.parent_id)
            if parentCity then
                local reward = get_small_mc_reward(mc)
                local pool = parentCity.reward_pool or {}
                table.insert(pool, reward)
                parentCity.reward_pool = pool
                add_act_plys(parentCity, atkTroop)
            end
        rem_ety(mc.eid)
        end
    end
    if is_ply(atkTroop.owner_eid) then
        atkTroop:back()
    end
end

function send_act_award(mc)
    for k, v in pairs(mc.act_plys) do

    end
end

--怪物城攻击玩家
function after_fight(atkTroop, defenseTroop)
    local mc = get_ety(atkTroop.owner_eid)
    if check_atk_win(atkTroop, defenseTroop) then
        local npcCity = get_ety(atkTroop.target_eid)
        local union = unionmng.get_union(defenseTroop.union_id)

        if union and npcCity then
           local citys = union.npc_citys or {}
           citys[npcCity.eid]  = nil
           union.npc_citys = citys
           npcCity.uid = npcCity.propid
           npcCity.my_troop_id = nil
           timer.del(union.mc_timer)
        end

        if mc then
            send_act_award(mc)
        end

        if is_ply(defenseTroop.owner_eid) then
            defenseTroop:back()
        end

        rem_ety(mc.eid)

    else
        if mc then
            local reward = get_mc_reward(mc)
            local pool = mc.reward_pool or {}
            table.insert(pool, reward)
            mc.reward_pool = pool
            add_act_plys(mc, defenseTroop)
        end
    end

    troop_mng.delete_troop(atkTroop._id)
end

--增加活跃玩家列表
function add_act_plys(mc, troop)
    local acts = mc.act_plys or {}
    if troop then
        for pid, v in pairs(troop.arms) do
            acts[pid] = pid
        end
    end
    mc.act_plys = acts
end

function after_atk_ply(atkTroop, defenseTroop)
    if not check_atk_win(atkTroop, defenseTroop)  then
        local mc = get_ety(atkTroop.owner_eid)
        if mc then
            local parentCity = get_ety(mc.parent_id)
            if parentCity then
                local reward = get_small_mc_reward(mc)
                local pool = parentCity.reward_pool or {}
                table.insert(pool, reward)
                parentCity.reward_pool = pool
                local acts = parentCity.act_plys or {}
                acts[defenseTroop.owner_pid] = defenseTroop.owner_pid
                parentCity.act_plys = acts
            end
        end
    end

    local mc = get_ety(atkTroop.owner_eid)
    if mc then
        rem_ety(mc.eid)
        troop_mng.delete_troop(atkTroop._id)
    end
    player_t.rm_watchtower_info(atkTroop)

end

function get_small_mc_reward(city)
    local prop = resmng.prop_world_unit[city.propid]
    local Rewards = {}
    if prop then
        for k, v in pairs(prop.Fix_award) do
            local fixAward = player_t.bonus_func[ v[1] ](prop, v[2])
            table.insert(Rewards, fixAward)
        end
    end
    return Rewards
end

function get_mc_reward(city)
    local armId = city.propid % (1000 *1000) * 1000 + city.state
    local prop = resmng.prop_monster_city[armId]
    local Rewards = {}
    if prop then 
        for k, v in pairs(prop.Reward) do
            local award = player_t.bonus_func[ v[1] ](prop, v[2])
            table.insert(Rewards, award)
        end
    end
    return Rewards
end

function check_atk_win(atkTroop, defenseTroop)
    return (atkTroop.win or 0) == 1
end

function eye_info(city, pack) 
    local ety= get_ety(city.atk_eid)
    if is_ply(ety) then
        pack.target_name = ety.name
        pack.x = ety.x
        pack.y = ety.y
    end
    if is_npc_city(ety) then
            pack.target_propid = ety.propid
            pack.x = ety.x
            pack.y = ety.y
    end
    local prop = gen_monster_prop(city)
    pack.Arms = prop.Arms
    pack.Heros = prop.Heros
    pack.propid = prop.ID
    pack.startTime = city.startTime
    pack.endTime = city.endTime
    pack.state = city.state
end


