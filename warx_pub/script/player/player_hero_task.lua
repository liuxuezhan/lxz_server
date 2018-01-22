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
    for k, _ in pairs(tab) do
        table.insert(tmp_tab, k)
    end
    local idx = math.random(#tmp_tab)
    local ele =  tab[tmp_tab[idx]]
    tab[tmp_tab[idx]] = nil
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
            if prop.TaskType == 2 then
                unit.uid = self.uid
            end
            unit.task_id = task_id
            unit.owner_name = self.name
            unit.task_type = prop.TaskType
            unit.status = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
            unit.idx = idx
            unit.pid = self.pid
            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, unit._id, unit)
            INFO("[HERO TASK], gen new single task pid=%d, idx=%d, propid=%d", self.pid, idx, task_id)
            return unit
        else
            WARN( "prop_hero_task_init, id = %d, invalid", k )
        end
    end
end

function gen_hero_task_list(self)  -- 生成任务
    INFO("[HERO TASK], gen hero task pid=%d", self.pid)
    local list = {}
    local pool = self:get_hero_task_pool() --- rem accept task from pool
    local cur_list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
    for k, v in pairs(resmng.prop_hero_task_init or {}) do
        --local idx = math.random(get_table_valid_count(pool[v.TaskType]))
        local task = find_valid_task_by_idx(self, k) -- find accept task replace new task_list
        if task then
            list[task._id] = task
        else
            local conf_id = random_tab_and_rem(pool[v.TaskType] or {})
            local prop = resmng.get_conf("prop_hero_task_detail", conf_id)
            if prop then
                local task_id = prop.ID
                local unit = {}
                unit._id = string.format( "%d_%d_%d", self.pid, task_id, gTime ) 
                if prop.TaskType == 2 then
                    unit.uid = self.uid
                end
                unit.owner_name = self.name
                unit.pid = self.pid
                unit.task_id = task_id
                unit.task_type = prop.TaskType
                unit.status = TASK_STATUS.TASK_STATUS_CAN_ACCEPT
                unit.idx = k
                list[unit._id] = unit
            else
                WARN( "prop_hero_task_init, id = %d, invalid", k )
            end
        end
    end
    return list
end

function get_hero_task_list_req(self)
    if check_ply_cross(self) then
        ack(self, "get_hero_task_list_req", resmng.E_FAIL, 0)
        return
    end
    local pack = {}
    local last_refresh_tm = self:get_hero_task("last_refresh_tm") or 0
    local last_tm = os.date("*t", last_refresh_tm)
    local now = os.date("*t", gTime)
    local list = {}
 --   if last_refresh_tm == 0 or last_refresh_tm - gTime >= 28800 or ((last_tm.hour % 2) == 1 and (now.hour % 2) == 0) then
    if can_date(last_refresh_tm, gTime) then
        INFO("[HERO TASK], reset hero task pid=%d, last_refresh_tm=%d, gTime=%d", self.pid, last_refresh_tm, gTime)
        self:reset_hero_task()
    end
    if last_refresh_tm == 0 or last_refresh_tm - gTime >= 28800 or math.abs((last_tm.hour % 8) - (now.hour % 8 )) >= 1 then
        INFO("[HERO TASK], refresh hero task pid=%d, last_refresh_tm=%d, gTime=%d", self.pid, last_refresh_tm, gTime)
        list = self:gen_hero_task_list()
        self:set_hero_task(HERO_TASK_MODE.CUR_LIST, list)
        self:set_hero_task("last_refresh_tm", gTime)
    else
        list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
    end
    pack[HERO_TASK_MODE.CUR_LIST] = list
    pack[HERO_TASK_MODE.HELP_LIST] = self:get_can_help_list()
    pack["accept_time"] = self:get_hero_task("accept_time") or 0
    pack["help_time"] = self:get_hero_task("help_time") or 0
    pack["next_refresh_tm"] = get_next_refresh_tm()
    Rpc:get_hero_task_list_ack(self, pack)
end

function get_next_refresh_tm()
    local now = os.date("*t", gTime)
    now.hour = math.floor(now.hour / 8) * 8
    now.min = 0
    now.second = 0
    local tm = os.time(now) + 8 * 3600
    return tm
end

function get_can_help_list(self)
    local union = self:get_union()
    if union then
        local task_list = copyTab(union.hero_task or {})
        for id, task in pairs(task_list or {}) do
            if task.pid == self.pid then
                task_list[id] = nil
            end
            if task.status == TASK_STATUS.TASK_STATUS_CAN_FINISH  then
                if task.task_plys then
                    if not task.task_plys[self.pid] then
                        task_list[id] = nil
                    end
                end
            elseif task.status == TASK_STATUS.TASK_STATUS_CAN_EVENT then
                if task.task_plys then
                    if not task.task_plys[self.pid] then
                        task_list[id] = nil
                    end
                end
            elseif task.status == TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
                task_list[id] = nil
            elseif task.status == TASK_STATUS.TASK_STATUS_DOING then
                if get_table_valid_count(task.task_plys or {}) == 3 then
                    if not task.task_plys[self.pid] then
                        task_list[id] = nil
                    end
                end
            end
            if task.task_plys then
                if task.task_plys[self.pid] then
                    if task.task_plys[self.pid].status == TASK_STATUS.TASK_STATUS_FINISHED then
                        task_list[id] = nil
                    end
                end
            end
        end

        return task_list
        --local pack = {}
        --pack[HERO_TASK_MODE.HELP_LIST] = union.hero_task or {}
        --Rpc:get_hero_task_list_ack(self, pack)
    end
