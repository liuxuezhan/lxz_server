module("union_hall_t", package.seeall)

union_battle_room = union_battle_room or {}
battle_id_counter = battle_id_counter or 0

function load_data(data)
    local id = data._id
    local troop = troop_mng.get_troop(id)
    if troop then
        union_battle_room[id] = data
        local A = get_ety(troop.owner_eid)
        if A then
            local union = unionmng.get_union(A.uid)
            if union then union:add_room_id(id) end
        end

        local A = get_ety(troop.target_eid)
        if A then
            if not A.rooms then A.rooms = {} end
            table.insert(A.rooms, id)
            local union = unionmng.get_union(A.uid)
            if union then union:add_room_id(id) end
        end
    end

    --local ack_union = unionmng.get_union(data.ack_uid)
    --if ack_union ~= nil then
    --    ack_union:add_room_id(data._id)
    --end
    --local defense_union = unionmng.get_union(data.defense_uid)
    --if defense_union ~= nil then
    --    defense_union:add_room_id(data._id)
    --end
end

function generate_battle_id()
    for i = 1, 10000 do 
        battle_id_counter = battle_id_counter + 1
        if battle_id_counter > 10000 then 
            battle_id_counter = 1 
        end
        if union_battle_room[battle_id_counter] == nil then
            return battle_id_counter
        end
    end
end

function get_battle_room(room_id)
    return  troop_mng.get_troop(room_id) and union_battle_room[room_id]
end

--function battle_room_update(mode, troopA, troopD)
--    --local id = string.format("%d_%d", troopA._id, troopD._id)
--    local id = troopA._id
--    local room = union_battle_room[ id ]
--    if not room then return end
--
--    local union = unionmng.get_union(room.ack_uid)
--    if union then union:notifyall("battle_room", mode, {["room_id"]=id}) end
--    
--    union = unionmng.get_union(room.defense_uid)
--    if union then union:notifyall("battle_room", mode, {["room_id"]=id}) end
--end
--

function battle_room_update(mode, troop)
    local id = troop._id
    local room = union_battle_room[ troop._id ]
    if not room then return end
    room.info = nil
    room.detail = nil

    local A = get_ety(troop.owner_eid)
    if A then
        local union = unionmng.get_union(A.uid)
        if union then
            if union then union:notifyall("battle_room", mode, {["room_id"]=id}) end
        end
    end

    local A = get_ety(troop.target_eid)
    if A then
        local union = unionmng.get_union(A.uid)
        if union then
            if union then union:notifyall("battle_room", mode, {["room_id"]=id}) end
        end
    end
end


function battle_room_update_ety(mode, ety)
    for _, rid in pairs(ety.rooms or {}) do
        local troop = troop_mng.get_troop(rid) 
        if troop then
            battle_room_update(mode, troop)
        end
    end
end


function battle_room_create(troopA)
    local id = troopA._id
    local room = {}
    room._id = id
    room.ack_uid = troopA.owner_uid
    room.ack_troop_id = troopA._id
    room.is_mass = troopA.is_mass or 0
    
    --todo
    union_battle_room[id] = room
    gPendingSave.room[id] = room

    local union = unionmng.get_union(troopA.owner_uid)
    if union then 
        union:add_room_id(id) 
        union:notifyall("battle_room", OPERATOR.ADD, {room_id=id})
    end

    local D = get_ety(troopA.target_eid)
    if D then
        room.def_eid = D.eid
        if not D.rooms then D.rooms = {} end
        table.insert(D.rooms, id)

        local union = unionmng.get_union(D.uid)
        if union then 
            room.defense_uid = union._id
            union:add_room_id(id) 
            union:notifyall("battle_room", OPERATOR.ADD, {room_id=id})
        end
        local troopD = troop_mng.get_my_troop(D)
        if troopD then room.defense_troop_id = troopD._id end
    end
end


function battle_room_remove(troopA)
    local id = troopA._id
    local room = union_battle_room[ id ]
    if not room then return end

    union_battle_room[id] = nil
    gPendingDelete.room[id] = 1

    local union = unionmng.get_union(troopA.owner_uid)
    if union then 
        if remove_id(union.battle_room_ids or {}, id) then union:notifyall("battle_room", OPERATOR.DELETE, {room_id=id}) end
    end

    local D = get_ety(troopA.target_eid)
    if D then 
        remove_id(D.rooms or {}, id) 
        union = unionmng.get_union(D.uid)
        if union then
            if remove_id(union.battle_room_ids or {}, id) then union:notifyall("battle_room", OPERATOR.DELETE, {room_id=id}) end
        end
    end
end

