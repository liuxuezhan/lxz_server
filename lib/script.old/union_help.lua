
-- 军团帮助模块
module(..., package.seeall)

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_help:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d._id)
        if u then
            u.help = d
        end
    end
end

function clear(uid)--删除军团时清除数据
    gPendingDelete.union_help[uid] = 0 
end

function add(p,tm_sn)
    local u = unionmng.get_union(p:get_uid())
    if not u.help then
        u.help={}
    end
    local t = timer.get(tm_sn)
    if t.what =="build" and p.pid == t.param[1] then
        table.insert(u.help,{id=tm_sn,log={}})
    end

    --gPendingSave.union_help[p.uid] = u.help
end

function set_one(p,cur)
    local u = unionmng.get_union(p:get_uid())
    if not u then return end
    if not u.help then return end
    if not u.help[cur] then return end

    local num = #(u.help[cur].log or {} )

    local t = timer.get(u.help[cur].id)
        local pid = t.param[1]
    if t and t.what == "build" and p.pid~=pid  then
        local idx = t.param[2]
        local w = getPlayer(pid)
        local limit = w:get_nums("CountHelp")
        local tm = w:get_nums("TimerHelp",u:get_ef())
        if limit>num then
            timer.acc(id,tm)
            Rpc:stateBuild(w, {idx=idx,tmOver=t.over })
            table.insert(u.help[cur].log,p.pid)
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

function one(p,t)
    local pid = t.param[1]
    local idx = t.param[2]
    local p = getPlayer(pid)
    local build = p:get_build(idx)
    local limit = p:get_nums("CountHelp")
    local d = {id=t._id,pid=p.pid ,name = p.name,limit=limit,idx=idx}
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
    return d
end

function get(p)
    local l  = {}
    local u = unionmng.get_union(p:get_uid())
    if u then
        for k, v in pairs(u.help or {}) do
            local t = timer.get(v.id)
            if t and t.what == "build" then
                local d = one(p,t)
                if d then
                    d.log = v.log
                    table.insert(l,d)
                end
            else
                u.help[k]=nil
            end
        end
    end
    return l
end























