
require("mytool")

local _M = {}
_M.save = {} 
local _name =...
_G[_name] = _M

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

function _M.one(_name,_example)
    local _mt = {
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
    local one = { _name=_name, _pro = copyTab(_example) }
    setmetatable(one, _mt)
    _M.save[ _name ][ one._id ] = v
    return one
end

return _M
