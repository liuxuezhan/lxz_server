module("player_t")

-- task_id 与配置用ID一致
-- _id 是任务的唯一标识

function reset_hero_task(self)  -- 每日重置
    local reset_key = {"accept_time", "help_time"}
    for k, v in pairs(reset_key) do
        self:set_hero_task(v)
    end
end

function random_tab_and_rem(tab)
    tab = tab or {}
    local tmp_tab = {}
    for k in pairs(tab) do
        table.insert(tmp_tab, k)
    end
    local ele =  tab[tmp_tab[math.random(#tmp_tab)]]
    tab[tmp_tab[math.random(#tmp_tab)]] = nil
    return ele
end

function find_valid_task_by_idx(self, idx)
    local cur_list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST) or {}
    for _, unit in pairs(cur_list or {}) do
        if unit.idx == idx and unit.status ~= TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
            return unit
        end
    end
    return 
end

function gen_single_task(self, idx)
    local cur_list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
    local pool = self:get_undisplay_task_pool()
    local conf = resmng.get_conf("prop_hero_task_init", idx)
    if conf then
        local conf_id = random_tab_and_rem(pool[conf.TaskType])
        local prop = resmng.get_conf("prop_hero_task_detail", conf_id)
        if prop then
            local task_id = prop.ID
            local unit = {}
            unit._id = string.format( "%d_%d_%d", self.pid, task_id, gTime ) 
            if prop.TaskType == 3 then
                unit.pid = self.pid
                unit.uid = self.uid
            end
            unit.task_id = task_id
            unit.status = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
            unit.idx = k
            self:set_hero_task(HERO_TASK_MODE.CUR_LIST, task_id, unit)
            return unit
        else
            WARN( "prop_hero_task_init, id = %d, invalid", k )
        end
    end
end

function gen_hero_task_list(self)  -- 生成任务
    local list = {}
    local pool = self:get_hero_task_pool() --- rem accept task from pool
    local cur_list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
    for k, v in pairs(resmng.prop_hero_task_init or {}) do
        --local idx = math.random(get_table_valid_count(pool[v.TaskType]))
        local task = find_valid_task_by_idx(self, idx) -- find accept task replace new task_list
        if task then
            list[task.task_id] = task
        else
            local conf_id = random_tab_and_rem(pool[v.TaskType] or {})
            local prop = resmng.get_conf("prop_hero_task_detail", conf_id)
            if prop then
                local task_id = prop.ID
                local unit = {}
                unit._id = string.format( "%d_%d_%d", self.pid, task_id, gTime ) 
                if prop.TaskType == 3 then
                    unit.pid = self.pid
                    unit.uid = self.uid
                end
                unit.task_id = task_id
                unit.status = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
                unit.idx = k
                list[task_id] = unit
            else
                WARN( "prop_hero_task_init, id = %d, invalid", k )
            end
        end
    end
    return list
end

function get_hero_task_list_req(self)
    local pack = {}
    local last_refresh_tm = self:get_hero_task("last_refresh_tm") or 0
    local last_tm = os.date("*t", last_refresh_tm)
    local now = os.date("*t", gTime)
    local list = {}
 --   if last_refresh_tm == 0 or last_refresh_tm - gTime >= 28800 or ((last_tm.hour % 2) == 1 and (now.hour % 2) == 0) then
    if can_date(last_refresh_tm, gTime) then
        self:reset_hero_task()
    end
    if last_refresh_tm == 0 or last_refresh_tm - gTime >= 28800 or math.abs((last_tm.hour % 8) - (now.hour % 8 )) >= 1 then
        list = self:gen_hero_task_list()
        self:set_hero_task(HERO_TASK_MODE.CUR_LIST, list)
        self:set_hero_task("last_refresh_tm", gTime)
    else
        list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
    end
    pack[HERO_TASK_MODE.CUR_LIST] = list
    pack[HERO_TASK_MODE.HELP_LIST] = self:get_can_help_list()
    pack["accetp_time"] = self:get_hero_task("accetp_time")
    pack["help_time"] = self:get_hero_task("help_time")
    Rpc:get_hero_task_list_ack(self, pack)
end

function get_can_help_list(self)
    local union = self:get_union()
    if union then
        return union.hero_task or {}
        --local pack = {}
        --pack[HERO_TASK_MODE.HELP_LIST] = union.hero_task or {}
        --Rpc:get_hero_task_list_ack(self, pack)
    end
end

function refresh_hero_task_list_req(self) -- 刷新英雄任务
    if self:can_refresh_list() then
        self:dec_refresh_consume()
        local list = self:gen_hero_task_list()
        self:set_hero_task(HERO_TASK_MODE.CUR_LIST, list)
        self:set_hero_task("last_refresh_tm", gTime)
    else
        return
    end
end

function get_refresh_price()
    local prop = resmng.get_conf("prop_hero_task_init", resmng.HERO_TASK_1)
    if prop then
        return prop.RefreshPrice or 100
    end
    return 100
end

function can_refresh_list(self)
    local gold_need = get_refresh_price()
    if gold_need > 0 and self.gold >= gold_need then
        return true
    end
    LOG("refresh hero task: pid = %d, player.gold(%d) < gold_need(%d)", self.pid, self.gold, gold_need)
    return false
end

function dec_refresh_consume(self)
    local gold_need = get_refresh_price()
    self:dec_gold(gold_need, VALUE_CHANGE_REASON.REFRESH_HERO_TASK)
end

function accept_hero_task_req(self, task_id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_CAN_ACCEPTE then
            task.status = TASK_STATUS.TASK_STATUS_ACCEPTED
            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, task)
        end
    end
    Rpc:update_hero_task_ack(self, task)
end

function add_hero_task_help_req(self, task_id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            local union = self:get_union()
            if union then
                if task.tmSn then
                    union_help.add(self, task.tmSn)
                end
            end
        end
    end
end

function cancel_hero_task_req(self, task_id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_CAN_ACCEPTE or task.status == TASK_STATUS.TASK_STATUS_DOING then
            task.status = TASK_STATUS.TASK_STATUS_CAN_ACCEPTE
            if task.status == TASK_STATUS.TASK_STATUS_DOING then
                if task.tmSn then
                    union_help.del(self, task.tmSn)
                end
                union_hero_task.del(task)
            end
            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, task)
            Rpc:update_hero_task_ack(self, task)
        end
    end
end

function acc_hero_task_req(self, task_id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_DOING then
            local prop = resmng.get_conf("prop_hero_task_detail", task_id)
            if prop then
                local tm = timer.get(task.tmSn)
                if not tm then
                    return
                end

                local dura = task.tmOver - gTime
                if dura < 0 then
                    dura = 0 
                end

               -- if not prop.AccGold then
               --     ERROR("acc hero task spend is null pid = %d, task_id = %d", self.pid, id)
               --     return
               -- end
               --

               local need_gold = calc_acc_gold( dura )
               if need_gold > 0 then
                   if self:get_res_num(resmng.DEF_RES_GOLD) < need_gold  then
                       return 
                   end
                   self:do_dec_res(resmng.DEF_RES_GOLD, need_gold, VALUE_CHANGE_REASON.ACC_HERO_TASK)
                   timer.adjust(task.tmSn, gTime)
                   task.tmOver = gTime
                   self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, task)
                   Rpc:update_hero_task_ack(self, task)
                   --if dura - prop.AccTime > 0 then
                   --    timer.acc(task.tmSn, prop.AccTime)
                   --    task.tmOver = task.tmOver - prop.AccTime
                   -- end
               end
           end
       end
   end
end

function get_hero_task_award_req(self, task_id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
            local prop = resmng.get_conf("prop_hero_task_detail", task_id)
            if prop.EventCondition or task.do_event == false then

                local accept_tm = self:get_hero_task("accept_time")
                if accept_tm >= 6 then
                    return 
                end
                self:add_bonus( "mutex_award", prop.Bonus, VALUE_CHANGE_REASON.HERO_TASK_NORMAL)
                task.status = TASK_STATUS.TASK_STATUS_FINISHED
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, nil)
                local new_task = self:gen_single_task(task.idx)
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, new_task)
                self:set_hero_task("accept_time", accept_tm + 1)
                Rpc:update_hero_task_ack(self, new_task)
            end
        end
    end
end

function help_acc_hero_task(self, task_id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_DOING then
            local prop = resmng.get_conf("prop_hero_task_detail", task_id)
            if prop then
                local tm = timer.get(task.tmSn)
                if not tm then
                    return
                end

                local dura = task.tmOver - gTime
                if dura < 0 then
                    dura = 0 
                end

                if dura - prop.HelpAccTime > 0 then
                    timer.acc(task.tmSn, prop.AccTime)
                    task.tmOver = task.tmOver - prop.HelpAccTime
                else
                    timer.adjust(task.tmSn, gTime)
                    task.tmOver = gTime
                end
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, task)
            end
        end
        Rpc:update_hero_task_ack(self, task)
    end
end

function get_hero_task_pool(self)
    local pools = copyTab(hero_task_pool or {})
    local list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST) or {}
    for task_id, unit in pairs(list or {}) do
        if unit.status ~= TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
            local prop = resmng.get_conf("prop_hero_task_detail", pool[v.TaskType][idx])
            if prop then
                pools[prop.TaskType][task_id] = nil
            end
        end
    end
    return pools
end

function get_undisplay_task_pool(self)
    local pools = copyTab(hero_task_pool or {})
    local list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST) or {}
    for task_id, unit in pairs(list or {}) do
        local prop = resmng.get_conf("prop_hero_task_detail", pool[v.TaskType][idx])
        if prop then
            pools[prop.TaskType][task_id] = nil
        end
    end
    return pools
end

function init_hero_task_pool()
    local pools = {{},{},{}}
    for k, v in pairs(resmng.prop_hero_task_detail or {}) do
        pools[v.TaskType][k] = k
        --table.insert(pools[v.TaskType], k)
    end
    return pools
end

hero_task_pool =  init_hero_task_pool() or {{},{},{}}

function get_hero_task(self, what1, what2)  -- 玩家内存数据库基础操作
    if not self._hero_task then
        local db = self:getDb()
        local info = db.ache:findOne({_id = self.pid})
        for k, v in pairs(info or {}) do
            if v.uid then
                info.k = union_hero_task.get(v.uid, v._id)  -- union hero task load from union_hero_task
            end
        end
        self._hero_task = info or {}
    end
    if what1 then
        return self._hero_task[ what1 ] 
    elseif what2 then
        if self._hero_task[ what1 ] then
            return
        else
            return self._hero_task[ what1 ][ what2 ]
        end
    else
        return self._hero_task
    end
end

function set_hero_task2(self, key1, key2, val) -- 
    local hero_task = self:get_hero_task()
    local val1 = hero_task[key1] or {}
    if not val then
        local del_val = val1[key2]
    end
    val1[key2] = val
    hero_task[key1] = val1
    if key1 == HERO_TASK_MODE.CUR_LIST and val.uid then -- union hero task save in ply and union_hero_task but load from union_hero_task only
        if val then
            union_hero_task.mark(val)
        end
        if del_val then
            union_hero_task.del(del_val)
        end
        return
    end
    gPendingSave.hero_task[ self.pid ][key1] = val1
end

function set_hero_task(self, key ,val)
    local hero_task = self:get_hero_task()
    hero_task[key] = val
    if key == HERO_TASK_MODE.CUR_LIST then
        for _, v in pairs(val) do
            if v.uid then
                union_hero_task.mark(v)
            end
        end
    end
    gPendingSave.hero_task[ self.pid ][key] = val
end

function update_hero_task_tm(task, tm_id) -- update ref did not save 
    local node = timer.get(id)
    if node then
        task.tmSn = tm_id
        task.tmOver = node.over
    end
end

------------------- multiplayer  hero task
function add_task_hero_by_ply(self, task_id, heros)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
    if task then
        if task.pid ~= self.pid then
            return
        end

        local prop = resmng.get_conf("prop_hero_task_detail", task_id)
        if prop then
            local main_heros = task.main_heros or {}
            if get_table_valid_count(main_heros) == 0 then
                for _, hero_id in pairs(heros or {}) do
                    main_heros[hero_id] = hero_id
                end
                task.main_heros = main_heros
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, task)
                Rpc:update_hero_task_ack(self, task)
            end
        end
    end
end

function add_task_hero_by_helper(self, _id, hero_id)
    local task = union_hero_task.get_by_id(_id)
    if task then
        if task.pid == self.pid then
            return
        end
        if task.uid ~= self.uid then
            return
        end

        local prop = resmng.get_conf("prop_hero_task_detail", task_id)
        if prop then
            local help_tm = self:get_hero_task("help_time")
            if help_tm >= 6 then
                return 
            end

            local help_heros = task.help_heros or {}
            if get_table_valid_count(help_heros) < prop.HelpHeroNum then
                local task_plys = task.task_plys or {}
                if not task_plys[self.pid] then
                    task_plys[self.pid] = {pid = self.pid}
                    help_heros[hero_id] = hero_id
                end
                task.help_heros = help_heros
                task.help_plys = help_plys
                union_hero_task.mark(task)
                self:set_hero_task("help_time", help_tm + 1)
                Rpc:update_hero_task_ack(self, task)
            end
        end
    end

end

function init_fight_cards()
    local max = 27
    local cards = {}
    for i = 1, max , 1 do
        table.insert(cards, i)
    end
    local tab1 = {}
    local tab2 = {}
    for j = 1, max, 1 do
        local idx = math.random(#{cards})
        if (j % 9) == 1 then
            tab2 = {}
            table.insert(tab1, tab2)
        end
        table.insert(tab2, cards[idx])
        table.remove(cards, idx)
    end
    return cards
end

function set_fight_cards(task)
    local task_plys = task.task_plys or {}
    if #{task_plys} ~= 3 then
        return
    end

    local task_cards = init_fight_cards()
    local idx = 1
    for _, task_ply in pairs(task_plys or {})  do
        task_ply.cards = task_cards[idx]
        idx = idx + 1
    end
    union_hero_task.mark(task)
end

function set_fight_order(self, _id, hero_order)
    local task = union_hero_task.get_by_id(_id)
    local check_order = function(order)  -- check fight order 
        local check_list = {1,1,1}
        for _, v in pairs(order or {}) do
            if check_list[v] == 1 then
                check_list[v] = 0
            else
                return true
            end
        end
        return false
    end

    if task then
        if task.uid ~= self.uid then
            return
        end

        local prop = resmng.get_conf("prop_hero_task_detail", task_id)
        if not prop then
            return
        end

        if #{hero_order} ~= 3 then
            return
        end

        if check_order(hero_order) then
            return
        end

        local task_plys = task.task_plys or {}
        local task_ply = task_plys[self.pid]
        if not task_ply then
            return
        end
        local order = task_ply.order or {1,1,1,1,1,1,1,1,1}
        for _, idx in pairs(hero_order) do
            table.insert(order, idx)
        end
        task_ply.order = order

        union_hero_task.mark(task)
    end
end

function is_hero_in_task(task, hero_id)
    local main_heros = task.main_heros or {}
    if main_heros[hero_id] then
        return true
    end
    local help_heros = task.help_heros or {} 
    if help_heros[hero_id] then
        return true
    end
    return false
end

function hero_task_fight(self, _id)
    local is_win = function(A, B)
        local card_1 = A % 3
        local card_2 = B % 3
        if (card_1 + 1) % 3 ==  card_2 then 
            return false
        elseif card_1 == card_2  and A < B then
            return false
        end
        return true
    end

    local task = union_hero_task.get_by_id(_id)
    if not task.task_plys then
        return
    end
    local task_plys = task.task_plys

    local task_ply1 = task_plys[self.pid]
    local card1 = copyTab(task_ply.cards or {})

    local task_ply2 = {}    --- 我头太胀是在想不起来怎么搞了。
    local card2 = {}
    local task_ply3 ={}
    local card3 = {}
    local temp = 1
    for pid, ply in pairs(task_plys or {}) do
        if pid ~= self.pid then
            if temp == 1 then
                task_ply2 = ply
                card2 = copyTab(ply or {})
                temp = temp + 1
            elseif temp == 2 then
                task_ply3 = ply
                card3 = copyTab(ply or {})
            end
        end
    end

    local win_num = task_ply.win_num or 0
    for i = 1, 9, 1 do
        if win_num >= 2 then
            return true
        end
        local A = table.remove(card1, task_ply1.order[i])
        local B = table.remove(card2, task_ply2.order[i])
        if is_win(A, B) then
            local C = table.remove(card2, task_ply2.order[i])
            if is_win(A, C) then
                win_num = win_num + 1
            end
        end
    end
    return false
end

function check_event_condition(task, event_cond)
    local heros = {}
    for _, h_id in pairs(task.main_heros or {}) do
        table.insert(heros, h_id)
    end
    for _, h_id in pairs(task.help_heros or {}) do
        table.insert(heros, h_id)
    end

    -- cond {"prop_type", val, num}
    local tag = true
    for _, cond in pairs(event_cond or {}) do
        tag = false
        local num = 0
        for _, h_id in pairs(heros or {}) do
            local h = heromng.get_hero_by_uniq_id(h_id)
            if h then
                local prop = resmn.get_conf("prop_hero_basic", h.propid)
                if prop then
                    if prop[cond[1]] == cond[2] then
                        num = num + 1
                    end
                end
            end
            if num >= cond[3] then
                tag = true
            end
        end
        if tag == false then
            return false
        end
    end
    return tag
end

------------------- multiplayer  hero task
