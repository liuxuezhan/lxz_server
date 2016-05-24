local skynet = require "skynet"
local json = require "json"
require "ply"

local server_id,id = ...
server_id = tonumber(server_id)--分区id
id = tonumber(id)--房间号id
local conf=_conf.server[server_id] 

function go_db(table,data)
    skynet.send(conf.db[1].name, "lua", table,json.encode(data))--不需要返回
end

function save(ret,data)
    go_db(table.unpack(data))

    if type(ret) == "table" then
        skynet.ret(skynet.pack(ret))
    else
        skynet.error(ret)
    end
end

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(conf.room[id].name) --注册服务名字便于其他服务调用
    ply.load(conf.db[1])--本线程加载
    -- If you want to fork a work thread , you MUST do it in CMD.login
    skynet.dispatch("lua", function(session, source, cmd,...)
            local ret = ply.dispath(...)--返回必须是一个表
            save( table.unpack(ret))--返回必须是一个表
    end)

end)
