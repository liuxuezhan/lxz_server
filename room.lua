local skynet = require "skynet"
local socket = require "socket"

local server_name = ...

local _online={}--玩家在线列表

local save = require "save"	
require "ply"	

local function write( fd, text)
    local ok  = pcall(socket.write,fd, json.encode(text).."\n")
    if not ok then
		skynet.error(string.format("socket(%d) write fail", fd))
    end
end

local  function save_db()
    skynet.timeout(3*100, function() 
        if next(save.data) then
            lxz(save.data)
            skynet.send(_conf.db1, "lua", json.encode(save.data))--不需要返回
            save.clear()
        end
        save_db()
    end)
end
save_db()

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(server_name) --注册服务名字便于其他服务调用
    --ply.load({conf.db[1]})

    skynet.dispatch("lua", function(session, source, fd,pid,msg_id,...)
            _online[pid]=fd
            --[[
            local ret = ply.dispath(pid,msg_id,...)
            if ret ~=0 then
                for pid, d in pairs(ret) do
                    write(_online[pid],d)
                end
            end
            --]]

    end)

end)
