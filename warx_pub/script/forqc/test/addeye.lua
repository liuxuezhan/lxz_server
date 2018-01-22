--移动地图
--lxz1
local t1 = {}


gTotalTime = 0
gTotalLogin = 0
gMaxTime = 0

function t1.action( idx )
    --idx = idx + 50000
    local t1 = c_msec()
    local p = get_account(idx)
    --chat( p, "@addres=6=999999" )
    --change_name( p, "robot_" .. p.idx )
    --change_name( p, make_name.make_name() )

    loadData( p )
    Rpc:addEye( p, gMapID, p.x, p.y )
    sync(p)
    --chat( p, string.format( "hello, i am %s", p.name ) )
    local t2 = c_msec()
    local use = t2 - p.tmStart

    gTotalTime = gTotalTime + use
    gTotalLogin = gTotalLogin + 1

    if gTotalLogin % 100 == 0 then
        WARN( "avg %d, %d", math.floor(gTotalTime / gTotalLogin), gTotalLogin )
    end

    if use > gMaxTime then
        WARN( "=========================, use: %d, idx: %d", use, idx )
        gMaxTime = use
    end

    logout( p )
    return "ok"
end

return t1

