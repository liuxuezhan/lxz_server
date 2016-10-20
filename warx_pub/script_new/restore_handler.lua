module("restore_handler", package.seeall)

function load_player()

    local db = dbmng:getOne()
    local info = db.player:find({})
    local count = 0
    local total = 0
    while info:hasNext() do
        local data = info:next()
        if data.tm_login > (data.tm_logout or 0) then data.tm_logout = gTime - 1 end
        if (not data.culture) or data.culture < 1 or data.culture > 4 then data.culture = 1 end

        if  data.pid and data.account then
            local token = data.token
            data.token = nil

            local p = player_t.new(data)
            gEtys[ p.eid ] = p
            rawset( p, "token", token )

            rawset(p, "eid", data.eid)
            rawset(p, "size", 4)
            rawset(p, "uname", "")

            if data.uid > 0 then
                local union = unionmng.get_union(data.uid)
                if union then
                    rawset(p, "uname", union.alias)
                end
            end

            count = count + 1
            if count >= 100 then
                total = total + 100
                LOG("load player %d", total)
                count = 0
            end
        end
    end
    total = total + count
end


function load_build()
    local db = dbmng:getOne()
    local info = db.build_t:find({})
    local count = 0
    while info:hasNext() do
        local b = info:next()
        local p = getPlayer(b.pid)
        if p then
            local bs = p._build
            if not bs then
                bs = {}
                p._build = bs
            end
            bs[ b.idx ] = build_t.wrap(b)
            count = count + 1
            if count % 10000 == 0 then
                LOG("load build %d", count)
            end
        else
            print( string.format( "building %s have not player %s", b._id, b.pid ) )
        end
    end
end

function load_troop()
    local db = dbmng:getOne()
    db.troop:delete({delete=true})

    local datas = {}

    local info = db.troop:find({})
    local maxSn = 0
    while info:hasNext() do
        local tr = info:next()
        if tr._id > maxSn then maxSn = tr._id end
        datas[ tr._id ] = tr
    end
    _G.gSns[ "troop" ] = maxSn + 1
    troop_mng.datas = datas
end

function restore_troop()
    local datas = troop_mng.datas
    troop_mng.datas = nil
    for k, v in pairs( datas ) do
        troop_mng.load_data( v )
    end
end

function load_equip()
    for _, v in pairs( gPlys ) do v._equip = {} end

    local db = dbmng:getOne()
    local info = db.equip:find({})
    while info:hasNext() do
        local t = info:next()
        local ply = getPlayer( t.pid )
        if ply then
            ply._equip[ t._id ] = t
        end
    end
end

function load_count()
    for _, v in pairs( gPlys ) do v._count = {} end
    local db = dbmng:getOne()
    local info = db.count:find({})
    while info:hasNext() do
        local t = info:next()
        local ply = getPlayer( t.pid )
        if ply then
            t._id = nil
            ply._count = t
        end
    end
end


function load_room()
    for k, v in pairs(unionmng._us) do v.battle_room_ids = {} end

    local db = dbmng:getOne()
    db.room:delete({delete=true})

    local info = db.room:find({})
    while info:hasNext() do
        union_hall_t.load_data(info:next())
    end
end

function load_npc_city()
    local db = dbmng:getOne()
    local info = db.npc_city:find({})
    local have = {}
    while info:hasNext() do
        local c = info:next()
        local n = resmng.prop_world_unit[ c.propid ]
        if n then
            gEtys[ c.eid ] = c
            etypipe.add(c)
            have[ n.ID ] = c
        end
    end

    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.NPC_CITY then
            if not have[ v.ID ] then
                local eid = get_eid_npc_city()
                if eid then
                    local c = {_id=eid, eid=eid, x=v.X, y=v.Y, propid=k, size=v.Size, uid=0}
                    gEtys[ eid ] = c
                    etypipe.add(c)
                    db.npc_city:insert(c)
                end
            end
        end
    end
end

function load_hero()
    local db = dbmng:getOne()
    local info = db.hero:find({})
    while info:hasNext() do
        local b = info:next()
        local p = getPlayer(b.pid)
        if p then
            if not p._hero then p._hero = {} end
            local hero = hero_t.wrap(b)
            p._hero[ b.idx ] = hero
            heromng.add_hero(hero)
        end
    end
end


function load_sys_status()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id=config.Map})
    if not info then
        info = {_id=gMapID, start=gTime, ids={}}
        db.status:insert(info)
    end
    _G.gSysStatus = info
end

