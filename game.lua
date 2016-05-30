package.path = package.path..";./?.lua"
local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local cluster = require "cluster"
local json = require "json"
require "ply"
local save = require "save"	
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local socket_id	-- listen socket
local client_number = 0


local server_name = "game_server1" 
local conf =_list[server_name] 
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
    skynet.send(conf.room, "lua", fd,name,msg_id,msg)
end


function open_fd(fd)
    if client_number >= conf.maxclient then
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

function CMD.login(data)
    lxz()
    data = json.decode(data) 
    ply._d[data.name]=data
    save.data.ply[data._id]=data
end

-- call by agent
function CMD.logout(name )
    close_fd(ply._d[name].fd)
    ply._d[name].online=0
    skynet.call(loginservice, "lua", "logout",name )
end

function CMD.kick(name )
    ply._d[name].online=0
end


local function accept(fd, addr)
    lxz(string.format("connect from %s (fd = %d)", addr, fd))

    open_fd(fd)	-- may raise error here
    --socket.limit(fd, 8192) -- set socket buffer limit (8K),Ifthe attacker send large package, close the socket

    local d = json.decode(copy(read(fd)))
    local name = d[1] 
    if name then
        if ply._d[name] then
            ply._d[name].fd = fd
            dispatch_msg(fd, name,d[2])
        end
    end
end

local  function save_db()
    skynet.timeout(3*100, function() 
        if next(save.data) then
            skynet.send(conf.db_name, "lua","db1", json.encode(save.data))--不需要返回
            save.clear()
        end
        save_db()
    end)
end
save_db()

skynet.start(function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)
    skynet.newservice("db_mongo",conf.db_name)--数据库写中心

	cluster.register("game1_1", SERVERNAME)
	cluster.open "game1"

    require "skynet.manager"	-- import skynet.register
    skynet.register(server_name) --注册服务名字便于其他服务调用

	local s = cluster.query("login1", "login1_1")
	cluster.call("login1",s, "register_gate", server_name, conf.host,conf.port)
    ply.load(_list[conf.db_name])

    skynet.newservice("room",conf.room)--模块服务器

    socket_id = socket.listen(conf.host, conf.port)
    socket.start ( socket_id , function(fd, addr)
        local ok, err = pcall(accept, fd, addr)
        if not ok then
            if err then
                skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
            end
            close_fd(fd)
        end
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

