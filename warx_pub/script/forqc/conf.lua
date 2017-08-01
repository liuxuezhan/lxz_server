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
Log = { "robot", "/home/loon/yx/logs/3/", 1440, 2, 1440, 28, 1440, 28 }
Debugger = true

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

LogLevel = 3
--Release = true
--BuddySize = 2048

IsEnableGm = 1

GameHost = "192.168.100.12"
APP_ID = "warx_test" 
SERVER_ID =  Tips 
PLAT_ID = 1 
TlogSwitch = 1
---------------------------------------------机器人专用

-- Autobot
Autobot = {}

---- 机器人数量控制开关
Autobot.EnableMassivePlayer = true  -- 为 true 启动机器人压力测试
Autobot.SinglePlayerIdx = 145
-- PlayerIdx = Massive_PreIdx * 1000000 + [1, Massive_BatchCount] * 1000 + [1,LoopCount]
Autobot.Massive_PreIdx = 1              -- 前缀ID（可用于不同机器人实例分隔ID段）
Autobot.Massive_BatchCount = 10        -- 共执行多少次批量登录
Autobot.Massive_LoopCount = 10          -- 每一批登录玩家数量
Autobot.Massive_Interval = 1            -- 每间隔多少秒执行一次玩家批量创建/登录

Autobot.ChoreInstantInterval = 2
Autobot.ChoreRestTime = 5
Autobot.ChoreReapInterval = 300

