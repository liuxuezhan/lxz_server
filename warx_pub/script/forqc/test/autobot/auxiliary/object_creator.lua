
function makeClass(class)
    local creator = {}
    creator.__index = creator
    creator.create = function(...)
        local instance = setmetatable({}, class)
        instance:init(...)
        return instance
    end
    class.__index = class
    return setmetatable(class, creator)
end

