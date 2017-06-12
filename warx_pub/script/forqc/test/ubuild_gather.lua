--lxz
--军团建筑采集

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local name = tostring(math.random(100,999))
    lxz(name)
    local p = get_account2( name )
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )

    Rpc:union_create(p, "robot"..name, name, 40, 1000)
    wait_for_ack( p, "union_on_create" )

    local num,def = 20,{} 
    for i = 1, num do
        def[i] = get_account2( name..i )

        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat( def[i], "@set_val=gold=100000000" )
        --chat( def[i], "@buildtop" )
        --chat( def[i], "@addbuf=1=-1" )
        chat( def[i], "@ef_add=CountSoldier=1000000" )
        chat( def[i], "@ef_add=CountTroop=2" )
        chat( def[i], "@addarm=4010=10000000" )
        chat( def[i], "@ef_add=SpeedGather_R=90000000" )
        sync( def[i] )
    end

    local obj = set_build(p, 10021001, p.x, p.y ) 
    build(p,obj,1)
    local obj2 = set_build(p, 10007001, obj.x, obj.y, 14 ) 
    build(p,obj2,1)
    while obj2 and obj2.val > 0 do
        for i = 1, num do
            back(def[i])
            obj2 = _us[p.uid].build[obj2.idx]
            lxz(obj2.val)
            gather(def[i],obj2)
            wait_for_ack( def[i], "stateTroop" )
        end
    end

    return "ok"

end




return mod

