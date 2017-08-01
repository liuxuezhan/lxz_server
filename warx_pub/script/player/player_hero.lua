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
            is_exist = hero
            break
        end
    end

    if is_exist then
        self:hero_to_chip(propid)
        return
    end

    for idx = 1, 100, 1 do
        if not hs[idx] then
            local h = hero_t.create_hero(idx, self.pid, propid)
            if h then
                self._hero[ idx ] = h
                --任务
                task_logic_t.process_task(self, TASK_ACTION.HAS_HERO_NUM)
                self:check_hero_num_ache()  -- check title ache

                local prop_hero = resmng.get_conf("prop_hero_basic", propid)
                if prop_hero.Quality >= 4 then
                    Rpc:tips({pid = -1, gid = _G.GateSid}, 2, resmng.GACHA_NOTIFY_GRADE4, {self.name, prop_hero.Name})
                    player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", resmng.GACHA_NOTIFY_GRADE4, {self.name, prop_hero.Name} )
                end
                --世界事件
                world_event.process_world_event(WORLD_EVENT_ACTION.HERO_NUM, propid)

                --运营活动
                operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.COLLECT_GRADE_HERO)
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
        WARN("call_hero_by_piece: player already have this hero. pid = %d, hero_propid = %d.", self.pid, hero_propid)
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
    end

    if not hero:is_valid() then return end

    hero:star_up()
end

--------------------------------------------------------------------------------
-- Function : 英雄升级
-- Argument : self, hero_id, item_idx, num
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function hero_lv_up(self, hero_idx, item_idx, num)
    if not hero_idx or not item_idx or not num or num <= 0 then return end

    local hero = self:get_hero(hero_idx)
    if not hero then return end

    if not hero:can_lv_up() then return end

    local item = self:get_item(item_idx)
    if not item then return end

    local conf = resmng.get_conf("prop_item", item[2])
    if not conf then return end

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

    if hero.build_idx ~= 0 then
        self:hero_offduty( hero )
        hero.build_idx = 0
    end

    if  hero.status ~= HERO_STATUS_TYPE.FREE then
        ERROR("dispatch_hero: status failed. pid = %d, hero_idx = %d, status=%d", self.pid, hero_idx, hero.status)
        return
    end

    if build.hero_idx ~= 0 then
        local ohero = self:get_hero( build.hero_idx )
        if ohero then self:hero_offduty( ohero ) end
        build.hero_idx = 0
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
        local base_exp = 0
        local conf = resmng.get_conf( "prop_hero_basic", hero.propid )
        if conf then base_exp = conf.DestroyExp end
        self:return_exp_item(exp * DESTROY_HERO_RETURN_RATIO + base_exp, VALUE_CHANGE_REASON.DESTROY_HERO)

        -- return piece
        if conf then
            local itemid = conf.PieceID
            local conf = resmng.get_conf( "prop_hero_star_up", hero.star )
            if conf then
                local itemnum = conf.Dicompose
                self:add_bonus( "mutex_award", { {"item", itemid, itemnum} }, VALUE_CHANGE_REASON.DESTROY_HERO )
            end
        end

        local wall = self:get_wall()
        if wall then
            local hs = wall:get_extra( "hero" )
            if hs then
                for k, v in pairs( hs ) do
                    if v == hero_idx then
                        hs[ k ] = 0
                        wall:set_extra( "hero", hs )
                        break
                    end
                end
            end
        end

        --运营活动
        operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.COLLECT_GRADE_HERO)
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
    timer.new("destroy_dead_hero", RELIVE_HERO_DAYS_LIMIT * 24 * 60 * 60, self.pid, hero_id)
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
function relive_hero(self, hero_idx, is_quick  )
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
    local cons = self:calc_relive_price(hero)
    if self:dec_cons(cons, VALUE_CHANGE_REASON.RELIVE_HERO) then

    elseif is_quick == 1 then
        local cons_have, cons_need_buy = self:split_cons(cons)
        local gold_need = calc_cons_value(cons_need_buy) 
        if gold_need > 0 and gold_need > self.gold then return ack( self, "relive_hero", resmng.E_NO_RES ) end

        self:dec_cons( cons_have, VALUE_CHANGE_REASON.RELIVE_HERO, true )
        if gold_need > 0 then self:do_dec_res(resmng.DEF_RES_GOLD, gold_need, VALUE_CHANGE_REASON.RELIVE_HERO) end

    else
        return
    end

    hero_t.mark_recalc( hero )
    hero.hp = hero.max_hp
    self:hero_set_free( hero )
