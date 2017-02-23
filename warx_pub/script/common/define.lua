--------------------------------------------------------------------------------

--时区偏移数值 秒
TIME_ZONE = 0


-- chat host
CHAT_HOST = "war_x.org"
-- 登录秘钥
APP_SECRET = "zMvnPIT4fHG4ecte"
APP_ID = "10000"
APP_KEY = "Os3NpXfDJeURCC1W"

-- login_url
LOGIN_URL = "http://common.walihudong.com/index.php/LoginClass/uploaduserinfo"
-- chat_url
CHAT_URL = "http://192.168.103.225:5280"

LOGIN_ERROR =
{
    TOKEN_INVAILD = 1,
    TOKEN_OUT_OF_DATE = 2,
    LOGIN_ERROR = 3,
    PID_ERROR = 4,
    SERVER_MAINTAIN = 5,

}
--概率总和
TOTAL_RATE = 10000
BLACK_MARKET_REFRESH_COST = {0,0,0,0,5,10,20,40,80,120,120,160,160,320,320,640,640,1000,1000,1000}

-- 数值变化原因
VALUE_CHANGE_REASON = {
    -- [0, 9] Don't use these value.
    DEFAULT = 0,
    DEBUG   = 1,
    RAGE   = 2,
    USE_ERROR = 3,
    MIGRATE = 4,
    BUY_RES = 5,
    GM_PAY = 6,
    GM_CMD = 7,
    CHAT_NOTICE = 8,

    -- [10, 19] Item
    USE_ITEM   = 10,
    FETCH_MAIL = 11,
    COMPOSE = 12,
    DECOMPOSE = 13,
    FORGE = 14,
    SPLIT = 15,
    CURE = 16,
    FORGE_CANCEL=17,
    COMPOUND = 18,
    ACC_TROOP = 19,


    -- [20, 29] Build
    BUILD_CONSTRUCT = 20,
    BUILD_UPGRADE   = 21,
    BUILD_ACC       = 22,
    LEARN_TECH      = 23,
    CANCEL_ACTION  = 24,
    WALL_REPAIR    = 25,
    TROOP_RECALL = 26,
    CHANGE_NAME = 27,

    -- [30, 39] Hero
    HERO_CREATE       = 30,
    HERO_SATR_UP      = 31,
    HERO_LV_UP        = 32,
    RESET_SKILL       = 33,
    CONVERT_HERO_CARD = 34,
    DESTROY_HERO      = 35,
    CURE_HERO         = 36,
    CANCEL_CURE_HERO  = 37,
    RELIVE_HERO       = 38,
    HERO_DESTORY      = 39,
    GENIUS_RESET      = 40,

    CASTLE_6_GIFT     = 41,

    -- [50, 79] Play
    GATHER = 50,
    REAP   = 51,
    TRAIN  = 52,
    JUNGLE = 53,
    SUPPORT_RES = 54,

    BLACK_MARKET_PAY = 61,
    BLACK_MARKET_BUY = 62,
    BLACK_MARKET_REFRESH = 63,

    RESOURCE_MARKET_PAY = 71,
    RESOURCE_MARKET_BUY = 72,

    MALL_PAY = 73,
    MALL_BUY = 74,

    VIP_BUY = 75,

    PT_MALL_BUY = 76,
    PT_MALL_REFRESH = 77,
    KW_MALL_BUY = 78,


    -- [100, 200] Union
    UNION_CREATE    = 101,
    UNION_DONATE    = 102,
    UNION_MALL      = 103,
    UNION_WAIT      = 104,
    UNION_FAIL      = 105,
    UNION_OK        = 106,
    UNION_MISSION   = 107,
    UNION_TASK      = 108,
    UNION_BUILDLV   = 109,
    UNION_GOD       = 110,
    UNION_RANK      = 111,
    UNION_ITEM      = 112,
    UNION_FLAG      = 113,

    --加奖励
    REASON_ADD_BONUS = 1000,
    REASON_ONLINE_AWARD             = 1001,          --在线奖励领奖
    REASON_MONTH_AWARD              = 1002,          --月登陆领奖
    REASON_TASK                     = 1003,          --任务奖励
    REASON_TASK_DAILY_BOX           = 1004,          --日常任务活跃度箱子
    REASON_GACHA_AWARD_YINBI_ONE    = 1005,          --银币单抽
    REASON_GACHA_AWARD_YINBI_TEN    = 1006,          --银币十连抽
    REASON_GACHA_AWARD_JINBI_ONE    = 1007,          --金币单抽
    REASON_GACHA_AWARD_JINBI_TEN    = 1008,          --金币十连抽
    REASON_GACHA_AWARD_HUNXIA_ONE   = 1009,          --魂匣单抽
    REASON_GACHA_AWARD_HUNXIA_TEN   = 1010,          --魂匣十连抽
    REASON_GACHA_GIFT_BOX           = 1011,          --抽卡箱子奖励
    REASON_TASK_NPC_AWARD           = 1012,          --打任务怪获得奖励
    REASON_ACHE                     = 1013,          --成就领奖
    REASON_MAIL_AWARD               = 1014,          --邮件领奖
    REASON_NPC                      = 1015,          --NPC奖励
    REASON_MONSTER                  = 1016,          --世界boss奖励
    REASON_MC                       = 1017,          --怪物攻城奖励
    REASON_LT                       = 1018,          --遗迹塔奖励
    REASON_KING                     = 1019,          --王城奖励
    REASON_UNION_DONATE             = 1020,          --军团捐献加奖励
    REASON_UNION_BUILD              = 1021,          --军团建筑加奖励
    REASON_UNION_AID                = 1022,          --军团士兵援助加奖励
    REASON_WEEKLY_AWARD             = 1023,          --七日登录奖励
    REASON_YUEKA                    = 1024,          --月卡奖励
    REASON_WORLD_EVENT              = 1025,          --世界事件

    --扣除资源
    REASON_DEC_RES = 2000,
    REASON_UNION_SAVE_RESTORE       = 2001,          --存储资源到联盟仓库
    REASON_DAILY_TASK_REFERSH       = 2002,          --刷新每日任务
    REASON_DAILY_TASK_DONE_TASK     = 2003,          --直接完成日常任务
    REASON_GACHA_YINBI_ONE          = 2004,          --银币单次抽卡
    REASON_GACHA_YINBI_TEN          = 2005,          --银币十连抽
    REASON_GACHA_JINBI_ONE          = 2006,          --金币单抽
    REASON_GACHA_JINBI_TEN          = 2007,          --金币十连抽
    REASON_GACHA_HUNXIA_ONE         = 2008,          --魂匣单抽
    REASON_GACHA_HUNXIA_TEN         = 2009,          --魂匣十连抽
    REASON_DEC_RES_RESET_SKILL      = 2010,          --重置技能
    REASON_DEC_RES_CHANGE_HEAD      = 2011,          --改变头像

    --增加资源
    REASON_ADD_RES = 3000,
    REASON_UNION_GET_RESTORE        = 3001,          --从联盟仓库取资源
    REASON_BUY_RES                  = 3002,          --从市场买资源
    REASON_UNION_SAVE_RESTORE       = 3003,          --军团存资源返回

    --扣除物品
    REASON_DEC_ITEM = 4000,
    REASON_TASK_DEC_ITEM            = 4001,          --任务扣除任务物品
    REASON_GACHA_DEC_ITEM           = 4002,          --魂匣单抽扣物品
    REASON_DEC_ITEM_RESET_SKILL     = 4003,          --重置技能
    REASON_DEC_ITEM_CHANGE_HEAD     = 4004,          --改变头像
}

RES_RATE = { 1, 1, 5, 20 }
RANGE_LV = { 3380, 1104, 816, 528, 240, 16 }

SECS_TWO_WEEK = 1209600

CLEAR_CD_COST =         ---清除cd时间与消耗金币关系的通用配置，需要按照时间顺序由小到大排序配置
{
    {300, 15},
    {3300, 135},
    {25200, 800},
    {57600, 1750},
}

BUY_RES_COST =         ---购买单位资源与消耗金币的通用配置，需要按照资源数量顺序由小到大排序配置
{
    {  10000,  40},
    {  40000, 120},
    { 100000, 240},
    { 350000, 800},
    {1000000,2100}
}
BUY_SILVER_COST = 150  -- 购买银币比率恒定150:1

