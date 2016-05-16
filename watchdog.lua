local skynet = require "skynet"
local netpack = require "netpack"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}

function SOCKET.open(fd, addr)
    skynet.error("New client from : " .. addr)
    agent[fd] = skynet.newservice("agent")  --启动agent模块（见agent.lua）
    skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() }) --向agent模块发送start命令
end

local function close_agent(fd)
    local a = agent[fd]
    agent[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        -- disconnect never return
        skynet.send(a, "lua", "disconnect")
    end
end

function SOCKET.close(fd)
    print("socket close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    print("socket error",fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    -- size K bytes havn't send out in fd
    print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
--lxz(msg)
end

function CMD.start(conf)
    skynet.call(gate, "lua", "open" , conf)  --向gate模块发送open命令
    print("Watchdog listen on ", 8880)
end

function CMD.close(fd)
    close_agent(fd)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
    lxz(cmd)
    lxz(subcmd)
            local f = SOCKET[subcmd]
            f(...)
            -- socket api don't need return
        else
            local f = assert(CMD[cmd])
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)

    gate = skynet.newservice("gate")  --启动gateserver模块
end)
