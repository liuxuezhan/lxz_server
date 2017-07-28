module(..., package.seeall)
_d = {}

function get(what,fun,id)
    if not _d[what] then _d[what]={} end
    if id then
        local co = _d[ what ][ id ]
        if not co then
            co = coroutine.create(fun)
        end
    else
        if #_d[ what ] > 0 then
            local co = table.remove(_d[ what ])
            return co
        else
            local co = coroutine.create(fun)
            table.insert(_d[ what ], co) 
        end
    end
    return co
end

function suspend(ret,id)
    local co = coroutine.running()
    if id  then
        if ret then 
            _d[ what ][ id ] = { co, ret }
        else 
            _d[ what ][ id ] = co 
        end
    end
    coroutine.yield(ret)

end

