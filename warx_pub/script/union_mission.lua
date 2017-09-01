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
        --if u then u.task = new(d)
        if u then u.task = tab_auto(d)
        else end
    end
end

function clear(u)--删除军团时清除数据
    u.task = nil
    gPendingDelete.union_mission[u.uid] = 0
end

function set(p,idx)--领取军团任务
    if not idx then return end
    local u = unionmng.get_union(p.uid)
    if not u then return end
    local one = u.task.cur[idx]
    if (not one) or (not next(one))  then return end 
    local sum = 0
    for _,v in pairs (u.task.cur ) do
        if v.state == TASK_STATUS.TASK_STATUS_ACCEPTED then sum = sum + 1 end
    end
    if one.state == TASK_STATUS.TASK_STATUS_CAN_ACCEPT then 
        if sum < 3 then 
            one.state = TASK_STATUS.TASK_STATUS_ACCEPTED  
            one.num = 0
            u:add_log(resmng.UNION_EVENT.MISSION,resmng.UNION_MODE.GET,{ name=p.name, propid = one.class*1000 +  u.task.lv  })
        else
            one.state = TASK_STATUS.TASK_STATUS_UPDATE  
            one.tm = gTime + 1 *60*60
            one.num = 0
        end
        gPendingSave.union_mission[u.uid] = u.task
        return true
    elseif one.state == TASK_STATUS.TASK_STATUS_ACCEPTED then 
        one.state = TASK_STATUS.TASK_STATUS_CAN_ACCEPT  
        one.num = 0
        one.sort = {}
        gPendingSave.union_mission[u.uid].cur = u.task.cur
        return true
    elseif one.state == TASK_STATUS.TASK_STATUS_UPDATE and gTime < one.tm then return end
end

function tab_auto(tab)
    _mt_auto = { 
                __index = function (t, k) local new = { } setmetatable(new, _mt_auto) rawset( t, k, new ) return new end, 
             --   __newindex = function (t, k,v) if type(v) == "table" then setmetatable(v, _mt_auto) end rawset( t, k, v ) end, 
               }
    setmetatable(tab, _mt_auto)
    return tab
end

--[[
function new(tab) 
    if not tab then  return end
    if type(tab)~= "table" then lxz1("数据无效") end

    local _mt_save = { --自动保存
        __index = function (t, k)
            if t.M[ k ] then 
                return t.M[ k ] 
            else
                local new = tab_auto({}) 
                rawset( t.M, k, new ) 
                return new  
            end
        end,
        __newindex = function(t, k, v)
            if type(v) == "table" then 
                setmetatable(v, _mt_save) 
            end
            t.M[k] = v     -- 修改时保存
            gPendingSave.union_mission[t._id][k] = v 
        end,
    }
    local one = { M = copyTab(tab) }
    setmetatable(one, _mt_save)
    return one
end
--]]

