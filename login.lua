local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local crypt = require "crypt"
local string = string
local assert = assert
local json = require "json"

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

local function accept(fd, addr)
    lxz(string.format("connect from %s (fd = %d)", addr, fd))

    socket.start(fd)	-- may raise error here
    socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket

    -- 发送基础key给客户端
    local base_key = crypt.randomkey()
    write( fd,crypt.base64encode(base_key).."\n")

    --接收客户端key
    local ret = read(fd)
    local clientkey = crypt.base64decode(ret)
    if #clientkey ~= 8 then
        error "Invalid client key"
    end

    --发送服务器key
    local serverkey = crypt.randomkey()
    write( fd, crypt.base64encode(crypt.dhexchange(serverkey)).."\n")

    --计算密匙
    local secret = crypt.dhsecret(clientkey, serverkey)
    local hmac = crypt.hmac64(base_key, secret)

    --接收客户端计算结果
    local ret = read(fd)
    ret = crypt.base64decode(ret) 

    if hmac ~= ret then
        write( fd, "400 Bad Request\n")
        error "challenge failed"
    end
    lxz("认证通过")

    local etoken = read(fd)
    local token = crypt.desdecode(secret, crypt.base64decode(etoken))

	local pid, server, pwd = token:match("([^@]+)@([^:]+):(.+)")
	pid = crypt.base64decode(pid)
	server = crypt.base64decode(server)
	pwd = crypt.base64decode(pwd)

    local p =_ply[pid]
	if p then
		if pwd == p.pwd then
	        local s = assert(server_list[server], "Unknown server")
            if p.server then
		        skynet.call(p.server, "lua", "kick", pid )
                p.server = server
            end
	        skynet.call(server, "lua", "login", pid, secret)
        else
			write( fd, "401 Unauthorized\n")
            return
		end
    else
        _ply[pid]={_id=pid,pwd=pwd }
        skynet.send(conf.db.name, "lua","ply" ,json.encode(_ply[pid]))--不需要返回
	end

	local s = assert(server_list[server], "Unknown server")
	local ret = json.encode({name=server,host=s.host,port=s.port})
	write(fd,  crypt.base64encode(ret).."\n")
    _ply[pid].server=server
    _ply[pid].addr=addr
    _ply[pid].tm=tm()

    socket.abandon(fd)	-- never raise error here
end




_ply = {}
function load(db_conf)
    local mongo = require "mongo"
	local db = mongo.client(db_conf)

    local info = db[db_conf.name].ply:find({})
    while info:hasNext() do
        local v = info:next()
        _ply[v._id]=v
    end
end

skynet.start (
function()
    skynet.register(conf.name)
    local host = conf.host or "0.0.0.0"
    local port = assert(tonumber(conf.port))
    local slave = {}
    load(conf.db)
    skynet.newservice("db_mongo",json.encode(conf.db))--数据库写中心

    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信
        skynet.ret(skynet.pack(command_handler(command, ...)))
    end)

    skynet.error(string.format("login server listen at : %s %d", host, port))

    local id = socket.listen(host, port)--客户端通信
    socket.start ( id , function(fd, addr)
        local ok, err = pcall(accept, fd, addr)
        if not ok then
            if err then
                skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
            end
        end
        socket.close_fd(fd)	-- We haven't call socket.start, so use socket.close_fd rather than socket.close.
    end
    )
end
)

