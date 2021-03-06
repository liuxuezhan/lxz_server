--------------------------------------------------------------------------------
-- Desc     : Hero
-- Author   : Yang Cong
-- History  :
--     2016-1-5 14:35:43 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--
module( "hero_t", package.seeall )

gPendingRecalcPow = gPendingRecalcPow or {}

module_class("hero_t", 
{
    _id          = 0,    -- 唯一ID
    pid          = 0,    -- 玩家ID
    propid       = 0,    -- 英雄ID，用于区分不同英雄
    name         = "",
    _type        = 0,    -- 类型：攻击、防御、血量、全能
    atk          = 0,
    def          = 0,
    hp           = 0,
    extra_atk    = 0,    -- 完成任务增加永久属性
    extra_def    = 0,
    extra_hp     = 0,
    max_hp       = 0,
    fight_power  = 0,
    lv           = 1,
    exp          = 0,
    star         = 1,
    personality  = HERO_NATURE_TYPE.STRICT,
    nature       = HERO_NATURE_TYPE.STRICT,
    basic_skill  = {},
    talent_skill = 0,
    equips       = {}, -- 英雄宝物
    bufs        = {}, -- 英雄buff
    quality      = HERO_QUALITY_TYPE.ORDINARY,
    status       = HERO_STATUS_TYPE.FREE,
    hero_task_status  = HERO_STATUS_TYPE.FREE,
    culture      = CULTURE_TYPE.EAST,
    build_idx    = 0,    -- 所派遣建筑的idx
    build_will   = 0,    -- 

    tmSn         = 0,
    tmStart      = 0,
    tmOver       = 0,
    capturer_pid = 0,    -- 捕获者
    capturer_eid = 0,    -- 捕获者
    capturer_name= "",    -- 捕获者
    capturer_x   = 0,    -- 捕获者
    capturer_y   = 0,    -- 捕获者

    prisoner     = 0,    -- 俘虏
    troop        = 0,    -- 所属部队
}
)

function create_hero(idx, pid, propid)
    if not idx or not pid or not propid then
        ERROR("new: idx= %d, pid = %d, propid = %d", idx or -1, pid or -1, propid or -1)
        return
    end

    local _id = string.format("%d_%d", idx, pid)
    local conf = resmng.get_conf("prop_hero_basic", propid)
    if not conf then
        return
    end

    local t = {
        _id          = _id,
        idx          = idx,
        pid          = pid,
        propid       = propid,
        name         = conf.Name,
        _type        = conf.Type,
        star         = conf.Star,
        lv           = 1,
        exp          = 0,
        hp           = 0,
        max_hp       = 0,
        fight_power  = 0,
        status       = HERO_STATUS_TYPE.FREE,
        quality      = conf.Quality,
        nature       = conf.Nature,
        culture      = conf.Culture,
        talent_skill = conf.TalentSkill,
        build_idx    = 0,
        tmSn         = 0,    -- timer
        capturer_pid = 0,    -- 捕获者
        capturer_eid = 0,    -- 捕获者
        capturer_name = "",    -- 捕获者
        capturer_x = 0,    -- 捕获者
        capturer_y = 0,    -- 捕获者
        prisoner     = 0,    -- 俘虏
        equips = {}, -- 装备
    }

    local skills = {}
    if #conf.BasicSkill > 0 then
        for _, skill_id in pairs(conf.BasicSkill) do
            table.insert(skills, {skill_id, 0})
        end
    end

    local conf_start_up = resmng.get_conf( "prop_hero_star_up", t.star )
    if conf_start_up then
        local slot = conf_start_up.StarStatus[ 1 ]
        local num = slot - #skills
        if num > 0 then
            for i = 1, num, 1 do
                table.insert( skills, {0,0} )
            end
        end
    end
    t.basic_skill = skills

    t.personality = math.random(HERO_NATURE_TYPE.STRICT, HERO_NATURE_TYPE.BOLD)

    -- 计算属性
    up_attr(t)
    t.hp = t.max_hp

    local hero = new(t)
    calc_fight_power( hero )

    local player = getPlayer(pid)
    if player then
        Rpc:stateHero(player, hero._pro)
        player:inc_pow( hero.fight_power )

        player:add_count( resmng.ACH_NUM_HERO, 1 )
    end

    heromng.add_hero(hero)

    INFO( "[HERO], create, pid=%d, heroid=%s, propid=%d", pid, _id, propid )
    return hero
end



function calc_hero_pow_body( self )
    local conf = resmng.get_conf("prop_hero_basic", self.propid)
    local imm = self.def / (self.def + self.lv * conf.LevelParam1 + conf.LevelParam2)
    --return math.floor(math.sqrt(self.max_hp * self.atk / (1 - imm)) / math.sqrt(2550))
    return math.sqrt(self.max_hp * self.atk / (1 - imm)) / math.sqrt(2550)
end

