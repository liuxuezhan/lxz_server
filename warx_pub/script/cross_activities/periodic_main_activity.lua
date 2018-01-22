module("periodic_main_activity", package.seeall)

module_class("periodic_main_activity", {
    mode = 0,
    sn = 0, 
    start_time = 0, 
    end_time = 0,
    extra = {},
})

function init(self)
    self.m_activities = {}
    self.m_gid_map = {}
end

function uninit(self)
end

function get_config(self, cfg_type)
    return PERIODIC_ACTIVITY_CFG[self.mode][cfg_type]
end

function load_data(self)
    local db = dbmng:getOne()
    local info = db.periodic_activity:find({mode = self.mode})
    while info:hasNext() do
        local activity = periodic_activity.wrap(info:next())
        self.m_activities[activity._id] = activity
    end
end

function init_data(self)
    if 0 == self.end_time then
        WARN("[PeriodicActivity] reset all activity because end_time is zero")
        self:reset_all_activities()
    else
        for k, v in pairs(self.m_activities) do
            for _, gid in pairs(v.server_list) do
                if self.m_gid_map[gid] then
                    WARN("[PeriodicActivity|MainActivity|%d] Server %d is alread exist in activity %d", self.mode, gid, self.m_gid_map[gid])
                end
                self.m_gid_map[gid] = k
            end
        end
    end
    PERIODIC_TIMER[self.mode](self)
end

PERIODIC_TIMER = {}
PERIODIC_TIMER[PERIODIC_ACTIVITY.DAILY] = function(self) end

PERIODIC_TIMER[PERIODIC_ACTIVITY.BIHOURLY] = function(self)
    if nil ~= self.extra.timer_id and 0 ~= self.extra.timer_id then
        local node = timer.get(self.extra.timer_id) 
        if node then
            WARN("[PeriodicActivity|MainActivity|%d] Main activity has timer %d", self.mode, self.extra.timer_id)
            return
        end
        WARN("[PeriodicActivity|MainActivity|%d] Timer %d isn't exist, ready to recreate it.", self.mode, self.extra.timer_id)
    end
    local bihour_seconds = SECONDS_ONE_HOUR * 2
    local next_seconds = bihour_seconds - math.floor(gTime % bihour_seconds)
    self.extra.timer_id = timer.cycle("periodic_bihourly_activity", next_seconds, bihour_seconds)
    self.extra = self.extra
    WARN("[PeriodicActivity|MainActivity|%d] Main activity create timer %d", self.mode, self.extra.timer_id)
end

function sync_all_data(self)
    for k, v in pairs(self.m_activities) do
        for _, gid in pairs(v.server_list) do
            v:sync_data_to_server(gid)
        end
    end
end

function refresh_activity(self, index)
    local prop = resmng[self:get_config("PROP_CROSS")][index]
    if nil == prop then
        return
    end
    local activity = self:get_activity_by_index(index)
    if nil ~= activity then
        activity:send_rank_award()
        activity:clear_ranks()
        for _, gid in pairs(activity.server_list) do
            Rpc:callAgent(gid, "periodic_activity_reset_player_data", self.mode)
        end
        self:_reset_activity(activity, prop)
    else
        self:_create_activity(prop)
    end
end

NEXT_ROUND_TIME = {}
NEXT_ROUND_TIME[PERIODIC_ACTIVITY.DAILY] = function(duration)
    return get_next_day_stamp(gTime, 0)
end

NEXT_ROUND_TIME[PERIODIC_ACTIVITY.BIHOURLY] = function(duration)
    return get_next_round_stamp(gTime, duration, 0)
end

function reset_all_activities(self)
    local duration = self:get_config("DURATION")
    self.sn = self.sn + 1
    self.start_time = NEXT_ROUND_TIME[self.mode](duration)
    self.end_time = self.start_time + duration
    WARN("[PeriodicActivity|MainActivity|%d] reset all activity with %d|%d|%d", self.mode, self.sn, self.start_time, self.end_time)

    local props = resmng[self:get_config("PROP_CROSS")]
    local need_create_activites = {}
    for id, prop in pairs(props) do
        need_create_activites[prop.ID] = id
    end
    for id, activity in pairs(self.m_activities) do
        need_create_activites[activity.index] = nil
        activity:send_rank_award()
        activity:clear_ranks()
        if props[activity.index] then
            self:_reset_activity(activity, props[activity.index])
        else
            activity:clr()
            self.m_activities[id] = nil
        end
    end
    for id, v in pairs(need_create_activites) do
        self:_create_activity(props[id])
    end
end

function _create_activity(self, prop)
    local activity = {}
    activity._id = self.mode * 1000 + prop.ID
    activity.mode = self.mode
    activity.index = prop.ID

    activity = periodic_activity.new(activity)
    self.m_activities[activity._id] = activity
    WARN("[PeriodicActivity|MainActivity|%d] create activity %d", self.mode, activity._id)
    self:_reset_activity(activity, prop)
end

function _reset_activity(self, activity, prop)
    for k, v in pairs(activity.server_list or {}) do
        self.m_gid_map[v] = nil
    end

    activity.group_id = activity:get_act_id()
    activity.sn = self.sn
    activity.server_list = copyTab(prop.Group)
    activity.start_time = self.start_time
    activity.end_time = self.end_time
    WARN("[PeriodicActivity|MainActivity|%d] reset activity %d with group %d", self.mode, activity._id, activity.group_id)

    -- create rank
    activity:create_ranks()
    -- sync activity info to game
    for k, v in pairs(activity.server_list) do
        activity:sync_data_to_server(v)
        self.m_gid_map[v] = activity._id
    end
end

function get_activity_by_gid(self, gid)
    local activity_id = self.m_gid_map[gid]
    if nil == activity_id then
        return
    end
    return self.m_activities[activity_id]
end

function get_activity_by_index(self, server_index)
    for k, v in pairs(self.m_activities) do
        if v.index == server_index then
            return v
        end
    end
end

function sync_activity_data(self, gid)
    local activity = self:get_activity_by_gid(gid)
    if nil == activity then
        WARN("[PeriodicActivity|MainActivity|%d] Server %d has no activity when sync activity data", self.mode, gid)
        return
    end
    activity:sync_data_to_server(gid)
end

function upload_score(self, gid, pid, rank_lv, score, time)
    local activity = self:get_activity_by_gid(gid)
    if nil == activity then
        WARN("[PeriodicActivity|MainActivity|%d] Server %d has no activity when upload score %d|%d", self.mode, gid, pid)
        return
    end
    activity:upload_score(pid, rank_lv, score, time)
end

function get_my_rank(self, gid, pid, rank_lv)
    local activity = self:get_activity_by_gid(gid)
    if nil == activity then
        WARN("[PeriodicActivity|MainActivity|%d] Server %d has no activity when get player rank|%d", self.mode, gid, pid)
        return 0
    end
    return activity:get_my_rank(pid, rank_lv)
end

