--[[
    脚本标题：道具使用自动回归测试
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
Map = 5 --服务器ID
Tips = "robot"

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
GatePort = 8001 

LogLevel = 1
--Release = true
BuddySize = 128

IsEnableGm = 1

GameHost = "192.168.100.12"
APP_ID = "warx_test" 
SERVER_ID =  Tips 
PLAT_ID = 1 
TlogSwitch = 1
---------------------------------------------机器人专用

g_start = 1000 --起始账号
g_num = 100 --建立账号数量
gName ="robot" --机器人名字
gTotalTime = 10  --登录秒数 
g_client_port = 8001

tm_check = 0 --检查时间


gm = { --登录加载gm命令
    "@additem=1001001=1",
    "@additem=1001002=1",
    "@buildall",
    "@addres=6=100000000",
    "@addres=8=100000000",
}

g_check = { --被动执行gm
    --arm = {num=100000,gm={} }, --士兵小于num 时执行
    --sinew = {num=100 }, --体力小于num 时执行
    --gold = {num=1000000 }, --金币小于num 时执行
}

function get_cival(self)
        --return self.robot_id % 4 + 1 --创建机器人时对应设置文明
        if self.robot_id >= g_start and self.robot_id <= g_start + 17 then return 1 end
        if self.robot_id > g_start + 17 and self.robot_id <= g_start + 35 then return 2 end
        if self.robot_id > g_start + 35 and self.robot_id <= g_start + 53 then return 3 end
        if self.robot_id > g_start + 53 and self.robot_id <= g_start + 71 then return 4 end
end


-------------------------------------------------------------------------------------------------

function setname()
    for i = g_start,g_start+g_num-1 do 
        local name = gName..tostring(i)
        local self = g_name[name] 
        if self and self.active then
            --if self and self.active and gTime - self.active  > 1 then
            Rpc:chat(self,1,"我是机器人",0)
            if self.name ~= self.acc then
                Rpc:change_name(self,self.acc)
                --WARN("change name to:"..self.acc)
            end
        end
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

function techup(name,tech_id,tech_lv,check)  --升级科技:机器人名称，科技ID，科技等级，检查项目
    local self = g_name[name]
    if self and self.active and gTime - self.active  > 1 then
        if not Ply.check_on(self,name,check) then
            Ply.tech(self,tech_id,tech_lv,1,check)
        end
    end
end



function robot_plan()

    setname()
--[[

-----------------------------测试代码------------------------------

    if not Ply.techup("techT1",1021019,19,{buff={SpeedRes4_R=11900}}) then return end 

-------------------------------------------------------------------

    --[[
    --
    item_test("robot1",1001001,{res={{0,100},{0,0},{0,0},{0,0}}})       
    item_test("robot2",1001002,{res={{0,1000},{0,0},{0,0},{0,0}}})
    if gTime > tm_check + 3 then
        tm_check = gTime
        for name, v in pairs(Ply._check) do
            WARN("check:"..name..":"..v.ret)
            os.execute("echo "..gTime..","..name..","..v.ret.." >> /tmp/check.csv")
            if  v.ret ~= math.huge then lxz(name,v.data)  return end
        end
    end




    local name = "robot1"
    Ply.gacha_test(name,GACHA_TYPE.YINBI_ONE )
    if gTime > tm_check + 10 then
        tm_check = gTime
        local self = g_name[name]
        for type, vs in pairs(self.gacha or {} ) do
            for k, v in pairs(vs) do
                for id, num in pairs(v) do
                    local p = gTime..","..name..","..type..","..k..","..id..","..num
                    WARN("gacha:"..p)
                    os.execute("echo "..p..">> /tmp/check.csv")
                end
            end
        end
    end
    --]]

end

