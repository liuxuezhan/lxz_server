
function load_game_module()
    gMapID = getMap()
    gMapNew = 1
    c_roi_init()
    c_roi_set_block("common/map_block.bytes")
    gSysMailSn = 0
    gSysMail = {}
    gSysStatus = {}
    gDelayAction = {}
    white_list = {}

    do_reload()

end

gTimeReload = gTimeReload or 0
function do_load2( mod )
    if gTimeReload == 0 or c_fmtime( mod .. ".lua" ) >= gTimeReload then
        --if gTimeReload > 0 then print( c_fmtime( mod .. ".lua" ), gTimeReload ) end
        package.loaded[ mod ] = nil
        require( mod )
        INFO("load module %s", mod)
        print("load module", mod)
    end
end

function do_reload()
    do_load("resmng")
    do_load("game")
    do_load("mem_monitor")
    do_load("common/define")
    do_load("common/tools")
    do_load("common/protocol")
    do_load("common/struct")

    do_load("timerfunc")
    do_load("public_t")
    do_load("player_t")
    do_load("player/player_item")
    do_load("player/player_mail")
    do_load("player/player_union")
    do_load("player/player_res")
    do_load("player/player_hero")
    do_load("player/player_build")
    do_load("player/player_task")
    do_load("player/player_online_award")
    do_load("player/player_month_award")
    do_load("player/player_skill")
    do_load("player/player_gacha")
    do_load("player/player_ache")
    do_load("player/player_title")
    do_load("player/player_pay_mall")
    do_load("agent_t")
    do_load("build_t")
    do_load("player/player_troop")
    do_load("troop_t")
    do_load("troop_mng")
    do_load("heromng")
    do_load("hero/hero_t")
    do_load("fight")
    do_load("farm")
    do_load("restore_handler")
    do_load("unionmng")
    do_load("union_t")
    do_load("union2_t")
    do_load("union_member_t")
    do_load("union_tech_t")
    do_load("union_build_t")
    do_load("union_hall_t")
    do_load("union_help")
    do_load("union_item")
    do_load("union_relation")
    do_load("union_god")
    do_load("npc_city")
    do_load("king_city")
    do_load("monster")
    do_load("monster_city")
    do_load("crontab")
    do_load("room")
    do_load("union_mall")
    do_load("union_task")
    do_load("union_mission")
    do_load("union_word")
    do_load("union_buildlv")
    do_load("new_union")
    do_load("triggers")
    do_load("task_logic_t")
    do_load("msglist")
    do_load("lost_temple")
    do_load("gacha_limit_t")
    do_load("kw_mall")
    do_load("use_item_logic")
    do_load("rank_mng")
    --do_load("rankmng")
    do_load("cross/gs_t")
    do_load("cross/cross_mng_c")
    do_load("cross/cross_refugee_c")
    do_load("cross/cross_rank_c")
    do_load("cross/cross_act")
    do_load("cross/cross_score")
    do_load("refugee")
    do_load("gmmng")
    do_load("gmcmd")
    do_load("wander")
    do_load("pay_mall")
    do_load("world_event")
    do_load("weekly_activity")

    --gTimeReload = c_get_time()
end

function reload()
    do_reload()
end

function tool_test()
    for i=1 , 500 , 1 do
        --to_tool(0, {type = "login_server", cmd = "upload_ply_info", appid = APP_ID, open_id = tostring(i), pid = tostring(i), logic = tostring(gMapID), level = tostring(1), name = "tool_test", custom = "1", token = 1, signature=1})
        to_tool(0, {url = "http://192.168.100.12:18083/", method = "post", appid = APP_ID, open_id = tostring(i), pid = tostring(i), logic = tostring(gMapID), level = tostring(i), name = tostring(i), custom = tostring(i), token = i, signature=i})
    end
    print("do tool test ")
    timer.new("tool_test", 1)
end

function chat_test()
    for i=10001 , 20000 , 1 do
        to_tool(0, {type = "chat", cmd = "create_chat", user = "b"..tostring(i), host = CHAT_HOST, password = "b"..tostring(i)})
    end
end

function restore_game_data()
    local rt = restore_handler.action()
    if rt == "Compensation" then
        _G.gInit = "InitCompensate"
    else
        _G.gInit = "InitGameDone"
    end
