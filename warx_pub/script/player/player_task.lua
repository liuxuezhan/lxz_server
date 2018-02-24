module("player_t")


function init_task(self)
    self.activity = 0
    self.activity_box = {}
    self.daily_refresh_num = 1
    self.daily_refresh_time = gTime + 14400     --4*3600  4个小时

    self._need_save_id = {}
    self._cur_task_list = {}
    self._finish_task_list = {}
    self._action_map = {}
end


function clear_task(self)
    self:do_save_task()
    self._need_save_id = {}
    self._cur_task_list = nil
    self._finish_task_list = nil
    self._action_map = nil
    INFO( "[TASK], pid=%d, clear_task", self.pid)
end

function load_task_from_db(self)
    if self._cur_task_list ~= nil then
        return
    end

    local st = c_msec()
    local tmp_cur_task_list = {}
    local tmp_finish_task_list = {}
    local tmp_action_map = {}

    local db = dbmng:getOne()
   
    --已经完成的任务
    local finish_info = db.finished_task:find({_id = self.pid})
    while finish_info:hasNext() do
        local list = finish_info:next()
        for k, v in pairs(list or {}) do
            if k ~= "_id" then
                tmp_finish_task_list[k] = v
            end
        end
    end
   
    --正在进行的任务
    local info = db.task:find({pid = self.pid})
    while info:hasNext() do
        local unit = info:next()
        unit.pid = nil
        unit._id = nil
        tmp_cur_task_list[unit.task_id] = unit

        if unit.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            local action = unit.task_action
            if action == nil then
                ERROR("This task action is nil, task_id: %d, pid: %d", unit.task_id, self.pid)
            end
            if action ~= nil then
                if tmp_action_map[action] == nil then
                    tmp_action_map[action] = {}
                end
                tmp_action_map[action][unit.task_id] = unit
            end
        end
        
        --漏掉的已完成任务容错
        if unit.task_type == TASK_TYPE.TASK_TYPE_TRUNK or 
            unit.task_type == TASK_TYPE.TASK_TYPE_BRANCH or 
            unit.task_type == TASK_TYPE.TASK_TYPE_HEROROAD then
            
            if unit.task_status == TASK_STATUS.TASK_STATUS_FINISHED then
                tmp_cur_task_list[unit.task_id] = nil
                local _id = self.pid.."_"..unit.task_id
                gPendingDelete.task[_id] = 0
                tmp_finish_task_list[unit.task_id] = 1
                gPendingSave.finished_task[self.pid] = tmp_finish_task_list
            end
        end
    end

    if self._cur_task_list == nil then
        self._cur_task_list = tmp_cur_task_list
    end
    if self._finish_task_list == nil then
        self._finish_task_list = tmp_finish_task_list
    end
    if self._action_map == nil then
        self._action_map = tmp_action_map
    end

    LOG(self.pid.."taskstatics:load task:"..(c_msec()-st))
end

function load_task_from_data(self, task_list, finished_task)
    if nil ~= self._cur_task_list then
        ERROR("_cur_task_list existed when load task from data")
        return
    end

    local pid = self.pid
    -- 已经完成的任务
    gPendingInsert.finished_task[pid] = finished_task
    -- 正在进行的任务
    local tmp_cur_task_list = {}
    local tmp_action_map = {}
    for k, v in pairs(task_list or {}) do
        -- 存储
        local fields = copyTab(v)
        fields.pid = pid
        local _id = pid.."_"..v.task_id
        gPendingInsert.task[_id] = fields
        -- 运行时数据
        tmp_cur_task_list[k] = v
        if v.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            local action = v.task_action
            if nil == action then
                ERROR("This task action is nil, task_id: %d, pid: %d", v.task_id, pid)
            else
                if nil == tmp_action_map[action] then
                    tmp_action_map[action] = {}
                end
                tmp_action_map[action][v.task_id] = v
            end
        end
        -- 容错
        if v.task_type == TASK_TYPE.TASK_TYPE_TRUNK or
            v.task_type == TASK_TYPE.TASK_TYPE_BRANCH or
            v.task_type == TASK_TYPE.TASK_TYPE_HEROROAD then
            if v.task_status == TASK_STATUS.TASK_STATUS_FINISHED then
                tmp_cur_task_list[v.task_id] = nil
                gPendingDelete.task[_id] = 0
                finished_task[v.task_id] = 1
            end
        end
    end

    self._cur_task_list = tmp_cur_task_list
    self._finish_task_list = finished_task
    self._action_map = tmp_action_map
