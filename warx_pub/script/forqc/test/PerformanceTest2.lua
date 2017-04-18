--PT
--creat accunt for all civilization
--创建账号,指定文明,指定城堡等级,迁城到一个区域内，分四个文明区域

local t1 = {}

function t1.action( _idx )
    
    local lvtable = {1,6,8,10,12,14,16,18,20,22,23,24,25,26,27,28,29,30}
    

    for i=1,18 do
        local p1 = get_one(true, 1)
        if not p1 then return end
        loadData( p1 )

        chat( p1, "@addres=6=100000" )
        chat( p1, "@lvbuild=0=0="..tostring(lvtable[i]))
        move_to(p1, 115, 115, 15)
        Rpc:change_name(p1,"HX-"..tostring(i))
        sync( p1 )
        logout( p1 )
    end
 
    for i=1,18 do
        local p2 = get_one(true, 2)
        if not p2 then return end
        loadData( p2 )

        chat( p2, "@addres=6=100000" )
        chat( p2, "@lvbuild=0=0="..tostring(lvtable[i]))
        move_to(p2, 85, 115, 15)
        Rpc:change_name(p2,"BS-"..tostring(i))
        sync( p2 )
        logout( p2 )
    end

    for i=1,18 do
        local p3 = get_one(true, 3)
        if not p3 then return end
        loadData( p3 )

        chat( p3, "@addres=6=100000" )
        chat( p3, "@lvbuild=0=0="..tostring(lvtable[i]))
        move_to(p3, 85, 85, 15)
        Rpc:change_name(p3,"LM-"..tostring(i))
        sync( p3 )
        logout( p3 )
    end

    for i=1,18 do
        local p4 = get_one(true, 4)
        if not p4 then return end
        loadData( p4 )

        chat( p4, "@addres=6=100000" )
        chat( p4, "@lvbuild=0=0="..tostring(lvtable[i]))
        move_to(p4, 115, 85, 15)
        Rpc:change_name(p4,"SL-"..tostring(i))
        sync( p4 )
        logout( p4 )
    end


end

return t1