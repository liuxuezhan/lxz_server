-- 军团定时任务模块
module(..., package.seeall)
_d={}--数据
_m ={0,5,10,20,20,30,30,40,40,50}--刷新次数对应消耗金币
_q ={--幸运度对应提升任务品质的概率
{},
{{20,0},{40,3},{60,8},{80,15},{95,25},{100,100}},
{{30,0},{60,2},{90,5},{120,10},{145,20},{150,100}},
{{40,0},{80,1},{120,4},{160,8},{195,13},{200,100}},
{{50,0},{100,1},{150,3},{200,6},{245,10},{250,100}},
}

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
_tm_limit= 4*60*60--完成时限
_tm_newlimit= 1*60*60--新手军团完成时限
_rr= {--任务抽取概率
1,1,1,1,1,1,1,1,
}


function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_mission:find({})
    while info:hasNext() do
        local d = info:next()
        _d[d._id]= d
    end
end

function clear(u)--删除军团时清除数据
    _d[u.uid]=nil
    u.task = nil
    gPendingDelete.union_mission[u.uid] = 0
end

function get_propid(uid)

    local u = unionmng.get_union(uid)
    local class = get_class(_rr,u:is_new())
    local lv = 0
    if not u:is_new() then
        lv =_ce[u:get_memberlimit()]
    end
    return class*1000+lv
end


function get_class(r,new)--任务类型
    if new then
        local r =  math.random(1,3)
        if r==1 then
            r = 3
        elseif r==2 then
            r = 2
        elseif r==3 then
            r = 6
        end
        return r
    else
        if player_t.debug_tag then return 2 end
        local tm_open = get_sys_status("start")
        if not tm_open then
            WARN("没有开服时间")
            return t_random(r)
        end

        local t =  math.ceil((gTime - tm_open )/24*60*60)--开服固定
        if t<=8 then
            return t
        end

        --if t==30 then return 10 end
    end

    return t_random(r)
end

function get(u,pid)--获取军团定时任务
    uid = u.uid
    if (not _d[uid]) then _d[uid]= { tm  = 0, } end

    if (not u:is_new() and can_date(_d[uid].tm,gTime) ) or ( u:is_new() and (gTime-_d[uid].tm)>_tm_newlimit+30*60 ) then
        local state  = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
        local class  = t_random({20,30,30,20,10})
        if u:is_new() then
            state  = TASK_STATUS.TASK_STATUS_ACCEPTED
            class  = 3
        end
        _d[uid]= {
            _id=uid,
            propid  = get_propid(uid),
            class  = class,--任务品质
            tm  = gTime ,
            tm_update  = 0 ,
            exp  = 0 ,
            state  = state,
            cur_item = 0,
            log = {},
            sort = {},
        }
        gPendingSave.union_mission[uid] = _d[uid]
        if u:is_new() then timer.new( "union_mission", _tm_newlimit, uid)
        else timer.new( "union_mission", _tm_limit, uid) end
    end

    local list = copyTab(_d[uid])
    list.log = nil
    list.sort = nil
    if u:is_new() then
        list.tm_over = list.tm +  _tm_newlimit
    else
        list.tm_over = list.tm +  _tm_limit
    end
    list.cur_num = get_num(uid)
    list.exp_limit=(list.class+1)*50
    list.gold = get_gold(pid,uid)
    local p = getPlayer(pid)
    if p then list.tm_mission = p._union.tm_mission end
    return list
end

function get_num(uid)
    local num = 0
    if not _d[uid] then WARN("") return 0 end

    for _,v in pairs (_d[uid].sort or {} ) do
        num = num + v.num
    end
    return num
end


function get_log(uid,type,id)
    local data = {type=type,list={}}
    if type == "sort" then
        for _,v in pairs (_d[uid].sort) do
            local l = copyTab(v)
            local p = getPlayer(l.pid)
            l.name = p.name
            table.insert(data.list,l)
        end
    elseif type == "log" then
        local d = _d[uid]
        if id ==0 then id = #(d.log) end
        for n=id,1,-1 do
            if not d[type][n] then break end
            local l = copyTab(d[type][n])
            local p = getPlayer(l.pid)
            l.name = p.name
            table.insert(data.list,l)
        end
    end
    return data
end

function can_update(class,exp)--刷新升级品质成功
    for _,v in pairs (_q[class] or {} ) do
        if exp <= v[1] then
            local r  = math.random(100)
            if r <= v[2] then return true end
            break
        end
    end
    return false
end

function get_gold(pid,uid)
    local num = 1
    for k,v in pairs (_d[uid].log) do
        if v.pid == pid  then num = num + 1 end
    end
    local gold = 0
    if num > #_m then gold = _m[#_m]
    else gold = _m[num] end
    return gold
end

function update_chat(p)--邀请
    if _d[p.uid].class  <= #_q and _d[p.uid].state == TASK_STATUS.TASK_STATUS_CAN_ACCEPT and gTime > _d[p.uid].tm_update  then
        _d[p.uid].tm_update = gTime + 180
        gPendingSave.union_mission[p.uid].tm_update = gTime + 180
    end
