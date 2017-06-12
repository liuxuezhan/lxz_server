
if not gCoroMark then
    gCoroMark = {}
    setmetatable( gCoroMark, { __mode="k" } )
end

function coro_mark_create( co, name )
    local node = gCoroMark[ co ]
    if not node then
        node = {}
        gCoroMark[ co ] = node
        node.action = "create"
    end
    node.tick = gTime
    node.name = name
end


function coro_mark( co, action )
    local node = gCoroMark[ co ]
    if not node then
        node = {}
        gCoroMark[ co ] = node
        node.name = "unknown"
        node.action = "unknown"
    end
    node.tick = gTime
    node.action = action
end


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
        WARN( v )
    end
    INFO("[GameStart], map=%s,time=%s", tostring(config.SERVER_ID),tms2str(gTime))
    if config.TlogSwitch then 
        local info = table.concat({"GameStart",config.SERVER_ID,tms2str(gTime)}, '|')
        c_tlog(info)
    end
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

--  require("frame/socket")

    if config.NO_DB then
        require("nodb/_conn")
        require("nodb/_dbmng")
        _G.mongo = require("nodb/_mongo")
    else
        require("frame/conn")
        require("warx_pub/dbmng")
    end

    require("frame/crontab")
    require("frame/timer")

    _G.Json = require("frame/json")

    -- rpc
    require("frame/class")

    doLoadMod("packet", "frame/rpc/packet")
    doLoadMod("MsgPack", "frame/MessagePack")
    doLoadMod("Array", "warx_pub/rpc/array")
    doLoadMod("Struct", "warx_pub/rpc/struct")
    doLoadMod("RpcType", "warx_pub/rpc/rpctype")
    doLoadMod("Rpc", "warx_pub/rpc/rpc")



    --if config.Game ~= "actx" then
    --    require("frame/player_t")
    --end

    require("frame/perfmon")
    require("frame/snapshot")
    require("frame/snapshot_diff")
    require("frame/mongo_save_mng")
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
    pktype = gNetPt.NET_MSG_CONN_COMP 
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
            gateid, tag = 1,1 
            if gateid then
                break
            else
                local nframe = gFrame
                local pid = nil
                local as = nil
                while true do
                    pid, as = next( gActionQue, pid )
                    if not pid then break end

                    local tmMark = gActionCur[ pid ]
                    if not tmMark or gTime - tmMark > 2 then -- maybe something wrong, so leave the gActionCur unclear
                        if #as == 0 then
                            gActionQue[ pid ] = nil
                        else
                            while #as > 0 do
                                local v = table.remove(as, 1)
                                gActionCur[ pid ] = gTime
                                lxz("RpcR, pid=%d, func=%s", pid, v[1])
                                local p = getPlayer(pid)
                                if p then player_t[ v[1] ](p, unpack(v[2]) ) end
                                gActionCur[ pid ] = nil
                            end
                            if gFrame ~= nframe then pid = nil end
                        end
                    end
                end

                putCoroPool("pk")
            end
        end

        if tag then
            --[[
            if gTagFun[ tag ] then
                gTagFun[ tag ](gateid)
            end
            --]]
            for sid, _ in pairs(gConns) do
                gTagFun[ 1 ](sid)
                gTagFun[ 2 ](sid)
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
                        rawset( p, "gid", gateid )
                        rawset( p, "tick", gTime )

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
    local id = 0 --getSn("qryCross")
    print("debug remote call", map_id, func, param)
    Rpc:callAgent(map_id, "agent_syn_call", id, func, param)
end

function threadAction()
    if _ENV then
        xpcall(do_threadAction, STACK )
    else
        do_threadAction()
    end
end

function threadTimer()
    if _ENV then
        xpcall(do_threadTimer, STACK )
    else
        do_threadTimer()
    end
end

function threadRoi()
    if _ENV then
        xpcall(do_threadRoi, STACK )
    else
        do_threadRoi()
    end
end

function threadPk()
    if _ENV then
        xpcall(do_threadPK, STACK )
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

function wait_connect_complete()
    while true do
        local ok = true
        for k, v in pairs( gConns ) do
            if v.state ~= 1 then
                ok = false
                break
            end
        end
        if not ok then 
            wait(1)
        end
    end
end

