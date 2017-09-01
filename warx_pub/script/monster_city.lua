module( "monster_city", package.seeall )
module_class(
"monster_city",
{
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    pid = 0,
    uid = 0,
    grade = 1,
    hp = 100,
    can_atk_uid = 0,
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
    defend_id = 0,
    class = 0, --区分大裂隙还是小裂隙
    remain_troop = {},  --每次反击时剩余的部队
    be_atk_list = {},   -- 被攻打的玩家列表
    reward_pool = {},   -- 奖励池在活动结束发放
    act_plys = {},      -- 参加活动的玩家
    be_atked_list = {}, --防守裂隙专用，限制防守裂隙被攻打次数
    mc_reward_pool = {},
    --atk_troops= {},    --攻击该城市的部队
    --leave_troops = {},  --从该城市出发的部队
}
)

function update_mc_ntf()
    local citys = player_t.get_do_mc_npc_info()
    if citys then
        subscribe_ntf.send_sub_ntf( "map_info", "get_do_mc_npc_req", citys)
    end
end

function try_update_ply_hurt(key, score, union)
    local inc_score = score

    local ply = getPlayer(key)
    if ply then
        local u = ply:get_union()
        if u then
            u:add_score_in_u(key, ACT_TYPE.MC, score)
        end
    end

    local org_score = rank_mng.get_score(8, key) or 0
    score = score + org_score
    rank_mng.add_data(8, key, {score})
    --任务
    local ply = getPlayer(key)
    task_logic_t.process_task(ply, TASK_ACTION.PANJUN_SCORE, inc_score)

    -- 军团内积分
    local mc_act_ply = union.mc_act_ply or {}
    local mc_ply_rank = union.mc_ply_rank or {}
    mc_ply_rank[key] = score
    mc_ply_rank.version = gTime
    mc_act_ply[key] = key
    union.mc_act_ply = mc_act_ply
    union.mc_ply_rank = mc_ply_rank
end

function try_update_union_hurt(key, score)
    local org_score = rank_mng.get_score(7, key) or 0
    score = score + org_score
    rank_mng.add_data(7, key, {score})
end

can_atk_stage =
{
    [6] = 1,
    [11] = 1,
    [18] = 1,
}

citys = citys or {}

function init(self)
    --local db = dbmng:getOne()
    --local info = db.monster_city:findOne({_id = self._id})
    --if not info then
    --    gPendingInsert.monster_city[ self._id ] = self._pro
    --end
    -- to do
end

--function on_check_pending(db, _id, chgs)
--    local t = gPendingSave.monster_city[ self._id ]
--    for k, v in pairs( chgs ) do
--        t[ k ] = v
--    end
--        gPendingSave.monster_city[ self._id ] = self._pro
--    db.monster_city:update({_id = _id}, {["$set"] = chgs})
--end

function load_monster_city()
    local db = dbmng:getOne()
    local info = db.monster_city:find({})
    while info:hasNext() do
        local m = monster_city.wrap(info:next())
        gEtys[m.eid] = m
        citys[m.atk_eid] = m.eid

        if m.band_eid ~= 0 then
            local band_citys = citys[m.band_eid] or {}
            band_citys[m.eid] = m.eid
            citys[m.band_eid] = band_citys
        end
        etypipe.add(m)
    end
    --init_redis_list()
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
    etypipe.add(self)
end

function rem_mc_by_npc(npc_id)
    local city = union_t.get_monster_city(npc_id)
    if city then
        local def_mc = monster_city.citys[city.eid]
        for eid, _ in pairs(def_mc or {}) do
            local def = get_ety(eid)
            if def then
                monster_city.remove_city(def)
            end
        end
        monster_city.citys[city.eid] = nil
        monster_city.citys[npc_id] = nil
        rem_ety(city.eid)
    end
end

