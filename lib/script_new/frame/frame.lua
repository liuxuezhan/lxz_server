
function thanks()
    local t = {}
    table.insert(t, [[                   _ooOoo_]])
    table.insert(t, [[                  o8888888o]])
    table.insert(t, [[                  88" . "88]])
    table.insert(t, [[                  (| -_- |)]])
    table.insert(t, [[                  O\  =  /O]])
    table.insert(t, [[               ____/`---'\____]])
    table.insert(t, [[             .'  \\|     |//  `.]])
    table.insert(t, [[            /  \\|||  :  |||//  \]])
    table.insert(t, [[           /  _||||| -:- |||||-  \]])
    table.insert(t, [[           |   | \\\  -  /// |   |]])
    table.insert(t, [[           | \_|  ''\---/''  |   |]])
    table.insert(t, [[           \  .-\__  `-`  ___/-. /]])
    table.insert(t, [[         ___`. .'  /--.--\  `. . __]])
    table.insert(t, [[      ."" '<  `.___\_<|>_/___.'  >'"".]])
    table.insert(t, [[     | | :  `- \`.;`\ _ /`;.`/ - ` : | |]])
    table.insert(t, [[     \  \ `-.   \_ __\ /__ _/   .-` /  /]])
    table.insert(t, [[======`-.____`-.___\_____/___.-`____.-'======]])
    table.insert(t, [[                   `=---=']])
    table.insert(t, [[^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^]])

    for k, v in ipairs(t) do
        print(v)
    end
    INFO("[GameStart], map=%d", _G.gMapID)
end


gNetPt = {
    NET_PING        = 1,
    NET_PONG        = 2,
    NET_ADD_LISTEN  = 3,
    NET_ADD_INCOME  = 4,
    NET_CMD_CLOSE   = 5,
    NET_MSG_CLOSE   = 6 ,
    NET_CMD_STOP    = 7,
    NET_SET_MAP_ID  = 8,
    NET_SET_SRV_ID  = 9,
    NET_MSG_CONN_COMP = 10 ,
    NET_MSG_CONN_FAIL  = 11,
    NET_ECHO = 12,
    NET_CHG_SRV = 13,
    NET_CERTIFY = 14,
    NET_SEND_MUL = 15,
}

gDbNum = 1

function loadMod()
    require("frame/tools")
    dofile("../etc/config.lua")

    if config.Release then

    else
        require("frame/debugger")
    end

    require("frame/socket")

    if config.NO_DB then
        require("nodb/_conn")
        require("nodb/_dbmng")
        _G.mongo = require("nodb/_mongo")
    else
        require("frame/conn")
        require("frame/dbmng")
        _G.mongo = require("frame/mongo")
    end

    require("frame/crontab")
    require("frame/timer")

    _G.Json = require("frame/json")

    -- rpc
    require("frame/class")

    doLoadMod("packet", "frame/rpc/packet")
    doLoadMod("MsgPack", "frame/MessagePack")
    doLoadMod("Array", "frame/rpc/array")

    doLoadMod("Struct", "frame/rpc/struct")
    doLoadMod("RpcType", "frame/rpc/rpctype")
    doLoadMod("Rpc", "frame/rpc/rpc")

    require("frame/player_t")
end

function handle_dbg(sid)
    local co = getCoroPend("dbg", sid)
    if not co then
        co = createCoro("dbg")
        gCoroPend[ "dbg" ][ sid ] = co
    end
end

function handle_network(sid)
    local pktype = pullInt()
    local p = gConns[ sid ]
    if p then
        if pktype ==  gNetPt.NET_MSG_CLOSE then
            LOG("handle_network, sid=%d, pktype=NET_MSG_CLOSE", sid)
            --gConns[ sid ] = nil
            p:onClose()

        elseif pktype == gNetPt.NET_MSG_CONN_COMP then
            p:onConnectOk()

        elseif pktype == gNetPt.NET_MSG_CONN_FAIL then
            LOG("handle_network, sid=%d, pktype=NET_MSG_CONN_FAIL", sid)
            --gConns[ sid ] = nil
            p:onConnectFail()
        end
    end
end

function handle_db(sid)
    mongo.recvReply(sid)
end

gTagFun = {}
gTagFun[1] = handle_network
gTagFun[2] = handle_db
gTagFun[3] = handle_dbg

function action(func, ...)
    table.insert(gActions, {func, {...}})
    begJob()
end


function do_threadAction()
    local co = coroutine.running()
    while true do
        while #gActions > 0 do
            local node = table.remove(gActions, 1)
            if node[2] then
                node[1](unpack(node[2]))
            else
                node[1]()
            end
        end
        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadAction, i should go away, %s", co)
            return
        end
        putCoroPool("action")
    end
end

function do_threadTimer()
    local co = coroutine.running()

    local sn, tag
    while true do
        sn = false
        while true do
            sn, tag = pullTimer()
            if not sn then
                putCoroPool("timer")
            else
                --LOG("threadTimer, sn=%d", sn)
                break
            end
        end
        timer.callback(sn, tag)

        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadTimer, i should go away, %s", co)
            return
        end

    end
end

function do_threadRoi()
    local co = coroutine.running()

    local msgid, d0, d1, d2, d3, eids
    while true do
        while true do
            msgid, d0, d1, d2, d3, eids = c_pull_msg_roi()
            if not msgid then
                putCoroPool("roi")
            else
                --LOG("threadTimer, sn=%d", sn)
                break
            end
        end
        if do_roi_msg then 
            do_roi_msg(msgid, d0, d1, d2, d3, eids) 
        end

        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadRoi, i should go away, %s", co)
            return
        end
    end
end

gActionQue = {}
gActionCur = {}
function do_threadPK()
    local co = coroutine.running()

    while true do
        local gateid, tag
        while true do
            gateid, tag = pullNext()
            if gateid then
                break
            else
                local dels = {}
                for pid, as in pairs(gActionQue) do
                    local tmMark = gActionCur[ pid ]
                    if not tmMark or gTime - tmMark > 2 then -- maybe something wrong, so leave the gActionCur unclear
                        if #as == 0 then
                            table.insert(dels, pid)
                        else
                            while #as > 0 do
                                local v = table.remove(as, 1)
                                gActionCur[ pid ] = gTime
                                LOG("%d, RpcR, pid=%d, func=%s, delay do", gFrame, pid, v[1])
                                LOG("RpcR, pid=%d, func=%s", pid, v[1])
                                local p = getPlayer(pid)
                                if p then player_t[ v[1] ](p, unpack(v[2]) ) end
                                gActionCur[ pid ] = nil
                            end
                            table.insert(dels, pid)
                        end
                    end
                end
                for k, v in pairs(dels) do
                    gActionQue[ v ] = nil
                end
                putCoroPool("pk")
            end
        end

        if tag then
            if gTagFun[ tag ] then
                gTagFun[ tag ](gateid)
            end
        else
            local pid = pullInt()
            local pktype = pullInt()
            --print(rpc.localF[pktype].type)
            local fname, args = Rpc:parseRpc(packet, pktype)
            if fname then
                if pid == 0 then
                    LOG("RpcR, pid=%d, func=%s", pid, fname)
                    player_t[ fname ](_G.gAgent, unpack(args) )

                elseif pid < 10000 then
                    LOG("RpcAR, pid:%s, func=%s", pid, fname)
                    agent_t[ fname ]( {pid=pid}, unpack( args ) )

                else
                    local p = getPlayer(pid)
                    if p then
                        p.gid = gateid
                        if gActionQue[ pid ] then
                            LOG("%d, RpcR, pid=%d, func=%s, in queue", gFrame, pid, fname)
                            table.insert(gActionQue[ pid ], {fname, args})
                        elseif gActionCur[ pid ] then
                            LOG("%d, RpcR, pid=%d, func=%s, new queue", gFrame, pid, fname)
                            gActionQue[ pid ] = { {fname, args} }
                        else
                            LOG("RpcR, pid=%d, func=%s", pid, fname)
                            gActionCur[ pid ] = gTime
                            player_t[ fname ](p, unpack(args) )
                            gActionCur[ pid ] = nil
                        end
                    else
                        LOG("RpcR, pid=%d, func=%s, no player", pid, Rpc.localF[pktype].name)
                    end
                end
            end
        end

        if gCoroBad[ co ] then
            gCoroBad[ co ] = nil
            LOG("Coro, threadPk, i should go away, %s", co)
            return
        end
    end
end

function remote_func(map_id, func, param)
    local id = getSn("qryCross")
    local co = coroutine.running()
    print("debug remote call", map_id, func, param)
    Rpc:callAgent(map_id, "agent_syn_call", id, func, param)
    return putCoroPend("syncall", id)
end

function remote_cast(map_id, func, param)
    local id = getSn("qryCross")
    print("debug remote call", map_id, func, param)
    Rpc:callAgent(map_id, "agent_syn_call", id, func, param)
end

function threadAction()
    if _ENV then
        xpcall(do_threadAction, function(e)
            WARN("[ERROR]%s", e)
            print(c_get_top())
        end)
    else
        do_threadAction()
    end
end

function threadTimer()
    if _ENV then
        xpcall(do_threadTimer, function(e) WARN("[ERROR]%s", e) end)
    else
        do_threadTimer()
    end
end

function threadRoi()
    if _ENV then
        xpcall(do_threadRoi, function(e) WARN("[ERROR]%s", e) end)
    else
        do_threadRoi()
    end
end

function threadPk()
    if _ENV then
        xpcall(do_threadPK, function(e) WARN("[ERROR]%s", e) end)
    else
        do_threadPK()
    end
end

function check_db_connect()
    for k, v in pairs(gConns) do
        if v.state ~= 1 then
            return false
        end
    end
    return true
end

function wait_db_connect()
    while not check_db_connect() do
        wait(1)
    end
end

function frame_init()
    wait_db_connect()

    INFO("$$$ done load_sys_config")
    load_uniq()

    load_sys_config()

    INFO("$$$ done load_uniq")

    gInit = "InitFrameDone"
    begJob()

    c_tlog_start( "../etc/tlog.xml" )
end

function clean_replay()
    local db = dbmng:getOne()
    local time = gTime - (86400 * 3)
    db.replay:delete({["1"] = {["$lt"] = time}})
end

function main_loop(sec, msec, fpk, ftimer, froi, deb)
    gFrame = gFrame + 1
    --LOG("gFrame = %d, fpk=%d, ftimer=%d, froi=%d, deb=%d, gInit=%s", gFrame, fpk, ftimer, froi, deb, gInit or "unknown")

    if deb > 0 then
        if pause then
            pause("debug in main_loop")
        else
            os.exit(-1)
        end
    end

    gTime = sec
    gMsec = msec

    if gInit then
        --real_gTime = sec
        --real_gMsec = msec

        if gInit == "StateBeginInit" then
            gInit = "InitFrameAction"
            action(frame_init)

        elseif gInit == "InitFrameDone" then
            gInit = "InitGameAction"
            action(restore_game_data)

        elseif gInit == "InitCompensate" then
            local real = os.time()
            if gCompensation < real then
                gCompensation = gCompensation + 1
                c_time_step(gCompensation)
                --WARN("Compensation, real=%d, now=%d, diff=%d", real, gCompensation, real - gCompensation)
            else
                gCompensation = nil
                c_time_release()
                WARN("Compensation, real=%d, finish", real)
                gInit = "InitGameDone"
            end

        elseif gInit == "InitGameDone" then
            conn.toGate(config.GateHost, config.GatePort)
            crontab.initBoot()
            clean_replay() --清理战斗录像

            if config.GatePort == 8002 then _G.g_warx = true end

            local hit = false
            for k, v in pairs(timer._sns) do
                if v.what == "cron" then
                    hit = true
                    break
                end
            end

            if not hit then
                local nextCron = 60 - (gTime % 60) + 30
                timer.new("cron", nextCron)
                timer.new("monitor", 1, 1)
            end

            if init_game_data then init_game_data() end

            gInit = "InitConnectGate"

        elseif gInit == "InitConnectGate" then
            if GateSid then
                thanks()
                gInit = nil
            end
        end

        begJob()
    end

    if fpk == 1 then
        while true do
            local co = getCoroPool("pk")
            local flag, what, id = coroutine.resume(co)
            if flag then
                if what == "ok" then break end
            else
                LOG("ERROR %s", what)
            end
        end
    end

    if ftimer == 1 then
        while true do
            local co = getCoroPool("timer")
            local flag, what, id = coroutine.resume(co)
            if flag then
                if what == "ok" then break end
            else
                LOG("ERROR %s", what)
            end
        end
    end

    if froi == 1 then
        while true do
            local co = getCoroPool("roi")
            local flag, what, id = coroutine.resume(co)
            if flag then
                if what == "ok" then break end
            else
                LOG("ERROR %s", what)
            end
        end
    end

    if #gActions > 0 then
        local co = getCoroPool("action")
        local flag = coroutine.resume(co)
    end

    while #gCoroWait > 0 do
        local t = gCoroWait[1]
        if t[2] > gFrame then break end
        --LOG("dowait, %d, %d", t[2], gFrame)
        table.remove(gCoroWait,1)
        coroutine.resume(t[1])
    end

    if gCompensation then
        if ftimer == 1 or froi == 1 or ftimer == 1 then
            local real = os.time()
            print(string.format("Compensation, %s, -> %s, diff=%d", os.date("%c",gTime), os.date("%c"), real-gTime))
            check_pending()
            global_save()
        end
    else
        check_pending()
        global_save()
    end

    --gPendingSave.test0[ gFrame + 0 ].hello = gPlys
    --gPendingSave.test1[ gFrame + 1 ].hello = timer._sns
    --gPendingSave.test2[ gFrame + 2 ].hello = "world"
    --begJob()

end



--so when you want to save data, just write down like
--gPendingSave.mail[ "1_270130" ].tm_lock = gTime
function global_save()
    local db = dbmng:tryOne(1)
    if db then
        local update = false
        local cur = gFrame
        for tab, doc in pairs(gPendingSave) do
            local cache = doc.__cache
            for id, chgs in pairs(doc) do
                if chgs ~= cache then
                    if not chgs._a_ then
                        local oid = chgs._id
                        chgs._id = id
                        db[ tab ]:update({_id=id}, {["$set"] = chgs }, true)
                        chgs._id = oid
                        print( "[DB], update", tab, id, "global" )

                    else
                        if chgs._a_ == 0 then
                            db[ tab ]:delete({_id=id})
                            print( "[DB], delete", tab, id, "global" )

                        else
                            local oid = chgs._id
                            rawset( chgs, "_a_", nil )
                            rawset( chgs, "_id", id )
                            db[ tab ]:update({_id=id}, chgs, true)
                            rawset( chgs, "_a_", 1)
                            rawset( chgs, "_id", oid )
                            print( "[DB], create", tab, id, "global" )
                        end
                    end
                    update = true
                    rawset( chgs, "_n_", cur )
                    doc[ id ] = nil
                    cache[ id ] = chgs
                end
            end
        end
        if update then check_save(db, cur)() end
    end
end


function check_save(db, frame)
    local f = function()
        if gFrame - frame > 10 then WARN( "[DB], check, elaps %d frame", gFrame - frame ) end

        local info = db:runCommand("getLastError")
        if info.ok then
            local code = info.code
            for tab, doc in pairs(gPendingSave) do
                local cache = doc.__cache
                local dels = {}
                for id, chgs in pairs(cache) do
                    if chgs._n_ == frame then
                        rawset( chgs, "_n_", nil )
                        table.insert(dels, id)
                        if code then
                            WARN( "mongo_error, %s", tips..id )
                            local tips = string.format("error: upd_tab %s:", tab)
                            dumpTab(chgs, tips..id)
                        end

                    elseif chgs._n_ < frame - 10 then
                        WARN("mongo_error, %s:%s, %s, %s, %s", tab, id, chgs._n_, frame, gFrame)
                        dumpTab( chgs, "mongo_error" )
                        rawset( chgs, "_n_", nil )
                        doc[ id ] = chgs
                        table.insert(dels, id)

                    end
                end
                if #dels > 0 then
                    for _, v in pairs(dels) do
                        cache[ v ] = nil
                    end
                end
            end

            if info.code then
                WARN( "mongo_error, frame=%d, gFrame=%d", frame, gFrame )
                dumpTab(info, "check_save")
            end
        end
    end
    return coroutine.wrap(f)
end


function wait(nframe)
    nframe = nframe or 1
    if nframe < 1 then nframe = 1 end
    nframe = nframe + gFrame

    local co = coroutine.running()
    for k, v in ipairs(gCoroWait) do
        if nframe <= v[2] then
            table.insert(gCoroWait, k, {co, nframe})
            coroutine.yield("wait")
            return
        end
    end
    table.insert(gCoroWait, {co, nframe})
    coroutine.yield("wait")
end

function init_pending()
    __mt_rec = {
        __index = function (self, recid)
            local t = self.__cache[ recid ]
            if t then
                self.__cache[ recid ] = nil
                t._n_ = nil
            else
                t = {}
            end
            self[ recid ] = t
            return t
        end
    }
    __mt_tab = {
        __index = function (self, tab)
            local t = { __cache={} }
            setmetatable(t, __mt_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingSave, __mt_tab)


    __mt_del_rec = {
        __newindex = function (t, k, v)
            gPendingSave[ t.tab_name ][ k ]._a_ = 0
        end
    }
    __mt_del_tab = {
        __index = function (self, tab)
            local t = {tab_name=tab}
            setmetatable(t, __mt_del_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingDelete, __mt_del_tab)

    __mt_new_rec = {
        __newindex = function (t, k, v)
            gPendingSave[ t.tab_name ][ k ] = v
            v._a_ = 1
        end
    }
    __mt_new_tab = {
        __index = function (self, tab)
            local t = {tab_name=tab}
            setmetatable(t, __mt_new_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingInsert, __mt_new_tab)

end


function init(sec, msec)
    gTime = math.floor(sec)
    gMsec = math.floor(msec)
    gMapID = getMap()
    gMapNew = 1

    math.randomseed(sec)

    gCoroPool = { ["pk"] = {}, ["timer"] = {}, ["action"] = {}, ["roi"] = {} }
    gCoroPend = { ["db"] = {}, ["rpc"] = {}, ["roi"] = {}, ["syncall"] = {} }
    gCoroWait = {}

    gActions = {}
    gSns = {}
    gFrame = 0
    gConns = {}
    gPlys = {}
    gAccs = {}
    gAccounts = {}


    gEids = {}
    gEtys = {}

    setmetatable( gEids, { __mode="v" } )
    setmetatable( gEtys, 
        { __newindex=function( tab, eid, obj) 
                rawset(tab, eid, obj)
                local idx = math.floor( eid / 4096 )
                gEids[ idx ] = obj 
            end
        }
    )

    gPendingSave = {}
    gPendingDelete = {}
    gPendingInsert = {}
    init_pending()

    --__mt_rec = {
    --    __index = function (self, recid)
    --        local t = self.__cache[ recid ]
    --        if t then
    --            self.__cache[ recid ] = nil
    --            t._n_ = nil
    --        else
    --            t = {}
    --        end
    --        self[ recid ] = t
    --        return t
    --    end
    --}
    --__mt_tab = {
    --    __index = function (self, tab)
    --        local t = { __cache={} }
    --        setmetatable(t, __mt_rec)
    --        self[ tab ] = t
    --        return t
    --    end
    --}
    --setmetatable(gPendingSave, __mt_tab)


    gInit = "StateBeginInit"
    loadMod()

    require("game")

    load_game_module()

    LOG("start: gTime = %d, gMsec = %d", gTime, gMsec)

    Rpc:init("server")
    Rpc.localF[ 6 ] = Rpc.localF[ hashStr("onBreak") ]


    if config.Tips then
        c_init_log(config.Tips)
    end

    --local dbname = string.format("warx_%d", gMapID)
    local name = config.Game or "warx"
    local dbname = string.format("%s_%d", name, gMapID)
    for i = 1, gDbNum, 1 do
        conn.toMongo(config.DbHost, config.DbPort, dbname)
    end

    local dbnameG = string.format("%sG", name)
    if config.DbHostG then
        conn.toMongo(config.DbHostG, config.DbPortG, dbnameG, "Global")
    end

    begJob()

    return 1
end


function createCoro(what)
    if what == "pk" then
        return coroutine.create(threadPk)
    elseif what == "timer" then
        return coroutine.create(threadTimer)
    elseif what == "action" then
        return coroutine.create(threadAction)
    elseif what == "roi" then
        return coroutine.create(threadRoi)
    end
end

function getCoroPool(what)
    if #gCoroPool[ what ] > 0 then
        local co = table.remove(gCoroPool[ what ])
        return co
    else
        local co = createCoro(what)
        return co
    end
end

function putCoroPool(what)
    local co = coroutine.running()
    local pool = gCoroPool
    if #pool < 10 then table.insert(gCoroPool[ what ], co) end
    coroutine.yield("ok")
end

function getCoroPend(what, id)
    local co = gCoroPend[ what ][ id ]
    if co then
        gCoroPend[ what ][ id ] = nil
        if type(co) == "table" then return unpack(co)
        else return co end
    end
end


function putCoroPend(what, id, extra)
    local co = coroutine.running()
    if extra then gCoroPend[ what ][ id ] = { co, extra }
    else gCoroPend[ what ][ id ] = co end
    return coroutine.yield(what)
end


function addPendSave(tab, id, key, val)
    local g = gPendingSave
    if not g then
        g = {}
        gPendingSave = g
    end

    local t = g[ tab ]
    if not t then
        t = {}
        g[ tab ] = t
    end

    local r = t[ id ]
    if not r then
        r = {}
        t[ id ] = r
    end

    r[ key ] = val
end

function getPlayer(pid)
    if pid then
        if pid >= 10000 then
            return gPlys[ pid ]
        elseif pid > 0 then
            return { pid=pid }
        end
    end
end

function load_sys_config()
    local db = dbmng:getByTips("Global")
    local info = db.config:findOne({_id=gMapID})
    if info then
        gSysConfig = info
    else
        gSysConfig = {_id=gMapID, create=gTime}
        db.config:insert(gSysConfig)
        if begin_new_map then
            begin_new_map()
        end
    end
end

function load_uniq()
    local db = dbmng:getOne()
    local info = db.uniq:find({})
    gUniqs = {}
    if info then
        while info:hasNext() do
            local b = info:next()
            gUniqs[ b._id ] = b
        end
    end
end

function getId(what)
    if config.NO_DB then
        gUniqs[what] = (gUniqs[what] or 10000) + 1
        return gUniqs[what]
    end

    local t = gUniqs[ what ]
    if not t then
        t = {_id=what, at=0, sn=0, wait=1}
        gUniqs[ what ] = t
        local idx = getAutoInc(what)
        t.at=idx
        t.wait = 0
        db = dbmng:getOne()
        db.uniq:insert(t)
    end

    for i = 1, 1000, 1 do
        if t.wait == 0 or not t.wait then break end
        wait(1)
    end

    if t.wait == 1 then return end

    if t.sn >= 10000 then
        t.wait = 1
        local idx = getAutoInc(what)
        t.at=idx
        t.sn = 0
        t.wait = 0
    end

    local id = t.at * 10000 + t.sn
    t.sn = t.sn + 1

    --addPendSave("uniq", what, "sn", t.sn)
    --addPendSave("uniq", what, "at", t.at)
    --addPendSave("uniq", what, "state", t.state)

    local n = gPendingSave.uniq[ what ]
    n.sn = t.sn
    n.at = t.at
    n.state = t.state

    return id
end

function getAutoInc(what)
    --local db = dbmng:getOne(0)
    local db = dbmng:getByTips("Global")
    LOG("getAutoInc, getdb after")
    local r = db:runCommand("findAndModify", "uniq", "query", {_id=what}, "update", {["$inc"]={sn=1}}, "new", true, "upsert", true)
    LOG("getAutoInc, runCommand after")
    dumpTab(r, "getAutoInc")
    return r.value.sn
end


-- change to new gate
-- 1. rpc, send_mul
-- 2. first packet
--
