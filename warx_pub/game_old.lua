
function load_game_module()
    --if not config.GameAppIDs then 
    --    WARN( " config file should have GameAppIDs like next line" )
    --    WARN( " GameAppIDs = { [\"NULL\"] = 0 }" )
    --    os.exit( -1 )
    --end

    if config.Version == nil or type(config.Version) ~= "number" then
        _G.gInit = "Shutdown"
        WARN("shutdown, because Version is error")
        os.exit( -1 )
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


    gOperateDiceTime = 0
    gOperateDiceIdx = 0
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
    do_load("frame/login_queue")
    do_load("game")
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
    do_load("player/player_pay_mall")
    do_load("player/player_operate")
    do_load("player/player_hero_road")
    do_load("player/player_hero_task")
    do_load("player/player_hero_equip")
    do_load("player/player_swap")
    do_load("agent_t")
    do_load("build_t")
    do_load("player/player_troop")
    do_load("troop_t")
    do_load("troop_mng")
    do_load("heromng")
    do_load("hero/hero_t")
    do_load("hero/hero_equip_t")
   -- do_load("hero/hero_task_t")
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
    do_load("yueka_t")
    do_load("triggers")
    do_load("daily_task_filter")
    do_load("task_logic_t")
    do_load("msglist")
    do_load("lost_temple")
    do_load("gacha_limit_t")
    do_load("kw_mall")
    do_load("use_item_logic")
    do_load("rank_mng")
    do_load("custom_rank_mng")
    do_load("cross/gs_t")
    do_load("cross/cross_mng_c")
    do_load("cross/cross_refugee_c")
    do_load("cross/cross_rank_c")
    do_load("cross/cross_act")
    do_load("cross/cross_score")
    do_load("cross/player_rank_award")
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
    do_load("act_mng")
    do_load("daily_activity")
    do_load("cross_activities/periodic_activity_manager")
    do_load("cross_activities/periodic_main_activity")
    do_load("cross_activities/periodic_activity")

    --gTimeReload = c_get_time()
end

function reload()
    do_reload()
end

function tool()
    gmcmd.to_tool()
end

function tool_test()
--    for i=1 , 500 , 1 do
        --to_tool(0, {type = "login_server", cmd = "upload_ply_info", appid = APP_ID, open_id = tostring(i), pid = tostring(i), logic = tostring(gMapID), level = tostring(1), name = "tool_test", custom = "1", token = 1, signature=1})
      --  to_tool(0, {url = "http://192.168.100.12:18083/", method = "post", appid = APP_ID, open_id = tostring(i), pid = tostring(i), logic = tostring(gMapID), level = tostring(i), name = tostring(i), custom = tostring(i), token = i, signature=i})
  --  end
  --to_tool(0, {type="mysql", sql_query="insert into tool (b) values (\"cc\")" })
 --qto_tool(0, {type="mysql", sql_query="REPLACE INTO tcapluse ('pid', 'day', 'gameappid', 'platid', 'openid', 'zoneareaid', 'level', 'viplevel', 'money', 'diamond', 'iFriends', 'regtime', 'lastime') VALUES (4282816, CURDATE(), \"gameappid\", 1, \"9f0abaf621c16eab62bd84268eca0490\", 3, 10, 2, 2521, 0, 0, FROM_UNIXTIME(1502972279, \"%Y%m%d\"), FROM_UNIXTIME(1503058868, \"%Y%m%d\"));"})
  --to_tool(0, {type="mysql", sql_query="REPLACE INTO tcaplus (pid, day, gameappid, platid, openid, zoneareaid, level, viplevel, money, diamond, iFriends, regtime, lastime) VALUES (4282815, CURDATE(), \"gameappid\", 1, \"9f0abaf621c16eab62bd84268eca0490\", 3, 10, 2, 2521, 0, 0, FROM_UNIXTIME(1502972279, \"%Y%m%d\"), FROM_UNIXTIME(1503058868, \"%Y%m%d\"))"})
  to_tool(0, {type = "echo", string = "hhhhhh"})
    print("do tool test ")
   -- timer.new("tool_test", 1)
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
    for i = 1, 131071, 1 do
        eid_max = eid_max + 1
        if eid_max >= 131071 then eid_max = 1 end
        local eid = eid_max * 4096 + gMapID
        if not gEtys[ eid ] then
            g_eid_max = eid_max
            if i >= 2000 then WARN( "[EID], not enough, %d", i ) end
            return eid
        end
    end
