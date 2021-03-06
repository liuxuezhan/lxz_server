
--local socket = require "socket"
--local socketdriver = require "socketdriver"
local hashString = hashStr
local packet = packet

local NumberType={
	float=true,
	int=true,
	word=true,
	byte=true,
}

local function isTypeOf(i,s,v)
	-- such as string type
	if s=="string" then 
		if s==type(v) then return true else return false end
	end
	
	-- if it's a number type
	if NumberType[s] and type(v)=="number" then return true end

	if type(v) == "nil" then
		return false
	end
	
	-- if it's a user defined type
	local ut = RpcType[s]
	if ut then
		-- if has check function
		if ut._check then
			if ut:_check(v) then
				return true
			else
				error(string.format("bad argument %d, expected %s, but got %s",i,s,type(v)))
			end
		else
			return true	
		end
	else
		error(string.format("can't find user defined type %s, argument %d",s,i))	
	end
	
	return false
end


local function makeRpc( rpc, name, ... )
	
    local packet = {f=name,args={}}

    for i, v in pairs({...}) do
        table.insert( packet.args, v )
    end

	return json.encode(packet)
end

local function parseRpc( rpc, packet, rfid)
	local rf = rpc.localF[rfid]
	if not rf then
        WARN( "RPC, rfid=%d, not found in localF", rfid )
        return
	end

	local args={}
	for i,v in ipairs(rf.args) do
		local tm = RpcType[v.t]
		args[i] = tm._read( packet )
        if args[i] == nil then 
            WARN("parseRpc, name = %s", rf.name)
            error(string.format("rfid(%d) not found in LocalF", rfid)) 
        end
	end

    return rf.name, args
end 



local function parseFunction( funcimpl )
   	local rf = { args = {} }
	--for t,n in string.gfind(funcimpl,"(%w+)%s+(%w+)") do
	for t,n in string.gmatch(funcimpl,"(%w+)%s+(%w+)") do
        table.insert(rf.args, {t=t, n=n})
	end
	return rf
end

local function parseProtocol( rpc, what )
    what = what or "server"
    local rpcS = {}
    local rpcC = {}

    for k, v in pairs(Protocol.Server) do
        local rf = parseFunction(v)
        rf.id = hashString(k)
        rf.name = k
        if rpcS[ rf.id ] or rf.id < 100 then
            WARN("function dup, name=%s", k)
            os.exit(-1)
        end

        rpcS[rf.id] = rf
        rpcS[k] = rf
    end

    for k, v in pairs(Protocol.Client) do
        local rf = parseFunction(v)
        rf.id = hashString(k)
        rf.name = k
        if rpcC[ rf.id ] or rf.id < 100 then
            WARN("function dup, name=%s", k)
            os.exit(-1)
        end
        rpcC[rf.id] = rf
        rpcC[k] = rf
    end

    if what == "server" then
        rpc.remoteF = rpcC
        rpc.localF = rpcS
    else
        rpc.remoteF = rpcS
        rpc.localF = rpcC
    end
    rpc.mode = what
end

local function parseRpcType()
	local parseStruct=function( k,v )
		local desc = parseFunction(v).args
		-- build rpc type
		RpcType[k] = {
			_write=function( packet, v )
	    		for i, arg in ipairs(desc) do
					local rt = RpcType[arg.t]
					rt._write( packet, v[arg.n] )
	    		end
			end,
			_read=function( packet )
		    local ret={}
		    for i, arg in ipairs(desc) do
	    		local rt = RpcType[arg.t]
				local data = rt._read( packet )
				ret[arg.n] = data
	    	end
	    	return ret
			end,
			_check=function( v )
				for i, arg in ipairs(desc) do
					local rt = RpcType[arg.t]
					if rt._check and not rt._check(v[arg.n]) then
						return false
					end
					return true
	    		end
			end,
		}
	end

	for k,v in pairs(RpcType.__struct) do
		parseStruct(k,v)
	end
end

local function init( rpc, what )
    --parseProtocol( rpc, what )
    parseRpcType()
    print("parse done")
end


local function debugListAllRpc( rpc )
    local log = "<color=yellow>===========remote============\n"
    for name, rf in pairs(rpc.remoteF) do
        log = string.format("%s  %s %d %s\n", log, name, rf.id, Protocol.Server[name])
    end

    log = string.format("%s\n===========local==========\n", log)
    for id, rf in pairs(rpc.localF) do
        log = string.format("%s %s %d %s\n", log, rf.name, id, Protocol.Client[rf.name])
    end

    log = string.format("%s</color>",log)
    print(log)
end

local function do_around( lv, rpc, eid, name, ... )
    local rf = rpc.remoteF[name]
   	if not rf then
		error(string.format("can't find remote function named %s",key))
		return nil 
	end
	
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		error(string.format("expected %d arguments, but passed in %d",#rf.args,#arg))
	end

    --pushHead(eid, lv, rf.id) -- eid will be set to buf->sid, lv will be the an integer after pklen
    pushHead2s(eid, rf.id) -- eid will be set to buf->sid, lv will be the an integer after pklen
    for i, v in ipairs(arg) do
        local t = rf.args[i].t
		if t and isTypeOf(i,t,v) then
			RpcType[t]._write( packet, v )
		else
			error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
		end
    end
    pushAround(eid)
end

local function around0( rpc, eid, name, ... )
    do_around(0, rpc, eid, name, ... )
end

local function around1( rpc, eid, name, ... )
    do_around(1, rpc, eid, name, ... )
end

local function callAgent( rpc, map, name, ... )
    lxz(map,name)
    if map~=gMapID  then return  end 
    if not rpc.localF then return  end 
    local rf = rpc.localF[name]
   	if not rf then
		error(string.format("can't find remote function named %s",name))
		return nil 
	end
	
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		error(string.format("expected %d arguments, but passed in %d",#rf.args,#arg))
	end

    pushHead(_G.GateSid, map, rf.id)
    for i, v in ipairs(arg) do
        local t = rf.args[i].t
		if t and isTypeOf(i,t,v) then
			RpcType[t]._write( packet, v )
		else
			error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
		end
    end
    pushOver()

    lxz("RpcA, pid=%d, func=%s", map, name)
end

local function callRpc( rpc, name, plA, ... )

    local socket = require "skynet.socket"
    local arg={...}
    if not plA then return end
    if type(plA)~="table" then lxz1()  end 
    local pack = {name=name,args={...}, }
    pack = lualib_serializable.pack(pack)
    pack = string.pack(">s", pack)
    if plA.pid then
        if plA.sockid then socket.write(plA.sockid, pack) end
        lxz("RpcS:"..(plA.pid or 0)..":"..name)
    else
        lxz("广播")
        for _, pid in pairs( plA or {} ) do
            local p = getPlayer(pid)
            if p and p.sockid then socket.write(p.sockid, pack) end
            lxz("RpcS:"..(p.pid or 0)..":"..name)
        end
    end

end

local mt = {
    __index = function( table, key )
        return function(rpc, ply,...)
            callRpc(rpc,key,ply, ...)
        end
    end
}

local function new()
    local ins = {}
    ins.init = init
    ins.makeRpc = makeRpc
    ins.parseRpc = parseRpc
    ins.around0 = around0
    ins.around1 = around1
    ins.callAgent = callAgent
    ins.debugListAllRpc = debugListAllRpc
    setmetatable(ins, mt)
    return ins
end

return new()