function gen_monster_city(atkEid)
    local npcCity = get_ety(atkEid)
    if npcCity then
    LOG("gen monster city atk eid %d  npc %d", atkEid, npcCity.eid )
        local _id = get_eid_monster_city()
        local m = {}
        m._id = _id
        local prop = get_conf_by_npc(npcCity)
        if prop then
            m.eid = _id
            m.propid = prop.ID
            m.size = prop.Size or 4
            local x, y = get_pos_in_range(math.floor(npcCity.x/16), math.floor(npcCity.y/16), 1, 1, m.size)
            LOG("gen monster city atk eid = %d x = %d y = %d", atkEid, x, y)
            m.x = x
            m.y = y
            local union = unionmng.get_union(npcCity.uid)
            if union then
                m.grade = union.mc_grade
            end
            m.can_atk_uid = npcCity.uid
            m.endTime = gTime + 30 * 60
            m.atk_eid = npcCity.eid
            citys[m.atk_eid] = m.eid
            m = monster_city.new(m)
            gEtys[m.eid] = m
            m.class = MC_TYPE.ATK_NPC   -- 大裂隙
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
    local lv = c_get_zone_lv(x, y)
    if lv == 6 then
        if x == 39 then
            x = 37
        end
        if x == 40 then
            x = 42
        end
        if y == 39 then
            y = 37
        end
        if y == 40 then
            y = 42
        end
    end
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
            local level = c_get_zone_lv(math.floor(x/16), math.floor(y/16))
            if level == lv or lv == 6 then
                return x, y
            end
        end
    end
end

function gen_small_city(pid, prop, parentId)
    local ply = getPlayer(pid)
    if ply then
        --local m = monster_city.new({})
        local m = {}
        local r = prop.Size or 2
        m.eid = get_eid_monster_city()
        m._id = m.eid
        m.x, m.y = get_pos_in_range(math.floor(ply.x/16), math.floor(ply.y/16), 1, 1, r)
        m.endTime = gTime + 30 * 60
        m.propid= prop.City
        m.atk_eid = ply.eid
        local city_prop = resmng.prop_world_unit[prop.City] 
        if city_prop then
            m.size = city_prop.Size
        else
            m.size = r
        end
        citys[m.atk_eid] = m.eid
        local ety = get_ety(parentId)
        if ety then
            m.grade = ety.grade
        end
        m.parent_id = parentId
        m.class = MC_TYPE.ATK_PLY   -- 小裂隙
        m = monster_city.new(m)
        gEtys[m.eid] = m
        etypipe.add(m)
        LOG("small city  %d atk ply  city x %d, y %d,  propid %d", m.eid, m.x, m.y, prop.ID)
        prop = resmng.prop_world_unit[prop.City]
        if prop then
            local u = unionmng.get_union(ply.uid)
            if u then
                gen_monster_and_atk(m, prop)
                --king_city.common_ntf(resmng.MC_ROLLCALL, {ply.name}, u)
            end
        end
    end
end

function gen_defense_city(city, prop)
    local eid = get_eid_monster_city()
    --local m = monster_city.new({_id = eid})
    local m = {}
    local r = prop.Size  or 1
    m._id = eid
    m.eid = eid
    m.size = r
    m.grade = city.grade
    m.propid = prop.DefCity
    m.x, m.y = get_pos_in_range(math.floor(city.x/16), math.floor(city.y/16), 1, 1, r)
    --m.x, m.y =  c_get_pos_in_zone( math.abs(math.floor(city.x / 16) + math.random(-1, 1)), math.abs(math.floor(city.y / 16) + math.random(-1, 1)), r, r)
    m.startTime = gTime
    m.endTime = gTime + 30 * 60
    m.band_eid = city.eid
    m.can_atk_uid = city.can_atk_uid
    m.uid = 0
    city.defend_id = m.eid
    local band_citys = citys[m.band_eid] or {}
    band_citys[eid] = eid
    citys[m.band_eid] = band_citys
    --citys[m.atk_eid] = m.eid
    m.class = MC_TYPE.DEF_ATK   -- 防守裂隙
    m = monster_city.new(m)
    gEtys[m.eid] = m
    LOG("defense city eid %d %d %d", m.eid, m.x , m.y)
    etypipe.add(m)
    timer.new("remove_mc", 2 * 60 * 60, m.eid)
    m:get_my_troop()
    return m
end

function remove_city(city)
    local bandCity = get_ety(city.band_eid)
    if bandCity then
        local remain_troop = bandCity.remain_troop or {}
        table.insert(remain_troop, city.my_troop_id)
        bandCity.remain_troop = remain_troop
        if bandCity.defend_id == city.eid then
            bandCity.defend_id = nil
        end
    end
    rem_ety(city.eid)
