local TechIdle = {}

local function _onPriorityChanged(self)
    self:_takeAction()
end

local function _onJobAccepted(self)
    self:_takeAction()
end

function TechIdle:onInit()
end

function TechIdle:onEnter()
    self.host.eventPriorityChanged:add(newFunctor(self, _onPriorityChanged))
    self.host.eventJobAccepted:add(newFunctor(self, _onJobAccepted))

    self:_takeAction()
end

function TechIdle:onExit()
    self.host.eventPriorityChanged:del(newFunctor(self, _onPriorityChanged))
    self.host.eventJobAccepted:del(newFunctor(self, _onJobAccepted))
end

function TechIdle:_takeAction()
    if not self.host:canStudyTech() then
        return
    end
    if not self.host:hasStudyJob() then
        return
    end
    self.fsm:translate("TakeAction")
end

return makeState(TechIdle)

