-- 军团悬赏任务模块
module(..., package.seeall)
_id=1000--当前最大_id
_d={}--数据
tm_cd=12*60*60

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_task:find({})
    while info:hasNext() do
        local d = info:next()
        mark(d)
        if d._id > _id then
            _id = d._id
        end
    end
end

function clear(uid)--删除军团时清除数据
    for k,v in pairs(_d ) do
        if v.uid ==uid then
            del(k)
        end
    end
end

function mark(data) --挂载
    _d[data._id] = data
--挂到军团上
    local union = unionmng.get_union(data.uid)
    if not union then
        ack(self, "union_task", resmng.E_NO_UNION) return false
    end
    if not union.u_task then
        union.u_task = {}
    end
    union.u_task[data._id] = data._id

--挂到目标上
    local d = get_ety(data.eid)
    if not d.u_task then
        d.u_task = {}
    end
    d.u_task[data._id] = data._id

    return true
end

function del_res(p,id,num) 
    local sum = calc_res(id,num)
    local b = p:get_build(1) 
    local c = resmng.get_conf("prop_build",b.propid)

    if sum < UNION_TASK_CONFIG.BONUS.MIN * c.Lv or sum > UNION_TASK_CONFIG.BONUS.MAX * c.Lv then
        return false
    end

    if num > p:get_res_num_normal(id) then
        return false
    end

    if not p:do_dec_res(id,num, VALUE_CHANGE_REASON.UNION_TASK) then
        return false
    end
    return true
end

function add(p,type,eid,hero_id,num,mode,res,res_num) --发布悬赏任务
    for k,v in pairs(_d ) do
        if v.eid == eid then
            return
        end
    end

    if is_ply(eid) then
        local e = get_ety(eid)
        if p.uid == e.uid then
            return
        end
    end

    if not p:doUpdateRes(resmng.DEF_RES_GOLD, UNION_TASK_CONFIG.PRICE, VALUE_CHANGE_REASON.UNION_TASK) then 
        return
    end

    if type > UNION_TASK.NUM then
        return
    end

    if type ==UNION_TASK.HERO and num ~= 1 then
        return
    elseif type ==UNION_TASK.PLY and num >10  then
        return
    elseif type ==UNION_TASK.NPC and num ~=1  then
        return
    end

    if not union_task.del_res(p,res,res_num) then
        return
    end

    if hero_id ~= "" then
        local h = heromng.get_hero_by_uniq_id(hero_id)
        if h then
            local p = getPlayer(h.capturer_pid)     
            eid = p.eid
        end
    end

    _id = _id + 1
    local data= {_id=_id,pid=p.pid,eid=eid,hero_id = hero_id,uid=p:get_uid(),type=type,num=num,mode=mode,
                    res=res,res_num = res_num,sum = res_num, tmStart=gTime,log={}
                }

    data.tax_rate = 45   
    local b = p:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.MARKET)
    if b then
        local c = resmng.get_conf("prop_build",b.propid)
        if c then
            data.tax_rate = get_taxrate(b.propid)
        end
    end

    if mark(data) then
        gPendingSave.union_task[data._id] = data 
    end
end

function get(uid) --获取悬赏任务列表
    local union = unionmng.get_union(uid)
    if not union then
        ack(self, "union_task", resmng.E_NO_UNION) return
    end

    local  list={}
    for k,id in pairs(union.u_task or {} ) do
        if  union_task.check(id) then
            local d = _d[id]
            d.tmOver = d.tmStart + tm_cd 
            local p = getPlayer(d.pid)
            d.p_name = p.name 
            if d.hero_id ~= "" then
                local h = heromng.get_hero_by_uniq_id(d.hero_id)
                if h then
                    d.h_propid = h.propid
                end
            end
            if d.eid ~= 0 then
                local e = get_ety(d.eid)
                if is_ply(e) then
                    d.e_name = e.name
                    d.e_photo = e.photo
                    d.e_x = e.x
                    d.e_y = e.y
                else
                    d.e_propid = e.propid
                end
            end
            table.insert(list,d)
        end
    end
    return list
end

function del(id)
    local c = _d[id]
    if c then
        local o = getPlayer(c.pid)
        local mail = {class=MAIL_CLASS.REPORT, mode=MAIL_REPORT_MODE.UNION_TASK, its={{c.res,c.res_num}},content={type=_d[id].type,own_name=o.name }}
        o:mail_new(mail)
        dbmng:getOne().union_task:delete({_id=id})
        local u = unionmng.get_union(c.uid)
        if u then
            u.u_task[id]=nil
        end
        local e = get_ety(c.eid)
        if e  then
            e.u_task[id]=nil
        end
        _d[id]=nil
    end
end

function check(id)--有效性检查 
    
    if not _d[id] then
        union_task.del(id)
        return false
    end

    local c = _d[id]
    local u = unionmng.get_union(c.uid)
    local e = get_ety(c.eid)

    if c.tmStart + tm_cd < gTime or c.tmStart > gTime  then
        union_task.del(id)
        return false
    end
    if c.type == UNION_TASK.HERO then
        local hero = heromng.get_hero_by_uniq_id(c.hero_id)
        if not hero then
            union_task.del(id)
            return false
        end

        if hero.status ~= HERO_STATUS_TYPE.BEING_IMPRISONED then
            union_task.del(id)
            return false
        end

    end
    return true
end

function ok(p,obj,type) --完成悬赏任务
    for k,id in pairs(obj.u_task or {}) do
        if union_task.check(id) and p.pid ~= _d[id].pid then
            local num = #_d[id].log
            local o = getPlayer(_d[id].pid)
            if p.uid == _d[id].uid and num < _d[id].num and _d[id].tmStart + tm_cd>gTime and gTime > _d[id].tmStart then
                local r = math.floor(_d[id].sum/_d[id].num)
                if _d[id].mode == 2  then
                    if num+1 == _d[id].num  then
                        r = _d[id].res_num  
                    else
                        r = math.random(1,math.floor(_d[id].res_num/1000)-(_d[id].num - num))
                        r = r * 1000
                    end
                end
                _d[id].res_num = _d[id].res_num - r 
                table.insert(_d[id].log,{name=p.name,num = r,tm=gTime})
                r = math.floor(r * (100-_d[id].tax_rate)/100)
                p:do_inc_res_normal(_d[id].res, r, VALUE_CHANGE_REASON.UNION_TASK)
                local mail = {class=MAIL_CLASS.REPORT, mode=MAIL_REPORT_MODE.UNION_TASK, its={{_d[id].res,r}},content={type=_d[id].type,own_name=o.name }}
                p:mail_new(mail)
                if num+1 == _d[id].num  then
                    del(id)
                else
                    gPendingSave.union_task[id] = _d[id]
                end
            end
        end
    end
end

