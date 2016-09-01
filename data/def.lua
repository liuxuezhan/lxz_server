json = require "json"
msg_t = require "msg_t"
save_t = require "save_t"
--------------------------------------------服务器配置--------------------------------------------------------------------------------
g_tm = os.time() --系统时间
g_cid = 1    --集群id
g_nid = 1000  --玩家id开始
g_sid = "warx1" --服务器id
g_pid = g_cid*1000*1000 --玩家角色id开始 

--登录服务器
g_login={name="login1", host = "192.168.103.225", port = 8001, multilogin = true,  db="db1",  }
g_login1={name="login1", host = "192.168.103.225", port = 8001, multilogin = true,  db="db1",  }
g_login2={name="login2", host = "127.0.0.1", port = 8001, multilogin = true,  db="db2",  }

--分区服务器
g_game={  name = "game1", host = "192.168.103.225", port = 8888, maxclient=3000, room ="room1", db = "db1" } 
g_game1={  name = "game1", host = "192.168.103.225", port = 8888, maxclient=3000, room ="room1", db = "db1" } 
g_game2={  name = "game2", host = "127.0.0.1", port = 8888, maxclient=3000, room ="room1", db = "db2" } 

--数据库
g_db = {
    db1={ host = "192.168.100.12", port = 27017, },
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
----------------------------------------------公用函数---------------------------------------------------------------------------------
function do_load(mod)
    package.loaded[ mod ] = nil
    require( mod )
end

function tab_add(...)--合并buff值
    local t = {}
    for _, ts in pairs({...}) do
        for k, v in pairs(ts) do
            t[k] = (t[k] or 0 ) + v 
        end
    end
    return t  
end

function get_val_by(what, ...)--计算buff值
    local bidx = what
    local ridx = string.format("%s_R", what)
    local eidx = string.format("%s_A", what)
    local b, r, e = 0, 0, 0 -- base, multiple, add
    for _, v in pairs({...}) do
        b = b + (v[ bidx ] or 0)
        r = r + (v[ ridx ] or 0)
        e = e + (v[ eidx ] or 0)
    end
    return b * (1 + r * 0.0001) + e
end


function get_nums_by(what, ...)--计算一个buff各种加成

    local bidx = what
    local ridx = string.format("%s_R", what)
    local eidx = string.format("%s_A", what)
    local b, r, e = 0, 0, 0 -- base, multiple, add
    for _, v in pairs({...}) do
        b = b + (v[ bidx ] or 0)
        r = r + (v[ ridx ] or 0)
        e = e + (v[ eidx ] or 0)
    end
    return b, r, e
end


function calc_crosspoint(sx, sy, dx, dy, rect)--直线与矩形相交
    local crosspoint = {}
    if sx == dx then
        local miny = math.min(sy, dy)
        local maxy = math.max(sy, dy)

        if miny < rect.y1 and maxy > rect.y1 then table.insert({sx, rect.y1}) end
        if miny < rect.y2 and maxy > rect.y2 then table.insert({sx, rect.y2}) end

        return crosspoint
    end

    local k = (sy - dy) / (sx - dx)
    local b = sy - k * sx
    function get_linear_y(x) return k * x + b end
    function get_linear_x(y) return (y - b) / k end

    local crosspoint = {}
    local y1 = get_linear_y(rect.x1)
    if y1 > rect.y1 and y1 < rect.y2 then
        table.insert(crosspoint, {rect.x1, y1})
    end

    local x1 = get_linear_x(rect.y1)
    if x1 > rect.x1 and x1 < rect.x2 then
        table.insert(crosspoint, {x1, rect.y1})
    end

    local y2 = get_linear_y(rect.x2)
    if y2 > rect.y1 and y2 < rect.y2 then
        table.insert(crosspoint, {rect.x2, y2})
    end

    local x2 = get_linear_x(rect.y2)
    if x2 > rect.x1 and x2 < rect.x2 then
        table.insert(crosspoint, {x2, rect.y2})
    end

    if #crosspoint > 0 then return crosspoint end
end

function calc_line_length(sx, sy, dx, dy) --两点间距离
    return math.sqrt((dy - sy) ^ 2 + (dx - sx) ^ 2)
end

function diff_days(timestamp1, timestamp2) --计算两个时间戳间隔的天数
    local days1 = math.floor((timestamp1 + TIME_ZONE) / 86400)
    local days2 = math.floor((timestamp2 + TIME_ZONE) / 86400)
    return math.abs(days1 - days2)
end


function get_days(timestamp) --计算1970年1月1日到当前的天数
    return math.floor((timestamp + TIME_ZONE) / 86400)
end


function cur_hour(timestamp)--计算这个时间戳是当天的第几个小时
    local s = timestamp % 86400
    return math.floor(s / 3600)
end

function t_random(t)--序列化随机
    local n =0
    for _,v in pairs (t) do
        n = n+v
    end
    local p = math.random(n)
    n=0
    for k,v in pairs (t) do
        n = n+v
        if p <= n then
            return k
        end
    end
end

function next_day() -- 第二天零点
    local now = os.date("*t", gTime)
    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0,sec=0 }
    return os.time(temp) + 24 * 3600
