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
    max_hp       = 0,
    fight_power  = 0,
    lv           = 1,
    exp          = 0,
    star         = 1,
    personality  = HERO_NATURE_TYPE.STRICT,
    basic_skill  = {},
    talent_skill = 0,
    quality      = HERO_QUALITY_TYPE.ORDINARY,
    nature       = HERO_NATURE_TYPE.STRICT,
    status       = HERO_STATUS_TYPE.FREE,
    culture      = CULTURE_TYPE.EAST,
    build_idx    = 0,    -- 所派遣建筑的idx
    build_last   = 0,    -- 上次所派遣建筑的idx

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
    hero:calc_fight_power()

    local player = getPlayer(pid)
    if player then
        Rpc:stateHero(player, hero._pro)
    end
    heromng.add_hero(hero)

    LOG("new: succ.")
    dumpTab( hero, "new hero" )

    return hero
end


--------------------------------------------------------------------------------
-- Function : 计算 hero 的战力，并修改 fight_power 字段
-- Argument : self
-- Return   : number
-- Others   : 英雄战斗力 = 开方[英雄最大生命*英雄攻击力/(1-英雄免伤率)] / 开方[2550]
--------------------------------------------------------------------------------
function calc_fight_power(self)
    local imm = self:calc_imm()
    local fight_power = math.floor(math.sqrt(self.max_hp * self.atk / (1 - imm)) / math.sqrt(2550))
    if fight_power ~= self.fight_power then
        self.fight_power = fight_power
    end
    return self.fight_power
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
    LOG("gain_exp: pid = %d, hero_id = %s, self.exp = %d, exp_num = %d", self.pid or -1, self._id or "nil", self.exp or -1, exp_num)
    local owner = getPlayer(self.pid)
    if owner then
        local maxlv = owner.lv
        local lv = self.lv
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
            end
        end

        self.lv = lv
        self.exp = total

        if up then
            self:up_attr()
            self:calc_fight_power()
            --任务
            task_logic_t.process_task(owner, TASK_ACTION.HERO_LEVEL_UP)
            task_logic_t.process_task(owner, TASK_ACTION.HERO_EXP, exp_num)
        end
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

    local skillid = skill[1]
    -- here use for loop, just for safe
    local exp_total = skill[2] + exp_num
    for i = 1, 20, 1 do
        local next_skill_id, exp_need = heromng.get_next_skill(skill[1])
        if not next_skill_id then break end

        if exp_total < exp_need then
            skill[2] = exp_total
            break
        else
            exp_total = exp_total - exp_need
            skill = {next_skill_id, 0}
        end
    end
    self.basic_skill[ skill_idx ] = skill
    self:basic_skill_changed( skill_idx )

    local role = getPlayer(self.pid)
    if skillid ~= skill[1] then
        --任务
        task_logic_t.process_task(role, TASK_ACTION.SUPREME_HERO_LEVEL)
        task_logic_t.process_task(role, TASK_ACTION.PROMOTE_HERO_LEVEL, (skill[1] - skillid))

        if self.status == HERO_STATUS_TYPE.BUILDING then
            local build = role:get_build(self.build_idx)
            if build and build.state == BUILD_STATE.WORK then
                build:recalc()
            end
        end
    end

    self.basic_skill = self.basic_skill
end

--function gain_skill_exp(self, skill_idx, exp_num, count)
--    if not self:is_valid() then
--        ERROR("gain_skill_exp: hero_id(%s) isn't valid.", self._id)
--        return
--    end
--
--    count = count or 0
--    if count >= #resmng.prop_hero_skill_exp then
--        ERROR("gain_skill_exp: check this function!!! It has been called %d times in a row.", count)
--        return
--    end
--
--    if not self or not skill_idx or not exp_num or type(exp_num) ~= 'number' or exp_num <= 0 then
--        ERROR("gain_skill_exp: skill_idx = %d, exp_num = %d", skill_idx or-1, exp_num or -1)
--        return
--    end
--
--    -- 能否升级
--    local skill = self.basic_skill[skill_idx]
--    if not skill then
--        ERROR("gain_skill_exp: hero._id = %s, basic_skill[%d] is still locked.", self._id or "nil", skill_idx)
--        return
--    else
--        if skill[1] == 0 then
--            ERROR("gain_skill_exp: hero._id = %s, basic_skill[%d] is still empty, should learn skill first.", self._id or "nil", skill_idx)
--            return
--        end
--    end
--
--    local next_skill_id, exp_need = heromng.get_next_skill(skill[1])
--    if not next_skill_id then
--        LOG("gain_skill_exp: get_next_skill() failed. skill_id = %d", skill[1])
--        return
--    end
--
--    if count == 0 then
--        LOG("gain_skill_exp: hero._id = %s, skill_idx = %d, exp_num = %d", self._id, skill_idx, exp_num)
--    end
--
--    -- 增加经验, 升级技能
--    local exp_total = exp_num + skill[2]
--    if exp_total < exp_need then
--        self:change_basic_skill(skill_idx, skill[1], exp_total)
--    elseif exp_total == exp_need then
--        self:change_basic_skill(skill_idx, next_skill_id, 0)
--        --任务
--        local player = getPlayer(self.pid)
--        task_logic_t.process_task(player, TASK_ACTION.SUPREME_HERO_LEVEL)
--    else
--        self:change_basic_skill(skill_idx, next_skill_id, 0)
--        --任务
--        local player = getPlayer(self.pid)
--        task_logic_t.process_task(player, TASK_ACTION.SUPREME_HERO_LEVEL)
--        if heromng.get_next_skill(next_skill_id) then
--            return self:gain_skill_exp(skill_idx, exp_total - exp_need, count + 1)
--        end
--    end
--
--    self:basic_skill_changed(skill_idx)
--end


