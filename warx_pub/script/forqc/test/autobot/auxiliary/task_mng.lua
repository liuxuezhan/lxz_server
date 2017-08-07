local Task = {}

local TASK_THREAD_COUNT = config.Autobot.TaskThreadCount or 1000

Task.__index = Task

function Task.create(action, functor, ...)
    local task = {action = action, eventFinished = newEventHandler(), args = table.pack(...)}
    task.eventFinished:add(functor)
    return setmetatable(task, Task)
end

function Task:execute()
    self.eventFinished(self.action(table.unpack(self.args)))
end

local TaskMng = {}

TaskMng.tasks = {}
TaskMng.threads = {}

local function _taskThreadImpl(self)
    local co = coroutine.running()
    while true do
        if self.quitFlag then
            break
        end
        self:_putThread(co)
        local task = coroutine.yield("standby")

        if nil == task then
            break
        end
        task:execute()
    end
    return "end"
end

local function _taskThread(self)
    if _ENV then
        xpcall(_taskThreadImpl, STACK, self)
    else
        _taskThreadImpl(self)
    end
end

function TaskMng:init()
    for i = 1, TASK_THREAD_COUNT do
        self:_createThrad()
    end
end

function TaskMng:uninit()
    self.quitFlag = true
    for k, v in ipairs(self.threads) do
        coroutine.resume(v)
    end
    -- what about these threads is executing?
    -- should we track all the hang out threads?
end

function TaskMng:createTask(action, functor, ...)
    local task = Task.create(action, functor, ...)
    table.insert(self.tasks, task)
end

function TaskMng:update()
    while #self.tasks > 0 do
        local task = table.remove(self.tasks, 1)
        if nil ~= task then
            local thread = self:_getThread()
            coroutine.resume(thread, task)
        end
    end
    --[[
    while #self.threads > 0 do
        if #self.tasks < 1 then
            break
        end
        local task = table.remove(self.tasks, 1)
        if nil ~= task then
            local coro = table.remove(self.threads)
            coroutine.resume(coro, task)
        end
    end
    --]]
end

function TaskMng:_createThrad()
    local thread = coroutine.create(_taskThread)
    local res = coroutine.resume(thread, self)
    return thread
end

function TaskMng:_getThread()
    if #self.threads > 0 then
        return table.remove(self.threads)
    end
    INFO("[Autobot|TaskMng]Lack of task thread, create one")
    return self:_createThrad()
end

function TaskMng:_putThread(thread)
    if #self.threads >= TASK_THREAD_COUNT then
        return
    end
    table.insert(self.threads, thread)
end

return TaskMng