function calc_hero_pow_skill( self )
    local pow_skill = 0
    local pskill = resmng.prop_skill
    local conf = pskill[ self.talent_skill ]
    if conf then pow_skill = ( conf.Pow or 0 ) end

    for _, v in pairs( self.basic_skill ) do
        if v[1] ~= 0 then
            conf = pskill[ v[1] ]
            if conf then
                pow_skill = pow_skill + ( conf.Pow or 0 )
            end
        end
    end
    return math.floor( pow_skill )
end


--------------------------------------------------------------------------------
-- Function : 计算 hero 的战力，并修改 fight_power 字段
-- Argument : self
-- Return   : number
-- Others   : 英雄战斗力 = 开方[英雄最大生命*英雄攻击力/(1-英雄免伤率)] / 开方[2550]
--------------------------------------------------------------------------------
function calc_fight_power(self)
    local pow_body = calc_hero_pow_body( self ) * self.hp / self.max_hp
    local pow_skill = calc_hero_pow_skill( self )
    local pow = math.floor( pow_body + pow_skill )
    if pow ~= self.fight_power then self.fight_power = pow end
    return self.fight_power
end


function recalc_pow_hero( self )
    local old = self.fight_power 
    calc_fight_power( self )
    local new = self.fight_power

    if new ~= old then
        if self.pid >= 10000 then
            local owner = getPlayer( self.pid )
            if owner then
                if new > old then
                    owner:inc_pow( new - old )
                else
                    owner:dec_pow( old - new )
                end
            end
        end

        local build = get_build( self )
        if build then
            build_t.recalc( build )
        end
    end
end

function get_build( self )
    if self.status == HERO_STATUS_TYPE.BUILDING then
        local owner = getPlayer( self.pid )
        if owner then
            local build = owner:get_build( self.build_idx )
            if build and build.hero_idx == self.idx  then return build end
        end
    end
end

function mark_recalc( self )
    gPendingRecalcPow[ self._id ] = self
end


-- TODO: 出错处理、入库、出库处理
-- key 以字符串方式存，捞取时tonumber
function on_check_pending(db, sn, chgs)
    local idx, pid = string.match(sn, "(%d+)_(%d+)")
    local p = getPlayer(tonumber(pid))
    if p then
        chgs.idx = tonumber(idx)
        Rpc:stateHero(p, chgs)
    end

    local nodes = gPendingRecalcPow
    gPendingRecalcPow = {}
    for hid, hero in pairs( nodes or {} ) do
        recalc_pow_hero( hero )
    end
end


--------------------------------------------------------------------------------
-- Function : 返回某个英雄信息
-- Argument : self 英雄；isDetail 是否需要详细信息
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function gen_hero_info(self, is_detail)
    if not self then
        ERROR("gen_hero_info: no self.")
        return
    end

    local p = getPlayer(self.capturer_pid)     
    local t = {
        _id         = self._id,
        propid      = self.propid,
        name        = self.name,
        star        = self.star,
        lv          = self.lv,
        hp          = self.hp,
        max_hp      = self.max_hp,
        status      = self.status,
        fight_power = self.fight_power,
        capturer_eid    = self.capturer_eid,
        capturer_name   = self.capturer_name,
        capturer_x      = self.capturer_x,
        capturer_y      = self.capturer_y,
    }

    if is_detail then
        t._type        = self._type
        t.personality  = self.personality
        t.basic_skill  = self.basic_skill
        t.talent_skill = self.talent_skill
        t.atk          = self.atk or -1
        t.def          = self.def or -1
        t.exp          = self.exp or -1
        t.culture      = self.culture
        t.nature       = self.nature
        t.quality      = self.quality
        t.build_idx    = self.build_idx
    end

    return t
end

function get_ef(self)
    local ef = {}
    for _, skill in pairs(self.basic_skill) do
        local skillid = skill[1] 
        if skillid ~= 0 then
            local conf = resmng.get_conf("prop_skill", skillid)
            if conf and conf.Type == SKILL_TYPE.BUILD then
                for _, v in pairs(conf.Effect) do
                    if v[1] == "AddBuf" and v[3] == 0 then
                        local buf = resmng.get_conf("prop_buff", v[2])
                        if buf then
                            for key, val in pairs(buf.Value) do
                                ef[ key ] = (ef[key] or 0) + val
                            end
                        end
                    end
                end
            end
        end
    end

    for _, buf_id in pairs(self.bufs or {}) do
        local buf = resmng.get_conf("prop_buff", buf_id)
        if buf then
            for key, val in pairs(buf.Value) do
                ef[key] = (ef[key] or 0) + val 
            end
        end
    end

    get_all_equip_ef(self, ef)

    return ef
end

