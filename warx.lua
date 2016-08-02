package.path = package.path..";./?.lua"
local skynet = require "skynet"
local socket = require "socket"
local save = require "save"	
local assert = assert

local socket_id	-- listen socket
local client_number = 0


local server_name = "warx" 
local conf =_list[server_name] 


local function read(fd)
    local ok ,ret = pcall(socket.readline,fd)
    if not ok then
		skynet.error(string.format("socket(%d) read fail", fd))
    end
    return ret
end


function dispatch_msg(fd, name,msg)--分发消息，不返回
    local msg_id,msg = table.unpack(msg)
    skynet.send(conf.room, "lua", fd,name,msg_id,msg)
end


function open_fd(fd)
    if client_number >= conf.maxclient then
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

function CMD.login(data)
    lxz()
    data = json.decode(data) 
    ply._d[data.name]=data
    save.data.ply[data._id]=data
end

-- call by agent
function CMD.logout(name )
    close_fd(ply._d[name].fd)
    ply._d[name].online=0
    skynet.call(loginservice, "lua", "logout",name )
end

function CMD.kick(name )
    ply._d[name].online=0
end


local function accept(fd, addr)
    lxz()
    lxz(string.format("connect from %s (fd = %d)", addr, fd))

    open_fd(fd)	-- may raise error here

    --slg_read(fd)
    local d = json.decode(copy(read(fd)))
    lxz(d)
    if d.f == "firstPacket2" then
        d.args[1]=fd
        player_t[d.f](_G.gAgent, unpack(d.args)  ) 
    else
        player_t[d.f](_G.gAgent, unpack(d.args)  ) 
    end
end

local  function save_db()
    skynet.timeout(3*100, function() 
        if next(save.data) then
            skynet.send(conf.db_name, "lua","db1", json.encode(save.data))--不需要返回
            save.clear()
        end
        save_db()
    end)
end


skynet.start(function()
--    local console = skynet.newservice("console")
 --   skynet.newservice("debug_console",80000)
 
    require "debugger"
    skynet.newservice("db_mongo",conf.db_name)--数据库写中心
    save_db()
    warx_init()

    lxz(conf)
    socket_id = socket.listen(conf.host, conf.port)
    socket.start ( socket_id , function(fd, addr)
        local ok, err = pcall(accept, fd, addr)
        if not ok then
            if err then
                lxz(fd, err)
            end
            close_fd(fd)
        end
    end
    )
end)