end

function gen_monster_prop(city)
    if city.class == MC_TYPE.ATK_NPC then
        local idx = city.state or 1
        if idx == 0 then
            idx = 1
        end
        local armId = city.propid % (1000 * 1000) * 1000 + idx
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
    LOG("do monster job city %d, stage %d", city.eid, stage)
    city.state = stage
    local armId = city.propid % (1000 *1000) * 1000 + stage  
    local prop = resmng.prop_monster_city[armId]
    if not prop then return end
    -- 生成小怪打玩家
    local plyList = get_atk_ply_list(city, union, stage)
    if plyList  then
        for k, v in pairs(plyList) do
            gen_small_city(v, prop, city.eid)
        end
        king_city.common_ntf(resmng.MC_ROLLCALL, {}, union)
    end

    -- 生产防守裂隙
    --[[if can_atk_stage[stage] then
        gen_defense_city(city, prop)
    end--]]

    if prop.DefCity then
        local def_city = gen_defense_city(city, prop) or {}

        local prop = resmng.get_conf("prop_act_notify", resmng.MC_COUNTERATTACK)
        if prop then
            if prop.Chat2 then
                union:union_chat("", prop.Chat2, {def_city.x, def_city.y})
            end
        end
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

    if atkNum > union.membercount then
        local _members = union:get_members()
        for k, v in pairs(_members or {}) do
            list[k] = k
        end
        return list
    end

    local num = 0
    local all_pow = 0
    local atk_ply_time = self.atk_ply_time or {}

    local _members = union:get_members()
    for k, v in pairs(_members or {} ) do
        local pow = v:get_pow()
        all_pow = all_pow + pow
    end

    if union then
        local _members = union:get_members()
        for k, v in pairs(_members or {}) do
            local atk_times = atk_ply_time[k] or 0
            pow = v:get_pow() * (atkNum - num)
            local rand = math.random(math.floor(all_pow))
            rand = rand * (atkNum -num)
            if rand <= pow then
                if atk_times < 2 then
                    if (gTime - v._union.tmJoin) >= (12 * 3600) and not list[k] then
                        list[k] = k
                        num = num + 1
                        atk_times = atk_times + 1
                        atk_ply_time[k] = atk_times
                    end
                end
            end

            if num == atkNum then
                break
            end
            
        end
    end

    if num < atkNum then
        local _members = union:get_members()
        for k, v in pairs(_members or {}) do
            local atk_times = atk_ply_time[k] or 0
            local rand = math.random(math.floor(all_pow))
            pow = v:get_pow() * (atkNum - num)
            if rand <= pow then
                if (gTime - v._union.tmJoin) >= (12 * 3600) and not list[k] then
                    list[k] = k
                    num = num + 1
                    atk_times = atk_times + 1
                    atk_ply_time[k] = atk_times
                end
            end

            if num == atkNum then
                break
            end
        end
    end

    self.atk_ply_time = atk_ply_time

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
    local grade = city.grade or 1
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
        tr.owner_uid = 0
        local union = unionmng.get_union(destCity.uid)
        if union then
            tr.mcStage = union.monster_city_stage
            local mc_trs = union.mc_trs or {}
            mc_trs[tr._id] = tr._id
            union.mc_trs = mc_trs
        end
        tr.mcid = prop.ID
        tr.owner_id = city.eid
        local arm = {}
        local prop_arms = {}
        local prop_heros = {}
        if grade then
            prop_arms = prop.Arms[grade]
            prop_heros = prop.Heros[grade]
        end
        for _, v in pairs(prop_arms or {}) do
            arm[v[1]] = v[2]
        end
        --tr:add_arm(0, {live_soldier = arm, heros = prop.Heros})
        tr:add_arm(0, {live_soldier = arm, heros = prop_heros or {0,0,0,0}})

        if tr.mcStage == 20 then  --最后一波
            for _, id in pairs(city.remain_troop or {}) do
                local remain_tr = troop_mng.get_troop(id)
                if remain_tr then
                    remain_tr:rem_hero()
                    remain_tr:troop_discount(0.25)
                    remain_tr:merge(tr)
                end
            end
        end
    end

    if tr then
        city.my_troop_id = tr._id
        if is_ply(destCity) then
            local dis = calc_line_length(city.x, city.y, destCity.x, destCity.y)
            local speed = math.ceil(dis / 300) 
            if speed == 0 then
                speed = 1
            end
            tr:go(speed)
        else
            tr:go()
        end
        union_hall_t.battle_room_create(tr, ROOM_TYPE.MC)
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
        for _, v in pairs(conf.Arms[self.grade or 1] or {}) do
            arm[ v[1] ] = v[2]
        end
        tr:add_arm(0, {live_soldier=arm, heros=conf.Heros[self.grade or 1] or {0,0,0,0}})
        self.my_troop_id = tr._id
        tr.mcid = self.propid
    end
    if tr then 
        local bandCity = get_ety(self.band_eid)
        if bandCity then
            local remain_troop = bandCity.remain_troop or {}
            table.insert(remain_troop, tr._id)
            bandCity.remain_troop = remain_troop
        end
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
    return true
    --return city.be_atk_tm == 0
