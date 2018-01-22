-- 军团商店模块
module(..., package.seeall)


function change()
    local db = dbmng:getOne()
    local info = db.union_mall:find({})
    while info:hasNext() do
        local d = info:next()
        for k, v in pairs(d.item or {}) do
            local t = {_id = d._id.."_"..v.propid, uid=d._id, propid=v.propid,num=v.num}  
            db.union_mall_item:insert(t)
        end

        for k, v in pairs(d.mark or {}) do
            local t = {_id = d._id.."_"..v.propid, uid=d._id, propid=v.propid}  
            db.union_mall_mark:insert(t)
        end

        for k, v in pairs(d.add or {}) do
            local t = { _id=bson.objectid(), uid=d._id, name = v.name,propid=v.propid,num=v.num,tm=v.tm }
            db.union_mall_add:insert(t)
        end

        for k, v in pairs(d.buy or {}) do
            local t = { _id=bson.objectid(), uid=d._id, name = v.name,propid=v.propid,num=v.num,tm=v.tm }
            db.union_mall_buy:insert(t)
        end
    end
    db.union_mall:delete({}) 
end

function add(p,propid,num)
    local u = unionmng.get_union(p:get_uid())
    if not u then return end
    local c = resmng.get_conf("prop_union_mall",propid)
    if u.donate < c.Donate*num then return end
    u.donate = u.donate - c.Donate*num

    u.mall_item = u.mall_item or {}  
    local d = u.mall_item[propid] or {_id = u.uid.."_"..propid, uid=u.uid, propid=propid,num=0}  
    d.num = d.num + num
    u.mall_item[propid] = d
    gPendingSave.union_mall_item[d._id] = d 

    if u.mall_mark then
        if u.mall_mark[propid] then
            u.mall_mark[propid]=nil
            gPendingDelete.union_mall_mark[u.uid.."_"..propid] = 1  
        end
    end

    local dd = { _id=bson.objectid(), uid=u.uid, name = p.name,propid=propid,num=num,tm=gTime }
    gPendingSave.union_mall_add[dd._id] = dd 
    u.mall_add = u.mall_add or {}  
    table.insert(u.mall_add, dd)

    u:notifyall("mall", resmng.OPERATOR.ADD,{propid=propid,num=d.num } )
end


function clear(uid)--删除军团时清除数据
    dbmng:getOne().union_mall_mark:delete({uid=uid})
    dbmng:getOne().union_mall_add:delete({uid=uid})
    dbmng:getOne().union_mall_buy:delete({uid=uid})
    dbmng:getOne().union_mall_item:delete({uid=uid})
end


function mark(p,propid,flag)
    local u = unionmng.get_union(p:get_uid())
    if not u then return false end
    u.mall_mark= u.mall_mark  or {} 
    local d  = u.mall_mark[propid] or { _id = u.uid.."_"..propid, uid = u.uid, propid=propid }  
    d[p.pid] = flag
    gPendingSave.union_mall_mark[d._id] = d 
    u.mall_mark[propid] = d  
    u:notifyall("mall_mark", resmng.OPERATOR.UPDATE,{pid=p.pid,name=p.name,propid=propid,flag=flag } )
end


function buy(p,propid,num)
    local u = unionmng.get_union(p:get_uid())
    if not u then return end
    
    u.mall_item = u.mall_item or {}
    local d = u.mall_item[propid]
    if not d then return end

    if  d.num < num then Rpc:tips(p,1,UNION_MALL_NUM_ERR,{}) return end
    local c = resmng.get_conf("prop_union_mall",propid)
    if p._union.donate < c.Val*num then return end

    p:local_execute("deliver_union_mall_item", c.Itemid, num, c.Val * num)

    d.num = d.num - num
    gPendingSave.union_mall_item[d._id].num = d.num 
    u.mall_item[propid].num = d.num

    local dd = { _id=bson.objectid(), uid=u.uid, name = p.name,propid=propid,num=num,tm=gTime }
    gPendingSave.union_mall_add[dd._id] = dd 
    u.mall_add = u.mall_add or {}  
    table.insert(u.mall_add, dd)

    local dd = { _id=bson.objectid(), uid=u.uid, name = p.name,propid=propid,num=num,tm=gTime }
    gPendingSave.union_mall_buy[dd._id] = dd 
    u.mall_buy = u.mall_buy or {}  
    table.insert(u.mall_buy,dd)

    u:notifyall("mall", resmng.OPERATOR.UPDATE,{propid=propid,num=d.num } )
end

function get_log(u,class)
    if class == 1 then
        for k, d in pairs(u.mall_add or {}) do
            if gTime - d.tm >= 60*60*24 *7 then
                gPendingDelete.union_mall_add[d._id] = 1 
                u.mall_add[k]=nil
            end
        end
        return (u.mall_add or {})
    else
        for k, d in pairs(u.mall_buy or {}) do
            if gTime - d.tm >= 60*60*24 *7 then
                gPendingDelete.union_mall_buy[d._id] = 1 
                u.mall_buy[k]=nil
            end
        end
        return (u.mall_buy or {})
    end
end

function get(uid)
    local u = unionmng.get_union(uid)
    if u then
        local mark = {}
        for propid, v in pairs(u.mall_mark or {}) do
            for k, v in pairs(v) do
                if type(k) == "number" and vv==1  then
                    local p = getPlayer(k)
                    table.insert(mark,{pid = k, propid = propid, name= p.name} )
                end
            end
        end
        return {list=u.mall_item,mark=mark}
    end
    return {list={},mark={} }
end


function load()--启动加载
    change()
    local db = dbmng:getOne()
    local info = db.union_mall_mark:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d.uid)
        if u then 
            u.mall_mark = u.mall_mark or {}  
            u.mall_mark[d.propid] = d 
        end
    end

    local info = db.union_mall_item:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d.uid)
        if u then 
            u.mall_item = u.mall_item or {}  
            u.mall_item[d.propid] = d 
        end
    end

    local info = db.union_mall_add:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d.uid)
        if u then 
            u.mall_add = u.mall_add or {}  
            table.insert(u.mall_add,d)
        end
    end

    local info = db.union_mall_buy:find({})
    while info:hasNext() do
        local d = info:next()
        local u = unionmng.get_union(d.uid)
        if u then 
            u.mall_buy = u.mall_buy or {}  
            table.insert(u.mall_buy,d)
        end
    end
end


