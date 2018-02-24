module("periodic_activity", package.seeall)

module_class("periodic_activity", {
    _id = 0,
    mode = 0,
    index = 0,              -- 活动服务器分组索引（服务器列表） -> prop_daily_activity_cross_group
    group_id = 0,           -- 活动分组ID（每日刷新时更新）   -> prop_daily_activity_group
    sn = 0,
    server_list = {},
    start_time = 0,
    end_time = 0,
})

function init(self)
end

function uninit(self)
end

function get_config(self, cfg_type)
    return PERIODIC_ACTIVITY_CFG[self.mode][cfg_type]
end

function get_rank_id(self, rank_lv)
    return custom_rank_mng.get_rank_id(self:get_config("RANK_CLASS"), self.index, rank_lv)
end

function create_ranks(self)
    for k, v in pairs(self:get_config("RANK") or {}) do
        local rank_id = self:get_rank_id(k)
        custom_rank_mng.create_rank(rank_id, v.Skeys, v.Num, self:get_config("RANK_CLASS"), CUSTOM_RANK_MODE.PLY, "cross_rank_c")
    end
end

function send_rank_award(self)
    local prop = resmng[self:get_config("PROP_GROUP")][self.group_id]
    if nil == prop then
        return
    end
    local rank_class = self:get_config("RANK_CLASS")
    local players = {}
    for rank_lv, _ in pairs(self:get_config("RANK") or {}) do
        local rank_id = self:get_rank_id(rank_lv)
        local min = 1
        local prop = resmng[self:get_config("PROP_AWARD")][rank_lv * 1000 + self.group_id]
        for index, max in pairs(self:get_config("RANK_SECTION") or {}) do
            local award_key = "RankAward" .. index
            local pids = custom_rank_mng.get_range(rank_id, min, max)
            for idx, pid in pairs(pids or {}) do
                local rank_pos = custom_rank_mng.get_rank(rank_id, pid)
                local rank_score = custom_rank_mng.get_score(rank_id, pid)

                player_rank_award.add_award(pid, rank_class, rank_lv * 1000 + self.group_id, self:get_config("RANK_MAIL_ID"), prop[award_key], {rank_score, rank_pos})
                players[pid] = 1
            end
            min = max + 1
        end
    end
    if _G.GateSid then
        local pids = {}
        for k, v in pairs(players) do
            table.insert(pids, k)
        end
        for k, v in pairs(self.server_list) do
            Rpc:callAgent(v, "notify_cross_award", pids)
        end
    end
end

function clear_ranks(self)
    for k, v in pairs(self:get_config("RANK") or {}) do
        local rank_id = self:get_rank_id(k)
        custom_rank_mng.delete_rank(rank_id)
    end
end

function upload_score(self, pid, rank_lv, score, time)
    local rank_id = self:get_rank_id(rank_lv)
    if score <= 0 then
        custom_rank_mng.rem_data(rank_id, pid)
    else
        custom_rank_mng.add_data(rank_id, pid, {score, time}, true)
    end
end

function get_my_rank(self, pid, rank_lv)
    local rank_id = self:get_rank_id(rank_lv)
    local rank_pos = custom_rank_mng.get_rank(rank_id, pid)
    if rank_pos <= 1 then
        return rank_pos, 0
    end
    local info = custom_rank_mng.get_range_with_score(rank_id, rank_pos - 1, rank_pos)
    local score_with_prev = 0
    if info then
        score_with_prev = info[2] - info[4]
    end
    return rank_pos, score_with_prev
end

function clear_rank(self, pid, rank_lv)
    local rank_id = self:get_rank_id(rank_lv)
    return custom_rank_mng.rem_data(rank_id, pid)
end

function sync_data_to_server(self, gs_id)
    if _G.GateSid then
        INFO("[PeriodicActivity|%d|%d] Sync data to server %d", self._id, self.mode, gs_id)
        Rpc:callAgent(gs_id, "periodic_activity_sync_data", self.mode, self.group_id, self.sn, self.start_time, self.end_time)
    end
end

function get_act_id(self)
    return ActivitySelector[self.mode](self)
end

local function _random_selector(activity)
    local pool = {}
    local total_ratio = 0
    for _, v in pairs(resmng[activity:get_config("PROP_GROUP")]) do
        if activity.group_id ~= v.ID then
            table.insert(pool, {v.ID, v.Weight})
            total_ratio = total_ratio + v.Weight
        end
    end
    local ratio = math.random(total_ratio)
    for _, v in ipairs(pool) do
        if v[2] >= ratio then
            return v[1]
        else
            ratio = ratio - v[2]
        end
    end
    return pool[1][1]
end

local function _sequence_selector(activity)
    local props = resmng[activity:get_config("PROP_GROUP")]
    local count = #props
    return (activity.group_id % count) + 1
end

ActivitySelector = {
    [PERIODIC_ACTIVITY.DAILY] = _random_selector,
    [PERIODIC_ACTIVITY.BIHOURLY] = _random_selector,
}

