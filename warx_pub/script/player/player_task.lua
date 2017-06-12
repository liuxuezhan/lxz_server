module("player_t")

function init_task(self)
    --当前正在做的任务
    self._cur_task_list = nil
    --已完成的任务id
    self._finish_task_list = nil
    --任务类型的映射
    self._action_map = nil
    --需要保存的任务ID数组
    self._need_save_id = {}

    --每日任务记录的数据
    self.activity = 0
    self.activity_box = {}
    self.daily_refresh_num = 1
    self.daily_refresh_time = gTime + 14400     --4*3600  4个小时

    --for k, v in pairs(resmng.prop_task_init) do
    --    local prop_tab = resmng.prop_task_detail[v.TaskID]
    --    if prop_tab == nil then
    --        ERROR("accept task fail in table prop_task_init!! the task isn't exist: %d", v.TaskID)
    --        return
    --    end
    --    self:add_task_data(prop_tab)
    --end
    --self:do_save_task()

    local cur_task_list = {}
    local action_map = {}
    local prop_task_init = resmng.prop_task_init 
    local pid = self.pid
    for k, v in pairs( prop_task_init ) do
        local hit = false
        local task_info = resmng.get_conf( "prop_task_detail", v.TaskID )
        if task_info then
            local taskid = v.TaskID
            local unit = {}
            unit._id = string.format( "%d_%d", pid, taskid )
            unit.pid = pid
            unit.task_id = taskid
            unit.task_status = TASK_STATUS.TASK_STATUS_ACCEPTED
            unit.task_type = task_info.TaskType
            unit.task_current_num = 0
            unit.task_daily_num = 0
            local func
            if unit.task_type == TASK_TYPE.TASK_TYPE_DAILY then
                func = resmng.prop_task_daily[taskid].FinishCondition[1]
            else
                func = resmng.prop_task_detail[taskid].FinishCondition[1]
            end

            if func then
                local action = g_task_func_relation[ func ]
                if action then
                    cur_task_list[ taskid ] = unit
                    local node = action_map[ action ]
                    if not node then
                        node = {}
                        action_map[ action ] = node
                    end
                    unit.task_action = action
                    node[ taskid ] = unit
                    gPendingInsert.task[ unit._id ] = unit
                    hit = true
                end
            end
        end
        if not hit then
            WARN( "prop_task_init, id = %d, invalid", k )
        end
    end
    self._cur_task_list = cur_task_list
    self._finish_task_list = {}
    self._action_map = action_map
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
                tmp_finish_task_list[k] = 1
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
        if unit.task_type == TASK_TYPE.TASK_TYPE_TRUNK or unit.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
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
function do_delete_task(self, task_id)
    local cur_list = self:get_cur_task_list()
    if cur_list[task_id] == nil then
        return
    end
    local task_action = cur_list[task_id].task_action
    cur_list[task_id] = nil

    local action_list = self:get_task_by_action(task_action)
    if action_list ~= nil then
        action_list[task_id] = nil
    end

    local _id = self.pid.."_"..task_id
    gPendingDelete.task[_id] = 0
end

function do_finish_task(self, task_id)
    self._finish_task_list[task_id] = 1
    gPendingSave.finished_task[self.pid] = self._finish_task_list
    INFO( "[TASK], pid=%d, finish_task=%s", self.pid, task_id)
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

    local func = nil
    if unit.task_type == TASK_TYPE.TASK_TYPE_DAILY then
        func = unpack(resmng.prop_task_daily[unit.task_id].FinishCondition)
        
    elseif unit.task_type == TASK_TYPE.TASK_TYPE_TRUNK then
        func = unpack(resmng.prop_task_detail[unit.task_id].FinishCondition)

    elseif unit.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
        func = unpack(resmng.prop_task_detail[unit.task_id].FinishCondition)

    elseif unit.task_type == TASK_TYPE.TASK_TYPE_TARGET then
        func = unpack(resmng.prop_task_detail[unit.task_id].FinishCondition)
    end
    unit.task_action = g_task_func_relation[func]

    local tab = self:get_cur_task_list()
    tab[unit.task_id] = unit
    self:set_task_by_action(unit)

    self:add_save_task_id(unit.task_id)
    INFO( "[TASK], pid=%d, add_task=%s", self.pid, unit.task_id)
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
        end

        if data.task_status == TASK_STATUS.TASK_STATUS_FINISHED then
            if data.task_type == TASK_TYPE.TASK_TYPE_TRUNK or data.task_type == TASK_TYPE.TASK_TYPE_BRANCH then
                self:do_delete_task(data.task_id)
                self:do_finish_task(data.task_id)
            else
                local action_list = self:get_task_by_action(data.task_action)
                if action_list ~= nil then
                    action_list[data.task_id] = nil
                end
            end
        end
    end
    self._need_save_id = {}
    self:notify_task_change(list)
