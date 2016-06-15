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
    if self.num < 1 then
        local co = coroutine.running()
        table.insert(dbmng.pending, co)
        return coroutine.yield("waitdb")
    end

    policy = policy or math.random(64)

    local idx = (policy % #self.idxMap) + 1
    local t = self.idxMap[ idx ]
    return t.db
end

function tryOne(self, policy)
    if self.num < 1 then return false end
    policy = policy or math.random(64)
    local idx = (policy % #self.idxMap) + 1
    local t = self.idxMap[ idx ]
    return t.db
end

function getByTips(self, tips)
    for _, t in pairs(self.sckMap) do
        if t.tips == tips then return t.db end
    end
end

function getGlobal(self)
    return getByTips(self, "Global")
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

