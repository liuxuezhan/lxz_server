package.path = package.path..";./?.lua"
local skynet = require "skynet"
local netpack = require "netpack"
local socketdriver = require "socketdriver"
local crypt = require "crypt"
local json = require "json"
require "ply"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local socket	-- listen socket
local queue		-- message queue
local maxclient	-- max client
local client_number = 0
local nodelay = false

local internal_id = 0
local users = {}
local username_map = {}
local user_online = {}--玩家在线列表
local handshake = {}
local pwd_connection = {}

local conf = json.decode(...)
local server = {}
function server.userid(username)
	-- base64(uid)@base64(server)#base64(subid)
	local uid, servername, subid = username:match "([^@]*)@([^#]*)#(.*)"
	return b64decode(uid), b64decode(subid), b64decode(servername)
end

function server.ip(username)
	local u = user_online[username]
	if u and u.fd then
		return u.ip
	end
end


function closeclient(fd)
	local c = pwd_connection[fd]
	if c then
		pwd_connection[fd] = false
		socketdriver.close(fd)
	end
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
        closeclient(fd)
    end
end

local expired_number = expired_number or 128
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
    local u = assert(pwd_connection[fd], "invalid fd")
    local session = string.unpack(">I4", message, -4)
    message = message:sub(1,-5)
    local p = u.response[session]
    if p then
        -- session can be reuse in the same 
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
    if pwd_connection[fd] then
        socketdriver.send(fd, p[2])
    end
    p[1] = nil
    retire_response(u)
end
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
    pwd_connection[fd] = u
end



skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local function old_request(fd, msg, sz)
    local message = netpack.tostring(msg, sz)
    local ok, err = pcall(do_request, fd, message)
    -- not atomic, may yield
    if not ok then
        skynet.error(string.format("Invalid package %s : %s", err, message))
        if pwd_connection[fd] then
            closeclient(fd)
        end
    end
end

function request(fd,name, msg)
    msg = json.decode(msg)

    msg = skynet.call(_conf.room[1].name, "lua", "client",fd,table.unpack(msg))
    return json.encode(msg)
end

function message(fd, msg, sz)
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
    old_request(fd, msg, sz)
    end
    --]]
end
local MSG = {}
function MSG.data(fd, msg, sz)
    if pwd_connection[fd] then
        message(fd, msg, sz)
    else
        skynet.error(string.format("Drop message from fd (%d) : %s", fd, netpack.tostring(msg,sz)))
    end
end

function MSG.more()
    local fd, msg, sz = netpack.pop(queue)
    if fd then
        -- may dispatch even the handler.message blocked
        -- If the handler.message never block, the queue should be empty, so only fork once and then exit.
        skynet.fork(dispatch_queue)
        dispatch_msg(fd, msg, sz)

        for fd, msg, sz in netpack.pop, queue do
            dispatch_msg(fd, msg, sz)
        end
    end
end

function MSG.open(fd, msg)
    if client_number >= maxclient then
        socketdriver.close(fd)
        return
    end
    if nodelay then
        socketdriver.nodelay(fd)
    end
    pwd_connection[fd] = true
    client_number = client_number + 1
    handshake[fd] = msg
	if pwd_connection[fd] then
		socketdriver.start(fd)
	end
end

function close_fd(fd)
    handshake[fd] = nil
    local c = pwd_connection[fd]
    if c then
        client_number = client_number - 1
        --[[
        local u = username_map[c.username]
        if u then
            skynet.call(u.agent, "lua", "afk")
        end
        --]]
        pwd_connection[fd] = nil
    end

end

function MSG.close(fd)
    if fd ~= socket then
        close_fd(fd)
    else
        socket = nil
    end
end

function MSG.error(fd, msg)
    if fd == socket then
        socketdriver.close(fd)
        skynet.error(msg)
    else
        close_fd(fd)
    end
end

function MSG.warning(fd, size)
    if warning then
        warning(fd, size)
    end
end

skynet.register_protocol {
    name = "socket",
    id = skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
    unpack = function ( msg, sz )
        return netpack.filter( queue, msg, sz)
    end,
    dispatch = function (_, _, q, type, ...)
        queue = q
        if type then
            MSG[type](...)
        end
    end
}


local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
function CMD.close()
    assert(socket)
    socketdriver.close(socket)
end

function CMD.login(uid, secret)
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
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		version = 0,
		index = 0,
		username = username,
		response = {},	-- response cache
	}
	-- you should return unique subid
	return id
end

-- call by agent
function CMD.logout(uid, subid)
	local u = users[uid]
	if u then
		local username = server.username(uid, subid, servername)
		assert(u.username == username)
	local u = user_online[u.username]
	user_online[u.username] = nil
	if u.fd then
		closeclient(u.fd)
		pwd_connection[u.fd] = nil
	end
		users[uid] = nil
		username_map[u.username] = nil
        lxz()
		skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

function CMD.kick(uid, subid)
	local u = users[uid]
	if u then
		local username = string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(conf.name) --注册服务名字便于其他服务调用
    assert(not socket)
    local address = conf.host or "0.0.0.0"
    local port = assert(conf.port)
    maxclient = conf.maxclient or 1024
    nodelay = conf.nodelay
    skynet.error(string.format("Listen on %s:%d", address, port))
    socket = socketdriver.listen(address, port)
    socketdriver.start(socket)
	skynet.call(_conf.login[1].name, "lua", "register_gate", conf.name, skynet.self())


    lxz(SERVICE_NAME)
    skynet.dispatch("lua", function (_, address, cmd, ...)
        local f = assert(CMD[cmd])
        skynet.ret(skynet.pack(f(address, ...)))
    end)
end)

