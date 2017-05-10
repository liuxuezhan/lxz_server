
gCoroWaitForAck = gCoroWaitForAck or {}
gCoroWaitForTime = gCoroWaitForTimer or {}
gHavePlayers = gHavePlayers or {}


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

function loadMod()
    require("frame/tools")
    _G.Json = require("frame/json")

    dofile( c_get_conf() )

    --require("frame/debugger") 

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
    require("frame/perfmon")

    -- rpc
    require("frame/class")

    doLoadMod("packet", "frame/rpc/packet")
    doLoadMod("MsgPack", "frame/MessagePack")
    doLoadMod("Array", "frame/rpc/array")

    doLoadMod("Struct", "frame/rpc/struct")
    doLoadMod("RpcType", "frame/rpc/rpctype")
    doLoadMod("Rpc", "frame/rpc/rpc")

    do_load("resmng")
    do_load("common/define")
    do_load("common/tools")
    do_load("common/protocol")
    do_load("common/struct")
    do_load("constant/constant")
    for k, v in pairs( RpcType._struct ) do
        RpcType._struct[ k ] = Rpc.parseFunction( v ).args
    end
    --do_load("forqc/test/t_npc")


    doLoadMod( "OnRpc", "forqc/OnRpc" )
    require( "forqc/test/action" )
    require( "forqc/names" )
    require( "forqc/make_name" )

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
            print("Coro, threadAction, i should go away", co)
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
            print("Coro, threadTimer, i should go away", co)
            return
        end
    end
end

function onConnectComp( self )
    if self.action == "db" then
        self:onConnectOk()

    elseif self.action == "login" then
        local idx = self.idx
        local node = gHavePlayers[ idx ] or self
        
        local info = {}
        info.server_id = config.Map
        info.cival = ( idx % 4 ) + 1
        info.pid = 0
        info.token_expire = gTime + 36000
        info.extra = ""
        info.time = gTime
        info.token = c_md5( node.account )
        info.open_id = node.account

        info.signature = c_md5( APP_KEY .. tostring( info.token_expire ) .. info.extra .. tostring( info.time ) .. info.token .. info.open_id )
        info.version = 10000000
        Rpc:firstPacket( self, config.Map, info )

    elseif self.action == "test_login" then
        local info = {}
        info.server_id = self.map
        info.cival = ( self.idx % 4 ) + 1
        info.pid = 0
        info.token_expire = self.expire
        info.extra = self.ext_info
        info.time = self.timestamp
        info.token = self.token
        info.open_id = self.uid
        info.signature = self.sig
        info.version = 10000000
        Rpc:firstPacket( self, info.server_id, info )

    else
        print( "onConnectComp, what?", self.action )

    end
end

function onConnectFail( n )
    if n.action == "login" then
        local sid = n.gid
        gConns[ sid ] = nil
        if n.idx then
            gHavePlayers[ n.idx ].online = nil
        end
    end
end

function onConnectClose( n )

end

function do_threadPK()
    local co = coroutine.running()
    
    while true do
        local sid, tag
        while true do
            sid, tag = pullNext()
            if sid then
                break
            else
                putCoroPool("pk")
            end
        end
        if tag then
            if tag == 1 then
                local pktype = pullInt()
                local n = gConns[ sid ]
                if n then
                    if pktype  == gNetPt.NET_MSG_CONN_COMP then
                        onConnectComp( n )

                    elseif pktype  == gNetPt.NET_MSG_CONN_FAIL then
                        onConnectFail( n )

                    elseif pktype == gNetPt.NET_MSG_CLOSE then
                        onConnectClose( n )

                    end
                end
            elseif tag == 2 then
                mongo.recvReply( sid )
            end
        else
            local pktype = pullInt()
            local fname, args = Rpc:parseRpc( packet, pktype )
            if fname then
                local n = gConns[ sid ]
                if n then
                    LOG("RpcR, pid=%d, func=%s", n.pid or 0, fname )
                    local f = OnRpc[ fname ]
                    if f then
                        f( n, unpack( args ) )

                        local pend = gCoroWaitForAck[ sid ]
                        if pend then
                            local hit = false
                            for k, v in pairs( pend ) do
                                if v[1] == fname then
                                    hit = k
                                end
                            end
                            if hit then
                                local one = pend[ hit ][ 2 ]
                                pend[ hit ] = nil
                                if tabNum( pend ) == 0 then gCoroWaitForAck[ sid ] = nil end
                                coroutine.resume( one ) 
                            end
                        end
                    end
                else
                    LOG("RpcR, pid=0, func=%s", fname )
                end
            end
        end
    end
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

