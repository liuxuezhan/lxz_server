module("player_t")

function get_can_buy_list_req(self)
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

    if player_t.debug_tag then
        self:gen_can_buy_list(pay_state)
    end
    self.pay_state = pay_state

    pack.normal_buy_list = pay_state.normal_buy_list or {}
    pack.gift_buy_list = pay_state.gift_buy_list or {}

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
            info.prop = prop
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
                    buy_list[product_id] = prop
                else
                    for _, id in pairs(prop.Next or {}) do
                        self:add_can_buy_id(id, buy_list)
                    end
                end
            end
        else
            if self:check_cond(Limited) then
                buy_list[product_id] = prop
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
                normal_buy_list[k] = v
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
        if check_each_cond[condition] then
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

check_each_cond["peruser"] = function(ply, mode, action, id, num)
    local pay_state = self.pay_state or {} 
    local buy_history = pay_state.buy_history or {}
    local history = buy_history[id] or {}
    local count = get_table_valid_count(history[id] or {} )
    return compare(count, action, num)
end

check_each_cond["perday"] = function(ply, mode, action, id, num)
    local pay_state = self.pay_state or {} 
    local buy_history = pay_state.daily_buy_history or {}
    local history = buy_history[id] or {}
    local count = get_table_valid_count(history[id] or {} )
    return compare(count, action, num)
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
        if group[product_id] then
            return true
        end
    end

    return false
end

function process_order(self, product_id)
    local prop = resmng.prop_buy[product_id]
    if prop then
        for k, v in pairs(prop.Limited or {}) do
            if do_record[v[1]] then
                do_record[v[1]](self, product_id)
            end
        end
    end
end

do_record["peruser"] = function(ply, product_id)
    local pay_state = ply.pay_state or {}
    local buy_history = pay_state.buy_history or {}
    local history = buy_history[product_id] or {}
    table.insert(history, {product_id, gTime})
    buy_history[product_id] = history
    pay_state.buy_history = buy_history
    ply.pay_state = pay_state
end

do_record["perday"] = function(ply, product_id)
    local pay_state = ply.pay_state or {}
    local buy_history = pay_state.daily_buy_history or {}
    local history = buy_history[product_id] or {}
    table.insert(history, {product_id, gTime})
    buy_history[product_id] = history
    pay_state.daily_buy_history = buy_history
    ply.pay_state = pay_state
end

