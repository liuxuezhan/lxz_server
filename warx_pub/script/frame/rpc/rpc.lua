
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
			if ut._check(v) then
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


local function push_args( defs, vals )
    for i, v in ipairs(vals) do
        local t = defs[i].t
        if t and isTypeOf(i,t,v) then
			RpcType[t]._write( packet, v, 1, defs[i].d )
		else
			error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
		end
    end
end



local function makeRpc( rpc, name, ... )
    local rf = rpc.remoteF[name]
   	if  not rf then
		error(string.format("can't find remote function named %s",key))
		return nil 
	end
	
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		error(string.format("expected %d arguments, but passed in %d",#rf.args,#arg))
	end
	
    local packet = LuaPacket(rf.id)

    for i, v in ipairs(arg) do
        local t = rf.args[i].t	
        if t and isTypeOf(i,t,v) then
			RpcType[t]._write( packet, v )
		else
			error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
		end
    end

	return packet
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
		args[i] = tm._read( packet, 1, v.d )
        if args[i] == nil then 
            WARN("parseRpc, name = %s, arg:%s is nil", rf.name, i)
            error("paresRpc failed, wrong args") 
        end
	end
    return rf.name, args
end 



function parseFunction( funcimpl )
   	--local rf = { args = {} }
	--for t,n in string.gmatch(funcimpl,"(%w+)%s+([%w_]+)") do
    --    table.insert(rf.args, {t=t, n=n})
	--end
	--return rf

    local args = {}
    for w in string.gmatch( funcimpl, "([^,]+),?" ) do
        local ns = {}
        for v in string.gmatch( w, "[%w_]+" ) do
            table.insert( ns, v )
        end
        local t = table.remove( ns, 1 )
        local n = table.remove( ns )
        local node = { t = t, n = n }
        if #ns > 0 then node.d = ns end
        table.insert( args, node )
    end

    return { args = args }
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
            local remain_len = nil
		    for i, arg in ipairs(desc) do
                remain_len = packet:checkBuf()
                if remain_len and remain_len > 0 then
                    local rt = RpcType[arg.t]
                    local data = rt._read( packet )
                    ret[arg.n] = data
                else
                    break
                end
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
    parseProtocol( rpc, what )
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

    push_args( rf.args, arg )

    --for i, v in ipairs(arg) do
    --    local t = rf.args[i].t
	--	if t and isTypeOf(i,t,v) then
	--		RpcType[t]._write( packet, v )
	--	else
	--		error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
	--	end
    --end
    pushAround(eid)
end

local function around0( rpc, eid, name, ... )
    do_around(0, rpc, eid, name, ... )
end

local function around1( rpc, eid, name, ... )
    do_around(1, rpc, eid, name, ... )
end

local function callAgent( rpc, map, name, ... )
    local rf = rpc.localF[name]
   	if not rf then
		error(string.format("can't find remote function named %s",name))
		return nil 
	end
	
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		error(string.format("rpc:%s, expected %d arguments, but passed in %d", name, #rf.args,#arg))
	end

    pushHead(_G.GateSid, map, rf.id)
    push_args( rf.args, arg )
    --for i, v in ipairs(arg) do
    --    local t = rf.args[i].t
	--	if t and isTypeOf(i,t,v) then
	--		RpcType[t]._write( packet, v )
	--	else
	--		error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
	--	end
    --end
    pushOver()

    LOG("RpcAS, pid=%d, func=%s", map, name)
end


local function sendToSock( rpc, sockid, name,  ... )
    local rf = rpc.remoteF[name]
   	if not rf then
		error(string.format("can't find remote function named %s",name))
		return nil 
	end
	
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		error(string.format("expected %d arguments, but passed in %d",#rf.args,#arg))
	end

    --local NET_SEND_TO_SCK = 730939457
    pushHead(_G.GateSid, 0, 730939457 )
    pushInt( sockid )
    pushInt( rf.id )

    push_args( rf.args, arg )

    --for i, v in ipairs(arg) do
    --    local t = rf.args[i].t
	--	if t and isTypeOf(i,t,v) then
	--		RpcType[t]._write( packet, v )
	--	else
	--		error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
	--	end
    --end
    pushOver()
end

local function callRpc( rpc, name, plA, ... )
    local rf = rpc.remoteF[name]
   	if not rf then
		error(string.format("can't find remote function named %s",name))
		return nil 
	end
	
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		error(string.format("expected %d arguments, but passed in %d",#rf.args,#arg))
	end

    if rpc.mode == "server"  then
        if plA.pid then
            if not plA.gid then 
                --WARN("callRpc, name=%s, pid=%d, no gid", name, plA.pid)
                return 
            end
            pushHead(_G.GateSid, plA.pid, rf.id)
        else
            if not _G.GateSid then return end

            local num = #plA
            if num == 0 then return end
            pushHead(_G.GateSid, 0, 15) --gNetPt.NET_SEND_MUL
            pushInt( num )

            for _, pid in ipairs( plA ) do
                pushInt( pid )
            end
            pushInt(rf.id)
        end
    else
        pushHead2s(plA.gid or _G.GateSid, rf.id)
    end

    push_args( rf.args, arg )

    --for i, v in ipairs(arg) do
    --    local t = rf.args[i].t
    --    if t and isTypeOf(i,t,v) then
	--		RpcType[t]._write( packet, v, 1, rf.args[i].d )
	--	else
	--		error(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
	--	end
    --end


    pushOver()

    LOG("RpcS, pid=%d, func=%s", plA.pid or 0, name)
end


local mt = {
    __index = function( table, key )
        return function(rpc, ...)
            --local packet = rpc:makeRpc(key,...)
            --Server.Send(packet)
            callRpc(rpc, key, ...)
            --rpc:callRpc(key, ...)
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
    ins.sendToSock = sendToSock
    ins.debugListAllRpc = debugListAllRpc
    ins.parseFunction = parseFunction
    setmetatable(ins, mt)
    return ins
end

return new()


