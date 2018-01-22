function spin_zones(spin_count)
    local spin_info =
    {
        {-1, -1, 1, 0},
        {1, -1, 0, 1},
        {1, 1, -1, 0},
        {-1, 1, 0, -1},
    }
    local function spin(layer)
        for k, v in ipairs(spin_info) do
            local start_x = layer * v[1]
            local start_y = layer * v[2]
            local count = layer * 2
            for i = 1, count do
                coroutine.yield(start_x + v[3] * i, start_y + v[4] * i)
            end
        end
    end

    local function _zones()
        coroutine.yield(0, 0)
        for i = 1, spin_count do
            spin(i)
        end
    end

    return coroutine.wrap(_zones)
end

function get_monster_type(mode)
    if mode <= 30 then --普通
        return 1
    elseif mode > 30 and mode <= 40 then --精英
        return 2
    elseif mode > 40 and mode <= 50 then --首领
        return 3
    elseif mode > 50 and mode <= 100 then --超级首领
        return 4
    else -- 任务
        return 5
    end
end

function cross_zones(start_x, start_y, end_x, end_y)
    local function _zones()
        local diff_x = end_x - start_x
        local diff_y = end_y - start_y
        local step = math.abs(diff_x) >= math.abs(diff_y) and math.abs(diff_x) or math.abs(diff_y)
        local gradient_x = diff_x / step
        local gradient_y = diff_y / step
        local cur_x = start_x + 0.5
        local cur_y = start_y + 0.5
        local last_x = cur_x
        local last_y = cur_y
        for i = 1, step do
            cur_x = cur_x + gradient_x
            cur_y = cur_y + gradient_y
            if math.floor(last_x) ~= math.floor(cur_x) or math.floor(last_y) ~= math.floor(cur_y) then
                last_x = cur_x
                last_y = cur_y
                coroutine.yield(math.floor(last_x), math.floor(last_y))
            end
        end
    end
    return coroutine.wrap(_zones)
end

local task_prop_map = {
    [TASK_TYPE.TASK_TYPE_TRUNK] = resmng.prop_task_detail,
    [TASK_TYPE.TASK_TYPE_BRANCH] = resmng.prop_task_detail,
    [TASK_TYPE.TASK_TYPE_DAILY] = resmng.prop_task_daily,
    [TASK_TYPE.TASK_TYPE_TARGET] = resmng.prop_task_detail,
    [TASK_TYPE.TASK_TYPE_HEROROAD] = resmng.prop_task_detail,
}

function getTaskProp(task)
    return task_prop_map[task.task_type][task.task_id]
end

function is_sys_name(name)
    local len = string.len(name)
    local pat = string.match(name, "K%d+a%d+")
    return (pat and string.len(pat) == len)
end

