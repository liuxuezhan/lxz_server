package.path = package.path..";./?.lua"
local skynet = require "skynet"
local socket = require "skynet.socket"
local profile = require "skynet.profile"
local assert = assert

local socket_id	-- listen socket
local client_number = 0
local data = { socket = {} }

function dispatch_msg(fd, name,msg)--分发消息，不返回
    local msg_id,msg = table.unpack(msg)
    skynet.send(g_warx_t.room, "lua", fd,name,msg_id,msg)
end


function open_fd(fd)
    if client_number >= g_warx_t.maxclient then
        return
    end
    client_number = client_number + 1
    socket.start(fd)
end

function close_fd(fd)
    client_number = client_number - 1
    socket.close(fd)
end

plys = {}
local function accept(fd, addr)

    while 1 do
        local msg ,err = socket.readline(fd)
        if msg then
            local d = lualib_serializable.unpack(copyTab(msg))
            if d then
                --lxz(d.f)
                if d.f == "firstPacket2" then
                    d.args[1]=fd
                    local p = player_t.firstPacket2(_G.gAgent, unpack(d.args)  ) 
                    if p  then plys[fd] = p end
                    monster.loop()
                    farm.loop()
                    refugee.loop()
                elseif player_t[d.f] then 
                    --profile.start()
                    if plys[fd] then
                        player_t[d.f](plys[fd], unpack(d.args)  ) 
                    end
                    --lxz(profile.stop())
                end
            else
                break
            end
        else
            lxz(msg)
            break
        end
    end
end

local  function save_db()
    skynet.timeout(3*100, function() 
       check_pending()
       save_db()
    end)
end

function new_socket(fd, addr)
    data.socket[fd] = "[AUTH]"
    proxy.subscribe(fd)
    local ok , userid =  pcall(auth_socket, fd)
    if ok then
        data.socket[fd] = userid
        if pcall(assign_agent, fd, userid) then return-- succ
        else log("Assign failed %s to %s", addr, userid) end
        log("Auth faild %s", addr)
    end
    proxy.close(fd)
    data.socket[fd] = nil
end

skynet.start(function()
    --skynet.newservice("debug_console",80000)

    skynet.newservice("lib/mongo_t",g_warx_t.db_name)--数据库写中心
    socket_id = socket.listen(g_warx_t.host or g_host, g_warx_t.port)--lua-socket.c
    lxz(g_warx_t.host or g_host, g_warx_t.port)
    save_db()
    require "warx_pub/script/frame/frame"
    init(os.time(),os.time())
    while g_beg do
        g_beg = nil
        main_loop(os.time(), os.time(), 0, 0, 0, 0)
    end

    socket.start ( socket_id , function(fd, addr)
        open_fd(fd)	-- may raise error here
        lxz(string.format("connect from %s (fd = %d),cur=%d", addr, fd,client_number))
        local ok, err = pcall(accept, fd, addr)
        if not ok then if err then lxz(fd, err) end end
        close_fd(fd)
        lxz(string.format("disconnect from %s (fd = %d),cur=%d", addr, fd,client_number))
    end
    )
    --skynet.newservice("warx_pub/client")
end)