end

function refresh_hero_task_list_req(self) -- 刷新英雄任务
    if check_ply_cross(self) then
        ack(self, "refresh_hero_task_list_req", resmng.E_FAIL, 0)
        return
    end
    if self:can_refresh_list() then
        self:dec_refresh_consume()
        local list = self:gen_hero_task_list()
        self:set_hero_task(HERO_TASK_MODE.CUR_LIST, list)
        self:set_hero_task("last_refresh_tm", gTime)
        local pack = {}
        pack[HERO_TASK_MODE.CUR_LIST] = list 
        pack[HERO_TASK_MODE.HELP_LIST] = self:get_can_help_list()
        pack["accept_time"] = self:get_hero_task("accept_time") or 0
        pack["help_time"] = self:get_hero_task("help_time") or 0
        pack["next_refresh_tm"] = get_next_refresh_tm()
        Rpc:get_hero_task_list_ack(self, pack) 
    else
        ack(self, "refresh_hero_task_list_req", resmng.E_FAIL, 0)
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
    INFO("[HERO TASK], refresh hero task pid=%d, consume_gold=%d", self.pid, gold_need)
    if gold_need > 0 then
        self:dec_gold(gold_need, VALUE_CHANGE_REASON.REFRESH_HERO_TASK)
    end
end

function can_join_hero_task(self)
    return self:get_castle_lv() >= 15
end

--function accept_hero_task_req(self, _id)
--    if check_ply_cross(self) then
--        ack(self, "accept_hero_task_req", resmng.E_FAIL, 0)
--        return
--    end
--    if not self:can_join_hero_task() then
--        ack(self, "accept_hero_task_req", resmng.E_FAIL, 0)
--        return
--    end
--    
--    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
--    if task then
--        local accept_tm = self:get_hero_task("accept_time") or 0
--        if accept_tm >= 8 then
--            ack(self, "accept_hero_task_req", resmng.E_FAIL, 0)
--            return 
--        end
--        if task.status == TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
--            local ply = task.task_plys[self.pid] or {}
--            ply.status = TASK_STATUS.TASK_STATUS_ACCEPTED
--            task.task_plys[self.pid] = ply
--            task.status = TASK_STATUS.TASK_STATUS_ACCEPTED
--            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
--            self:set_hero_task("accept_time", accept_tm + 1)
--        end
--    end
--    update_hero_task(task)
--end

function add_hero_task_help_req(self, _id)
    if check_ply_cross(self) then
        return
    end
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_ACCEPTED or task.status == TASK_STATUS.TASK_STATUS_DOING  then
            local union = self:get_union()
            if union then
                if task.tmSn then
                    union_help.add(self, task.tmSn)
                    self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
                    update_hero_task(task)
                    INFO("[HERO TASK], add hero task pid=%d, task_id=%s", self.pid, _id)
                end
            end
        end
    end
end

