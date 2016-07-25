-- 军团外交模块
module(..., package.seeall)
function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_relation:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then
            u.relation = {_id=u.uid,data={},log=d.log}
            for _, v in pairs(d.data) do
               u.relation.data[v.uid] = v
            end
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_relation[uid] = 0 
end

function get(u,d)
    if not u then return end
    if not d then return end
    if (d.uid ~= u.uid) and (not d.new_union_sn) and (not u.new_union_sn) then
        if not u.relation then u.relation = {_id=u.uid,data={},log={} } end
        if not u.relation.data[d.uid] then
            u.relation.data[d.uid]= { uid=d.uid,num=0,tm=0,tm_add=gTime }
            if u.language == d.language then
                u.relation.data[d.uid].type = UNION_RELATION.FRIEND
            else
                u.relation.data[d.uid].type = UNION_RELATION.NORMAL
            end
        end

        if (gTime - u.relation.data[d.uid].tm) > 60*60*24*14 then
            if not can_month(u.relation.data[d.uid].tm_add)then
                if u.relation.data[d.uid].num > 9 then
                    u.relation.data[d.uid].type = UNION_RELATION.DEAD
                elseif u.relation.data[d.uid].num > 1 then
                    u.relation.data[d.uid].type = UNION_RELATION.ENEMY
                end
                table.insert(u.relation.log,{type=u.relation.data[d.uid].type,u_name=d.name,tm=gTime})
            else
                u.relation.data[d.uid].num = 0  
            end
        end

--[[
        if  (gTime - u.relation.data[d.uid].tm_add) > 60*60*24*3 then
            u.relation.data[d.uid].tm_add = gTime
            u.relation.data[d.uid].num =  u.relation.data[d.uid].num - math.ceil(u.relation.data[d.uid].num/10)
        end
        --]]

        return u.relation.data[d.uid]
    end
end

function list(u)
    local l = {list={},log={}}
    for uid, v in pairs( unionmng._us or {}) do
        local t = copyTab(union_relation.get(u,v))
        if t  then
            local u = unionmng.get_union(t.uid)
            if u then
                t.info = u:get_info()
                table.insert(l.list,t)
            end
        end
    end

    if u.relation then
        for k, v in pairs( u.relation.log or {}) do
            if (gTime-v.tm)> 60*60*24*7 then
                v=nil
            else
                table.insert(l.log,v)
            end
        end
    end
    gPendingSave.union_relation[u.uid] = u.relation
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

    if union_relation.get(u,d) then
        u.relation.data[d.uid].num =  u.relation.data[d.uid].num + 1
        u.relation.data[d.uid].tm_add = gTime 
        gPendingSave.union_relation[u.uid] = u.relation
    end

    if union_relation.get(d,u) then
        d.relation.data[u.uid].num =  d.relation.data[u.uid].num + 1
        d.relation.data[u.uid].tm_add = gTime 
        gPendingSave.union_relation[d.uid] = d.relation
    end
end

function set(ply,uid,type)
    local d = unionmng.get_union(uid)
    if not d then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
    if d.new_union_sn then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
    if type >= UNION_RELATION.MAX then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
    if not union_t.is_legal(ply, "Relation") then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
    local u = unionmng.get_union(ply:get_uid())
    if not u then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
    if u.new_union_sn then
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
    if union_relation.get(u,d) then
        u.relation.data[d.uid].type =  type
        u.relation.data[d.uid].tm =  gTime
        table.insert(u.relation.log,{name=ply.name,type=type,u_name=d.name,tm=gTime})
        gPendingSave.union_relation[u.uid] = u.relation
    end
end










