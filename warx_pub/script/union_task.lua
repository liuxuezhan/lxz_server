-- 军团悬赏任务模块
module(..., package.seeall)
_id = 1000--当前最大_id
_d = {}--数据
tm_cd = 12 * 60 * 60

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_task:find({})
    while info:hasNext() do
        local d = info:next()
        mark(d)
        if d._id > _id then _id = d._id end
    end
end

function clear(uid)--删除军团时清除数据
    for k,v in pairs(_d ) do
        if v.uid ==uid then del(k) end
    end
end

function mark(data) --挂载
    _d[data._id] = data
--挂到军团上
    local union = unionmng.get_union(data.uid)
    if not union then return false end
    if not union.u_task then union.u_task = {} end
    union.u_task[data._id] = data._id

--挂到目标上
    local d = get_ety(data.eid)
    if d then
        if not d.u_task then d.u_task = {} end
        d.u_task[data._id] = data._id
    end
    return true
end

function del_res(p,id,num) 
    local sum = calc_res(id,num)
    local b = p:get_build(1) 
    local c = resmng.get_conf("prop_build",b.propid)

    if sum < UNION_TASK_CONFIG.BONUS.MIN * c.Lv or sum > UNION_TASK_CONFIG.BONUS.MAX * c.Lv then
        INFO("[UNION] union_task pid=%d uid=%d 上限不足 sum=%d ",p.pid,p.uid,sum) 
        return false 
    end

    if num > p:get_res_num_normal(id) then 
        INFO("[UNION] union_task pid=%d uid=%d  普通资源不足 num=%d ",p.pid,p.uid,num) 
        return false 
    end

    if not p:do_dec_res(id,num, VALUE_CHANGE_REASON.UNION_TASK) then return false end

    return true
end

function add(p,sub,eid,hero_id,num,mode,res,res_num,x,y) --发布悬赏任务
    for k,v in pairs(_d ) do
        if v.eid == eid and v.uid == p:get_uid() then return 1 end
    end

    if is_ply(eid) then
        local e = get_ety(eid)
        if p.uid == e.uid then  return 2 end
    end

    if sub > UNION_TASK.NUM then return 3 end
    if num < 1 then return 4 end

    if sub == UNION_TASK.HERO then
        if num ~= 1 then return 5 end
        if hero_id == "" then return 6 end

        local h = heromng.get_hero_by_uniq_id(hero_id)
        if not h then return 7 end
        if h.status ~= HERO_STATUS_TYPE.BEING_IMPRISONED then return 8 end
        if h.capturer_pid < 10000 then return 9 end
        local enemy = getPlayer( h.capturer_pid )
        if not enemy then return 10 end
        eid = enemy.eid

    elseif sub == UNION_TASK.PLY then
        if num > 10 then return 11 end
        local target = get_ety( eid )
        if not target then return 12 end
        if not is_ply( target ) then return 13 end

    elseif sub == UNION_TASK.NPC then 
        if num > 10  then return 14 end

        local target = get_ety( eid )
        if not target then return 15 end
        if not is_npc_city( target ) then return 16 end

    end
    
    _id = _id + 1
    local t = {}
    if mode == 2 then
        if res_num < num * 1000 then return 17 end
        local sum =  math.floor(res_num /1000)
        t = split(sum,num)
        for i = 1, num do
            t[i] = t[i] * 1000
        end
        local sn =  math.random(num)
        t[sn] = t[sn] + res_num % 1000 
    end

    if p.gold < UNION_TASK_CONFIG.PRICE then return 18 end
    if not union_task.del_res(p,res,res_num) then return 19 end
    if not p:do_dec_res(resmng.DEF_RES_GOLD, UNION_TASK_CONFIG.PRICE, VALUE_CHANGE_REASON.UNION_TASK) then return 20 end

    local data= {_id=_id,pid=p.pid,eid=eid,hero_id = hero_id,uid=p:get_uid(),type=sub,num=num,
                mode=mode,t=t,res=res,res_num = res_num,sum = res_num, tmStart=gTime,log={},x=x,y=y, tax_rate=45 }

    local b = p:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.MARKET)
    if b then
        local c = resmng.get_conf("prop_build",b.propid)
        if c then data.tax_rate = get_taxrate(b.propid) end
    end
    if mark(data) then gPendingSave.union_task[data._id] = data end
    Rpc:union_task_add(p,get_one(p.uid,data._id))
    return 0
end