end


function do_roi_msg(msg, d0, d1, d2, d3, eids )
    --print( "do_roi_msg", msg )
    if msg == ROI_MSG.NTY_NO_RES then
        farm.do_check(d0, d1)
        monster.do_check(d0, d1)
        refugee.do_check(d0, d1)

    elseif msg == ROI_MSG.TRIGGERS_ARRIVE then
        -- x, y, eid , eid is actor
        triggers_t.arrived_target(d0, d1, d2, d3)

    elseif msg == ROI_MSG.TRIGGERS_ENTER then
        -- x, y, eidA, eidB , eidA is actor, eidB is scanner
        triggers_t.enter_range(d0, d1, d2, d3)

    elseif msg == ROI_MSG.TRIGGERS_LEAVE then
        -- x, y, eidA, eidB , eidA is actor, eidB is scanner
        triggers_t.leave_range(d0, d1, d2, d3 )

    elseif msg == ROI_MSG.GET_AROUND then
        local co = getCoroPend( "roi", d0 )
        if co then coroutine.resume(co, eids ) end
    else
        LOG("[ROI_MSG], what %s", msg)
    end
end

-------------------------------------------
--the above should be here
--
--

g_eid_max = 0

function get_eid(mode)
    local eid_max = g_eid_max
    for i = 1, 65536, 1 do
        eid_max = eid_max + 1
        if eid_max > 65535 then eid_max = 1 end
        local eid = eid_max * 4096 + gMapID
        if not gEtys[ eid ] then
            g_eid_max = eid_max
            return eid
        end
    end
end

function mark_eid( eid )
end


function add_ety(ety)
    gEtys[ ety.eid ] = ety
end

function get_ply(eid)
    local e = get_ety(eid)
    if is_ply(e) then return e end
end

function get_mon(eid)
    local e = get_ety(eid)
    if is_monster(e) then return e end
end

function get_eid_ply()
    return get_eid(EidType.Player)
end

function get_eid_res()
    return get_eid(EidType.Res)
end

function get_eid_refugee()
    return get_eid(EidType.Refugee)
end

function get_eid_troop()
    return get_eid(EidType.Troop)
end

function get_eid_monster()
    return get_eid(EidType.Monster)
end

function get_eid_lost_temple()
    return get_eid(EidType.LostTemple)
end

function get_eid_king_city()
    return get_eid(EidType.KingCity)
end

function get_eid_monster_city()
    return get_eid(EidType.MonsterCity)
end

function get_eid_uion_building()
    return get_eid(EidType.UnionBuild)
end

function get_eid_npc_city()
    return get_eid(EidType.NpcCity)
end

function get_eid_camp()
    return get_eid(EidType.Camp)
end

function get_home_troop( e )
    if e.get_my_troop then return e:get_my_troop() end
    local tr = troop_mng.get_troop( e.my_troop_id )
    if tr then return tr end

    if is_union_superres( e.propid ) and e.state == BUILD_STATE.WAIT then 
        e.my_troop_id = {}
    else
        e.my_troop_id = 0
    end
end

function get_mode_by_eid(eid)
    if eid == -1 then return -1 end
    local e = get_ety( eid )
    if e then
        return math.floor( e.propid / 1000000 )
    end
end

function get_ety(eid)
    if not eid then return end
    if eid == 0 then return end
    local e =  gEtys[ eid ]
    return e
end


function get_ety_arms(e)
    if e then
        if is_union_building(e) then
           return union_build_t.arms(e)
        else
	        return e:get_my_troop()
        end
    end
end

function save_ety(e)
    if e then
        if is_union_building(e) then
           union_build_t.save(e)
        elseif is_troop( e ) then
            e:save()
            e:notify_owner()
        elseif is_wander( e ) then
            e:save()
        else
            WARN( "no save_ety, propid=%s", e.propid or "none" )
        end
    end
end


gRemEty = gRemEty or {}
function rem_ety( eid )
    local ety = gEtys[ eid ]
    if ety then
        gRemEty[ eid ] = 1
        if ety.rooms then
            for _, rid in pairs( ety.rooms ) do
                local troop = troop_mng.get_troop( rid )
                if troop then
                    union_hall_t.battle_room_remove( troop )
                    if troop:is_go() or troop:is_ready() then
                        if troop.owner_pid >= 10000 then
                            local owner = getPlayer( troop.owner_pid )
                            if owner then
                                owner:troop_recall( troop._id, true )
                            end
                        end
                    end
                end
            end
        end
    end
