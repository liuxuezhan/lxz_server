module("Protocol")
Server = {

    agent_test_struct = "int id, array struct UnionMember mems, string name",
    agent_test = "pack info, pack info1",

    firstPacket = "int server_id, pack info",
    firstPacket2 = "int sockid, int server_id, pack info",
    get_characters = "",

    --firstPacket2 = "int sockid, int source_map, string account, string pasw",
    --string mac, string idfa,string gaid,string android_id,string udid,string openudid,string imei,string ver, string pack_name, string channel, 
    --string hardware, string software, string telecomoper, string network, string width, string hight, string mem",
    login = "int pid",
    onBreak = "int sid",
    create_character = "pack info",
    change_name = "string name",
    change_language = "int language",
    sync = "int sn",

    get_lv_6_gift = "",

    union_help_add = "int tmSn",--请求军团帮助
    union_help_get = "",--获取军团帮助
    union_help_sets = "pack sns",--帮助请求
    union_help_get_detail = "",--获取军团帮助

    --just for test
    build_all = "",

    getTime = "int tag",
    reCalcFood = "",

    debugInput = "string str",

    onQryCross = "int toPid, int sn, int smap, int spid, string cmd, pack arg",
    onAckCross = "int smap, int sn, int code, pack arg",

    hello = "int pid1, int pid2, string text",
    say = "string say, int nouse",
    say1 = "string say, int nouse",

    use_item = "int idx, int num",
    use_items = "pack infos",

    buy_item = "int id, int num, int use",
    gold_to_res = "int resid, int resnum",

    search_entity = "int sn, int propid",

    material_compose = "int id, int count",
    material_compose2 = "int id, int count",
    material_decompose = "int id, int count",

    equip_forge = "int propid",
    equip_split = "int sn",
    equip_on = "int sn",
    equip_off = "int sn",

    --  聊天
    chat = "int chanelid, string word, int chatid",      --chanelId: enum in common/define/ChatChanelEnum;   word:the word you say;     chatid:聊天流水号，服务器会在onError方法中返回
    chat_report = "pack p,string reason",
    fetch_chat = "int channel,int sn,int count",
    chat_p2p = "int pid, string word",
    --chat_with_audio = "int chanelid, byte[] stream",      --TODO
    get_user_simple_info = "int pid",   --获取用户简单信息

    get_user_info = "int pid, string what", --查看别的玩家的信息

    testPack = "int i, pack p, string s",
    qryInfo = "int pid",
    loadData = "string what",
    get_buff = "string what",
    qryAround = "",

	--troop
    --
    get_eye_info_by_propid = "int propid",  --通过propid 查找
    get_eye_info = "int eid",--获取地图单位详细信息
    get_room_troop = "int rid,int pid", --获取战争的行军队列数据
    get_eid_troop = "int eid,int pid", --获取建筑的行军队列数据
	troop_go = "int action, pack dp, pack info",--发出行军队列

    troop_acc = "int tid, int ration",

    qry_troop_info = "int tid",

	--dp 包含 eid or x , y
	--info 包含 res , arms，heros
	troopx_back = "int idx",    --正常召回部队
    troopx_stdtime = "int did", --行军标准时间
    union_mass_deny = "int mid, int pid",
    union_aid_go = "int pid, pack arms, pack heros",--援助
    union_aid_count = "int pid",
    union_aid_recall = "int pid",

    -----------------------------------------------------------
    siege = "int dest_eid, pack arm",   --单独攻击
    union_mass_create = "int dest_eid, int wait_time, pack arm",   --创建集结
    union_mass_join = "int dest_eid, int dest_troop_id, pack arm",        --参与集结
    massgo = "int tid", -- 集结出发
    hold_defense = "int dest_eid, pack arm",  --驻守
    kick_hold_defense = "int tr_id, int ply_id",  --踢驻防
    support_arm = "int dest_eid, pack arm",  --士兵援助
    support_res = "int dest_eid, pack res",
    gather = "int dest_eid, pack arm",   --采集
    spy = "int dest_eid",  --采集
    camp = "int x, int y, pack arm",  -- 野外帐篷
    union_save_res = "int dest_eid, pack res",  --联盟仓库存资源
    union_get_res = "int dest_eid, pack res",  --联盟仓库取资源
    union_build = "int dest_eid, pack arm",  --联盟建造建筑

    buy_specialty = "int dest_eid, pack item",  --买特产
    confirm_specialty = "int dest_eid, pack item",  --上架特产
    cancle_specialty = "int dest_eid, pack item",  --下架特产
    troop_recall = "int dest_troop_id",  --撤回部队
    troop_cancel_mass = "int troop_id",
    -----------------------------------------------------------

    ---战争大厅
    union_battle_room_list = "",
    union_battle_room_info = "int room_id",
    union_battle_room_detail = "int room_id",
    --


    reap = "int idx",
    train = "int idx, int armid, int num, int quick",
    draft = "int idx",

    migrate = "int x, int y",
    migrate_random = "",

    --------------------------------------------------------------------------------
    -- build begin
    construct = "int x, int y, int build_propid",
    upgrade = "int idx",
    acc_build = "int build_idx, int acc_type",
    item_acc_build = "int build_idx, int item_idx, int num",
    one_key_upgrade_build = "int build_idx",
    learn_tech = "int build_idx, int tech_id, int is_quick", -- is_quick == 1, means quick learn, 
    acc_res = "int build_idx, int item_idx",
    acc_res_gold = "int build_idx",
    destroy_build = "int build_idx",
    build_action_cancel = "int build_idx",
    wall_repair = "int mode", -- 0, free; 1 use gold
    wall_outfire = "",

    set_def_hero = "int h1, int h2, int h3, int h4",


    -- build end.
    --------------------------------------------------------------------------------

    --geniusDo = "int id",
    do_genius = "int id",
    reset_genius = "int mode", 

    launch_talent_skill = "int geniusID",

    -- mail
    --mail_load = "int class, int id, int is_new",
    mail_load = "int idx",
    mail_load_by_idx = "pack ids",  -- idx s
    mail_read_by_sn = "pack sns",
    mail_drop_by_sn = "pack sns",
    mail_fetch_by_sn ="pack sns",
    mail_lock_by_sn = "pack sns",
    mail_unlock_by_sn= "pack sns",
    mail_send_player = "int to_player_id, string title, string content",
    mail_send_union = "string title, string content",--发送军团邮件

    mail_read_by_class = "int class, int mode, int lv",
    mail_drop_by_class = "int class, int mode, int lv",

    -- todo, just for test
    test_mail_all = "int class, string title, string content, pack its",

    -- roi
    addEye = "int x,int y",
    remEye = "",
    movEye = "int map, int x, int y",
    agent_move_eye = "int pid, int x, int y",
    agent_remove_eye = "int pid",
    ack_tool = "int sn, pack info",
    gm_cmd = "string callback_pid, string gm_type, pack content",
    -- ply change gs
    ply_change_server = "int map, int x, int y",
    change_server = "int map, int x, int y, pack data, pack timers, pack union_pro, pack troop, pack mails",
    change_server_ack = "int map, int pid, int param",
    -- cross gs
    agent_migrate = "int map, int x, int y, pack data, pack timers, pack union_pro, pack troop, pack mails",
    agent_migrate_ack = "int map, int pid, int param",
    agent_migrate_back = "int map, int x, int y, pack data, pack timers, pack union_pro, pack troop, pack todos, pack mails",
    agent_migrate_back_ack = "int map, int pid, int param",
    agent_syn_call = "int id, string func, pack arg",
    agent_syn_call_ack = "int id, pack ret",
    agent_login = "int pid, pack info",
    cross_act_ntf = "int ntf_id, pack param1, pack param2",
    cross_npc_info_req = "int pid",  -- gs to cross mng
    cross_act_st_cast = "pack info",
    --cross act
    upload_gs_info = "pack info",
    --upload_union_info = "pack info",
    cross_gm = "pack info",
    refugee_occu_change = "int pid, int mode, pack info",
    refugee_end = "", -- refugee act end
    post_cross_score = "pack info",
    cross_act_st_req = "",
    upload_act_score = "int action, int val, pack info",
    send_cross_award = "int mode, int reward_mode, int id, pack award , pack param",

    -- allience
    -- tech = {info={{idx,id,exp,tmOver},{...}},mark={idx,idx}}
    -- donate = {tmOver,flag}
    union_load = "string what",      
    --[[
        "info","ply","member","apply","mass",
        "aid","tech","donate","fight","build",
        "mall","item","word","relation","mars","enlist","union_donate","ef"
    --]]
    union_get = "string what,int uid",     
    union_search = "string name ",     --搜索玩家
    union_relation_set = "int uid,int type",  -- 设置军团外交关系 
    union_create = "string name, string alias, int language, int mars", --创建军团
    union_god_add = "int mode",        --膜拜战神
    union_god_get = "",                --领取战神升级奖励
    union_rm_member = "int pid",        --踢人
    union_add_member = "int pid",       --同意申请
    union_quit = "",                    --主动退出联盟
    union_destory = "",
    union_enlist_set = "int check,string text,int lv,int pow",   --设置招募规则
    union_list = "string name",         --获取军团列表
    union_list2 = "",         --推荐军团列表
    union_apply = "int uid",            --申请加入
    union_reject = "int pid",            --拒绝申请

    union_invite_migrate = "pack info",--邀请迁城 

    union_invite = "int pid",           --邀请加入
    union_accept_invite = "int unionId", --同意邀请
    union_reject_invite = "int uid",     --拒绝邀请

    union_set_note_in = "string what",  --设置军团对内公告

    union_troop_buf = "",              -- 激活军团总动员
    union_tech_info = "int idx",            --科技详细信息
    union_tech_upgrade = "int idx",         --科技升级
    union_tech_mark = "pack info",          --设置新的优先标记
    union_donate = "int idx, int type",     --科技捐献
    union_donate_clear = "",                --清除科技捐献冷却时间
    union_buildlv_donate = "int mode",       --建筑捐献
    union_log = "int idx, string mode",        --获取联盟日志
    union_donate_rank = "int what",         --捐献排名
    union_ply_rank_req = "int mode",           -- 军团内玩家排名
    union_mall_add = "int propid,int num",   --军团长采购道具
    union_mall_mark = "int propid,int flag",  --军团成员标记要买的道具
    union_mall_buy = "int propid,int num",    --军团成员买道具
    union_item_get = "int idx",                --领取军团礼物
    union_mall_log = "int type",              --获取军团商店的日志  1:进货日志 2:购买日志
    union_member_rank = "int pid, int r",   --设置军阶
    union_member_title = "int pid, string t",   --设置头衔
    union_leader_update="int pid",--移交军团长

    union_build_setup = "int idx, int propid, int x, int y,string name",--放置军团建筑
    union_build_remove = "int eid", --拆除大地图建筑
    union_build_up = "int idx,int state",     --扩建军团建筑
    union_task_add = "int type,int eid,string hero_id,int task_num,int mode,int res,int res_num, int x, int y",--发布悬赏任务
    union_task_get = "",     --获取军团悬赏任务
    union_mission_get = "",     --获取军团定时任务
    union_mission_update = "",     --刷新军团定时任务
    union_mission_chat = "",     --刷新邀请时间
    union_mission_set = "int idx",     --领取军团定时任务
    union_mission_log = "string type,int id",     --获取军团定时任务日志
    union_mission_add = "int idx",     --领取奖励 
    union_word_add = "int uid,string title,string word, int flag",--军团留言
    union_word_update = "int wid,string title,string word",--军团内部留言修改
    union_word_top = "int wid,int flag",--军团内部留言置顶 1:置顶 0：取消
    union_word_del = "int wid",--军团内部留言删除
    union_word_get = "int uid,int wid",--获取军团留言内容
    --改联盟基本信息 name,alias,language,rank_alias,mars
    --{tag=value, ...}
    union_set_info = "pack info",

    get_room = "int rid", --获取战斗双方数据


    -- just for test
    addArm = "",
    addItem = "int id, int num",
    addRes = "",

    runCommand = "string command",

    -- debug func beign.
    clear_item = "",
    -- debug func end.

    gm_user = "string cmd",
    gm_platform = "string cmd",

    testFight = "int an1, int an2, int an3 int an4, int ah1, int ah2, int ah3, int ah4, int dn1, int dn2, int dn3, int dn4, int dh1, int dh2, int dh3, int dh4",

    query_fight_info = "int eid",

    echo = "int time",
    --------------------------------------------------------------------------------
    -- Hero Begin.    YC@2015-12-30
    get_hero_list_info = "int pid",
    get_hero_detail_info = "string hero_id",

    call_hero_by_piece = "int hero_propid",
    hero_star_up = "int hero_idx",
    hero_lv_up = "int hero_idx, int item_idx, int num",
    hero_skill_up = "int hero_idx, int skill_idx, int item_idx, int num",

    use_hero_skill_item = "int hero_idx, int skill_idx, int item_idx, int num",

    -- 派遣
    dispatch_hero = "int build_idx, int hero_idx",

    -- 分解英雄
    destroy_hero = "int hero_idx",

    -- 治疗英雄
    --cure_hero = "int hero_idx, int delta_hp",
    cancel_cure_hero = "int hero_idx",
    cure = "pack arm, int quick",
    cure_acc = "int mode",
    cure_acc_item = "int item_idx, int num",
    cure_cancel = "",

    dismiss = "int id, int num, int ishurt",

    hero_cure = "int hero_idx, int tohp",
    hero_cure_cancel = "int hero_idx",
    hero_cure_quick = "int hero_idx, int tohp",
    hero_cure_acc_item = "int hero_idx, int item_idx, int item_num",
    hero_cure_acc_gold = "int hero_idx, int acc_type",


    -- 获取被俘英雄信息
    get_prisoners_info = "",

    -- 释放英雄
    release_prisoner = "string hero_id",

    -- 处死英雄
    kill_hero = "string hero_id, int buff_idx",

    -- 复活英雄
    relive_hero = "int hero_idx, int is_quick",

    -- Hero End.
    --------------------------------------------------------------------------------
    get_resm_conf = "",--获取当前物资市场配置
    buy_res = "int id",--购买资源

    ----------------------------------------------------------------------------
    --task
    finish_task = "int task_id",     --完成任务获得奖励
    accept_task = "pack task_id_array",     --接任务
    finish_open_ui = "int ui_id",  --完成打开UI的任务
    refresh_daily_task = "",  --刷新每日任务
    daily_task_activity = "",  --得到每日任务活跃度
    get_activity_box = "int id",  --活跃度领奖
    get_daily_refresh_time = "", --得到下次刷新的时间
    daily_task_done = "int task_id",  --直接完成任务

    task_visit = "int task_id, int dest_eid, int x, int y, pack arm",  --task 侦查
    spy_task_ply = "int task_id, int dest_eid, int x, int y", --任务侦查伪玩家
    siege_task_ply = "int task_id, int dest_eid, int x, int y, pack arm", --攻击任务伪玩家

    ---------------------------------------------------------------------------
    --在线奖励
    require_online_award_time = "", --获取领奖剩余时间
    require_online_award = "", --获得本次在线奖励

    ----------------------------------------------------------------------------
    --月登陆奖励
    --require_month_award_process = "", --获得月登陆进度
    --require_get_month_award = "", --月登陆领奖
    --require_month_award_com = "", --月登陆补签领奖
    month_award_get_award = "",
    month_award_get_extra = "",
    -- pay cash
    get_can_buy_list_req = "",

    -----act info
    act_info_tag_req = "int act_type",

    ---- boss
    boss_rank_req = "",
    act_info_req = "",
    gen_boss_req = "int mode, int lv", -- 用于测试
    ---- npc city tw
    get_random_award_req = "int eid",  -- 获取随机奖励
    declare_tw_req = "int eid", --- 宣战
    declare_tw_status_req = "int eid", --- 宣战
    get_can_atk_citys_req = "", --- 可攻击城市列表
    get_npc_map_req = "",       --- npc大地图信息
    tag_npc_req = "int act, int eid",  --大地图标记城市 act = 1 -- 标记攻击act = 2 -- 标记防守
    untag_npc_req = "int eid", -- 取消标记
    get_union_npc_rank_req = "", --- 军团排名
    npc_info_req = "int eid",
    get_union_npc_req = "", --  取得本军团占领的npc
    npc_act_info_req =  "", -- npc 活动页面
    union_npc_info_req =  "", -- 军团npc info
    npc_info_by_propid_req = "int propid",
    npc_log_req = "",
    abandon_npc = "int eid", -- 弃城
    abd_npc_cond_req = "int eid", -- 弃城条件
    post_npc_change = "int npc_propid, int occu_gs_id, int tag", --post npc change to cross mng center
    get_city_for_robot_req = "int mode, int lv", -- robot get a npc eid
    ---- king city 
    officers_info_req = "",  --任命官员大厅
    king_info_req = "", -- king info
    select_officer_req = "int pid, int index", --任命官员
    rem_officer_req = "int index", --卸任
    acc_tower_recover_req = "int eid",
    honour_wall_req = "", --国王荣誉墙,
    mark_king_req = "int score", --给国王评价
    kw_mall_buy_req = "int mode, int index",-- 购买王城商城物品
    kw_want_buy_req = "int index",-- 投票王城商城物品
    kw_mall_info_req = "int mode", -- 王城商城信息G
    refresh_mall_req = "int mode", -- 刷新商城
    find_player_by_name_req = "string name", -- 搜索玩家
    kw_info_req = "", -- 王城战活动页面
    get_gs_buf = "",
    --monster city
    mc_info_req = "", -- 怪物攻城活动页面
    set_mc_start_time_req = "int time, int grade", -- 怪物攻城活动开启时间和难度
    get_mc_akt_info_req = "", -- 获得怪物攻城信息

    --lost temple
    lt_info_req = "", --遗迹塔活动页面
    lt_citys_info_req = "int index", -- 分页请求遗迹塔活动数据
    get_lt_award = "int index", --lt 个人奖励



    black_market_buy = "int idx",
    black_market_refresh = "",

    load_msg_list = "string what, int sn, int count, int new",

    --gacha抽卡
    get_gacha_status = "",
    do_gacha = "int type",
    get_gacha_box = "",

    kick_mass = "int tid, int pid",

    --攻击npc怪
    siege_task_npc = "int task_id, int dest_eid, int x, int y, pack arm",

    -- chat admin
    chat_account_info_req = "", -- 请求玩家聊天账户信息
    create_chat_account = "int result",
    create_room = "int result",
    send_invite = "string room, pack pids",

    vip_buy_gift = "int idx",

    testCross = "int a1, string a2",
    ack_tool = "int sn, pack info",

    open_field = "int index",

    report_load = "int mode",
    report_del = "int mode",

    set_culture = "int culture", -- 1 -> 4
    syn_back_code = "int syn",


    load_rank = "int idx, int version",
    load_my_rank_score = "int idx",

    set_client_parm = "string key, string data",
    set_show_equip = "int flag",

    -- achievement
    ache_info_req = "", --成就
    get_ache_reward = "int idx",
    -- title
    title_info_req = "",--称号
    use_title_req = "int idx" ,
    rem_title_req = "int idx" ,

    p2p = "int to_pid, pack info",

    reset_skill = "int hero_idx, int skill_idx",
    reset_skill_senior = "int hero_idx, int skill_idx",
    reset_skill_primary = "int hero_idx, int skill_idx",

    request_empty_pos = "int x, int y, int size, pack info",
    request_fight_replay = "string replay_id",

    role_info = "int pid",

    choose_head_icon = "int id",
    get_uname_by_propid = "int propid",
    world_chat_task = "",
    packet_target_task = "",
    qiri_get_award = "",
    get_yueka_award = "",

    get_world_event_award = "int event_id",
    get_world_event_process = "",


    query_troop_coming = "",
    query_log_support_arm = "",

    --on_pay = "int propduct_id",

    buy_yueka = "", --临时接口
    pack_weekly_activity_info = "",   --限时活动信息
    boss_gather = "int eid_boss, int eid_res",

    get_dig_pos = "",
    dig = "int x, int y, int itemid, pack arm",

    reset_nature = "int hero_idx",
    query_around = "pack param, int eid, int range",
    hero_piece_decompose = "int itemid, int count",
    skill_piece_decompose = "int itemid, int count",

    get_tribute_exchange = "int eid",
    exchange = "int eid, pack res, pack tribute", -- res, tribute is in the fomat { [ id ] = num } 

    get_mail_share = "string mail_id",

    hero_info = "int pid, int propid",
    operate_exchange = "int activity_id, int exchange_id",
    operate_single_get = "int activity_id",
    operate_activity_list = "",
    operate_task_get = "int activity_id, int task_id",

    ---- jpush ntf
    push_ntf_list_req = "pack info",   -- 开通通知的列表
    up_jpush_info_req = "pack info",
    get_server_tag_req = "",

    dbg_show = "string cmd",
    dbg_run = "string func", 
    dbg_set = "string key, string val",
    dbg_ask = "string key", 
    get_target_all_award = "int index",
    get_world_event_stage_award = "int index",

    ip_rule = "unsigned int cmd, unsigned int ip",

    ping = "",
    accept_hero_road_chapter = "int chapter_id",
    get_hero_road_task_award = "int chapter_id, int task_id",
    get_hero_road_chapter_award = "int chapter_id",
    server_map_king_info = "",

    get_device_grade = "string device, string gpu, int frenquency, int core",

    --hero_task
    get_hero_task_list_req = "",
    refresh_hero_task_list_req = "",
    accept_hero_task_req = "int id",
    add_hero_task_help_req = "int id",

    --
    certify ="int code",

    set_auto_mass = "pack info",
    get_auto_mass = "",

}


