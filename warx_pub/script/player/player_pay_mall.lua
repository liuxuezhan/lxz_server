module("player_t")

function get_can_buy_list_req(self, force)
    local pack = {}
    local pay_state = self.pay_state or {}
    local can_buy_list = pay_state.can_buy_list or {}
    local last_refresh_time = pay_state.last_refresh_time or 0
    local last_buy_time = pay_state.last_buy_time 
    if check_daily_buy(last_buy_time) and get_table_valid_count(pay_state.daily_buy_history or {}) > 0 then
        pay_state.daily_buy_history = {}
    end

    if check_refresh(last_refresh_time ) then
        self:gen_can_buy_list(pay_state)
        pay_state.last_refresh_time = pay_mall.refresh_time
    end

    self.pay_state = pay_state

    local normal_buy_list = {}
    for k, v in pairs( pay_state.normal_buy_list or {}) do
        local prop = resmng.prop_buy[v]
        if prop then
            normal_buy_list[k] = prop
        end
    end

    local gift_buy_list = {}
    for k, v in pairs( pay_state.gift_buy_list or {}) do
        local gift = copyTab(v)
        local list = {}
        for id, _ in pairs(v.list or {}) do
            local prop = resmng.prop_buy[id] or {}
            list[id] = prop
        end
        gift.list = list
        local prop = resmng.prop_buy_group[v.prop] or {}
        gift.prop = prop
        gift_buy_list[k] = gift
    end

    pack.normal_buy_list = normal_buy_list or {}
    pack.gift_buy_list = gift_buy_list or {}

    Rpc:get_can_buy_list_ack(self, pack)
end

local do_record = {}

function check_daily_buy(last_buy_time)
    return can_date(last_buy_time)
end

function check_refresh(last_refresh_time)
    if last_refresh_time == 0 then
        return true
    end
    if last_refresh_time >= (pay_mall.refresh_time or gTime) then
        return false
    end
   -- if last_refresh_time == gTime then
   --     return true
   -- end
   -- if (gTime - last_refresh_time) > 60 then
   --     local clock = os.date("*t", last_refresh_time)
   --     local now = os.date("*t", gTime)
   --     if clock.hour ~= now.hour then
   --         return true
   --     end
   -- end
   -- return false
end

function gen_can_buy_list(self, pay_state)
    self:gen_normal_buy_list(pay_state)

    self:gen_gift_list(pay_state)
end

function gen_gift_list(self, pay_state)
    --local group = self:get_enable_group(self, pay_state) or {}
    local group = pay_mall.get_enable_group()

    gen_group_list(self, group, pay_state)
end

function gen_group_list(self, group, pay_state)
    local gift_buy_list = {}
    for k, v in pairs(group or {}) do
        local info = {}
        local list = {}
        local prop = resmng.prop_buy_group[v.idx]
        if prop then
            info.prop = v.idx
            info.end_time = v.end_time
            for _, id in pairs(prop.GiftList or {}) do
                self:add_can_buy_id(id, list)
            end
        end
        info.list = list
        gift_buy_list[k] = info
    end
    pay_state.gift_buy_list = gift_buy_list
end

function add_can_buy_id( self, product_id, buy_list) --查看是否有高优先级的存在
    local prop = resmng.prop_buy[product_id]
    if prop then
        if prop.pre_id then
            if not self:add_can_buy_id(prop.pre_id, buy_list) then
                if self:check_cond(prop.Limited) then
                    buy_list[product_id] = product_id
                else
                    for _, id in pairs(prop.Next or {}) do
                        self:add_can_buy_id(id, buy_list)
                    end
                end
            end
        else
            if self:check_cond(prop.Limited) then
                buy_list[product_id] = product_id
            else
                for _, id in pairs(prop.Next or {}) do
                    self:add_can_buy_id(id, buy_list)
                end
            end
        end
    end
end

function get_enable_group(self, pay_state)
    local group = {}
    local group_state = pay_state.group_state or {}
    for k, v in pairs(resmng.prop_buy_group or {}) do
        if v.Group == 1 then
            if not group[v.Group] then
                local index = math.ceil((gTime - _G.gSysStatus.start) / v.Lasts) % 7 + 1
                local prop = resmng.prop_buy_group[index]
                if prop then
                    if self:check_cond(prop.Cond) then
                        group[v.Group] = v.ID
                    end
                end
            end
        else
            if check_cond(v.Cond) then
                group[v.Group] = k
            end
        end
    end
    return group
end

function gen_normal_buy_list(self, pay_state)
    local normal_buy_list = {}
    for k, v in pairs(resmng.prop_buy or {}) do
        if v.Class == 0 then
            if self:check_can_buy( k) then
                normal_buy_list[k] = k
            end
        end
    end
    pay_state.normal_buy_list = normal_buy_list