end

function do_rem_ety(eid)
    local e = gEtys[ eid ]
    if e then
        --todo
        --if is_union_building(e) then
        --    if (not player_t.debug_tag) and e.fire_speed ~= 0 then
        --        WARN("燃烧不能回收")
        --        return
        --    end
        --    action( union_build_t.remove, e )
        --    --union_build_t.remove(e)
        --else

        gEtys[ eid ] = nil
        c_rem_ety(eid)
        if is_res(e) then
            if e.marktm then gPendingDelete.farm[ eid ] = 0 end

        elseif is_monster(e) then
            if e.grade >= BOSS_TYPE.ELITE and e.grade < BOSS_TYPE.SUPER then
                if monster.boss[e.eid] then
                    monster.boss[e.eid] = nil
                end
            elseif e.grade == BOSS_TYPE.SPECIAL then
                local lv =  c_get_zone_lv(e.zx, e.zy)
                local boss_list = monster.boss_special[lv] or {}
                local idx = e.zy * 80 + e.zx
                if boss_list[idx] then
                    boss_list[idx] = nil
                    monster.boss_special[lv] = boss_list
                end
            elseif e.grade == BOSS_TYPE.SUPER then
                super_boss = 0
            end
            --if e.marktm then gPendingDelete.monster[ eid ] = 0 end
            gPendingDelete.monster[ eid ] = 0

        elseif is_monster_city(e) then
            gPendingDelete.monster_city[ eid ] = 0

        elseif is_lost_temple(e) then
            gPendingDelete.lost_temple[ eid ] = 0

        elseif is_king_city(e) then
            gPendingDelete.king_city[ eid ] = 0

        elseif is_npc_city(e) then
            gPendingDelete.npc_city[ eid ] = 0

        elseif is_troop( e ) then

        else
            gPendingDelete.unit[ eid ] = 0
        end
    end
end

function is_focus(ety)
    --todo
end
function test3()
    local ap = get_ety(8)
    local union = unionmng.get_union(ap:get_uid())
    local dp1 = get_ety(2)
    union:add_member(dp1)
    local dp2 = get_ety(5)
    union:add_member(dp2)
end

function lt()
    lost_temple.start_lt()
end


function test_mc()
    local p = getPlayer(70006)
    local union = unionmng.get_union(p.uid)
    union_t.set_mc_state(union, 1)
end

function test_ch()
    local ply = getPlayer(650000)
    local pid = ply.pid
    ply.gid = 1179672
    --Rpc:create_chat_account(ply, tostring(pid), CHAT_HOST, tostring(pid))
    create_room()
    send_invite()
end

function create_room()
    local ply = getPlayer(650000)
    local pid = ply.pid
    ply.gid = 1179672
    Rpc:create_room(ply, "650000", "conference."..CHAT_HOST, ply.chat_ccount)
end

function send_invite()
    local ply = getPlayer(650000)
    local pid = ply.pid
    ply.gid = 1179672
    local users = {}
    table.insert(users, "650000@war_x.org")
    --table.insert(users, ":")
    --table.insert(users, "650001@war_x.org")
    Rpc:send_invite(ply, "650005@conference.war_x.org", users)

end


function test()
    local t1 = c_msec()
    local count = 0
    for i = 1, 100, 1 do
        for k, v in pairs( resmng.prop_task_detail ) do
            count = count + 1
            copyTab( v.FinishCondition)
        end
    end
    local t2 = c_msec()
    print( count, t2 - t1 )


    --for pid, ply in pairs( gPlys ) do
    --    if not ply:is_online() and ply._build then
    --        print( "remove player", ply.pid )
    --        ply._mail = nil
    --        ply._build = nil
    --        ply.tm_check = nil
    --    end
    --end
end

function test4()
    dumpTab(union_hall_t.union_battle_room)
end

function check_pending()
    for eid, _ in pairs( gRemEty ) do
        do_rem_ety( eid )
    end
    gRemEty = {}
    player_t.check_pending()
end