function cancel_hero_task_req(self, _id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_CAN_ACCEPTE or task.status == TASK_STATUS.TASK_STATUS_DOING then
            task.status = TASK_STATUS.TASK_STATUS_CAN_ACCEPTE
            if task.status == TASK_STATUS.TASK_STATUS_DOING then
                if task.tmSn then
                    union_help.del(self, task.tmSn)
                end
                union_hero_task.del(task)
            end
            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
            update_hero_task(task)
            INFO("[HERO TASK], cancel hero task pid=%d, task_id=%s", self.pid, _id)
        end
    end
end

function acc_hero_task_req(self, _id)
    if check_ply_cross(self) then
        ack(self, "acc_hero_task_req", resmng.E_FAIL, 0)
        return
    end
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_DOING then
            local prop = resmng.get_conf("prop_hero_task_detail", task.task_id)
            if prop then
                local tm = timer.get(task.tmSn)
                if not tm then
                    ack(self, "acc_hero_task_req", resmng.E_FAIL, 0)
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
                       ack(self, "acc_hero_task_req", resmng.E_FAIL, 0)
                       return 
                   end
                   self:do_dec_res(resmng.DEF_RES_GOLD, need_gold, VALUE_CHANGE_REASON.ACC_HERO_TASK)
                   timer.adjust(task.tmSn, gTime)
                   task.tmOver = gTime
                   self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
                   update_hero_task(task)
                   INFO("[HERO TASK], acc hero task pid=%d, task_id=%s need_gold=%d", self.pid, _id, need_gold)
                   --if dura - prop.AccTime > 0 then
                   --    timer.acc(task.tmSn, prop.AccTime)
                   --    task.tmOver = task.tmOver - prop.AccTime
                   -- end
               end
           end
       end
   end
end

function get_hero_task_info_req(self, _id)
    if check_ply_cross(self) then
        return
    end
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
    update_hero_task(task)
    end
end

function get_hero_task_by_id(self, _id)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        return task
    end

    task = union_hero_task.get(self.uid, _id)
    return task
end

function event1_task_answer_req(self, _id, is_win)
    if check_ply_cross(self) then
        return
    end
    INFO("[HERO TASK], event1 hero task pid=%d, task_id=%s, is_win=%d", self.pid, _id, is_win)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        if task.task_type == 1 then
            task.event1_is_win = is_win
            task.status = TASK_STATUS.TASK_STATUS_CAN_FINISH
            for pid, ply in pairs(task.task_plys or {}) do
                if pid == self.pid then
                    ply.status = TASK_STATUS.TASK_STATUS_CAN_FINISH
                end
            end
            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
            update_hero_task(task)
        end
    end
end

function get_hero_task_award_req(self, _id)
    if check_ply_cross(self) then
        return
    end
    INFO("[HERO TASK], get hero task award pid=%d, task_id=%s", self.pid, _id)
    local task = self:get_hero_task_by_id(_id)
    if task then
        local status = task.status
        local ply = task.task_plys[self.pid]
        if ply then
            status = ply.status
        end
        if status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
            local prop = resmng.get_conf("prop_hero_task_detail", task.task_id)
            --local its =  player_t.bonus_func[prop.Bonus[1]](prop.Bonus, prop.Bonus[2])
            if task.pid == self.pid then
                local its =  player_t.bonus_func["mutex_award"](prop.Bonus, prop.Bonus)
                cal_award_num(task, its) 
                local award = deal_hero_buf_award(task, self.pid, its)
                self:add_bonus( "mutex_award", award, VALUE_CHANGE_REASON.HERO_TASK_NORMAL)
            else
                local its =  player_t.bonus_func["mutex_award"](prop.HelpBonus, prop.HelpBonus)
                local award = deal_hero_buf_award(task, self.pid, its)
                self:add_bonus( "mutex_award", award, VALUE_CHANGE_REASON.HERO_TASK_NORMAL)
            end

            if not ply then
                task.status = TASK_STATUS.TASK_STATUS_FINISHED
            else
                ply.status = TASK_STATUS.TASK_STATUS_FINISHED
            end

            if prop.TaskType == 1 then
                if (task.event1_is_win or 0 ) == 1 then
                    local its =  player_t.bonus_func["mutex_award"](prop.EventBonus, prop.EventBonus)
                    --cal_award_num(task, its) 
                    local award = deal_hero_buf_award(task, self.pid, its)
                    self:add_bonus( "mutex_award", award, VALUE_CHANGE_REASON.HERO_TASK_NORMAL)
                end
            elseif prop.TaskType == 2 then
                if ply then
                    if (ply.win_num or 0) >= 2 then
                        local its =  player_t.bonus_func["mutex_award"](prop.EventBonus, prop.EventBonus)
                        local award = deal_hero_buf_award(task, self.pid, its)
                        self:add_bonus( "mutex_award", award, VALUE_CHANGE_REASON.HERO_TASK_NORMAL)
                    end
                end
            end

            if prop.TaskType == 1 then
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, nil)
                local new_task = self:gen_single_task(task.idx)
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, new_task._id, new_task)
            elseif prop.TaskType == 2 then
                if task.pid == self.pid then
                    local ret = true
                    for _, ply in pairs(task.task_plys or {}) do
                        if ply.status ~= TASK_STATUS.TASK_STATUS_FINISHED then
                            ret = false
                            break
                        end
                    end
                    if ret  == true then
                        self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, nil)
                    else
                        self:del_ply_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
                    end
                    local new_task = self:gen_single_task(task.idx)
                    self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, new_task._id, new_task)
                else
                    local ret = true
                    for _, ply in pairs(task.task_plys or {}) do
                        if ply.status ~= TASK_STATUS.TASK_STATUS_FINISHED then
                            ret = false
                            break
                        end
                    end
                    if ret == true then
                        union_hero_task.del(task)
                    end
                end
            end

            --Rpc:update_hero_task_ack(self, new_task)
            local pack = {}
            pack[HERO_TASK_MODE.CUR_LIST] = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
            pack[HERO_TASK_MODE.HELP_LIST] = self:get_can_help_list()
            pack["accept_time"] = self:get_hero_task("accept_time") or 0
            pack["help_time"] = self:get_hero_task("help_time") or 0
            pack["next_refresh_tm"] = get_next_refresh_tm()
            Rpc:get_hero_task_list_ack(self, pack)
        end
    end
end

function do_hero_task_event_req(self, _id)
    if check_ply_cross(self) then
        return
    end
    local task = self:get_hero_task_by_id(_id)
    --local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        if task.is_event_init == true then
        else
            set_fight_cards(task)
        end
        local task_ply = task.task_plys[self.pid]
        if task_ply then
            if not task_ply.other_order then
                local other_order = {}
                for pid, v in pairs(task.task_plys or {}) do
                    if pid ~= self.pid then
                        other_order[pid] = v.order
                    end
                end
                task_ply.other_order = other_order
                union_hero_task.mark(task)
            end
        end
        update_hero_task(task)
    end