function frame_init()
    while true do
        local ok = true
        for k, v in pairs( gConns ) do
            if v.state ~= 1 then
                WARN( "wait connect %s, %s", v.host, v.port )
                ok = false
                break
            end
        end
        if ok then break end
        wait(1)
    end

    INFO("### load_uniq")
    load_uniq()
    INFO("$$$ load_uniq")

    INFO("### load_sys_config")
    load_sys_config()
    INFO("$$$ load_sys_config")

    gInit = "InitFrameDone"
    begJob()

    if config.TlogSwitch then 
        c_tlog_start( "../etc/tlog.xml" )
    end


end

function clean_replay()
    local db = dbmng:getOne()
    if db then
        local time = gTime - (86400 * 3)
        db.replay:delete({["1"] = {["$lt"] = time}})
    end
end

local SignalDefine = {
	SIGHUP		= 1	, --/* Hangup (POSIX).  */
	SIGINT		= 2	, --/* Interrupt (ANSI).  */
	SIGQUIT		= 3	, --/* Quit (POSIX).  */
	SIGILL		= 4	, --/* Illegal instruction (ANSI).  */
	SIGTRAP		= 5	, --/* Trace trap (POSIX).  */
	SIGABRT		= 6	, --/* Abort (ANSI).  */
	SIGIOT		= 6	, --/* IOT trap (4.2 BSD).  */
	SIGBUS		= 7	, --/* BUS error (4.2 BSD).  */
	SIGFPE		= 8	, --/* Floating-point exception (ANSI).  */
	SIGKILL		= 9	, --/* Kill, unblockable (POSIX).  */
	SIGUSR1		= 10, --/* User-defined signal 1 (POSIX).  */
	SIGSEGV		= 11, --/* Segmentation violation (ANSI).  */
	SIGUSR2		= 12, --/* User-defined signal 2 (POSIX).  */
	SIGPIPE		= 13, --/* Broken pipe (POSIX).  */
	SIGALRM		= 14, --/* Alarm clock (POSIX).  */
	SIGTERM		= 15, --/* Termination (ANSI).  */
	SIGSTKFLT	= 16, --/* Stack fault.  */
	SIGCHLD		= 17, --/* Child status has changed (POSIX).  */
	SIGCONT		= 18, --/* Continue (POSIX).  */
	SIGSTOP		= 19, --/* Stop, unblockable (POSIX).  */
	SIGTSTP		= 20, --/* Keyboard stop (POSIX).  */
	SIGTTIN		= 21, --/* Background read from tty (POSIX).  */
	SIGTTOU		= 22, --/* Background write to tty (POSIX).  */
	SIGURG		= 23, --/* Urgent condition on socket (4.2 BSD).  */
	SIGXCPU		= 24, --/* CPU limit exceeded (4.2 BSD).  */
	SIGXFSZ		= 25, --/* File size limit exceeded (4.2 BSD).  */
	SIGVTALRM	= 26, --/* Virtual alarm clock (4.2 BSD).  */
	SIGPROF		= 27, --/* Profiling alarm clock (4.2 BSD).  */
	SIGWINCH	= 28, --/* Window size change (4.3 BSD, Sun).  */
	SIGIO		= 29, --/* I/O now possible (4.2 BSD).  */
	SIGPWR		= 30, --/* Power failure restart (System V).  */
    SIGSYS		= 31, --/* Bad system call.  */
    SIGUNUSED	= 31
}

gTimeDebugOffset = 0

function is_db_ready()
    for k, v in pairs( gConns ) do
        if v.action == "db" then
            if v.state ~= 1 then return false end
        end
    end
    return true
end


