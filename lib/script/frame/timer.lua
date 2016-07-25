module("timer", package.seeall)
_sns = _sns or {}
_funs = _funs or {}

function newTimer(node)
    addTimer(node._id, (node.over-gTime)*1000, node.tag or 0)
end

function get(id)
    return _sns[ id ]
end

function mark(node)
    local ignore = {cron=1, toGate=1, toMongo=1, check=1, check_frame=1}
    if not ignore[ node.what ] then
        if node.delete then
            gPendingDelete.timer[ node._id ] = 0
        else
            gPendingSave.timer[ node._id ] = node
        end
    end
end

function new(what, sec, ...)
    if what == "tlog" then pause() end
    if sec >= 0 and _funs[ what ] then
        sec = math.ceil( sec )
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
        newTimer(node)
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
        return id, node
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
        newTimer(node)
        mark(node)
    end
end

function callback(id, tag)
    local t = get(id)
    if t and t.tag == tag then
        _sns[id] = nil
        if t.delete then return end
        t.delete = true
        mark(t)

        local fun = _funs[ t.what ]
        --LOG("_timer_,  do, %s, %d, over:%s ", t.what, gTime, os.date("%y-%m-%d %H:%M:%S", t.over))
        if fun then
            local rt =  fun(id, unpack(t.param))
            if rt == 1 and t.cycle then
                t.start = gTime
                t.over = t.over + t.cycle
                t.tag = t.tag + 1
                _sns[ id ] = t
                timer.newTimer(t)
                t.delete = nil
                mark(t)
            end
        end
    end
end

