module("player_t")
_cache_items = _cache_items or {}

function get_item(self, idx)
    if not self._item then
        local ms = {}
        local db = self:getDb()
        local info = db.item:findOne({_id=self.pid})
        if info then
            for k, v in pairs(info) do
                if k ~= "_id" then
                    ms[ tonumber(k) ] = v
                end
            end
        else
            db.item:insert({_id=self.pid})
        end
        --self._item = ms
        rawset(self, "_item", ms)
    end
    if not idx then return self._item
    else return self._item[ idx ] end
end

-- one item = {idx, id, num, extra ...}
function inc_item(self, id, num, reason)
    local its = self:get_item()
    local hit = false
    local idx = 0
    for k, v in pairs(its) do
        if v[2] == id and not v[4] then
            v[3] = v[3] + num
            hit = true
            idx = k
            break
        end
    end

    if not hit then
        for i = 1, 500, 1 do
            if not its[ i ] then
                its[ i ] = {i, id, num}
                idx = i
                break
            end
        end
    end

    self:add_item_pend(idx)

    reason = reason or VALUE_CHANGE_REASON.DEFAULT
    if reason == VALUE_CHANGE_REASON.DEFAULT then
        ERROR("inc_item: pid = %d, don't use the default reason.", self.pid)
    end
    LOG("inc_item: pid = %d, item_id = %d, num = %d, reason = %d.", self.pid, id, num, reason)
end

function add_item_pend(self, idx)
    local pid = self.pid
    local node = _cache_items[ pid ]
    if not node then
        node = {}
        _cache_items[ pid ] = node
    end
    local k = tostring(idx)
    node[ k ] = self._item[ idx ]
    node[ k ]._n_ = nil
end


--------------------------------------------------------------------------------
-- Function : 根据格子索引 idx 从 self 的背包中扣除 num 个物品
-- Argument : self, idx, num, reason
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function dec_item(self, idx, num, reason)
    if not self or not idx or not num or num <= 0 then
        ERROR("dec_item: pid = %d, idx = %d, num = %d", self and self.pid or -1, idx or -1, num or -1)
        return false
    end


    local item = self:get_item(idx)
    if item and item[3] >= num then
        item[3] = item[3] - num
        self:add_item_pend(idx)

        reason = reason or VALUE_CHANGE_REASON.DEFAULT
        if reason == VALUE_CHANGE_REASON.DEFAULT then
            ERROR("dec_item: pid = %d, don't use the default reason.", self.pid)
        end
        LOG("dec_item: pid = %d, idx = %d, item_id = %d, num = %d, reason = %d.", self.pid, idx, item[2], num, reason)
        --任务
        task_logic_t.process_task(self, TASK_ACTION.USE_ITEM, id, num)
        return true
    else
        LOG("dec_item: pid = %d, idx = %d, item_id = %d, num = %d > have = %d", self.pid, idx, item[2], num, item and item[3] or -1)
        return false
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 item_id 从 self 的背包中扣除 num 个物品
-- Argument : self, item_id, num, reason
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function dec_item_by_item_id(self, item_id, num, reason)
    if not self or not item_id or not num or num <= 0 then
        ERROR("dec_item_by_item_id: pid = %d, item_id = %d, num = %d", self and self.pid or -1, item_id or -1, num or -1)
        return false
    end

    local item_have = self:get_item_num(item_id)
    if num > item_have then
        LOG("dec_item_by_item_id: pid = %d, item_id = %d, num = %d > have = %d", self.pid, item_id, num, item_have)
        return false
    end

    -- TODO: 之后估计会添加物品有效期，到时这里的代码需要修改，优先删除快过期的
    local item_list = self:get_item()
    local item_need_del = num
    for idx, item in pairs(item_list) do
        if item[2] == item_id then
            if item[3] >= item_need_del then
                item[3] = item[3] - item_need_del
                item_need_del = 0
            else
                item[3] = 0
                item_need_del = item_need_del - item[3]
            end
            self:add_item_pend(idx)
        end

        if item_need_del == 0 then
            break
        end
    end

    reason = reason or VALUE_CHANGE_REASON.DEFAULT
    if reason == VALUE_CHANGE_REASON.DEFAULT then
        ERROR("dec_item_by_item_id: pid = %d, don't use the default reason.", self.pid)
    end
    INFO("dec_item_by_item_id: pid = %d, item_id = %d, num = %d, reason = %d.", self.pid, item_id, num, reason)
    return true
end


function addItem(self, id, num)
    self:inc_item(id, num, VALUE_CHANGE_REASON.DEBUG)
    --任务
    task_logic_t.process_task(self, TASK_ACTION.GET_ITEM, id, num)
end


function get_item_num(self, id)
    local its = self:get_item()
    local total = 0
    for k, v in pairs(its) do
        if v[2] == id then
            total = total + v[3]
        end
    end
    return total
