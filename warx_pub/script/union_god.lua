-- 军团战神模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_god:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data._id)
        if u then u.god = data end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_god[uid] = 0
end

function set(u,propid)
    local c = resmng.get_conf("prop_union_god",propid )
    if not c then return false end
    u.god = {propid =propid ,exp = 0, }
    gPendingSave.union_god[u.uid] = u.god
    return true
end

function add(p,mode)--膜拜
    if mode > 3  then return end
    if not can_date(p._union.god_log.tm or 0, gTime) then return end
    local u = unionmng.get_union(p:get_uid())
    if not u  then return end

    local c = resmng.get_conf("prop_union_god",u.god.propid )
    if not c  then return end

    if not p:do_dec_res(c.Cons[mode][1], c.Cons[mode][2], VALUE_CHANGE_REASON.UNION_GOD) then return end
    p._union.god_log.tm = gTime
    gPendingSave.union_member[p.pid] = p._union

    p:add_bonus(c.WorshipItem[mode][1], c.WorshipItem[mode][2],VALUE_CHANGE_REASON.UNION_GOD)
    union_mission.ok(p,UNION_MISSION_CLASS.GOD,1)
    p:union_load("mars")

    task_logic_t.process_task(p, TASK_ACTION.WORSHIP_GOD, 1)
end

function add_exp(p,num)--战神经验
    local u = unionmng.get_union(p:get_uid())
    if not u  then return end
    if u:is_new()  then return end

    local c = resmng.get_conf("prop_union_god",u.god.propid + 1 )
    if not c  then return end

    u.god.exp =  u.god.exp + num
    if u.god.exp > c.Exp  then
        u.god.propid =  u.god.propid + 1
        u.god.exp = u.god.exp - c.Exp
        u:ef_init()
    end
    gPendingSave.union_god[u.uid] = u.god
end

function get(p)--获取升级礼包
    local u = unionmng.get_union(p:get_uid())
    if not u  then return end

    local c = resmng.get_conf("prop_union_god",u.god.propid )
    if not c  then return end

    if p._union.god_log.lv >=  c.Lv then return end

    c = resmng.get_conf("prop_union_god",c.Mode*1000+p._union.god_log.lv+1 )
    if c then
        p:add_bonus(c.UpgradeItem[1][1], c.UpgradeItem[1][2],VALUE_CHANGE_REASON.UNION_GOD)
        p._union.god_log.lv = p._union.god_log.lv + 1
        gPendingSave.union_member[p.pid] = p._union
        p:union_load("mars")
    end
end
