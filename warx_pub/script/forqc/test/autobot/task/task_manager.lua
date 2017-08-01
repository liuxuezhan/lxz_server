local TaskManager = {}

TaskManager.__index = TaskManager

local function _onTaskInfoUpdated(self, player, new_data, old_data)
    if nil == old_data or new_data.task_status ~= old_data.task_status then
        if new_data.task_status == TASK_STATUS.TASK_STATUS_FINISHED then
            if new_data.task_type == TASK_TYPE.TASK_TYPE_TRUNK or
                new_data.task_type == TASK_TYPE.TASK_TYPE_BRANCH or
                new_data.task_type == TASK_TYPE.TASK_TYPE_HEROROAD then
                self:_finishTask(new_data.task_id)
                -- 临时解决方案，应该根据服务器消息更新相关数据
                if 130010127 == new_data.task_id then
                    Rpc:loadData(player, "ef")
                end
            end
            self:_acceptSubsequentTask(new_data.task_id)
        elseif new_data.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
            self:_addPendingTask(new_data)
        --elseif new_data.task_status == TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
        elseif new_data.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
            self:_addPendingTask(new_data)
        --elseif new_data.task_status == TASK_STATUS.TASK_STATUS_UPDATE then
        end
    else
        -- 检查任务当前执行状态，是否要重新加入执行列表
        self:_addPendingTask(new_data)
    end
end

local function _onBuildUpdated(self, player, build)
    local prop = resmng.prop_build[build.propid]
    if BUILD_CLASS.FUNCTION ~= prop.Class or BUILD_FUNCTION_MODE.CASTLE ~= prop.Mode then
        return
    end
    -- 城堡等级改变时需要重新接取任务
    self:_acceptCastleTask(prop.Lv)
end

function TaskManager.create(...)
    local obj = setmetatable({}, TaskManager)
    obj:init(...)
    return obj
end

function TaskManager:init(player)
    self.player = player
    self.pending_tasks = {}
    player.eventTaskInfoUpdated:add(newFunctor(self, _onTaskInfoUpdated))

    self.player.eventBuildUpdated:add(newFunctor(self, _onBuildUpdated))

    for k, v in pairs(self.player._task.cur or {}) do
        if TASK_TYPE.TASK_TYPE_TRUNK == v.task_type or
            TASK_TYPE.TASK_TYPE_BRANCH == v.task_type then
            table.insert(self.pending_tasks, v.task_id)
        end
    end
end

function TaskManager:uninit()
    self.pending_tasks = nil
    player.eventTaskInfoUpdated:del(newFunctor(obj, _onTaskInfoUpdated))
end

function TaskManager:getTask(task_id)
    for k, v in pairs(self.player._task.cur) do
        if v.task_id == task_id then
            return v
        end
    end
end

function TaskManager:_acceptSubsequentTask(task_id)
    local tasks = {}
    for k, v in pairs(resmng.prop_task_detail) do
        if v.PreTask == task_id then
            table.insert(tasks, k)
        end
    end
    INFO("[Autobot|TaskManager|%d]Accept subsequent task", self.player.pid)
    Rpc:accept_task(self.player, tasks)
end

function TaskManager:_acceptCastleTask(castle_lv)
    local tasks = {}
    for k, v in pairs(resmng.prop_task_detail) do
        if is_task_finished(self.player, v.PreTask) and not is_task_finished(self.player, v.ID) then
            local t, lv = unpack(v.PreCondition)
            if lv <= castle_lv then
                table.insert(tasks, k)
            end
        end
    end
    if 0 ~= #tasks then
        INFO("[Autobot|TaskManager|%d]try to accept %d task while castle level up", self.player.pid, #tasks)
        Rpc:accept_task(self.player, tasks)
    end
end

function TaskManager:_finishTask(task_id)
    --for k, v in pairs(self.player._task.cur) do
    --    if v.task_id == task_id then
    --        self.player._task.cur[k] = nil
    --        break
    --    end
    --end
    --table.insert(self.player._task.finish, task_id)
    for k, v in ipairs(self.pending_tasks) do
        if v == task_id then
            table.remove(self.pending_tasks, k)
            break
        end
    end
end

local task_type_string = 
{
    [TASK_TYPE.TASK_TYPE_TRUNK] = "Trunk",
    [TASK_TYPE.TASK_TYPE_BRANCH] = "Branch",
    [TASK_TYPE.TASK_TYPE_DAILY] = "Daily",
    [TASK_TYPE.TASK_TYPE_UNION] = "Union",
    [TASK_TYPE.TASK_TYPE_TARGET] = "Target",
    [TASK_TYPE.TASK_TYPE_HEROROAD] = "HeroRoad",
}
local function _getTaskTypeString(task_type)
    return task_type_string[task_type] or "Invalid"
end

local task_status_string = 
{
    [TASK_STATUS.TASK_STATUS_LOCK] = "Lock",
    [TASK_STATUS.TASK_STATUS_CAN_ACCEPT] = "CanAccept",
    [TASK_STATUS.TASK_STATUS_ACCEPTED] = "Accepted",
    [TASK_STATUS.TASK_STATUS_CAN_FINISH] = "CanFinish",
    [TASK_STATUS.TASK_STATUS_FINISHED] = "Finished",
    [TASK_STATUS.TASK_STATUS_UPDATE] = "Update",
    [TASK_STATUS.TASK_STATUS_DOING] = "Doing",
}
local function _getTaskStatusString(task_status)
    return task_status_string[task_status] or "Invalid"
end

function TaskManager:_addPendingTask(task)
    if TASK_TYPE.TASK_TYPE_TRUNK == task.task_type or
        TASK_TYPE.TASK_TYPE_BRANCH == task.task_type then

        for _, v in ipairs(self.pending_tasks) do
            if v == task.task_id then
                return
            end
        end
        table.insert(self.pending_tasks, task.task_id)
        INFO("[Autobot|TaskManager|%d] add pending task : %d|%s|%s|%d",
        self.player.pid,
        task.task_id,
        _getTaskTypeString(task.task_type),
        _getTaskStatusString(task.task_status),
        #self.pending_tasks)
    end
end

function TaskManager:fetchPendingTask()
    if 0 == #self.pending_tasks then
        return
    end
    local task_id = self.pending_tasks[1]
    local task = self:getTask(task_id)
    table.remove(self.pending_tasks, 1)

    INFO("[Autobot|TaskManager|%d] fetched pending task : %d", self.player.pid, task_id)
    return task
end

function TaskManager:getPendingTaskCount()
    return #self.pending_tasks
end

return TaskManager