resmng.CLASS_RES = 1			--物品类型1资源
resmng.CLASS_BUILD = 2			--物品类型2建筑
resmng.CLASS_ARM = 3			--物品类型3军队
resmng.CLASS_GENIUS = 4			--物品类型4天赋
resmng.CLASS_TECH = 5			--物品类型5科技
resmng.CLASS_ITEM = 6			--物品类型6道具
resmng.CLASS_COUNT = 7			--操作类型7达成次数
resmng.CLASS_UNION_TECH = 8     --物品类型8军团科技
resmng.CLASS_UNION_BUILDLV = 9  --物品类型9军团建筑等级
resmng.CLASS_PLAYER_LEVEL = 10  --物品类型10角色等级
resmng.CLASS_UNION_LEVEL = 11   --物品类型11军团等级
resmng.CLASS_GLOB_RES = 12      --全服资源如国王比
resmng.CLASS_TRUNKTASK = 13     --需要正在做这个主线任务
resmng.CLASS_CULTURE = 14     --需要属于这个文明
resmng.CLASS_GUIDED = 15     --需要完成这个引导class
resmng.CLASS_CASTLE_MAX = 16     --需要城堡等级小于等于这个值
resmng.CLASS_RES_PROTECT = 101	--物品类型101保护资源

WALL_FIRE_SECONDS = 18          -- 非土地每18秒减1点城防
WALL_FIRE_IN_BLACK_LAND = 44    -- 黑土地每1秒减44点城防
WALL_FIRE_REPAIR_FREE = 60      -- 免费修复，每次恢复60点城防
WALL_FIRE_REPAIR_TIME = 1800    -- 免费修复，每1800秒一次
WALL_FIRE_OUTFIRE_COST = 50     -- 城墙灭火，花费30金币


UNION_TASK =      ---军团悬赏任务类型
{
    PLY = 0,
    NPC = 1,
    HERO = 2,
    NUM = 3,
}

UNION_DONATE_LIMIT =60000 
UNION_DONATE_B_LIMIT =7 

UNION_DONATE_WEEK = 
{
    ONE = 2013161, 
    TWO = 2013162, 
    THREE = 2013163, 
    B_ONE = 2013164, 
    B_TWO = 2013165, 
    B_THREE = 2013166, 
}

DONATE_RANKING_TYPE = {
    DAY = 1, --科技日排行
    WEEK = 2, --科技周排行
    UNION = 3, --科技历史排行
    DAY_B = 4, --建筑日排行
    WEEK_B = 5, --建筑周排行
    UNION_B = 6, --建筑历史排行
}

UNION_ITEM =      ---军团礼包来源
{
    POS = 1,      --- 充值
    BOSS = 2,     --- 击杀BOSS
    TASK = 3,     --- 完成军团任务
    CITY = 4,     --- 占领NPC城市
    KING = 5,     --- 王城战
    GM = 6,
    MAX = 7,
}

UNION_TASK_CONFIG =
{
    PRICE = 20,
    BONUS = {MIN = 20*1000,MAX = 80*1000}
}

resmng.ITEM_CLASS_ACC = 3
resmng.MATERIAL_COMPOSE_COUNT = 3

-- 重置天赋所需金币
GENIUS_RESET_COST = 1000
-- 领主体力最大值
LORD_MAX_SINEW = 100
ROI_MSG = {
    NTY_NO_RES  = 13,
    TRIGGERS_ENTER = 21,
    TRIGGERS_LEAVE = 22,
    TRIGGERS_ARRIVE = 23,
    ADD_SCAN = 24,
    REM_SCAN = 25,
    ADD_ACTOR = 26,
    REM_ACTOR = 27,
    UPD_ACTOR = 28,
    TIME_STEP = 29,
    GET_AROUND = 30,
}

--resmng.CLASS_UNION_BUILD_
--
CLASS_UNIT = {
    PLAYER_CITY = 0,
    RESOURCE = 1,
    MONSTER = 2,
    NPC_CITY = 3,
    KING_CITY = 4,
    Camp =5,
    MONSTER_CITY = 6,
    LOST_TEMPLE = 7,

    UnionBuild = 10,
    Troop = 11,
    CLOWN = 12,
}

ACT_NAME = {
    NPC_CITY = 1,
    MONSTER_CITY = 2,
    LOST_TEMPLE = 3,
    KING = 4,
    REFUGEE = 5,
    CROSS_NPC = 6,
}

RANK_ACTION = {
    NORMAL = 1,
    CURE = 2,
    NPC_DMG = 3,
    KING_DMG = 4,
    NPC_ACT = 5,
    KING_ACT = 6,
}

RANK_MODE = {
    PLY = 1, 
    UNION = 2,
    GS = 3,
}

ACT_TYPE ={
    NPC = 1,
    BOSS = 2,
    MC = 3,
    KING = 4,
    LT = 5,
}

OPT_TYPE = {
    EQ = 1,
    UE = 2,
    LT = 3,
    GT = 4
}

BOSS_TYPE = {
    NORMAL = 1,
    ELITE = 2,
    LEADER = 3,
    SUPER = 4,
    SPECIAL = 5,
}

TW_STATE =
{
    PACE = 1,
    DECLARE = 2,
    PREPARE = 3,
    FIGHT = 4,
}

KW_STATE =
{
    LOCK = 1,
    UNLOCK = 2,
    PACE = 3,
    PREPARE = 4,
    FIGHT = 5,
}

CROSS_STATE =
{
    LOCK = 0,
    PREPARE = 1,
    FIGHT = 2,
    PEACE = 3,
}

GM_TYPE =
{
    PAY = 1,
}

KING = 1001 --国王称号的id

CITY_TYPE =
{
    FORT = 3,
    TOWER = 2,
    KING_CITY = 1,
}

TOWER_STATUS=
{
    ENALBE = 0,
    ABLE = 1,
}

MC_TYPE =
{
    ATK_NPC = 1,
    ATK_PLY = 2,
    DEF_ATK = 3,
}

--CIVIL_TYPE =
    CIVIL_1 = 1
    CIVIL_2 = 2


-- table of boss reborn after dead
BossRbTime = {
    [ BOSS_TYPE.NORMAL ] = 10,
    [ BOSS_TYPE.ELITE ] = 3600,
    [ BOSS_TYPE.LEADER ] = 3600,
    [ BOSS_TYPE.SUPER ] = 259200
}

ROOM_TYPE =
{
    OTHER = 1,
    NPC = 2,
    MC = 3,
}


--邮件
MAIL_CLASS = {
    PLAYER  = 1,  -- 玩家
    FIGHT   = 2,  -- 战斗
    SYSTEM  = 3,  -- 系统
    REPORT  = 4,  -- 报告
    UNION   = 5,  -- 军团
}

MAIL_PLAYER_MODE = {
    CHAT = 1,  --玩家聊天
}

MAIL_FIGHT_MODE = {
    SPY = 1,  -- 侦查
    BE_SPY = 2,  -- 被侦查
    ATTACK_SUCCESS = 3,  -- 进攻成功
    ATTACK_FAIL = 4,  -- 进攻失败
    DEFEND_SUCCESS = 5,  -- 防守成功
    DEFEND_FAIL = 6,  -- 防守失败
}

MAIL_SYSTEM_MODE = {
    NORMAL = 1,  -- 普通系统邮件
    UNION_INVITATION = 2, -- 军团邀请
    MOVE_CITY = 3, -- 邀请迁城
}

MAIL_REPORT_MODE = {
    GATHER = 1,  -- 采集
    JUNGLE = 2,  -- 打怪
    PANJUN = 3,  --叛军突袭活动 攻击NPC城市
    PANJUN2 = 4,  --叛军突袭活动 攻击玩家城堡
    GONGCHENG = 5, --攻城掠地活动
    KING = 6, --王者之战
    LOSTTEMPLE = 7, --遗迹塔
}

MAIL_UNION_MODE = {
    ANNOUNCE = 1,  --通知
}

--系统邮件界面元素
MAIL_SYSTEM_SEQ = {
    NOTICE = 1,         --公告标题
    PRESENT = 2,        --奖励标题
    CONTENT = 3,        -- 内容文字
    AWARD = 4,          -- 奖励
    RESPONSE = 5,       -- 应答按钮
}

MAIL_UNREAD_OP = {
    CLEAR_ALL = 1,
    ADD = 2,
    CONSUME = 3,
}



MOVE_CITY_MODE = {
    ADVANCED = 1, --高级迁城
    RANDOM = 2, --随机迁城
    GRADING = 4, --资源带迁城
}


