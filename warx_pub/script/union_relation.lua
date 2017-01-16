-- 军团外交模块
module(..., package.seeall)
function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_relation:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then
            u.relation = {_id=u.uid,data={},log=(d.log or {}), }
            for _, v in pairs(d.data or {} ) do
               u.relation.data[v.uid] = v
            end
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_relation[uid] = 0
end

function init(u,d)
    if not u then return end
    if not d then return end
    if (d.uid ~= u.uid) and (not d:is_new()) and (not u:is_new()) then
        if not u.relation then 
            u.relation = {_id=u.uid,data={},log={} } 
        end
        if not u.relation.data[d.uid] then
            u.relation.data[d.uid]= { uid=d.uid,num=0,tm=0,tm_add=gTime }
            u.relation.data[d.uid].type = UNION_RELATION.NORMAL
        end
        return true 
    end
end

function change(u,d)
    if not u then return end
    if not d then return end
    local log = {}
    if (d.uid ~= u.uid) and (not d:is_new()) and (not u:is_new()) then
        if not init(u,d) then return end
        if can_month(u.relation.data[d.uid].tm) then
            if not can_month(u.relation.data[d.uid].tm_add) then
                if u.relation.data[d.uid].num > 2 and u.relation.data[d.uid].type ~= UNION_RELATION.ENEMY then
                    u.relation.data[d.uid].type = UNION_RELATION.ENEMY
                    table.insert(log,{type=u.relation.data[d.uid].type,u_name=d.name,tm=gTime})
                end
            else
                if u.relation.data[d.uid].num == 0 then
                    if u.relation.data[d.uid].type == UNION_RELATION.ENEMY then
                        u.relation.data[d.uid].type = UNION_RELATION.NORMAL
                        table.insert(log,{type=u.relation.data[d.uid].type,u_name=d.name,tm=gTime})
                    end
                end
                u.relation.data[d.uid].num = 0
            end

            if u.relation.data[d.uid].num < 2 and u.relation.data[d.uid].type ~= UNION_RELATION.NORMAL then
                u.relation.data[d.uid].type = UNION_RELATION.NORMAL
                u.relation.data[d.uid].num = 0
                table.insert(log,{type=u.relation.data[d.uid].type,u_name=d.name,tm=gTime})
            end
        end

        --[[
        if  (gTime - u.relation.data[d.uid].tm_add) > 60*60*24*3 then
        u.relation.data[d.uid].tm_add = gTime
            u.relation.data[d.uid].num =  u.relation.data[d.uid].num - math.ceil(u.relation.data[d.uid].num/10)
        end
        --]]
    end
    return log
end

function list(u)
    local l = {list={},log={}}

    if u.relation then
        for uid, v in pairs( u.relation.data or {}) do
            local d = unionmng.get_union(v.uid)
            if d then
                save(u,d) 
                local t = d:get_info() 
                t.relation = copyTab(v)
                table.insert(l.list,t)
            end
        end

        for k, v in pairs( u.relation.log or {}) do
            if (gTime-v.tm)> 60*60*24*7 then
                v=nil
                gPendingSave.union_relation.log = u.relation.log
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

    if not is_ply(troop.target_eid) then
        return
    end
    local dest = get_ety(troop.target_eid)
    if not dest then return  end
    local u = unionmng.get_union(ply:get_uid())
    local d = unionmng.get_union(dest.uid)

    if init(u,d) then
        u.relation.data[d.uid].num =  u.relation.data[d.uid].num + 1
        u.relation.data[d.uid].tm_add = gTime
        union_relation.save(u,d) 
    end

    if init(d,u) then
        d.relation.data[u.uid].num =  d.relation.data[u.uid].num + 1
        d.relation.data[u.uid].tm_add = gTime
        union_relation.save(d,u) 
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

    if union_relation.init(u,d) then
        u.relation.data[d.uid].type =  type
        u.relation.data[d.uid].tm =  gTime
        local log = {name=ply.name,type=type,u_name=d.name,tm=gTime}
        save(u,d,log)
    end
end

function save(u,d,log)
    local logs = {}
    if log then
        table.insert(u.relation.log,log)
        table.insert(logs,log)
    end

    local ret = union_relation.change(u,d) 
    for _, v in pairs( ret or {}) do
        table.insert(u.relation.log,v)
        table.insert(logs,v)
    end
    gPendingSave.union_relation[u.uid].data = u.relation.data
    u:notifyall(resmng.UNION_EVENT.RELATION, resmng.UNION_MODE.UPDATE, {uid = d.uid,data=u.relation.data[d.uid],log=logs })
end