function threadPk()
    if _ENV then
        xpcall(do_threadPK, STACK )
    else
        do_threadPK()
    end
end

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

    gTime = sec
    gMsec = msec

    if signal > 0 then
        if pause then
            pause()
        else os.exit(-1) end

        if signal == 2 then -- SIGINT
            if pause then pause() end
        elseif signal == 3 then -- SIGQUIT 
            os.exit( -1 )
        elseif signal == 10 then -- SIGUSR1
            
        elseif signal == 12 then -- SIGUSR2
            gInit = "StateAction"
        end
    end

    if gInit == "StateBeginInit" then
        gInit = "StateAction" 
    elseif gInit == "StateAction" then
        gActionStart = c_msec()
        dofile( "forqc/task_queue.lua" )
        gInit = nil
    end

    --if gInit == "StateBeginInit" then
    --    if is_db_ready() then
    --        gInit = "StateLoadAccount"
    --        action( load_account )
    --    end
    --elseif gInit == "StateLoadAccount" then
    --    if gHavePlayers then
    --        gInit = "StateAction"
    --    end
    --elseif gInit == "StateAction" then
    --    dofile( "forqc/task_queue.lua" )
    --    gInit = nil
    --end

    if gInit then begJob() end

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
        table.remove(gCoroWait,1)
        coroutine.resume(t[1])
    end
end


function init(sec, msec)
    print( "init----------------" )
    gTime = math.floor(sec)
    gMsec = math.floor(msec)
    gMapID = getMap()
    gMapNew = 1
    set_mode( 1 )

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

    gInit = "StateBeginInit"
    loadMod()

    LOG("start: gTime = %d, gMsec = %d", gTime, gMsec)

    Rpc:init("client")
    Rpc.localF[ 6 ] = Rpc.localF[ hashStr("onBreak") ]

    if config.Tips then c_init_log(config.Tips) end

    --conn.toMongo( config.DbHost, config.DbPort, "warx_"..config.Map )
    --conn.toMongo( config.DbHostG, config.DbPortG, "warxG", "Global" )

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


function getPlayer(pid)
    if pid then
        if pid >= 10000 then
            return gPlys[ pid ]
        elseif pid > 0 then
            return { pid=pid }
        end
    end
end


function make_login( device_id )
    local ios = "aos"
    local AppID = "10000"
    local AppKey = "Os3NpXfDJeURCC1W"
    local login_type = 1
    local platform_type = 1
    local platform_openid = nil
    local platform_token = nil

    local s1 = c_md5( AppID .. device_id .. ios )
    local s2 = c_md5( s1 .. AppKey )

    local info = string.format( "appid=%s&device_id=%s&platform_type=%s&os=%s&login_type=%s&signature=%s", AppID, device_id, platform_type, ios, login_type, s2 )
    local url = "http://common.tapenjoy.com/index.php/LoginClass/login"
    local tmpfile = string.format( "%s.%d,txt", device_id, gTime )
    local cmd = string.format( "curl -s -d \"%s\" \"%s\" > %s", info, url, tmpfile )
    os.execute( cmd )

    local f = io.lines( tmpfile )
    local line = f()
    local str = ""
    while line do
        if string.len( line ) > 1 then
            str = str .. line
        end
        line = f()
    end
    os.execute( "rm -rf ".. tmpfile )

    --print( str )
    --{"code":200,"msg":"success","time":1483602610,"open_id":"c0e096c9e608eefd74afdb69318f8caa","token":"34da193eba4523067b2b8c651569bfb3","signature":"771fa40208f41e123c62ea63b8c2157a"}

    local info = {}
    for k, v in string.gmatch( str, "\"([%w_]+)\":\"?([%w_]+)\"?" ) do
        info[ k ] = v
    end
    return info.open_id, info.token, info.signature, info.time
end


