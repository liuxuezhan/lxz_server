-- 使用说明：
-- 1.perfmon模块默认是在服务器的debug模式下使用的，用于性能监测和调优的模块
-- 2.使用perfmon.start(module_name, key)作为计时的开始，对应的stop用于计时的结束
-- 3.一对匹配的start和stop必须含有相同的module_name和key，不关心key时，key可以传0
-- 4.确保start和stop正确匹配是调用者需要注意的，stop要覆盖运行分支
-- 5.常用命令：perfmon.output(module_name)
--   打印统计结果，不传递参数表示打印全部监测数据（当监测数据较多时不建议使用）
--   传入module_name可以只查看该module_name以及子module_name的统计数据
-- 6.常用命令：perfmon.clear(module_name)
--   清除掉统计数据，参数意义同perfmon.output。
--   为什么没有删除掉node，是因为有可能是在某次start和stop之间调用的
-- 7.关于监测代码段中抛出了异常，或者出现了start和stop不匹配的情况
--   会导致该协程的本次调用栈之前的监测（从根节点开始）结果弃用，下一次start从协程根节点记录
-- 8.对于递归的支持：递归只会记录最外层的运行时间
-- 9.客户端使用规则：替换get_ms_time的实现，替换need_record的实现
--   如果是多协程的，并且协程并不是复用的，那么需要改写init并在初始化时调用
--   建议在xpcall的处理函数里面加入perfmon.on_exception()的调用
module("perfmon", package.seeall)

_show_data = _show_data or {sons={}, dirty=false} -- 用于存放记录的数据
_co_data = _co_data or {}   -- 用于分协程存储每个协程自己的记录数据
_dead_co_data = _dead_co_data or {sons={}} -- 保存已经死掉的协程的记录数据, 防止_co_data表过大
_switch = _switch or true   -- 是否生效的总开关

local get_ms_time = c_msec

function init()
    timer._funs["dead_co_check_func"] = dead_co_check_func
    timer.cycle("dead_co_check_func", 60*10, 60*10)
end

function dead_co_check_func()
    for k, co_data in pairs(_co_data) do
        if co_data.last_visit_time < gTime - 600 then
            for _, co_root_node in pairs(co_data.data) do
                local dead_root_node, is_new = _get_next_node_anyway(_dead_co_data, co_root_node.name)
                if is_new then
                    _dead_co_data.sons[dead_root_node.name] = dead_root_node
                end
                _merge_one_node(dead_root_node, co_root_node)
            end
            _co_data[k] = nil
        end
    end
    return 1
end

function need_record()
    return _switch-- and not config.Release
end

function start(module_name, key)
    if not need_record() then return end

    -- 先判断是否进入了一个递归中
    -- 进入递归的判断条件：当前递归深度>0或者模块名已经存在于调用栈中
    local up_node = _get_co_curr_node()
    if up_node and (up_node.loop_deep > 0 or _is_self_or_son_of(up_node, module_name)) then
        --print(string.format("zhoujy_log: perfmon_start_loop module_name = %s, key = %s", module_name, key))
        up_node.loop_deep = up_node.loop_deep + 1
        return
    end

    local node = _get_co_next_node_anyway(module_name)
    node.key_temp = tostring(key)
    node.start_tick_temp = get_ms_time()

    _show_data.dirty = true

    -- 更新最新访问时间，用于检测死掉的co
    local curr_co_data = _get_co_data()
    curr_co_data.last_visit_time = gTime
end

function stop(module_name, key)
    if not need_record() then return end

    local node = _get_co_curr_node()
    if node == nil then
        -- 当手动调用了xpcall，处理过异常后，外层的stop会调用到这里
        -- Act-X程序可参看test.zhoujy_perfmon的test_func2函数，会在perfmon_test2的end时触发
        --ERROR("node should not be nil, module_name:%s, key=%s", module_name, tostring(key))
        return
    end
    if node.loop_deep > 0 then
        --print(string.format("zhoujy_log: perfmon_stop_loop module_name = %s, key = %s", module_name, key))
        node.loop_deep = node.loop_deep - 1
        return
    end
    if node.name ~= module_name or node.key_temp ~= tostring(key) then
        local err_str = string.format(
            "zhoujy_error: perfmon start and stop not match. start_key[%s-%s], stop_key[%s-%s]",
            node.name, node.key_temp, module_name, tostring(key))
        _on_error(err_str)
        return
    end

    local cost_time = get_ms_time() - node.start_tick_temp
    if cost_time < 0 then cost_time = 0 end

    if cost_time < node.min.time then
        node.min.key = node.key_temp
        node.min.time = cost_time
    end
    if cost_time > node.max.time then
        node.max.key = node.key_temp
        node.max.time = cost_time
    end

    node.total_count = node.total_count + 1
    node.total_time = node.total_time + cost_time
    node.avg_time = node.total_time / node.total_count

    _pop_to_parent()