function get_ef_after_fight( self )
    local ef = {}
    for _, skill in pairs(self.basic_skill) do
        local skillid = skill[1] 
        if skillid ~= 0 then
            local conf = resmng.get_conf("prop_skill", skillid)
            if conf and conf.Type == SKILL_TYPE.FIGHT_AFTER_FIGHT then  -- skill after fight
                for _, v in pairs(conf.Effect) do
                    if v[1] == "AddBuf" and v[3] == 0 then
                        local buf = resmng.get_conf("prop_buff", v[2])
                        if buf then
                            for key, val in pairs(buf.Value) do
                                ef[ key ] = (ef[key] or 0) + val
                            end
                        end
                    end
                end
            end
        end
    end

    self:get_all_equip_ef(ef)

    return ef
end

function exp_need(self)
    local owner = getPlayer(self.pid)
    if not owner then return end

    local quality = self.quality
    local maxlv = owner.lv
    local lv = self.lv

    local need = 0
    local tab = resmng.prop_hero_lv_exp
    for idx = lv+1, maxlv+1, 1 do
        local conf = tab[ idx ]
        if not conf then break end
        need = need + conf.NeedExp[ quality ]
    end
    need = need - self.exp
    need = need - 1
    if need < 1 then need = 0 end
    return need
end


--------------------------------------------------------------------------------
-- Function : 获得经验
-- Argument : self, exp_num
-- Return   : succ - true; fail - false
-- Others   : 调用接口前需要做道具验证和扣除
--------------------------------------------------------------------------------
function gain_exp(self, exp_num)
    if not self or not exp_num or exp_num < 0 then
        ERROR("gain_exp: exp_num = %d", exp_num or -1)
        return false
    end

    -- WARNING: 因为传承时增加的经验值可能比较多，这里没做 exp_num 的上限限制
    local total = self.exp + exp_num
    INFO("[HERO], gain_exp, pid=%d, heroid=%s, propid=%s, exp=%d, exp_add=%d", self.pid or -1, self._id or "nil", self.propid, self.exp or -1, exp_num)
    local owner = getPlayer(self.pid)
    if owner then
        local maxlv = owner.lv
        local lv = self.lv
        local olv = lv
        local quality = self.quality
        local need = 0
        local up = false

        while lv <= maxlv do
            local exp_conf = resmng.get_conf("prop_hero_lv_exp", lv+1)
            if not exp_conf then break end
            local need = exp_conf.NeedExp[ quality ]
            if not need then break end
            if total < need then break end

            if lv >= maxlv then
                --if total > need then 
                --    total = need 
                --end
                break
            else
                lv = lv + 1
                total = total - need
                up = true
                INFO("[HERO], gain_exp, pid=%d, heroid=%s, propid=%s, exp=%d, exp_add=%d, lv=%d", self.pid or -1, self._id or "nil", self.propid, self.exp or -1, exp_num, lv)
            end
        end

        self.lv = lv
        self.exp = total

        if olv < 30 and lv >= 30 then owner:add_count( resmng.ACH_HERO_LEVEL_30, 1 ) end

        if up then
            local old_maxhp = self.max_hp
            self:up_attr()
            local new_maxhp = self.max_hp

            if self.status == HERO_STATUS_TYPE.BEING_CURED then
                local tm = timer.get( self.tmSn )
                if tm then
                    local tohp = tm.param[3]
                    local offset = old_maxhp - tohp
                    tohp = new_maxhp - offset
                    tm.param[3] = tohp
                    timer.mark( tm )
                end
            end

            --任务
            --task_logic_t.process_task(owner, TASK_ACTION.HERO_LEVEL_UP)
            --task_logic_t.process_task(owner, TASK_ACTION.SPECIAL_HERO_LEVEL)

        end
        task_logic_t.process_task(owner, TASK_ACTION.HERO_EXP, exp_num)


        return true
    end
end


--------------------------------------------------------------------------------
-- Function : 获得技能经验
-- Argument : self, skill_idx, exp_num, count(嵌套调用次数, 避免死循环)
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function gain_skill_exp(self, skill_idx, exp_num)
    if exp_num < 1 then return end

    local skill = self.basic_skill[ skill_idx ]
    if not skill or skill[ 1 ] == 0 then
        ERROR("gain_skill_exp: hero._id = %s, basic_skill[%d] is still locked.", self._id or "nil", skill_idx)
        return
    end

    local skill_id = skill[1]
    local skill_exp = skill[2] + exp_num

    for i = 1, 20, 1 do
        local next_skill_id, exp_need = heromng.get_next_skill( skill_id )
        if not next_skill_id then break end

        if skill_exp < exp_need then
            break
        else
            skill_exp = skill_exp - exp_need
            skill_id = next_skill_id
        end
    end

    self:change_basic_skill( skill_idx, skill_id, skill_exp )
end


