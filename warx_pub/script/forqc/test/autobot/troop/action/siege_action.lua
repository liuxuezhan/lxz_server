local SiegeAction = {}

local factories = {}

function SiegeAction.makeClass(name, class, troop_action)
    assert(nil == factories[name], string.format("exist siege action: %s", name))
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
    factories[name] = class

    return setmetatable(class, creator)
end

function SiegeAction.createAction(name, ...)
    local factory = factories[name]
    if nil == factory then
        return
    end
    return factory.create(...)
end

return SiegeAction

