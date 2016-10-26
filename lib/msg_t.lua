local json = require "json"
local socket = require "socket"
local msg = {}

msg.cs_login = {"name","pwd","sid","pid"} 
msg.sc_login = {"nid","pid","host","port"} 

msg.cs_msg = {"pid","id","msg"} 

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

local function zips(tab,src) --表中表
    local obj = {}
    for i=1,#tab do
        local key = tab[i]
        if type(key) == "table" then
            local temp_tab = msg.get(key)
            obj[i] = zip(temp_tab,src[key[1]])
        else
            obj[i] = src[key]
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

function msg.read(fd)
    local ok ,ret = pcall(socket.readline,fd)
    if not ok then
        lxz(ret)
        return
    end
    return ret
end

function msg.write(fd,msg)
    local ok  = pcall(socket.write,fd, msg.."\n")
    if not ok then
        lxz(ret)
        return
    end
    return ok
end


return msg

