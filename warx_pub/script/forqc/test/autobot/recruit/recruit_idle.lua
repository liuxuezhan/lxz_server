-- 
--

local RecruitIdle = {}

local function _onPriorityChanged(self, recruit_manager, mode)
    if self.fsm.mode ~= mode then
        return
    end
    self:_takeAction()
end

local function _onJobAccepted(self, recruit_manager, mode)
    if self.fsm.mode ~= mode then
        return
    end
    self:_takeAction()
end

function RecruitIdle:onInit()
end

function RecruitIdle:onEnter()
    self.host.eventPriorityChanged:add(newFunctor(self, _onPriorityChanged))
    self.host.eventJobAccepted:add(newFunctor(self, _onJobAccepted))

    self:_takeAction()
end

function RecruitIdle:onExit()
    self.host.eventPriorityChanged:del(newFunctor(self, _onPriorityChanged))
    self.host.eventJobAccepted:del(newFunctor(self, _onJobAccepted))
end

function RecruitIdle:_takeAction()
    if not self.host:getRecruitPermit(self.fsm.mode) then
        return
    end
    if not self.host:hasRecruitJob(self.fsm.mode) then
        return
    end
    self.fsm:translate("TakeAction")
end

return makeState(RecruitIdle)

