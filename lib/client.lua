local socket = require "socket"
local json = require "json"
package.cpath =package.cpath..";/root/skynet/skynet/luaclib/?.so"
local crypt = require "crypt"
--require "debugger"
dofile("../data/define.lua")

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
end


local function writeline(fd, text)
	socket.send(fd, text .. "\n")
end

local function send_pack(fd,v, session)
	writeline(fd, v)
	return v, session
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


local last = ""
local function unpack_old(f,fd)
	local function try_recv(fd, last)
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r = socket.recv(fd)
		if not r then
			return nil, last
		end
		if r == "" then
			error "Server closed"
		end
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
local function read_line(text)--返回换行前后两个字符串
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end


local function encode_token(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

function send(i)
    if robot[i][cur].open then
        conf = robot[i][cur].open 
        local fd = socket.connect( conf[1],conf[2])
        robot[i].fd = fd 
        robot[i].pid = conf[3] 
        if fd == 0 then
            lxz("connect fail["..i.."]\n")
			return 1
		end

        local readline = unpack_old(read_line,fd)
        local base_key = crypt.base64decode(readline())

        local clientkey = crypt.randomkey()
        writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
        local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

        local hmac = crypt.hmac64(base_key, secret)
        writeline(fd, crypt.base64encode(hmac))

        --开始登陆
        local token = {
            user = conf[3],
            pass =  conf[4],
            server = conf[5],
        }
        lxz(token)

        local etoken = crypt.desencode(secret, encode_token(token))
        local b = crypt.base64encode(etoken)
        writeline(fd, crypt.base64encode(etoken))

        local result = readline()
        local info  = crypt.base64decode(result)
        info = json.decode(info)

        socket.close(fd)


        fd = socket.connect( info.host,info.port)
        robot[i].fd = fd 
        if fd == 0 then
            lxz("connect fail["..i.."]\n")
			return 1
		end
	end

	if robot[i][cur].send then
       local msg = json.encode(robot[i][cur].send) 
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


