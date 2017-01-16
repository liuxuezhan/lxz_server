-- This file will execute before every lua service start
-- See config

--基础库
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

function to_str(table,out,sp,e)--递归遍历表结构为字符串
   local l_e = e or ""
  if type(table) == "table" then
    out = out.."{"
    for k,v in pairs(table) do
      if type(k) == "string" then
           out = out..sp..k.."="
      elseif type(k) == "number" then
           out = out..sp.."["..k.."]="
      end
      if type(v) == "table" then
           out = to_str(v,out,sp..sp,",")
      elseif type(v) == "string" then
        out = out.."'"..v.."',"
      elseif type(v) == "number" then
        out = out ..v..","
      end
    end
    out = out ..sp.."}"..l_e..sp
 elseif type(table) == "string" then
    out = out..table
 elseif type(table) == "number" then
    out = out..table
  elseif type(table) == "nil" then
      out = out.."nil"
 end
 return out
end

function local_to_str(tab)--转换lua变量为字符串，便于用loadstring函数再转换为lua变量
    local str =""
    str = "local tmp="
    str = to_str(tab,str,"","")
    str = str.." return tmp"
    return str
end

function lxz(tab)--打印lua变量数据到日志文件
    local info = debug.getinfo(2)                                                                                                                              
    local str = "["..(info.short_src or "FILE")..":"..(info.name or "")..":"..(info.currentline or 0).."]"
    str = to_str(tab,str,"").."\n"
    str = "["..os.date().."]: "..str
    print(str)
end

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
