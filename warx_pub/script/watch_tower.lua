module("watch_tower", package.seeall)

function watchtower_get_attacked_info(player, msg_send, all_info)
    local b = player:get_watchtower()
    local cur_watchtower_lv = 1
    if b ~= nil then
        local prop_tab = resmng.prop_build[b.propid]
        if prop_tab ~= nil then
            cur_watchtower_lv = prop_tab.Lv
        end
    end
    --cur_watchtower_lv = 29
    for i = 0, cur_watchtower_lv, 1 do
        if watchtower_attacked[i] ~= nil then
            watchtower_attacked[i](msg_send, all_info)
        end
    end
end

watchtower_attacked = {}
watchtower_attacked[1] = function(msg, src)
    msg.data_id = src.data_id
    msg.owner_pid = src.owner_pid
    msg.owner_propid = src.owner_propid
    msg.owner_photo = src.owner_photo
    msg.owner_name = src.owner_name
    msg.owner_castle = src.owner_castle or nil
    msg.owner_union_name = src.owner_union_name
    msg.action = src.action
    msg.is_mass = src.is_mass
    msg.load = src.load or nil
    msg.target = copyTab(src.target)
end

watchtower_attacked[3] = function(msg, src)
    msg.owner_pos = copyTab(src.owner_pos)
end

watchtower_attacked[5] = function(msg, src)
    msg.arrived_time = src.arrived_time
end

watchtower_attacked[7] = function(msg, src)
    msg.arms_num = src.arms_num
end

watchtower_attacked[9] = function(msg, src)
    msg.heros = copyTab(src.heros)
end

watchtower_attacked[11] = function(msg, src)
    msg.arms = copyTab(src.arms)
end

watchtower_attacked[13] = function(msg, src)
    msg.arms = copyTab(src.arms)
end

watchtower_attacked[15] = function(msg, src)
    msg.genius = copyTab(src.genius)
end

watchtower_attacked[26] = function(msg, src)
    msg.tech = copyTab(src.tech)
end

watchtower_attacked[29] = function(msg, src)
    msg.equip = copyTab(src.equip)
end

function get_watchtower_info(troop, dest_load, player)
    local base_action = troop:get_base_action()
    if WatchTowerAction[base_action] == nil then
        return
    end

    local ack = get_ety(troop.owner_eid)
    local def = get_ety(troop.target_eid)
    if ack == nil or def == nil then
        return
    end
    local recv_ply = player
    if is_ply(def) then
        recv_ply = def
        --pack_data(def)
    else
        local tmp_ply = getPlayer(def.pid)
        if tmp_ply ~= nil then
            recv_ply = tmp_ply
            --pack_data(tmp_ply)
        end
    end
    if recv_ply == nil or recv_ply:is_online() == false then
        return
    end


    local ack_info = {}
    ack_info.data_id = troop._id
    ack_info.owner_pid = ack.pid or 0
    ack_info.owner_photo = ack.photo or 0
    ack_info.owner_name = ack.name or ""
    ack_info.owner_propid = ack.propid
    ack_info.owner_pos = {}
    ack_info.owner_pos[1] = troop.sx
    ack_info.owner_pos[2] = troop.sy
    ack_info.is_mass = troop.is_mass or 0

    local owner_union = unionmng.get_union(troop.owner_uid)
    if owner_union ~= nil then
        ack_info.owner_union_sn = owner_union.new_union_sn
        ack_info.owner_union_name = owner_union.alias
    end
    ack_info.load = dest_load

    ack_info.target = {}
    if is_ply(def) then
        ack_info.target.is_castle = 1
    end
    ack_info.target.prop_id = def.propid
    ack_info.target.pos = {}
    ack_info.target.pos[1] = troop.dx
    ack_info.target.pos[2] = troop.dy
    local target_union = unionmng.get_union(troop.target_uid)
    if target_union ~= nil then
        ack_info.target_union_name = target_union.alias
    end

    ack_info.arrived_time = {troop.tmStart, troop.tmOver}
    ack_info.action = troop:get_base_action()

    local owner_arms = troop:get_arm_by_pid(ack_info.owner_pid)
    if not owner_arms then
        WARN( "troop = %d, action = %d, pid = %d", troop._id, troop.action, ack_info.owner_pid )
    else
        ack_info.heros = {}
        for k, v in pairs(owner_arms.heros or {}) do
            if v ~= 0 then
                if ack_info.owner_pid == 0 then --怪物部队
                    local prop_boss_hero = resmng.get_conf("prop_boss_hero", v)
                    if prop_boss_hero then
                        table.insert(ack_info.heros, {prop_boss_hero.PropID, prop_boss_hero.Lv, prop_boss_hero.Star})
                    end
                else
                    local hero_data = heromng.get_hero_by_uniq_id(v)
                    if hero_data then
                        table.insert(ack_info.heros, {hero_data.propid, hero_data.lv, hero_data.star})
                    else
                        WARN("can not get hero, id = %s", v)
                    end
                end
            end
        end
    end

    ack_info.arms = {}
    ack_info.arms_num = 0

    for k, v in pairs(troop.arms or {}) do
        for i, j in pairs(v.live_soldier or {}) do
            if ack_info.arms[i] == nil then
                ack_info.arms[i] = 0
            end
            ack_info.arms[i] = ack_info.arms[i] + j
            ack_info.arms_num = ack_info.arms_num + j
        end
    end
    if ack_info.action == TroopAction.SupportArm then
        ack_info.load = ack_info.arms_num
        --ack_info.load = ack_info
    end


    if is_ply(ack) then
        ack_info.genius = {}
        table.insert(ack_info.genius, {1,0})
        table.insert(ack_info.genius, {2,0})
        table.insert(ack_info.genius, {3,0})
        for k, v in pairs(ack.genius) do
            local prop_tab = resmng.prop_genius[v]
            local class = prop_tab.Class
            if class == 1 then
                ack_info.genius[1][2] = ack_info.genius[1][2] + prop_tab.Lv
            elseif class == 2 then
                ack_info.genius[2][2] = ack_info.genius[2][2] + prop_tab.Lv
            elseif class == 3 then
                ack_info.genius[3][2] = ack_info.genius[3][2] + prop_tab.Lv
            end
        end

        ack_info.tech = {}
        for k, v in pairs(ack.tech) do
            table.insert(ack_info.tech, v)
        end

        ack_info.equip = {}
        for k, v in pairs(ack._equip) do
            table.insert(ack_info.equip, v.propid)
        end

        --主城等级
        ack_info.owner_castle = ack:get_castle_lv()
    end

    local msg_watch = {}
    watchtower_get_attacked_info(recv_ply, msg_watch, ack_info)
    Rpc:add_compensation_info(recv_ply, msg_watch)
