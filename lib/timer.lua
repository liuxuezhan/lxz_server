module(..., package.seeall)
_sns = _sns or {}
_funs = _funs or {}


function get(id)
    return _sns[ id ]
end

function mark(node)
    if node.what ~= "cron" then
        if node.delete then
            save.del.timer[node._id]=0
        else
            save.data.timer[node._id]=node
        end
    end
end

function new(what, sec, ...)
    if sec >= 0 and _funs[ what ] then
        local id = false
        while true do
            local sn = getSn("timer")
            if not timer.get(sn) then
                id = sn
                break
            end
        end

        local node = {_id=id, tag=0, start=gTime, over=gTime+sec, what=what, param={...}}
        _sns[ id ] = node
        mark(node)
        return id, node
    end
end

function cycle(what, sec, cycle, ...)
    if sec >= 1 and cycle >= 1 then
        local id, node = new(what, sec, ...)
        if id then
            node.cycle = cycle
            mark(node)
        end
    end
end

function del(id)
    local node = _sns[id]
    if node then 
        node.delete = true
        mark(node)
        _sns[ id ] = nil
    end
end

function acc(id, sec)
    local node = get(id)
    if node then
        node.over = node.over - sec
        node.tag = (node.tag or 0) + 1
        mark(node)
    end
end

function callback(id, tag)
    local t = get(id)
    if t and t.tag == tag then
        _sns[id] = nil
        if t.delete then return end
        t.delete = true

        local fun = _funs[ t.what ]
        LOG("_timer_,  do, %s, %d, over:%s ", t.what, gTime, os.date("%y-%m-%d %H:%M:%S", t.over))
        if fun then
            local rt =  fun(id, unpack(t.param))
            if rt == 1 and t.cycle then
                t.start = gTime
                t.over = t.over + t.cycle
                t.tag = t.tag + 1
                _sns[ id ] = t
                t.delete = nil
            end
        end
        mark(t)
    end
end

function load()--推动时间
    local db = dbmng:getOne()
    db.timer:delete({delete=true})

    local info = db.timer:find({})
    local minTime = math.huge--获取最新定时器结束时间
    local maxSn = 0
    local isCron = false

    local real = os.time()
    while info:hasNext() do
        local t = info:next()
        if t.over > real - 36000 then 
            timer._sns[ t._id ] = t
            if t._id > maxSn then maxSn = t._id end
            if t.over < minTime then
                print(string.format("SetTimerStart, min=%d, timer, what=%s", t.over, t.what))
                minTime = t.over
            end
            if t.what == "cron" then
                if not isCron then 
                    isCron = true
                else
                    timer._sns[ t._id ] = nil -- duplicate crontab
                end
            end
        end
    end
    _G.gSns[ "timer" ] = maxSn + 1
    dumpTab(gSns, "gSns")

    local dels = {}
    local retroop = {}
    for k, v in pairs(troop_mng.troop_id_map) do
        if v:is_go() or v:is_back() then
            if not v.tmCur then 
                table.insert(dels, {k, v})
            else
                if v.tmCur > real - 36000 then
                    if v.tmCur < minTime then
                        print(string.format("SetTimerStart, min=%d, troop, troopid=%s", v.tmCur, v._id))
                        minTime = v.tmCur
                    end
                    table.insert(retroop, v)
                else
                    table.insert(dels, {k, v})
                    WARN("restore_troop, id=%d, action=%d, offset=%f hour", v._id, v.action, (real-v.tmCur)/3600)
                end
            end
        end
    end

    for _, t in  pairs(dels) do
        local k = t[1]
        local troop = t[2]
        troop_mng.delete_troop(k)
        for pid, _ in pairs(troop.arms or {}) do
            if pid > 0 then
                local p = getPlayer(pid)
                if p then
                    remove_id(p.busy_troop_ids, k)
                end
            end
        end
    end

    if minTime < real then
        _G.gTime = minTime
        _G.gMsec = 0
        _G.gCompensation = minTime
        c_time_set_start(minTime)
        WARN("gCompensation, from=%d, to=%d", minTime, real)

        for k, node in pairs(timer._sns) do
            addTimer(node._id, (node.over-minTime)*1000, node.tag or 0)
        end

        for _, v in pairs(retroop) do
            etypipe.add(v)
            c_add_actor(v.eid, v.curx, v.cury, v.dx, v.dy, v.tmCur, v.speed)
            gEtys[ v.eid ] = v
        end

        return "Compensation"
    else
        for k, node in pairs(timer._sns) do
            addTimer(node._id, (real - node.over)*1000, node.tag or 0)
        end
    end
end