end

function reset_action_map( self )
    local action_map = {}
    for k, v in pairs( self._cur_task_list ) do
        local action = v.task_action
        if action then
            local node = action_map[ action ]
            if not node then
                node = {}
                action_map[ action ] = node
            end
            node[ v.task_id ] = v
        end
    end
    self._action_map = action_map
end

function get_cur_task_list(self)
    self:load_task_from_db()
    return self._cur_task_list
end

function get_finish_task_list(self)
    self:load_task_from_db()
    return self._finish_task_list
end

function has_task(self, task_id)
    local list = self:get_cur_task_list()
    if list[task_id] ~= nil then
        return true
    end
    local finish = self:get_finish_task_list()
    if finish[task_id] ~= nil then
        return true
    end
    return false
end

function is_task_finished(self, task_id)
    local finish = self:get_finish_task_list()
    if finish[task_id] ~= nil then
        return true
    end
    local list = self:get_cur_task_list()
    if list[task_id] ~= nil and list[task_id].task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
        return true
    end

    return false
end

function get_task_by_id(self, task_id)
    local list = self:get_cur_task_list()
    return list[task_id]
end

function get_task_by_action(self, task_action)
    self:load_task_from_db()
    return self._action_map[task_action]
end

function set_task_by_action(self, task)
    self:load_task_from_db()
    local task_action = task.task_action
    local task_id = task.task_id
    if self._action_map[task_action] == nil then
        self._action_map[task_action] = {}
    end
    if self._action_map[task_action][task_id] ~= nil then
        ERROR("insert task action map, the task id repetition!! action:%d, task id:%d", task.task_action, task_id)
        return
    end
    self._action_map[task_action][task_id] = task
end

--delete db
function do_delete_task(self, task)
    local task_id = task.task_id
    local cur_list = self:get_cur_task_list()
    if cur_list[task_id] == nil then return end

    local task_action = task.task_action
    cur_list[task_id] = nil

    local action_list = self:get_task_by_action(task_action)
    if action_list ~= nil then action_list[task_id] = nil end

    local _id = self.pid.."_"..task_id
    gPendingDelete.task[_id] = 0
end


function do_finish_task(self, task)
    local dura = gTime - ( task.task_tick or 0 )
    local id = task.task_id
    self._finish_task_list[id] = dura
    gPendingSave.finished_task[ self.pid ][ id ] = dura
end



function add_save_task_id(self, task_id)
    self._need_save_id = self._need_save_id or {} 
    table.insert(self._need_save_id, task_id)
end

function add_task_data(self, task_info)
    if self:has_task(task_info.ID) == true then
        return false
    end

    local unit = {}
    unit.task_id = task_info.ID
    unit.task_status = TASK_STATUS.TASK_STATUS_ACCEPTED
    unit.task_type = task_info.TaskType

    unit.task_current_num = 0
    unit.task_daily_num = 0
    unit.task_tick = gTime

    local func = nil
    if unit.task_type == TASK_TYPE.TASK_TYPE_DAILY then
        func = resmng.prop_task_daily[unit.task_id].FinishCondition[1]
        
    elseif unit.task_type == TASK_TYPE.TASK_TYPE_TRUNK then
        func = resmng.prop_task_detail[unit.task_id].FinishCondition[1]

    elseif unit.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
        func = resmng.prop_task_detail[unit.task_id].FinishCondition[1]

    elseif unit.task_type == TASK_TYPE.TASK_TYPE_TARGET then
        func = resmng.prop_task_detail[unit.task_id].FinishCondition[1]

    elseif unit.task_type == TASK_TYPE.TASK_TYPE_HEROROAD then
        func = resmng.prop_task_detail[unit.task_id].FinishCondition[1]

    end
    unit.task_action = g_task_func_relation[func]

    local tab = self:get_cur_task_list()
    tab[unit.task_id] = unit
    self:set_task_by_action(unit)

    self:add_save_task_id(unit.task_id)
    INFO( "[TASK], add, pid,%d, task,%s, action,%s", self.pid, unit.task_id, func)

    return true
