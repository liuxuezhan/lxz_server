local SoloShuttle = {}

function SoloShuttle:onStart()
    INFO("[Autobot|BotMng] Start solo shuttle")
    local entity = Entity.createEntity(config.Autobot.SinglePlayerIdx)
    bot_mng:addEntity(entity)
    entity:start()
end

return makeShuttle("Solo", SoloShuttle)

