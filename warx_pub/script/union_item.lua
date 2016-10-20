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
            p.union_item = data.item
        end
    end
end


function add(ply,propid,src,d_propid,pid)--加入军团礼物
    if src >= UNION_ITEM.MAX then
        return
    end 

    if not ply.union_item then
        ply.union_item = {_id=ply.pid,cur_idx=0,item={} }
    end
    ply.union_item.cur_idx= ply.union_item.cur_idx + 1
    table.insert(ply.union_item.item,{idx=ply.union_item.cur_idx ,propid=propid,tm=gTime,src=src,d_propid=d_propid,pid=pid } )
    gPendingSave.union_item[ply.pid] = ply.union_item
end

function show(ply)--获取军团礼物列表
    if not ply.union_item then
        ply.union_item = {_id=ply.pid,cur_idx=0,item={} }
    end
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
    for k, v in pairs(ply.union_item.item or {}) do
        if v.idx == idx then
            if gTime <v.tm+_tm then
                ply:addItem(v.propid,1)
            end
            ply.union_item.item[k] = nil 
            gPendingSave.union_item[ply.pid] = ply.union_item
            return 
        end
    end
end
