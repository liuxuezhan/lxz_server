module("crontab") --年月日定时器

function union_donate_summary()
    LOG("[Union] summary start")
    local n = 1
    for _, u in pairs(unionmng.get_all()) do

        if n % 50 == 0 then 
            begJob() 
            wait(1) 
        end
        n = n + 1

        u:donate_summary_day()
    end
    LOG("[Union] summary end")
end

function union_donate_week()
    LOG("[Union] week start")
    local n = 1
    for _, u in pairs(unionmng.get_all()) do

        if n % 50 == 0 then 
            begJob() 
            wait(1) 
        end
        n = n + 1

        u:donate_summary_week()
    end
    LOG("[Union] week end")
end


function start_tw()
    npc_city.start_tw()
end

function end_tw()
    npc_city.end_tw()
end

function reset_kw_mall()
    kw_mall.refresh_kw_mall()
end

function try_open_lt()
    lost_temple.try_start_lt()
end

--boss reset at AM 0
function on_day_pass()
    local last_tick = _G.gSysStatus.pass_day_tick or 0
    if get_diff_days(gTime, last_tick) > 0 then
        farm.on_day_pass()
        monster.on_day_pass()  --- boss reset
        npc_city.on_day_pass() --- npc score

        INFO( "on_day_pass, system" )
        player_t.refresh_global_black_market()


        --玩家跨天
        for k, v in pairs(gPlys) do
            if v:is_online() then
                if get_diff_days(gTime, v.cross_time) > 0 then
                    v:on_day_pass()
                end
            end
        end
        --抽卡限制重置
        gacha_limit_t.gacha_limit_on_day_pass()
        --周限时活动
        weekly_activity.on_day_pass()

        _G.gSysStatus.pass_day_tick = gTime
        set_sys_status("pass_day_tick", gTime)
    end
end

function try_start_kw()
    king_city.try_unlock_kw()
end

function send_boss_award()
    monster.send_score_award()
    rank_mng.clear(11)
end

function send_tw_award()
    npc_city.send_score_award()
    rank_mng.clear(12)
    rank_mng.clear(13)
end

function send_mc_award()
    monster_city.send_score_award()
    rank_mng.clear(7)
    rank_mng.clear(8)
end

function send_lt_award()
    lost_temple.send_score_award()
    rank_mng.clear(9)
    rank_mng.clear(10)
end

function cross_act_start()
    cross_mng.cross_act_start()
end

function upload_gs_info()
    local center_id = 999
    local pack = {}
    pack.pid = gMapID
    pack.power = cal_gs_power()
    
    local kings = king_city.kings
    local king = {}
    if kings then
        local now_king = kings[king_city.season]
        if now_king then
            local king_ply = getPlayer(now_king[2])
            if king_ply then
                pack.king_name = king_ply.name
            else
                pack.king_name = now_king[6]
            end
        end
    end
    Rpc:callAgent(center_id, "upload_gs_info", pack)
end

function prepare_boss_attack_city()
    npc_city.prepare_boss_attack_city()
end

function start_boss_attack_city()
    npc_city.start_boss_attack_city()
end

function tmp_stop_boss_attack_city()
    npc_city.tmp_stop_boss_attack_city()
end

function stop_boss_attack_city()
    npc_city.stop_boss_attack_city()
end

function operate_activity_tick()
    operate_activity.heart_beat()
end
