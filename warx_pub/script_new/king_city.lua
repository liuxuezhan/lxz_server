module( "king_city", package.seeall )
module_class("king_city",
{
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    propid = 0,
    size = 0,
    uid = 0,
    pid = 0,
    uname = "",
    state = 0,
    status = 1,
    occuTime = 1,
    startTime = 1,
    endTime = 1,
    my_troop_id = 0,
    acc_recover_times = 0,  --箭塔复活次数
    timers = {},
    atk_troops = {},
    --atk_troops= {},    --攻击该城市的部队
    --leave_troops = {},  --从该城市出发的部队
})
-- 要塞 箭塔攻击类型 index
ATK_TYPE =
{
    fire = 1,
    troop = 2,
    super = 3,
}
-- 攻击属性  index
FORCE_ATTR=
{
    force = 1,
    add = 2,
    cd = 3,
}

--- king wars state pace fight ...
season = season  or 0  -- 王城战期数
kings = kings or {}
officers = officers or {}
state = state or 0     -- 王城战目前的状态
timerId = timerId or 0 -- 王城战的计时器id
citys = citys or {}
after_atk_win = after_atk_win or {}
deal_new_defender = deal_new_defender or {}

function init()
    --to do
end

--function on_check_pending(db, _id, chgs)
--    db.king_city:update({_id = _id}, {["$set"] = chgs})
--end

function mark(m)
    gPendingInsert.king_city[ m.eid ] = m._pro
end

function load_king_city()
    local db = dbmng:getOne()
    local info = db.king_city:find({})
    local have = {}
    while info:hasNext() do
        local m = king_city.wrap(info:next())
        gEtys[m.eid] = m
        citys[m.eid] = m.eid
        have[m.propid] = m.eid
        print("king city eid = ", m.eid)
        etypipe.add(m)
    end

    init_king_citys(have)
    load_kw_state()
    set_tower_range()

    -- test
    --try_unlock_kw()
    --prepare_kw()
    --fight_kw()
end

function load_kw_state()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "kwState"})
    if not info then
        info = {_id = "kwState"}
        db.status:insert(info)
    end
    state = info.state or 1
    kings = info.kings or {}
    officers = info.officers or {}
    season = info.season or 0
    timerId = info.timer or 0
end

function init_king_citys(have)
    for k , v in pairs(resmng.prop_world_unit or {}) do
        if v.Class == CLASS_UNIT.KING_CITY and have[v.ID] == nil then
            local eid = get_eid_king_city()
            local kingCity = init_king_city(v, eid)
            gEtys[eid] = kingCity
            citys[eid] = eid
            etypipe.add(kingCity)
            mark(kingCity)
        end
    end
end

function init_king_city(prop, eid)
    local kingCity = {}
    kingCity._id = eid
    kingCity.eid = eid
    kingCity.propid = prop.ID
    kingCity.size = prop.Size
    kingCity.x = prop.X
    kingCity.y = prop.Y
    kingCity = new( kingCity )
   -- kingCity.uid = prop.ID
    init_king_state(kingCity)
    return kingCity
end

function init_king_state(kingCity)
    kingCity.state = KW_STATE.LOCK
    local prop = resmng.prop_kw_stage[KW_STATE.LOCK]
    local time =  60 * 86400
    if prop then
        time = prop.Spantime
    end
    local k_prop = resmng.prop_world_unit[kingCity.propid]
    if k_prop then
        if k_prop.Lv ~= CITY_TYPE.FORT then
            kingCity.endTime = gTime + time
        end
    end
end

function is_kw_unlock()
    -- 开服60天
    local prop = resmng.prop_kw_stage[KW_STATE.LOCK]
    local time =  60 * 86400
    if prop then
        time = prop.Spantime
    end
    if ( gTime - _G.gSysStatus.start) > time  then
        return true
    end
    -- 四个堡垒被占领
    local num = 0
    if npc_city.citys then
        for k, v in pairs(npc_city.citys or {}) do
            local npcCity = get_ety(v) 
            if npcCity.lv == 1 and (npcCity.uid ~= 0 ) then
                num = num + 1
            end
        end
        if num == 4 then
            return true
        end
    end

    return false
end

function try_unlock_kw()
    if state ~= KW_STATE.LOCK and state ~= KW_STATE.UNLOCK then
        return
    end

    if is_kw_unlock() == true then
        --unlock_kw()
        prepare_kw()
    end
end

function set_citys_state(state)
    for k, v  in pairs(citys or {}) do
        local city = get_ety(v)
        if city then
            city.state = state
            etypipe.add(city)
            try_set_tower_range(city)
        end
    end
end

