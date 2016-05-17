package.path = package.path..";./?.lua"
local skynet = require "skynet"
local gateserver = require "gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local socketdriver = require "socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

--[[
Protocol:
	All the number type is big-endian
	Shakehands (The first package)

	Client -> Server :
	base64(uid)@base64(server)#base64(subid):index:base64(hmac)

	Server -> Client
	XXX ErrorCode
		404 User Not Found
		403 Index Expired
		401 Unauthorized
		400 Bad Request
		200 OK
	Req-Resp

	Client -> Server : Request
		word size (Not include self)
		string content (size-4)
		dword session

	Server -> Client : Response
		word size (Not include self)
		string content (size-5)
		byte ok (1 is ok, 0 is error)
		dword session

API:
	server.userid(username)
		return uid, subid, server

	server.username(uid, subid, server)
		return username

	server.login(username, secret)
		update user secret

	server.logout(username)
		user logout

	server.ip(username)
		return ip when connection establish, or nil

	server.start(conf)
		start server

Supported skynet command:
	kick username (may used by loginserver)
	login username secret  (used by loginserver)
	logout username (used by agent)

Config for server.start:
	expired_number : the number of the response message cached after sending out (default is 128)
	login(uid, secret) -> subid : the function when a new user login, alloc a subid for it. (may call by login server)
	logout(uid, subid) : the functon when a user logout. (may call by agent)
	kick(uid, subid) : the functon when a user logout. (may call by login server)
	request(username, session, msg) : the function when recv a new request.
	register(servername) : call when gate open
	disconnect(username) : call when a connection disconnect (afk)
]]

local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local user_online = {}--玩家在线列表
local handshake = {}
local connection = {}

function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		response = {},	-- response cache
	}
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end

local internal_id = 0
local users = {}
local username_map = {}
local json = require "json"
local loginservicea     --登录服务
local room= {all=0,}          --集体服务 
function login(uid, secret)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
	local username = server.username(uid, id, servername)

	local u = {
		username = username,
		uid = uid,
		subid = id,
	}

	-- trash subid (no used)
	skynet.call(agent, "lua", "login", uid, id, secret)
	users[uid] = u
	username_map[username] = u
	server.login(username, secret)
	-- you should return unique subid
	return id
end

-- call by agent
function logout(uid, subid)
	local u = users[uid]
	if u then
		local username = server.username(uid, subid, servername)
		assert(u.username == username)
		server.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

-- call by login server
function kick(uid, subid)
	local u = users[uid]
	if u then
		local username = server.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end
    --[[
	local function request(fd, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, err = pcall(do_request, fd, message)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, message))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end
    -]]
function request(fd,name, msg)
    msg = json.decode(msg)
    msg = skynet.call("room.all", "lua", "client",fd,table.unpack(msg))
    return json.encode(msg)
    --return skynet.tostring(skynet.rawcall("room.all", "client",msg))
end

function register(name)
    servername = name
    loginservice = skynet.newservice("logind")--加密登录
    room.all = skynet.newservice("room","room.all")
    skynet.call("room.all", "lua", "start")
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self())
end

function disconnect(username)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

function server.start()
	local expired_number = expired_number or 128
	local handler = {}

	local CMD = {
		login = assert(login),
		logout = assert(logout),
		kick = assert(kick),
	}

	function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end

	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return register(servername)
	end

	function handler.connect(fd, addr)
		handshake[fd] = addr
		gateserver.openclient(fd)
	end

	function handler.disconnect(fd)
		handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if disconnect then
				disconnect(c.username)
			end
		end
	end

	handler.error = handler.disconnect

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		local username, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
		local u = user_online[username]
		if u == nil then
			return "404 User Not Found"
		end
		local idx = assert(tonumber(index))
		hmac = b64decode(hmac)

		if idx <= u.version then
			return "403 Index Expired"
		end

		local text = string.format("%s:%s", username, index)
		local v = crypt.hmac_hash(u.secret, text)	-- equivalent to crypt.hmac64(crypt.hashkey(text), u.secret)
		if v ~= hmac then
			return "401 Unauthorized"
		end

		u.version = idx
		u.fd = fd
		u.ip = addr
		connection[fd] = u
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400 Bad Request"
		end

		local close = result ~= nil

		if result == nil then
			result = "200 OK"
		end

		socketdriver.send(fd, netpack.pack(result))

		if close then
			gateserver.closeclient(fd)
		end
	end

	local request_handler = assert(request)

	-- u.response is a struct { return_fd , response, version, index }
	local function retire_response(u)
		if u.index >= expired_number * 2 then
			local max = 0
			local response = u.response
			for k,p in pairs(response) do
				if p[1] == nil then
					-- request complete, check expired
					if p[4] < expired_number then
						response[k] = nil
					else
						p[4] = p[4] - expired_number
						if p[4] > max then
							max = p[4]
						end
					end
				end
			end
			u.index = max + 1
		end
	end

	local function do_request(fd, message)
		local u = assert(connection[fd], "invalid fd")
		local session = string.unpack(">I4", message, -4)
		message = message:sub(1,-5)
		local p = u.response[session]
		if p then
			-- session can be reuse in the same connection
			if p[3] == u.version then
				local last = u.response[session]
				u.response[session] = nil
				p = nil
				if last[2] == nil then
					local error_msg = string.format("Conflict session %s", crypt.hexencode(session))
					skynet.error(error_msg)
					error(error_msg)
				end
			end
		end

		if p == nil then
			p = { fd }
			u.response[session] = p
			local ok, result = pcall(request, fd,u.username, message)
			-- NOTICE: YIELD here, socket may close.
			result = result or ""
			if not ok then
				skynet.error(result)
				result = string.pack(">BI4", 0, session)
			else
				result = result .. string.pack(">BI4", 1, session)
			end

			p[2] = string.pack(">s2",result)
			p[3] = u.version
			p[4] = u.index
		else
			-- update version/index, change return fd.
			-- resend response.
			p[1] = fd
			p[3] = u.version
			p[4] = u.index
			if p[2] == nil then
				-- already request, but response is not ready
				return
			end
		end
		u.index = u.index + 1
		-- the return fd is p[1] (fd may change by multi request) check connect
		fd = p[1]
		if connection[fd] then
			socketdriver.send(fd, p[2])
		end
		p[1] = nil
		retire_response(u)
	end


	function handler.message(fd, msg, sz)
        local m = netpack.tostring(msg,sz)
		lxz(fd, m)
		local ok, res = pcall(request, fd,0, m )
		socketdriver.send(fd, netpack.pack(res))
        --socket.write(fd, res)
        --[[
		local addr = handshake[fd]
		if addr then
			auth(fd,addr,msg,sz)
			handshake[fd] = nil
		else
			request(fd, msg, sz)
		end
        --]]
	end

	return gateserver.start(handler)
end

server.start()