-- Zhao@2016年11月23日 ：道具class类型的宏定义
ITEM_TYPE = {
    RES = 1,                --1、资源
    BOX = 2,                --2、箱子
    ACC_ITEM = 3,           --3、加速道具
    HERO_ITEM = 4,          --4、英雄碎片+英雄经验书
    HERO_SKILL = 5,         --5、英雄技能书
    EQUIP_CAILIAO = 6,      --6、装备材料
    CIVIL_FAMOUS = 7,       --7、名产
    BUFF_ITEM = 8,          --8、buff类道具
    SOLDIER_ITEM = 9,       --9、直接获得士兵
    MOVECITY = 10,          --10、迁城道具
    MARCH_ITEM = 11,        --11、行军道具+城建道具
    FRAGMENT = 12,          --12、碎片
    ACTIVITY_ITEM = 13,     --13、以后的活动道具
    OTHER = 20,             --20、杂项，对于无法进行归类，同时由于过于零散，无法新建class的  
}

-- Hx@2015-12-04 : union state in player eye
UNION_STATE = {
    NONE = 0,
    APPLYING = 1,
    IN_UNION = 2,
    ENEMY = 3,
}

----军团战争动员价格(金币)，客户端已引用
UNION_MOBILIZE_PRICE = 20000
UNION_MOBILIZE_EFFECTID = resmng.BUFF_90001001

--军团距离
UNION_RANGE = {
    NEAR =1,
    NORMAL = 2,
    FAR = 3,
}

UNION_RELATION = {
    -- PARTNER     = 1,
    FRIEND      = 1,
    NORMAL      = 2,
    ENEMY       = 3,
    -- DEAD        = 5,
    MAX         = 4,
}

-- Hx@2015-12-08 :
UNION_MASS_STATE = {
    CREATE = 0,
    UPDATE = 1,
    DESTORY = 2,
    FINISH = 3,
}

--- Zhao@2016年4月14日：军团创建条件
CREATEUNION = {
    lv = 5,
    cost = 1000
}

--- 军团科技捐献清除cd价格表
CLEAR_DONATE_COST = {100,250,250,350,350,600}

---弹劾军团长价格
UNION_IMPEACH_PRICE = 1000

---军团建筑受成员数量控制配置表
-- [1] = 基础值，达到这个值可以获得2个联盟奇迹
-- [2] = 步进值，每满足一个步进值，奇迹数+1
UNION_CASTALCOUNT_LIMIT = {1,1}

---军团设施类别，决定了会在军团设施页面显示多少种类别
UNION_CONSTRUCT_TYPE =
{
    MIRACAL = 1,    --奇迹
    RESTORE = 2,    --仓库
    SUPERRES = 3,   --超级矿
--    TUTTER = 4,     --箭塔
    MARCKET = 5     --市场
}

---军团领地争夺战可以占领的城市数量限制
-- [1] = 基础值，达到这个值可以占领一个系统城
-- [2] = 步进值，每满足一个步进值，可占领系统城市数量加 1
UNION_OCCUPY_LIMIT = {2,1}

----军团帮助的类型
HELP_TYPE =
{
    CONSTRUCT = 1,   ---建造
    UPGRADE = 2,     ---升级
    CAST = 3,        ---铸造
    HEAL = 4,        ---治疗
    RESEARCH = 5,    ---研究
}


---军团权限对应的key
UNION_POWER =
{
    CREATE = "Create",                      ---创建
    DESTORY = "Destory",                    ---解散
    JOIN = "Join",                          ---加入
    QUIT = "Quit",                          ---退出
    CHGNAME = "ChgName",                    ---改名
    CHGALIAS = "ChgAlias",                  ---改简称
    CHGFLAG = "ChgFlag",                    ---改旗帜
    TRANS = "Trans",                        ---转让
    CHGRANKALIAS = "ChgRankAlias",          ---修改阶级称谓
    BUILDUP = "BuildUp",                    ---建筑升级
    BUILDPLACE = "BuildPlace",              ---放置建筑
    DIPLOMACY = "Diplomacy",                ---外交
    ENOUNCE = "Enounce",                    ---修改宣言
    CHGRECRUIT = "ChgRecruit",              ---公开招募开关
    CHGRANK = "ChgRank",                    ---阶级调整
    KICK = "Kick",                          ---踢人
    INVITE = "Invite",                      ---邀请/同意申请
    TECHUP = "TechUp",                      ---升级科技
    SETNOTEIN = "SetNoteIn",                ---设置对内公告
    MEMMARK = "MemMark",                    ---人员标注
    ADDITEM = "AddItem",                    ---采购军团道具
    MISSION = "Mission",                    ---军团任务
    WITHDRAW = "Withdraw",                 ---领地争夺弃城
    WRITEINWORDS = "Writeinwords",          ---写军团内部留言
    UPDATEINWORDS = "Updateinwords",        ---管理军团留言
    APPOINT = "Appoint",                    ---王城战任命国王
    MONSTERCITY = "MonsterCity",            ---设置怪物攻城时间
    IMPEACH = "Impeach",                    ---弹劾军团长的权限
    GLOBAL = "Global",                      ---军团全局权限：军团长才有权限
    GLOBAL2 = "Global2",                    ---军团全局权限：只有R4,R5才有权限
    CHGLAN = "ChgLan",
}

TroopStatus = {
    Wait        = 1,
    Moving      = 2,
    Stop        = 3,

}

SPEED_GATHER = {
    40320,
    45360,
    50400,
    55440,
    60480,
}

-- prepare  = V + 000
-- go       = V + 100
-- action   = V + 200
-- back     = V + 300

CastleState = {
    Shell = 1,
    ShellRokie = 2,
    ShellCross = 3,
    AntiSpy = 4,
    Imprison = 5,
    RecallTroop = 6,
    DeFire =7,
}

TroopState = {
    Mobilize = 1,
    TurboSpeed = 2,
}

TroopAction = {
    DefultFollow    = 1,   --默认玩家身上额troop
    --Wait            = 2,   --等待
    SiegePlayer     = 3,   --单独攻击玩家城堡
    Back            = 4,   --通常返回
    JoinMass        = 5,   --参加集结
    HoldDefense     = 6,   --驻守
    Mass            = 7,   --发起集结
    Gather          = 8,   --采集
    SiegeMonster    = 9,   --单独攻击Monster
    Monster         = 10,  --怪物部队
    Spy             = 11,  --侦查
    SiegeCamp       = 12,  --攻击帐篷
    SaveRes         = 13,  --盟仓库存资源
    GetRes          = 14,  --盟仓库取资源
    UnionBuild      = 15,  --建造联盟建筑
    UnionFixBuild   = 16,  --修联盟建筑
    -- WaitMass        = 17,  --集结中
    -- MassMonster     = 18,  --集结攻击Monster
    BuySpecialty    = 19,  --买特产
    ConfirmSpecialty = 20, --上架特产 -- useless
    CancleSpecialty = 21,  --下架特产 -- useless
    --UnionBuilding   = 22,  --建造联盟建筑ing
    UnionUpgradeBuild = 23,  --升级建筑
    SupportArm      = 35,    -- 士兵援助
    SupportRes      = 36,    -- 物资援助
    Camp            = 37,   -- 野外帐篷
    Declare         = 24,  --领土争夺宣战
    SiegeNpc        = 25,  --单独攻击NPC city               -- 领地争夺, lost temple -- player attack npc city
    Tower           = 26,  --箭塔攻击为 模拟部队攻击
    King            = 27,  --攻击王城相关建筑
    HeroBack        = 28,  --英雄逃回家
    MonsterAtkPly   = 29,    -- 怪物攻打玩家                --叛军突袭
    SiegeMonsterCity= 30,    -- 怪物攻打玩家占领NPC      --叛军突袭
    SiegeTaskNpc    = 31,   --攻击任务怪
    AtkMC           = 32,   --玩家攻打怪物城市                     --叛军突袭
    SiegeUnion      = 33,
    LostTemple      = 34,   --攻打遗迹塔
    Refugee      = 38,   --攻打难民营
    HoldDefenseNPC = 39, -- 驻守NPC
    HoldDefenseKING = 40, --驻守王城
    HoldDefenseLT = 41, --驻守遗迹塔
}

WatchTowerAction = {
    [TroopAction.SiegePlayer] = 1,
    [TroopAction.Spy] = 1,
    [TroopAction.SiegeCamp] = 1,
    [TroopAction.SupportArm] = 1,
    [TroopAction.SupportRes] = 1,
    [TroopAction.MonsterAtkPly] = 1,
    [TroopAction.Gather] = 1,
}

TroopTimerCallBack = {
    StartMarch      = 1, --开始行军
    StartGather     = 2, --开始采集
    StartUnionGather= 3, --开始采集联盟矿
}

MassTime = {
    Level1 = 300,
    Level2 = 900,
    Level3 = 1800,
    Level4 = 3600,
}

--特殊情况固定行军速度，每分钟的速度

