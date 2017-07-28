cur = 1000--当前最大id
local _M = {_d = {}}--数据
_onlines = {} --在线玩家
local _name = ...
function _M.load(conf)
    local mongo = require "mongo"
    local db = mongo.client(conf)
    local info = db[g_sid].ply:find({})
    while info:hasNext() do
        local d = info:next()
        _d[d.name]=d
        if cur  < d.pid then
            cur = d.pid
        end
    end
end

function _M.cs_msg( fd,pid,mid,msg )
    if mid == "cs_enter" then
        local self = _d[pid]
        if not self then log("没有角色")  return end
        

    end
end

function _M.cs_login(msg)--接受
lxz(msg)
    self={_id=msg.online.pid,nid=msg.nid }
    --ply_t.save(self)
end

function _M.enter(pid,tid)
    local self = _d[pid]
    if not self then
        self = {_id=pid,tid= tid }
    end
end


function _M.save(self)
    _d[self._id]=self
    save_t.data[_name][self._id]=self
end

function _M.new(server,name,pwd)
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
return _M
