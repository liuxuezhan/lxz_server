-- warx项目common/tool.lua 移植

local function tm_zone() --取本地时区差
    local now = os.time()
    return os.difftime(now, os.time(os.date("*t", now)))
end

function guid()
    local seed = { '1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'} 
    local tb = {}
    for i =1,32 do
        table.insert(tb,seed[math.random(16)])
    end
    return table.concat(tb)
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


function diff_days(timestamp1, timestamp2) --计算两个时间戳间隔的天数
    local days1 = math.floor((timestamp1 + TIME_ZONE) / 86400)
    local days2 = math.floor((timestamp2 + TIME_ZONE) / 86400)
    return math.abs(days1 - days2)
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


function string.split(str, delimiter)
    if str == nil or str == "" or delimiter == nil then
        return nil
    end

    local results = {}
    for match in (str ..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(results, match)
    end
    return results
end

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
------------------------------------------打印相关-------------------------------------------
function lxz1(...)--打印lua变量数据到日志文件
    lxz(...)
    cprint(debug.traceback(),1)
end
function lxz(...)--打印表
    local info = debug.getinfo(2)
    local h = "["..tm_str(time).."]".."["..(info.short_src or "FILE")..":"..(info.name or "")..":"..(info.currentline or 0).."]:"

    if ... == nil then
        cprint(h,1)
    else
        for k,v in pairs({...}) do
            if k == 1 then
                print_tab(v,h)
            else
                print_tab(v)
            end
        end
    end
end

function print_tab(sth,h)
    h = h or ""
    if type(sth) ~= "table" then
        if type(sth) == "boolean" then
            if sth then
                cprint(h.."true",1) 
            else 
                cprint(h.."false",1)
            end 
        elseif type(sth) == "function" then 
            cprint(h.."function",1)
        elseif type(sth) == "string" then
            cprint(h.."\\\""..sth.."\\\"",1)
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
            elseif type(k) == "string" then
                key = "[\\\""..key.."\\\"]"
            end

            if type(v) == "table" then

                deep = deep + 2
                cprint(string.format( "%s%s = {", string.rep(space, deep - 1), key )) 
                _dump(v)
                cprint(string.format("%s}",string.rep(space, deep-1)))
                deep = deep - 2
            elseif type(v) == "string" then
                cprint(string.format("%s%s = \\\"%s\\\"", string.rep(space, deep + 1), key, v)) 
            elseif type(v) == "function" then 
                cprint(string.format("%s%s = function", string.rep(space, deep + 1), key )) 
            elseif type(v) == "boolean" then
                if sth then
                    cprint(string.format("%s%s = true", string.rep(space, deep + 1), key )) 
                else 
                    cprint(string.format("%s%s = false", string.rep(space, deep + 1), key )) 
                end 
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
    local c = "echo -e \"\\033[31;2m"-- 红色
    if num == 1 then --蓝色
        c =  "echo -e \"\\033[34;2m"
    end
    local cool = c..s.." \\033[0m \"" 
    os.execute(cool) 
    --os.execute(cool.."|jg") 

end

function log_t(...)--日志
    local info = debug.getinfo(2)
    local d = "["..(info.short_src or "FILE")..":"..(info.currentline or 0).."]"..":"
    for _,v in pairs({...}) do
        d = d..json.encode(v).."@"
    end
    cprint(d)
    os.execute("logger -p local0.info "..d )
end



-----------------------字符串扩展----------------------------------------------------------------
function string.starts_with(str,start_str)
    if str == start_str then return true end
    if not str or not start_str then return false end
    return start_str == string.sub(str,1,string.len(start_str))
end

function string.ends_with(str,end_str)
    if str == end_str then return true end
    if not str or not end_str then return false end
    return end_str == string.sub(str,-string.len(end_str))
end

function string.format_ex(str,tab_arg)
    if not str then return "" end
    if not tab_arg then return str end
    local match_count = 0
    for i = 1,#tab_arg do
        local pattern = string.format("{%d}",i) 
        str,match_count = string.gsub(str,pattern,tostring(tab_arg[i]))
        if match_count > 1 then 
            print("<color=yellow>target string has more than one pattern: "..pattern.."</color>\nstring is: "..str)
        end
    end
    return str
end

local function format_ts(s,fun)
    while true do
        local i,e=string.find(s,"{%d,%d}")
        if i==nil then
            break
        end

        local p=string.sub(s,i,e)
        local p2=string.split(string.sub(p,2,-2),",")

        s=string.gsub(s,p,fun(p2[1],p2[2]),1)
    end
    return s
end

local function replace_ts(s,i,e,r)
    local t=string.sub(s,1,i-1)
    if r==nil then return t.."[R]"..string.sub(s,e+1) end
    t=t..r..string.sub(s,e+1)
    return t
end



function string.format_ts(s,...)
    if s==nil then
        return s
    end

    local i,e=string.find(s,"%%%d%$%w")
    local arg={...}

    if i==nil then
        return string.format(s,...)
    end
    
    local replace_table=arg[1]
    if replace_table==nil then
        return "[R]"..s
    end

    while true do
        local p=string.sub(s,i,e)
        local mtype=string.sub(p,4,4)
        local index=tonumber(string.sub(p,2,2))
        if mtype=="s" or mtype=="d" then
             if type(replace_table[index])=="table" then
                local ms=""
                for i,v in ipairs(replace_table[index]) do
                    ms=ms..v
                    if i ~= #replace_table[index] then
                        ms=ms..","
                    end
                end
                s=replace_ts(s,i,e,ms)
            else
                s=replace_ts(s,i,e,replace_table[index])
            end
        elseif mtype=="z" then
            if type(replace_table[index])=="table" then
                local ms=""
                for i,v in ipairs(replace_table[index]) do
                    ms=ms..get_value(v)
                    if i ~= #replace_table[index] then
                        ms=ms..","
                    end
                end
                s=replace_ts(s,i,e,ms)
            else
                s=replace_ts(s,i,e,get_value(replace_table[index]))
            end
        else 
            break
        end

        i,e=string.find(s,"%%%d%$%w")
        if i==nil then
            break
        end
    end
    return s
end

-- Zhao@2016年2月16日：数学库扩展
function math.clamp(max,min,value)
    if min > max then max,min = min,max end
    if value > max then value = max end
    if value < min then value = min end
    return value
end
-- 返回最接近该数的整数
function math.round(num)
    if num >= 0 then
        return math.floor(num + 0.5)
    else
        return math.floor(num - 0.5)
    end
end

function basename(path)
    if type(path) ~= "string" then
        INFO("basename: %s not a string")
        return nil
    end

    return ((path):gsub(".*[\\/]", ""))
end

--clone一个table
function table.clone(table)
    local save_t = {}

    local function table_clone(t)
        local dt = {}
        if type(t) == "table" then
            if save_t[t] then
                dt = t
            else
                save_t[t] = t
                for k,v in pairs(t) do
                    if type(v) == "table" then
                        local v1 = table_clone(v)
                        dt[k] = v1
                    else
                        dt[k] = v
                    end
                end
            end
        end
        return dt
    end

    save_t = {}
    return table_clone(table)
end

function table.index_of(tb,o,field)
    for k,v in ipairs(tb) do
        if field ~= nil and v[field] == o then
            return k
        elseif v == o then
            return k
        end
    end

    return -1
end

----对目标table的value求和
function table.get_value_sum(tab)
    local sum = 0
    for k,v in pairs(tab) do
        if "number" == type(v) then
            sum = sum + v
        end
    end
    return sum
end

-- 多层向下查找
function table.loop_find(tab,...)
    if type(tab) == "table" then
        local _value = tab
        for i,v in ipairs({...}) do
            _value = _value[v]
            if not _value then
                break
            end
        end
        return _value
    end
end


function class(base, _ctor)
    local c = {}    -- a new class instance
    if not _ctor and type(base) == 'function' then
        _ctor = base
        base = nil
    elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
        for i,v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end

    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}

    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj,c)

        if _ctor then
            _ctor(obj,...)
        end
        return obj
    end

    c._ctor = _ctor
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    setmetatable(c, mt)
    return c
