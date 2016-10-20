-- 军团留言模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_word:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then
            u.word = d
            u.wid = 0 --当前留言的最大序号
            for _, v in pairs(u.word.log or {}) do
                if v.wid > u.wid then
                    u.wid=v.wid
                end
            end
        end
    end
end

function check(u)
    local out_num = 0
    local in_num = 0
    local id = 0
    local tm = math.huge
    for k, v in pairs(u.word.log or {}) do
        if v.type ==0 then
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
        u.word.log[id]=nil
        gPendingSave.union_word[u.uid] = u.word
    end

    if in_num == 100  then
        return false
    end

    return true
end

function list(pid,u)
    if not u.word then return {} end
    local list ={}
    for k, v in pairs(u.word.log or {}) do
        local d = copyTab(v)
        local p = getPlayer(v.pid)
        d.word = nil
        d.name = p.name
        if v.type ==0 then
            table.insert(list,d)
        elseif u._members[pid] then
            table.insert(list,d)
        end
    end
    return list
end

function get(p,u,wid)
    if not u.word then return end
    for k, v in pairs(u.word.log or {}) do
        if v.wid == wid then
            if v.type ==0 then
                return  v
            elseif u._members[p.pid] then
                return  v
            end
        end
    end
    return {}
end

function add(p,uid,title,word)
    if p.uid == uid then
        if not union_t.is_legal(p, "Writeinwords") then return resmng.E_DISALLOWED end
    end
    local u = unionmng.get_union(uid)
    if not u.word then
        u.word={_id=uid,log={}}
    end
    if not check(u) then return  0 end
    u.wid = (u.wid or 0) + 1
    local type = 0
    if u._members[p.pid] then
        type = 1
    end
    table.insert(u.word.log,{wid=u.wid,pid=p.pid,title=title,word=word,tm=gTime,type=type})
    gPendingSave.union_word[uid] = u.word
    return {wid=u.wid,pid=p.pid,name=p.name,title=title,word=word,tm=gTime,type=type}
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_word[uid] = 0
end

function del(p,wid)
    local u = unionmng.get_union(p:get_uid())
    if not u.word then return end
    for k, v in pairs(u.word.log or {}) do
        if v.wid == wid then
            if  p.pid ~= v.pid then
                if not union_t.is_legal(p, "Updateinwords") then return resmng.E_DISALLOWED end
            end
            u.word.log[k]= nil
            gPendingSave.union_word[p.uid] = u.word
            return
        end
    end
end

function update(p,wid,title,word)
    local u = unionmng.get_union(p:get_uid())
    if not u.word then return end
    for k, v in pairs(u.word.log or {}) do
        if v.wid == wid then
            if  p.pid ~= v.pid then
                if not union_t.is_legal(p, "Updateinwords") then return resmng.E_DISALLOWED end
            end
            u.word.log[k].pid = p.pid
            u.word.log[k].title= title
            u.word.log[k].word = word
            u.word.log[k].tm = gTime
            gPendingSave.union_word[u.uid] = u.word
            return
        end
    end
end

function top(p,wid,flag)
    local u = unionmng.get_union(p:get_uid())
    if not u.word then return end
    for k, v in pairs(u.word.log or {}) do
        if v.wid == wid then
            if not union_t.is_legal(p, "Updateinwords") then return resmng.E_DISALLOWED end
            if flag == 1 then
                u.word.log[k].tm_top = gTime
            else
                u.word.log[k].tm_top = nil
            end
            gPendingSave.union_word[u.uid] = u.word
            return
        end
    end
end

