end

function deal_hero_buf_award(task, pid, its)
    if not task.task_plys then
        return
    end

    local task_ply = task.task_plys[pid]
    if not task_ply then
        return
    end

    local heros = task_ply.heros or {}
    local award = {}

    for key, item in pairs( its or {}) do
       -- for key, item in pairs( v or {}) do
            if item[1] == "hero_attr" then
                for _, h in pairs( heros or {} ) do
                    if h._id ~= 0 then
                        table.insert( award, { "hero_attr", {h_id = h._id, mode = item[2]}, item[3] } )
                    end
                end
            else
                table.insert( award, item )
            end
       -- end
    end
    return award
end

function help_acc_hero_task(self, _id, acc_tm)
    local task = self:get_hero_task(HERO_TASK_MODE.CUR_LIST, _id)
    if task then
        if task.status == TASK_STATUS.TASK_STATUS_DOING then
            local prop = resmng.get_conf("prop_hero_task_detail", task.task_id)
            if prop then
                local tm = timer.get(task.tmSn)
                if not tm then
                    ack(self, "help_acc_hero_task", resmng.E_FAIL, 0)
                    return
                end

                local dura = task.tmOver - gTime
                if dura < 0 then
                    dura = 0 
                end

                if dura - acc_tm > 0 then
                    timer.acc(task.tmSn, acc_tm)
                    task.tmOver = task.tmOver - acc_tm
                else
                    timer.adjust(task.tmSn, gTime)
                    task.tmOver = gTime
                end
                self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
            end
        end
        update_hero_task(task)
    end
end

function get_hero_task_pool(self)
    local pools = copyTab(hero_task_pool or {})
    local list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST) or {}
    for _id, unit in pairs(list or {}) do
        if unit.status ~= TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
            local prop = resmng.get_conf("prop_hero_task_detail", pools[unit.task_type][unit.task_id])
            if prop then
                pools[prop.TaskType][unit.task_id] = nil
            end
        end
    end
    return pools
end

function get_undisplay_task_pool(self)
    local pools = copyTab(hero_task_pool or {})
    local list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST) or {}
    for _id, unit in pairs(list or {}) do
        if pools[unit.task_type][unit.task_id] then
            local prop = resmng.get_conf("prop_hero_task_detail", pools[unit.task_type][unit.task_id])
            if prop then
                pools[prop.TaskType][unit.task_id] = nil
            end
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
        local info = db.hero_task:findOne({_id = self.pid})
        if not info then
            self._hero_task = {}
        else
            for k, v in pairs(info.cur_hero_task_list or {}) do
                if v.uid then
                    info.cur_hero_task_list.k = union_hero_task.get(v.uid, v._id)  -- union hero task load from union_hero_task
                end
            end
        end
        if not self._hero_task then
            self._hero_task = info or {}
        end
        local info1 = db.union_hero_task:find({pid = self.pid})
        if info1 then
            while info1:hasNext() do
                local b = info1:next()
                if b.task_plys then
                    local task_ply = b.task_plys[self.pid]
                    if task_ply then
                        if task_ply.status ~= TASK_STATUS.TASK_STATUS_FINISHED then
                            self._hero_task[HERO_TASK_MODE.CUR_LIST] = self._hero_task[HERO_TASK_MODE.CUR_LIST] or {}
                            self._hero_task[HERO_TASK_MODE.CUR_LIST][b._id] = b
                        end
                    end
                end
            end
        end
    end
    if what1 and what2 then
        if not self._hero_task[ what1 ] then
            return
        else
            return self._hero_task[ what1 ][ what2 ]
        end
    elseif what1 then
        return self._hero_task[ what1 ] 
    else
        return self._hero_task
    end
end

function del_ply_hero_task(self, key1, key2)
    local hero_task = self:get_hero_task()
    local val1 = hero_task[key1] or {}
    val1[key2] = nil
    hero_task[key1] = val1
    gPendingSave.hero_task[ self.pid ][key1] = val1
end

function set_hero_task2(self, key1, key2, val) -- 
    local hero_task = self:get_hero_task()
    local val1 = hero_task[key1] or {}
    local del_val
    if not val then
        del_val = val1[key2]
    end
    val1[key2] = val
    hero_task[key1] = val1
    if key1 == HERO_TASK_MODE.CUR_LIST then -- union hero task save in ply and union_hero_task but load from union_hero_task only
        if val and val.uid then
            union_hero_task.mark(val)
            return
        end
        if del_val and del_val.uid then
            union_hero_task.del(del_val)
            return
        end
    end
    gPendingSave.hero_task[ self.pid ][key1] = val1
end

function set_hero_task(self, key ,val)
    local hero_task = self:get_hero_task()
    if key == HERO_TASK_MODE.CUR_LIST then
        local old_val = hero_task[key]
        for _, v in pairs(old_val or {}) do
            if v.uid then
                union_hero_task.del(v)
            end
        end
    end
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
    local node = timer.get(tm_id)
    if node then
        task.tmSn = tm_id
        task.tmOver = node.over
        task.tmStart = node.start
    end
end

