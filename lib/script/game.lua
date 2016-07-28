
function load_game_module()
    gMapID = getMap()
    gMapNew = 1
    c_map_init()
    c_roi_init()
    c_roi_set_block("common/map_block.bytes")
    gSysMailSn = 0
    gSysMail = {}
    gSysStatus = {}
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
    do_load("arm_t")
    do_load("player/player_troop")
    do_load("troop_t")
    do_load("troop_mng")
    do_load("heromng")
    do_load("hero/hero_t")
    do_load("fight")
    do_load("farm")
    do_load("unionmng")
    do_load("union_t")
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
    do_load("restore_handler")

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


function do_roi_msg(msg, d0, d1, d2, d3, d4, d5, d6, d7)
    if msg == ROI_MSG.NTY_NO_RES then
        farm.do_check(d0, d1)
        monster.do_check(d0, d1)

    elseif msg == ROI_MSG.TRIGGERS_ARRIVE then
        -- x, y, eid , eid is actor
        triggers_t.arrived_target(d0, d1, d2, d3, d4, d5, d6, d7)

    elseif msg == ROI_MSG.TRIGGERS_ENTER then
        -- x, y, eidA, eidB , eidA is actor, eidB is scanner
        triggers_t.enter_range(d0, d1, d2, d3, d4, d5, d6, d7)
    elseif msg == ROI_MSG.TRIGGERS_LEAVE then
        -- x, y, eidA, eidB , eidA is actor, eidB is scanner
        triggers_t.leave_range(d0, d1, d2, d3, d4, d5, d6, d7)
    else
        LOG("[CPU_FRAME, what")
    end
end

-------------------------------------------
--the above should be here
--
--

g_eid_max = 0
function get_eid()
    local eid_max = g_eid_max
    --524288 = math.pow(2,19)
    for i = 1, 524288, 1 do 
        eid_max = eid_max + 1
        if eid_max > 524288 then eid_max = 1 end
        local eid = eid_max * 4096 + (gMapID or 1)

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
    return gEtys[ eid ]
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
        elseif e.action then--行军队列  
            e:save()
            e:notify_owner()
        else
            assert()
        end
    end
end

