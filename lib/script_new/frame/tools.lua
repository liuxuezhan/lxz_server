
gCoroBad = {}
function doLoadMod(name, mod)
    mod = mod or name
    if name == "debugger" then
        if not _G[ name ] then
            _G[ name ] = require( mod )
        end
    else
        package.loaded[ name ] = nil
        _G[ name ] = require( mod )
        LOG("load %s", name)
    end
end

function do_load(mod)
    package.loaded[ mod ] = nil
    require( mod )
    INFO("load module %s", mod)
    print("load module", mod)
end


map_file_svn = {}
function svnnum( _svn_info )
    local key = nil
    local svn = nil
    for k,v in string.gmatch(_svn_info,"$Id: ([a-z_/0-9A-Z]*.lua) ([0-9]*)") do
        key = k
        svn = v
        break
    end
    if key == nil then
        INFO("[SCRIPT](lua) regist_file_svn fail. catch filename fail. " .. (_svn_info or "") )
        return
    end
    if svn == nil then
        INFO("[SCRIPT](lua) regist_file_svn fail. catch svn fail. " .. (_svn_info or "") )
        return
    end

    map_file_svn[key]=_svn_info
end

-- llog  --> localA
-- linfo --> localA  localB
-- lwarn --> localA  localB  localC

function LOG(fmt, ...)
    if config.LogLevel and config.LogLevel < 3 then return end
    local s = string.format(fmt, ...)
    llog(s)
end

function INFO(fmt, ...)
    if config.LogLevel and config.LogLevel < 2 then return end
    local s = string.format(fmt, ...)
    linfo(s)
end

function WARN(fmt, ...)
    local s = string.format(fmt, ...)
    lwarn(s)

    --local flag, info = pcall(string.format, fmt, ...)
    --if flag then
    --    lwarn(info)
    --else
    --    local co = coroutine.running()
    --    if co then gCoroBad[ co ] = 1 end
    --    --local s = debug.traceback()
    --    local s = debug.stack()
    --    lwarn(s)
    --    error(s)
    --end
end

function ERROR(fmt, ...)
    local s = string.format(fmt, ...)
    lwarn(s)
    local s = debug.traceback()
    lwarn(s)


    --local flag, info = pcall(string.format, fmt, ...)
    --if flag then
    --    lwarn(info)
    --else
    --    local s = debug.traceback()
    --    lwarn(s)
    --    error(s)
    --end
end


function MONITOR(fmt, ...)
    local s = string.format(fmt, ...)
    lmonitor(s)
end

function getSn(what)
    gSns[ what ] = (gSns[ what ] or 0) + 1
    return gSns[ what ]
end



function tabNum(t)
    local num = 0
    if t then
        for _, v in pairs(t) do
            num=num+1
        end
    end
    return num
end

function mkSpace(num)
    -- return "|" .. string.rep(" ", num)
    return string.rep(" ", num)
end

function toStr(x)
    if type(x) == "string" then
        return "\"" .. tostring(x) .. "\""
    else
        return tostring(x)
    end
end

--------------------------------------------------------------------------------
dump_mark = {}
function doDumpTab(t, step, max_cnt, dump_cnt, first)
    if type(t) ~= "table" then
        return LOG("%s: %s", type(t), tostring(t))
    end

    if first then
        dump_cnt = 0
        dump_mark = {}
        max_cnt = max_cnt or 20
    else
        if max_cnt and (dump_cnt + 1 > max_cnt) then
            return
        end
    end

    step = step or 4
    LOG("%s{", mkSpace(step*dump_cnt))
    for k, v in pairs(t) do
        if type(v) == "table" then
            if not dump_mark[v] then
                dump_mark[v] = true
                LOG("%s[%s] = %s", mkSpace(step*(dump_cnt+1)), toStr(k), tostring(v))
                doDumpTab(v, step, max_cnt, dump_cnt+1)
            else
                LOG("%s[%s] = %s -- already dumped.", mkSpace(step*(dump_cnt+1)), toStr(k), tostring(v))
            end
        else
            LOG("%s[%s] = %s", mkSpace(step*(dump_cnt+1)), toStr(k), toStr(v))
        end
    end
    LOG("%s}", mkSpace(step*dump_cnt))
    if first then dump_mark = {} end
end

-- max_cnt 打印层数
function dumpTab(t, what, max_cnt)
    if not config.Release then
        LOG("|@@ : %s", what or "Unknown")
        if type(t) ~= "table" then
            LOG("%s: %s", type(t), tostring(t))
        else
            doDumpTab(t, nil, max_cnt, 0, true)
        end
        LOG("|$$ : %s", what or "Unknown")
    end
end


function getField(tab, field, val)
    for k, v in pairs(tab) do
        if v[field] == val then return v, k end
    end
