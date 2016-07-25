--------------------------------------------------------------------------------

--时区偏移数值 秒
TIME_ZONE = 0

-- chat host
CHAT_HOST = "war_x.org"

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

    -- [10, 19] Item
    USE_ITEM   = 10,
    FETCH_MAIL = 11,
    COMPOSE = 12,
    DECOMPOSE = 13,
    FORGE = 14,
    SPLIT = 15,
    CURE = 16,
    

    -- [20, 29] Build
    BUILD_CONSTRUCT = 20,
    BUILD_UPGRADE   = 21,
    BUILD_ACC       = 22,
    LEARN_TECH      = 23,
    CANCEL_ACTION  = 24,
    WALL_REPAIR    = 25,

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

    --增加资源
    REASON_ADD_RES = 3000,
    REASON_UNION_GET_RESTORE        = 3001,          --从联盟仓库取资源
    REASON_BUY_RES                  = 3002,          --从市场买资源

    --扣除物品
    REASON_DEC_ITEM = 4000,
    REASON_TASK_DEC_ITEM            = 4001,          --任务扣除任务物品
    REASON_GACHA_DEC_ITEM           = 4002,          --魂匣单抽扣物品
}

RES_RATE = { 1, 1, 5, 20 } 

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
resmng.CLASS_RES_PROTECT = 101	--物品类型101保护资源


WALL_FIRE_SECONDS = 18          -- 非土地每18秒减1点城防
WALL_FIRE_IN_BLACK_LAND = 44    -- 黑土地每1秒减44点城防
WALL_FIRE_REPAIR_FREE = 60      -- 免费修复，每次恢复60点城防
WALL_FIRE_REPAIR_TIME = 1800    -- 免费修复，每1800秒一次
WALL_FIRE_OUTFIRE_COST = 30     -- 城墙灭火，花费30金币
-- 城墙一键修补所需金币
function onekey_repair_gold(defence)
    return math.ceil(defence/300)*20
end



UNION_TASK =      ---军团悬赏任务类型
{
    PLY = 0,
    NPC = 1,
    HERO = 2,
    NUM = 3,
}

UNION_ITEM =      ---军团礼包来源
{
    POS = 1,      --- 充值  
    BOSS = 2,     --- 击杀BOSS   
    TASK = 3,     --- 完成军团任务
    CITY = 4,     --- 占领NPC城市
    GM = 5,
    MAX = 6,
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
}

--resmng.CLASS_UNION_BUILD_
--
CLASS_UNIT = {
    UNION_BUILD = 10,
    PLAYER_CITY = 0,
    RESOURCE = 1,
    MONSTER = 2,
    NPC_CITY = 3,
    KING_CITY = 4,
    Camp =5,
    MONSTER_CITY = 6,
    LOST_TEMPLE = 7,
}

BOSS_TYPE = {
    NORMAL = 1,
    ELITE = 2,
    LEADER = 3,
    SUPER = 4,
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
    [ BOSS_TYPE.NORMAL ] = 0,
    [ BOSS_TYPE.ELITE ] = 3600,
    [ BOSS_TYPE.LEADER ] = 3600,
    [ BOSS_TYPE.SUPER ] = 259200
}


-- Hx@2015-12-02 : mail
--


MailMode = {}
MailMode.Sys = 1
MailMode.AlncInvite = 2

MAIL_CLASS = {
    PLAYER = 1,  -- 玩家
    FIGHT = 2,  -- 战斗
    SYSTEM = 3,  -- 系统
    REPORT = 4,  -- 报告
}
MAIL_FIGHT_MODE = {
    SPY = 1,  -- 侦查
    BE_SPY = 2,  -- 被侦查

    ATTACK_SUCCESS = 3,  -- 进攻成功
    ATTACK_FAIL = 4,  -- 进攻失败
    DEFEND_SUCCESS = 5,  -- 防守成功
    DEFEND_FAIL = 6,  -- 防守失败

    MASS_SUCCESS = 7,  -- 集结成功
    MASS_FAIL = 8,  -- 集结失败
    DEFEND_MASS_SUCCESS = 9,  -- 防守集结成功
    DEFEND_MASS_FAIL = 10,  -- 防守集结失败
}
MAIL_REPORT_MODE = {
    GATHER = 1,  -- 采集
    JUNGLE = 2,  -- 打怪
    UNION_TASK = 3,  -- 军团悬赏任务
    UNION_INVITE = 4,  -- 军团邀请
    ACTIVITY = 5,  -- 活动奖励
    DECLARE = 6,  -- npc 宣战成功
}