--------------------------------------------------------------------------------
-- Function : 重置技能
-- Argument : self, skill_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function reset_skill(self, skill_idx, is_senior)
    if not skill_idx then
        ERROR("reset_skill: no skill_idx.")
        return
    end

    local skill = self.basic_skill[skill_idx]
    if not skill then
        ERROR("reset_skill: hero._id = %s, basic_skill[%d] is still locked.", self._id or "nil", skill_idx)
        return
    else
        if skill[1] == 0 then
            ERROR("reset_skill: hero._id = %s, basic_skill[%d] is empty.", self._id or "nil", skill_idx)
            return
        else
            local skill_id = skill[1]
            local skill_exp = skill[2]

            self:change_basic_skill(skill_idx, 0, 0)

            local ori_exp = 0
            if not is_senior then
                local prop = resmng.prop_skill[skill_id]
                if prop then
                    ori_exp = prop.ReturnExp or 0
                end
            end

            -- 统计经验值
            local curr_skill_lv = heromng.get_skill_lv( skill_id ) or -1
            for lv = 2, curr_skill_lv do
                local conf = resmng.get_conf("prop_hero_skill_exp", lv)
                if conf then
                    skill_exp = skill_exp + conf.NeedExp[skill_idx]
                else
                    ERROR("reset_skill: hero.pid = %d, hero._id = %d, lv = %d", self.pid, self._id, lv)
                end
            end
            local exp_return = math.floor(skill_exp * RESET_SKILL_RETURN_RATIO) + ori_exp
            LOG("reset_skill: hero.pid = %d, hero._id = %s, skill_idx = %d, skill_id = %d, skill_exp = %d, exp_return = %d", self.pid, self._id, skill_idx, skill_id, skill_exp, exp_return)

            local player = getPlayer(self.pid)
            if player then
                player:return_exp_item(exp_return, VALUE_CHANGE_REASON.RESET_SKILL)
            else
                ERROR("reset_skill: getPlayer(%d) failed.", self.pid)
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 校验能否升级
-- Argument : self
-- Return   : succ - true; fail - nil
-- Others   : 满级或者达到城主等级不能继续升级
--------------------------------------------------------------------------------
function can_lv_up(self)
    -- 满级
    if self.lv >= #resmng.prop_hero_lv_exp then return end

    -- 等级不能超过城主
    local player = getPlayer(self.pid)
    if not player then
        WARN("can_lv_up: getPlayer() failed. pid = %d", self.pid)
        return
    else
        if self.lv > player.lv then 
            WARN("can_lv_up: hero[%s], hero.lv = %d >= player.lv = %d", self._id, self.lv, player.lv)
            --player:add_debug("can not lv up")
            return false 
        end

        if self.lv == player.lv then
            local exp_conf = resmng.get_conf("prop_hero_lv_exp", self.lv + 1)
            if not exp_conf then return false end
            local need = exp_conf.NeedExp[ self.quality ]
            if not need then return false end
            if self.exp >= need then 
                ERROR("can_lv_up: hero[%s], hero.lv = %d >= player.lv = %d, have=%d, need=%d", self._id, self.lv, player.lv, self.exp, need)
                --player:add_debug("can not lv up")
                return false 
            end
        end
    end

    return true
end


--------------------------------------------------------------------------------
-- Function : 返回升到指定等级所需经验
-- Argument : self, lv
-- Return   : succ - need_exp; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_lv_up_exp(self, lv)
    lv = lv or self.lv + 1
    local exp_conf = resmng.get_conf("prop_hero_lv_exp", lv)
    if not exp_conf then return end
    return exp_conf.NeedExp and exp_conf.NeedExp[self.quality]
end


--------------------------------------------------------------------------------
-- Function : 校验能否升星
-- Argument : self
-- Return   : succ - true; fail - nil
-- Others   : 满星或者达到自身星级上限不能升星
--------------------------------------------------------------------------------
function can_star_up(self)
    if self.star >= #resmng.prop_hero_star_up then return end
    local conf = resmng.get_conf("prop_hero_basic", self.propid)
    if not conf then return end
    if self.star >= conf.MaxStar then return end
    return true
end

--function check_hero_lv_ache(player)
--    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_1)
--    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_2)
--    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_3)
--    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_4)
--    player:try_add_tit_point(resmng.ACH_HERO_LEVEL_5)
--end
--
--function check_hero_star_ache(player)
--    player:try_add_tit_point(resmng.ACH_HERO_STAR_1)
--    player:try_add_tit_point(resmng.ACH_HERO_STAR_2)
--    player:try_add_tit_point(resmng.ACH_HERO_STAR_3)
--    player:try_add_tit_point(resmng.ACH_HERO_STAR_4)
--    player:try_add_tit_point(resmng.ACH_HERO_STAR_5)
--    player:try_add_tit_point(resmng.ACH_HERO_STAR_6)
--end
--

