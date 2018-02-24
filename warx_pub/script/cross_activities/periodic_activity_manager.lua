module("periodic_activity_manager", package.seeall)

m_main_activities = m_main_activities or {}

function init()
end

function uninit()
end

function load_data()
    if not is_center_server() then
        return
    end

    local db = dbmng:getOne()
    info = db.periodic_main_activity:find({})
    while info:hasNext() do
        local main_activity = periodic_main_activity.wrap(info:next())
        m_main_activities[main_activity.mode] = main_activity
        main_activity:init()
        main_activity:load_data()
    end

    for k, v in pairs(PERIODIC_ACTIVITY) do
        if not m_main_activities[v] then
            _create_main_activity(v)
        end
    end
end

function _create_main_activity(mode)
    local main_activity = {}
    main_activity._id = mode
    main_activity.mode = mode

    main_activity = periodic_main_activity.new(main_activity)
    m_main_activities[main_activity.mode] = main_activity
    main_activity:init()

    WARN("[PeriodicActivity] create main activity %d", main_activity.mode)
end

function init_data()
    if not is_center_server() then
        return
    end

    for k, v in pairs(m_main_activities) do
        v:init_data()
    end
end

function clear_player_rank(gid, info)
    for k, v in pairs(PERIODIC_ACTIVITY) do
        local main_activity = m_main_activities[v]
        if main_activity then
            main_activity:clear_player_rank(gid, info[v])
        end
    end
end

function sync_all_data()
    if not is_center_server() then
        return
    end

    for k, v in pairs(m_main_activities) do
        v:sync_all_data()
    end
end

function refresh_activity(mode, server_index)
    if not m_main_activities[mode] then
        return
    end
    m_main_activities[mode]:refresh_activity(server_index)
end

function on_day_pass()
    if not is_center_server() then
        return
    end

    if m_main_activities[PERIODIC_ACTIVITY.DAILY] then
        m_main_activities[PERIODIC_ACTIVITY.DAILY]:reset_all_activities()
    end
end

function on_bihour_pass()
    if not is_center_server() then
        return
    end

    if m_main_activities[PERIODIC_ACTIVITY.BIHOURLY] then
        m_main_activities[PERIODIC_ACTIVITY.BIHOURLY]:reset_all_activities()
    end
end

function get_main_activity(mode)
    return m_main_activities[mode]
end

function sync_activity_data(gid, mode)
    local main_activity = get_main_activity(mode)
    if main_activity then
        main_activity:sync_activity_data(gid)
    end
end

function upload_score(mode, gid, pid, rank_lv, score, time)
    local main_activity = get_main_activity(mode)
    if main_activity then
        main_activity:upload_score(gid, pid, rank_lv, score, time)
    end
end

function get_my_rank(mode, gid, pid, rank_lv)
    local main_activity = get_main_activity(mode)
    if main_activity then
        return main_activity:get_my_rank(gid, pid, rank_lv)
    end
    return 0, 0
end