end


--------------------------------------------------------------------------------
-- Function : 计算复活价格
-- Argument : self, hero_id
-- Return   : {}
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_relive_price(self, hero)
    local pow = hero:calc_hero_pow_body()
    return { 
        {resmng.CLASS_RES, resmng.DEF_RES_FOOD, math.ceil( 30 * pow ) }, 
        {resmng.CLASS_RES, resmng.DEF_RES_WOOD, math.ceil( 6 * pow ) }
    }
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

function do_calc_hero_cure( self, hero, hp )
    print("do_calc_hero_cure", hp, hero.hp, hero.max_hp)
    if hp > hero.max_hp then return false, E_HP end
    if hp <= hero.hp then return false, E_HP end

    local pow = hero:calc_hero_pow_body()
    local delta = ( hp - hero.hp ) / hero.max_hp
    if delta > 0 then
        local consume_rate = self:get_num( "CountConsumeCure_R" ) or 0
        consume_rate = 1 + consume_rate * 0.0001

        food = math.ceil(25.5 * pow * delta * consume_rate)
        wood = math.ceil(4.5 * pow * delta * consume_rate)
        dura = pow * delta
        dura = math.ceil( dura / ( 1 + self:get_num( "SpeedCure_R" ) * 0.0001 ) )
        return dura, { [ resmng.DEF_RES_FOOD ] = food, [ resmng.DEF_RES_WOOD ] = wood }
    end
end

function hero_cure( self, hidx, tohp )
    local hero = self:get_hero( hidx )
    if not hero then return ack( self, "hero_cure", E_NO_HERO, 0) end
    if not hero:is_valid() then ack( self, "cure_hero", resmng.E_HERO_BUSY, mode) end

    if tohp > hero.max_hp then tohp = hero.max_hp end

    local dura, res = self:do_calc_hero_cure( hero, tohp )
    if not dura then return  ack( self, "hero_cure", E_HP, 0 )  end

    for mode, num in pairs( res ) do
        if self:get_res_num( mode ) < math.ceil( num ) then return ack( self, "cure_hero", resmng.E_NO_RES, mode) end
    end

    for mode, num in pairs( res ) do
        self:do_dec_res( mode, math.ceil( num ), VALUE_CHANGE_REASON.CURE )
    end


    self:hero_offduty( hero )
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
    self:hero_set_free( hero )
    hero.tmSn = 0
    hero.tmStart = gTime
    hero.tmOver = 0

end

function hero_cure_quick(self, hidx, tohp)
    local hero = self:get_hero( hidx )
    if not hero then return ack( self, "hero_cure", E_NO_HERO, 0) end

    if not hero:is_valid() then ack( self, "cure_hero_quick", resmng.E_HERO_BUSY, mode) end

    if tohp > hero.max_hp then tohp = hero.max_hp end
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

    --任务
    task_logic_t.process_task(self, TASK_ACTION.CURE, 1, (tohp - hero.hp))

    hero.hp = tohp
    hero_t.mark_recalc( hero )
    reply_ok(self, "hero_cure_quick", 0)
end

function check_hero_num_ache(self)
    self:try_add_tit_point(resmng.ACH_NUM_HERO)
    self:try_add_tit_point(resmng.ACH_HERO_QUALITY_1)
    self:try_add_tit_point(resmng.ACH_HERO_QUALITY_2)
    self:try_add_tit_point(resmng.ACH_HERO_QUALITY_3)
    self:try_add_tit_point(resmng.ACH_HERO_QUALITY_4)
    self:try_add_tit_point(resmng.ACH_HERO_QUALITY_5)
    self:try_add_tit_point(resmng.ACH_HERO_QUALITY_6)
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
    if not conf then return end 

    if conf.Class ~= ITEM_CLASS.SPEED then return end
    if conf.Mode ~= ITEM_SPEED_MODE.CURE and conf.Mode ~= ITEM_SPEED_MODE.COMMON then return end

    if item[3] < item_num then return end
    
    if self:dec_item(item_idx, item_num, VALUE_CHANGE_REASON.BUILD_ACC) then
        local secs = conf.Param * item_num
        hero.tmStart = hero.tmStart - secs
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
    self:hero_set_free( hero )
