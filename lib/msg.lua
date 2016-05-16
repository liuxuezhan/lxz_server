module(..., package.seeall)

local cid=1000--当前最大id
local data={}--战争双方军队
local op={}--data数据修改标志

function load()
    local db = dbmng:getOne()
    local info = db.room:find({})
    while info:hasNext() do
        local v = info:next()
        data[v._id]=v
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
        for id, _ in pairs(op) do
            if data[id] then
                db.room:update({_id=id},{["$set"]=data[id] })
                op[id]=nil
            end
        end
    end
end

function load_fight(result,pid)--集结战斗一级界面数据

    local p = getPlayer(pid)
    local uid=p and p:union().uid

    for k, room in pairs(data) do
        if room.A.uid == uid then
            for _, v in pairs(room.A.plys) do
                if pid == v.pid then
                    table.insert(result.val, get_info(k))
                end
            end
        end

        if room.D.uid == uid then
            for _, v in pairs(room.D.plys) do
                if pid == v.pid then
                    table.insert(result.val, get_info(k))
                end
            end
        end
    end

end

function get_info(rid)
    local r = data[rid]

    for k, v in pairs(r.A.plys) do
        local p = getPlayer(v.pid)
        r.A.plys[k].name = p.account
        r.A.plys[k].lv = p.lv
        r.A.plys[k].photo = p.photo

        local t = p:get_troop(v.troop)
        if t then
            r.A.plys[k].state =  t.state
            r.A.plys[k].tmStart = t.tmStart
            r.A.plys[k].tmOver = t.tmOver
        end

    end

    for k, v in pairs(r.D.plys) do
        if v.pid then
            local p = getPlayer(v.pid)
            r.D.plys[k].name = p.account
            r.D.plys[k].lv = p.lv
            r.D.plys[k].photo = p.photo

            if k == 1 then
            else
                local t = p:get_troop(v.troop)
                r.D.plys[k].state = t.state
                r.D.plys[k].tmStart = t.tmStart
                r.D.plys[k].tmOver = t.tmOver
            end
        end

    end

    return r
end

function get_troop(rid,pid)
    if not data[rid] then return end
    local t = nil
    local p = getPlayer(pid)
    for k, v in pairs(data[rid].A.plys) do
        if v.pid and v.pid == pid then
           t = p:get_troop(v.troop)
           break
        end
    end
    for k, v in pairs(data[rid].D.plys) do
        if v.pid and v.pid == pid then
           t = p:get_troop(v.troop)
           break
        end
    end
    if not t then return end
    data = t

    return data
end

function load_troop(p,idx)--集结战斗二级界面数据

    local T = troop_t.get_by_tid(_id)
    if not T then return end

    local xs = {
        id=T.idx,
    }
    if p:get_uid() == T:owner():get_uid() then
        xs.A=T:atk_detail()
        xs.D=T:def_general()
        xs.Dcnt={
            total=T:def_sum()
        }
    else
        xs.A=T:atk_general()
        xs.D=T:def_detail()
        xs.Acnt={
            total= T:atk_sum()
        }
    end
    Rpc:union_mass_info(p, xs)
end


function new(at,m)

    local mass = m or at
    local p = getPlayer(at.pid)
    local dp = get_ety(mass.did)

    cid = cid + 1
    data[cid]= { 
        _id =cid,
        did = mass.did,
        action = mass.action,
        state = mass.state,
        tmStart= mass.tmStart,  
        tmOver=mass.tmOver,    
        A = {
            uid=p:union().uid,
            uname=p:union().name,
            uflag=p:union().flag, 
            ualias=p:union().alias,    
            tid=mass._id,
            x=mass.sx,
            y=mass.sy,
            plys={
                {pid=at.pid,troop=at.idx,}, 
            },
        },
        D = {
            uid= 0,
            uname= 0,
            uflag= 0, 
            ualias=0,    
            x=mass.dx,
            y=mass.dy,

        },

    }

    if is_ply(dp) then
        data[cid].D.plys= { {pid=dp.pid}, }
        --加载被攻击方的援助
        for k, v in pairs(dp.aid) do
            table.insert(data[cid].D.plys, {pid=v.pid, troop=v.idx,})
        end

        local du = dp:union()
        if du then
            data[cid].D.uid= du.uid 
            data[cid].D.uname= du.name 
            data[cid].D.uflag= du.flag 
            data[cid].D.ualias= du.alias 
        end
    else
        data[cid].D.plys= { {eid=mass.did}, }
    end

    dbmng:getOne().room:insert(data[cid])

end

function add_A(mass,at)
    for k, v in pairs(data) do
        if v.A.tid == mass._id then
            table.insert(data[k].A.plys, {pid=at.pid, troop=at.idx,})
            --dbmng:getOne().room:update({_id=k},{["$set"]={A=data[k].A} })
            op[k]=resmng.OPERATOR.UPDATE
            broadcast(k,"fight", resmng.OPERATOR.UPDATE)
            return
        end
    end
end

function add_D(pid,at)
    for k, room in pairs(data) do
        if pid == room.D.plys[1].pid then
            local dp = getPlayer(at.pid)
            local du = dp:union()
            if du then
                data[k].D.uid= du.uid 
                data[k].D.uname= du.name 
                data[k].D.uflag= du.flag 
                data[k].D.ualias= du.alias 
            end

            table.insert(data[k].D.plys, {pid=at.pid, troop=at.idx,})
            --dbmng:getOne().room:update({_id=k},{["$set"]={D=data[k].D} })
            op[k]=resmng.OPERATOR.UPDATE
            broadcast(k,"fight", resmng.OPERATOR.UPDATE)
        end
    end
end

function del(at)
    if at.action == resmng.TroopAction.Mass_node then
        del_A(at)
    elseif at.action == resmng.TroopAction.Aid then
        del_D(at)
    end
end

function del_A(at)
    for id, room in pairs(data) do
        for k, v in pairs(room.A.plys ) do
            if at.pid == v.pid and v.troop == at.idx then
                if k==1 then
                    broadcast(id,"fight", resmng.OPERATOR.DELETE)
                    data[id] = nil  
                    dbmng:getOne().room:delete({_id=id})
                else
                    data[id].A.plys[k]=nil
                    --dbmng:getOne().room:update({_id=id},{["$set"]={A=lf.data[id].A}})
                    op[id]=resmng.OPERATOR.UPDATE
                    broadcast(id,"fight", resmng.OPERATOR.UPDATE)
                end
                return
            end
        end

    end
end


function del_D(at)
    for id, room in pairs(data) do
        for k, v in pairs(room.D.plys ) do
            if at.pid== v.pid and at.idx == v.troop then
                data[id].D.plys[k]=nil
                --dbmng:getOne().room:update({_id=id},{["$set"]={D=elf.data[id].D}})
                op[id]=resmng.OPERATOR.UPDATE
                broadcast(id,"fight", resmng.OPERATOR.UPDATE)
            end
        end
    end
end

function broadcast(rid,what, mode)
    local pids = {}
    local room = data[rid]

    if not room then return end

    for _,v in pairs(room.A.plys) do
        if v.pid then
            p = getPlayer(v.pid)
            if p:isOnline() then
                table.insert(pids, v.pid)
            end
        end
    end

    for _,v in pairs(room.D.plys ) do
        if v.pid then
            p = getPlayer(v.pid)
            if p:isOnline() then
                table.insert(pids, v.pid)
            end
        end
    end

    if not next(pids) then return end
    Rpc:union_broadcast(pids, what, mode, {rid})
end

