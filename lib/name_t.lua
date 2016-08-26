module(..., package.seeall)
_d = {}--数据

function load(conf)
    local mongo = require "mongo"
    for name,v  in pairs(conf) do
        local db = mongo.client(v)
        local info = db[name].name:find({})
        while info:hasNext() do
            local d = info:next()
            _d[d._id]=d
            if  type(d.name)=="number"  and g_nid < d.pid then
                g_nid = d.pid
            end
        end
    end
end


function login( ins )

    local pid = ins.pid
    local self = _d[ins.name] 
    if not self then
        g_nid = g_nid + 1
        self = {_id=ins.name,nid=g_nid,pwd=ins.pwd }
    end
    if ins.pwd ~= self.pwd then return end

    if not self[ins.pid] then
        if not self.online then
            g_pid = g_pid + 1
            self[tostring(g_pid)] = ins.sid
            pid = tostring(g_pid)
        else
            pid = self.online.pid 
        end
    end

    return self,pid
end

function save(self)
    _d[self._id]=self
    save_t.data.name[self._id]=self
end

function new(server,name,pwd)
    if not _d[name] then
        cur = cur + 1
        local id = server.."_"..cur
        _d[name]={_id=id,pid=cur,name=name,pwd=pwd}
        return _d[name]
    end
end