--------------------------------------------------------------------------------
-- Function : 重置技能
-- Argument : self, skill_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function reset_skill(self, skill_idx)
    if not self:is_valid() then
        ERROR("reset_skill: hero_id(%s) isn't valid.", self._id)
        return
    end

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
            self:change_basic_skill(skill_idx, 0, 0)
            self:basic_skill_changed(skill_idx)

            -- 统计经验值
            local exp_total = skill[2]
            local curr_skill_lv = heromng.get_skill_lv(skill[1]) or -1
            for lv = 2, curr_skill_lv do
                local conf = resmng.get_conf("prop_hero_skill_exp", lv)
                if not conf then
                    ERROR("reset_skill: hero.pid = %d, hero._id = %d, lv = %d", self.pid, self._id, lv)
                    return
                end
                exp_total = exp_total + conf.NeedExp[skill_idx]
            end
            local exp_return = math.floor(exp_total * RESET_SKILL_RETURN_RATIO)
            LOG("reset_skill: hero.pid = %d, hero._id = %s, skill_idx = %d, skill_id = %d, exp_total = %d, exp_return = %d",
                 self.pid, self._id, skill_idx, skill[1], exp_total, exp_return)

            local player = getPlayer(self.pid)
            if not player then
                ERROR("reset_skill: getPlayer(%d) failed.", self.pid)
                return
            end
            player:return_exp_item(exp_return, VALUE_CHANGE_REASON.RESET_SKILL)
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
    --if not self:is_valid() and self.status ~= HERO_STATUS_TYPE.BEING_CURED  then
    --    WARN("can_lv_up: hero_id(%s) isn't valid.", self._id)
    --    return
    --end

    if not self:is_valid() then 
        WARN("can_lv_up: hero_id(%s) isn't valid.", self._id)
        return 
    end

    -- 满级
    if self.lv >= #resmng.prop_hero_lv_exp then
        return
    end

    -- TODO: 暂时不校验城主等级
    --do return true end

    -- 等级不能超过城主
    local player = getPlayer(self.pid)
    if not player then
        WARN("can_lv_up: getPlayer() failed. pid = %d", self.pid)
        return
    else
        if self.lv > player.lv then 
            WARN("can_lv_up: hero[%s], hero.lv = %d >= player.lv = %d", self._id, self.lv, player.lv)
            player:add_debug("can not lv up")
            return false 
        end

        if self.lv == player.lv then
            local exp_conf = resmng.get_conf("prop_hero_lv_exp", self.lv + 1)
            if not exp_conf then return false end
            local need = exp_conf.NeedExp[ self.quality ]
            if not need then return false end
            if self.exp >= need then 
                ERROR("can_lv_up: hero[%s], hero.lv = %d >= player.lv = %d, have=%d, need=%d", self._id, self.lv, player.lv, self.exp, need)
                player:add_debug("can not lv up")
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
    --lv = lv or self.lv
    local exp_conf = resmng.get_conf("prop_hero_lv_exp", lv)
    if not exp_conf then
        return
    end

    return exp_conf.NeedExp and exp_conf.NeedExp[self.quality]
end


