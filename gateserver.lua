package.path = package.path..";./?.lua"
local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local crypt = require "crypt"
local json = require "json"
require "ply"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local socket_id	-- listen socket
local maxclient	-- max client
local client_number = 0
local nodelay = false

local users = {}
local username_map = {}
local user_online = {}--玩家在线列表
local handshake = {}
local pwd_connection = {}

local id = ...
id = tonumber(id)--分区id
local conf =_conf.server[id] 
local server = {}

local function write( fd, text)
    local ok  = pcall(socket.write,fd, text)
    if not ok then
		skynet.error(string.format("socket(%d) write fail", fd))
		error(socket_error)
    end
end

local function read(fd)
    local ok ,ret = pcall(socket.readline,fd)
    if not ok then
		skynet.error(string.format("socket(%d) read fail", fd))
		error(socket_error)
    end
    return ret
end

function server.username(uid, servername)
	return string.format("%s_%s", b64encode(servername) ,b64encode(uid))
end


function closeclient(fd)
	local c = pwd_connection[fd]
	if c then
		pwd_connection[fd] = false
		socket.close(fd)
	end
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

function request(fd,name, msg)
    msg = skynet.call(conf.room[1].name, "lua", "client",fd,table.unpack(msg))
    return json.encode(msg)
end

function message(fd, msg)
    local ok, res = pcall(request, fd,0, msg )
    write(fd, json.encode(res))
end


function open_fd(fd)
    if client_number >= maxclient then
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

function CMD.login(pid, secret)
    if not users[pid] then
        local u = {
            pid = pid,
        }
        users[pid] = u
    end
    users[pid].secret = secret
end

-- call by agent
function CMD.logout(pid )
	local u = users[pid]
	if u then
		local username = server.username(pid, servername)
		assert(u.username == username)
	local u = user_online[u.username]
	user_online[u.username] = nil
	if u.fd then
		closeclient(u.fd)
		pwd_connection[u.fd] = nil
	end
		users[pid] = nil
		username_map[u.username] = nil
        lxz()
		skynet.call(loginservice, "lua", "logout",pid )
	end
end

function CMD.kick(pid )
	local u = users[pid]
	if u then
        users[pid].online = false
	end
end


local function accept(fd, addr)
    lxz(string.format("connect from %s (fd = %d)", addr, fd))

    open_fd(fd)	-- may raise error here
    socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket

    local d = json.decode(read(fd))
    lxz(d)
    message(fd, d)

end

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(conf.name) --注册服务名字便于其他服务调用
    maxclient = conf.maxclient or 1024
    nodelay = conf.nodelay
	skynet.call(_conf.login[1].name, "lua", "register_gate", conf.name, conf.host,conf.port)

    skynet.newservice("room",id,1)
    skynet.newservice("db_mongo",json.encode(conf.db[1]))--数据库写中心


    local address = conf.host or "0.0.0.0"
    local port = assert(conf.port)
    socket_id = socket.listen(address, port)
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
        skynet.ret(skynet.pack(f(address, ...)))
    end)
end)