end


function add_ety(ety)
    gEtys[ ety.eid ] = ety
end

function get_ply(eid)
    local e = get_ety(eid)
    if e and is_ply(e) then return e end
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
    if e and e.eid == eid then 
        return e 
    else
        return
    end
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
            local rooms = ety.rooms
            ety.rooms = {}
            for _, rid in pairs( rooms ) do
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

function test_thread1()
    INFO( "hello = %d",  bb_ )
    assert( false, "shit shit shit" )
end

function test_thread()
    --test_thread1()
    xpcall( test_thread1, STACK )
end


function test(id)
    local p = getPlayer( 1540004 )
    if p then
        p:operate_dice_action( 1 )
    end
end

function test4()
    dumpTab(union_hall_t.union_battle_room)
end

function check_pending()
    for eid, _ in pairs( gRemEty ) do
        do_rem_ety( eid )
    end
    gRemEty = {}
    warxG_check_save()
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

            WARN( "[TROOP], save_on_shutdown, id,%s, x,%4.2f, y,%4.2f, tmCur,%s", troop._id, troop.curx or troop.sx or 0, troop.cury or troop.sy or 0, troop.tmCur or 0 )
        end
    end
    if next( player_t.gChat or {} ) then gPendingSave.status.chat = player_t.gChat end

    for pid, node in pairs( gOnlines ) do
        player_t.mark_online_time( pid )
    end

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
            if t._pro[ k ] or t._pro[k] == false then return t._pro[ k ] end
            if _example[ k ] ~= nil then
                local v = _example[ k ]
                if type( v ) == "table" then
                    t._pro[ k ] = copyTab2( v )
                    return t._pro[ k ]
                else
                    return v
                end
            end
            return rawget( _G[ _name ], k )
        end,
       
        __newindex = function( t, k, v )
            if _example[ k ] ~= nil then
                if type(v) ~= "table" then
                    if t._pro[k] ~= v then
                        t._pro[ k ] = v
                        --print( _table_name, ",", k, ",", v )
                        _G.gPendingSave[ _table_name ][ t._id ][ k ] = v
                        return
                    end
                end
                --print( _table_name, ",", t._id, ",", k, ",", v )
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

    if gMapID ~= gCenterID then
        daily_activity.init_daily_activity()
    else
        periodic_activity_manager.sync_all_data()
    end
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
                    local op = chgs._a_
                    if not op then
                        db[ tab ]:update({_id=id}, {["$set"] = chgs }, true)
                    elseif op == 0 then
                        db[ tab ]:delete({_id=id})
                    else 
                        chgs._a_ = nil
                        db[ tab ]:update( {_id=id}, chgs, true )
                        chgs._a_ = op
                    end
                end
            end

            local info = db:runCommand("getLastError")
            local flag = false
            if info and info.ok then
                if info.errmsg or info.writeErrors or info.writeConcernError then
                    WARN( "[DB], global, error" )
                    dumpTab( info, "global_check_save", 100, true )
                end

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

    local rnode = node[ key ]
    if not rnode then
        rnode = {}
        node[ key ] = rnode
    end

    for k, v in pairs( info ) do
        rnode[ k ] = v
    end
end

function insert_global( tab, key, info )
    info._a_ = 1
    update_global( tab, key, info)
end

