------------------------- Labor
local Labor = {}

Labor.__index = Labor

function Labor:init(functor, ...)
    self.finish_handler = functor
    if self.onStart then
        return self:onStart(...)
    end
end

function Labor:uninit()
    if self.finish_handler then
        self.finish_handler(self)
    end
    if self.onStop then
        self:onStop()
    end
end

function Labor:addListener(name, functor)
end

local function _createLabor(self, functor, ...)
    local labor = setmetatable({}, self)
    labor.id = getSn("Autobot.Labor")
    if not labor:init(functor, ...) then
        labor:uninit()
        return
    end
    return labor
end

local labor_classes = {}

function makeLabor(name, labor)
    assert(nil == labor_classes[name], string.format("exist labor: %s", name))

    labor.createInstance = _createLabor
    labor.__index = labor
    setmetatable(labor, Labor)
    labor_classes[name] = labor

    return labor
end
------------------------- Labor

local LaborManager = {}

function LaborManager:init(player)
    self.player = player
    self.labors = {}
end

function LaborManager:uninit()
    for k, v in pairs(self.labors) do
        v:uninit()
    end
    self.labors = nil
end

function LaborManager:createLabor(name, functor, ...)
    local labor_class = labor_classes[name]
    assert(labor_class, string.format("not exist labor: %s", name))

    local labor = labor_class:createInstance(functor, ...)
    if nil == labor then
        return
    end
    self.labors[labor.id] = labor
    return labor
end

function LaborManager:deleteLabor(labor)
    if not self.labors[labor.id] then
        return
    end
    self.labors[labor.id] = nil
    labor:uninit()
end

return makeClass(LaborManager)