function main_loop(sec, msec, fpk, ftimer, froi, signal)
    gFrame = gFrame + 1
    --LOG("gFrame = %d, fpk=%d, ftimer=%d, froi=%d, deb=%d, gInit=%s", gFrame, fpk, ftimer, froi, deb, gInit or "unknown")

    local t1 = c_msec()

    if signal > 0 then
        if signal == SignalDefine.SIGINT then
            if pause then
                pause( "debug in main_loop" )
            else

            end
        elseif signal == SignalDefine.SIGQUIT then
            WARN( "shutdown" )
            gInit = "Shutdown"

        elseif signal == SignalDefine.SIGUSR1 then
            if reload then reload() end

        elseif signal == SignalDefine.SIGUSR2 then
            dofile( "extra.lua" )

        else
            WARN( "SIGNAL, %d", signal )
        end
    end

    gTime = sec + gTimeDebugOffset
    gMsec = msec

    if gInit then
        --real_gTime = sec
        --real_gMsec = msec

        if gInit == "StateBeginInit" then
            gInit = "InitFrameAction"
            action(frame_init)

        elseif gInit == "InitFrameDone" then
            gInit = "InitGameData"
            action( restore_game_data )
        
        elseif gInit == "InitCompensate" then
            local real = c_time_real()
            if gCompensation < real then
                if c_get_troop_count() < 1 then
                    local recent = timer.get_recently()
                    if recent and recent < real then
                        if recent > gCompensation then
                            gCompensation = recent + 1
                            c_time_step(gCompensation)
                        else
                            gCompensation = gCompensation + 1
                            c_time_step(gCompensation)
                        end
                    else
                        gCompensation = real
                        c_time_step(gCompensation)
                    end
                else
                    gCompensation = gCompensation + 1
                    c_time_step(gCompensation)
                end
            else
                set_sys_status( "tick", real )
                gCompensation = nil
                c_time_release()
                WARN("Compensation, real=%d, finish", real)
                gInit = "InitGameDone"
            end

        elseif gInit == "InitGameDone" then
            perfmon.init()
            gInit = "InitCronBoot"
            action( crontab.initBoot )

        elseif gInit == "InitCronBootDone" then
            crontab.initBoot()
            clean_replay() --清理战斗录像

            local hit = false
            for k, v in pairs(timer._sns) do
                if v.what == "cron" then
                    hit = true
                    break
                end
            end

            if not hit then
                local next_cron = gTime + 90
                next_cron = next_cron - ( next_cron % 60 )
                timer.new( "cron", next_cron - gTime )
            end

            if init_game_data then init_game_data() end

       --     c_set_init( 0 )
            thanks()
            gInit = nil
            gBootTime = gTime

            --[[
            local t = debug.tablemark(10)
            for k, v in pairs( t ) do
                INFO( "MarkTable, Start, %s", v )
            end
            --]]
        
        elseif gInit == "Shutdown" then
            set_sys_status( "tick", gTime )
            if on_shutdown then
                action( on_shutdown )
                gInit = "GameSaving"
            else
                gInit = "SystemSaving"
            end

        elseif gInit == "SystemSaving" then
            if gFrame % 100 == 0 then  WARN( "shutdown, frame = %d", gFrame ) end
            if not check_pending_before_shutdown or not check_pending_before_shutdown() then
                local have = is_remain_db_action()
                if not have then
                    c_tlog_stop()
                    WARN( "save done" )
                    c_game_stop()
                else
                    if not gTimeStartSave then
                        gTimeStartSave = gTime
                    elseif gTime - gTimeStartSave > 60 then
                        dump_pending( "save.lua" )
                        c_tlog_stop()
                        WARN( "save to file save.lua" )
                        c_game_stop()
                    end
                end
            end
        end
        begJob()

        if fpk ~= 1 or ftimer ~= 1 or froi ~= 1 then
            --if gInit then WARN( "InitState: %s", gInit ) end
        end

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
        while true do
            local co = getCoroPool("action")
            local flag, what = coroutine.resume(co)
            if flag then
                if what == "ok" then break end
            else
                LOG("ERROR %s", what)
            end
        end
    end

    while #gCoroWait > 0 do
        local t = gCoroWait[1]
        if t[2] > gFrame then break end
        --LOG("dowait, %d, %d", t[2], gFrame)
        table.remove(gCoroWait,1)
        coroutine.resume(t[1])
    end

    -- zhoujy 20161117 在主协程中reload
    if gInit == nil and type(gReloadFunc) == "function" then
        gReloadFunc()
        gReloadFunc = false
    end

    local t2 = c_msec()

    if gCompensation then
        if ftimer == 1 or froi == 1 then
            local real = c_time_real()
            WARN("Compensation, %s, -> %s, diff=%d", os.date("%c",gTime), os.date("%c", real), real-gTime)
            check_pending()
            global_save()
            --check_tool_ack()
        end
    else
        check_pending()
        global_save()
        check_tool_ack()
    end
end


function is_remain_db_action()
    if mongo_save_mng._switch then
        return mongo_save_mng.is_remain_db_action(false)
    end

    local have = false
    for tab, doc in pairs( gPendingSave ) do
        local cache = doc.__cache
        for id, chgs in pairs( doc ) do
            if chgs == cache then
                for k, v in pairs( cache or {} ) do
                    have =true
                    INFO( "shutdown, save %s : %s, n = %d", tab, k, v._n_ or 0 )
                end
            elseif id == "__name" then

            else
                have = true
                INFO( "shutdown, save %s : %s", tab, id )
                return true
            end
        end
    end
    return have
end


function set_sys_status(_type, tms)
end

