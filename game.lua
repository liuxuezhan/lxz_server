package.path = package.path..";./?.lua"
local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local cluster = require "cluster"
require "ply_t"
require "name_t"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local socket_id	-- listen socket
local client_number = 0


local server = {}

local function read(fd)
    local ok ,ret = pcall(socket.readline,fd)
    if not ok then
		skynet.error(string.format("socket(%d) read fail", fd))
    end
    return ret
end

function server.username(uid, servername)
	return string.format("%s_%s", b64encode(servername) ,b64encode(uid))
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
    lxz(msg)
    self={_id=msg.online.pid,tid=msg._id }
    ply_t.save(self)
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

    while 1 do
        local d = msg_t.unpack(copy(read(fd)))
        local name = d[1] 
        if name then
            if ply_t._d[name] then
                ply_t._d[name].fd = fd
                dispatch_msg(fd, name,d[2])
            end
        end
    end
end

local  function save_db()
    skynet.timeout(3*100, function() 
    lxz()
        if next(save_t.data) then
            skynet.send(g_game.db, "lua",g_game.db, msg_t.pack(save_t.data))--不需要返回
            save_t.clear()
        end
        save_db()
    end)
end

skynet.start(function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)
    require "debugger"
    skynet.newservice("db_mongo",g_game.db)--数据库写中心
    save_db()
	cluster.register(g_game.name, SERVERNAME)
	cluster.open "game1"

    require "skynet.manager"	-- import skynet.register
    do_load("resmng")--加载策划配置
    skynet.register(g_game.name) --注册服务名字便于其他服务调用

	local s = cluster.query("login1", g_login.name)
	cluster.call("login1",s, "register_gate", g_game.name, g_game.host,g_game.port)
    ply_t.load(g_db[g_game.db])

    skynet.newservice("room",g_game.room)--模块服务器

    lxz(g_game)
    socket_id = socket.listen(g_game.host, g_game.port)
    socket.start ( socket_id , function(fd, addr)
        open_fd(fd)	-- may raise error here
        lxz(string.format("connect from %s (fd = %d)", addr, fd))
        local ok, err = pcall(accept, fd, addr)
        if not ok then
            if err then
                lxz(err)
            end
        end
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

