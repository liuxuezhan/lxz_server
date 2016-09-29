
function load_game_module()
    gMapID = getMap()
    gMapNew = 1
    c_roi_init()
    c_roi_set_block("common/map_block.bytes")
    gSysMailSn = 0
    gSysMail = {}
    gSysStatus = {}
    gDelayAction = {}

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
    do_load("common/rpc_parse")
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
    do_load("gmmng")

    --gTimeReload = c_get_time()
end

function reload()
    do_reload()
end

function restore_game_data()
    local rt = restore_handler.action()
    if rt == "Compensation" then
        gInit = "InitCompensate"
    else
        gInit = "InitGameDone"
    end
end


function do_roi_msg(msg, d0, d1, d2, d3, eids )
    --print( "do_roi_msg", msg )
    if msg == ROI_MSG.NTY_NO_RES then
        farm.do_check(d0, d1)
        monster.do_check(d0, d1)

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
        if eid_max > 65535 then eid_max = 0 end
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

function get_mode_by_eid(eid)
    if eid == -1 then return -1 end
    local e = get_ety( eid )
    if e then
        return math.floor( e.propid / 1000000 )
    end
end

function get_ety(eid)
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
        else
            WARN( "no save_ety, propid=%s", e.propid or "none" )
        end
    end
end

