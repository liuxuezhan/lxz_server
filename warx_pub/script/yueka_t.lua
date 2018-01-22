module(..., package.seeall) -- 月卡模块

function load_db(p)--启动加载
    local db = dbmng:getOne()
    local info = db.yueka:find({pid=p.pid})
    if info then
        while info:hasNext() do
            local d = info:next()
            local p = getPlayer(d.pid)
            if p then 
                p.yueka = p.yueka or {} 
                p.yueka[d.groupid] = d
            end
        end
    end
end

function buy(p,id)
    if not p.yueka then load_db(p) end
    for _, d in pairs( p.yueka or {} ) do
        if is_in_table(d.buy_id,id) and d.new==1 then 
            local c = resmng.get_conf("prop_buy", id)
            if not c then 
                WARN("[yueka] pid=%d,buyid=%d buy conf fail",p.pid,id)
                return 
            end
            local days,item = c.Bonus[2],c.Bonus[3]
            local num = d.num1 + d.num2
            if num == 0 or (get_days(gTime) - d.cur) > num then --超时清零 
                d.num1,d.num2 = 0,0 
                if d.cur ~= get_days(gTime) then d.cur = get_days(gTime)-1 end
            end

            if c.Hot == 1 then --优惠
                d.num1 = d.num1 + days 
            else --普通
                d.num2 = d.num2 + days 
            end

            if next(item) then
                p:add_bonus(item[1], item[2], VALUE_CHANGE_REASON.REASON_YUEKA)
            end
            p.yueka[d.groupid] = d 
            gPendingSave.yueka[d._id] = d 
            Rpc:get_yueka(p, p.yueka)
            INFO("[yueka] pid=%d,buyid=%d buy ok",p.pid,id)
            return 
        end
    end
    WARN("[yueka] pid=%d,buyid=%d buy fail",p.pid,id)
end

function new(p,groupid) --新类型月卡
    local group_conf = resmng.get_conf("prop_buy_month_card_group",groupid)
    if not group_conf then 
       WARN("[yueka] pid=%d,groupid=%d prop_buy_month_card_group not config(2)",p.pid,groupid)
       return 
    end 
    local d = { _id = p.pid.."_"..groupid, pid=p.pid, groupid=groupid, 
                -----购买数据-------
                buy_id={}, 
                last={0,0},--购买时间
                new = 0,--是否可购买
                -----领取数据-------
                cur=get_days(gTime)-1, 
                num1=0, 
                num2=0,
                } 

    if group_conf.Discount_Open_Time then --先判断优惠
        local start,last = group_conf.Discount_Open_Time[1],group_conf.Discount_Open_Time[2]
        if next(start) then 
            start = tab_to_timestamp(group_conf.StartTime ) 
        else
            start = p.tm_create 
        end 
        local over  = 0  
        if last then over = start + last  else over = math.huge  end 
        if gTime >= start and gTime <= over  then 
            d.new = 1
            d.buy_id = group_conf.Discount_Yueka_List
            d.last = {start,last or 0}
            return d  
        end
    end

    if group_conf.Open_Time then --判断普通
        local start,last = group_conf.Open_Time[1],group_conf.Open_Time[2]
        if next(start) then 
            start = tab_to_timestamp(group_conf.StartTime ) 
        else
            start = p.tm_create 
        end 
        local over  = 0  
        if last then over = start + last  else over = math.huge  end 
        if gTime >= start and gTime <= over  then 
            d.new = 1
            d.buy_id = group_conf.Yueka_List
            d.last = {start,last or 0}
            return d  
        end
    end
    return d  
end

