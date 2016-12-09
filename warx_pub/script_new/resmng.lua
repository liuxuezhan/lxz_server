module("resmng", package.seeall)

local BasePath = "data/"
do_load("reschk")
--------------------------------------------------------------------------------
do_load(BasePath .. "prop_cron")

do_load(BasePath .. "define_resource")
do_load(BasePath .. "define_arm")
do_load(BasePath .. "define_build")
do_load(BasePath .. "define_world_unit")
do_load(BasePath .. "define_buff")
do_load(BasePath .. "define_skill")
do_load(BasePath .. "define_hero_basic")
do_load(BasePath .. "define_hero_cure")
do_load(BasePath .. "define_hero_lv_exp")
do_load(BasePath .. "define_hero_quality")
do_load(BasePath .. "define_hero_skill_exp")
do_load(BasePath .. "define_hero_star_up")
do_load(BasePath .. "define_union_power")
do_load(BasePath .. "define_item")
do_load(BasePath .. "define_union_tech")
do_load(BasePath .. "define_union_donate")
do_load(BasePath .. "define_union_buildlv")
do_load(BasePath .. "define_union_task")
do_load(BasePath .. "define_union_award")
do_load(BasePath .. "define_union_mall")
do_load(BasePath .. "define_resm")
do_load(BasePath .. "define_tech")
do_load(BasePath .. "define_genius")
do_load(BasePath .. "define_task_detail")
do_load(BasePath .. "define_equip")
do_load(BasePath .. "define_online_award")
do_load(BasePath .. "define_citybuildview")
do_load(BasePath .. "define_citybuildview")
do_load(BasePath .. "define_boss_mod_by_date")
do_load(BasePath .. "define_boss_unlock")
do_load(BasePath .. "define_boss_level")
do_load(BasePath .. "define_tw_consume")
do_load(BasePath .. "define_tw_stage")
do_load(BasePath .. "define_kw_stage")
do_load(BasePath .. "define_level")
do_load(BasePath .. "define_task_daily")
do_load(BasePath .. "define_task_daily_award")
do_load(BasePath .. "define_kw_officer")
do_load(BasePath .. "define_monster_city")
do_load(BasePath .. "define_mc_stage")
do_load(BasePath .. "define_black_market")
do_load(BasePath .. "define_black_market_hot")
do_load(BasePath .. "define_black_market_hot_group")
do_load(BasePath .. "define_lt_stage")
do_load(BasePath .. "define_lt_reward")
do_load(BasePath .. "define_gacha_group")
do_load(BasePath .. "define_gacha_piont")
do_load(BasePath .. "define_gacha_gacha")
do_load(BasePath .. "define_gacha_world_limit")
do_load(BasePath .. "define_mall")
do_load(BasePath .. "define_union_god")
do_load(BasePath .. "define_language")
do_load(BasePath .. "define_open_field")
do_load(BasePath .. "define_altar_buff")
do_load(BasePath .. "define_vip")
do_load(BasePath .. "define_mall_item")
do_load(BasePath .. "define_mall_group_kw")
do_load(BasePath .. "define_mall_refresh")
do_load(BasePath .. "define_mall_group_manor")
do_load(BasePath .. "define_mall_group_monster")
do_load(BasePath .. "define_mall_group_relic")
do_load(BasePath .. "define_month_award")
do_load(BasePath .. "define_achievement_var")
do_load(BasePath .. "define_achievement")
do_load(BasePath .. "define_rank")
do_load(BasePath .. "define_mail")
do_load(BasePath .. "define_title")
do_load(BasePath .. "define_sacrifice_hero")
do_load(BasePath .. "define_kw_notify")
do_load(BasePath .. "define_boss_hero")
do_load(BasePath .. "define_language_cfg")
do_load(BasePath .. "define_lt_rank_award")
do_load(BasePath .. "define_lt_union_award")
do_load(BasePath .. "define_tw_union_rank_award")
do_load(BasePath .. "define_tw_person_rank_award")
do_load(BasePath .. "define_mc_union_rank_award")
do_load(BasePath .. "define_mc_person_rank_award")
do_load(BasePath .. "define_mc_rank_award")
do_load(BasePath .. "define_boss_rank_award")
do_load(BasePath .. "define_tw_union_consume")
do_load(BasePath .. "define_boss_notify")
do_load(BasePath .. "define_tw_notify")
do_load(BasePath .. "define_tw_declare_notify")
do_load(BasePath .. "define_kw_buff")
do_load(BasePath .. "define_kw_debuff")
do_load(BasePath .. "define_act_notify")
do_load(BasePath .. "define_damage_rate")
do_load(BasePath .. "define_flag")