function kw_notify()
    print("king war notify timer")
    local prop = resmng.get_conf("prop_act_notify", resmng.KW_END)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
        end
        if prop.Chat1 then
            Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", prop.Chat1, {})
        end
    end
    for k, v in pairs(resmng.prop_kw_notify or {}) do
        local time = resmng.prop_kw_stage[state].Spantime * 60

        if v.BeforeTime then
            local ahead = time - v.BeforeTime

            if player_t.debug_tag then -- debug 
                ahead = 2
            end

            if ahead > 0 then
                local timerId = timer.new("kw_notify", ahead, k)
            end
        end
    end
end

function prepare_kw_notify()
    local prop = resmng.get_conf("prop_act_notify", resmng.KW_PREPARE)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
        end
        if prop.Chat1 then
            Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", prop.Chat1, {})
        end
    end
    for k, v in pairs(resmng.prop_kw_notify or {}) do
        local time = resmng.prop_kw_stage[state].Spantime * 60

        if v.BeforeTime then
            local ahead = time - v.BeforeTime

            if player_t.debug_tag then -- debug 
                ahead = 2
            end

            if ahead > 0 then
                local timerId = timer.new("kw_notify", ahead, k)
            end
        end
    end
end

function send_notify(notify_id, occu_time)
    if notify_id == resmng.KW_OCCUPY_TIME then
        local king = get_king()
        local union = unionmng.get_union(king.uid)
        if union then
            local conf = resmng.prop_act_notify[notify_id]
            if conf then
                if conf.Notify then
                    Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify, {union.name, occu_time})
                end
                if conf.chat then
                    Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", conf.Chat, {union.name, occu_time} )
                end
            end
        end
        return
    end

    local conf = resmng.prop_kw_notify[notify_id]

    if conf then

        local time = conf.BeforeTime / 60

        if notify_id == 1 or notify_id == 2 then
            time = time / 60
        end

        if conf.SendMail then
            local content = conf.SendMail
            -- for easy
            --for k, ply in pairs(gPlys) do
              --  ply:send_system_notice(content)
            --end
            player_t.send_system_to_all(content, {},{time})
        end


        if conf.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify, {time})
        end

        if conf.Chat then
            Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "",  conf.Chat, {time} )
        end
    end

end

function set_kw_state(newState)
    local kingCity = get_king()
    kingCity.state = newState
    set_citys_state(newState)

    state = newState
    gPendingSave.status["kwState"].state = newState
    update_act_tag()
end

function set_kw_timer(newTimerId)
    timer.del(timerId)

    timerId = newTimerId
    gPendingSave.status["kwState"].timer = newTimerId
end

function unlock_kw()
    for k, v in pairs(citys or {}) do
    end
    set_kw_state(KW_STATE.UNLOCK)
    do_timer()
end

function prepare_kw()
    set_kw_state(KW_STATE.PREPARE)

    prepare_kw_notify() --  发放全服通知定时器

    do_timer()
end

function fight_kw()
    local prop = resmng.get_conf("prop_act_notify", resmng.KW_START)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{})
        end
        if prop.Chat1 then
            Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", prop.Chat1, {})
        end
    end
    clear_officer()
    kw_mall.rem_all_buf()
    clear_kings_debuff()
    add_last_king_debuff()
    season = season + 1
    gPendingSave.status["kwState"].season = season
    officers = {}
    gPendingSave.status["kwState"].officers = officers
    monster.rem_super_boss()
    fight_again()
end

function clear_kings_debuff()
    for k, king in pairs(kings or {}) do
        local uid = king[3]
        local union = unionmng.get_union(uid)
        if union then 
            union:clear_kw_buff()
        end
    end
end

function gen_npc_buf()
    local buffs = copyTab(resmng.prop_kw_buff or {})
    local count = get_table_valid_count(buffs)
    if count <= 0 then return end

    for k, v in pairs(npc_city.citys or {}) do
        if count <= 0 then return end
        local city = get_ety(v)
        if city then
            if city.lv == 1 then
                local index = math.random(count)
                local prop = buffs[index]
                if prop then
                    local bufid = prop.Buff
                    local kw_buff = {} 
                    table.insert(kw_buff, bufid)
                    table.remove(buffs, index)
                    count = count -1
                    city.kw_buff = kw_buff

                    local buf = {}
                    if kw_buff[1] then
                        buf = resmng.get_conf("prop_buff", kw_buff[1]) or {}
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

                    local ntf_prop = resmng.get_conf("prop_act_notify", resmng.FORTRESS_BUFF)
                    local npc_conf = resmng.prop_world_unit[city.propid]
                    if ntf_prop and ef_name and city.lv == 1 and npc_conf then
                        local union = unionmng.get_union(city.uid)
                        if union then
                            if  ntf_prop.Chat2 then
                                union:union_chat("", ntf_prop.Chat2, {npc_conf.Name, ef_name, ef_value})
                            end
                        end
                    end

                end
            end
        end
    end
end

