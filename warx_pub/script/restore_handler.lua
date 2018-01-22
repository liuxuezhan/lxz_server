module("restore_handler", package.seeall)
function load_player()
    local db = dbmng:getOne()
    local info = db.player:find({})
    local count = 0
    local total = 0
    while info:hasNext() do
        local data = info:next()
        if (data.tm_login or 0) > (data.tm_logout or 0) then data.tm_logout = gTime - 1 end
        if (not data.culture) or data.culture < 1 or data.culture > 4 then data.culture = 1 end

        if  data.pid and data.account then
            if data.emap == gMapID then
                local acc = gAccounts[ data.account ]
                if not acc then
                    acc = {}
                    gAccounts[ data.account ] = acc
                end
                acc[ data.pid ] = { data.map, data.smap or gMapID }
            end

            if data.eid ~= 0 then 
                local token = data.token
                data.token = nil

                local p = player_t.wrap( data )
                gPlys[ data.pid ] = p

                rawset(p, "eid", data.eid)
                rawset(p, "pid", data.pid)
                rawset(p, "size", 4)

                rawset(p, "token", token )
                rawset(p, "uname", "")

                if p.eid ~= 0 then gEtys[ p.eid ] = p end

                count = count + 1
                if count >= 100 then
                    total = total + 100
                    LOG("load player %d", total)
                    count = 0
                end
            end
        end
    end
    total = total + count
    player_t.gTotalCreate = total
end


function load_build(pid)
    local db = dbmng:getOne()
    local info 
    if pid then
        info = db.build_t:find({pid=pid})
    else
        info = db.build_t:find({})
    end
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
            LOG( "[LOAD], building %s have not player %s", b._id, b.pid ) 
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
        local pid = tr.owner_pid or 0
        for _, arm in pairs( tr.arms or {} ) do
            local valid = true
            for id, num in pairs( arm.live_soldier or {} ) do
                if num < 1 then 
                    valid = false
                    break 
                end
            end
            if not valid then
                local live = {}
                for id, num in pairs( arm.live_soldier or {} ) do
                    if num >= 1 then 
                        live[ id ] = num
                    end
                end
                arm.live_soldier = live
            end
        end

        if not tr.arms then tr.arms = {} end
        if not tr.arms[ pid ] then tr.arms[ pid ] = { live_soldier={} } end
        if tr._id > maxSn then maxSn = tr._id end

        if pid >= 10000 and not getPlayer( pid ) then

        else
            troop_t.wrap( tr )
            datas[ tr._id ] = tr
        end
    end
    _G.gSns[ "troop" ] = maxSn + 1
    troop_mng.troop_id_map = datas
end


function load_equip()
    for _, v in pairs( gPlys ) do v._equip = {} end

    local db = dbmng:getOne()
    db.equip:delete({pos=-1})

    local info = db.equip:find({})
    while info:hasNext() do
        local t = info:next()
        local ply = getPlayer( t.pid )
        if ply then
            ply._equip[ t._id ] = t
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

function load_clown()
    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.CLOWN then
            local eid = get_eid_npc_city()
            if eid then
                local c = {_id=eid, eid=eid, x=v.X, y=v.Y, propid=k, size=v.Size, uid=0}
                gEtys[ eid ] = c
                etypipe.add(c)
            end
        end
    end
end

function load_hero(pid)
    local db = dbmng:getOne()
    local info 
    if pid then 
        info = db.hero_t:find({pid=pid})
    else
        info = db.hero_t:find({})
    end
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
    local info = db.status:findOne({_id=gMapID})
    dumpTab(info, "SysStatus")
    if not info then
        info = {_id=gMapID, start=gTime, ids={}}
        db.status:insert(info)
    end
    _G.gSysStatus = info
end

function load_white_list_status()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id= "white_list"})
    dumpTab(info, "white_list")
    if not info then
        info = {_id="white_list"}
        db.status:insert(info)
    end
    _G.white_list = info
end

function init_effect()
    local count = 0
    for pid, v in pairs(gPlys) do
        local propid = v.culture * 1000 + v:get_castle_lv()
        if v.propid ~= propid then v.propid = propid end
        v.nprison = v:get_prison_count()
        v:initEffect(true)

        if v.uid > 0 then
            local u = unionmng.get_union( v.uid )
            if u then 
                v.uname = u.alias
                v.uflag = u.flag
            end
        end
        if v.eid ~= 0 then etypipe.add(v) end
        count = count + 1
        if count % 100 == 0 then INFO( "init_effect, count = %d", count ) end
    end

    local us = unionmng.get_all()
    for _, v in pairs( us ) do v:union_pow() end

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

