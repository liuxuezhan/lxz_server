
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

function _M.one(_name)
    local _example = _M._ex[_name]
    local _mt1 = {
        __index = function (t, k)
            if t._pro[k]  then return t._pro[k] end
            if _example[k]  then
                if type(_example[k]) == "table" then
                    t._pro[k] = copyTab(_example[k])
                    return t._pro[k]
                else
                    return _example[k]
                end
            end
            return rawget(_G[_name], k)
        end,

        __newindex = function(t, k, v)
            if _example[k] then
                t._pro[k] = v
                if v then
                    _M.save[ _name ][ t._id ][ k ] = v
                else
                    lxz1(_name..":"..t._id..":"..k..":".."不能为空")
                end
            else
                rawset(t, k, v)
            end
        end
    }
    local one = { _pro = copyTab(_example) }
    setmetatable(one, _mt1)
    if not one._id then  lxz1("没有_id") return  end
    one._id = guid()
    _M.save[ _name ][ one._id ] = one._pro
    return one
end

function _M.one2(_name)
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
    return one
end

return _M