end

function check_can_buy( self, product_id) --查看是否有高优先级的存在
    local prop = resmng.prop_buy[product_id]
    if prop then
        if prop.pre_id then
            if self:check_can_buy(prop.pre_id) then
                return false
            else
                return self:check_cond(prop.Limited)
            end
        else
            return self:check_cond(prop.Limited)
        end
    end
    return false
end

function check_cond(self, conditions)
    local ret = true
    for k, condition in pairs(conditions or {}) do
        if check_each_cond[condition[1]] then
            ret = ret and check_each_cond[condition[1]](self, unpack(condition))
            if ret == false then
                return flase
            end
        end
    end
    return true
end

function compare(num1, num2, action)
    if action == "<" then
        return num1 < num2
    end
    if action == ">" then
        return num1 > num2
    end
    if action == "<=" then
        return num1 <= num2
    end
    if action == ">=" then
        return num1 >= num2
    end
    if action == "==" then
        return num1 == num2
    end
    if action == "~=" then
        return num1 ~= num2
    end
end

check_each_cond = {}

check_each_cond["buy_peruser"] = function(ply, mode, action, id, num)
    local pay_state = ply.pay_state or {} 
    local buy_history = pay_state.buy_history or {}
    local history = buy_history[id] or {}
    local count = get_table_valid_count(history or {} )
    return compare(count, num, action)
end

check_each_cond["buy_perday"] = function(ply, mode, action, id, num)
    local pay_state = ply.pay_state or {} 
    local buy_history = pay_state.daily_buy_history or {}
    local history = buy_history[id] or {}
    local count = get_table_valid_count(history or {} )
    return compare(count, num, action)
end

check_each_cond["buildlevel"] = function(ply, mode, action, id,  num)
    return true
end

function is_in_can_buy_list(self, product_id)
    local pay_state = self.pay_state or {}

    local normal_buy_list = pay_state.normal_buy_list or {}
    if normal_buy_list[product_id] then
        return true
    end

    for _, group in pairs(pay_state.gift_buy_list or {}) do
        local list = group.list or {}
        if list[product_id] then
            return true
        end
    end


    return false
end

function process_order(self, product_id)
    local pay_state = self.pay_state or {}
    pay_state.last_refresh_time = 0 --强制刷新标记
    local prop = resmng.prop_buy[product_id]
    if prop then
        for k, v in pairs(prop.Limited or {}) do
            if do_record[v[1]] then
                do_record[v[1]](self, product_id)
            end
        end
    end
end

function on_pay( self, product_id, real )
    if real or ( not config.Release ) then
        local prop = resmng.prop_buy[product_id]
        if prop then
            if product_id == 50 or product_id == 51 then
                self:set_yueka()
            else
                if not self:check_can_buy(product_id) then
                    LOG("GM CMD PAY product id buy limited")
                    return {code = 0, msg = "product buy limited"}
                end

                if not self:is_in_can_buy_list(product_id) then
                    LOG("GM CMD PAY product did not in buy list")
                    return {code = 0, msg = "product did not in buy list"}
                end

                
                if prop.Gold and prop.Gold > 0 then
                    self:do_inc_res_normal(6, prop.Gold, VALUE_CHANGE_REASON.GM_PAY)
                end

                if prop.ExtraGold and prop.ExtraGold > 0 then
                    self:do_inc_res_normal(6, prop.ExtraGold, VALUE_CHANGE_REASON.GM_PAY)
                end

                if prop.Item_ExtraGift and prop.Item_ExtraGift > 0 then
                    agent_t.gm_add_ply_item(self, {{"item", prop.Item_ExtraGift, 1, 10000}}, VALUE_CHANGE_REASON.GM_PAY)
                end
            end

            self:process_order(product_id)
            self:get_can_buy_list_req()
            return {code = 1, msg = "success"}
        end
    end
end

do_record["buy_peruser"] = function(ply, product_id)
    local pay_state = ply.pay_state or {}
    local buy_history = pay_state.buy_history or {}
    local history = buy_history[product_id] or {}
    table.insert(history, {product_id, gTime})
    buy_history[product_id] = history
    pay_state.buy_history = buy_history
    ply.pay_state = pay_state
end

do_record["buy_perday"] = function(ply, product_id)
    local pay_state = ply.pay_state or {}
    local buy_history = pay_state.daily_buy_history or {}
    local history = buy_history[product_id] or {}
    table.insert(history, {product_id, gTime})
    buy_history[product_id] = history
    pay_state.daily_buy_history = buy_history
    ply.pay_state = pay_state
end

