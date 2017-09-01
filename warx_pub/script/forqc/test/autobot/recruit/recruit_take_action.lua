-- 
--

local RecruitTakeAction = {}

local build_prop_id = {
    [BUILD_ARMY_MODE.BARRACKS] = BUILD_BARRACKS_1,
    [BUILD_ARMY_MODE.STABLES] = BUILD_STABLES_1,
    [BUILD_ARMY_MODE.RANGE] = BUILD_RANGE_1,
    [BUILD_ARMY_MODE.FACTORY] = BUILD_FACTORY_1,
}

function RecruitTakeAction:onInit()
end

function RecruitTakeAction:onEnter()
    if not self.host:getRecruitPermit(self.fsm.mode) and
        not self.host:hasRecruitJob(self.fsm.mode) then
        self.fsm:translate("Idle")
        return
    end
    local job = self.host:getRecruitJob(self.fsm.mode)
    local build = get_build(self.host.player, BUILD_CLASS.ARMY, job.mode)
    -- 没有建筑
    if nil == build then
        local propid = build_prop_id[job.mode]
        self.host.build_manager:addBuilding(propid, job.priority + 1, 1)
        self.host:addRecruitJob(job.mode, job.level, job.num, job.priority, job.accelerate)
        self.fsm:translate("Idle")
        return
    end

    local level = job.level
    local build_prop = resmng.prop_build[build.propid]
    -- 建筑等级不够
    if level > 0 then
        if build_prop.TrainLv < level then
            self.host.build_manager:addBuilding(build.propid + 1, job.priority + 1, 1)
            self.host:addRecruitJob(job.mode, job.level, job.num, job.priority, job.accelerate)
            self.fsm:translate("Idle")
            return
        end
    else
        level = build_prop.TrainLv
    end

    -- TODO: 资源不够的处理逻辑

    local army_id = get_arm_id_by_mode_lv(job.mode, job.level, self.host.player.culture)
    
    INFO("[Autobot|Recruit|%d] start to recruit soldier %d|%d, accelerate %s", self.host.player.pid, army_id, job.num, tostring(job.accelerate))
    Rpc:train(self.host.player, build.idx, army_id, job.num, job.accelerate and 1 or 0)

    action(function()
        wait_for_time(2)
        self.fsm:translate("Working")
    end)
end

function RecruitTakeAction:onExit()
end

return makeState(RecruitTakeAction)

