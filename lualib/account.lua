
require "_base"

local _name =...
local self = {}
_G[_name] = self

self.accs = {}--帐号唯一

function self.load(conf)
    local mongo = require "mongo"
    for name,v  in pairs(conf) do
        local db = mongo.client(v)
        local info = db[name].name:find({})
        while info:hasNext() do
            local d = info:next()
            self.pids[d._id]=d
            if  type(d.name)=="number"  and g_nid < d.pids then
                g_nid = d.pids
            end
        end
    end
end


function self.login( t )
    if not t then return end
    if t._id then
    else
        self.new(t)
    end
end

function self.new(t)
    if not t then return end
    if type(t)~="table" then return end
    if not t.acc then lxz1("没帐号名") end
    local one = _base.new(_name,t)
    return one 
end

function self.del(one)
    self.accs[one.data.acc] = nil 
    _base.del(_name,one.data._id)
end

function self.get( _id )
    return _base.get(_name,_id)
end

return self