end



--------------------------------------------------------------------------------
-- Function : 指定守城英雄
-- Argument : self, def_heros = {步兵英雄hero_idx, 骑兵hero_idx, 弓兵hero_idx, 车兵hero_idx}
-- Return   : NULL
-- Others   : hero_idx = 0 表示取消该类兵种英雄设置
--------------------------------------------------------------------------------
--function set_def_hero(self, def_heros)
--    -- check params.
--    local count = {}
--    for i = 1, 4 do
--        local hero_idx = def_heros[i]
--        if hero_idx ~= 0 then
--            count[hero_idx] = (count[hero_idx] or 0) + 1
--            if count[hero_idx] > 1 then
--                ERROR("set_def_hero: repeated hero_idx. pid = %d, hero_idx = %d.", self.pid, hero_idx)
--                dumpTab(def_heros, string.format("set_def_hero[%d]", self.pid))
--                return
--            end
--
--            local hero = self:get_hero(hero_idx)
--            if not hero or not hero:can_def() then
--                ERROR("set_def_hero: pid = %d, hero_idx = %d, hero.status = %d.", self.pid, hero_idx, hero and hero.status or -1)
--                return
--            end
--        end
--    end
--
--    local flag = false
--    local tmp = self.def_heros
--    for i = 1, 4 do
--        if tmp[i] ~= def_heros[i] then
--            tmp[i] = def_heros[i]
--            flag = true
--        end
--    end
--    if flag then
--        self.def_heros = tmp
--    end
--end



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
            local ps = copyTab( prison.extra.prisoners_info )
            for _, prisoner in pairs( ps ) do
                self:release_prisoner(prisoner.id)
                print( "release hero", prisoner.id )
                flag = true
            end
        end
    end

    -- 祭坛
    --local altar = self:get_altar()
    --if altar then
    --    if altar.extra and altar.extra.kill then
    --        -- 释放hero
    --        self:let_prison_back_home(altar.extra.kill.id)

    --        -- 清理祭坛
    --        altar.state   = BUILD_STATE.WAIT
    --        altar.tmSn    = 0
    --        altar.tmStart = gTime
    --        altar.tmOver  = 0
    --        altar:clr_extra("kill")
    --        flag = true
    --    end
    --end
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
                    local conf = resmng.get_conf( "prop_arm", k )
                    if conf then
                        local mode = conf.Mode
                        soldier[ mode ] = soldier[ mode ] + v
                    end
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

function hero_set_free( self, hero )
    hero.status = HERO_STATUS_TYPE.FREE 
    self:hero_try_onduty( hero )
end


function hero_try_onduty(self, hero)
    if hero.status ~= HERO_STATUS_TYPE.FREE then return end
    if hero.build_last == 0 then return end

    local build = self:get_build( hero.build_last )
    if not build then return end

    if build.hero_idx ~= 0 then return end
    self:hero_onduty( hero, build )
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
            if pre == hero then return end
            if pre.status == HERO_STATUS_TYPE.BUILDING then
                self:hero_offduty( pre )
            end
        end
        build.hero_idx = 0
    end
    
    build.hero_idx = hero.idx
    hero.build_idx = build.idx
    hero.build_last = build.idx
    hero.status = HERO_STATUS_TYPE.BUILDING

    --任务
    task_logic_t.process_task(self, TASK_ACTION.HERO_STATION, 1)

    if build.state == BUILD_STATE.WORK then
        build:recalc()
        if class == 1 then task_logic_t.process_task(self, TASK_ACTION.RES_OUTPUT) end
    end
    return true
end


