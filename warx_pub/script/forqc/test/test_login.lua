--测试登陆
--lxz
local t1 = {}


--2017-07-31 02:18:51.246 map_1201: firstPacket2, from=1201, sockid=513146985, ip=182.150.21.43, open_id=0355A2097C13DA0A45028503C360CF70, pid=10000, did=AD921D60486366258809553A3DB49A4A, cival=0, signature=6c278012d8475e131b8d0e47221b2c98, time=1501467529, toke=, token_expire=0, version=11006, extra={"social_profile":{"openid":"0355A2097C13DA0A45028503C360CF70","name":"\u516d\u5c11","gender":1,"avatar":"http:\/\/q.qlogo.cn\/qqapp\/1106049523\/0355A2097C13DA0A45028503C360CF70\/40","avatar100":"http:\/\/q.qlogo.cn\/qqapp\/1106049523\/0355A2097C13DA0A45028503C360CF70\/100"}}

AppID = "045fce0de7f9b8ee9bf12e28c2d6d2cd"
AppKey = "1a4d7ea4895af21dd945ead32e9b1eae"
login_type = 2

Version="0.11.6"
UDID = "AD921D60486366258809553A3DB49A4A"
OPEN_ID="0355A2097C13DA0A45028503C360CF70"

--UrlVer="http://gw-warx-qq.tapenjoy.com/api/ver/get?ver=%s&udid=%s&os=android&time=%s"
UrlVer="http://192.168.100.14/resources/dev/android/v9000/27f16bd0f3fd53a635a7bbaf203a0d4e.u"

_G.Json = require("frame/json")

function get_ver()
    local tmpfile = string.format( "download.%d", gTime )
    os.execute( "rm -rf ".. tmpfile )

    local url = string.format(UrlVer, Version, UDID, gTime )

    print( url )
    local cmd = string.format( "curl -s -o %s \'%s\'", tmpfile, url)
    os.execute( cmd )

    local f = io.open( tmpfile, "r" )
    if not f then return end
    local str = f:read()
    print( str )
    --os.execute( "rm -rf ".. tmpfile )
    return Json.decode( str )
end

function get_server_list( gateway )
    local s1 = c_md5( AppID .. login_type )
    local s2 = c_md5( s1 .. AppKey )

    local data = {}
    data.appid = AppID
    data.platform = 2
    data.signature = s2
    local url = gateway .. "/api/servers/lists"
    local info = post_to( url, data )
    if not info then return end

    local server_id = false
    local ip = false

    if info.code == 0 then
        for _, srv in pairs( info.data ) do
            for k, v in pairs( srv ) do
                if k == "server_id" then
                    server_id = v
                elseif k == "ip" then
                    ip = v
                end
            end
        end
    end
    return server_id, ip
end
function create_http_sign(tab)
    local sign = AppKey
    local tab_key = {}
    tab.timestamp = gTime
    for k,v in pairs(tab) do
        table.insert(tab_key, k)
    end
    table.sort(tab_key, function ( a, b )
        return tostring(a) < tostring(b)
    end)
    for i=1,#tab_key do
        sign = sign.. tostring(tab[tab_key[i]])
    end
    return c_md5(sign)
end

function get_user_info( user_center )
    local cid = UDID
    local data = {}
    data.cid = cid
    data.appid = AppID
    data.ctoken = "D96EE62E748EFB032A73090165523C6C"
    --data.sig = sig
    data.ctype = 2
    --data.timestamp = gTime
    --data.open_udid = cid
    --data.os = "android"
    --data.language = "cn"
    --data.locale = "ase"
    --data.mac = "mac"
    --data.device_info = "device_info"

    local sig = create_http_sign(data)
    data.sig = sig

    local url = user_center .. "/api/user/login"
    local info = post_to( url, data )
    return info
end


function t1.action( idx )
    os.execute( "rm -rf login.ok" )

    local user_center = false
    local gateway = false

    local info = false
    print( "get_ver" )
    local start = c_msec()
    local now = start
    while ( not info ) do
        info = get_ver()
        if info then break end
        print( "." )
    end
    print( string.format( "get_ver use %d msec", c_msec() - now ) )
    now = c_msec()

    user_center = info.user_center
    gateway = info.gateway
    
    local server_id = false
    local ip = false
    print( "get_server_list" )
    while ( not server_id ) do
        server_id, ip = get_server_list( gateway )
        if server_id then break end
        print( "." )
    end
    print( string.format( "get_server_list use %d msec, server_id=%s, ip=%s", c_msec() - now, server_id, ip ) )
    now = c_msec()


    --info = false
    --print( "get_user_info" )
    --while ( not info ) do
    --    info = get_user_info( user_center )
    --    if info then break end
    --    print( "." )
    --end
    --print( string.format( "get_user_info use %d msec", c_msec() - now ) )
    --now = c_msec()
    --print( Json.encode( info ) )


    --local node = info.data
    local node = {}
    node.map = server_id
    node.map = 12
    node.open_id = OPEN_ID
    node.account = node.open_id
    node.did = UDID
    node.idx = idx
    gHavePlayers[ idx ] = node

    ip = "139.224.9.97"
    --local sid = connect(ip, 8001, 0, 0 )
    local sid = connect(ip, 6001, 1, 0 )
    if sid then
        node.action = "test_login"
        node.gid = sid
        gConns[ sid ] = node
        wait_for_ack( node, "onLogin" )

        Rpc:get_npc_map_req( node )

        wait_for_ack( node, "get_npc_map_ack" )


        print( string.format( "login use %d msec", c_msec() - now ) )
        print( string.format( "total use %d msec", c_msec() - start ) )
        --os.execute( "touch login.ok" )
        --os.exit(-1)
        --return "ok"
    end

    --Rpc:get_characters( node )
   
    --local total = 0
    --for i = 1, 4096, 1 do
    --    if total - gCountLoadData < 200 then
    --        total = total + 1
    --        action( start_action, "forqc/test/t1" )
    --    else
    --        wait_for_time( 1 )
    --    end
    --end
    return "ok"
end

return t1

