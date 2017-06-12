module("refugee", package.seeall)

distrib = distrib or {}
scan_id = scan_id or 0
act_state = act_state or 0

module_class("refugee",
{ 
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
    timers = {},
    extra = {},
}
)

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
    local tr = troop_mng.get_troop(self.my_troop_id)
    return tr
end

function after_fight(ackTroop, defenseTroop)

    local city = get_ety(ackTroop.target_eid) 

    local extra = city.extra or {}   -- deal old dominator

    local ply = getPlayer(city.pid)  
    if ply then
        local refugee_info = ply.refugee_info or {}
        if refugee_info[city.eid] then
            refugee_info[city.eid] = nil
        end
        ply.refugee_info = refugee_info
    else
        if extra.ply_gs_id then
            Rpc:callAgent(extra.ply_gs_id, "refugee_change", city.pid, 0, {eid = eid})
        else
            WARN("did not find where is ply who occupied refugee")
        end
    end

    new_defender_state(city)
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, city)


    local atk_ply = getPlayer(ackTroop.owner_pid)
    if atk_ply then
        extra.ply_gs_id = atk_ply.map_id 
        city.my_troop_id = ackTroop._id
        city.pid = atk_ply.pid
        city.uid = atk_ply.uid
        city.extra = extra
        refugee_info[city.eid] = {eid = city.eid, tm_over = city.end_time, map_id = gMapID}
        atk_ply.refugee_info = refugee_info
    else
        WARN("did not find ply who occupied refugee")
    end

    etypipe.add(city)
end

function new_defender_state(self)
    clear_timer(self)
    set_timer(1, self)
    self.start_time = gTime
    local time = resmng.prop_world_unit[self.propid].Spantime
    -- to do
    self.end_time = gTime + time 
end

function clear_timer(self)
    if self then
        timer.del(self.timers)
        self.timers = nil
    end
    self.start_time = 0
    self.end_time = 0
end

function set_timer(state, self)
    if state == nil then state = self.state end
    -- to do
    local time = 0
    if self then
        time = resmng.prop_world_unit[self.propid].Spantime
    end
    if self then
        local timerId = 0
        timerId = timer.new("refugee", time, state, self.eid)
        self.timers= timerId
    end
end

function finish_grap(self)
    clear_timer(self)
    local tr = self:get_my_troop()
    if tr then
        tr:back()
    end
    local zx = mail.floor(self.x / 16)
    local zy = mail.floor(self.y / 16)
    local node = distrib[ zy * 80 + zx]
    local news = {}
    for k, eid in pairs(node or {}) do
        if eid ~= self.eid then
            rem_ety(self.eid)
        else
            table.insert(news, eid)
        end
    end
    distrib[idx] = news
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
                rem_ety(v)
            end
        end
        distrib[i] = nil
    end
    distrib = {}
end

