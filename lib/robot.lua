
--机器人发消息模块
dofile("/www/lualib/skynet/data/define.lua")
module(..., package.seeall)
local msg = require "msg"
package.cpath =package.cpath..";/www/lualib/skynet/skynet/luaclib/?.so"
local crypt = require "crypt"
local socket = require "client_socket"
--require "debugger"

local _r ={}--机器人列表
local cur = 1--当前执行的步骤

local function write(i, text)
	local fd = _r[i].fd
	socket.send(fd, text .. "\n")
end

function dispath(r,name,type,...)
    if type == "open" then
        r.open = {...}
        r.open[3] = name --动态生成机器人名字
    elseif type == "first" then
        r.name = ...
    elseif type == "send" then
        r.send ={...} 
    elseif type == "close" then
        r.close = 0
    end
end

function robot_init(id,_num,_conf)--初始化配置
    for i=1,_num do
        _r[i]={last="",name = "test"..os.time().."_"..id.."_"..i }
        for k,v in pairs(_conf) do
            _r[i][k]={}
            dispath(_r[i][k],_r[i].name,table.unpack(v))
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

function open(i,conf)
    local fd = socket.connect( conf[1],conf[2])
    _r[i].fd = fd 
    _r[i].pid = conf[3] 
    if fd == 0 then
        lxz("connect fail["..i.."]\n")
        return 1
    end

    local base_key = crypt.base64decode(read(i))

    local clientkey = crypt.randomkey()
    write(i, crypt.base64encode(crypt.dhexchange(clientkey)))
    local secret = crypt.dhsecret(crypt.base64decode(read(i)), clientkey)

    local hmac = crypt.hmac64(base_key, secret)
    write(i, crypt.base64encode(hmac))

    --开始登陆
    local token = {
        user = conf[3],
        pass =  conf[4],
        server = conf[5],
    }
    lxz(token)

    local etoken = crypt.desencode(secret, encode_token(token))
    local b = crypt.base64encode(etoken)
    write(i, crypt.base64encode(etoken))

    local result = read(i)

    local info  = crypt.base64decode(result)
    info = msg.unpack(info)
    socket.close(fd)

    lxz(info)
    fd = socket.connect( info.host,info.port)
    _r[i].fd = fd 
    if fd == 0 then
        lxz("connect fail["..i.."]\n")
        return 1
    end
end

function send(i)
    if _r[i][cur].open then
        local conf = _r[i][cur].open 
        if open(i,conf) then
            return
        end
	end

	if _r[i][cur].send then
       local msg = msg.pack({_r[i].pid,_r[i][cur].send})
		write(i, msg )
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


function robot_start(_num,_conf)--开始执行

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


