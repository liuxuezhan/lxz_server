module("dbmng", package.seeall)

idxMap = idxMap or {}
sckMap = sckMap or {}
num = num or 0
pending = pending or {}

--function conn_new(self, sock, db, tips)
function conn_new(self, host, port, dbname, sock, db, tips)
    local t = {host=host, port=port, dbname=dbname, sock=sock, db=db, status="ok", pending=nil, tips=tips}
    self.sckMap[ sock ] = t
    self.num = self.num + 1
    if not tips then
        table.insert(self.idxMap, t)
    end

    while tabNum(dbmng.pending) > 0 do
        local co = table.remove(dbmng.pending, 1)
        coroutine.resume(co)
    end
end

function getOne(self, policy)
    if not g_db_s then
        local mongo = require "lualib/mongo"

        local v  = _list.db_server1.db1 
        v.host = v.host or g_host 
        --v.host =  "192.168.100.12" 
        --v.host =  "192.168.101.223" 
        v.host =  "192.168.67.135" 
        lxz(v)
        g_db_s = mongo.client(v)
    end

    local name = "my"
    local dbname = string.format("%s_%d", name, config.Map)
    return g_db_s[dbname]
end

function tryOne(self, policy)
    return getOne(self, policy)
end

function getByTips(self, tips)
    return self:getOne(policy)
    --[[
    for _, t in pairs(self.sckMap) do
        if t.tips == tips then return t.db end
    end
    --]]
end

function getGlobal(self)
    local mongo = require "mongo" --删除warx的mongo
    local name,v  = "warx",_list.db_server1.db1 
    local db = mongo.client(v)
    return db[name]
end

function conn_close(self, sock)
    LOG("############  dbmng:conn_close, sock=%d", sock)
    for k, v in pairs(self.idxMap) do
        if v.sock == sock then
            table.remove(self.idxMap, k)
            self.sckMap[ sock ] = nil
            self.num = self.num - 1
            conn.toMongo(v.host, v.port, v.dbname, v.tips)
            return
        end
    end
end

