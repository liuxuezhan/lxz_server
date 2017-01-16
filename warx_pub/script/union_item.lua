--军团礼物模块
module(..., package.seeall)
_d={}
_tm = 24*60*60
function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_item:find({})
    while info:hasNext() do
        local data = info:next()
        local p = getPlayer(data._id)
        if p then
            p.union_item = copyTab(data) 
            p.union_item.item = {}  
            for _, v in pairs(data.item or {}) do
                if ( p.union_item.cur_idx or 0 ) <  v.idx  then p.union_item.cur_idx = v.idx end
                p.union_item.item[v.idx] = v
            end
        end
    end
end


function add(ply,propid,src,d_propid,pid)--加入军团礼物

    if src >= UNION_ITEM.MAX then return end 

    if not ply.union_item then
        ply.union_item = {_id=ply.pid,cur_idx=0,item={} }
        gPendingSave.union_item[ply.pid] = ply.union_item 
    end
    local d = ply.union_item 
    d.cur_idx = (d.cur_idx or 0)  + 1
    local t = {idx=d.cur_idx ,propid=propid,tm=gTime,src=src,d_propid=d_propid,pid=pid }
    d.item[t.idx] = t
    gPendingSave.union_item[ply.pid].item = d.item 
end

function show(ply)--获取军团礼物列表

    if not ply.union_item then ply.union_item = {_id=ply.pid,cur_idx=0,item={} } end
    local l = {}
    for _, v in pairs(ply.union_item.item or {}) do
        local s = {idx=v.idx, propid=v.propid,src=v.src ,tmOver = (v.tm + _tm )}
        local p = getPlayer(v.pid)
        if p  then
            s.name = p.name
        end
        s.d_propid = v.d_propid
        table.insert(l,s )
    end
    return l 
end

function get(ply,idx)--领取或清除军团礼物
    local v  = ply.union_item.item[idx] 
    if v then
        if gTime < v.tm + _tm then
            ply:add_bonus(v.propid[1], v.propid[2],VALUE_CHANGE_REASON.UNION_ITEM)
        end
        ply.union_item.item[idx]= nil 
        gPendingSave.union_item[ply.pid] = ply.union_item 
    end
end
