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
                if c then
                    u.buildlv.data[c.Mode]=v
                end
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
    if not u then return end
    if u.new_union_sn then return end

    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        get_cons(ply,v)
    end

    if u.buildlv then
        l.buildlv = u.buildlv.data 
    end

    l.log = ply._union.buildlv
    return l 
end

function get_cons(ply,mode)
    local u = unionmng.get_union(ply.uid)
    if not u then 
        WARN()
        return 
    end

    local l = get_buildlv(ply.uid, mode)
    if not l then 
        WARN()
        return 
    end

    local c = resmng.get_conf("prop_union_buildlv",l.id + 1 )

    if not ply._union.buildlv[mode] then
        ply._union.buildlv[mode] ={ mode=mode,tm=0,} 
    end

    if can_date(ply._union.buildlv[mode].tm) then
        if not  u.god then 
            WARN()
            return 
        end 

        local god = resmng.get_conf("prop_union_god",u.god.propid )
        if not god then
            WARN()
            return 
        end

        local i = {}
        if god.Mode == CULTURE_TYPE.EAST then
            i=(c.East)
        elseif god.Mode == CULTURE_TYPE.WEST then
            i=(c.West)
        elseif god.Mode == CULTURE_TYPE.SOUTH then
            i=(c.South)
        elseif god.Mode == CULTURE_TYPE.NORTH then
            i=(c.North)
        else
            WARN("捐献物品随机错误:"..god.Mode)
            return 
        end
        local cons = player_t.bonus_func["mutual_award"](ply, i)
        if (not cons)  or (not next(cons)) then
            WARN("捐献物品随机错误:"..god.Mode)
        end
        ply._union.buildlv[mode].cons=cons
        gPendingSave.union_member[ply.pid] = ply._union 

    end
    return ply._union.buildlv[mode].cons
end

function get_buildlv(uid, mode)
    local u = unionmng.get_union(uid)
    if not u then return end

    if not u.buildlv then
        u.buildlv={_id=u._id,data={}}
    end

    if u.buildlv.data[mode] then
        return u.buildlv.data[mode] 
    end

    local conf = resmng.get_conf("prop_union_buildlv",(mode*1000+1))
    if not conf then return end
    local data = {
        id = conf.ID,
        exp = 0,
    }
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
    
    if v and not can_date(v.tm) then
        WARN("冷却中")
        return false
    end

--[[
    local i = ply._union.buildlv[mode].cons
    if ply:get_item_num(i[1]) < i[2] then
        return false
    end
    --]]

    local lv = get_buildlv(ply.uid,mode)
    if not lv then return false end

    local nc = resmng.get_conf("prop_union_buildlv",lv.id + 1)
    if not nc then return false end

    return true
end

function add_buildlv_donate(ply, mode)
    if not can(ply,mode) then return false end
    local u = unionmng.get_union(ply.uid)
    if not u then return false end

    local cons = ply._union.buildlv[mode].cons
    --[[
    if not ply:dec_item_by_item_id(cons[2],cons[3],VALUE_CHANGE_REASON.UNION_BUILDLV) then
        return false
    end
    --]]

    if not u.buildlv.data[mode] then return false end
    local c = resmng.get_conf("prop_union_buildlv",u.buildlv.data[mode].id+1)
    for _, v in pairs(c.BonusID) do
        ply:add_bonus(v[1], v[2], VALUE_CHANGE_REASON.UNION_BUILDLV )
    end

    u.buildlv.data[mode].exp = u.buildlv.data[mode].exp + c.DonateExp
    if u.buildlv.data[mode].exp >= c.UpExp then
        local nc = resmng.get_conf("prop_union_buildlv",u.buildlv.data[mode].id+1)
        u.buildlv.data[mode].exp = 0
        u.buildlv.data[mode].id = nc.ID
        u._ef = nil
        u:notifyall(resmng.UNION_EVENT.BUILDLV, resmng.UNION_MODE.UPDATE, u.buildlv.data[mode])
    end

    ply._union.buildlv[mode].tm = gTime
    gPendingSave.union_member[ply.pid].buildlv = ply._union.buildlv
    gPendingSave.union_buildlv[ply.uid] = u.buildlv
    --成就
    ply:add_count(resmng.ACH_TASK_SHESHI_DONATE, 1)
    --任务
    task_logic_t.process_task(ply, TASK_ACTION.UNION_SHESHI_DONATE, 1)

    local l = {}
    l.buildlv = u.buildlv.data 
    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        get_cons(ply,v)
    end
    l.log = ply._union.buildlv
    union_mission.ok(ply,UNION_MISSION_CLASS.BUILD ,1)
    return l
end


