local socket = require "socket"
local json = require "json"
--require "debugger"
dofile("../data/tool.lua")

dofile("client_conf.lua")

local robot ={}
local cur = 1

local function unpack_package(text)
    if not text  then
		return nil, ""
    end

	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function unpack_f(i)
	local function try_recv(i)
		local result
		result, robot[i].last = unpack_package(robot[i].last)
		if result then
			return result, robot[i].last
		end

		local r = socket.recv(robot[i].fd)
		if not r then
			return nil, robot[i].last
		end
		if r == "" then
			error "Server closed"
		end
		return unpack_package(robot[i].last .. r)
	end

		while true do
			local result
			result, robot[i].last = try_recv(i)
			if result then
				return result
			end
			socket.usleep(100)
		end
end

local function recv_response(v)
    return v
    --[[
	local size = #v - 5
	local content, ok, session = string.unpack("c"..tostring(size).."B>I4", v)
	return ok ~=0 , content, session
    --]]
end



local function send_pack(fd,v, session)
	local size = #v + 4
	local package = string.pack(">I2", size)..v..string.pack(">I4", session)
	socket.send(fd, package)
	return v, session
end

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end



function dispath(r,type,...)
    if type == "open" then
        r.open = {...}
    elseif type == "first" then
        r.name = ...
    elseif type == "send" then
        r.send ={...} 
    elseif type == "close" then
        r.close = 0
    end
end

function robot_init(id)
    for i=1,_num do
        robot[i]={}
        for k,v in pairs(_conf) do
            robot[i][k]={}
            dispath(robot[i][k],table.unpack(v))
        end
    end
end


function send(i)

    if robot[i][cur].open then
        robot[i].fd = socket.connect( table.unpack(robot[i][cur].open))
        if robot[i].fd == 0 then
            lxz("connect fail["..i.."]\n")
			return 1
		end

	end

	if robot[i][cur].send then
       local msg = json.encode(robot[i][cur].send) 
		lxz(cur,i,robot[i][cur].send)
		send_pack(robot[i].fd, msg,0 )
        lxz(recv_response(unpack_f(i)))
	end

	if robot[i][cur].close then
		socket.close(robot[i].fd )
		lxz("socket close----"..i)
		robot[i].fd = nil
	end

	return 0
end


function robot_start()

	local ret = 0
	if cur >#_conf then
		return 1
	end

	for i=1,_num do

		ret = send(i)
	end

	cur = cur + 1

	return 0
end