end

--怪物城被攻击
function after_been_atk(atkTroop, defenseTroop)
    if  atkTroop.mkdmg == 0 then
         atkTroop.mkdmg = 1
    end
    local mc = get_ety(atkTroop.target_eid)
    troop_mng.send_report[TroopAction.AtkMC](atkTroop, defenseTroop, mc.grade or 1)

    mc.be_atk_tm = gTime
    if check_atk_win(atkTroop, defenseTroop) then
        if mc then
            
            local score = math.floor(defenseTroop.lost) 
            local union = unionmng.get_union(atkTroop.owner_uid)
            for pid, arm in pairs(atkTroop.arms or {}) do
                local point = score * arm.mkdmg / atkTroop.mkdmg
                try_update_ply_hurt(pid, math.floor(point), union)
            end

            local parentCity = get_ety(mc.parent_id)
            if parentCity then
                local reward = get_small_mc_reward(mc)
                --[[local pool = parentCity.reward_pool or {}
                table.insert(pool, reward)
                parentCity.reward_pool = pool--]]
                --add_act_plys(parentCity, atkTroop)
                if union then
                    try_update_union_hurt(atkTroop.owner_uid, score)
                    union:add_mc_reward(reward)
                end
            end
        end
        troop_mng.delete_troop(defenseTroop._id)
        rem_ety(mc.eid)  -- 打赢消失
    else
        etypipe.add(mc)
    end
    if is_ply(atkTroop.owner_eid) then
        atkTroop:back()
    end
end


function send_union_act_award(union)
    for k, v in pairs(union.mc_act_ply or {}) do
        local ply = getPlayer(tonumber(k))
        if ply then
            ply:send_system_notice(10006, {}, {}, union.mc_reward_pool or {})
        end
    end

   -- local mc_act_ply = copyTab(union.mc_act_ply)
   -- table.sort(mc_act_ply, mc_sort)
   -- local idx = 1
   -- for k, v in pairs(resmng.prop_mc_rank_award or {}) do
   --     for i = v.Rank[1], v.Rank[2] , 1 do
   --         local pid = table.remove(mc_act_ply)
   --         local ply = getPlayer(tonumber(pid))
   --         if ply then
   --              ply:send_system_notice(10007, {}, {idx}, v.Award) 
   --              idx = idx + 1
   --         end
   --     end
   -- end

end

--function send_act_award(mc)
--    for k, v in pairs(mc.act_plys or {}) do
--        local ply = getPlayer(k)
--        local npc = get_ety(mc.atk_eid)
--        local npc_name = ""
--        if npc then
--            local prop = resmng.prop_world_unit[npc.propid]
--            if prop then
--                npc_name = prop.Name
--            end
--        end
--        
--        if ply then
--            ply:send_system_notice(10006, {}, {npc_name}, mc.mc_reward_pool or {})
--        end
--
--    end
--end