Client = {
    getTime = "int gTime, int gMsec, int tag,int gBootTime",

    ply_list = "string proc, string account, pack pids, pack characters",

    onQryCross = "int toPid, int sn, int smap, int spid, string cmd, pack arg",
    onAckCross = "int smap, int sn, int code, pack arg",

    hello = "int pid1, int pid2, string text",
    onLogin = "int pid, string name",
    logout = "",

    first_packet_ack = "int error_code", -- 登录验证信息
    login_in_queue_init = "pack info", -- 登录队列满
    login_in_queue_update = "pack info", -- 登录队列更新

    get_characters = "pack infos",

    say = "string say, int nouse",
    say1 = "string say, int nouse",

    -- 聊天
   --chat = "int chanelID, pack speaker, string word, int language, pack args",    --chanelId: enum in common/define/ChatChanelEnum;   pid==-1 means system;   word:the word somebody say
    chat = "int chanelID,int sn, pack speaker, string word, int language, pack args, int id, int channel",
    --{sn,gTime,speaker,word,lang,args}
    fetch_chat="int chanel,pack infos",
    --chatWithAudio         --TODO
    --获取用户简单信息回应，这次通讯主要是用来获取玩家的聊天基本信息，获取详细信息可以采用另外的接口,remoteAvatarId为空时代表没有自定义头像
    on_get_user_simple_info = "int pid, int vipLevel, string userName, int defaultAvatarId, string remoteAvatarId",


    get_user_info = "pack info",

    testPack = "int i, pack p, string s",

    qryInfo = "pack info",
    loadData = "pack info",
    get_buff = "string what, int val",
    qryAround = "int x, int y, pack objs",
    upd_arm = "pack arminfo",

    found_entity = "int sn, int propid, int x, int y",

    --type= 1-飘字通用提示 2-跑马灯公告 3-只有确定按钮的对话框
    --lanid --客户端多语言字段的id
    --info --对应填入多语言的参数列表    
    tips = "int type,int lanid,pack info",

    --add_troop = "pack troop",

    equip_add = "pack e",
    equip_rem = "int sn",

    -- mail
    mail_new = "pack mail",
    --mail_unread = "pack mail_class",  -- {[class_id]=unread_count,....}
    --mail_unread_inc = "int class, int inc",

    mail_load = "pack mails",
    mail_notify = "pack info",

    mail_sys_new = "int sysMail",
    mail_fetch_resp = "pack sns",

    -- roi
    addEty = "pack obj",
    addEtys = "pack objs",
    remEty = "int eid",

    add_troop      = "int eid, int action, int sx, int sy, int dx, int dy, int tm, int cx, int cy, pack info ",
    troop_set_move = "int eid, int action, int sx, int sy, int dx, int dy, int tm, int cx, int cy",

    rem_troop = "int eid",

    --crose gs

    agent_migrate = "int map, int x, int y, pack data, pack task, pack timers, pack union_pro",
    agent_migrate_ack = "int map, int pid, int param",
    agent_syn_call = "int map, int id, string func, pack arg",
    agent_syn_call_ack = "int id, pack ret",
    cross_npc_info_ack = "pack info",  -- cross mng  to client
    --cross act
    cross_act_st_ack = "pack info",

    -- state change
    stateBuild = "pack build",
    statePro = "pack pro",
    stateEf = "pack ef",
    state_ef_hero= "pack ef_hero",
    stateTroop = "pack troop",
    -- 单个英雄发生变化的字段
    stateHero = "pack hero",
    -- {idx（唯一ID）,_id（配置表ID）,num（当前数量）}
    stateItem = "pack items",

    addTips = "string str, pack tab",

    fightInfo = "pack info",
    battle = "int eid, int aid, int did, int pid, int uid",
    enter_tower = "int eid, int troopid",
    leave_tower = "int eid, int troopid",

    gmCmd = "string process, string ack",

    onError = "int cmdHash, int code, int reason",

    union_load = "pack info",
    union_get = "pack info",
    union_on_create = "pack info",
    union_search = "string key, array struct PlayerInfo infos",     --搜索玩家
    union_member_get = "int uid, array struct UnionMember datas",
    union_on_rm_member = "int pid",            --broadcast
    union_add_member = "pack info",           --broadcast

    union_destory = "",                      --- 军团解散
    union_list = "string key, array struct UnionInfo infos",                ---读取军团列表
    union_list2 = "pack info",                --推荐军团列表
    union_task_add = "pack info",     --获取军团悬赏任务列表
    union_task_get = "pack info",     --获取军团悬赏任务列表
    union_mission_get = "pack info",     --获取军团定时任务
    union_mission_set = "",              ----领取军团定时任务
    union_mission_log = "pack info",     --获取军团定时任务日志

    union_reject = "int pid",                --广播申请拒绝消息
    union_reply = "int unionId,string name,int state",   --- 发送加入军团申请成功
    union_invite = "int unionId",            ---主动邀请玩家加入军团
    union_mass_on_create = "int mid",   --回复集结创建成功
    union_state_mass = "pack info",     --集结变化(新的集结，完成集结) --broadcast
    
    union_tech_update = "pack info",    --广播科技变化{idx,.id,xx,.tmOver}
    union_tech_mark = "pack info",      --广播新的标记
    union_tech_info = "pack info",      --科技详细信息{idx,id,exp,tmOver,donate={2,0,0}}
    union_donate_info = "pack info",    --更新捐献状态
    union_log = "pack info",            --获取联盟日志
    --union_donate_rank = "pack info",  --捐献排名
    union_donate_rank = "struct UnionRank pack", --捐献排名
    union_ply_rank_ack = "int mode, pack info",           -- 军团内玩家排名
    union_member_mark = "int pid, string mark", --联盟标记
    union_buildlv_donate = "pack info",       --更新建筑捐献
    union_mall_buy = "int propid,int num",     --军团成员买道具
    union_mall_log = "pack info",              --获取军团商店的日志
    union_help_get = "pack info",--获取军团帮助
    union_help_get_detail = "pack info",--获取军团帮助

    union_word_add = "pack info",--军团留言
    union_word_get = "pack info",--获取军团留言内容

    --援助目标统计
    --{max,cur,mine,}
    union_aid_count = "pack info",

    ---战争大厅
    union_battle_room_list_resp = "pack data",
    union_battle_room_info_resp = "pack data",
    union_battle_room_detail_resp = "pack data",
    --- 

    --联盟数据广播    
    --member:联盟成员变化(ADD和DELETE暂时还用union_add_member&union_on_rm_member)
    --ADD={pid,name,lv,rank,photo,mark}
    --UPDATE={pid,name,lv,rank,photo,mark}
    --DELETE={pid}
    --
    --buildlv:建筑变化(exp变化不推)
    --UPDATE={class,id,stage,exp}
    --
    --info:基本信息变化
    --UPDATE={name,alias,language,mars,rank_alias}
    --mall_mark: 商城标记
    --UPDATE={name,propid,flag}
    union_broadcast = "string what, int mode, pack info",

    get_room = "int rid,pack info", --获取战斗双方数据
    get_room_troop = "int rid,int pid,pack info", --获取战争的行军队列数据
    get_eid_troop = "int eid,int pid,pack info", --获取建筑的行军队列数据
    get_eye_info = "int eid, pack info",--获取地图单位详细信息
    --troop
    troopx_stdtime = "int did, int tm", --行军标准时间

    --test
    runCommand = "pack info",

    --------------------------------------------------------------------------------
    -- Hero Begin.    YC@2015-12-30
    -- _id name star lv currHP maxHP status fightPower _type personality（随机天性） basicSkill talentSkill atk def exp culture nature（固定天性） quality
    on_get_hero_list_info = "pack heroListInfo",
    -- _id name star lv currHP maxHP status fightPower _type personality（随机天性） basicSkill talentSkill atk def exp culture nature（固定天性） quality
    on_get_hero_detail_info = "pack heroDetailInfo",
    -- hero_idx, skill_idx, skill_id, exp
    on_basic_skill_changed = "int hero_idx, int skill_idx, int skill_id, int exp",
    on_destroy_hero = "int hero_idx",
    -- {{idx, propid,star, fight_power, prison_start_tm, kill_start_tm, kill_over_tm, player_name, player_id, union_name}, ...}
    on_get_prisoners_info = "pack prisoners_info",
    -- 英雄逃脱，被释放、处斩之后告知前端
    on_get_out_of_prison = "string hero_id",
    -- Hero End.
    --------------------------------------------------------------------------------
    --get_resm_conf = "int rmb, pack info, int res_num, int buy_num ",--物资市场配置
    get_resm_conf = "int rmb, pack info",--物资市场配置

    -- 建筑完成工作
    on_build_work_completed = "int build_idx",

    ------------------------------------------------------
    --task
    finish_task_resp = "int result",
    update_task_info = "pack info",
    daily_task_activity_resp = "pack info",
    get_activity_box_resp = "int result",
    get_daily_refresh_time_resp = "pack info",
    daily_task_done_resp = "int result",
    refresh_daily_task_resp = "int result",

    -------------------------------------------------------
    --在线奖励
    get_online_award_time_resp = "int is_end, int left_time",

    ------------------------------------------------------------
    --月登陆奖励
    --month_award_process_resp = "int month_day, int can_get",
    --month_award_get_award_resp = "int res",
    --month_award_com_resp = "int res",

    --------------------------------------------------------
    --瞭望塔
    add_compensation_info = "pack info",
    rm_compensation_info = "int id",
    update_compensation_info = "int id, int tm_over",

    -----------------------------------------------------
    --通知显示奖励
    notify_bonus = "pack info",
    -----------------------------------------------------
    -- pay cash
    gm_resend_order = "",
    get_can_buy_list_ack = "pack info",
    
    --act info
    act_info_tag_ack = "int tag",
    --boss
    gen_boss_eid_ack = "int eid",  --测试用
    boss_rank_ack = "pack info",

    act_info_ack = "pack info",
    get_npc_map_ack = "pack info",
    get_do_mc_npc_ack = "pack info",
    lt_map_info_ack = "pack info",
    -- npc city
    get_can_atk_citys_ack = "pack info", -- 军团可以攻击的npc城市
    get_union_npc_rank_ack = "pack info",
    tag_npc_ack = "pack info",
    npc_info_ack = "pack info",
    get_union_npc_ack = "pack info",
    npc_act_info_ack =  "pack info",
    union_npc_info_ack =  "pack info",
    npc_info_by_propid_ack = "pack info",
    npc_log_ack = "pack info",
    declare_tw_ack = "int eid, int ret", --- 宣战 
    declare_tw_status_ack = "int eid, pack info", --- 宣战 
    abd_npc_cond_ack = "pack info", -- 弃城条件
    get_city_for_robot_ack = "int mode, int eid", -- robot get a npc eid
    npc_ft_result_ntf = "pack info",  --npc战斗结果通知

    --kingcity war
    officers_info_ack = "pack info",
    honour_wall_ack = "pack info",
    kw_mall_info_ack = "pack info",
    find_player_by_name_ack = "pack info", 
    kw_info_ack = "pack info",
    king_info_ack = "pack info",
    mark_king_ack = "int score",
    gs_buf_ntf = "pack info",
    --monster city
    mc_info_ack = "pack info", -- 怪物攻城页面
    set_mc_start_time_ack = "pack info", -- 怪物攻城活动开启时间
    get_mc_akt_info_ack = "pack info", -- 获得怪物攻城信息

    --lost temple
    lt_info_ack = "pack info",
    lt_citys_info_ack = "pack info", -- 分页请求遗迹塔活动数据




    ack_troop_info = "pack info",

    msg_load = "string what, int sn, int count, int new, pack infos",
    msg_add = "string what, pack info",

    notify_server = "string val",

    --gacha抽卡
    get_gacha_status_resp = "pack info",
    do_gacha_resp = "pack info",
    get_gacha_box_resp = "int result",

    -- chat admin
    chat_account_info_ack = "int jid, int pwd", -- 请求玩家聊天账户信息
    create_chat_account = "string pid, string host, string psw ",
    create_room = "string uid, string host, string admin",
    c_create_room = "", --客户端创建聊天室
    send_invite = "string room, pack pids",

    rm_npc_monster = "int eid",
    rm_fake_ply = "int ply_id",


    testCross = "int a1, string a2",
    qry_tool = "int sn, pack info",

    report_load = "int mode, pack infos",
    report_notify = "int mode, pack info",

    --load_mail_resp = "pack info",
    --notify_mail = "pack info",

    --load_report_resp = "int mode, pack info",
    --notify_report = "int mode, pack info",
    syn_back_code_resp = "int syn",
    load_rank = "int idx, int version, int pos, pack info",
    rank_pos = "int idx, int pos",
    load_my_rank_score = "int idx",
    -- achievement
    ache_info_ack = "pack info",
    set_ache = "int key, int val",
    set_count = "int key, int val",
    -- title
    title_info_ack = "pack info",
    display_ntf = "pack info",
    p2p = "int from_pid, pack info",

    response_empty_pos = "int x, int y, pack info",
    response_fight_replay = "int result",

    send_army_state = "int code, int max, int total",
    --
    role_info = "pack info",

    be_attacked = "",

    choose_head_icon_resp = "int res",

    --rpc dostring
    do_string = "string trunk",
    get_uname_by_propid_resp = "pack info",

    target_task_list_resp = "",

    notify_buf = "int bufid, int start, int over",
    notify_build_upgrade = "int build_idx",

    support_notify = "pack infos",
    sync = "int sn",
    qiri_get_award_resp = "int res",

    test_struct = "int id, array struct UnionMember member",    
    get_world_event_process_resp = "pack info",
    ety_info_ack = "pack info", --测试使用

    query_troop_coming = "pack info",
    query_log_support_arm = "pack info",
    monster_declare = "pack info",
    pack_weekly_activity_info_resp = "pack info",  --限时活动信息

    acc_build = "int build_idx, int state, int acc_type",
    get_dig_pos = "int x, int y",

    query_around = "pack param, pack infos",


    get_tribute_exchange = "int eid, pack info",

    get_mail_share_resp = "pack info",

    hero_info = "int pid, int propid, pack info",
    operate_activity_list_resp = "pack info",

    ---- jpush ntf
    push_ntf_list_ack = "pack info",   -- 开通通知的列表
    get_server_tag_ack = "string tag",
    echo = "int time",

    dbg_show = "pack info",
    activate = "",

    set_first_blood = "int id, int tm",
    set_sys_option = "pack info",

    ping = "",

    pop_up = "int what, pack info",

    train_over = "int id, int num",
    server_map_king_info_resp = "pack info",

    get_device_grade = "int grade",
    cross_server_success = "",

    --hero_task
    get_hero_task_list_ack = "pack info",
    update_hero_task_ack = "pack info",
    update_hero_task_info = "pack info",

    broadcast_world_event_proccess = "pack info",
    broadcast_operate_end = "int activity_id",

    certify ="int code",

    get_auto_mass = "pack info",

    mass_join = "pack info", -- { propid, alias, name, pid }

}

CrossQuery = {
    get_union_npc_rank_req = 1,
    get_npc_map_req = 1,
    act_info_req = 1,
    king_info_req = 1,
    server_map_king_info = 1,
}