function add_last_king_debuff()
    local num = 0
    local king = kings[season]

    if not king then return end


    local uid = king[3]
    local union = unionmng.get_union(uid)
    if not union then return end

    if king then
        for k = season, 1, -1 do
            if not kings[k] then break end
            if kings[k][3] == king[3] then
                num = num + 1
            else
                break
            end
        end
    end

    if num == 0 then return end
    local count = get_table_valid_count(resmng.prop_kw_debuff or {})

    if num > count then
        num = count
    end

    local prop = resmng.get_conf("prop_kw_debuff", num)
    if prop then
        union:add_kw_buf(prop.Debuff, -1)
    end
end

function clear_city_uid()
    for k, v in pairs(citys or {}) do
        local city = get_ety(k)
        city.uid = 0  --初始化所以王城的uid都是0  这样才不会互相误伤
        --city.pid = 0
    end
end



function fight_again()
    clean_timer()
    set_kw_state(KW_STATE.FIGHT)
    local kingCity = get_king()
    if kingCity then
        reset_other_city(kingCity)

        if kingCity.uid ~= 0 then
            do_timer()
        else
            kingCity.endTime = nil
        end
        etypipe.add(kingCity)
    end
end

function pace_kw()
    monster.reset_super_boss()
    clear_citys_timer()

    timer.new("select_default_king", 3600)

    do_peace_city() --初始化个城市

    set_kw_state(KW_STATE.PACE)
    kw_notify() --  发放全服通知定时器
    do_timer()
    gen_npc_buf()  -- 刷新新buf
end

function do_peace_city()
    for k, v in pairs(citys or {}) do
        local city = get_ety(v)
        if city then
            if  resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.FORT then
                city.uid = 0  --初始化所以王城的uid都是0  这样才不会互相误伤
                --city.pid = 0  --初始化所以王城的uid都是0  这样才不会互相误伤
                city.uname = nil  --初始化所以王城的uid都是0  这样才不会互相误伤
                city.status = 0 --要塞失效

                local troop = city:get_my_troop()
                if troop.owner_eid ~= city.eid then
                    troop:back()
                    --troop_back(troop)
                end
            end
            etypipe.add(city)
        end
   end
end

function clear_citys_timer()
    for k, v in pairs(citys or {}) do 
        local city = get_ety(k)
        if city then
            clear_timer(city)
        end
    end
end


function do_timer()
    local time = resmng.prop_kw_stage[state].Spantime
    local nextStage = resmng.prop_kw_stage[state].NextStage
    local timerId = timer.new("king_state", time, nextStage)

    local kingCity = get_king()
    kingCity.startTime = gTime
    kingCity.endTime = gTime + time
    etypipe.add(kingCity)

    set_kw_timer(timerId)
end

function clean_timer()
    timer.del(timerId)
end

function gen_atk_npc(city)
    local tr = false
    local kingCity = get_king()
    local conf = resmng.get_conf("prop_world_unit", city.propid)

    if conf then
        if is_super_boss() then

        else
            local arm = {}
            for _,v in pairs(conf.Arms or {}) do
                arm[v[1]] = v[2]
            end
            tr = troop_mng.create_troop(TroopAction.Npc, city, kingCity, arm)
        end
    end

    if tr then return tr end
end

function get_king()
    for k, v in pairs(citys or {}) do 
        local city = get_ety(v)

        if city then
            if resmng.prop_world_unit[city.propid].Lv ==  CITY_TYPE.KING_CITY then
                return city
            end
        end
    end
end

function fire_win(kingCity, atkCity)
    --kingCity.uid = atkCity.uid
    kingCity.uid = 0
    --kingCity.pid = 0
    local union = unionmng.get_union(atkCity.uid)
    if union then
        --kingCity.uname = union.alias
    end
    kingCity.my_troop_id = nil
    clear_timer(atkCity)

    deal_new_defender[CITY_TYPE.KING_CITY](kingCity)
    etypipe.add(atkCity)
end

-- 要塞npc攻击王城
function try_atk_king(city)
    print("city atk king city ", city.propid)
    local kingCity = get_king()

    if can_atk_king(city) then
       -- local troop = gen_atk_npc(city)
        --troop:go()
        local prop = resmng.prop_world_unit[city.propid]
        if prop then
            local force = 0
            if is_super_boss() then
                local force = get_force_prop(city, "super", "force") or 0
            else
                local force = get_force_prop(city, "troop", "force") or 0
            end
            local troop = kingCity:get_my_troop()
            --local troop = troop_mng.get_troop(kingCity.my_troop_id)
            if troop then
                troop:apply_dmg(force)
                if not troop:has_alive() then
                    fire_win(kingCity, city)
                    if troop.owner_eid ~= kingCity.eid then
                        troop:back()
                    end
                else
                    set_timer(city, "troop")
                end
            end
            --local fireTroop = get_fire_troop(city)
            --fight.fight.pvp(TroopAction.TOWER, fireTroop, defenseTroop)
        end
    end

