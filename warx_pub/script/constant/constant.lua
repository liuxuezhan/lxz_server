
--概率总和
TOTAL_RATE = 10000

BLACK_MARKET_REFRESH_COST = {0,0,0,0,5,10,20,40,80,120,120,160,160,320,320,640,640,1000,1000,1000}

RES_RATE = { 1, 1, 5, 20 }

RANGE_LV = { 3380, 1104, 816, 528, 240, 16 }
BUY_SILVER_COST = 150  -- 购买银币比率恒定150:1
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

WALL_FIRE_SECONDS = 18          -- 非土地每18秒减1点城防
WALL_FIRE_IN_BLACK_LAND = 44    -- 黑土地每1秒减44点城防
WALL_FIRE_REPAIR_FREE = 60      -- 免费修复，每次恢复60点城防
WALL_FIRE_REPAIR_TIME = 1800    -- 免费修复，每1800秒一次
WALL_FIRE_OUTFIRE_COST = 50     -- 城墙灭火，花费30金币


UNION_DONATE_LIMIT =60000 
UNION_DONATE_B_LIMIT =7 

UNION_TASK_CONFIG =
{
    PRICE = 20,
    BONUS = {MIN = 20*1000,MAX = 80*1000}
}

-- 重置天赋所需金币
GENIUS_RESET_COST = 1000

-- 领主体力最大值
LORD_MAX_SINEW = 100


KING = 1001 --国王称号的id

-- table of boss reborn after dead
BossRbTime = {
    [ BOSS_TYPE.NORMAL ] = 10,
    [ BOSS_TYPE.ELITE ] = 3600,
    [ BOSS_TYPE.LEADER ] = 3600,
    [ BOSS_TYPE.SUPER ] = 259200
}


----军团战争动员价格(金币)，客户端已引用
UNION_MOBILIZE_PRICE = 20000
UNION_MOBILIZE_EFFECTID = resmng.BUFF_90001001

--- 军团科技捐献清除cd价格表
CLEAR_DONATE_COST = {100,250,250,350,350,600}

---弹劾军团长价格
UNION_IMPEACH_PRICE = 1000

SPEED_GATHER = {
    40320,
    45360,
    50400,
    55440,
    60480,
}



MassTime = {
    Level1 = 300,
    Level2 = 900,
    Level3 = 1800,
    Level4 = 3600,
}


Gather_Level = { 1, 1, 10, 15 }

---军团科技层级开放配置，必须比最后一层配置多一个值，不可达到的极限值
TechValidCond = {0,10,100,200,1000}

-- 资源田加速
ACC_RES_COST = {30,30,50,70}  -- 金币消耗
ACC_RES_ITEM = {resmng.ITEM_8009002, resmng.ITEM_8009001, resmng.ITEM_8009003, resmng.ITEM_8009004}
ACC_RES_BUFF = {resmng.BUFF_52001001, resmng.BUFF_52002001, resmng.BUFF_52003001, resmng.BUFF_52004001}


CANCEL_BUILD_FACTOR = 0.6  -- 取消建筑操作返还的资源比率(向上取整)
DESTROY_FIELD_FACTOR = 20  -- 拆除野地耗时:Lv*20

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

--奖励概率总和
AWARD_RANDOM_SUM = 10000

--重置技能消耗的金币
RESET_SKILL_GOLD = 250
--重置技能消耗的道具ID
RESET_SKILL_ITME = 5003001

--月卡总天数
YUEKA_TOTAL_DAYS = 30
--月卡打折时间
YUEKA_SALE_TIME = 259200 --3天

DEFAULT_PHOTO = {
    {1,5,9},
    {2,6,12},
    {3,7,10},
    {4,8,13}
}

--- Zhao@2016年4月14日：军团创建条件
CREATEUNION = {
    lv = 5,
    cost = 1000
}

---军团建筑受成员数量控制配置表
-- [1] = 基础值，达到这个值可以获得2个联盟奇迹
-- [2] = 步进值，每满足一个步进值，奇迹数+1
UNION_CASTALCOUNT_LIMIT = {1,1}

---军团领地争夺战可以占领的城市数量限制
-- [1] = 基础值，达到这个值可以占领一个系统城
-- [2] = 步进值，每满足一个步进值，可占领系统城市数量加1
UNION_OCCUPY_LIMIT = {2,1}

---军团捐献排行榜周奖励科技与设施捐献1、2、3名分别获得的奖励
UNION_DONATE_WEEK = 
{
    ONE = 2013161, 
    TWO = 2013162, 
    THREE = 2013163, 
    B_ONE = 2013164, 
    B_TWO = 2013165, 
    B_THREE = 2013166, 
}

--刷新日常任务的消耗
REFRESH_DAILY_TASK_CON = {{resmng.CLASS_RES, resmng.DEF_RES_GOLD, 200}}
--直接完成日常任务活跃度和金币的比率
DONE_DAILY_TASK_GOLD = 5


---军团任务的星星数配置,3档，最高档就是完成全部任务的星星数
UNION_TIMINGTASK_CONFIG = {1,5,10}

--重置英雄性格道具ID
RESET_HERO_NATURE_ITEM = resmng.ITEM_4006001

TRIBUTE_EXCHANGE_LOOP = 7200
TRIBUTE_EXCHANGE_TAX = 10

WEEKLY_ACTIVITY_CIRCULATION = 0 --周限时活动间隔周数
WEEKLY_ACTIVITY_OPEN_TIME = 7 --周限时活动开放时间

SPECIAL_DIG = 16001003

OFFLINE_NOTIFY = {
    [1] = resmng.LG_OFFLINE_NOTIFY_TITLE_173300001,
    [2] = resmng.LG_OFFLINE_NOTIFY_TITLE_173300002,
    [3] = resmng.LG_OFFLINE_NOTIFY_TITLE_173300003,
    [4] = resmng.LG_OFFLINE_NOTIFY_TITLE_173300004,
    [5] = resmng.LG_OFFLINE_NOTIFY_TITLE_173300005,
}

-- 英雄经验书分解 key为被分解书星级 value为分解目标
SKILL_BOOK_DECOMPOSE = {
    [1] = {id = resmng.SKILL_MIN_EXP_BOOK, num = 1},
    [2] = {id = resmng.SKILL_MIN_EXP_BOOK, num = 10},
    [3] = {id = resmng.SKILL_MIN_EXP_BOOK, num = 25},
    [4] = {id = resmng.SKILL_MIN_EXP_BOOK, num = 50},
    [5] = {id = resmng.SKILL_MIN_EXP_BOOK, num = 100},
    [6] = {id = resmng.SKILL_MIN_EXP_BOOK, num = 200},
}