function ack_tool(pid, sn, data)
    if sn then
        --print("receive tool ack ", sn)
        gPendingToolAck[sn] = nil
    end

    if on_ack_tool then
        -- act的ack_tool接口
        on_ack_tool(pid, sn, data)
    else
        if data.api then
            player_t[data.api](data)
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
    return sn
end

function check_tool_ack()
    local dels = {}
    for k, v in pairs(gPendingToolAck) do
        if gTime - v._t_ >= 100 then
            dels[k] = v
        end
    end

    for k, v in pairs(dels) do
        gPendingToolAck[k] = nil
        resend_to_tool(k, v.info)
    end

end

function resend_to_tool(sn, params)
    LOG("Resend to tool sn= %d ", sn)
    to_tool(sn, params)
end


--so when you want to save data, just write down like
--gPendingSave.mail[ "1_270130" ].tm_lock = gTime
gUpdateCallBack = {}

function registe_update_callback( tab, func )
    gUpdateCallBack[ tab ] = func
end

function global_save()
    if mongo_save_mng._switch then
        mongo_save_mng.by_pid_save_update(gPendingSave, false)
        return
    end

    local db = dbmng:tryOne(1)
    if not db then
        WARN( "no db" )
        return
    end

    local cbs = gUpdateCallBack
    local update = false
    local cur = gFrame
    --为了避免在遍历gPendingSave的途中去调用on_check_pending接口，防止开发者错误的在on_check_pending中去进行了数据库操作
    local cb_map = {}       --key为函数，value为table(key为id, value为chgs)
    for tab, doc in pairs(gPendingSave) do
        local cache = doc.__cache
        local cb = nil
        for id, chgs in pairs(doc) do
            if chgs ~= cache then

                doc[ id ] = nil
                update = true
                if not chgs._a_ then
                    if tab ~= "todo" then
                        LOG( "[DB], update, %s, %s", tab, tostring(id) )
                    end
                    local oid = chgs._id
                    chgs._id = id
                    db[ tab ]:update({_id=id}, {["$set"] = chgs }, true)
                    chgs._id = oid
                else
                    if chgs._a_ == 0 then
                        if tab ~= "todo" then
                            LOG( "[DB], delete, %s, %s", tab, tostring(id) )
                        end
                        db[ tab ]:delete({_id=id})
                    else
                        if tab ~= "todo" then
                            LOG( "[DB], create, %s, %s", tab, tostring(id) )
                        end
                        local oid = chgs._id
                        rawset( chgs, "_a_", nil )
                        rawset( chgs, "_id", id )
                        db[ tab ]:update({_id=id}, chgs, true)
                        rawset( chgs, "_a_", 1)
                        rawset( chgs, "_id", oid )
                    end
                end
                rawset( chgs, "_n_", cur )
                cache[ id ] = chgs

                if cb == nil then
                    cb = cbs[ tab ]
                    if cb == nil then
                        if _G[ tab ] and type( _G[ tab ] ) == "table" then
                            if _G[ tab ].on_check_pending then
                                cb = _G[ tab ].on_check_pending
                                if cb == nil then cb = false end
                            end
                        end
                        cbs[ tab ] = cb
                    end
                end

                if cb then
                    cb_map[cb] = cb_map[cb] or {}
                    cb_map[cb][id] = chgs
                end
            end
        end
    end

    -- on_check_pending统一在外部调用
    for cb, params in pairs(cb_map) do
        for id, chgs in pairs(params) do
            cb(db, id, chgs )
        end
    end

    if update then gen_global_checker( db, cur ) end
end


function cache_check(cache, table_name, check_table, check_fails)
    -- 校验了不同的key指向了同一个cache的错误，出现此问题肯定是逻辑上写错了
    -- 20161208 在act项目中，出现了2张不同的表里面的相同的id指向了同一个cache的错误
    -- 如果在同一帧存储，也会导致_n_为nil的情况，所以增加了check的范围
    for id, chgs in pairs(cache) do
        if check_table[chgs] ~= nil then
            local first_table_name = check_table[chgs][1]
            local first_id = check_table[chgs][2]
            WARN("zhoujy_warning: cache_check failed tab_1=%s, id_1=%s, tab_2=%s, id_2=%s",
                first_table_name, first_id, table_name, id)

            if not check_fails[chgs] then
                check_fails[chgs] = {}
                local cache_key = string.format("%s@%s", first_table_name, first_id)
                check_fails[chgs][cache_key] = true
            end
            local cache_key = string.format("%s@%s", table_name, id)
            check_fails[chgs][cache_key] = true
        else
            check_table[chgs] = {table_name, id}
        end
    end