function update_hero_task(task)
    local tag = false
    for pid, _ in pairs(task.task_plys or {}) do
        if pid == task.pid then
            tag = true
        end

        local ply = getPlayer(pid)
        if ply then
            Rpc:update_hero_task_ack(ply, task)
        end
    end
    if tag == false then
        local ply = getPlayer(task.pid)
        if ply then
            Rpc:update_hero_task_ack(ply, task)
        end
    end
end

------------------- multiplayer  hero task
--
function helper_confirm_hero_req(self, _id)
    if check_ply_cross(self) then
        ack(self, "helper_confirm_hero_req", resmng.E_FAIL, 0)
        return
    end
    local task = self:get_hero_task_by_id(_id)
    if task then
        if task.status ~= TASK_STATUS.TASK_STATUS_DOING then
            ack(self, "helper_confirm_hero_req", resmng.E_FAIL, 0)
            return
        end
        local help_tm = self:get_hero_task("help_time") or 0
        if help_tm >= 8 then
            ack(self, "helper_confirm_hero_req", resmng.E_FAIL, 0)
            return 
        end
        if task.task_plys then
            local task_ply = task.task_plys[self.pid] or {}
            task_ply.status = TASK_STATUS.TASK_STATUS_DOING
            task.task_plys[self.pid] = task_ply
            union_hero_task.mark(task)
            self:set_hero_task("help_time", help_tm + 1)
            update_hero_task(task)
        end
    end
end

function deal_quit_for_hero_task(self)
    local cur_list = self:get_hero_task(HERO_TASK_MODE.CUR_LIST)
    for _id, task in pairs(cur_list or {}) do
        if task.status ~= TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
            for pid, task_ply in pairs(task.task_plys or {}) do
                for _, h in pairs(task_ply.heros or {}) do
                    local hero = heromng.get_hero_by_uniq_id(h._id)
                    if hero then
                        hero.hero_task_status = HERO_STATUS_TYPE.FREE
                    end
                end
                local tr = troop_mng.get_troop(task.troop_id)
                if tr then
                    tr:home()
                end
                if task.tmSn then
                    timer.del(task.tmSn)
                end

            end
            self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, nil)
        end
    end

    local help_list = self:get_can_help_list()
    for _id, task in pairs(help_list or {}) do
        if task.pid ~= self.pid then
            if not task.task_plys then
                break
            end

            local task_ply = task.task_plys[self.pid]
            if task_ply then
                for _, h in pairs(task_ply.heros or {}) do
                    local hero = heromng.get_hero_by_uniq_id(h._id)
                    if hero then
                        hero.hero_task_status = HERO_STATUS_TYPE.FREE
                    end
                end
                task_ply.status = TASK_STATUS.TASK_STATUS_FINISHED
            end

        end

        local ret = true
        for _, ply in pairs(task.task_plys or {}) do
            if ply.status ~= TASK_STATUS.TASK_STATUS_FINISHED then
                ret = false
                break
            end
        end
        if ret == true then
            union_hero_task.del(task)
        end
    end
end

