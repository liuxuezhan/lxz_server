--军团礼物模块
module(..., package.seeall)
_tm = 24*60*60
function load(pid)--启动加载
    local db = dbmng:getOne()
    local info 
    if pid then
        info = db.union_item:find({_id=pid})
    else
        info = db.union_item:find({})
    end
    while info:hasNext() do
        local data = info:next()
        local p = getPlayer(data._id)
        if p then
            p.u_item = copyTab(data) 
            p.u_item.item = {}  
            for _, v in pairs(data.item or {}) do
                if ( p.u_item.cur_idx or 0 ) <  v.idx  then p.u_item.cur_idx = v.idx end
                p.u_item.item[v.idx] = v
            end
        end
    end
end


function add(p,propid,src,d_propid,pid)--加入军团礼物

    INFO( "[UNION]pid=%d,uid=%d, src=%d add union_item", p.pid,p.uid, src )
    if src >= UNION_ITEM.MAX then return end 

    if not p.u_item then
        p.u_item = {_id=p.pid,cur_idx=0,item={} }
        gPendingSave.union_item[p.pid] = p.u_item 
    elseif type(p.u_item) ~= "table" then 
        INFO( "[UNION]pid=%d,uid=%d,u_item is not table", p.pid,p.uid )
    end
    local d = p.u_item 
    d.cur_idx = (d.cur_idx or 0)  + 1
    local t = {idx=d.cur_idx ,propid=propid,tm=gTime,src=src,d_propid=d_propid,pid=pid }
    local item = d.item or {}
    item[t.idx] = t
    d.item = item
    gPendingSave.union_item[p.pid].item = d.item 
end

function show(ply)--获取军团礼物列表

    if not ply.u_item then ply.u_item = {_id=ply.pid,cur_idx=0,item={} } end
    local l = {}
    for _, v in pairs(ply.u_item.item or {}) do
        local s = {idx=v.idx, propid=v.propid,src=v.src ,tmOver = (v.tm + _tm )}
        local p = getPlayer(v.pid)
        if p  then s.name = p.name end
        s.d_propid = v.d_propid
        table.insert(l,s )
    end
    return l 
end

function get(ply,idx)--领取或清除军团礼物
    local v  = ply.u_item.item[idx] 
    if v then
        if gTime < v.tm + _tm then
            ply:add_bonus(v.propid[1], v.propid[2],VALUE_CHANGE_REASON.UNION_ITEM)
        end
        ply.u_item.item[idx]= nil 
        gPendingSave.union_item[ply.pid] = ply.u_item 
    end
end
