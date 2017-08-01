local ChoreReap = {}

local REAP_INTERVAL = config.Autobot.ChoreReapInterval or 600

function ChoreReap:init(player)
    self.player = player
    self.periodic_id = AutobotTimer:addPeriodicTimer(newFunctor(self, ChoreReap._doReap), REAP_INTERVAL)
end

function ChoreReap:unint()
    AutobotTimer:delPeriodicTimer(self.periodic_id)
end

function ChoreReap:_doReap()
    local count = 0
    for k, v in pairs(self.player._build) do
        local prop = resmng.prop_build[v.propid]
        if BUILD_CLASS.RESOURCE == prop.Class then
            Rpc:reap(self.player, v.idx)
            count = count + 1
        end
    end
    INFO("[Autobot|ChoreReap|%d] Reap resource from %d building.", self.player.pid, count)
end

return makeClass(ChoreReap)