end

function output(module_name)
    if _show_data.dirty then
        _merge_data()
    end

    _output_one_node(_show_data, module_name)

    _print_and_log("--------------------perfmon output done!")
end

function output_in_order(module_name, order_mode)
    if _show_data.dirty then
        _merge_data()
    end

    local node = _find_node_by_name(_show_data, module_name)
    if node then
        _output_one_node_in_order(node, order_mode)
    else
        _print_and_log(string.format("--------------------can not find module[%s]!", module_name))
        return
    end

    _print_and_log("--------------------perfmon output done!")
end

function clear(module_name)
    for _, co_data in pairs(_co_data) do
        for _, co_root_node in pairs(co_data.data) do
            _clear_one_node(co_root_node, module_name)
        end
    end
    for _, co_root_node in pairs(_dead_co_data.sons) do
        _clear_one_node(co_root_node, module_name)
    end

    _print_and_log("--------------------perfmon clear done!")
end

-- 需要在xpcall的异常处理函数里面调用此接口， 默认只在服务器端的STACK函数里面调用了
-- 不调用的后果：递归函数中抛异常不能正确处理，调用栈不平衡，不会进行时间记录
-- 调用的好处：异常导致的时间无法采集范围压缩到最小
function on_exception()
    _on_error("perfmon handle exception")
end

------------------------------------------------------------------------
-- 有2种情况导致记录栈不匹配:
-- 1.编写的start-stop调用不匹配，比如没有覆盖所有return分支，传递的module_name和key不匹配
-- 2.在start-stop期间lua运行出错，抛出了异常
-- 处理的方法：单次运行作废，下一次start从根节点记录，保证栈平衡
function _on_error(err_str)
    ERROR(err_str)
    local curr_co_data = _get_co_data()
    if curr_co_data.node then
        -- 如果是递归的时候抛了异常，由于递归不会导致栈深入，所以只需要置当前层的loop_deep
        curr_co_data.node.loop_deep = 0
    end
    curr_co_data.node = nil
end

function _get_co_data()
    local co_key = tostring(coroutine.running())
    if not _co_data[co_key] then
        _co_data[co_key] = {
            data = {},
            node = nil,
            last_visit_time = gTime,
        }
    end
    return _co_data[co_key]
end

function _gen_path_name(up_node, module_name)
    if up_node == nil or up_node.path == nil then return module_name end
    return up_node.path.."|"..module_name
end

function _new_node(up_node, module_name)
    local new_node = {
        name = module_name,
        path = _gen_path_name(up_node, module_name),
        min = {key=nil, time=math.huge},
        max = {key=nil, time=-1},
        avg_time = 0,
        total_count = 0,
        total_time = 0,
        loop_deep = 0,  -- 递归深度
        
        key_temp = "",
        start_tick_temp = 0,

        parent = up_node,
        sons = {}
    }
    return new_node
end

function _get_next_node_anyway(up_node, module_name)
    if up_node == nil or up_node.sons[module_name] == nil then
        local new_node = _new_node(up_node, module_name)
        return new_node, true
    else
        return up_node.sons[module_name], false
    end
end

function _get_co_next_node_anyway(module_name)
    local curr_co_data = _get_co_data()
    if curr_co_data.node == nil then
        -- 第一层
        if curr_co_data.data[module_name] == nil then
            local new_node = _new_node(nil, module_name)
            curr_co_data.data[module_name] = new_node
        end
        curr_co_data.node = curr_co_data.data[module_name]
    else
        local next_node, is_new = _get_next_node_anyway(curr_co_data.node, module_name)
        if is_new then
            curr_co_data.node.sons[module_name] = next_node
        end
        curr_co_data.node = next_node
    end

    return curr_co_data.node
end

function _get_co_curr_node()
    local curr_co_data = _get_co_data()
    return curr_co_data.node
end

