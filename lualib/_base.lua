
require("mytool")

local _name =...
local self = {}
_G[_name] = self

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
    end,

}

self.main = {}      --存库数据 
setmetatable(self.main, _mt_auto)
self.save = {}    --修改的数据 
setmetatable(self.save, __mt_tab)


function self.new(module,tab)

    if not module then lxz1("没模块名") end
    if not tab then lxz1("没数据") end
    if type(tab)~= "table" then lxz1("数据无效") end

    local _mt_save = { --自动保存
        __index = function (t, k)
            if t.M[ k ] then return t.M[ k ] end
        end,
        __newindex = function(t, k, v)
            if v then
                t.M[k] = v
                self.save[ module ][ t._id ][ k ] = v
            else
                lxz1(module..":"..t._id..":"..k..":".."不能为空")
            end
        end
    }
    local one = { M = copyTab(tab) }
    setmetatable(one, _mt_save)
    one._id = guid()

    local _mt_obj = { --对象
        __index = function (t, k)
            return rawget(_G[module], k)
        end,
    }
    local ret = { data=one,}
    setmetatable(ret, _mt_obj)

    self.main[ module ][ one.M._id ] = one.M
    self.save[ module ][ one.M._id ] = one.M

    return ret
end

function self.del(module,_id)
    _base.main[module][_id] = nil
    _base.save[module][_id ]._a_ = 0
end

function self.get(module,_id)
    return _base.main[module][_id] 
end

return self