--------------------------------------------------------------------------------
-- Function : 英雄升星
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function star_up(self)
    -- 能否升星
    if not self:can_star_up() then
        local hero_basic_conf = resmng.get_conf("prop_hero_basic", self.propid)
        WARN("star_up: can't star up. hero._id = %s, star = %d, max_star = %d", self._id, self.star, hero_basic_conf.MaxStar)
        return
    end

    -- { ID = xx, StarStatus = {xx,xx}, StarUpPrice = xx, GrowRate = {{1,1,1},{1,1,1},{1,1,1},{1,1,1}} }
    local star_up_conf    = resmng.get_conf("prop_hero_star_up", self.star + 1)
    local hero_basic_conf = resmng.get_conf("prop_hero_basic", self.propid)
    if not star_up_conf or not hero_basic_conf then return end

    -- 校验碎片
    local player = getPlayer(self.pid)
    if not player then
        ERROR("star_up: getPlayer() failed. hero._id = %s", self._id)
        return
    else
        local piece_have = player:get_item_num(hero_basic_conf.PieceID)
        if piece_have < star_up_conf.StarUpPrice then
            WARN("star_up: hero[%s], piece[%d] not enough, have %d, need %d", self._id, hero_basic_conf.PieceID, piece_have, star_up_conf.StarUpPrice)
            return
        end
    end

    -- 扣除碎片
    if not player:dec_item_by_item_id(hero_basic_conf.PieceID, star_up_conf.StarUpPrice, VALUE_CHANGE_REASON.HERO_SATR_UP) then
        WARN("star_up: player[%s], delete piece failed, piece_id = %d, count =  %d", self.pid, hero_basic_conf.PieceID, star_up_conf.StarUpPrice)
        return
    end

    local star_status = star_up_conf.StarStatus
    if star_status[1] == 3 and star_status[2] == 0 then player:add_count( resmng.ACH_HERO_STAR_3, 1 ) end

    -- 升星，修改属性
    self.star = self.star + 1
    self:up_attr()

    INFO( "[HERO], star_up, pid=%d, heroid=%s, propid=%s, star=%d", self.pid, self._id, self.propid, self.star )

    --任务
    --task_logic_t.process_task(player, TASK_ACTION.HAS_HERO_NUM)
    --task_logic_t.process_task(player, TASK_ACTION.SPECIAL_HERO_STAR)
    
    --check_hero_star_ache(player)  -- check title ache

    -- 大升星
    local old_talent_skill = self.talent_skill
    local new_talent_skill, big_star_lv = heromng.get_talent_skill(self.propid, self.star)
    --print(string.format("star_up, star=%d, big_start_lv=%s, skill=%s", self.star, big_star_lv, new_talent_skill))
    if new_talent_skill and old_talent_skill ~= new_talent_skill then
        -- 解锁技能栏位
        if not self.basic_skill[big_star_lv] then
            self:change_basic_skill(big_star_lv, 0, 0)
        else
            ERROR("star_up: hero[%s], basic_skill error. big_star_lv = %d.", self._id, big_star_lv)
            doDumpTab(self.basic_skill)
        end

        -- 升级特技
        self.talent_skill = new_talent_skill
        LOG("star_up: hero[%s], new_talent_skill = %d", self._id, self.talent_skill)
    end
end


--------------------------------------------------------------------------------
-- Function : 升级或者升星时调整属性
-- Argument : self
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function up_attr(self)
    -- 英雄属性=(对应初始属性+英雄对应属性成长值*英雄lv)*对应品质对应英雄类型对应属性的系数*对应星级对应英雄类型对应属性的系数
    local basic_conf   = resmng.get_conf("prop_hero_basic", self.propid)
    local quality_conf = resmng.get_conf("prop_hero_quality", self.quality)
    local star_up_conf = resmng.get_conf("prop_hero_star_up", self.star)

    if not basic_conf or not quality_conf or not star_up_conf then
        ERROR("up_attr: get conf failed. propid = %d, quality = %d, star = %d.", self.propid or -1, self.quality or -1, self.star or -1)
        return
    end

    local htype = self._type

    local basic_delta = basic_conf.GrowDelta
    local quality_rate = quality_conf.GrowRate and quality_conf.GrowRate[htype]
    local star_up_rate = star_up_conf.GrowRate and star_up_conf.GrowRate[htype]
    local star_up_abs = star_up_conf.GrowAbsolute and star_up_conf.GrowAbsolute[htype]

    if not basic_delta or not quality_rate or not star_up_rate or not star_up_abs then
        ERROR("up_attr: get delta conf failed. propid = %d, quality = %d, star = %d.", self.propid or -1, self.quality or -1, self.star or -1)
        return
    end

    local ef= get_ef(self)
    local atk = get_num_by("AtkHero_A", ef) 
    local equip_atk = get_num_by("HeroEquipAtk_A", ef)
    --local equip_atk = get_hero_equip_attr(self, "HeroEquipAtk", "a*r")
    local def = get_num_by("DefHero_A", ef)
    local equip_def = get_num_by("HeroEquipDef_A", ef)
    --local equip_def = get_hero_equip_attr(self, "HeroEquipDef", "a*r")
    local hp = get_num_by("HpHero_A", ef)
    local equip_hp = get_num_by("HeroEquipHp_A", ef)
    --local equip_hp = get_hero_equip_attr(self, "HeroEquipHp", "a*r")
    local extra_atk = self.extra_atk or 0
    local extra_def = self.extra_def or 0
    local extra_hp = self.extra_hp or 0


    self.atk = math.ceil((basic_conf.Atk + basic_delta[1] * (self.lv - 1) + star_up_abs[1]) * quality_rate[1] * star_up_rate[1]) + atk + equip_atk + extra_atk
    self.def = math.ceil((basic_conf.Def + basic_delta[2] * (self.lv - 1) + star_up_abs[2]) * quality_rate[2] * star_up_rate[2]) + def + equip_def + extra_def
    local old_max_hp = self.max_hp
    self.max_hp = math.ceil((basic_conf.HP + basic_delta[3] * (self.lv - 1) + star_up_abs[3]) * quality_rate[3] * star_up_rate[3]) + hp + equip_hp + extra_hp

    if self.hp > 0 then self.hp = self.max_hp - old_max_hp + self.hp end

    mark_recalc( self )