end


--------------------------------------------------------------------------------
-- Function : 检查元素是否在 table 中
-- Argument : tab value
-- Return   : succ - k / fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_in_table(tab, value)
    if type(tab) ~= "table" then
        ERROR("Argument error: tab isn't a table, type(tab) = %s", type(tab))
        return false
    end

    for k, v in pairs (tab) do
        if v == value then
            return k
        end
    end

    return false
end


--------------------------------------------------------------------------------
-- Function : 获取 table 元素个数
-- Argument : table
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function get_table_valid_count(tab)
    if not tab then
        return 0
    end

    local count = 0
    for k, v in pairs(tab) do
        if v then count = count + 1 end
    end

    return count
end


--------------------------------------------------------------------------------
-- Function : 时间戳转字符串
-- Argument : timestamp
-- Return   : NULL
-- Others   : timestamp 为空则取当前时间
--------------------------------------------------------------------------------
function timestamp_to_str(timestamp)
    return os.date("%Y-%m-%d %X", timestamp or 0)
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

function get_num_by(what, ...)
    local val = 0
    for _, v in pairs({...}) do
        val = val + (v[ what ] or 0)
    end
    return val
end

function calc_crosspoint(sx, sy, dx, dy, rect) --直线与矩形相交
    local crosspoint = {}
    if sx == dx then
        local miny = math.min(sy, dy)
        local maxy = math.max(sy, dy)

        if miny < rect.y1 and maxy > rect.y1 then table.insert(crosspoint,{sx, rect.y1}) end
        if miny < rect.y2 and maxy > rect.y2 then table.insert(crosspoint,{sx, rect.y2}) end

        return crosspoint
    end

    --y = kx + b
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

