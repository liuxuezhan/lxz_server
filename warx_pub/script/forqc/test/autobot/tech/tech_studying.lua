local TechStudying = {}

local rest_time = 3

function TechStudying:onEnter()
    local build = get_build(self.host.player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ACADEMY)
    if nil == build or BUILD_STATE.WORK ~= build.state then
        self.fsm:translate("Idle")
        return
    end
    self.host.player.eventBuildUpdated:add(newFunctor(self, self._onBuildUpdated))
    self:_refreshWaitTime(build)
end

function TechStudying:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
    self.last_overtime = nil
    self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
end

function TechStudying:_refreshWaitTime(build)
    local overtime = build.tmOver
    local wait_time = rest_time
    if overtime > gTime then
        wait_time = overtime - gTime + rest_time
        self:_checkUnionHelp(build)
    else
        self.host.player.eventBuildUpdated:del(newFunctor(self, self._onBuildUpdated))
    end

    if nil == self.timer_id then
        INFO("[Autobot|Tech|%d] Study tech %d will spend %d seconds.", self.host.player.pid, build.extra.id, wait_time)
        self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._onTimesUp), wait_time)
    elseif self.last_overtime ~= build.tmOver then
        INFO("[Autobot|Tech|%d] Reset tech %d and will spend %d seconds now.", self.host.player.pid, build.extra.id, wait_time)
        AutobotTimer:adjustTimer(self.timer_id, wait_time)
    end
    self.last_overtime = build.tmOver
end

function TechStudying:_checkUnionHelp(build)
    if not self.host.player:is_in_union() then
        return
    end
    local help_pid = self.host.player.union_help_manager:getHelp(build.tmSn)
    if nil ~= help_pid then
        return
    end
    INFO("[Autobot|Tech|%d] Asking union's help.", self.host.player.pid)
    Rpc:union_help_add(self.host.player, build.tmSn)
end

function TechStudying:_onBuildUpdated(player, build)
    if build.state ~= BUILD_STATE.WORK then
        return
    end
    local prop = resmng.prop_build[build.propid]
    if nil == prop or prop.Class ~= BUILD_CLASS.FUNCTION or prop.Mode ~= BUILD_FUNCTION_MODE.ACADEMY then
        return
    end
    self:_refreshWaitTime(build)
end

function TechStudying:_onTimesUp()
    local build = get_build(self.host.player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ACADEMY)
    if build.state == BUILD_STATE.WORK then
        self:_refreshWaitTime(build)
    else
        INFO("[Autobot|Tech|%d] Player has studied tech.", self.host.player.pid)
        self.fsm:translate("Idle")
    end
end

return makeState(TechStudying)

