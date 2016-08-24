module(..., package.seeall)
cur = 1000--当前最大id
_d = {}--数据

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


function login( pid )
    if pid == 0 then --新建 
        cur = cur + 1
        local pid = _sid.."_"..cur
        _d[pid]={_id=pid,}
    else

    end
    return _d[pid]
end

function new(server,name,pwd)
    if not _d[name] then
        cur = cur + 1
        local id = server.."_"..cur
        _d[name]={_id=id,pid=cur,name=name,pwd=pwd}
        return _d[name]
    end
end

function doCondCheck(pid, class, mode, lv, ...)
    local self = ply[pid]
    if class == "OR" then
        for _, v in pairs({mode, lv, ...}) do
            if doCondCheck(pid,unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then
        for _, v in pairs({mode, lv, ...}) do
            if not doCondCheck(pid,unpack(v)) then return false end
        end
        return true

    elseif class == "res" then
        return

    elseif class == "build"  then
        local t = resmng.prop_build[ mode ]
        if t then
            local c = t.Class
            local m = t.Mode
            local l = t.Lv
            for _, v in pairs(self.build) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == "tech" then
        local t = resmng.get_conf("prop_tech", mode)
        if t then
            for _, v in pairs(self.tech) do
                local n = resmng.get_conf("prop_tech", v)
                if n and t.Class == n.Class and t.Mode == n.Mode and t.Lv <= n.Lv then
                    return true
                end
            end
        end
    end

    return false
end

function consCheck(pid,tab) --前置条件检查
    if tab then
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not doCondCheck(pid,class, mode, lv ) then return false end
        end
    end
    return true
end
