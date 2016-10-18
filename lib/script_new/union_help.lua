
-- 军团帮助模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_help:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then
            for _, v in pairs(d or {}) do
                u.help[v.id] = copyTab(v)
                u.help[v.id].log = {} 
                for _, pid in pairs(v.log or {}) do
                    u.help[v.id].log[pid] = pid 
                end
            end
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_help[uid] = 0 
end

function add(p,tm_sn)
    local u = unionmng.get_union(p:get_uid())
    if not u  then
        return 
    end

    if not u.help then
        u.help={}
    end

    if u.help[tm_sn] then
        LOG("已求助:"..tm_sn)
        return
    end

    local t = timer.get(tm_sn)
    if not t then
        LOG("没有定时器:"..tm_sn)
        return
    end

    if (t.what =="build" or t.what =="cure" or t.what =="hero_cure") and p.pid == t.param[1] then
        u.help[tm_sn]={id=tm_sn,log={}}
        local d = get_one(u.help[tm_sn])
        u:notifyall(resmng.UNION_EVENT.HELP, resmng.UNION_MODE.ADD, d)
        --任务
        task_logic_t.process_task(p, TASK_ACTION.UNION_HELP_NUM, 1)
    end


end

function set_one(p,cur)
    local u = unionmng.get_union(p:get_uid())
    if not u then return end
    if not u.help then return end
    if not u.help[cur] then return end
    if  u.help[cur].log[p.pid] then
        LOG("已帮助")
        return 
    end

    local num = #(u.help[cur].log or {} )

    local t = timer.get(u.help[cur].id)
        local pid = t.param[1]
    if t and (t.what == "build" or t.what == "cure" or t.what == "hero_cure")and p.pid~=pid  then
        local idx = t.param[2]
        local w = getPlayer(pid)
        local limit = w:get_val("CountHelp")
        local tm = w:get_val("TimeHelp")
        if limit>num then
            timer.acc(t._id,tm)
            if t.what == "cure" or t.what == "hero_cure"  then
                for k, v in pairs( w:get_build() or {}) do
                    local conf = resmng.get_conf("prop_build", v.propid)
                    if conf.Mode == BUILD_FUNCTION_MODE.HOSPITAL then
                        Rpc:stateBuild(w, {idx=v.idx,tmOver=t.over,h_name=p.name })
                    end
                end
            else
                Rpc:stateBuild(w, {idx=idx,tmOver=t.over,h_name=p.name })
            end
            u.help[cur].log[p.pid]=p.pid
            union_mission.ok(p,UNION_MISSION_CLASS.HELP,1)
            --任务
            task_logic_t.process_task(p, TASK_ACTION.UNION_HELP_NUM, 1)
        end
        if limit == (num + 1) then
            union_help.del(p,cur)
        end
    end
end

function set(p,id)
    local u = unionmng.get_union(p:get_uid())
    if not u then
        return
    end
    for k, v in pairs(u.help or {}) do
        if id == 0 then
            set_one(p,k)
        else
            if  v.id == id and v.pid ~= p.pid then
                set_one(p,k)
                return
            end
        end
    end

end

function get_one(v)
    local t = timer.get(v.id)
    if  t and (t.what == "build" or  t.what == "cure" or  t.what == "hero_cure") then
        local pid = t.param[1]
        local idx = t.param[2]
        local p = getPlayer(pid)
        local build = p:get_build(idx)
        local limit = p:get_val("CountHelp")
        local d = {id=t._id, pid=p.pid, photo=p.photo, name = p.name, limit=limit,idx=idx,}
        if t and (t.what == "cure" or t.what == "hero_cure") then
            d.type = HELP_TYPE.HEAL
            return d
        end
        if build.state == BUILD_STATE.CREATE then
            d.type = HELP_TYPE.CONSTRUCT
            d.propid=build.propid
        elseif build.state == BUILD_STATE.UPGRADE then
            d.type = HELP_TYPE.UPGRADE
            d.propid=build.propid
        elseif build.state == BUILD_STATE.WORK then
            local conf = resmng.get_conf("prop_build", build.propid)
            if conf.Mode == BUILD_FUNCTION_MODE.ACADEMY then
                d.type = HELP_TYPE.RESEARCH
                d.propid = t.param[3]
            elseif conf.Mode == BUILD_FUNCTION_MODE.HOSPITAL then
                d.type = HELP_TYPE.HEAL
            elseif conf.Mode == BUILD_FUNCTION_MODE.FORGE then
                d.type = HELP_TYPE.CAST
                d.propid = build:get_extra_val("forge")
            else
                return
            end
        else
            return
        end

        d.num =tabNum(v.log)
        if d.num < d.limit then
            return d
        end
    end
end

function del(p,sn)
    local u = unionmng.get_union(p:get_uid())
    if u and u.help and u.help[sn] then
        u:notifyall(resmng.UNION_EVENT.HELP, resmng.UNION_MODE.DELETE, {id = u.help[sn].id})
        u.help[sn]=nil
    end
end

function get(p)
    local l  = {}
    local u = unionmng.get_union(p:get_uid())
    if u then
        for k, v in pairs(u.help or {}) do
            if not v.log[p.pid] then 
                local d = get_one(v)
                if d  then
                    table.insert(l,d)
                else
                    u.help[k]=nil
                end
            end
        end
    end
    return l
end