end

function get_city_type(city)
    return resmng.prop_world_unit[city.propid].Lv
end

function get_cd_time(Type, cityType)
    local table = { ["troop"] = {0,0,18}, [ "fire" ] = {0, 15, 30}, [ "towerDown" ] = {[2] = 36}}
    return table[Type][cityType]
end

function get_force_prop(city, Type, attr)
    local union = unionmng.get_union(city.uid)
    local factor = 0
    if union then
        local leader = getPlayer(union.leader)
        if leader then
            if Type == "fire" then
                factor = leader:get_num("BombardmentDamage_R")
            elseif Type == "troop" or Type == "super" then
                factor = leader:get_num("MonsterDamage_R")
            end
        end
    end

    if factor == 0 then
        factor = 10000
    end

    local prop = resmng.prop_world_unit[city.propid]
    if prop then
        if attr == "cd" then
            return prop.Fire_force[ATK_TYPE[Type]][FORCE_ATTR[attr]]
        elseif attr == "force" then
            if prop.Fire_force[ATK_TYPE[Type]][FORCE_ATTR[attr]] then
                local base_force = prop.Fire_force[ATK_TYPE[Type]][FORCE_ATTR[attr]]
                local troop = troop_mng.get_troop(city.my_troop_id)
                local pow = 0
                if troop and troop.owner_eid ~= city.eid then
                    pow = troop:get_tr_pow()
                end
                local force = base_force + prop.Fire_force[ATK_TYPE[Type]][FORCE_ATTR.add] * pow 
                force = force * factor * 0.0001
                return force
            end
        elseif attr == "add" then
            return prop.Fire_force[ATK_TYPE[Type]][FORCE_ATTR[attr]]
        end
    end
end

function set_timer(city, Type, troopId)
    local cityType = get_city_type(city)
    --local time = get_cd_time(Type, cityType)
    local time = 0
    if Type == "towerDown" then
        time = get_cd_time(Type, cityType)
    else
        time = get_force_prop(city, Type, "cd")  or 60
    end

    local timerId = timer.new("king_city", time, city.eid, Type, troopId)
    if troopId then
        city.timers[troopId] = timerId
    else
        city.timers[Type] = timerId
        if Type ~= "fire" then
            city.startTime = gTime
            city.endTime = gTime + time
        end
    end

    if Type == "towerDown" then
        city.startTime = gTime
        city.endTime = gTime + time
    end
    etypipe.add(city)
    try_set_tower_range(city) -- 如果是箭塔，重置扫描范围
end
--- 要塞对王城射箭
function try_fire_king(city)
    print("city atk fire city ", city.propid)
    local kingCity = get_king()

    if can_atk_king(city) then
        local prop = resmng.prop_world_unit[city.propid]
        if prop then
            --local force = get_force_prop(city, "troop", "force") or 0
            local force = get_force_prop(city, "fire", "force") or 0
            --local troop = troop_mng.get_troop(city.my_troop_id)
            local troop = kingCity:get_my_troop()
            if troop then
                troop:apply_dmg(force)
                if not troop:has_alive() then
                    fire_win(kingCity, city)
                    if troop.owner_eid ~= kingCity.eid then
                        troop:back()
                    end
                else
                    set_timer(city, "fire")
                end
            end
            --local fireTroop = get_fire_troop(city)
            --fight.fight.pvp(TroopAction.TOWER, fireTroop, defenseTroop)
        end
    end
    
end

function pass_troop_enter(city, troopId)
    local tr = troop_mng.get_troop(troopId)
    if tr and tr:is_go() then
        city.atk_troops[troopId] = troopId
        try_fire_troop(city, troopId)
    end
end

function pass_troop_leave(city, troopId)
    local tr = troop_mng.get_troop(troopId)
    if tr then
        local be_atk_list = tr.be_atk_list or {}
        if be_atk_list[city.eid] then
            be_atk_list[city.eid] = nil
            tr.be_atk_list = be_atk_list
            etypipe.add(tr)
            try_set_tower_range(city)
        end
        --Rpc:around0(city.eid, "leave_tower", city.eid, tr.eid)
        local atk_troops = city.atk_troops
        if atk_troops then
            atk_troops[troopId] = nil
            city.atk_troops = atk_troops
        end
    end
end

