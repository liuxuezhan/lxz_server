module("timer", package.seeall)
_sns = _sns or {}
_funs = _funs or {}

function newTimer(node)
    addTimer(node._id, (node.over-gTime)*1000, node.tag or 0)
end

function get(id)
    local node = _sns[ id ]
    if node and not node.delete then return node end
end

function mark(node)
    local ignore = {cron=1, toGate=1, toMongo=1, check=1, check_frame=1, monitor=1}
    if not ignore[ node.what ] and not node.ignore then
        if node.delete then
            gPendingDelete.timer[ node._id ] = 0
        else
            gPendingSave.timer[ node._id ] = node
        end
    end
end

function get_id()
    while true do
        local sn = getSn("timer")
        if not get(sn) then return sn end
    end
end

function new(what, sec, ...)
    --if what == "tlog" then pause() end
    if _funs[ what ] then
        if sec < 0 then sec = 0 end
        sec = math.ceil( sec )
       
        local id = get_id()
        local node = {_id=id, tag=0, start=gTime, over=gTime+sec, what=what, param={...}}
        _sns[ id ] = node
        newTimer(node)
        mark(node)
        return id, node
    end
end

function reopen_timer( node )
    if get( node._id ) then node._id = get_id() end
    _sns[ node._id ] = node
    mark( node )
    if node.over <= gTime then
        callback( node._id, node.tag )
    else
        newTimer( node )
    end
end


function is_valid( sn, ... )
    local node = get( sn )
    if node then
        local param = node.param
        for k, v in ipairs( { ... } ) do
            if param[ k ] ~= v then
                return false
            end
        end
        return true
    end
end

function new_ignore(what, sec, ...)
    --if what == "tlog" then pause() end
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

        local node = {_id=id, tag=0, start=gTime, over=gTime+sec, what=what, param={...}, ignore=true}
        _sns[ id ] = node
        newTimer(node)
        mark(node)
        return id, node
    end
end


function new_msec_ignore(what, msec, ...)
    local sec = msec / 1000
    if sec >= 0 and _funs[ what ] then
        local id = false
        while true do
            local sn = getSn("timer")
            if not timer.get(sn) then
                id = sn
                break
            end
        end

        local node = {_id=id, tag=0, start=gTime, over=gTime+sec, what=what, param={...}, ignore=true}
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

function adjust( id, over )
    if over < gTime then over = gTime end
    local node = get( id )
    if node then
        node.over = over
        node.tag = ( node.tag or 0 ) + 1
        newTimer( node )
        mark( node )
    end
end

function add(id, sec)
    local node = get(id)
    if node then
        node.over = node.over + sec
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
        INFO("[TIMER], %d, %s, now:%d, over:%s ", id, t.what, gTime, t.over or 0 )
        perfmon.start("timer_func", 0)
        perfmon.start(t.what, id)
        if fun then
            local rt =  fun(id, unpack(t.param))
            if rt == 1 and t.cycle then
                t.tag = t.tag + 1
                _sns[ id ] = t
                t.delete = nil
                if not t.msec then
                    t.start = gTime
                    t.over = t.over + t.cycle
                    timer.newTimer(t)
                    mark(t)
                else
                    t.start = gMsec
                    t.over = t.over + t.cycle
                    timer.m_newTimer(t)
                end
            end
        end
        perfmon.stop(t.what, id)
        perfmon.stop("timer_func", 0)
    end
end

--function m_newTimer(node)
--    --print("m_newTimer", node.over, node.start, node.over - node.start)
--    --addTimer(node._id, node.over - node.start, node.tag or 0)
--    addTimer(node._id, node.over - node.start, node.tag or 0)
--end
--
--function m_new(what, msec, ...)
--    if msec >= 0 and _funs[what] then
--        msec = math.ceil(msec)
--        local id = false
--        while true do
--            local sn = getSn("timer")
--            if not timer.get(sn) then
--                id = sn
--                break
--            end
--        end
--
--        local node = {_id=id, tag=0, start=gMsec, over=gMsec + msec, msec=true, what=what, param={...}}
--        _sns[ id ] = node
--        m_newTimer(node)
--        return id, node
--    end
--end
--
--function m_cycle(what, msec, cycle, ...)
--    if msec >= 1 and cycle >= 1 then
--        local id, node = m_new(what, msec, ...)
--        if id then node.cycle = cycle end
--        return id, node
--    end
--end

-- 应该被各自项目的cron调用，在这里利用cron的timer执行一些框架级别的定时工作
function cron_base_func()
    --local nextCron = 60 - (gTime % 60) + 30
    --local newsn, node = timer.new("cron", nextCron)

    local next_cron = gTime + 90
    next_cron = next_cron - ( next_cron % 60 )
    timer.new( "cron", next_cron - gTime )

    crontab.loop()
    c_mem_info()
end

function get_recently()
    local t = -1
    for k, v in pairs( _sns or {} ) do
        if t == -1 or v.over < t then
            t = v.over
        end
    end
    if t ~= -1 then return t end
end

--------------------------------------------------- ---------------------------------------------------
-- TIMER CALL BACK FUNCTION
--------------------------------------------------- ---------------------------------------------------

_funs["toGate"] = function(sn, ip, port)
    conn.toGate(ip, port)
end

_funs["toMongo"] = function(sn, host, port, db, user, pwd, mechanism, tips, is_reconnect)
    conn.toMongo(host, port, db, user, pwd, mechanism, tips, is_reconnect)
end


