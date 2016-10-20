local skynet = require "skynet"
local socket = require "socket"

local server_name = ...

local _online={}--玩家在线列表

require "ply_t"	

local function write( fd, text)
    local ok  = pcall(socket.write,fd, json.encode(text).."\n")
    if not ok then
		skynet.error(string.format("socket(%d) write fail", fd))
    end
end

local  function save_db()
    skynet.timeout(3*100, function() 
        if next(save_t.data) then
            lxz(save_t.data)
            skynet.send(_conf.db1, "lua", json.encode(save_t.data))--不需要返回
            save_t.clear()
        end
        save_db()
    end)
end
save_db()

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(server_name) --注册服务名字便于其他服务调用
    --ply_t.load({conf.db[1]})

    skynet.dispatch("lua", function(session, source, fd,pid,msg_id,...)
            _online[pid]=fd
            --[[
            local ret = ply_t.dispath(pid,msg_id,...)
            if ret ~=0 then
                for pid, d in pairs(ret) do
                    write(_online[pid],d)
                end
            end
            --]]

    end)

end)
