
local _name =...
local self = {} 
_G[_name] = self
local _funs = {}
local save_t = require "my_save"

function self.load(conf)--推动时间
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
            if t.over < minTime then
                print(string.format("SetTimerStart, min=%d, timer, what=%s", t.over, t.what))
                minTime = t.over
            end
            if t.what == "cron" then
                if not isCron then 
                    _base.new(_name,t)
                    isCron = true
                end
            end
        end
    end

    if minTime < real then
        g_tm = minTime

        for k, node in pairs(self.get()) do
            self.start(node, (node.over-minTime))
        end

        return "Compensation"
    else
        for k, node in pairs(self.get()) do
            self.start(node, (real - node.over))
        end
    end
end

function self.get(id)
    return _base.get(_name,_id)
end

function self.mark(node)
    if node.what ~= "cron" then
        if node.delete then
            save_t.del.timer[node._id]=0
        else
            save_t.data.timer[node._id]=node
        end
    end
end

function self.set_call( what,fun)
    _funs[what] = fun
end

function self.new( what,sec, ...)

    if not _funs[what] then lxz1("没有回调函数:"..what) return end
    if sec < 0 then return  end

    local one = _base.new(_name,{sec=sec, what=what, param={...}})
    _funs[what](one)
    return one
end


function self.cycle(what, sec, cycle, ...)
    if sec >= 1 and cycle >= 1 then
        local id, node = new(what, sec, ...)
        if id then
            node.cycle = cycle
            mark(node)
        end
    end
end

function self.del(one)
    _base.del(_name,one.data._id)
end

function self.acc(id, sec)
    local node = get(id)
    if node then
        node.over = node.over - sec
        node.tag = (node.tag or 0) + 1
        self.start(node,node.over-g_tm)
        mark(node)
    end
end

return self

