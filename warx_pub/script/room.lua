module(..., package.seeall)

local cid=1000--当前最大id
local _d={}--战争双方军队
local op={}--_d数据修改标志

function load()
    local db = dbmng:getOne()
    local info = db.room:find({})
    while info:hasNext() do
        local v = info:next()
        _d[v._id]=v
        if tonumber(v._id) > cid then
            cid = tonumber(v._id)
        end
    end
    return
end

function check_pending()--帧结尾统一保存数据库
    if next(op) then 
        local db = dbmng:tryOne(1)
        if not db then return end
        for id, v in pairs(op) do
            db.room:update({_id=id},{["$set"]=k })
            op[id]=nil
        end
    end
end

function load_fight(result,pid)--集结战斗一级界面数据
    local p = getPlayer(pid)
    local uid=p and p:union().uid
    for k, room in pairs(_d) do
        table.insert(result.val, get_info(k))
    end
end

function get_info(rid)
    local r = _d[rid]
    local mass = troop_t.get_by_tid(r.A.tid)
    if mass then
        r.state = mass.state
        r.action = mass.action
        r.tmStart= mass.tmStart  
        r.tmOver=mass.tmOver    
    end

    for k, v in pairs(r.A.plys) do
        local p = getPlayer(v.pid)
        r.A.plys[k].name = p.account
        r.A.plys[k].lv = p.lv
        r.A.plys[k].photo = p.photo
        r.A.plys[k].count = 0 

        local t = p:get_troop(v.troop)
        if t then
            r.A.plys[k].state =  t.state
            r.A.plys[k].tmStart = t.tmStart
            r.A.plys[k].tmOver = t.tmOver
            for _, o in pairs(t.arms or {}) do
                r.A.plys[k].count = r.A.plys[k].count + (o.num or 0) 
            end
        end

    end

    local dp = get_ety(r.D.eid)
    r.D.plys= {}
    if is_ply(dp) then

        local t = {}
        t.name = dp.account
        t.lv = dp.lv
        t.photo = dp.photo
        t.count = 0 
        for _, o in pairs(dp.arms or {}) do
            t.count = t.count + o[2] 
        end
        table.insert(r.D.plys,t)

        for k, t in pairs(dp.aid) do
            local p = getPlayer(t.pid)
            t.name = p.account
            t.lv = p.lv
            t.photo = p.photo
            t.count = 0 
            for _, o in pairs(t.arms or {}) do
                t.count = t.count + (o.num  or 0)
            end
            table.insert(r.D.plys,t)
        end
    elseif is_monster(dp) then
        table.insert(r.D.plys,{dp.propid,dp.arms})
    elseif is_union_building(dp) then
        for k, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
            local p = getPlayer(v.pid)
            local t = p:get_troop(v.idx)
            t.name = p.account
            t.lv = p.lv
            t.photo = p.photo
            t.count = 0 
            for _, o in pairs(t.arms or {}) do
                t.count = t.count + (o.num  or 0)
            end
            table.insert(r.D.plys,t)
        end
    end

    -- mark, modify every time ?
    return r
end

function get_troop(rid,pid)
    if not _d[rid] then return end
    local p = getPlayer(pid)
    for k, v in pairs(_d[rid].A.plys) do
        if v.pid and v.pid == pid then
            local tr = p:get_troop(v.troop) or {}
            return tr.arms
        end
    end


    local dp = get_ety(r.D.eid)
    if dp.pid == pid then
        return dp.arms
    end
    if is_ply(dp) then
        for _, v in pairs(dp.aid or {}) do
            if v.pid == pid then
                return v.arms
            end
        end
    elseif is_union_building(dp) then
        for k, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
            local p = getPlayer(v.pid)
            local t = p:get_troop(v.idx)
            return arms
        end
    end

end

function get_room(rid)
    return _d[rid]
end

