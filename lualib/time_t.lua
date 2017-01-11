
local _M = {} 
max_sn =  g_cid*1000 
_sns = _sns or {}
local _funs = {}
local save_t = require "my_save"
_funs["save_db"] = function(sn,db)
    if next(save_t.data) then
        lxz(db,save_t.data)
        skynet.send(db, "lua",db, msg_t.pack(save_t.data))--不需要返回
        save_t.clear()
    end
    _M.news("save_db",3,db)
end

function _M.load(conf)--推动时间
    local mongo = require "mongo"
    local db = mongo.client(conf)
    db.timer:delete({delete=true})

    local info = db.timer:find({})
    local minTime = math.huge--获取最新定时器结束时间
    local isCron = false

    local real = os.time()
    while info:hasNext() do
        local t = info:next()
        if t.over > real then 
            timer._sns[ t._id ] = t
            if tonumber(t._id) > max_sn then max_sn = tonumber(t._id) end
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

    if minTime < real then
        g_tm = minTime

        for k, node in pairs(timer._sns) do
            add(node, (node.over-minTime))
        end

        return "Compensation"
    else
        for k, node in pairs(timer._sns) do
            add(node, (real - node.over))
        end
    end
end

function _M.get(id)
    return _sns[ id ]
end

function _M.mark(node)
    if node.what ~= "cron" then
        if node.delete then
            save_t.del.timer[node._id]=0
        else
            save_t.data.timer[node._id]=node
        end
    end
end

function _M.new(what, sec, ...)
    if sec >= 0 and _funs[ what ] then
        local id = false
        while true do
            max_sn = max_sn + 1
            local sn = tostring(max_sn)
            if not _M.get(sn) then
                id = sn
                break
            end
        end

        local node = {_id=id, tag=0, start=g_tm, over=g_tm+sec, what=what, param={...}}
        _sns[ id ] = node
        _M.add(node,sec)
        _M.mark(node)
        return id, node
    end
end

function _M.news(what, sec, ...)
    local fun = _funs[ what ]
    local args = {...}
    skynet.timeout(sec*100, function() 
        fun(1, table.unpack(args))
    end)
end

function _M.add(node,sec)
    skynet.timeout(sec*100, function() 
        callback(node._id,node.tag)
    end)
end

function _M.cycle(what, sec, cycle, ...)
    if sec >= 1 and cycle >= 1 then
        local id, node = new(what, sec, ...)
        if id then
            node.cycle = cycle
            mark(node)
        end
    end
end

function _M.del(id)
    local node = _sns[id]
    if node then 
        node.delete = true
        mark(node)
        _sns[ id ] = nil
    end
end

function _M.acc(id, sec)
    local node = get(id)
    if node then
        node.over = node.over - sec
        node.tag = (node.tag or 0) + 1
        add(node,node.over-g_tm)
        mark(node)
    end
end

function callback(id, tag)
    local t = _M.get(id)
    if t and t.tag == tag then
        _sns[id] = nil
        if t.delete then return end
        t.delete = true
        _M.mark(t)

        local fun = _funs[ t.what ]
        if fun then
        lxz(t.what,fun)
            local rt =  fun(id, table.unpack(t.param))
            if rt == 1 and t.cycle then
                t.start = g_tm
                t.over = t.over + t.cycle
                t.tag = t.tag + 1
                _sns[ id ] = t
                t.delete = nil
            end
        end
        _M.mark(t)
    end
end
return _M

