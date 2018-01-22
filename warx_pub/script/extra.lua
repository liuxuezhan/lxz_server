
player_t.gen_group_list = function(self, group, pay_state)
    local gift_buy_list =  pay_state.gift_buy_list or {}
    local dels = {}

    for k, v in pairs(gift_buy_list) do
        if not group[k] then
            table.insert(dels, k)
        end
    end

    for k, v in pairs(dels) do
        gift_buy_list[v] = nil
    end

    for k, v in pairs(group or {}) do
        if gTime < v.end_time then
            local info = {}
            local list = {}
            local prop = resmng.prop_buy_group[v.idx]
            if prop then
                info.prop = v.idx
                info.end_time = v.end_time
                for _, id in pairs(prop.GiftList or {}) do
                    player_t.add_can_buy_id(self, id, list)
                end
            end
            info.list = list
            gift_buy_list[k] = info
        end
    end
    pay_state.gift_buy_list = gift_buy_list
end

pay_mall.gen_enable_group = function()
    pay_mall.group = {}
    for k, v in pairs(resmng.prop_buy_group or {}) do
        if v.FrontReq == 0 then
            local time, num, is_cyclic = pay_mall.get_group_time(v)
            local start_time = tab_to_timestamp(v.StartTime or {})
            local left = gTime - start_time
            if left >= time then
                if is_cyclic then
                    local idx, end_time = pay_mall.get_group_idx(left % time, k)

                    if pay_mall.refresh_time == 0 or end_time < pay_mall.refresh_time then
                        pay_mall.refresh_time = end_time
                    end
                     pay_mall.group[v.Group] = {idx = idx, end_time = end_time }
                end
            elseif left < time and left >= 0 then
                local idx,  end_time =  pay_mall.get_group_idx(left, k)

                if  pay_mall.refresh_time == 0 or end_time <  pay_mall.refresh_time then
                     pay_mall.refresh_time = end_time
                end

                local prop = resmng.prop_buy_group[idx]
                 pay_mall.group[v.Group] = {idx = idx, end_time = end_time }
            elseif left < 0 then
                if  pay_mall.refresh_time == 0 or start_time <  pay_mall.refresh_time then
                     pay_mall.refresh_time = start_time
                end
            end
        end
    end
    gPendingSave.status["pay_mall"].refresh_time =  pay_mall.refresh_time
    gPendingSave.status["pay_mall"].group =  pay_mall.group
    return  pay_mall.group
end

resmng.prop_buy[81] = { ID = 81, Class = 1, Mode = 1, Level = 11, Gold = 200, ExtraGold = 100, Item_ExtraGift = 2100072, OldPrice = 270, NewPrice = 6, Discount = 4503, Bonus = nil, Limited = {{"buy_perday","<",81,1}}, Hot = 1, Next = {82}, pre_id = nil, AppleBuyID = "wm.app.credit1", NewPrice_US = 0.99,}
resmng.prop_buy[82] = { ID = 82, Class = 1, Mode = 2, Level = 11, Gold = 700, ExtraGold = 300, Item_ExtraGift = 2100073, OldPrice = 669, NewPrice = 30, Discount = 2230, Bonus = nil, Limited = {{"buy_perday","<",82,1}}, Hot = 1, Next = {83}, pre_id = nil, AppleBuyID = "wm.app.credit2", NewPrice_US = 4.99,}
resmng.prop_buy[83] = { ID = 83, Class = 1, Mode = 3, Level = 11, Gold = 1600, ExtraGold = 400, Item_ExtraGift = 2100074, OldPrice = 1482, NewPrice = 68, Discount = 2179, Bonus = nil, Limited = {{"buy_perday","<",83,1}}, Hot = 1, Next = {84}, pre_id = nil, AppleBuyID = "wm.app.credit4", NewPrice_US = 9.99,}
resmng.prop_buy[84] = { ID = 84, Class = 1, Mode = 4, Level = 11, Gold = 3400, ExtraGold = 600, Item_ExtraGift = 2100075, OldPrice = 2245, NewPrice = 128, Discount = 1754, Bonus = nil, Limited = {{"buy_perday","<",84,1}}, Hot = 1, Next = {}, pre_id = nil, AppleBuyID = "wm.app.credit6", NewPrice_US = 19.99,}

resmng.prop_buy_group[9] = { ID = 9, Cond = nil, FrontReq = 0, StartTime = {2017,12,30}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
resmng.prop_buy_group[10] = { ID = 10, Cond = nil, FrontReq = 0, StartTime = {2017,12,31}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
resmng.prop_buy_group[11] = { ID = 11, Cond = nil, FrontReq = 0, StartTime = {2018,1,1}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
resmng.prop_buy_group[12] = { ID = 12, Cond = nil, FrontReq = 0, StartTime = {2018,1,2}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
resmng.prop_buy_group[13] = { ID = 13, Cond = nil, FrontReq = 0, StartTime = {2018,1,3}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
resmng.prop_buy_group[14] = { ID = 14, Cond = nil, FrontReq = 0, StartTime = {2018,1,4}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
resmng.prop_buy_group[15] = { ID = 15, Cond = nil, FrontReq = 0, StartTime = {2018,1,5}, GiftList = {81}, Group = 2, Lasts = 86400, NextListID = {},}
