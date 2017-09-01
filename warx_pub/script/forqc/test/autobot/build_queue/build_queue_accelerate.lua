local BuildQueueAccelerate = {}

local delay_time = 3

function BuildQueueAccelerate:_getBuild()
    local build_idx = self.host.player.build_queue[self.fsm.queue_index]
    if build_idx > 0 then
        return self.host.player._build[build_idx]
    end
end

function BuildQueueAccelerate:onEnter()
    local build = self:_getBuild()
    if nil == build then
        return
    end
    if BUILD_STATE.CREATE ~= build.state and BUILD_STATE.UPGRADE ~= build.state then
        return
    end
    INFO("[Autobot|BuildQueue|%d|%d] Accelerate building %d/%d", self.host.player.pid, self.fsm.queue_index, build.idx, build.propid)
    Rpc:acc_build(self.host.player, build.idx,  ACC_TYPE.FREE)
end

function BuildQueueAccelerate:_getBuild()
    local build_idx = self.host.player.build_queue[self.fsm.queue_index]
    if build_idx > 0 then
        return self.host.player._build[build_idx]
    end
end

return makeState(BuildQueueAccelerate)