function load_count()
    for _, v in pairs( gPlys ) do v._count = {} end
    local db = dbmng:getOne()
    local info = db.count:find({})
    while info:hasNext() do
        local line = info:next()
        local player = getPlayer(line._id)
        if player ~= nil then
            line._id = nil
            player._count = line
        end
    end
end

function load_chat()
    local db = dbmng:getOne()
    local chats = {}
    local info = db.status:findOne({_id="chat"})
    if info then
        for k, v in pairs( info ) do
            if type( k ) == "number" then
                chats[ k ] = v
                local uid = math.floor( k / 10 )
                if uid >= 10000 then
                    if not unionmng.get_union(uid) then
                        chats[ k ] = nil
                    end
                end
            end
        end
    end

    for k, v in pairs( chats ) do
        if v.sn >= 2147483647 then
            local idx = 0
            for _, n in pairs( v.list ) do
                idx = idx + 1
                n[1] = idx
            end
            v.sn = idx
        end
    end

    player_t.gChat = chats
end


function load_first_kill()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id="first_kill"})
    if info then
        troop_mng.g_first_kill = info
    end
end

function restore_timer()
    local db = dbmng:getOne()
    db.timer:delete({delete=true})

    local info = db.timer:find({})
    local maxSn = 0

    local tm_shutdown = gSysStatus.tick or gTime
    WARN( "tm_shutdown, %d, %d, %s", tm_shutdown, gTime - tm_shutdown, os.date( "%c", tm_shutdown ) )

    _G.gTime = tm_shutdown
    _G.gMsec = 0
    _G.gCompensation = tm_shutdown
    c_time_set_start(tm_shutdown)

    while info:hasNext() do
        local t = info:next()
        if t.over < tm_shutdown - 10 then
            WARN( "timer error, id = %d, over=%d, now=%d", t._id, t.over, tm_shutdown )
        else
            local sn = t._id
            timer._sns[ sn ] = t
            addTimer(t._id, (t.over-tm_shutdown)*1000, t.tag or 0)
            timer_ex.mark_only(t)
            if sn > maxSn then maxSn = sn end
        end
    end
    _G.gSns[ "timer" ] = maxSn + 1

    --local next_cron = gSysStatus.cron or tm_shutdown
    --next_cron = next_cron - ( next_cron % 60 ) + 90
    --timer.new( "cron", next_cron - tm_shutdown )

    local next_cron = ( gSysStatus.cron or tm_shutdown ) + 90
    next_cron = next_cron - ( next_cron % 60 )
    timer.new( "cron", next_cron - tm_shutdown )

    for eid, ety in pairs( gEtys or {} ) do
        if not is_troop( ety ) then
            ety.troop_comings = nil
        end
    end
    troop_mng.check_troop( tm_shutdown )

    for _, h in pairs( heromng._heros or {} ) do
        if h.status == HERO_STATUS_TYPE.MOVING then
            if h.troop and troop_mng.get_troop( h.troop ) then

            else
                h.status = HERO_STATUS_TYPE.FREE
            end
        end
    end

   return "Compensation"
end



function post_init()
    c_roi_view_start()

    INFO("-- init_rank ---------")
    rank_mng.init()
    INFO("-- init_rank done  ---")

    INFO("-- custom_rank_mng -----------")
    custom_rank_mng.init()
    INFO("-- custom_rank_mng done -----------")

    INFO("-- accpet world events ---------")
    world_event.init_world_event()
    INFO("-- accpet world events done  ---")

    INFO("-- init weekly activity ---------")
    weekly_activity.init_weekly_activity()
    INFO("-- init weekly activity done  ---")

    INFO("-- init operate activity ---------")
    operate_activity.init_operate_activity()
    INFO("-- init operate activity done  ---")
    
    INFO("-- init daily task filter ---------")
    daily_task_filter.init_filter()
    INFO("-- init odaily task filter done  ---")

    --[[
    INFO("-- init daily activity ---------")
    daily_activity.init_daily_activity()
    INFO("-- init daily activity done  ---")
    --]]
    INFO("-- init daily activity manager ---------")
    periodic_activity_manager.init_data()
    INFO("-- init daily activity manager done  ---")
end