function init_effect()
    local count = 0
    for _, v in pairs(gPlys) do
        local propid = v.culture * 1000 + v:get_castle_lv()
        if v.propid ~= propid then v.propid = propid end
        v.nprison = v:get_prison_count()
        v:initEffect(true)
        etypipe.add(v)
        count = count + 1
    end

    local us = unionmng.get_all()
    for _, v in pairs( us ) do
        v:union_pow()
    end
    return count
end

function load_sys_mail()
    local db = dbmng:getOne()
    local info = db.mail:find({to=0})
    local mails = {}
    local sn = 0
    while info:hasNext() do
        local v = info:next()
        table.insert(mails, v)
        if v.idx > sn then sn = v.idx end
    end
    table.sort(mails,function(l, r) return l.idx < r.idx end)
    _G.gSysMailSn = sn
    _G.gSysMail = mails
end

--任务
function load_task()
    local db = dbmng:getOne()
    local info = db.task:find({})
    while info:hasNext() do
        local line = info:next()
        local player = getPlayer(line._id)
        if player ~= nil then
            --player:init_task()
            player:init_from_db(line)
        end
    end
end

function restore_timer()
    local db = dbmng:getOne()
    db.timer:delete({delete=true})

    local info = db.timer:find({})
    local minTime = math.huge
    local maxSn = 0
    local isCron = false

    local real = os.time()
    while info:hasNext() do
        local t = info:next()
        timer._sns[ t._id ] = t
        if t._id > maxSn then maxSn = t._id end
        if t.over < minTime then
            minTime = t.over
        end
        if t.what == "cron" then
            if not isCron then 
                isCron = true
            else
                timer._sns[ t._id ] = nil -- duplicate crontab
            end
        end
    end
    _G.gSns[ "timer" ] = maxSn + 1

    local dels = {}
    local retroop = {}
    for k, v in pairs(troop_mng.troop_id_map) do
        if v:is_go() or v:is_back() then
            if not v.tmCur then 
                table.insert(dels, {k, v})
            else
                if v.tmCur > real - 36000 then
                    if v.tmCur < minTime then
                        print(string.format("SetTimerStart, min=%d, troop, troopid=%s", v.tmCur, v._id))
                        minTime = v.tmCur
                    end
                    table.insert(retroop, v)
                else
                    table.insert(dels, {k, v})
                    WARN("restore_troop, id=%d, action=%d, offset=%f hour", v._id, v.action, (real-v.tmCur)/3600)
                end
            end
        end
    end

    for _, t in  pairs(dels) do
        local k = t[1]
        local troop = t[2]
        troop_mng.delete_troop(k)
        for pid, _ in pairs(troop.arms or {}) do
            if pid > 0 then
                local p = getPlayer(pid)
                if p then
                    remove_id(p.busy_troop_ids, k)
                end
            end
        end
    end

    if minTime < real then
        _G.gTime = minTime
        _G.gMsec = 0
        _G.gCompensation = minTime
        c_time_set_start(minTime)
        WARN("gCompensation, from=%d, to=%d", minTime, real)


        for k, node in pairs(timer._sns) do
            addTimer(node._id, (node.over-minTime)*1000, node.tag or 0)
        end


        for _, v in pairs(retroop) do
            local speed = v.speed
            local black = is_in_black_land( v.curx or v.sx, v.cury or v.sy )
            if black then v.speed = v.speed * 0.1 end
            etypipe.add(v)
            c_add_actor(v.eid, v.curx or v.sx, v.cury or v.sy, v.dx, v.dy, v.tmCur, v.speed)
            gEtys[ v.eid ] = v
            v.speed = speed
        end

        return "Compensation"
    else
        for k, node in pairs(timer._sns) do
            addTimer(node._id, (node.over-real)*1000, node.tag or 0)
        end
    end
end

function post_init()
    c_roi_view_start()

    INFO("-- init_rank ---------")
    rank_mng.init()
    INFO("-- init_rank done  ---")
end