function on_shutdown()
    for id, troop in pairs( troop_mng.troop_id_map or {} ) do
        if troop:is_go() or troop:is_back() then
            troop.curx, troop.cury = c_get_actor_pos( troop.eid )
            troop.tmCur = gTime

            local chg = gPendingSave.troop[ troop._id ]
            chg.curx    = troop.curx
            chg.cury    = troop.cury
            chg.tmCur    = troop.tmCur

            print( "save troop", troop._id, troop.curx or troop.sx, troop.cury or troop.sy, troop.tmCur )
        end
    end
    _G.gInit = "SystemSaving"
end

function check_pending_before_shutdown()
    if not gPendingModule then
        --gPendingModule = { player_t, build_t, hero_t, union_t, npc_city, monster_city, king_city, lost_temple }
        gPendingModule = { player_t }
    end

    local mods = gPendingModule
    local update = false
    for _, mod in pairs( mods ) do
        for k, v in pairs( mod._cache ) do
            INFO( "shutdown, save %s : %s, n = %d", mod._name, k, v._n_ or 0 )
            update = true
        end
    end
    return update
end


function mem_info()
    local heap, alloc, mlua, mbuf, mobj, nbuf = c_get_engine_mem()
    INFO("[MEM_INFO], heap,%d, alloc,%d, lua,%d, mobj,%d, mbuf,%d, nbuf,%d", heap, alloc, mlua, mobj, mbuf, nbuf)
end

-- Hx@2015-12-03 :
function ack(self, funcname, code, reason)
    assert(self)
    assert(funcname)
    assert(code)
    code = code or resmng.E_OK
    reason = reason or resmng.E_OK
    if not Rpc.localF[funcname] then
        WARN("func:%s, code:%s, reason:%s", funcname, code, reason)
        return
    end
    local hash = Rpc.localF[funcname].id
    Rpc:onError(self, hash, code, reason)
end


function module_class( name, example ) 
    local mod = _G[ name ]
    _ENV = mod

    local _example = example
    local _name = name
    mod._example = _example
    mod._name = _name

    local mt = {
        __index = function ( t, k )
            if t._pro[ k ] then return t._pro[ k ] end
            if _example[ k ] then
                local v = _example[ k ]
                if type( v ) == "table" then
                    t._pro[ k ] = copyTab( v )
                    return t._pro[ k ]
                else
                    return v
                end
            end
            if _G[ _name ][ k ] then return _G[ _name ][ k ] end
        end,
        
        __newindex = function( t, k, v )
            if _example[ k ] then
                t._pro[ k ] = v
                _G.gPendingSave[ _name ][ t._id ][ k ] = v
            else
                rawset( t, k, v )
            end
        end
    }


    function wrap( t )
        return setmetatable( { _pro = t }, mt )
    end

    function new( t )
        if not t._id  then return MARK( "no _id") end
        gPendingInsert[ _name ][ t._id ] = t
        local self = { _pro = t }
        setmetatable( self, mt )
        self:init()
        return self
    end

    function clr( t )
        gPendingDelete[ _name ][ t._id ] = 1
    end

    function init( self )
        --override
    end
end


function get_material_group_by_rare(rare)
    if gItemGroupRare and gItemGroupRare[ rare] then return gItemGroupRare[ rare ] end

    local its = {}
    local class = ITEM_CLASS.MATERIAL
    for k, v in pairs(resmng.prop_item) do
        if v.Class == class and v.Rare == rare then
            table.insert(its, k)
        end
    end

    if not gItemGroupRare then gItemGroupRare = {} end
    gItemGroupRare[ rare ] = its
    return its
end

function Mark(fmt, ...)
    if fmt then lwarn( string.format(fmt, ...).. " ".. debug.stack(1)) else lwarn(debug.stack(1)) end
    return false
end

function get_sys_status(key)
    return _G.gSysStatus[ key ]
end

function set_sys_status(key, val)
    _G.gSysStatus[ key ] = val
    gPendingSave.status[ gMapID ][ key ] = val
end
function get_white_list(key)
    return _G.white_list[ key ]
end

function set_white_list(key, val)
    _G.white_list[ key ] = val
    gPendingSave.status[ "white_list" ][ key ] = val
end

function init_game_data()
    msglist.new("black_market", 100, true)
end

