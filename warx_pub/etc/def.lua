-----------------------------------warx项目专用----------------------------------------------
-- 原warx 的socket由c语言引擎统一队列处理 ，移植后由lua分发处理
json = require "json"
require "lib_tools"

_list={

    db_server1 ={ 
        db1={ host = "192.168.100.12", port = 27017, },
    --    db1={ host = "127.0.0.1", port = 27017, },
        -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
    },

    warx = {   host = "192.168.103.225", port = 8888, maxclient=3000, room ="room1", db_name = "db_server1" }, 
}

--g_warx_t= {   host = "192.168.103.225", port = 8888, maxclient=3000, room ="room1", db_name = "db_server1" } 
g_warx_t = {   host = "192.168.100.12", port = 8888, maxclient=3000, room ="room1", db_name = "db_server1" } 

--数据库
g_db = {
    db1={ host = "192.168.100.12", port = 27017, },
    db2={ host = "127.0.0.1", port = 27017, },
    -- db={  host = "127.0.0.1", port = 27017,username="admin",password="admin" },
}


    getfenv = getfenv or function(f)
        f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
        local name, val
        local up = 0
        repeat
            up = up + 1
            name, val = debug.getupvalue(f, up)
        until name == '_ENV' or name == nil
        return val
    end

    setfenv = setfenv or function(f, t) --lua5.3 没有,模拟一个
        f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
        local name
        local up = 0
        repeat
            up = up + 1
            name = debug.getupvalue(f, up)
        until name == '_ENV' or name == nil
        if name then
            debug.upvaluejoin(f, up, function() return name end, 1) -- use unique upvalue
            debug.setupvalue(f, up, t)
        end
    end


    module = module or function(mname)  --lua5.3 没有,模拟一个
        _ENV[mname] = _ENV[mname] or {}
        setmetatable(_ENV[mname], {__index = _ENV})
        setfenv(2, _ENV[mname])
    end

function c_get_zone_lv(tx, ty)
    return 1
end

function c_get_culture(...)
    return 0
end

function c_tlog_start(...)
end
function c_get_top()
end

function pullInt()
end

function pullNext()
end

function llog(...)
lxz(...)
end

function linfo(...)
lxz(...)
end 

function lwarn(...)
lxz(...)
end 

function c_add_ety(...)
end

function c_add_troop(...)
end

function c_add_scan(...)
end

function c_roi_view_start(...)
end

function   addTimer(...)
end

skiplist = {

 new = function (...) end,
 insert = function (...) end,
 get_range_with_score = function (...) end,

 }

cmsgpack = {
 pack = function (v) return v end,
 }

 function getMap(...)
     return  config.Map 
 end

 function c_roi_init(...)
 end

 function c_roi_set_block(...)
 end
 function c_init_log(...)
 end

 function     pushHead(...)
 end
 function     pushInt(...)
 end
 function     pushOver(...)
 end
 function     c_set_gate( ...)
 end

 function connect(host,port,...)
    local driver = require "socketdriver"
	local fd = driver.connect(host,port)
    return fd
 end

 function begJob (...)
     --main_loop 没消息也循环
     g_beg = true
 end

 function warx_init()
     _G.GateSid = 1 
    _G.gAgent = {pid=0, account="@ConGate", gid=_G.gGateSid}
    gTime = os.time() 
    gMapNew = 1

    gActions = {}
    gSns = {}
    gFrame = 0
    gConns = {}
    gPlys = {}
    gAccs = {}
    gAccounts = {}
    gEtys = {}

    gPendingSave = {}
    gPendingDelete = {}
    gPendingInsert = {}
    init_pending()

    gInit = "StateBeginInit"
    require("etc/config")
    require("frame/tools")
    --require("frame/debugger")
    require("frame/conn")
    require("frame/crontab")
    require("warx_pub/dbmng")
    require("frame/timer")
    require("frame/socket")
    require("frame/class")
    require("frame/frame")
    doLoadMod("packet", "warx_pub/rpc/packet")
    doLoadMod("MsgPack", "warx_pub/MessagePack")
    doLoadMod("Array", "warx_pub/rpc/array")
    doLoadMod("Struct", "warx_pub/rpc/struct")
    doLoadMod("RpcType", "warx_pub/rpc/rpctype")
    doLoadMod("Rpc", "warx_pub/rpc/rpc")
    require("frame/player_t")

    gSysMailSn = 0
    gSysMail = {}
    gSysStatus = {}

    do_load("resmng")
    do_load("game")
    do_load("mem_monitor")
    do_load("common/define")
    --do_load("common/tools")
    do_load("warx_pub/tools")
    do_load("common/protocol")
    do_load("common/rpc_parse")

    do_load("timerfunc")

    do_load("public_t")

    do_load("player_t")
    do_load("player/player_item")
    do_load("player/player_mail")
    do_load("player/player_union")
    do_load("player/player_res")
    do_load("player/player_hero")
    do_load("player/player_build")
    do_load("player/player_task")
    do_load("player/player_online_award")
    do_load("player/player_month_award")
    do_load("player/player_skill")
    do_load("player/player_gacha")

    do_load("build_t")

    do_load("player/player_troop")
    do_load("troop_t")
    do_load("troop_mng")


    do_load("heromng")
    do_load("hero/hero_t")

    do_load("fight")
    do_load("farm")
    do_load("restore_handler")

    do_load("unionmng")
    do_load("union_t")
    do_load("union_member_t")
    do_load("union_tech_t")
    do_load("union_build_t")
    do_load("union_hall_t")
    do_load("union_help")
    do_load("union_item")
    do_load("union_relation")
    do_load("union_god")

    do_load("npc_city")
    do_load("king_city")
    do_load("monster")
    do_load("monster_city")
    do_load("crontab")
    do_load("room")
    do_load("union_mall")
    do_load("union_task")
    do_load("union_mission")
    do_load("union_word")
    do_load("union_buildlv")
    do_load("new_union")
    do_load("triggers")
    do_load("task_logic_t")
    do_load("msglist")
    do_load("lost_temple")
    do_load("gacha_limit_t")
    do_load("kw_mall")
    do_load("use_item_logic")
    do_load("rank_mng")

    do_load("gmmng")
    local rt = restore_handler.action()
    if rt == "Compensation" then
        gInit = "InitCompensate"
    else
        gInit = "InitGameDone"
    end

    gMapID=1 
    load_sys_config()
    load_uniq()
end

function check_pending()
    player_t.check_pending()
    build_t.check_pending()
    hero_t.check_pending()
    union_t.check_pending()
    room.check_pending()
    npc_city.check_pending()
end
