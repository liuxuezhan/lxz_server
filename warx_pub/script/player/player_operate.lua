module("player_t")

-- 玩家存储结构
-- player.operate_activity = 
-- {
--  [activity_id] = 
--  {
--      [OPERATE_PLAYER_DATA.VERSION] = 0
--      [OPERATE_PLAYER_DATA.EXCHANGE] = {id=num, id=num, id=num}
--      [OPERATE_PLAYER_DATA.ACTION] = {id=num, id=num, id=num}
--      [OPERATE_PLAYER_DATA.ACTION_AWARD] = {id=1, id=1}
--  }
-- }

function get_operate_info(self, activity_id, type)
    if self.operate_activity[activity_id] == nil then
        return nil
    end
    local info = self.operate_activity[activity_id]
    if info[type] == nil then
        return nil
    end
    return info[type]
end

function set_operate_version(self, activity_id, version)
    if self.operate_activity[activity_id] == nil then
        self.operate_activity[activity_id] = {}
    end
    self.operate_activity[activity_id][OPERATE_PLAYER_DATA.VERSION] = version
end

function set_operate_first_flag(self, activity_id)
    if self.operate_activity[activity_id] == nil then
        self.operate_activity[activity_id] = {}
    end
    self.operate_activity[activity_id][OPERATE_PLAYER_DATA.FIRST_FLAG] = true
    self.operate_activity = self.operate_activity
end

function get_operate_first_flag(self, activity_id)
    if self.operate_activity[activity_id] == nil then
        return nil
    end
    if self.operate_activity[activity_id][OPERATE_PLAYER_DATA.FIRST_FLAG] == nil then
        return nil
    end
    return true
end

function set_operate_info(self, activity_id, type, key, value)
    if self.operate_activity[activity_id] == nil then
        self.operate_activity[activity_id] = {}
    end
    local info = self.operate_activity[activity_id]
    if info[type] == nil then
        info[type] = {}
    end

    local data = info[type]
    if data[key] == nil then
        data[key] = 0
    end
    data[key] = data[key] + value

    --活动计数标记赋值
    if info[OPERATE_PLAYER_DATA.VERSION] == nil then
        local activity = operate_activity.get_activity_by_id(activity_id)
        if activity ~= nil then
            info[OPERATE_PLAYER_DATA.VERSION] = activity.version
        end
    end

    self.operate_activity = self.operate_activity
end

function update_operate_info(self, activity_id, type, key, value)
    if self.operate_activity[activity_id] == nil then
        self.operate_activity[activity_id] = {}
    end
    local info = self.operate_activity[activity_id]
    if info[type] == nil then
        info[type] = {}
    end

    local data = info[type]
    data[key] = value

    --活动计数标记赋值
    if info[OPERATE_PLAYER_DATA.VERSION] == nil then
        local activity = operate_activity.get_activity_by_id(activity_id)
        if activity ~= nil then
            info[OPERATE_PLAYER_DATA.VERSION] = activity.version
        end
    end

    self.operate_activity = self.operate_activity
end

--rpc
function operate_activity_list(self)
    self:operate_check_all_version()
    operate_activity.packet_activity_list(self)
end

function operate_exchange(self, activity_id, exchange_id)
    operate_activity.exchage(self, activity_id, exchange_id)
end

function operate_single_get(self, activity_id)
    operate_activity.single_get(self, activity_id)
end

function operate_task_get(self, activity_id, task_id)
    operate_activity.task_get(self, activity_id, task_id)
end

function operate_on_day_pass(self)
    local clear_list = {}
    for id, info in pairs(self.operate_activity or {}) do
        local activity = operate_activity.get_activity_by_id(id)
        if activity == nil or activity.is_end == 1 then
            table.insert(clear_list, id)
        elseif nil ~= info[OPERATE_PLAYER_DATA.VERSION] then
            local prop = resmng.get_conf("prop_operate_activity", id)
            if prop.CirculationNum then
                self.operate_activity[id] = {}
                self.operate_activity[id][OPERATE_PLAYER_DATA.VERSION] = activity.version
            end
        end
    end

    for k, v in pairs(clear_list) do
        self.operate_activity[v] = nil
    end
    self.operate_activity = self.operate_activity
end

function operate_check_all_version(self)
    for id, info in pairs(self.operate_activity or {}) do
        local activity = operate_activity.get_activity_by_id(id)
        if activity ~= nil then
            if info[OPERATE_PLAYER_DATA.VERSION] ~= nil then
                if activity.version ~= info[OPERATE_PLAYER_DATA.VERSION] then
                    self.operate_activity[id] = {}
                    self.operate_activity[id][OPERATE_PLAYER_DATA.VERSION] = activity.version
                end
            end
        end
    end
end

function operate_check_version(self, activity)
    if activity == nil then
        return
    end
    local id = activity.activity_id
    local info = self.operate_activity[id]
    if info == nil then
        return
    end
    
    if info[OPERATE_PLAYER_DATA.VERSION] ~= nil then
        if activity.version ~= info[OPERATE_PLAYER_DATA.VERSION] then
            self.operate_activity[id] = {}
            self.operate_activity[id][OPERATE_PLAYER_DATA.VERSION] = activity.version
        end
    end
end

