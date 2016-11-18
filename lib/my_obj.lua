module(..., package.seeall)

function new(_name,id)
    local _example = data[_name] or {}
    local obj = { _id=id,_pro=copyTab(_example) }

    local _mt = {
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
            return rawget(_G[_name], k)
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
    setmetatable(obj, _mt)
    _G[_name]= obj
    save_t.data[_name][obj._id] = obj._pro
    return obj
end

function del(_name,id)
    _G[_name][id]= nil
    save_t.del[_name][id] = 1
end

function load_db(conf)
    local mongo = require "mongo"
    local db = mongo.client(conf)
    for _, _name in pairs(my_mode) do
        local info = db[g_sid]._name:find({})
        while info:hasNext() do
            local data = info:next()
            _G[_name].load(data)
        end
    end
end

function load_mod(_name)
    if not my_mode then my_mode= {}  end
    table.insert(my_mode,_name)
end




