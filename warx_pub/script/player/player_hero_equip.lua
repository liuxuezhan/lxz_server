 module( "player_t")

function do_load_hero_equip(self)
    local db = self:getDb()
    --local info = db.equip:find({pid=self.pid, pos={["$gte"]=0}})
    local info = db.hero_equip_t:find({pid=self.pid})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[b._id] = hero_equip_t.wrap(b)
    end
    return bs
end

function get_hero_equip(self, id)
    if not self._hero_equip then
        local info = self:do_load_hero_equip()
        if not self._hero_equip then
            if info then
                self._hero_equip = info
            else
                self._hero_equip = {}
            end
        end
    end
    if id then
        return self._hero_equip[ id ]
    else
        return self._hero_equip
    end
end

function get_hero_equip_num_by_class_mode(self, class, mode)
    local eqs = self:get_hero_equip()
    if not eqs then
        return 0
    end

    local n = 0
    local list = {}
    for id, eq in pairs(eqs or {}) do
        local prop = resmng.get_conf("prop_hero_equip", eq.propid) 
        if prop.Class == class and prop.Mode == mode then
            n = n + 1
            table.insert(list, id)
        end
    end
    return n, list
end

function del_hero_equip_by_class_mode(self, class, mode, num, why)
    local eqs = self:get_hero_equip()
    if not eqs then
        return false
    end

    local n = 0
    local dels = {}
    for id, eq in pairs(eqs or {}) do
        local prop = resmng.get_conf("prop_hero_equip", eq.propid) 
        if prop.Class == class and prop.Mode == mode then
            n = n + 1
            table.insert(des, id)
        end
        if n == num then
            break
        end
    end
    if n >= num then
        for _, id in pairs(dels or {}) do
            self:del_hero_equip(id)
        end
        return true
    else
        return false
    end
end

function del_hero_equip(self, equip_id, why)
    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return false
    end
    --local hero = heromng:get_hero_by_uniq_id(equip.hero_id)
    local hero = self:get_hero(equip.hero_id)
    if hero then
        hero.equips[equip.pos] = nil
    end
    self:set_hero_equip(equip_id) 
    hero_equip_t.clr(equip)
    return true
end

function set_hero_equip(self, key, val)
    local hero_equips = self:get_hero_equip()
    hero_equips[key] = val
   -- if val then
   --     gPendingSave.hero_equip[ self.pid ][key] = hero_equips[ key ]  
   -- else
   --     gPendingDelete.hero_equip[self.pid][key] = 1 
   -- end
end
--------------------------------------------------------------------
--
function get_hero_equip_req(self)
    local equip = self:get_hero_equip()
    if equip then
        Rpc:get_hero_equip_ack(self, equip)
    end
end

function hero_equip_add(self, propid, why)
    local why1 = why or 1
    local id = getId("heroequip")
    local t = {_id = id, propid=propid, pid=self.pid, pos=0, hero_id = 0, exp = 0}
    local equip = hero_equip_t.new(t)
    self:set_hero_equip(id, equip)
    Rpc:update_hero_equip_ack(self, equip._pro)
    INFO("hero_equip_add: pid = %d, _id = %d, item_id = %d, reason = %d.", self.pid, id, propid, why1)
end

function hero_equip_lv_up_req(self, equip_id, item_idx, num)
    if not equip_id or not item_idx or not num or num <= 0 then
        return
    end

    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return
    end

    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return
    end

    if prop_equip.Lv == prop_equip.MaxLv then
        return
    end

    local item = self:get_item(item_idx)
    if not item then
       -- return
    end

    local conf = resmng.get_conf("prop_item", item[2])
    if not conf or conf.Class ~= ITEM_CLASS.HERO_EQUIP_EXP then
        ERROR("hero_equip_lv_up: not hero equip exp book. pid = %d, item_idx = %d, item_id= %d, conf.Class = %d, conf.Mode = %d.",self.pid, item_idx, item[2], conf.Class, conf.Mode)
        return
    end
    --local conf = resmng.get_conf("prop_item", 4003001)

   -- if self.lv <= prop_equip.Lv then
    --    return
   -- end

    if equip.hero_id  ~= 0 then
        local hero = self:get_hero(equip.hero_id)
        --hero = heromng.get_hero_by_uniq_id(equip.hero_id)
        if not hero then
            return
        end
        if not hero:is_valid() then
            return
        end
        if hero.lv <= prop_equip.Lv then
            return 
        end
    end

    --local need_exp = prop_equip.LvUpCond - equip.exp
    local need_exp = self:get_max_exp(equip) - equip.exp
    if need_exp < 1 then
        return
    end
    local max = math.ceil(need_exp / conf.Param)
    if num > max then num = max end
    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.HERO_EQUIP_LV_UP) then 
        do_lv_up(equip, conf.Param * num)
        self:set_hero_equip( equip_id, equip)
    end
    Rpc:update_hero_equip_ack(self, equip._pro)
end

function get_max_exp(self, equip)
    local prop = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop then
        return 0
    end
    local maxlv = prop.MaxLv
  --  if maxlv > self.lv then
  --      maxlv = self.lv
 --   end
    local h = self:get_hero(equip.hero_id)
    if h then
        if h.lv < maxlv then
            maxlv = h.lv
        end
    end
    if prop.Lv >= maxlv then
        return 0
    end
    local need_exp = 0
    local propid = equip.propid
    for i = prop.Lv, maxlv, 1 do
        local prop_equip = resmng.get_conf("prop_hero_equip", propid)
        need_exp = need_exp +  prop_equip.LvUpCond
        propid = propid + 1
    end
    return need_exp
end

