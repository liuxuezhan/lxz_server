
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


function LOG(fmt, ...)
    local s = string.format(fmt, ...)
    if SHOW_DEBUG_INFO then
        local info = debug.getinfo(2)
        local extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
        llog(string.format("%s%s", extra_info, s))
    else
        llog(s)
    end

    --local flag, info = pcall(string.format, fmt, ...)
    --if flag then
    --    local extra_info = ""
    --    if SHOW_DEBUG_INFO then
    --        local info = debug.getinfo(2)
    --        extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
    --    end

    --    llog(extra_info .. info)
    --else
    --    local co = coroutine.running()
    --    if co then gCoroBad[ co ] = 1 end

    --    llog(info)
    --    local s = debug.traceback()
    --    llog(s)
    --end
end

function INFO(fmt, ...)
    local s = string.format(fmt, ...)
    if SHOW_DEBUG_INFO then
        local info = debug.getinfo(2)
        local extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
        linfo(string.format("%s%s", extra_info, s))
    else
        linfo(s)
    end


    --local flag, info = pcall(string.format, fmt, ...)
    --if flag then
    --    local extra_info = ""
    --    if SHOW_DEBUG_INFO then
    --        local info = debug.getinfo(2)
    --        extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
    --    end

    --    linfo(extra_info .. info)
    --else
    --    local co = coroutine.running()
    --    if co then gCoroBad[ co ] = 1 end

    --    linfo(info)
    --    local s = debug.traceback()
    --    linfo(s)
    --end
end

function WARN(fmt, ...)
    local s = string.format(fmt, ...).. " ".. debug.stack(1)
    if SHOW_DEBUG_INFO then
        local info = debug.getinfo(2)
        local extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
        lwarn(string.format("%s%s", extra_info, s))
    else
        lwarn(s)
    end

    --local flag, info = pcall(string.format, fmt, ...)
    --if flag then
    --    local extra_info = ""
    --    if SHOW_DEBUG_INFO then
    --        local info = debug.getinfo(2)
    --        extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
    --    end

    --    lwarn(extra_info .. info)
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
    local s = string.format(fmt, ...).. " ".. debug.stack(1)
    if SHOW_DEBUG_INFO then
        local info = debug.getinfo(2)
        local extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
        lwarn(string.format("%s%s", extra_info, s))
    else
        lwarn(s)
    end

    --local flag, info = pcall(string.format, fmt, ...)
    --if flag then
    --    local extra_info = ""
    --    if SHOW_DEBUG_INFO then
    --        local info = debug.getinfo(2)
    --        extra_info = "["..(info.short_src or "FILE").."]["..(info.name or "").."]["..(info.currentline or 0).."]"
    --    end

    --    lwarn(extra_info .. info)
    --else
    --    local s = debug.traceback()
    --    lwarn(s)
    --    error(s)
    --end
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
function doDumpTab(t, step, max_cnt, dump_cnt, not_first)
    if not not_first then
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
    if type(t) == "table" then
        for k, v in pairs(t) do
            if type(v) == "table" then
                if not dump_mark[v] then
                    dump_mark[v] = true
                    LOG("%s[%s] = %s", mkSpace(step*(dump_cnt+1)), toStr(k), tostring(v))
                    doDumpTab(v, step, max_cnt, dump_cnt + 1, true)
                else
                    LOG("%s[%s] = %s -- already dumped.", mkSpace(step*(dump_cnt+1)), toStr(k), tostring(v))
                end
            else
                LOG("%s[%s] = %s", mkSpace(step*(dump_cnt+1)), toStr(k), toStr(v))
            end
        end
    else
        LOG("%s[%s] = %s", mkSpace(step*dump_cnt), toStr(k), toStr(v))
    end
    LOG("%s}", mkSpace(step*dump_cnt))
end

-- max_cnt 打印层数
function dumpTab(t, what, max_cnt)
    LOG("|@@ : %s", what or "Unknown")
    if type(t) ~= "table" then
        LOG("%s: %s", type(t), tostring(t))
        --LOG("not table, but %s", type(t))
    else
        doDumpTab(t, nil, max_cnt)
    end
    LOG("|$$ : %s", what or "Unknown")
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

module = module or function(mname)
    _ENV[mname] = _ENV[mname] or {}
    setmetatable(_ENV[mname], {__index = _ENV})
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