-- 箭塔射部队
function try_fire_troop(city, troopId)
    print("city atk fire troop ", city.propid, troopId)
    if not city.atk_troops[troopId] then
        return
    end

    local troop = troop_mng.get_troop(troopId)
    if troop then
        if can_fire_troop(city, troop) then
            local prop = resmng.prop_world_unit[city.propid]
            if prop then
                local force = get_force_prop(city, "fire", "force") or 0
                troop:apply_dmg(force)
                if troop:has_alive() then
                    local be_atk_list = troop.be_atk_list or {}
                    be_atk_list[city.eid] = city.eid
                    troop.be_atk_list = be_atk_list
                    set_timer(city, "fire", troopId)
                    etypipe.add(troop)
                else
                    local be_atk_list = troop.be_atk_list or {}
                    if be_atk_list[city.eid] then
                        be_atk_list[city.eid] = nil
                        troop.be_atk_list = be_atk_list
                        etypipe.add(troop)
                    end
                    troop:back()
                end
            end
        else
            local be_atk_list = troop.be_atk_list or {}
            if be_atk_list[city.eid] then
                be_atk_list[city.eid] = nil
                troop.be_atk_list = be_atk_list
            end
            etypipe.add(troop)
        end
    end
end

function clear_fire_troop(self)
    for k, v in pairs(self.atk_troops or {}) do
        local troop = troop_mng.get_troop(k)
        if troop then
            local be_atk_list = troop.be_atk_list or {}
            if be_atk_list[self.eid] then
                be_atk_list[self.eid] = nil
                troop.be_atk_list = be_atk_list
                etypipe.add(troop)
            end
        end
    end
end

function deal_atked_troop(troop)
    if not troop.win then
        -- 部队撤回
    end
end

function can_fire_troop(city, troop) 

    if city.state ~= KW_STATE.FIGHT then
        return false
    end

    if city.status == 0 then
        return false
    end

    if city.uid == troop.owner_uid then
        return false
    end

    if troop:is_back() then
        return false
    end

    local kingCity = get_king()
    if kingCity.uid == troop.owner_uid then
        return false
    end
    return true
end

function get_fire_troop(city)
    -- to do 
    return get_my_troop(city)
end

function get_dmg(city)
    ---to do
    return 1000
end

function fire_king(city, mkdmg)
    -- to do
end

function can_atk_king(city)
    local kingCity = get_king()
    if city.state ~= KW_STATE.FIGHT then
        return false
    end

    if city.uid ~= kingCity.uid and city.uid ~= 0 then
        city.status = 1
        return true
    else
        city.status = 0
        return false
    end
end

function is_super_boss()
    local num = 0
    local kingCity = get_king()

    for k, v in pairs(citys or {}) do 
        local city = get_ety(v)
        if resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.FORT and city.uid ~= kingCity.uid then
            num = num + 1
        end
    end

    return num == 4
end

function get_my_troop(self)
    local tr = false
    if self.my_troop_id and self.my_troop_id ~= 0 then
        tr = troop_mng.get_troop(self.my_troop_id)
        if tr then return tr end
    end

    -- npc 守城

    if self.uid == 0 or self.uid == self.propid then

        local conf = resmng.get_conf("prop_world_unit", self.propid)
        if conf then
            if conf.Lv == CITY_TYPE.TOWER then  --箭塔没有npc守军
                tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self,{live_soldier = {[3002] = 0}, heros = {0,0,0,0}})
            else
                local arm = {}
                if conf.Arms  then
                    for _, v in pairs(conf.Arms or {}) do
                        arm[ v[1] ] = v[2]
                    end
                end
                tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self, arm)
                if conf.Arms then
                    local arm = {}
                    for _, v in pairs(conf.Arms or {}) do
                        arm[ v[1] ] = v[ 2 ]
                    end
                    tr:add_arm(0, {live_soldier = arm,heros = conf.Heros or {0,0,0,0}})
                end
            end
        end
        tr.owner_uid = 0
        self.my_troop_id = tr._id
    else
        tr = troop_mng.create_troop(TroopAction.HoldDefense, self, self)
        tr.owner_uid = self.uid
    end

    if tr then
        return tr
    end
end

function deal_troop(atkTroop, defenseTroop)
    atkTroop.be_atk_list = nil
    defenseTroop.be_atk_list = nil

    if check_atk_win(atkTroop) then
        local city = get_ety(atkTroop.target_eid)
        local lv = resmng.prop_world_unit[city.propid].Lv
        if lv == CITY_TYPE.FORT then
            if city.eid ~= defenseTroop.owner_eid then
                defenseTroop:back()
            else
                troop_mng.delete_troop(defenseTroop._id)
            end
            npc_city.try_hold_troop(city, atkTroop)
        end
        if lv == CITY_TYPE.TOWER then
            if city.eid ~= defenseTroop.owner_eid then
                defenseTroop:back()
            else
                troop_mng.delete_troop(defenseTroop._id)
            end
            if city.uid == atkTroop.owner_uid then
                npc_city.try_hold_troop(city, atkTroop)
            else
                atkTroop:back()
            end
        end
        if lv == CITY_TYPE.KING_CITY then
            if defenseTroop.owner_eid ~= defenseTroop.target_eid then
                defenseTroop:back()
            else
                troop_mng.delete_troop(defenseTroop._id)
            end
            npc_city.try_hold_troop(city, atkTroop)
        end
    else
        atkTroop:back()
    end
