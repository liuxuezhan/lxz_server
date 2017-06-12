
local t1 = {}

function t1.action( idx )
    local p = get_account( idx )
    print( "get player", p.pid )

    tele_debug( p )
end

return t1