end

function date(time)--是否跨天
    if (not time) or (time == 0)  then
        return true
    end

    if os.date("%d")~=os.date("%d",time) then
        return true
    end
    return false
end

function month(time)--是否跨月

    if (not time) or (time == 0)  then
        return true
    end

    if os.date("%m")~=os.date("%m",time) then
        return true
    end
    return false
end

function tm_str(time)--时间串
    return os.date("%Y-%m-%d %X", time or os.time() )
end

function tab_num(t)--计算表项数
    local num = 0
    if t then
        for _, v in pairs(t) do
            num=num+1
        end
    end
    return num
end

function copy(object)--复制表
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end  -- for
        return new_table
        --return setmetatable(new_table, getmetatable(object))
    end  -- function _copy
    return _copy(object)
end  -- function deepcopy

function split(str, reps)  --分割字符串
    local resultStrsList = {};
    string.gsub(str,'[^'..reps..']+', function(w) table.insert(resultStrsList, w) end );
    return resultStrsList;
end

function load_file (path)--读取csv文件数据为lua表
    local file = io.open(path,"r")
    for line in file:lines() do
    local t = split(line, ",");
    for k, v in pairs(t) do
        print(v);
    end
    end
    file:close()
end

function save_file (mod,path,buf)
    local file= io.open(path,mod)
    file:write("\n"..buf)
    file:close()
end



function print_tab(sth,h)

    if type(sth) ~= "table" then
        if type(sth) == "boolean" then
            if sth then
                cprint(h.."true",1) 
            else 
                cprint(h.."true",1)
            end 
        elseif type(sth) == "function" then 
            cprint(h.."function",1)
        elseif type(sth) == "string" and (not string.find(sth,'^[_%a][_.%w]*$')) then
            cprint(h.."\""..sth.."\"",1)
        else
            cprint(h..sth,1)
        end
        return
    end

    cprint(h,1)

    local space, deep = string.rep(' ', 2), 0

    local function _dump(t)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if type(k)=="number" then
                key = "["..key.."]"
            elseif type(k) == 'string' and (not string.find(k,'^[_%a][_.%w]*$')) then
                key = "[\""..key.."\"]"
            end

            if type(v) == "table" then

                deep = deep + 2
                cprint(string.format( "%s%s = {", string.rep(space, deep - 1), key )) 
                _dump(v)
                cprint(string.format("%s}",string.rep(space, deep-1)))
                deep = deep - 2
            elseif type(v) == "string" and (not string.find(v,'^[_%a][_.%w]*$')) then
                cprint(string.format("%s%s = \"%s\"", string.rep(space, deep + 1), key, v)) 
            else
                cprint(string.format("%s%s = %s", string.rep(space, deep + 1), key, v)) 
            end 
        end 
    end

    cprint("{")
    _dump(sth)
    cprint("}")
end

function cprint(s,num)--颜色答应
    if not s  then return end
    local c = "echo -e \"\\033[40;31;2m"-- 红色
    if num == 1 then --蓝色
        c =  "echo -e \"\\033[40;34;2m"
    end
    local cool = c..s.." \\033[0m \"" 
    os.execute(cool) 
end

function log(...)--日志
    local info = debug.getinfo(2)
    local d = "["..(info.short_src or "FILE")..":"..(info.currentline or 0).."]"..":"
    for _,v in pairs({...}) do
        d = d..json.encode(v).."@"
    end
    cprint(d)
    os.execute("logger -p local0.info "..d )
end

function lxz(...)--打印lua变量数据到日志文件
    local info = debug.getinfo(2)
    local h = "["..tm_str(time).."]".."["..(info.short_src or "FILE")..":"..(info.name or "")..":"..(info.currentline or 0).."]:"

    for _,v in pairs({...}) do
        print_tab(v,h)
    end
end

function lxz1(...)--打印lua变量数据到日志文件
    local info = debug.getinfo(2)
    cprint(debug.traceback(),1)
    for _,v in pairs({...}) do
        print_tab(v)
    end
end