end

gGlobalChecker = {}
function global_save_checker()
    while true do
        local db, frame = coroutine.yield()

        local info = db:runCommand("getLastError")
        if info.ok then
            local code = info.code
            local check_table = {}
            local check_fails = {}
            local need_reset_n = false
            for tab, doc in pairs(gPendingSave) do
                local cache = doc.__cache
                cache_check(cache, tab, check_table, check_fails)
                local adds = {}
                local dels = {}
                for id, chgs in pairs(cache) do
                    need_reset_n = false
                    if chgs._n_ == frame then
                        need_reset_n = true
                        table.insert(dels, id)
                        if code then
                            local tips = string.format("error: upd_tab %s: %s", tab, id)
                            WARN( "mongo_error, %s", tips)
                            dumpTab(chgs, tips)
                        end
                    elseif chgs._n_ < frame - 100 then
                        need_reset_n = true
                        WARN("mongo_error, %s:%s, %s, %s, %s", tab, id, chgs._n_, frame, gFrame)
                        dumpTab( chgs, "mongo_error" )
                        adds[id] = chgs
                        table.insert(dels, id)
                    end

                    if need_reset_n and check_fails[chgs] then
                        local cache_key = string.format("%s@%s", tab, id)
                        check_fails[chgs][cache_key] = nil
                        if next(check_fails[chgs]) then
                            -- 说明还有未check的重复条目，虽然chgs是一致的，但是希望下一个重复的条目走del流程和日志输出流程
                            need_reset_n = false
                        end
                    end

                    if need_reset_n then
                        rawset( chgs, "_n_", nil )
                    end
                end
                for id, chgs in pairs(adds) do
                    doc[id] = chgs
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

        local co = coroutine.running()
        if #gGlobalChecker < 20 then
            coro_mark( co, "inpool" )
            table.insert( gGlobalChecker, co )
        else
            gCoroBad[ co ] = nil
            return
        end
    end
end

function thread_global_save_checker()
    if _ENV then
        xpcall(global_save_checker, STACK )
    else
        global_save_checker()
    end
end

function gen_global_checker( db, frame )
    local co
    if #gGlobalChecker > 0 then
        co = table.remove( gGlobalChecker )
        coro_mark( co, "outpool" )
        coroutine.resume( co, db, frame )
    else
        co = coroutine.create( thread_global_save_checker)
        coro_mark_create( co, "global_checker" )
        coro_mark( co, "outpool" )
        coroutine.resume( co )
        coroutine.resume( co, db, frame )
    end
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
            if mongo_save_mng._switch then
                local t = mongo_save_mng.get_collection_table(tab, false)
                self[ tab ] = t
                return t
            end
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