function add_task_hero(self, _id, task_heros)
    -----------------------check condition------------------------------
    if check_ply_cross(self) then
        ack(self, "add_task_hero", resmng.E_FAIL, 0)
        return
    end
    if not self:can_join_hero_task() then
        ack(self, "add_task_hero", resmng.E_FAIL, 0)
        return
    end

    for _, hero_id in pairs(task_heros or {}) do
        local hero = heromng.get_hero_by_uniq_id(hero_id)
        if hero then
            if hero.hero_task_status == HERO_STATUS_TYPE.HERO_TASK then
                ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
                return
            end
        end
    end

    local task = self:get_hero_task_by_id(_id)
    if not task then
        ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
        return
    end

    task.task_plys = task.task_plys or {}
    if task.pid == self.pid then
        if task.status ~= TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
            ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
            return
        end
        local accept_tm = self:get_hero_task("accept_time") or 0
        if accept_tm >= 8 then
            ack(self, "add_task_hero", resmng.E_FAIL, 0)
            return 
        end
        local ply = task.task_plys[self.pid] or {}
        --ply.status = TASK_STATUS.TASK_STATUS_ACCEPTED
        --task.task_plys[self.pid] = ply
        --task.status = TASK_STATUS.TASK_STATUS_ACCEPTED
        self:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
    else
        if task.status ~= TASK_STATUS.TASK_STATUS_DOING then
            ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
            return
        end
        local help_tm = self:get_hero_task("help_time") or 0
        if help_tm >= 8 then
            ack(self, "add_task_hero", resmng.E_FAIL, 0)
            return 
        end
    end

    local task_plys = task.task_plys or {}
    local task_ply = task_plys[self.pid] or {}
    if task_ply == TASK_STATUS.TASK_STATUS_DOING then
        ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
        return
    end

    local prop = resmng.get_conf("prop_hero_task_detail", task.task_id)
    if not prop then
        ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
        return
    end

    local task_plys = task.task_plys or {}
    local task_ply = task_plys[self.pid] or {}
    --local heros = task_ply.heros or {}
    for _, hero in pairs(task_ply.heros or {}) do
        local h =  heromng.get_hero_by_uniq_id(hero._id)
        if h then
            h.hero_task_status = HERO_STATUS_TYPE.FREE
        end
    end

    local heros = {}
    if task.pid == self.pid  or self.pid == nil then
        if get_table_valid_count(task_heros or {}) > prop.HeroNum then
            ack(self, "add_task_hero", resmng.E_FAIL, 0)
            return
        end
    else
        if self.uid ~= task.uid then
            ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
            return
        end
        if get_table_valid_count(task_heros or {}) > 1 then
            ack(self, "add_task_hero", resmng.E_CAN_NOT_DO_HERO_TASK, 0)
            return
        end
        if (get_help_ply_num(task) or 0) >= prop.HelpHeroNum then
            if not task_plys[self.pid] then
                ack(self, "add_task_hero", resmn.E_CAN_NOT_DO_HERO_TASK, 0)
                return
            end
        end
    end

    if get_table_valid_count(heros) == 0 then
        for _, h_id in pairs(task_heros or {}) do
            local hero = heromng.get_hero_by_uniq_id(h_id)
            if hero then
                table.insert(heros, { _id = h_id, propid = hero.propid, personality = hero.personality})
                hero.hero_task_status = HERO_STATUS_TYPE.HERO_TASK
            end
            INFO("[HERO TASK], add task hero pid=%d, task_id=%s, hero_id=%s", self.pid, _id, h_id)
            --heros[hero_id] = hero_id
        end
        task_ply.heros = heros
        task_ply.name = self.name
        task_ply.photo = self.photo
        task_ply.pid = self.pid
        task_plys[self.pid] = task_ply
        task.task_plys = task_plys
        local pow = 0
        if task.pid == self.pid then
            for _, h_id in pairs( task_heros or {} ) do
                local hero = heromng.get_hero_by_uniq_id(h_id)
                if hero then
                    pow = pow + hero:calc_fight_power()
                end
            end
        else
            task_ply.status = TASK_STATUS.TASK_STATUS_DOING
        end
        task.hero_pow = pow
        local main_ply = getPlayer(task.pid)
        if main_ply then
            main_ply:set_hero_task2(HERO_TASK_MODE.CUR_LIST, _id, task)
        end
    end

    if task.pid == self.pid then
        local arm = {heros = task_ply.heros }
        self:hero_task_siege(1, arm, task._id)
        local accept_tm = self:get_hero_task("accept_time") or 0
        self:set_hero_task("accept_time", accept_tm + 1)
    else
        local help_tm = self:get_hero_task("help_time") or 0
        self:set_hero_task("help_tm", help_tm + 1)
    end
    update_hero_task(task)
end

function get_help_ply_num(task)
    local num = 0
    for pid, _ in pairs(task.task_plys or {}) do
        if task.pid ~= pid then
            num = num + 1
        end
    end
    return num
end

--function add_task_hero_by_helper(self, _id, hero_id)
--    local task = union_hero_task.get_by_id(_id)
--    if task then
--        if task.pid == self.pid then
--            return
--        end
--        if task.uid ~= self.uid then
--            return
--        end
--
--        local prop = resmng.get_conf("prop_hero_task_detail", task_id)
--        if prop then
--            local help_tm = self:get_hero_task("help_time")
--            if help_tm >= 6 then
--                return 
--            end
--
--            local help_heros = task.help_heros or {}
--            if get_table_valid_count(help_heros) < prop.HelpHeroNum then
--                local task_plys = task.task_plys or {}
--                if not task_plys[self.pid] then
--                    task_plys[self.pid] = {pid = self.pid}
--                    help_heros[self.pid] = hero_id
--                end
--                task.help_heros = help_heros
--                task.task_plys = task_plys
--                union_hero_task.mark(task)
--                self:set_hero_task("help_time", help_tm + 1)
--update_hero_task(task)
--            end
--        end
--    end
--
--end

