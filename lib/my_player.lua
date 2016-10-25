--warx项目frame/player_t.lua
module(..., package.seeall)
_example = PLAYER_INIT or {}
_name = ...

local player_mt = {
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
        return rawget(_name, k)
    end,

    __newindex = function(t, k, v)
        if _example[k] ~= nil then
            t._pro[k] = v
            save_t.data[_name][t._id][k] = v
        else
            rawset(t, k, v)
        end
    end
}

function new(account,pid,smap)
    local obj = { _ef={}, _ef_hero={}, _pro=copyTab(player_t._example) }
    obj.pid = pid 
    obj.account = account 
    obj.smap = smap 

    gPlys[ obj.pid ] = obj
    gAccs[ obj.account ] = obj

    local acc = gAccounts[ obj.account ]
    if not acc then
        acc = { [ obj.pid ] = { map=gMapID, smap=obj.smap or gMapID } } 
        gAccounts[ obj.account ] =  acc
    end

    setmetatable(obj, player_mt)
    if player_t.initObj then
        player_t.initObj(obj)
    end
    return obj
end

function del(t)
    gPlys[ t.pid ] = nil
    gAccs[ t.account ] = nil
    gAccounts[ t.account ] = nil
    save_t.del[_name][t._id] = 1
end

function is_online(self)
    return self.tm_login > self.tm_logout
end

function onBreak(self)
    self.tm_logout = g_tm
    if g_online_num and  g_online_num  > 0 then
        g_online_num = g_online_num  - 1 
    end
end

function load(conf)
    local mongo = require "mongo"
    local db = mongo.client(conf)
    local info = db[g_sid]._name:find({})
    while info:hasNext() do
        local data = info:next()
        if data.tm_login > (data.tm_logout or 0) then data.tm_logout = g_tm - 1 end
        if  data.pid and data.account then
            local p = player_t.new(data)

        end
    end
end



