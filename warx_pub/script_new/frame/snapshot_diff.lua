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
    -- other_diff_obj = {
    --      [snapshot.TABLE] = {},         -- 类型为table的diff对象数组
    --      [snapshot.FUNCTION] = {},      -- 类型为function的diff对象数组
    --      [snapshot.THREAD] = {},        -- 类型为thread的diff对象数组
    --      [snapshot.USERDATA] = {},      -- 类型为userdata的diff对象数组
    -- }
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
        local record = nil
        for addr_str, type_index in pairs(self.data_later[snapshot.MARK]) do
            if self.data_earlier[snapshot.MARK][addr_str] == nil then
                record = self.data_later[type_index][addr_str]
                if record and not record.desc then
                    table.insert(self.other_diff_obj[type_index], addr_str)
                end
            end
        end
    end,

    _diff_sort_func = function(A, B)
        if A.diff ~= B.diff then
            return A.diff > B.diff
        end
        return A.name < B.name
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
                print(i.."."..simple_info)
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

    print_one_node = function(self, addr_str, max_cnt)
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
        local tree = self:get_relation_tree(data, addr_str)
        self:dumpTab(tree, "print_one_node", max_cnt)
        self:print_line()
    end,

    print_other = function(self, obj_type, limit_start, limit_count)
        if not self.data_earlier or not self.data_later then
            print("call load() first!")
            self:print_line()
            return
        end

        obj_type = obj_type or "table"
        local type_index = snapshot.type_2_index[obj_type]
        if type_index == nil then
            print("error: invalid obj_type")
            return
        end

        if self.other_diff_obj == nil then
            self.other_diff_obj = {
                [snapshot.TABLE] = {},
                [snapshot.FUNCTION] = {},
                [snapshot.THREAD] = {},
                [snapshot.USERDATA] = {},
            }
            self:_scan_other()
            for k, v in pairs(self.other_diff_obj) do
                table.sort(v, nil)
            end
        end

        self:_output_array_simple_info(self.other_diff_obj[type_index], self.data_later, limit_start, limit_count)
        return
    end,

    -- addr_str为要统计的节点key
    -- node为父节点，
    -- mark_nodes为所有已经包含在树中的节点，扁平的
    get_relation_tree = function(self, data, addr_str, node, mark_nodes)
        local first = node == nil and mark_nodes == nil
        if first then
            node = {key=addr_str}
            mark_nodes = {}
        end
        if mark_nodes[addr_str] == nil then
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
                                str_temp = str_temp.."|"..k1
                            end
                            str_temp = str_temp.."]"
                            desc = desc..str_temp

                            local parent_node = {}
                            self:get_relation_tree(data, k, parent_node, mark_nodes)
                            if next(parent_node) ~= nil then
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
                            str_temp = str_temp.."|"..k1
                        end
                        str_temp = str_temp.."]"
                        desc = desc..str_temp
                    end
                end
                
            end
        end

        return desc
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
