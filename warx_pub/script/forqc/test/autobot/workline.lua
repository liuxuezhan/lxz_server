local Workline = {}

function Workline:initState()
end

function Workline.addUpdateState(fsm)
    local entity = fsm.host.entity
    entity.update_states = entity.update_states or {}
    entity.update_states[fsm] = true
end

function Workline.delUpdateState(fsm)
    local entity = fsm.host.entity
    entity.update_states = entity.update_states or {}
    entity.update_states[fsm] = false
end

function Workline.updateState(entity)
    local need_delete = {}
    local update_states = entity.update_states or {}
    for k, v in pairs(update_states) do
        if v then
            k:update()
        else
            table.insert(need_delete, k)
        end
    end
    for k, v in ipairs(need_delete) do
        update_states[v] = nil
    end
end

return makeFSM(Workline)

