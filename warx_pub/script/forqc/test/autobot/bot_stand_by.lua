local BotStandBy = {}

function BotStandBy:onInit()
end

function BotStandBy:onEnter(immediately)
    if immediately then
        INFO("[Autobot|StandBy]%s is ready to login now", self.host.idx)
        self.fsm:translate("Login")
        return
    end
    local seconds = math.random(1,800)
    timer.new_msec_ignore("BotStandBy", seconds, self)
    INFO("[Autobot|StandBy]%d will wait for %d milliseconds", self.host.idx, seconds)
    --self.fsm:translate("Login")
end

function BotStandBy:onUpdate()
end

function BotStandBy:onExit()
end

function BotStandBy:onTimer()
    INFO("[Autobot|StandBy]%s is ready to login", self.host.idx)
    self.fsm:translate("Login")
end

timer._funs["BotStandBy"] = function(sn, self)
    self:onTimer()
end

return makeState(BotStandBy)

