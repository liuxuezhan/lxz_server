--道具
--物资市场

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
        if not market(p,v) then lxz(c.ID) end
    end
    return "ok"
end

function market(p,v)
    local old = AddBonus_on(p,v[2])
    Rpc:buy_res(p,v[1]) 
    if AddBonus_off(p,old) then
        os.execute("echo tech,"..v[1]..",ok >> /tmp/check.csv")
    else
        os.execute("echo tech,"..v[2]..",fail >> /tmp/check.csv")
    end
end



sort = {
    {1,{{"mutex_award",{{"res",1,-100,10000},{"res",1,38000,10000}}}}},
}

return mod

