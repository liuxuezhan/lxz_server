module(..., package.seeall)
_d = {}

function get(what,fun,id)
    if not _d[what] then _d[what]={} end
    if id then
        local co = _d[ what ][ id ]
        if not co then
           return coroutine.create(fun)
        else
            return co
        end
    else
        if _d[ what ] then
            local co = table.remove(_d[ what ])
            return co
        else
            return coroutine.create(fun)
        end
    end
end

function suspend(what,ret,id)
    local co = coroutine.running()
    if id  then
        if ret then 
            _d[ what ][ id ] = { co, ret }
        else 
            _d[ what ][ id ] = co 
        end
        coroutine.yield(ret)
    else
        table.insert(_d[ what ], co) 
        coroutine.yield(ret)
    end

end

