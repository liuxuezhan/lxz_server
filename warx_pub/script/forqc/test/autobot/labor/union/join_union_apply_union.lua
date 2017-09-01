local JoinUnion_ApplyUnion = {}

local MAX_WAIT_TIME = 5

function JoinUnion_ApplyUnion:onEnter(union)
    INFO("[Autobot|JoinUnion|%d] Applying union : %s|%d", self.host.player.pid, union.name, union.uid)
    Rpc:union_apply(self.host.player, union.uid)
    self.host.player.eventUnionReply:add(newFunctor(self, self._onUnionReply))
    self.host.player:addRpcErrorHandler("union_apply", newFunctor(self, self._onApplyError))
    self.timer_id = AutobotTimer:addTimer(newFunctor(self, self._onTimeout), MAX_WAIT_TIME)
end

function JoinUnion_ApplyUnion:onExit()
    self.host.player:delRpcErrorHandler("union_apply", newFunctor(self, self._onApplyError))
    self.host.player.eventUnionReply:del(newFunctor(self, self._onUnionReply))
    AutobotTimer:delTimer(self.timer_id)
end

-- 申请错误
function JoinUnion_ApplyUnion:_onApplyError(code, reason)
    INFO("[Autobot|JoinUnion|%d] Server notify error on apply: %d|%d", self.host.player.pid, code, reason)
    self:translate("GetUnions")
end

-- 申请成功
function JoinUnion_ApplyUnion:_onUnionReply(player, union_id, name, state)
    if UNION_STATE.APPLYING == state then
        -- 直接准备申请加入下一个军团，不等待军团管理同意
        self:translate("GetUnions")
    elseif UNION_STATE.IN_UNION == state then
        WARN("[Autobot|JoinUnion|%d] Player has joined the union %s(%d)", self.host.player.pid, name, union_id)
        self.fsm:translate("Accomplish")
    end
end

function JoinUnion_ApplyUnion:_onTimeout()
    INFO("[Autobot|JoinUnion|%d] Apply timeout", self.host.player.pid)
    self:translate("GetUnions")
end

return makeState(JoinUnion_ApplyUnion)