end

--save db
function do_save_task(self)
    if #(self._need_save_id or {}) <= 0 then
        return
    end
    local list = {}
    for k, v in ipairs(self._need_save_id) do
        local data = self:get_task_by_id(v)
        if data ~= nil then
            local save = copyTab(data)
            save._id = self.pid.."_"..data.task_id
            save.pid = self.pid
            gPendingInsert.task[save._id] = save

            table.insert(list, data)

            if data.task_status == TASK_STATUS.TASK_STATUS_FINISHED then
                if data.task_type == TASK_TYPE.TASK_TYPE_TRUNK or 
                    data.task_type == TASK_TYPE.TASK_TYPE_BRANCH or 
                    data.task_type == TASK_TYPE.TASK_TYPE_HEROROAD then

                    self:do_delete_task(data)
                    self:do_finish_task(data)
                else
                    local action_list = self:get_task_by_action(data.task_action)
                    if action_list ~= nil then
                        action_list[data.task_id] = nil
                    end
                end
            end
        end
    end
    self._need_save_id = {}
    self:notify_task_change(list)
end

function check_finish(self, task_id, cond, ...)
    local task_data = self:get_task_by_id(task_id)
    if task_data == nil then return end

    task_logic_t.distribute_operation(self, task_data, cond, ...)
end

function can_finish_task( self, task_id )
    local task = self:get_task_by_id(task_id)
    if not task then return false end

    if task.task_status == TASK_STATUS_CAN_FINISH then 
        return true 

    else
        local tconf = resmng.get_conf( "prop_task_detail", task_id )
        if tconf then
            --self:check_finish( task_id, unpack( tconf.FinishCondition ) )
            self:check_finish( task_id, tconf.FinishCondition )
            return task.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH
        end
    end
end

function mark_task( p, task_id )
    local info = p:get_task_by_id(task_id)
    if not info then return end
    if info.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
        if can_finish_task( p, task_id ) then
            info.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
            info._id = p.pid .. "_" .. task_id
            gPendingSave.task[ info._id ].task_sttus = TASK_STATUS.TASK_STATUS_CAN_FINISH
        end
    end
end

function finish_task(p, task_id)
    local info = p:get_task_by_id(task_id)
    if not info then return end

    if info.task_status ~= TASK_STATUS.TASK_STATUS_CAN_FINISH then
	    if not p:can_finish_task(task_id) then return end
    end

    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then return false end

    info.task_status = TASK_STATUS.TASK_STATUS_FINISHED
    p:add_save_task_id(task_id)
    p:do_save_task()

    INFO( "[TASK], finish, pid,%d, task,%d, action,%s, dura,%d ", p.pid, task_id, prop_task.FinishCondition[1], gTime - p.tm_create )

    --加奖励
    local bonus_policy = prop_task.BonusPolicy
    local bonus = prop_task.Bonus
    p:add_bonus(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_TASK)

    --开启建筑
    --p:open_build_by_task(task_id)

    p:pre_tlog("QuestComplete", task_id)
    p:upload_37task(task_id)

    return true
end

function can_take_task(self, task_id)
    --判断这个任务是否已接
    if self:has_task(task_id) == true then
        return false
    end

    --判断前置任务
    local prop_tab = resmng.prop_task_detail[task_id]
    if prop_tab == nil then
        return false
    end

    local pre_task_id = prop_tab.PreTask
    if pre_task_id ~= nil then
        if self:is_task_finished(pre_task_id) == false then
            return false
        end
    end

    --判断前置条件
    local con_type, lv = unpack(prop_tab.PreCondition)
    if con_type == TASK_COND_TYPE.PLAYER_LV then
    elseif con_type == TASK_COND_TYPE.CASTLE_LV then
        local castle_level = self:get_castle_lv()
        if castle_level < lv then
            return false
        end
    elseif con_type == TASK_COND_TYPE.UNION_LV then
    elseif con_type == TASK_COND_TYPE.CHAPTER_LV then
        if not self:is_chapter_finished(lv) then
            return false
        end
    end
    return true
