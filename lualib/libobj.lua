
require("mytool")

local _M = {}
_M.save = {} 
_M._ex = {} 
local _name =...
_G[_name] = _M

local __mt_rec = {
    __index = function (self, recid)
        local t = self.__cache[ recid ]
        if t then
            self.__cache[ recid ] = nil
            t._n_ = nil
        else
            t = {}
        end
        self[ recid ] = t
        return t
    end
}

local __mt_tab = { 
    __index = function (self, tab)
        local t = { __cache={} }
        setmetatable(t, __mt_rec)
        self[ tab ] = t
        return t
    end
}
setmetatable(_M.save, __mt_tab)


function _M.new(_name)
    local _example = _M._ex[_name]
    local _mt1 = { --自动表
    __index = function (k, v)
        local t = { }
        setmetatable(t, _mt)
        k[ v ] = t
        return t
    end
    }

    local one = _example 
    setmetatable(one, _mt1)
    if not one._id then  lxz1("没有_id") return  end
    one._id = guid()
    _M.save[ _name ][ one._id ] = one

    local _mt2 = {
        __index = function (t, k)
            return rawget(_G[_name], k) 
        end,
    }

    local d = { }  
    setmetatable(d, _mt2)
    d.M  = one
    return d
end

return _M