end

function fill_watchtower_info(troop)
    if troop == nil or troop:is_back() == true then
        return
    end

    local base_action = troop:get_base_action()
    if WatchTowerAction[base_action] == nil then
        return
    end

    local dest_load = nil
    if base_action == TroopAction.SupportRes then --如果是物资援助，要把负重算出来
        dest_load = {}
        for k, v in pairs(troop.goods or {}) do
            if v[3] > 0 then
                --dest_load = dest_load + math.floor(v[3] * RES_RATE[k])
                dest_load[ k ] = v
            end
        end
    end

    get_watchtower_info(troop, dest_load)
end

function packet_watchtower_info(player)
    --向自己行军的
    for k, v in pairs(player.troop_comings or {}) do
        local troop = troop_mng.get_troop(k)
        fill_watchtower_info(troop)
    end

    --向驻扎建筑行军的
    local function is_build(build)
        if build == nil then
            return false
        end
        if is_ply(build) then
            return false
        end
        if build.pid == nil then
            return true
        end

        if build.pid >= 10000 then
            return false
        end
        return true
    end

    for k, v in pairs(player.busy_troop_ids or {}) do
        local temp_troop = troop_mng.get_troop(v)
        if temp_troop ~= nil and temp_troop:is_settle() == true then
            local build = get_ety(temp_troop.target_eid)
            if is_build(build) == true then
                for id, action in pairs(build.troop_comings or {}) do
                    local troop = troop_mng.get_troop(id)
                    if troop then
                        if troop.owner_uid ~= player.uid then
                            get_watchtower_info(troop, nil, player)
                        end
                    end
                end
            end
        end
    end
end

function rm_watchtower_info(troop)
    local dest = get_ety(troop.target_eid)
    if is_ply(dest) then
        Rpc:rm_compensation_info(dest, troop._id)
    else
        local tr = troop_mng.get_troop(dest.my_troop_id)
        if tr then
            for pid , _ in pairs(tr.arms or {}) do
                local ply = getPlayer(pid)
                if ply then
                    Rpc:rm_compensation_info(ply, troop._id)
                end
            end
        end

        local ply = getPlayer(dest.pid)
        if ply == nil then
            return
        end
        Rpc:rm_compensation_info(ply, troop._id)
    end

    --[[
    local ply = nil
    ply = getPlayer(troop.target_pid)
    if ply == nil then
        local ety = get_ety(troop.target_eid)
    end
    if ply == nil then
        return
    end

    Rpc:rm_compensation_info(ply, troop._id)
    --]]
end

