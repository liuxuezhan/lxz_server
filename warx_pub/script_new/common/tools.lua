-- Hx@2015-11-25 : common functions

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

-- Zhao@2016年1月28日:字符串扩展
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

--清理table数据
function table.clear(tb)
    for k,v in pairs(tb) do
        tb[k] = nil
    end
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

--[[
-- >stack>stack>[file:line]
function debug.stack(level)
    level = level or 0
    level = level + 2
    local info = debug.getinfo(level)

    local result = ""

    local dep = 3
    repeat
        result = result.. string.format("@%s:%s:%s",
            basename(info.short_src or ""), info.name or "", info.currentline or ""
        )

        level = level + 1
        info = debug.getinfo(level)
        dep = dep - 1
    until not info or dep < 0

    return result
end
--]]

-- Hx@2015-11-30 :
function handler(obj, method)
    assert(obj)
    assert(method)
    return function(...)
        method(obj, ...)
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

function tojson(tbl,indent)
    assert(tal==nil)
    if not indent then indent = 0 end

    local tab=string.rep("  ",indent)
    local havetable=false
    local str="{"
    local sp=""
    if tbl then
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                havetable=true
                if(indenct==0) then
                    str=str..sp.."\r\n  "..tostring(k)..":"..tojson(v,indent+1)
                else
                    str=str..sp.."\r\n"..tab..tostring(k)..":"..tojson(v,indent+1)
                end
            else
                str=str..sp..tostring(k)..":"..tostring(v)
            end
            sp=";"
        end
    end

    if(havetable) then      str=str.."\r\n"..tab.."}"   else        str=str.."}"    end

    return str
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


etypipe = {}
etypipe[EidType.Player] =       {"propid", "eid", "x", "y", "uid", "pid", "photo", "name", "uname", "officer", "nprison", "state","uflag"}
etypipe[EidType.Res]    =       {"propid", "eid", "x", "y", "uid", "pid", "val", "extra"}
etypipe[EidType.Troop]  =       {"propid", "eid", "culture","action", "owner_eid", "owner_pid", "owner_uid", "target_eid", "target_pid", "target_uid", "sx", "sy", "dx", "dy", "tmCur", "curx", "cury", "speed", "tmStart", "tmOver", "soldier_num","be_atk_list", "flag", "name", "mcid", "alias", "heros", "target_propid"}
etypipe[EidType.Troop]  =       {"propid", "eid", "culture","action", "owner_eid", "owner_pid", "owner_uid", "target_eid", "target_pid", "target_uid", "sx", "sy", "dx", "dy", "tmCur", "curx", "cury", "speed", "tmStart", "tmOver", "soldier_num","be_atk_list", "flag", "name", "mcid", "alias", "heros", "target_propid"}
etypipe[EidType.Monster]=       {"propid", "eid", "x", "y", "hp", "level","born"}
etypipe[EidType.UnionBuild] =   {"propid", "eid", "x", "y", "uid","alias", "sn","idx","hp","state","name","val","culture","holding","build_speed","fire_speed"}
etypipe[EidType.NpcCity]=       {"propid", "eid", "x", "y", "state", "startTime","endTime", "unions", "randomAward", "declareUnions", "getAwardMember"}
etypipe[EidType.KingCity]=      {"propid", "eid", "x", "y", "state", "status","startTime", "endTime", "occuTime","uid", "uname"}
etypipe[EidType.MonsterCity]=   {"propid", "eid", "x", "y", "state", "class", "startTime", "endTime"}
etypipe[EidType.Camp]    =      {"propid", "eid", "x", "y", "pid", "uid"}
etypipe[EidType.LostTemple]=    {"propid", "eid", "x", "y", "state", "startTime", "endTime", "uid", "uname", "born"}


function etypipe.pack(filter, xs)
    local val = {}
    for k, v in pairs(filter) do
        if xs[v] then
            val[k] = xs[v]
        else
            val[k] = 0
            --WARN( "ety add lack key: " .. v)
        end
    end
    return cmsgpack.pack(val)
end

function etypipe.unpack(filter, data)
    local val = {}
    for k, v in pairs(filter) do
        val[v] = data[k]
    end
    return val
end

function etypipe.parse(data)
    local propid = data[1]
    local mode = math.floor(propid / 1000000)
    local node = etypipe[ mode ]
    if node then
        return etypipe.unpack(node, data)
    else
        WARN("no etypipid, eid=0x%08x", propid)
        return data
    end
end

function etypipe.add(data)
    local mode = math.floor(data.propid / 1000000)
    local node = etypipe[ mode ]
    if not node then
        WARN("what type, etypipe.add??")
        dumpTab(data, "etypipe.add error")
        return
    end

    if is_troop(data) then 
        data.be_atk_list = data.be_atk_list or {}
        data.mcid = data.mcid or 0
        c_add_troop(data.propid, data.eid, data.sx, data.sy, data.dx, data.dy, etypipe.pack(node, data))
        print( "============================ add_troop, ", data._id, data.propid )
        --print( debug.traceback() )
        
    else
        if not data.size then WARN("no size, propid=%d", data.propid) end

        if not data.size or data.size == 0 then data.size = 4 end
        c_add_ety(data.propid, data.eid, data.x, data.y, data.size, 0, etypipe.pack(node, data))
    end
