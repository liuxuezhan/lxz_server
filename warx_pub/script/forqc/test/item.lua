--道具
--支持类型：使用后获得资源,道具,增加Buf（角色Buf）,不支持几率道具

local mod = {}

function mod.action( _idx )
    require("frame/debugger") 
    local p = get_account(651)
    loadData(p)
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addbuf=1=-1" )
    sync( p )


    for _, v in pairs( sort) do 
        local c = resmng.prop_item[v[1]]
        lxz(c.ID)
        if not use_item(p,c,v[2]) then lxz(c.ID) end
    end
    return "ok"
end

function use_item(p,c,Param)
    if c.Action == "AddBonus" then
        local ret = AddBonus(p,c,Param)
        if  ret then ret = "ok" else ret = "fail" end
        os.execute("echo item,"..c.ID..","..ret.." >> /tmp/check.csv")
    elseif c.Action == "AddBuf" then
    elseif c.Action == "BuyRes" then
    elseif c.Action == "UnionItemPos" then
    elseif c.Action == "UseHeroCard" then
    elseif c.Action == "VipEnable" then
    elseif c.Action == "Compound" then
    end
    return true 
end

function AddBonus(p,c,Param)
    local old = AddBonus_on(p,Param or c.Param)

    chat( p, "@adddaoju="..c.ID.."=1" )
    Rpc:loadData( p, "item" )
    sync(p)
    for idx, v in pairs(p._item) do
        if v[2] == c.ID then
            Rpc:use_item(p,idx,1) 
        end
    end

    return AddBonus_off(p,old)
end



sort = {
    {1001001,{{"mutex_award",{{"respicked",2,38000,10000},{"respicked",1,38000,10000}}}}},
}

return mod

