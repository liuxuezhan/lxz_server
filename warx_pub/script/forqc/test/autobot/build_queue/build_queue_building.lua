local BuildQueueBuilding = {}

local delay_time = 3

local function _getBuild(self)
    local build_idx = self.player.build_queue[self.which_queue]
    if build_idx > 0 then
        return self.player._build[build_idx]
    end
end

local function _buildNextBuilding(self)
    action(function()
        wait_for_time(delay_time)
        self.fsm:translate("Idle")
    end)
end

function BuildQueueBuilding:onInit()
end

function BuildQueueBuilding:onEnter()
    self.which_queue = self.host.which_queue
    self.player = self.host.entity.player
    -- find the building build
    -- wait for the building complete
    INFO("[Autobot|BuildQueue|%d|%d]Player is busy: %d", self.player.pid, self.which_queue, self.player.build_queue[self.which_queue])
    local overtime = 0
    local build = _getBuild(self)
    if build then
        overtime = build.tmOver
    end
    if 0 == overtime then
        INFO("[Autobot|BuildQueue|%d|%d]Player has no under construction building", self.player.pid, self.which_queue)
        _buildNextBuilding(self)
    else
        --local free_time = get_val(self.player, "BuildFreeTime") or 0
        local free_time = self.host.entity:get_val("BuildFreeTime") or 0
        local overtime = build.tmOver
        local wait_time = delay_time
        if overtime > gTime + free_time then
            wait_time = overtime - ( gTime + free_time ) + delay_time
        else
            INFO("[Autobot|BuildQueue|%d|%d]overtime mismatch %d|%d", self.player.pid, self.which_queue, overtime, gTime)
        end

        INFO("[Autobot|BuildQueue|%d|%d]It will take %d|%d seconds to finish the building", self.player.pid, self.which_queue, wait_time, free_time)
        timer.new_ignore("BuildQueueBuilding", wait_time, self)
    end
end

function BuildQueueBuilding:onExit()
end

timer._funs["BuildQueueBuilding"] = function(sn, self)
    INFO("[Autobot|BuildQueue|%d|%d]Player has waited enought time, now accelerate with free time.", self.player.pid, self.which_queue)
    self.fsm:translate("Accelerate")
end

return makeState(BuildQueueBuilding)