TroopSpeed = {
    [ TroopAction.Spy ] = 100,
    [ TroopAction.SaveRes ] = 10,
    [ TroopAction.SupportRes ] = 10,
    [ TroopAction.GetRes ] = 10,
    [ TroopAction.Declare ] = 100,
    [ TroopAction.SiegeMonsterCity ] = 20,
    [ TroopAction.MonsterAtkPly ] = 20,
}

--侦查类型
SpyType = {
    Castle = 1, --玩家城堡
    Res = 2,    --资源点
    Camp = 3,   --驻军
    UnionMiracal = 4, --军团奇迹
    NpcCity = 5,--Npc城市
    DefenceTower = 6, --守卫塔
    Fort = 7,       --要塞
    KingCity = 8,   --王城
    LostTemple = 9, --遗迹
}

BigMapState = {
    normal = 1,
    war = 2,
}

Gather_Level = { 1, 1, 10, 15 }

--EidType = {
--    Player = 0,
--    Res = 1,
--    Troop = 2,
--    Monster = 3,
--    UnionBuild = 4,
--    NpcCity = 5,
--    KingCity = 6,
--    Camp = 7,
--    MonsterCity = 8,
--    LostTemple = 9,
--}

EidType = {
    Player = 0,
    Res = 1,
    Monster = 2,
    NpcCity = 3,
    KingCity = 4,
    Camp = 5,
    MonsterCity = 6,
    LostTemple = 7,
    UnionBuild = 10,
    Troop = 11,
    CLOWN = 12,
    Wander = 13,
    Refugee = 14,
}

--聊天频道枚举
ChatChanelEnum = {
    World = 0,        --世界
    Union = 1,        --军团
    Culture = 2,      --文明
    Notice = 3,       --for item ITEM_NOTICE redmine 13106
}

TECH_DONATE_TYPE = {
    PRIMARY = 1,    --初级
    MEDIUM = 2,     --中级
    SENIOR = 3,     --高级
}


---军团科技层级开放配置，必须比最后一层配置多一个值，不可达到的极限值
TechValidCond = {0,10,100,200,1000}
-- 资源田加速
ACC_RES_COST = {30,30,50,70}  -- 金币消耗
ACC_RES_ITEM = {resmng.ITEM_8009002, resmng.ITEM_8009001, resmng.ITEM_8009003, resmng.ITEM_8009004}
ACC_RES_BUFF = {resmng.BUFF_52001001, resmng.BUFF_52002001, resmng.BUFF_52003001, resmng.BUFF_52004001}

--------------------------------------------------------------------------------
-- Build begin.
-- TODO: 把这里的 CLASS MODE NUM 改成配置

BUILD_CLASS = {
    FUNCTION = 0,     -- 功能建筑
    RESOURCE = 1,     -- 资源田(农田、伐木场、铁矿厂、能源石)
    ARMY     = 2,     -- 造兵建筑
    UNION    = 10,    -- 军团建筑
}

BUILD_FUNCTION_MODE = {
    CASTLE          = 0,     -- 城堡
    ALTAR           = 1,     -- 祭坛
    WALLS           = 2,     -- 城墙
    DAILYQUEST      = 3,     -- 行宫
    STOREHOUSE      = 4,     -- 仓库
    MARKET          = 5,     -- 市场
    BLACKMARKET     = 6,     -- 黑市
    RESOURCESMARKET = 7,     -- 物资市场
    PRISON          = 8,     -- 监狱
    FORGE           = 9,     -- 铁匠铺
    ACADEMY         = 10,    -- 研究院
    HALLOFHERO      = 11,    -- 英雄大厅
    EMBASSY         = 12,    -- 大使馆
    HALLOFWAR       = 13,    -- 战争大厅
    WATCHTOWER      = 14,    -- 瞭望塔
    TUTTER_LEFT     = 15,    -- 左箭塔
    HELP            = 16,    -- 公告牌
    DRILLGROUNDS    = 17,    -- 校场
    MILITARYTENT    = 18,    -- 训练营
    HOSPITAL        = 19,    -- 医疗所
    TUTTER_RIGHT    = 20,    -- 右箭塔
    SHIPYARD        = 21,    -- 飞艇
    MASCOTPLAT      = 22,    -- 吉祥物
    MANORMALL       = 23,    -- 领地争夺商店
    MONSTERMALL     = 24,    -- 怪物攻城商店
    RELICMALL       = 25,    -- 遗迹塔商店
}

BUILD_RESOURCE_MODE = {
    FARM        = 1,  -- 农田
    LOGGINGCAMP = 2,  -- 伐木场
    MINE        = 3,  -- 铁矿厂
    QUARRY      = 4,  -- 能源石
}

BUILD_ARMY_MODE = {
    BARRACKS = 1,  -- 兵营
    STABLES  = 2,  -- 马厩
    RANGE    = 3,  -- 靶场
    FACTORY  = 4,  -- 工坊
}

--BUILD_UNION_MODE
resmng.CLASS_UNION_BUILD_CASTLE_EAST = 21           --大奇迹，东
resmng.CLASS_UNION_BUILD_CASTLE_SOUTH = 22          --大奇迹，南
resmng.CLASS_UNION_BUILD_CASTLE_WEST = 23           --大奇迹，西
resmng.CLASS_UNION_BUILD_CASTLE_NORTH = 24          --大奇迹，北
resmng.CLASS_UNION_BUILD_MINI_CASTLE_EAST = 31      --小奇迹，东
resmng.CLASS_UNION_BUILD_MINI_CASTLE_SOUTH = 32     --小奇迹，南
resmng.CLASS_UNION_BUILD_MINI_CASTLE_WEST = 33      --小奇迹，西
resmng.CLASS_UNION_BUILD_MINI_CASTLE_NORTH = 34     --小奇迹，北
resmng.CLASS_UNION_BUILD_MARKET = 3          --市场
resmng.CLASS_UNION_BUILD_RESTORE = 4         --仓库
resmng.CLASS_UNION_BUILD_TUTTER1 = 5         --箭塔1
resmng.CLASS_UNION_BUILD_TUTTER2 = 6         --箭塔2
resmng.CLASS_UNION_BUILD_FARM = 7            --农田
resmng.CLASS_UNION_BUILD_LOGGINGCAMP = 8     --木厂
resmng.CLASS_UNION_BUILD_MINE = 9            --铁矿厂
resmng.CLASS_UNION_BUILD_QUARRY = 10         --能源石

-- 建筑数量上限
BUILD_MAX_NUM = {
    [BUILD_CLASS.FUNCTION] = {
        [BUILD_FUNCTION_MODE.CASTLE]          = 1,  -- 城堡
        [BUILD_FUNCTION_MODE.ALTAR]           = 1,  -- 祭坛
        [BUILD_FUNCTION_MODE.WALLS]           = 1,  -- 城墙
        [BUILD_FUNCTION_MODE.DAILYQUEST]      = 1,  -- 行宫
        [BUILD_FUNCTION_MODE.STOREHOUSE]      = 1,  -- 仓库
        [BUILD_FUNCTION_MODE.MARKET]          = 1,  -- 市场
        [BUILD_FUNCTION_MODE.BLACKMARKET]     = 1,  -- 黑市
        [BUILD_FUNCTION_MODE.MONSTERMALL]     = 1,  -- 怪物攻城商店
        [BUILD_FUNCTION_MODE.MANORMALL]       = 1,  -- 领地争夺商店
        [BUILD_FUNCTION_MODE.RELICMALL]       = 1,  -- 遗迹塔商店
        [BUILD_FUNCTION_MODE.RESOURCESMARKET] = 1,  -- 物资市场
        [BUILD_FUNCTION_MODE.PRISON]          = 1,  -- 监狱
        [BUILD_FUNCTION_MODE.FORGE]           = 1,  -- 铁匠铺
        [BUILD_FUNCTION_MODE.ACADEMY]         = 1,  -- 研究院
        [BUILD_FUNCTION_MODE.HALLOFHERO]      = 1,  -- 英雄大厅
        [BUILD_FUNCTION_MODE.EMBASSY]         = 1,  -- 大使馆
        [BUILD_FUNCTION_MODE.HALLOFWAR]       = 1,  -- 战争大厅
        [BUILD_FUNCTION_MODE.WATCHTOWER]      = 1,  -- 瞭望塔
        [BUILD_FUNCTION_MODE.TUTTER_LEFT]     = 1,  -- 箭塔
        [BUILD_FUNCTION_MODE.TUTTER_RIGHT]    = 1,  -- 箭塔
        [BUILD_FUNCTION_MODE.HELP]            = 1,  -- 公告牌
        [BUILD_FUNCTION_MODE.DRILLGROUNDS]    = 1,  -- 校场
        [BUILD_FUNCTION_MODE.SHIPYARD]        = 1,  -- 飞艇
        [BUILD_FUNCTION_MODE.MILITARYTENT]    = 8,  -- 训练营
        [BUILD_FUNCTION_MODE.HOSPITAL]        = 8,  -- 医疗所
    },
    [BUILD_CLASS.RESOURCE] = {
        [BUILD_RESOURCE_MODE.FARM]        = 8,  -- 农田
        [BUILD_RESOURCE_MODE.LOGGINGCAMP] = 8,  -- 伐木场
        [BUILD_RESOURCE_MODE.MINE]        = 8,  -- 铁矿厂
        [BUILD_RESOURCE_MODE.QUARRY]      = 8,  -- 能源石
    },
    [BUILD_CLASS.ARMY] = {
        [BUILD_ARMY_MODE.BARRACKS] = 1,  -- 兵营
        [BUILD_ARMY_MODE.STABLES]  = 1,  -- 马厩
        [BUILD_ARMY_MODE.RANGE]    = 1,  -- 靶场
        [BUILD_ARMY_MODE.FACTORY]  = 1,  -- 工坊
    },
}

