local AutobotTimer = {}

AutobotTimer.periodic_routines = {}
AutobotTimer.normal_routines = {}

function AutobotTimer:addPeriodicTimer(functor, interval, ...)
    local id, node = timer.new_ignore("AutoBotPeriodicTimer", interval, self)
    node.cycle = interval
    node._autobot = {
        func = functor,
        params = table.pack(...),
    }
    self.periodic_routines[id] = node
    return id
end

function AutobotTimer:delPeriodicTimer(id)
    if nil == id then
        return
    end
    if self.periodic_routines[id] then
        timer.del(id)
    end
    self.periodic_routines[id] = nil
end

function AutobotTimer:addTimer(functor, interval, ...)
    local id, node = timer.new_ignore("AutoBotNormalTimer", interval, self)
    node._autobot = {
        func = functor,
        params = table.pack(...),
    }
    self.normal_routines[id] = node
    return id
end

function AutobotTimer:delTimer(id)
    if nil == id then
        return
    end
    if self.normal_routines[id] then
        timer.del(id)
    end
    self.normal_routines[id] = nil
end

function AutobotTimer:_onPeriodicTimer(id)
    local routine = self.periodic_routines[id]
    if nil == routine then
        return 0
    end
    routine._autobot.func(table.unpack(routine._autobot.params))
    return 1
end

function AutobotTimer:_onNormalTimer(id)
    local routine = self.normal_routines[id]
    if nil == routine then
        return 0
    end
    routine._autobot.func(table.unpack(routine._autobot.params))
end

timer._funs["AutoBotPeriodicTimer"] = function(id, self)
    return self:_onPeriodicTimer(id)
end

timer._funs["AutoBotNormalTimer"] = function(id, self)
    return self:_onNormalTimer(id)
end

return AutobotTimer

