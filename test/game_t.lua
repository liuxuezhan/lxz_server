skynet = require "skynet"
local socket = require "socket"
local cluster = require "cluster"
local ply_t = require "ply_t"
local assert = assert

local socket_id	-- listen socket
local client_number = 0

local function write( fd, text)
    msg_t.write(socket.write,fd,text)
end

local function read(fd)
    return msg_t.read(socket.readline,fd)
end



function dispatch_msg(fd, name,msg)--分发消息，不返回
    local msg_id,msg = table.unpack(msg)
    skynet.send(g_game.room, "lua", fd,name,msg_id,msg)
end


function open_fd(fd)
    if client_number >= g_game.maxclient then
        return
    end
    client_number = client_number + 1
    socket.start(fd)
end

function close_fd(fd)
    client_number = client_number - 1
    socket.close(fd)
end

local CMD = {} 
function CMD.close()
    assert(socket_id)
    socket.close(socket_id)
end

function CMD.login(msg)
    msg = msg_t.unpack(msg) 
    ply_t.cs_login(msg)
end

-- call by agent
function CMD.logout(name )
    close_fd(ply_t._d[name].fd)
    ply_t._d[name].online=0
    skynet.call(loginservice, "lua", "logout",name )
end

function CMD.kick(name )
    ply_t._d[name].online=0
end


local function accept(fd, addr)
    --socket.limit(fd, 8192) -- set socket buffer limit (8K),Ifthe attacker send large package, close the socket

    while true do
        lxz()
        local msg = msg_t.unpack(read(fd))
        msg = msg_t.unzip("cs_msg",msg)
        ply_t.cs_msg(fd, msg.pid,msg.id,msg.msg)
    end
end

callback =  function(one)
    if next(base.save) then
        lxz(g_login.db,base.save)
        skynet.send(g_game.db, "lua",g_game.db, msg_t.pack(base.save))--不需要返回
        base.clear_save()
    end
    one.data.start = g_tm
    one.data.start = g_tm + one.data.sec
    one.data.tag = one.tag or 0 + 1
    skynet.timeout(one.data.sec*100, function() callback(one) end)
end

skynet.start(function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)
    skynet.newservice("lualib/mongo_t",g_game.db)--数据库写中心
    timer.set_call("save_db2",callback)
    local one = timer.new("save_db2",10)

	cluster.register(g_game.name, SERVERNAME)
	cluster.open(g_game.name)

    require "skynet.manager"	-- import skynet.register
    --do_load("resmng")--加载策划配置
    skynet.register(g_game.name) --注册服务名字便于其他服务调用

	local s = cluster.query(g_login.name, g_login.name)
	cluster.call(g_login.name,s, "register_gate", g_game.name, g_game.host or g_host, g_game.port)


    require "debugger"
    g_db[g_game.db].host = g_db[g_game.db].host or g_host 
    ply_t.load(g_db[g_game.db])

   -- skynet.newservice("room_t",g_game.room)--模块服务器

    lxz(g_game)
    socket_id = socket.listen(g_game.host or g_host, g_game.port)
    socket.start ( socket_id , function(fd, addr)
        open_fd(fd)	-- may raise error here
        lxz(string.format("connect from %s (fd = %d)", addr, fd))
        local ok, err = pcall(accept, fd, addr)
        if not ok then if err then lxz(err) end end
        close_fd(fd)
    end
    )
    skynet.dispatch("lua", function (_, addr, cmd, ...)
        local f = assert(CMD[cmd])
        local ret =  f( ...)
        if cmd == "login" then
        else
            skynet.ret(skynet.pack(ret))
        end
    end)
end)

