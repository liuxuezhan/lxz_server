--lxz
--军团建筑科技捐献
local mod = {}


function mod.action(_idx)

    require("frame/debugger")
    
    name = "555"
    local a = union_create(name,1)
    for i = 1, 1000 do
        local p = get_account2(name..i)
        Rpc:union_quit(p)
        Rpc:union_apply( p,a[1].uid)
        buildlv(p)
        Rpc:union_quit( p )
    end

    return "ok"
end

return mod
