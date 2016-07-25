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

-- Zhao@2016年2月16日：数学库扩展
function math.clamp(max,min,value)
    if min > max then max,min = min,max end
    if value > max then value = max end
    if value < min then value = min end
    return value
end
-- 返回最接近该数的整数
function math.round(num)
    if not type(num) == "number" then return end
    local int_num,decimal = math.modf(num)
    if decimal<0.5 then
        return int_num
    else
        return int_num+1
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

function table.index_of(tb,o)
    for k,v in ipairs(tb) do
        if v == o then
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


-- Hx@2016-01-15 : ety format
etypipe = {}
etypipe[EidType.Player] =       {"eid", "x", "y", "propid", "uid", "pid", "photo", "name", "uname"}
etypipe[EidType.Res]    =       {"eid", "x", "y", "propid", "uid", "pid", "val", "extra"}
--etypipe[EidType.Troop]  =       {"eid", "culture", "owner_eid", "start_eid", "start_uid", "dest_eid", "dest_uid", "sx", "sy", "dx", "dy", "tmStart", "tmOver", "tmCur", "action", "status", "curx", "cury", "speed", "soldier_num"}
etypipe[EidType.Troop]  =       {"eid", "culture", "action", "owner_eid", "owner_pid", "owner_uid", "target_eid", "target_pid", "target_uid", "sx", "sy", "dx", "dy", "tmCur", "curx", "cury", "speed", "tmStart", "tmOver", "soldier_num","be_atk_list"}
etypipe[EidType.Monster]=       {"eid", "x", "y", "propid", "hp", "level"}
etypipe[EidType.UnionBuild] =   {"eid", "x", "y", "propid", "uid", "sn","idx","hp","state","name"}
etypipe[EidType.NpcCity]=   {"eid", "x", "y", "propid", "state", "startTime","endTime", "unions"}
etypipe[EidType.KingCity]=   {"eid", "x", "y", "propid", "state", "status","startTime", "endTime", "occuTime","uid", "uname"}
etypipe[EidType.MonsterCity]=   {"eid", "x", "y", "propid", "state", "class", "startTime", "endTime"}
etypipe[EidType.Camp]    =       {"eid", "x", "y", "propid", "pid", "uid"}
etypipe[EidType.LostTemple]=   {"eid", "x", "y", "propid", "state", "startTime", "endTime", "uid"}



function etypipe.pack(filter, xs)
    local val = {}
    for k, v in pairs(filter) do
        assert(xs[v], "ety add lack key: ".. v)
        val[k] = xs[v]
    end
    --return cmsgpack.pack(val)
end

function etypipe.unpack(filter, data)
    local val = {}
    for k, v in pairs(filter) do
        val[v] = data[k]
    end
    return val
end
-- api
function etypipe.parse(data)
    local eid = data[1]
    local mode = math.floor(eid / 0x010000)
    local node = etypipe[ mode ]
    if node then
        return etypipe.unpack(node, data)
    else
        WARN("no etypipid, eid=0x%08x", eid)
        return data
    end
end

function etypipe.add(data)
    --assert(data.eid, data.x, data.y)
    local mode = math.floor(data.eid / 0x010000)
    local node = etypipe[ mode ]
    if not node then
        WARN("what type, etypipe.add??")
        dumpTab(data, "etypipe.add error")
    end

    if is_troop(data.eid) then 
        data.be_atk_list = data.be_atk_list or {}
        --c_add_troop(data.eid, data.sx, data.sy, data.dx, data.dy, etypipe.pack(node, data))
    else
        if not data.size then WARN("no size, ") end
        data.size = data.size or 4
        --c_add_ety(data.eid, data.x, data.y, data.size, 0, etypipe.pack(node, data))
    end

end

function get_val_by(what, ...)
    local node = resmng.get_conf("prop_effect_type", what)
    --if not node then WARN("effect %s not found in prop_effect_type", what) end

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
    --local node = resmng.prop_effect_type[ what ]
    --if not node then WARN("effect %s not found in prop_effect_type", what) end

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

        if miny < rect.y1 and maxy > rect.y1 then table.insert({sx, rect.y1}) end
        if miny < rect.y2 and maxy > rect.y2 then table.insert({sx, rect.y2}) end

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
    local cx,cy,hw = 512, 512, 256
    
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
        seq = seq or 1
        if seq >= 100 then return end
        local idx = class * 10000 + mode * 100 + seq
        return builds[ idx ]
    end
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