function get(u) --查询
    --u.task = u.task or new({_id=u.uid,tm=0,})
    u.task = u.task or tab_auto({_id=u.uid,tm=0,})
    if u:is_new() and   u.task.tm + 2*60*60 < gTime then --重置 
        u.task.tm = gTime
        u.task.lv = 0 
        local tm = gTime + 1*60*60
        local state  = TASK_STATUS.TASK_STATUS_ACCEPTED
        u.task.cur[1] = { idx=1, class = 12,  tm = tm , num = 0, state = state }
        u.task.cur[2] = { idx=2, class = 21,  tm = tm , num = 0, state = state } 
        gPendingSave.union_mission[u.uid] = u.task 
    elseif (not u:is_new()) and  can_date( u.task.tm, gTime) then --重置 
        u.task.tm = gTime
        u.task.lv = _ce[u:get_memberlimit()]
        local tm = gTime + 1*60*60

        local state  = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
        local t = {11,12,13,14}
        shuffle(t)
        u.task.cur[1] = { idx=1, class = t[1],  tm = tm , num = 0, state = state }
        u.task.cur[2] = { idx=2, class = t[2],  tm = tm, num = 0, state = state }

        local t = {21,22,23,24}
        shuffle(t)
        u.task.cur[3] = { idx=3, class = t[1],  tm = tm , num = 0, state = state }
        u.task.cur[4] = { idx=4, class = t[2],  tm = tm, num = 0, state = state }

        local t = {31,32,33,34}
        shuffle(t)
        u.task.cur[5] = { idx=5, class = t[1],  tm = tm , num = 0, state = state }
        u.task.cur[6] = { idx=6, class = t[2],  tm = tm, num = 0, state = state }

        gPendingSave.union_mission[u.uid] = u.task 
    else --查询
        if u:is_new() then
        else
            local f = false
            for _,v in pairs (u.task.cur ) do 
                if v.state  == TASK_STATUS.TASK_STATUS_UPDATE and gTime > v.tm then f = true break end
            end
            if f then
                local t = {}
                for i =11,14 do t[i]=i end
                for i =21,24 do t[i]=i end
                for i =31,34 do t[i]=i end
                for _,v in pairs (u.task.cur ) do t[v.class] = nil end
                local tt = {}
                for k,_ in pairs ( t ) do table.insert(tt,k) end
                shuffle(t)
                local i = 1
                for _,v in pairs (u.task.cur ) do 
                    if v.state  == TASK_STATUS.TASK_STATUS_UPDATE and gTime >v.tm then
                        v.class = tt[i]
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
    if not u.task then return end
    for k,v in pairs (u.task.cur or {} ) do
        if v.state == TASK_STATUS.TASK_STATUS_ACCEPTED then 
            local c = resmng.get_conf("prop_union_task",v.class*1000 + u.task.lv )
            if not c then return end
            if cond == c.Class then
                if v.num + num >= c.Count then
                    v.state = TASK_STATUS.TASK_STATUS_FINISHED 
                    v.num = c.Count
                    u:add_log(resmng.UNION_EVENT.MISSION,resmng.UNION_MODE.OK,{ propid=v.class*1000 +  u.task.lv})
                else
                    v.num = v.num + num
                end
				tab_auto(v)
				tab_auto(v.sort)
                if next(v.sort[p.pid]) then 
                    v.sort[p.pid].num = v.sort[p.pid].num + num  
                else 
                    v.sort[p.pid].name =  p.name  
                    v.sort[p.pid].num =  num  
                end
                v.sort[p.pid].tm =  gTime  
                task_logic_t.process_task(p, TASK_ACTION.FINISH_UNION_TASK, v.sort[p.pid].num)
                gPendingSave.union_mission[p.uid] = u.task 
                return
            end
        end
    end
end

function add(p, idx)--领取军团任务奖励
    if not idx then
        ack(p, "add", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union( p.uid )
    if not u then return end
    if not u.task then return end

    local star = 0
    for _,v  in pairs(u.task.cur) do
        local c = resmng.get_conf("prop_union_task",v.class*1000+u.task.lv)
        if not c  then return end
        if v.state ==  TASK_STATUS.TASK_STATUS_FINISHED and v.num >= c.Count then star = star + c.Stars end
    end

    if star < 1 then return
    elseif star < 5 then star =1
    elseif star < 10 then star =2
    else star =3 end

    if can_date(p._union.tm_mission ,gTime) then p._union.cur_item = {} end

    local cur_item = p._union.cur_item
    if idx > star or cur_item[idx] then
        ack(p, "add", resmng.E_DISALLOWED) return
    end

    local c = resmng.get_conf("prop_union_award",5*10000+idx*100 +u.task.lv)
    if c then
        p:add_bonus(c.Item[1], c.Item[2],VALUE_CHANGE_REASON.UNION_MISSION)
        cur_item[idx] = idx
        p._union.cur_item = cur_item
    end
    p._union.tm_mission = gTime
    gPendingSave.union_member[p.pid].tm_mission = gTime
    gPendingSave.union_member[p.pid].cur_item = p._union.cur_item 

end

