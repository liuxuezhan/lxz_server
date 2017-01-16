--lxz
--训练士兵buff

local t1 = {}

function t1.action( _idx )
    local p = get_one()
    loadData( p )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addallitem" )
    chat( p, "@additem=3004001=100" )
    sync( p )
    wait_for_time( 10 )

    local culture = p.culture

    local armid = culture * 1000000 + 1010 
    local build = get_build( p, 2, 1 )
    if not build then return end
    lxz(build)
    if build.state == 2 then
        Rpc:train( p, build.idx, armid, 10, 0)
        sync( p )
        wait_for_time( 2 )
        lxz(p.acc)
    end

    local tmStart = build.tmStart
    local t = {}
    t[1] = build.tmOver

    local item = get_item( p, 3004001 )
    if not item then return end
    Rpc:item_acc_build( p, build.idx, item[1], 1 )
    sync( p )
    wait_for_time( 2 )

    t[2] = build.tmOver
    lxz( t )

    local hero = get_hero( p, 1 )
    if not hero then return "nohero" end
    hero_star_up( p, hero, 3 )
    local item = get_item( p, 5001206 )
    if not item then return end
    use_hero_skill_item( p, hero, 5, item[1], 1 )

    Rpc:dispatch_hero(p,build.idx,hero.idx)
    sync( p )
    wait_for_time( 2 )
    local tmOver2 = build.tmOver

    Rpc:dispatch_hero(p,build.idx,0)
    sync( p )
    wait_for_time( 2 )
    t[3] = build.tmOver
    lxz( t )

    Rpc:learn_tech(p,1001,2001001,1)
    sync( p )
    Rpc:learn_tech(p,1001,2010001,1)
    sync( p )
    Rpc:learn_tech(p,1001,2004001,1)
    sync( p )
    wait_for_time( 2 )
    t[4] = build.tmOver
    lxz( t )

    Rpc:construct(p,106,0,1)
    sync( p )
    wait_for_time( 2 )
    t[5] = build.tmOver
    lxz( t )

    --logout( p )
end

return t1

