
function load_game_module()
    if config.Version == nil or type(config.Version) ~= "number" then
        _G.gInit = "Shutdown"
        WARN("shutdown, because Version is error")
        --return
    end
    gMapID = getMap()
    gMapNew = 1
    gCenterID = config.CENTER_ID or 999
    c_roi_init()
    c_roi_set_block("common/mapBlockInfo.bytes")
    gSysMailSn = 0
    gSysMail = {}
    gSysStatus = {}
    gDelayAction = {}
    white_list = {}

    Rpc.reload_protocol_define = function() do_load("war_pub/rpc/protocol") end
    Rpc.reload_user_struct_define = function() do_load("war_pub/rpc/struct") end
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
    do_load("constant/constant")
    do_load("common/define")
    do_load("common/tools")

    do_load("common/protocol")
    do_load("common/struct")
    Rpc:init("server")

    do_load("timerfunc")
    do_load("public_t")
    do_load("secret")

    do_load("player_t")
    do_load("player/player_item")
    do_load("player/player_mail")
    do_load("player/player_union")
    do_load("player/player_res")
    do_load("player/player_hero")
    do_load("player/player_build")
    do_load("player/player_task")
    do_load("player/player_online_award") --签到
    do_load("player/player_month_award") --月卡
    do_load("player/player_skill")
    do_load("player/player_gacha") --抽卡
    do_load("player/player_ache")
    do_load("player/player_title")
    do_load("player/player_pay_mall")
    do_load("player/player_operate")
    do_load("player/player_hero_road")
    do_load("player/player_hero_task")
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
    do_load("union_hero_task")
    do_load("new_union")
    do_load("triggers")
    do_load("daily_task_filter")
    do_load("task_logic_t")
    do_load("msglist")
    do_load("lost_temple")
    do_load("gacha_limit_t")
    do_load("kw_mall")
    do_load("use_item_logic")
    do_load("rank_mng")
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
    do_load("subscribe_ntf")
    do_load("tribute_exchange")

    do_load("operate_activity/operate_activity")
    do_load("operate_activity/operate_base")
    do_load("operate_activity/operate_normal")
    do_load("operate_activity/operate_lord_rank")
    do_load("operate_activity/operate_occupy_rank")

    do_load("offline_ntf")
    do_load("watch_tower")

    --gTimeReload = c_get_time()
end

function reload()
    do_reload()
end

function tool()
    gmcmd.to_tool()
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
    if config.RestorePending then
        restore_pending( config.RestorePending )
    end

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

    elseif msg == ROI_MSG.GET_NEAR then
        local co = getCoroPend( "roi", d0 )
        if co then coroutine.resume(co, d1 ) end

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
            --if e.grade >= BOSS_TYPE.ELITE and e.grade < BOSS_TYPE.SUPER then
            --    if monster.boss_grade[e.grade] then
            --        local boss = monster.boss_grade[e.grade] or {}
            --        local idx = e.zy * 80 + e.zx
            --        if boss[idx] then
            --            boss[idx] = nil
            --            monster.boss_grade[e.grade] = boss
            --        end
            --    end
            --elseif e.grade == BOSS_TYPE.SPECIAL then
            --    local lv =  c_get_zone_lv(e.zx, e.zy)
            --    local boss_list = monster.boss_special[lv] or {}
            --    local idx = e.zy * 80 + e.zx
            --    if boss_list[idx] then
            --        boss_list[idx] = nil
            --        monster.boss_special[lv] = boss_list
            --    end
            --elseif e.grade == BOSS_TYPE.SUPER then
            --    super_boss = 0
            --end
            --if e.marktm then gPendingDelete.monster[ eid ] = 0 end
            troop_mng.delete_troop(e.my_troop_id)
            gPendingDelete.monster[ eid ] = 0

        elseif is_monster_city(e) then
            local tr = troop_mng.get_troop(e.my_troop_id)
            if tr then
                if tr.owner_pid == 0 then
                    troop_mng.delete_troop(e.my_troop_id)
                end
            end
            monster_city.rem_mc_in_citys(e)
            gPendingDelete.monster_city[ eid ] = 0

        elseif is_lost_temple(e) then
            local tr = troop_mng.get_troop(e.my_troop_id)
            if tr then
                if tr.owner_pid == 0 then
                    troop_mng.delete_troop(e.my_troop_id)
                end
            end
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
   -- lost_temple.start_lt()
   monster_city.rem_all_mc()
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


