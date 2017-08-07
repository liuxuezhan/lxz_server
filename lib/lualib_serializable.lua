local json = require "cjson"
json.safe = require "cjson.safe"
json.encode_sparse_array(true,1,0)  
local msg = {}

msg.cs_login = {"name","pwd","sid","pid"} 
msg.sc_login = {"nid","pid","host","port"} 
msg.cs_msg = {"pid","id","msg"} 
msg.test1 = {"pid","id","msg",{class="table",v="cs_msg",k="pids" },} 
msg.test2 = {"pid","id","msg",{class="array_table",v="cs_msg",k="pids" },} 
msg.test3 = {"pid","id","msg",{class="array_sparse",k="pids" },} 
msg.test4 = {"pid","id","msg",{class="array",k="pids" },} 


local function zip(tab,...) 
    local obj = {}
    local src = {...}
    for i=1,#tab do
        local key = tab[i]
        if type(key) == "table" then
            if key.class == "table" then--套单表项
                for j=1,#src do
                    if type(src[j])=="table" then
                        obj[i] = zip(msg[key.v],src[j][key.k])
                    end
                end
            elseif key.class == "array" then--套数组
                for j=1,#src do
                    if type(src[j])=="table" then
                        obj[i] = src[j][key]
                    end
                end
            elseif key.class == "array_table" then--套多表项
                for j=1,#src do
                    if type(src[j])=="table" and type(src[j][key.k])=="table" then
                        obj[i] = {} 
                        for _,v in pairs(src[j][key.k]) do
                            table.insert(obj[i],zip(msg[key.v],v))
                        end
                    end
                end
            elseif key.class == "array_sparse" then--套稀疏数组
                for j=1,#src do
                    if type(src[j])=="table" then
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
            if key.class == "table" then--套单表项
                obj[key.k] = unzip(msg[key.v],src[i])
            elseif key.class == "array" then--套数组
                obj[key.k] = src[i]
            elseif key.class == "array_table" then--套多表项
                obj[key.k] = {} 
                table.insert(obj[key.k],unzip(msg[key.v],src[i]))
            elseif key.class == "array_sparse" then--套稀疏数组
                obj[key.k] = {} 
                for _,v in pairs(src[i]) do
                    obj[key.k][v[1]] = v[2] 
                end
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
    if not json.safe.decode(src) then  return end
    src = json.decode(src)
    if tab then src = msg.unzip(tab,src) end
    return src
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

