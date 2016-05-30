local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local crypt = require "crypt"
local cluster = require "cluster"
local string = string
local assert = assert
local json = require "json"
require "ply"	

--local server_name = ...
local server_name = "login_server1"
local conf = _list.login[server_name] 

local server_list = {}

local function tm()
    local _tm = os.time()
    return _tm
end
local CMD = {}

function CMD.register_gate(server, host,port)--注册分区
    lxz(server,host,port)
	server_list[server] = {host=host,port=port} 
end

function CMD.logout(name)
    u = ply._d[name]
	if u then
		print(string.format("%s is logout",name))
        ply._d[name].online=0
	end
end

local function command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

local socket_error = {}

local function write( fd, text)
    local ok  = pcall(socket.write,fd, text.."\n")
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

local function accept(fd, addr)
    lxz(string.format("connect from %s (fd = %d)", addr, fd))

    socket.start(fd)	-- may raise error here
    socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket

    -- 发送基础key给客户端
    local base_key = crypt.randomkey()
    write( fd,crypt.base64encode(base_key))

    --接收客户端key
    local ret = read(fd)
    local clientkey = crypt.base64decode(ret)
    if #clientkey ~= 8 then
        error "Invalid client key"
    end

    --发送服务器key
    local serverkey = crypt.randomkey()
    write( fd, crypt.base64encode(crypt.dhexchange(serverkey)))

    --计算密匙
    local secret = crypt.dhsecret(clientkey, serverkey)
    local hmac = crypt.hmac64(base_key, secret)

    --接收客户端计算结果
    local ret = read(fd)
    ret = crypt.base64decode(ret) 

    if hmac ~= ret then
        write( fd, "400 Bad Request")
        error "challenge failed"
    end
    lxz("认证通过")

    local etoken = read(fd)
    local token = crypt.desdecode(secret, crypt.base64decode(etoken))

	local name, server, pwd = token:match("([^@]+)@([^:]+):(.+)")
	name = crypt.base64decode(name)
	server = crypt.base64decode(server)
	pwd = crypt.base64decode(pwd)

    local p =ply._d[name]
	if p then
		if pwd == p.pwd then
            lxz()
	        local s = assert(server_list[server], "Unknown server")
            lxz()
            if p.server then
	            local s = cluster.query("game1", "game1_1")
	            cluster.call("game1",s, "kick", p.name)
                p.server = server
            end
            lxz()
        else
			write( fd, "401 Unauthorized")
            return
		end
    else
        p = ply.new(server,name,pwd) 
	end

	local s = assert(server_list[server], "Unknown server")
	local ret = json.encode({name=server,host=s.host,port=s.port})
	write(fd,  crypt.base64encode(ret))
    ply._d[name].server = server
    ply._d[name].addr = addr
    ply._d[name].online = 1
    ply._d[name].tm = tm()

    lxz()
	local s = cluster.query("game1", "game1_1")
	cluster.call("game1",s, "login", json.encode(p))
	--skynet.send(server, "lua", "login", json.encode(p))
    socket.abandon(fd)	-- never raise error here
end


skynet.start (
function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)
	cluster.register("login1_1", SERVERNAME)
	cluster.open "login1"
    skynet.register(server_name)
    ply.load(_list[conf.db_name])

    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信,包括集群
        skynet.ret(skynet.pack(command_handler(command, ...)))
    end)

    skynet.error(string.format("login server listen at : %s %d", conf.host, conf.port))
    local s = socket.listen(conf.host, conf.port)--客户端通信
    socket.start ( s , function(fd, addr)
        local ok, err = pcall(accept, fd, addr)
        if not ok then
            if err then
                skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
            end
        end
        socket.close_fd(fd)	-- We haven't call socket.start, so use socket.close_fd rather than socket.close.
    end)
end
)