function one(p,groupid)
    local group_conf = resmng.get_conf("prop_buy_month_card_group",groupid)
    if not group_conf then 
       WARN("[yueka] pid=%d,groupid=%d prop_buy_month_card_group not config(1)",p.pid,groupid)
       return 
    end 
    if not p.yueka then load_db(p) end
    if not p.yueka[groupid] then 
        local d = new(p,groupid)
        p.yueka[groupid] = d 
        gPendingSave.yueka[d._id] = d  
        return
    else
        local d = p.yueka[groupid]
        local start,last = d.last[1],d.last[2]
        local over  = 0  
        if last~=0 then over = start + last else over = math.huge  end 

        if gTime >= start and gTime <= over  then 
            return   
        else 
            local c = resmng.get_conf("prop_buy", d.buy_id[1])
            if not c then 
                WARN("[yueka] pid=%d,id=%d prop_buy not config",p.pid,d.buy_id[1])
                return 
            end
            if c.Hot==0 then--普通
                p.yueka[groupid].new = 0 
                gPendingSave.yueka[d._id].new = 0  
                WARN("[yueka] pid=%d,groupid=%d Open_Time err(1)",p.pid,groupid)
                return   
            elseif c.Hot==1 then--优惠
                if not group_conf.Open_Time then 
                    WARN("[yueka] pid=%d,groupid=%d not Open_Time(1)",p.pid,groupid)
                    if p.yueka[groupid].new ~= 0 then 
                        p.yueka[gropid].new = 0 
                        gPendingSave.yueka[d._id].new = 0  
                        return   
                    end
                else --判断普通
                    local start,last = group_conf.Open_Time[1],group_conf.Open_Time[2]
                    if next(start) then 
                        start = tab_to_timestamp(group_conf.StartTime ) 
                    else
                        start = p.tm_create 
                    end 
                    local over  = 0  
                    if last then over = start + last  
                    else over = math.huge  end 
                    if gTime >= start and gTime <= over  then 
                        d.new = 1
                        d.buy_id = group_conf.Yueka_List
                        d.last = {start,last or 0}
                        p.yueka[groupid] = d 
                        gPendingSave.yueka[d._id] = d  
                        return   
                    else
                        p.yueka[groupid].new = 0 
                        gPendingSave.yueka[d._id].new = 0  
                        WARN("[yueka] pid=%d,groupid=%d Open_Time err(2)",p.pid,groupid)
                        return   
                    end
                end
            end
        end
    end
end

function get(p) --查询
    if not p.yueka then load_db(p) end
    p.yueka = p.yueka or {} 
    for id, _ in pairs( resmng.prop_buy_month_card_group or {} ) do
        one(p,id)
    end
    return p.yueka  
end

function draw(p, groupid)--领取
    local c = resmng.get_conf("prop_buy_month_card_group", groupid)
    if not c then 
        WARN( "[yueka] pid=%d,groupid=%d draw config fail",p.pid,groupid )
        return 
    end 

    if c.Type~=1 then 
        WARN( "[yueka] pid=%d,groupid=%d draw config type err",p.pid,groupid )
        return 
    end 

    if not p.yueka then load_db(p) end
    if not p.yueka then 
        WARN( "[yueka] pid=%d,groupid=%d draw data fail",p.pid,groupid )
        return 
    end 
    local d = p.yueka[groupid] 
    if not d then 
        WARN( "[yueka] pid=%d,groupid=%d draw data group fail",p.pid,groupid )
        return 
    end 
    local item 
    local num = get_days(gTime) - d.cur --跨天领取
    if num == 0 then 
        WARN( "[yueka] pid=%d,groupid=%d already draw ",p.pid,groupid )
        return 
    end 
    if num <= d.num1 then  
        d.num1 = d.num1 - num
        item = c.Discount_Item
    else
        num = num - d.num1 
        d.num1 = 0 
        if num > d.num2 then 
            d.num2 = 0 
        else
            d.num2 = d.num2 - num
            item = c.Item
        end
    end
    d.cur = get_days(gTime)
    p.yueka[groupid] = d 
    gPendingSave.yueka[d._id] = d 
    if item then 
        p:add_bonus(item[1], item[2], VALUE_CHANGE_REASON.REASON_YUEKA) 
        INFO("[yueka] pid=%d,groupid=%d draw ok",p.pid,groupid)
    else
        WARN("[yueka] pid=%d,groupid=%d draw timeout",p.pid,groupid)
    end
    Rpc:get_yueka(p, p.yueka)
end

