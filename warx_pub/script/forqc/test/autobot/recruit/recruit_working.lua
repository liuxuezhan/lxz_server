local RecruitWorking = {}

local rest_time = 3

function RecruitWorking:onInit()
end

function RecruitWorking:onEnter()
    local build = get_build(self.host.player, BUILD_CLASS.ARMY, self.fsm.mode)
    if nil == build then
        -- no building, don't kidding me
        self.fsm:translate("Idle")
        return
    end
    if BUILD_STATE.WORK ~= build.state then
        -- not working
        self.fsm:translate("Idle")
        return
    end

    -- calculate the working time
    local overtime = build.tmOver
    local wait_time = 0
    if overtime <= gTime then
        wait_time = rest_time
    else
        wait_time = overtime - gTime + rest_time
    end
    INFO("[Autobot|Recruit|%d]Recruiting %d, Wait for %d seconds.", self.host.player.pid, self.fsm.mode, wait_time)
    timer.new_ignore("Recruit_Working", wait_time, self)
end

function RecruitWorking:onExit()
end

timer._funs["Recruit_Working"] = function(sn, self)
    INFO("[Autobot|Recruit|%d] player has recruited %d.", self.host.player.pid, self.fsm.mode)
    self.fsm:translate("Idle")
end

return makeState(RecruitWorking)