function calc_distance(sx, sy, dx, dy)
    local dist = math.sqrt((dy - sy) ^ 2 + (dx - sx) ^ 2)
    local cx,cy,hw = 608, 608, 64
    
    if sx < cx and dx < cx then return dist end
    if sy < cy and dy < cy then return dist end
    if sx > cx + hw and dx > cx + hw then return dist end
    if sy > cy + hw and dy > cy + hw then return dist end

    local cross = calc_crosspoint(sx, sy, dx, dy, {x1=cx, y1=cy, x2=cx+hw, y2=cy+hw})
    if not cross then return dist end
    
    local ncross = #cross
    if ncross == 1 then
        if sx > cx and sx < cx+hw and sy > cy and sy < cy+hw then
            local zone = calc_line_length(sx ,sy, cross[1][1], cross[1][2])
            return dist - zone, zone
        else
            local zone = calc_line_length(dx ,dy, cross[1][1], cross[1][2])
            return dist - zone, zone
        end
    elseif ncross == 2 then
        local zone = calc_line_length(cross[1][1], cross[1][2], cross[2][1], cross[2][2])
        return dist - zone, zone
    end
    return dist
end


--计算两个时间戳间隔的天数
function get_diff_days(timestamp1, timestamp2)
    local days1 = math.floor((timestamp1 + TIME_ZONE) / 86400)
    local days2 = math.floor((timestamp2 + TIME_ZONE) / 86400)
    return math.abs(days1 - days2)
end

function get_days(timestamp) --计算1970年1月1日到当前的天数
    return math.floor((timestamp + TIME_ZONE) / 86400)
end

--计算这个时间戳是当天的第几个小时
function get_cur_hour(timestamp)
    local s = timestamp % 86400
    return math.floor(s / 3600)
end

function get_next_day_stamp(timestamp)
    local dest_days = get_days(timestamp) + 1
    return (dest_days * 86400)
end


function get_one_building(builds, class, mode )
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

-- 第二天零点
function get_next_time()
    local now = os.date("*t", gTime)
    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0,sec=0 }
    return os.time(temp) + 24 * 3600
end

function can_date(time)--是否跨天

    if (not time) or (time == 0)  then
        return true
    end

    if os.date("%d")~=os.date("%d",time) then
        return true
    end
    return false
end

function can_month(time)--是否跨月

    if (not time) or (time == 0)  then
        return true
    end

    if os.date("%m")~=os.date("%m",time) then
        return true
    end
    return false
end


function table_count(tab)
    local n = 0
    for k, v in pairs(tab or {}) do
        n = n + 1
    end
    return n
end

