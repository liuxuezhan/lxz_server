module("gmmng")
function do_public_gm(self, tb)
    function get_parm(idx)
        if idx < 1 or tb[idx + 1] == nil then
            return 0
        end
        return tb[idx + 1]
    end
    local cmd = tb[1] 
    if cmd == "example" then
        local pid = get_parm(1)
        local exp = get_parm(2)
        local player = getPlayer(tonumber(pid))
        player:add_exp(tonumber(exp))
    end
end