function _pop_to_parent()
    local curr_co_data = _get_co_data()
    if curr_co_data.node then
        curr_co_data.node = curr_co_data.node.parent
    else
        ERROR("zhoujy_error: node should not be nil, maybe start-stop not match")
    end
end

function _merge_one_node(show_node, co_node)
    -- merge本层数据
    if show_node.min.time > co_node.min.time then
        show_node.min.key = co_node.min.key
        show_node.min.time = co_node.min.time
    end
    if show_node.max.time < co_node.max.time then
        show_node.max.key = co_node.max.key
        show_node.max.time = co_node.max.time
    end
    show_node.total_count = show_node.total_count + co_node.total_count
    show_node.total_time = show_node.total_time + co_node.total_time
    if show_node.total_count ~= 0 then
        show_node.avg_time = show_node.total_time / show_node.total_count
    end
    -- 递归merge
    for _, co_son_node in pairs(co_node.sons) do
        local show_son_node, is_new = _get_next_node_anyway(show_node, co_son_node.name)
        if is_new then
            show_node.sons[show_son_node.name] = show_son_node
        end
        _merge_one_node(show_son_node, co_son_node)
    end
end

-- 刷新显示数据
function _merge_data()
    _show_data = {sons={}, dirty=false}
    for _, co_data in pairs(_co_data) do
        for _, co_root_node in pairs(co_data.data) do
            local show_root_node, is_new = _get_next_node_anyway(_show_data, co_root_node.name)
            if is_new then
                _show_data.sons[show_root_node.name] = show_root_node
            end
            _merge_one_node(show_root_node, co_root_node)
        end
    end
    for _, co_root_node in pairs(_dead_co_data.sons) do
        local show_root_node, is_new = _get_next_node_anyway(_show_data, co_root_node.name)
        if is_new then
            _show_data.sons[show_root_node.name] = show_root_node
        end
        _merge_one_node(show_root_node, co_root_node)
    end
end

-- 递归查找某个名字的node
function _find_node_by_name(node, module_name)
    if node.name and node.name == module_name then
        return node
    end

    for k, v in pairs(node.sons) do
        if v.name and v.name == module_name then
            return v
        end
    end

    for k, v in pairs(node.sons) do
        if _find_node_by_name(v, module_name) then
            return v
        end
    end

    return nil
end

function _print_log_str(node)
    local path_str = string.format("[path:%s]", node.path)
    local count_str = string.format("[at:%.1f, tc:%d, tt:%.1f][max_t:%.1f, max_k:%s, min_t:%.1f, min_k:%s]",
        node.avg_time, node.total_count, node.total_time,
        node.max.time, node.max.key, node.min.time, node.min.key)
    local split_str = "-------------------------------------------------------------------"

    _print_and_log(path_str)
    _print_and_log(count_str)
    _print_and_log(split_str)
end

function _output_one_node(node, module_name)
    if node.name then
        if not module_name or _is_self_or_son_of(node, module_name) then
            _print_log_str(node)
        end
    end

    for k, v in pairs(node.sons) do
        _output_one_node(v, module_name)
    end
end

-- 只输出一层内的，按照时间来进行排序
-- order_mode: 1-avg_time; 2-max_time; 3-total_count
_output_sort_func = {}
_output_sort_func[1] = function(node_a, node_b)
    return node_a.avg_time < node_b.avg_time
end
_output_sort_func[2] = function(node_a, node_b)
    return node_a.max.time < node_b.max.time
end
_output_sort_func[3] = function(node_a, node_b)
    return node_a.total_count < node_b.total_count
end

function _output_one_node_in_order(node, order_mode)
    local order_array = {}
    for k, v in pairs(node.sons) do
        order_array[#order_array + 1] = v
    end

    table.sort(order_array, _output_sort_func[order_mode])
    for i, v in ipairs(order_array) do
        _print_log_str(v)
    end
end

function _is_self_or_son_of(node, module_name)
    local parent = node
    while parent do
        if parent.name == module_name then
            return true
        end
        parent = parent.parent
    end
    return false
end

function _clear_one_node(node, module_name)
    if node.name then
        if not module_name or _is_self_or_son_of(node, module_name) then
            node.total_count = 0
            node.total_time = 0
            node.avg_time = 0
            node.min = {key=nil, time=math.huge}
            node.max = {key=nil, time=-1}
        end
    end
    for k, v in pairs(node.sons) do
        _clear_one_node(v, module_name)
    end
end

function _print_and_log(str)
    print(str)
    LOG(str)
end
