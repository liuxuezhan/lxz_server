module("operate_activity", package.seeall)

--管理类
OpActivityData = OpActivityData or {}
local LoadDataTemp = {}
function load_operate_activity()
	local db = dbmng:getOne()
    local info = db.status:findOne({_id = "operate_activity"})
    for k, v in pairs(info or {}) do
        if k ~= "_id" then
            LoadDataTemp[k] = v
        end
    end
end

function save_operate_activity(data)
	if data == nil then
		return
	end
	local unit = {}
	unit.activity_id = data.activity_id
	unit.start_time = data.start_time
	unit.end_time = data.end_time
	unit.is_start = data.is_start
	unit.is_end = data.is_end
	unit.version = data.version

	gPendingSave.status["operate_activity"][unit.activity_id] = unit
end

function get_obj_by_type(type)
	if type == OPERATE_ACTIVITY_TYPE.NORMAL then
		return NormalActivity:New()

	elseif type == OPERATE_ACTIVITY_TYPE.LORD_RANK then
		return LordRankActivity:New()

	elseif type == OPERATE_ACTIVITY_TYPE.OCCUPY_RANK then
		return OccupyRankActivity:New()
	end
end

function init_activity()
	for k, v in pairs(resmng.prop_operate_activity) do
		if v.Open == 1 then
			--先判断数据库的数据有没有
			local unit = get_obj_by_type(v.Type)
			if LoadDataTemp[v.ID] == nil then
				unit:init(v)
				unit:init_action()
				unit:init_activity()
				OpActivityData[v.ID] = unit
				save_operate_activity(unit)
			end

			if LoadDataTemp[v.ID] ~= nil and LoadDataTemp[v.ID].is_end ~= 1 then
				local db_data = LoadDataTemp[v.ID]
				unit.activity_id = db_data.activity_id
				unit.start_time = db_data.start_time
				unit.end_time = db_data.end_time
				unit.is_start = db_data.is_start
				unit.is_end = db_data.is_end
				unit.version = db_data.version
				unit:init_action()
				unit:init_activity()
				OpActivityData[v.ID] = unit
			end
		end
	end
end

function heart_beat()
	for k, v in pairs(OpActivityData) do
		local prop_tab = resmng.get_conf("prop_operate_activity", v.activity_id)
		if prop_tab ~= nil and prop_tab.Open == 1 then
			if v:tick() == true then
				save_operate_activity(v)
			end
		end
	end
end

--operate_activity.process_operate_activity(OPERATE_ACTIVITY_ACTION.GACHA)
--operate_activity.process_operate_activity(OPERATE_ACTIVITY_ACTION.BLACK_MARKET)
--operate_activity.process_operate_activity(OPERATE_ACTIVITY_ACTION.RESOURCE_MARKET)
--operate_activity.process_operate_activity(OPERATE_ACTIVITY_ACTION.KILL_SOLDIER)
--operate_activity.process_operate_activity(OPERATE_ACTIVITY_ACTION.OCCUPY_CITY)

function get_activity_by_id(activity_id)
	return OpActivityData[activity_id]
end

function process_operate_activity(player, action, ...)
	for k, v in pairs(OpActivityData) do
		local prop_tab = resmng.get_conf("prop_operate_activity", v.activity_id)
		if prop_tab.Open == 1 then
			v:process_action(player, action, ...)
		end
	end
end

function exchage(player, activity_id, exchange_id)
	if OpActivityData[activity_id] == nil then
		return
	end
	local prop_tab = resmng.get_conf("prop_operate_activity", activity_id)
	if prop_tab ~= nil and prop_tab.Open == 1 then
		OpActivityData[activity_id]:exchage(player, exchange_id)
	end
end

function single_get(player, activity_id)
	if OpActivityData[activity_id] == nil then
		return
	end
	local prop_tab = resmng.get_conf("prop_operate_activity", activity_id)
	if prop_tab ~= nil and prop_tab.Open == 1 then
		OpActivityData[activity_id]:single_get(player)
	end
end

function packet_activity_list(player)
	local msg = {}
	for k, v in pairs(OpActivityData or {}) do
		local prop_tab = resmng.get_conf("prop_operate_activity", v.activity_id)
		if prop_tab.Open == 1 and v.is_end == 0 then
			local unit = {}
			unit.id = v.activity_id
			unit.start_time = v.start_time
			unit.end_time = v.end_time
			table.insert(msg, unit)
		end
	end
	Rpc:operate_activity_list_resp(player, msg);
end

function task_get(player, activity_id, task_id)
	if OpActivityData[activity_id] == nil then
		return
	end
	local prop_tab = resmng.get_conf("prop_operate_activity", activity_id)
	if prop_tab ~= nil and prop_tab.Open == 1 then
		OpActivityData[activity_id]:task_get(player, task_id)
	end
end

--gm测试
function gm()
	for k, v in pairs(OpActivityData or {}) do
		v:handout_rank_award() --排行榜邮件发奖
	end
	OpActivityData[4]:end_activity()
end