gOnlines = gOnlines or {}
function mark_access( pid )
    local node = gOnlines[ pid ]
    if not node then
        gOnlines[ pid ] = {gTime-1, gTime}
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


function can_handle_login_num()
    local max_online_num = config.MaxOnlineNum or 4000
    local load_num_pre_sec = config.LoadNumPreSec or 2
    local num = max_online_num - player_t.g_online_num
    if num <= 0 then return 0 end

    return math.min(num, load_num_pre_sec)
end

function gSyncFunction() 
    player_t.frame_end()
end

function get_player_map(pid)
    local db = dbmng:getGlobal()
    local info = db.players:findOne({_id=pid})
    if info then
        return info.emap
    end
end

function get_union_map(uid)
    local db = dbmng:getGlobal()
    local info = db.unions:findOne({_id=uid})
    if info then
        return info.map
    end
end

timer_ex = timer_ex or {
    mark_func = timer.mark,
    timers = {},
    wanted_timer = {
        cure = 1,
        hero_cure = 1,
        hero_task = 1,
        troop = 1,
        build = 1,
        expiry = 1,
        buf = 1,
        city_fire = 1,
        rem_buf_build = 1,
        remove_state = 1,
        cross_migrate_back = 1,
    },
}

function timer_ex.mark(node)
    timer_ex.mark_func(node)
    timer_ex.mark_only(node)
end

function timer_ex.mark_only(node)
    if timer_ex.wanted_timer[node.what] then
        local pid = node.param[1]
        if node.delete then
            if timer_ex.timers[pid] then
                timer_ex.timers[pid][node._id] = nil
            end
        else
            timer_ex.timers[pid] = timer_ex.timers[pid] or {}
            timer_ex.timers[pid][node._id] = gTime
        end
    end
end

function timer_ex.get_timers(pid)
    return timer_ex.timers[pid]
end

function timer_ex.clear_timer(pid)
    timer.mark = timer_ex.mark_func
    for k, v in pairs(timer_ex.timers[pid] or {}) do
        timer.del(k)
    end
    timer.mark = timer_ex.mark
    timer_ex.timers[pid] = nil
end

function timer_ex.wrap()
    timer.mark = timer_ex.mark
end


function table_mark()
    local t = debug.tablemark(100)

    local info = {}
    for k, v in pairs( t ) do
        local idx = string.find( v, ",", 1, true )
        local count = string.sub( v, 1, idx - 1 )
        local location = string.sub( v, idx + 1 )
        table.insert( info, {tonumber(count), location} )
    end

    table.sort( info, function (A,B) return A[1] < B[1] end )

    for k, v in ipairs( info ) do
        print( v[1], v[2] )
    end
end

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function to_37_chat_center(ply, mode, msg, tar_ply)
    local to_ply = tar_ply or {}
    local body = {
        time = gTime,
        uid = ply.account,
        gid = 1002794,
        dsid = tostring(gMapID),
        type = mode,
        actor_name = encodeURI(ply.name),
        actor_id = ply.pid,
        to_uid = to_ply.account or "",
        to_actor_name = to_ply.name or "",
        content = encodeURI(msg),
        chat_time = gTime,
    }

   local send_body = ""
   for k, v in pairs(body or {}) do
       local val = v
       if type(v) == "number" then
           val = tostring(v)
       end
       if send_body == "" then
           send_body = k .."=".. val
       else
           send_body = send_body .. "&" .. k .."=".. val
       end
   end

    to_tool(0,
    {
        url = "http://cm2.api.37.com.cn",
        method = "post",
        content_type = "application/x-www-form-urlencoded",
        body = send_body
    }
    )
end

