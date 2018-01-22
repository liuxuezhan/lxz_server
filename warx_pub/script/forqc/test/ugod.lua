--军团
--膜拜战神
local mod = {}

function mod.action(_idx)

    local a = union_create(nil,1)
    for i = 1, 5000 do
        local p = get_account(i)
        lxz(p.pid)
        loadData(p)
        Rpc:union_quit( p )
        Rpc:union_apply( p,a[1].uid)
        chat(p, "@set_val=gold=100000000")
        chat(p, "@buildtop")
        chat(p, "@jump=6")
        chat(p, "@jumpback=5")
        sync( p )

        Rpc:union_god_add(p,3)        --膜拜战神
        Rpc:union_quit( p )
        sync( p )
        logout( p )
    end

    return "ok"
end

return mod
