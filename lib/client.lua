local json = require "json"
package.cpath =package.cpath..";/root/skynet/skynet/luaclib/?.so"
local crypt = require "crypt"
local socket = require "socket"
--require "debugger"
dofile("../data/define.lua")

dofile("client_conf.lua")

local _r ={}--机器人列表
local cur = 1--当前执行的步骤

local function write(fd, text)
	socket.send(fd, text .. "\n")
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
        _r[i]={last="",}
        for k,v in pairs(_conf) do
            _r[i][k]={}
            dispath(_r[i][k],table.unpack(v))
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

local function read(i)
	local function try_recv(fd, last)
		local result
		result, last = read_line(last)
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
		return read_line(last .. r)
	end

    while true do
        local result
        result, _r[i].last = try_recv(_r[i].fd, _r[i].last)
        if result then
            return result
        end
        socket.usleep(100)
    end
end


local function encode_token(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

function send(i)
    if _r[i][cur].open then
        conf = _r[i][cur].open 
        local fd = socket.connect( conf[1],conf[2])
        _r[i].fd = fd 
        _r[i].pid = conf[3] 
        if fd == 0 then
            lxz("connect fail["..i.."]\n")
			return 1
		end

        local base_key = crypt.base64decode(read(i))

        local clientkey = crypt.randomkey()
        write(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
        local secret = crypt.dhsecret(crypt.base64decode(read(i)), clientkey)

        local hmac = crypt.hmac64(base_key, secret)
        write(fd, crypt.base64encode(hmac))

        --开始登陆
        local token = {
            user = conf[3],
            pass =  conf[4],
            server = conf[5],
        }
        lxz(token)

        local etoken = crypt.desencode(secret, encode_token(token))
        local b = crypt.base64encode(etoken)
        write(fd, crypt.base64encode(etoken))

        local result = read(i)

        local info  = crypt.base64decode(result)
        info = json.decode(info)
        socket.close(fd)

        lxz(info)
        fd = socket.connect( info.host,info.port)
        _r[i].fd = fd 
        if fd == 0 then
            lxz("connect fail["..i.."]\n")
			return 1
		end
	end

	if _r[i][cur].send then
       local msg = json.encode({_r[i].pid,_r[i][cur].send})
		write(_r[i].fd, msg )
        local ret = read(i)
        lxz(ret)
	end

	if _r[i][cur].close then
		socket.close(_r[i].fd )
		lxz("socket close----"..i)
		_r[i].fd = nil
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