end

function finish_task(self, task_id)
    local info = self:get_task_by_id(task_id)
    if info == nil or info.task_status ~= TASK_STATUS.TASK_STATUS_CAN_FINISH then
        return
    end
    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then
        return
    end

    info.task_status = TASK_STATUS.TASK_STATUS_FINISHED
    self:add_save_task_id(task_id)
    self:do_save_task()

    --加奖励
    local bonus_policy = prop_task.BonusPolicy
    local bonus = prop_task.Bonus
    self:add_bonus(bonus_policy, bonus, VALUE_CHANGE_REASON.REASON_TASK)

    --开启建筑
    self:open_build_by_task(task_id)

    self:pre_tlog("QuestComplete", task_id)
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
    local type, lv = unpack(prop_tab.PreCondition)
    local castle_level = self:get_castle_lv()
    if castle_level < lv then
        return false
    end
    return true
end

function check_finish(self, task_id, func, ...)
    local task_data = self:get_task_by_id(task_id)
    if task_data == nil then
        return
    end
    task_logic_t.distribute_operation(self, task_data, func, ...)
end

function accept_task(self, task_id_array)
    for k, v in pairs(task_id_array or {}) do
        local can_take = self:can_take_task(v)
        if can_take == true then
            local accept_task_data = resmng.prop_task_detail[v]
            self:add_task_data(accept_task_data)
            self:check_finish(accept_task_data.ID, unpack(accept_task_data.FinishCondition))
            INFO( "[TASK], pid=%d, accept_task=%s", self.pid, accept_task_data.ID)
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
        self:check_finish(prop_daily.ID, unpack(prop_daily.FinishCondition))
        INFO( "[TASK], pid=%d, take_daily_task=%s", self.pid, prop_daily.ID)
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
            table.insert(list, v.task_id)
        end
    end
    for k, v in pairs(list) do
        self:do_delete_task(v)
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
        self:do_delete_task(v.task_id)

        local task_id = daily_task_filter.select_task_by_group_id(castle_level, v.group_id)
        if task_id ~= nil then
            local prop_daily = resmng.prop_task_daily[task_id]
            self:add_task_data(prop_daily)
            self:check_finish(prop_daily.ID, unpack(prop_daily.FinishCondition))
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
    task_logic_t.process_task(self, TASK_ACTION.FINISH_DAILY_TASK)
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


--完成任务开启建筑
function open_build_by_task(self, task_id)
    for k, v in pairs(resmng.prop_citybuildview) do
        if v.OpenCond ~= nil then
            if task_id == v.OpenCond[2] then
                local build_id = v.PropId
                local bs = self:get_build()
                local conf = resmng.get_conf("prop_build", build_id)
                local build_idx = self:calc_build_idx(conf.Class, conf.Mode, 1)
                if bs[ build_idx ] == nil then
                    local build = build_t.create(build_idx, self.pid, build_id, 0, 0, BUILD_STATE.CREATE)
                    bs[ build_idx ] = build
                    build.tmSn = 0
                    self:doTimerBuild( 0, build_idx )
                end
            end
        end
    end
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


---------------------------------------------------------
--修复任务操作
function fix_task(self)  
    --重置目标任务
    local prop_task_init = resmng.prop_task_init 
    local pid = self.pid 
    local cur_list = self:get_cur_task_list()
    for _, prop in pairs( prop_task_init ) do
        local task_info = resmng.get_conf( "prop_task_detail", prop.TaskID )
        if task_info and task_info.TaskType == 5 then
            self:add_task_data(task_info)
        end 
    end
    self:do_save_task()
    --重置日常任务
    self:take_daily_task()
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



