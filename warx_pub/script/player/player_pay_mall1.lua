module("player_t")

function change_pay_state()
    for _, p in pairs( gPlys or {}) do
        if p._pro.pay_state then
            local as = p._pro.pay_state
            as.pid = p.pid
            as._id = p.pid
            gPendingInsert.pay_state[p.pid] = as
            rawset( p, "_pay_state", as )
            p.pay_state = nil
            WARN( "update %d pay_state", p.pid )
        end
    end

    local db = dbmng:getOne()
    if db then
        db.player:update( {}, { ["$unset"]={ ["pay_state"]='', } }, false, true )
    else
        ERROR( "change_pay_state, can not get db" )
    end
end

function do_load_pay_state( self )
    if not self._pay_state then
        local bs = {}
        local db = self:getDb()
        local info = db.pay_state:find({_id=self.pid})
        if info then
            local bs = info:next() or {}
            if not self._pay_state then rawset(self, "_pay_state", bs) end
        end
    end
end

function get_pay_state(self, key)
    if not self._pay_state then do_load_pay_state(self) end
    if key then
        local node = self._pay_state[key] or {}
        if not node then
            node = {_id = self.pid.."_"..key, pid = self.pid}
            self._pay_state[key] = node
            gPendingSave.pay_state[node._id] = node
        end
        return node
    else
        return self._pay_state
    end
end

function set_pay_state(self, val)
    val._id = self.pid
    gPendingSave.pay_state[self.pid] = val
end

function set_pay_state1(self, key, val)
    local data = self:get_pay_state()
    if val == nil then
        gPendingDel.pay_state[self.pid][key] = 0
    else
        data[key] = val
        gPendingSave.pay_state[self.pid][key] = val
    end
end

function get_can_buy_list_req(self, force)
    local pack = {}
    local pay_state = self:get_pay_state()
    local can_buy_list = pay_state.can_buy_list or {}
    local last_refresh_timeline = pay_state.last_refresh_timeline or 0
    local last_buy_time = pay_state.last_buy_time 
    if check_daily_buy(last_buy_time) and get_table_valid_count(pay_state.daily_buy_history or {}) > 0 then
        pay_state.daily_buy_history = {}
        self:set_pay_state1("daily_buy_history", pay_state.daily_buy_history)  
    end

    if check_refresh(last_refresh_timeline ) then
        self:gen_can_buy_list(pay_state)
        pay_state.last_refresh_timeline = pay_mall.refresh_time
        pay_state.new_list = {}
        self:set_pay_state1("last_refresh_timeline", pay_state.last_refresh_timeline)  
        self:set_pay_state1("new_list", pay_state.new_list)  
        --pay_state.last_refresh_time = gTime
    end

    self._pay_state = pay_state
    --self:set_pay_state(pay_state)

    local normal_buy_list = {}
    for k, v in pairs( pay_state.normal_buy_list or {}) do
        local prop = resmng.prop_buy[v]
        if prop then
            normal_buy_list[k] = prop
        end
    end

    --gen_group_list(self, {[5]={idx=8,end_time=math.huge} }, pay_state)
    local gift_buy_list = {}
    for k, v in pairs( pay_state.gift_buy_list or {}) do
        local gift = copyTab(v)
        local list = {}

        for id, _ in pairs(v.list or {}) do
            local prop = resmng.prop_buy[id] or {}
            local item = copyTab(prop)
            item.count_by_daily = get_buy_count(pay_state.daily_buy_history or {}, id)
            item.count_by_life = get_buy_count(pay_state.buy_history or {}, id)
            list[id] = item
        end
        gift.list = list
        local prop = resmng.prop_buy_group[v.prop] or {}
        gift.prop = prop
        gift_buy_list[k] = gift
    end

    pack.normal_buy_list = normal_buy_list or {}
    pack.gift_buy_list = gift_buy_list or {}
    pack.new_list = pay_state.new_list

    Rpc:get_can_buy_list_ack(self, pack)
end

