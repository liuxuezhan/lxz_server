local JoinUnion_GetUnions = {}

local WAIT_MIN_TIME = config.Autobot.JoinUnionWaitMinTime or 30
local WAIT_MAX_TIME = config.Autobot.JoinUnionWaitMaxTime or 90

function JoinUnion_GetUnions:onEnter()
    local wait_time = math.random(WAIT_MIN_TIME * 1000, WAIT_MAX_TIME * 1000)
    self.timer_id = AutobotTimer:addMsecTimer(newFunctor(self, self._requestUnions), wait_time)
end

function JoinUnion_GetUnions:onExit()
    AutobotTimer:delTimer(self.timer_id)
    self.timer_id = nil
    self.host.player.eventGotUnionList:del(newFunctor(self, self._onGotUnions))
end

function JoinUnion_GetUnions:_requestUnions()
    INFO("[Autobot|JoinUnion|%d] request union list", self.host.player.pid)
    Rpc:union_list(self.host.player, "")
    self.host.player.eventGotUnionList:add(newFunctor(self, self._onGotUnions))
end

function JoinUnion_GetUnions:_onGotUnions(player, key, unions)
    local available_unions = {}
    for k, v in pairs(unions) do
        if v.membercount < v.memberlimit and 0 == v.enlist.check then
            table.insert(available_unions, v)
        end
    end
    local count = #available_unions
    if 0 == count then
        self:translate("CreateUnion")
    else
        local index = math.random(1, count)
        local union = available_unions[index]
        self:translate("ApplyUnion", union)
    end
end

return makeState(JoinUnion_GetUnions)

