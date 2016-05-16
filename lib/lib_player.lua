
--[ 打印参数
for i = 1, select('#', ...) do
     print(select(i, ...))
end
--]]

local name = ...

local mod = {}    -- 局部的变量
_G[name] = mod     -- 将这个局部变量最终赋值给模块名
--local rawget = rawget
--local print = print

package.loaded[name] = mod

function mod.db_save(...)--保存数据
end

function mod.cs_new(...)--创建玩家
    local t = { _pro={...},_save = {...}, }
    local mt = {
        __index = function(t, k)--访问不存在的成员时调用
            return t._pro[k]
        end,
        __newindex = function(t, k, v)--给不存在的成员赋值时调用
       -- lxz(k)
            t._pro[k]= v
            t._save[k]= v
        end
    }
    mod.sc_new(...)
    return setmetatable(t, mt)
end

function mod.sc_new(...)
end

function mod.save(...)
     --t._save 
end