function init_fight_cards(task)
    local max = 27
    local cards = {}
    for i = 1, max , 1 do
        table.insert(cards, i)
    end

    local task_plys = task.task_plys or {}
    for _, task_ply in pairs(task_plys or {}) do
        local min, max = find_card_range_by_hero(task_ply.heros or {})
        local list = gen_cards_list(cards, min, max)
        local tab = {}
        for i = 1 , 3, 1 do
            local idx = math.random(#list)
            table.insert(tab, cards[list[idx]])
            cards[list[idx]] = nil
            table.remove(list, idx) 
        end
        task_ply.cards = tab
    end

    local cards2 = {}
    for _, v in pairs(cards) do
        table.insert(cards2, v)
    end

    for _, task_ply in pairs(task_plys or {}) do
        local tab = task_ply.cards or {}
        for i = 1, 6, 1 do
            local idx = math.random(#cards2)
            table.insert(tab, cards2[idx])
            table.remove(cards2, idx)
        end
        task_ply.cards = tab
    end

    for _, task_ply in pairs(task_plys or {}) do
        local tab = copyTab(task_ply.cards or {})
        local num = #tab
        local order = {}
        for i=1, num, 1 do
            local max = 3
            if #tab < 3 then
                max = #tab
            end
            local idx = math.random(max)
            table.insert(order, tab[idx])
            table.remove(tab, idx)
        end
        task_ply.order = order
    end
end

function gen_cards_list(cards, min, max)
    local list = {}
    local num = 0
    for i = 1, 3, 1 do
        for j = min, max, 1 do
            if cards[j + num] then
                table.insert(list, j + num)
            end
        end
        num = num + 9
    end
    return list
end

function find_max_hero_by_pow(hero_list)
    local pow = 0
    for _, val in pairs(hero_list or {}) do
        local hero = heromng.get_hero_by_uniq_id(val._id)
        if hero then
            local h_pow = hero:calc_fight_power()
            if h_pow > pow then
                pow = h_pow
            end
        end
    end
    return pow
end

function find_card_range_by_hero(hero_list)
    local pow = find_max_hero_by_pow(hero_list) or 1
    if pow == 0  then 
        pow = 10 
    end
    local min = 1
    local max = 4
    for k, v in pairs(resmng.prop_hero_event_number or {}) do
        if pow >= v.Power then
            local prop = resmng.prop_hero_event_number[k+1]
            if prop then
                if pow < v.Power then
                    min = v.min
                    max = v.max
                    break
                end
            else
                min = v.min
                max = v.max
                break
            end
        end
    end
    return min, max
end

function set_fight_cards(task)
    local task_plys = task.task_plys or {}
    --if #{task_plys} ~= 3 then
     --   return
    --end

    init_fight_cards(task)
    task.is_event_init = true
    union_hero_task.mark(task)
end

function abandon_hero_task_req(self, _id)
    if check_ply_cross(self) then
        ack(self, "abandon_hero_task_req", resmng.E_FAIL, 0)
        return
    end
    local task = self:get_hero_task_by_id(_id)
    if not task then
        return
    end

    if task.uid ~= self.uid then
        ack(self, "set_fight_order", resmng.E_FAIL, 0)
        return
    end

    local task_plys = task.task_plys or {}
    local task_ply = task_plys[self.pid]
    if not task_ply then
        ack(self, "set_fight_order", resmng.E_FAIL, 0)
        return
    end

    task_ply.cur_index = 9
    task_ply.status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    union_hero_task.mark(task)
    update_hero_task(task)
end

function set_fight_order(self, _id, index, num)
    if check_ply_cross(self) then
        ack(self, "set_fight_order", resmng.E_FAIL, 0)
        return
    end
   -- local accept_tm = self:get_hero_task("accept_time")
   -- if accept_tm >= 6 then
   --     return 
   -- end
   -- local task = union_hero_task.get_by_id(_id)
    local task = self:get_hero_task_by_id(_id)

   -- local check_order = function(order)  -- check fight order 
   --     local check_list = {1,1,1}
   --     for _, v in pairs(order or {}) do
   --         if check_list[v] == 1 then
   --             check_list[v] = 0
   --         else
   --             return false
   --         end
   --     end
   --     return true
   -- end

    if task then
        if task.uid ~= self.uid then
            ack(self, "set_fight_order", resmng.E_FAIL, 0)
            return
        end

        local prop = resmng.get_conf("prop_hero_task_detail", task.task_id)
        if not prop then
            ack(self, "set_fight_order", resmng.E_FAIL, 0)
            return
        end

        --if #{hero_order} ~= 3 then
        --    return
        --end

        --if not check_order(hero_order) then
        --    return
        --end

        local task_plys = task.task_plys or {}
        local task_ply = task_plys[self.pid]
        if not task_ply then
            ack(self, "set_fight_order", resmng.E_FAIL, 0)
            return
        end

        local cur_index =  task_ply.cur_index or 0
        if (cur_index + 1) ~= index then
            ack(self, "set_fight_order", resmng.E_FAIL, 0)
            return
        end

        local order = task_ply.order or {1,2,3,4,5,6,7,8,9}
        for k, v in pairs(order or {}) do
            if v == num then
                if k < index then
                    return
                end
                order[k] = order[index]
                break
            end
        end
        order[index] = num
        task_ply.order = order
        task_ply.cur_index = index

        local is_win = function(A, B)
            local card_1 = math.ceil(A / 9)
            local card_2 = math.ceil(B / 9)
            if (card_1 + 1) % 3 ==  (card_2 % 3) then 
                return false
            elseif card_1 == card_2  and A < B then
                return false
            end
            return true
        end

        local task_ply1 = task_plys[self.pid]

        local task_ply2 = {}    --- 我头太胀是在想不起来怎么搞了。
        local task_ply3 ={}
        local temp = 1
        for pid, ply in pairs(task_plys or {}) do
            if pid ~= self.pid then
                if temp == 1 then
                    task_ply2 = ply
                    temp = temp + 1
                elseif temp == 2 then
                    task_ply3 = ply
                end
            end
        end

        local A = task_ply1.order[index]
        local B = task_ply2.order[index]
        local C = task_ply3.order[index]
        task_ply2.win_fake_num = task_ply2.win_fake_num or {}
        task_ply3.win_fake_num = task_ply3.win_fake_num or {}

        if is_win(A, B) then
            if is_win(A, C) then
                task_ply1.win_num = (task_ply1.win_num or 0) + 1
            elseif is_win(C, B) then
                task_ply3.win_fake_num[self.pid] = (task_ply3.win_fake_num[self.pid] or 0) + 1
            end
        else
            if is_win(B, C) then
                task_ply2.win_fake_num[self.pid] = (task_ply2.win_fake_num[self.pid] or 0) + 1
            elseif is_win(C, A) then
                task_ply3.win_fake_num[self.pid]  = (task_ply3.win_fake_num[self.pid] or 0) + 1
            end
        end

        if (task_ply1.win_num or 0) >= 2 or (task_ply2.win_fake_num[self.pid]  or 0) >= 2 or (task_ply3.win_fake_num[self.pid]  or 0) >= 2 or task_ply1.cur_index == 9 then
            task_ply1.status = TASK_STATUS.TASK_STATUS_CAN_FINISH
            --task_ply2.win_fake_num = 0
            --task_ply3.win_fake_num = 0
        end
        union_hero_task.mark(task)
        update_hero_task(task)
    end
end

function cal_award_num(task, its)
    local res_type = {
        [1] = "Res1",
        [2] = "Res2",
        [3] = "Res3",
        [4] = "Res4",
    }

    local idx = 1001
    for k, v in pairs(resmng.prop_hero_task_award or {}) do
        if v.Character == task.task_type then
            if task.hero_pow >= v.FightCapacity then
                local prop = resmng.prop_hero_task_award[k + 1]
                if prop then
                    if prop.Character == task.task_type then
                        if prop.FightCapacity < task.hero_pow then
                            idx = k
                            break
                        end
                    else
                        idx = k
                        break
                    end
                end

            end
        end
    end
    local task_prop = resmng.get_conf("prop_hero_task_award", idx)
    --local task_prop = resmng.get_conf("prop_hero_task_award", 1001)
    for _, v in pairs(its or {}) do
        if v[1] == "res" then
            v[3] = task_prop[res_type[v[2]]]
        end
    end
end

--function is_hero_in_task(task, herk_ply_id)
--    local main_heros = task.main_heros or {}
--    if main_heros[hero_id] then
--        return true
--    end
--    local help_heros = task.help_heros or {} 
--    if help_heros[hero_id] then
--        return true
--    end
--    return false
--end

--function hero_task_fight(self, _id)
--    local is_win = function(A, B)
--        local card_1 = A % 3
--        local card_2 = B % 3
--        if (card_1 + 1) % 3 ==  (card_2 % 3) then 
--            return false
--        elseif card_1 == card_2  and A < B then
--            return false
--        end
--        return true
--    end
--
--    local task = union_hero_task.get_by_id(_id)
--    if not task.task_plys then
--        ack(self, "set_fight_order", resmng.E_FAIL, 0)
--        return
--    end
--    local task_plys = task.task_plys
--
--    local task_ply1 = task_plys[self.pid]
--    local card1 = copyTab(task_ply.cards or {})
--
--    local task_ply2 = {}    --- 我头太胀是在想不起来怎么搞了。
--    local card2 = {}
--    local task_ply3 ={}
--    local card3 = {}
--    local temp = 1
--    for pid, ply in pairs(task_plys or {}) do
--        if pid ~= self.pid then
--            if temp == 1 then
--                task_ply2 = ply
--                card2 = copyTab(ply or {})
--                temp = temp + 1
--            elseif temp == 2 then
--                task_ply3 = ply
--                card3 = copyTab(ply or {})
--            end
--        end
--    end
--
--    local win_num = task_ply.win_num or 0
--    for i = 1, 9, 1 do
--        if win_num >= 2 then
--            return true
--        end
--        local A = table.remove(card1, task_ply1.order[i])
--        local B = table.remove(card2, task_ply2.order[i])
--        if is_win(A, B) then
--            local C = table.remove(card2, task_ply2.order[i])
--            if is_win(A, C) then
--                win_num = win_num + 1
--            end
--        end
--    end
--    return false
--end

function check_event_condition(task, event_cond)
    local heros = {}
    for _, ply in pairs(task.task_plys) do
        for _, h in pairs(ply.heros or {}) do
            table.insert(heros, h._id)
        end
    end

    -- cond {"prop_type", val, num}
    local tag = true
    for _, cond in pairs(event_cond or {}) do
        tag = false
        local num = 0
        for _, h_id in pairs(heros or {}) do
            local h = heromng.get_hero_by_uniq_id(h_id)
            if h then
                local prop = resmng.get_conf("prop_hero_basic", h.propid)
                if prop then
                    if cond[1] == "Lean" then
                        for _, v in pairs(prop[cond[1]] or {}) do
                            if v == cond[2] then
                                num = num + 1
                            end
                        end
                    elseif cond[1] == "personality" then
                        if h[cond[1]] == cond[2] then
                            num = num + 1
                        end
                    else
                        if prop[cond[1]] == cond[2] then
                            num = num + 1
                        end
                    end
                end
            end
            if num >= cond[3] then
                tag = true
                break
            end
        end
        if tag == false then
            return false
        end
    end
    return tag
end

------------------- multiplayer  hero task
