local RecruitRest = {}

local REST_TIME = 1

function RecruitRest:onEnter()
    self.timer_id = AutobotTimer:addTimer(function() self:translate("TakeAction") end, REST_TIME)
end

function RecruitRest:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
end

return makeState(RecruitRest)

