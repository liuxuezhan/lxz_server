--lxz
--lxz1
local t1 = {}

function t1.action( idx )
    local p = get_account(idx)
    --chat( p, "@addres=6=999999" )
    --change_name( p, "robot_" .. p.idx )
    change_name( p, make_name.make_name() )
    loadData( p )
    Rpc:addEye( p, p.x, p.y )
    --logout( p )
    return "ok"
end

return t1

