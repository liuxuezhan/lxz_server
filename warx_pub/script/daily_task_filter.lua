module("daily_task_filter", package.seeall)

task = task or {}

function init_filter()
    for _, prop_tab in pairs(resmng.prop_task_daily) do
    	local a, s_lv, e_lv = unpack(prop_tab.PreCondition)
    	for i = s_lv, e_lv, 1 do
    		if task[i] == nil then
    			task[i] = {}
    		end
    		if task[i][prop_tab.GroupID] == nil then
    			task[i][prop_tab.GroupID] = {}
    			task[i][prop_tab.GroupID].total_weight = 0
    			task[i][prop_tab.GroupID].id_list = {}
    		end
    		local temp_group = task[i][prop_tab.GroupID]
    		temp_group.total_weight = temp_group.total_weight + prop_tab.CorolWeight
    		table.insert(temp_group.id_list, {prop_tab.ID, prop_tab.CorolWeight})
    	end
    end
end

function select_task(lv)
	local list = {}
	if task[lv] == nil then
		return nil
	end

	for group_id, group_data in pairs(task[lv]) do
		local p = math.random(group_data.total_weight)
		local tmp_p = 0
		for _, v in pairs(group_data.id_list) do
			tmp_p = tmp_p + v[2]
			if tmp_p >= p then
				list[group_id] = v[1]
				break
			end
		end
	end

	return list
end


function select_task_by_group_id(lv, group_id)
	local group_data = task[lv]
	if group_data == nil then
		return nil
	end
	local list = group_data[group_id]
	if list == nil then
		return nil
	end
	local p = math.random(list.total_weight)
	local tmp_p = 0
	for _, v in pairs(list.id_list) do
		tmp_p = tmp_p + v[2]
		if tmp_p >= p then
			return v[1]
		end
	end
	return nil
end

