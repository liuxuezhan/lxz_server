-- 军团定时任务模块
module(..., package.seeall)
_d={}--数据
_m ={0,5,10,20,20,30,30,40,40,50}--刷新次数对应消耗金币
_q ={--幸运度对应提升任务品质的概率
{},
{[20]=0,[40]=10,[60]=30,[80]=60,[100]=100},
{[30]=0,[60]=10,[90]=30,[120]=60,[150]=100},
{[40]=0,[80]=10,[120]=30,[160]=60,[200]=100},
{[50]=0,[100]=10,[150]=30,[200]=60,[250]=100},
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
        _d[d._id]= copyTab(d)
        _d[d._id].log={}
        for _,v in pairs (d.log or {}) do
            _d[d._id].log[v.id]=v
        end

        _d[d._id].sort={}
        for _,v in pairs (d.sort or {}) do
            _d[d._id].sort[v.pid]=v
        end
    end
end

function clear(uid)--删除军团时清除数据
    _d[uid]=nil
    gPendingDelete.union_mission[uid] = 0 
end

function get_propid(uid)
    local u = unionmng.get_union(uid)
    local class = union_mission.get_class(_rr,u.new_union_sn)
    local lv = 0
    if not u.new_union_sn then
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
            r = 4
        elseif r==3 then
            r = 6
        end
        return r 
    else
        local t =  math.ceil((gTime - gSysStatus.start)/24*60*60)--开服固定
        if t<10 then
            return t 
        end

        if t==30 then
            return 10 
        end
    end

    return t_random(r)
end

function get(pid,uid)--获取军团定时任务

    local u = unionmng.get_union(uid)
    if not u then return end
    local state  = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
    local class  = t_random({20,30,30,20,10})
    if u.new_union_sn then
        state  = TASK_STATUS.TASK_STATUS_ACCEPTED
        class  = 3
    end

    if (not _d[uid]) then _d[uid]= { tm  = 0, } end

    if (not u.new_union_sn and can_date(_d[uid].tm) ) or ( u.new_union_sn and (gTime-_d[uid].tm)>_tm_newlimit ) then
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
        for k,v in pairs (u._members or {}) do
            ok(v,UNION_MISSION_CLASS.ACTIVE,v.activity)
        end
    end
    local list = copyTab(_d[uid])
    list.log = nil
    list.sort = nil
    if u.new_union_sn then
        list.tm_over = list.tm +  _tm_newlimit 
    else
        list.tm_over = list.tm +  _tm_limit 
    end
    list.cur_num = get_num(uid) 
    list.exp_limit=(list.class+1)*50
    list.gold = get_gold(pid,uid) 
    local p = getPlayer(pid)
    if p then
        list.tm_mission = p._union.tm_mission 
    end
    return list 
end

function get_num(uid)
    local num = 0 
    if not _d[uid] then
        WARN("")
        return 0
    end
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
        if id ==0 then
            id = #(d.log)
        end
        for n=id,1,-1 do 
            if not d[type][n] then
                break
            end
            local l = copyTab(d[type][n])
            local p = getPlayer(l.pid)
            l.name = p.name 
            table.insert(data.list,l) 
        end
    end

    return data
end

function can_update(class,exp)--刷新升级品质成功
    for k,v in pairs (_q[class] or {} ) do
        if exp < k then
            local r  = math.random(100)
            if r < v then
                return true
            end
            break
        end
    end
    return false
end

function get_gold(pid,uid)
    local num = 1
    for k,v in pairs (_d[uid].log) do
        if v.pid == pid  then
            num = num + 1
        end
    end
    local gold = 0 
    if num > #_m then
        gold = _m[#_m]
    else
        gold = _m[num]
    end
    return gold
end

function update_num(uid,ply)--刷新扣金币
    ply:do_dec_res(resmng.DEF_RES_GOLD, get_gold(ply.pid,uid) , VALUE_CHANGE_REASON.UNION_MISSION)
end

function update_chat(p)--邀请
    if _d[p.uid].class  < 6 and _d[p.uid].state == TASK_STATUS.TASK_STATUS_CAN_ACCEPT and gTime > _d[p.uid].tm_update  then
        _d[p.uid].tm_update = gTime + 180
    end
    gPendingSave.union_mission[p.uid] = _d[p.uid]
end

function update(uid,ply,exp)--刷新军团定时任务品质
    if _d[uid].class > 5 then
        return
    end
    exp = exp or 5
    if _d[uid].class  < 6 and _d[uid].state == TASK_STATUS.TASK_STATUS_CAN_ACCEPT  then
         update_num(uid,ply)
        _d[uid].exp = _d[uid].exp + exp
        local cur = #(_d[uid].log)+1
        if can_update(_d[uid].class+1,_d[uid].exp) then
            _d[uid].exp = 0
            _d[uid].class  = _d[uid].class + 1
            _d[uid].log[cur]={id=cur,pid=ply.pid,exp=exp,class = _d[uid].class }
        else
            _d[uid].log[cur]={id=cur,pid=ply.pid,exp=exp}
        end
        gPendingSave.union_mission[uid] = _d[uid]
    end
end

function set(uid)--领取军团任务
    _d[uid].tm  =  gTime 
    _d[uid].state  =  TASK_STATUS.TASK_STATUS_ACCEPTED 
    gPendingSave.union_mission[uid].state = _d[uid].state 
end

function ok(ply,cond,num)--完成军团任务
    local d = _d[ply.uid]
    if not d then
        return
    end
    local c = resmng.get_conf("prop_union_task",d.propid)
    if not c then
        WARN("没有任务:"..d.propid)
        return 
    end
    local u = unionmng.get_union(d._id)
    if not u then return end
    local cur_num = get_num(ply.uid)
    if cur_num >= c.Count then
        return
    end
    if cur_num + num > c.Count then
        num = c.Count - cur_num
    end

    if cond == c.Class then
        if ((not u.new_union_sn and gTime > d.tm + _tm_limit) or (u.new_union_sn and gTime > d.tm + _tm_newlimit) )then
        else
            if not _d[ply.uid].sort[ply.pid] then
                _d[ply.uid].sort[ply.pid]={pid=ply.pid,num=num }
            else
                _d[ply.uid].sort[ply.pid].num= _d[ply.uid].sort[ply.pid].num + num
            end
            gPendingSave.union_mission[ply.uid] = _d[ply.uid]
            add(ply.uid)
        end
    end
end

function add(uid)--领取军团任务奖励
    local d = _d[uid]
    if not d then
        return
    end
    local c = resmng.get_conf("prop_union_task",d.propid)
    if not c  then
        WARN("没有任务:"..d.propid)
        return 
    end
    local num = get_num(uid) 
    local mode = 0 
    num = (num*100/c.Count)
    if num < 10 then
        return 
    elseif num < 50 then
        mode =1
    elseif num < 100 then
        mode =2
    else
        mode =3
    end

    if mode > d.cur_item then
        d.cur_item =  mode 
        gPendingSave.union_mission[uid] = d
        local id = d.class *10000 + mode*100 + c.Lv
        local cc = resmng.get_conf("prop_union_award",id)
        if cc then
            local u = unionmng.get_union(uid)
            if u then
                for _,v  in pairs(u._members ) do
                    if (not can_date(v._union.tm_mission)) and (v._union.cur_item > d.cur_item) then
                    else
                        union_item.add(v,cc.Item,UNION_ITEM.TASK)
                        v._union.tm_mission = gTime 
                        v._union.cur_item = d.cur_item 
                        gPendingSave.union_member[v.pid].tm_mission = v._union.tm_mission  
                    end
                end
                u:add_log(resmng.UNION_EVENT.MISSION,resmng.UNION_MODE.OK,{ propid=c.propid })
            end
        end
    end
end