function new(at,m)--新建

    local mass = m or at
    local p = getPlayer(at.pid)
    local u = p:union() or {} 
    local dp = get_ety(mass.did)

    -- mark, maybe duplicate when restart 
    cid = cid + 1
    mass.tid = cid
    _d[cid]= { 
        _id =cid,
        did = mass.did,
        action = mass.action,
        state = mass.state,
        tmStart= mass.tmStart,  
        tmOver=mass.tmOver,    
        idx=mass.idx,    
        A = {
            uid=u.uid or 0,
            uname=u.name or 0,
            uflag=u.flag or 0, 
            ualias=u.alias or 0,    
            tid=mass._id,
            x=mass.sx,
            y=mass.sy,
            plys={
                {pid=at.pid,troop=at.idx,}, 
            },
        },
        D = {
            eid = mass.did, 
            uid= 0,
            uname= 0,
            uflag= 0, 
            ualias=0,    
            x=mass.dx,
            y=mass.dy,

        },

    }

    if is_ply(dp) then
        --加载被攻击方的援助
        local du = dp:union()
        if du then
            _d[cid].D.uid= du.uid 
            _d[cid].D.uname= du.name 
            _d[cid].D.uflag= du.flag 
            _d[cid].D.ualias= du.alias 
        end
    elseif is_union_building(dp) then
        _d[cid].D.uid= dp.uid 
    else
    end

    dbmng:getOne().room:insert(_d[cid])
    broadcast(cid,"fight", resmng.OPERATOR.ADD)

end

function back(rid)

    local p = getPlayer(_d[rid].A.plys[1].pid)
    local tr = p:get_troop(_d[rid].idx)
    p:troop_back(tr)

    for _, v in pairs(_d[rid].A.plys) do
        p = getPlayer(v.pid)
        tr = p:get_troop(v.troop)
        p:troop_back(tr)
    end

    del(_d[rid].A.plys[1])
end

function add_A(rid,at)
    table.insert(_d[rid].A.plys, {pid=at.pid, troop=at.idx,})
    op[rid]=_d[fid]
    broadcast(rid,"fight", resmng.OPERATOR.UPDATE)
end

function add_D(pid,at)
    for k, room in pairs(_d) do
        if at.did == room.D.eid then
            local dp = getPlayer(at.pid)
            local du = dp:union()
            if du then
                _d[k].D.uid= du.uid 
                _d[k].D.uname= du.name 
                _d[k].D.uflag= du.flag 
                _d[k].D.ualias= du.alias 
            end
            broadcast(k,"fight", resmng.OPERATOR.UPDATE)
        end
    end
end

function del(at)
    if at.action == resmng.TroopAction.Aid then
        del_D(at)
    else
        del_A(at)
    end
end

function del_A(at)
    for id, room in pairs(_d) do
        if room.A then
            for k, v in pairs(room.A.plys ) do
                if at.pid == v.pid and v.troop == at.idx then
                    if k==1 then
                        broadcast(id,"fight", resmng.OPERATOR.DELETE)
                        _d[id] = nil  
                        dbmng:getOne().room:delete({_id=id})
                    else
                        _d[id].A.plys[k]=nil
                        op[id]=_d[id]
                        broadcast(id,"fight", resmng.OPERATOR.UPDATE)
                    end
                    return
                end
            end
        end

    end
end


function del_D(at)
    for id, room in pairs(_d) do
        if at.eid == room.D.eid then
            broadcast(id,"fight", resmng.OPERATOR.UPDATE)
        end
    end
end

function broadcast(rid,what, mode)--双方军团广播
    local pids = {}
    local room = _d[rid]

    if not room then return end

    if room.A.uid ~=0 then 
        local u = unionmng.get_union(room.A.uid)
        u:notifyall(what, mode, {rid=rid})
    end

    if room.D.uid ~=0 then 
        local u = unionmng.get_union(room.D.uid)
        u:notifyall(what, mode, {rid=rid})
    end

end

function troop_broadcast(t,what, mode)
    for k,room in pairs(_d) do
        if t._id == room.A.tid then
            broadcast(k,what, mode)
            return
        end

        for _,v in pairs(room.A.plys) do
            if v.pid == t.pid and v.troop == t.idx then
                broadcast(k,what, mode)
                return 
            end
        end

        local dp = get_ety(room.D.eid)
        if is_ply(dp) then
            for _,v in pairs(dp.aid) do
                if v.pid == t.pid and v.idx == t.idx then
                    broadcast(k,what, mode)
                    return 
                end
            end
        elseif is_union_building(dp) then
            for k, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
                if v.pid == t.pid and v.idx == t.idx then
                    broadcast(k,what, mode)
                    return 
               end 
            end
        end

    end
end
