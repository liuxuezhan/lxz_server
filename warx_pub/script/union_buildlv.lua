-- 军团建筑升级模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_buildlv:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data._id)
        if u then
            u.buildlv = {_id=data._id,data={}}
            for _, v in pairs(data.data) do
                local c = resmng.get_conf("prop_union_buildlv",v.id )
                if c then u.buildlv.data[c.Mode]=v end
            end
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_buildlv[uid] = 0
end


function get(ply)
    local l = {}
    local u = unionmng.get_union(ply.uid)
    if not u then return l  end
    if u:is_new() then return l end

    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        get_cons(ply,v)
    end

    if u.buildlv then l.buildlv = u.buildlv.data end

    l.log = ply._union.buildlv
    return l
end

function get_cons(ply,mode,flag)
    local u = unionmng.get_union(ply.uid)
    if not u then return end

    local l = get_buildlv(ply.uid, mode)
    if not l then return end


    if not ply._union.buildlv[mode] then
        ply._union.buildlv[mode] ={ mode=mode,tm=0,open_tm =0 }
    end

    if can_date(ply._union.buildlv[mode].open_tm,gTime) or flag then
        ply._union.buildlv[mode].open_tm =gTime
        if not  u.god then  return end

        local god = resmng.get_conf("prop_union_god",u.god.propid )
        if not god then  return end

        local c = resmng.get_conf("prop_union_buildlv",l.id )
        if not c  then return end

        local i = {}
        if god.Mode == CULTURE_TYPE.EAST then i=(c.East)
        elseif god.Mode == CULTURE_TYPE.WEST then i=(c.West)
        elseif god.Mode == CULTURE_TYPE.SOUTH then i=(c.South)
        elseif god.Mode == CULTURE_TYPE.NORTH then i=(c.North)
        else return end

        local cons = player_t.bonus_func["mutual_award"](ply, i)
        if (not cons)  or (not next(cons)) then 
            INFO("[UNION]get_cons pid=%d,uid=%d i=%d,mode=%d,conf err",ply.pid,ply.uid,l.id,god.Mode) 
        end

        ply._union.buildlv[mode].cons=cons
        gPendingSave.union_member[ply.pid].buildlv = ply._union.buildlv

    end
    return ply._union.buildlv[mode].cons
end

function get_buildlv(uid, mode)
    local u = unionmng.get_union(uid)
    if not u then return end

    if not u.buildlv then u.buildlv={_id=u._id,data={}} end

    if u.buildlv.data[mode] then return u.buildlv.data[mode] end

    local conf = resmng.get_conf("prop_union_buildlv",(mode*1000+1))
    if not conf then return end
    local data = { id = conf.ID, exp = 0, }
    u.buildlv.data[mode] =data
    gPendingSave.union_buildlv[u.uid] = u.buildlv
    return data
end

function can(ply, mode)
    local u = unionmng.get_union(ply.uid)
    if not u then return false end

    if not ply._union.buildlv then return false end

    local v = ply._union.buildlv[mode]
    if not v then return false end

    if not player_t.debug_tag then
        if v and not can_date(v.tm,gTime) then INFO("冷却中") return  end

        local cons = ply._union.buildlv[mode].cons
        for _, item in pairs(cons) do
            if ply:get_item_num(item[2]) < item[3] then INFO("没名产") return  end
        end
    end

    local lv = get_buildlv(ply.uid,mode)
    if not lv then return false end


    return true
end

function add_buildlv_donate(ply, mode)
    if not can(ply,mode) then return false end
    local u = unionmng.get_union(ply.uid)
    if not u then return false end

    local cons = ply._union.buildlv[mode].cons

    if not player_t.debug_tag then
        for _, item in pairs(cons) do
            if not ply:dec_item_by_item_id(item[2],item[3],VALUE_CHANGE_REASON.UNION_BUILDLV) then
                return false
            end
        end
    end

    if not u.buildlv.data[mode] then return false end
    local c = resmng.get_conf("prop_union_buildlv",u.buildlv.data[mode].id+1)
    if c then
        u.buildlv.data[mode].exp = u.buildlv.data[mode].exp + c.DonateExp
        if player_t.debug_tag then c.UpExp = 0 end

        if u.buildlv.data[mode].exp >= c.UpExp then
            local nc = resmng.get_conf("prop_union_buildlv",u.buildlv.data[mode].id+1)
            u.buildlv.data[mode].exp = u.buildlv.data[mode].exp - c.UpExp
            u.buildlv.data[mode].id = nc.ID
            u:ef_init()
            u:notifyall(resmng.UNION_EVENT.BUILDLV, resmng.UNION_MODE.UPDATE, u.buildlv.data[mode])
        end
        gPendingSave.union_buildlv[ply.uid] = u.buildlv
    else
        c = resmng.get_conf("prop_union_buildlv",u.buildlv.data[mode].id)
        if not c  then return end
    end

    for _, v in pairs(c.BonusID) do
        ply:add_bonus(v[1], v[2], VALUE_CHANGE_REASON.UNION_BUILDLV )
    end
    union_member_t.add_donate_rank(ply,c.DonateExp,1,2)

    ply._union.buildlv[mode].tm = gTime
    gPendingSave.union_member[ply.pid].buildlv = ply._union.buildlv
    --成就
    ply:add_count(resmng.ACH_TASK_SHESHI_DONATE, 1)
    --任务
    task_logic_t.process_task(ply, TASK_ACTION.UNION_SHESHI_DONATE, 1)

    local l = {}
    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        get_cons(ply,v)
    end
    l.buildlv = u.buildlv.data
    l.log = ply._union.buildlv
    union_mission.ok(ply,UNION_MISSION_CLASS.BUILD ,1)
    return l
end