end

function add_attr(self, mode, val)
    if mode == "Atk" or mode == "atk" then
        self.extra_atk = self.extra_atk + val
    elseif mode == "Def" or mode == "def" then
        self.extra_def = self.extra_def + val
    elseif mode == "Hp" or mode == "HP" then
        self.extra_hp = self.extra_hp + val
    end
    self:up_attr()
end

function get_hero_equip_attr(self, what, mode)
    local ply = getPlayer(self.pid)
    if not ply then
        return 0
    end
    local num = 0
    for _, id in pairs(self.equips or {}) do
        local equip = ply:get_hero_equip(id)
        if equip then
            num = num + get_equip_attr(equip, what, mode)
        end
    end
    return num
end

function get_equip_attr(equip, what, mode)
    local ef = get_equip_ef(equip)
    local b, r, a = get_nums_by(what, ef)
    if mode == "a*r" then
        return math.floor(a * (1 + r * 0.0001))
    elseif mode == "b*r+a" then
        return math.floor(b * (1 + r * 0.0001) + a)
    elseif mode == "b" then
        return math.floor(b)
    elseif mode == "r" then
        return r * 0.0001
    elseif mode == "a" then
        return math.floor(a)
    else
        return math.floor(b * (1 + r * 0.0001) + a)
    end
end

function get_all_equip_ef(self, ef)
    local tb = ef or {}
    local ply = getPlayer(self.pid)
    if ply  then
        for _, id in pairs(self,equips or {}) do
            local equip = ply:get_hero_equip(id)
            if equip then
                get_equip_ef(equip, tb)
            end
        end
    end
    return tb
end

function get_equip_ef(equip, ef)
    local tb = ef or {}
    local prop = resmng.prop_hero_equip[equip.propid]
    if prop then
        for _, v in pairs(prop.BaseAttr or {}) do
            local attr_conf = resmng.get_conf("prop_buff", v[2])
            if attr_conf then
                local num = v[3]
                if num == 0 then
                    num = 1
                end
                for i = 1, num, 1 do
                    for k, v in pairs(attr_conf.Value) do
                        tb[k] =(tb[k] or 0) + v
                    end
                end
            end
        end
        local ef_list = {"Effect", "OwnerEffect", "GroupEffect"}
        for _, v in pairs(ef_list) do
            if equip[v] == nil or equip[v] == true then
                -- prop.Effect = {10001003, 10001004}
                if v == "GroupEffect" then
                    for _, e in pairs(prop[v] or {}) do
                        local attr_conf = resmng.get_conf("prop_buff", e[2])
                        if attr_conf then
                            local num = e[3]
                            if num == 0 then
                                num = 1
                            end
                            for i = 1, num, 1 do
                                for k, v in pairs(attr_conf.Value) do
                                    tb[k] =(tb[k] or 0) + v
                                end
                            end
                        end
                    end
                else
                    for _, skill_id in pairs(prop[v] or {}) do
                        local conf = resmng.get_conf("prop_skill", skill_id)
                        if conf then
                            for _, e in pairs(conf.Effect) do
                                if e[1] == "AddBuf" then
                                    local buf = resmng.get_conf( "prop_buff", e[2] )
                                    local num = e[3]
                                    if num == 0 then
                                        num = 1
                                    end
                                    for i = 1, num, 1 do
                                        if buf then
                                            for k, v in pairs(buf.Value) do 
                                                tb[ k ] = (tb[ k ] or 0) + v
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return tb
end

