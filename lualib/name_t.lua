

local _M= {
        _d = {},--数据
        _acc = {},--帐号唯一
    }
setmetatable(_M._d, {__mode = "v"})

require "libobj"
local _name =...
_G[_name] = _M
libobj._ex[_name] = {_id=0,name="null",acc="null"}
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


function _M.login( t )
    if not t then return end
    if t._id then
    else
        _M.new(t)
    end
end

function _M.new(t)
    if not t then return end
    if type(t)~="table" then return end
    t._id = guid()
    if not _M._d[t._id] then
        local one = libobj.one(_name)
        _M._d[one._id] = one 
        _M._acc[one.acc] = one 
        return one 
    else
        lxz1("guid失败:"..t._id)
    end
end

function _M.del(one)
    libobj.save[_name][ one._id ]._a_ = 0
    _M._d[one._id] = nil
end

function _M.get(_id)
    return _M._d[_id] 
end

return _M
