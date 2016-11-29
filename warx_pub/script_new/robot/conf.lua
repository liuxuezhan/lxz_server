module("config")


-- Map 跟 Tips 每个服务器都不一样，要改
Map = 5
Tips = "robot"

-- 脚本所在目录，可以不改，也可以用全路径
StartScript = "robot/robot.lua"

--以下配置各个服务器基本一致, 可以不改动
Game = "warx"
DbPort = 27017
DbHost = "192.168.100.12"

Daemon = 0
DbPortG = 27017
DbHostG = "192.168.100.12"
GateHost = "192.168.100.12"
GatePort = 8002 

LogLevel = 3
--Release = true
BuddySize = 128

IsEnableGm = 1

GameHost = "192.168.100.12"
APP_ID = "warx_test" 
SERVER_ID =  Tips 
PLAT_ID = 1 
TlogSwitch = 1
---------------------------------------------机器人专用

g_start = 1 
g_num = 1000 
gName ="robot" 
gTotalTime = 60  --登录秒数 
g_client_port = 8001
g_name = {}

tm_check = 0
function robot_plan()
  --  move()
 --   robot_union_build()
  --  Ply.union_mission()

  use_item("use_item")
  if gTime > tm_check + 3 then
    tm_check = gTime 
    for name, v in pairs(Ply._check) do
        WARN("check:"..name..":"..v.ret)
    end
  end
end


function use_item(name)
    local self = g_name["robot1"]
    if self and self.active and gTime - self.active  > 1 then
        if Ply.check_on(self, name,{gold=0,item={[4002014]=1,}}) then
            Rpc:chat(self, 0, "@item=4003003=1", 0 )
            for idx, v in pairs(self._item) do
                if v[2] == 4003003 then
                    Rpc:use_item(self,idx,1) 
                end
            end
        end
    -- lxz(self._check[name])
    end
end

function buildup(name)
    local self = g_name["robot1"]
    if self and self.active and gTime - self.active  > 1 then
        if Ply.check_on(self, name,{gold=0,}) then
            self:build_up(0,0,30,1)
        end
    end
end

function techup(name)
    local self = g_name["robot1"]
    if self and self.active and gTime - self.active  > 1 then
        if Ply.check_on(self, name,{gold=0,buf={SpeedRes2=1,}}) then
            self:tech(1001001,2,1)
        end
    end
end

function genius_up(name)
    local self = g_name["robot1"]
    if self and self.active and gTime - self.active  > 1 then
        if Ply.check_on(self, name,{gold=0,}) then
            self:genius_up(1001001)
        end
    end
end

function equip_forge(name)
    local self = g_name["robot1"]
    if self and self.active and gTime - self.active  > 1 then
        if Ply.check_on(self, name,{gold=0,item={[1001]=1,}}) then
            Rpc:equip_forge(self,6)
        end
    end
end

function equip_on(name)
    local self = g_name["robot1"]
    if self and self.active and gTime - self.active  > 1 then
        if Ply.check_on(self, name,{gold=0,item={[1001]=1,}}) then
            for id, v in pairs(self._equip) do
                if v.propid == 100010 then
                    Rpc:equip_on(self,id)
                end
            end
        end
    end
end


lvtable = {1,5,8,10,12,14,16,18,20,22,23,24,25,26,27,28,29,30} --城堡外观等级设置

setx = 100  --指定迁城坐标x值
sety = 0  --指定迁城坐标y值

function get_cival(self)
        --return self.robot_id % 4 + 1 --创建机器人时对应设置文明
        if self.robot_id >= g_start and self.robot_id <= g_start + 17 then return 1 end
        if self.robot_id > g_start + 17 and self.robot_id <= g_start + 35 then return 2 end
        if self.robot_id > g_start + 35 and self.robot_id <= g_start + 53 then return 3 end
        if self.robot_id > g_start + 53 and self.robot_id <= g_start + 71 then return 4 end
end

function setname(self)
    for i = g_start,g_start+g_num do
        local name = gName..tostring(i)
        local self = g_name[name]
    end
end

function setlvbuild(start,last)
    local lv = 1
    for l = start,last do
        if self.active and gTime - self.active  > gInterval then
            Rpc:chat(self, 0, "@lvbuild=0=0="..tostring(lvtable[lv]), 0 )  --建筑等级到lvtable[i]等级
            lv = lv + 1
        end       
    end
end


function move()
    local movex = 200
    local movey = 200
    for i = g_start,g_start+g_num do
        local name = gName..tostring(i)
        local self = g_name[name]
        local x,y = setx,sety  --指定迁城坐标
        if self and self.active and gTime - self.active  > 1 then
            Ply.pending( self )
            if self.name ~= self.acc then
                Rpc:change_name(self,self.acc)
            end
            if self.x < x + movex and self.x > 0 and self.y < y + movey and self.y > 0 then  --设置迁城坐标和范围，范围由x，y后面加的值控制
            else 
                Rpc:request_empty_pos(self,x,y,2,{key="move"})  --移动到指定范围
            end
        end
    end 
end


gm = { --登录加载gm命令

    "@ef_add=CountSoldier_R=1000000",
    "@addres=6=10000000", 
    "@addarm=1010=100000", 
    "@addarm=2010=100000", 
    "@addarm=3010=100000", 
    "@addarm=4010=100000", 

    --[[
    "@ef_add=SpeedMarch_R=10000000", 
    "@ef_add=SpeedMarchPvE_R=10000000", 
    "@ef_add=SpeedRes_R=10000000", 
    "@ef_add=SpeedGather_R=10000000", 

    "@buildall", 
    "@buildfarm", 
    "@addres=1=10000000", 
    "@addres=2=10000000", 
    "@addres=3=10000000", 
    "@addres=4=10000000", 
    "@item=4=10000000", 
    "@item=3001003=10000000", 
    "@item=4003003=10000000",


    "@addbuf=1=-1", 
    "@ef_add=CountRes_R=10000000",
    "@addallitem", 

    "@addexp=1000000000000", 
    "@debug", 
    --]]
}

g_check = { --被动执行gm
    arm = {num=100000,gm={} }, --士兵小于num 时执行
    sinew = {num=100 }, --体力小于num 时执行
    gold = {num=1000000 }, --金币小于num 时执行
}