function recalc_sinew( val, tm, now, mul )
    tm = tm or 0
    local elaps = now - tm
    local num = math.floor( elaps / 300 )
    local remain = elaps - num * 300

    if val < 100 then
        val = val + num
        if val > 100 then val = 100 end
        return val, now - remain
    else
        return val, now
    end
end

function is_in_black_land( x, y )
    --return  x >= 512 and x < 512 + 256 and y >= 512 and y < 512 + 256 
    return  x >= 608 and x < 608 + 64 and y >= 608 and y < 608 + 64  -- 640 - 16 * 2
end

function clr_bit( val, idx )
    val = math.floor( val )
    local n1 = 2 ^ idx
    local n0 = 2 ^ (idx - 1)

    local remain = val % n1
    if remain >= n0 then
        val = val - n0
    end
    return math.floor( val )
end

-- the first bit idx is 1, not 0
function set_bit( val, idx )
    val = math.floor( val )
    local n1 = 2 ^ idx
    local n0 = 2 ^ (idx - 1)

    local remain = val % n1
    if remain < n0 then
        val = val + n0
    end
    return math.floor(val)
end

-- the first bit idx is 1, not 0
function get_bit( val, idx )
    local n1 = 2 ^ idx
    local n0 = 2 ^ (idx - 1)

    local remain = val % n1
    if remain < n0 then return 0
    else return 1 end
end

function get_first_zero( val )
    for i = 1, 32, 1 do
        if get_bit( val, i ) == 0 then return i end
    end
end

function format_time(time)  
    local hour = math.floor(time/3600);  
    local minute = math.fmod(math.floor(time/60), 60)  
    local second = math.fmod(time, 60)  

    local rtTime = ""
    if hour ~= 0 then
        rtTime = string.format("%s:%s:%s", hour, minute, second)  
    else
        rtTime = string.format("%s:%s",  minute, second)  
    end
    return rtTime  
end 

function can_enter( lv_castle, lv_pos )
    if lv_castle <  6 then return lv_pos <= 1 end
    if lv_castle < 10 then return lv_pos <= 2 end
    if lv_castle < 12 then return lv_pos <= 3 end
    if lv_castle < 15 then return lv_pos <= 4 end
    return true
end

-----------------------------warx模块支持-------------------------------------------------------------------------------------
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
function string_split(str, delim, maxNb)      
    if string.find(str, delim) == nil then  
        return { str }  
    end  
    if maxNb == nil or maxNb < 1 then  
        maxNb = 0    -- No limit   
    end  
    local result = {}  
    local pat = "(.-)" .. delim .. "()"   
    local nb = 0  
    local lastPos   
    for part, pos in string.gfind(str, pat) do  
        nb = nb + 1  
        result[nb] = part   
        lastPos = pos   
        if nb == maxNb then break end  
    end  
    -- Handle the last field   
    if nb ~= maxNb then  
        result[nb + 1] = string.sub(str, lastPos)   
    end  
    return result   
end  

function string_startswith(str, prefix)
    return string.find(str, prefix) == 1
end

function string_endswith(str, suffix)
    return string_startswith(string.reverse(str), string.reverse(suffix))
end