--------------------------------------------------------------------------------
-- Function : 英雄升级
-- Argument : self, count(嵌套调用次数, 避免死循环)
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function lv_up(self, count)
    if not self:is_valid() then
        ERROR("lv_up: hero_id(%s) isn't valid.", self._id)
        return
    end

    count = count or 0
    -- TODO: 暂定100, 以后修正为英雄等级上限
    if count >= 100 then
        ERROR("lv_up: check this function!!! It has been called %d times in a row.", count)
        return
    end

    -- 等级限制
    if not self:can_lv_up() then
        self.exp = 0
        LOG("lv_up: hero(%s), can't lv up. clear exp.", self._id)
        return
    end

    -- 校验经验值是否足够
    local exp_need = self:get_lv_up_exp()
    if not exp_need then
        ERROR("lv_up: get_lv_up_exp() failed. self.lv = %d, self.quality = %d", self.lv, self.quality)
        return
    else
        if self.exp < exp_need then
            LOG("lv_up: hero(%s), exp not enough, have %d, need %d", self._id, self.exp, exp_need)
            return
        end
    end

    -- 扣除经验值
    self.exp = self.exp - exp_need

    -- 升级，修改属性
    self.lv = self.lv + 1
    self:up_attr()

    -- 继续升级
    return self:lv_up(count + 1)
end


--------------------------------------------------------------------------------
-- Function : 校验能否升星
-- Argument : self
-- Return   : succ - true; fail - nil
-- Others   : 满星或者达到自身星级上限不能升星
--------------------------------------------------------------------------------
function can_star_up(self)
    if not self:is_valid() then
        ERROR("can_star_up: hero_id(%s) isn't valid.", self._id)
        return
    end

    if self.star >= #resmng.prop_hero_star_up then
        return
    end

    local conf = resmng.get_conf("prop_hero_basic", self.propid)
    if not conf then
        return
    end

    if self.star >= conf.MaxStar then
        return
    else
        return true
    end
end


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
            ERROR("star_up: hero[%s], piece[%d] not enough, have %d, need %d", self._id, hero_basic_conf.PieceID, piece_have, star_up_conf.StarUpPrice)
            return
        end
    end

    -- 扣除碎片
    if not player:dec_item_by_item_id(hero_basic_conf.PieceID, star_up_conf.StarUpPrice, VALUE_CHANGE_REASON.HERO_SATR_UP) then
        ERROR("star_up: player[%s], delete piece failed, piece_id = %d, count =  %d", self.pid, hero_basic_conf.PieceID, star_up_conf.StarUpPrice)
        return
    end

    -- 升星，修改属性
    self.star = self.star + 1
    self:up_attr()

    --任务
    task_logic_t.process_task(player, TASK_ACTION.HAS_HERO_NUM)

    -- 大升星
    local old_talent_skill = self.talent_skill
    local new_talent_skill, big_star_lv = heromng.get_talent_skill(self.propid, self.star)
    print(string.format("star_up, star=%d, big_start_lv=%s, skill=%s", self.star, big_star_lv, new_talent_skill))
    if new_talent_skill and old_talent_skill ~= new_talent_skill then
        -- 解锁技能栏位
        if not self.basic_skill[big_star_lv] then
            self:change_basic_skill(big_star_lv, 0, 0)
            self:basic_skill_changed(big_star_lv)
        else
            ERROR("star_up: hero[%s], basic_skill error. big_star_lv = %d.", self._id, big_star_lv)
            doDumpTab(self.basic_skill)
        end

        -- 升级特技
        self.talent_skill = new_talent_skill
        LOG("star_up: hero[%s], new_talent_skill = %d", self._id, self.talent_skill)
    end

    self:calc_fight_power()
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

    local basic_delta = basic_conf.GrowDelta
    local quality_rate = quality_conf.GrowRate and quality_conf.GrowRate[self._type]
    local star_up_rate = star_up_conf.GrowRate and star_up_conf.GrowRate[self._type]
    if not basic_delta or not quality_rate or not star_up_rate then
        ERROR("up_attr: get data failed.")
        return
    end

    self.atk = math.ceil((basic_conf.Atk + basic_delta[1] * (self.lv - 1)) * quality_rate[1] * star_up_rate[1])
    self.def = math.ceil((basic_conf.Def + basic_delta[2] * (self.lv - 1)) * quality_rate[2] * star_up_rate[2])
    local old_max_hp = self.max_hp
    self.max_hp = math.ceil((basic_conf.HP + basic_delta[3] * (self.lv - 1)) * quality_rate[3] * star_up_rate[3])
    self.hp = self.max_hp - old_max_hp + self.hp

    LOG("up_attr: hero[%s], quality = %d, star = %d, lv = %d, atk = %d, def = %d, max_hp = %d",
         self._id, self.quality, self.star, self.lv, self.atk, self.def, self.max_hp)
end