function rem_ety(eid)
    local e = gEtys[ eid ]
    if e then
        if is_union_building(e) then
            if (not player_t.debug_tag) and e.fire_speed ~= 0 then
                WARN("燃烧不能回收")
                return
            end
            union_build_t.remove(e)
        else
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            if is_res(e) then
                if e.marktm then gPendingDelete.farm[ eid ] = 0 end

            elseif is_monster(e) then
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

            else
                gPendingDelete.unit[ eid ] = 0
            end
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
    Rpc:create_room(ply, "650000", "conference."..CHAT_HOST, ply.chat_account)
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

    Rpc:callAgent( 13, "agent_move_eye", 123, 2, 3)

    --local p = getPlayer( 2970038 )
    --p:add_msg( "aid", {1,2,"loon0"})
    --p:add_msg( "aid", {1,2,"loon1"})
    --p:add_msg( "aid", {1,2,"loon2"})
    --p:add_msg( "aid", {1,2,"loon3"})

    --local msg = p:load_msg( "aid" )
    --dumpTab( msg, "load_msg" )


    --get_around_eids( p.eid, 20 )
    --for i = 1, 3200, 1 do
    --    monster.loop()
    --end

    --local mons = {}
    --local ress = {}

    --for k, v in pairs( gEtys ) do
    --    if is_res( v ) or is_monster( v ) then
    --        local x = math.floor( v.x / 16 )
    --        local y = math.floor( v.y / 16 )
    --        local idx = y * 80 + x

    --        if is_res( v ) then
    --            if not ress[ idx ] then
    --                ress[ idx ] = { v }
    --            else
    --                table.insert( ress[ idx ], v )
    --            end
    --        else
    --            if not mons[ idx ] then
    --                mons[ idx ] = { v }
    --            else
    --                table.insert( mons[ idx ], v )
    --            end
    --        end
    --    end
    --end

    --for k, v in pairs( mons ) do
    --    if #v > 2 then
    --        print( "mons", k, #v )
    --        for _, mon in pairs( v ) do
    --            print( "mon", mon.eid, mon.propid, mon.hp, mon.x, mon.y, mon.born, mon.grade, mon.level )
    --            INFO( "mons_num, %d,%d,%d,%d,%d,%d,%d,%d,%d", k, mon.eid, mon.propid, mon.hp, mon.x, mon.y, mon.born, mon.grade, mon.level )
    --        end
    --    end
    --end
end

function test4()
    dumpTab(union_hall_t.union_battle_room)
end

function check_pending()
    player_t.check_pending()
    build_t.check_pending()
    hero_t.check_pending()
    union_t.check_pending()
    room.check_pending()
    npc_city.check_pending()
    monster_city.check_pending()
    king_city.check_pending()
    lost_temple.check_pending()


    for pid, actions in pairs( gDelayAction ) do
        local A = getPlayer( pid )
        if A then
            for func, v in pairs( actions ) do
                if v == 0 then
                    func( A )
                    actions[ func ] = 1
                end
            end
        end
    end
    gDelayAction = {}

    --dirty_sync()
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

-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 模块类
-- 因为module 中找不到时会去全局找，所以对象局部变量找不到时很可能在全局找
-- 如：
-- local data = {module_class=nil}
-- local obj = name_t.new(data)
-- local k = obj.module_class
-- 如果obj中不存在class则会去全局找module_class，因此找到本全局函数，造成错误
-- 所以一定类成员不要和全局函数同名!!!!
-- -----------------------------------------------------------------------------
function module_class(name, example)
    assert(example._id, "must have _id as pk")
    module(name, package.seeall)
    setfenv(2, getfenv(1))
    _cache = _cache or {}
    _example = example
    local mt = {
        __index = function(t, k)
            if t._pro[k] ~= nil then return t._pro[k] end
            if _example[k] ~= nil then
                if type(_example[k]) == "table" then
                    t._pro[k] = copyTab(_example[k])
                    return t._pro[k]
                else
                    return _example[k]
                end
            end
            if _G[name][k] ~= nil then return _G[name][k] end
        end,
        __newindex = function(t, k, v)
            if _example[k] then
                t._pro[k] = v
                local id = t._id 
                local chgs = _cache[ id ]
                if not chgs then
                    chgs = {}
                    _cache[ id ] = chgs 
                end
                chgs[ k ] = v
                chgs._n_ = nil
            else
                rawset(t, k, v)
            end
        end
    }

    function wrap(t)
        return setmetatable({_pro=t}, mt)
    end

    function new(t)
        if not t._id  then return MARK( "no _id") end
        _cache[t._id] = t
        local self = {_pro=t}
        t._a_ = 1
        setmetatable(self, mt)
        self:init()

        -- in order to detect add event when check_pending()
        -- Hx@2016-01-07 : do it in init() by your self. some module did not want that
        --_cache[self._id] = self._pro

        return self
    end

    function clr(t)
        _cache[ t._id ] = {_a_=0}
    end

    function init(self)
        --override
    end

    function check_pending()
        local db = dbmng:tryOne(1)
        if not db then return end

        local update = false
        local cur = gFrame
        for id, chgs in pairs(_cache) do
            if not chgs._n_ then
                if not chgs._a_ then
                    local oid = chgs._id
                    chgs._id = id
                    db[ name ]:update({_id=id}, {["$set"] = chgs }, true)
                    chgs._id = oid
                    print( "[DB], update", name, id )
                else
                    if chgs._a_ == 0 then
                        db[ name ]:delete( { _id = id } ) 
                        print( "[DB], delete", name, id )
                    else
                        local oid = chgs._id
                        rawset( chgs, "_a_", nil )
                        rawset( chgs, "_id", id )
                        db[ name ]:update( {_id=id}, chgs, true )
                        rawset( chgs, "_a_", 1)
                        rawset( chgs, "_id", oid )
                        print( "[DB], create", name, id )
                    end
                end
                update = true
                rawset( chgs, "_n_", cur )
                if on_check_pending then on_check_pending( db, id, chgs ) end
            end
        end
        if update then get_db_checker(db, cur)() end
    end

    --function on_check_pending(db, _id, chgs)
    --    WARN("override this!!!")
    --    --override
    --end

    function get_db_checker(db, frame)
        local f = function()
            local info = db:runCommand("getPrevError")
            if info.ok then
                local dels = {}
                for k, v in pairs(_cache) do
                    local n = v._n_
                    if n then
                        if n == frame then
                            table.insert(dels, k)
                        elseif n < frame - 100 then
                            WARN("mongo_error, %s:%s, %s, %s, %s", name, k, n, frame, gFrame)
                            dumpTab( v, "mongo_error" )
                            v._n_ = nil

                        end
                    end
                end
                if #dels > 0 then
                    for _, v in pairs(dels) do
                        _cache[v] = nil
                    end
                end
            end
        end
        return coroutine.wrap(f)
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
    --[[
    if fmt then lwarn( string.format(fmt, ...).. " ".. debug.stack(1))
    else lwarn(debug.stack(1)) end
    --]]
    return false
end


function get_sys_status(key)
    return _G.gSysStatus[ key ]
end

function set_sys_status(key, val)
    _G.gSysStatus[ key ] = val
    gPendingSave.status[ gMapID ][ key ] = val
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



--timer.new("tlog", 1)
