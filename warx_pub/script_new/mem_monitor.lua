MONITOR_LEVEL = {
    DEBUG       = 1,    --调试
    LOG         = 2,    --日志
    WARNING     = 3,    --告警
}

MONITOR_TYPE = {
    TOTAL = 1,
    TROOP = 2,
    UNION = 3,
    PLY = 4,
    LOADDATA = 5,
    LUAOBJ = 6,
}

MONITOR_TYPE_LEVEL = {
    [MONITOR_TYPE.TOTAL] = MONITOR_LEVEL.LOG,
    [MONITOR_TYPE.TROOP] = MONITOR_LEVEL.DEBUG,
    [MONITOR_TYPE.UNION] = MONITOR_LEVEL.DEBUG,
    [MONITOR_TYPE.PLY] = MONITOR_LEVEL.DEBUG,
    [MONITOR_TYPE.LOADDATA] = MONITOR_LEVEL.DEBUG,
    [MONITOR_TYPE.LUAOBJ] = MONITOR_LEVEL.DEBUG,
}
function monitor_debug(string, ...)
    if cur_monitor_level <= MONITOR_LEVEL.DEBUG then
        MONITOR("[Monitor_debug]"..string, ...)
    end
end
function monitor_log(string, ...)
    if cur_monitor_level <= MONITOR_LEVEL.LOG then
        MONITOR("[Monitor_log]"..string, ...)
    end
end
function monitor_warning(string, ...)
    if cur_monitor_level <= MONITOR_LEVEL.WARNING then
        MONITOR("[Monitor_warning]"..string, ...)
    end
end

function monitor_get_engine_mem()
    --[[
    mheap -- 堆上分配的内存MB
    mengine -- 前引擎alloc出来的内存KB
    mlua -- 当前lua的内存KB
    mbuffer -- 当前网络buffer的内存KB
    mobj -- 引擎大地图对象的内存
    nbuffer -- 网络buffer数量
    --]]

    local m = {}
    if cur_monitor_level < MONITOR_LEVEL.WARNING then
        m.mheap, m.mengine, m.mlua, m.mbuffer, m.mworldobj, m.nbuffer = c_get_engine_mem() 
    end
    return m
end

function monitor_get_engine_obj_num()
    local m = {}
    if cur_monitor_level < MONITOR_LEVEL.WARNING then
        m.nply, m.nres, m.nmonster, m.npccity, m.kingcity, m.camp, m.monstercity, m.nlosttemple, m.nunionbuild, m.ntroop, m.neye = c_get_engine_obj_num()
    end
    return m
end

cur_monitor_level = 3
function monitor_init()
    cur_monitor_level = MONITOR_LEVEL.WARNING
end

function monitoring(type, ...)
    if MONITOR_TYPE_LEVEL[type] and MONITOR_TYPE_LEVEL[type] >= cur_monitor_level then
        monitor_func[type](...)
    end
end

monitor_peak_troop = 0

monitor_func = {}
monitor_func[MONITOR_TYPE.TOTAL] = function()
    local mem = monitor_get_engine_mem()
    local num = monitor_get_engine_obj_num()

    monitor_log("*********************")
    monitor_debug("[OBJ_MEM], mengine=%dKB, mlua=%dKB, mbuffer=%dKB, mworldobj=%dKB", mem.mengine, mem.mlua, mem.mbuffer, mem.mworldobj)
    monitor_log("[OBJ_MEM], mheap=%dMB, mengine=%dMB, mlua=%dMB, mbuffer=%dMB, mworldobj=%dMB, nbuffer=%d", 
        mem.mheap, math.ceil(mem.mengine/1024), math.ceil(mem.mlua/1024), math.ceil(mem.mbuffer/1024), math.ceil(mem.mworldobj/1024), mem.nbuffer)
    monitor_log("[OBJ_NUM], nply=%d, nres=%d, nmonster=%d, nnpccity=%d, nkingcity=%d, ncamp=%d, nmonstercity=%d, nlosttemple=%d, nunionbuild=%d, ntroop=%d, neye=%d", 
        num.nply, num.nres, num.nmonster, num.npccity, num.kingcity, num.camp, num.monstercity, num.nlosttemple, num.nunionbuild, num.ntroop, num.neye)
    local total_obj = 0
    for k, v in pairs(num) do
        if k ~= "neye" then
            total_obj = total_obj + v
        end
    end
    monitor_log("[WORLD_COUNT], engine total num=%d", total_obj)
    total_obj = get_table_valid_count(gEtys)
    monitor_log("[WORLD_COUNT], lua total num=%d", total_obj)
    monitor_log("*********************")
end
--部队监控
monitor_func[MONITOR_TYPE.TROOP] = function()
    monitor_peak_troop = monitor_peak_troop + 1
    monitor_debug("[PEAK_TROOP], npeak=%d", monitor_peak_troop)
end

--联盟监控
monitor_func[MONITOR_TYPE.UNION] = function(union_num)
    local mem = monitor_get_engine_mem()
    monitor_debug("[MEM_UNION], nluaunion=%dKB, mlua=%dKB", union_num, mem.mlua)
end

--玩家监控
monitor_func[MONITOR_TYPE.PLY] = function()
    local ply_num = get_table_valid_count(gPlys)
    local mem = monitor_get_engine_mem()
    monitor_debug("[MEM_PLY], nluaply=%d, mengine=%dKB, mlua=%dKB", ply_num, mem.mengine, mem.mlua)
end

--起服加载数据
monitor_func[MONITOR_TYPE.LOADDATA] = function(tips)
    local mem = monitor_get_engine_mem()
    monitor_debug("[MEM_LOADDATA], %s, mengine=%dMB, mlua=%dMB", tips, math.ceil(mem.mengine/1024), math.ceil(mem.mlua/1024))
end

--lua数据数量
monitor_func[MONITOR_TYPE.LUAOBJ] = function()
    --local mem = monitor_get_engine_mem()
    --monitor_debug("[MEM_LUAOBJ], mengine=%dMB, mlua=%dMB", math.ceil(mem.mengine/1024), math.ceil(mem.mlua/1024))

    local total_ply = 0
    local total_task = 0
    local total_hero = get_table_valid_count(heromng._heros)
    local total_build = 0
    local total_ache = 0
    local total_item = 0
    for _, ply in pairs(gPlys) do
        total_ply = total_ply + 1
        total_task = total_task + get_table_valid_count(ply._daily_task_list) + get_table_valid_count(ply._life_task_list)
        total_build = total_build + get_table_valid_count(ply._build)
        total_ache = total_ache + get_table_valid_count(ply._ache)
        total_item = total_item + get_table_valid_count(ply._item)
    end
    monitor_debug("[PLY_OBJ], nplynum=%d, ntask=%d, nhero=%d, nbuild=%d, nache=%d, nitem=%d",
        total_ply, total_task, total_hero, total_build, total_ache, total_item)

    local cur_troop = get_table_valid_count(troop_mng.troop_id_map)
    monitor_debug("[TROOP_OBJ], ncurnum=%d, npeaknum=%d", cur_troop, monitor_peak_troop)

    local total_union = get_table_valid_count(unionmng._us)
    monitor_debug("[UNION_OBJ], nunionnum=%d", total_union)
end
