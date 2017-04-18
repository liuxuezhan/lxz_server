module("union_hall_t", package.seeall)

union_battle_room = union_battle_room or {}
battle_id_counter = battle_id_counter or 0

function load_data(data)
    local id = data._id
    local troop = troop_mng.get_troop(id)
    if troop then
        if troop:is_ready() or troop:is_go() then
            union_battle_room[id] = data
            local A = get_ety(troop.owner_eid)
            if A then
                local union = unionmng.get_union(A.uid)
                if union then setIns( union.battle_room_ids, id) end
            end

            local A = get_ety(troop.target_eid)
            if A then
                if not A.rooms then A.rooms = {} end
                table.insert(A.rooms, id)
                local union = unionmng.get_union(A.uid)
                if union then  setIns( union.battle_room_ids, id) end
            end
            return
        end
    end
    gPendingDelete.room[ id ] = 1
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

function battle_room_update(mode, troop)
    local id = troop._id
    local room = union_battle_room[ troop._id ]
    if not room then return end

    local A = get_ety(troop.owner_eid)
    if A then
        local union = unionmng.get_union(A.uid)
        if union then
            if setIns( union.battle_room_ids, id ) then
                local info = player_t.make_room_list( troop )
                info.id = troop._id
                union.battle_list = nil
                union:notifyall("battle_room", OPERATOR.ADD, {room_id=id, list=info})
            else
                union:notifyall("battle_room", mode, {["room_id"]=id})
            end
        end
    end

    local A = get_ety(troop.target_eid)
    if A then
        local union = unionmng.get_union(A.uid)
        if union then
            if setIns( union.battle_room_ids, id ) then
                local info = player_t.make_room_list( troop )
                info.id = troop._id
                union.battle_list = nil
                union:notifyall("battle_room", OPERATOR.ADD, {room_id=id, list=info})
            else
                union:notifyall("battle_room", mode, {room_id=id, action=troop.action })
            end
        end
    end
end


function battle_room_update_ety(mode, ety)
    if not ety then return end
    for _, rid in pairs(ety.rooms or {}) do
        local troop = troop_mng.get_troop(rid) 
        if troop then
            battle_room_update(mode, troop)
        end
    end
end


function battle_room_create(troopA, class)
    class = class or ROOM_TYPE.OTHER

    local id = troopA._id
    local room = {}
    room._id = id
    room.ack_uid = troopA.owner_uid
    room.ack_troop_id = troopA._id
    room.is_mass = troopA.is_mass or 0
    room.class = class
    
    --todo
    union_battle_room[id] = room
    gPendingSave.room[id] = room

    local info = player_t.make_room_list( troopA )
    info.id = troopA._id
    local union = unionmng.get_union(troopA.owner_uid)
    if union then 
        if setIns( union.battle_room_ids, id ) then
            union.battle_list = nil
            union:notifyall("battle_room", OPERATOR.ADD, {room_id=id, list=info})
        end
    end

    local D = get_ety(troopA.target_eid)
    if D then
        room.def_eid = D.eid
        if not D.rooms then D.rooms = {} end
        table.insert(D.rooms, id)

        local union = unionmng.get_union(D.uid)
        if union then 
            room.defense_uid = union._id
            if setIns( union.battle_room_ids, id ) then
                union.battle_list = nil
                union:notifyall("battle_room", OPERATOR.ADD, {room_id=id, list=info})
            end
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
        if setRem( union.battle_room_ids, id ) then
            union.battle_list = nil
            union:notifyall("battle_room", OPERATOR.DELETE, {room_id=id}) 
        end
    end

    local D = get_ety(troopA.target_eid)
    if D then 
        remove_id(D.rooms or {}, id) 
        union = unionmng.get_union(D.uid)
        if union then
            if setRem( union.battle_room_ids, id ) then
                union.battle_list = nil
                union:notifyall("battle_room", OPERATOR.DELETE, {room_id=id})
            end
        end
    end
end

function ety_rem_def(dest)
    local union = unionmng.get_union(dest.uid)
    if not union then
        return
    end

    for k, v in pairs(dest.rooms or {}) do
        if setRem( union.battle_room_ids, v ) then
            union.battle_list = nil
            union:notifyall("battle_room", OPERATOR.DELETE, {room_id=v}) 
        end
    end
end

function ety_add_def(dest)
    for k, v in pairs(dest.rooms or {}) do
        local tr = troop_mng.get_troop(v)
        tr.target_uid = dest.uid
        if tr then
            local atk_u = unionmng.get_union(tr.owner_uid)
            if atk_u then 
                if is_in_table( atk_u.battle_room_ids, v ) then
                    atk_u.battle_list = nil
                end
            end
            battle_room_update(OPERATOR.UPDATE, tr)
        end
    end
end
