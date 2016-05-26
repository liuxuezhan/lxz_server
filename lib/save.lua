--数据定时保存模块
module(..., package.seeall)
data = {}
del = {}

function clear()
    for k, v in pairs(data) do
        rawset(data, k,nil )
    end
end

function init()
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
    setmetatable(data, mt_table)


    mt_del_data = {
        __newindex = function (t, k, v)
            data[ t.tab_name ][ k ]._a_ = 0
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
    setmetatable(del, mt_del_table)

end

init()

