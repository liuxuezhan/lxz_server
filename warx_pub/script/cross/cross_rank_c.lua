module("cross_rank_c", package.seeall)


local peason_rank = 1
local union_rank = 2
local gs_rank = 3

function update_score(mode, val, ...)
    local arg = {...}
    if mode == RANK_ACTION.NARMAL or  mode == RANK_ACTION.CURE or  mode == RANK_ACTION.NPC_DMG or mode ==  mode == RANK_ACTION.KING_DMG then
        add_score(peason_rank, arg[1], val)
        add_score(union_rank, arg[2], val)
        add_score(gs_rank, arg[3], val)
    else
        add_score(union_rank, arg[1], val)
        add_score(gs_rank, arg[2], val)
    end

end

function add_score(rank_id, key, val)
    local old_score = rank_mng.get_score(rank_id, key) or 0
    val = old_score + val
    if val <= 0 then
        rank_mng.rem_date(rank_id, key)
    else
        rank_mng.add_data(rank_id, key, {score})rank_mng.add_data(rank_id, key, {val})
    end
end

function send_rank_award()
        for k, v in pairs(resmng.prop_cross_person_rank_award or {}) do
            local plys = rank_mng.get_range(15, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(15, tonumber(pid)) or 0

            end
        end
        for k, v in pairs(resmng.prop_cross_union_rank_award or {}) do
            local plys = rank_mng.get_range(16, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(16, tonumber(pid)) or 0
                    local ply = getPlayer(tonumber(pid))
            end
        end

end

function send_ply_award(reward_mode, pid, award, param)
    local gs_id = 7
    Rpc:callAgent(gs_id, "send_cross_award", RANK_MODE.PLY, reward_mode, pid, param)

end

function send_uid_award(reward_mode, uid, award, param)
    local gs_id = 7
    Rpc:callAgent(gs_id, "send_cross_award", RANK_MODE.UNION, reward_mode, uid, param)
end


