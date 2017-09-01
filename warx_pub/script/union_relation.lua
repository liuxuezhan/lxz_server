-- 军团外交模块
module(..., package.seeall)
function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_relation:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then
            if not u.relation then u.relation = { _id=u.uid, log={}  } end
            for k, v in pairs(d or {} ) do
               if type(k)=="number" then u.relation[v.uid] = v end
            end
        end
    end

    local info = db.union_relation_log:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u and u.relation then
            for k, v in pairs(d or {} ) do
               if type(k)=="number" then u.relation.log[k] = v end
            end
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_relation[uid] = 0
    gPendingDelete.union_relation_log[uid] = 0
end


function list(u)
    local l = {list={},log={}}

    if u.relation then
        for k, v in pairs( u.relation or {}) do
            if type(k) == "number"  then
                local d = unionmng.get_union(v.uid)
                if d then
                    check(u,d) 
                    local t = d:get_info() 
                    t.relation = copyTab(v) --todo, no need copy
                    table.insert(l.list,t)
                end
            end
        end

        for k, v in pairs( u.relation.log or {}) do
            if (gTime-v.tm)> 60*60*24*7 then
                u.relation.log[k] = nil 
                dbmng:getOne().union_relation_log:update( {_id=u.uid}, { ["$unset"]={ [k]='', } }, false,true )
            else
                table.insert(l.log,v)
            end
        end


    end
    return l
end

function add(troop)
    local ply = getPlayer(troop.owner_pid)
    if not ply then return  end

    if not is_ply(troop.target_eid) then return end

    local dest = get_ety(troop.target_eid)
    if not dest then return  end
    local u = unionmng.get_union(ply:get_uid())
    local d = unionmng.get_union(dest.uid)

    if u and d then
        local log = check(u,d)
        u.relation[d.uid].num =  u.relation[d.uid].num + 1
        u.relation[d.uid].tm_add = gTime
        gPendingSave.union_relation[u.uid][d.uid] = u.relation[d.uid]
        u:notifyall(resmng.UNION_EVENT.RELATION, resmng.UNION_MODE.UPDATE, { uid = d.uid, data=u.relation[d.uid], log={log}, })

        log = check(d,u)
        d.relation[u.uid].num =  d.relation[u.uid].num + 1
        d.relation[u.uid].tm_add = gTime
        gPendingSave.union_relation[d.uid][u.uid] = d.relation[u.uid]
        d:notifyall(resmng.UNION_EVENT.RELATION, resmng.UNION_MODE.UPDATE, { uid = u.uid, data=d.relation[u.uid], log={log}, })
    end
end

function set(ply,uid,type)
    if type >= UNION_RELATION.MAX then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(ply, "Relation") then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(ply:get_uid())
    local d = unionmng.get_union(uid)

    check(u,d)
    u.relation[d.uid].type =  type
    u.relation[d.uid].tm =  gTime
    gPendingSave.union_relation[u.uid][d.uid] = u.relation[d.uid]
    local log = {name=ply.name,type=type,u_name=d.name,tm=gTime}
    u.relation.log[gTime] = log 
    gPendingSave.union_relation_log[u.uid][log.tm] = log 
    u:notifyall(resmng.UNION_EVENT.RELATION, resmng.UNION_MODE.UPDATE, { uid = d.uid, data=u.relation[d.uid], log={log}, })
end


function check(u,d)
    local log 
    if u and d and (d.uid ~= u.uid) then
        if not u.relation then u.relation = { _id=u.uid, log={} } end
        if not u.relation[d.uid] then
            u.relation[d.uid]= { uid=d.uid,num=0, tm=0, tm_add=gTime, type = UNION_RELATION.NORMAL }
        end
        if can_month(u.relation[d.uid].tm) then
            if not can_month(u.relation[d.uid].tm_add) then
                if u.relation[d.uid].num > 2 and u.relation[d.uid].type ~= UNION_RELATION.ENEMY then
                    u.relation[d.uid].type = UNION_RELATION.ENEMY
                    gPendingSave.union_relation[u.uid][d.uid] = u.relation[d.uid]

                    log = { type=u.relation[d.uid].type, u_name=d.name,tm=gTime }
                    u.relation.log[gTime] = log 
                    gPendingSave.union_relation_log[u.uid][log.tm] = log 
                end
            else
                if u.relation[d.uid].num == 0 then
                    if u.relation[d.uid].type == UNION_RELATION.ENEMY then
                        u.relation[d.uid].type = UNION_RELATION.NORMAL

                        log = {type=u.relation[d.uid].type,u_name=d.name,tm=gTime}
                        u.relation.log[gTime] = log 
                        gPendingSave.union_relation_log[u.uid][log.tm] = log 
                    end
                end
                u.relation[d.uid].num = 0
                gPendingSave.union_relation[u.uid][d.uid] = u.relation[d.uid]
            end

            if u.relation[d.uid].num < 2 and u.relation[d.uid].type ~= UNION_RELATION.NORMAL then
                u.relation[d.uid].type = UNION_RELATION.NORMAL
                u.relation[d.uid].num = 0
                gPendingSave.union_relation[u.uid][d.uid] = u.relation[d.uid]

                log = {type=u.relation[d.uid].type, u_name=d.name,tm=gTime}
                u.relation.log[gTime] = log 
                gPendingSave.union_relation_log[u.uid][log.tm] = log 
            end
        end
    end
    return log
end