end

function update(uid,ply,exp)--刷新军团定时任务品质
    if _d[uid].class > #_q then return end

    exp = exp or 5
    if _d[uid].class  < #_q and _d[uid].state == TASK_STATUS.TASK_STATUS_CAN_ACCEPT  then
        if not ply:do_dec_res(resmng.DEF_RES_GOLD, get_gold(ply.pid,uid) , VALUE_CHANGE_REASON.UNION_MISSION) then return end

        local info = _d[uid]
        info.exp = info.exp + exp
        gPendingSave.union_mission[ uid ].exp = info.exp

        local cur = #( info.log ) + 1
        local log = { id=cur, pid=ply.pid, exp=exp }
        info.log[cur] = log

        if can_update( info.class + 1, info.exp ) then
            info.exp = 0
            info.class = info.class + 1
            log.class = info.class
            gPendingSave.union_mission[ uid ].exp = info.exp
            gPendingSave.union_mission[ uid ].class = info.class
        end
        gPendingSave.union_mission[ uid ].log = info.log
    end
end

function set(p)--领取军团任务
    local u = unionmng.get_union(p.uid)
    if not u then return end
    if _d[u.uid].state == TASK_STATUS.TASK_STATUS_ACCEPTED then return end
    _d[u.uid].state  =  TASK_STATUS.TASK_STATUS_ACCEPTED
    _d[u.uid].tm  =  gTime
    gPendingSave.union_mission[u.uid].state = _d[u.uid].state

    local d = _d[u.uid]
    if not d then return end
    local c = resmng.get_conf("prop_union_task",d.propid)
    if not c then WARN("没有任务:"..d.propid) return end

    if c.Class == UNION_MISSION_CLASS.ACTIVE then
        local u = unionmng.get_union(u.uid)
        if not u then return end 
        for k,v in pairs (u:get_members() or {}) do
            if get_diff_days(gTime, v.cross_time) > 0 then
                ok(v,UNION_MISSION_CLASS.ACTIVE,v.activity)
            end
        end
    end
    return true
end


function ok(ply,cond,num)--完成军团任务
    local d = _d[ply.uid]
    if not d then return end
    if d.state ~= TASK_STATUS.TASK_STATUS_ACCEPTED then return end

    local c = resmng.get_conf("prop_union_task",d.propid)
    if not c then WARN("没有完成任务:"..d.propid) return end

    if cond ~= c.Class then return end

    local u = unionmng.get_union(d._id)
    if not u then return end

    local cur_num = get_num(ply.uid)
    if cur_num >= c.Count then  return end
    if cur_num + num > c.Count then num = c.Count - cur_num end

    if ((not u:is_new() and gTime > d.tm + _tm_limit) or (u:is_new() and gTime > d.tm + _tm_newlimit) )then

    else
        if not _d[ply.uid].sort[ply.pid] then _d[ply.uid].sort[ply.pid] = {pid=ply.pid,num=num }
        else _d[ply.uid].sort[ply.pid].num = _d[ply.uid].sort[ply.pid].num + num end
        --任务
        task_logic_t.process_task(ply, TASK_ACTION.FINISH_UNION_TASK, _d[ply.uid].sort[ply.pid].num)
        gPendingSave.union_mission[ply.uid].sort = d.sort
    end
end

function add(uid)--领取军团任务奖励
    local d = _d[uid]
    if not d then WARN("没有领取任务:"..uid) return end
    if d.state ~= TASK_STATUS.TASK_STATUS_ACCEPTED then return end
    d.state = TASK_STATUS.TASK_STATUS_FINISHED
    gPendingSave.union_mission[uid].state = d.state

    local u = unionmng.get_union( uid )
    if not u then 
        _d[ uid ] = nil
        gPendingDelete.union_mission[ uid ] = 1
        return 
    end

    local c = resmng.get_conf("prop_union_task",d.propid)
    if not c  then WARN("没有配置任务:"..d.propid) return end

    local mode = 0
    local num = get_num(uid) * 100 / c.Count

    if num < 10 then return
    elseif num < 50 then mode =1
    elseif num < 100 then mode =2
    else mode =3 end

    d.cur_item =  mode
    gPendingSave.union_mission[uid].cur_item = d.cur_item

    local _members = u:get_members()

    u:add_log(resmng.UNION_EVENT.MISSION,resmng.UNION_MODE.OK,{ propid=d.propid,mode=mode})

    for idx = 1, mode, 1 do
        local id = d.class *10000 + idx*100 + c.Lv
        local cc = resmng.get_conf("prop_union_award",id)
        if cc then
            for _,v  in pairs(_members or {}) do
                union_item.add(v,cc.Item,UNION_ITEM.TASK)
                v._union.tm_mission = gTime
                v._union.cur_item = idx
                gPendingSave.union_member[v.pid].tm_mission = gTime
                gPendingSave.union_member[v.pid].cur_item = idx
            end
        else 
            WARN("union_mission.add, uid=%d, no award=%d", uid, id )
        end
    end
end

