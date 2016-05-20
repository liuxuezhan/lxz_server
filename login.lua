local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"
local crypt = require "crypt"
local table = table
local string = string
local assert = assert
local json = require "json"

local id = ...
id = tonumber(id)
local conf = _conf.login[id] 

local server_list = {}
local user_online = {}
local user_login = {}

--[[

Protocol:

	line (\n) based text protocol

	1. Server->Client : base64(8bytes random challenge)
	2. Client->Server : base64(8bytes handshake client key)
	3. Server: Gen a 8bytes handshake server key
	4. Server->Client : base64(DH-Exchange(server key))
	5. Server/Client secret := DH-Secret(client key/server key)
	6. Client->Server : base64(HMAC(challenge, secret))
	7. Client->Server : DES(secret, base64(token))
	8. Server : call auth_handler(token) -> server, uid (A user defined method)
	9. Server : call login_handler(server, uid, secret) ->subid (A user defined method)
	10. Server->Client : 200 base64(subid)

Error Code:
	400 Bad Request . challenge failed
	401 Unauthorized . unauthorized by auth_handler
	403 Forbidden . login_handler failed
	406 Not Acceptable . already in login (disallow multi login)

Success:
	200 base64(subid)
]]
local CMD = {}
function CMD.register_gate(server, address)--注册分区
	server_list[server] = address
end

function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		print(string.format("%s@%s is logout", uid, u.server))
		user_online[uid] = nil
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

local function client_auth(fd, addr)
    lxz(string.format("connect from %s (fd = %d)", addr, fd))
    socket.start(fd)	-- may raise error here

    socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket

    local key = crypt.randomkey()
    key = crypt.base64encode(key).."\n"
    key = "hero".."\n"
    write( fd, key)
    lxz(key)

    local handshake = read( fd)
    local clientkey = crypt.base64decode(handshake)
    if #clientkey ~= 8 then
        error "Invalid client key"
    end
    local serverkey = crypt.randomkey()
    write( fd, crypt.base64encode(crypt.dhexchange(serverkey)).."\n")

    local secret = crypt.dhsecret(clientkey, serverkey)

    local response = read( fd)
    local hmac = crypt.hmac64(challenge, secret)

    if hmac ~= crypt.base64decode(response) then
        write( fd, "400 Bad Request\n")
        error "challenge failed"
    end

    local etoken = read( fd)

    local token = crypt.desdecode(secret, crypt.base64decode(etoken))

    local ok, server, uid =  pcall(server_auth,token)
    socket.abandon(fd)	-- never raise error here

    return ok, server, uid, secret
end

local user_login = {}--玩家登陆状态

local function accept(fd, addr)

	local ok, server, uid, secret = client_auth(fd, addr)

	if not ok then
		if ok ~= nil then
			write( fd, "401 Unauthorized\n")
		end
		error(server)
	end

	if not conf.multilogin then
		if user_login[uid] then
			write( fd, "406 Not Acceptable\n")
			error(string.format("User %s is already login", uid))
		end

		user_login[uid] = true
	end

	local ok, err = pcall(server_login, server, uid, secret)
	-- unlock login
	user_login[uid] = nil

	if ok then
		err = err or ""
		write(fd,  "200 "..crypt.base64encode(err).."\n")
	else
		write(fd,  "403 Forbidden\n")
		error(err)
	end
end


local function server_auth(token)--第三方平台token校验
	-- the token is base64(user)@base64(server):base64(password)
	local user, server, password = token:match("([^@]+)@([^:]+):(.+)")
	user = crypt.base64decode(user)
	server = crypt.base64decode(server)
	password = crypt.base64decode(password)
	assert(password == "password", "Invalid password")
	return server, user
end

local function server_login(server, uid, secret)--通知分区验证通过
	print(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
		skynet.call(last.address, "lua", "kick", uid, last.subid)
	end
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end

	local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
	user_online[uid] = { address = gameserver, subid = subid , server = server}
	return subid
end


skynet.start (
function()

    skynet.register(conf.name)
    local host = conf.host or "0.0.0.0"
    local port = assert(tonumber(conf.port))
    local slave = {}

    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信
        skynet.ret(skynet.pack(command_handler(command, ...)))
    end)

    skynet.error(string.format("login server listen at : %s %d", host, port))

    local id = socket.listen(host, port)--客户端通信
    socket.start ( 
    id , 
    function(fd, addr)
        local ok, err = pcall(accept, fd, addr)
        if not ok then
            if err ~= socket_error then
                skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
            end
        end
        socket.close_fd(fd)	-- We haven't call socket.start, so use socket.close_fd rather than socket.close.
    end
    )
end
)

