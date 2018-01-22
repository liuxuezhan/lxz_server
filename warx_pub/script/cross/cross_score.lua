module("cross_score", package.seeall)

function process_troop(action, attack_troop, defense_troop)
    if cross_act.act_state ~= CROSS_STATE.FIGHT then
        return
    end

    if 0 == attack_troop.owner_pid then
        return
    end
    local attacker = getPlayer(attack_troop.owner_pid)
    if not attacker then
        return
    end

    if 0 == defense_troop.owner_pid then
        return
    end
    local defender = getPlayer(defense_troop.owner_pid)
    if not defender then
        return
    end
    -- 双方玩家为同一服务器时，不进行积分处理
    if attacker.emap == defender.emap then
        return
    end
    -- 攻方部队
    for pid, arm in pairs(attack_troop.arms or {}) do
        process_score(action, pid, attack_troop.owner_uid, arm.mkdmg or 0)
    end
    -- 守方部队
    for pid, arm in pairs(defense_troop.arms or {}) do
        process_score(action, pid, defense_troop.owner_uid, arm.mkdmg or 0)
    end
end


function process_score(action, ...)
    if cross_act.act_state ~= CROSS_STATE.FIGHT then
        return
    end

    do_score[action](action, ...)
end

function upload_act_score(action, gs_id, val, ...)
    local pack = { ... } or {}
    Rpc:callAgent(gCenterID, "upload_act_score", action, gs_id, val, pack)
end

local scale_array =
{
    {
        [RANK_ACTION.NORMAL] = 1,
        [RANK_ACTION.NPC_DMG] = 0.11,
        [RANK_ACTION.KING_DMG] = 1.5,
    },
    {
        [RANK_ACTION.NORMAL] = 1 * 1.5,
        [RANK_ACTION.NPC_DMG] = 0.11 * 1.5,
        [RANK_ACTION.KING_DMG] = 1.5 * 1.5,
    },
}

function get_score_scale(player, action)
    local index = check_ply_cross(player) and 2 or 1
    return scale_array[index][action] or 1
end

do_score = {}

do_score[RANK_ACTION.NORMAL] = function (action, pid, uid, dmg)
    local player = getPlayer(pid)
    if not player then
        return
    end

    local scale = get_score_scale(player, action)
    local score = math.floor(dmg * scale)
    player:add_cross_score(score)
    upload_act_score(action, player.emap, score, pid, uid)
end

do_score[RANK_ACTION.CURE] = function (action, pid, uid, dmg)
    local score = math.floor(dmg * 0.86)
    local ply = getPlayer(pid)
    local gs_id = ply.emap

    if ply and check_ply_cross(ply) then
        ply:add_cross_score(score)
        upload_act_score(action, gs_id, score, pid, uid)
    end
end

do_score[RANK_ACTION.NPC_DMG] = function (action, pid, uid, dmg)
    local player = getPlayer(pid)
    if not player then
        return
    end

    local scale = get_score_scale(player, action)
    local score = math.floor(dmg * 0.11 * scale)
    player:add_cross_score(score)
    upload_act_score(action, player.emap, score, pid, uid)
end

do_score[RANK_ACTION.KING_DMG] = function (action, pid, uid, dmg)
    local player = getPlayer(pid)
    if not player then
        return
    end

    local scale = get_score_scale(player, action)
    local score = math.floor(dmg * scale)
    player:add_cross_score(score)
    upload_act_score(action, player.emap, score, pid, uid)
end

do_score[RANK_ACTION.NPC_ACT] = function (action, uid, propid)
    local union = unionmng.get_union(uid)

    if union and check_union_cross(union) then
        local prop = resmng.prop_world_unit[propid]
        if prop then
            local score = prop.CrossScore
            local gs_id = union.map_id
            upload_act_score(action, gs_id, score, uid)
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
            upload_act_score(action, gs_id, score, uid)
        end
    end
end

