local eventHandler_mt = {
    __call = function(t, ...)
        for k, v in ipairs(t.__subscriber) do
            v(...)
        end
    end,
    __index = eventHandler_mt,
    add = function(self, functor)
        for k, v in ipairs(self.__subscriber) do
            if v == functor then
                print("same functor")
                return
            end
        end
        table.insert(self.__subscriber, functor)
    end,
    del = function(self, functor)
        local index = nil
        for k, v in ipairs(self.__subscriber) do
            if v == functor then
                index = k
                break
            end
        end
        if nil ~= index then
            table.remove(self.__subscriber, index)
        end
    end,
    clear = function(self)
        self.__subscriber = setmetatable({}, {__mode="v"})
    end,
    count = function(self)
        return #self.__subscriber
    end
}
eventHandler_mt.__index = eventHandler_mt

function newEventHandler()
    local handler = {__subscriber = setmetatable({}, {__mode="v"})}
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

