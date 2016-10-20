--local farm = farm or {}
module("farm", package.seeall)

distrib = distrib or {}
scan_id = scan_id or 0

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

function farm_reset()
    local n = gTime - gSysConfig.create
    n = n / (3600*24)

    local node = false

    for _, v in ipairs(resmng.prop_respawn_tm) do
        if n < v.Days then
            node = v
            break
        elseif v.Days == -1 then
            node = v
            break
        end
    end
    if node then
        local t = {}
        local total = 0
        for k, v in ipairs(node.Rates) do
            total = total + v
            t[ k ] = total
        end
        table.insert(t, 1, total)
        return t
    end
end

function get_respawn_type(lv)
    local node = farm.respawn_tm 
    if not node then 
        farm.respawn_tm = farm_reset() 
        node = farm.respawn_tm
    end

    if not node then return end

    local rate = math.random(1, node[1])
    local mode = false
    for k, v in ipairs(node) do
        if k > 1 then
            if rate <= v then
                mode = k - 1
                break
            end
        end
    end

    local tlv = false

    if mode then
        node = resmng.prop_respawn_lv[ lv ]
        if node then
            rate = math.random(1,100)
            total = 0
            for k, v in pairs(node.Rates) do
                total = total + v
                if rate <= total then
                    tlv = k
                    break
                end
            end
        end
    end

    if tlv then
        local id = math.ceil(1000000 + mode * 1000 + tlv)
        local node = resmng.prop_world_unit[ id ]
        return node
    end
end


function respawn(tx, ty)
    local lv = c_get_zone_lv(tx, ty)
    local prop = get_respawn_type(lv)
    if prop then
        local eid = get_eid_res()
        if eid then
            local x, y = c_get_pos_in_zone(tx, ty, prop.Size, prop.Size)
            if x then
                local obj = {_id=eid, eid=eid, x=x, y=y, propid=prop.ID, size=prop.Size, born=gTime, val=prop.Count, pid=0, uid=0, extra={} }
                gEtys[ eid ] = obj
                etypipe.add(obj)
                checkin(obj)
            else
                --print("no room, tx=", tx, ", ty=", ty)
            end
        end
    end
end

function do_check(zx, zy)
    if zx >= 0 and zx < 80 and zy >= 0 and zy < 80 then
        local idx = zy * 80 + zx
        local node = distrib[ idx ]

        local news = {}
        for k, eid in pairs(node or {})  do
            local ety = get_ety(eid)
            if ety then
                if ety.pid == 0 and ety.born < gTime - 12 * 3600 then
                    rem_ety(ety)
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
        elseif num < 4 then
            for i = num+1, 4, 1 do
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
            do_check(zx, zy)
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
    gPendingInsert.farm[ m.eid ] = m
end


function load_from_db()
    local db = dbmng:getOne()
    db.farm:delete( { pid = 0 } )

    local info = db.farm:find({})
    while info:hasNext() do
        local m = info:next()
        if m.eid then 
            gEtys[ m.eid ] = m
            if not m.extra then m.extra = {} end
            etypipe.add(m)
            checkin(m)
        end
    end
end

