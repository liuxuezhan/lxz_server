local BotLogin = {}

function BotLogin:onInit()
end

local function _getPlayer(idx)
    local player = get_account(idx)
    loadData(player)
    Rpc:set_client_parm(player, "guidedclass","1|2|3|4|5|6|7|9|10|12|13|14|15|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|40|43|44|45|46|47|48|49|50|51|52|53|55|56|57|66|67|68|101|102|103|104|105")  
    sync(player)
    return player
end

function BotLogin:onEnter()
    self.start_time = gMsec / 1000
    INFO("[Autobot|Login]Player %s start login.", self.host.idx)
    TaskMng:createTask(_getPlayer, newFunctor(self, BotLogin.onLoadPlayer), self.host.idx)
end

--function BotLogin:onUpdate()
--end

--function BotLogin:onExit()
--end

function BotLogin:onLoadPlayer(player)
    self.load_time = gMsec / 1000 - self.start_time
    INFO("[Autobot|Login|%d]Player %s spend %f seconds to load.", player.pid, self.host.idx, self.load_time)
    self.host:initPlayer(player)
    self.fsm:translate("Game")
end

return makeState(BotLogin)

