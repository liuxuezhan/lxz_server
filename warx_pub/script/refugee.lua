module("refugee", package.seeall)

distrib = distrib or {}
grabbing_refugee = grabbing_refugee or {}
scan_id = scan_id or 0
act_state = act_state or 0

module_class("refugee", { 
    _id = 0,
    x = 0,
    y = 0,
    eid = 0,
    propid = 0,
    uid = 0,
    pid = 0,
    state = 1,
    start_time = 0,
    end_time = 0,
    my_troop_id = 0,
    size = 0,
    timers = 0,
    extra = {},
})

function checkin(m)
    local zx = math.floor(m.x / 16)
    local zy = math.floor(m.y / 16)
    local idx = zy * 80 + zx
    local node = distrib[ idx ]
    if not node then
        node = {}
        distrib[ idx ] = node
    end
    table.insert(node, m.eid)
end

function get_respawn_by_lv(lv)
    local node = resmng.prop_respawn_lv[ lv ]
    if node then
        rate = math.random(1, 100)
        local total = 0
        local c_lv = 1
        for k, v in pairs(node.Rates) do
            total = total + v
            if rate <= total then
                c_lv = k
            end
        end
    end

    c_lv = 1
    local mode = 1

    if c_lv then
        local id =  math.ceil(14000000 + mode * 1000 + c_lv)
        return resmng.prop_world_unit[ id ]
    end
end

function respawn(tx, ty)
    local lv = c_get_zone_lv(tx, ty)
    local prop = get_respawn_by_lv(lv)
    if prop then
        local eid = get_eid_refugee()
        if eid then
            local x, y = c_get_pos_in_zone(tx, ty, prop.Size, prop.Size)
            if x then
                local obj = {_id=eid, eid=eid, x=x, y=y, propid=prop.ID, size=prop.Size, born=gTime, val=prop.Count, pid=0, uid=0, extra={} }
                print("refugge x y", x, y)

                obj = new(obj)
                gEtys[ eid ] = obj
                etypipe.add(obj)
                checkin(obj)
            else
                --print("no room, tx=", tx, ", ty=", ty)
            end
        end
    end
end

function do_check(zx, zy, isloop)
    if act_state ~= CROSS_STATE.FIGHT then
        return
    end

    if zx >= 0 and zx < 80 and zy >= 0 and zy < 80 then
        local idx = zy * 80 + zx
        local node = distrib[ idx ]

        local news = {}
        for k, eid in pairs(node or {})  do
            local ety = get_ety(eid)
            if ety then
                if isloop and ety.pid == 0 and ety.born < gTime - 12 * 3600 then
                    rem_ety(eid)
                else
                    table.insert(news, eid)
                end
            end
        end
        distrib[ idx ] = news

        local num = #news
        local access = c_get_map_access(zx, zy)
        if math.abs(gTime - access) > 3600 then
            if num == 0 then
                distrib[ idx ] = nil
            end
        elseif num < 2 then
            for i = num+1, 2, 1 do
                respawn(zx, zy)
            end
        end
    end
end

function loop()
    local idx = scan_id
    for i = 1, 80, 1 do
        if idx >= 6400 then idx = 0 end
        if distrib[ idx ] then
            local zx = idx % 80
            local zy = math.floor(idx / 64)
            scan_id = idx
            do_check(zx, zy, true)
        end
        idx = idx + 1
    end
end

function add_ety()
end

function test()
    print("test farm")
    for i = 1, 32, 1 do
        respawn(0, 8)
    end
end

function mark(m)
    m.marktm = gTime
    gPendingInsert.refugee[ m.eid ] = m
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

function get_my_troop(self)
    return troop_mng.get_troop(self.my_troop_id)
end

function calc_grab(self)
    local troop = self:get_my_troop()
    if not troop then
        return
    end

    local extra = self.extra or {}
    local speed, count = troop:get_refugee_power()
    extra.speed = speed
    extra.count = count
    self.extra = extra
end

