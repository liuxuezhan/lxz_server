--数据定时保存模块
local mode = {}
mode.data = {}
mode.del = {}

function mode.clear()
    for k, v in pairs(mode.data) do
        rawset(mode.data, k,nil )
    end
end

mt_data = {
    __index = function (t, k)
        local tmp = t._bak[ k ]
        if tmp then
            t._bak[ k ] = nil
            tmp._n_ = nil
        else
            tmp = {}
        end
        t[ k ] = tmp
        return tmp
    end
}
mt_table = {
    __index = function (t, k)
        local tmp = { _bak={} }
        setmetatable(tmp, mt_data)
        t[ k ] = tmp
        return tmp
    end
}
setmetatable(mode.data, mt_table)


mt_del_data = {
    __newindex = function (t, k, v)
        mode.data[ t.tab_name ][ k ]._a_ = 0
    end
}
mt_del_table = {
    __index = function (t, k)
        local tmp = {tab_name=k}
        setmetatable(tmp, mt_del_data)
        t[ k ] = tmp
        return tmp
    end
}
setmetatable(mode.del, mt_del_table)

return mode



