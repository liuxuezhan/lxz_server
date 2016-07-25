module("resmng")
prop_cron = {
    [1] = {game="*", boot=nil, min="*", hour="*", day="*", month="*", wday="*", action="cronTest", arg={1, "hello"}},
    [2] = {game="*", boot=nil, min="17", hour="5", day="*", month="*", wday="*", action="clean", arg={1, "hello"}},
    [3] = {game="*", boot=true, min="*", hour="5", day="*", month="*", wday="*", action="setDayStart", arg={1, "hello"}},
    [4] = {game="*", boot=nil, min="1", hour="5", day="*", month="*", wday="*", action="union_donate_summary", arg={}},
    [5] = {game="*", boot=true, min="1", hour="*", day="*", month="*", wday="*", action="on_day_pass", arg={}},
    [6] = {game="*", boot=nil, min="00", hour="14", day="*", month="*", wday="*", action="start_tw", arg={}},
    [7] = {game="*", boot=nil, min="00", hour="15", day="*", month="*", wday="*", action="end_tw", arg={}},
    [8] = {game="*", boot=nil, min="00", hour="00", day="*", month="*", wday="*", action="reset_kw_mall", arg={}},
}
