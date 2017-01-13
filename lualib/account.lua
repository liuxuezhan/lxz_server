
require "base"

local _name =...
local self = {}
_G[_name] = self

self.accs = {}--帐号唯一

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
    local one = base.new(_name,t)
    self.accs[one.data.acc] = one 
    return one 
end

function self.del(one)
    self.accs[one.data.acc] = nil 
    base.del(_name,one.data._id)
end

function self.get( _id )
    return base.get(_name,_id)
end

return self
