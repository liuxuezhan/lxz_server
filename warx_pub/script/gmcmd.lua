module( "gmcmd", package.seeall )


function do_cmd(cmd)
    INFO( "gm, cmd=%s", cmd )
    local gm_type = cmd.cmd

    local cmd_item = gmcmd_table[ gm_type ]
    if cmd_item == nil or not cmd_item then
        return {code = 0, msg = "no this cmd"}
    end

    return cmd_item[2](cmd.pids, unpack(cmd.param) )

end

function showbuf(pids)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        return {code = 1, msg = ply.bufs}
    end
    return {code = 0, msg = "no ply"}
end

function nospeak(pids, time)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        ply.nospeak_time = gTime + time
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function nologin(pids, time)
    local ply = getPlayer(tonumber(pids[1]))
    if ply then
        ply.nologin_time = gTime + time
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function addexp(param)
    local ply = getPlayer(tonumber(param[3]))
    if ply then
        local num = tonumber(param[2])
        ply:add_exp(num)
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function build_exp(param)
    local ply = getPlayer(tonumber(param[4]))
    if ply then
        local mode = tonumber(param[2])
        local num = tonumber(param[3])
        local t = union_buildlv.get_buildlv(ply.uid,mode)
        t.exp = exp
        return {code = 1, msg = "success"}
    end
    return {code = 0, msg = "no ply"}
end

function start_tw(pids, param)
    npc_city.start_tw()
    return {code = 1, msg = "success"}
end

function fight_tw(pids, param)
    npc_city.fight_tw()
    return {code = 1, msg = "success"}
end

function end_tw(pids, param)
    npc_city.end_tw()
    return {code = 1, msg = "success"}
end

function reward_tw(pids, param)
    npc_city.tw_random_award()
    return {code = 1, msg = "success"}
end

function start_lt(pids, param)
    lost_temple.start_lt()
    return {code = 1, msg = "success"}
end

function try_lt(pids, param)
    lost_temple.try_start_lt()
    return {code = 1, msg = "success"}
end

function end_lt(pids, param)
    lost_temple.end_lt()
    return {code = 1, msg = "success"}
end

function start_kw(pids, param)
    king_city.prepare_kw(param)
    return {code = 1, msg = "success"}
end

function fight_kw(pids, param)
    king_city.fight_kw()
    return {code = 1, msg = "success"}
end

function end_kw(pids, param)
    king_city.pace_kw()
    return {code = 1, msg = "success"}
end

function try_kw(pids, param)
    king_city.try_unlock_kw()
    return {code = 1, msg = "success"}
end

function addwhitelist(pids, open_id)
    local white_list = _G.white_list.list or {}
    if not white_list[open_id] then
        white_list[open_id] = open_id
    end
    set_white_list("list", white_list)
    return {code = 1, msg = "success"}
end

function activewhitelist(pids, active)
    set_white_list("active", active)
    return {code = 1, msg = "success"}
end

function adddebug(pids, lan_id)
    local ply = getPlayer(pids[1])
    if ply then
        ply:add_debug("", lan_id)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function refreshboss(pids, param)
    local ply = getPlayer(pids[1])
    if ply then
        monster.do_check(ply.x/16, ply.y/16)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function hurt(pids, arm_id, num)
    arm_id = tonumber(arm_id)
    num = tonumber(num)
    local ply = getPlayer(pids[1])
    if ply then
        local hurt = ply.hurts
        if not hurt[arm_id] then
            hurt[arm_id] = num
        else
            hurt[arm_id] = hurt[arm_id] + num
        end
        ply.hurts = hurt
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function pay(pids, product_id)
    local ply = getPlayer(pids[1])
    if ply then
        local param = {player_id = tostring(ply.pid), order_id = tostring(gTime), pay_amount = "1", product_id = product_id}
        agent_t.do_gm_cmd["pay"](param)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function taskbuild(pids)
    local ply = getPlayer(pids[1])
    if ply then
        task_logic_t.process_task(ply, TASK_ACTION.CITY_BUILD_LEVEL_UP) 
        task_logic_t.process_task(ply, TASK_ACTION.CITY_BUILD_MUB, 1)
        task_logic_t.process_task(ply,  TASK_ACTION.PROMOTE_POWER, 1, 1)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function fieldtop(pids)
    local ply = getPlayer(pids[1])
    if ply then
        ply:build_file()
        ply:build_top()
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function genboss(pids, mode, lv)
    local ply = getPlayer(pids[1])
    if ply then
        while true
            do
                local propid, x, y, eid = monster.force_born(math.floor(ply.x/16), math.floor(ply.y/16), tonumber(lv))
                if eid then
                    Rpc:gen_boss_eid_ack(ply, eid)
                    break
                end
            end
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function reset_city(pids, mode)
    if mode == ACT_NAME.NPC_CITY then
        npc_city.reset_all_npc()
    end
    if mode == ACT_NAME.LOST_TEMPLE then
        lost_temple.end_lt()
    end
    if mode == ACT_NAME.KING then
        king_city.reset_all_city()
    end
    return {code = 1, msg = "success"}