function hero_offduty(self, hero)
    if hero.build_idx == 0 then return end
    local build = self:get_build(hero.build_idx)

    hero.build_idx = 0
    if hero.status == HERO_STATUS_TYPE.BUILDING then hero.status = HERO_STATUS_TYPE.FREE end

    if build then
        if build.hero_idx == hero.idx then
            build.hero_idx = 0
            if build.state == BUILD_STATE.WORK then build:recalc() end
        end
    end

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
        troop:settle()
        troop.curx, troop.cury = get_ety_pos(self)
        troop:back()
        hero_t.mark_recalc( hero )
    end

    self.nprison = self:get_prison_count()
    etypipe.add( self )
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
                    full_pow        = hero_t.calc_hero_pow_body( hero ),
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
                --count = count + 1
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

    fpow = hero:calc_hero_pow_body()

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
    hero.buff_idx = buff_idx
    hero.tmStart = gTime
    hero.tmOver = tmOver
    
    altar.state = BUILD_STATE.WORK
    altar.tmStart = gTime
    altar:set_extra( "count", kill_time )
    altar:recalc()

    altar:set_extra("kill", {id=hero._id, start=gTime, over=tmOver, buff_idx=buff_idx, buff_id=buff_id, buff_time=buff_time})

    -- notify client.
    self:get_prisoners_info()

    -- 世界频道公告处决信息
    local hero_owner = getPlayer(hero.pid)
    if hero_owner then
        -- local msg = string.format("%s的英雄%s正在被%s处决!", hero_owner.name, hero.name, self.name)
        -- self:chat(resmng.ChatChanelEnum.World, msg)
        local prop_hero = resmng.get_conf("prop_hero_basic", hero.propid)
        Rpc:tips({pid = -1, gid = _G.GateSid}, 2, resmng.HERO_ALTAR_NOTIFY_EXECUTE, {hero_owner.name, prop_hero.Name, self.name}) 
        player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", resmng.HERO_ALTAR_NOTIFY_EXECUTE, {hero_owner.name, prop_hero.Name, self.name}) 
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
    if not hero_idx or not skill_idx or not item_idx or not num or num <= 0 then return end
    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then return end

    -- 物品类型校验
    if num < 1 then return end
    local item = self:get_item(item_idx)
    if not item then return end
    if item[3] < num then return end

    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SKILL then return end

    if is_in_table(ITEM_SKILL_MODE, conf.Mode) then

        local skill = hero.basic_skill[skill_idx]
        if not skill then return end

        if conf.Mode == ITEM_SKILL_MODE.SPECIAL_BOOK then
            self:use_skill_special_book( hero_idx, skill_idx, item_idx, num, unpack( conf.Param or {} ) )

        elseif conf.Mode == ITEM_SKILL_MODE.COMMON_BOOK then
            self:use_skill_common_book( hero_idx, skill_idx, item_idx, num, unpack( conf.Param or {} ) )

        end
    end
end

function hero_skill_up( self, hero_idx, skill_idx, item_idx, num )
    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then return end

    if num < 1 then return end
    local item = self:get_item(item_idx)
    if not item then return end
    if item[3] < num then return end

    local conf = resmng.get_conf("prop_item" ,item[2])
    if not conf or conf.Class ~= ITEM_CLASS.SKILL then return end

    local exp = 0
    if conf.Mode == ITEM_SKILL_MODE.SPECIAL_BOOK then
        exp = conf.Param[ 2 ] * num
    elseif conf.Mode == ITEM_SKILL_MODE.COMMON_BOOK then
        exp = conf.Param[ 2 ] * num
    end

    if exp == 0 then return end

    if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
        hero:gain_skill_exp(skill_idx, exp)
    end
end


function use_skill_special_book(self, hero_idx, skill_idx, item_idx, num, skill_id, exp)
    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then return end

    local skill = hero.basic_skill[skill_idx]
    if not skill then return end

    local prop_skill = resmng.prop_skill

    local conf = prop_skill[ skill_id ]
    if not conf then return end

    if num < 1 then
        WARN( "[USE_SKILL_SPECIAL_BOOK], NUM_ERROR, num < 1, pid=%d, skill_id=%d, num=%d", self.pid, skill_id, num )
        return
    end
    
    if skill[1] == 0 then
        -- 尚无: 首张用于获得该技能，其余用于升级
        local mode = conf.Mode
        for _, v in pairs( hero.basic_skill or {} ) do
            local id = v[1]
            if id and id > 0 then
                if prop_skill[ id ] and prop_skill[ id ].Mode == mode then
                    WARN( "use_skill_special_book, pid=%d, hero_idx=%d, skill_id=%d, have = %d, same skill", self.pid, hero_idx, skill_id, id )
                    return
                end
            end
        end

        if self:dec_item(item_idx, num, VALUE_CHANGE_REASON.USE_ITEM) then
            hero:change_basic_skill(skill_idx, skill_id, 0)
            if num > 1 then hero:gain_skill_exp(skill_idx, (num - 1) * exp) end
            LOG("use_skill_common_book: pid=%d, hero._id = %s, skill_idx = %d, skill_id=%d, ", self.pid, hero._id, skill_idx, skill_id )
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
    end
