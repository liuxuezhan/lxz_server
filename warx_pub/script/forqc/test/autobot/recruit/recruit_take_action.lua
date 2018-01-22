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
        self:translate("Idle")
        return
    end
    local job = self.host:getRecruitJob(self.fsm.mode)
    local build = get_build(self.host.player, BUILD_CLASS.ARMY, job.mode)
    -- 没有建筑
    if nil == build then
        local propid = build_prop_id[job.mode]
        self.host.build_manager:addBuilding(propid, job.priority + 1, 1)
        self.host:addRecruitJob(job.mode, job.level, job.num, job.priority, job.acc_type, job.functor)
        self:translate("Idle")
        return
    end

    local level = job.level
    local build_prop = resmng.prop_build[build.propid]
    -- 建筑等级不够
    if level > 0 then
        if build_prop.TrainLv < level then
            self.host.player.build_manager:addBuilding(build.propid + 1, job.priority + 1, 1)
            self.host:addRecruitJob(job.mode, job.level, job.num, job.priority, job.acc_type, job.functor)
            self:translate("Idle")
            return
        end
    else
        level = build_prop.TrainLv
    end

    -- TODO: 资源不够的处理逻辑

    local army_id = get_arm_id_by_mode_lv(job.mode, level, self.host.player.culture)
    
    INFO("[Autobot|Recruit|%d|%d] start to recruit soldier %d|%d, acc_type %d", self.host.player.pid, self.fsm.mode, army_id, job.num, job.acc_type)
    Rpc:train(self.host.player, build.idx, army_id, job.num, job.acc_type == ACC_TYPE.GOLD and 1 or 0)
    self.host.player:addRpcErrorHandler("train", newFunctor(self, self._onError))
    self.host.player:sync(function()
        if self.train_result then
            if job.acc_type == ACC_TYPE.GOLD then
                self:translate("Rest")
            else
                self:translate("Working", job.functor, job.acc_type)
            end
        else
            self.host:addRecruitJob(job.mode, job.level, job.num, job.priority, job.acc_type, job.functor)
            self:translate("Rest")
        end
    end)
end

function RecruitTakeAction:onExit()
    self.host.player:delRpcErrorHandler("train", newFunctor(self, self._onError))
    self.train_result = nil
end

function RecruitTakeAction:_onError(code, reason)
    local build = self.host.player:get_build(BUILD_CLASS.ARMY, self.fsm.mode)
    if nil == build then
        return
    end
    if build.idx ~= reason then
        return
    end
    self.train_result = code == resmng.E_OK
end

return makeState(RecruitTakeAction)

