package.path = package.path..";./?.lua"
local skynet = require "skynet"
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

local _ply = {}

local id = ...
id = tonumber(id)--分区id
local conf =_conf.server[id] 
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


function dispatch_msg(fd, pid,msg)--分发消息，不返回
    local msg_id,msg = table.unpack(msg)
    lxz(msg)
    skynet.send(conf.room[1].name, "lua", fd,pid,msg_id,msg)
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

function CMD.login(pid, addr,secret)
    lxz(pid)
    if not _ply[pid] then
        local u = {
            pid = pid,
        }
        _ply[pid] = u
    end
    _ply[pid].addr = addr
    _ply[pid].secret = secret
end

-- call by agent
function CMD.logout(pid )
    close_fd(_ply[pid].fd)
    _ply[pid]=nil
    skynet.call(loginservice, "lua", "logout",pid )
end

function CMD.kick(pid )
    _ply[pid]=nil
end


local function accept(fd, addr)
    lxz(string.format("connect from %s (fd = %d)", addr, fd))

    open_fd(fd)	-- may raise error here
    --socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket

    local d = json.decode(copy(read(fd)))
    local pid = d[1] 
    if pid then
        if _ply[pid] then
            _ply[pid].fd = fd
            dispatch_msg(fd, pid,d[2])
        end
    end
end

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(conf.name) --注册服务名字便于其他服务调用
    maxclient = conf.maxclient or 1024
    nodelay = conf.nodelay
	skynet.call(_conf.login[1].name, "lua", "register_gate", conf.name, conf.host,conf.port)

    skynet.newservice("room",id,1)--模块服务器

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
        skynet.ret(skynet.pack(f( ...)))
    end)
end)

