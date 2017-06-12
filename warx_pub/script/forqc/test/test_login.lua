local t1 = {}

AppID = "045fce0de7f9b8ee9bf12e28c2d6d2cd"
AppKey = "1a4d7ea4895af21dd945ead32e9b1eae"
login_type = 2
--UDID = "E8A73FBD-BF47-40D9-A7B7-9E5E93804006"
--UDID = "5096F8D7B847AE9D19EBCF13F1F8F973"
UDID = "CD8F97F83071828DAB5623B8DD47FB4D"

_G.Json = require("frame/json")

function get_ver()
    local tmpfile = string.format( "download.%d", gTime )
    os.execute( "rm -rf ".. tmpfile )

    --local url = string.format("http://gw-warx.tapenjoy.com/api/ver/get?ver=0.8.3&udid=%s&os=ios&time=%d", UDID, gTime )
    local url = string.format("http://gw-warx.tapenjoy.com/api/ver/get?ver=0.8.5v&udid=%s&os=android&time=%d", UDID, gTime )
    print( url )
    local cmd = string.format( "curl -s -o %s \'%s\'", tmpfile, url)
    os.execute( cmd )

    local f = io.open( tmpfile, "r" )
    if not f then return end
    local str = f:read()
    print( str )
    os.execute( "rm -rf ".. tmpfile )
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
    data.appid = AppID
    data.ctype = 0
    data.cid = cid
    data.open_udid = cid
    --data.os = "android"
    data.os = "android"
    data.language = "cn"
    data.locale = "ase"
    data.mac = "mac"
    data.device_info = "device_info"
    local sig = create_http_sign(data)
    data.sig = sig

    local url = user_center .. "/api/user/login"
    local info = post_to( url, data )
    return info
end


function t1.action( idx )
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
    print( string.format( "get_server_list use %d msec", c_msec() - now ) )
    now = c_msec()

    info = false
    print( "get_user_info" )
    while ( not info ) do
        info = get_user_info( user_center )
        if info then break end
        print( "." )
    end
    print( string.format( "get_user_info use %d msec", c_msec() - now ) )
    now = c_msec()
    print( Json.encode( info ) )

    local node = info.data
    node.map = server_id
    node.account = node.uid
    node.idx = idx
    node.did = UDID
    gHavePlayers[ idx ] = node

    local sid = connect(ip, 8001, 0, 0 )
    if sid then
        node.action = "test_login"
        node.gid = sid
        gConns[ sid ] = node
        wait_for_ack( node, "onLogin" )
        print( string.format( "login use %d msec", c_msec() - now ) )
        print( string.format( "total use %d msec", c_msec() - start ) )
        os.exit(-1)
        return "ok"
    end


    Rpc:get_characters( node )
   
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

