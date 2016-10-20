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
    for k, _ in pairs(title_list) do
        self:try_upgrade(k)
    end
end

function try_upgrade(self, idx)
    if check_tit(self, idx) then
        local lv = self:get_title(idx) or 1
        local propid = idx * 10 + lv 
        local conf = resmng.get_conf("prop_title", propid)
        if not conf then return end
        local nextId = conf.NextID or 0
        local conf1 = resmng.get_conf("prop_title", nextId)
        if not conf1 then return end

        set_title(self, idx, lv + 1 )
        self:try_upgrade(idx)
    end
end

function check_tit(self, idx)
    local lv = self:get_title(idx) or 1
    local propid = idx * 10 + lv 
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

function use_title_req(self, idx)
    local oldConf = resmng.get_conf("prop_title", self.title)
    if oldConf then
        self:rem_buf(oldConf.Buff)
    end
    self.title = idx
    local conf = resmng.get_conf("prop_title", idx)
    if conf then
        self:add_buf(conf.Buff, 1)
    end
end

function rem_title_req(self, idx)
    local oldConf = resmng.get_conf("prop_title", self.title)
    if oldConf then
        self:rem_buf(oldConf.Buff)
    end
    self.title = 0
end




