-- --.-----------------------------------------------------------------------.--
-- Hx@2016-05-25: 排行榜 version 0.3.0
-- 子类不要继承ctor,因为在恢复数据的逻辑中强行指定了ctor
-- --'-----------------------------------------------------------------------'--

module("scorerank_t")
_example = {
    _id = 0,
    mode = 0,
    param = 0,
    tbl = {},
}
attach_wrap_()

INFO_HACK = 0   --c zset数据 = {rank = tostring(member)}
INFO_ORIGIN = 1 --原始数据 = {rank = what you add(t)}
INFO_AMPLE = 2  --通过ample_function丰富过的数据 = {rank = ample_function(t)}

function new(...)
    local self = deliver()
    self:ctor(...)
    gPendingSave.rank[self._id] = self._pro
    --nextframe()
    dbmng:getOne():runCommand("getLastError")
    return self
end

function init(self)
    self.zs = {}
    self.size = 0
end

function ctor(self, mode, param, size, amplefun)
    assert(mode and param)
    self._id = string.format("%s_%s", mode, param)
    self.mode = mode
    self.param = param
    self.size = size or 0
    self.amplefun = amplefun or function(t) return t end
end

function init_zset(self, ...)
    self.zs = mulzset.new(...)
    if not self.zs then return false end
    -- link
    self.tbl = self.zs.tbl
    return true
end

function destory(self)
    WARN("[DEL]")
    gPendingDelete.rank[self._id] = 1
end

function clean(self)
    self.zs:clean()
    -- relink
    self.tbl = self.zs.tbl
    self:save_all()
    LOG("[scorerank_t] clean, mode:%s, param:%s", self.mode, self.param)
end

function save_all(self)
    -- incase insert and update in then same time
    gPendingSave.rank[self._id] = nil
    gPendingInsert.rank[self._id] = self._pro
    dbmng:getOne():runCommand("getLastError")
    LOG("[scorerank_t] save_all, mode:%s, param:%s", self.mode, self.param)
end

-- limit 时并没有从数据库移除, 只是去掉了保存动作, 移除动作在restore时做
function add(self, data)
    self.zs:add(data)
    local key = self.zs:_zset_member(data)
    gPendingSave.rank[self._id]["tbl.".. key] = data
    LOG("[scorerank_t] add, key:%s, size:%s", key, self.size)
    if self.size ~= -1 then
        self.zs:limit(self.size, function(member) 
            LOG("[scorerank_t] add, drop:%s", member)
            if key == member then
                gPendingSave.rank[self._id]["tbl.".. member] = nil
            end
        end)
    end
end

function rem(self, member)
    self.zs:rem(member)
    gPendingSave.rank[self._id][string.format("tbl.%s._del", member)] = 1
end

function rank(self, member)
    return self.zs:rank(member)
end

function rev_rank(self, member)
    return self.zs:rev_rank(member)
end

function count(self)
    return self.zs:count()
end

function score(self, member)
    return self.zs:score(member)
end

function score_by_rank(self, r)
    local range = self:range(r, r)
    if range[1] then return self:score(self.zs:_zset_member(range[1])) end
end

function range_by_score(self, s1, s2, infotype, amplefun)
    return self:render_list(self.zs:range_by_score(s1, s2), infotype or INFO_ORIGIN, amplefun or self.amplefun)
end

--
function range(self, r1, r2, infotype, amplefun)
    return self:render_list(self.zs:range(r1, r2), infotype or INFO_ORIGIN, amplefun or self.amplefun)
end

function rev_range(self, r1, r2, infotype, amplefun)
    return self:render_list(self.zs:rev_range(r1, r2), infotype or INFO_ORIGIN, amplefun or self.amplefun)
end

function render_list(self, r, infotype, amplefun)
    local res = {}
    if infotype == INFO_HACK then
        res = r
    elseif infotype == INFO_ORIGIN then
        for k, v in pairs(r) do res[k] = self.tbl[v] end
    elseif infotype == INFO_AMPLE then
        if not amplefun or type(amplefun) ~= 'function' then
            WARN("[scorerank_t] render_list, no render function")
            return
        end
        for k, v in pairs(r) do res[k] = amplefun(self.tbl[v]) end
    end
    return res
end

function get_ample_list(self, index)
    return self:range(index, index + 20, INFO_AMPLE)
end
