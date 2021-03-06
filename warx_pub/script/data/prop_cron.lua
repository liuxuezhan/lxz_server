module("resmng")
prop_cron = {
    {game="*", boot=nil, min="17", hour="5", day="*", month="*", wday="*", action="clean", arg={1, "hello"}},
    {game="*", boot=true, min="0", hour="0", day="*", month="*", wday="*", action="setDayStart", arg={1, "hello"}},
    {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="*", action="union_donate_summary", arg={}},
    {game="*", boot=nil, min="*", hour="*", day="*", month="*", wday="*", action="operate_activity_tick", arg={}},
    {game="*", boot=true, min="0", hour="0", day="*", month="*", wday="*", action="on_day_pass", arg={}},
   -- {game="*", boot=nil, min="0", hour="4", day="*", month="*", wday="*", action="start_tw", arg={}},
   -- {game="*", boot=nil, min="0", hour="13", day="*", month="*", wday="*", action="end_tw", arg={}},
    {game="*", boot=nil, min="0", hour="16", day="*", month="*", wday="*", action="reset_kw_mall", arg={}},
    {game="*", boot=nil, min="30", hour="23", day="*", month="*", wday="*", action="try_open_lt", arg={}},
    {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="*", action="try_open_act", arg={}},
    -- [11] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="1", action="send_boss_award", arg={}},
   -- {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="1", action="send_tw_award", arg={}},
   -- {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="1", action="send_mc_award", arg={}},
    -- [14] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="1", action="send_lt_award", arg={}},
    --{game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="5", action="cross_act_prepare", arg={}},
    {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="1", action="union_donate_week", arg={}},
    --{game="*", boot=nil, min="30", hour="13", day="*", month="*", wday="*", action="first_pre_boss_atk_city", arg={}},
    --{game="*", boot=nil, min="0", hour="14", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="15", day="*", month="*", wday="*", action="tmp_stop_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="30", hour="15", day="*", month="*", wday="*", action="prepare_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="16", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="17", day="*", month="*", wday="*", action="tmp_stop_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="30", hour="17", day="*", month="*", wday="*", action="prepare_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="18", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="19", day="*", month="*", wday="*", action="tmp_stop_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="30", hour="19", day="*", month="*", wday="*", action="prepare_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="20", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="21", day="*", month="*", wday="*", action="tmp_stop_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="30", hour="21", day="*", month="*", wday="*", action="prepare_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="22", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="23", day="*", month="*", wday="*", action="tmp_stop_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="30", hour="23", day="*", month="*", wday="*", action="prepare_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="1", day="*", month="*", wday="*", action="tmp_stop_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="30", hour="1", day="*", month="*", wday="*", action="prepare_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="2", day="*", month="*", wday="*", action="start_boss_attack_city", arg={}},
    --{game="*", boot=nil, min="0", hour="3", day="*", month="*", wday="*", action="stop_boss_attack_city", arg={}},
    {game="*", boot=nil, min="0", hour="4", day="*", month="*", wday="*", action="rem_all_mc", arg={}},
    {game="*", boot=nil, min="30", hour="23", day="*", month="*", wday="*", action="upload_gs_info", arg={}},
    {game="*", boot=true, min="0", hour="0", day="*", month="*", wday="5,1", action="operate_dice", arg={}}
}
