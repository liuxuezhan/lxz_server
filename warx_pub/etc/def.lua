-----------------------------------warx项目专用----------------------------------------------
-- 原warx 的socket由c语言引擎统一队列处理 ，移植后由lua分发处理
json = require "json"
require "my_tools"
g_host = "192.168.100.12"

_list={

    db_server1 ={ 
        db1={ port = 27017, },
        -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
    },

}

g_warx_t = {   port = 8888, maxclient=3000, room ="room1", db_name = "db_server1" } 

--数据库
g_db = {
    db1={ host = "192.168.100.12", port = 27017, },
    -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
}

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

function c_get_zone_lv(tx, ty)
    return 1
end

function c_get_culture(...)
    return 0
end

function c_tlog_start(...)
end
function c_get_top()
end

function pullInt()
end

function c_add_eye(...)
end

function c_mov_eye(...)
end

function pullNext()
end

function llog(...)
--lxz(...)
end

function linfo(...)
lxz(...)
end 

function lwarn(...)
lxz(...)
end 

function c_add_ety(...)
end

function c_add_troop(...)
end

function c_add_scan(...)
end

local x,y=0,0
function c_get_pos_born(...)
    x = x + 4
    return x,y
end

function c_roi_view_start(...)
end

function c_time_set_start(...)
end

function c_time_step(...)
end

function c_time_release(...)
end

function   addTimer(...)
end
local id = 1 
function getId(name)
    id = id + 1
    return id
end

skiplist = {

 new = function (...) end,
 insert = function (...) end,
 get_range_with_score = function (...) end,

 }

mathx = {
 frexp = function (v) return v end,
 }

 cmsgpack = {
  pack = function (v) return v end,
   }

 function getMap(...)
     return  config.Map 
 end

 function c_roi_init(...)
 end

 function c_roi_set_block(...)
 end
 function c_init_log(...)
 end

 function     pushHead(...)
 end
 function     pushInt(...)
 end
 function     pushOver(...)
 end
 function     c_set_gate( ...)
 end

 function c_md5(...)
 end

function c_get_pos_by_lv(...)
    return 0,0
end

 function connect(host,port,...)
    local driver = require "socketdriver"
    local fd = driver.connect(host,port)
    return fd
 end

 function begJob (...)
     --main_loop 没消息也循环
     g_beg = true
 end

function gen_checker(... )
end


