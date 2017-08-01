local TechTakeAction = {}

local dealy_time = 2

local function _studyNextTech(self)
    action(function()
        wait_for_time(dealy_time)
        self.fsm:translate("Idle")
    end)
end

function TechTakeAction:onInit()
end

function TechTakeAction:onEnter()
    if not self.host:canStudyTech() and
        not self.host:hasStudyJob() then
        _studyNextTech(self)
        return
    end
    local job = self.host:getStudyJob()
    if nil == job then
        _studyNextTech(self)
        return
    end
    local build = get_build(self.host.player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ACADEMY)
    if nil == build then
        self.host.wanted_building:addBuilding(BUILD_ACADEMY_1, job.priority + 1, 1)
        self.host.addStudyJob(job.tech_id, job.priority, job.functor)
        _studyNextTech(self)
        return
    end
    -- TODO: 前置条件判定（在tech_manager.lua里做）
    -- TODO: 资源不够的处理

    INFO("[Autobot|Tech|%d] start to study tech %d.", self.host.player.pid, job.tech_id)
    Rpc:learn_tech(self.host.player, build.idx, job.tech_id, 0)

    action(function()
        wait_for_time(1)
        self.fsm:translate("Studying")
    end)
end

function TechTakeAction:onExit()
end

return makeState(TechTakeAction)

