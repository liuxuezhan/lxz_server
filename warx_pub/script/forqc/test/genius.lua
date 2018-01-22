--天赋
--支持所有技能的升级效果检查,配置中需要注意同类的Buf按照升级前后的差值计算检查

local mod = {}

function mod.action( _idx )
   -- require("frame/debugger") 
    local p = get_account(123)
    loadData(p)
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addexp=100000000" )
    chat( p, "@addbuf=1=-1" )
    chat( p, "@addres=1=1234567890" )
    chat( p, "@addres=2=1234567890" )
    chat( p, "@addres=3=1234567890" )
    chat( p, "@addres=4=1234567890" )
    chat( p, "@addres=5=1234567890" )
    chat( p, "@addres=6=1234567890" )
    chat( p, "@addres=7=1234567890" )
    sync( p )

    lxz(p.pid)
    for _, v in pairs( sort ) do 
        local c = resmng.prop_genius[v[1]] 
        lxz(v[1])
        while true do
            if genius(p, c.ID,c.Lv,v[2]) then break 
            else sync(p) end
        end
    end
    return "ok"
end
sort = {
    {1001001,{SpeedRes2_R=200}},
}


return mod

