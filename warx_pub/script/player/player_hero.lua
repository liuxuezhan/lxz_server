--------------------------------------------------------------------------------
-- Desc     : player hero.
-- Author   : Yang Cong
-- History  :
--     2016-1-25 19:43:18 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
module("player_t")


--------------------------------------------------------------------------------
function make_hero(self, propid)
    local hs = self:get_hero()
    --英雄存在转化成碎片
    local is_exist = false
    for idx, hero in pairs(hs) do
        if hero.propid == propid then
            is_exist = true
            break
        end
    end
    if is_exist == true then
        self:hero_to_chip(propid)
        return
    end

    for idx = 1, 100, 1 do
        if not hs[idx] then
            local h = hero_t.new(idx, self.pid, propid)
            if h then
                self._hero[ idx ] = h
                --任务
                task_logic_t.process_task(self, TASK_ACTION.HAS_HERO_NUM)
            end
            return
        end
    end
end

function hero_to_chip(self, propid)
    local prop_basic = resmng.get_conf("prop_hero_basic", propid)
    if prop_basic == nil then
        return
    else
        local total_chip = math.floor(prop_basic.CallPrice * HERO_CARD_2_PIECE_RATIO)
        self:inc_item(prop_basic.PieceID, total_chip, VALUE_CHANGE_REASON.CONVERT_HERO_CARD)
    end
end


function get_hero(self, idx)
    if not self._hero then self._hero = {} end
    if idx then
        if type(idx) == "string" then idx = tonumber(idx) end
        if self._hero then return self._hero[ idx ] end
    else
        return self._hero
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 propid 获取 hero
-- Argument : self, propid
-- Return   : hero / false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_hero_by_propid(self, propid)
    if not propid then
        ERROR("is_have_hero: pid = %d, propid = %d", self.pid or -1, propid or -1)
        return false
    end

    for idx, hero in pairs(self:get_hero()) do
        if hero.propid == propid then
            return hero
        end
    end

    return false
end


--------------------------------------------------------------------------------
-- Function : 使用碎片召唤英雄
-- Argument : self, piece_item_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function call_hero_by_piece(self, hero_propid)
    if not hero_propid then
        ERROR("call_hero_by_piece: hero_propid = %d.", hero_propid or -1)
        return
    end

    local hero = self:get_hero_by_propid(hero_propid)
    if not hero then
        local conf = resmng.get_conf("prop_hero_basic", hero_propid)
        if not conf then
            return
        end

        if self:dec_item_by_item_id(conf.PieceID, conf.CallPrice, VALUE_CHANGE_REASON.HERO_CREATE) then
            self:make_hero(hero_propid)
        else
            local piece_have = self:get_item_num(conf.PieceID)
            self:add_debug("call_hero_by_piece: pid = %d, hero_propid = %d, conf.PieceID = %d, piece_have = %d < conf.CallPrice = %d",
                   self.pid, hero_propid, conf.PieceID, piece_have, conf.CallPrice)
            return
        end
    else
        ERROR("call_hero_by_piece: player already have this hero. pid = %d, hero_propid = %d.", self.pid, hero_propid)
        return
    end
end


--------------------------------------------------------------------------------
-- Function : 英雄升星
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function hero_star_up(self, hero_idx)
    if not hero_idx then
        ERROR("hero_star_up: pid = %d, hero_idx = %d", self.pid or -1, hero_idx or -1)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("hero_star_up: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        hero:star_up()
    end
end

--------------------------------------------------------------------------------
-- Function : 英雄升级
-- Argument : self, hero_id, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function hero_lv_up(self, hero_idx, item_idx, num)
    if not hero_idx or not item_idx or not num or num <= 0 then
        ERROR("hero_lv_up: hero_idx = %d, item_idx = %d, num = %d", hero_idx or -1, item_idx or -1, num or -1)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("hero_lv_up: get_hero() failed. pid = %d, hero_idx = %d.", self.pid, hero_idx)
        return
    end

    if not hero:can_lv_up() then
        return
    end

    local item = self:get_item(item_idx)
    if not item then
        ERROR("hero_lv_up: get_item() failed. pid = %d, item_idx = %d.", self.pid, item_idx)
        return
    else
        local conf = resmng.get_conf("prop_item", item[2])
        if not conf then
            return
        end

        if conf.Class ~= ITEM_CLASS.HERO or conf.Mode ~= ITEM_HERO_MODE.EXP_BOOK then
            ERROR("hero_lv_up: not hero exp book. pid = %d, item_idx = %d, item_id= %d, conf.Class = %d, conf.Mode = %d.",
                   self.pid, item_idx, item[2], conf.Class, conf.Mode)
            return
        else
            local need = hero:exp_need()
            if need < 1 then return end
            local max = math.ceil(need / conf.Param)
            if num > max then num = max end
            if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.HERO_LV_UP) then
                hero:gain_exp(conf.Param * num)
            else
                return
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 查询所有英雄的详细信息
-- Argument : self, pid
-- Return   : NULL
-- Others   : pid
--------------------------------------------------------------------------------
function get_hero_list_info(self, pid)
    if self.pid ~= pid then
        return ERROR("get_hero_list_info: not allowed to get other players' info. self.pid = %d, pid = %d", self.pid, pid)
    end

    local ply = getPlayer(pid)
    if not ply then
        return LOG("get_hero_list_info: getPlayer(pid = %d) failed.", pid or -1)
    end

    local hero_list_info = {}
    for idx, hero in pairs(ply:get_hero()) do
        local hero_info = hero:gen_hero_info(true)
        table.insert(hero_list_info, hero_info)
    end

    return Rpc:on_get_hero_list_info(self, hero_list_info)
end