function test(id)
    --gPendingInsert.test[1] = {a="b", c="d"}
    --gPendingInsert.test[1] = {e="f"}


    local rids = {
        1502480137,
        2109937726,
        157621797,
        1923780972,
        196969287,
        1433481197,
        206363805,
        393583197,
        1102596737,
        359104097,
    }

    for k, v in ipairs( rids ) do
        local node = Rpc.localF[ v ]
        print( v, node.name )
    end

    local ns = {
        {798001119, 890, 1244, 1397},
        {135185993, 2, 3, 1500},
        {1472712897, 72, 108, 1500},
        {393583197, 3028, 4801, 1585},
        {1524610729, 10, 16, 1600},
        {183746984, 646, 1039, 1608},
        {1569020298, 320, 524, 1637},
        {96213039, 123, 207, 1682},
        {975817409, 124, 214, 1725},
        {2010336858, 46, 83, 1804},
        {1102596737, 3059, 5763, 1883},
        {1090649378, 1, 2, 2000},
        {400966909, 23, 46, 2000},
        {2068420318, 12, 25, 2083},
        {359104097, 3109, 7212, 2319},
        {1553452151, 3, 7, 2333},
        {798787189, 31, 75, 2419},
        {2121008823, 301, 751, 2495},
        {326180269, 4, 10, 2500},
        {294628538, 5, 13, 2600},
        {514716984, 5, 13, 2600},
        {157621797, 1414, 3730, 2637},
        {1168354026, 3, 8, 2666},
        {575404459, 29, 79, 2724},
        {259854322, 96, 280, 2916},
        {1071939102, 6, 18, 3000},
        {1551716341, 7, 22, 3142},
        {2018864233, 14, 46, 3285},
        {201287549, 33, 121, 3666},
        {1056903569, 17, 64, 3764},
        {2093118677, 1, 4, 4000},
        {456538552, 1, 4, 4000},
        {97893147, 7, 30, 4285},
        {748250112, 223, 980, 4394},
        {206363805, 2237, 9863, 4409},
        {1815056972, 6, 28, 4666},
        {1019996971, 1, 5, 5000},
        {1086361970, 461, 2354, 5106},
        {2078887350, 10, 52, 5200},
        {1526195904, 6, 32, 5333},
        {678995975, 66, 363, 5500},
        {1506482774, 16, 115, 7187},
        {1472690236, 12, 90, 7500},
        {799185316, 29, 229, 7896},
        {1080338257, 3, 36, 12000},
        {247548640, 4, 51, 12750},
        {159043482, 10, 130, 13000},
        {1433481197, 1672, 23200, 13875},
        {888840546, 3, 59, 19666},
        {565925220, 1, 21, 21000  },

    }
    for k, v in ipairs( ns ) do
        local node = Rpc.localF[ v[1] ]
        print( string.format( "count=%d, avg=%d, use=%d, name=%s ", v[2], v[4], v[3], node.name ) )
    end


    --local name = "hello1"
    --local code = want_insert_unique_name( "name_ply", name, { pid=1, } )
    --print( "code=", code, name )



    --local p = getPlayer( 3560000 )
    --local u = unionmng.get_union( p.uid )
    --dumpTab( u.help, "union_help" )

    --local p = getPlayer( 3560002 )
    --if p then
    --    union_help.set( p, 4391 )
    --end


    --gPendingInsert.test[1] = {foo="world"}
    --gPendingSave.test[1] = {}
    
    --local p = getPlayer( 3370136 )
    --p._count = nil
    --p:add_count(1,1)
    --p:clear_task()
    --if p._cur_task_list then
    --    WARN( "should not see this" )
    --end

    --print( p:get_device_grade( "iphone", "opengl", 100, 1 ) )
    --p:add_exp(100)

    --Rpc:tips(p, 1, resmng.TIPS_OVERLAP, {})
    --player_t.mail_all({class=3, mode=0, title="hello", content="world", its=nil} )
    --player_t.gClientExtra = "Rpc:init()"
    --local info 
    --for i = 1, 1024, 1 do
    --    local db = dbmng:getOne()
    --    info = db:runCommand( "getLastError" )
    --end
    --dumpTab(info, "TableMark" )

    --local s = debug.tablemark(1024)
    --for k, v in pairs( s ) do
    --    INFO( "TableMark, %s", v)
    --end
    

    --local node = {{hello="foo"}, {foo="bar"}}
    --Rpc:union_search( p, "hello", node )

    --local a = bson.encode_order( "update", "status", "updates", {hello="world", a=1}, "ordered", false)
    --local b,c,d,e,f,g = bson.decode( a )
    --for k, v in pairs( b ) do
    --    print( k, v )
    --end


    --for i = 1, 50, 1 do
    --    player_t.add_chat({pid=-1, gid=_G.GateSid}, 0, 0, {pid=0}, "ok "..i, 0, {})
    --end


    --break_player( 2290016 )
    --gmcmd.kaifu()

    --gPendingSave.test[ "hello" ] = { _id="hello", foo="bar" }

    --local str0 = c_encode_aes( "4e69fd13cb06ef2c62c712ced980d1e6", "1234567890123456", Json.encode( { hello="foo", world=1} ) )
    --local str1 = c_encode_base64( str0 )
    --print( str1 )

    --local ply = getPlayer( 2020000 )
    --local eid = get_near( ply.x+2, ply.y+2, 2001002 )
    --local dst = get_ety( eid )
    --if dst then
    --    print( "ply", ply.x, ply.y )
    --    print( "dst", dst.x, dst.y )
    --end


    --for r = 1, 78, 1 do
    --    for c = 1, 78, 1 do
    --        farm.do_check( r, c, true )
    --        monster.do_check( r, c, true )
    --    end
    --end

    --local t = debug.tablemark()
    --for k, v in pairs( t ) do
    --    INFO( "MarkTable, %s", v )
    --end

    --local s1 = snapshot()
    --for k, v in pairs( s1 ) do
    --    print( k, v )
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
    warxG_check_save()
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
    if next( player_t.gChat ) then gPendingSave.status.chat = player_t.gChat end

    _G.gInit = "SystemSaving"
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
    INFO("pid=%d,uid=%d,func:%s, code:%s, reason:%s",self.pid,self.uid, funcname, code, reason)
    Rpc:onError(self, hash, code, reason)
