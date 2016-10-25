--warx项目frame/player_t.lua
module(..., package.seeall)
_example = { account="Unknown", pid=-2 }
mode = ...

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
        return rawget(mode, k)
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

function new(t)
    local obj = {_ef={}, _ef_hero={}, _pro=t}
    gPlys[ t.pid ] = obj
    gAccs[ t.account ] = obj

    local acc = gAccounts[ t.account ]
    if not acc then
        acc = { [ t.pid ] = { map=gMapID, smap=t.smap or gMapID } } 
        gAccounts[ t.account ] =  acc
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



