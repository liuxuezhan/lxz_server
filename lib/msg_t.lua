local json = require "json"
local msg = {}

msg.cs_open = {"tid","pwd","sid","pid"} --链接loginserver
msg.sc_open = {"tid","pid","host","port"} --链接loginserver

msg.cs_msg = {"pid","id","msg"} 

local function zip(src,tab) --压缩key
    local obj = {}
    for i=1,#tab do 
        local key = tab[i]  
        if type(key) == "table" then
            local temp_tab = msg.get(key)         
            obj[i] = zip(src[key[1]],temp_tab)
        else
            obj[i] = src[key]
        end
    end
    return obj
end

local function unzip(src,tab)
    local obj = {}
    for i = 1,#tab do
        local key = tab[i]
        if type(key) == "table" then
            local temp_tab = msg.get(key)
            local temp_key = key[1]
            if src[i] then
                obj[temp_key]  = unzip(src[i],temp_tab)
            end
        else
            obj[key] = src[i]
        end
    end
    return obj
end

function msg.pack(src,tab)
    if tab then
        src = msg.zip(src,tab)
    end
    src = json.encode(src)
    return src
end

function msg.unpack(src,tab)
    src = json.decode(src)
    if tab then
        src = msg.unzip(src,tab)
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

function msg.zip(src,what) --压缩key
    return zip(src,msg[what])
end

function msg.unzip(src,what)
    return unzip(src,msg[what])
end

return msg

