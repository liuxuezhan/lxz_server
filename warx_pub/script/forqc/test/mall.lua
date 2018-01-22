--道具
--商城

local mod = {}

function mod.action( _idx )

    local p = get_account()
    loadData(p)
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addbuf=1=-1" )
    chat( p, "@buildtop" )
    sync( p )

    lxz(p.pid)
    for _, v in pairs( sort) do 
        if not mall(p,v) then lxz(c.ID) end
    end
    return "ok"
end

function mall(p,v)
    local c = resmng.prop_mall[v[1]]
    if v[1] < 46 then 
        local old = AddBonus_on(p,{{"",{"item",c.item[2],c.item[3]*v[2],}}})
        Rpc:buy_item(p,v[1],v[2],0) 
        if AddBonus_off(p,old) then
            os.execute("echo mall,"..v[1]..",ok >> /tmp/check.csv")
        else
            os.execute("echo mall,"..v[2]..",fail >> /tmp/check.csv")
        end
    else
        local old = AddBonus_on(p,{{"",{"item",c.item[2],c.item[3]*v[2],}}},"AddBuf")
        Rpc:buy_item(p,v[1],v[2],0) 
        if AddBonus_off(p,old,"AddBuf") then
            os.execute("echo mall,"..v[1]..",ok >> /tmp/check.csv")
        else
            os.execute("echo mall,"..v[2]..",fail >> /tmp/check.csv")
        end
    end
end



sort = {
    {1,1},
}

return mod

