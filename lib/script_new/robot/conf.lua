gMap = 6 --服务器id  
g_start = 8000 
g_num = 1000 
gName ="robot" 
gTotalTime = 1  --登录秒数 
g_membercount = 50 --军团人数
gPlan ={ 
    union = {
        add = 1, --加入军团 热点
        fight = "is_monster",                    --军团战争 
        build = 100004001,                       --军团建筑
        --[[
        rank = resmng.UNION_RANK_4,              --设置军阶
        help = HELP_TYPE.CONSTRUCT,              --帮助类型
        donate = 0,                              --科技捐献
        buildlv = UNION_CONSTRUCT_TYPE.MIRACAL,  --建筑捐献
        god = 0 ,                                --膜拜战神
        word = 0,                                --留言
        --]]
    },


        build = {lv=30},                       --主城等级
        task = {},                             --主线任务
--[[
        king = {},                             --王城战
        --]]
} 

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
--[[
    arm = {num=100000,gm={} }, --士兵小于num 时执行
    sinew = {num=100 }, --体力小于num 时执行
    gold = {num=1000000 }, --金币小于num 时执行
    --]]

}
