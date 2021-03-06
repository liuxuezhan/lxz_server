--------------------------------------------------------------------------------
-- Desc     : Hero manager.
-- Author   : Yang Cong
-- History  :
--     2016-1-5 14:23:51 Created
-- Copyright: Chengdu Tapenjoy Tech Co.,Ltd
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
module("heromng", package.seeall)

-- All Hero: _id => Hero
_heros = _heros or {}


--------------------------------------------------------------------------------
-- Function : 添加hero到heromng
-- Argument : hero or nil
-- Return   : NULL
-- Others   : NULL
--------------------------------------------------------------------------------
function add_hero(hero)
    if not hero then
        LOG("add_hero: no hero.")
        return
    end
    _heros[ hero._id ] = hero
end

function clear_hero_task_status()
    for _, hero in pairs(_heros or {}) do
        hero.hero_task_status = HERO_STATUS_TYPE.FREE
    end
end


--------------------------------------------------------------------------------
-- Function : 销毁hero
-- Argument : hero_id
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function destroy_hero(hero_id, no_player_check)
    if not hero_id then
        ERROR("destroy_hero: no hero_id.")
        return false
    end

    local hero = get_hero_by_uniq_id(hero_id)
    if not hero then
        ERROR("destroy_hero: get hero failed. hero_id = %d", hero_id)
        return false
    end

    hero.status = HERO_STATUS_TYPE.DESTROY
    hero_t.mark_recalc( hero )

    -- 解除领主的引用，消除数值影响
    local player = getPlayer(hero.pid)
    if player then
        player._hero[ hero.idx ] = nil
    elseif not no_player_check then
        ERROR("destroy_hero: getPlayer failed. pid = %d", hero.pid or -1)
        return false
    end

    -- 解除heromng的引用
    _heros[ hero._id ] = nil

    -- 清理缓存信息
    gPendingDelete.hero_t[ hero._id ] = 1
    INFO( "[HERO], destroy, pid=%d, heroid=%s, propid=%d", hero.pid, hero._id, hero.propid )

    return true
end


--------------------------------------------------------------------------------
-- Function : 根据唯一ID获取hero
-- Argument : hero_id
-- Return   : NULL
-- Others   : 如果要对hero进行操作, 需要自行校验hero是否属于该玩家
--------------------------------------------------------------------------------
function get_hero_by_uniq_id(hero_id)
    if hero_id then
        return _heros[ hero_id ]
    end
end


--------------------------------------------------------------------------------
-- Function : 根据 propid 和 star 查询对应特技ID和大星级
-- Argument : propid, star
-- Return   : succ - skill_id, big_star_lv; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_talent_skill(propid, star)
    if not propid or not star then
        ERROR("get_talent_skill: propid = %d, star = %d", propid or -1, star or -1)
        return
    end

    local star_up_conf = resmng.get_conf("prop_hero_star_up", star)
    if not star_up_conf then
        return
    end

    local big_star_lv = star_up_conf.StarStatus and (star_up_conf.StarStatus[1] or 0)
    local skill_id = SKILL_CLASS.TALENT * 1000000 + propid * 1000 + big_star_lv
    local skill_conf = resmng.get_conf("prop_skill", skill_id)
    if not skill_conf then
        return
    end

    return skill_id, big_star_lv
end


--------------------------------------------------------------------------------
-- Function : 根据 skill_id  返回技能等级
-- Argument : skill_id
-- Return   : skill_lv / nil
-- Others   : skill_id = Class * 10^7 + Mode * 10^4 + Lv
--------------------------------------------------------------------------------
function get_skill_lv(skill_id)
    return tonumber(string.sub(tostring(skill_id), -3, -1))
end


--------------------------------------------------------------------------------
-- Function : 根据 skill_id 返回下一等级的技能ID和升级所需经验值
-- Argument : skill_id
-- Return   : succ - next_skill_id, exp_need; fail - nil
-- Others   : skill_id = Class * 10^7 + Mode * 10^4 + Lv
--------------------------------------------------------------------------------
function get_next_skill(skill_id)
    if not skill_id then
        ERROR("get_next_skill: no skill_id.")
        return
    end

    local next_skill_id = skill_id + 1
    local skill_conf = resmng.get_conf("prop_skill", next_skill_id)
    if not skill_conf then
        return
    end

    local curr_skill_lv = get_skill_lv(skill_id)
    local exp_conf = resmng.get_conf("prop_hero_skill_exp", curr_skill_lv + 1)
    if not exp_conf then
        return
    else
        return next_skill_id, exp_conf.NeedExp[skill_conf.Class]
    end
end


--------------------------------------------------------------------------------
-- Function : 校验两个skil_id是否是同一个技能
-- Argument : skill_id_1, skill_id_2
-- Return   : true / false
-- Others   : NULL
--------------------------------------------------------------------------------
function is_same_skill(skill_id_1, skill_id_2)
    local prop_skill = resmng.prop_skill
    local conf1 = prop_skill[ skill_id_1 ]
    local conf2 = prop_skill[ skill_id_2 ]
    if conf1 and conf2 then
        return conf1.Class == conf2.Class and conf1.Mode == conf2.Mode
    end
