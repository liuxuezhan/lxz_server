module("pay_mall", package.seeall)

local group = group or {}
local refresh_time = refresh_time or 0

function get_enable_group()
    if gTime  > refresh_time then
        refresh_time = gTime + 3600
        gen_enable_group()
    end
    return group
end

function gen_enable_group()
    for k, v in pairs(resmng.prop_buy_group or {}) do
        if v.FrontReq == 0 then
            local time, num, is_cyclic = get_group_time(v)
            local start_time = tab_to_timestamp(v.StartTime or {})
            local left = gTime - start_time
            if left > time then
                if is_cyclic then
                    local idx, end_time = get_group_idx(left % time, k)

                    if end_time < refresh_time then
                        refresh_time = end_time
                    end
                    group[v.Group] = {idx = idx, end_time = end_time }
                end
            elseif left < time and left > 0 then
                local idx,  end_time = get_group_idx(left, k)

                if end_time < refresh_time then
                    refresh_time = end_time
                end

                local prop = resmng.prop_buy_group[idx]
                group[v.Group] = {idx = idx, end_time = end_time }
            elseif left < 0 then
                if start_time < refresh_time then
                    refresh_time = start_time
                end
            end
        end
    end
end

function get_group_idx(left, idx)
    local prop = resmng.prop_buy_group[idx]
    if left < prop.Lasts then
        return idx, gTime + prop.Lasts - left
    end
    left = left - prop.Lasts
    if get_table_valid_count(prop.NextListID or {}) > 0 then
        return get_group_idx(left, prop.NextListID[1])
    end
end

function get_group_time(prop)  --计算每组的循环时间和循环数量
    local last_time = prop.Lasts
    local num = 1
    local is_cyclic = true

    local next_time = 0
    local next_num = 0
    local next_cyclic = true

    if get_table_valid_count(prop.NextListID or {}) > 0 then
        local next_prop = resmng.prop_buy_group[prop.NextListID[1]]
        if next_prop then
            if next_prop.FrontReq ~= 0 then
                next_time, next_num, next_cyclic = get_group_time(next_prop)
            end
        end
    else
        is_cyclic = false
    end
    return last_time + next_time, num + next_num, is_cyclic and next_cyclic
end