--怪物城攻击玩家占领npc
function after_fight(atkTroop, defenseTroop)
    local mc = get_ety(atkTroop.owner_eid)
    if mc and check_atk_win(atkTroop, defenseTroop) then
    INFO("[MC] monster atk npc pid = %d, eid = %d, is_mass = %s, is_win = %s", atkTroop.owner_pid, atkTroop.target_eid, atkTroop.is_mass, true)
        local npcCity = get_ety(atkTroop.target_eid)
        local union = unionmng.get_union(defenseTroop.owner_uid)

        if union and npcCity then
            local city_pro = resmng.prop_world_unit[npcCity.propid]
            if union.mc_grade > 1 and city_pro then
                king_city.common_ntf(resmng.MC_LOSE, {union.name, city_pro.Name, union.alias}, union)
            end

            local _members = union:get_members()
            for _, ply in pairs(_members or {}) do
                ply:send_system_notice(resmng.MAIL_10063, {city_pro.Name}, {city_pro.Name})
            end

            if (union.mc_grade or 1 )> 1 then
                local citys = union.npc_citys or {}
                citys[npcCity.eid]  = nil
                union.npc_citys = citys
                npcCity:reset_npc()
                timer.del(union.mc_timer)
            end
       end

       --if mc then
           --send_act_award(mc)
       --end

       if is_ply(defenseTroop.owner_eid) then
           defenseTroop:back()
           npcCity.my_troop_id = nil
       end

       rem_ety(mc.eid)
       for _, id in pairs(mc.remain_troop or {}) do
           troop_mng.delete_troop(id)
       end

   else
       if  defenseTroop.mkdmg == 0 then
           defenseTroop.mkdmg = 1
       end

       if mc then
           local union = unionmng.get_union(defenseTroop.owner_uid)
           if union then
               for pid, arm in pairs(defenseTroop.arms or {}) do
                   local score = atkTroop.lost * arm.mkdmg / defenseTroop.mkdmg or 0
                   try_update_ply_hurt(pid, math.floor(score), union)
               end
           end

           --local score = defenseTroop.get_tr_pow(atkTroop)
           local score = math.floor(atkTroop.lost)
           local reward = get_mc_reward(mc)
            if union then
                union:add_mc_reward(reward)
                try_update_union_hurt(defenseTroop.owner_uid, score)
            end

            --add_act_plys(mc, defenseTroop)
        end
    end

    troop_mng.delete_troop(atkTroop._id)
    
end

----增加活跃玩家列表
--function add_act_plys(mc, troop)
--    local union = unionmng.get_union(troop.owner_uid)
--    if union then
--        --local acts = mc.act_plys or {}
--        local acts = union.mc_act_ply or {}
--        if troop then
--            for pid, v in pairs(troop.arms) do
--                if not acts[pid] then
--                    acts[pid] = pid
--                end
--            end
--        end
--        union.mc_act_ply = acts
--    end
--    --mc.act_plys = acts
--end

function after_atk_ply(atkTroop, defenseTroop)
    if not check_atk_win(atkTroop, defenseTroop)  then
        local mc = get_ety(atkTroop.owner_eid)
        if mc then
            local parentCity = get_ety(mc.parent_id)
            if parentCity then
                local reward = get_small_mc_reward(mc)
                --[[local pool = parentCity.reward_pool or {}
                table.insert(pool, reward)
                parentCity.reward_pool = pool--]]
                local union = unionmng.get_union(defenseTroop.owner_uid)
                if union then
                    union:add_mc_reward(reward)
                end

                if parentCity then
                    local acts = parentCity.act_plys or {}
                    acts[defenseTroop.owner_pid] = defenseTroop.owner_pid
                    parentCity.act_plys = acts
                end
            end
        end
    end

    troop_mng.delete_troop(atkTroop._id)
end

function get_small_mc_reward(city)
    local prop = resmng.prop_world_unit[city.propid]
    local Rewards = {}
    local union = unionmng.get_union(city.can_atk_uid)
    if not union then
        return
    end

    if prop then
        for k, v in pairs(prop.Fix_award[city.grade or 1 ]) do
            local fixAward = player_t.bonus_func[ v[1] ](prop, v[2])
            for _, gift in pairs(fixAward) do
                table.insert(Rewards, gift)
            end
        end
    end
    return Rewards
end