end


function doT2S(szRet, _i, _v)
    if "number" == type(_i) then
        --szRet = szRet .. "[" .. _i .. "]="
        if "number" == type(_v) then
            szRet = szRet .. _v .. ", "
        elseif "string" == type(_v) then
            szRet = szRet .. '\'' .. _v .. '\'' .. ", "
        elseif "table" == type(_v) then
            szRet = szRet .. sz_T2S(_v) .. ", "
        else
            szRet = szRet .. "nil,"
        end
    elseif "string" == type(_i) then
        szRet = szRet ..  _i .. '='
        if "number" == type(_v) then
            szRet = szRet .. _v .. ", "
        elseif "string" == type(_v) then
            szRet = szRet .. '\'' .. _v .. '\'' .. ", "
        elseif "table" == type(_v) then
            szRet = szRet .. sz_T2S(_v) .. ", "
        else
            szRet = szRet .. "nil, "
        end
    end
    return szRet
end

function sz_T2S(_t)
    local szRet = "{"
    for k, v in pairs(_t) do
        szRet = doT2S(szRet, k, v)
    end
    szRet = string.sub(szRet,1,-3) .. "}"
    return szRet
end

function tab_add(...)
    local t = {}
    for _, ts in pairs({...}) do
        for k, v in pairs(ts) do
            t[k]= (t[k] or 0) + v
        end
    end
    return t
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

setfenv = setfenv or function(f, t)
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

module = module or function(mname, what)
    _ENV[mname] = _ENV[mname] or {}
    if not getmetatable(_ENV[mname]) then setmetatable(_ENV[mname], {__index = _ENV}) end
    setfenv(2, _ENV[mname])
end

unpack = unpack or table.unpack
loadstring = loadstring or load

function basename(path)
    if type(path) ~= "string" then
        INFO("basename: %s not a string", path)
        return nil
    end

    return ((path):gsub(".*[\\/]", ""))
end

-- @stack@stack@[file:fun:line]
function debug.stack(level)
    level = level or 0
    level = level + 2
    local info = debug.getinfo(level)

    local result = ""

    local dep = 9
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

function debug.gettop()
    for i = 1, 1000, 1 do
        if not debug.getinfo(i) then return i end
    end
    return 1000
end


--------------------------------------------------------------------------------
-- Function : 时间戳转字符串
-- Argument : timestamp
-- Return   : NULL
-- Others   : timestamp 为空则取当前时间 gTime
--------------------------------------------------------------------------------
function tms2str(timestamp)
    return os.date("%Y-%m-%d %X", timestamp or gTime)
end

--------------------------------------------------------------------------------
-- Function : Tlog 日志
-- Argument : log_name, ...
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function Tlog(log_name, ...)
    if not config.TlogSwitch then
        return
    end

    local info = table.concat({log_name, config.APP_ID, config.SERVER_ID, config.PLAT_ID, tms2str(), gTime, ...}, '|')
    c_tlog(info)
end


function ltrim(s, r)
    r = r or "%s+"
    return (string.gsub(s, "^" .. r, ""))
end

function rtrim(s, r)
    r = r or "%s+"
    return (string.gsub(s, r .. "$", ""))
end

function trim(s, r)
    return rtrim(ltrim(s, r), r)
end

function print_r(sth)
    if type(sth) ~= "table" then
        if type(sth) == "boolean" then
            if sth then
                cprint("true")
            else
                cprint("true")
            end
        elseif type(sth) == "function" then
            cprint("function")
        else
            cprint(sth.."")
        end
        return
    end

    local space, deep = string.rep(' ', 2), 0
    local function _dump(t)
        local temp = {}

        for k,v in pairs(t) do
            local key = tostring(k)

            if type(v) == "table" then

                deep = deep + 2
                cprint(string.format( "%s[%s]=\n%s(", string.rep(space, deep - 1), key, string.rep(space, deep)))
                _dump(v)
                cprint(string.format("%s)",string.rep(space, deep)))
                deep = deep - 2

            else
                cprint(string.format("%s[%s]=%s", string.rep(space, deep + 1), key, v))
            end
        end
    end
    cprint("(")
    _dump(sth)
    cprint(")")
end

function cprint(s,color)--颜色答应
    color = color or "echo -e \"\\033[40;31;2m"
    local cool = color..s.." \\033[0m \""
    os.execute(cool)
end

function lxz(...)--打印lua变量数据到日志文件
    local info = debug.getinfo(2)
    local head = "["..(info.short_src or "FILE")..":"..(info.name or "")..":"..(info.currentline or 0).."]["..os.date("%Y-%m-%d %X").."]:"
    cprint(head,"echo -e \"\\033[40;34;2m")
    for _,v in pairs({...}) do
        print_r(v)
    end
end
