-- --.-----------------------------------------------------------------------.--
-- Hx@2016-05-25: 多字段zset version 0.2.0
-- 单字段zset + table.sort,效率瓶颈在取数据出来时使用了table.sort做多字段排序
-- Hx@2016-06-20: version 0.2.1 
-- 支持数字key
-- --'-----------------------------------------------------------------------'--

module("mulzset")
attach_wrap_()

function new(...)
    local self = deliver()
    if not self:ctor(...) then return end
    return self
end

function init(self)
    self.pk = ""
    self.args = {}
    self.sl = skiplist()
    self.tbl = {}
end

function ctor(self, pk, ...)
    assert(pk and #{...} ~= 0)
    self.pk = pk
    self.args, self.symbols = self:decode_args({...})
    if not self.args or is_table_empty(self.args) then return false end
    return true
end

function clean(self)
    self.tbl = {}
    self.sl = skiplist()
end

function add(self, data)
    if not self:check_add_data(data) then
        WARN("[mulzset] add, wrong data")
        return
    end

    local member = self:_zset_member(data)
    local zval = self:_zset_value(data)
    
    local old_zval = self:_zset_value(self.tbl[member])
    if old_zval then
        if old_zval ~= zval then 
            self.sl:delete(old_zval, member)
            self.sl:insert(zval, member)
        end
    else
        self.sl:insert(zval, member)
    end

    self.tbl[member] = data
    LOG("[mulzset] add, zset_score:%s, member:%s", zval, member)
end

function rem(self, member)
    member = tostring(member)
    local data = self.tbl[member]
    if data then
        self.sl:delete(self:_zset_value(data), member)
        self.tbl[member] = nil
    end
    LOG("[mulzset] rem, member:%s", member)
end

function count(self)
    return self.sl:get_count()
end

function limit(self, count, callback)
    local total = self.sl:get_count()
    if total <= count then return 0 end
    LOG("[mulzset] limit, delete, from:%s, to:%s", count, total)
    return self.sl:delete_by_rank(count + 1,  total, function(member) 
        self.tbl[member] = nil
        if callback then callback(member) end
    end)
end
function rev_limit(self, count, callback)
    local total = self.sl:get_count()
    if total <= count then
        return 0
    end
    local from = self:_reverse_rank(count + 1)
    local to = self:_reverse_rank(total)
    return self.sl:delete_by_rank(from, to, function(member) 
        self.tbl[member] = nil
        if callback then callback(member) end
    end)
end

function range(self, r1, r2)
    if #self.args == 1 then
        return self:_sol_range(r1, r2)
    else
        return self:_mul_range(r1, r2)
    end
end
function rev_range(self, r1, r2)
    local r1 = self:_reverse_rank(r1)
    local r2 = self:_reverse_rank(r2)
    if #self.args == 1 then
        return self:_sol_range(r1, r2)
    else
        local list = self:_mul_range(r1, r2)
        self:_mul_rev_sort(list)
        return list
    end
end

function rank(self, member)
    member = tostring(member)
    if not self.tbl[member] then return 0 end
    if #self.args == 1 then
        return self:_sol_rank(member)
    else
        return self:_mul_rank(member)
    end
end
function rev_rank(self, member)
    local r = self:rank(tostring(member))
    if r then return self:_reverse_rank(r) end
    return r
end

function range_by_score(self, s1, s2)
    return self.sl:get_score_range(self:_zset_score(s1), self:_zset_score(s2))
end

function score(self, member)
    return self.tbl[tostring(member)]
end

-- inner -----------
function _zset_value(self, data)
    if not data then return end
    return self:_zset_score(data[self.args[1]])
end

function _zset_score(self, score)
    return self.symbols[1] * score
end

function _zset_member(self, data)
    return tostring(data[self.pk])
end

function decode_args(self, t)
    local args, symbols = {}, {}
    for k, v in pairs(t) do
        if type(v) == 'string' then
            symbols[k] = (string.sub(v, 0, 1) == "-") and -1 or 1
            args[k] = string.gsub(v, "^-%W*", "")
        elseif type(v) == 'number' then
            symbols[k] = v > 0 and 1 or -1
            args[k] = math.abs(v)
        else
            WARN("[mulzset] unsupported sort key:%s, type:%s, idx:%s", tostring(v), type(v), k)
            return
        end
    end
    return args, symbols
end

function check_add_data(self, data)
    if not data[self.pk] then return false end
    for k, v in pairs(self.args) do
        if not data[v] then return false end
    end
    return true
end

--
function _reverse_rank(self, r)
    return self.sl:get_count() -r + 1
end

function _sol_range(self, r1, r2)
    if r1 < 1 then r1 = 1 end
    if r2 < 1 then r2 = 1 end
    return self.sl:get_rank_range(r1, r2)
end
function _mul_range(self, from, to)
    local list = self:_sol_range(from, to)
    local expand, exfrom, exto = self:_mul_expand(list, from, to)
    if expand then list = self:_sol_range(exfrom, exto) end
    self:_mul_sort(list)

    if expand then
        local res = {}
        for i = from - exfrom + 1, to - exfrom + 1 do
            table.insert(res, list[i])
        end
        list = res
    end
    return list
end

function _mul_sort(self, list)
    table.sort(list, function(l, r) 
        l, r = self.tbl[l], self.tbl[r]
        for i = 1, #self.args do
            local s, v = self.symbols[i], self.args[i]
            local left, right = s * l[v], s * r[v]
            if left ~= right then return left < right end
        end
        return l[self.pk] < r[self.pk]
    end)
end
function _mul_rev_sort(self, list)
    table.sort(list, function(l, r) 
        l, r = self.tbl[l], self.tbl[r]
        for i = 1, #self.args do
            local s, v = self.symbols[i], self.args[i]
            local left, right = s * l[v], s * r[v]
            if left ~= right then return left > right end
        end
        return l[self.pk] > r[self.pk]
    end)
end
function _mul_expand(self, list, from, to)
    local expand, exfrom, exto = false, from, to
    if #list ~= 0 then 
        local function score(member)
            return self:_zset_value(self.tbl[member])
        end
        local scorelist = self.sl:get_score_range(score(list[1]), score(list[#list]))
        local gap = #scorelist - #list
        if gap > 0 then 
            expand = true
            exfrom, exto = (from - gap < 1) and 1 or (from - gap), to + gap
        end
    end
    return expand, exfrom, exto
end

function _sol_rank(self, member)
    return self.sl:get_rank(self:_zset_value(self.tbl[member]), member)
end
function _mul_rank(self, member)
    local pos = self:_sol_rank(member)
    local expand, exfrom, exto = self:_mul_expand({member}, pos, pos)
    if expand then
        local exlist = self:_sol_range(exfrom, exto)
        self:_mul_sort(exlist)
        for k, v in pairs(exlist) do
            if v == member then   
                pos = exfrom + k - 1
                break
            end
        end
    end
    return pos
end