--------------------------------------------------------------------------------
-- Function : 技能变化
-- Argument : self, skill_idx, skill_id, exp
-- Return   : NULL
-- Others   : 需要和 basic_skill_changed() 配合使用
--------------------------------------------------------------------------------
function change_basic_skill(self, skill_idx, skill_id, exp)
    if not skill_idx or not skill_id or not exp then
        ERROR("change_basic_skill: skill_idx = %d, skill_id = %d, exp = %d", skill_idx or -1, skill_id or -1, exp or -1)
        return
    end

    local oskill = self.basic_skill[ skill_idx ]
    local oid = oskill and oskill[ 1 ]

    self.basic_skill[skill_idx] = {skill_id, exp}
    self.basic_skill = self.basic_skill

    INFO( "[HERO], change_basic_skill, pid=%d, heroid=%s, propid=%s, skill_idx=%d, skill_id=%d", self.pid, self._id, self.propid, skill_idx, skill_id )

    --任务
    local role = getPlayer(self.pid)
    if role ~= nil then
        Rpc:on_basic_skill_changed(role, self.idx, skill_idx, skill_id, exp )

        if not oid and skill_id == 0 then
            -- open the slot, will not change pow
        else
            mark_recalc( self )
            --role:try_add_tit_point(resmng.ACH_HERO_SKILL_1)
            --role:try_add_tit_point(resmng.ACH_HERO_SKILL_2)
            --role:try_add_tit_point(resmng.ACH_HERO_SKILL_3)
            --role:try_add_tit_point(resmng.ACH_HERO_SKILL_4)
            --role:try_add_tit_point(resmng.ACH_HERO_SKILL_5)
            --role:try_add_tit_point(resmng.ACH_HERO_SKILL_6)
        end

        if oid == 0 and skill_id ~= 0 then
            --task_logic_t.process_task(role, TASK_ACTION.LEARN_HERO_SKILL)
        end

        if oid and oid ~= 0 and skill_id ~= 0 and skill_id > oid then
            --task_logic_t.process_task(role, TASK_ACTION.SUPREME_HERO_LEVEL )
            task_logic_t.process_task(role, TASK_ACTION.PROMOTE_HERO_LEVEL, skill_id - oid)
        end

        if self.status == HERO_STATUS_TYPE.BUILDING then
            local build = role:get_build(self.build_idx)
            if build and build.state == BUILD_STATE.WORK then
                build:recalc()
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 天性和个性是否匹配
-- Argument : self
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_best_personality(self)
    if not self then
        ERROR("is_best_personality: no self.")
        return false
    end
    local conf = resmng.get_conf( "prop_hero_basic", self.propid )
    return (self.personality == conf.Nature)
end


--------------------------------------------------------------------------------
-- Function : 计算免伤
-- Argument : self
-- Return   : number
-- Others   : 英雄的免伤率=英雄防御/(英雄防御+英雄等级*系数1+系数2)
--------------------------------------------------------------------------------
function calc_imm(self)
    local conf = resmng.get_conf("prop_hero_basic", self.propid)
    local imm = self.def / (self.def + self.lv * conf.LevelParam1 + conf.LevelParam2)
    return imm
end


--------------------------------------------------------------------------------
-- Function : 计算英雄总经验值
-- Argument : self
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_total_exp(self)
    local exp_total = self.exp
    for lv = 2, self.lv do
        local exp = self:get_lv_up_exp(lv)
        if exp then
            exp_total = exp_total + exp
        else
            ERROR("calc_total_exp: get exp failed. lv = %d, quality = %d", lv, self.quality or -1)
        end
    end
    return exp_total
end


--------------------------------------------------------------------------------
-- Function : 生成城建技能buff信息
-- Argument : self
-- Return   : {buff_id_1, buff_id_2, ...}
-- Others   : NULL
--------------------------------------------------------------------------------
function gen_build_buff_info(self)
    local ret = {}
    -- INFO: 目前只有2号技能槽是城建技能，以后如果一个英雄可以有多个城建技能，这里需要调整
    local skill_id = self.basic_skill[2] and self.basic_skill[2][1] or 0

    if skill_id ~= 0 then
        local conf = resmng.get_conf("prop_skill", skill_id)
        if not conf then
            return ret
        end

        for k, v in pairs(conf.Effect) do
            if v[1] == "AddBuf" then
                table.insert(ret, v[2])
            end
        end
    end

    return ret
end


--------------------------------------------------------------------------------
-- Function : 校验英雄是否能够防守
-- Argument : self
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function can_def(self)
    local can_def_status = {
        [HERO_STATUS_TYPE.FREE]     = true,
        [HERO_STATUS_TYPE.BUILDING] = true,
    }
    return  can_def_status[self.status] and self.hp > 0
end


