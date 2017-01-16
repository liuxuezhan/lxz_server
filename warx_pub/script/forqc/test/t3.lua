--lxz
-- title: check siege monster
--
local t1 = {}
function t1.action( _idx )
    local p = get_one()
    loadData( p )

    chat( p, "@set_val=gold=1000000" )
    chat( p, "@initarm" )
    buy_item( p, 39, 20 )

    move_to( p, 1103, 828, 30 )
    get_eye( p, 30 )

    for k, v in pairs( p._etys or {} ) do
        if is_monster( v ) then
            print( v.propid )
            local conf = resmng.get_conf( "prop_world_unit", v.propid )
            if conf and conf.Clv and conf.Clv < 10 then
                local arms = {}
                for id, num in pairs( p._arm ) do
                    arms[ id ] = 500
                end
                print( "siege", v.propid, v.eid )
                Rpc:siege( p, v.eid, { live_soldier=arms } )
                break
            end
        end
    end

    --logout( p )
end


return t1

