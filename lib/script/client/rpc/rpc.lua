local hashString = pack.hashStr
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

local function parseRpc(rpc, body)
    local rfid = pack.pullNext(body)
	local rf = rpc.localF[rfid]

	if not rf then
		error(string.format("rfid(%d) not found in LocalF", rfid))
	end

	local args={}
	for i,v in ipairs(rf.args) do
		local tm = RpcType[v.t]
		--args[i] = tm._read( packet )
		args[i] = tm._read( packet )
	end
    return rf.name, args
end


local function parseFunction( funcimpl )
   	local rf = { args = {} }
	for t,n in string.gmatch(funcimpl,"(%w+)%s+(%w+)") do
        table.insert(rf.args, {t=t, n=n})
	end
	return rf
end

local function parseProtocol( rpc, what )
    local rpcS = {}
    local rpcC = {}

    for k, v in pairs(Protocol.Server) do
        local rf = parseFunction(v)
        rf.id = hashString(k)
        rf.name = k
        rpcS[rf.id] = rf
        rpcS[k] = rf
    end

    for k, v in pairs(Protocol.Client) do
        local rf = parseFunction(v)
        rf.id = hashString(k)
        rf.name = k
        rpcC[rf.id] = rf
        rpcC[k] = rf
    end

    rpc.remoteF = rpcS
    rpc.localF = rpcC
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
    parseProtocol( rpc, what )
    parseRpcType()
    print("parse done")
end

local function callRpc( rpc, name, ... )
    local rf = rpc.remoteF[name]
   	if not rf then
		error(string.format("can't find remote function named %s",key))
		return nil
	end
	local arg={...}
	if #arg ~= #rf.args then
		for i,v in ipairs(arg) do print(i,v) end
		lxz(string.format("expected %d arguments, but passed in %d",#rf.args,#arg))
	end

    pack.pushHead(rf.id)
    for i, v in ipairs(arg) do
        local t = rf.args[i].t
		if t and isTypeOf(i,t,v) then
			RpcType[t]._write( packet, v )
		else
			lxz(string.format("bad argument %d, expected %s, but a %s",i,t,type(v)))
		end
    end

    return pack.pushOver()
end


local mt = {
    __index = function( table, key )
        return function(rpc, ...)
            return callRpc(rpc, key, ...)
        end
    end
}

local function new()
    local ins = {}
    ins.init = init
    ins.parseRpc = parseRpc
    setmetatable(ins, mt)
    return ins
end

return new()

