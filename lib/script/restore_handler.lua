module("restore_handler", package.seeall)

function load_player()
    local db = dbmng:getOne()
    local info = db.player:find({})
    local count = 0
    local total = 0
    while info:hasNext() do
        local data = info:next()

        local cures = {}
        for k, v in pairs(data.cures or {} ) do
            cures[ tonumber(k) ] = v
        end
        data.cures = cures

        local hurts = {}
        for k, v in pairs(data.hurts) do
            hurts[ tonumber(k) ] = v
        end
        data.hurts = hurts

        local p = player_t.new(data)
        rawset(p, "eid", data.eid)
        rawset(p, "propid", resmng.PLY_CITY_WEST_1)
        rawset(p, "size", 4)
        rawset(p, "uname", "")

        if data.uid > 0 then
            local union = unionmng.get_union(data.uid)
            if union then
                rawset(p, "uname", union.alias)
            end
        end
        etypipe.add(p)

        gEtys[ p.eid ] = p
        mark_eid(p.eid)
        count = count + 1
        if count >= 100 then
            total = total + 100
            LOG("load player %d", total)
            print(string.format("load player %d", total))
            --mem_info()
            count = 0
        end
    end
    total = total + count
    print("load_player done")
    --INFO("total player %d", total)
end


function load_build()
    local db = dbmng:getOne()
    local info = db.build:find({})
    while info:hasNext() do
        local b = info:next()
        local p = getPlayer(b.pid)
        if p then
            local bs = p._build
            if not bs then
                bs = {}
                p._build = bs
            end
            bs[ b.idx ] = build_t.new(b)
        end
    end
end

function load_troop()
    local db = dbmng:getOne()
    db.troop:delete({delete=true})

    local info = db.troop:find({})
    local maxSn = 0
    while info:hasNext() do
        local tr = info:next()
        if tr._id > maxSn then maxSn = tr._id end
        troop_mng.load_data(tr)
    end
    _G.gSns[ "troop" ] = maxSn + 1
end

function load_equip()
    local db = dbmng:getOne()
    local info = db.troop:find({})

    for _, v in pairs( gPlys ) do v._equip = {} end

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

function load_troop2()
    local db = dbmng:getOne()
    local info = db.troop:find({})
    while info:hasNext() do
        local b = troop_mng.new()
        b:load_data(info:next())
        --if b.status == TroopStatus.Moving then
            --b.curx, b.cury, b.speed, b.tmCur
            --troop_mng.troop_id_map
        --end
    end
end

function troop_t.mark(T)
    --gPendingSave.troop[ T._id ] = T
    gPendingSave.troop[ T._id ].tmCur = gTime
    gPendingSave.troop[ T._id ].arms = {} 

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
            mark_eid(c.eid)
            etypipe.add(c)
            have[ n.ID ] = c

            print("npc_city, eid, x, y =", c.eid, c.x, c.y)
        end
    end

    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.NPC_CITY then
            if not have[ v.ID ] then
                --if c_map_test_pos(v.X, v.Y, v.Size) == 0 then
                    local eid = get_eid_npc_city()
                    if eid then
                        local c = {_id=eid, eid=eid, x=v.X, y=v.Y, propid=k, size=v.Size, uid=0}
                        print("npc_city, eid, x, y =", c.eid, c.x, c.y)
                        gEtys[ eid ] = c

                        mark_eid(eid)
                        etypipe.add(c)
                        db.npc_city:insert(c)
                    end
                --else
                --    print("npc_city, propid= x, y =", v.ID, v.X, v.Y)
                --end
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
            if not p._hero then
                p._hero = {}
            end
            local hero = hero_t.wrap(b)
            p._hero[ b.idx ] = hero
            heromng.add_hero(hero)
        end
    end
end

function load_union()
    local db = dbmng:getOne()
    local info = db.union:find({})
    while info:hasNext() do
        local union = union_t.new(info:next())
        unionmng._us[union.uid] = union
        if union.new_union_sn and union.new_union_sn > new_union._id   then
            new_union._id =  union.new_union_sn 
        end
    end

    info = db.union_log:find({})
    while info:hasNext() do
        local lg = union_t.new(info:next())
        if unionmng._us[lg._id] then
            unionmng._us[lg._id].log = lg
            local csn = 0
            for _, v in pairs(lg.log) do
                if csn < v.sn then
                    csn = v.sn
                end
            end
            unionmng._us[lg._id].log_csn = csn
        end
    end
