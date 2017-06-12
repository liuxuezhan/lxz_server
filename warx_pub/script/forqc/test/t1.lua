--lxz
--lxz1
local t1 = {}

gMaxTime = 0
function t1.action( idx )
    local t1 = c_msec()
    local p = get_account(idx)
    --chat( p, "@addres=6=999999" )
    --change_name( p, "robot_" .. p.idx )
    --change_name( p, make_name.make_name() )
    loadData( p )
    --Rpc:addEye( p, p.x, p.y )
    sync(p)
    local t2 = c_msec()
    local use = t2 - t1
    if use > gMaxTime then
        WARN( "=========================, use: %d, idx: %d", use, idx )
    end

    --logout( p )
    return "ok"
end

return t1

