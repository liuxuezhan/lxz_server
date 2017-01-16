module("cross_score", package.seeall)


function process_troop(action, troop)
    if cross_act.act_state ~= CROSS_STATE.FIGHT then
        return
    end

    if troop.owner_pid ~= 0 and troop.owner_uid ~= 0 then
        for pid, arm in pairs(troop.arms or {}) do
            local dmg = arm.dmg
            process_score(action, pid, troop.owner_uid, dmg)
        end
    end
end


function process_score(action, ...)
    if cross_act.act_state ~= CROSS_STATE.FIGHT then
        return
    end

    do_score[action](action, ...)

end

function upload_act_score(action, val, ...)
    local center_id = 999
    local pack = pack(...)
    Rpc:callAgent(center_id, "upload_act_score", action, val, pack)
end

do_score = {}

do_score[RANK_ACTION.NORMAL] = function (action, pid, uid, dmg)

    local score = dmg
    local ply = getPlayer(pid)
    local gs_id = ply.map

    if ply and check_ply_cross(ply) then
        upload_act_score(action, score, pid, uid, gs_id)
    end

end

do_score[RANK_ACTION.CURE] = function (action, pid, uid, dmg)

    local score = dmg * 0.86
    local ply = getPlayer(pid)
    local gs_id = ply.map

    if ply and check_ply_cross(ply) then
        upload_act_score(action, score, pid, uid, gs_id)
    end

end

do_score[RANK_ACTION.NPC_DMG] = function (action, pid, uid, dmg)

    local score = dmg * 0.11
    local ply = getPlayer(pid)
    local gs_id = ply.map

    if ply and check_ply_cross(ply) then
        upload_act_score(action, score, pid, uid, gs_id)
    end

end

do_score[RANK_ACTION.KING_DMG] = function (action, pid, uid, dmg)

    local score = dmg * 7.5
    local ply = getPlayer(pid)
    local gs_id = ply.map

    if ply and check_ply_cross(ply) then
        upload_act_score(action, score, pid, uid, gs_id)
    end

end

do_score[RANK_ACTION.NPC_ACT] = function (action, uid, propid)

    local union = unionmng.get_union(uid)

    if union and check_union_cross(union) then
        local prop = resmng.prop_world_unit[propid]
        if prop then
            local score = prop.CrossScore
            local gs_id = union.map_id
            upload_act_score(action, score, uid, gs_id)
        end
    end

end

do_score[RANK_ACTION.KING_ACT] = function (action, uid, propid)

    local union = unionmng.get_union(uid)

    if union and check_union_cross(union) then
        local prop = resmng.prop_world_unit[propid]
        if prop then
            local score = prop.CrossScore
            local gs_id = union.map_id
            upload_act_score(action, score, uid, gs_id)
        end
    end

end