function get_mc_reward(city)
    local union = unionmng.get_union(city.can_atk_uid)
    if not union then
        return 
    end

    local armId = city.propid % (1000 *1000) * 1000 + (city.state or 1)
    local prop = resmng.prop_monster_city[armId]
    local Rewards = {}
    if prop then 
        for k, v in pairs(prop.Reward[city.grade or 1] or {}) do
            local award = player_t.bonus_func[ v[1] ](prop, v[2])
            for _, gift in pairs(award) do
            table.insert(Rewards, gift)
            end
        end
    end
    return Rewards
end

function check_atk_win(atkTroop, defenseTroop)
    return defenseTroop:is_no_live_arm()
end

function eye_info(city, pack) 
    local ety= get_ety(city.atk_eid)
    if  city.class == MC_TYPE.DEF_ATK then
        local mc = get_ety(city.band_eid)
        if mc then
            pack.parent_id = mc.propid
            pack.parent_x = mc.x
            pack.parent_y = mc.y
        end
    end
    if is_ply(ety) then
        local mc = get_ety(city.parent_id)
        if mc then
            pack.parent_id = mc.propid
            pack.parent_x = mc.x
            pack.parent_y = mc.y
            local target = get_ety(mc.atk_eid)
            if target then
                pack.npc_id = target.propid
            end
        end
        pack.target_name = ety.name
        pack.target_x = ety.x
        pack.target_y = ety.y
    end
    if is_npc_city(ety) then
            pack.target_propid = ety.propid
            pack.target_x = ety.x
            pack.target_y = ety.y
    end
    local prop = gen_monster_prop(city)
    if prop then
        pack.Arms = prop.Arms
        pack.Heros = prop.Heros
        pack.propid = prop.ID
        pack.startTime = city.startTime
        pack.endTime = city.endTime
        pack.state = city.state
    end
end

function add_atk_troop(city, troopId) -- 增加前来攻击的部队
    local ft_troops = city.ft_troops or {}
    ft_troops[troopId] = troopId
    city.ft_troops = ft_troops
    city.atk_tr_tag = nil
end

function rem_atk_troop(city, troopId)
    local ft_troops = city.ft_troops or {}
    if ft_troops[troopId] then
        ft_troops[troopId] = nil
        city.ft_troops = ft_troops
        city.atk_tr_tag = nil
    end
end

function add_leave_troop(city, troopId) -- 增加前来攻击的部队
    local leave_troops = city.leave_troops or {}
    leave_troops[troopId] = troopId
    city.leave_troops = leave_troops
    city.leave_tr_tag = nil
end

function rem_leave_troop(city, troopId)
    local leave_troops = city.leave_troops or {}
    if leave_troops[troopId] then
        leave_troops[troopId] = nil
        city.leave_troops = leave_troops
        city.leave_tr_tag = nil
    end
end

function get_fast_troop(city, mode)
    local troops = {}
    if mode ==  ETY_TROOP.ATK then
        troops = city.ft_troops
    elseif mode == ETY_TROOP.LEAVE then
        troops = city.leave_troops
    end
    
    if city[mode] then
        local tr = troop_mng.get_troop( city[mode])
        if tr then 
            if tr.owner_uid ~= city.uid then
                return tr 
            else
                local troop = cal_fast_troop(city, troops)
                if troop then
                    city[mode] = troop._id
                    return troop
                end
            end
        end
    else
        local troop = cal_fast_troop(city, troops)
        if troop then
            city[mode] = troop._id
            return troop
        end
    end
end

function cal_fast_troop(city, troops)
    if not troops then return end

    local tmOver = 0
    local troop = {}
    local dels = {}
    for k, v in pairs(troops) do
        local tr =  troop_mng.get_troop(v)
        if tr and tr.tmOver then
            if (tmOver == 0 or (tmOver >= tr.tmOver and tr.tmOver > gTime and tr.tmOver ~= 0 )) and tr.owner_uid ~= city.uid then
                troop = tr
                tmOver = tr.tmOver
            end
            if tr.tmOver < gTime then
                table.insert( dels, k )
            end
        else
            table.insert( dels, k )
        end
    end
    if #dels > 0 then
        for _, v in pairs(dels) do
            troops[v] = nil
        end
    end

    if troop ~= {} then return troop end

end

