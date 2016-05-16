
package.path = package.path..";./?.lua"
local msgserver = require "msgserver"
local crypt = require "crypt"
local skynet = require "skynet"
local json = require "json"

local loginservicea     --登录服务
local room= {all=0,}          --集体服务 
local pool_agent = {}   --个体服务

local server = {}
local users = {}
local username_map = {}
local internal_id = 0

function agent_add(num)
    for n = 1,num do
	    pool_agent[#pool_agent+1]= {name=0,agent=skynet.newservice "msgagent"}
    end

end

function server.login_handler(uid, secret)
	if users[uid] then
		error(string.format("%s is already login", uid))
	end

	internal_id = internal_id + 1
	local id = internal_id	-- don't use internal_id directly
    lxz(uid)
    lxz(id)
    lxz(servername)
	local username = msgserver.username(uid, id, servername)

	-- you can use a pool to alloc new agent
    lxz(username)

	local u = {
		username = username,
		uid = uid,
		subid = id,
	}

	for k,v in pairs(pool_agent) do
        if v.namne == 0 then
            u.agent_id = k 
            v.name = u.username
            break;
        end
    end


	-- trash subid (no used)
	skynet.call(agent, "lua", "login", uid, id, secret)

	users[uid] = u
	username_map[username] = u

	msgserver.login(username, secret)

	-- you should return unique subid
	return id
end

-- call by agent
function server.logout_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		msgserver.logout(u.username)
		users[uid] = nil
		username_map[u.username] = nil
		skynet.call(loginservice, "lua", "logout",uid, subid)
	end
end

-- call by login server
function server.kick_handler(uid, subid)
	local u = users[uid]
	if u then
		local username = msgserver.username(uid, subid, servername)
		assert(u.username == username)
		-- NOTICE: logout may call skynet.exit, so you should use pcall.
		pcall(skynet.call, u.agent, "lua", "logout")
	end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

-- call by self (when recv a request from client)
function server.request_handler(fd,name, msg)
    msg = json.decode(msg)
    msg = skynet.call("room.all", "lua", "client",fd,table.unpack(msg))
    lxz(msg)
    return json.encode(msg)

    --return skynet.tostring(skynet.rawcall("room.all", "client",msg))
end

-- call by self (when gate open)
function server.register_handler(name)
    servername = name
    agent_add(1)
    loginservice = skynet.newservice("logind")--加密登录
    room.all = skynet.newservice("room","room.all")
    skynet.call("room.all", "lua", "start")
	skynet.call(loginservice, "lua", "register_gate", servername, skynet.self())
end

msgserver.start(server)

