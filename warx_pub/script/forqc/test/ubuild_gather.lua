--lxz
--军团建筑采集

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local name = math.floor(gTime%1000)
    local p = get_account( 100 )
    Rpc:union_quit( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    Rpc:loadData( p, "pro" )

    sync( p )

    --local alias = c_num2str( p.pid )
    local alias = c_num2str( gTime )
    local len = string.len( alias )
    if len < 3 then
        for i = len, 3, 1 do
            alias = "0" .. alias
        end
    elseif len > 3 then
        alias = string.sub( alias, len-2 )
    end

    local name = tostring( gTime )
    if string.len( name ) < 6 then
        for i = len, 6, 1 do 
            name = "0" .. name
        end
    end

    Rpc:union_create(p, name, alias, 40, 1000)
    wait_for_ack( p, "union_on_create" )

    local num,def = 2,{} 
    for i = 1, num do
        def[i] = get_account( i + 100 )

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
    while obj2 do
        for i = 1, num do
            back(def[i])
            gather(def[i],obj2)
            wait_for_ack( def[i], "stateTroop" )
            obj2 = _us[p.uid].build[obj2.idx]
            lxz(obj2.val)
        end
    end

    return "ok"

end




return mod