do_load(BasePath .. "prop_language_cfg")
do_load(BasePath .. "prop_arm")
do_load(BasePath .. "prop_build")
do_load(BasePath .. "prop_world_unit")
do_load(BasePath .. "prop_buff")
do_load(BasePath .. "prop_effect_type")
do_load(BasePath .. "prop_skill")
do_load(BasePath .. "prop_hero_basic")
do_load(BasePath .. "prop_hero_cure")
do_load(BasePath .. "prop_hero_lv_exp")
do_load(BasePath .. "prop_hero_quality")
do_load(BasePath .. "prop_hero_skill_exp")
do_load(BasePath .. "prop_hero_star_up")
do_load(BasePath .. "prop_union_power")
do_load(BasePath .. "prop_item")
do_load(BasePath .. "prop_union_tech")
do_load(BasePath .. "prop_union_donate")
do_load(BasePath .. "prop_union_buildlv")
do_load(BasePath .. "prop_union_task")
do_load(BasePath .. "prop_union_award")
do_load(BasePath .. "prop_union_mall")
do_load(BasePath .. "prop_union_god")
do_load(BasePath .. "prop_resource")
do_load(BasePath .. "prop_resm")
do_load(BasePath .. "prop_resm_num")
do_load(BasePath .. "prop_respawn_lv")
do_load(BasePath .. "prop_respawn_tm")
do_load(BasePath .. "prop_tech")
do_load(BasePath .. "prop_genius")
do_load(BasePath .. "prop_task_detail")
do_load(BasePath .. "prop_equip")
do_load(BasePath .. "prop_online_award")
do_load(BasePath .. "prop_citybuildview")
do_load(BasePath .. "prop_boss_mod_by_date")
do_load(BasePath .. "prop_boss_unlock")
do_load(BasePath .. "prop_boss_level")
do_load(BasePath .. "prop_tw_consume")
do_load(BasePath .. "prop_tw_stage")
do_load(BasePath .. "prop_kw_stage")
do_load(BasePath .. "prop_level")
do_load(BasePath .. "prop_task_daily")
do_load(BasePath .. "prop_task_daily_award")
do_load(BasePath .. "prop_kw_officer")
do_load(BasePath .. "prop_monster_city")
do_load(BasePath .. "prop_mc_stage")
do_load(BasePath .. "prop_lt_stage")
do_load(BasePath .. "prop_lt_reward")
do_load(BasePath .. "prop_lt_union_award")
do_load(BasePath .. "prop_lt_rank_award")
do_load(BasePath .. "prop_tw_union_rank_award")
do_load(BasePath .. "prop_tw_person_rank_award")
do_load(BasePath .. "prop_mc_union_rank_award")
do_load(BasePath .. "prop_mc_person_rank_award")
do_load(BasePath .. "prop_mc_rank_award")
do_load(BasePath .. "prop_boss_rank_award")
do_load(BasePath .. "prop_tw_union_consume")
do_load(BasePath .. "prop_boss_notify")
do_load(BasePath .. "prop_tw_notify")
do_load(BasePath .. "prop_tw_declare_notify")
do_load(BasePath .. "prop_kw_buff")
do_load(BasePath .. "prop_kw_debuff")
do_load(BasePath .. "prop_act_notify")
do_load(BasePath .. "prop_damage_rate")

do_load(BasePath .. "prop_black_market")
do_load(BasePath .. "prop_black_market_hot")
do_load(BasePath .. "prop_black_market_hot_group")
do_load(BasePath .. "prop_gacha_group")
do_load(BasePath .. "prop_gacha_piont")
do_load(BasePath .. "prop_gacha_gacha")
do_load(BasePath .. "prop_gacha_world_limit")
do_load(BasePath .. "prop_mall")
do_load(BasePath .. "prop_open_field")
do_load(BasePath .. "prop_altar_buff")
do_load(BasePath .. "prop_vip")
do_load(BasePath .. "prop_mall_item")
do_load(BasePath .. "prop_mall_group_kw")
do_load(BasePath .. "prop_mall_refresh")
do_load(BasePath .. "prop_mall_group_manor")
do_load(BasePath .. "prop_mall_group_monster")
do_load(BasePath .. "prop_mall_group_relic")
do_load(BasePath .. "prop_month_award")

do_load(BasePath .. "prop_achievement_var")
do_load(BasePath .. "prop_achievement")
do_load(BasePath .. "prop_rank")
do_load(BasePath .. "prop_mail")
do_load(BasePath .. "prop_title")
do_load(BasePath .. "prop_sacrifice_hero")
do_load(BasePath .. "prop_kw_notify")
do_load(BasePath .. "prop_boss_hero")
do_load(BasePath .. "prop_flag")

