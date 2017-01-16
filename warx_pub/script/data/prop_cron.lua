module("resmng")
prop_cron = {
    [1] = {game="*", boot=nil, min="*", hour="*", day="*", month="*", wday="*", action="cronTest", arg={1, "hello"}},
    [2] = {game="*", boot=nil, min="17", hour="5", day="*", month="*", wday="*", action="clean", arg={1, "hello"}},
    [3] = {game="*", boot=true, min="*", hour="5", day="*", month="*", wday="*", action="setDayStart", arg={1, "hello"}},
    [4] = {game="*", boot=nil, min="1", hour="5", day="*", month="*", wday="*", action="union_donate_summary", arg={}},
    [5] = {game="*", boot=true, min="0", hour="0", day="*", month="*", wday="*", action="on_day_pass", arg={}},
    [6] = {game="*", boot=nil, min="0", hour="9", day="*", month="*", wday="*", action="start_tw", arg={}},
    [7] = {game="*", boot=nil, min="59", hour="23", day="*", month="*", wday="*", action="end_tw", arg={}},
    [8] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="*", action="reset_kw_mall", arg={}},
    [9] = {game="*", boot=nil, min="30", hour="23", day="*", month="*", wday="*", action="try_open_lt", arg={}},
    [10] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="*", action="try_start_kw", arg={}},
    [11] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="7", action="send_boss_award", arg={}},
    [12] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="7", action="send_tw_award", arg={}},
    [13] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="7", action="send_mc_award", arg={}},
    [14] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="7", action="send_lt_award", arg={}},
    [15] = {game="*", boot=nil, min="0", hour="0", day="*", month="*", wday="5", action="cross_act_prepare", arg={}},
    --[16] = {game="*", boot=true, min="30", hour="23", day="*", month="*", wday="*", action="upload_gs_info", arg={}},
}
