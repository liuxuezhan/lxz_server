

local _M= {
        _d = {},--数据
    }
setmetatable(_M._d, {__mode = "v"})


local mod = require "myobj"
local _name =...
function _M.load(conf)
    local mongo = require "mongo"
    for name,v  in pairs(conf) do
        local db = mongo.client(v)
        local info = db[name].name:find({})
        while info:hasNext() do
            local d = info:next()
            _M._d[d._id]=d
            if  type(d.name)=="number"  and g_nid < d.pid then
                g_nid = d.pid
            end
        end
    end
end


function _M.login( ins )

    local pid = ins.pid
    local self = _M._d[ins.name] 
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

function _M.new(server,name,pwd)
    if not _M._d[name] then
        _M._d[name]=mod.one(_name,{_id=1,name=name,pwd=pwd})
--local bson = require "bson"
        --_M._d[name]=mod.one(_name,{_id=bson.objectid(),name=name,pwd=pwd})
        return _M._d[name]
    end
end

function _M.del(one)
    mod.save[_name][ one._id ]._a_ = 0
    _M._d[one._id] = nil
end

function _M.get(_id)
    return _M._d[_id] 
end

return _M