end

function copyTab2(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return new_table
    end
    return _copy(object)
end

function module_class( name, example, table_name ) 
    local mod = _G[ name ]
    _ENV = mod

    local _example = example
    local _name = name
    local _table_name = table_name or name

    mod._example = _example
    mod._name = _name
    mod._table_name = _table_name

    local mt = {
        __index = function ( t, k )
            if t._pro[ k ] then return t._pro[ k ] end
            if _example[ k ] then
                local v = _example[ k ]
                if type( v ) == "table" then
                    t._pro[ k ] = copyTab2( v )
                    return t._pro[ k ]
                else
                    return v
                end
            end
            return rawget( _G[ _name ], k )
            -- todo is it ok?
            --return _G[ _name ][ k ]
        end,
       
        __newindex = function( t, k, v )
            if _example[ k ] then
                if type(v) ~= "table" then
                    if t._pro[k] ~= v then
                        t._pro[ k ] = v
                        _G.gPendingSave[ _table_name ][ t._id ][ k ] = v
                        return
                    end
                end
                t._pro[ k ] = v
                _G.gPendingSave[ _table_name ][ t._id ][ k ] = v
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
        gPendingInsert[ _table_name ][ t._id ] = t
        local self = { _pro = t }
        setmetatable( self, mt )
        self:init()
        return self
    end

    function clr( t )
        gPendingDelete[ _table_name ][ t._id ] = 1
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

    local tm_drop = gTime - 3600 * 24 * 7
    local tm_delete = gTime - 3600 * 24 * 30
    local db = dbmng:getOne()
    db.mail:delete( { tm_drop = { [ "$gt" ] = 0, [ "$lt" ] = tm_drop } } )
    db.mail:delete( { tm = { [ "$lt" ] = tm_delete } } )
    player_t.clear_outline() 
end


function remove_id(tab, id)
    for k, v in pairs(tab or {}) do
        if v == id then
            table.remove(tab, k)
            return true
        end
    end
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

function get_near( x, y, propid, dist )
    dist = dist or 0
    gQueryAroundSn = gQueryAroundSn + 1
    c_get_near( gQueryAroundSn, x, y, propid, dist )
    local eid = putCoroPend( "roi", gQueryAroundSn )
    return eid
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
    Rpc:callAgent(gCenterID, "upload_act_score", class, mode, key, val)
end

function arm_id( culture, id )
    return ( culture * 1000000 ) + ( id % 1000000 )
end


gGlobalPending = gGlobalPending or false
gGlobalWaiting = gGlobalWaiting or false
gGlobalSaveThread = gGlobalSaveThread or { nil, 1, 0 }

function make_sure_save( )
    local co = coroutine.running()
    local node = gGlobalSaveThread
    while true do
        coro_mark( co, "pend" )
        coroutine.yield()
        node[2] = 1
        node[3] = gTime
        local db = dbmng:getGlobal()
        if db then
            local infos = gGlobalWaiting
            if not infos then
                infos = gGlobalPending
                gGlobalWaiting = infos
                gGlobalPending = false
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
                    gGlobalWaiting = false 
                    flag = true
                end
            end

            if not flag then 
                INFO( "make_sure_save, flag = false, %d, %s", gFrame, co )
                return 
            end
        end
        if node[1] ~= co then 
            INFO( "make_sure_save, node[1] ~= co, %d, %s", gFrame, co )
            return 
        end
        node[2] = 0
    end
end

function warxG_check_save()
    if gGlobalPending or gGlobalWaiting then
        local node = gGlobalSaveThread
        if node[2] == 1 then
            if gTime - node[3] < 5 then return end
            local co = coroutine.create( make_sure_save )
            INFO( "make_sure_save, new co, %d, %s", gFrame, co )
            node[1] = co
            node[2] = 0
            node[3] = 0
            coroutine.resume( co )
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

gOnlines = gOnlines or {}
function mark_access( pid )
    local node = gOnlines[ pid ]
    if not node then
        gOnlines[ pid ] = {gTime, gTime}
    else
        node[2] = gTime
    end
end


function getPlayer(pid)
    if pid then
        if pid >= 10000 then
            local p = gPlys[ pid ]
            if p then
                rawset( p, "_access", gTime )
            end
            return p

        elseif pid > 0 then
            return { pid=pid }
        end
    end
end