function action()

    local index_info = {
        build_t = { build_pid_idx = { pid=1}, },
        equip = { equip_pid_idx = { pid=1}, },
        hero_t = { equip_pid_idx = { pid=1}, },
        mail = { mail_to_idx = { to=1}, },
        task = { task_pid_idx = { pid=1}, },
        onlines = { onlines_pid_idx = { pid=1, day=1}, },
        operate_activity = { operate_activity_pid_idx = { pid=1 } },
        yueka = { yueka_pid_idx = { pid=1 } },
    }
    --dbmng:index_update( index_info, false )

    --monitoring(MONITOR_TYPE.LOADDATA, "before load data")
    INFO("-- load_sys_status ---------")
    load_sys_status()
    INFO("-- load_sys_status done-----")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_sys_status")

    INFO("-- load_wander -------------")
    wander.load()
    INFO("-- load_wander done --------")

    INFO("-- load_player -------------")
    load_player()
    player_t.change_operate_activity()--转档
    player_t.change_pay_state()--转档
    INFO("-- load_player done --------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_player")
    --

    INFO("-- load_world_event -------------")
    world_event.load_world_event()
    INFO("-- load_world_event done --------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_world_event")

    INFO("-- load_weekly_activity -------------")
    weekly_activity.load_weekly_activity()
    INFO("-- load_weekly_activity done --------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_weekly_activity")

    INFO("-- load_operate_activity -------------")
    operate_activity.load_operate_activity()
    INFO("-- load_operate_activity done --------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_operate_activity")

    --[[
    INFO("-- load_daily_activity -------------")
    daily_activity.load_daily_activity()
    INFO("-- load_daily_activity done --------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_daily_activity")
    --]]
    INFO("-- load_periodic_activity_manager -------------")
    periodic_activity_manager.load_data()
    INFO("-- load_periodic_activity_manager done --------")


    INFO("-- load_union --------------")
    union_t.load()
    union2_t.load()
    INFO("-- load_union done ---------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_union")


    INFO("-- load_union_member -------")
    union_member_t.load()
    INFO("-- load_union_member done --")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_union_member")

    INFO("-- unoin_buildlv -----") -- union_t后 在load_troop 前
    union_buildlv.load()--
    INFO("-- unoin_buildlv done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_buildlv")

    INFO("-- load_union_build --------")
    union_build_t.load()
    INFO("-- load_union_build done ---")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_union_build")

    INFO("-- load_union_tech ---------")
    union_tech_t.load()
    INFO("-- load_union_tech done ----")
    INFO("-- load_union_hero_task ---------")
    union_hero_task.load()
    INFO("-- load_union_hero_task done ----")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_union_tech")
    --
    
    INFO("-- load_chat -------------")
    load_chat()
    INFO("-- load_chat done --------")
    
    INFO("-- load_build --------------")
    load_build()
    INFO("-- load_build done ---------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_build")

    INFO("-- load_npc_city -----------")
    npc_city.load_npc_city()
    INFO("-- load_npc_city -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_npc_city")

    INFO("-- load_cross_act -----------")
    cross_act.load_data()
    INFO("-- load_cross_act -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_cross_act")
    --
    INFO("-- load_act_mng -----------")
    act_mng.load_act_state()
    INFO("-- load_act_mng -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_act_mng")

    INFO("-- load_refugee -----------")
    refugee.load_from_db()
    INFO("-- load_refugee -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_refugee")

    INFO("-- load_cross_refugee -----------")
    cross_refugee_c.load_data()
    INFO("-- load_cross_refugee -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_refugee")


    INFO("-- load_clown -----------")
    load_clown()
    INFO("-- load_clown -----------")

    INFO("-- load_monster_city -----------")
    monster_city.load_monster_city()
    monster_city.load_mc_state()
    INFO("-- load_monster_city -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_monster_city")

    INFO("-- load_king_city -----------")
    king_city.load_king_city()
    INFO("-- load_king_city -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_king_city")

    INFO("-- load_kw_mall -----------")
    kw_mall.load_from_db()
    INFO("-- load_kw_mall -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_kw_mall")

    load_troop() 

    INFO("-- load_hero ---------------")
    load_hero()
    INFO("-- load_hero done ----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_hero")

    INFO("-- load_monster ------------")
    monster.load_from_db()
    INFO("-- load_monster done--------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_monster")

    INFO("-- restore_load_farm -------")
    farm.load_from_db()
    INFO("-- restore_load_farm done --")
    --monitoring(MONITOR_TYPE.LOADDATA, "restore_load_farm")

    INFO("-- restore_load_unit -------")
    load_unit()
    INFO("-- restore_load_unit done --")
    --monitoring(MONITOR_TYPE.LOADDATA, "restore_load_unit")

    INFO("-- restore_system_mail -----")
    load_sys_mail()
    INFO("-- restore_system_mail done-")
    --monitoring(MONITOR_TYPE.LOADDATA, "restore_system_mail")
    
    INFO("-- load_lost_temple -----------")
    lost_temple.load_lost_temple()
    INFO("-- load_lost_temple -----------")
    --monitoring(MONITOR_TYPE.LOADDATA, "load_lost_temple")


    INFO("-- restore_equip -----")
    load_equip()
    INFO("-- restore_equip done-")
    --monitoring(MONITOR_TYPE.LOADDATA, "restore_equip")

    INFO("-- load_count -----")
    load_count()
    INFO("-- load_count done-")

    --INFO("-- init_effect -------------")
    --local count = init_effect()
    --INFO("-- init_effect done -------- %d", count)
    --monitoring(MONITOR_TYPE.LOADDATA, "init_effect")
    
    INFO("-- restore_room -----")
    load_room() 
    INFO("-- restore_room done-")
    --monitoring(MONITOR_TYPE.LOADDATA, "restore_room")
    
    INFO("-- unoin_mall -----")
    union_mall.load()
    INFO("-- unoin_mall done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_mall")

    INFO("-- unoin_task -----")
    union_task.load()--在ety和union 后加载
    INFO("-- unoin_task done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_task")

    INFO("-- unoin_mission -----")
    union_mission.load()--
    INFO("-- unoin_mission done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_mission")

    INFO("-- unoin_word -----")
    union_word.load()--
    INFO("-- unoin_word done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_word")


    INFO("-- unoin_relation -----")
    union_relation.load()--
    INFO("-- unoin_relation done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_relation")

    INFO("-- unoin_god -----")
    union_god.load()--
    INFO("-- unoin_god done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_god")


    --monitoring(MONITOR_TYPE.LOADDATA, "unoin_god")
    INFO("-- gacha_world_limit -----")
    gacha_limit_t.load_gacha_world_limit()
    INFO("-- gacha_world_limit done -----")
    --monitoring(MONITOR_TYPE.LOADDATA, "gacha_world_limit")

    INFO("-- white list-----")
    load_white_list_status()
    INFO("-- white list done-----")
    --monitoring(MONITOR_TYPE.LOADDATA, "white_list")


    INFO("-- first kill -----")
    load_first_kill()
    INFO("-- first kill done -----")

    INFO("-- pay mall -----")
    pay_mall.load_pay_mall()
    INFO("-- pay mall -----")

    INFO("-- tribute_exchange -----")
    load_tribute_exchange()
    INFO("-- tribute_exchange done -----")

    INFO("-- restore_timer -----------")
    local compensate =  restore_timer()
    INFO("-- restore_timer done ------, %s", compensate or "none")
    --monitoring(MONITOR_TYPE.LOADDATA, "restore_timer")

    INFO("-- cross_mng_c -----------")
    if gCenterID == gMapID then
        cross_mng_c.init()
    end
    INFO("-- cross_mng_c done -----------")

    c_tick(0)
    init_effect()
    local use = c_tick(1)
    WARN( "init_effect, use %d ms", use )

    post_init()

    INFO("-- done done done ----------")

    return compensate
end


function load_unit()
    local db = dbmng:getOne()
    db.unit:delete({delete=true})
    local info = db.unit:find({})
    while info:hasNext() do
        local m = info:next()
        if is_camp( m ) then
            local troop = troop_mng.get_troop( m.my_troop_id )
            if troop and troop.target_eid == m.eid then
                gEtys[ m.eid ] = m
                etypipe.add(m)
            else
                gPendingDelete.unit[ m.eid ] = 1
            end
        else
            gEtys[ m.eid ] = m
            etypipe.add(m)
        end
    end
end


function load_tribute_exchange()
    local db = dbmng:getOne()
    local info = db.tribute_exchange:find({})
    local citys = {}
    while info:hasNext() do
        local m = info:next()
        citys[ m._id ] = m
    end

    if not next( citys ) then
        tribute_exchange.reset_special()
    else
        tribute_exchange.g_exchanges = citys
        tribute_exchange.g_tribute_special = get_sys_status( "tribute_special" )
    end
end

