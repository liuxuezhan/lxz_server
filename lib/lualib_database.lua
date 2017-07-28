
require("lualib_mytool")

local _name =...
local self = {}
_G[_name] = self

local __mt_rec = {
    __index = function (tab, recid)
        local tmp = tab.__cache[ recid ]
        if tmp then
            tab.__cache[ recid ] = nil
            tmp._n_ = nil
        else
            tmp = {}
        end
        tab[ recid ] = tmp
        return tmp
    end
}

local __mt_tab = { 
    __index = function (tab, k)
        local tmp = { __cache={} }
        setmetatable(tmp, __mt_rec)
        tab[ k ] = tmp
        return tmp
    end,

}

function self.auto(tab)--自动表
	_mt_auto = { __index = function (t, k) local new = { } setmetatable(new, _mt_auto) rawset( t, k, new ) return new end, 
                 __newindex = function (t, k,v) if type(v) == "table" then setmetatable(v, _mt_auto) end rawset( t, k, v ) end,
    }
	setmetatable(tab, _mt_auto)
    return tab
end 

self.main = {}      --存库数据 
self.auto(self.main)      --存库数据 
self.save = {}    --修改的数据 
setmetatable(self.save, __mt_tab)


function self.new(module,tab)

    if not module then lxz1("没模块名") return end
    if not tab then lxz1("没数据") return end
    if type(tab)~= "table" then lxz1("数据无效") return end

    local _mt_save = { --自动保存
        __index = function (t, k)
            if t.M[ k ] then return t.M[ k ] 
            else
                local new = self.auto({}) 
                rawset( t.M, k, new ) 
                return new  
            end
        end,
        __newindex = function(t, k, v)
            if type(v) == "table" then setmetatable(v, _mt_save) end
            t.M[k] = v     -- 修改时保存
            self.save[ module ][ t._id ][ k ] = v
        end,
    }
    local one = { M = copyTab(tab) }
    setmetatable(one, _mt_save)

    local _mt_obj = { --对象
        __index = function (t, k)
            return rawget(_G[module], k)-- 指向对象方法
        end,
    }
    local ret = { save=one,}
    setmetatable(ret, _mt_obj)

    if not one._id then 
        while true do
            local id = guid() 
            local tmp = self.get(module,id) 
            if not tmp then 
                one._id = id 
                break 
            end
        end
    end
    self.main[ module ][ one._id ] = one.M
    self.save[ module ][ one._id ] = one.M

    return ret
end

function self.del(module,_id)
    self.main[module][_id] = nil
    self.save[module][_id ]._a_ = 0
end

function self.get(module,_id)
    if _id then
        local t = self.main[module][_id] 
        if next(t) then return t end
    else
        return self.main[module] 
    end
end

function self.clear_save() 
    for k, v in pairs(self.save) do
        rawset(self.save, k,nil )
    end
end

gUpdateCallBack = {}
function self.save_mongo(data,fd,db_name)
    local gFrame = (gFrame or 0) + 1
    if fd then
        local cbs = gUpdateCallBack
        local update = false
        local cur = gFrame
        local cb_map = {}       --key为函数，value为table(key为id, value为chgs)
        for tab, doc in pairs(data) do
            local cache = doc.__cache
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

        if update then self.check_mongo( data,gFrame,fd) end
    end
end


function self.check_mongo(data, frame,fd)
    local info = fd:runCommand("getLastError")
    if info.ok then
        local code = info.code
        local check_table = {}
        for tab, doc in pairs(data) do
            local cache = doc.__cache
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

return self
