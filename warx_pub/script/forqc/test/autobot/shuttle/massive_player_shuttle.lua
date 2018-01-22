local MassivePlayerShuttle = {}

local function Transport()
    local pre_idx = config.Autobot.Massive_PreIdx
    local batch_count = config.Autobot.Massive_BatchCount
    local loop_count = config.Autobot.Massive_LoopCount
    local interval = config.Autobot.Massive_Interval
    WARN("[Autobot|MassiveShuttle] Start to load player [%d * 1000000 + %d * 1000 + %d|%d].", pre_idx, batch_count, loop_count, interval)
    for i = 1, batch_count do
        for j = 1, loop_count do
            local idx = pre_idx * 1000000 + i * 1000 + j
            local entity = Entity.createEntity(idx)
            bot_mng:addEntity(entity)
            entity:start()
        end
        wait_for_time(interval)
    end
    WARN("[Autobot|MassiveShuttle] All player have been started.")
end

function MassivePlayerShuttle:onStart()
    action(Transport)
end

return makeShuttle("MassivePlayer", MassivePlayerShuttle)

