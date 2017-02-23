--lxz
--lxz1
local t1 = {}

function t1.action( _idx )
    local name = tostring(math.floor(gTime%1000))
    local p = get_one2(name)
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    sync( p )
    Rpc:union_create(p,name,name,40,1000)
    wait_for_ack( p, "union_on_create" )

    local num,def = 3,{} 
    for i = 1, num do
        def[i] = get_one2(name..i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat( def[i], "@set_val=gold=100000000" )
        chat( def[i], "@buildtop" )
        chat( def[i], "@addbuf=1=-1" )
        sync( def[i] )
    end

end
return t1

