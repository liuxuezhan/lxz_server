skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local cluster = require "cluster"
local string = string
require "ply_t"
require "name_t"
require "time_t"


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
    g_tm = os.time()
    lxz(addr, fd)


    -- 发送基础key给客户端
    local base_key = crypt.randomkey()
    write( fd,crypt.base64encode(base_key))

    --接收客户端key
    local ret = read(fd)
    lxz(ret)
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
    ins = msg_t.unzip("cs_login",ins)
    lxz(ins)
    local p,pid = name_t.login(ins)

    if p then --踢掉上次登录
        if p.online then 
            local sid = p[p.online.pid]
            local s = svrs[sid]
            if s then
                local cid = cluster.query(g_game.name, g_game.name)
                cluster.call(g_game.name,cid, "kick", p.online.pid)
            end
        end
    else
        write( fd, "401 Unauthorized")
        return
    end

    p.online = {pid=pid,addr=addr,fd= fd, tm_login=g_tm }
    name_t.save(p)

    local s = svrs[ins.sid]
    if not s then
        log("")
    end
    local msg = msg_t.zip("sc_login",{nid=p.nid,pid=pid,host=s.host,port=s.port})
    lxz(msg)
    msg = msg_t.pack(msg)
	write(fd,  crypt.base64encode(msg))

    log(p._id,"认证通过")
	local s = cluster.query(g_game.name,g_game.name)
    lxz(p)
	cluster.call(g_game.name,s, "login", msg_t.pack(p))
--    socket.abandon(fd)	-- never raise error here
end


skynet.start (
function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)

    require "debugger"
    skynet.newservice("mongo_t",g_login.db)--数据库写中心
    time_t.new("save_db",3,g_login.db)

	cluster.register(g_login.name, SERVERNAME)
	cluster.open(  g_login.name )

    require "skynet.manager"
    skynet.register(g_login.name)

    skynet.dispatch("lua", function(_,source,command, ...)--服务器间通信,包括集群
        skynet.ret(skynet.pack(command_handler(command, ...)))
    end)

    skynet.error(string.format("login server listen at : %s %d", g_login.host, g_login.port))
    local s = socket.listen(g_login.host, g_login.port)--客户端通信
    socket.start ( s , function(fd, addr)
        socket.start(fd)	-- may raise error here
    --    socket.limit(fd, 8192) -- set socket buffer limit (8K),If the attacker send large package, close the socket
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