function get(uid,id)
    local union = unionmng.get_union(uid)
    if not union then return end
    local list = {}
    if  id == 0  then
        for k,v in pairs(union.u_task or {} ) do
            local d = get_one(uid,v)
            if d then table.insert(list,d) end
        end
    else
        local d = get_one(uid,id)
        if d  then table.insert(list,d) end
    end
    return list
end

function get_one(uid,id) 
    local union = unionmng.get_union(uid)
    if not union then return end
    if  union_task.check(id) then
        local d = _d[id]
        d.tmOver = d.tmStart + tm_cd 
        local p = getPlayer(d.pid)
        d.p_name = p.name 
        d.p_photo = p.photo 
        if d.hero_id ~= "" then
            local h = heromng.get_hero_by_uniq_id(d.hero_id)
            if h then d.h_propid = h.propid end
        end
        if d.eid ~= 0 then
            local e = get_ety(d.eid)
            if is_ply(e) then
                d.e_name = e.name
                d.e_photo = e.photo
                d.e_x = d.x
                d.e_y = d.y
            else d.e_propid = e.propid end
        end
        return d
    end
end

function del(id)
    local c = _d[id]
    if c then
        local o = getPlayer(c.pid)
        if c.res_num ==0 then        
            local pids ="" 
            local t ={} 
            for _,v in pairs(c.log ) do t[v.name] = v.name end

            for _,v in pairs( t ) do
                if pids == "" then pids = v
                else pids = pids..","..v end
            end
            o:send_system_notice( 10016, {}, {pids} )
        else o:send_system_notice( 10018, {}, {}, {{"res",c.res,c.res_num,10000}}) end
        dbmng:getOne().union_task:delete({_id = id})
        local u = unionmng.get_union(c.uid)
        if u then u.u_task[id] = nil end
        local e = get_ety(c.eid)
        if e then e.u_task[id] = nil end
        _d[id]=nil
    end
end

function check(id)--有效性检查 
    
    if not _d[id] then union_task.del(id) return false end
    local c = _d[id]
    local u = unionmng.get_union(c.uid)
    local e = get_ety(c.eid)
    if c.tmStart + tm_cd < gTime or c.tmStart > gTime  then union_task.del(id) return false end
    if c.type == UNION_TASK.HERO then
        local hero = heromng.get_hero_by_uniq_id(c.hero_id)
        if not hero then union_task.del(id) return false end
        if hero.status ~= HERO_STATUS_TYPE.BEING_IMPRISONED then union_task.del(id) return false end
    end
    return true
end

function ok(p,obj,sub) --完成悬赏任务
    for k,id in pairs(obj.u_task or {}) do
        if union_task.check(id) and p.pid ~= _d[id].pid and p.uid == _d[id].uid and sub==_d[id].type then
            local num = #_d[id].log
            local o = getPlayer(_d[id].pid)
            if p.uid == _d[id].uid and num < _d[id].num and _d[id].tmStart + tm_cd>gTime and gTime > _d[id].tmStart then
                local r = math.floor(_d[id].sum/_d[id].num)
                if _d[id].mode == 2  then r =  _d[id].t[num+1] end
                _d[id].res_num = _d[id].res_num - r 
                table.insert(_d[id].log,{name=p.name,num = r,tm=gTime})
                local old = r
                r = math.floor(r * (100-_d[id].tax_rate)/100)
                local c = resmng.get_conf("prop_resource",_d[id].res) 
                if c and c.Name then
                    p:send_system_notice(10017, {},
                        {o.name,nformat(old),c.Name,nformat(old-r),c.Name,nformat(r),c.Name}, 
                        {{"res",_d[id].res,r,10000}})
                end
                if num + 1 == _d[id].num  then del(id)
                else gPendingSave.union_task[id] = _d[id] end
            end
        end
    end
end

function nformat(num,accuracy)--数字表达式 
    if type(num) ~= "number" then return "∞" end
    if not accuracy then accuracy = 1 end
    local fom = string.format("%%.%df",accuracy)
    local num_new = math.abs(num)
    local sign = 1 
    if num < 0 then sign = -1 end       
    if num_new < 1000 then 
        return math.floor(num_new) * sign
    elseif num_new < 1000000 then
        return string.format(fom .. "k",num*0.001 * sign)
    elseif num_new < 1000000000 then
        return string.format(fom .. "M",num*0.000001 * sign)
    else
        return string.format(fom .. "G",num*0.000000001 * sign)
    end
end

