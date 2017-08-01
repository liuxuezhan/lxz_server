--lxz
--lxz1
local t1 = {}

function t1.action( _idx )
    require("frame/debugger")
    local name = tostring(math.floor(gTime%1000))
    local p = get_account()
    sync( p )
    Rpc:union_quit( p )
    Rpc:union_create(p,name,name,40,1000)
    wait_for_ack( p, "union_on_create" )

    union_mission(p,13 )

end



return t1

