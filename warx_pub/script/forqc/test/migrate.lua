--随机迁城
-- title: check migrate overlap

local t1 = {}
function t1.action( _idx )
    local ply = get_account()
    if not ply then 
        WARN( "can not get one player" )
        return
    end
    loadData( ply )

    chat( ply, "@set_val=gold=100000" )
    buy_item( ply, 36, 2 )

    local dx, dy = 1104, 828
    
    buy_item( ply, 36, 2 )
    local range = 100
    while true do
        local tx = dx + math.random( 1, 2 * range ) - range
        local ty = dy + math.random( 1, 2 * range ) - range
        if tx >= 0 and tx < 1280 then
            if ty >= 0 and ty < 1280 then
                Rpc:migrate( ply, tx, ty )
                sync( ply )
                if ply.x == tx and ply.y == ty then
                    break
                end
            end
        end
    end
    logout( ply )
    print( "done: check migrate overlap" )
end

return t1