-- Zhao@2015年12月3日 ：Language
language_def = {
	[40] = {text = "中文(简体)",icon = "icon_language_cn"},
	[41] = {text = "繁體中文",icon = "icon_language_cn"},
	[10] = {text = "English",icon = "icon_language_en"},
	[22] = {text = "日 本 語",icon = "icon_language_jpn"},
	[15] = {text = "Deutsch",icon = "icon_language_de"},		-- 德语
	[14] = {text = "Français",icon = "icon_language_fra"},			-- 法语
	[36] = {text = "ภาษาไทย",icon = "icon_language_th"}			-- 泰语
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

--军团距离
UNION_RANGE = {
    NEAR =1, 
    NORMAL = 2, 
    FAR = 3,
}

UNION_RELATION = {
    PARTNER     = 1, 
    FRIEND      = 2,
    NORMAL      = 3,
    ENEMY       = 4,
    DEAD        = 5,
    MAX         = 6,
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
    condition = {{2,2}},
    consume = {{1,resmng.DEF_RES_GOLD,1000}}
}

---军团建筑受成员数量控制配置表 
-- [1] = 基础值，达到这个值可以获得2个联盟奇迹 
-- [2] = 步进值，每满足一个步进值，奇迹数+1
UNION_CASTALCOUNT_LIMIT = {40,10}

---军团设施类别，决定了会在军团设施页面显示多少种类别
UNION_CONSTRUCT_TYPE = 
{
    MIRACAL = 1,    --奇迹
    RESTORE = 2,    --仓库
    SUPERRES = 3,   --超级矿
    TUTTER = 4,     --箭塔
    MARCKET = 5     --市场
}

---军团领地争夺战可以占领的城市数量限制
-- [1] = 基础值，达到这个值可以占领一个系统城
-- [2] = 步进值，每满足一个步进值，可占领系统城市数量加 1
UNION_OCCUPY_LIMIT = {40,10}

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
    WITHDRAW = "Withdraw ",                 ---领地争夺弃城
    WRITEINWORDS = "Writeinwords",          ---写军团内部留言
    UPDATEINWORDS = "Updateinwords",        ---管理军团留言   
    APPOINT = "Appoint",                    ---王城战任命国王  
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

TroopAction2 = {
    DefultFollow    = 1,   --默认玩家身上额troop
    SiegePlayer     = 9,
    MassPlayer      = 1,
    SiegeMonster    = 9,
    MassMonster     = 1,
    JoinMass        = 1,
    Gather          = 1,
    Spy             = 1,
    UnionBuild      = 1,
    UnionFix        = 1,
    UnionUpgrade    = 1,
    SupportArm      = 1,
    SupportRes      = 1,
    Camp            = 1,
    HeroBack        = 1,
    MonsterAtkPly   = 1,
    SiegeMonsterCity= 1,
    SiegeNpc        = 1,
    



    Wait            = 2,   --等待
    WaitMass        = 17,  --集结中
    SiegePlayer     = 2,   --单独攻击玩家城堡
    JoinMass        = 5,   --参加集结
    HoldDefense     = 6,   --驻守
    MassPlayer      = 7,   --集结攻击玩家城堡
    Gather          = 8,   --采集
    SiegeMonster    = 9,   --单独攻击Monster
    Monster         = 10,  --怪物部队
    Spy             = 11,  --侦查
    Back            = 4,   --通常返回

    Gathering       = 208,  --采集中
    SaveRes         = 13,  --盟仓库存资源
    GetRes          = 14,  --盟仓库取资源
    UnionFixBuild   = 16,  --修联盟建筑
    MassMonster     = 18,  --集结攻击Monster
    BuySpecialty    = 19,  --买特产
    ConfirmSpecialty = 20, --上架特产
    CancleSpecialty = 21,  --下架特产

    UnionBuild      = 15,  --建造联盟建筑
    UnionBuilding   = 215,  --建造联盟建筑ing

    UnionUpgradeBuild = 23,  --升级建筑
    Declare         = 24,  --领土争夺宣战
    SupportArm      = 25,    -- 士兵援助
    SupportRes      = 26,    -- 士兵援助
    Camp            = 27,   -- 野外帐篷

    Camping         = 227,   -- 野外帐篷

    MonsterAtkPly   = 29,    -- 怪物攻打玩家
    SiegeMonsterCity   = 30,    -- 玩家攻打怪物城市
    SiegeNpc        = 31,  --单独攻击NPC city
    Tower           = 32,  --箭塔攻击为 模拟部队攻击
    King            = 33,  --攻击王城相关建筑
    HeroBack        = 34,  --英雄逃回家
}



TroopAction = {
    DefultFollow    = 1,   --默认玩家身上额troop
    Wait            = 2,   --等待
    SiegePlayer     = 3,   --单独攻击玩家城堡
    Back            = 4,   --通常返回
    JoinMass        = 5,   --参加集结
    HoldDefense     = 6,   --驻守
    MassPlayer      = 7,   --集结攻击玩家城堡
    Gather          = 8,   --采集
    SiegeMonster    = 9,   --单独攻击Monster
    Monster         = 10,  --怪物部队
    Spy             = 11,  --侦查
    Gathering       = 12,  --采集中
    SaveRes         = 13,  --盟仓库存资源
    GetRes          = 14,  --盟仓库取资源
    UnionBuild      = 15,  --建造联盟建筑
    UnionFixBuild   = 16,  --修联盟建筑
    WaitMass        = 17,  --集结中
    MassMonster     = 18,  --集结攻击Monster
    BuySpecialty    = 19,  --买特产
    ConfirmSpecialty = 20, --上架特产
    CancleSpecialty = 21,  --下架特产
    UnionBuilding   = 22,  --建造联盟建筑ing
    UnionUpgradeBuild = 23,  --升级建筑
    SupportArm      = 35,    -- 士兵援助
    SupportRes      = 36,    -- 士兵援助
    Camp            = 37,   -- 野外帐篷
    Camping         = 38,   -- 野外帐篷
    Declare         = 24,  --领土争夺宣战
    SiegeNpc        = 25,  --单独攻击NPC city
    Tower           = 26,  --箭塔攻击为 模拟部队攻击
    King            = 27,  --攻击王城相关建筑
    HeroBack        = 28,  --英雄逃回家
    MonsterAtkPly   = 29,    -- 怪物攻打玩家
    SiegeMonsterCity   = 30,    -- 怪物攻打玩家占领NPC
    SiegeTaskNpc    = 31,   --攻击任务怪
    AtkMC    = 32,   --玩家攻打怪物城市
}

TroopTimerCallBack = {
    StartMarch      = 1, --开始行军
    StartGather     = 2, --开始采集
    StartUnionGather= 3, --开始采集联盟矿
}

MassTime = {
    Level1 = 30,
    Level2 = 900,
    Level3 = 1800,
    Level4 = 3600,
}

--特殊情况固定行军速度，每分钟的速度
FixTroopSpeed = {
    Spy          = 100,    --侦查
    Declare      = 100,    --领土争夺宣战：
    Runaway      = 100,    --侦查
    ResHelp      = 10,     --资源帮助
    Restore      = 5,      --仓库存取
    HeroBack     = 5,      --hero release
    Environment  = 1,      --固定环境
}

TroopSpeed = {
    [ TroopAction.Spy ] = 100,
    [ TroopAction.SaveRes ] = 5,
    [ TroopAction.SupportRes ] = 5,
    [ TroopAction.GetRes ] = 5,
    [ TroopAction.Declare ] = 100,
}


BigMapState = {
    normal = 1,
    war = 2,
}

EidType = {
    Player = 0,
    Res = 1,
    Troop = 2,
    Monster = 3,
    UnionBuild = 4,
    NpcCity = 5,
    KingCity = 6,
    Camp = 7,
    MonsterCity = 8, 
    LostTemple = 9, 
}

--聊天频道枚举
ChatChanelEnum = {
    World = 0,        --世界
    Union = 1,        --军团
    Culture = 2,      --文明
}

TECH_DONATE_TYPE = {
    PRIMARY = 1,    --初级
    MEDIUM = 2,     --中级
    SENIOR = 3,     --高级
}

DONATE_RANKING_TYPE = {
    DAY = 1,
    WEEK = 2,
    UNION = 3,
    ALL = 4,
}

TechValidCond = {0,18,137,242}
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
    MONSTERMALL     = 23,    -- 怪物攻城商店 
    MANORMALL       = 24,    -- 领地争夺商店
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
resmng.CLASS_UNION_BUILD_CASTLE = 1         --奇迹
resmng.CLASS_UNION_BUILD_MINI_CASTLE = 2    --小奇迹
resmng.CLASS_UNION_BUILD_MARKET = 3        --市场
resmng.CLASS_UNION_BUILD_RESTORE = 4        --仓库
resmng.CLASS_UNION_BUILD_TUTTER1 = 5         --箭塔1
resmng.CLASS_UNION_BUILD_TUTTER2 = 6         --箭塔2
resmng.CLASS_UNION_BUILD_FARM = 7           --农田
resmng.CLASS_UNION_BUILD_LOGGINGCAMP = 8    --木厂
resmng.CLASS_UNION_BUILD_MINE = 9           --铁矿厂
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
    HERO  = 4,  -- 英雄道具
    SKILL = 5,  -- 技能道具
    MATERIAL = 6, -- 材料
    BUFF = 8, -- buff类
    GLOBUFF = 9, -- 全服buff类
    UNION = 10, -- 军团
    UINBUFF = 11, -- 联盟buff类
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
    VIP_POINT = 20,
    LORD_SINEW = 30,
    -- class 8
    VIP_TIME = 10,

}