end

function accept_task(self, task_id_array)
    for k, v in pairs(task_id_array or {}) do
        local can_take = self:can_take_task(v)
        if can_take == true then
            local accept_task_data = resmng.prop_task_detail[v]

            self:add_task_data(accept_task_data)

            local action = accept_task_data.FinishCondition[ 1 ] 
            action = g_task_func_relation[ action ]

            if not task_logic_t.gTaskProcessByClient[ action ] then
                self:check_finish(accept_task_data.ID, accept_task_data.FinishCondition)
            end
        else
            INFO( "[TASK], accept, pid,%d, task,%d, fail", self.pid, v )

        end
    end
    self:do_save_task()
end

--玩家登陆的时候把所有任务发给客户端
function packet_all_task_id(self)
    local list = {}
    list.cur = {}
    list.finish = {}
    -- 当前有的任务
    local cur_list = self:get_cur_task_list()
    for k, v in pairs(cur_list or {}) do
        local unit = {}
        unit.task_id = v.task_id
        unit.task_action = v.task_action
        unit.task_type = v.task_type
        unit.task_status = v.task_status
        unit.current_num = v.task_current_num
        unit.hp = v.hp
        unit.eid = v.monster_eid

        if unit.task_type == TASK_TYPE.TASK_TYPE_DAILY then
            unit.task_daily_num = v.task_daily_num
            unit.task_group_id = resmng.prop_task_daily[unit.task_id].GroupID
        end
            
        table.insert(list.cur, unit)
    end

    --已完成的任务
    local finish_list = self:get_finish_task_list()
    for k, v in pairs(finish_list or {}) do
        table.insert(list.finish, k)
    end

    return list
end

--任务改变了通知客户端
function notify_task_change(self, task_list)
    local msg_send = {}
    
    for k, v in pairs(task_list or {}) do
        local unit = {}
        unit.task_id = v.task_id
        unit.task_type = v.task_type
        unit.task_status = v.task_status
        unit.task_action = v.task_action
        unit.current_num = v.task_current_num
        unit.hp = v.hp
        unit.eid = v.monster_eid

        if unit.task_type == TASK_TYPE.TASK_TYPE_DAILY then
            unit.task_daily_num = v.task_daily_num
            unit.task_group_id = resmng.prop_task_daily[unit.task_id].GroupID
        end
        table.insert(msg_send, unit)
    end

    Rpc:update_task_info(self, msg_send)
end

--完成打开界面任务
function finish_open_ui(self, ui_id)
    task_logic_t.process_task(self, TASK_ACTION.OPEN_UI, ui_id)
end



----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--每日任务
function get_daily_task(self)
    local list = {}
    local cur_list = self:get_cur_task_list()
    for k, v in pairs(cur_list) do
        if v.task_type == TASK_TYPE.TASK_TYPE_DAILY then
            table.insert(list, v)
        end
    end
    return list
end

function take_daily_task(self)
    local st = c_msec()
    local castle_level = self:get_castle_lv()
    local list = daily_task_filter.select_task(castle_level)
    if list == nil then
        return
    end

    local tab = self:get_daily_task()
    for k, v in pairs(tab) do
        local prop_tmp = resmng.prop_task_daily[v.task_id]
        if prop_tmp ~= nil then
            list[prop_tmp.GroupID] = nil
        end
    end

    for k, v in pairs(list) do
        local prop_daily = resmng.prop_task_daily[v]
        self:add_task_data(prop_daily)
        self:check_finish(prop_daily.ID, prop_daily.FinishCondition)
    end
    self:do_save_task()
    LOG("taskstatics:task_daily_task:"..(c_msec()-st))
end

