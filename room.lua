local skynet = require "skynet"
local json = require "json"
require "ply"

local my_name,other = ...
local db={
    all={
        host="127.0.0.1",
        port=27017,
       -- username="admin",
       -- password="admin",
    }
}
function load()
    ply.load("all",db.all)--本线程加载
    skynet.newservice("db_mongo","all",json.encode(db.all))--数据库写中心
end

function go_db(table,data)
    skynet.send("all", "lua", table,json.encode(data))--不需要返回
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
    skynet.register(my_name) --注册服务名字便于其他服务调用
    -- If you want to fork a work thread , you MUST do it in CMD.login
    skynet.dispatch("lua", function(session, source, cmd,...)
        if cmd == "start" then
            load()
        else
            local ret = ply.dispath(...)--返回必须是一个表
            save( table.unpack(ret))--返回必须是一个表
        end

    end)

end)
