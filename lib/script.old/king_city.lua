module_class("king_city",
{
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    propid = 0,
    size = 0,
    uid = 0,
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

function on_check_pending(db, _id, chgs)
    db.king_city:update({_id = _id}, {["$set"] = chgs})
end

function mark(m)
    local db = dbmng:getOne(m.eid)
        db.king_city:insert(m._pro)
    --[[if not m.makrtm  then
        m.marktm = gTime
        db.npc_city:insert(m)
    else
        m.marktm = gTime
        db.npc_city:update({_id = m._id}, m)
    end--]]
end

function load_king_city()
    local db = dbmng:getOne()
    local info = db.king_city:find({})
    local have = {}
    while info:hasNext() do
        local m = king_city.new(info:next())
        gEtys[m.eid] = m
        mark_eid(m.eid)
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
end

function init_king_citys(have)
    for k , v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.KING_CITY and have[v.ID] == nil then
            local eid = get_eid_king_city()
            local kingCity = init_king_city(v, eid)
            gEtys[eid] = kingCity
            citys[eid] = eid
            mark_eid(eid)
            etypipe.add(kingCity)
            mark(kingCity)
        end
    end
end

function init_king_city(prop, eid)
    local kingCity = new({})
    kingCity._id = eid
    kingCity.eid = eid
    kingCity.propid = prop.ID
    kingCity.size = prop.Size
    kingCity.x = prop.X - 4
    kingCity.y = prop.Y - 4
   -- kingCity.uid = prop.ID
    init_king_state(kingCity)
    return kingCity
end

function init_king_state(kingCity)
    kingCity.state = KW_STATE.LOCK
end

function is_kw_unlock()
    -- 开服60天
    if ( math.floor(( gTime - _G.gSysStatus.start) / 86400) > 60 ) then
        return true
    end
    -- 四个堡垒被占领
    local num = 0
    if npc_city.citys then
        for k, v in pairs(npc_city.citys) do
            local npcCity = get_ety(v) 
            if npcCity.lv == 1 and npcCity.uid ~= npcCity.propid then
                num = num + 1
            end
        end
        if num == 4 then
            return true
        end
    end

    return true
end

function try_unlock_kw()
    if state ~= KW_STATE.LOCK then
        return
    end

    if is_kw_unlock() == true then
        unlock_kw()
    end
end

function set_citys_state(state)
    for k, v  in pairs(citys) do
        local city = get_ety(v)
        if city then
            city.state = state
            etypipe.add(city)
            try_set_tower_range(city)
        end
    end
end

function set_kw_state(newState)
    local kingCity = get_king()
    kingCity.state = newState
    set_citys_state(newState)

    state = newState
    gPendingSave.status["kwState"].state = newState
end

function set_kw_timer(newTimerId)
    timer.del(timerId)

    timerId = newTimerId
    gPendingSave.status["kwState"].timer = newTimerId
end

function unlock_kw()
    for k, v in pairs(citys) do
    end
    set_kw_state(KW_STATE.UNLOCK)
    do_timer()
end

function prepare_kw()
    set_kw_state(KW_STATE.PREPARE)
    do_timer()
end

function fight_kw()
    clear_officer()
    season = season + 1
    gPendingSave.status["kwState"].season = season
    officers = {}
    gPendingSave.status["kwState"].officers = officers
    fight_again()
end

function fight_again()
    set_kw_state(KW_STATE.FIGHT)
    do_timer()
end

function pace_kw()
    clear_citys_timer()

    timer.new("select_default_king", 3600)

    set_kw_state(KW_STATE.PACE)
    do_timer()
end

function clear_citys_timer()
    for k, v in pairs(citys) do 
        local city = get_ety(k)
        if city then
            clear_timer(city)
        end
    end
end

function do_timer()
    local time = resmng.prop_kw_stage[state].Spantime * 60
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
            for _,v in pairs(conf.Arms) do
                arm[v[1]] = v[2]
            end
            tr = troop_mng.create_troop(TroopAction.Npc, city, kingCity, arm)
        end
    end

    if tr then return tr end
end

function get_king()
    for k, v in pairs(citys) do 
        local city = get_ety(v)

        if city then
            if resmng.prop_world_unit[city.propid].Lv ==  CITY_TYPE.KING_CITY then
                return city
            end
        end
    end
end

function fire(troop, force)

end

function fire_win(kingCity, atkCity)
    kingCity.uid = atkCity.uid
    local union = unionmng.get_union(atkCity.uid)
    if union then
        atkCity.uname = union.alias
    end
    atkCity.my_troop_id = nil
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
            local force = get_force_prop(city, "troop", "force") or 0
            local troop = kingCity:get_my_troop()
            --local troop = troop_mng.get_troop(kingCity.my_troop_id)
            if troop then
                troop:apply_dmg(force)
                if not troop:has_alive() then
                    fire_win(kingCity, city)
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
    local prop = resmng.prop_world_unit[city.propid]
    if prop then
        if prop.Fire_force[ATK_TYPE[Type]][FORCE_ATTR[attr]] then
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
        time = (get_force_prop(city, Type, "cd") * 10) or 60
    end
    local timerId = timer.new("king_city", time, city.eid, Type, troopId)
    if troopId then
        city.timers[troopId] = timerId
    else
        city.timers[Type] = timerId
        city.startTime = gTime
        city.endTime = gTime + time
    end

    if Type == "towerDown" then
        city.startTime = gTime
        city.endTime = gTime + time
    end
    etypipe.add(city)
    try_set_tower_range(city)
end
--- 要塞对王城射箭
function try_fire_king(city)
    print("city atk fire city ", city.propid)
    local kingCity = get_king()

    if can_atk_king(city) then
        local prop = resmng.prop_world_unit[city.propid]
        if prop then
            local force = get_force_prop(city, "troop", "fire") or 0
            --local troop = troop_mng.get_troop(city.my_troop_id)
            local troop = kingCity:get_my_troop()
            if troop then
                troop:apply_dmg(force)
                if not troop:has_alive() then
                    fire_win(kingCity, city)
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

    for k, v in pairs(citys) do 
        local city = get_ety(v)
        if resmng.prop_world_unit[city.propid].Lv == 1 and city.uid ~= kingCity.uid then
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
                tr = troop_mng.create_troop(TroopAction.SiegeNpc, self, self,{live_soldier = {[3002] = 0}, heros = {0,0,0,0}})
            else
                local arm = {}
                if conf.Arms  then
                    for _, v in pairs(conf.Arms) do
                        arm[ v[1] ] = v[2]
                    end
                end
                tr = troop_mng.create_troop(TroopAction.SiegeNpc, self, self, arm)
                if conf.Arms then
                    local arm = {}
                    for _, v in pairs(conf.Arms) do
                        arm[ v[1] ] = v[ 2 ]
                    end
                    tr:add_arm(0, {live_soldier = arm,heros = {0,0,0,0}})
                end
            end
        end
        tr.owner_uid = 0
        self.my_troop_id = tr._id
    else
        tr = troop_mng.create_troop(TroopAction.SiegeNpc, self, self,{live_soldier = {[3002] = 0}, heros = {0,0,0,0}})
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
            end
        end
        if lv == CITY_TYPE.TOWER then
            if city.eid ~= defenseTroop.owner_eid then
                defenseTroop:back()
            end
            atkTroop:back()
        end
        if lv == CITY_TYPE.KING_CITY then
            if defenseTroop.owner_eid ~= defenseTroop.target_eid then
                defenseTroop:back()
            end
        end
    else
        atkTroop:back()
    end
end

function deal_other_city(kingCity)
    for k, v in pairs(citys) do
        local city = get_ety(k)
        if resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.TOWER then
            city.uid = kingCity.uid 
            local troop = city:get_my_troop()
            if troop.owner_eid ~= city.eid then
                troop:back()
                --troop_back(troop)
            end
        elseif resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.FORT then
            city.occuTime = gTime
            try_atk_king(city)
            try_fire_king(city)
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
                local troop = troop_mng.create_troop(TroopAction.Npc, ply, target, arm)
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
        after_atk_win[lv](atkTroop)
    end
end

after_atk_win[CITY_TYPE.FORT] = function(atkTroop)
    local city = get_ety(atkTroop.target_eid)
    local kingCity = get_king()

    city.uid = atkTroop.owner_uid
    local union = unionmng.get_union(city.uid)
    if union then
        city.uname = union.alias
    end
    city.my_troop_id = atkTroop._id
    clear_timer(city)
    atkTroop.action = TroopAction.HoldDefense
    atkTroop:settle()

    deal_new_defender[CITY_TYPE.FORT](city, kingCity)
    etypipe.add(city)
end

after_atk_win[CITY_TYPE.TOWER] = function(atkTroop)
    local city = get_ety(atkTroop.target_eid)
    city.status = 0
    clear_timer(city)
    set_timer(city, "towerDown")
    etypipe.add(city)
    try_set_tower_range(city)
end

after_atk_win[CITY_TYPE.KING_CITY] = function(atkTroop)
    local city = get_ety(atkTroop.target_eid)

    city.uid = atkTroop.owner_uid
    local union = unionmng.get_union(city.uid)
    if union then
        city.uname = union.alias
    end
    city.my_troop_id = atkTroop._id
    clear_timer(city)

    atkTroop.action = TroopAction.HoldDefense
    atkTroop:settle()

    deal_new_defender[CITY_TYPE.KING_CITY](city)
    etypipe.add(city)
end

function check_atk_win(atkTroop)
    return (atkTroop.win or 0) == 1
end

function clear_timer(city)
    for k, v in pairs(city.timers) do
        timer.del(v)
    end
end

deal_new_defender[CITY_TYPE.FORT] = function(city, kingCity)
    city.occuTime = gTime
    try_atk_king(city)
    try_fire_king(city)
end

--[[deal_new_defender[CITY_TYPE.TOWER] = function(city)
    try_atk_king(city)
    try_fire_king(city)
end--]]

deal_new_defender[CITY_TYPE.KING_CITY] = function(city)
    deal_other_city(city)
    fight_again()
end

function reset_tower(city)
    print("reset_tower ", city.propid)
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
    for k, v in pairs(citys) do
        local city = get_ety(v) 
        if city then
            if (get_city_type(city) or 0) == CITY_TYPE.TOWER then
                --c_add_scan(city.eid, 5)
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
        pack.dmg = 999
    elseif lv == CITY_TYPE.TOWER then
        pack.defender = city.uid
        pack.dmg = 999
    elseif lv == CITY_TYPE.KING_CITY then
        pack.defender = city.uid
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


function select_king(union, pid)
    local ply = getPlayer(pid)
    if ply and union:has_member(ply) then
        local king = {season, pid, union.uid, 0, gTime}
        -- 国王加入到
        kings[season] = king
        --table.insert(kings,  king)
        gPendingSave.status["kwState"].kings = kings
        ply.officer = KING   -- 任命国王
        officers[KING] = pid
        gPendingSave.status["kwState"].officers = officers
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
        officers[index] = pid
        gPendingSave.status["kwState"].officers = officers
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
    kings[season][4] = kings[season][4] + score
    gPendingSave.status["kwState"].kings = kings
end

function clear_officer()
    local king = kings[season]
    
    if king then
        local ply = getPlayer(king[2])
        if ply then
            ply.officer = 0
        end
    end
    for k, v in pairs(officers) do 
        local ply = getPlayer(v)
        if ply then
            ply.officer = 0
        end
    end

    officers = {}
    gPendingSave.status["kwState"].officers = officers
end

