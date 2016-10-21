

require "lib_tools"
json = require "json"
msg_t = require "msg_t"
save_t = require "save_t"
--------------------------------------------服务器配置--------------------------------------------------------------------------------
g_tm = os.time() --系统时间
g_cid = 1    --集群id
g_nid = 1000  --玩家id开始
g_sid = "warx1" --服务器id
g_pid = g_cid*1000*1000 --玩家角色id开始 
g_path = "test" 
g_host = "192.168.100.12" 

--登录服务器
g_login={name="login1", port = 60001, multilogin = true,  db="db1", }

--分区服务器
g_game={  name = "game1", port = 60002, maxclient=3000, room ="room1", db = "db1" }

--数据库
g_db = {
    db1={ port = 27017, },
    db2={ host = "127.0.0.1", port = 27017, },
    -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
}

-------------------------------------------warx模块----------------------------------------------------------------------------
getfenv = getfenv or function(f)
    f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
    local name, val
    local up = 0
    repeat
        up = up + 1
        name, val = debug.getupvalue(f, up)
    until name == '_ENV' or name == nil
    return val
end

setfenv = setfenv or function(f, t) --lua5.3 没有,模拟一个
    f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
    local name
    local up = 0
    repeat
        up = up + 1
        name = debug.getupvalue(f, up)
    until name == '_ENV' or name == nil
    if name then
        debug.upvaluejoin(f, up, function() return name end, 1) -- use unique upvalue
        debug.setupvalue(f, up, t)
    end
end


module = module or function(mname)  --lua5.3 没有,模拟一个
    _ENV[mname] = _ENV[mname] or {}
    setmetatable(_ENV[mname], {__index = _ENV})
    setfenv(2, _ENV[mname])
end

require "ply_t"
require "name_t"
require "co_t"
----------------------------------------------公用函数---------------------------------------------------------------------------------