end

-- function use_item(self, idx, num)
--     local item = self:get_item(idx)
--     if self:dec_item(idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
--         local conf = resmng.get_conf("prop_item", item[2])
--         if conf then
--             -- 此接口屏蔽英雄技能物品的使用，被扣除了道具活该 ^_^
--             if conf.Class ~= ITEM_CLASS.SKILL then
--                 if not conf.Action then return Mark() end

--                 if not item_func[ conf.Action ] then
--                     self:inc_item(conf.ID, num, VALUE_CHANGE_REASON.USE_ERROR)
--                     WARN( "no item function, Action = %s, id = %s", conf.Action, conf.ID )
--                     return
--                 end

--                 local res = item_func[conf.Action](self, num, unpack(conf.Param or {}))
--                 if res == "noAction" then
--                     self:inc_item(conf.ID, num, VALUE_CHANGE_REASON.USE_ERROR)
--                 end
--             else
--                 ERROR("use_item: conf.Class = %d", conf.Class)
--             end
--         end
--     end
-- end


--------------------------------------------------------------------------------
-- Function : 清空背包
-- Argument : NULL
-- Return   : NULL
-- Others   : debug func.
--------------------------------------------------------------------------------
function clear_item(self)
    local item_list = self:get_item()
    for idx, item in pairs(item_list) do
        self:dec_item(idx, item[3], VALUE_CHANGE_REASON.DEBUG)
    end
end


--------------------------------------------------------------------------------
-- Function : 将 cons 按照已有和需要购买进行拆分
-- Argument : self; cons = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
-- Return   : succ - cons_have, cons_need_buy; fail - nil, nil
-- Others   : cons 中只能是道具或者资源
--------------------------------------------------------------------------------
function split_cons(self, cons)
    if not cons then
        ERROR("split_cons: no cons.")
        return
    end

    local cons_have = {}
    local cons_need_buy = {}
    for _, con in pairs(cons) do
        if con[3] > 0 then
            if con[1] == resmng.CLASS_RES then
                local res_have = self:get_res_num(con[2])
                if not res_have then
                    ERROR("split_cons: wrong resource type, con[2] = %d", con[2] or -1)
                    return
                end

                if res_have > con[3] then
                    table.insert(cons_have, con)
                else
                    table.insert(cons_need_buy, {con[1], con[2], con[3] - res_have})
                    if res_have > 0 then
                        table.insert(cons_have, {con[1], con[2], res_have})
                    end
                end
            elseif con[1] == resmng.CLASS_ITEM then
                local have = self:get_item_num(con[2])
                if have >= con[3] then
                    table.insert(cons_have, con)
                else
                    table.insert(cons_need_buy, {con[1], con[2], con[3] - have})
                    if have > 0 then
                        table.insert(cons_have, {con[1], con[2], have})
                    end
                end
            else
                ERROR("split_cons: wrong con, neither resmng.CLASS_ITEM nor resmng.CLASS_RES, but %d", con[1] or -1)
                return
            end
        end
    end

    return cons_have, cons_need_buy
end


--------------------------------------------------------------------------------
-- Function : 统计 cons_list 总共值多少金币
-- Argument : cons = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
-- Return   : succ - gold_num; fail - math.huge
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_cons_value(cons_list)
    --if not cons_list then
    --    ERROR("calc_cons_value: no cons_list.")
    --    return math.huge
    --end

    --for _, v in pairs(cons_list) do
    --    gold_num = gold_num + get_con_price(v[1], v[2]) * v[3]
    --end

    --return gold_num
    
    local gold_num = 0
    for _, v in pairs(cons_list) do
       if v[1] == resmng.CLASS_RES then
           gold_num = gold_num + calc_buyres_gold(v[3], v[2])
       end
    end
    return gold_num
end


--------------------------------------------------------------------------------
-- Function : 查询 con 价值
-- Argument :  _class, id
-- Return   : gold_num
-- Others   : NULL
--------------------------------------------------------------------------------
function get_con_price(_class, id)
    -- TODO: 数值未定，这里返回1作测试用
    do return 1 end

    if _class == resmng.CLASS_RES then
    elseif _class == resmng.CLASS_ITEM then
    end
end


--------------------------------------------------------------------------------
-- Function : 扣除 cons_list 中的资源和道具
-- Argument : self, cons_list, reason, not_check_num(跳过数量校验)
-- Return   : succ - true; fail - false
-- Others   : not_check_num = true 时，调用者需要自己保证数量足够扣除!!!
--            cons_list = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
--------------------------------------------------------------------------------
function dec_cons(self, cons_list, reason, not_check_num)
    if not cons_list then
        ERROR("dec_cons: no cons_list. pid = %d.", self.pid)
        return false
    end

    if not not_check_num then
        for _, con in pairs(cons_list) do
            if con[1] == resmng.CLASS_RES then
                local res_have = self:get_res_num(con[2])
                if not res_have then
                    ERROR("dec_cons: wrong resource type, con[2] = %d", con[2] or -1)
                    return false
                end

                if res_have < con[3] then
                    LOG("dec_cons: resouce(%d) not enough. need = %d, have = %d", con[2], con[3], res_have)
                    return false
                end
            elseif con[1] == resmng.CLASS_ITEM then
                local item_have = self:get_item_num(con[2])
                if item_have < con[3] then
                    LOG("dec_cons: item(%d) not enough. need = %d, have = %d.", con[2], con[3], item_have)
                    return false
                end
            end
        end
    end

    for _, con in pairs(cons_list) do
        if con[1] == resmng.CLASS_RES then
            self:do_dec_res(con[2], con[3], reason)

        elseif con[1] == resmng.CLASS_ITEM then
            self:dec_item_by_item_id(con[2], con[3], reason)
        end
    end

    return true
end


--------------------------------------------------------------------------------
-- Function : 发放 cons_list 中的资源和道具，与 dec_cons 对应
-- Argument : self, cons_list, reason
-- Return   : NULL
-- Others   : cons_list = {{resmng.CLASS_ITEM, item_id, item_num}, {resmng.CLASS_RES, res_id, res_num}, ...}
--------------------------------------------------------------------------------
function inc_cons(self, cons_list, reason)
    if not cons_list then
        ERROR("inc_cons: no cons_list. pid = %d.", self.pid)
        return false
    end

    for _, con in pairs(cons_list) do
        if con[1] == resmng.CLASS_RES then
            self:do_inc_res_protect(con[2], con[3], reason)

        elseif con[1] == resmng.CLASS_ITEM then
            self:inc_item(con[2], con[3], reason)
        end
    end
end

function material_compose(self, id)
    local node = resmng.get_conf("prop_item", id)
    if not node then return ack(self, "material_compose", resmng.E_FAIL) end
    if node.Class ~= ITEM_CLASS.MATERIAL then return ack(self, "material_compose", resmng.E_FAIL) end
    local prenode = resmng.get_conf("prop_item", id-1)
    if not prenode then return ack(self, "material_compose", resmng.E_FAIL) end
    if not self:dec_item_by_item_id(prenode.ID, resmng.MATERIAL_COMPOSE_COUNT, VALUE_CHANGE_REASON.COMPOSE) then return ack(self, "material_compose", resmng.E_FAIL) end
    self:inc_item(id, 1, VALUE_CHANGE_REASON.COMPOSE)
    self:reply_ok("material_compose", id)
    --任务
    task_logic_t.process_task(self, TASK_ACTION.SYN_MATERIAL, id, 1)
end


function material_decompose(self, id)
    local node = resmng.get_conf("prop_item", id)
    if not node then return ack(self, "material_decompose", resmng.E_FAIL) end
    if node.Class ~= ITEM_CLASS.MATERIAL then return ack(self, "material_decompose", resmng.E_FAIL) end
    local prenode = resmng.get_conf("prop_item", id-1)
    if not prenode then return ack(self, "material_decompose", resmng.E_FAIL) end
    if not self:dec_item_by_item_id(node.ID, 1, VALUE_CHANGE_REASON.DECOMPOSE) then return ack(self, "material_decompose", resmng.E_FAIL) end
    self:inc_item(prenode.ID, resmng.MATERIAL_COMPOSE_COUNT, VALUE_CHANGE_REASON.DECOMPOSE)
    self:reply_ok("material_decompose", id)
end

function buy_item(self, id, num, use)
    if num < 0 then return end
    local conf = resmng.get_conf("prop_mall", id)
    if conf then
        local cost = math.ceil(conf.NewPrice * num)
        if self:doCondCheck(resmng.CLASS_RES, resmng.DEF_RES_GOLD, cost) then
            self:doConsume(resmng.CLASS_RES, resmng.DEF_RES_GOLD, cost, VALUE_CHANGE_REASON.MALL_PAY)
            if use == 1 then
                for k, v in pairs( conf.Item ) do
                    local flag = false
                    if v[1] == "item" then
                        local itemid = v[2]
                        local itemnum = v[3]
                        local itemp = resmng.get_conf( "prop_item", itemid )
                        if itemp then
                            if itemp.Action then
                        --        item_func[ itemp.Action ]( self, itemnum * num, unpack(itemp.Param or {} ) )
                            player_t.use_item_logic[itemp.Action](self,itemp.ID, num, itemp)
                                flag = true
                            end
                        end
                    end
                    if not flag then
                        self:add_bonus("mutex_award", {v},  VALUE_CHANGE_REASON.MALL_BUY, num)
                    end
                end
            else
                self:add_bonus("mutex_award", conf.Item,  VALUE_CHANGE_REASON.MALL_BUY, num)
            end
        end
    end
end



