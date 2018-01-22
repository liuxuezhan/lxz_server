--[[
    脚本标题：前端性能测试，建立4个文明不同等级城堡，移动到同一个坐标附近
    ==========================
    执行过程
    1、下载配置 --为了保证留下上次测试脚本，不丢失
    2、选择配置文件，上传
    3、开始序号：建立机器人开始的序号 --建立前，需要上传脚本，会读脚本中的机器人名字配置
    4、结束序号：建立机器人结束的序号
    5、开始执行
    6、关闭执行
    7、获取日志：可以填写获取日志的行数，点击按钮下载
    ==========================
--]]

--------------------------------------------------------------------------
module("config")

-- Map 跟 Tips 每个服务器都不一样，要改
Map = 3 --服务器ID
Tips = "robot"
--Log = { "robot", "/home/yangjun/warx/server/script/forqc/logs/", 1440, 2, 1440, 28, 1440, 28 }
--Debugger = true

-- 脚本所在目录，可以不改，也可以用全路径
--StartScript = "robot/robot.lua"
StartScript = "forqc/main.lua"

--以下配置各个服务器基本一致, 可以不改动
Game = "warx"
DbPort = 27017
DbHost = "192.168.100.12"

Daemon = 0
DbPortG = 27017
DbHostG = "192.168.100.12"
GateHost = "192.168.100.12"
GatePort = 6001

LogLevel = 1
--Release = true
BuddySize = 2048

--IsEnableGm = 1

GameHost = "192.168.100.12"
APP_ID = "warx_test" 
SERVER_ID =  Tips 
PLAT_ID = 1 
TlogSwitch = 1
---------------------------------------------机器人专用

-- Autobot
Autobot = {}

---- 机器人登录策略配置
Autobot.ShuttleName = "MultiPlayer"
Autobot.ShuttleName = "Solo"
Autobot.ShuttleName = "EndlessRush"
Autobot.ShuttleName = "ContinuousRush"
Autobot.ShuttleName = "EphemeraRush"
Autobot.ShuttleName = "MassivePlayer"

-- Solo
Autobot.SinglePlayerIdx = 100

-- MultiPlayer
local function sequence(from, to)
    local t = {}
    for i = from, to do
        t[#t + 1] = i
    end
    return t
end
Autobot.MultiPlayer = {
    Idxs = sequence(1001, 1020),
    Interval = 1,
}

-- EndlessRush：持续登录，首批登录BatchCount * LoopCount个玩家，然后每完成指定任务后进入退出流程并登录一个新的玩家
Autobot.EndlessRush = {
    Prefix = 0,
    BatchCount = 10,
    LoopCount = 10,
    Interval = 1,
    DyingTime = 10,                 -- 指定任务完成后等待多长时间退出游戏：DyingTime <= 等待时间 <= DyingTime * 2
    TaskId = {130061054,130062054,130063054,130064054},             -- 指定任务
}

-- ContinuousRush：连续登录，每帧登录LoopCount个玩家，当当前登录/在线玩家数大于MaxCount时暂停登录
Autobot.ContinuousRush = {
    Prefix = 4,
    MaxCount = 5000,
    WaitCount = 1000,
    LoopCount = 5,
    DyingTime = 5,                 -- 指定任务完成后等待多长时间退出游戏：DyingTime <= 等待时间 <= DyingTime * 2
    TaskId = {130061034,130062034,130063034,130064034},         -- 指定任务
}

-- EphemeraRush：循环登录
--      每隔 Interval 秒登录 LoopCount 个玩家，每个玩家保持在线 AliveTime 秒后登出，登录/在线数超过 MaxCount 时暂停登录新玩家
--      登录玩家账号为 1000000 * Prefix + [0 - (MaxId -1)]，当登录玩家数超过 MaxId 后从 0 开始循环登录
Autobot.EphemeraRush = {
    Prefix = 1,
    MaxId = 10000,
    AliveTime = 120,
    MaxCount = 1000,
    WaitCount = 30,
    LoopCount = 5,
    Interval = 1,
}

-- MassivePlayer
-- PlayerIdx = Massive_PreIdx * 1000000 + [1, Massive_BatchCount] * 1000 + [1,LoopCount]
Autobot.Massive_PreIdx = 2              -- 前缀ID（可用于不同机器人实例分隔ID段）
Autobot.Massive_BatchCount = 40        -- 共执行多少次批量登录
Autobot.Massive_LoopCount = 100          -- 每一批登录玩家数量
Autobot.Massive_Interval = 1            -- 每间隔多少秒执行一次玩家批量创建/登录

Autobot.DisableWorkline = {
    Chore = false,
    TechScavenger = false,
    TaskScavenger = false,
    MonsterScavenger = false,
}


Autobot.ChoreInstantInterval = 2
Autobot.ChoreRestTime = 5
Autobot.ChoreReapInterval = 300

Autobot.LevelGift = {
    [3] = "get_lv_3_gift",
    [6] = "get_lv_6_gift",
}