--------------------------------------------------------------------------------
-- Function : 校验英雄是否属于可用状态
-- Argument : self
-- Return   : true / false
-- Others   : 英雄处于被俘虏或者监禁状态时, 城主不能对其进行操作
--------------------------------------------------------------------------------
function is_valid(self)
    if self.status == HERO_STATUS_TYPE.FREE then return true end
    if self.status == HERO_STATUS_TYPE.BUILDING then return true end
    if self.status == HERO_STATUS_TYPE.BEING_CURED then return true end

    WARN( "hero_is_not_valid, pid = %d, _id = %s, name = %s, status = %d", self.pid, self._id, self.name, self.status )
    return false
end


--------------------------------------------------------------------------------
-- Function : is_valid_name
-- Argument : string
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_valid_name(name)
    if not name or type(name) ~= "string" then
        return false
    end

    -- TODO: 长度限制

    -- TODO: 非法字符

    return true
end

function try_use_equip(self, idx, equip_id)
    if not equip_id then
        return false
    end

    local ply = getPlayer(self.pid)
    if not ply then
        return
    end

    local equip = ply:get_hero_equip(equip_id)
    if not equip then
        return false
    end

    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
    if not prop_equip then
        return false
    end

    if idx ~= prop_equip.Pos then
        return false
    end

    if self.equips[idx] then
    --    return false
    end

    local equips = self.equips or {}
    equips[idx] = equip_id
    self.equips = equips

    equip.hero_id = self.idx
    equip.pos = idx
    equip.OwnerEffect = check_cond_owner(self, prop_equip)
    for _, id in pairs(self.equips or {}) do
        local eq = ply:get_hero_equip(id)
        if eq then
            local conf = resmng.prop_hero_equip[eq.propid]
            if conf then
                eq.GroupEffect = check_cond_group(self, conf) 
                if eq.propid ~= equip.propid then
                    ply:set_hero_equip(id, eq)
                end
            end
        end
    end
    self.equips = self.equips
    ply:set_hero_equip(equip_id, equip)
    self:up_attr()
    return true
end

function check_cond_owner(self, prop)
    if not prop.CondOwner then
        return false
    end
    return prop.CondOwner == self.propid
end

function check_cond_group(self, prop)
    local ply = getPlayer(self.pid)
    if not ply then
        return false
    end
    if not prop.CondGroup then
        return false
    end

    for _, v in pairs(prop.CondGroup or {}) do
        if v ~= prop.Class then
            local tag = false
            for _, equip_id in pairs(self.equips or {}) do
                local equip = ply:get_hero_equip(equip_id)
                if equip then
                    local prop_equip = resmng.get_conf("prop_hero_equip", equip.propid)
                    if prop_equip.Class == v then
                        tag = true
                    end
                end
            end
            if tag == false then
                return false
            end
        end
    end

    return true
end

function try_rem_equip(self, idx)
    local equip_id = self.equips[idx]
    if not equip_id then
        return false
    end
    local ply = getPlayer(self.pid)
    if not ply then
        return false
    end
    local equip = ply:get_hero_equip(equip_id)
    if not equip then
        return false
    end
    equip.hero_id = 0
    equip.pos = 0
    equip.OwnerEffect = nil
    equip.GroupEffect = nil
    ply:set_hero_equip(equip_id, equip)
    self.equips[idx] = nil
    for _, id in pairs(self.equips or {}) do
        local eq = ply:get_hero_equip(id)
        if eq then
            local conf = resmng.prop_hero_equip[eq.propid]
            if conf then
                eq.GroupEffect = check_cond_group(self, conf) 
                if eq.propid ~= equip.propid then
                    ply:set_hero_equip(id, eq)
                end
            end
        end
    end
    self.equips = self.equips
    self:up_attr()
    return true
end

function add_buf(self, buf_id)
    local node = resmng.get_conf("prop_buff", buf_id) 
    if node then
        local dels = {}
        local bufs = self.bufs
        if node.Mutex == 1 then  -- 互斥
            local group = node.Group
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    table.insert(dels, v)
                end
            end

        elseif node.Mutex == 2 then -- 高级替换低级
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.Lv > lv then return end
                    table.insert(dels, v)
                end
            end
        elseif node.Mutex == 3 then -- 相同的就叠加时间
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.ID == buf_id then
                        INFO( "add_buf, pid=%d, hero=%d, bufid=%d, count=%d", self.pid, self._id, buf_id, count )
                        self.bufs = bufs
                        return
                    end
                end
            end
        end

        if #dels > 0 then
            for _, v in pairs( dels ) do
                self:rem_buf( v[1], v[3] )
            end
        end
        local buf = {buf_id}
        table.insert(bufs, buf)
        self.bufs = bufs
        return buf
    end
end

function rem_buf(self, buf_id)
    local bufs = self.bufs
    for k, v in pairs(bufs or {}) do
        --v = {bufid, tmStart, tmOver}
        if v[1] == buf_id then
            table.remove(bufs, k)
            local node = resmng.prop_buff[ buf_id ]
            self.bufs = bufs
            INFO( "rem_buf, pid=%d, hero=%d, bufid=%d", self.pid, self.id, buf_id)
            return
        end
    end
end
