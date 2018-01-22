local Shuttle = {}

Shuttle.__index = Shuttle

function Shuttle:init(...)
    if self.onInit then
        self:onInit(...)
    end
end

function Shuttle:uninit()
    self:stop()
    if self.onUninit() then
        self:onUninit()
    end
end

function Shuttle:start()
    if self.onStart then
        self:onStart()
    end
end

function Shuttle:stop()
    if self.onStop then
        self:onStop()
    end
end

local shuttle_classes = {}

local function _createInstance(self, ...)
    local shuttle = setmetatable({}, self)
    shuttle:init()
    return shuttle
end

function makeShuttle(name, shuttle)
    assert(nil == shuttle_classes[name], string.format("exist shuttle: %s", name))

    shuttle.createInstance = _createInstance
    shuttle.__index = shuttle
    setmetatable(shuttle, Shuttle)
    shuttle_classes[name] = shuttle
    
    return shuttle
end

function createShuttle(name, ...)
    local shuttle_base = shuttle_classes[name]
    assert(shuttle_base, string.format("not exist shuttle: %s", name))
    return shuttle_base:createInstance(...)
end

return Shuttle

