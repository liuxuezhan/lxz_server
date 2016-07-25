
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


function do_reload()
    do_load("game")

    do_load("resmng")
    do_load("common/define")
    do_load("common/tools")
    do_load("common/protocol")

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

    do_load("build_t")
    do_load("arm_t")

    do_load("player/player_troop")
    do_load("troop_t")
    do_load("troop_mng")

    --do_load("player/player_troop2")
    --do_load("troop2_t")
    --do_load("troop_mng2")

    do_load("heromng")
    do_load("hero/hero_t")

    do_load("fight")
    do_load("farm")
    do_load("restore_handler")

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

    --do_load("frame/zset")
    --require("test")

    --c_start_debug(10023)
    do_load("gmmng")
end

function reload()
    do_reload()
    --action(do_reload)
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

g_eid_idx = g_eid_idx or {}
function get_eid(mode)
    local base = mode * 0x010000
    local idx = g_eid_idx[ mode ] or 0
    for i = 1, 65530, 1 do
        idx = idx + 1
        if idx >= 0x010000 then idx = 0 end
        local id = base + idx
        if not gEtys[ id ] then
            g_eid_idx[ mode ] = idx
            return id
        end
    end
end

function mark_eid(eid)
    local mode = math.floor(eid / 65536)
    local idx = math.floor(eid % 65536)
    local cur = g_eid_idx[ mode ]

    if not cur then
        g_eid_idx[ mode ] = idx
    else
        if idx > cur then g_eid_idx[ mode ] = idx end
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

function get_eid_troop()
    return get_eid(EidType.Troop)
end

function get_eid_monster()
    local base = EidType.Monster * 0x010000
    local idx = g_eid_idx[EidType.Monster] or 0
    for i = 1, 65519, 1 do  --65519之后是NPC怪物特殊id
        idx = idx + 1
        if idx > 65519 then idx = 0 end
        local id = base + idx
        if not gEtys[ id ] then
            g_eid_idx[EidType.Monster] = idx
            return id
        end
    end
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
    return math.floor(eid / 65536)
end

function get_ety(eid)
    return gEtys[ eid ]
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

        elseif is_lost_temple(e) then
            gEtys[ eid ] = nil
            c_rem_ety(eid)
            local db = dbmng:getOne()
            db.lost_temple:delete({_id=e.eid})
            if e.marktm then gPendingDelete.monster[ eid ] = 0 end
        elseif is_union_building(e) then
            local u = unionmng.get_union(e.uid)
            union_build_t.remove_build(u,e.idx)

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
    local db = dbmng:getOne()
    db.farm:delete( { pid = 0 } )

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
        ERROR("[Rpc]: onError, not found, func:%s, code:%s, reason:%s", funcname, code, reason)
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