function rem_ety(eid)
    local e = gEtys[ eid ]
    if e then
        if is_res(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            if e.marktm then gPendingDelete.farm[ eid ] = 0 end

        elseif is_monster(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            e:checkout()
            if e.marktm then gPendingDelete.monster[ eid ] = 0 end

        elseif is_monster_city(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            if e.marktm then gPendingDelete.monster_city[ eid ] = 0 end

        elseif is_lost_temple(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            if e.marktm then gPendingDelete.monster[ eid ] = 0 end

        elseif is_union_building(e) then
           union_build_t.remove(e)

        else
            gPendingDelete.unit[ eid ] = 0
            gEtys[ eid ] = nil
            c_rem_ety(eid)
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

--[[
function test2()
    local ap = get_ety(7)
    c_rem_ety(ap.eid)
    ap.x = 160
    ap.y = 1100
    etypipe.add(ap)
end

--]]
function test()

    --gPendingSave.test[ 2 ] = { {1,2,3}, {4,5,6,} }
    --gPendingSave.test[ 2 ] = { _id=2, {1,2,3}, {4,5,6,} }
    --gPendingSave.test[ 3 ] = { data={{1,2,3},{4,5,6,}} }

    --local hero = heromng.get_hero_by_uniq_id( "5_1550001" )
    --local tab = heromng.get_fight_attr( "5_1550001" )
    --dumpTab( tab, "hero_fight" )

    --timer.new( "check_frame", 0, 0)

    local pl = getPlayer( 1880006 )
    pl:initEffect()
    --pl:add_debug( "hello, %d", pl.pid )

    --pl:ef_add( {SpeedConsume_R=1000} )
    --pl:ef_add( {SpeedGather1_R=50000} )
    

    --pl.month_award_count = 3
    --pl.month_award_1st = gTime - 3600 * 240

    --print( pl.month_award_1st)
    --print( pl.month_award_cur)
    --print( pl.month_award_mark)
    --print( pl.month_award_count)

    --local idx = pl:month_award_get_award()

    --print( pl.month_award_1st)
    --print( pl.month_award_cur)
    --print( pl.month_award_mark)
    --print( pl.month_award_count)

    --dumpTab( rank_mng.load_rank(1), "rank1") 
    --dumpTab( rank_mng.load_rank(2), "rank2") 
    --dumpTab( rank_mng.load_rank(5), "rank3") 

    --c_tlog( "hello" )

    --rank_mng.clear(6)

    --local pl = getPlayer( 1180000 )
    --print( pl:get_ache( 1001 ) )
    --pl:set_ache( 1001 )

    --print( pl:get_count( 1001 ) )
    --pl:add_count( 1001, 1 )

    ----
    --rank_mng.add_member( 1, 1180011, {2, gTime, "hello"} )

    --local res = rank_mng.load_rank( 1 )
    --for k, v in pairs( res ) do
    --    print( v[1], v[2], v[3], v[4] )
    --end

    --print(rank_mng.get_rank( 1, 1180014 ))

    --print( "rank", rank_mng.get_rank(1, 10010 ) )

    --local t = {}
    --t.heloo = 5
    --t[1] = 100
    --t[2] = 100
    --t[3] = 100

    --gPendingSave.test[ "hello" ] = t

    --local sl = skiplist()
    --sl:insert(1, "hello")
    --sl:insert(3, "world")
    --sl:insert(5, "foo")
    --sl:insert(5, "aaa")
    --sl:insert(7, "bar")
    --print( sl:get_count() )
    --sl:dump()
    --print( sl:get_rank( 5, "foo" ) )
    --local t = sl:get_rank_range(1, 3)
    --for k, v in pairs( t ) do
    --    print( k, v)
    --end


    --local p = getPlayer(1120501)
    --p:add_report( 2, {foo="bar"})
    --local db = dbmng:getOne()
    --db.farm:delete( { pid = 0 } )

    --to_tool(0, {type="chat", cmd="create_chat", user="liuxiang", host= CHAT_HOST, password = "liuxiang"})
    --to_tool(0, {type = "chat", cmd = "create_room", name = "666", server="conference."..CHAT_HOST, host = CHAT_HOST })
    --to_tool(0, {type = "chat", cmd = "send_invite", name = "666", service="conference."..CHAT_HOST, users = {"650000@war_x.org"} })
    --local t = {a="hel", b={[-1]="hello"}}
    --gPendingInsert.test[2] = t
    --gPendingInsert.test[3] = {a=1}
    --local ply = getPlayer(590000)
    --ply:on_day_pass()

--    local db = dbmng:getOne()
--    local info = db.troop:findOne({_id=49})
--    for k, v in pairs(info.arms) do
--        print("type, val=", type(k), k)
--        print("type, val=", type(v), v)
--    end
--

    --local t = {_id=1, foo="bar"}
    --gPendingInsert.test[1] = t
    --gPendingSave.test[1].hello = "world"
    ----gPendingDelete.test[1] = 0
    ----
    --t = {_id=1, hello="world"}
    --gPendingInsert.test[1] = t
    --
    --Rpc:testCross({ pid=9, gid=_G.GateSid }, 1, "hello" )

    --local armA = { }
    --local armB = { live_soldier = {[1001]=100, [2001]=100}, dead_soldier={[2001]=49, [4001]=1}, heros={0,0,0,0}, B="B"}
    --troop_t.do_add_arm_to(armA, armB)
    --dumpTab(armB, "merge")

    --local p = getPlayer(590000)
    --local code, result = p:qryCross(270000, "test_command", {a=1, foo="bar"})
    --print("qryCross", code)
    --dumpTab(result, "qryCross")
end

function test4()
    dumpTab(union_hall_t.union_battle_room)
end

function addsoldier(eid)
    local ap = get_ety(eid)
    ap.my_troop_id = 0
    if ap.my_troop_id == 0 then
        local troop = troop_mng.create_troop(eid, 0, TroopAction.DefultFollow, 0, 0, 0, 0)
        troop.owner_pid = ap.pid
        ap.my_troop_id = troop._id
        ap.busy_troop_ids = {}
        local arm = arm_t.new()
        troop:add_arm(ap.pid, arm)
    end
    ap:inc_arm(1001, 100000)
    ap:inc_arm(2001, 100000)
    ap:inc_arm(3001, 100000)
    ap:inc_arm(4001, 100000)

end

function check_pending()
    player_t.check_pending()
    build_t.check_pending()
    hero_t.check_pending()
    union_t.check_pending()
    room.check_pending()
    npc_city.check_pending()

    --dirty_sync()
end

function mem_info()
    local heap, mem, mlua, mbuf, mobj, nbuf, nply, nres, ntroop, nmonster, nothers, neye = c_get_engine_mem()
    INFO("[MEM_INFO], heap=%d, mem=%d, lua=%d, mbuf=%d, mobj=%d", heap, mem, mlua, mbuf, mobj)
    INFO("[MEM_DETAIL], mem=%d, lua=%d, mbuf=%d, mobj=%d, nbuf=%d, nply=%d, nres=%d, ntroop=%d, nmonster=%d, neye=%d", mem, mlua, mbuf, mobj ,nbuf, nply, nres, ntroop, nmonster, neye)
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
                if not _cache[t._id] then _cache[t._id] = {} end
                _cache[t._id][k] = v
                _cache[t._id]._n_ = nil
            else
                rawset(t, k, v)
            end
        end
    }

    function new(t)
        if not t._id then return MARK( "no _id") end
        _cache[t._id] = t
        local self = {_pro=t}
        setmetatable(self, mt)
        self:init()

        --in order to detect add event when check_pending()
        -- Hx@2016-01-07 : do it in init() by your self. some module did not want that
        --_cache[self._id] = self._pro

        return self
    end

    function init(self)
        --override
    end

    function check_pending()
        local db = dbmng:tryOne(1)
        if not db then return end
        local hit = false
        local cur = gFrame
        for _id, chgs in pairs(_cache) do
            if not chgs._n_ then
                on_check_pending(db, _id, chgs)
                chgs._n_ = cur
                hit = true
            end
        end
        if hit then get_db_checker(db, cur)() end
    end

    function on_check_pending(db, _id, chgs)
        WARN("override this!!!")
        --override
    end

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
    if fmt then lwarn( string.format(fmt, ...).. " ".. debug.stack(1))
    else lwarn(debug.stack(1)) end
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

--timer.new("tlog", 1)
