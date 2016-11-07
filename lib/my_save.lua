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

function mode.check_mongo(data, frame,fd)
    local info = fd:runCommand("getLastError")
    if info.ok then
        local code = info.code
        for tab, doc in pairs(data) do
            local cache = doc._bak
            local dels = {}
            for id, chgs in pairs(cache) do
                if chgs._n_ == frame then
                    rawset( chgs, "_n_", nil )
                    table.insert(dels, id)
                    if code then lxz("erro",tab,id,chgs) end
                elseif chgs._n_ < frame - 10 then
                    rawset( chgs, "_n_", nil )
                    doc[ id ] = chgs
                    table.insert(dels, id)
                    lxz("erro",tab,id,chgs)
                end
            end
            if #dels > 0 then
                for _, v in pairs(dels) do
                    cache[ v ] = nil
                end
            end
        end

        if info.code then
            lxz("check_save err ",info,frame)
        end
    end
end

function mode.save_mongo(data,fd,db_name)
    local gFrame = (gFrame or 0) + 1
    if fd then
        local update = false
        for tab, doc in pairs(data) do
            local cache = doc._bak
            for id, chgs in pairs(doc) do
                if chgs ~= cache then
                    if not chgs._a_ then
                        -- require "debugger"
                        local oid = chgs._id
                        chgs._id = id
                        fd[db_name][tab]:update({_id=id}, {["$set"] = chgs }, true) 
                        chgs._id = oid
                        print("update", tab, id) 
                    else
                        if chgs._a_ == 0 then
                            print("delete", tab, id)
                            fd[db_name][ tab ]:delete({_id=id})
                        else
                            local oid = chgs._id
                            rawset( chgs, "_a_", nil )
                            rawset( chgs, "_id", id )
                            fd[db_name][ tab ]:update({_id=id}, chgs, true)
                            rawset( chgs, "_a_", 1)
                            rawset( chgs, "_id", oid )
                            print("insert", tab, id)
                        end
                    end
                    update = true
                    rawset( chgs, "_n_", gFrame )
                    doc[ id ] = nil
                    cache[ id ] = chgs
                end
            end
        end

        if update then mode.check_mongo( data,gFrame,fd) end
    end
end

return mode



