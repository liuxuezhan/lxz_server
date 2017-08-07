local ScavengerMonsterRest = {}

local INITIAL_TIME = config.Autobot.ScavengeMonsterInitialRestTime or 5
local REST_TIME = config.Autobot.ScavengeMonsterRestTime or 30

function ScavengerMonsterRest:onInit()
    self.rest_time = INITIAL_TIME
end

function ScavengerMonsterRest:onEnter()
    self.timer_id = AutobotTimer:addTimer(function()
        self.fsm:translate("TakeAction")
    end, self.rest_time)
    self.rest_time = REST_TIME
end

function ScavengerMonsterRest:onExit()
    AutobotTimer:delTimer(self.timer_id)
end

return makeState(ScavengerMonsterRest)

