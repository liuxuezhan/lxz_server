--机器人发消息模块
dofile("../data/def.lua")
package.cpath =package.cpath..";../skynet/luaclib/?.so"
local crypt = require "crypt"
local socket = require "client_socket"
require "debugger"


_num = 1 --机器人数量
_conf = { --机器人操作集合
			{"open","192.168.103.225",8001,{name="10000",pwd="pwd",sid=g_game.name,pid="" }},
			--{"open","127.0.0.1",8001,"10000","pwd","game_server1"},
			{"send",{id="cs_enter",pid=0,msg={} },},
			{"close"},
	}

local _r ={}--机器人列表
local cur = 1--当前执行的步骤

local function write(i, text)
	local fd = _r[i].fd
	socket.send(fd, text .. "\n")
end

function dispath(r,name,type,...)
    if type == "open" then
        r.open = {...}
        r.open[3].name = name --动态生成机器人名字
    elseif type == "first" then
        r.name = ...
    elseif type == "send" then
        r.send =... 
    elseif type == "close" then
        r.close = 0
    end
end

function robot_init(id)--初始化配置
    for i=1,_num do
        _r[i]={last="",name = "robot_"..tostring((math.floor(id)+1)*1000 + i) }
        for k,v in pairs(_conf) do
            _r[i][k]={}
       lxz(v) 
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

reading = coroutine.create(function (i)
	local function try_recv(fd, last)
		local ret
		ret, last = read_line(last)
		if ret then
			return ret, last
		end

		local ret = socket.recv(fd)
		if not ret then
			return nil, last
		end
		if ret == "" then
			error "Server closed"
		end
		return read_line(last .. ret)
	end

    while true do
        local ret
        ret, _r[i].last = try_recv(_r[i].fd, _r[i].last)
        --lxz()
        if ret then
            coroutine.yield(ret) 
        end
        coroutine.yield() 
    end
end)

local function read(i)--读到数据
   while true do
        local f,r = coroutine.resume(reading, i)
        if f and r then 
            return r
        end
   end
end

local function read_one(i)--读一个
    local f,r = coroutine.resume(reading, i)
    if f and r then 
        return r
    end
end

local function encode_token(token)
      return msg_t.pack(token)
end

function open(i,conf)
    local fd = socket.connect( conf[1],conf[2])
    _r[i].fd = fd 
    _r[i].pid = conf[3] 
    lxz(conf)
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
    local token = msg_t.zip("cs_login",conf[3])
    lxz(token)

    local etoken = crypt.desencode(secret, encode_token(token))
    local b = crypt.base64encode(etoken)
    write(i, crypt.base64encode(etoken))

    local result = read(i)

    local info  = crypt.base64decode(result)
    info = msg_t.unpack(info)
    info = msg_t.unzip("sc_login",info)
    socket.close(fd)

    lxz(info)
    fd = socket.connect( info.host,info.port)
    _r[i].fd = fd 
    _r[i].pid = info.pid 
    _r[i].nid = info.nid 
    if fd == 0 then
        lxz("connect fail["..i.."]\n")
        return 1
    end
end

function send(i)
    local self=_r[i][cur]
    if not self then
        return
    end

    if _r[i][cur].open then
        local conf = _r[i][cur].open 
        if open(i,conf) then
            return
        end
	end

	if self.send then
        local msg = self.send
        msg.pid = _r[i].pid 
        msg.tid = _r[i].tid 
        msg = msg_t.zip("cs_msg",msg)
        msg = msg_t.pack(msg)
		write(i, msg )
    lxz(msg)
        local ret = read_one(i)
        lxz(ret)
	end

	if _r[i][cur].close then
		socket.close(_r[i].fd )
		lxz("socket close----"..i)
		_r[i].fd = nil
	end

	return 0
end


function main_loop(deb,num)--开始执行
    if deb > 0 then
        pause("debug in main_loop")
    elseif deb > 1 then
        os.exit(-1)
    end

    for i = 1,num do
        local ret = 0
        if cur >#_conf then
            return 1
        end

        for i=1,_num do
            ret = send(i)
        end

        cur = cur + 1
    end
    return 0
end


