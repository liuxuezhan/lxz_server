-- snapshot by zhoujy 20161206
-- 因为涉及大量的对象访问和遍历，强烈建议在release模式下使用
-- 目的：
--      1.希望知道一个对象的引用关系
--      2.希望通过较通用的方法来分析内存泄漏，主要是module实例的内存泄漏
-- 原理：通过记录下某2个时刻的所有复杂对象的快照。通过比较差异性，得出在2次快照之间产生了哪些复杂对象，并分析对象的引用关系A
-- 使用方法：
--      1.在某一个时刻使用snapshot:make(filename)来生成一个lua对象快照文件
--      2.利用snapshot_diff:load(filename1, filename2)来加载2份快照文件，进行差异性比较。
--      3.可以使用snapshot_diff:print_module()来输出module对象的统计信息
--      4.可以使用snapshot_diff:print_one_module(module_name, limit_start, limit_count)来输出某一个module对象的具体差异对象列表
--      5.可以使用snapshot_diff:print_one_node(addr_str, dump_level)来输出某一个对象的应用关系树
--      6.可以使用snapshot_diff:print_other(limit_start, limit_count)来输出非module对象的签名和数量
--      7.可以使用snapshot_diff:print_other_by_search(search, output_cnt_only)来输出特定签名的非module对象.
--          search可以是字符串或者函数
-- 其他：
--      1.关于时机的选择，2个时刻包含的时段应该包含泄漏事件（越明显越好）

