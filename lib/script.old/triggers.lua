module("triggers_t")


triggers_funcs = {} 

--进入区域
function enter_range(x, y, actor_eid, scanner_eid, parm1, parm2, parm3, parm4)
    local mode = get_mode_by_eid(scanner_eid)
    if mode == EidType.Troop then
        triggers_enter_troop(x, y, actor_eid, scanner_eid, parm1, parm2, parm3, parm4)
    else
        triggers_enter_world_unit(x, y, actor_eid, scanner_eid, parm1, parm2, parm3, parm4)
    end
end

--离开区域
function leave_range(x, y, actor_eid, scanner_eid, parm1, parm2, parm3, parm4)
    local mode = get_mode_by_eid(scanner_eid)
    if mode == EidType.Troop then
        triggers_leave_troop(x, y, actor_eid, scanner_eid, parm1, parm2, parm3, parm4)
    else
        triggers_leave_world_unit(x, y, actor_eid, scanner_eid, parm1, parm2, parm3, parm4)
    end
end

--到达目的地
function arrived_target(x, y, actor_eid, parm1, parm2, parm3, parm4, parm5)
    local troop = get_ety(actor_eid)
    if troop ~= nil then
        if x == troop.dx and y == troop.dy then
            troop.curx = troop.dx
            troop.cury = troop.dy
            troop.tmCur = gTime
            troop_mng.trigger_event(troop)
        else
            print("arrive", x, y, troop.dx, troop.dy)
        end
    end
end


--进入部队范围
-------------------------------------------------------------------
-------------------------------------------------------------------
function triggers_enter_troop(x, y, actor_eid, scanner_eid, ...)
    
end

function triggers_leave_troop(x, y, actor_eid, scanner_eid, ...)
end

--进入建筑范围
-------------------------------------------------------------------
-------------------------------------------------------------------
function triggers_enter_world_unit(x, y, actor_eid, scanner_eid, ...)
    local world_unit = get_ety(scanner_eid)
    if world_unit == nil then return end

    local prop_unit = resmng.prop_world_unit[world_unit.propid]
    if prop_unit == nil then return end

    local troop_unit = get_ety(actor_eid)
    if troop_unit == nil then return end

    if is_king_city(world_unit) and prop_unit.Lv == 2 then -- 如果是箭塔
        king_city.pass_troop_enter(world_unit, troop_unit._id)
    end

end

function triggers_leave_world_unit(x, y, actor_eid, scanner_eid, ...)
    local world_unit = get_ety(scanner_eid)
    if world_unit == nil then return end

    local prop_unit = resmng.prop_world_unit[world_unit.propid]
    if prop_unit == nil then return end

    local troop_unit = get_ety(actor_eid)
    if troop_unit == nil then return end

    if is_king_city(world_unit) and prop_unit.Lv == 2 then -- 如果是箭塔
        king_city.pass_troop_leave(world_unit,  troop_unit._id)
    end
end
-------------------------------------------------------------------
---------------------------------------------------------------------



triggers_funcs[TRIGGERS_EVENT_ID.TRIGGERS_ACK] = function(troop)
end

triggers_funcs[TRIGGERS_EVENT_ID.TRIGGERS_SLOW] = function(troop)
    troop.speed = troop.speed - 2;
    --c_update_actor(troop.eid, troop.speed)  --更新引擎速度
end




