local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local crypt = require "crypt"
local string = string
local assert = assert
local json = require "json"
require "save"	
require "ply"	

local id = ...
id = tonumber(id)
local conf = _conf.login[id] 

local server_list = {}
local user_login = {}--玩家登陆状态

local function tm()
    local _tm = os.time()
    return _tm
end
local CMD = {}

function CMD.register_gate(server, host,port)--注册分区
	server_list[server] = {host=host,port=port} 
end

function CMD.logout(pid)
	local u = user_login[pid]
	if u then
		print(string.format("%s@%s is logout", pid, u.server))
		user_login[pid] = nil
	end
end

local function command_handler(command, ...)
	local f = assert(CMD[command])
	return f(...)
end

local socket_error = {}

local function write( fd, text)
    lxz(text)
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

local  function save_db()
    skynet.timeout(3*100, function() 
        if next(save.data) then
            lxz(save.data)
            skynet.send("db_login", "lua","db1",json.encode(save.data))--不需要返回
            save.clear()
        end
        save_db()
    end)
end
save_db()

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
	        local s = assert(server_list[server], "Unknown server")
            if p.server then
		        skynet.call(p.server, "lua", "kick", p._id )
                p.server = server
            end
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
    ply._d[name].tm = tm()

	skynet.call(server, "lua", "login", p._id, addr,secret)
    socket.abandon(fd)	-- never raise error here
end


skynet.start (
function()
    skynet.register(conf.name)
    ply.load(_conf.db.db_login)

    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信
        skynet.ret(skynet.pack(command_handler(command, ...)))
    end)

    skynet.error(string.format("login server listen at : %s %d", conf.host, conf.port))
    local id = socket.listen(conf.host, conf.port)--客户端通信
    socket.start ( id , function(fd, addr)
        lxz()
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

