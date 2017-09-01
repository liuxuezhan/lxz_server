local Bot = {}

function Bot:onInit()
    self:addState("StandBy", BotStandBy, true)
    self:addState("Login", BotLogin)
    self:addState("Game", BotGame)
end

-- static method and members
-- update support
Bot.update_states = {}
function Bot.addUpdateState(fsm)
    Bot.update_states[fsm] = true
end

function Bot.delUpdateState(fsm)
    Bot.update_states[fsm] = false
end

function Bot.updateState()
    local need_delete = {}
    for k, v in pairs(Bot.update_states) do
        if v then
            k:update()
        else
            table.insert(need_delete, k)
        end
    end
    for k, v in ipairs(need_delete) do
        Bot.update_states[v] = nil
    end
end

return makeFSM(Bot)

