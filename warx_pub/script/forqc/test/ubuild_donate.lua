--军团
--军团科技捐献
local mod = {}

function mod.action(_idx)
    require("union_tech_t")

    local a = union_create(nil,1)
    local p =a[1]
    chat(p, "@buildtop")
    chat(p, "@jump=1")
    sync(p)

    local id =1001
    local info = {}
    while true do
        local ret = union_tech(p,1001)
        if ret == 0  then break end
    end

    return "ok"
end

return mod