-- 建筑状态
BUILD_STATE = {
    DESTROY = 0,   -- 被拆除
    CREATE  = 1,   -- 修建
    WAIT    = 2,   -- 待机状态
    WORK    = 3,   -- 生效中/训练中/治疗中/科技研究/锻造
    UPGRADE = 4,   -- 升级中
    FIX     = 5,   -- 修理中
}



CANCEL_BUILD_FACTOR = 0.6  -- 取消建筑操作返还的资源比率(向上取整)
DESTROY_FIELD_FACTOR = 20  -- 拆除野地耗时:Lv*20
-- Build end.
--------------------------------------------------------------------------------
-- Hx@2016-01-04 : 数据操作类型
OPERATOR = {
    ADD = 1,        --增
    UPDATE = 2,     --改
    DELETE = 3,     --删
}

-- 加速方式
ACC_TYPE = {
    FREE = 1,
    GOLD = 2,
    ITEM = 3,
}

-- 道具class种类
ITEM_CLASS = {
    RES   = 1,  -- 资源
    BOX   = 2,  -- 箱子
    SPEED = 3,  -- 加速道具
    HERO  = 4,  -- 英雄碎片和经验
    SKILL = 5,  -- 英雄技能
    MATERIAL = 6, -- 装备的材料
    TRIBUTE = 7,  --名产
    BUFF = 8, -- buff类
    GLOBUFF = 9, -- 直接获得士兵
    MOVE_CITY = 10, -- 迁城道具
    UINBUFF = 11, -- 行军道具+城建道具
    ITEM_PIECE = 12, -- 道具碎片
    ACTIVITY = 13, -- 活动道具
    OTHER = 20, -- 特殊物品
}
-- 道具mode
ITEM_MODE = {
    -- class 1
    FOOD = 1,
    WOOD = 2,
    IRON = 3,
    ENERGY = 4,
    SILVER = 5,
    LORD_EXP = 12,
    LORD_SINEW = 14,
    -- CLASS OTHER
    VIP_POINT = 1,
    VIP_TIME = 2,

}

-- buff mode
BUFF_MODE = {
    PROTECT = 1, --保护罩
    BUILD_LIST = 12, --建筑队列
}

-- 加速MODE分类
ITEM_SPEED_MODE = {
    COMMON = 1,    -- 通用加速
    LV_UP  = 2,    -- 建筑加速
    TECH  = 3,    -- 科技加速
    TRAIN  = 4,    -- 造兵加速
    CURE   = 5,    -- 治疗加速
    MARCH   = 6,    --行军加速
}

-- 英雄道具
ITEM_HERO_MODE = {
    HERO_CARD           = 1,  -- 英雄卡
    PIECE               = 2,  -- 英雄碎片
    EXP_BOOK            = 3,  -- 英雄经验书
    RESET_NAME          = 4,  -- 改名卡
    RESET_PERSONALITY   = 5,  -- 重置个性
}

-- 技能道具
ITEM_SKILL_MODE = {
    SPECIAL_BOOK = 1,  -- 特定技能书
    COMMON_BOOK  = 2,  -- 通用技能书
    RESET_BOOK   = 3,  -- 重置技能书
}

UNION_MODE = {--军团事件操作
    ADD = 1,        --增
    UPDATE = 2,     --改
    DELETE = 3,     --删
    OK = 4,         --完成
    GET = 5,        --接受
    WIN = 6,
    FAIL = 7,
    RANK_UP = 8,
    RANK_DOWN = 9,
    TITLE = 10,
}

UNION_EVENT = { --  军团事件类型
    TECH = "tech_up",
    MEMBER = "member",
    INFO = "info",
    BUILDLV = "buildlv",
    BUILD_SET  = "build_set",
    MISSION  = "mission",
    TASK  = "task",
    FIGHT = "fight",
    REJECT = "union_reject",
    HELP = "help",
    RELATION = "relation",
}



EVENT_TYPE = {
    UNION_CREATE = 1,
    UNION_DESTORY = 2,
    UNION_JOIN = 3,
    UNION_QUIT = 4,
    UNION_KICK = 5,
    SET_NOTE_IN = 6,
    SET_RANK = 7,
    SET_TECH = 8,
    FIGHT = 10,
}

-- Hx@2016-01-08 : effect类型，配置表使用,此枚举用于检查唯一性
-- 1.数值类使用此定义
-- 2.因子类使用 xxRate
EFFECT_TYPE = {
    MaxSoldier = true,
    TrainCount = true,
    TrainSpeed = true,
    FoodUse = true,
    FoodSpeed = true,
    FoodCount = true,
    WoodSpeed = true,
    GatherSpeed = true,
    TroopExtra = true,

    FoodSpeedR   = true,
    WoodSpeedR   = true,
    IronSpeedR   = true,
    EnergySpeedR = true,
    TrainSpeedR  = true,
    CureSpeedR   = true,
    LearnSpeedR  = true,

     Atk_R = true,
    Atk1_R = true,
    Atk2_R = true,
    Atk3_R = true,
    Atk4_R = true,

    AAtk1_R = true,
    AAtk2_R = true,
    AAtk3_R = true,
    AAtk4_R = true,

     Def_R = true,
    Def1_R = true,
    Def2_R = true,
    Def3_R = true,
    Def4_R = true,

    Imm = true,
    Imm1 = true,
    Imm2 = true,
    Imm3 = true,
    Imm4 = true,

     Imm_R = true,
    Imm1_R = true,
    Imm2_R = true,
    Imm3_R = true,
    Imm4_R = true,

    DImm1_R = true,
    DImm2_R = true,
    DImm3_R = true,
    DImm4_R = true,
}

-- -----------------------------------------------------------------------------
-- Hx@2016-01-26 : 行军速度倍率
-- -----------------------------------------------------------------------------
TROOP_STDSPEED = 10


-- Hx@2015-12-03 : ErrorCode
E_OK = 0
E_FAIL = 1

-- judge
E_DISALLOWED = 2
E_TIMEOUT = 3
E_MISC = 4

E_ALREADY_IN_UNION = 101

-- lack of something
E_NO_TROOP = 1001
E_NO_MASS = 1002
E_NO_PLAYER = 1003
E_NO_UNION = 1004
E_NO_ENEMY = 1005
E_NO_CONF = 1006
E_NO_RMB = 1007
E_NOT_ENOUGH_SOLDIER = 1008
E_NO_HERO = 1009
E_NO_SOLDIER = 1010
E_HERO_BUSY = 1011
E_NO_REPORT = 1012
E_NO_ROOM = 1013
E_TROOP_BUSY = 1014
E_DUP_NAME = 1015
E_CONDITION_FAIL = 1016
E_CONSUME_FAIL = 1017
E_DUP_ALIAS = 1018
E_HP = 1019
E_NO_BUILD = 1020
E_NO_VIP = 1021
E_LV = 1022


-- overflow
E_MAX_LV = 2001
E_TOO_MUCH_SOLDIER = 2002

E_ALREADY_CURE = 2003
E_NO_HURT = 2004
E_NO_RES = 2005
E_NO_COUNT = 2006


E_DUP = 3001



--------------------------------------------------------------------------------
-- Hero Begin.   YC@2015-12-30
-- 属性
HERO_ATTR_TYPE = {
    ATTACK  = 1,    -- 攻击
    DEFENSE = 2,    -- 防御
    TANK    = 3,    -- 生命
    ALL     = 4,    -- 全能
}

-- 天性
HERO_NATURE_TYPE = {
    STRICT   = 1,    -- 严谨
    FEARLESS = 2,    -- 无谓
    CALM     = 3,    -- 冷静
    BOLD     = 4,    -- 豪放
}