do_check("prop_arm")
do_check("prop_build")
do_check("prop_buff")
do_check("prop_effect_type")
do_check("prop_skill")
do_check("prop_hero_basic")
do_check("prop_hero_cure")
do_check("prop_hero_lv_exp")
do_check("prop_hero_quality")
do_check("prop_hero_skill_exp")
do_check("prop_hero_star_up")
do_check("prop_union_power")
do_check("prop_item")
do_check("prop_union_tech")
do_check("prop_union_donate")
do_check("prop_tech")
do_check("prop_task_detail")
do_check("prop_online_award")
do_check("prop_level")
do_check("prop_task_daily")
do_check("prop_task_daily_award")
do_check("prop_gacha_group")
do_check("prop_gacha_piont")
do_check("prop_gacha_gacha")
do_check("prop_gacha_world_limit")
do_check("prop_mail")
do_check("prop_sacrifice_hero")
--------------------------------------------------------------------------------
do_load("common/define")


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Function : 根据 prop_name，index 获取配置
-- Argument : prop_name, index
-- Return   : table or nil
-- Others   : NULL
--------------------------------------------------------------------------------
function get_conf(prop_name, index)
    if not prop_name or not index then
        ERROR("get_conf: prop_name = %s, index = %s", prop_name or "nil", index or -1 .. "")
        return
    end

    local conf = resmng[prop_name] and resmng[prop_name][index]
    if not conf then
        LOG("get_conf: lost config. prop_name = %s, index = %s", prop_name or "nil", index or -1 .. "")
        return
    else
        return conf
    end
end


function init_prop_monster()
    --local ret = {
    --    ["id"]    = hero.propid,
    --    ["num"]    = hero.hp / hero.max_hp,
    --    ["hero"]   = hero._id,
    --    ["skill"]  = hero.talent_skill,
    --    ["skills"] = {},
    --    ["cul"] = hero.culture,
    --    ["per"] = hero.personality,
    --    ["prop"]   = {
    --        ["Atk"] = hero.atk,
    --        ["Hp"]  = hero.max_hp,
    --        ["Imm"] = hero:calc_imm(),
    --        ["Pow"] = hero:calc_fight_power(),
    --        ["Lv"] = hero.lv
    --    }
    --}
    --resmng.prop_boss_monster = {
    --    { ID=1, Propid=1, Lv=2, Quality=2, Star=2, Skill=20001001, Effect={Atk_R=1000, Def_R=1000}},
    --    { ID=2, Propid=2, Lv=2, Quality=2, Star=2, Skill=20001001, Effect={Atk_R=1000, Def_R=1000}},
    --    { ID=3, Propid=3, Lv=2, Quality=2, Star=2, Skill=20001001, Effect={Atk_R=1000, Def_R=1000}},
    --    { ID=4, Propid=4, Lv=2, Quality=2, Star=2, Skill=20001001, Effect={Atk_R=1000, Def_R=1000}},
    --}

    local skills = {}
    local heros = {}
    for k, v in pairs( resmng.prop_boss_hero ) do
        local basic_conf   = resmng.get_conf("prop_hero_basic", v.PropID)
        local quality_conf = resmng.get_conf("prop_hero_quality", v.Quality)
        local star_up_conf = resmng.get_conf("prop_hero_star_up", v.Star)

        if basic_conf and quality_conf and star_up_conf then
            local basic_delta = basic_conf.GrowDelta
            local quality_rate = quality_conf.GrowRate and quality_conf.GrowRate[basic_conf.Type]
            local star_up_rate = star_up_conf.GrowRate and star_up_conf.GrowRate[basic_conf.Type]
            if basic_delta and quality_rate and star_up_rate then
                local hero = { id=basic_conf.ID, num=1, hero=k, skill=v.Skill, skills=skills, cul=basic_conf.Culture, per=basic_conf.Nature, ef=v.Effect, fit_per=1 }
                local info = {}
                info.Lv = v.Lv
                info.Atk =      math.ceil((basic_conf.Atk + basic_delta[1] * (info.Lv - 1)) * quality_rate[1] * star_up_rate[1])
                info.Def =      math.ceil((basic_conf.Def + basic_delta[2] * (info.Lv - 1)) * quality_rate[2] * star_up_rate[2])
                info.Hp =       math.ceil((basic_conf.HP +  basic_delta[3] * (info.Lv - 1)) * quality_rate[3] * star_up_rate[3])
                info.Imm =      info.Def / ( info.Def + info.Lv * basic_conf.LevelParam1 + basic_conf.LevelParam2 )
                info.Pow =      math.floor( math.sqrt( info.Hp * info.Atk / ( 1 - info.Imm )) / math.sqrt( 2550 ) )

                hero.prop = info
                heros[ k ] = hero
            end
        end
    end
    resmng.prop_hero = heros
end

init_prop_monster()