--------------------------------------------------------------------------------
-- Function : 技能变化
-- Argument : self, skill_idx, skill_id, exp
-- Return   : NULL
-- Others   : 需要和 basic_skill_changed() 配合使用
--------------------------------------------------------------------------------
function change_basic_skill(self, skill_idx, skill_id, exp)
    if not self:is_valid() then
        ERROR("change_basic_skill: hero_id(%s) isn't valid.", self._id)
        return
    end

    if not skill_idx or not skill_id or not exp then
        ERROR("change_basic_skill: skill_idx = %d, skill_id = %d, exp = %d", skill_idx or -1, skill_id or -1, exp or -1)
        return
    end

    self.basic_skill[skill_idx] = {skill_id, exp}
    self.basic_skill = self.basic_skill

    LOG("change_basic_skill: hero._id = %s, skill_idx = %d, skill_id = %d, exp = %d", self._id, skill_idx, skill_id, exp)
    --任务
    local player = getPlayer(self.pid)
    if player ~= nil then
        task_logic_t.process_task(player, TASK_ACTION.LEARN_HERO_SKILL)
    end

    if self.status == HERO_STATUS_TYPE.BUILDING then
        local role = getPlayer(self.pid)
        if role then
            local build = role:get_build(self.build_idx)
            if build and build.state == BUILD_STATE.WORK then
                build:recalc()
            end
        end
    end
end


--------------------------------------------------------------------------------
-- Function : 技能变更后的入库和通知前端
-- Argument : self, skill_idx
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function basic_skill_changed(self, skill_idx)
    if not skill_idx then
        ERROR("basic_skill_changed: no skill_idx.")
        return
    end

    local skill = self.basic_skill[skill_idx]
    if not skill then
        ERROR("basic_skill_changed: hero._id = %s, basic_skill[%d] is still locked.", self._id, skill_idx)
        return
    else
        self.basic_skill = self.basic_skill
        local role = getPlayer( self.pid )
        if role then
            Rpc:on_basic_skill_changed(role, self.idx, skill_idx, skill[1], skill[2])
            task_logic_t.process_task(role, TASK_ACTION.SUPREME_HERO_LEVEL)
            if self.status == HERO_STATUS_TYPE.BUILDING then
                local build = role:get_build(self.build_idx)
                if build and build.state == BUILD_STATE.WORK then
                    build:recalc()
                end
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
-- Function : 重置个性
-- Argument : self
-- Return   : NULL
-- Others   : 调用处需要做道具校验和扣除
--------------------------------------------------------------------------------
function change_personality(self)
    if not self:is_valid() then
        ERROR("change_personality: hero_id(%s) isn't valid.", self._id)
        return
    end

    if not self then
        ERROR("change_personality: no self.")
        return
    end

    local nature_type = {
        HERO_NATURE_TYPE.STRICT,
        HERO_NATURE_TYPE.FEARLESS,
        HERO_NATURE_TYPE.CALM,
        HERO_NATURE_TYPE.BOLD,
    }
    table.remove(nature_type, self.personality)
    self.personality = nature_type[math.random(1, 3)]
end


--------------------------------------------------------------------------------
-- Function : 改名
-- Argument : self, new_name
-- Return   : NULL
-- Others   : 调用处需要做道具校验和扣除
--------------------------------------------------------------------------------
function rename_hero(self, new_name)
    if not self:is_valid() then
        ERROR("rename_hero: hero_id(%s) isn't valid.", self._id)
        return
    end

    if not self or not new_name then
        ERROR("rename_hero: new_name = %s.", new_name or "nil")
        return
    end

    if is_valid_name(new_name) then
        self.name = new_name
    else
        -- ERROR_CODE
        return
    end
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
-- Function : 修改当前血量
-- Argument : self, hp_ratio
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function update_hp(self, hp_ratio)
    if not self:is_valid() then
        ERROR("update_hp: hero_id(%s) isn't valid.", self._id)
        return false
    end

    if not hp_ratio or hp_ratio < 0 or hp_ratio > 1 then
        ERROR("update_hp: hp_ratio = %f, self.max_hp = %d.", hp or -1, self.max_hp)
        return false
    end

    self.hp = math.floor(hp_ratio * self.max_hp)
    LOG("update_hp: hero._id = %s, hp_ratio = %f, new hp = %d", self._id, hp_ratio, self.hp)
    print(string.format("update_hp: hero._id = %s, hp_ratio = %f, new hp = %d", self._id, hp_ratio, self.hp))
    return true
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
    WARN( "hero_is_not_valid, pid = %d, _id = %s, name = %s, status = %d", self.pid, self._id, self.name, self.status )

    return false


    --local invalid_status = {
    --    [HERO_STATUS_TYPE.BUILDING]      = true,
    --    [HERO_STATUS_TYPE.MOVING]      = true,
    --    [HERO_STATUS_TYPE.BEING_CURED]      = true,
    --    [HERO_STATUS_TYPE.BEING_CAPTURED]   = true,
    --    [HERO_STATUS_TYPE.BEING_IMPRISONED] = true,
    --    [HERO_STATUS_TYPE.BEING_EXECUTED]   = true,
    --    [HERO_STATUS_TYPE.DEAD]             = true,
    --}
    --if invalid_status[self.status] then
    --    return false
    --else
    --    return true
    --end
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


