json = require "json"

_list={

    db_server1 ={ 
        db1={ host = "127.0.0.1", port = 27017, },
        -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
    },

    --登录服务器
    login_server1={ host = "127.0.0.1", port = 8001, multilogin = true, db_read="db_server1"  },


    --分区服务器
    game_server1={   host = "127.0.0.1", port = 8888, maxclient=3000, room ="room1", db_name = "db_server1" }, 

    warx = {   host = "10.0.2.15", port = 8888, maxclient=3000, room ="room1", db_name = "db_server1" }, 
}


--基础库
function copy(object)
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
    string.gsub(str, '[^' .. reps ..']+', function(w) table.insert(resultStrsList, w) end );
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


function print_r(sth)

    if type(sth) ~= "table" then
        cprint(sth.."")
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

function log(...)--日志
    local info = debug.getinfo(2)
    local d = "["..(info.short_src or "FILE")..":"..(info.currentline or 0).."]"..":"
    for _,v in pairs({...}) do
        d = d..json.encode(v).."@"
    end
    os.execute("logger -p local0.info "..d )
end

function lxz(...)--打印lua变量数据到日志文件
  local info = debug.getinfo(2)
  local head = "["..(info.short_src or "FILE")..":"..(info.name or "")..":"..(info.currentline or 0).."]"
  cprint(head,"echo -e \"\\033[40;34;2m")
    for _,v in pairs({...}) do
        print_r(v)
    end
end

function lxz1(...)--打印lua变量数据到日志文件
  local info = debug.getinfo(2)
  cprint(debug.traceback(),"echo -e \"\\033[40;34;2m")
  for _,v in pairs({...}) do
        print_r(v)
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

