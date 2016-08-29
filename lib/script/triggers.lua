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
    print( "arrive", actor_eid )
    local troop = get_ety(actor_eid)
    if troop ~= nil then
        if x == troop.dx and y == troop.dy then
            troop.curx = troop.dx
            troop.cury = troop.dy
            troop.tmCur = gTime
            rem_ety_troop(troop)
            troop_mng.trigger_event(troop)
        else
            print("arrive", x, y, troop.dx, troop.dy)
        end
    end
end

function rem_ety_troop(troop)  -- 删除建筑上，出发和目标部队ID
    local owner = get_ety(troop.owner_eid)
    local target = get_ety(troop.target_eid)

    if is_npc_city(owner) or is_lost_temple(owner) or is_king_city(owner) or is_monster_city(owner) or is_monster(owner) then
        monster_city.rem_leave_troop(owner, troop._id)
        owner.leave_troop_tag = nil
    end

    if is_npc_city(target) or is_lost_temple(target) or is_king_city(target) or is_monster_city(target) or is_monster(target) then
        monster_city.rem_atk_troop(target, troop._id)
        target.atk_troop_tag = nil
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
    print(" triggers, enter", scanner_eid, x, y )
    local troop_unit = get_ety(actor_eid)
    if troop_unit == nil then return end
    if not is_troop( troop_unit ) then return end

    local world_unit = get_ety(scanner_eid)
    if world_unit == nil then 
        if scanner_eid == -1 then
            troop_unit:enter_black_zone()
        end
        return
    end

    local prop_unit = resmng.prop_world_unit[world_unit.propid]
    if prop_unit == nil then return end

    if is_king_city(world_unit) and prop_unit.Lv == 2 then -- 如果是箭塔
        king_city.pass_troop_enter(world_unit, troop_unit._id)
    end
end

function triggers_leave_world_unit(x, y, actor_eid, scanner_eid, ...)
    print(" triggers, leave", scanner_eid, x, y )
    local troop_unit = get_ety(actor_eid)
    if troop_unit == nil then return end

    local world_unit = get_ety(scanner_eid)
    if world_unit == nil then 
        if scanner_eid == -1 then
            troop_unit:leave_black_zone()
        end
        return 
    end

    local prop_unit = resmng.prop_world_unit[world_unit.propid]
    if prop_unit == nil then return end

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



