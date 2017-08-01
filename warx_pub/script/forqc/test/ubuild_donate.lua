--lxz
--军团科技捐献
local mod = {}

function mod.action(_idx)
    require("union_tech_t")
    require("frame/debugger")
    local name = tostring(math.random(100,999))
    lxz(name)

    local p = get_account2( name )
    Rpc:union_quit(p)

    loadData(p)
    chat(p, "@set_val=gold=100000000")
    chat(p, "@addres=1=10000000")
    chat(p, "@addres=2=10000000")
    chat(p, "@addres=3=10000000")
    chat(p, "@addres=4=10000000")
    chat(p, "@buildtop")
    chat(p, "@addbuf=1=-1")
    sync(p)
    Rpc:union_create(p, "robot"..name, name, 40, 1000)
    wait_for_ack(p, "union_on_create")
    local id =1001
    local info = {}
    while true do
        local ret = union_tech(p,1001)
        if ret == 0  then break end
    end
    lxz(name)

    return "ok"
end

return mod