-- 加速MODE分类
ITEM_SPEED_MODE = {
    COMMON = 0,    -- 通用加速
    LV_UP  = 1,    -- 升级加速
    TRAIN  = 2,    -- 造兵加速
    CURE   = 3,    -- 治疗加速
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

-- Hx@2015-12-28 : 事件类型
EVENT_TYPE = {
    UNION_CREATE = 1,
    UNION_DESTORY = 2,
    UNION_JOIN = 3,
    UNION_QUIT = 4,
    UNION_KICK = 5,
    SET_NOTE_IN = 6,
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


-- overflow
E_MAX_LV = 2001
E_TOO_MUCH_SOLDIER = 2002

E_ALREADY_CURE = 2003
E_NO_HURT = 2004
E_NO_RES = 2005
E_NO_COUNT = 2006



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
    WEST  = 2,    -- 西方 (西欧，美国)
    SOUTH = 3,    -- 南方 (阿拉伯，波斯)
    NORTH = 4,    -- 北方 (斯拉夫，蒙古)
}

-- 状态
HERO_STATUS_TYPE = {
    FREE             = 1,    -- 待机
    MOVING           = 2,    -- 行军中
    -- DEFENDING        = 3,    -- 驻守中
    BUILDING         = 4,    -- 城建中
    -- GATHER           = 5,    -- 采集中
    BEING_CURED      = 6,    -- 治疗中
    BEING_CAPTURED   = 7,    -- 被俘虏
    BEING_IMPRISONED = 8,    -- 被监禁
    BEING_EXECUTED   = 9,    -- 处决中
    DEAD             = 10,   -- 死亡
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
    FIGHT     = 0,  -- 战斗技能
    NOT_FIGHT = 1,  -- 非战斗技能
}

-- 英雄卡折算成碎片时的比例
HERO_CARD_2_PIECE_RATIO = 0.8

-- 重置技能时经验返回比例
RESET_SKILL_RETURN_RATIO = 0.8

-- 分解英雄时的经验值返回比例
DESTROY_HERO_RETURN_RATIO = 0.8

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
TASK_ACTIVITY = {
    [1] = 20,
    [2] = 40,
    [3] = 70,
    [4] = 100,
    [5] = 120,
}
--任务定义
TASK_TYPE = {
    TASK_TYPE_INVALID       = 0,
    TASK_TYPE_TRUNK         = 1,    --主线任务
    TASK_TYPE_BRANCH        = 2,    --支线任务
    TASK_TYPE_DAILY         = 3,    --日常任务
    TASK_TYPE_UNION         = 4,    --军团任务
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
    ACTIVE      =4,
    ENTER       =5,
    GATHER      =6,
    POW         =7,
    MARKET      =8,
    COST        =9,
}

TASK_ACTION = {
    INVALID                         = 0,    
    ATTACK_SPECIAL_MONSTER          = 1,    --攻击特定怪物
    ATTACK_LEVEL_MONSTER            = 2,    --攻击等级怪物
    BATTLE_LIANGDONG                = 3,    --单场战斗进行联动
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
}
-- 打开UI任务
TASK_UI_ID = {
    UNION_MAIN = 1,  -- 军团主界面
    TECH_DONATE = 2,  -- 科技捐献
    FAST_ARMY = 3,  -- 快捷招募
    FAST_BUILD = 4,  -- 快捷建筑
    HERO_MAIN = 5,  -- 英雄主界面
}

g_task_func_relation = {
["attack_special_monster"] = TASK_ACTION.ATTACK_SPECIAL_MONSTER,   --攻击特定怪物                 
["attack_level_monster"] = TASK_ACTION.ATTACK_LEVEL_MONSTER,       --攻击等级怪物             
["battle_liandong"] = TASK_ACTION.BATTLE_LIANGDONG,                --单场战斗进行联动        
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
}
-------------------------------------------------------------
--奖励
BONUS_TYPE = {
    BONUS_TYPE_ITEM         = "item",
    BONUS_TYPE_RES          = "res",
    BONUS_TYPE_RESPICKED    = "respicked",
    BONUS_TYPE_EXP          = "exp",
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
-- 积分商城类型
POINT_MALL = {
    MONSTER = 1,    --怪物
    MANOR = 2,      --领地
    RELIC = 3,      --遗迹塔
    KING = 4,       --国王
}
-- 天赋end
function is_ply(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Player end
        else
            return (math.floor(ety / 0x010000)) == EidType.Player
        end
    end
end

function is_res(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Res end
        else
            return (math.floor(ety / 0x010000)) == EidType.Res
        end
    end
end

function is_camp(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Camp end
        else
            return (math.floor(ety / 0x010000)) == EidType.Camp
        end
    end
end


function is_troop(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Troop end
        else
            return (math.floor(ety / 0x010000)) == EidType.Troop
        end
    end
end

function is_monster(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.Monster end
        else
            return (math.floor(ety / 0x010000)) == EidType.Monster
        end
    end
end

function is_monster_city(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.MonsterCity end
        else
            return (math.floor(ety / 0x010000)) == EidType.MonsterCity
        end
    end
end

function is_king_city(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.KingCity end
        else
            return (math.floor(ety / 0x010000)) == EidType.KingCity
        end
    end
end

function is_lost_temple(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.LostTemple end
        else
            return (math.floor(ety / 0x010000)) == EidType.LostTemple
        end
    end
end

function is_union_building(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.UnionBuild end
        else
            return (math.floor(ety / 0x010000)) == EidType.UnionBuild
        end
    end
end

function is_npc_city(ety)
    if ety then
        if type(ety) == "table" then
            if ety and ety.eid then return (math.floor(ety.eid / 0x010000)) == EidType.NpcCity end
        else
            return (math.floor(ety / 0x010000)) == EidType.NpcCity
        end
    end
end

function can_attack(ety)
    if is_ply(ety) then return true end
    if is_monster(ety) then return true end
    if is_res(ety) and ety.on then return true end
    return false
end