function can_atk_def_mc(self, pid)
    local ply = getPlayer(pid)
    if not ply then return  false end

    local bandCity = get_ety(self.band_eid)
    if not bandCity then
        return false
    end

    local npcCity = get_ety(bandCity.atk_eid)
    if not npcCity then
        return false
    end

    if npcCity.uid ~= ply.uid then
        return false
    end

  --  local be_atked_list = self.be_atked_list or {}
  --  if  be_atked_list[pid] then
  --      return false
  --  end
    return true
end

function send_score_award()
    local prop = resmng.prop_mc_person_rank_award
    if prop then
        for k, v in pairs(prop) do
            local plys = rank_mng.get_range(8, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(8, tonumber(pid)) or 0
                INFO("[MC] person rank %d, %d, %d", v.Rank[1] + idx - 1, tonumber(pid), score)
                    local ply = getPlayer(tonumber(pid))
                    if ply then
                        ply:send_system_notice(10009, {}, {v.Rank[1] + idx - 1}, v.Award)
                    end
            end
        end
    end

    local u_award = resmng.prop_mc_union_rank_award
    if u_award then 
        for k, v in pairs(u_award) do
            local unions = rank_mng.get_range(7, v.Rank[1], v.Rank[2])
            for idx, uid in pairs(unions or {}) do
                uid = tonumber(uid)
                local s = rank_mng.get_score(7, uid) or 0 
                INFO("[MC] union rank %d, %d, %d", v.Rank[1] + idx - 1, uid, s)
                local union = unionmng.get_union(uid)
                if union then
                    local _members = union:get_members()
                    for pid, ply in pairs(_members or {}) do
                        local score = rank_mng.get_score(8, tonumber(pid)) or 0
                        local ply = getPlayer(tonumber(pid))
                        if ply then
                            ply:send_system_notice(10010, {}, {v.Rank[1] + idx -1}, v.Award)
                        end
                    end
                end
            end
        end
    end

    local us = unionmng.get_all()
    for uid, union in pairs(us or {}) do
        --local mc_ply_rank = copyTab(union.mc_ply_rank)
        local mc_ply_rank = mc_sort(union.mc_ply_rank or {})
        local idx = 1
        for k, v in pairs(resmng.prop_mc_rank_award or {}) do
            for i = v.Rank[1], v.Rank[2] , 1 do
                local ply_score = table.remove(mc_ply_rank, 1)
                if ply_score then
                    local ply = getPlayer(ply_score[1])
                    INFO("[MC] peason rank in union uid $d, idx %d, pid %d, score %d", uid, idx , ply_score[1], ply_score[2])
                    if ply then
                        ply:send_system_notice(10007, {}, {idx}, v.Award) 
                        idx = idx + 1
                    end
                end
                if #mc_ply_rank <= 0 then
                    break
                end
            end
        end
        union.mc_ply_rank = {}
    end

end

function do_sort(a, b)
    if a[2] == b[2] then
        return a[1] > b[2]
    end
    return a[2] > b[2]
end

function mc_sort(mc_ply_rank)
    local rank = {}
    for k, v in pairs(mc_ply_rank or {}) do
        if k ~= "version" then
            --local ply_score = {tonumber(k), v}
            local ply_score = {k, v}
            table.insert(rank, ply_score)
        end
    end
    table.sort(rank, do_sort)
    return rank
end

function rem_all_mc()
    for _, mc in pairs(citys or {}) do
        if type(mc) == "number" then
            local ety = get_ety(mc)
            if ety then
                troop_mng.delete_troop(ety.my_troop_id)
            end
            rem_ety(mc)
        else
            for _, v in pairs(mc or {}) do
                local ety = get_ety(v)
                if ety then
                    troop_mng.delete_troop(ety.my_troop_id)
                end
                rem_ety(v)
            end
        end
    end
    citys = {}
end

function rem_mc_in_citys(ety)
    if ety then
        if citys[ety.atk_eid] then
            citys[ety.atk_eid] = nil
        end
        if ety.band_eid ~= 0 then
            local band_citys = citys[ety.band_eid] or {}
            if band_citys[ety.eid] then
                band_citys[ety.eid] = nil
                citys[ety.band_eid] = band_citys
            end
        end
    end
end


