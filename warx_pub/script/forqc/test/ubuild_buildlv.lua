--军团
--军团建筑科技捐献
local mod = {}


function mod.action(_idx)

    local a = union_create("100",1)
    lxz(a[1].pid)
    for i = 1, 1000 do
        local p = get_account(1000 + i)
        Rpc:union_quit(p)
        Rpc:union_apply( p,a[1].uid)
        loadData(p)
        sync(p)
        if not buildlv(p) then lxz("失败") return end
        Rpc:union_quit( p )
        sync(p)
    end

    return "ok"
end

return mod
