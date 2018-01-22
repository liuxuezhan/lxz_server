

local t1 = {}

function t1.action( idx )
    local p = get_account( idx )
    loadData( p )
    logout( p )
    
    return "ok"
end

return t1
