module("player_t")

title_list = title_list or {}

function gen_title_list()
    for _, v in pairs(resmng.prop_title or {}) do
        if not title_list[v.Mode] then
            title_list[v.Mode] = v.Mode
        end
    end
end

function do_load_title(self)
    local db = self:getDb()
    local info = db.title:findOne({_id = self.pid})

    gen_title_list()

    return info or {}
end

function get_title(self, id)
    if not self._title then self._title = self:do_load_title() end
    if id then return self._title[id] else return self._title end
end

function set_title(self, id, val)
    local title = self:get_title()
    title[id] = val
    gPendingSave.title[self.pid][id] = val
end

function title_info_req(self)
    local pack = {}
    local titles = self:get_title()
    if titles then
        pack.titles = titles
    end
    Rpc:title_info_ack(self, pack)
end

function try_upgrade_titles(self)
    --local titles = self:get_title()
    for k, _ in pairs(title_list or {}) do
        self:try_upgrade(k)
    end
end

function try_upgrade(self, idx)
    if check_tit(self, idx) then
        local lv = self:get_title(idx) or 0
        if type(lv) == "table" then
            lv = 0
        end

        if lv ~= 0 then -- level 0 
            local propid = idx * 10 + lv 
            local conf = resmng.get_conf("prop_title", propid)
            if not conf then return end
            local nextId = conf.NextID or 0
            local conf1 = resmng.get_conf("prop_title", nextId)
            if not conf1 then return end
        end
        set_title(self, idx, lv + 1 )
        try_use_title(self)
        self:try_upgrade(idx)
    end
end

function try_use_title(self)
    local index = math.floor(self.title / 10)
    local lv = self.title % 10
    local real_lv = self:get_title(index) or 0
    if real_lv ~= lv then
        local oldConf = resmng.get_conf("prop_title", self.title)
        if oldConf then
            self:rem_buf(oldConf.Buff)
        end
        self.title = index * 10 + real_lv
        local conf = resmng.get_conf("prop_title", self.title)
        if conf then
            self:add_buf(conf.Buff, -1)
        end
    end
end

function check_tit(self, idx)
    local lv = self:get_title(idx) or 0
    if type(lv) == "table" then
        lv = 0
    end
    local propid = idx * 10 + lv + 1
    local conf = resmng.get_conf("prop_title", propid)
    if not conf then return end

    local result = false

    result =  (conf.Point or 0) <= self.ache_point

    if not result then return end

    for k, v in pairs(conf.Achievement or {}) do
        --result = self:check_ache(v)
        result = self:is_already_ache(v)
        if not result then return end
    end

    return result
end

function check_ach(self, idx)
    local ach = self:get_ache(idx)
    return ach > 0
end

function use_title_req(self, title)
    local index = math.floor(title / 10)
    local lv = title % 10
    local real_lv = self:get_title(index) or 0
    if type(real_lv) == "table"  then -- not title
        return
    end

    if real_lv ~= lv then --
        return
    end

    local oldConf = resmng.get_conf("prop_title", self.title)
    if oldConf then
        self:rem_buf(oldConf.Buff)
    end
    self.title = title
    local conf = resmng.get_conf("prop_title", title)
    if conf then
        self:add_buf(conf.Buff, -1)
    end
end

function rem_title_req(self, idx)
    local oldConf = resmng.get_conf("prop_title", self.title)
    if oldConf then
        self:rem_buf(oldConf.Buff)
    end
    self.title = 0
end