-- 文明
CULTURE_TYPE = {
    EAST  = 1,    -- 东方 (华夏，日本，朝鲜)
    SOUTH = 2,    -- 南方 (阿拉伯，波斯)
    WEST  = 3,    -- 西方 (西欧，美国)
    NORTH = 4,    -- 北方 (斯拉夫，蒙古)
}

-- 状态
HERO_STATUS_TYPE = {
    FREE             = 1,    -- 待机
    BUILDING         = 2,    -- 城建中
    DEFENDING        = 3,    -- 驻守中
    MOVING           = 4,    -- 行军中
    GATHER           = 5,    -- 采集中
    BEING_CURED      = 6,    -- 治疗中
    BEING_CAPTURED   = 7,    -- 被俘虏
    BEING_IMPRISONED = 8,    -- 被监禁
    BEING_EXECUTED   = 9,    -- 处决中
    DEAD             = 10,   -- 死亡
    DESTROY          = 11,   -- 解雇
}

-- 品质
HERO_QUALITY_TYPE = {
    ORDINARY  = 1,    -- 普通
    GOOD      = 2,    -- 优秀
    EXCELLENT = 3,    -- 精良
    EPIC      = 4,    -- 史诗
    LEGENDARY = 5,    -- 传说
    GODLIKE   = 6,    -- 神级
}

-- 技能 CLASS
SKILL_CLASS = {
    ATTACK  = 1,  --  攻击类技能
    BUILD   = 2,  --  城建类技能
    DEFENSE = 3,  --  防御类技能
    TACTICS = 4,  --  战法类技能
    SPECIAL = 5,  --  特殊类技能
    CONTROL = 6,  --  统御类技能
    --TALENT  = 7,  --  特技
    TALENT  = 20,  --  特技
}

SKILL_TYPE = {
    FIGHT_TALENT = 0, -- 特技, 一个， 英雄自带。
    FIGHT_BASIC = 1,  -- 战斗被动技能，多个，需要学习。
    BUILD = 2,  -- 城建技能
    FIGHT_AFTER_FIGHT = 3,  -- 战斗结算技能
    LORD = 4,  -- 领主技能
}

-- 英雄卡折算成碎片时的比例
HERO_CARD_2_PIECE_RATIO = 1

-- 重置技能时经验返回比例
RESET_SKILL_RETURN_RATIO = 0.5

-- 分解英雄时的经验值返回比例
DESTROY_HERO_RETURN_RATIO = 0.7

-- 取消治疗时的资源返还比例
CANCEL_CURE_RETURN_RATIO = 0.5

-- 英雄俘虏玩法开启所需的主城等级
CAPTURE_LV_LIMIT = 10

-- 英雄被处死后的复活时限(单位天)
RELIVE_HERO_DAYS_LIMIT = 7

-- 前端显示英雄数值除以数值
HERO_SHOW_HP_RATE = 265  -- 血量
HERO_SHOW_ATT_RATE = 10  -- 攻防

-- Hero End.
-------------------------------------------------------------------------------------

--活跃度
-- TASK_ACTIVITY = {
--     [1] = 20,
--     [2] = 40,
--     [3] = 70,
--     [4] = 100,
--     [5] = 120,
-- }

--活跃度
TASK_ACTIVITY = {
    [1] = 24,
    [2] = 48,
    [3] = 72,
    [4] = 96,
    [5] = 120,
}
--任务定义
TASK_TYPE = {
    TASK_TYPE_INVALID       = 0,
    TASK_TYPE_TRUNK         = 1,    --主线任务
    TASK_TYPE_BRANCH        = 2,    --支线任务
    TASK_TYPE_DAILY         = 3,    --日常任务
    TASK_TYPE_UNION         = 4,    --军团任务
    TASK_TYPE_TARGET        = 5,    --目标任务
}
-- 任务前置类型
TASK_COND_TYPE = {
    PLAYER_LV = 1,
    CASTLE_LV = 2,
    UNION_LV = 3,
}

TASK_STATUS = {
    TASK_STATUS_INVALID             = 0,
    TASK_STATUS_LOCK                = 1,    --未解锁
    TASK_STATUS_CAN_ACCEPT          = 2,    --可以接收
    TASK_STATUS_ACCEPTED            = 3,    --已接收(正在进行)
    TASK_STATUS_CAN_FINISH          = 4,    --可以领取
    TASK_STATUS_FINISHED            = 5,    --已完成（已领取）
}

UNION_MISSION_TM = 180
UNION_MISSION_CLASS = {
    BUILD       =1,
    HELP        =2,
    DONATE      =3,
    ACTIVE      =4, --积分
    GATHER      =5,
    POW         =6,
    GOD         =7,
    COST        =8,
}

TASK_ACTION = {
    INVALID                         = 0,
    ATTACK_SPECIAL_MONSTER          = 1,    --攻击特定怪物
    ATTACK_LEVEL_MONSTER            = 2,    --攻击等级怪物
    BATTLE_LIANDONG                 = 3,    --单场战斗进行联动
    BATTLE_DAMAGE                   = 4,    --单场战斗战损比
    SPY_PLAYER_CITY                 = 5,    --侦查玩家城堡
    SLOW_SPEED                      = 6,    --单次行军加速减少时间
    ATTACK_PLAYER_CITY              = 7,    --攻击玩家城堡
    LOOT_RES                        = 8,    --抢夺资源数量
    SPY_NPC_CITY                    = 9,    --侦查系统城市
    ATTACK_NPC_CITY                 = 10,    --攻击系统城市
    OCC_NPC_CITY                    = 11,    --占领系统城市
    HAS_HERO_NUM                    = 12,    --持有英雄数量
    HERO_LEVEL_UP                   = 13,    --提升英雄等级
    LEARN_HERO_SKILL                = 14,    --学习英雄技能
    JOIN_PLAYER_UNION               = 15,    --加入玩家军团lxz
    JOIN_MASS                       = 16,    --参与军团集结
    UNION_TECH_DONATE               = 17,    --军团科技捐献lxz
    UNION_SHESHI_DONATE             = 18,    --军团设施捐献lxz
    UNION_HELP_NUM                  = 19,    --军团帮助次数
    UNION_AID                       = 20,    --军团援助
    GATHER                          = 21,    --采集资源
    GET_ITEM                        = 22,    --收集物品
    GET_EQUIP                       = 23,    --收集品质装备
    USE_ITEM                        = 24,    --使用道具
    MARKET_BUY_NUM                  = 25,    --市场购买次数lxz
    CITY_BUILD_LEVEL_UP             = 26,    --升级城建
    OPEN_RES_BUILD                  = 27,    --开启野地
    RES_OUTPUT                      = 28,    --资源产量
    STUDY_TECH                      = 29,    --研究科技
    RECRUIT_SOLDIER                 = 30,    --招募士兵
    CURE                            = 31,    --治疗单位
    MAKE_EQUIP                      = 32,    --铸造装备
    SYN_MATERIAL                    = 33,    --合成材料
    MONTH_AWARD                     = 34,    --签到
    DAY_AWARD                       = 35,    --飞艇（码头）领取
    OPEN_UI                         = 36,    --打开界面
    VISIT_NPC                       = 37,    --拜访NPC
    GET_RES                         = 38,    --收获士兵/资源
    SUPREME_HERO_LEVEL              = 39,    --英雄技能达到某一等级
    ROLE_LEVEL_UP                   = 40,    --提升领主等级
    GACHA_MUB                       = 41,    --抽卡次数
    CAPTIVE_HERO                    = 42,    --俘虏英雄
    PROMOTE_HERO_LEVEL              = 43,    --提升英雄技能
    HERO_EXP                        = 44,    --提升英雄经验
    STUDY_TECH_MUB                  = 45,    --研发科技次数
    CITY_BUILD_MUB                  = 46,    --升级城建次数
    KILL_SOLDIER                    = 47,    --击杀士兵数量
    GOLD_ACC                        = 48,    --金币加速
    PROMOTE_POWER                   = 49,    --提升战力途径
    DEAD_SOLDIER                    = 50,    --阵亡士兵数量
    HERO_STATION                    = 51,    --派遣驻守英雄
    WORLD_CHAT                      = 52,    --世界频道说话
    FINISH_DAILY_TASK               = 53,    --完成日常任务
    FINISH_UNION_TASK               = 54,    --完成军团任务
    MOVE_TO_ZONE                    = 55,    --迁城到资源带
    PANJUN_SCORE                    = 56,    --叛军突袭活动获得积分
    LOSTTEMPLE_SCORE                = 57,    --遗迹塔获得贤者之石
    TROOP_TO_KING_CITY              = 58,    --向王城行军
}
-- 打开UI任务
TASK_UI_ID = {
    UNION_MAIN = 1,  -- 军团主界面
    TECH_DONATE = 2,  -- 科技捐献
    FAST_ARMY = 3,  -- 快捷招募
    FAST_BUILD = 4,  -- 快捷建筑
    HERO_MAIN = 5,  -- 英雄主界面
    DAILY_TASK = 6, --日常任务
    BALCK_MARKET = 7, --黑市
    ACHIEVE = 8, --成就
}

