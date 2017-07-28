local skynet = require "skynet"
require "lualib_mytool"
local socket = require "client.socket"


local fd = assert(socket.connect(g_warx_t.host or g_host, g_warx_t.port))
local function unpack_f(f)
	local function try_recv(fd, last)
		local result
		result, last = f(last)
		if result then return result, last end

		local r = socket.recv(fd)
		if not r then return nil, last end

		if r == "" then lxz "Server closed" end
		return f(last .. r)
	end

	return function()
		while true do
			local result
			result, last = try_recv(fd, last)
			if result then
				return result
			end
			socket.usleep(100)
		end
	end
end

local function unpack_line(text)
    if not text then return end 
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local readline = unpack_f(unpack_line)
local function writeline(fd, text) socket.send(fd, text .. "\n") end

skynet.start(function()
    --while(true) do
        lxz()
        writeline(fd, "hello word")
        lxz()
        local result = readline()
        lxz()
    --end

end)