end


--------------------------------------------------------------------------------
-- Function : 查询英雄战斗属性
-- Argument : hero_id
-- Return   : succ - table; fail - nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_fight_attr(hero_id)
    if type( hero_id ) == "number" then
        local hero = resmng.prop_hero[ hero_id ]
        if hero then
            hero.num = 1
            return hero
        end
    end

    local hero = get_hero_by_uniq_id(hero_id)
    if not hero then
        ERROR("get_fight_attr: get_hero_by_uniq_id(hero_id = %s) failed.", hero_id or -1)
        return
    else
        local pow = hero_t.calc_hero_pow_body( hero )
        local ret = {
            ["id"]    = hero.propid,
            ["num"]    = hero.hp / hero.max_hp,
            ["hero"]   = hero._id,
            ["skill"]  = hero.talent_skill,
            ["skills"] = {},
            ["cul"] = hero.culture,
            ["per"] = hero.personality,
            ["prop"]   = {
                ["Atk"] = hero.atk,
                ["Hp"]  = hero.max_hp,
                ["Imm"] = hero:calc_imm(),
                ["Pow"] = pow,
                ["Lv"] = hero.lv
            }
        }

        if hero:is_best_personality() then ret.fit_per = 1 end

        for _, skill in pairs(hero.basic_skill) do
            if skill[1] ~= 0 then
                local conf = resmng.get_conf("prop_skill", skill[1])
                if conf and conf.Type == SKILL_TYPE.FIGHT_BASIC then
                    table.insert(ret.skills, skill[1])
                end
            end
        end

        local ply = getPlayer(hero.pid)  --- add hero equip skill
        if ply then
            for _, equip_id in pairs(hero.equips or {}) do
                local equip = ply:get_hero_equip(equip_id)
                if equip then
                    local equip_conf = resmng.get_conf("prop_hero_equip", equip.propid)
                    if equip_conf then
                        local ef_list = {"Effect", "OwnerEffect"}
                        for _, v in pairs(ef_list) do
                            if equip[v] == nil or equip[v] == true then
                                --equip_conf.Effect = {10001011}
                                for _, skill_id in pairs(equip_conf[v] or {}) do
                                    local conf = resmng.get_conf("prop_skill", skill_id)
                                    if conf and conf.Type == SKILL_TYPE.FIGHT_BASIC then
                                        table.insert(ret.skills, skill_id)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return ret
    end
end

--------------------------------------------------------------------------------
-- Function : 英雄获得经验
-- Argument : hero_id, exp
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function inc_hero_exp(hero_id, exp)
    local hero = get_hero_by_uniq_id(hero_id)
    if not hero then
        ERROR("inc_hero_exp: get_hero_by_uniq_id(hero_id = %d) failed.", hero_id or -1)
        return false
    else
        return hero:gain_exp(exp)
    end
end


--------------------------------------------------------------------------------
-- Function : 英雄 src_hero_id 俘虏英雄 des_hero_id
-- Argument : src_hero_id, des_hero_id
-- Return   : succ - true; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function capture(src_hero_id, des_hero_id)
    local src_hero = get_hero_by_uniq_id(src_hero_id)
    if not src_hero then
        ERROR("capture: get src_hero failed. src_hero_id = %s.", src_hero_id or "")
        return
    end

    local des_hero = get_hero_by_uniq_id(des_hero_id)
    if not des_hero then
        ERROR("capture: get des_hero failed. des_hero_id = %s.", des_hero_id or "")
        return
    else
        INFO( "[HERO], capture, pida=%d, heroida=%s, propida=%s,  pidb=%d, heroidb=%s, propidb=%s", src_hero.pid, src_hero._id, src_hero.propid, des_hero.pid, des_hero._id, des_hero.propid )

        -- 解除俘虏派遣
        local ply = getPlayer(des_hero.pid)
        if not ply then
            ERROR("capture: get player failed, pid = %d.", des_hero.pid)
            return
        end

        local build = ply:get_build(des_hero.build_idx)
        if build then
            player_t.put_off_hero( ply, des_hero.idx )
            --ply:dispatch_hero(des_hero.build_idx, 0)
        end

        local winner = getPlayer(src_hero.pid)
        if winner then
            src_hero.prisoner = des_hero._id
            des_hero.status   = HERO_STATUS_TYPE.BEING_CAPTURED
            des_hero.capturer_pid = winner.pid
            des_hero.capturer_eid = winner.eid
            des_hero.capturer_name = winner.name
            des_hero.capturer_x = winner.x
            des_hero.capturer_y = winner.y

            --任务
            task_logic_t.process_task(winner, TASK_ACTION.CAPTIVE_HERO, 1)
        end
    end
end

