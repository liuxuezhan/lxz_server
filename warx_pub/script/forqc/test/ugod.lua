--lxz
--军团建筑科技捐献
local mod = {}

function mod.action(_idx)

    require("frame/debugger")
    local name = tostring(math.random(100,999))
    lxz(name)
    local p = get_account2(name)
    chat(p, "@set_val=gold=100000000")
    Rpc:union_quit(p)
    Rpc:union_create(p, "robot"..name, name, 40, 1000)
    wait_for_ack(p, "union_on_create")
    
    local num, def = 5000, {}
    for i = 1, num do
        def[i] = get_account2(name..i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat(def[i], "@set_val=gold=100000000")

        Rpc:union_god_add(def[i],3)        --膜拜战神
        Rpc:union_quit( def[i] )
        sync( def[i] )
        logout( def[i] )
    end

    return "ok"
end

return mod