--function async_chat(ply, mode, msg, tar_ply)
--    local to_ply = tar_ply or {}
--    local key = "4Makr5AIzlwQp9P3mGfiV+q@7jRYXdL6"
--    local uid = ply.account
--    local gid = 1002794
--    local dsid = tostring(gMapID)
--
--    local body = {
--    time = gTime,
--    uid = ply.account,
--    gid = gid,
--    dsid = dsid,
--    type = mode,
--    actor_name = encodeURI(ply.name),
--    actor_id = ply.pid,
--    content = encodeURI(msg),
--    idfa = "",
--    oudid = "",
--    idfv = "",
--    mac = "",
--    imei = "",
--    user_ip = "",
--    chat_time = tostring(gTime),
--    to_uid = to_ply.account,
--    to_actor_name = to_ply.name,
--    actor_level = player_t.get_castle_lv(to_ply),
--    actor_recharge_gold = to_ply.gold,
--    sign = string.lower(c_md5(key .. uid .. tostring(gid) .. dsid .. tostring(gTime) .. tostring(mode))),
--}
--    local sn = to_tool(0,
--    {
--        url = "http://cm3.api.37.com.cn/Content/_checkContent",
--        method = "post",
--        body = Json.encode(body)
--    }
--    )
--    return sn
--end

function async_chat(ply, mode, msg, tar_ply)
    local get_type_by_mode = 
    {
        [resmng.ChatChanelEnum.World] = 1,
        [resmng.ChatChanelEnum.Union] = 2,
        [resmng.ChatChanelEnum.Culture] = 3,
        [resmng.ChatChanelEnum.Notice] = 7,
    }
    local to_ply = tar_ply or {}
    local key = "D3%ZkY8UwtZS(Pk6"
    local uid = ply.account
    local gid = 1002794
    local dsid = tostring(gMapID)
    local body = {
    time = gTime,
    uid = ply.account,
    gid = gid,
    dsid = dsid,
    type = get_type_by_mode[mode],
    actor_name = encodeURI(ply.name),
    actor_id = ply.pid,
    content = encodeURI(msg),
    --idfa = "",
    --oudid = "",
    --idfv = "",
    --mac = "",
    --imei = "",
    --user_ip = "",
    chat_time = tostring(gTime),
    to_uid = to_ply.account,
    to_actor_name = to_ply.name,
    actor_level = player_t.get_castle_lv(to_ply),
    actor_recharge_gold = to_ply.gold,
    sign = string.lower(c_md5(key .. uid .. tostring(gid) .. dsid .. tostring(gTime) .. tostring(mode))),
}

   local send_body = ""
   for k, v in pairs(body or {}) do
       local val = v
       if type(v) == "number" then
           val = tostring(v)
       end
       if send_body == "" then
           send_body = k .."=".. val
       else
           send_body = send_body .. "&" .. k .."=".. val
       end
   end

    local sn = to_tool(0,
    {
        url = "http://cm3.api.37.com.cn/Content/_checkContent",
        method = "post",
        content_type = "application/x-www-form-urlencoded",
        body = send_body
        --body = "time=1512998323& uid=db8ea08bbeafae22cb52dd16743bfede&gid=1002794&dsid=7&type=1& sign=f089afa67822338cab069f211e2c1c71&actor_name=K7a70000&actor_id=70000&chat_time=1512998323&content=ffff"
    })
    return sn
end

function deal_tool_ack(req, pid, sn, data)
    if req.url and handle_tool_ack[req.url] then
        handle_tool_ack[req.url](req, pid, sn, data)
    end
end

handle_tool_ack = {}

handle_tool_ack["http://cm3.api.37.com.cn/Content/_checkContent"] = function(req, pid, sn, data)
    if data.result == 1 then
        local third_ret = Json.decode(tostring(data.third_ret or ""))
        if third_ret.state == 1 then
            send_chat(sn)
        end
    end
end

function send_chat(sn)
    local chat_info = player_t.gPendingChat[sn]
    if chat_info then
        player_t.do_chat(chat_info.ply, chat_info.channel, chat_info.speaker, chat_info.word)
        player_t.gPendingChat[sn] = nil
    end
end