function start_grab(self, troop)
    self.my_troop_id = troop._id
    local player = getPlayer(troop.owner_pid)
    if player then
        self.pid = player.pid
        self.uid = player.uid
    else
        self.pid = 0
        self.uid = 0
        WARN("did not find ply who occupied refugee")
    end

    self:calc_grab()
    self:new_defender_state()
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, self)

    etypipe.add(self)
    grabbing_refugee[self.eid] = self.eid
end

function stop_grab(self)
    self:clear_timer()

    grabbing_refugee[self.eid] = nil

    local gain = math.ceil((self.extra.speed or 0) * (gTime - (self.extra.start or gTime)))
    if gain > self.val then
        gain = self.val
    end
    self.val = self.val - gain

    local player = getPlayer(self.pid)
    if player then
        Rpc:callAgent(gCenterID, "upload_refugee_score", player.map, player.pid, gain)
    end

    self.pid = 0
    self.uid = 0
    self.my_troop_id = 0
    self.extra = {}
    if self.val < 2 then
        local zx = mail.floor(self.x / 16)
        local zy = mail.floor(self.y / 16)
        local idx = zy * 80 + zx
        local node = distrib[idx]
        local new_node = {}
        for k, eid in pairs(node or {}) do
            if eid ~= self.eid then
                rem_ety(self.eid)
            else
                table.insert(new_node, eid)
            end
        end
        distrib[idx] = new_node

        respawn(math.floor(self.x / 16), math.floor(self.y / 16))
    else
        etypipe.add(self)
        self:mark()
    end
end

function new_defender_state(self)
    self:clear_timer()
    self:set_timer(1)
    self.start_time = gTime
    local time = resmng.prop_world_unit[self.propid].Spantime
    -- to do
    self.end_time = gTime + time 
end

function clear_timer(self)
    if self.timers then
        timer.del(self.timers)
        self.timers = 0
    end
    if self.extra.gift_timer then
        timer.del(self.extra.gift_timer)
        self.extra.gift_timer = nil
    end
    self.state = 0
    self.start_time = 0
    self.end_time = 0
end

function set_timer(self, state)
    if state == nil then
        state = self.state
    end

    local troop = self:get_my_troop()
    if not troop then
        return
    end
    self:calc_grab()

    local dura = math.ceil(self.extra.count / self.extra.speed)
    local timer_id = timer.new("refugee", dura, state, self.eid)
    self.timers = timer_id

    timer_id = timer.cycle("refugee_gift", 10 * 60, state, self.eid, self.pid)
    self.extra.gift_timer = timer_id
    self.extra.gift_count = 0
end

function finish_grab(self)
    if 0 == self.state then
        return
    end

    local troop = self:get_my_troop()
    if troop then
        troop:back()
    end

    self:stop_grab()
end

function refugee_gift(self, pid)
    if self.pid ~= pid then
        return
    end

    local player = getPlayer(self.pid)
    if not player then
        return
    end
    local item_id = SETTLE_REFUGEE_GIFT
    if check_ply_cross(player) then
        item_id = ENSLAVE_REFUGEE_GIFT
    end
    player:add_bonus("mutex_award", {{"item", item_id, 1, 10000}}, VALUE_CHANGE_REASON.REASON_CROSS_PERSONAL_AWARD)

    self.extra.gift_count = self.extra.gift_count + 1
    return 1
end

function post_refugee_score(pid, eid, propid)
    local pack = {}
    pack.mode = ACT_NAME.REFUGEE
    local info = {pid = pid, eid = eid, propid = propid}
    pack.info = info
    Rpc:callAgent(gCenterID, "post_cross_score", pack)
end

function loop()
    local idx = scan_id
    for i = 1, 80, 1 do
        if idx >= 6400 then idx = 0 end
        if distrib[ idx ] then
            local zx = idx % 80
            local zy = math.floor(idx / 64)
            scan_id = idx
            do_check(zx, zy, true)
        end
    end
end

function clear_all_refugee()
    for i = 1, 6400 , 1 do
        local node = distrib[i]
        if node then
            for k, v in pairs(node) do
                v:stop_grab()
                rem_ety(v)
            end
        end
        distrib[i] = nil
    end
    distrib = {}
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

