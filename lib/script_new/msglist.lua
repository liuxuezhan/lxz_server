module("msglist")
_mt_msglist = {__index = msglist}
g_msglists = {}

function new(what, max, save)
    max = max or 100
    local t = {_id=what, sn=0, max=max, msg={}, save=save}
    if save then
        local db = dbmng:getOne(1)
        db.msglist:insert(t)
    end
    g_msglists[ what ] = t
    return setmetatable(t, _mt_msglist)
end

function get(what)
    return g_msglists[ what ]
end


function msg_add(self, msg)
    self.sn = self.sn + 1
    local info = {self.sn, gTime, msg}
    table.insert(self.msg, info)
    while #self.msg > self.max do
        table.remove(self.msg, 1)
    end

    if self.save then
        local db = dbmng:getOne(1)
        db.msglist:update({_id=msg._id}, { ["$push"] = { ["msg"] = info, ["$slice"] = self.max } } )
    end
    return info
end


function msg_load_new(self, sn, count)
    local msgs = self.msg
    local total = #msgs
    if total < 1 then return {} end
    local idx

    if sn > 0 then idx = sn - msgs[1][1] + 1 
    else idx = total - count end

    if idx < 0 then idx = 0 end

    local infos = {}
    for i = idx + 1, total, 1 do
        if msgs[ i ] then
            table.insert(infos, msgs[i])
            count = count - 1
            if count == 0 then break end
        else
            break
        end
    end
    return infos 
end

function msg_load_old(self, sn, count)
    local msgs = self.msg
    local total = #msgs
    if total < 1 then return {} end

    local idx = sn - msgs[1][1] + 1
    if idx < 1 then return {} end
    if idx > total then return {} end

    local infos = {}
    for i = idx - 1, 1, -1 do
        if msgs[ i ] then
            table.insert(infos, 1, msgs[i])
            count = count - 1
            if count <= 0 then break end
        else
            break
        end
    end
    return infos 
end

function load_from_db()
    local db = dbmng.getOne(1)
    local info = db.msglist:find({})
    local have = {}
    while info:hasNext() do
        local m = info:next()
        setmetatable(m, msglist)
        g_msglists[ m._id ] = m
    end
end