end

function get_val_by(what, ...)
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


function get_nums_by(what, ...)
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

--直线与矩形相交
function calc_crosspoint(sx, sy, dx, dy, rect)
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

    --[[ 
    local prop_build = resmng.prop_world_unit[self.propid]
    local rect = {
        x1 = self.x - self:get_range(),
        y1 = self.x + prop_build.Size + self:get_range(),
        x2 = self.y - self:get_range()
        y2 = self.y + prop_build.Size + self:get_range()
    }
    --]]

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

    --if #crosspoint == 2 then
    --    --print(crosspoint[1][1], crosspoint[1][2])
    --    --print(crosspoint[2][1], crosspoint[2][2])
    --    return crosspoint
    --else
    --    return nil
    --end
end

--两点间距离
function calc_line_length(sx, sy, dx, dy)
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

--计算1970年1月1日到当前的天数
function get_days(timestamp)
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


function get_building(builds, class, mode, seq)
    if builds then
        if seq then
            return builds[class * 10000 + mode * 100 + seq]
        else
            for i=1,BUILD_MAX_NUM[class][mode] do
                if builds[class * 10000 + mode * 100 + i] then
                    return builds[class * 10000 + mode * 100 + i]
                end
            end
        end
    end
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


function get_ety_offset(ety)
    local conf = resmng.get_conf("prop_world_unit", ety.propid)
    if conf then
        return conf.Size * 0.5
    end
    WARN("ety.eid = %d, no conf", ety.eid)
    return 1
end

function get_ety_pos(ety)
    local offset = 1
    local conf = resmng.get_conf("prop_world_unit", ety.propid)
    if not conf.Size then
        WARN("ety.propid = %d, no size", ety.propid)
        return 
    end
    if conf then
        offset = conf.Size * 0.5
        if offset < 1 then offset = 1 end
    end
    return math.floor(ety.x + offset), math.floor(ety.y + offset)
end

function calc_pow(lv, builds, arms, equips, techs, genius, heros)
    local pow = 0

    local conf = resmng.get_conf("prop_level", lv)
    if conf then
        pow = pow + conf.Pow
    end

    for _, v in pairs(builds or {}) do
        local conf = resmng.get_conf("prop_build", v.propid)
        if conf then
            if conf.Pow then
                pow = pow + (conf.Pow or 0)
            else
                print("build no pow, id = ", conf.ID)
            end
        end
    end

    for id, num in pairs(arms or {}) do
        local conf = resmng.get_conf("prop_arm", id)
        if conf then
            pow = pow + conf.Pow * num
        end
    end

    for _, v in pairs(equips or {}) do        
        if v.pos > 0 then
            local conf = resmng.get_conf("prop_equip", v.propid)
            if conf then
                pow = pow + (conf.Pow or 0)
            end
        end
    end

    for _, v in pairs(techs or {}) do
        local conf = resmng.get_conf("prop_tech", v)
        if conf then
            pow = pow + (conf.Pow or 0)
        end
    end

    for _, v in pairs(genius or {}) do
        local conf = resmng.get_conf("prop_genius", v)
        if conf then
            pow = pow + (conf.Pow or 0)

        end
    end
   
    for _,v in pairs(heros or {}) do
        if v.status == HERO_STATUS_TYPE.FREE or v.status == HERO_STATUS_TYPE.BUILDING or 
           v.status == HERO_STATUS_TYPE.MOVING or v.status == HERO_STATUS_TYPE.BEING_CURED then
           pow = pow + (v.fight_power or 0)
        end
    end

    return math.ceil(pow)
end

function calc_res(res_id,res_num) --计算资源单位量
    local prop = resmng.get_conf("prop_resource", res_id)
    if not prop then return res_num end
    return res_num * prop.Mul
end

