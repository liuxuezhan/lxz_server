-- 军团商店模块
module(..., package.seeall)

function add(ply,propid,num)
    local u = unionmng.get_union(ply:get_uid())
    if not u then return false end
    if not u.mall then
        u.mall= { _id=u.uid,add={},buy={},mark={}}
    end
    local c = resmng.get_conf("prop_union_mall",propid)
    if u.donate < c.Donate*num then return end
    u.donate = u.donate - c.Donate*num

    local cur_num = 0
    for _, v in pairs(u.mall.item or {}) do
        if v.propid == propid then
            v.num = v.num + num
            cur_num = v.num
            break
        end
    end

    if cur_num == 0 then
        if not u.mall.item then u.mall.item={} end
        table.insert(u.mall.item,{propid=propid,num=num})
        cur_num = num
    end

    for k, v in pairs(u.mall.mark or {}) do
        if v.propid == propid then
            u.mall.mark[k]=nil
        end
    end

    table.insert(u.mall.add,{name = ply.name,propid=propid,num=num,tm=gTime})
    gPendingSave.union_mall[u.uid] = u.mall
    u:notifyall("mall", resmng.OPERATOR.ADD,{propid=propid,num=cur_num } )
end

function clear(uid)--删除军团时清除数据
    dbmng:getOne().union_mall:delete({_id=uid})
end

function mark(ply,propid,flag)
    local u = unionmng.get_union(ply:get_uid())
    if not u then return false end
    if not u.mall then
        u.mall= { _id=u.uid,add={},buy={},mark={}}
    end
    local f = 0
    for k, v in pairs(u.mall.mark or {}) do
        if v.propid == propid  and v.pid == ply.pid then
            if flag == 0 then
                u.mall.mark[k]=nil
                gPendingSave.union_mall[u.uid] = u.mall
                u:notifyall("mall_mark", resmng.OPERATOR.UPDATE,{pid=ply.pid,name=ply.name,propid=propid,flag=flag } )
            end
            return
        end
    end

    if flag == 1 then
        table.insert(u.mall.mark,{pid = ply.pid,propid=propid,})
        gPendingSave.union_mall[u.uid] = u.mall
        u:notifyall("mall_mark", resmng.OPERATOR.UPDATE,{pid=ply.pid,name=ply.name,propid=propid,flag=flag } )
    end
end

function buy(ply,propid,num)
    local u = unionmng.get_union(ply:get_uid())
    if not u then return false end

    if not u.mall then return false end

    for _, v in pairs(u.mall.item or {}) do
        if v.propid == propid then
            if  v.num < num then Rpc:tips(ply,1,UNION_MALL_NUM_ERR,{}) return end

            local c = resmng.get_conf("prop_union_mall",propid)
            if ply._union.donate < c.Val*num then return end

            ply._union.donate = ply._union.donate - c.Val*num
            gPendingSave.union_member[ply.pid] = ply._union

            v.num = v.num - num
            table.insert(u.mall.buy,{name=ply.name,propid=propid,num=num,tm=gTime})
            gPendingSave.union_mall[ply.uid] = u.mall
            ply:inc_item(c.Itemid, num, VALUE_CHANGE_REASON.UNION_MALL)
            u:notifyall("mall", resmng.OPERATOR.UPDATE,{propid=propid,num=v.num } )
            return 
        end
    end
end

function get_log(u,type)
    if u.mall then
        if type == 1 then
            for k, v in pairs(u.mall.add or {}) do
                if gTime - v.tm >= 60*60*24 *7 then
                    u.mall.add[k]=nil
                    gPendingSave.union_mall[u.uid].add = u.mall.add
                end
            end
            return (u.mall.add or {})
        else
            for k, v in pairs(u.mall.buy or {}) do
                if gTime - v.tm >= 60*60*24 *7 then
                    u.mall.buy[k]=nil
                    gPendingSave.union_mall[u.uid].buy = u.mall.buy
                end
            end
            return (u.mall.buy or {})
        end
    else
        return  {}
    end
end

function get(uid)
    local u = unionmng.get_union(uid)
    if  u and u.mall then
        local mark = {}
        for k, v in pairs(u.mall.mark or {}) do
            local p = getPlayer(v.pid)
            v.name = p.name
            table.insert(mark,v)
        end
        return {list=u.mall.item,mark=mark}
    end
    return {list={},mark={} }
end

function load()--启动加载
    local db = dbmng:getOne()
    local info = db.union_mall:find({})
    while info:hasNext() do
        local data = info:next()
        local u = unionmng.get_union(data._id)
        if u then
            u.mall = data
        end
    end
end


