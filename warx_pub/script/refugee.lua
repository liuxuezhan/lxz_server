module("refugee", package.seeall)

grabbing_refugee = grabbing_refugee or {}
act_state = act_state or 0
zone_entities = zone_entities or {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
}

--[[
entities_by_lv = entities_by_lv or {
    [1] = {},
    [2] = {},
    [3] = {},
}
--]]

loop_count = 100
total_count = 0
respawn_limit = {}
zone_district = zone_district

module_class("refugee", { 
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    propid = 0,
    uid = 0,
    pid = 0,
    my_troop_id = 0,
    size = 0,
    val = 0,
    extra = {},
})

function on_reload()
    respawn_limit = {}
    total_count = 0
    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == EidType.Refugee then
            local zone_limit = respawn_limit[v.Mode] or {}
            zone_limit[v.Lv] = v.Range
            total_count = total_count + v.Range

            respawn_limit[v.Mode] = zone_limit
        end
    end
    if not zone_district then
        zone_district = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
            [6] = {},
        }
        for x = 0, 79 do
            for y = 0, 79 do
                local zone_lv = c_get_zone_lv(x, y)
                if zone_lv > 0 and zone_lv <= 6 then
                    table.insert(zone_district[zone_lv], {x, y})
                end
            end
        end
    end
end

function checkin(m)
    local prop = resmng.prop_world_unit[m.propid]
    local node = zone_entities[prop.Mode][prop.Lv]
    if not node then
        node = {}
        zone_entities[prop.Mode][prop.Lv] = node
    end
    table.insert(node, m.eid)
    INFO("check in refugee %d|%d|%d in %d|%d", m.eid, m.x, m.y, prop.Mode, prop.Lv)

    --[[
    local entities = entities_by_lv[prop.Lv] or {}
    entities_by_lv[prop.Lv] = entities
    local zone_x = math.floor(m.x / 16)
    local zone_y = math.floor(m.y / 16)
    local index = zone_y * 1000 + zone_x
    if not entities[index] then
        entities[index] = {}
    end
    table.insert(entities[index], m.eid)
    --]]
end

function respawn(prop, tx, ty)
    local eid = get_eid_refugee()
    if eid then
        local x, y = c_get_pos_in_zone(tx, ty, prop.Size, prop.Size)
        if x then
            local obj = {_id=eid, eid=eid, x=x, y=y, propid=prop.ID, size=prop.Size, born=gTime, val=prop.Count, pid=0, uid=0, extra={} }

            obj = new(obj)
            gEtys[ eid ] = obj
            etypipe.add(obj)
            checkin(obj)
        end
    end
end

function load_from_db()
    local db = dbmng:getOne()
    db.refugee:delete( { pid = 0 } )

    local info = db.refugee:find({})
    while info:hasNext() do
        local m = refugee.wrap(info:next())
        if m.eid then 
            gEtys[ m.eid ] = m
            if not m.extra then m.extra = {} end
            etypipe.add(m)
            checkin(m)
        end
    end
end

function create_refugee(zone_lv, res_lv)
    local district = zone_district[zone_lv]
    local zone_index = math.random(#district)
    local zone_info = district[zone_index]
    local zone_x, zone_y = zone_info[1], zone_info[2]

    local access = c_get_map_access(zone_x, zone_y)
    --if math.abs(gTime - access) > 3600 then
    --else
        local propid = EidType.Refugee * 1000000 + zone_lv * 1000 + res_lv
        local prop = resmng.prop_world_unit[propid]
        respawn(prop, zone_x, zone_y)
    --end
end

function loop()
    if act_state ~= CROSS_STATE.FIGHT then
        return
    end

    local ratio = loop_count / total_count
    for zone_lv, zone_limits in pairs(respawn_limit) do
        for res_lv, limit in pairs(zone_limits) do
            local count = 0
            if zone_entities[zone_lv][res_lv] then
                count = #zone_entities[zone_lv][res_lv]
            end
            local max_limit = math.min(math.ceil(limit * ratio), limit - count or 0)
            for i = 1, max_limit do
                create_refugee(zone_lv, res_lv)
            end
        end
    end
end

function get_my_troop(self)
    return troop_mng.get_troop(self.my_troop_id)
end

function start_grab(self, troop)
    troop.extra = {}
    troop:recalc()
    troop.tmStart = gTime

    self.my_troop_id = troop._id

    local speed = troop:get_extra("speed")
    local count = troop:get_extra("count")
    if count > self.val then
        count = self.val
        troop:set_extra("count", count)
    end
    local dura = math.max(math.ceil((count - troop:get_extra("cache")) / speed), 1)
    troop.tmOver = gTime + dura
    troop.tmSn = timer.new("troop_action", dura, troop._id)

    local player = getPlayer(troop.owner_pid)
    if player then
        self.pid = player.pid
        self.uid = player.uid
    else
        self.pid = 0
        self.uid = 0
        WARN("did not find ply who occupied refugee")
    end
    self.extra = {
        speed = speed,
        start = gTime,
        count = self.val - troop:get_extra("cache"),
        tm = gTime,
        tid = troop._id,
    }

    self:set_timer()
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, self)
    etypipe.add(self)
    grabbing_refugee[self.eid] = self.eid