g_task_func_relation = {
["attack_special_monster"] = TASK_ACTION.ATTACK_SPECIAL_MONSTER,   --攻击特定怪物
["attack_level_monster"] = TASK_ACTION.ATTACK_LEVEL_MONSTER,       --攻击等级怪物
["battle_liandong"] = TASK_ACTION.BATTLE_LIANDONG,                --单场战斗进行联动
["battle_damage"] = TASK_ACTION.BATTLE_DAMAGE,                     --单场战斗战损比
["spy_player_city"] = TASK_ACTION.SPY_PLAYER_CITY,                 --侦查玩家城堡
["slow_speed"] = TASK_ACTION.SLOW_SPEED,                           --单次行军加速减少时
["attack_player_city"] = TASK_ACTION.ATTACK_PLAYER_CITY,           --攻击玩家城堡
["loot_res"] = TASK_ACTION.LOOT_RES,                               --抢夺资源数量
["spy_npc_city"] = TASK_ACTION.SPY_NPC_CITY,                       --侦查系统城市
["attack_npc_city"] = TASK_ACTION.ATTACK_NPC_CITY,                 --攻击系统城市
["occ_npc_city"] = TASK_ACTION.OCC_NPC_CITY,                       --占领系统城市
["has_hero_num"] = TASK_ACTION.HAS_HERO_NUM,                       --持有英雄数量
["hero_level_up"] = TASK_ACTION.HERO_LEVEL_UP,                     --提升英雄等级
["learn_hero_skill"] = TASK_ACTION.LEARN_HERO_SKILL,               --学习英雄技能
["supreme_hero_level"] = TASK_ACTION.SUPREME_HERO_LEVEL,           --英雄技能达到某一等级
["join_player_union"] = TASK_ACTION.JOIN_PLAYER_UNION,             --加入玩家军团
["join_mass"] = TASK_ACTION.JOIN_MASS,                             --参与军团集结
["union_tech_donate"] = TASK_ACTION.UNION_TECH_DONATE,             --军团科技捐献
["union_sheshi_donate"] = TASK_ACTION.UNION_SHESHI_DONATE,         --军团设施捐献
["union_help_num"] = TASK_ACTION.UNION_HELP_NUM,                   --军团帮助次数
["union_aid"] = TASK_ACTION.UNION_AID,                             --军团援助
["gather"] = TASK_ACTION.GATHER,                                   --采集资源
["get_item"] = TASK_ACTION.GET_ITEM,                               --收集物品
["get_equip"] = TASK_ACTION.GET_EQUIP,                             --收集品质装备
["use_item"] = TASK_ACTION.USE_ITEM,                               --使用道具
["market_buy_num"] = TASK_ACTION.MARKET_BUY_NUM,                   --市场购买次数
["city_build_level_up"] = TASK_ACTION.CITY_BUILD_LEVEL_UP,         --升级城建
["open_res_build"] = TASK_ACTION.OPEN_RES_BUILD,                   --开启野地
["res_output"] = TASK_ACTION.RES_OUTPUT,                           --资源产量
["study_tech"] = TASK_ACTION.STUDY_TECH,                           --研究科技
["recruit_soldier"] = TASK_ACTION.RECRUIT_SOLDIER,                 --招募士兵
["cure"] = TASK_ACTION.CURE,                                       --治疗单位
["make_equip"] = TASK_ACTION.MAKE_EQUIP,                           --铸造装备
["syn_material"] = TASK_ACTION.SYN_MATERIAL,                       --合成材料
["month_award"] = TASK_ACTION.MONTH_AWARD,                         --签到
["day_award"] = TASK_ACTION.DAY_AWARD,                             --飞艇（码头）领取
["open_ui"] = TASK_ACTION.OPEN_UI,                                 --打开界面
["visit_npc"] = TASK_ACTION.VISIT_NPC,                             --拜访NPC
["get_res"] = TASK_ACTION.GET_RES,                                 --收获士兵/资源
["role_lv"] = TASK_ACTION.ROLE_LEVEL_UP,                           --提升领主等级
["gacha_mub"] = TASK_ACTION.GACHA_MUB,                             --抽卡次数
["captive_hero"] = TASK_ACTION.CAPTIVE_HERO,                       --俘虏英雄
["promote_hero_level"] = TASK_ACTION.PROMOTE_HERO_LEVEL,           --提升英雄技能
["hero_exp"] = TASK_ACTION.HERO_EXP,                               --提升英雄经验
["study_tech_mub"] = TASK_ACTION.STUDY_TECH_MUB,                   --研发科技次数
["city_build_mub"] = TASK_ACTION.CITY_BUILD_MUB,                   --升级城建次数
["kill_soldier"] = TASK_ACTION.KILL_SOLDIER,                       --击杀士兵数量
["gold_acc"] = TASK_ACTION.GOLD_ACC,                               --金币加速
["promote_power"] = TASK_ACTION.PROMOTE_POWER,                     --提升战力途径
["dead_soldier"] = TASK_ACTION.DEAD_SOLDIER,                       --阵亡士兵数量
["hero_station"] = TASK_ACTION.HERO_STATION,                       --派遣驻守英雄
["world_chat"] = TASK_ACTION.WORLD_CHAT,                           --世界频道说话
["finish_daily_task"] = TASK_ACTION.FINISH_DAILY_TASK,             --完成日常任务
["finish_union_task"] = TASK_ACTION.FINISH_UNION_TASK,             --完成军团任务
["move_to_zone"] = TASK_ACTION.MOVE_TO_ZONE,                       --迁城到资源带
["panjun_score"] = TASK_ACTION.PANJUN_SCORE,                       --叛军突袭活动获得积分
["losttemple_score"] = TASK_ACTION.LOSTTEMPLE_SCORE,               --遗迹塔获得贤者之石
["troop_to_king_city"] = TASK_ACTION.TROOP_TO_KING_CITY,           --向王城行军
}
-------------------------------------------------------------
--奖励
BONUS_TYPE = {
    BONUS_TYPE_ITEM         = "item",
    BONUS_TYPE_RES          = "res",
    BONUS_TYPE_RESPICKED    = "respicked",
    BONUS_TYPE_SOLDIER      = "soldier",
    BONUS_TYPE_HEROEXP      = "heroexp",
    BONUS_TYPE_HERO         = "hero",
}

-----------------------------------------------------------------
-- 装备位置
EQUIP_POS = {
    WEAPON = 1,
    HELMET = 2,
    CLOTH = 3,
    GLOVE = 4,
    TROUSERS = 5,
    SHOE = 6,
}
-----------------------------------------------------------------
--触发器

RANGE_EVENT_ID = {
    ENTER_RANGE        = 1,    --进入作用范围
    LEAVE_RANGE        = 2,    --离开作用范围
    ARRIVED_TARGET     = 3,    --到达目标
}

TRIGGERS_EVENT_ID = {
    TRIGGERS_BEGIN             = 0,  --起始值
    TRIGGERS_ACK               = 1,  --被攻击
    TRIGGERS_SLOW              = 3, --被减速

    ---------------------------------------------------------
    TRIGGERS_END               = 3,  --终止值（增加一个类型需要递增）
}
--------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--世界事件
WORLD_EVENT_ACTION = {
    CASTLE_LEVEL      = 1,         --升级城堡
    ATTACK_MONSTER    = 2,         --攻击怪物
    OCCUPY_CITY       = 3,         --占领城市
    HERO_NUM          = 4,         --收集英雄数量
    PANJUN_KILL       = 5,         --击杀叛军
    CURE_SOLDIER      = 6,         --治疗士兵
    UNION_TECH_NUM    = 7,         --军团数量
    GATHER_NUM        = 8,         --采集量
    OCCUPY_KING_CITY  = 9,         --占领王城
    MONSTER_POINT     = 10,        --击杀怪物获得积分
}

