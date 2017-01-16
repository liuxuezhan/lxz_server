--lxz
--lxz1
local t1 = {}

function t1.action( _idx )
    local p = get_one(true)
    chat( p, "@buildtop" )

    logout( p )

    --local f = io.open( "names2.lua", "w+" )
    --for k, v in pairs( open_ids ) do
    --    local account = k
    --    local token = v.token
    --    f:write( string.format( "\"%s\" = {account = \"%s\"},\n", token, account ) )
    --end
    --io.close( f )

    --local ply = get_one(true)
    --if not ply then return end
    --loadData( ply )

    --chat( ply, "@set_val=gold=1000" )
    --if ply.gold ~= 1000 then return "fail" end
    --
    --buy_item( ply, 72, 1 )

    --if ply.gold == 960 then return "ok" 
    --else return "fail" end

    --logout( ply )
    return "ok"
end

return t1

