local json = require "json"
local msg = {}

--ex = {"key","num"}

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

function msg.zip(src,tab) --压缩key
    local des = {}
    for i=1,#tab do 
        local key = tab[i]  
        if type(key) == "table" then
            local temp_tab = msg.get(key)         
            des_tab[i] = msg.pack(src[key[1]],temp_tab)
        else
            des_tab[i] = src[key]
        end
    end
    return des
end

function msg.unzip(src,tab)
    local des = {}
    for i = 1,#tab do
        local key = tab[i]
        if type(key) == "table" then
            local temp_tab = msg.get(key)
            local temp_key = key[1]
            if src[i] then
                des[temp_key]  = msg.unpack(src[i],temp_tab)
            end
        else
            des[key] = src[i]
        end
    end
    return des
end

function msg.get(tab)
    local temp = {}
    for i=2,#tab do
        temp[i - 1] = tab[i]
    end 
    return temp
end


return msg

