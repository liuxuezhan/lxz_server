local json = require "json"
local msg = {}

msg.cs_login = {"name","pwd","sid","pid"} 
msg.sc_login = {"nid","pid","host","port"} 
msg.cs_msg = {"pid","id","msg"} 
msg.test1 = {"pid","id","msg",{name="table",v="cs_msg",k="pids" },} 
msg.test2 = {"pid","id","msg",{name="array_table",v="cs_msg",k="pids" },} 
msg.test2 = {"pid","id","msg",{name="array",k="pids" },} 

local function zip(tab,...) --压缩key
    local obj = {}
    local src = {...}
    for i=1,#tab do
        local key = tab[i]
        for j=1,#src do
            if type(src[j])=="table" then
                obj[i] = src[j][key]
            end
        end
    end
    return obj
end

local function zip2(tab,...) 
    local obj = {}
    local src = {...}
    for i=1,#tab do
        local key = tab[i]
        if type(key) == "table" then
            if key.name == "table" then--套单表项
                for j=1,#src do
                    if type(src[j])=="table" then
                        obj[i] = zip2(msg[key.v],src[j][key.k])
                    end
                end
            elseif key.name == "array_table" then--套多表项
                for j=1,#src do
                    if type(src[j])=="table" and type(src[j][key.k])=="table" then
                        obj[i] = {} 
                        for _,v in pairs(src[j][key.k]) do
                            table.insert(obj[i],zip2(msg[key.v],v))
                        end
                    end
                end
            elseif key.name == "array" then--套稀疏数组
                for j=1,#src do
                    if type(src[j])=="table" and type(src[j][key.k])=="table" then
                        obj[i] = {} 
                        for k,v in pairs(src[j][key.k]) do
                            table.insert(obj[i],{k,v})
                        end
                    end
                end
            end
        else
            for j=1,#src do
                if type(src[j])=="table" then
                    obj[i] = src[j][key]
                end
            end
        end
    end
    return obj
end


local function unzip(tab,src)
    local obj = {}
    for i = 1,#tab do
        local key = tab[i]
        if type(key) == "table" then
            local temp_tab = msg.get(key)
            local temp_key = key[1]
            if src[i] then
                obj[temp_key]  = unzip(temp_tab,src[i])
            end
        else
            obj[key] = src[i]
        end
    end
    return obj
end

function msg.pack(src,tab)
    if tab then
        src = msg.zip(tab,src)
    end
    src = json.encode(src)
    return src
end

function msg.unpack(src,tab)
    src = json.decode(src)
    if tab then
        src = msg.unzip(tab,src)
    end
    return src
end

function msg.arr(src) --压缩空洞数组
      local t = {}
      for k,v in pairs(src) do
          table.insert(t,{k,v})
      end
      return t
end
function msg.unarr(src) 
      local t = {}
      for _,v in pairs(src) do
          t[v[1]]=v[2] 
      end
      return t
end



function msg.get(tab)
    local temp = {}
    for i=2,#tab do
        temp[i - 1] = tab[i]
    end 
    return temp
end

function msg.zip(what,...) --压缩key
    return zip(msg[what],...)
end

function msg.unzip(what,src)
    return unzip(msg[what],src)
end
function msg.read(fun,fd)
    local ok ,ret = pcall(fun,fd)
    if not ok then
        lxz(ret)
        return
    end
    return ret
end

function msg.write(fun,fd,text)
    local ok  = pcall(fun,fd, text.."\n")
    if not ok then
        lxz(ret)
        return
    end
    return ok
end

function msg.cp(object)
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
    end  -- function _copy
    return _copy(object)
end  -- function deepcopy


return msg

