--lxz
--lxz1
local t1 = {}

function t1.action( _idx )
    local p = get_one(true)
    if not p then return end
    loadData( p )

    local hero = get_hero( p, 1 )
    if not hero then return "nohero" end

    hero_star_up( p, hero, 10 )
    use_hero_skill_item( p, hero, 5001205, 10, 2 )

    dumpTab( hero )
    return "ok"

end
return t1

