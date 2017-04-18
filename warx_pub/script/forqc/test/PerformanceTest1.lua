--PT
--performance test,creat accunt
--创建账号,指定文明,指定城堡等级,迁城到一个区域内

local t1 = {}

function t1.action( _idx )
    
    local lvtable = {1,6,8,10,12,14,16,18,20,22,23,24,25,26,27,28,29,30}
    
    for j=1,4 do
        for i=1,18 do
            local ply = get_one(true, j)
            if not ply then return end
            loadData( ply )

            chat( ply, "@addres=6=100000" )
            chat( ply, "@lvbuild=0=0="..tostring(lvtable[i]))
            move_to(ply, 720, 70, 30)
            Rpc:change_name(ply,"P"..tostring(j+8)..tostring(i))
            sync( ply )
            logout( ply )
        end
    end    

end

return t1