end

function on_exhaust(self)
    local prop = resmng.prop_world_unit[self.propid]

    --[[
    local zone_x = math.floor(self.x / 16)
    local zone_y = math.floor(self.y / 16)
    local index = zone_y * 1000 + zone_x
    for k, v in pairs(entities_by_lv[prop.Lv][index] or {}) do
        if v == self.eid then
            table.remove(entities_by_lv[prop.Lv][index], k)
            break
        end
    end
    --]]

    for k, v in pairs(zone_entities[prop.Mode][prop.Lv]) do
        if v == self.eid then
            table.remove(zone_entities[prop.Mode][prop.Lv], k)
            break
        end
    end
    rem_ety(self.eid)
    self:clr()
end

function on_refugee_stop(self)
    self:clear_timer()
    grabbing_refugee[self.eid] = nil
end

function clear_timer(self)
    if self.extra.gift_timer then
        timer.del(self.extra.gift_timer)
        self.extra.gift_timer = nil
    end
end

function set_timer(self)
    self:clear_timer()
    self.extra.gift_timer = timer.cycle("refugee_gift", 5 * 60, self.eid, self.pid)
    self.extra.gift_count = 0
end

function refugee_gift(self, pid)
    if self.pid ~= pid then
        return
    end

    local player = getPlayer(self.pid)
    if not player then
        return
    end

    local prop = resmng.prop_world_unit[self.propid]
    local index = 1
    if check_ply_cross(player) then
        index = 2
    end
    player:add_bonus(prop.Fix_award[index][1], prop.Fix_award[index][2], VALUE_CHANGE_REASON.REASON_CROSS_PERSONAL_AWARD)

    self.extra.gift_count = self.extra.gift_count + 1
    self.extra = self.extra
    return 1
end

function clear_all_refugee()
    for zone_lv, district_entities in pairs(zone_entities) do
        for lv, entities in pairs(district_entities) do
            for k, eid in pairs(entities) do
                local ety = get_ety(eid)
                if ety then
                    local troop = ety:get_my_troop()
                    if troop then
                        troop:refugee_stop()
                    end
                    rem_ety(ety.eid)
                    ety:clr()
                end
            end
        end
        zone_entities[zone_lv] = {}
    end
end

function send_refugee_info(player)
    info = {}
    for _, eid in pairs(grabbing_refugee) do
        local ety = get_ety(eid)
        if ety then
            local data = {
                gid = gMapID,
                x = ety.x,
                y = ety.y,
                propid = ety.propid,
                gift_count = ety.extra.gift_count,
                mode = 0,
            }
            if check_ply_cross(player) then
                data.mode = 1
            end
            local tm = timer.get(ety.timers)
            if tm then
                data.start = tm.start
                data.over = tm.over
            end
            tm = timer.get(ety.extra.gift_timer)
            if tm then
                data.gift_start = tm.start
                data.gift_over = tm.over
            end
            table.insert(info, data)
        end
    end
    Rpc:cross_refugee_info_ack(player, cross_act.tm_over, info)
end

--[[
function find_refugee_from_pos(pos_x, pos_y, level)
    local zone_x = math.floor(pos_x / 16)
    local zone_y = math.floor(pos_y / 16)
    local entities = entities_by_lv[level]
    if not entities then
        return
    end
    for x, y in spin_zones(4) do
        local new_x = zone_x + x
        local new_y = zone_y + y
        if new_x > 0 and new_x < 80 and new_y > 0 and new_y < 80 then
            local index = new_y * 1000 + new_x
            if entities[index] and #entities[index] > 0 then
                local eid = entities[index][math.random(#entities[index])]
                if eid then
                    return get_ety(eid)
                end
            end
        end
    end
end
--]]

function dump_all_refugee()
    WARN("========================== Dumping all refugee")
    local total_count = 0
    for zone_lv, district_entities in pairs(zone_entities) do
        for lv, entities in pairs(district_entities) do
            local count = #entities
            total_count = total_count + count
            WARN("\tThere is %d entity of %d|%d", count, zone_lv, lv)
        end
    end
    WARN("========================== Dump all refugee done, %d|%d", total_count, act_state)
end