function gen_next_buy_list(ply, product_id)
    local pay_state = ply:get_pay_state()
   -- for k, v in pairs( pay_state.normal_buy_list or {}) do
   --     if v == product_id then
   --         pay_state.normal_buy_list[k] = nil
   --         local prop = resmng.prop_buy[id] or {}
   --         if get_table_valid_count(prop.Limited) > 0 then
   --             ply:add_can_buy_id(product_id,  pay_state.normal_buy_list)
   --         else
   --             for _, id in pairs(prop.Next or {}) do
   --                 ply:add_can_buy_id(id,  pay_state.normal_buy_list)
   --             end
   --         end
   --         break
   --     end
   -- end
    ply:gen_normal_buy_list(pay_state)
    local new_list = {}
    for k, v in pairs( pay_state.gift_buy_list or {}) do
        for id, _ in pairs(v.list or {}) do
            if id == product_id then
                v.list[id] = nil
                local prop = resmng.prop_buy[id] or {}
         --       if get_table_valid_count(prop.Limited) > 0 then
          --          ply:add_can_buy_id(id, v.list)
           --     else
                    for _, id in pairs(prop.Next or {}) do
                       if  ply:add_can_buy_id(id,  v.list) then
                           table.insert(new_list, id)
                       end
                    end
           --     end
                break
            end
        end
        pay_state.gift_buy_list[k] = v
    end
    pay_state.new_list = new_list
    ply:set_pay_state1("gift_buy_list", pay_state.gift_buy_list)
    ply:set_pay_state1("new_list", pay_state.new_list)
    ply:get_can_buy_list_req()
end

local do_record = {}

function check_daily_buy(last_buy_time)
    return can_date(last_buy_time)
end

function check_refresh(last_refresh_timeline)
    if last_refresh_timeline == 0 then
        return true
    end

    if pay_mall.refresh_time == 0 then
        return true
    end

    if gTime >= last_refresh_timeline then
        return true
    end

    return false
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
    self:gen_group_list(group, pay_state)
end

function gen_group_list(self, group, pay_state)
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
                    self:add_can_buy_id(id, list)
                end
            end
            info.list = list
            gift_buy_list[k] = info
        end
    end
    pay_state.gift_buy_list = gift_buy_list
    self:set_pay_state1("gift_buy_list", pay_state.gift_buy_list)
end

function add_can_buy_id( self, product_id, buy_list) --查看是否有高优先级的存在
    local prop = resmng.prop_buy[product_id]
    if prop then
        if prop.pre_id then
            if not self:add_can_buy_id(prop.pre_id, buy_list) then
                if self:check_cond(prop.Limited) then
                    buy_list[product_id] = product_id
                    return true
            --    elseif get_table_valid_count(prop.Limited) > 0 then
             --       for _, id in pairs(prop.Next or {}) do
             --           self:add_can_buy_id(id, buy_list)
             --       end
                end
            end
        else
            if  self:check_cond(prop.Limited) then
                buy_list[product_id] = product_id
                return true
           -- elseif get_table_valid_count(prop.Limited) > 0 then  
           --     for _, id in pairs(prop.Next or {}) do
           --         self:add_can_buy_id(id, buy_list)
           --     end
            end
        end
    end
    return false
end

function get_enable_group(self, pay_state)
    local group = {}
    local group_state = pay_state.group_state or {}
    for k, v in pairs(resmng.prop_buy_group or {}) do
        if v.Group == 1 then
            if not group[v.Group] then
                local index = math.ceil((gTime - get_sys_status("start") or 0 ) / v.Lasts) % 7 + 1
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
    self:set_pay_state1("normal_buy_list", pay_state.normal_buy_list)
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

function get_buy_count(history, id)
    return get_table_valid_count(history[id] or {})
end

check_each_cond = {}

check_each_cond["buy_peruser"] = function(ply, mode, action, id, num)
    local pay_state = ply:get_pay_state()
    local buy_history = pay_state.buy_history or {}
    local history = buy_history[id] or {}
    local count = get_table_valid_count(history or {} )
    return compare(count, num, action)
end

check_each_cond["buy_perday"] = function(ply, mode, action, id, num)
    local pay_state = ply:get_pay_state()
    local buy_history = pay_state.daily_buy_history or {}
    local history = buy_history[id] or {}
    local count = get_table_valid_count(history or {} )
    return compare(count, num, action)
