module("player_t", package.seeall)
_cache = _cache or {}
_name = "player_t"
_example = { account="Unknown", pid=-2 }

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
        return rawget(player_t, k)
    end,

    __newindex = function(t, k, v)
        if _example[k] ~= nil then
            t._pro[k] = v
            if not _cache[t._id] then _cache[t._id] = {} end
            _cache[t._id][k] = v
            _cache[t._id]._n_ = nil
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
        acc = {}
        gAccounts[ t.account ] =  acc
    end
    acc[ t.pid ] = { map=gMapID, smap=t.smap or gMapID }

    setmetatable(obj, player_mt)
    _cache[ t.pid ] = t
    if initObj then
        initObj(obj)
    end
    return obj
end

-- just for example
-- just for example
-- just for example
function check_pending()
    local db = dbmng:tryOne(1)
    if not db then return end

    local hit = false
    local cur = gFrame
    for pid, chgs in pairs(_cache) do
        if not chgs._n_ then
            db.player:update({_id=pid}, {["$set"]=chgs}, true)
            dumpTab(chgs, "update player")
            local p = getPlayer(pid)
            if p and p.notify then p:notify(chgs) end
            chgs._n_ = cur
            hit =true
        end
    end
    --if hit then get_db_checker(db, gFrame)() end
    if hit then 
        gen_checker(db, cur, _cache, "player") 
    end
end

function get_db_checker(db, frame)
    local f = function( )
        local info = db:runCommand("getPrevError")
        if info.ok then
            local dels = {}
            local its = _cache
            local cur = gFrame

            for k, v in pairs(its) do
                local n = v._n_
                if n then
                    if n == frame then
                        table.insert(dels, k)
                    elseif cur - n > 100 then
                        v._n_ = nil
                    end
                end
            end
            for _, v in pairs(dels) do its[ v ] = nil end
        end
    end
    return coroutine.wrap(f)
end

