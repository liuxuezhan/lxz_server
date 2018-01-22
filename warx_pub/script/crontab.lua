module("crontab") --年月日定时器

function union_donate_summary()
    LOG("[Union] summary start")
    local n = 1
    for _, u in pairs(unionmng.get_all()) do

        if n % 10 == 0 then 
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

        if n % 10 == 0 then 
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

function rem_all_mc()
    monster_city.rem_all_mc()
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
        local now = gTime
        local onlines = gOnlines
        for pid, node in pairs( onlines ) do
            local p = getPlayer( pid ) 
            if p and p.map == gMapID then
                if get_diff_days(gTime, p.cross_time) > 0 then
                    p:on_day_pass()
                end
            end
        end

        --抽卡限制重置
        gacha_limit_t.gacha_limit_on_day_pass()
        --周限时活动
        weekly_activity.on_day_pass()
        periodic_activity_manager.on_day_pass()

        _G.gSysStatus.pass_day_tick = gTime
        set_sys_status("pass_day_tick", gTime)
    end
end

function try_start_kw()
    king_city.try_unlock_kw()
end

function try_open_act()
    act_mng.try_open_act()
end

function send_boss_award()
    monster.send_score_award()
    rank_mng.clear(11)
end

function send_tw_award()
    npc_city.send_score_award()
end

function send_mc_award()
    monster_city.send_score_award()
 --   rank_mng.clear(7)
 --   rank_mng.clear(8)
end

function send_lt_award()
    --lost_temple.send_score_award()
    rank_mng.clear(9)
    rank_mng.clear(10)
end

function cross_act_start()
    if gCenterID == gMapID then
        cross_mng_c.cross_act_start()
    end
end

function upload_gs_info()
    if gCenterID == gMapID then
        return
    end

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
                pack.king_culture = king_ply.culture
                local union = unionmng.get_union(king_ply:get_uid())
                if union then
                    pack.king_u_name = union.name
                    pack.king_language = union.language
                else
                    pack.king_u_name = ""
                    pack.king_language = -1
                end
            else
                pack.king_name = now_king[6]
                pack.king_culture = now_king[12]
                pack.king_u_name = now_king[9]
                pack.king_language = now_king[11]
            end
        end
    end
    Rpc:callAgent(gCenterID, "upload_gs_info", pack)
end

function first_pre_boss_atk_city()
    npc_city.first_pre_boss_atk_city()
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

function operate_dice()
    local open_time = get_sys_status("start")
    local tm = os.date( "*t", open_time )
    _G.gOperateDiceTime = 0
    _G.gOperateDiceIdx = 0

    local unlock_time = os.time( {year=tm.year, month=tm.month, day=tm.day+7, hour=0, min=0, sec=0} )
    if gTime < unlock_time then
        timer.new( "operate_dice", unlock_time - gTime + 1 )
        return
    end

    local tm_base = 0
    if tm.wday >= 2 then
        tm_base = open_time - ( (tm.wday-2) * 3600 * 24 + tm.hour * 3600 + tm.min * 60 + tm.sec )
    else
        tm_base = open_time - ( (tm.wday-6) * 3600 * 24 + tm.hour * 3600 + tm.min * 60 + tm.sec )
    end

    local OneWeek = 3600 * 24 * 7
    local OneDay = 3600 * 24

    local nweek = math.floor( ( gTime - tm_base ) / OneWeek ) + 1
    local offset = ( gTime - tm_base ) % OneWeek

    local start = 0
    if nweek == 1 then
        start = gTime + OneWeek - offset + OneDay * ( 4 + 7 )

    elseif nweek == 2 then
        start = gTime + OneWeek - offset + OneDay * ( 4 )

    elseif nweek % 2 == 1 then
        if offset >= 4 * OneDay then
            start = gTime - ( offset - 4 * OneDay )
        else
            start = gTime + ( 4 * OneDay - offset )
        end
    else
        start = gTime + OneWeek - offset + OneDay * ( 4 )
    end
    _G.gOperateDiceTime = start

    local idx = 0
    if start > 0 then
        nweek = math.floor( ( start - tm_base ) / OneWeek ) + 1
        idx = math.floor( (nweek - 1)/2 )
        local conf = resmng.prop_dice
        local total = #conf
        idx = idx % total
        if idx == 0 then idx = total end
        _G.gOperateDiceIdx = idx
        WARN( "OperateDice, nweek,%d, idx,%d", nweek, idx )
    end

    Rpc:operate_dice_query( {pid=-1,gid=_G.GateSid}, start, idx )

    local t = os.date( "*t", _G.gOperateDiceTime )
    for k, v in pairs( t ) do
        WARN( "OperateDice, %s, %s", k, v )
    end
end

