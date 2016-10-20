local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
--local base = require "base"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd


local function request(cmd,...)
    local r = skynet.call("SIMPLEDB", "lua", "get", cmd)
lxz(r)
    if response then
        return response(r)
    end
    return r
end

local function send_package(pack)
--    local package = string.pack(">s2", pack)
   local package = pack
    socket.write(client_fd, package)
end

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = skynet.tostring,
    dispatch = function (_, _, cmd,...)
    lxz(cmd)
        local ok, result  = pcall(request, cmd,...)
            if ok then
	    lxz(result)
                if result then
                   --- send_package(result)
                    send_package("我们看的份")
                end
            else
                skynet.error(result)
            end
    end
}

function CMD.start(conf)
    local fd = conf.client
    local gate = conf.gate
    WATCHDOG = conf.watchdog
    -- slot 1,2 set at main.lua
    host = sprotoloader.load(1):host "package"   --获取一个消息处理器
    send_request = host:attach(sprotoloader.load(2)) --构成返回消息数据
    --[[
    skynet.fork(function()
        while true do
            send_package(send_request "heartbeat") --建立一个携程循环发送心跳包
            skynet.sleep(500)
        end
    end)
    --]]

    client_fd = fd
    skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
    -- todo: do something before exit
    skynet.exit()
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, command, ...)
    lxz(command)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
end)