function update_watchtower_speed(troop)
    local action = troop:get_base_action()

    if WatchTowerAction[action] == nil then
        return
    end
    local dest = get_ety(troop.target_eid)
    if not dest then return end
    local recv_ply = nil
    if is_ply(dest) then
        recv_ply = dest
    else
        local tmp_ply = getPlayer(dest.pid)
        if tmp_ply ~= nil then
            recv_ply = tmp_ply
        else
            --给建筑里面的所有人发
            local hold_troop = troop_mng.get_troop(dest.my_troop_id)
            if hold_troop == nil then
                return
            end
            for k, v in pairs(hold_troop.arms or {}) do
                if k ~= 0 then
                    local ply = getPlayer(k)
                    if ply ~= nil then
                        local b = ply:get_watchtower()
                        local cur_watchtower_lv = 1
                        if b ~= nil then
                            local prop_tab = resmng.prop_build[b.propid]
                            if prop_tab ~= nil then
                                cur_watchtower_lv = prop_tab.Lv
                            end
                        end
                        if cur_watchtower_lv >= 5 then
                            Rpc:update_compensation_info(ply, troop._id, troop.tmOver)
                        end
                    end
                end
            end
            return
        end
    end

    if recv_ply then
        local b = recv_ply:get_watchtower()
        local cur_watchtower_lv = 1
        if b ~= nil then
            local prop_tab = resmng.prop_build[b.propid]
            if prop_tab ~= nil then
                cur_watchtower_lv = prop_tab.Lv
            end
        end
        if cur_watchtower_lv >= 5 then
            Rpc:update_compensation_info(recv_ply, troop._id, troop.tmOver)
        end
    end
end

--进攻建筑
function building_troop_add(build, troop)
    if troop == nil or troop:is_back() == true then
        return
    end
    local base_action = troop:get_base_action()
    if WatchTowerAction[base_action] == nil then
        return
    end

    if build.uid == troop.owner_uid then
        return
    end

    local hold_troop = troop_mng.get_troop(build.my_troop_id)
    if hold_troop == nil then
        return
    end

    for k, v in pairs(hold_troop.arms or {}) do
        if k ~= 0 then
            local ply = getPlayer(k)
            if ply ~= nil then
                get_watchtower_info(troop, nil, ply)
            end
        end
    end
end

--进攻方部队返回
function building_ack_recall(build, troop)
    if build.uid == troop.owner_uid then
        return
    end

    local hold_troop = troop_mng.get_troop(build.my_troop_id)
    if hold_troop == nil then
        return
    end

    for k, v in pairs(hold_troop.arms or {}) do
        if k ~= 0 then
            local ply = getPlayer(k)
            if ply ~= nil then
                Rpc:rm_compensation_info(ply, troop._id)
            end
        end
    end
end

--防守方部队返回
function building_def_recall(ply, build)
    for k, v in pairs(build.troop_comings or {}) do
        Rpc:rm_compensation_info(ply, k)
    end
end

--部队到达
function building_arrive(build, troop)
    if troop == nil or troop:is_back() == true then
        return
    end
    local action = troop:get_base_action()
    if WatchTowerAction[action] == nil then
        return
    end
    if build.uid == troop.owner_uid then
        for id, action in pairs(build.troop_comings or {}) do
            local coming_troop = troop_mng.get_troop(id)
            if coming_troop ~= nil then
                if coming_troop.owner_uid ~= troop.owner_uid then
                    for k, v in pairs(troop.arms or {}) do
                        local ply = getPlayer(k)
                        if ply ~= nil then
                            get_watchtower_info(coming_troop, nil, ply)
                        end
                    end
                end
            end
        end
    else
        local hold_troop = troop_mng.get_troop(build.my_troop_id)
        if hold_troop == nil then
            return
        end

        for k, v in pairs(hold_troop.arms or {}) do
            if k ~= 0 then
                local ply = getPlayer(k)
                if ply ~= nil then
                    Rpc:rm_compensation_info(ply, troop._id)
                end
            end
        end
    end
end

function building_recalc(build)
    local hold_troop = troop_mng.get_troop(build.my_troop_id)
    if hold_troop == nil then
        return
    end
    for id, action in pairs(build.troop_comings or {}) do
        local troop = troop_mng.get_troop(id)
        if troop and troop.owner_pid ~= hold_troop.owner_pid then
            if troop.owner_uid ~= hold_troop.owner_uid or (troop.owner_uid == 0 and hold_troop.owner_uid == 0 ) then
                for k, v in pairs(hold_troop.arms or {}) do
                    if k ~= 0 then
                        local ply = getPlayer(k)
                        if ply ~= nil then
                            get_watchtower_info(troop, nil, ply)
                        end
                    end
                end
            end
        end
    end
end

function building_hold_full(build, troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then
        return
    end
    for id, action in pairs(build.troop_comings or {}) do
        local coming = troop_mng.get_troop(id)
        if coming and coming.owner_uid ~= troop.owner_uid then
            Rpc:rm_compensation_info(ply, coming._id)
        end
    end
end

function building_def_clear(build, troop)
    if not troop then
        return
    end
    for id, action in pairs(build.troop_comings or {}) do
        local coming = troop_mng.get_troop(id)
        for k, v in pairs(troop.arms or {}) do
            if k ~= 0 then
                local ply = getPlayer(k)
                if ply ~= nil then
                    Rpc:rm_compensation_info(ply, id)
                end
            end
        end
    end
end


