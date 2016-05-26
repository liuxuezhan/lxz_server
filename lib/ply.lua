module(..., package.seeall)
cur= 1000--当前最大id
_d= {}--数据

function load(conf)
    local mongo = require "mongo"
    for name,v  in pairs(conf) do
        local db = mongo.client(v)
        local info = db[name].ply:find({})
        while info:hasNext() do
            local d = info:next()
            _d[d.name]=d
            if cur  < d.pid then
                cur = d.pid
            end
        end
    end
end

function new(server,name,pwd)
    if not _d[name] then
        cur = cur + 1
        local id = server.."_"..cur
        _d[name]={_id=id,pid=cur,name=name,pwd=pwd}
        return _d[name]
    end
end

