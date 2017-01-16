--lxz
--lxz1
local t1 = {}

function t1.action( _idx )
    local p = get_one(true)
    loadData( p )

    chat( p, "@set_val=gold=100000000" )
    if true then return end

    chat( p, "@buildtop" )
    chat( p, "@initarm" )
    chat( p, "@additem=3004001=100" )

    chat( p, "@addres=1=10000000" )
    chat( p, "@addres=2=10000000" )
    chat( p, "@addres=3=10000000" )
    chat( p, "@addres=4=10000000" )

    local culture = p.culture
    local armid = culture * 1000000 + 1010 

    local build = get_build( p, 2, 1 )
    if not build then 
        WARN( "no build" )
        return
    end
        
    if build.state == 2 then
        Rpc:train( p, build.idx, armid, 10, 0)
        sync( p )
    elseif build.state == 3 then

    else
        WARN( "build.state = %d, not complete", build.state )
        return
    end
    dumpTab( build, "build1" )
    
    local tmStart = build.tmStart
    local tmOver = build.tmOver

    local item = get_item( p, 3004001 )
    if not item then
        WARN( "no item" )
        return
    end

    Rpc:item_acc_build( p, build.idx, item[1], 1 )
    sync( p )
    wait_for_time( 2 )

    dumpTab( build, "build2" )

    local tmOver1 = build.tmOver

    print( "acc", tmOver - tmOver1 )

    --logout( p )
end

return t1