end

function reset_other_city(kingCity)
    for k, v in pairs(citys or {}) do
        local city = get_ety(k)
        if city then
            if resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.TOWER then
                city.uid = kingCity.uid 
                --city.pid = kingCity.pid 
                city.uname = kingCity.uname
                local troop = city:get_my_troop()
                if troop.owner_eid ~= city.eid then
                    troop:back()
                    --troop_back(troop)
                else  --清除要塞原npc部队
                    troop_mng:delete_troop(troop._id)
                    city.my_troop_id = nil
                end
            elseif resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.FORT then
                city.occuTime = gTime
                try_atk_king(city)
                try_fire_king(city)

            end
            etypipe.add(city)
        end
    end
end

function troop_back(troop)
    local tid = troop._id
    troop_mng.delete_troop(tid)
    troop:notify_owner()
    local target = get_ety(troop.target_eid)
    local dx, dy = get_ety_pos(target)
    for pid, arm in pairs(troop.arms or {}) do
        if pid > 0 then
            local ply = getPlayer(pid)
            if ply then
                ply:rem_busy_troop(tid)
                local troop = troop_mng.create_troop(TroopAction.HoldDefense, ply, target, arm)
                troop.curx, troop.cury = dx, dy
                troop:back()
            end
        end
    end
end


function after_fight(atkTroop, defenseTroop)
    if check_atk_win(atkTroop) then
        local city = get_ety(atkTroop.target_eid)


        local lv = resmng.prop_world_unit[city.propid].Lv
        after_atk_win[lv](atkTroop, defenseTroop)
        city.hold_troop = {}
    else
        deal_troop(atkTroop, defenseTroop)
    end
end

after_atk_win[CITY_TYPE.FORT] = function(atkTroop, defenseTroop)
    local city = get_ety(atkTroop.target_eid)
    local kingCity = get_king()

    if city.uid == 0 then -- npc 被打败有军团礼包
        local union = unionmng.get_union(atkTroop.owner_uid)
        local prop = resmng.prop_world_unit[city.propid]
        if prop then
            local award = prop.Base_award or {"mutex_award",{{"item",2016002,1,500}}}
            if union then
                local _members = union:get_members() 
                for _, mem in pairs(union._members or {}) do
                    union_item.add(mem, award, UNION_ITEM.KING)
                end
            end
        end
    end

    city.uid = atkTroop.owner_uid
    --city.pid = atkTroop.owner_pid
    city.my_troop_id = nil
    local union = unionmng.get_union(city.uid)
    if union then
        city.uname = union.alias
    end
    clear_timer(city)
    deal_troop(atkTroop, defenseTroop)
    --npc_city.try_hold_troop(city, atkTroop)
    deal_new_defender[CITY_TYPE.FORT](city, kingCity)
    etypipe.add(city)
end

after_atk_win[CITY_TYPE.TOWER] = function(atkTroop, defenseTroop)
    local city = get_ety(atkTroop.target_eid)
    city.status = 0
    city.my_troop_id = nil
    clear_timer(city)

    local union = unionmng.get_union(atkTroop.owner_uid)
    local prop = resmng.get_conf("prop_act_notify", resmng.GUARD_TOWER_PARALYSIS_1)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify, {city.x, city.y, city.x, city.y, union.name}) 
        end
    end
    if prop.Chat2 then
        if union then
            union:union_chat("", prop.Chat2, {city.x, city.y, city.x, city.y})
        end
    end

    local def_union = unionmng.get_union(city.uid)
    local def_prop = resmng.get_conf("prop_act_notify", resmng.GUARD_TOWER_PARALYSIS_2)
    if def_prop and def_union then
        if def_prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, def_conf.Notify,{city.x, city.y, city.x, city.y, def_union.name}) 
        end
        if def_prop.Chat2 then
            if def_union then
                def_union:union_chat("", prop.Chat2, {city.x, city.y, city.x, city.y, union.name})
            end
        end
    end

    set_timer(city, "towerDown")
    etypipe.add(city)
    deal_troop(atkTroop, defenseTroop)
    city:clear_fire_troop()
    try_set_tower_range(city)
end

