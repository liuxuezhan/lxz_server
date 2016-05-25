local skynet = require "skynet"
local json = require "json"
local socket = require "socket"

local server_id,id = ...
server_id = tonumber(server_id)--分区id
id = tonumber(id)--房间号id
local conf=_conf.server[server_id] 

local _online={}--玩家在线列表

data = {}
del = {}

function do_load(mod)
    package.loaded[ mod ] = nil
    require( mod )
    print("load module", mod)
end

function init()
    __mt_rec = {
        __index = function (self, recid)
            local t = self.__cache[ recid ]
            if t then
                self.__cache[ recid ] = nil
                t._n_ = nil
            else
                t = {}
            end
            self[ recid ] = t
            return t
        end
    }
    __mt_tab = {
        __index = function (self, tab)
            local t = { __cache={} }
            setmetatable(t, __mt_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(data, __mt_tab)


    __mt_del_rec = {
        __newindex = function (t, k, v)
            data[ t.tab_name ][ k ]._a_ = 0
        end
    }
    __mt_del_tab = {
        __index = function (self, tab)
            local t = {tab_name=tab}
            setmetatable(t, __mt_del_rec)
            self[ tab ] = t
            return t
        end
    }
    setmetatable(del, __mt_del_tab)

end


local function write( fd, text)
    local ok  = pcall(socket.write,fd, json.encode(text).."\n")
    if not ok then
		skynet.error(string.format("socket(%d) write fail", fd))
    end
end

local  function save_db()
    skynet.timeout(10, function() 
        if next(data) then
            lxz(data)
            skynet.send(conf.db[1].name, "lua", json.encode(data))--不需要返回
            for k, v in pairs(data) do
                rawset(data, k,nil )
            end
            lxz(data)
        end
        save_db()
    end)
end
save_db()
init()

skynet.start(function()
    require "skynet.manager"	-- import skynet.register
    skynet.register(conf.room[id].name) --注册服务名字便于其他服务调用
    do_load("ply")
    ply.load(conf.db[1])--本线程加载

    skynet.dispatch("lua", function(session, source, fd,pid,msg_id,...)
            _online[pid]=fd
            local ret = ply.dispath(pid,msg_id,...)
            if ret ~=0 then
                for pid, d in pairs(ret) do
                    write(_online[pid],d)
                end
            end

    end)

end)