end

check_each_cond["lv_build"] = function(ply, mode, action, con_lv)
    local lv = ply:get_castle_lv()
    return compare(lv, con_lv, action)
end

check_each_cond["lv_ply"] = function(ply, mode, action, con_lv)
    local lv = ply:get_castle_lv()
    return compare(lv, con_lv, action)
end

function is_in_can_buy_list(self, product_id)
    local pay_state = self:get_pay_state()

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
    local pay_state = self:get_pay_state()
    pay_state.last_buy_time = gTime
    self:set_pay_state1("last_buy_time", gTime)
    local prop = resmng.prop_buy[product_id]
    if prop then
        for k, v in pairs(prop.Limited or {}) do
            if do_record[v[1]] then
                do_record[v[1]](self, product_id)
            end
        end
    end
end

function agent_on_pay(self, product_id, real, map_id, force)
    LOG("agent_on_pay from map %d, pid %d, product_id %d", map_id, self.pid, product_id)
    return self:on_pay(product_id, real, force)
end

function on_pay( self, product_id, real, force)
    if real or ( not config.Release ) then
        local prop = resmng.prop_buy[product_id]
        if prop then
            WARN( "[pay], pid,%d, openid,%s, product_id,%d, price,%s, lv,%d, ip,%s", self.pid, self.account, product_id, prop.NewPrice_US or "0",  self.propid % 1000,  self.ip or "0.0.0.0" )

            if prop.Class == 2 then
                self:set_yueka(product_id)
            else
                if force == true then
                    WARN("GM GMC PAY send product without any limit pid %d, product_id %d ", self.pid, product_id)
                    self:do_pay(prop)
                    return {code = 1, msg = "success"}
                end

                if not self:check_can_buy(product_id) then
                    WARN("GM CMD PAY product id buy limited, pid %d, product_id %d ", self.pid, product_id)
                    return {code = 0, msg = "product buy limited"}
                end

                if not self:is_in_can_buy_list(product_id) then
                    WARN("GM CMD PAY product did not in buy list, pid %d, product_id %d ", self.pid, product_id)
                    return {code = 0, msg = "product did not in buy list"}
                end
                self:do_pay(prop)
            end

            self:process_order(product_id)
            self:gen_next_buy_list(product_id)
            return {code = 1, msg = "success"}
        end
    end
end

function do_pay(self, prop)
    local msg_ntf = gPendingBonus[ self.pid ]
    if not msg_ntf then
        msg_ntf = {}
        gPendingBonus[ self.pid ] = msg_ntf
    end

    if prop.Gold and prop.Gold > 0 then
        self:do_inc_res_normal(6, prop.Gold, VALUE_CHANGE_REASON.GM_PAY)
        table.insert(msg_ntf, {"res", 6, prop.Gold})
    end

    if prop.ExtraGold and prop.ExtraGold > 0 then
        self:do_inc_res_normal(6, prop.ExtraGold, VALUE_CHANGE_REASON.GM_PAY)
        table.insert(msg_ntf, {"res", 6, prop.ExtraGold})
    end

    if prop.Item_ExtraGift and prop.Item_ExtraGift > 0 then
        agent_t.gm_add_ply_item(self, {{"item", prop.Item_ExtraGift, 1, 10000}}, VALUE_CHANGE_REASON.GM_PAY)
    end
end

do_record["buy_peruser"] = function(ply, product_id)
    local pay_state = ply:get_pay_state()
    local buy_history = pay_state.buy_history or {}
    local history = buy_history[product_id] or {}
    table.insert(history, {product_id, gTime})
    buy_history[product_id] = history
    pay_state.buy_history = buy_history
    ply:set_pay_state1("buy_history", pay_state.buy_history)  
end

do_record["buy_perday"] = function(ply, product_id)
    local pay_state = ply:get_pay_state()
    local buy_history = pay_state.daily_buy_history or {}
    local history = buy_history[product_id] or {}
    table.insert(history, {product_id, gTime})
    buy_history[product_id] = history
    pay_state.daily_buy_history = buy_history
    ply:set_pay_state1("daily_buy_history", pay_state.daily_buy_history)  
end

