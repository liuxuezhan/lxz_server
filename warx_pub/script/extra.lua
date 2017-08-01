--local p = getPlayer( 3460179 )
--if p then
--    local build = p:get_altar()
--    if build then
--        local kill = build.extra.kill
--        local h = heromng.get_hero_by_uniq_id( kill.id )
--        if h then
--            h.status = HERO_STATUS_TYPE.DEAD
--        end
--        build.extra = {}
--    end
--end
----
--for _, ply in pairs(gPlys or {}) do
--    if ply.union_item then
--        local item = copyTab(ply.union_item.item or {})
--        ply.union_item.item = item
--        gPendingSave.union_item[ply.pid].item = item 
--    end
--end
--
--
--player_t.set_sys_option( "radioflag", 1 )

local count = 0
for k, v in pairs( gPendingActions ) do
    count = count + 1
end
WARN( "gPendingActions = %d", count )
--
--global_save()


local co = coroutine.create( global_saver )
coroutine.resume( co )

WARN( "gThreadAction = %s, gThreadActionState = %s", gThreadAction, gThreadActionState )


WARN ("gTimeStartSave = %d, gTime = %d, %d",  gTimeStartSave, gTime, gTime - gTimeStartSave )

local name = config.Game or "warx"
local dbname = string.format("%s_%d", name, gMapID)
conn.toMongo(config.DbHost, config.DbPort, dbname, nil, false)
conn.toMongo(config.DbHost, config.DbPort, dbname, nil, false)
conn.toMongo(config.DbHost, config.DbPort, dbname, nil, false)



