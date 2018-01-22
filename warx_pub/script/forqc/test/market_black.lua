--道具
--黑市

local mod = {}

function mod.action( _idx )

    local p = get_account(2220000)
    loadData(p)
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addbuf=1=-1" )
    chat( p, "@buildtop" )
    chat( p, "@addres=1=100000000" )
    chat( p, "@addres=2=100000000" )
    chat( p, "@addres=3=100000000" )
    chat( p, "@addres=4=100000000" )
    chat( p, "@addres=5=100000000" )
    sync( p )

    lxz(p.pid)
    for k, v in pairs( sort) do 
        if not market(p,k,v) then lxz() end
    end
    return "ok"
end

function market(p,k,v)
    local its = p._build[601].extra.items
    local c = resmng.prop_black_market[its[1]]
    local m = {}
    table.insert(m,c.Buy[1])
    table.insert(m,{"res",c.Pay[1][2],-c.Pay[1][3],})
    m = {{"",m}}
    local old = AddBonus_on(p,m)
    Rpc:black_market_buy(p,1) 
    Rpc:load_msg_list(p, "black_market", -1, 6, 1)
    if AddBonus_off(p,old) then
        os.execute("echo tech,"..k..",ok >> /tmp/check.csv")
    else
        os.execute("echo tech,"..k..",fail >> /tmp/check.csv")
    end
end



sort = {
    {1,{{"mutex_award",{{"res",1,-100,10000},{"res",1,38000,10000}}}}},
}

return mod

