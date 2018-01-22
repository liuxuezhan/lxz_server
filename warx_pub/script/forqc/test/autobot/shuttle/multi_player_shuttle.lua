local MultiPlayerShuttle = {}

function MultiPlayerShuttle:onStart()
    INFO("[Autobot|BotMng] Start multi-player shuttle")
    action(function()
        for _, idx in pairs(config.Autobot.MultiPlayer.Idxs) do
            wait_for_time(config.Autobot.MultiPlayer.Interval)
            local entity = Entity.createEntity(idx)
            bot_mng:addEntity(entity)
            entity:start()
        end
    end)
end

return makeShuttle("MultiPlayer", MultiPlayerShuttle)

