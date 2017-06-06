-----------------------------------warx项目专用----------------------------------------------
-- 原warx 的socket由c语言引擎统一队列处理 ，移植后由lua分发处理
json = require "json"
require "mytool"
g_host = "192.168.100.12"

_list={

    db_server1 ={ 
        db1={ host="192.168.67.135",port = 27017, },
        db2={ host="192.168.101.223",port = 27017, },
        -- db1={ host="127.0.0.1",port = 27017, },
        -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
    },

}

g_warx_t = {   port = 8001, maxclient=3000, room ="room1", db_name = "db_server1" } 

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

function c_pull_msg_roi()
    return ROI_MSG.NTY_NO_RES 
end
 c_pid = {}
local _x,_y = 100,100
function c_mov_eye(pid,x,y)
    c_pid[pid] = {x=x,y=y}
    local zx = math.floor( x / 16 ) 
    local zy = math.floor( y / 16 )
    monster.do_check(zx, zy)
    for _, e in pairs(gEtys or {} ) do
        if not is_troop(e) and  calc_line_length(x,y,e.x,e.y) < 10  then
            etypipe.add(e) 
        end
    end
end

function c_add_eye(x, y, lv, pid, gid)
    c_pid[pid] = {x=x,y=y}
    local zx = math.floor( x / 16 ) 
    local zy = math.floor( y / 16 )
    monster.do_check(zx, zy)
    for _, e in pairs(gEtys or {} ) do
        if  not is_troop(e) and calc_line_length(x,y,e.x,e.y) < 10  then
           -- etypipe.add(e) 
        end
    end
end

function c_add_ety(...)
    local d = {...} 
    for pid, _ in pairs(c_pid or {} ) do
        local p = getPlayer(pid)
        if p then
            Rpc:addEty(p, d)
        end
    end
end

function c_add_troop(...)
    local d = {...} 
    for pid, _ in pairs(c_pid or {} ) do
        local p = getPlayer(pid)
        if p  then  
            Rpc:addEty(p, d)
        end
    end
end

function c_get_map_access(zx, zy)
    return 0 
end

function c_get_pos_by_lv(...)
     _x = _x + 4
    return _x,_y
end

function c_get_pos_in_zone(x, y, r, r)
    return x,y
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


function c_add_scan(...)
end

function c_get_pos_born(...)
    _x = _x + 4
    return _x,_y
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

function c_tick(...)
    return 1
end
function skiplist.get_range(...)
end
function skiplist.clear(...)
end
function c_msec()
    return os.time()
end

function pullString()
    return ""
end



