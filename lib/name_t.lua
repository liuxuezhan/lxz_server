module(..., package.seeall)
cur = 1000--当前最大id
_d = {}--数据

function load(conf)
    local mongo = require "mongo"
    for name,v  in pairs(conf) do
        local db = mongo.client(v)
        local info = db[name].name:find({})
        while info:hasNext() do
            local d = info:next()
            _d[d._id]=d
            if  type(d.name)=="number"  and cur < d.pid then
                cur = d.pid
            end
        end
    end
end


function login( tid,pwd,sid )
    --require "debugger"

    tid = tonumber(tid)
    local self = _d[tid] 
    if not self then
        cur = cur + 1
        tid = cur 
        self = {_id=tid,pwd=pwd, }
    end

    if pwd ~= self.pwd then return end
    self.online = {sid=sid}
    save(self)
end

function save(self)
    _d[self._id]=self
    save_t.data.name_t[self._id]=self
end

function new(server,name,pwd)
    if not _d[name] then
        cur = cur + 1
        local id = server.."_"..cur
        _d[name]={_id=id,pid=cur,name=name,pwd=pwd}
        return _d[name]
    end
end


