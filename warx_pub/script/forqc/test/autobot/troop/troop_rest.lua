local TroopRest = {}

local REST_TIME = config.Autobot.TroopRestTime or 5

function TroopRest:onEnter()
    INFO("[Autobot|TroopRest|%d] rest for %d seconds for next troop.", self.host.player.pid, REST_TIME)
    AutobotTimer:addTimer(function()
        self.fsm:translate("TakeAction")
    end, REST_TIME)
end

return makeState(TroopRest)

