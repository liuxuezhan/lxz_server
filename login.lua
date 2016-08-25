local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local cluster = require "cluster"
local string = string
local assert = assert
require "ply_t"	
require "name_t"	


local svrs = {}

local function tm()
    local _tm = os.time()
    return _tm
end
local CMD = {}

function CMD.register_gate(server, host,port)--注册分区
    lxz(server,host,port)
	svrs[server] = {host=host,port=port} 
end

function CMD.logout(name)
    u = ply_t._d[name]
	if u then
		print(string.format("%s is logout",name))
        ply_t._d[name].online=0
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

    local etoken = read(fd)
    local ins = crypt.desdecode(secret, crypt.base64decode(etoken))

    ins = msg_t.unpack(ins)
    ins = msg_t.unzip(ins,"cs_open")
    lxz(ins)
    local p = name_t.login(ins)

    if p then --踢掉上次登录
        if p.online then 
            local sid = p[p.online.pid]
            local s = svrs[sid]
            if s then
                local cid = cluster.query("game1", g_game.name)
                cluster.call("game1",cid, "kick", p.online.pid)
            end
        end
    else
        write( fd, "401 Unauthorized")
        return
    end
    p.online = {pid=tostring(ins.pid),addr=addr,fd= fd, tm_login=os.time() }
    name_t.save(p)

    local s = assert(svrs[ins.sid], "Unknown server")
    lxz(p)
    local msg = msg_t.zip({tid=p._id,pid=p.online.pid,host=s.host,port=s.port},"sc_open")
    lxz(msg)
    msg = msg_t.pack(msg)
	write(fd,  crypt.base64encode(msg))

    log(p._id,"认证通过")
	local s = cluster.query("game1",g_game.name)
    lxz(p)
	cluster.call("game1",s, "login", msg_t.pack(p))
    socket.abandon(fd)	-- never raise error here
end

local  function save_db()
    skynet.timeout(3*100, function() 
        if next(save_t.data) then
    print("deddddddddddddddddddd")
            skynet.send(g_login.db, "lua",g_login.db, msg_t.pack(save_t.data))--不需要返回
            save_t.clear()
        end
        save_db()
    end)
end

skynet.start (
function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)
    require "debugger"

    require "skynet.manager"
	cluster.register(g_login.name, SERVERNAME)

	cluster.open "login1" 

    skynet.register(g_login.name)
    skynet.newservice("db_mongo",g_login.db)--数据库写中心
    save_db()

    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信,包括集群
        skynet.ret(skynet.pack(command_handler(command, ...)))
    end)

    skynet.error(string.format("login server listen at : %s %d", g_login.host, g_login.port))
    local s = socket.listen(g_login.host, g_login.port)--客户端通信
    socket.start ( s , function(fd, addr)
        socket.start(fd)	-- may raise error here
        socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket
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