after_atk_win[CITY_TYPE.KING_CITY] = function(atkTroop, defenseTroop)
    local city = get_ety(atkTroop.target_eid)

    if city.uid == 0 then -- npc 被打败有军团礼包
        local union = unionmng.get_union(atkTroop.owner_uid)
        local prop = resmng.prop_world_unit[city.propid]
        if prop then
            local award = prop.Base_award or {"mutex_award",{{"item",2016002,1,10000}}}
            if union then
                local _members = union:get_members() 
                for _, mem in pairs(union._members) do
                    union_item.add(mem, award, UNION_ITEM.KING)
                end
            end
        end
    end

    city.uid = atkTroop.owner_uid
    --city.pid = atkTroop.owner_pid
    city.my_troop_id = nil
    local union = unionmng.get_union(city.uid)
    if union then
        city.uname = union.alias
    end
    deal_troop(atkTroop, defenseTroop)
    clear_timer(city)

    local prop = resmng.get_conf("prop_act_notify", resmng.ANCIENT_FORTRESS_OCCUPY)
    local king_conf = resmng.get_conf("prop_world_unit", city.propid)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{union.name, king_conf.Name}) 
        end
    end
    if prop.Chat2 then
        local union = unionmng.get_union(atkTroop.owner_uid)
        if union then
            union:union_chat("", prop.Chat2,  {king_conf.X, king_conf.Y, king_conf.Name})
        end
    end

    set_timer_notify(city)

    deal_new_defender[CITY_TYPE.KING_CITY](city)
    etypipe.add(city)

    --任务
    local city_type = 0
    local prop_build = resmng.get_conf("prop_world_unit", city.propid)
    if prop_build ~= nil and prop_build.Class == 4 and prop_build.Mode == 1 and prop_build.Lv == 1 then
        local _members = union:get_members() 
        for k, v in pairs(union._members or {}) do
            task_logic_t.process_task(v, TASK_ACTION.OCC_NPC_CITY, 5)
        end
    end

end

function check_atk_win(atkTroop)
    return (atkTroop.win or 0) == 1
end

function clear_timer(city)
    for k, v in pairs(city.timers or {}) do
        timer.del(v)
    end
    city.startTime = nil
    city.endTime = nil
    city.timers = nil
    etypipe.add(city)
end

function set_timer_notify(city)
    local timers = citys.timers or {}
    local time = 4 * 60 * 60
    local timerId = timer.new("kw_notify", time, resmng.KW_OCCUPY_TIME, 4)
    table.insert(timers, timerId)
    time = 7 * 60 * 60
    timerId = timer.new("kw_notify", time, resmng.KW_OCCUPY_TIME, 7)
    table.insert(timers, timerId)
    city.timers = timers
end

deal_new_defender[CITY_TYPE.FORT] = function(city, kingCity)
    city.occuTime = gTime
    try_atk_king(city)
    try_fire_king(city)
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, self)
end

--[[deal_new_defender[CITY_TYPE.TOWER] = function(city)
    try_atk_king(city)
    try_fire_king(city)
end--]]

deal_new_defender[CITY_TYPE.KING_CITY] = function(city)
    fight_again()
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, city)
end

function reset_tower(city)
    print("reset_tower ", city.propid)

    local union = unionmng.get_union(city.uid)
    local prop = resmng.get_conf("prop_act_notify", resmng.GUARD_TOWER_RECOVERY_1)
    if prop then
        if prop.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{city.x, city.y}) 
        end
    end
    if prop.Chat2 then
        --Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", string.format("towner down,", conf.Chat))  
    end

    city.status = 1
    city.startTime = nil
    city.endTime = nil
    etypipe.add(city)
    try_set_tower_range(city)
end

function try_set_tower_range(city)
    if (get_city_type(city) or 0) == CITY_TYPE.TOWER then
        c_add_scan(city.eid, 5)
        print("add_scan", city.x, city.y)
    end
end

function set_tower_range()
    for k, v in pairs(citys or {}) do
        local city = get_ety(v) 
        if city then
            if (get_city_type(city) or 0) == CITY_TYPE.TOWER then
                c_add_scan(city.eid, 5)
                print("add_scan", city.x, city.y)
            end
            if (get_city_type(city) or 0) == CITY_TYPE.FORT then
                city.status = 0
                etypipe.add(city)
            end
        end
    end
end

function eye_info(city, pack)
    local lv =  resmng.prop_world_unit[city.propid].Lv
    if lv == CITY_TYPE.FORT then
        pack.defender = city.uid
        pack.uname = city.uname
        pack.dmg = get_force_prop(city, "fire", "force")
        if is_super_boss() then
            pack.troop_dmg = get_force_prop(city, "super", "force") or 0
        else
            pack.troop_dmg = get_force_prop(city, "troop", "force") or 0
        end

    elseif lv == CITY_TYPE.TOWER then
        pack.defender = city.uid
        pack.uname = city.uname
        pack.dmg = get_force_prop(city, "fire", "force")
    elseif lv == CITY_TYPE.KING_CITY then
        pack.defender = city.uid
        pack.uname = city.uname
        if city.uid ~= city.propid then
            local king = kings[season]
            if king then
                local ply = getPlayer(king[2])
                if ply then
                    pack.kingid = ply.pid
                    pack.kingname = ply.name
                    pack.kingphoto = ply.photo
                    pack.score = king[4]
                end
            end
        end
    end
