local TaskAction = {}

TaskAction.__index = TaskAction

function TaskAction:init(task_action_manager, player)
    self.task_action_manager = task_action_manager
    self.player = player
    if self.onStart then
        self:onStart()
    end
end

function TaskAction:uninit()
    if self.onStop then
        self:onStop()
    end
    self.player = nil
end

function TaskAction:process(task_data, ...)
    self.task_id = task_data.task_id
    self:onProcess(task_data, ...)
end

function TaskAction:_finishTask()
    local task = self.player.task_manager:getTask(self.task_id)
    if nil == task then
        return
    end
    if task.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then
        return
    end
    INFO("[Autobot|TaskAction|%d] Task %d has finished", self.player.pid, self.task_id)
    task.task_status = TASK_STATUS.TASK_STATUS_CAN_FINISH
    self.player:eventTaskInfoUpdated(task, nil)
    self.task_action_manager:delTaskHandler(self.task_id)
end

local task_action_handlers = {}

function makeTaskActionHandler(task_action, handler)
    assert(nil == task_action_handlers[task_action], "The type of action has registered")

    handler.createInstance = function(self, task_action_manager, player)
        local instance = setmetatable({}, self)
        instance.task_action = task_action
        instance:init(task_action_manager, player)
        return instance
    end
    handler.__index = handler
    setmetatable(handler, TaskAction)
    task_action_handlers[task_action] = handler

    return handler
end

local TaskActionManager = {}

function TaskActionManager:init(player)
    self.player = player
    self.handlers = {}
    self.player.eventTaskInfoUpdated:add(newFunctor(self, self._onTaskInfoUpdated))

    for k, v in pairs(self.player._task.cur or {}) do
        self:addTaskHandler(v)
    end
end

function TaskActionManager:uninit()
    self.player.eventTaskInfoUpdated:del(newFunctor(self, self._onTaskInfoUpdated))
    for k, v in pairs(self.handlers) do
        v:uninit()
    end
    self.handlers = nil
end

function TaskActionManager:addTaskHandler(task_data)
    if task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then
        return
    end
    if not task_action_handlers[task_data.task_action] then
        return
    end
    if nil ~= self.handlers[task_data.task_id] then
        return
    end

    local prop = getTaskProp(task_data)
    self:_processTaskHandler(task_data, unpack(prop.FinishCondition))
end

function TaskActionManager:_processTaskHandler(task_data, func, ...)
    local player = self.player
    local task_action = task_data.task_action
    local task_id = task_data.task_id
    if task_action ~= g_task_func_relation[func] then
        WARN("[Autobot|TaskAction|%d] The action %d of task %d mismatches func '%s'", player.pid, task_action, task_id, func)
        return
    end
    local handler = task_action_handlers[task_action]:createInstance(self, player)
    self.handlers[task_id] = handler

    handler:process(task_data, ...)
end

function TaskActionManager:delTaskHandler(task_id)
    if self.handlers[task_id] then
        self.handlers[task_id]:uninit()
        self.handlers[task_id] = nil
    end
end

function TaskActionManager:_onTaskInfoUpdated(player, task_data)
    self:addTaskHandler(task_data)
end

return makeClass(TaskActionManager)