--------------------------------------------------------------------------------
-- Function : 查询指定英雄的详细信息
-- Argument : self, hero id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function get_hero_detail_info(self, hero_id)
    if not hero_id then
        return LOG("get_hero_detail_info: no hero_id.")
    end

    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero then
        return LOG("get_hero_detail_info: get hero failed, hero_id = %s", hero_id)
    end

    -- 暂时只允许查看自己的英雄，以后有需求再放开
    if hero.pid ~= self.pid then
        return ERROR("get_hero_detail_info: not allowed to get other players' info. self.pid = %d, hero_id = %s", self.pid, hero_id)
    end

    local hero_detail_info = hero:gen_hero_info(true)
    return Rpc:on_get_hero_detail_info(self, hero_detail_info)
end


--------------------------------------------------------------------------------
-- Function : 派遣英雄
-- Argument : self, build_idx, hero_idx
-- Return   : NULL
-- Others   : hero_idx = 0 表示取消派遣; 
--------------------------------------------------------------------------------
function dispatch_hero(self, build_idx, hero_idx)
    local build = self:get_build(build_idx)
    if not build then
        ERROR("dispatch_hero: get_build() failed. pid = %d, build_idx = %d", self.pid, build_idx)
        return
    end

    if hero_idx == 0 then
        if build.hero_idx == 0 then return end
        local hero = self:get_hero(build.hero_idx)
        if not hero then return end
        self:hero_offduty(hero)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("dispatch_hero: get_hero() failed. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    if build.hero_idx == hero_idx then
        self:hero_offduty(hero)
        return
    end

    if  hero.status ~= HERO_STATUS_TYPE.FREE then
        ERROR("dispatch_hero: status failed. pid = %d, hero_idx = %d, status=%d", self.pid, hero_idx, hero.status)
        return
    end

    self:hero_onduty(hero, build)
    LOG("dispatch_hero: build._id= %d, hero_idx = %d", self._id, hero_idx)
end


--------------------------------------------------------------------------------
-- Function : 分解英雄，返还经验卡
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function destroy_hero(self, hero_idx)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("destroy_hero: get hero failed. pid = %d, hero_idx = %d", self.pid, hero_idx or -1)
        return
    end

    local exp = hero:calc_total_exp()

    -- 判断状态是否正确
    if hero.status ~= HERO_STATUS_TYPE.FREE and hero.status ~= HERO_STATUS_TYPE.BUILDING and hero.status ~= HERO_STATUS_TYPE.BEING_CURED then
        return
    end

    if hero.quality >= HERO_QUALITY_TYPE.EPIC then return end

    -- 解除派遣
    self:hero_offduty(hero)

    if heromng.destroy_hero(hero._id) then
        Rpc:on_destroy_hero(self, hero_idx)
        -- 返还技能经验卡
        self:return_skill_exp_item(hero, VALUE_CHANGE_REASON.DESTROY_HERO)
        -- 返还英雄经验
        self:return_exp_item(exp * DESTROY_HERO_RETURN_RATIO, VALUE_CHANGE_REASON.DESTROY_HERO)
    end
end


--------------------------------------------------------------------------------
-- Function : 根据经验值返回经验值道具
-- Argument : self, exp, reason
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function return_exp_item(self, exp, reason)
    if not exp or (reason ~= VALUE_CHANGE_REASON.RESET_SKILL and reason ~= VALUE_CHANGE_REASON.DESTROY_HERO) then
        ERROR("return_exp_item: exp = %d, reason = %d.", exp or -1, reason or -1)
        return
    end
    if exp <= 0 then return end

    -- 统计经验道具
    local exp_item = {}
    if reason == VALUE_CHANGE_REASON.RESET_SKILL then
        for item_id, info in pairs(resmng.prop_item) do
            if info.Class == ITEM_CLASS.SKILL and info.Mode == ITEM_SKILL_MODE.COMMON_BOOK then
                table.insert(exp_item, {["item_id"] = item_id, ["exp"] = info.Param[2]})
            end
        end
    else
        for item_id, info in pairs(resmng.prop_item) do
            if info.Class == ITEM_CLASS.HERO and info.Mode == ITEM_HERO_MODE.EXP_BOOK then
                table.insert(exp_item, {["item_id"] = item_id, ["exp"] = info.Param})
            end
        end
    end

    local func_sort = function (node_1, node_2)
        return node_1.exp > node_2.exp
    end
    table.sort(exp_item, func_sort)

    -- 计算道具
    local item_list = {}
    for _, v in pairs(exp_item) do
        local num = math.floor(exp / v.exp)
        if num > 0 then
            table.insert(item_list, {["item_id"] = v.item_id, ["num"] = num})
        end
        exp = exp - num * v.exp
        if exp < exp_item[#exp_item].exp then
            break
        end
    end

    -- 发放道具
    for _, v in pairs(item_list) do
        --self:inc_item(v.item_id, v.num, reason)
        self:add_bonus("mutex_award", {{"item", v.item_id, v.num, 10000}}, reason)
        print( "add_item", v.item_id, v.num )
    end
    dumpTab(item_list, string.format("return_exp_item: pid = %d, item_list = ", self.pid))
end

--------------------------------------------------------------------------------
-- Function : 俘虏行军返回城市
-- Argument : hero_id
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function let_prison_back_home(self, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if hero then
        hero.tmSn    = 0
        hero.capturer_pid = 0
        hero.capturer_eid = 0
        hero.capturer_x = 0
        hero.capturer_y = 0
        hero.capturer_name = ""
        hero.status   = HERO_STATUS_TYPE.MOVING

        local ply = getPlayer(hero.pid)
        if ply then
            local arm = {pid=hero.pid, live_soldier={}, heros={hero_id, 0, 0, 0}}
            local troop = troop_mng.create_troop(TroopAction.Siege, ply, self, arm)
            troop.curx, trop.cury = get_ety_pos(self)
            troop.tmCur = gTime
            troop:back()
        else
            ERROR("let_prison_back_home: get player failed. pid = %d, hero._id = %s, hero.pid = %d.", self.pid, hero._id, hero.pid)
        end
    end
end



--------------------------------------------------------------------------------
-- Function : 真正的处决英雄
-- Argument : self, hero_id, new_buff_id, buff_time
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function real_kill_hero(self, hero_id, new_buff_id, buff_time)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero or hero.status ~= HERO_STATUS_TYPE.BEING_EXECUTED then
        ERROR("real_kill_hero: pid = %d, hero_id = %s, hero.status = %d.", self.pid, hero_id or "", hero and hero.status or -1)
        return
    end

    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar then
        ERROR("real_kill_hero: get altar failed. pid = %d", self.pid)
        return
    end

    if new_buff_id then
        -- remove old buff
        if altar.extra.curr_buff_id then
            self:update_kill_buff(altar.extra.curr_buff_id)
        end

        -- add new buff
        self:update_kill_buff(new_buff_id, true, buff_time)

        -- new timer to delete new buff.
        timer.new("delete_kill_buff", buff_time, self.pid, new_buff_id)
    end

    hero.status = HERO_STATUS_TYPE.DEAD
    -- altar.state = BUILD_STATE.WAIT

    local chg = {"hero_id", "kill_start_tm", "kill_over_tm"}
    altar:clr_extras(chg)

    -- new timer destroy hero.
    timer.new("destroy_dead_hero", RELIVE_HERO_DAYS_LIMIT * 24 * 60 * 60, hero_id)
end


--------------------------------------------------------------------------------
-- Function : 从监狱中移除指定英雄
-- Argument : self, hero_id
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function rm_prisoner(self, hero_id)
    local idx = self:is_in_prison(hero_id)
    if not idx then
        ERROR("rm_prisoner: pid = %d, hero_id = %s, not in prison.", self.pid, hero_id or -1)
        return false
    end

    local prison = self:get_prison()
    local chg = prison.extra.prisoners_info
    table.remove(chg, idx)
    prison:update_extra({["prisoners_info"] = chg})

    Rpc:on_get_out_of_prison(self, hero_id)
    return true
end


--------------------------------------------------------------------------------
-- Function : 添加或者删除 kill_buff
-- Argument : self, buff_id, is_add
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function update_kill_buff(self, buff_id, is_add, buff_time)
    -- TODO: 根据英雄战力计算buff加成
    local buff_conf = resmng.get_conf("prop_buff", buff_id)
    if buff_conf then
        -- TODO: check cond ???
        for effect_name, effect_value in pairs(buff_conf.Value) do
            if is_add then
                self._ef_hero[effect_name] = (self._ef_hero[effect_name] or 0) + effect_value
            else
                self._ef_hero[effect_name] = (self._ef_hero[effect_name] or 0) - effect_value
            end
        end
        LOG("update_kill_buff: pid = %d, buff_id = %d, is_add = %s.", self.pid, buff_id, is_add and "true" or "false")
    else
        ERROR("update_kill_buff: get prop_buff conf failed. pid = %d, buff_id = %d,", self.pid, buff_id)
    end

    -- modify kill_buff info.
    local altar = self:get_altar()
    if not altar then
        ERROR("update_kill_buff: get altar failed. pid = %d.", self.pid)
        return
    else
        if is_add then
            local chg = {
                ["curr_buff_id"] = buff_id,
                ["buff_over_tm"] = gTime + buff_time,
            }
            altar:set_extras(chg)
        else
            altar:clr_extras({"curr_buff_id", "buff_over_tm"})
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 校验某个英雄是否被关押在监狱中
-- Argument : self, hero_id
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_in_prison(self, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if not hero then
        ERROR("is_in_prison: get hero failed. pid = %d, hero_id = %s", self.pid, hero_id)
        return false
    else
        if hero.status ~= HERO_STATUS_TYPE.BEING_IMPRISONED then
            ERROR("is_in_prison: pid = %d, hero_id = %s, hero.status = %d.", self.pid, hero_id, hero.status)
            return false
        end
    end

    local prison = self:get_prison()
    if not prison then
        ERROR("is_in_prison: get prison failed. pid = %d.", self.pid)
        return false
    else
        for k, v in pairs(prison.extra.prisoners_info) do
            if v.hero_id == hero_id then
                return k
            end
        end

        return false
    end
end


--------------------------------------------------------------------------------
-- Function : 复活英雄
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function relive_hero(self, hero_idx)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("relive_hero: get hero failed. pid = %d, hero_idx = %d.", self.pid, hero_idx or -1)
        return
    else
        if hero.status ~= HERO_STATUS_TYPE.DEAD then
            ERROR("relive_hero: pid = %d, hero_idx = %d, hero.status(%d) ~= HERO_STATUS_TYPE.DEAD.", self.pid, hero_idx, hero.status)
            return
        end
    end

    -- 消耗资源、金币
    local cons = self:calc_relive_price(hero_idx)
    if self:dec_cons(cons, VALUE_CHANGE_REASON.RELIVE_HERO) then
        hero.status = HERO_STATUS_TYPE.FREE
    end
end


--------------------------------------------------------------------------------
-- Function : 计算复活价格
-- Argument : self, hero_id
-- Return   : {}
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_relive_price(self, hero_idx)
    -- TODO: 调试代码，扣除10个金币
    return {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, 10}}
end


--------------------------------------------------------------------------------
-- Function : 获得当前祭坛的配置信息
-- Argument : self
-- Return   : succ - {}; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_altar_conf(self)
    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar then
        ERROR("get_altar_conf: get altar failed. pid = %d", self.pid)
        return false
    end

    local conf = resmng.get_conf("prop_build", altar.propid)
    if not conf then
        ERROR("get_altar_conf: failed. pid = %d, altar.prop_build = %d", self.pid, altar.prop_build)
        return false
    end
    return conf
end


--------------------------------------------------------------------------------
-- Function : 治疗hero
-- Argument : self, hero_idx, delta_hp 血量增量
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------

--function cure_hero(self, hero_idx, delta_hp)
--    local hero = self:get_hero(hero_idx)
--    if not hero then
--        ERROR("cure_hero: get hero failed. pid = %d, hero_idx = %d", self.pid, hero_idx or -1)
--        return
--    end
--
--    if delta_hp <= 0 or (delta_hp + hero.hp) > hero.max_hp then
--        ERROR("cure_hero: pid = %d, hero_idx = %d, delta_hp = %d, hero.hp = %d, hero.max_hp= %d", self.pid, hero_idx, delta_hp, hero.hp, hero.max_hp)
--        return
--    end
--
--    -- 计算治疗费用
--    local conf = resmng.get_conf("prop_hero_cure", resmng.CURE_PRICE)
--    if not conf then
--        ERROR("cure_hero: get prop_hero_cure config failed.")
--        return
--    end
--
--    local cost = copyTab(conf.Cons)
--    for _, v in pairs(cost) do
--        v[3] = v[3] * delta_hp
--    end
--
--    if self:dec_cons(cost, VALUE_CHANGE_REASON.CURE_HERO) then
--        -- 启动定时器
--        local cure_time = self:calc_real_dura("CureSpeed", delta_hp)
--
--        hero.state = HERO_STATUS_TYPE.BEING_CURED
--        hero.tm_sn = timer.new("cure_hero", cure_time, self.pid, hero_idx, delta_hp)
--
--        LOG("cure_hero: pid = %d, hero_idx = %d, delta_hp = %d", self.pid, hero_idx, delta_hp)
--        return true
--    end
--end
--
--hero_cure(pack={{[heroid]=tohp},{[heroid]=tohp}})
--hero_cure_quick()
--hero_cure_acc_item(build_idx, item_idx, item_num)
--hero_cure_acc_gold(build_idx, acc_type)


function do_calc_hero_cure( self, hero, hp )
    print("do_calc_hero_cure", hp, hero.hp, hero.max_hp)
    if hp > hero.max_hp then return false, E_HP end
    if hp <= hero.hp then return false, E_HP end

    local pow = hero:calc_fight_power()
    local delta = ( hp - hero.hp ) / hero.max_hp
    if delta > 0 then
        food = math.ceil(25.5 * pow * delta)
        wood = math.ceil(4.5 * pow * delta)
        dura = math.ceil(pow * delta)
        return dura, { [ resmng.DEF_RES_FOOD ] = food, [ resmng.DEF_RES_FOOD ] = wood }
    end
end

function hero_cure( self, hidx, tohp )
    local hero = self:get_hero( hidx )
    if not hero then return ack( self, "hero_cure", E_NO_HERO, 0) end
    if hero.status ~= HERO_STATUS_TYPE.FREE then return ack( self, "cure_hero", resmng.E_HERO_BUSY, mode) end

    local dura, res = self:do_calc_hero_cure( hero, tohp )
    if not dura then return  ack( self, "hero_cure", E_HP, 0 )  end

    for mode, num in pairs( res ) do
        if self:get_res_num( mode ) < math.ceil( num ) then return ack( self, "cure_hero", resmng.E_NO_RES, mode) end
    end

    for mode, num in pairs( res ) do
        self:do_dec_res( mode, math.ceil( num ), VALUE_CHANGE_REASON.CURE )
    end

    hero.status = HERO_STATUS_TYPE.BEING_CURED
    hero.tmSn = timer.new( "hero_cure", dura, self.pid, hidx, tohp )
    hero.tmStart = gTime
    hero.tmOver = gTime + dura

    reply_ok(self, "hero_cure", 0)
end

function hero_cure_cancel( self, hidx )
    local hero = self:get_hero( hidx )
    if not hero then return ack( self, "hero_cure", E_NO_HERO, 0) end
    if hero.status ~= HERO_STATUS_TYPE.BEING_CURED then return end

    local tm = timer.get( hero.tmSn )
    if not tm then return end
    local tohp = tm.param[ 3 ]

    local dura, res = self:do_calc_hero_cure( hero, tohp )
    for mode, num in pairs( res ) do
        self:doObtain( resmng.CLASS_RES,  mode, num * CANCEL_BUILD_FACTOR, VALUE_CHANGE_REASON.CANCEL_ACTION )
    end
    hero.status = HERO_STATUS_TYPE.FREE
    hero.tmSn = 0
    hero.tmStart = gTime
    hero.tmOver = 0

end

function hero_cure_quick(self, hidx)
    local hero = self:get_hero( hidx )
    if not hero then return ack( self, "hero_cure", E_NO_HERO, 0) end

    if hero.status ~= HERO_STATUS_TYPE.FREE then return ack( self, "cure_hero_quick", resmng.E_HERO_BUSY, mode) end

    local tohp = hero.max_hp
    local dura, res = self:do_calc_hero_cure( hero, tohp )
    if not dura then return  ack( self, "hero_cure", E_HP, 0 )  end

    local cons = {}
    for mode, num in pairs( res ) do
        if num > 0 then table.insert( cons, { resmng.CLASS_RES, mode, num } ) end
    end

    local cons_have, cons_need_buy = self:split_cons(cons)
    local gold_need = calc_cons_value(cons_need_buy) + calc_acc_gold(dura)
    if gold_need > 0 and gold_need > self.gold then return ack(self, "cure", resmng.E_NO_RES, mode) end

    self:dec_cons(cons_have, VALUE_CHANGE_REASON.CURE, true)
    if gold_need > 0 then
        self:do_dec_res(resmng.DEF_RES_GOLD, gold_need, VALUE_CHANGE_REASON.CURE)
    end

    hero.hp = tohp
    reply_ok(self, "hero_cure_quick", 0)
end


function hero_cure_acc_item(self, hero_idx, item_idx, item_num)
    local hero = self:get_hero( hero_idx )
    if not hero then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end
    if hero.status ~= HERO_STATUS_TYPE.BEING_CURED then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end
    if not hero.tmSn then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end
    if hero.tmSn < 1 then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end

    local item = self:get_item(item_idx)
    if not item then return end
    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SPEED or conf.IsCure ~= 1 then return end
    if item[3] < item_num then return end
    
    if self:dec_item(item_idx, item_num, VALUE_CHANGE_REASON.BUILD_ACC) then
        local secs = conf.Param * item_num
        hero.tmOver = hero.tmOver - secs
        if hero.tmOver < gTime then hero.tmOver = gTime end
        timer.acc( hero.tmSn, secs )
        return reply_ok( self, "hero_cure_acc_item", 0)
    end
end


function hero_cure_acc_gold(self, hero_idx, acc_type)
    local hero = self:get_hero( hero_idx )
    if not hero then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end
    if hero.status ~= HERO_STATUS_TYPE.BEING_CURED then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end
    if not hero.tmSn then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end
    if hero.tmSn < 1 then return ack( self, "hero_cure_acc_item", E_NO_HERO, 0) end

    local secs = hero.tmOver - gTime
    if secs < 1 then return end

    if acc_type == ACC_TYPE.FREE then
        --todo
        --
    elseif acc_type == ACC_TYPE.GOLD then
        local num = calc_acc_gold( secs ) 
        if self:get_res_num(resmng.DEF_RES_GOLD) < num  then return ack( self, "hero_cure_acc_gold", E_NO_RMB) end

        self:do_dec_res(resmng.DEF_RES_GOLD, num, VALUE_CHANGE_REASON.BUILD_ACC)
        --任务
        task_logic_t.process_task(self, TASK_ACTION.GOLD_ACC, 1)
        timer.acc( hero.tmSn, secs )
        reply_ok( self, "hero_cure_acc_gold", 0)
    end
end


--------------------------------------------------------------------------------
-- Function : 取消治疗
-- Argument : self, hero_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function cancel_cure_hero(self, hero_idx)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("cancel_cure_hero: get hero failed. hero_idx = %d", hero_idx)
        return
    end

    -- 计算资源
    local node = timer.get(hero.tmSn)
    local delta_hp = node and node.param and node.param[3]
    if delta then
        ERROR("cancel_cure_hero: get delta_hp failed. pid = %d, hero_idx = %d, hero.tm_sn = %d", self.pid, hero_idx, hero.tmSn)
        hero.tmSn = 0
        return
    end

    local conf = resmng.get_conf("prop_hero_cure", resmng.CURE_PRICE)
    if not conf then
        ERROR("cure_hero: get prop_hero_cure config failed.")
        return
    end

    local cost = copyTab(conf.Cons)
    for _, v in pairs(cost) do
        v[3] = math.floor(v[3] * delta_hp * CANCEL_CURE_RETURN_RATIO)
    end

    -- 返回道具和资源
    self:inc_cons(cost, VALUE_CHANGE_REASON.CANCEL_CURE_HERO)

    -- 修改状态
    hero.tmSn = 0
    hero.status = HERO_STATUS_TYPE.FREE
end



--------------------------------------------------------------------------------
-- Function : 指定守城英雄
-- Argument : self, def_heros = {步兵英雄hero_idx, 骑兵hero_idx, 弓兵hero_idx, 车兵hero_idx}
-- Return   : NULL
-- Others   : hero_idx = 0 表示取消该类兵种英雄设置
--------------------------------------------------------------------------------
function set_def_hero(self, def_heros)
    -- check params.
    local count = {}
    for i = 1, 4 do
        local hero_idx = def_heros[i]
        if hero_idx ~= 0 then
            count[hero_idx] = (count[hero_idx] or 0) + 1
            if count[hero_idx] > 1 then
                ERROR("set_def_hero: repeated hero_idx. pid = %d, hero_idx = %d.", self.pid, hero_idx)
                dumpTab(def_heros, string.format("set_def_hero[%d]", self.pid))
                return
            end

            local hero = self:get_hero(hero_idx)
            if not hero or not hero:can_def() then
                ERROR("set_def_hero: pid = %d, hero_idx = %d, hero.status = %d.", self.pid, hero_idx, hero and hero.status or -1)
                return
            end
        end
    end

    local flag = false
    local tmp = self.def_heros
    for i = 1, 4 do
        if tmp[i] ~= def_heros[i] then
            tmp[i] = def_heros[i]
            flag = true
        end
    end
    if flag then
        self.def_heros = tmp
    end
end



----------------------------------------------------------------------------------
-- Function : return_skill_exp_item
-- Argument : self
-- Return   : NULL
-- Others   : NULL
----------------------------------------------------------------------------------
function return_skill_exp_item(self, hero, reason)
    local skills = hero.basic_skill
    local total_exp = 0
    for k, v in pairs(skills) do
        local skill_id = v[1]
        local skill_exp = v[2]
        if skill_id ~= 0 then
            local cur_lv = resmng.prop_skill[skill_id].Lv
            local exp_array = resmng.prop_hero_skill_exp[cur_lv].TotalExp
            total_exp = total_exp + (exp_array[k] + skill_exp)  --k是技能槽位
        end
    end

    local ratio = 0.8
    local return_exp = math.floor(total_exp * ratio)
    for i = 10, 1, -1 do
        local item_id = ITEM_CLASS.SKILL * 1000000 + ITEM_SKILL_MODE.COMMON_BOOK * 1000 + i
        local item = resmng.prop_item[ item_id ]
        if item then
            local grade = item.Param[2]
            local book_num = math.floor(return_exp / grade)
            if book_num > 0 then
                --self:inc_item(item_id, book_num, reason)
                self:add_bonus("mutex_award", {{"item", item_id, book_num, 10000}}, reason)
                return_exp = return_exp - book_num * grade
                if return_exp <= 0 then break end
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 释放所有俘虏
-- Argument : self
-- Return   : NULL
-- Others   : 当关押俘虏的城市被任意玩家攻破后，城内所有俘虏（包括正在被处决中的）立刻逃脱，行军返回自己的城市。
--------------------------------------------------------------------------------
function release_all_prisoner(self)
    local flag = false
    -- 监狱
    local prison = self:get_prison()
    if prison then
        if prison.extra and prison.extra.prisoners_info then
            for _, prisoner in pairs(prison.extra.prisoners_info) do
                self:release_prisoner(prisoner.id)
                print( "release hero", prisoner.id )
                flag = true
            end
        end
    end

    -- 祭坛
    local altar = self:get_altar()
    if altar then
        if altar.extra and altar.extra.kill then
            -- 释放hero
            self:let_prison_back_home(altar.extra.kill.id)

            -- 清理祭坛
            altar.state   = BUILD_STATE.WAIT
            altar.tmSn    = 0
            altar.tmStart = gTime
            altar.tmOver  = 0
            altar:clr_extra("kill")
            flag = true
        end
    end
    -- notify client.
    self:get_prisoners_info()
    return flag
end


--------------------------------------------------------------------------------
-- Function : 得到当前可出战防守的英雄
-- Argument : self
-- Return   : NULL
-- Others   : NULL 
--------------------------------------------------------------------------------

function get_defense_heros(self)
    local soldier = {0,0,0,0}
    local troop = self:get_my_troop()
    if troop then
        for _, arm in pairs( troop.arms or {} ) do
            for k, v in pairs( arm.live_soldier or {} ) do
                if v > 0 then
                    local mode = math.floor( k / 1000 )
                    soldier[ mode ] = soldier[ mode ] + v
                end
            end
        end
    end

    local ret = {0, 0, 0, 0}
    local count = 0
    local wall = self:get_wall()
    if wall then
        local hs = wall:get_extra( "hero" )
        if hs then
            for k, v in ipairs( hs ) do
                if soldier[ k ] > 0 then
                    if v ~= 0 then
                        local hero = self:get_hero( v )
                        if hero and hero:can_def() then
                            ret[ k ] = hero._id 
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    local count_soldier = 0
    for k, v in pairs( soldier ) do
        if v > 0 then count_soldier = count_soldier + 1 end
    end

    if count < count_soldier then
        -- 空缺位置，按照步、骑、弓、车顺序，选取战力高的英雄依次补齐
        count = 0
        local can_def_heros = {}
        for hero_idx, hero in pairs(self:get_hero()) do
            if not is_in_table(ret, hero._id) and hero:can_def() then
                table.insert(can_def_heros, {hero_id = hero._id, fight_power = hero.fight_power})
                count = count + 1
            end
        end

        if count > 0 then
            local func_sort = function (node_1, node_2) return node_1.fight_power > node_2.fight_power end
            table.sort(can_def_heros, func_sort)

            for mode = 1, 4, 1 do 
                if ret[ mode ] == 0 and soldier[ mode ] > 0 then
                    local t = table.remove(can_def_heros, 1)
                    ret[ mode ] = t.hero_id
                    count = count - 1
                    if count == 0 then break end
                end
            end
        end
    end
    return ret
end


function hero_onduty(self, hero, build)
    if not build then return Mark() end
    if hero.status ~= HERO_STATUS_TYPE.FREE then return Mark("hero._id=%d", hero._id) end

    local prop = resmng.get_conf("prop_build", build.propid)
    local class = prop.Class
    local mode = prop.Mode

    if build.hero_idx > 0 then
        local pre = self:get_hero(build.hero_idx) 
        if pre then
            pre.build_idx = 0
            pre.status = HERO_STATUS_TYPE.FREE
            for _, v in pairs(pre.basic_skill) do
                local id = v[1]
                if id > 0 then
                    local skill = resmng.get_conf("prop_skill", id)
                    if skill and skill.Bclass == class and (skill.Bmode == mode or skill.Bmode == 0)then
                        for _, e in pairs(skill.Effect) do
                            if e[1] == "AddBuf" then
                                build:do_rem_buf(e[2])
                            end
                        end
                    end
                end
            end
        end
        build.hero_idx = 0
    end

    for _, v in pairs(hero.basic_skill) do
        local id = v[1]
        if id > 0 then
            local skill = resmng.get_conf("prop_skill", id)
            if skill and skill.Bclass == class and (skill.Bmode == mode or skill.Bmode == 0) then
                for _, e in pairs(skill.Effect) do
                    if e[1] == "AddBuf" then
                        build:do_add_buf(e[2])
                    end
                end
            end
        end
    end

    build.hero_idx = hero.idx
    hero.build_idx = build.idx
    hero.status = HERO_STATUS_TYPE.BUILDING
    --任务
    task_logic_t.process_task(self, TASK_ACTION.HERO_STATION, 1)

    if build.state == BUILD_STATE.WORK then
        build:recalc()
        --任务
        if class == 1 then
            task_logic_t.process_task(self, TASK_ACTION.RES_OUTPUT)
        end
    end
    return true
end


function hero_offduty(self, hero)
    if hero.build_idx == 0 then return end
    local build = self:get_build(hero.build_idx)
    if not build then return end

    if build.hero_idx ~= hero.idx then return Mark("hero = %d", hero._id) end

    build.hero_idx = 0
    hero.build_idx = 0
    hero.status = HERO_STATUS_TYPE.FREE

    local prop = resmng.get_conf("prop_build", build.propid)
    local class = prop.Class
    local mode = prop.Mode
    for _, v in pairs(hero.basic_skill) do
        local id = v[1]
        if id > 0 then
            local skill = resmng.get_conf("prop_skill", id)
            if skill and skill.Bclass == class and (skill.Bmode == mode or skill.Bmode == 0) then
                for _, e in pairs(skill.Effect) do
                    if e[1] == "AddBuf" then
                        build:do_rem_buf(e[2])
                    end
                end
            end
        end
    end
    if build.state == BUILD_STATE.WORK then build:recalc() end
    return true
end


--- hero prison, new version ---
--- hero prison, new version ---
--- hero prison, new version ---

function imprison(self, hero)
    local prison = self:get_prison()
    if not prison then ERROR("imprison_hero: get prison failed. pid = %d.", self.pid) return end
    local count = prison:get_param("count")
    local time = prison:get_param("time")
    if not count or not time  then return Mark("imprison_captive") end

    local prisoners_info = prison.extra.prisoners_info

    -- 达到容量上限，释放最早俘虏的hero
    if prisoners_info then
        if #prisoners_info >= count then
            local h = prison:pullone()
            if h then
                self:release(h)
            end
        end
    end
    prison:imprison(hero, time * 60)
    self:get_prisoners_info()
    return true
end

-- for rpc
function release_prisoner(self, hero_id)
    local prison = self:get_prison()
    if prison then
        local hero = prison:release(hero_id)
        if hero then
            self:release(hero)
            self:get_prisoners_info()
        end
    end
end

-- internal use
function release(self, hero)
    hero.capturer_pid = 0
    hero.capturer_eid = 0
    hero.capturer_name = ""
    hero.capturer_x = 0
    hero.capturer_y = 0
    hero.status   = HERO_STATUS_TYPE.MOVING

    local ply = getPlayer(hero.pid)
    if ply then
        local arm = {pid=ply.pid, heros={hero._id, 0, 0, 0}}
        local troop = troop_mng.create_troop(TroopAction.HeroBack, ply, self, arm)
        troop.curx, troop.cury = get_ety_pos(self)
        troop:back()
        self:add_debug("hero in prison gone")
    end
end

function get_prisoners_info(self)
    local infos = {}

    local make_info = function(info)
        local hero = heromng.get_hero_by_uniq_id(info.id)
        if hero then
            local ply = getPlayer(hero.pid)
            if ply then
                local t = {
                    hero_id         = hero._id,
                    propid          = hero.propid,
                    star            = hero.star,
                    lv              = hero.lv,
                    fight_power     = hero.fight_power,
                    player_name     = ply.name,
                    union_name      = "",
                    player_id       = ply._id,
                    tmStart         = info.start,
                    tmOver          = info.over,
                    status          = hero.status
                }
                local union = ply:union()
                if union then t.union_name = union.name end
                return t
            end
        end
    end

    local count = 0
    local prison = self:get_prison()
    if prison then
        local ts = prison:get_extra("prisoners_info")
        if ts then
            for _, v in pairs(ts) do
                local info = make_info(v)
                if info then
                    info.status = HERO_STATUS_TYPE.BEING_IMPRISONED
                    table.insert(infos, info)
                    count = count + 1
                end
            end
        end
    end

    local altar = self:get_altar()
    if altar then
        local killing = altar:get_extra("kill")
        if killing then
            local info = make_info(killing)
            if info then 
                info.status = HERO_STATUS_TYPE.BEING_EXECUTED
                table.insert(infos, info) 
                count = count + 1
            end
        end
    end
    if count ~= self.nprison then
        self.nprison = count
        etypipe.add( self )
    end
    Rpc:on_get_prisoners_info(self, infos)
end

function get_prison_count( self )
    local count = 0
    local prison = self:get_prison()
    if prison then
        local ts = prison:get_extra("prisoners_info")
        if ts then
            for _, v in pairs(ts) do
                count = count + 1
            end
        end
    end
    local altar = self:get_altar()
    if altar then
        local info = altar:get_extra("kill")
        if info then
            count = count + 1
        end
    end
    return count
end


function kill_hero(self, hero_id, buff_idx)
    local altar = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.ALTAR)
    if not altar or altar.state ~= BUILD_STATE.WAIT then
        ERROR("kill_hero: altar not valid. pid = %d, altar.state = %d.", self.pid, altar and altar.state or -1)
        return
    end

    local conf = resmng.get_conf("prop_build", altar.propid)
    if not conf or not conf.Param then
        ERROR("kill_hero: get conf.Param failed. pid = %d", self.pid)
        return
    end

    local jail = self:get_prison()
    local hero = jail:release(hero_id)
    if not hero then return end

    local fpow = hero.fight_power
    if fpow < 1 then fpow = hero:calc_fight_power() end

    local buff_id = false
    for k, v in ipairs( resmng.prop_sacrifice_hero ) do
        if fpow <= v.FightCapacity then
            buff_id = v.Buff[ buff_idx ]
            break
        end
    end
    if not buff_id then return end

    local kill_time = conf.Param.kill_time
    local buff_time = conf.Param.buff_time

    local tmOver = gTime + kill_time
    hero.status = HERO_STATUS_TYPE.BEING_EXECUTED
    hero.tmStart = gTime
    hero.tmOver = tmOver

    altar.state   = BUILD_STATE.WORK
    altar.tmStart = gTime
    altar.tmOver  = tmOver
    altar.tmSn    = timer.new("build", kill_time, self.pid, altar.idx, tmOver, buff_id, buff_time)
    altar:set_extra("kill", {id=hero._id, start=gTime, over=tmOver})

    -- notify client.
    self:get_prisoners_info()

    -- 世界频道公告处决信息
    local hero_owner = getPlayer(hero.pid)
    if hero_owner then
        local msg = string.format("%s的英雄%s正在被%s处决!", hero_owner.name, hero.name, self.name)
        self:chat(resmng.ChatChanelEnum.World, msg)
    end
end


--------------------------------------------------------------------------------
-- Function : 使用英雄技能物品(特定技能书、通用技能书)
-- Argument : self, hero_idx, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function use_hero_skill_item(self, hero_idx, skill_idx, item_idx, num)
    -- 参数校验
    if not hero_idx or not skill_idx or not item_idx or not num or num <= 0 then
        ERROR("use_hero_skill_item: pid = %d, hero_idx = %d, skill_idx = %d, item_idx = %d, num = %d",
               self.pid or -1, hero_idx or -1, skill_idx or -1, item_idx or -1, num or -1)
        return
    end

    -- 物品类型校验
    local item = self:get_item(item_idx)
    if not item then
        ERROR("use_hero_skill_item: get_item() failed. pid = %d, item_idx = %d", self.pid or -1, item_idx)
        return
    end

    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SKILL then
        ERROR("use_hero_skill_item: not skill item. pid = %d, item_idx = %d, item_id = %d, item_class = %d",
               self.pid or -1, item_idx, item[2], conf and conf.Class or -1)
        return
    end

    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then
        ERROR("use_hero_skill_item: hero isn't valid. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    if is_in_table(ITEM_SKILL_MODE, conf.Mode) then
        --print(conf.ID, conf.Action)
        --item_func[conf.Action](self, hero_idx, skill_idx, item_idx, num, unpack(conf.Param or {}))

        local skill = hero.basic_skill[skill_idx]
        if not skill then return end

        if conf.Mode == ITEM_SKILL_MODE.SPECIAL_BOOK then
            self:use_skill_special_book( hero_idx, skill_idx, item_idx, num, unpack( conf.Param or {} ) )

        elseif conf.Mode == ITEM_SKILL_MODE.COMMON_BOOK then
            self:use_skill_common_book( hero_idx, skill_idx, item_idx, num, unpack( conf.Param or {} ) )

        end

    else
        ERROR("use_hero_skill_item: unknown item mode. item_idx = %d, item_mode = %d", item_idx, conf.Mode or -1)
    end
end


function use_skill_special_book(self, hero_idx, skill_idx, item_idx, num, skill_id, exp)
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("item_func.useHeroSkillSpecialBook: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        local skill = hero.basic_skill[skill_idx]
        if not skill then
            ERROR("item_func.useHeroSkillSpecialBook: hero._id = %s, basic_skill[%d] is still locked.", hero._id or "nil", skill_idx)
            return
        else
            local conf = resmng.get_conf("prop_skill", skill_id)
            if not conf then
                return
            end

            -- TODO: 校验 num 是否过大，超过升到顶级所需的经验值

            if conf.Class == skill_idx then
                if skill[1] == 0 then
                    -- 尚无: 首张用于获得该技能，其余用于升级
                    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                        hero:change_basic_skill(skill_idx, skill_id, 0)
                        if num > 1 then
                            hero:gain_skill_exp(skill_idx, (num - 1) * exp)
                        else
                            hero:basic_skill_changed(skill_idx)
                        end
                        LOG("item_func.useHeroSkillSpecialBook: hero._id = %s, skill_idx = %d", hero._id, skill_idx)
                    else
                        return
                    end
                elseif heromng.is_same_skill(skill[1], skill_id) then
                    -- 校验能否升级
                    if not heromng.get_next_skill(skill[1]) then
                        LOG("item_func.useHeroSkillSpecialBook: get_next_skill() failed. hero._id = %s, skill_idx = %d, skill_id = %d",
                             hero._id or "nil", skill_idx, skill[1])
                        return
                    end

                    -- 增加技能经验
                    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                        hero:gain_skill_exp(skill_idx, num * exp)
                    else
                        return
                    end
                else
                    -- 被其它技能占据，不能使用
                    ERROR("item_func.useHeroSkillSpecialBook: hero._id = %s, basic_skill[%d][1] = %d ~= skill_id = %d",
                           hero._id or "nil", skill_idx, skill[1] or -1, skill_id)
                    return
                end
            else
                -- skill_idx 与 skill_id 不匹配
                ERROR("item_func.useHeroSkillSpecialBook: pid = %d, hero_idx = %s, skill_id = %d, conf.Class(%d) ~= skill_idx(%d)",
                      self and self.pid or -1, hero_idx, skill_id, conf.Class or -1, skill_idx)
                return
            end
        end
    end
end

-- 使用英雄通用技能书
function use_skill_common_book(self, hero_idx, skill_idx, item_idx, num, skill_id, exp)
    -- skill_id === 0
    local hero = self:get_hero(hero_idx)
    if not hero then
        ERROR("item_func.useHeroSkillCommonBook: get_hero() failed. pid = %d, hero_idx = %d", self.pid or -1, hero_idx)
        return
    else
        local skill = hero.basic_skill[skill_idx]
        if not skill then
            ERROR("item_func.useHeroSkillCommonBook: hero._id = %s, basic_skill = %d is still locked.", hero._id or "nil", skill_idx)
            return
        else
            if not heromng.get_next_skill(skill[1]) then
                LOG("item_func.useHeroSkillCommonBook: get_next_skill() failed. hero._id = %s, skill_idx = %d, skill_id = %d",
                     hero._id or "nil", skill_idx, skill[1])
                return
            end

            -- 增加经验
            if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
                hero:gain_skill_exp(skill_idx, num * exp)
            end
        end
    end
end

function set_def_hero( self, h1, h2, h3, h4 )
    local t = { h1, h2, h3, h4 }
    local hs = {}
    local hit = {}
    for _, idx in pairs( t ) do
        if idx ~= 0 then
            if hit[ idx ] then return end
            local hero = self:get_hero( idx )
            if not hero then return end
            hit[ idx ] = 1
        end
    end
    local wall = self:get_wall()
    if not wall then return end
    wall:set_extra( "hero", t )
end



-- 重置技能
function reset_skill(self, hero_idx, skill_idx)
    local hero = self:get_hero(hero_idx)
    if hero == nil then
        return
    end

    local skill = hero.basic_skill[skill_idx]
    if skill == nil or skill[1] == 0 then
        return
    end

    --使用物品
    local num = self:get_item_num(RESET_SKILL_ITME)
    if num ~= 0 then
        self:dec_item(item_idx, num, VALUE_CHANGE_REASON.REASON_DEC_ITEM_RESET_SKILL)
        hero:reset_skill(skill_idx)
        return
    end

    --使用金币
    local gold = self:get_res_num(resmng.DEF_RES_GOLD)
    if gold >= RESET_SKILL_GOLD then
        self:do_dec_res(resmng.DEF_RES_GOLD, RESET_SKILL_GOLD, VALUE_CHANGE_REASON.REASON_DEC_RES_RESET_SKILL)
        hero:reset_skill(skill_idx)
    end
end