end

-- 使用英雄通用技能书
function use_skill_common_book(self, hero_idx, skill_idx, item_idx, num, skill_id, exp)
    if num < 1 then 
        WARN( "[USE_SKILL_COMMOM_BOOK], NUM_ERROR, pid=%d, num=%d", self.pid, num)
        return 
    end
    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then
        WARN("use_skill_common_book: hero isn't valid. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

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
--function reset_skill(self, hero_idx, skill_idx)
--    local hero = self:get_hero( hero_idx )
--    if not hero then return end
--
--    local num = self:get_item_num(RESET_SKILL_ITME)
--    if num ~= 0 then
--        self:dec_item_by_item_id(RESET_SKILL_ITME, 1, VALUE_CHANGE_REASON.REASON_DEC_ITEM_RESET_SKILL)
--        hero:reset_skill(skill_idx)
--        return
--    end
--
--    --使用金币
--    local gold = self:get_res_num(resmng.DEF_RES_GOLD)
--    if gold >= RESET_SKILL_GOLD then
--        self:do_dec_res(resmng.DEF_RES_GOLD, RESET_SKILL_GOLD, VALUE_CHANGE_REASON.REASON_DEC_RES_RESET_SKILL)
--        hero:reset_skill(skill_idx)
--    end
--end

function reset_skill_senior(self, hero_idx, skill_idx)
    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then
        WARN("reset_skill: hero isn't valid. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    local skill = hero.basic_skill[skill_idx]
    if skill == nil or skill[1] == 0 then return end

    local skillid = skill[1]
    if skillid == 0 then return end

    --使用物品
    local num = self:get_item_num(RESET_SKILL_ITME)
    if num ~= 0 then
        self:dec_item_by_item_id(RESET_SKILL_ITME, 1, VALUE_CHANGE_REASON.REASON_DEC_ITEM_RESET_SKILL)
        hero:reset_skill(skill_idx, true)

        local conf = resmng.get_conf( "prop_skill", skillid )
        if conf then
            local itemid = conf.SkillItemID
            local item_conf = resmng.get_conf( "prop_item", itemid )
            if item_conf then
                self:inc_item( itemid, 1, VALUE_CHANGE_REASON.RESET_SKILL )
            end
        end
        return
    end
end

function reset_skill_primary(self, hero_idx, skill_idx)
    local hero = self:get_hero(hero_idx)
    if not hero or not hero:is_valid() then
        WARN("reset_skill: hero isn't valid. pid = %d, hero_idx = %d", self.pid, hero_idx)
        return
    end

    local skill = hero.basic_skill[skill_idx]
    if skill == nil or skill[1] == 0 then return end

    hero:reset_skill( skill_idx )
end


function reset_nature( self, hero_idx )
    local hero = self:get_hero( hero_idx )
    if not hero then return end

    if not hero:is_valid() then return end

    local itemid = RESET_HERO_NATURE_ITEM
    if not self:dec_item_by_item_id( itemid, 1, VALUE_CHANGE_REASON.HERO_NATURE_RESET ) then 
        local gold = get_item_price( itemid )
        if not ( gold and gold > 0 ) then return end
        if not self:dec_gold( gold, VALUE_CHANGE_REASON.HERO_NATURE_RESET ) then return end
    end

    local nature_type = {
        HERO_NATURE_TYPE.STRICT,
        HERO_NATURE_TYPE.FEARLESS,
        HERO_NATURE_TYPE.CALM,
        HERO_NATURE_TYPE.BOLD,
    }
    table.remove(nature_type, hero.personality)
    hero.personality = nature_type[math.random(1, 3)]
    --任务
    task_logic_t.process_task(self, TASK_ACTION.HERO_NATURE_RESET, hero.propid, 1)
end