function calc_acc_gold(total)
    local orig = total
    if total < 1 then return 0 end
    local cost = 0
    for k, v in ipairs(CLEAR_CD_COST) do
        if total >= v[1] then
            cost = cost + v[2]
            total = total - v[1]
        else
            cost = cost + math.ceil(total * v[2] / v[1])
            total = 0
            break
        end
    end
    if total > 0 then
        local v = BUY_RES_COST[ #CLEAR_CD_COST ]
        cost = cost + math.ceil(total * v[2] / v[1])
    end
    -- print("time_to_gold", orig, cost)
    return cost
end

function calc_buyres_gold(res_num, res_id)
    local orig = res_num
    local total = RES_RATE[ res_id ]  * res_num
    if total < 1 then return 0 end
    local cost = 0
    for k, v in ipairs(BUY_RES_COST) do
        if total >= v[1] then
            cost = cost + v[2]
            total = total - v[1]
        else
            cost = cost + math.ceil(total * v[2] / v[1])
            total = 0
            break
        end
    end
    if total > 0 then
        local v = BUY_RES_COST[ #BUY_RES_COST ]
        cost = cost + math.ceil(total * v[2] / v[1])
    end
    -- print("res_to_gold", res_id, orig, cost)
    return cost
end

function get_taxrate(propid,effect)--获取税率
    local c = resmng.get_conf("prop_build",propid)
    if c.Mode ~= BUILD_FUNCTION_MODE.MARKET then
        return 45
    end
    return (c.Effect.CountTax + (effect or 0))
end

function get_castle_count(member_count)
    local count = 0
    if member_count < UNION_CASTALCOUNT_LIMIT[1] then
        return count
    end
    count = 1 + math.floor((member_count - UNION_CASTALCOUNT_LIMIT[1]) / UNION_CASTALCOUNT_LIMIT[2])    
    return count
end

function get_can_occupycity_count(member_count)    
    if member_count < UNION_OCCUPY_LIMIT[1] then
        return 0
    end    
    return 1 + math.floor((member_count - UNION_OCCUPY_LIMIT[1]) / UNION_OCCUPY_LIMIT[2])
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

--------------------------------------------------------------------
--解析奖励
--------------------------------------------------------------------
function analysis_award(tab, close_open)    
    local list = {}
    local box = {}
    
    for k, v in pairs(tab) do
        local unit = {}
        unit.type, unit.id, unit.num = unpack(v)
        local prop_tmp = nil
        if unit.type == "item" then
            local array = ana_item(unit, close_open)
            if array ~= nil then
                for i = 1, #array, 1 do
                    table.insert(list, array[i])
                end
            end

            --第一层物品信息
            local prop_tab = resmng.prop_itemById(unit.id)
            if prop_tab ~= nil and prop_tab.Open == 1 then
                local temp = {}
                temp.icon = prop_tab.Icon
                temp.grade = prop_tab.Color or 1
                temp.name = prop_tab.Name
                table.insert(box, temp)
            end

        elseif unit.type == "res" or unit.type == "respicked" then
            ana_res(unit)
            table.insert(list, unit)

        elseif unit.type == "hero" then
            ana_hero(unit)
            table.insert(list, unit)

        elseif unit.type == "soldier" then
            ana_solider(unit)
            table.insert(list, unit)
        end
    end   
    return list, box
end

function ana_item(unit, close_open)
    local prop_tab = resmng.prop_itemById(unit.id)
    if prop_tab == nil then
        return nil
    end
    local list = {}
    if prop_tab.Open == 0 or close_open == true then
        unit.icon = prop_tab.Icon
        unit.grade = prop_tab.Color or 1
        unit.name = prop_tab.Name
        table.insert(list, unit)
    else
        for _, info in pairs(prop_tab.Param) do
            for k, v in pairs(info[2]) do
                local tmp = {}
                tmp.type, tmp.id, tmp.num = unpack(v)
                if tmp.type == "item" then
                    local prop_tmp = resmng.prop_itemById(tmp.id)
                    if prop_tmp ~= nil then
                        tmp.icon = prop_tmp.Icon
                        tmp.grade = prop_tmp.Color or 1
                        tmp.name = prop_tmp.Name
                    end
                elseif tmp.type == "res" or tmp.type == "respicked" then
                    ana_res(tmp)
                elseif tmp.type == "hero" then
                    ana_hero(tmp)
                end
                table.insert(list, tmp)
            end
        end
    end
    return list
end

function ana_res(unit)
    local prop_tab = resmng.prop_resourceById(unit.id)
    if prop_tab == nil then
        return
    end
    unit.icon = prop_tab.Icon
    unit.grade = prop_tab.Color or 1
    unit.name = prop_tab.Name
end

function ana_hero(unit)
    local prop_tab = resmng.prop_hero_basicById(unit.id)
    if prop_tab == nil then
        return
    end
    unit.icon = prop_tab.Icon
    unit.grade = prop_tab.Quality or 1
    unit.name = prop_tab.Name
end

function ana_solider(unit)
    local prop_arm = resmng.prop_armById(unit.id)
    if prop_arm == nil then
        return
    end
    unit.icon = prop_arm.Icon
    unit.grade = 1
    unit.name = prop_arm.Name
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

function check_union_cross(union)
    if not union then
        return
    end
    local u = {}
    if type(union) == "number" then
        u = unionmng:get_union(union) or {}
    else
        u = union
    end
    if not u.map_id then
        return false
    end
    return true
end

function check_ply_cross(ply)
    local union = unionmng.get_union(ply.uid)
    if union then
        return check_union_cross(union)
    end
    return false
--    local p = {}
--    if type(ply) == "number" then
--        p = getPlayer(ply) or {}
--    else
--        p = ply
--    end
--    if not p.map_id then
--        return false
--    end
 --   return true
end

--------------------------------------------------------------------
--------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 常用调试函数，简写函数名
p = dumpTab