end



function load_union_build()
    local db = dbmng:getOne()
    local info = db.union_build:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data.uid)
        if u  and data.state ~= BUILD_STATE.DESTROY then
            u.build[data.idx] = data
            gEtys[ data.eid ] = data 
            data.name = ""

            print("union_build,", data.eid)
            mark_eid(data.eid)
            etypipe.add(data)
            union_build_t.set_sn(data.sn)
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

function init_effect()
    for _, v in pairs(gPlys) do
        v:initEffect()
    end
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

function restore_timer2()
    local db = dbmng:getOne()
    db.timer:delete({delete=true})

    local info = db.timer:find({})
    local minTime = math.huge
    local maxSn = 0
    local isCron = false

    local real = os.time()
    while info:hasNext() do
        local t = info:next()
        if t.over > real - 36000 then 
            timer._sns[ t._id ] = t
            if t._id > maxSn then maxSn = t._id end
            if t.over < minTime then
                print(string.format("SetTimerStart, min=%d, timer, what=%s", t.over, t.what))
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
    end
    _G.gSns[ "timer" ] = maxSn + 1
    dumpTab(gSns, "gSns")

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
           -- print(string.format("add_actor, troop, troopid=%s, speed=%f, eid=%d, action=%d, status=%d", v._id, v.speed, v.eid, v.action, v.status))
            etypipe.add(v)
            c_add_actor(v.eid, v.curx, v.cury, v.dx, v.dy, v.tmCur, v.speed)
            gEtys[ v.eid ] = v
        end

        return "Compensation"
    else
        for k, node in pairs(timer._sns) do
            --addTimer(node._id, (node.over-real)*1000, node.tag or 0)
        end
    end
end

function restore_timer()
    local ghostNewTimer = timer.newTimer
    timer.newTimer = function() end

    local db = dbmng:getOne()
    local info = db.timer:find({})

    while info:hasNext() do
        local t = info:next()
        timer._sns[ t._id ] = t
    end

    local funMin = function()
        local min = math.huge
        local k = false
        for sn, v in pairs(timer._sns) do
            if v.over < min then
                k = sn
                min = v.over
            end
        end
        return k
    end

    _G.gTime = 0
    _G.gMsec = 0
    local start = 0

    while true do
        local id = funMin()
        if not id then break end
        local node = timer.get(id)

        print(string.format("over:%d, real:%d, action=%s", node.over, real_gTime, node.what))

        if node.over > real_gTime then break end

        if _G.gTime == 0 then
            _G.gTime = node.over
            start = node.over
        end

        _G.gTime = node.over
        _G.gMsec = (node.over - start) * 1000

        timer.callback(node._id, node.tag)
    end

    timer.newTimer = ghostNewTimer
    _G.gTime = real_gTime
    _G.gMsec = real_gMsec

    for k, node in pairs(timer._sns) do
        if node.what == "cron" then
            timer.del(node._id)
        else
            addTimer(node._id, (node.over-gTime)*1000, node.tag or 0)
        end
    end
end

function renewTimer()
    for _, p in pairs(gPlys) do
        local bs = p._build
        if bs then
            for _, b in pairs(bs) do
                if b.tmOver and b.tmOver > 0 then
                    b.tmSn = timer.new("build", b.tmOver - _G.gTime, p.pid, b.idx)
                else
                    if b.tmSn ~= 0 then b.tmSn = 0 end
                end
            end
        end

        local ts = p:get_troop()
        if ts then
            for _, t in pairs(ts) do
                if t.tmOver and t.tmOver > 0 then
                    t.tmSn = timer.new("troop", t.tmOver - _G.gTime, t.pid, t.idx)
                end
            end
        end
    end

    for _, union in pairs(unionmng.get_all()) do
        for _, t in pairs(union.mass or {}) do
            if t.tmOver and t.tmOver > 0 then
                t.tmSn = timer.new("mass", t.tmOver - _G.gTime, union.uid, t.idx)
            end
        end

        for _, t in pairs(union._tech) do
            if t.tmOver and t.tmOver > 0 then
                t.tmSn = timer.new("uniontech", t.tmOver - _G.gTime, union.uid, t.idx)
            end
        end

        for _, t in pairs(union.build) do
            if t.tmOver and t.tmOver > 0 then
                t.tmSn = timer.new("unionbuild", t.tmOver - _G.gTime, t._id)
            end
        end
    end
