
package.cpath = "./robot.so"
package.path = "./rpc/?.lua;../common/?.lua"

local socket = require "socket"
dofile("preload.lua")

function doLoadMod(name, mod)
    mod = mod or name
    if name == "debugger" then
        if not _G[ name ] then
            _G[ name ] = require( mod )
        end
    else
        package.loaded[ name ] = nil
        _G[ name ] = require( mod )
    end
end

function do_load(mod)
    package.loaded[ mod ] = nil
    require( mod )
  --  LOG("load module %s", mod)
end

function init()
    do_load("protocol")
    doLoadMod("packet", "packet")
    doLoadMod("MsgPack","MessagePack")
    doLoadMod("Array",  "array")
    doLoadMod("Struct", "struct")
    doLoadMod("RpcType","rpctype")
    doLoadMod("pack","pack")
    iopack = pack
    doLoadMod("Rpc",    "rpc")
    Rpc:init()
end


local function send_package(fd, pack)
    socket.send(fd, pack)
end

local function unpack_package(text)
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

local function recv_package(fd)
    local r = socket.recv(fd)
    if not r then
        return nil, nil
    end

	return Rpc:parseRpc( r )
end



init()
local robot ={}
dofile("conf.lua")

function robot_init(id)
	for i=1,_num do
		robot[i]={}
		for k,v in pairs(_conf) do
			robot[i][k]={rev=v[1] or 0,}
			if v[2] == "open" then
				robot[i][k].open = {v[3],v[4]}
			end

			if v[2] == "first" then
				local name = "test"..os.time().."_"..id.."_"..i
				robot[i][k].first = v[3]
				robot[i].name = name
			end

			if v[2] == "send" then
				robot[i][k].send = v[3]
			end

			if v[2] == "reap" then
				robot[i][k].reap = 0
			end

			if v[2] == "build" then
				robot[i][k].build = v[3]
			end

			if v[2] == "upgrade" then
				robot[i][k].upgrade = v[3]
			end

			if v[2] == "train" then
				robot[i][k].train = v[3]
				robot[i][k].arm = v[4]
				robot[i][k].num = v[5]
			end

			if v[2] == "fight" then
				robot[i][k].fight = v[3]
			end

			if v[2] == "close" then
				robot[i][k].close = 0
			end
		end
	end
end

local function dispatch_package(i,ok,err)--读取返回数据
	err = err or 1
	if robot[i].fd then
		while true do
		   local pktype, args = recv_package(robot[i].fd )
			if pktype  then
				lxz("rev ....."..pktype)
				lxz(args)
			if pktype == ok or pktype == err then
				return pktype,args
			end
			end
		end
	end

end


local cur = 1 --当前命令
function send(i)
	lxz("cur --------------"..cur)

	if robot[i][cur].open then
		robot[i].fd = socket.connect( robot[i][cur].open[1],robot[i][cur].open[2])
		lxz("connect --------------"..robot[i].fd)
		if robot[i].fd == 0 then
			lxz("connect fail["..i.."]\n")
			return 1
		end

	end

	if robot[i][cur].build then
		lxz("build --------------"..robot[i][cur].build)
		socket.send(robot[i].fd, Rpc:construct(100+cur,0,robot[i][cur].build) )
		local rev,args = dispatch_package(i,"stateBuild","onError")
		while rev == "onError" do
			socket.send(robot[i].fd, Rpc:reap(20) )
			socket.send(robot[i].fd, Rpc:reap(21) )

			socket.send(robot[i].fd, Rpc:loadData("pro") )
			dispatch_package(i,"loadData")

			socket.send(robot[i].fd, Rpc:loadData("build") )
			dispatch_package(i,"loadData")

			lxz("cur time----------"..os.time())
			socket.usleep(1000000*5 )

			ocket.send(robot[i].fd, Rpc:construct(x,0,robot[i][cur].build) )
			rev,args = dispatch_package(i,"stateBuild","onError")
		end
	end

	if robot[i][cur].upgrade then
		lxz("upgrade --------------"..robot[i][cur].upgrade)

		socket.send(robot[i].fd, Rpc:upgrade(robot[i][cur].upgrade) )
		local rev,args = dispatch_package(i,"stateBuild","onError")
		while rev == "onError" do
			socket.send(robot[i].fd, Rpc:reap(20) )
			socket.send(robot[i].fd, Rpc:reap(21) )

			socket.send(robot[i].fd, Rpc:loadData("pro") )
			dispatch_package(i,"loadData")

			socket.send(robot[i].fd, Rpc:loadData("build") )
			dispatch_package(i,"loadData")

			lxz("cur time----------"..os.time())
			socket.usleep(1000000*5 )

			socket.send(robot[i].fd, Rpc:upgrade(robot[i][cur].upgrade) )
			rev,args = dispatch_package(i,"stateBuild","onError")
		end

	end

	if robot[i][cur].train then
		lxz("train --------------"..robot[i][cur].train)
		socket.send(robot[i].fd, Rpc:train(robot[i][cur].train,robot[i][cur].arm, robot[i][cur].num) )
		socket.send(robot[i].fd, Rpc:loadData("build") )
		local _,args = dispatch_package(i,"loadData")
		while args[1].val[robot[i][cur].train].tmOver > os.time() do
			lxz("cur time----------"..os.time())
			socket.usleep(1000000*5 )
		end
		socket.send(robot[i].fd, Rpc:draft(robot[i][cur].train) )
	end

	if robot[i][cur].fight then
		lxz("fight --------------"..robot[i].pid)
		socket.send(robot[i].fd, Rpc:addEye() )
		local _,args = dispatch_package(i,"addEty")
		while args[1].name == nil or robot[i].pid ==args[1].pid do
			_,args = dispatch_package(i,"addEty")
		end

		lxz(args[1].name)

		socket.send(robot[i].fd, Rpc:seige(args[1].eid,robot[i][cur].fight) )
	--	local _,args = dispatch_package(i,"loadData")
	end

	if robot[i][cur].close then
		socket.close(robot[i].fd )
		lxz("socket close----"..i)
		robot[i].fd = nil
	end

	if robot[i][cur].first then
		lxz("first --------------"..robot[i].name)
		socket.send(robot[i].fd, Rpc:firstPacket(robot[i][cur].first,robot[i].name,"123") )
		local _,args = dispatch_package(i,"onLogin")
		robot[i].pid =args[1]
	end

	if robot[i][cur].send then
		lxz("send cur:"..cur.." robot:"..i)
		socket.send(robot[i].fd, robot[i][cur].send )
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