function do_lv_up(equip, exp)
    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return
    end

    local need_exp = prop_equip.LvUpCond - equip.exp
    if need_exp < 1 then
        return
    end

    equip.exp = equip.exp + exp
    if need_exp > exp then
        return 
    else
        local new_prop = resmng.prop_hero_equip[equip.propid + 1]
        if not new_prop then
            return
        end
        equip.propid = new_prop.ID
        equip.exp = equip.exp - prop_equip.LvUpCond
        if equip.exp >= new_prop.LvUpCond then
            local exp_add = equip.exp
            equip.exp = 0
            do_lv_up(equip, exp_add)
        end
    end
end

function hero_equip_star_up_req(self, equip_id)
    if not equip_id then
        return
    end

    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return
    end

    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return
    end
    if prop_equip.Mode >= prop_equip.MaxMode then
        return
    end

    local starup_cond = {}

    for _, cond in pairs(prop_equip.StarUpCond) do
        local class, mode, num = unpack(cond)
        if class == resmng.CLASS_HERO_EQUIP_GRAGE then
            local n = 0
            for _, id in pairs(consume_equips or {}) do
                if id ~= equip_id then
                    local eq = self:get_hero_equip(id)
                    if eq then
                        local prop = resmng.get_conf("prop_hero_equip", eq.propid)
                        if prop.Class == mode[1] and prop.Mode == mode[2] then
                            n = n + 1
                            table.insert(starup_cond, {resmng.CLASS_HERO_EQUIP, id, 1})
                        end
                    end
                    if n < num then
                        return
                    end
                end
            end
        else
            table.insert(starup_cond, cond)
        end
    end


    local use_list = {}
--    for _, id in pairs(consume_equips or {}) do
--        local eq = self:get_hero_equip(id)
--        if eq then
--            table.insert(use_list, eq.propid)
--        end
--    end

    if not self:condCheck(starup_cond) then
        return 
    end

    if self:consume(starup_cond, 1, VALUE_CHANGE_REASON.HERO_EQUIP_STAR_UP) then
        do_star_up(equip)
        self:set_hero_equip(equip_id, equip)
        for _, id in pairs(use_list or {}) do
            local prop = resmng.get_conf("prop_hero_equip", id)
            if prop.DecomposeExp then
                self:add_bonus(prop.DecomposeExp[1], prop.DecomposeExp[2], VALUE_CHANGE_REASON.HERO_EQUIP_DECOMPOSE)
            end
        end
    end
    Rpc:update_hero_equip_ack(self, equip._pro)
end

function do_star_up(equip)
    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return
    end
    local exp = get_totle_exp(equip)

    equip.propid = equip.propid + 1000
    local propid = math.floor(equip.propid / 100) * 100 + prop_equip.MinLv
    while true do
        local conf = resmng.get_conf("prop_hero_equip", propid)
        if not conf then
            break
        end
        if exp >= conf.LvUpCond then
            exp = exp - conf.LvUpCond
            propid = propid + 1
        else
            equip.propid = propid
            equip.exp = exp
            return
        end
    end
end

function get_totle_exp(equip)
    local exp = equip.exp or 0
    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return 0 
    end
    local propid = math.floor(equip.propid / 100) * 100 +  prop_equip.MinLv
    for i = prop_equip.MinLv , prop_equip.Lv, 1 do
        propid = propid + 1
        if propid < equip.propid then
            local conf = resmng.get_conf("prop_hero_equip", propid)
            exp = exp + conf.LvUpCond
        end
    end
    return exp
end

function hero_equip_decompose_req(self, equip_id)
    if not equip_id then
        return
    end

    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return
    end

    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return
    end

    if self:del_hero_equip(equip_id) then
        if prop_equip.DecomposeExp then
            self:add_bonus(prop_equip.DecomposeExp[1], prop_equip.DecomposeExp[2], VALUE_CHANGE_REASON.HERO_EQUIP_DECOMPOSE)
        end

        if prop_equip.DecomposeItem then
            self:add_bonus(prop_equip.DecomposeItem[1], prop_equip.DecomposeItem[2], VALUE_CHANGE_REASON.HERO_EQUIP_DECOMPOSE)
        end
        local eq = equip._pro
        eq.delete = 1
        Rpc:update_hero_equip_ack(self, eq)
    end
end

function use_equip_req(self, hero_idx, idx, equip_id)
    if not hero_idx or not idx or not equip_id then
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        return
    end

    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return
    end

    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return
    end

    --if prop_equip.Lv ~= prop_equip.MinLv and prop_equip.Lv > self.lv then
    --    return
   -- end

    if prop_equip.Lv ~= prop_equip.MinLv and prop_equip.Lv > hero.lv then
        return
    end

    self:rem_equip_req(hero_idx, idx)

    if hero:try_use_equip(idx, equip_id) then
        Rpc:update_hero_equip_ack(self, equip._pro)
    end
    --print("use equip", equip_id)
    return
end

function rem_equip_req(self, hero_idx, idx)
    if not hero_idx or not idx then
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        return
    end

    if hero.equips[idx] == nil then
        return
    end

    local equip = self:get_hero_equip(hero.equips[idx])
    if not equip then
        return
    end

    if hero:try_rem_equip(idx) then
        Rpc:update_hero_equip_ack(self, equip._pro)
    end
    --print("rem equip", equip._id)
end

--function hero_equip_break(self, equip_id)
--    if not equip_id then
--        return
--    end
--
--    local equip = self:get_hero_equip(equip_id)
--    if not equip then
--        return
--    end
--
--    local prop_equip = resmng.get_conf("prop_hero_item", equip.propid)
--    if not prop_equip then
--        return
--    end
--
--end