end

function ety_info(pids, eid)
    eid = tonumber(eid)
    local ply = getPlayer(pids[1])
    if ply then
        local ety = get_ety(eid)
        ety = ety or {}
        Rpc:ety_info_ack(ply, ety)
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end

function addcount(pids, s_id, s_num)
    local id = tonumber(s_id)
    local num = tonumber(s_num)
    local ply = getPlayer(pids[1])
    if ply then
        ply:add_count(id, num)
        if id ==  resmng.ACH_TASK_SPY_PLAYER then
            task_logic_t.process_task(ply, TASK_ACTION.SPY_PLAYER_CITY, 1) 
        end
        if id ==  resmng.ACH_TASK_CAPTIVE_HERO then
            task_logic_t.process_task(ply, TASK_ACTION.CAPTIVE_HERO, 1) 
        end
        if id == resmng.ACH_COUNT_GATHER then
            task_logic_t.process_task(ply, TASK_ACTION.GATHER, 1, num)
        end
        if id == resmng.ACH_TASK_ATK_RES1 then
            task_logic_t.process_task(ply, TASK_ACTION.LOOT_RES, 1, num)
        end

        if id == resmng.ACH_TASK_SHESHI_DONATE then
            task_logic_t.process_task(ply, TASK_ACTION.UNION_SHESHI_DONATE, 1)
        end

        if id == resmng.ACH_TASK_TECH_DONATE then
            task_logic_t.process_task(ply, TASK_ACTION.UNION_TECH_DONATE, 1)
        end
        return {code = 1, msg = "success"}
    else
        return {code = 0, msg = "no ply"}
    end
end


gmcmd_table = {
    --     -- 权限越大,数字越大
    --         -- 4 以下的都是普通玩家
    --             -- 4 普通GM
    --                 ------------------------------------------------------------------------------------------------------------------------------
    -- 名称               权限              执行函数            所属系统                                        实例
--系统gm
    ["adddebug"]         = { 4,              add_debug,         "冒字",                     "adddebug=111" },
    ["addwhitelist"]         = { 4,              addwhitelist,         "add whitelist",                     "addwhitelist=open_id" },
    ["activewhitelist"]         = { 4,              activewhitelist,         "activewhitelist",                     "activewhitelist" },
    ["showbuf"]         = { 4,              showbuf,         "show buff",                     "showbuf " },
    ["nospeak"]         = { 4,              nospeak,         "禁言",                     "nospeak=time=pid" },
    ["nologin"]         = { 4,              nologin,         "禁止登录",                     "nologin=time=pid" },
    ["addexp"]         = { 4,              addexp,         "加经验",                     "addexp=num=pid" },
    ["build_exp"]         = { 4,              build_exp,         "加军团建筑经验",                     "build_exp=mode=num=pid" },
------活动相关
    ["refreshboss"]         = { 4,              refreshboss,         "刷玩家周边boss",                     "refreshboss" },
    ["starttw"]         = { 4,              start_tw,         "攻城掠地开启",                     "starttw" },
    ["fighttw"]         = { 4,              fight_tw,         "攻城掠地战斗",                     "starttw" },
    ["endtw"]         = { 4,              end_tw,         "攻城掠地结束",                     "starttw" },
    ["rewardtw"]         = { 4,              reward_tw,         "攻城掠地发奖",                     "rewardtw" },

    ["startlt"]         = { 4,              start_lt,         "遗迹塔开启",                     "startlt" },
    ["trystartlt"]         = { 4,              try_start_lt,         "遗迹塔解锁",                     "trystartlt" },
    ["endlt"]         = { 4,              end_lt,         "遗迹塔结束",                     "endlt" },

    ["startkw"]         = { 4,              start_kw,         "王城战准备",                     "startkw" },
    ["fightkw"]         = { 4,              fight_kw,         "王城战战斗",                     "fightkw" },
    ["endkw"]         = { 4,              end_kw,         "王城战结束",                     "endkw" },
    ["peacekw"]         = { 4,              end_kw,         "王城战结束",                     "endkw" },
    ["trykw"]         = { 4,              try_kw,         "王城战解锁",                     "endkw" },
    ---- 测试使用
    ["buylist"]         = { 4,              buylist,         "生成购买列表",                     "buylist" },
    ["pay"]         = { 4,              pay,         "模拟购买",                     "pay=product_id" },
    ["hurt"] = {4, hurt, "增加伤兵", "hurt=arm_id=num"},
    ["addcount"] = {4, addcount, "增加计数器", "addcount=id=num"},
    ["taskbuild"] = {4, taskbuild, "更新城建相关任务", "taskbuild"},
    ["fieldtop"] = {4, fieldtop, "野地区域全满", "feildtop"},
    ["genboss"] = {4, genboss, "生成规定野怪", "genboss=mode=lv"},
    ["resetcity"] = {4, reset_city, "重置城市", "resetcity=mode"},
    ["occcitynum"] = {4, occ_city_num, "占领npc数量", "occcitynum"},
    ["etyinfo"] = {4, ety_info, "ety 信息", "etyinfo=eid"},

}
