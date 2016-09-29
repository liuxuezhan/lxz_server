

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
-----------------位操作--------------------------------------
bit={data32={}}
for i=1,32 do
    bit.data32[i]=2^(32-i)
end

function bit:d2b(arg)
    local   tr={}
    for i=1,32 do
        if arg >= self.data32[i] then
        tr[i]=1
        arg=arg-self.data32[i]
        else
        tr[i]=0
        end
    end
    return   tr
end   --bit:d2b

function    bit:b2d(arg)
    local   nr=0
    for i=1,32 do
        if arg[i] ==1 then
        nr=nr+2^(32-i)
        end
    end
    return  nr
end   --bit:b2d

function    bit:_xor(a,b)
    local   op1=self:d2b(a)
    local   op2=self:d2b(b)
    local   r={}

    for i=1,32 do
        if op1[i]==op2[i] then
            r[i]=0
        else
            r[i]=1
        end
    end
    return  self:b2d(r)
end --bit:xor

function    bit:_and(a,b)
    local   op1=self:d2b(a)
    local   op2=self:d2b(b)
    local   r={}
    
    for i=1,32 do
        if op1[i]==1 and op2[i]==1  then
            r[i]=1
        else
            r[i]=0
        end
    end
    return  self:b2d(r)
    
end --bit:_and

function    bit:_or(a,b)
    local   op1=self:d2b(a)
    local   op2=self:d2b(b)
    local   r={}
    
    for i=1,32 do
        if  op1[i]==1 or   op2[i]==1   then
            r[i]=1
        else
            r[i]=0
        end
    end
    return  self:b2d(r)
end --bit:_or

function    bit:_not(a)
    local   op1=self:d2b(a)
    local   r={}

    for i=1,32 do
        if  op1[i]==1   then
            r[i]=0
        else
            r[i]=1
        end
    end
    return  self:b2d(r)
end --bit:_not

function    bit:_rshift(a,n)
    local   op1=self:d2b(a)
    local   r=self:d2b(0)
    
    if n < 32 and n > 0 then
        for i=1,n do
            for i=31,1,-1 do
                op1[i+1]=op1[i]
            end
            op1[1]=0
        end
    r=op1
    end
    return  self:b2d(r)
end --bit:_rshift

function    bit:_lshift(a,n)
    local   op1=self:d2b(a)
    local   r=self:d2b(0)
    
    if n < 32 and n > 0 then
        for i=1,n   do
            for i=1,31 do
                op1[i]=op1[i+1]
            end
            op1[32]=0
        end
    r=op1
    end
    return  self:b2d(r)
end --bit:_lshift


function    bit:print(ta)
    local   sr=""
    for i=1,32 do
        sr=sr..ta[i]
    end
    print(sr)
end
-----------------加载模块--------------------------------
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

local robot ={}

local function recv_package(i)
    local r = socket.recv(robot[i].fd )
    if not r then
        return nil, nil
    end

	return Rpc:parseRpc( r )
end



init()
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
				local name = "test"..v[4]..os.time().."_"..id.."_"..i
				robot[i][k].first = v[3]
				robot[i].name = name
			end

			if v[2] == "send" then
				robot[i][k].send = v[3]
				robot[i][k].rev = v[4]
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

			if v[2] == "draft" then
				robot[i][k].draft = v[3]
			end

			if v[2] == "fight" then
				robot[i][k].fight = v[3]
				robot[i][k].type = v[4]
			end

			if v[2] == "union" then
				robot[i][k].union = v[3] 
			end

			if v[2] == "add_union" then
				robot[i][k].add_union = v[3] 
			end

			if v[2] == "union_mass" then
				robot[i][k].union_mass = v[3] 
				robot[i][k].type = v[4] 
			end

			if v[2] == "close" then
				robot[i][k].close = 0
			end
		end
	end
end

local cur = 1 --当前命令
local function dispatch_package(i,ok,err)--读取返回数据
	err = err or 1
    local pktype
    local args 
	if robot[i].fd then
		while true do
            pktype, args = recv_package(i )
			if pktype  then
		        --lxz(robot[i].name..":"..cur..":"..ok..":"..err)
		--		lxz(pktype)
		--	    lxz(args)
			    if pktype == ok or pktype == err then
				    return pktype,args
			    end
			end
		end
	end

end

local unionlist = {} 