g_world_event_relation = {
    ["castle_level"] = WORLD_EVENT_ACTION.CASTLE_LEVEL,       --升级城堡
    ["attack_monster"] = WORLD_EVENT_ACTION.ATTACK_MONSTER,         --攻击怪物
    ["occupy_city"] = WORLD_EVENT_ACTION.OCCUPY_CITY,            --占领城市
    ["hero_num"] = WORLD_EVENT_ACTION.HERO_NUM,               --收集英雄数量
    ["panjun_kill"] = WORLD_EVENT_ACTION.PANJUN_KILL,            --击杀叛军
    ["cure_soldier"] = WORLD_EVENT_ACTION.CURE_SOLDIER,           --治疗士兵
    ["union_halltech_lv"] = WORLD_EVENT_ACTION.UNION_TECH_NUM,              --军团数量
    ["gather_num"] = WORLD_EVENT_ACTION.GATHER_NUM,             --采集量
    ["occupy_king_city"] = WORLD_EVENT_ACTION.OCCUPY_KING_CITY,       --占领王城
    ["monster_point"] = WORLD_EVENT_ACTION.MONSTER_POINT,   --击杀怪物获得积分
}

-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--运营活动类型
OPERATE_ACTIVITY_ACTION = {
    HEISHI            = 1,         --黑市购买
    WUZISHICHANG      = 2,         --物资市场
}

g_operate_activity_relation = {
    ["black_market"] = OPERATE_ACTIVITY_ACTION.BLACK_MARKET,       --黑市
    ["res_market"] = OPERATE_ACTIVITY_ACTION.RES_MARKET,         --物资市场
}

-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--周限时活动
WEEKLY_ACTIVITY_ACTION = {
    GATHER            = 1,         --采集
    TRAIN_ARM         = 2,         --训练士兵
    POWER_UP          = 3,         --提升战斗力
    ATK_MONSTER       = 4,         --攻击怪物
    GACHA             = 5,         --抽卡
    RES_MARKET        = 6,         --物资市场
    BLACK_MARKET      = 7,         --黑市
    KILL_ARM          = 8,         --攻击玩家击杀士兵
}

-------------------------------------------------------------------------------------




-- 日志中是否显示调试信息（文件名、函数名、行号）
SHOW_DEBUG_INFO = false

--奖励概率总和
AWARD_RANDOM_SUM = 10000

-- Certify Code
CertifyCode = {
    OK = 0,
    PASS_ERROR = 1,
    BLOCK = 2,
    DUPLICATE = 3,
}

--刷新日常任务的消耗
REFRESH_DAILY_TASK_CON = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, 200}}
--直接完成日常任务活跃度和金币的比率
DONE_DAILY_TASK_GOLD = 5

--抽卡
GACHA_TYPE = {
    YINBI_ONE = 1,  --银币单抽
    YINBI_TEN = 2,  --银币十连抽
    JINBI_ONE = 3,  --金币单抽
    JINBI_TEN = 4,  --金币十连抽
    HUNXIA_ONE = 5, --魂匣单抽
    HUNXIA_TEN = 6, --魂匣十连抽
}

-- LOST_TEMPLE
LT_STATE =
{
    LOCK = 0,
    ACTIVE = 1,
    DOWN = 2,
}

-- 建筑上部队绑定的类型 来攻击部队，出发部队
ETY_TROOP =
{
    ATK = "atk_troop_tag",
    LEAVE = "leave_troop_tag",
}

-- 积分商城类型
POINT_MALL = {
    MANOR = 1,      --领地
    MONSTER = 2,    --怪物
    RELIC = 3,      --遗迹塔
    KING = 4,       --国王
}

MALL_PAY_TYPE =
{
    "PayManor",
    "PayMonster",
    "PayRelic",
}

POINT_MALL_TYPE = {
    "manor_gold",
    "monster_gold",
    "relic_gold",
    "kw_gold",
}


--key, value:len
CLIENT_PARM = {
    ["report_lock_1"] = 2,
    ["report_read_1"] = 2,

    ["report_lock_2"] = 2,
    ["report_read_2"] = 2,

    ["report_lock_3"] = 2,
    ["report_read_3"] = 2,
    ["curguiding"] = 3,

    ["guidedclass"] = 800,
}

--重置技能消耗的金币
RESET_SKILL_GOLD = 250
--重置技能消耗的道具ID
RESET_SKILL_ITME = 5003001

function is_type( ety, typeid )
    if not ety then return end
    if type( ety ) == "number" then
        ety = gEtys[ ety ]
        if not ety then return end
    end
    return math.floor( ety.propid / 1000000 ) == typeid
end

function get_type(ety)
    if not ety  then return end
    if type( ety ) == "number" then
        ety = gEtys[ ety ]
        if not ety then return end
    end
    return math.floor( ety.propid / 1000000 )
end

function is_type_propid(propid, typeid)
    if not propid then return end
    
    return math.floor( propid / 1000000 ) == typeid
end


function is_ply(ety) return is_type( ety, EidType.Player ) end
function is_res(ety) return is_type( ety, EidType.Res ) end
function is_camp(ety) return is_type( ety, EidType.Camp ) end
function is_troop(ety) return is_type( ety, EidType.Troop ) end
function is_monster(ety) return is_type( ety, EidType.Monster ) end
function is_monster_city(ety) return is_type( ety, EidType.MonsterCity ) end
function is_king_city(ety) return is_type( ety, EidType.KingCity ) end
function is_lost_temple(ety) return is_type( ety, EidType.LostTemple ) end
function is_union_building(ety) return is_type( ety, EidType.UnionBuild ) end
function is_npc_city(ety) return is_type( ety, EidType.NpcCity ) end
function is_clown(ety) return is_type( ety, EidType.CLOWN ) end
function is_wander(ety) return is_type( ety, EidType.Wander ) end
function is_refugee(ety) return is_type( ety, EidType.Refugee ) end

function can_attack(ety)
    if is_ply(ety) then return true end
    if is_monster(ety) then return true end
    if is_res(ety) and ety.on then return true end
    return false
end


SEARCH_RANGE = {
[1] = {{0,0}},
[2] = {{1,0},{1,1},{0,1},{-1,1},{-1,0},{-1,-1},{0,-1},{1,-1}},
[3] = {{2,0},{2,1},{2,2},{1,2},{0,2},{-1,2},{-2,2},{-2,1},{-2,0},{-2,-1},{-2,-2},{-1,-2},{0,-2},{1,-2},{2,-2},{2,-1}},
}

OFFLINE_UNIT_TYPE = {
    NPC_MONSTER = 1,
}

--月卡总天数
YUEKA_TOTAL_DAYS = 30
--月卡打折时间
YUEKA_SALE_TIME = 259200 --3天

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
    flag = 1,
    reg_name = "unknown",
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
    sinew_tm = 0,
    sinew_speed = 0,
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
    showequip = 1,
    pow = 0,

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
    join_tm = 0, --  加入军团次数,

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
    lives = {},

    cures = {},     -- soldiers who are curing,
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
    cross_gs = 0, --所在服的id服 跨服用,

    qiri_time = 0, --七日登录时间
    qiri_num = 0, --七日登录已领次数

    nospeak_time = 0,
    nologin_time = 0,

    pay_state = {}, -- 玩家充值的相关状态

    tm_yueka_cur = 0,       --月卡当前领取天数
    tm_yueka_start = 0,     --月卡开始天数
    tm_yueka_end = 0,       --月卡结束天数
    yueka_level = 0,        --月卡档次

    world_event_get_id = {},    --已经领取奖励的世界事件的ID

    weekly_activitiy_num = 0,   --周限时活动计数
    weekly_activity_score = {0,0,0,0,0,0},  --周限时活动积分
    weekly_activity_award = {0,0,0,0,0,0},  --周限时活动领奖标记
}

map_city_zone = {
    [0] = 3001001,
    [1] = 3002002,
    [2] = 3003002,
    [3] = 3004003,
    [4] = 3005003,
    [5] = 3006003,
    [6] = 3007004,
    [7] = 3008004,
    [8] = 3009004,
    [9] = 3010004,
    [10] = 3011001,
    [11] = 3012002,
    [12] = 3013002,
    [13] = 3014003,
    [14] = 3015003,
    [15] = 3016003,
    [16] = 3017004,
    [17] = 3018004,
    [18] = 3019004,
    [19] = 3020004,
    [20] = 3021001,
    [21] = 3022002,
    [22] = 3023002,
    [23] = 3024003,
    [24] = 3025003,
    [25] = 3026003,
    [26] = 3027004,
    [27] = 3028004,
    [28] = 3029004,
    [29] = 3030004,
    [30] = 3031001,
    [31] = 3032002,
    [32] = 3033002,
    [33] = 3034003,
    [34] = 3035003,
    [35] = 3036003,
    [36] = 3037004,
    [37] = 3038004,
    [38] = 3039004,
    [39] = 3040004,
    [40] = 4001001
}
