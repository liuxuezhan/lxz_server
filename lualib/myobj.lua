
require("mytool")

local _M = {}
_M.save = {} 
_M.del = {} 

__mt_rec = {
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
__mt_tab = {
    __index = function (self, tab)
        local t = { __cache={} }
        setmetatable(t, __mt_rec)
        self[ tab ] = t
        return t
    end
}
setmetatable(_M.save, __mt_tab)


__mt_del_rec = {
    __newindex = function (t, k, v)
        _M.save[ t.tab_name ][ k ]._a_ = 0
    end
}
__mt_del_tab = {
    __index = function (self, tab)
        local t = {tab_name=tab}
        setmetatable(t, __mt_del_rec)
        self[ tab ] = t
        return t
    end
}
setmetatable(_M.del, __mt_del_tab)


function _M.one(_name,_example)
    local _mt = {
        __index = function (t, k)
            if t._pro[k] ~= nil then return t._pro[k] end
            if _example[k] ~= nil then
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
            if _example[k] ~= nil then
                t._pro[k] = v
                _M.save[ _name ][ t._id ][ k ] = v
            else
                rawset(t, k, v)
            end
        end
    }
    local one = {_pro = copyTab(_example)}
    setmetatable(one, _mt)
    _M.save[ _name ][ one._id ] = v
    return one
end

return _M