function init_global_database_pending()
    __g_mt_rec = {
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
    __g_mt_tab = {
        __index = function (self, tab)
            local t = { __cache={} }
            setmetatable(t, __g_mt_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingGlobalSave, __g_mt_tab)


    __g_mt_del_rec = {
        __newindex = function (t, k, v)
            gPendingGlobalSave[ t.tab_name ][ k ]._a_ = 0
        end
    }
    __g_mt_del_tab = {
        __index = function (self, tab)
            local t = {tab_name=tab}
            setmetatable(t, __g_mt_del_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingGlobalDelete, __g_mt_del_tab)

    __g_mt_new_rec = {
        __newindex = function (t, k, v)
            gPendingGlobalSave[ t.tab_name ][ k ] = v
            v._a_ = 1
        end
    }
    __g_mt_new_tab = {
        __index = function (self, tab)
            local t = {tab_name=tab}
            setmetatable(t, __g_mt_new_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(gPendingGlobalInsert, __g_mt_new_tab)
end


function init(sec, msec)
    require("warx_pub/etc/config")
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

    loadMod()

    if config.Game ~= "warx" then
        gPendingSave = {}
        gPendingDelete = {}
        gPendingInsert = {}
    else
        require( "frame/pending_save" )
    end

    init_pending()

    gPendingGlobalSave = {}
    gPendingGlobalDelete = {}
    gPendingGlobalInsert = {}
    init_global_database_pending()

    gPendingToolAck = {}

    gInit = "StateBeginInit"

    require("game")

    load_game_module()

    --debug.settablemark(1)

    LOG("start: gTime = %d, gMsec = %d", gTime, gMsec)

    Rpc:init("server")
    --Rpc.localF[ 6 ] = Rpc.localF[ hashStr("onBreak") ]


    if config.Tips then
        c_init_log(config.Tips)
    end

    --local dbname = string.format("warx_%d", gMapID)
    local name = config.Game or "warx"
    local dbname = string.format("%s_%d", name, gMapID)
    for i = 1, gDbNum, 1 do
        conn.toMongo(config.DbHost, config.DbPort, dbname, nil, false)
    end

    local dbnameG = string.format("%sG", name)
    if config.DbHostG then
        conn.toMongo(config.DbHostG, config.DbPortG, dbnameG, "Global", false)
    end

    conn.toGate(config.GateHost, config.GatePort)

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
        coro_mark(co, "outpool")
        return co
    else
        local co = createCoro(what)
        coro_mark_create( co, what )
        coro_mark(co, "outpool")
        return co
    end
end

function putCoroPool(what)
    local co = coroutine.running()
    coro_mark( co, "pool" )
    local pool = gCoroPool[ what ]
    if #pool < 10 then table.insert(gCoroPool[ what ], co) end
    coroutine.yield("ok")
end

function getCoroPend(what, id)
    local co = gCoroPend[ what ][ id ]
    if co then
        gCoroPend[ what ][ id ] = nil
        if type(co) == "table" then
            coro_mark( co[1], "outpend" )
            return unpack(co)
        else
            coro_mark( co, "outpend" )
            return co
        end
    end
end

function putCoroPend(what, id, extra)
    local co = coroutine.running()
    coro_mark( co, what.."_pend" )
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

function remPlayer(pid)
    if pid then
        gPlys[ pid ] = nil
    end
end

function load_sys_config()
    local db = dbmng:getGlobal()
    if not db then
        return ERROR("zhoujy_error: can not find global db!")
    end
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
        local db = dbmng:getOne()
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

    local n = gPendingSave.uniq[ what ]
    n.sn = t.sn
    n.at = t.at
    n.state = t.state

    return id
end

function getAutoInc(what)
    --local db = dbmng:getOne(0)
    local db = dbmng:getGlobal()
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

gCheckers = {}
function save_checker()
    while true do
        local db, frame, cache, name = coroutine.yield()
        local info = db:runCommand("getPrevError")
        if info.ok then
            local dels = {}
            local check_table = {}
            local check_fails = {}
            cache_check(cache, name, check_table, check_fails)
            for k, v in pairs(cache) do
                local n = v._n_
                if n then
                    if n == frame then
                        table.insert(dels, k)
                    elseif n < frame - 100 then
                        WARN("mongo_error in save_checker, %s:%s, %s, %s, %s", name, k, n, frame, gFrame)
                        dumpTab( v, "mongo_error" )
                        v._n_ = nil
                    end
                end
            end
            if #dels > 0 then
                for _, v in pairs(dels) do
                    cache[v] = nil
                end
            end
        end
        local co = coroutine.running()
        if #gCheckers < 20 then
            coro_mark( co, "pool" )
            table.insert( gCheckers, co )
        else
            gCoroBad[ co ] = nil
            return
        end
    end
end

function thread_save_checker()
    if _ENV then
        xpcall(save_checker, STACK )
    else
        save_checker()
    end
end

function gen_checker( db, frame, cache, name )
    local co
    if #gCheckers > 0 then
        co = table.remove(gCheckers)
        coro_mark( co, "check" )
        coroutine.resume( co, db, frame, cache, name )
    else
        co = coroutine.create( thread_save_checker )
        coro_mark_create( co, "checker" )
        coro_mark( co, "check" )
        coroutine.resume( co )
        coroutine.resume( co, db, frame, cache, name )
    end
end

function coro_info()
    collectgarbage()
    for k, v in pairs( gCoroMark ) do
        --local status = "none"
        --if v.co then status = coroutine.status( v.co ) end
        local status = coroutine.status( k )
        print( string.format( "Coro, name=%s, action=%s, tick=%s, last=%d, status=%s", v.name, v.action, v.tick, gTime-v.tick, status ) )
        if status == "dead" then print( "coro dead", k ) end
    end
end



function take_over_os_time()
    if c_time_real and not g_real_os_time then
        g_real_os_time = os.time
        os.time = my_os_time
    end
end


function my_os_time( info )
    if not info then
        return c_time_real()
    else
        return g_real_os_time( info )
    end
end

take_over_os_time()

function is_system_db_field(id)
    return id == "__cache" or id == "__app_data" or id == "__cmd_data"
end