function on_day_pass_daily_task(self)
    local st = c_msec()
    --清除之前的日常任务
    local list = {}
    local cur_list = self:get_cur_task_list()
    for k, v in pairs(cur_list) do
        if v.task_type == TASK_TYPE.TASK_TYPE_DAILY then
            table.insert( list, v )
        end
    end
    for k, v in pairs(list) do
        self:do_delete_task(v)
    end

    local u = unionmng.get_union(self.uid)
    if u and u.activity_day ~= get_days(gTime) then
        u.activity = 0 
        for _, p in pairs(u._members) do
            u.activity = u.activity + p.activity 
        end
        player_t.pre_tlog(nil,"UnionList",u.uid,u.name,u.language,4,
            tostring(u.mc_start_time[1]),u.membercount,u.activity or 0 ) 
        u.activity_day = get_days(gTime)
    end

    
    self.activity = 0
    self.activity_box = {}
    self.activity_box = self.activity_box
    self.daily_refresh_num = 1
    self.daily_refresh_time = gTime + 14400     --4*3600  4个小时
    self:take_daily_task()
    LOG("taskstatics:daily_task_on_day_pass:"..(c_msec()-st))
end

function refresh_daily_task(self)
    local st = c_msec()
    --判断是否日常任务全部完成了
    local unfinish = {}
    local tab = self:get_daily_task()
    for k, v in pairs(tab) do
        if v.task_status ~= TASK_STATUS.TASK_STATUS_FINISHED then
            local unit = {}
            unit.group_id = resmng.prop_task_daily[v.task_id].GroupID
            unit.task_id = v.task_id
            unit.task_action = v.task_action
            table.insert(unfinish, unit)
        end
    end
    if #unfinish <= 0 then
        return
    end

    self:calc_daily_refresh_time()
    if self.daily_refresh_num > 0 then
        self.daily_refresh_num = self.daily_refresh_num - 1
    else
        --判断金币是否够
        if self.gold < 200 then
            Rpc:refresh_daily_task_resp(self, 1)
            return
        end
        self:consume(REFRESH_DAILY_TASK_CON, 1, VALUE_CHANGE_REASON.REASON_DAILY_TASK_REFERSH)
    end

    local castle_level = self:get_castle_lv()
    for k, v in pairs(unfinish) do
        self:do_delete_task(v)

        local task_id = daily_task_filter.select_task_by_group_id(castle_level, v.group_id)
        if task_id ~= nil then
            local prop_daily = resmng.prop_task_daily[task_id]
            self:add_task_data(prop_daily)
            self:check_finish(prop_daily.ID, prop_daily.FinishCondition)
            INFO( "[TASK], pid=%d, refresh_daily_task=%s", self.pid, prop_daily.ID)
        else
            ERROR("refresh_daily_task error,task id is not exist,group id:%d", v.group_id)
        end
    end
    self:do_save_task()

    self:get_daily_refresh_time()
    Rpc:refresh_daily_task_resp(self, 0)
    LOG("taskstatics:refresh_daily_task:"..(c_msec()-st))
end

function daily_task_activity(self)
    local msg_send = {}
    msg_send.activity = self.activity
    msg_send.activity_box = self.activity_box
    Rpc:daily_task_activity_resp(self, msg_send)
end


function get_activity_box(self, id)
    if id <= 0 or id > 5 then
        Rpc:get_activity_box_resp(self, 1)
        return
    end
    if self.activity_box[id] ~= nil then
        Rpc:get_activity_box_resp(self, 2)
        return
    end
    if self.activity < TASK_ACTIVITY[id] then
        Rpc:get_activity_box_resp(self, 3)
        return
    end

    --领奖
    local castle_level = self:get_castle_lv()
    local prop_award = resmng.prop_task_daily_award[castle_level]
    local function get_award_by_boxid()
        if id == 1 then
            return prop_award.BonusPolicy1, prop_award.Bonus1
        elseif id == 2 then
            return prop_award.BonusPolicy2, prop_award.Bonus2
        elseif id == 3 then
            return prop_award.BonusPolicy3, prop_award.Bonus3
        elseif id == 4 then
            return prop_award.BonusPolicy4, prop_award.Bonus4
        elseif id == 5 then
            return prop_award.BonusPolicy5, prop_award.Bonus5
        end
    end
    if prop_award ~= nil then
        local bonus_policy, bonus = get_award_by_boxid()
        self:add_bonus(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_TASK_DAILY_BOX)
    end


    self.activity_box[id] = true
    self.activity_box = self.activity_box
    Rpc:get_activity_box_resp(self, 0)
    INFO( "[TASK], pid=%d, get_box=%s", self.pid, id)