function can_date(time)--是否跨天
    if os.date("%d")~=os.date("%d",time) then
        return true
    end
    return false
end

function can_month(time)--是否跨月
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
    if conf then
        offset = conf.Size * 0.5
        if offset < 1 then offset = 1 end
    end
    return math.floor(ety.x + offset), math.floor(ety.y + offset)
end

function calc_pow(lv, builds, arms, equips, techs, genius )
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
-- 计算除去已有资源所需的金币
function calc_need_res_gold(res_num, res_id)
    local _res = Model.get_pro("res")[res_id]
    local _have_res = _res[1]+_res[2]
    if _have_res>=res_num then
        return 0
    else
        return calc_buyres_gold(res_num-_have_res, res_id)
    end
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
    count = 2 + math.ceil((member_count - UNION_CASTALCOUNT_LIMIT[1]) / UNION_CASTALCOUNT_LIMIT[2]) 
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
function analysis_award(tab)
    local list = {}
    
    for k, v in pairs(tab) do
        local unit = {}
        unit.type, unit.id, unit.num = unpack(v)
        local prop_tmp = nil
        if unit.type == "item" then
            local array = ana_item(unit)
            if array ~= nil then
                for i = 1, #array, 1 do
                    table.insert(list, array[i])
                end
            end
        elseif unit.type == "res" or unit.type == "respicked" then
            ana_res(unit)
            table.insert(list, unit)
        elseif unit.type == "hero" then
            ana_hero(unit)
            table.insert(list, unit)
        end
    end
    return list
end

function ana_item(unit)
    local prop_tab = resmng.prop_itemById(unit.id)
    if prop_tab == nil then
        return nil
    end
    local list = {}
    if prop_tab.Open == 0 then
        unit.icon = prop_tab.Icon
        unit.grade = prop_tab.Color or 1
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
end

function ana_hero(unit)
    local prop_tab = resmng.prop_hero_basicById(unit.id)
    if prop_tab == nil then
        return
    end
    unit.icon = prop_tab.Icon
    unit.grade = prop_tab.Quality or 1
end

--得到礼包里面的奖励物品
function get_award_box_item(item_id)
    local prop_item = resmng.prop_itemById(item_id)
    if prop_item == nil or prop_item.Param == nil then
        return nil
    end

    local list = {}
    for _, info in pairs(prop_item.Param) do
        for k, v in pairs(info[2]) do
            local unit = {}
            unit.type, unit.id, unit.num = unpack(v)
            local prop_tmp = nil
            if unit.type == "item" then
                prop_tmp = resmng.prop_itemById(unit.id)
                if prop_tmp ~= nil then
                    unit.icon = prop_tmp.Icon
                    unit.grade = prop_tmp.Color
                end
            elseif unit.type == "res" or unit.type == "respicked" then
                prop_tmp = resmng.prop_resourceById(unit.id)
                if prop_tmp ~= nil then
                    unit.icon = prop_tmp.Icon
                    unit.grade = prop_tmp.Color
                end
            elseif unit.type == "hero" then
                prop_tmp = resmng.prop_hero_basicById(unit.id)
                if prop_tmp ~= nil then
                    unit.icon = prop_tmp.Icon
                    unit.grade = prop_tmp.Quality
                end
            end

            if unit.grade == nil then
                unit.grade = 1
            end
            table.insert(list, unit)
        end
    end
    return list
end

function is_in_black_land( x, y )
    return  x >= 512 and x < 512 + 256 and y >= 512 and y < 512 + 256 
end

-- the first bit idx is 1, not 0
function set_bit( val, idx )
    local n1 = 2 ^ idx
    local n0 = 2 ^ (idx - 1)

    local remain = val % n1
    if remain < n0 then
        val = val + n0
    end
    return val
end

-- the first bit idx is 1, not 0
function get_bit( val, idx )
    local n1 = 2 ^ idx
    local n0 = 2 ^ (idx - 1)

    local remain = val % n1
    if remain < n0 then return 0
    else return 1 end
end

--------------------------------------------------------------------
--------------------------------------------------------------------




--------------------------------------------------------------------------------
-- 常用调试函数，简写函数名
p = dumpTab

