local SiegeAction = {}

function SiegeAction.makeClass(class, troop_action)
    assert(nil ~= troop_action, "unspecified troop_action")

    local creator = {}
    creator.__index = creator
    creator.create = function(...)
        local instance = setmetatable({}, class)
        instance.eventAccomplished = newEventHandler()
        instance:init(...)
        return instance
    end

    class.__index = class
    class.getTroopAction = function() return troop_action end
    class.accomplish = function(self, ...) 
        self.eventAccomplished(...)
    end

    return setmetatable(class, creator)
end

return SiegeAction

