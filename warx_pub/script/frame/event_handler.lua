local eventHandler_mt = {
    __call = function(t, ...)
        for k, v in pairs(t.__subscriber) do
            k(...)
        end
    end,
    __index = eventHandler_mt,
    add = function(self, functor)
        for k, v in pairs(self.__subscriber) do
            if k == functor then
                ERROR("[EventHandler] try to add same functor.")
                return
            end
        end
        self.__subscriber[functor] = true
    end,
    del = function(self, functor)
        for k, v in pairs(self.__subscriber) do
            if k == functor then
                self.__subscriber[k] = nil
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

