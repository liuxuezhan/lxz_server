--PT
--creat accunt for all civilization
--创建账号,指定文明,指定城堡等级,迁城到一个区域内，分四个文明区域

local t1 = {}

function t1.action( _idx )
    
    --local lvtable = {1,6,8,10,12,14,16,18,20,22,23,24,25,26,27,28,29,30}
    
    local index = 1
    local lv = 30

    for i=61,100 do
        local p1 = get_account(index * 1000 + i)
        if not p1 then return end
        loadData( p1 )

        chat( p1, "@addres=6=10000" )
        --chat( p1, "@lvbuild=0=0="..lv)
        move_to(p1, 121, 942, 35)
        
        sync( p1 )
        logout( p1 )
    end
 

end

return t1