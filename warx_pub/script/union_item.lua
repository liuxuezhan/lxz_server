--军团礼物模块
module(..., package.seeall)
_tm = 24*60*60
_tm2 = 24*60*60
function load_db(pid)
    local db = dbmng:getOne()
    local info = db.union_item:find({pid=pid})
    while info:hasNext() do
        local d = info:next()
        local p = getPlayer(d.pid)
        if p then
            p.union_item_idx = p.union_item_idx or 0 
            p.union_item = p.union_item or {}  
            p.union_item[d.idx] = d
            if p.union_item_idx <  d.idx  then p.union_item_idx = d.idx end
        end
    end
end


function add(p,propid,src,d_propid,pid)--加入军团礼物
    if check_ply_cross(p) then
        remote_cast(p.emap, "add", {"union_item", p.pid, propid, src, d_propid, pid})
        return
    end

    INFO( "[UNION]pid=%d,uid=%d, src=%d add union_item", p.pid,p.uid, src )
    if src >= UNION_ITEM.MAX then return end 

    if not p.union_item then  load_db(p.pid) end
    p.union_item= p.union_item or {}  
    p.union_item_idx  =  (p.union_item_idx or 0)  + 1 
    local d = { _id=p.pid.."_"..p.union_item_idx,
                pid=p.pid,
                idx=p.union_item_idx,
                propid=propid,
                tm=gTime,
                src=src,
                d_propid=d_propid,
                s_pid =pid }
    p.union_item[d.idx] =  d  
    gPendingSave.union_item[d._id] = d 
    for k, d in pairs(p.union_item ) do
        if gTime > d.tm+_tm+_tm2 then
            gPendingDelete.union_item[d._id] = 1 
            p.union_item[k] =  nil  
        end
    end
end

function show(p)--获取军团礼物列表
    if check_ply_cross(p) then
        local ret, val = remote_func(p.emap, "show", {"union_item", p.pid})
        if E_OK ~= ret then
            return
        end
        return val
    end

    local l = {}
    if not p.union_item then load_db(p.pid) end
    for _, v in pairs(p.union_item or {}) do
        local s = {idx=v.idx, propid=v.propid,src=v.src ,tmOver = (v.tm + _tm )}
        local p = getPlayer(v.s_pid)
        if p  then s.name = p.name end
        s.d_propid = v.d_propid
        table.insert(l,s )
    end
    return l 
end

function get(p,idx)--领取或清除军团礼物
    if check_ply_cross(p) then
        remote_cast(p.emap, "get", {"union_item", p.pid, idx})
        return
    end
    if not p.union_item then load_db(p.pid) end
    p.union_item= p.union_item or {}  
    local d  = p.union_item[idx] 
    if d then
        if gTime < d.tm + _tm then
            p:local_execute("add_bonus", d.propid[1], d.propid[2], VALUE_CHANGE_REASON.UNION_ITEM)
        end
        gPendingDelete.union_item[d._id] = 1 
        p.union_item[idx] =  nil  
        INFO( "[UNION]pid=%d,uid=%d,union_item is draw", p.pid,p.uid )
    end
end
