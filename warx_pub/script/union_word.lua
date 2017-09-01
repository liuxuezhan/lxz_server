-- 军团留言模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_word:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d.uid)
        if u then
            u.word = u.word or { } 
            u.wid = u.wid or 0 
            u.word[d.wid] = d
            if d.wid > u.wid then u.wid = d.wid  end
        end
    end
end

function check(u)
    local out_num = 0
    local in_num = 0
    local id = 0
    local tm = math.huge
    for k, v in pairs(u.word or {}) do
        if v.type == 0 then
            out_num = out_num + 1
            if v.tm < tm then
                tm = v.tm
                id = k
            end
        else
            in_num = in_num + 1
        end
    end

    if out_num == 100  then
        local d = u.word[id]
        gPendingDelete.union_word[d._id] = 1
        u.word[id] = nil
    end

    if in_num == 100  then return false end

    return true
end

function list(pid,u)
    if not u.word then return {} end
    local list ={}
    for k, v in pairs(u.word or {}) do
        local _members = u:get_members() or {}
        local d = info(v,pid)
        if v.type ==0 then
            table.insert(list,d)
        elseif _members[pid] then
            table.insert(list,d)
        end
    end
    return list
end

function get(p,u,wid)
    if not u.word then return end
    local _members = u:get_members() or {}
    local d = u.word[wid] 
    if d.type ==0 then 
        d[p.pid] = 1
        gPendingSave.union_word[d._id][p.pid] = 1 
        return  d
    elseif _members[p.pid] then 
        d[p.pid] = 1
        gPendingSave.union_word[d._id][p.pid] = 1 
        return  d 
    end
    return {}
end

function info(d,pid)
    local v = {} 
    v.tm = d.tm
    v.pid = d.pid
    v.title = d.title
    v.type = d.type
    v.wid = d.wid
    v.word = d.word
    v.uid = d.uid
    v.tm_top = d.tm_top
    local p = getPlayer(d.pid)
    if not p then return {}  end
    v.name = p.name
    local u = unionmng.get_union(p.uid)
    if u then v.u_alias = u.alias end
    v.word = nil
    if d[pid] then  v.read = 1 
    else v.read = 0 end
    return v 
end

function add(p,uid,title,word)
    if p.uid == uid then
        if not union_t.is_legal(p, "Writeinwords") then return resmng.E_DISALLOWED end
    end
    local u = unionmng.get_union(uid)
    if not u then return end

    u.word = u.word or {} 

    if not check(u) then return  0 end
    u.wid = (u.wid or 0)   + 1
    local type = 0
    local _members = u:get_members() or {}
    if _members[p.pid] then type = 1 end
    local d = {_id=u.uid..u.wid, uid=u.uid, wid=u.wid, pid=p.pid,title=title,word=word,tm=gTime,type=type}
    d[p.pid] = 1
    u.word[d.wid] = d
    gPendingSave.union_word[d._id] = d 
    u:notifyall(resmng.UNION_EVENT.WORD, resmng.UNION_MODE.ADD,{d.wid},p )
    return info(d,p.pid)
end

function clear(uid)--删除军团时清除数据
    local u = unionmng.get_union(uid)
    if not u then return end
    for _, d in pairs(u.word or {}) do
        gPendingDelete.union_word[d._id] = 0
    end
end

function del(p,wid)
    local u = unionmng.get_union(p:get_uid())
    if not u.word then return end
    local d = u.word[wid]
    if  p.pid ~= d.pid then
        if not union_t.is_legal(p, "Updateinwords") then return resmng.E_DISALLOWED end
    end
    gPendingDelete.union_word[d._id] = 0 
    u.word[wid] = nil
    u:notifyall(resmng.UNION_EVENT.WORD, resmng.UNION_MODE.DELETE, {wid},p )
    return
end

function update(p,wid,title,word)
    local u = unionmng.get_union(p:get_uid())
    if not u.word then return end
    local d = u.word[wid]
    if  p.pid ~= d.pid then
        if not union_t.is_legal(p, "Updateinwords") then return resmng.E_DISALLOWED end
    end
    d.pid = p.pid
    d.title= title
    d.word = word
    d.tm = gTime
    for k, v in pairs( d or {}) do
        if type(k)=="number" then d[k] = nil end
    end
    gPendingInsert.union_word[d._id] = d 
    u:notifyall(resmng.UNION_EVENT.WORD, resmng.UNION_MODE.UPDATE,{d.wid},p )
    return
end

function top(p,wid,flag)
    local u = unionmng.get_union(p:get_uid())
    if not u.word then return end
    if not union_t.is_legal(p, "Updateinwords") then return resmng.E_DISALLOWED end
    local d = u.word[wid]
    if flag == 1 then d.tm_top = gTime
    else d.tm_top = nil end
    gPendingSave.union_word[d._id] = d 
    return info(d,p.pid)
end

















