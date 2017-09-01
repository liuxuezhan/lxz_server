local TroopRest = {}

local REST_TIME = config.Autobot.TroopRestTime or 5

function TroopRest:onEnter()
    INFO("[Autobot|TroopRest|%d] rest for %d seconds for next troop.", self.host.player.pid, REST_TIME)
    self.timer_id = AutobotTimer:addTimer(function()
        self.fsm:translate("TakeAction")
    end, REST_TIME)
    -- 如果troop太多，将自己移除
    if self.host:checkTroopQueue(self.fsm) then
        if not self.host:isActive() then
            self:translate("Idle")
        end
    end
end

function TroopRest:onExit()
    AutobotTimer:delTimer(self.timer_id)
end

return makeState(TroopRest)

