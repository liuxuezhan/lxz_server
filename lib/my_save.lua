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
        local check_table = {}
        for tab, doc in pairs(data) do
            local cache = doc._bak
            cache_check(cache, tab, check_table)
            local adds = {}
            local dels = {}
            for id, chgs in pairs(cache) do
                if chgs._n_ == frame then
                    rawset( chgs, "_n_", nil )
                    table.insert(dels, id)
                    if code then lxz("erro",tab,id,chgs) end
                elseif chgs._n_ < frame - 100 then
                    rawset( chgs, "_n_", nil )
                    adds[id] = chgs
                    table.insert(dels, id)
                    lxz("erro",tab,id,chgs._n_,frame )
                end
            end
                for id, chgs in pairs(adds) do
                    doc[id] = chgs
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

function cache_check(cache, table_name, check_table)
    -- 校验了不同的key指向了同一个cache的错误，出现此问题肯定是逻辑上写错了
    -- 20161208 在act项目中，出现了2张不同的表里面的相同的id指向了同一个cache的错误
    -- 如果在同一帧存储，也会导致_n_为nil的情况，所以增加了check的范围
    if not config.Release then
        for id, chgs in pairs(cache) do
            if check_table[chgs] ~= nil then
                local exist_record = check_table[chgs]
                WARN("zhoujy_warning: cache_check failed tab_1=%s, id_1=%s, tab_2=%s, id_2=%s",
                    table_name, id, exist_record[1], exist_record[2])
            else
                check_table[chgs] = {table_name, id}
            end
        end
    end
end

function mode.save_mongo(data,fd,db_name)
    local gFrame = (gFrame or 0) + 1
    if fd then
        local cbs = gUpdateCallBack
        local update = false
        local cur = gFrame
        local cb_map = {}       --key为函数，value为table(key为id, value为chgs)
        for tab, doc in pairs(data) do
            local cache = doc._bak
            local cb = nil
            for id, chgs in pairs(doc) do
                if chgs ~= cache then
                        doc[ id ] = nil
                        update = true
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
                    rawset( chgs, "_n_", gFrame )
                    cache[ id ] = chgs

                    if cb == nil then
                        cb = cbs[ tab ]
                        if cb == nil then
                            cb = _G[ tab ] and _G[ tab ].on_check_pending
                            if cb == nil then cb = false end
                            cbs[ tab ] = cb
                        end
                    end

                    if cb then
                        cb_map[cb] = cb_map[cb] or {}
                        cb_map[cb][id] = chgs
                        --cb( db, id, chgs )
                    end
                end
            end
        end

        -- on_check_pending统一在外部调用
        for cb, params in pairs(cb_map) do
            for id, chgs in pairs(params) do
                cb(db, id, chgs)
            end
        end

        if update then mode.check_mongo( data,gFrame,fd) end
    end
end

return mode