function send(i)

	if robot[i][cur].open then
		robot[i].fd = socket.connect( robot[i][cur].open[1],robot[i][cur].open[2])
		lxz("connect --------------"..robot[i].fd)
		if robot[i].fd == 0 then
			lxz("connect fail["..i.."]\n")
			return 1
		end

	end

	if robot[i][cur].build then
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

			socket.send(robot[i].fd, Rpc:construct(x,0,robot[i][cur].build) )
			rev,args = dispatch_package(i,"stateBuild","onError")
		    lxz("build --------------"..robot[i][cur].build)

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
	end

	if robot[i][cur].draft then
		lxz("draft --------------"..robot[i][cur].draft)
		socket.send(robot[i].fd, Rpc:loadData("build") )
		local _,args = dispatch_package(i,"loadData")
		while args[1].val[robot[i][cur].draft].tmOver > os.time() do
			lxz("cur time----------"..os.time())
			socket.usleep(1000000*5 )
		end
		socket.usleep(1000000*1 )
		socket.send(robot[i].fd, Rpc:draft(robot[i][cur].draft) )
		socket.send(robot[i].fd, Rpc:loadData("pro") )
		local _,args = dispatch_package(i,"loadData")
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
		robot[i].pid =args[2]
	end

	if robot[i][cur].union then
		lxz("union --------------"..robot[i][cur].union)
		socket.send(robot[i].fd, Rpc:unionList())
	    local _,args = dispatch_package(i,"unionList")
        robot[i].unionid = 0 
        for _, v in ipairs(args[1]) do
            for _, n in ipairs(robot) do
                if v.leader == n.pid then
                    robot[i].unionid = v.uid  
                end
            end
        end

        if robot[i].unionid == 0 then
		    socket.send(robot[i].fd, Rpc:unionCreate(robot[i].name,robot[i].alias,10,1)) 
	        local _,args = dispatch_package(i,"unionOnCreate")
            robot[i].unionid = args[1].uid
        else
		    socket.send(robot[i].fd, Rpc:unionApply(robot[i].unionid)) 
	        local _,args = dispatch_package(i,"unionReply")
        end
	end

	if robot[i][cur].add_union then
		lxz("add_union --------------"..robot[i].unionid)
		socket.send(robot[i].fd, Rpc:unionLoad("apply"))
	    local _,args = dispatch_package(i,"unionLoad")
        for _, v in ipairs(args[1].val) do
		    socket.send(robot[i].fd, Rpc:unionAddMember(v.pid))
        end
    end

	if robot[i][cur].union_mass then
		lxz("union_mass --------------"..robot[i].unionid)
		socket.send(robot[i].fd, Rpc:unionLoad("info"))
	    local _,args = dispatch_package(i,"unionLoad")

		socket.send(robot[i].fd, Rpc:unionLoad("mass"))
	    local _,args = dispatch_package(i,"unionLoad")
        local mid = 0
        for _, v in ipairs(args[1].val) do
            if v.count < v.max then
                mid = v.mid
            end
        end

        if mid == 0 then
		    socket.send(robot[i].fd, Rpc:addEye() )
		    local _,args = dispatch_package(i,"addEty")
            local type = math.floor(args[1].eid/65536)   
            while robot[i][cur].type ~= type do 
		        _,args = dispatch_package(i,"addEty")
                type = math.floor(args[1].eid/65536)   
            end
		    socket.send(robot[i].fd, Rpc:union_mass_create(args[1].eid,300,robot[i][cur].union_mass) )
		    dispatch_package(i,"union_mass_on_create","onError")
        else
		    socket.send(robot[i].fd, Rpc:union_mass_join(mid,robot[i][cur].union_mass) )
		    dispatch_package(i,"stateTroop","onError")
        end
    end

	if robot[i][cur].fight then
		lxz("fight --------------"..robot[i].pid)
		socket.send(robot[i].fd, Rpc:addEye() )
		    _,args = dispatch_package(i,"addEty")
            local type = math.floor(args[1].eid/65536)   
            while robot[i][cur].type ~= type or (robot[i][cur].val == 0 or nil) do 
		        _,args = dispatch_package(i,"addEty")
                type = math.floor(args[1].eid/65536)   
            end

		lxz(args[1].name)

		socket.send(robot[i].fd, Rpc:seige(args[1].eid,robot[i][cur].fight) )
	--	local _,args = dispatch_package(i,"loadData")
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

