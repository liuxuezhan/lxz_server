 module( "player_t")

function do_load_hero_equip(self)
    local db = self:getDb()
    --local info = db.equip:find({pid=self.pid, pos={["$gte"]=0}})
    local info = db.hero_equip:find({_id=self.pid})
    return info
end

function get_hero_equip(self, id)
    if not self._hero_equip then self._hero_equip = self:do_load_hero_equip() end
    if id then
        return self._hero_equip[ id ]
    else
        return self._hero_equip
    end
end

function set_hero_equip(self, key, val)
    local hero_equips = self:get_hero_equip()
    hero_equips[key] = val
    gPendingSave.hero_equip[ self.pid ][key] = hero_equips[ key ]  
end

function hero_equip_add(self, propid, why)
    --local id = getId("equip")
    local t = {_id = propid, propid=propid, pid=self.pid, pos=0, hero_id = 0, exp = 0}
    self:set_hero_equip(self, key, val)
    INFO("hero_equip_add: pid = %d, item_id = %d, reason = %d.", self.pid, propid, why)
end

function hero_equip_lv_up_req(self, equip_id, item_idx, num)
    if not equip_id or not item_idx or not num or num <= 0 then
        return
    end

    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return
    end

    local prop_equip = resmng.get_conf("prop_hero_item", equip.propid)
    if not prop_equip then
        return
    end

    local item = self:get_item(item_idx)
    if not item then
        return
    end

    local conf = resmng.get_conf("prop_item", item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SKILL then
        ERROR("hero_equip_lv_up: not hero equip exp book. pid = %d, item_idx = %d, item_id= %d, conf.Class = %d, conf.Mode = %d.",self.pid, item_idx, item[2], conf.Class, conf.Mode)
        return
    end

    local hero
    if equip.hero_id  ~= 0 then
        hero = heromng.get_hero_by_uniq_id(equip.hero_id)
        if hero then
            if hero.lv <= prop_equip.Lv then
                return
            end
        end
    end

    local need_exp = prop_equip.LvUpCond - equip.exp
    if need_exp < 1 then
        return
    end
    local max = math.ceil(need_exp / conf.Param)
    if num > max then num = max end
    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.HERO_LV_UP) then 
        do_lv_up(equip, conf.Param * num)
    end
end

function do_lv_up(equip, exp)
    local prop_equip = resmng.get_conf("prop_hero_item", equip.propid)
    if not prop_equip then
        return
    end

    local need_exp = prop_equip.LvUpCond - equip.exp
    if need_exp < 1 then
        return
    end

    if need_exp > exp then
        return 
    else
        local new_prop = resmng.prop_hero_item[equip.propid + 1]
        if not new_prop then
            return
        end
        equip.propid = new_prop.ID
        equip.exp = equip.exp - need_exp


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

    local prop_equip = resmng.get_conf("prop_hero_item", equip.propid)
    if not prop_equip then
        return
    end

    if not self:condCheck(prop_equip.StarUpCond) then
        return 
    end

    self:consume(prop_equip.StarUpCond, 1, VALUE_CHANGE_REASON.FORGE)
end

function hero_equip_break(self, equip_id)
    if not equip_id then
        return
    end

    local equip = self:get_hero_equip(equip_id)
    if not equip then
        return
    end

    local prop_equip = resmng.get_conf("prop_hero_item", equip.propid)
    if not prop_equip then
        return
    end

end