end

function add_activity(self, task_id)
    local prop_task = resmng.prop_task_daily[task_id]
    if prop_task == nil then
        return
    end
    self:inc_activity(prop_task.ActiveNum)
end

function inc_activity(self, value)
    self.activity = self.activity + value
    union_mission.ok(self, UNION_MISSION_CLASS.ACTIVE, value)
    kw_mall.add_kw_point(value)
    INFO( "[TASK], pid=%d, add_point=%s", self.pid, value)
end

function calc_daily_refresh_time(self)
    for i = 1, 7 do
        if gTime >= self.daily_refresh_time then
            self.daily_refresh_time = self.daily_refresh_time + 14400
            self.daily_refresh_num = self.daily_refresh_num + 1
        end
        if gTime < self.daily_refresh_time then
            break
        end
    end
end

function get_daily_refresh_time(self)
    self:calc_daily_refresh_time()
    local msg_send = {}
    msg_send.left_num = self.daily_refresh_num
    msg_send.time = self.daily_refresh_time
    Rpc:get_daily_refresh_time_resp(self, msg_send)
end

function daily_task_done(self, task_id)
    local task_info = self:get_task_by_id(task_id)
    if task_info == nil then
        Rpc:daily_task_done_resp(self, 1)
        return
    end
    if task_info.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then
        Rpc:daily_task_done_resp(self, 2)
        return
    end
    --计算金币
    local prop_tab = resmng.prop_task_daily[task_id]
    local left_activity = (prop_tab.FinishNum - task_info.task_daily_num) * prop_tab.ActiveNum
    local need_gold = left_activity * DONE_DAILY_TASK_GOLD
    if self.gold < need_gold then
        Rpc:daily_task_done_resp(self, 3)
        return
    end
    local res = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, need_gold}}
    self:consume(res, 1, VALUE_CHANGE_REASON.REASON_DAILY_TASK_DONE_TASK)

    task_info.task_status = TASK_STATUS.TASK_STATUS_FINISHED
    task_info.task_daily_num = prop_tab.FinishNum
    self:inc_activity(left_activity)
    self:add_save_task_id(task_id)
    self:do_save_task()
    self:daily_task_activity()

    Rpc:daily_task_done_resp(self, 0)
end


----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
--目标任务

function packet_target_task(self)

end

function get_target_all_award(self, index)
    if TASK_TARGET_AWARD[index] == nil or TASK_TARGET_ID[index] == nil then
        return
    end

    if self.task_target_all_award_index[index] ~= nil then
        return
    end

    local is_finish = true
    local list = self:get_cur_task_list()
    for k, v in pairs(TASK_TARGET_ID[index]) do
        if list[v] == nil or list[v].task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            is_finish = false
        end
    end
    if is_finish == false then
        return
    end
    local prop_item = resmng.get_conf("prop_item", TASK_TARGET_AWARD[index])
    if prop_item == nil then
        return
    end

    self:add_bonus(prop_item.Param[1][1], prop_item.Param[1][2], VALUE_CHANGE_REASON.REASON_TASK)
    self.task_target_all_award_index[index] = 1
    self.task_target_all_award_index = self.task_target_all_award_index
    INFO( "[TASK], pid=%d, get_target_task=%s", self.pid, index)
end


--GM 测试指令
----------------------------------------------------------------------
function gm_finish_task(self, task_id)
    local task = self:get_task_by_id(task_id)
    if task == nil then
        return
    end
    task.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    self:add_save_task_id(task_id)
    self:do_save_task()
end

function gm_accept_task(self, task_id)
    local prop_tab = resmng.prop_task_detail[task_id]
    if prop_tab == nil then
        return
    end
    self:add_task_data(prop_tab)
end

function get_silver( self )
    return self.silver
end



