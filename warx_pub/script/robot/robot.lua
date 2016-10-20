require("frame/tools")
--mongoexport -d warx_6 -c player -f account | cut -d"\"" -f6
gSns = {}
gDelay = {}--定时器分组
gIdx = 0
gZones = gZones or {}
gEtys = gEtys or {}

gSkiplist = gSkiplist or true

gMap = getMap()
gTotalCount = 1
gTotalConnect = 0
gInterval = 1

print("gmap = ", gMap)

function loadMod()
    require("resmng")
    require("frame/tools")
    --require("frame/debugger")
    require("frame/dbmng")
    require("frame/timer")
    require("frame/socket")
    require("common/define")
    require("common/tools")

    -- rpc
    require("frame/class")

    doLoadMod("packet", "frame/rpc/packet")
    doLoadMod("MsgPack", "frame/MessagePack")
    doLoadMod("Array", "frame/rpc/array")
    doLoadMod("Struct", "frame/rpc/struct")
    doLoadMod("RpcType", "frame/rpc/rpctype")
    doLoadMod("Rpc", "frame/rpc/rpc")

    do_load("common/protocol")
    do_load("robot/ply")
    do_load("robot/name")

    --do_load("resmng")
    --timer._funs.lazy = doLazy
    --timer._funs = {}
end

gConns = {}--机器人


function init(sec, msec)
    gTime = math.floor(sec)
    gMsec = math.floor(msec)

    loadMod()
    print("robot init")
    begJob()

    Rpc:init("client")
    Rpc.localF[ 6 ] = Rpc.localF[ hashStr("onBreak") ]

    gSkiplist = skiplist()
    
    return 1
end


gActive = gActive or {}


function main_loop(sec, msec, fpk, ftimer, froi, deb)
    begJob()

    if deb > 0 then
        --pause("debug in main_loop")
        os.exit(-1)
    end

    gFrame = (gFrame or 0) + 1
    gTime = sec

    --local ncount = 0
    --for k, n in pairs(gConns) do
    --    ncount = ncount + 1
    --    local idx = gFrame % 2
    --    if k % 2 == idx then
    --        if n.tmLogin then
    --            if gTime - n.tmLogin > 3000000 then
    --                shutdown(k)
    --                gConns[ k ] = nil
    --            else
    --                if gTime - (n.tmAction or 0) > 1 then
    --                    Ply.doAction(n)
    --                    n.tmAction = gTime
    --                else
    --                end
    --            end
    --        end
    --    end
    --end

    --if ncount < 3000 then--在线上限
    --if ncount < 1 then--在线上限
    --    for i = 1, 10, 1 do--每秒登录人数
    --        --if gIdx > 200 then break end
    --        if gIdx > 1 then --单服玩家上限
    --            break
    --        --    gIdx = 0 
    --        end
    --        gIdx = gIdx + 1
    --        local name = string.format("30_%d", gIdx)
    --        --local sid = connect("192.168.0.4", 8011, 1, 0)
    --        local sid = connect("192.168.100.12", 18001, 0, 0)
    --        gConns[ sid ] = Ply.new(name)
    --        break
    --    end
    --end


    local ncount = 0
    --for k, n in pairs( gConns ) do
    --    ncount = ncount + 1
    --    if n.tmLogin then
    --        if gTime - (n.tmAction or 0) > 4 then
    --            Ply.doAction( n )
    --            n.tmAction = gTime
    --        end
    --    end
    --end
    begJob()

    if gTotalConnect < gTotalCount then
        gTotalConnect = gTotalConnect + 1
        local name = string.format("%d0_%d", gMap, gTotalConnect)
        local sid = connect("192.168.100.12", 7001, 0, 0)
        gConns[ sid ] = Ply.new(name)
    end
    gMsec = msec

    if fpk == 1 then
        while true do
            local sid, tag = pullNext() 
            if not sid then break end

            if not tag then
                local mem = collectgarbage("count")
                if mem > (gMaxMem or 0) then
                    gMaxMem = mem
                end

                local pktype = pullInt()
                local fname, args = Rpc:parseRpc(packet, pktype)
                if fname then
                    local n = gConns[ sid ]
                    if n then
                        LOG("RpcR, pid=%d, func=%s", n.pid or 0, fname )
                        local f = Ply[fname ]
                        if f then
                            f(n, unpack(args) )
                        end
                    else
                        LOG("RpcR, pid=0, func=%s", fname )
                    end
                end
            elseif tag == 1 then
                local pktype = pullInt()
                local n = gConns[ sid ]
                if n then
                    Ply.handle_network(n, sid, pktype)
                end
            end
        end
    end

    if ftimer == 1 then
        while true do
            local sn, tag = pullTimer()
            if not sn then break end
            timer.callback(sn, tag)
        end
    end

    local infos = gSkiplist:get_rank_range( 1, 1 ) 
    for _, v in pairs( infos ) do
        local gid = tonumber( v )
        local n = gConns[ gid ]
        if n then
            if gTime - n.active > gInterval then
                Ply.doAction( n )
                Ply.pending( n )
            end
        end
    end
end


