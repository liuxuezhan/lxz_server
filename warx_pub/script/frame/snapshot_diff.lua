local string = string
local table = table

snapshot_diff = {
    _NAME = "snapshot_diff",
    data_earlier = nil,
    data_later = nil,
    -- module_table = {
    --      statistics = {},    -- key为module name，value为该module的个数
    --      data = {},          -- key为module name，value为table(table的key为attr, value为true)
    -- }
    module_earlier = nil,
    module_later = nil,
    other_diff_obj = nil,

    print_line = function(self)
        print(string.rep("-", 60))
    end,

    -- file_earlier: 较早的一个snapshot文件
    -- file_later: 较迟的一个snapshot文件
    load = function(self, file_earlier, file_later)
        self.data_earlier = snapshot:load(file_earlier)
        self.data_later = snapshot:load(file_later)
        if type(self.data_earlier) ~= "table" or type(self.data_later) ~= "table" then
            local str = string.format("snapshot_diff load failed! please check the filename.file_1:[%s],file_2:[%s]", self.data_earlier, self.data_later)
            print(str)
            return false
        end
        self.module_earlier = nil
        self.module_later = nil
        self.other_diff_obj = nil
        self:print_module()
        return true
    end,

    _scan_module = function(self, data, module_table)
        local module_stat = module_table.statistics
        local module_data = module_table.data
        local record = nil
        for addr_str, type_index in pairs(data[snapshot.MARK]) do
            record = data[type_index][addr_str]
            if record and record.desc then
                module_data[record.desc] = module_data[record.desc] or {}
                module_data[record.desc][addr_str] = true

                module_stat[record.desc] = module_stat[record.desc] or 0
                module_stat[record.desc] = module_stat[record.desc] + 1
            end
        end
    end,

    _scan_other = function(self)
        local ms_begin = c_msec()
        local record = nil
        local signatures = nil
        local sign_cnt_tab = {}
        local one_sign_info = nil
        local scan_cnt = 0
        for addr_str, type_index in pairs(self.data_later[snapshot.MARK]) do
            if self.data_earlier[snapshot.MARK][addr_str] == nil then
                record = self.data_later[type_index][addr_str]
                if record and not record.desc then
                    signatures = self:get_node_signatures(self.data_later, addr_str)
                    for k, v in pairs(signatures) do
                        one_sign_info = sign_cnt_tab[k]
                        if nil == one_sign_info then
                            one_sign_info = {cnt = 0, addrs = {}}
                            sign_cnt_tab[k] = one_sign_info
                        end
                        one_sign_info.cnt = one_sign_info.cnt + 1
                        if #one_sign_info.addrs < 3 then
                            table.insert(one_sign_info.addrs, addr_str)
                        end
                    end
                    scan_cnt = scan_cnt + 1
                    if scan_cnt % 100 == 0 then
                        print(string.format("print_other scan count = %d", scan_cnt))
                    end
                end
            end
        end

        for k, v in pairs(sign_cnt_tab) do
            table.insert(self.other_diff_obj, {sign = k, cnt = v.cnt, addrs = v.addrs})
        end

        table.sort(self.other_diff_obj, self._cnt_sort_func)
        local ms_end = c_msec()
        print(string.format("scan %d obj total, cost %d ms.", scan_cnt, ms_end - ms_begin))
    end,

    _diff_sort_func = function(A, B)
        if A.diff ~= B.diff then
            return A.diff > B.diff
        end
        return A.name < B.name
    end,

    _cnt_sort_func = function(A, B)
        return A.cnt > B.cnt
    end,

    _output_one_sign_info = function(i, sign_info)
        local out_str = string.format("%d.cnt:%d    sign:%s\n        addrs:", i, sign_info.cnt, sign_info.sign)
        for _, addr in ipairs(sign_info.addrs) do
            out_str = out_str .. string.format("<%s>", addr)
        end
        print(out_str)
    end,

    _output_array_simple_info = function(self, output_data, org_data, limit_start, limit_count)
        limit_start = limit_start or 1
        limit_count = limit_count or 10

        if #output_data < limit_start then
            print("no more records")
        else
            local simple_info = nil
            for i = limit_start, limit_count do
                if i > #output_data then
                    break
                end
                simple_info = self:get_simple_info(org_data,  output_data[i])
                print(string.format("%d.%s", i, simple_info))
                self:print_signature(output_data[i])
            end
        end
        self:print_line()
    end,

    _output_array_detail_info = function(self, output_data, org_data, limit_start, limit_count, max_deep)
        limit_start = limit_start or 1
        limit_count = limit_count or 10
        max_deep = max_deep or 5

        if #output_data < limit_start then
            print("no more records")
        else
            for i = limit_start, limit_count do
                if i > #output_data then
                    break
                end
                local tree = self:get_relation_tree(org_data, output_data[i], 0, math.ceil(max_deep))
                self:dumpTab(tree, "print_one_node", max_deep)
                self:print_line()
            end
        end
        --self:print_line()
    end,

    _output_array_sign_cnt = function(self, output_data, limit_start, limit_count)
        limit_start = limit_start or 1
        limit_count = limit_count or 10

        if #output_data < limit_start then
            print("no more records")
        else
            for i = limit_start, limit_count do
                if i > #output_data then
                    break
                end
                self._output_one_sign_info(i, output_data[i])
            end
        end
        self:print_line()
    end,

    -- 只统计module的个数
    print_module = function(self)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end
        
        if not self.module_earlier or not self.module_later then
            self.module_earlier = {
                statistics = {},
                data = {},
            }
            self.module_later = {
                statistics = {},
                data = {},
            }
            self:_scan_module(self.data_earlier, self.module_earlier)
            self:_scan_module(self.data_later, self.module_later)
        end

        -- diff_data = {
        --      [1] = {
        --          name = "snapshot",      --模块名
        --          earlier = 0,            --之前的count
        --          later = 0,              --之后的count
        --          diff = 0,               --diff的count,可能为负数
        --      }
        -- }
        local diff_data = {}
        local later_count = 0
        for name, count in pairs(self.module_earlier.statistics) do
            later_count = self.module_later.statistics[name] or 0
            table.insert(diff_data, {name=name, earlier=count, later=later_count, diff=later_count-count})
        end
        for name, count in pairs(self.module_later.statistics) do
            if self.module_earlier.statistics[name] == nil then
                table.insert(diff_data, {name=name, earlier=0, later=count, diff=count})
            end
        end

        table.sort(diff_data, self._diff_sort_func)
        for i, v in ipairs(diff_data) do
            print(string.format("name=%s, earlier=%d, later=%d, diff_count=%d", v.name, v.earlier, v.later, v.diff))
        end

        self:print_line()
    end,

    -- 输出差异module的具体对象列表和简单信息
    -- module_name: 希望输出的module的名字
    -- limit_start: 输出起始点，默认为1
    -- limit_count: 输出数量，默认为10
    -- eg: snapshot_diff:print_one_module("player_t")   --默认输出前10条
    -- eg: snapshot_diff:print_one_module("player_t", 10) -- 输出第10-20条
    -- eg: snapshot_diff:print_one_module("player_t", 10, 25) --输出第10-35条
    print_one_module = function(self, module_name, limit_start, limit_count)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end
        if not module_name or string.len(module_name) == 0 then
            print("error: you must input module_name")
            return
        end
        
        -- 如果later中存在，那么就输出later与earlier的差异数据
        -- 如果later中不存在，那么就输出earlier中的数据
        local org_data = self.data_later
        local src_data = self.module_later.data[module_name]
        local dst_data = self.module_earlier.data[module_name]
        if not src_data and not dst_data then
            print("error: module_name not exists!")
            return
        end

        if not src_data then
            src_data, dst_data = dst_data, src_data
            org_data = self.data_earlier
        end

        local diff_data = {}
        for addr_str, _ in pairs(src_data) do
            if not dst_data or dst_data[addr_str] == nil then
                table.insert(diff_data, addr_str)
            end
        end
        table.sort(diff_data, nil)

        self:_output_array_simple_info(diff_data, org_data, limit_start, limit_count)
        return
    end,

    print_one_node = function(self, addr_str, max_deep)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end
        local earlier_mark_data = self.data_earlier[snapshot.MARK][addr_str]
        local later_mark_data = self.data_later[snapshot.MARK][addr_str]
        if not earlier_mark_dataor and not later_mark_data then
            print("error: invalid addr_str")
            return
        end
        local data = later_mark_data and self.data_later or self.data_earlier
        local tree = self:get_relation_tree(data, addr_str, 0, math.ceil(max_deep / 2))
        self:dumpTab(tree, "print_one_node", max_deep)
        self:print_line()
    end,

    -- 输出差异module的某些结点的详细信息
    -- module_name: 希望输出的module的名字
    -- limit_start: 输出起始点，默认为1
    -- limit_count: 输出数量，默认为10
    -- max_deep: 输出深度，默认为5
    -- eg: snapshot_diff:print_one_module_detail("player_t")   --默认输出前10条
    -- eg: snapshot_diff:print_one_module_detail("player_t", 10) -- 输出第10-20条
    -- eg: snapshot_diff:print_one_module_detail("player_t", 10, 25) --输出第10-35条
    print_one_module_detail = function(self, module_name, limit_start, limit_count, max_deep)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end
        if not module_name or string.len(module_name) == 0 then
            print("error: you must input module_name")
            return
        end
        
        -- 如果later中存在，那么就输出later与earlier的差异数据
        -- 如果later中不存在，那么就输出earlier中的数据
        local org_data = self.data_later
        local src_data = self.module_later.data[module_name]
        local dst_data = self.module_earlier.data[module_name]
        if not src_data and not dst_data then
            print("error: module_name not exists!")
            return
        end

        if not src_data then
            src_data, dst_data = dst_data, src_data
            org_data = self.data_earlier
        end

        local diff_data = {}
        for addr_str, _ in pairs(src_data) do
            if not dst_data or dst_data[addr_str] == nil then
                table.insert(diff_data, addr_str)
            end
        end
        table.sort(diff_data, nil)

        self:_output_array_detail_info(diff_data, org_data, limit_start, limit_count, max_deep)
        return
    end,

    print_other = function(self, limit_start, limit_count)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end

        if self.other_diff_obj == nil then
            self.other_diff_obj = {}
            self:_scan_other()
        end

        self:_output_array_sign_cnt(self.other_diff_obj, limit_start, limit_count)
        return
    end,

    print_other_by_search = function(self, search, output_cnt_only)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end

        if self.other_diff_obj == nil then
            self.other_diff_obj = {}
            self:_scan_other()
        end

        local is_func = type(search) == "function"
        local num = 1
        local total_cnt = 1
        for i, v in ipairs(self.other_diff_obj) do
            if is_func then
                if search(v) then
                    if not output_cnt_only then
                        self._output_one_sign_info(num, v)
                    end
                    num = num + 1
                end
            elseif string.find(v.sign, search) then
                if not output_cnt_only then
                    self._output_one_sign_info(num, v)
                end
                num = num + 1
            end
            total_cnt = total_cnt + 1
        end

        print(string.format("print_other_by_search cnt=%d, total_cnt=%d", num, total_cnt))
    end,

    print_signature = function(self, addr_str)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end
        local earlier_mark_data = self.data_earlier[snapshot.MARK][addr_str]
        local later_mark_data = self.data_later[snapshot.MARK][addr_str]
        if not earlier_mark_dataor and not later_mark_data then
            print("error: invalid addr_str")
            return
        end
        local data = later_mark_data and self.data_later or self.data_earlier
        local signatures = self:get_node_signatures(data, addr_str)
        self:dumpTab(signatures, "print_signature")
        self:print_line()
    end,

    -- addr_str为要统计的节点key
    -- node为父节点，
    -- mark_nodes为所有已经包含在树中的节点，扁平的
    get_relation_tree = function(self, data, addr_str, curr_deep, max_deep, node, mark_nodes)
        local first = node == nil and mark_nodes == nil
        if first then
            curr_deep = 1
            max_deep = max_deep or 5
            node = {key=addr_str}
            mark_nodes = {}
        else
            curr_deep = curr_deep + 1
        end

        if mark_nodes[addr_str] ~= nil then
            node.desc = "already visit"
        else
            mark_nodes[addr_str] = true

            if data[snapshot.SOURCE][addr_str] then
                node.source = data[snapshot.SOURCE][addr_str]
            end

            local type_index = data[snapshot.MARK][addr_str]
            if type_index then
                local record = data[type_index][addr_str]
                if record then
                    local desc = record.desc or ""
                    for k,v in pairs(record) do
                        if k ~= "desc" then
                            -- 将与父亲的关系串，整合为一个字符串，放入desc中
                            -- k为parent_key，v为一个table，table的key为关系描述字符串
                            local str_temp = "["
                            for k1,_ in pairs(v) do
                                str_temp = string.format("%s|%s", str_temp, k1)
                            end
                            str_temp = string.format("%s]", str_temp)
                            desc = string.format("%s%s", desc, str_temp)

                            if curr_deep < max_deep then
                                local parent_node = {}
                                self:get_relation_tree(data, k, curr_deep, max_deep, parent_node, mark_nodes)
                                node.parents = node.parents or {}
                                parent_node.relation = str_temp
                                node.parents[k] = parent_node
                            end
                        end
                    end
                    node.desc = desc
                end
            end
        end

        if first then
            return node
        end
    end,

    -- simple info只包括自身描述，与上一层父亲关系组成的描述串
    get_simple_info = function(self, data, addr_str)
        local desc = "unknown"
        local type_index = data[snapshot.MARK][addr_str]
        if type_index then
            local record = data[type_index][addr_str]
            if record then
                desc = record.desc or ""
                desc = desc.."<"..addr_str
                if data[snapshot.SOURCE][addr_str] then
                    desc = desc.."["..data[snapshot.SOURCE][addr_str].."]"
                end
                for k,v in pairs(record) do
                    if k ~= "desc" then
                        -- 将与父亲的关系串，整合为一个字符串，放入desc中
                        -- k为parent_key，v为一个table，table的key为关系描述字符串
                        local str_temp = "["
                        for k1,_ in pairs(v) do
                            str_temp = string.format("%s|%s", str_temp, k1)
                        end
                        str_temp = string.format("%s]", str_temp)
                        desc = string.format("%s%s", desc, str_temp)
                    end
                end
                
            end
        end

        return desc
    end,

    -- signature组成：从node往上搜寻，直到搜索到终端结点，往上的路径关系描述组成签名
    -- 终端结点包括：_ENV, _G, MODULE, FUNCTION
    -- 一个node可能有多个signature，都需要生成
    -- 广度遍历, 已经访问过的结点就不要重复访问了
    get_node_signatures = function(self, data, node_addr)
        local visited = {}
        local node_queue = {}
        local signatures = {}

        node_queue[1] = {node_addr, ""}

        while #node_queue > 0 do
            local addr_str = node_queue[1][1]
            local sign = node_queue[1][2]
            table.remove(node_queue, 1)

            if not visited[addr_str] then
                visited[addr_str] = true

                local type_index = data[snapshot.MARK][addr_str]
                if type_index then
                    local record = data[type_index][addr_str]
                    if record then
                        -- 如果自身就已经是一个module
                        if record.desc then
                            signatures[string.format("%s-%s", record.desc, sign)] = true
                            -- 如果已经上溯到function
                        elseif type_index == snapshot.FUNCTION then
                                local func_desc = data[snapshot.SOURCE][addr_str]
                                if func_desc ~= nil then
                                    signatures[string.format("%s-%s", func_desc, sign)] = true
                                else
                                    -- c function will come here
                                end
                            else
                                for k,v in pairs(record) do
                                    if k ~= "desc" then
                                        -- k为parent_key，v为一个table，table的key为关系描述字符串
                                        -- 如果与父亲有多个关系，则拼接成字符串，并且排序
                                        local ralations = {}
                                        local terminal_str = nil
                                        local need_deep  = false
                                        for k1,_ in pairs(v) do
                                            local key_sub_desc = string.sub(k1, 1, 2)
                                            local format_key = string.gsub(k1, "%d+", "NUM")
                                            ralations[#ralations+1] = format_key

                                            if string.find(k1, "_ENV") then
                                                terminal_str = "_ENV"
                                            elseif string.find(k1, "_G") then
                                                terminal_str = "_G"
                                            elseif key_sub_desc == "ke" or key_sub_desc == "k(" or key_sub_desc == "up" then
                                                need_deep = true
                                            end
                                        end
                                        if #ralations > 1 then
                                            table.sort(ralations, nil)
                                        end
                                        local ralation_desc = nil
                                        for i, v1 in ipairs(ralations) do
                                            if ralation_desc == nil then
                                                ralation_desc = v1
                                            else
                                                ralation_desc = string.format("%s-%s", ralation_desc, v1)
                                            end
                                        end

                                        if terminal_str then
                                            signatures[string.format("%s-%s-%s", terminal_str, ralation_desc, sign)] = true
                                        elseif need_deep then
                                            --print(string.format("%s-%s", ralation_desc, sign))
                                            node_queue[#node_queue+1] = {k, string.format("%s-%s", ralation_desc, sign)}
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            return signatures
        end,

    ------------------------------------------------------------------------------
    -- 以下几个函数是为了打印table
    mkSpace = function(self, num)
        return string.rep(" ", num)
    end,

    toStr = function(self, x)
        if type(x) == "string" then
            return "\"" .. tostring(x) .. "\""
        else
            return tostring(x)
        end
    end,

    dump_mark = {},

    LOG = function(self, fmt, ...)
        print(string.format(fmt, ...))
    end,

    doDumpTab = function(self, t, step, max_cnt, dump_cnt, first)
        if type(t) ~= "table" then
            self:LOG("%s: %s", type(t), tostring(t))
            return
        end
        local dump_mark = self.dump_mark

        if first then
            dump_cnt = 0
            dump_mark = {}
            max_cnt = max_cnt or 20
        else
            if max_cnt and (dump_cnt + 1 > max_cnt) then
                return
            end
        end

        step = step or 4
        self:LOG("%s{", self:mkSpace(step*dump_cnt))
        for k, v in pairs(t) do
            if type(v) == "table" then
                if not dump_mark[v] then
                    dump_mark[v] = true
                    if max_cnt and dump_cnt + 2 > max_cnt then
                    else
                        self:LOG("%s[%s] =", self:mkSpace(step*(dump_cnt+1)), self:toStr(k))
                        self:doDumpTab(v, step, max_cnt, dump_cnt+1)
                    end
                else
                    self:LOG("%s[%s] = %s -- already dumped.", self:mkSpace(step*(dump_cnt+1)), self:toStr(k), tostring(v))
                end
            else
                self:LOG("%s[%s] = %s", self:mkSpace(step*(dump_cnt+1)), self:toStr(k), self:toStr(v))
            end
        end
        self:LOG("%s}", self:mkSpace(step*dump_cnt))
        if first then dump_mark = {} end
    end,

    dumpTab = function(self, t, what, max_cnt)
        if true then
            self:LOG("|@@ : %s", what or "Unknown")
            if type(t) ~= "table" then
                self:LOG("%s: %s", type(t), tostring(t))
            else
                self:doDumpTab(t, nil, max_cnt, 0, true)
            end
            self:LOG("|$$ : %s", what or "Unknown")
        end
    end,
}
