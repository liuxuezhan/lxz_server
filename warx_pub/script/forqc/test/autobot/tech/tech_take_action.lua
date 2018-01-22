local TechTakeAction = {}

local dealy_time = 2

local function _studyNextTech(self)
    self.timer_id = AutobotTimer:addTimer(function() self.fsm:translate("Idle") end, dealy_time)
end

function TechTakeAction:onInit()
end

function TechTakeAction:onEnter()
    if not self.host:canStudyTech() and
        not self.host:hasStudyJob() then
        _studyNextTech(self)
        return
    end
    --[[
    local job = self.host:getStudyJob()
    if nil == job then
        _studyNextTech(self)
        return
    end
    local build = get_build(self.host.player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ACADEMY)
    if nil == build then
        self.host.build_manager:addBuilding(BUILD_ACADEMY_1, job.priority + 1, 1)
        self.host.addStudyJob(job.tech_id, job.priority, job.functor)
        _studyNextTech(self)
        return
    end
    -- TODO: 前置条件判定（在tech_manager.lua里做）
    -- TODO: 资源不够的处理
    -- ]]
    local tech_id = self.host:getStudyJob()
    if nil == tech_id then
        _studyNextTech(self)
        return
    end
    local build = get_build(self.host.player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ACADEMY)
    if nil == build then
        self.host.build_manager:addBuilding(BUILD_ACADEMY_1, job.priority + 1, 1)
        _studyNextTech(self)
        return
    end

    INFO("[Autobot|Tech|%d] start to study tech %d.", self.host.player.pid, tech_id)
    Rpc:learn_tech(self.host.player, build.idx, tech_id, 0)

    self.host.player:sync(function()
        self.fsm:translate("Studying")
    end)
end

function TechTakeAction:onExit()
    if nil ~= self.timer_id then
        AutobotTimer:delTimer(self.timer_id)
        self.timer_id = nil
    end
end

return makeState(TechTakeAction)

