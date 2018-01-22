
function makeClass(class, index_mt)
    local creator = {}
    class.__index = index_mt or class
    creator.create = function(...)
        local instance = setmetatable({}, class)
        instance:init(...)
        return instance
    end
    return creator
end

function makeDataIndex(base_class, data_field)
    return function(t, k)
        if base_class[k] then
            return base_class[k]
        end
        local data = rawget(t, data_field)
        if nil ~= data then
            return data[k]
        end
    end
end

