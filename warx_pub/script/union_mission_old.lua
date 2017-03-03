-- 军团定时任务模块
module(..., package.seeall)

_ce = {--军团人数上限对应任务等级
[50]=1,
[55]=2,
[60]=3,
[65]=4,
[70]=5,
[75]=6,
[80]=7,
[85]=8,
[90]=9,
[95]=10,
[100]=11,
[105]=11,
}

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_mission:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then u.task = d
        else WARN("没有军团："..d._id) end
    end
end

function clear(u)--删除军团时清除数据
    u.task = nil
    gPendingDelete.union_mission[u.uid] = 0
end

function set(p,id)--领取军团任务
    id = id or 1
    local u = unionmng.get_union(p.uid)
    if not u then return end
    local one = u.task.cur[id]
    if not next(one) then return end 
    local sum = 0
    for _,v in pairs (u.task.cur ) do
        if v.state == TASK_STATUS.TASK_STATUS_ACCEPTED then sum = sum + 1 end
    end
    if one.state == TASK_STATUS.TASK_STATUS_CAN_ACCEPT then 
        if sum < 3 then 
            one.state = TASK_STATUS.TASK_STATUS_ACCEPTED  
            one.num = 0
            table.insert(u.task.log,{name=p.name,class=one.class,state=one.state} )
            
            local c = resmng.get_conf("prop_union_task",one.class*1000 + u.task.lv)
            if not c then WARN("没有任务:"..one.class) return end

            if c.Class == UNION_MISSION_CLASS.ACTIVE then
                for k,v in pairs (u:get_members() or {}) do
                    if get_diff_days(gTime, v.cross_time) > 0 then
                        ok(v,UNION_MISSION_CLASS.ACTIVE,v.activity)
                    end
                end
            end
        else 
            one.state = TASK_STATUS.TASK_STATUS_UPDATE  
            one.tm = gTime
        end
    elseif one.state == TASK_STATUS.TASK_STATUS_ACCEPTED then 
        one.state = TASK_STATUS.TASK_STATUS_CAN_ACCEPT  
        one.num = 0
    elseif one.state == TASK_STATUS.TASK_STATUS_UPDATE and gTime < one.tm + 1*60*60  then 
        return 
    end
    gPendingSave.union_mission[u.uid] = u.task
end

function tab_auto(tab)
    _mt_auto = { __index = function (t, k) local new = { } setmetatable(new, _mt_auto) rawset( t, k, new ) return new end, }
    setmetatable(tab, _mt_auto)
end


function get(u)
    u.task = u.task or {_id=u.uid,tm=0,log={}}
    tab_auto(u.task)
    if u:is_new() and   u.task.tm + 2*60*60 < gTime then --重置 
        u.task.tm = gTime
        u.task.lv = _ce[u:get_memberlimit()]
        local tm = gTime + 1*60*60
        local state  = TASK_STATUS.TASK_STATUS_ACCEPTED
        u.task.cur[1] = { class = 3,  tm = tm , num = 0, state = state }
        u.task.cur[2] = { class = 6,  tm = tm , num = 0, state = state } 
        gPendingSave.union_mission[u.uid] = u.task 
    elseif not u:is_new() and  can_date( u.task.tm, gTime) then --重置 
        u.task.tm = gTime
        u.task.lv = _ce[u:get_memberlimit()]
        local tm = gTime + 1*60*60
        local state  = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
        local t = {1,2,3,4}
        shuffle(t)
        u.task.cur[1] = { class = t[1],  tm = tm , num = 0, state = state }
        u.task.cur[2] = { class = t[2],  tm = tm, num = 0, state = state }

        local t = {5,6,7,8}
        shuffle(t)
        u.task.cur[3] = { class = t[1],  tm = tm , num = 0, state = state }
        u.task.cur[4] = { class = t[2],  tm = tm, num = 0, state = state }

        local t = {9,10,11,12}
        shuffle(t)
        u.task.cur[5] = { class = t[1],  tm = tm , num = 0, state = state }
        u.task.cur[6] = { class = t[2],  tm = tm, num = 0, state = state }
        gPendingSave.union_mission[u.uid] = u.task 
    else --查询
        if u:is_new() then
        else
            local f = false
            for _,v in pairs (u.task.cur ) do 
                if v.state  == TASK_STATUS.TASK_STATUS_UPDATE and v.tm > gTime then
                    f = true
                    break
                end
            end
            if f then
                local t = {}
                for i=1,12 do t[i]=i end
                for _,v in pairs (u.task.cur ) do table.remove(t,v.class) end
                lxz(t)
                shuffle(t)
                local i = 1
                for _,v in pairs (u.task.cur ) do 
                    if v.state  == TASK_STATUS.TASK_STATUS_UPDATE and v.tm > gTime then
                        v.class = t[i]
                        i = i + 1
                        v.state  = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
                        v.num = 0
                    end
                end
                gPendingSave.union_mission[u.uid].cur = u.task.cur 
            end
        end
    end
    return u.task
end

function ok(p,cond,num)
    local u = unionmng.get_union(p.uid)
    if not u then return end
    for _,v in pairs (u.task.cur ) do
        if v.state == TASK_STATUS.TASK_STATUS_ACCEPTED then 
            local c = resmng.get_conf("prop_union_task",v.class*1000 + u.task.lv )
            if not c then WARN("没有任务:"..v.class) return end
            if cond == c.Class then
                if v.num + num > c.Count then
                    v.state = TASK_STATUS.TASK_STATUS_FINISHED 
                    table.insert(u.task.log,{class=v.class,state=v.state,star=c.Star} )
                    num = c.Count - v.num
                end
                v.num = v.num + num
                tab_auto(v)  
                if type(v.sort[p.pid]) == "number" then
                    v.sort[p.pid] = v.sort[p.pid]  + num  
                else
                    v.sort[p.pid] =  num  
                end
                task_logic_t.process_task(p, TASK_ACTION.FINISH_UNION_TASK, v.sort[p.pid])
                gPendingSave.union_mission[p.uid].cur = u.task.cur 
                break
            end
        end
    end
end

function add(p)--领取军团任务奖励

    local u = unionmng.get_union( p.uid )
    if not u then return end
    if not u.task then return end

    local star = 0
    for _,v  in pairs(u.task.cur) do
        local c = resmng.get_conf("prop_union_task",v.class*1000+u.task.lv)
        if not c  then WARN("没有配置任务:"..u.uid) return end
        if v.state ==  TASK_STATUS.TASK_STATUS_FINISHED and v.num >= c.Count then
            star = star + 10 
        end
    end

    if star < 1 then return
    elseif star < 5 then star =1
    elseif star < 10 then star =2
    else star =3 end

    if can_date(p._union.cur_item ,gTime) then p._union.cur_item = 0 end

    while p._union.cur_item < star do
        p._union.cur_item = p._union.cur_item + 1 
        local c = resmng.get_conf("prop_union_award",5*10000+star*100 +u.task.lv)
        p:add_bonus(c.Item[1][1], c.Item[1][2],VALUE_CHANGE_REASON.UNION_MISSION)
    end
    p._union.tm_mission = gTime
    gPendingSave.union_member[p.pid].tm_mission = gTime
    gPendingSave.union_member[p.pid].cur_item = star

--    u:add_log(resmng.UNION_EVENT.MISSION,resmng.UNION_MODE.OK,{ propid=d.propid,mode=mode})

end

