

require "my_tools"
json = require "json"
save_t = require "my_save"

msg_t = require "msg_t"
--------------------------------------------服务器配置--------------------------------------------------------------------------------
g_tm = os.time() --系统时间
g_cid = 1    --集群id
g_nid = 1000  --玩家id开始
g_sid = "warx1" --服务器id
g_pid = g_cid*1000*1000 --玩家角色id开始 
g_path = "test" 
g_host = "10.0.2.15"

--登录服务器
g_login={name="login1", port = 60001, multilogin = true,  db="db1", }
--分区服务器
g_game={  name = "game1", port = 60002, maxclient=3000, room ="room1", db = "db1" }

--数据库
g_db = {
    --db1={ port = 27017, },
    db1={ host = "127.0.0.1", port = 27017, },
    -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
}

PLAYER_INIT = {
    map = 0,
    tm_create = 0,
    lv = 1,
    exp = 0,

    tm_lv = 0,
    tm_lv_castle = 0,
    vip_lv = 1,
    vip_lv_old = 1,
    vip_exp = 0,
    vip_login = 0,
    vip_nlogin = 0,
    vip_gift = 0,
    build_queue = { 0 },
    photo = 1,
    name = "unknown",
    photo_url = "",
    x = 0,
    y = 0,
    eid = 0,
    pid = 0,
    uid = 0,
    rmb = 0,
    gold = 0,
    silver = 0,
    sinew = 100,
    tm_sinew = 0,
    culture = 1,
    propid = 1001,
    field = 2,
    state = 0,
    tm_login = 0,
    tm_logout = 0,
    kw_gold = 0,
    manor_gold = 0,
    relic_gold = 0,
    monster_gold = 0,

    cds = {},
    bufs = {},
    report_idx = {0,0,0},

    res={{100000,0},{100000,0},{0,0},{0,0}},

    foodUse = 0,
    foodTm = 0,
    talent = 0,
    genius = {},
    tech = {},
    my_troop_id = 0,
    busy_troop_ids = {},

    mail_sys = 0,
    mail_max = 0,
    report_gather = 0,
    report_panjun = 0,

    kwseason = 0, -- 王城战评价的期数,
    officer = 0,-- 王城战职务,
    vote_time = 0, -- 王城战投票购买时间,
    tm_union = 0, -- 进入军团的时间,

    activity = 0,  --每日任务活跃度,
    activity_box = {},  --每日活跃度箱子领取,
    daily_refresh_num = 0, --每日任务免费刷新剩余次数,
    daily_refresh_time = 0, --每日任务免费刷新时间,

    def_heros = {},  -- 守城英雄,

    online_award_on_day_pass = 0, --跨天标记,
    online_award_time = 0, --上一次在线奖励时间,
    online_award_num = 0, --在线奖励领奖进度,

    cross_time = 0, --玩家跨天时间记录,

    month_award_1st = 0,    --玩家月登陆第一次时间,
    month_award_cur = 0,    --玩家月登录最后一次时间,
    month_award_mark = 0,   --玩家月登陆签到次数,
    month_award_count = 0,  --玩家补签次数,
    month_award_round = 1,    --玩家月登陆第N轮,

    hurts = {},     -- soldiers who are waiting for cure,
    cures = {},     -- soldiers who are curing,
    lives = {},
    tm_cure = 0,     -- timer,
    cure_start = 0,     -- timer  start,
    cure_over = 0,     -- timer  over,
    cure_rate = 0,     -- CountConsumeCure_R for cure time,
    language = 10000,

    gacha_yinbi_num = 0,  --银币抽卡次数,
    gacha_yinbi_free_num = 0,  --银币抽卡免费次数,
    gacha_yinbi_cd = 0,  --银币抽卡CD,
    gacha_yinbi_index = 1,  --银币抽卡的位置,
    gacha_jinbi_num = 0,  --金币抽卡次数,
    gacha_jinbi_free_num = 0,  --金币抽卡免费次数,
    gacha_jinbi_cd = 0,  --金币抽卡CD,
    gacha_jinbi_index = 1, --金币抽卡的位置,
    gacha_hunxia_index = 1,  --魂匣抽卡的位置,
    gacha_gift = 0,  --抽卡奖励值,
    gacha_box = 0,  --抽卡奖励值箱子,

    chat_account = "", --聊天账号,
    chat_psw = "",    --聊天密码,
    gacha_yinbi_first = false,  --银币首抽,
    gacha_jinbi_first = false,  --金币首抽,
    title = 0, --称号,
    lt_time = 0, -- lt 领奖时间,
    lt_award_st = {},  --lt 领奖状态,
    ef_eid = 0,  --影响自己的奇迹,
    ef_u = {}, --飞服时使用军团buf,
    ef_ue = {}, --飞服时使用军团奇迹buf,
    cross_gs = 0, --是否跨服,
}








