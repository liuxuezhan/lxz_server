local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local db = {}

local command = {}

function command.GET(key)
	lxz(key)
    local r = skynet.call("mysql_server", "lua", "get", key ) --向mysql模块发送get命令
    lxz(r)
    local s=""
    r=to_str(r,s,"")
    lxz (s)

    return r
end

function command.SET(key, value)
	local last = db[key]
	db[key] = value
	return last
end

skynet.start(function()
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = command[string.upper(cmd)]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
    skynet.register "SIMPLEDB" --注册SIMPLEDB模块名字便于多个agent模块调用
end)