end

function acc_tower_recomer(city)
end

function select_default_king()
    if not kings[season] then
        local kingCity = get_king()
        local union = unionmng.get_union(kingCity.uid)
        if union then
            select_king(union, union.leader)
        end
    end
end

function select_king_by_leader(self, pid)
    local kingCity = get_king()
    local union = unionmng.get_union(kingCity.uid)
    if union then
        if union.leader == self.pid then
            select_king(union, pid)
        end
    end
end

function get_cur_king()
    return kings[season]
end

function select_king(union, pid)
    local ply = getPlayer(pid)
    if ply and union:has_member(ply) then
        local king = {season, pid, union.uid, 0, gTime, ply.name, ply.flag, ply:get_castle_lv(), union.name}
        -- 国王加入到
        kings[season] = king
        --table.insert(kings,  king)
        gPendingSave.status["kwState"].kings = kings
        ply.officer = KING   -- 任命国王
        add_officer_buff(ply)
        officers[KING] = pid
        gPendingSave.status["kwState"].officers = officers
        etypipe.add(ply)
    end
end

function add_officer_buff(ply)
    local prop = resmng.get_conf("prop_kw_officer", ply.officer or 0)
    if prop then
        for k, buf_id in pairs(prop.Buff or {}) do
            ply:add_buf(buf_id, -1)
        end
    end
end

function rem_officer_buff(ply)
    local prop = resmng.get_conf("prop_kw_officer", ply.officer or 0)
    if prop then
        for k, buf_id in pairs(prop.Buff or {}) do
            ply:rem_buf(buf_id, -1)
        end
    end
end

function select_officer(king, pid, index)
    if kings[season][2] ~= king.pid then
        return
    end
    if officers[ index ] then
        local ply = getPlayer(officers[index])
        if ply then
            ply.officer = 0
        end
    end
    local ply = getPlayer(pid)
    if ply and (ply.offiecer ~= KING) then
        local preOfficer = ply.officer
        officers[preOfficer] = nil
        ply.officer = index
        add_officer_buff(ply)
        officers[index] = pid
        gPendingSave.status["kwState"].officers = officers

        local prop = resmng.get_conf("prop_act_notify", resmng.OFFICIAL_APPOINTMENT)
        if prop then
            local officer_conf = resmng.prop_kw_officer[index]
            if not officer_conf then
                officer_conf = {}
            end
            if prop.Notify then
                Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify,{ply.name, officer_conf.GDDesc})
            end
            if prop.Chat1 then
                Rpc:chat({pid=-1,gid=_G.GateSid}, 0, 0, 0, "system", "", prop.Chat1, {ply.name, officer_conf.GDDesc})
            end
        end

        etypipe.add(ply)
    end
end

function rem_officer(king, index)
    if kings[season][2] ~= king.pid then
        return
    end
    local ply = getPlayer(officers[index])
    if ply then
        ply.officer = 0
    end
    officers[index] = nil
    gPendingSave.status["kwState"].officers = officers
end

function mark_king(score)
    local king = kings[season]
    if king then
        local point = king[4] or 0
        point = point + score
        king[4] = point
        kings[season] = king
        gPendingSave.status["kwState"].kings = kings
        return point
    end
end

function clear_officer()
    local king = kings[season]
    
    if king then
        local ply = getPlayer(king[2])
        rem_officer_buff(ply)
        if ply then
            ply.officer = 0
        end
        etypipe.add(ply)
    end
    for k, v in pairs(officers or {}) do 
        local ply = getPlayer(v)
        rem_officer_buff(ply)
        if ply then
            ply.officer = 0
        end
        etypipe.add(ply)
    end

    officers = {}
    gPendingSave.status["kwState"].officers = officers
end

function add_kw_buff(union, tr)
    for k, v in pairs(union.npc_citys or {}) do
        local city = get_ety(v)
        if city then
            for k, buffid in pairs(city.kw_buff or {}) do
                tr:add_tr_ef(buffid)
            end
        end
    end

    for k, v in pairs(union.kw_bufs or {}) do
        tr:add_tr_ef(v)
    end
end

function rem_kw_buff(union, tr)
    for k, v in pairs(union.npc_citys or {}) do
        local city = get_ety(v)
        if city then
            for k, buffid in pairs(city.kw_buff or {}) do
                tr:rem_tr_ef(buffid)
            end
        end
    end

    for k, v in pairs(union.kw_bufs or {}) do
        tr:rem_tr_ef(buffid)
    end
end

function update_act_tag()
    act_tag = gTime
end
