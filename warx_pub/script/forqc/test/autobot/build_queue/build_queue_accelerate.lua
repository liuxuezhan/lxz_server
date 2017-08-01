local BuildQueueAccelerate = {}

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

function BuildQueueAccelerate:onInit()
    self.which_queue = self.host.which_queue
    self.player = self.host.entity.player
end

function BuildQueueAccelerate:onEnter()
    local build = _getBuild(self)
    if nil == build then
        _buildNextBuilding(self)
        return
    end
    if BUILD_STATE.CREATE ~= build.state and BUILD_STATE.UPGRADE ~= build.state then
        _buildNextBuilding(self)
        return
    end
    INFO("[Autobot|BuildQueue|%d|%d] Accelerate building %d/%d", self.player.pid, self.which_queue, build.idx, build.propid)
    Rpc:acc_build(self.player, build.idx,  ACC_TYPE.FREE)
    _buildNextBuilding(self)
end

return makeState(BuildQueueAccelerate)

