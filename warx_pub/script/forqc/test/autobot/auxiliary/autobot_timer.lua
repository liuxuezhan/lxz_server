local AutobotTimer = {}

AutobotTimer.periodic_routines = {}
AutobotTimer.normal_routines = {}

function AutobotTimer:addPeriodicTimer(functor, interval, ...)
    assert(nil ~= functor, "functor can't be nil")
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
    return self:addMsecTimer(functor, interval * 1000, ...)
end

function AutobotTimer:addMsecTimer(functor, interval, ...)
    assert(nil ~= functor, "functor can't be nil")
    local id, node = timer.new_msec_ignore("AutoBotNormalTimer", interval, self)
    node._autobot = {
        func = functor,
        params = table.pack(...),
    }
    self.normal_routines[id] = node
    return id
end

function AutobotTimer:adjustTimer(id, interval)
    if nil == id then
        return
    end
    local node = self.normal_routines[id]
    if nil == node then
        return
    end
    local over = gTime + interval
    timer.adjust(id, over)
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
    local interval = routine._autobot.func(table.unpack(routine._autobot.params))
    if nil ~= interval and type(interval) == "number" then
        routine.cycle = interval
    end
    return 1
end

function AutobotTimer:_onNormalTimer(id)
    local routine = self.normal_routines[id]
    if nil == routine then
        return 0
    end
    routine._autobot.func(table.unpack(routine._autobot.params))
    self:delTimer(id)
end

timer._funs["AutoBotPeriodicTimer"] = function(id, self)
    return self:_onPeriodicTimer(id)
end

timer._funs["AutoBotNormalTimer"] = function(id, self)
    return self:_onNormalTimer(id)
end

return AutobotTimer

