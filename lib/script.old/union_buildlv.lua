-- 军团建筑升级模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_buildlv:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data._id)
        if u then
            u.buildlv = data
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_buildlv[uid] = 0 
end


function get(ply)
    local l = {}
    local u = unionmng.get_union(ply.uid)
    if not u then return end
    if u.buildlv then
        l.buildlv = u.buildlv.data 
    end
    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        get_cons(ply,v)
    end
    l.log = ply._union.buildlv

    return l 
end

function random_cons(d)
    local t = {}
    for i=1, #d do
       t[i]=d[i][2] 
    end
    local cur = t_random(t)
    return d[cur][1],d[cur][3]
end

function get_cons(ply,mode)
    local u = unionmng.get_union(ply.uid)
    if not u then return end
    local l = get_buildlv(ply.uid, mode)
    local c = resmng.get_conf("prop_union_buildlv",l.id )
    
    if not ply._union.buildlv[mode] then
        ply._union.buildlv[mode] ={ mode=mode,tm=0,} 
    end
    if can_date(ply._union.buildlv[mode].tm) then
        local i = {}
        if not  u.god then
            return
        end 
        local god = resmng.get_conf("prop_union_god",u.god.propid )
        if not god then
            return
        end
        if god.Mode == CULTURE_TYPE.EAST then
            i=random_cons(c.ChinaCons)
        elseif god.Mode == CULTURE_TYPE.WEST then
            i=random_cons(c.PersiaCons)
        elseif god.Mode == CULTURE_TYPE.SOUTH then
            i=random_cons(c.ArabCons)
        elseif god.Mode == CULTURE_TYPE.NORTH then
            i=random_cons(c.SlavicCons)
        else
            return 
        end
        ply._union.buildlv[mode].cons=i
        gPendingSave.union_member[ply.pid] = ply._union.buildlv
    end
    return ply._union.buildlv[mode].cons
end

function get_buildlv(uid, mode)
    local u = unionmng.get_union(uid)
    if not u then return end

    if not u.buildlv then
        u.buildlv={_id=u._id,data={}}
        gPendingSave.union_buildlv[u.uid] = u.buildlv
    end

    for _, v in pairs(u.buildlv.data or {}) do
        local c = resmng.get_conf("prop_union_buildlv",v.id)
        if c.Mode == mode then
            return v
        end
    end

    local conf = resmng.get_conf("prop_union_buildlv",(mode*1000+1))
    if not conf then return end
    local data = {
        id = conf.ID,
        exp = 0,
    }
    table.insert(u.buildlv.data ,data)
    return data
end

function can(ply, mode)
    local u = unionmng.get_union(ply.uid)
    if not u then return false end

    if ply._union.buildlv then
        return false
    end

    local v = ply._union.buildlv[mode]
    if not v then return false end
    
    if v and not can_date(v.log.tm) then
        return false
    end

    local i = ply._union.buildlv[mode].cons
    if ply:get_item_num(i[1]) < i[2] then
        return false
    end

    local lv = get_buildlv(ply.uid,mode)
    if not lv then return false end

    local nc = resmng.get_conf("prop_union_buildlv",lv.id + 1)
    if not nc then return false end

    return true
end

function add_buildlv_donate(ply, mode)
    if not can(ply,mode) then return false end
    local u = unionmng.get_union(ply.uid)
    local c = resmng.get_conf("prop_union_buildlv",b.id)

    local cons = ply._union.buildlv[mode].cons
    if not ply:dec_item_by_item_id(cons[1],cons[2],VALUE_CHANGE_REASON.UNION_BUILDLV) then
        return false
    end
    local b = get_buildlv(ply.uid,mode)
    ply:inc_item(b.BonusID, 1, VALUE_CHANGE_REASON.UNION_BUILDLV )

    b.exp = b.exp + c.DonateExp
    if b.exp >= c.UpExp then
        local nc = resmng.get_conf("prop_union_buildlv",b.id+1)
        b.exp = 0
        b.id = nc.ID
        u:notifyall("buildlv", resmng.OPERATOR.UPDATE, b)
    end

    ply._union.buildlv[mode].tm = gTime
    gPendingSave.union_member[ply.pid] = ply._union.buildlv
    gPendingSave.union_buildlv[ply.uid] = u.buildlv
    task_logic_t.process_task(ply, TASK_ACTION.UNION_SHESHI_DONATE, 1)

    local l = {}
    l.buildlv = u.buildlv.data 
    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        get_cons(ply,v)
    end
    l.log = ply._union.buildlv
    return l
end