local string = string
snapshot = {
    TABLE = 1,
    FUNCTION = 2,
    THREAD = 3,
    USERDATA = 4,
    SOURCE = 5,         --专门存放代码行数的域
    MARK = 6,

    data = nil,

    get_addr_str = function(self, obj)
        return tostring(obj)
    end,

    get_table_value_desc = function(self, k)
        return string.format("k(%s)", k)
    end,

    get_upvalue_desc = function(self, name)
        return string.format("up(%s)", name)
    end,

    get_obj = function(self, index, addr_str)
        return self.data[index][addr_str]
    end,

    is_marked = function(self, addr_str, type_index)
        local marked = self:get_obj(self.MARK, addr_str)
        if not marked then
            self.data[self.MARK][addr_str] = type_index
        end
        --print(string.format("zhoujy_debug is_marked=%s, addr=[%s]", marked, addr_str))
        --self:print(self.data[self.MARK])
        return marked
    end,

    -- 不能直接使用._NAME，因为会触发mongo.lua中的collection的新建表，导致扫描无线循环
    find_module_name = function(self, obj)
        --if rawget(obj, "_NAME") then
        --    -- 本身是一个使用module定义的模块table
        --    return rawget(obj, "_NAME")
        --end

        local meta = getmetatable(obj)
        if meta and meta.__index and type(meta.__index) == "function" then
            local uv_index = 1
            while true do
                local name, value = debug.getupvalue(meta.__index, uv_index)
                if name == nil then
                    break
                end
                if type(value) == "table" and rawget(value, "_NAME") then
                    return rawget(value, "_NAME")
                end
                uv_index = uv_index + 1
            end
        end
    end,

    -- desc参数，当parent_key为nil时，表示自身的描述
    -- 当parent_key不为nil时，表示自身与parent的关系描述
    --[[
        record = {
            desc = desc_str,            --描述该obj的字符串，可能是module_name或者[snapshot]等
            [parent_key] = relation_desc,   -- 存储和父亲的关系，以及关系描述
        }
    ]]--
    read_object = function(self, obj, parent_key, desc)
        local type_index = self.type_2_index[type(obj)]
        if type_index == nil then
            return nil
        end

        local addr_str = self:get_addr_str(obj)
        local marked = self:is_marked(addr_str, type_index)
        local record = nil
        if marked then
            record = self:get_obj(type_index, addr_str)
            --print(string.format("zhoujy_debug read_object already mark, index=[%d], addr=[%s], record=[%s]", type_index, addr_str, record))
        else
            --print(string.format("zhoujy_debug read_object first mark, index=[%d], addr=[%s]", type_index, addr_str))
            record = {}
            if type_index == snapshot.TABLE then
                -- 如果是table，那么看一下有没有可能是module，module具有_NAME字段
                record.desc = self:find_module_name(obj)
            end
            self.data[type_index][addr_str] = record
        end

        if record then
            if parent_key then
                record[parent_key] = record[parent_key] or {}
                record[parent_key][desc] = true
            else
                record.desc = desc
            end
        end

        if marked then
            return nil
        else
            return addr_str
        end
    end,

    mark_table = function(self, obj, parent_key, desc)
        local addr_str = self:read_object(obj, parent_key, desc)
        if addr_str == nil then
            return
        end
        if self.ignore_module_name[rawget(obj, "_NAME")] then
            return
        end
        --print(string.format("zhoujy_debug: mark_object obj=[%s], type=[%s], parent_key=[%s], desc=[%s]", obj, type(obj), parent_key, desc))

        local is_weak_k = false
        local is_weak_v = false
        local mt = getmetatable(obj)
        if mt then
            local model_str = rawget(mt, "__mode")
            if model_str then
                is_weak_k = string.find(model_str, 'k') ~= nil
                is_weak_v = string.find(model_str, 'v') ~= nil
            end

            self:mark_table(mt, addr_str, "metatable")
        end

        for k,v in pairs(obj) do
            if not is_weak_k then
                self:mark_object(k, addr_str, "key")
            end
            if not is_weak_v then
                self:mark_object(v, addr_str, self:get_table_value_desc(k))
            end
        end
    end,

    mark_userdata = function(self, obj, parent_key, desc)
        local addr_str = self:read_object(obj, parent_key, desc)
        if addr_str == nil then
            return
        end
        --print(string.format("zhoujy_debug: mark_object obj=[%s], type=[%s], parent_key=[%s], desc=[%s]", obj, type(obj), parent_key, desc))

        local mt = getmetatable(obj)
        if mt then
            self:mark_table(mt, addr_str, "metatable")
        end
        local user_value = debug.getuservalue(obj)
        if user_value then
            self:mark_table(user_value, addr_str, "uservalue")
        end
    end,

    mark_function = function(self, obj, parent_key, desc)
        local addr_str = self:read_object(obj, parent_key, desc)
        if addr_str == nil then
            return
        end
        --print(string.format("zhoujy_debug: mark_object obj=[%s], type=[%s], parent_key=[%s], desc=[%s]", obj, type(obj), parent_key, desc))

        local uv_index = 1
        while true do
            local name, value = debug.getupvalue(obj, uv_index)
            if name == nil then
                break
            end
            self:mark_object(value, addr_str, self:get_upvalue_desc(name))
            uv_index = uv_index + 1
        end

        local func_info = debug.getinfo(obj, "S")
        if func_info.what == 'C' then
            if uv_index == 1 then
                --print("zhoujy_debug: mark_function addr_str[%s] is c function set 2 nil")
                --self.data[self.FUNCTION][addr_str].desc = "C Func"
                self.data[self.FUNCTION][addr_str] = nil
            end
        elseif func_info.what == 'Lua' then
            local str = string.format("%s:%d", func_info.short_src, func_info.linedefined)
            self.data[self.SOURCE][addr_str] = str
        end
    end,

    mark_thread = function(self, obj, parent_key, desc)
        local addr_str = self:read_object(obj, parent_key, desc)
        if addr_str == nil then
            return
        end
        --print(string.format("zhoujy_debug: mark_object obj=[%s], type=[%s], parent_key=[%s], desc=[%s]", obj, type(obj), parent_key, desc))

        -- 以下代码是查找thread中的local，暂时不用
        --[[
        -- 故意跳过自身
        local f = 1
        while true do
            local info = debug.getinfo(obj, f, "Sl")
            if info == nil then
                break
            else
                for i=-1,1,2 do
                    local local_index = i
                    while true do
                        local name, value = debug.getlocal(obj, f, local_index)
                        if name == nil then
                            break
                        else
                            --print(string.format("zhoujy_debug: mark_thread name=%s, value=%s", name, value))
                        end
                        local desc_temp = string.format("[local]%s:%s:%d", name, info.short_src, info.currentline)
                        self:mark_object(value, addr_str, desc_temp)

                        local_index = local_index + i
                    end
                end
            end
            f = f + 1
        end
        ]]--
        
        local info = debug.getinfo(obj, 1)
        if info and info.func then
            self:mark_function(info.func, addr_str, info.name or "co-func")
        end

        --[[
        local info = debug.getinfo(obj, 1, "Sl")
        local str = string.format("%s:%d", info.short_src, info.currentline)
        self.data[self.SOURCE][addr_str] = str]]--
    end,

    mark_object = function(self, obj, parent_key, desc)
        local func = self.type_2_func[type(obj)]
        if func then
            func(self, obj, parent_key, desc)
        end
    end,

    reset = function(self)
        collectgarbage()
        collectgarbage()
        self.data = {}

        for i=self.TABLE,self.MARK do
            self.data[i] = {}
        end
       
        local self_addr = self:read_object(self, nil, "snapshot")
        for k,v in pairs(self) do
            self:read_object(v, self_addr, self:get_table_value_desc(k))
        end
    end,

    make = function(self, filename)
        if not filename or string.len(filename) == 0 then
            print("error: you must input a filename")
            return
        end
        self:reset()
        self:mark_table(debug.getregistry(), nil, "registry")
        local err = self:save(self.data, filename)
        if err then
            print(string.format("save file failed, err:%s", err))
        else
            print(string.format("make snapshot file successfull! path=%s", filename))
        end
        self.data = nil
    end,

---------------------------------------------------------------------------------
--以下几个函数是为了将table存成文件或者从文件加载
    exportstring = function(self, s)
        return string.format("%q", s)
    end,

    save = function(self, tbl, filename)
        local file,err = io.open( filename, "wb" )
        if err then return err end
        local pack_str = cmsgpack.pack(tbl)
        file:write(pack_str)
        file:close()
        return
    end,

    load = function(self, filename)
        local file,err = io.open(filename, "rb")
        if err then return err end
        local pack_str = file:read("a")
        file:close()
        --print("zhoujy_debug: load file successfull")
        return cmsgpack.unpack(pack_str)
    end,
}

snapshot.type_2_index = {
    ["table"] = snapshot.TABLE,
    ["function"] = snapshot.FUNCTION,
    ["thread"] = snapshot.THREAD,
    ["userdata"] = snapshot.USERDATA,
}

snapshot.type_2_func = {
    ["table"] = snapshot.mark_table,
    ["function"] = snapshot.mark_function,
    ["thread"] = snapshot.mark_thread,
    ["userdata"] = snapshot.mark_userdata,
}

snapshot.ignore_module_name = {
    ["perfmon"] = true,
    ["snapshot_diff"] = true,
}