function action()
    monitoring(MONITOR_TYPE.LOADDATA, "before load data")
    INFO("-- load_sys_status ---------")
    load_sys_status()
    INFO("-- load_sys_status done-----")
    monitoring(MONITOR_TYPE.LOADDATA, "load_sys_status")

    load_troop()
    monitoring(MONITOR_TYPE.LOADDATA, "load_troop")

    INFO("-- load_union --------------")
    union_t.load()
    INFO("-- load_union done ---------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_union")

    INFO("-- load_player -------------")
    load_player()
    INFO("-- load_player done --------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_player")

    INFO("-- load_build --------------")
    load_build()
    INFO("-- load_build done ---------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_build")

    INFO("-- load_union_member -------")
    union_member_t.load()
    INFO("-- load_union_member done --")
    monitoring(MONITOR_TYPE.LOADDATA, "load_union_member")

    INFO("-- load_union_tech ---------")
    union_tech_t.load()
    INFO("-- load_union_tech done ----")
    monitoring(MONITOR_TYPE.LOADDATA, "load_union_tech")

    INFO("-- load_npc_city -----------")
    npc_city.load_npc_city()
    INFO("-- load_npc_city -----------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_npc_city")

    INFO("-- load_monster_city -----------")
    monster_city.load_monster_city()
    INFO("-- load_monster_city -----------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_monster_city")


    INFO("-- load_king_city -----------")
    king_city.load_king_city()
    INFO("-- load_king_city -----------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_king_city")

    INFO("-- load_kw_mall -----------")
    kw_mall.load_from_db()
    INFO("-- load_kw_mall -----------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_kw_mall")

    -- should load after troop
    --INFO("-- load_lost_temple -----------")
    --lost_temple.load_lost_temple()
    --INFO("-- load_lost_temple -----------")

    INFO("-- load_union_build --------")
    union_build_t.load()
    INFO("-- load_union_build done ---")
    monitoring(MONITOR_TYPE.LOADDATA, "load_union_build")

    INFO("-- load_hero ---------------")
    load_hero()
    INFO("-- load_hero done ----------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_hero")

    INFO("-- load_monster ------------")
    monster.load_from_db()
    INFO("-- load_monster done--------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_monster")

    INFO("-- restore_load_farm -------")
    farm.load_from_db()
    INFO("-- restore_load_farm done --")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_load_farm")

    INFO("-- restore_load_unit -------")
    load_unit()
    INFO("-- restore_load_unit done --")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_load_unit")

    INFO("-- restore_system_mail -----")
    load_sys_mail()
    INFO("-- restore_system_mail done-")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_system_mail")

    INFO("-- restore_troop -----")
    restore_troop()
    INFO("-- restore_troop done-")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_troop")

    INFO("-- load_lost_temple -----------")
    lost_temple.load_lost_temple()
    INFO("-- load_lost_temple -----------")
    monitoring(MONITOR_TYPE.LOADDATA, "load_lost_temple")


    INFO("-- restore_equip -----")
    load_equip()
    INFO("-- restore_equip done-")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_equip")

    --INFO("-- init_effect -------------")
    --local count = init_effect()
    --INFO("-- init_effect done -------- %d", count)
    --monitoring(MONITOR_TYPE.LOADDATA, "init_effect")
    
    INFO("-- restore_room -----")
    load_room() 
    INFO("-- restore_room done-")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_room")
    
    INFO("-- restore_task -----")
    load_task()
    INFO("-- restore_task done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_task")

    INFO("-- unoin_mall -----")
    union_mall.load()
    INFO("-- unoin_mall done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_mall")

    INFO("-- unoin_task -----")
    union_task.load()--在ety和union 后加载
    INFO("-- unoin_task done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_task")

    INFO("-- unoin_mission -----")
    union_mission.load()--
    INFO("-- unoin_mission done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_mission")

    INFO("-- unoin_word -----")
    union_word.load()--
    INFO("-- unoin_word done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_word")

    INFO("-- unoin_buildlv -----")
    union_buildlv.load()--
    INFO("-- unoin_buildlv done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_buildlv")

    INFO("-- unoin_relation -----")
    union_relation.load()--
    INFO("-- unoin_relation done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_relation")

    INFO("-- unoin_help -----")
    union_help.load()--
    INFO("-- unoin_help done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_help")

    INFO("-- unoin_god -----")
    union_god.load()--
    INFO("-- unoin_god done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "unoin_god")

    INFO("-- unoin_item -----")
    union_item.load()--
    INFO("-- unoin_item done -----")

    monitoring(MONITOR_TYPE.LOADDATA, "unoin_god")
    INFO("-- gacha_world_limit -----")
    gacha_limit_t.load_gacha_world_limit()
    INFO("-- gacha_world_limit done -----")
    monitoring(MONITOR_TYPE.LOADDATA, "gacha_world_limit")

    post_init()
    INFO("-- done done done ----------")

    INFO("-- restore_timer -----------")
    local compensate =  restore_timer()
    INFO("-- restore_timer done ------")
    monitoring(MONITOR_TYPE.LOADDATA, "restore_timer")

    init_effect()

    return compensate
end


function load_unit()
    local db = dbmng:getOne()
    db.unit:delete({delete=true})
    local info = db.unit:find({})
    while info:hasNext() do
        local m = info:next()
        gEtys[ m.eid ] = m
        etypipe.add(m)
    end
end

