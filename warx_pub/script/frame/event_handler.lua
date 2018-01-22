local eventHandler_mt = {
    __call = function(t, ...)
        --t:log("[EventHandler] call begin.")
        local call_count = t.call_count + 1
        t.call_count = call_count
        for k, v in pairs(t.__subscriber) do
            if v and v < call_count then
                k(...)
                --t:log("[EventHandler] call %s.", k)
            end
        end
        --t:log("[EventHandler] call finish.")
        for k, v in pairs(t.__subscriber) do
            if not v then
                t.__subscriber[k] = nil
            end
        end
    end,
    __index = eventHandler_mt,
    log = function(self, msg, ...)
        if not self.__debug then
            return
        end
        WARN(msg, ...)
    end,
    add = function(self, functor)
        --self:log("[EventHandler] add functor %s.", functor)
        for k, v in pairs(self.__subscriber) do
            if k == functor then
                if v then
                    ERROR("[EventHandler] try to add same functor.")
                else
                    self.__subscriber[k] = self.call_count
                end
                return
            end
        end
        self.__subscriber[functor] = self.call_count
    end,
    del = function(self, functor)
        --self:log("[EventHandler] del functor %s.", functor)
        for k, v in pairs(self.__subscriber) do
            if k == functor then
                self.__subscriber[k] = false
                break
            end
        end
    end,
    clear = function(self)
        self.__subscriber = setmetatable({}, {__mode="k"})
    end,
    count = function(self)
        local count = 0
        for k, v in pairs(self.__subscriber) do
            count = count + 1
        end
        return count
    end
}
eventHandler_mt.__index = eventHandler_mt

function newEventHandler()
    local handler = {__subscriber = setmetatable({}, {__mode="v"}), call_count = 0}
    setmetatable(handler, eventHandler_mt)
    return handler
end

local Functor = {
    __cache = setmetatable({},{__mode="k"}),
    __call = function(t, ...)
        t.__func(t.__object, ...)
    end,
    __eq = function(t1, t2)
        return t1.__object == t2.__object and t1.__func == t2.__func;
    end,
}

function newFunctor(object, func)
    if "table" ~= type(object) or "function" ~= type(func) then
        return
    end
    if nil ~= Functor.__cache[object] then
        for k, v in ipairs(Functor.__cache[object]) do
            if v.__func == func then
                return v
            end
        end
    else
        Functor.__cache[object] = {}
    end
    local o = {__object=object, __func=func}
    setmetatable(o, Functor)
    table.insert(Functor.__cache[object], o)
    return o
end

