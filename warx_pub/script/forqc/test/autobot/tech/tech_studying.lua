local TechStudying = {}

local rest_time = 3

function TechStudying:onInit()
end

function TechStudying:onEnter()
    local build = get_build(self.host.player, BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ACADEMY)
    if nil == build or BUILD_STATE.WORK ~= build.state then
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
    self.tech_id = build.extra.id
    INFO("[Autobot|Tech|%d] Studying tech %d, wait for %d seconds.", self.host.player.pid, self.tech_id, wait_time)
    timer.new_ignore("Tech_Studying", wait_time, self)
end

function TechStudying:onExit()
end

timer._funs["Tech_Studying"] = function(sn, self)
    INFO("[Autobot|Tech|%d] Player has studied tech %d.", self.host.player.pid, self.tech_id)
    self.fsm:translate("Idle")
end

return makeState(TechStudying)