end

function post_init()
    --c_roi_view_start()
end

function action()
    INFO("-- load_sys_status ---------")
    load_sys_status()
    INFO("-- load_sys_status done-----")

    INFO("-- load_union --------------")
    load_union()
    INFO("-- load_union done ---------")

    INFO("-- load_player -------------")
    load_player()
    INFO("-- load_player done --------")

    INFO("-- load_build --------------")
    load_build()
    INFO("-- load_build done ---------")

    INFO("-- load_union_member -------")
    union_member_t.load()
    INFO("-- load_union_member done --")

    INFO("-- load_union_tech ---------")
    union_tech_t.load()
    INFO("-- load_union_tech done ----")

    INFO("-- load_npc_city -----------")
    npc_city.load_npc_city()
    INFO("-- load_npc_city -----------")

    INFO("-- load_monster_city -----------")
    monster_city.load_monster_city()
    INFO("-- load_monster_city -----------")

    INFO("-- load_king_city -----------")
    king_city.load_king_city()
    INFO("-- load_king_city -----------")

    INFO("-- load_kw_mall -----------")
    kw_mall.load_from_db()
    INFO("-- load_kw_mall -----------")

    INFO("-- load_lost_temple -----------")
    lost_temple.load_lost_temple()
    INFO("-- load_lost_temple -----------")

    INFO("-- load_union_build --------")
    load_union_build()
    INFO("-- load_union_build done ---")

    INFO("-- load_hero ---------------")
    load_hero()
    INFO("-- load_hero done ----------")

    INFO("-- load_monster ------------")
    monster.load_from_db()
    INFO("-- load_monster done--------")

    INFO("-- restore_load_farm -------")
    farm.load_from_db()
    INFO("-- restore_load_farm done --")

    INFO("-- restore_load_unit -------")
    load_unit()
    INFO("-- restore_load_unit done --")

    INFO("-- restore_system_mail -----")
    load_sys_mail()
    INFO("-- restore_system_mail done-")

    INFO("-- restore_troop -----")
    load_troop()
    INFO("-- restore_troop done-")

    INFO("-- restore_equip -----")
    load_equip()
    INFO("-- restore_equip done-")

    INFO("-- init_effect -------------")
    init_effect()
    INFO("-- init_effect done --------")
    
    INFO("-- restore_room -----")
    load_room() 
    INFO("-- restore_room done-")
    
    INFO("-- restore_task -----")
    load_task()
    INFO("-- restore_task done -----")

    INFO("-- unoin_mall -----")
    union_mall.load()
    INFO("-- unoin_mall done -----")

    INFO("-- unoin_task -----")
    union_task.load()--在ety和union 后加载
    INFO("-- unoin_task done -----")

    INFO("-- unoin_mission -----")
    union_mission.load()--
    INFO("-- unoin_mission done -----")

    INFO("-- unoin_word -----")
    union_word.load()--
    INFO("-- unoin_word done -----")

    INFO("-- unoin_buildlv -----")
    union_buildlv.load()--
    INFO("-- unoin_buildlv done -----")

    INFO("-- unoin_relation -----")
    union_relation.load()--
    INFO("-- unoin_relation done -----")

    INFO("-- unoin_help -----")
    union_help.load()--
    INFO("-- unoin_help done -----")

    INFO("-- unoin_god -----")
    union_god.load()--
    INFO("-- unoin_god done -----")

    INFO("-- gacha_world_limit -----")
    gacha_limit_t.load_gacha_world_limit()
    INFO("-- gacha_world_limit done -----")

    post_init()
    INFO("-- done done done ----------")

    INFO("-- restore_timer -----------")
    local compensate =  restore_timer2()
    INFO("-- restore_timer done ------")


    --- fo test
    --test_mc()

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