function remove_id(tab, id)
    for k, v in pairs(tab or {}) do
        if v == id then
            table.remove(tab, k)
            return true
        end
    end
end

function to_tool( sn, info )
    if sn == 0 then sn = getSn("to_tool")  end
    local val = {}
    val._t_ = gTime
    val.info = info
    gPendingToolAck[sn] = val
    Rpc:qry_tool( gAgent, sn ,info )
end

gReplayMax = 0
function get_replay_id()
    gReplayMax = gReplayMax + 1
    if gReplayMax > 4096 then
        gReplayMax = 0
    end
    return string.format("%d%d%d", gTime, gMapID, gReplayMax)
end

gQueryAroundSn = gQueryAroundSn or 0
function get_around_eids( eid, r )
    gQueryAroundSn = gQueryAroundSn + 1
    c_get_around( gQueryAroundSn, eid, r )
    local eids = putCoroPend( "roi", gQueryAroundSn )
    return eids
end

function get_mall_item( itemid )
    for _, conf in pairs( resmng.prop_mall ) do
        if type(conf.Item) == "table" and #conf.Item == 1 then
            local node = conf.Item[1]
            if node[1] == "item" and node[2] == itemid then
                return conf
            end
        end
    end
end

function get_item_price( itemid )
    for _, conf in pairs( resmng.prop_mall ) do
        if type(conf.Item) == "table" and #conf.Item == 1 then
            local node = conf.Item[1]
            if node[1] == "item" and node[2] == itemid then
                return conf.NewPrice
            end
        end
    end
    return math.huge
end



function get_pos_lv( x, y )
    return c_get_zone_lv( math.floor( x/16 ), math.floor( y/16 ) )
end

function cal_gs_power()
    local power = 0
    for k, v in pairs(gPlys or {}) do
        if v then
            power = power + v.pow
        end
    end
    return power
end

function get_top_plys(num)
    return  rank_mng:get_range(3, 1, num)
end

function upload_act_score(mode, key, val)
    local class = 1
    local center_id = 999
    Rpc:callAgent(center_id, "upload_act_score", class, mode, key, val)
end

function arm_id( culture, id )
    return ( culture * 1000000 ) + ( id % 1000000 )
end


gGlobalPending = gGlobalPending or nil
gGlobalWaiting = gGlobalWaiting or nil
gGlobalSaveThread = gGlobalSaveThread or { nil, 1, 0 }

function make_sure_save( )
    local co = coroutine.running()
    local node = gGlobalSaveThread
    while true do
        coroutine.yield()
        node[2] = 1
        node[3] = gTime
        local db = dbmng:getGlobal()
        if db then
            local infos = gGlobalWaiting
            if not infos then
                infos = gGlobalPending
                gGlobalWaiting = infos
                gGlobalPending = nil
            end

            for tab, recs in pairs( infos ) do
                for id, chgs in pairs( recs ) do
                    if not chgs._a_ then
                        db[ tab ]:update({_id=id}, {["$set"] = chgs }, true)
                    elseif chgs._a_ == 0 then
                        db[ tab ]:delete({_id=id})
                    else 
                        db[ tab ]:update( {_id=id}, chgs, true )
                    end
                end
            end
            local info = db:runCommand("getLastError")
            local flag = false
            if info and info.ok then
                if node[1] == co then
                    node[2] = 0
                    gGlobalWaiting = nil 
                    flag = true
                end
            end
            if not flag then return end
        end
        if node[1] ~= co then return end
        node[2] = 0
    end
end

function warxG_check_save()
    if gGlobalPending or gGlobalWaiting then
        local node = gGlobalSaveThread
        if node[2] == 1 then
            if gTime - node[3] < 5 then return end
            local co = coroutine.create( make_sure_save )
            coroutine.resume( co )
            node[1] = co
            node[2] = 0
            node[3] = 0
        end
        coroutine.resume( node[1] )
    end
end

function update_global( tab, key, info )
    if not gGlobalPending then gGlobalPending = {} end
    local node = gGlobalPending[ tab ]
    if not node then
        node = {}
        gGlobalPending[ tab ] = node
    end
    info._id = key
    node[ key ] = info
end

function insert_global( tab, key, info )
    info._a_ = 1
    update_global( tab, key, info)
end