function string_trim(s)
    local first = string.find(s, '%S')
    if not first then return '' end
    local last = string.find(string.reverse(s), '%S')
    return string.sub(s, first, #s + 1 - last)
end

-- 计算utf8字符串的字符个数，英文字符和中文字符等价都算作1个
function string_utf8_len( s )
    local _, count = string.gsub(s, "[^\128-\193]", "")
    return count
end

function array_equal(t, t2)
    for i, v in ipairs(t) do
        if v ~= t2[i] then return false end
    end
    return true
end

function array_merge(array1, array2)
    local ret = {}
    for i = 1, #array1 do
        table.insert(ret, array1[i])
    end
    for i = 1, #array2 do
        table.insert(ret, array2[i])
    end
    return ret
end

function array_copy(ar)
    return array_merge({}, ar)
end

function array_sub(ar, st, ed)
    local r = {}
    for i = st, ed do
        table.insert(r, ar[i])
    end
    return r
end

function array_unique(array)
    local r = {}
    local s = {}
    for _, v in ipairs(array) do
        if not s[v] then
            s[v] = true
            table.insert(r, v)
        end
    end
    return r
end

function array_new(len, val)
    local r = {}
    for i = 1, len do
        table.insert(r, val)
    end
    return r
end

function array_find(t, val)
    for i, v in ipairs(t) do
        if val == v then return i end
    end
    return -1
end

function array_insert(t, val)
    if array_find(t, val) == -1 then
        table.insert(t, val)
    end
end

function array_delete(t, val)
    local ix = array_find(t, val)
    if ix > -1 then
        table.remove(t, ix)
    end
end

function array_find_in_field(t, field, val)
     for i, v in ipairs(t) do
        if val == v[field] then return i end
    end
    return -1
end

function array_find_obj_in_field(t, field, val)
    for i, v in ipairs(t) do
        if val == v[field] then return v end
    end
    return nil
end

function array_reverse(t)
    local ret = {}
    for i= #t, 1, -1  do
        table.insert(ret, t[i])
    end
    return ret
end

function array_random(t, num)
    if num >= #t then return array_copy(t) end
    local ret = {}
    local ixs = {}
    for i = 1, num do
        local r = math.random(#t)
        while array_find(ixs, r) > -1 do
            r = math.random(#t)
        end
        table.insert(ixs, r)
        table.insert(ret, t[r])
    end
    return ret
end

function array_resort(t)
    for i = 1, #t do
        local r = math.random(#t)
        t[i], t[r] = t[r], t[i]
    end
end

function table_size(t)
    local r = 0
    for _, _ in pairs(t) do r = r + 1 end
    return r
end

function table_empty(t)
    return not next(t)
end

function table_merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
    return dest
end

function table_find(t, val)
    for k, v in pairs(t) do
        if val == v then return k end
    end
    return nil
end

function table_equal(t, t2)
    local n = 0
    for k, v in pairs(t) do
        if v ~= t2[k] then return false end
        n = n + 1
    end
    return n == table_size(t2)
end

function copyTab(object)
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

function table_copy(t)
    return table_merge({}, t)
end

function table_keys(t)
    local r = {}
    for k, _ in pairs(t) do
        table.insert(r, k)
    end
    return r
end

function table_values(t)
    local r = {}
    for _, v in pairs(t) do
        table.insert(r, v)
    end
    return r
end

function table_filter(t, func)
    local r = {}
    for k, v in pairs(t) do
        if func(k, v) then r[k] = v end
    end
    return r
end

function table_random(t, num)
    local ar = table_values(t)
    return array_random(ar, num)
end

function table_from_key(t, key, value)
    local r = {}
    for k, v in pairs(t) do
        if v[key] == value then table.insert(r, v) end
    end
    return r
end

function table_map(t, func)
    local r = {}
    for k, v in pairs(t) do
        local nk, nv = func(k, v)
        r[nk] = nv
    end
    return r
end

function table_requal(t, t2)
    local n = 0
    for k, v in pairs(t) do
        if type(v) == 'table' then
            local v2 = t2[k]
            if type(v2) ~= 'table' then return false end
            if not table_requal(v, v2) then return false end
        else
            if v ~= t2[k] then return false end
        end
        n = n + 1
    end
    return n == table_size(t2)
end

function table_rcopy(t)
    local r = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            r[k] = table_rcopy(v)
        else
            r[k] = v
        end
    end
    return r
end

-- 是否为中文
function is_gbchar( _char )
    if _char >= 0x81 then
        return true
    else
        return false     
    end
end

function sub_gbstr(_str,_len)
    local real_len = 0
    local length = string.len(_str)
    local i = 1

    while real_len < _len and i <= length do
        local char = string.sub(_str,i,i)
        if is_gbchar(string.byte(char)) then
            i = i + 3
        else
            i = i + 1
        end
        real_len = real_len + 1
    end

    return string.sub(_str,1,i)
end

--按照中文回车
function gen_chinese_str(_str,len)
    if _str == " " then
        return _str
    end
    local length = string.len(_str)
    local i = 1
    local ret_arr = {}

    while i <= length do
        local char = string.sub(_str,i,i)
        if is_gbchar(string.byte(char)) then
            table.insert(ret_arr, string.sub(_str,i,i+2))
            i = i + 3
        else
            table.insert(ret_arr, string.sub(_str,i,i))
            i = i + 1
        end
    end
    local ret = ""
    local c = 0
    for _, w in ipairs(ret_arr) do
        c = c + 1
        ret = ret .. w
        if c >= len then
            break
        end
    end
    return ret
end
--按照中文回车
function split_chinese(_str)
    if _str == " " then
        return _str
    end
    local length = string.len(_str)
    local i = 1
    local ret_arr = {}

    while i <= length do
        local char = string.sub(_str,i,i)
        if is_gbchar(string.byte(char)) then
            table.insert(ret_arr, string.sub(_str,i,i+2))
            i = i + 3
        else
            table.insert(ret_arr, string.sub(_str,i,i))
            i = i + 1
        end
    end
    local name = ""
    for _, w in ipairs(ret_arr) do
        name = name .. w .. "\n"
    end
    return name
end

function is_utf8char( c )
    if c >= 128 then
        if c < 194 or c > 245 then
            return false, 0
        end

        if c >= 194 and c < 224 then
            b = 1
        elseif c >= 224 and c < 240 then
            b = 2
        --elseif c >= 240 and c <= 244 then 不需要支持
        --    b = 3
        else
            return false, 0
        end
        return true, b
    end
    return false, 0
end


function is_program_keyword( ch )
    program_keyword = { [','] = true, [';'] = true, ['/'] = true, ['\''] = true, ['\\'] = true, ['%'] = true, ['?'] = true, ['#'] = true, ['<'] = true, ['>'] = true }
    if( program_keyword[ch] == true )then
        return true
    else
        return false
    end
end

function is_punctuation_char( s )
    if( type(s) == "string" and string.len(s) == 1 )then
        if( string.match( s, "%p") )then
            return true
        else
            return false
        end
    else
        return false
    end
end

function is_alpha_num_char( s )
    if( type(s) == "string" and string.len(s) == 1 )then
        if( string.match( s, "%w") )then
            return true
        else
            return false
        end
    else
        return false
    end
end
--检查是否合法的字符
function is_valid_string2(s)
    if( type(s) == "string" )then
        local length = string.len(s)
        local i = 1
        while( i <= length )do
            local first_char = string.sub( s, i, i )
            local utf8, offset = is_utf8char( string.byte( first_char ) )
            if utf8 then
                local utf8_char = string.sub( s, i+1, i+offset )
                for j = 1, offset, 1 do
                    local c = string.byte( utf8_char, j)
                    if c < 128 or c >= 192 then
                        print("is invalidate utf8")
                        return false, "is invalidate utf8"
                    end
                end
                i = i + offset
            elseif( is_program_keyword( first_char ) == true )then
                print("is keyword")
                return false, "is keyword"
            elseif( is_alpha_num_char( first_char ) == false )then
                if( is_punctuation_char( first_char ) == false )then
                    print("is alpha num char")
                    return false, "is alpha num char"
                end
            end
            i = i + 1
        end
    else
        return false, "not string"
    end
    return true
end

--检查是否含有英文，数字
function have_number_word(s)
    if( type(s) == "string" )then
        return false
    end
    local length = string.len(s)
    local i = 1
    while( i <= length )do
        local first_char = string.sub( s, i, i )
        local utf8, offset = is_utf8char( string.byte( first_char ) )
        if utf8 then
            i = i + offset
        else
            local c = string.byte(first_char)
            if (c >= 0x41 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A) then
                return true
            end
        end
        i = i + 1
    end
    return false
end

------------------------------------------------------------------------------
--是否包含过滤词
function is_include_filter(_str)
    local filter_map = resmng.prop_filter
    for word, _ in pairs(filter_map) do
        if string.find( _str, word ) then 
            return true
        end
    end
    return false
end


function string.replace( str, tofind, toreplace )
    tofind = tofind:gsub( "[%-%^%$%(%)%%%.%[%]%*%+%?]", "%%%1" )
    toreplace = toreplace:gsub( "%%", "%%%1" )
    return ( str:gsub( tofind, toreplace ) )
end

-- 替换敏感词
function replace_filter(_str, _rep)
    _rep = _rep or '*'
    local filter_map = resmng.prop_filter
    for word, _ in pairs(filter_map) do
        _str = string.replace( _str, word, _rep )
    end
    return _str
end

-- 世界频道替换敏感词
function replace_world_filter(_str, _rep)
    _rep = _rep or '*'
    local filter_map = resmng.prop_World_filter
    for word, _ in pairs(filter_map) do
        _str = string.replace( _str, word, _rep )
    end
    return _str
end
------------------------------------------------------------------------------

local floor = math.floor
function bxor(a,b)
  local r = 0
  for i = 0, 31 do
    local x = a / 2 + b / 2
    if x ~= floor (x) then
      r = r + 2^i
    end
    a = floor (a / 2)
    b = floor (b / 2)
  end
  return r
end

function gen_invite_id(id)
    if id == 0 then
        return id
    end
    return bxor(id,59864)
end

function bind_func( self, func )
    local function target_func( ... )
        func( self, unpack(arg) )
    end
    return target_func
end

function mergeAB2A(dst, src)
    dst = dst or {}
    for k, v in pairs(src) do
        table.insert(dst, v)
    end
    return dst
end

--迭代器，与pairs用法相同，保证索引从小到大取值而不是按哈希值取值
function pairsByIndex(tbl)
    local key_list = {}
    for k, v in pairs(tbl) do
        table.insert(key_list, k)
    end
    table.sort(key_list)
    local i = 0

    return function()
        i = i + 1
        if key_list[i] then
            return key_list[i], tbl[key_list[i]]
        end
    end
end

--- 分隔字符成组
function string_split_array(str, exp)
    local result = {}
    local strlen = #str
    local index = 1
    while index < strlen do
        local start_pos, end_pos = string.find(str, exp, index)
        if start_pos == nil then
            break;
        else
            local match_str = string.sub(str, index, start_pos - 1)
            result[#result + 1] = match_str
            index = end_pos + 1
        end
    end
    result[#result + 1] = string.sub(str, index)

    return result
end

--- table sort by key
function table_sort_by_key(tbl, func)
  local key_lst = table_keys(tbl)

  sort_func = sort_func or function(a, b) return a < b end

  table.sort(key_lst, function(a, b)
    return sort_func(a, b)
  end)

  local i = 0
  return function()
    i = i + 1
    if key_lst[i] then
      return key_lst[i], tbl[key_lst[i]]
    end
  end
end

--洗牌算法，用于将一组数据等概率随机打乱。等概率算法。
local function shuffle(t)
    if not t then return end
    local cnt = #t
    for i=1,cnt do
        local j = math.random(i,cnt)
        t[i],t[j] = t[j],t[i]
    end
end

--分红包算法
local function split(m,n)
    --构造m-1个可用的分割标记位
    local mark = {}
    for i=1,m-1 do
        mark[i] = i
    end

    --打乱标所有记位
    shuffle(mark)
    --构建一个新的表，并从mark表中取前n-1个位置作为有效标记位
    local validMark = {}
    for i=1,n-1 do
        validMark[i] = mark[i]
    end

    --重新按从小到大排序有效标记
    table.sort(validMark,function (a,b)
        return a<b
    end)

    --设置有效标记表的头、尾分别为0和m
    validMark[0] = 0
    validMark[n] = m
    --构建输出数组
    local out = {}
    for i=1,n do
        out[i] = validMark[i] - validMark[i-1]
    end
    return out
end

function num_format(num,accuracy) --数组表达式
    if type(num) ~= "number" then return "∞" end
    if          not accuracy then accuracy = 1 end
    local fom = string.format("%%.%df",accuracy)
    local num_new = math.abs(num)
    local sign = 1 
    if num < 0 then sign = -1 end
    if num_new < 1000 then 
        return math.floor(num_new) * sign
    elseif num_new < 1000000 then
        return string.format(fom .. "k",num*0.001 * sign)
    elseif num_new < 1000000000 then
        return string.format(fom .. "M",num*0.000001 * sign)
    else
         return string.format(fom .. "G",num*0.000000001 * sign) 
    end
end

