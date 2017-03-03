module("subscribe_ntf", package.seeall)

local sub_group = sub_group or {}


function add_sub_group( group_id, ply_id)
    local group = sub_group[group_id] or {}
    if group[ply_id] then
        ply_info = group[ply_id]
        ply_info[2] = gTime
    else
        group[ply_id] = {ply_id, gTime}
    end
end

function get_sub_group(group_id)
    return sub_group[group_id]
end

function rem_sub_group(group_id, ply_id)

end

local sub_func = {}

sub_func["lt_map_info_req"] = function(ply, func_name, ...)
    Rpc:lt_map_info_ack(ply, ...)
end

sub_func["get_do_mc_npc_req"] = function(ply, func_name, ...)
    Rpc:get_do_mc_npc_ack(ply, ...)
end

sub_func["npc_ft_result_ntf"] = function(ply, func_name, ...)
    Rpc:npc_ft_result_ntf(ply, ...)
end

function send_sub_ntf(group_id, func_name, ...)
    local group = get_sub_group(group_id)
    local dels = {}
    if group then
        for pid, _info in pairs(group or {}) do
            local ply = getPlayer(pid)
            if ply then
                if ply:is_online() then
                    if sub_func[func_name] then
                        sub_func[func_name](ply, ...)
                    end
                else
                    table.insert(dels, pid)
                end
            else
                table.insert(dels, pid)
            end
        end
    end
    for k, v in pairs(dels or {}) do
        group[v] = nil
    end
    sub_group[group_id] = group
end
