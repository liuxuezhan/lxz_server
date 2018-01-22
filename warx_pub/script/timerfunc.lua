module("timer")

_funs["cron"] = function(sn)
    timer.cron_base_func()

    if gTime - gThreadActionTime > 10 then
        if gInit ~= "InitCompensate" then
            if gThreadAction and gThreadActionState == "idle" and coroutine.status( gThreadAction ) == "suspended" then

            else
                local co = coroutine.create( global_saver )
                coro_mark_create( co, "global_saver" )
                coro_mark( co, "outpool" )
                coroutine.resume( co )
            end	
        end
    end

    set_sys_status( "tick", gTime )
    set_sys_status( "cron", gTime )

    monster.loop()
    farm.loop()
    refugee.loop()
    fight.clean_report()

    for what, cos in pairs( gCoroPend ) do
        local count = table_count( cos )
        if count > 0 then
            INFO( "CoroPend %s, %d", what, count )
        end
    end

    for what, cos in pairs( gCoroPool ) do
        local count = table_count( cos )
        if count > 0 then
            INFO( "CoroPool %s, %d", what, count )
        end
    end

    local db = dbmng:tryOne()
    local total = 0
    local onlines = gOnlines
    local gone = {}

    --local tlog_onlines = { }
    --for k, v in pairs( config.GameAppIDs ) do
    --    tlog_onlines[ k ] = { [0] = 0, [1] = 0 }
    --end

    for pid, node in pairs( onlines ) do
        local p = getPlayer( pid ) 
        if p and p.map == gMapID then
            local offset = gTime - node[2]
            --local gameappid = p.gameappid 
            --local platid = p.PlatID 
            --if platid ~= 0 and platid ~= 1 then platid = 0 end

            --if offset < 300 then
            if offset < 60 then
                total = total + 1
                --if not tlog_onlines[ gameappid ] then tlog_onlines[ gameappid ] = {} end
                --tlog_onlines[ gameappid ][ platid ] = ( tlog_onlines[ gameappid ][ platid ] or 0 ) + 1
            --elseif offset < 400 then
            elseif offset < 120 then
                total = total + 1
                --if not tlog_onlines[ gameappid ] then tlog_onlines[ gameappid ] = {} end
                --tlog_onlines[ gameappid ][ platid ] = ( tlog_onlines[ gameappid ][ platid ] or 0 ) + 1
                Rpc:ping( p, gMapID )
            else
                table.insert( gone, pid )
                break_player( pid )
                player_t.onBreak( p, p.sockid or 0 ) 
            end
        else
            table.insert( gone, pid )
        end
    end
    if player_t.g_online_num ~= total then
        player_t.g_online_num = total
        c_set_online( total )
    end

    for _, pid in pairs( gone ) do onlines[ pid ] = nil end

    INFO( "[Online], %d", player_t.g_online_num )
    player_t.pre_tlog(nil,"GameSvrState",config.GameHost,(player_t.g_online_num or 0),(get_sys_status("start") or 0) ,0 )


    --min = min + 1
    --for k, v in pairs( tlog_onlines or {} ) do
    --    player_t.tlog_ten(nil,"onlinecnt",tms2str(), k, gTime, config.Country, gMapID, gMapID, v[0] or 0 , v[1] or 0 )
    --    player_t.tlog_ten2(nil,"OnlineCount",gMapID,tms2str(), k, gMapID, v[0] or 0, 0 )
    --    player_t.tlog_ten2(nil,"OnlineCount",gMapID,tms2str(), k, gMapID, v[1] or 0, 1 )
    --    --local node = { timekey=gTime, gsid=gMapID, zoneareaid=gMapID, gameappid=k }
    --    --node.onlinecntios = v[0] or 0
    --    --node.onlinecntandroid = v[1] or 0
    --    --insert_global( "onlinecnt", string.format( "%s_%s_%d", gMapID, k, gTime ), node )
    --end

    --if (min%5) == 0 then 
    --    player_t.tlog_ten(nil,"GameSvrState" ) 
    --    player_t.tlog_ten2(nil,"GameSvrState" ) 
    --end
end


_funs["cure"] = function(sn, pid)
    local p = getPlayer(pid)
    if p then
        union_help.del(p,sn)
        p.tm_cure = 0
        p.cure_start = 0
        p.cure_over = 0

        local count = 0
        for id, num in pairs( p.cures ) do
            count = count + num
        end
        --cross rank
        --local pow = p:calc_cure_pow(p.cures)
        --cross_score.process_score(RANK_ACTION.CURE, p.pid, p.uid, pow)

        p:add_soldiers( p.cures )
        p:add_count( resmng.ACH_COUNT_CURE, count )
        p.cures = {}

        --任务
        task_logic_t.process_task(p, TASK_ACTION.CURE, 2, count)
        --世界事件
        world_event.process_world_event(WORLD_EVENT_ACTION.CURE_SOLDIER, count)
        p:clear_one()
    end
end

_funs["hero_cure"] = function(sn, pid, hidx, tohp)
    local p = getPlayer( pid )
    if p then
        union_help.del(p,sn)
        local hero = p:get_hero( hidx )
        if hero and hero.tmSn == sn then
            --任务
            task_logic_t.process_task(p, TASK_ACTION.CURE, 1, (tohp - hero.hp))

            hero.hp = math.floor( tohp )
            p:hero_set_free( hero )
            hero.tmSn = 0
            hero.tmStart = 0
            hero.tmOver = 0
            hero_t.mark_recalc( hero )
        end
        p:clear_one()
    end
end

_funs["hero_task"] = function(sn, pid, tr_id, task_id)
    local p = getPlayer( pid )
    local tr = troop_mng.get_troop(tr_id)
    if tr then
        tr:home()
    end
    if p and tr then
        local task = p:get_hero_task(HERO_TASK_MODE.CUR_LIST, task_id)
        if task then
            local prop = resmng.get_conf("prop_hero_task_detail", task.task_id)
            if not prop then
                return
            end
            if task.status == TASK_STATUS.TASK_STATUS_DOING then
                if prop.EventCondition then
                    local do_event = player_t.check_event_condition(task, prop.EventCondition)
                    if task.task_type == 2 then
                        do_event = do_event and (get_table_valid_count(task.task_plys or {}) == 3)
                    end
                    task.do_event = do_event
                end
                if task.do_event == true then
                    task.status = TASK_STATUS.TASK_STATUS_CAN_EVENT
                else
                    task.status = TASK_STATUS.TASK_STATUS_CAN_FINISH
                end
                for _, ply in pairs(task.task_plys or {}) do
                    ply.status = task.status
                    --ply.status = TASK_STATUS.TASK_STATUS_CAN_EVENT 
                end
                for _, task_ply in pairs(task.task_plys or {}) do
                    for _, hero in pairs(task_ply.heros or {}) do
                        local h =  heromng.get_hero_by_uniq_id(hero._id)
                        if h then
                            h.hero_task_status = HERO_STATUS_TYPE.FREE
                        end
                    end
                end
                 --task.status = TASK_STATUS.TASK_STATUS_CAN_EVENT
                p:set_hero_task2(HERO_TASK_MODE.CUR_LIST, task_id, task)
                union_help.del(p,sn)
                --Rpc:update_hero_task_ack(p, task)
                player_t.update_hero_task(task)
            end
        end
    end
end

_funs["troop"] = function(sn, pid, tid)
        local p = getPlayer(pid)
        p:doTimerTroop(sn, tid)
    end

_funs["monster"] = function(sn, zx, zy, grade)
    monster.do_time_boss(sn, zx, zy, grade)
end

_funs["monster_city"] = function(sn, uid, stage)
    local union = unionmng.get_union(uid)
    if union then
        union_t.set_mc_state(union, stage)
        monster_city.update_mc_ntf()
    end
end


_funs["mc_notify"] = function(sn, notify_id, uid)
    local union = unionmng.get_union(uid)
    if union then
        union:mc_notify(notify_id)
    end
end

_funs["remove_mc"] = function(sn, eid)
    local city = get_ety(eid)
    if city then
        monster_city.remove_city(city)
    end
end

_funs["npc_city"] = function(sn, eid, state)
    local npcCity = gEtys[ eid ]
    if npcCity then
        if state == TW_STATE.PREPARE then
            npc_city.prepare_state(npcCity)
        elseif  state == TW_STATE.FIGHT then
            npc_city.fight_state(npcCity)
        elseif  state == TW_STATE.DECLARE then
            npc_city.declare_state(npcCity)
            npc_city.def_success(npcCity)
        end
    end

end

_funs["tw_stage"] = function(sn, stage, tm)
    if stage == TW_STATE.DECLARE then
        npc_city.start_tw(tm)
    elseif stage == TW_STATE.PACE then
        npc_city.end_tw()
    end
end

_funs["refugee"] = function(sn, state, eid)
    if eid then
        local refugee = get_ety(eid)
        if refugee then
            refugee:finish_grab()
        end
    end
end

_funs["refugee_gift"] = function(sn, state, eid, pid)
    if eid then
        local refugee = get_ety(eid)
        if refugee then
           refugee:refugee_gift(pid)
        end
    end
end

_funs["lost_temple"] = function(sn, state, eid, propid)
    if eid then
        if state == 1 then
            local lt = get_ety(eid)
            if lt then
                lost_temple.finish_grap_state(lt)
            end
        elseif state == 2 then
            lost_temple.gen_temple_by_propid(propid)
        end
    else
        if state == LT_STATE.ACTIVE then
            lost_temple.start_lt()
        elseif state == LT_STATE.DOWN then
            lost_temple.end_lt()
        end
    end
end

_funs["start_lt"] = function(sn)
    lost_temple.start_lt()
end

_funs["king_state"] = function(sn, state, eid)
    if not eid then
        if state == KW_STATE.PAREPARE then
            king_city.prepare_kw()
        end
        if state == KW_STATE.FIGHT then
            king_city.fight_kw()
        end
        if state == KW_STATE.PACE then
            king_city.pace_kw()
        end
    end

end

_funs["kw_notify"] = function(sn, notify_id, time)
    time = time or 0
    king_city.send_notify(notify_id, time)
end

_funs["select_default_king"] = function(sn)
    king_city.select_default_king()
end

_funs["king_city"] = function(sn, eid, Type, troopId)
    local city = get_ety(eid)
    if city then
        if troopId then
            king_city.try_fire_troop(city, troopId)
            return
        end
        if Type == "fire" then
            king_city.try_fire_king(city)
            return
        end
        if Type == "troop" then
            king_city.try_atk_king(city)
            return
        end
        if Type == "towerDown" then
            king_city.reset_tower(city)
            return
        end
    end
end

_funs["union_build"] = function(sn,at, eid)
        union_build_t.update_val(at, eid,sn)
    end

_funs["union_gather" ] = function(sn, eid)

end


_funs["build"] = function(sn, pid, build_idx, ...)
    local p = getPlayer(pid)
    if p then
        union_help.del(p,sn)
        p:doTimerBuild(sn, build_idx, ...)
    end
end

_funs["mass"] = function(sn, uid, idx)
    local union = unionmng.get_union(uid)
    union:do_timer_mass(sn, idx)
end

_funs["uniontech"] = function(sn, uid, idx)
    local union = unionmng.get_union(uid)
    union_tech_t.up_ok(union,sn, idx)
end


_funs["test"] = function(sn, uid, idx)
    local p = getPlayer(30001)
    local ts = p:get_item()
end

_funs.expiry = function(sn, pid, heroid, over)
    local ply = getPlayer(pid)
    if ply then
        if ply:get_cross_state() == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
            return
        end
        local jail = ply:get_prison()
        if jail then
            local h = jail:release(heroid, over)
            if h then
                ply:release(h)

                local B = getPlayer( h.pid )
                if B then
                    local uname = ""
                    local Bunion = unionmng.get_union( B.uid )
                    if Bunion then uname = string.format( "(%s)", Bunion.alias) end
                    ply:send_system_notice( resmng.MAIL_10078, {}, {uname, B.name, h.name} )
                end
            end
        end
    end
end

_funs["union_buf"] = function(sn, uid, bufid, tmOver)
    local union = unionmng.get_union(uid)
    if union then
        union:rem_buf(bufid, tmOver)
    end
end



_funs["globuf"] = function(sn, bufid, tmOver)
    kw_mall.rem_buf(bufid, tmOver)
end


_funs["union_gather_empty"] = function(sn, eid)
    local dest = get_ety(eid)
    if dest and dest.tmSn_g == sn then
        union_build_t.recalc_gather( dest )
    end
end


_funs["union_build_complete"] = function(sn, eid)
    local dest = get_ety(eid)
    if dest and dest.tmSn_b == sn then
		union_build_t.mark(dest)
        save_ety(dest)
    end
end



_funs["union_build_fire"] = function(sn, eid)
    local dest = get_ety(eid)
    if dest and dest.tmSn_f == sn then
        dest.tmSn_f = 0
        dest.tmOver_f = 0
        union_build_t.recalc_build( dest )
    end
end

_funs["union_build_construct"] = function(sn, eid)
    local dest = get_ety(eid)
    if dest and dest.tmSn_b == sn then
        dest.tmSn_b = 0
        dest.tmOver_b = 0
        union_build_t.recalc_build( dest )
    end
end
_funs["union_mission"] = function(sn, uid)
    union_mission.add(uid)
end


_funs["rem_buf_troop"] = function(sn, tid, bufid, tmOver)
    local troop = troop_mng.get_troop(tid)
    if troop then
        for k, v in pairs(troop.bufs) do
            if v[1] == bufid and v[2] == tmOver then
                table.remove(troop.bufs, k)
                troop:recalc()
                return
            end
        end
    end
end

_funs["buf"] = function(sn, pid, bufid, tmOver)
    local p = getPlayer( pid )
    if p then
        if p:get_cross_state() == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
            return
        end
        p:rem_buf( bufid, tmOver )
        p:clear_one()
    end
end



_funs["rem_buf_build"] = function(sn, pid, idx, bufid, tmOver)
    local ply = getPlayer(pid)
    if ply then
        if ply:get_cross_state() == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
            return
        end
        local build = ply:get_build(idx)
        if build then
            for k, v in pairs(build.bufs) do
                if v[1] == bufid and v[2] == tmOver then
                    table.remove(build.bufs, k)
                    build.bufs = build.bufs
                    build:recalc()
                    return
                end
            end
        end
    end
end

_funs["troop_action"] = function(sn, tid)
    troop_mng.troop_timer(sn, tid)
end

_funs["city_fire"] = function(sn, pid)
    local ply = getPlayer( pid )

    if ply then 
        local wall = ply:get_wall()
        if wall then
            if sn == wall:get_extra( "tmSn_f" ) then
                ply:wall_fire( 0 )
            end
        end
    end
end


g_log_idx = 0
_funs["tlog"] = function(sn, tid)
    c_tlog( string.format("rolelogin|%d|2012-07-12|222222|111111", g_log_idx ) )
    timer.new("tlog", 1 )
    g_log_idx = g_log_idx + 1
end


_funs["check_frame"] = function(sn, idx)
    if idx <= 100 then
        if idx == 0 or idx == 100 then LOG( "checkframe, %d, %d", idx, gMsec ) end
        timer.new( "check_frame", 0, idx+1)
    end
end


_funs["troop_back"] = function(sn, tid)
    local troop = troop_mng.get_troop( tid )
    if troop then troop:back() end
end

_funs["tool_test"] = function(sn)
    tool_test()
end

_funs["cross_act_notify"] = function(sn, notify_id, time)
    time = time or "24"
    cross_mng_c.cross_act_notify(notify_id, time)
end

_funs["cross_act"] = function(sn, state)
    if state == CROSS_STATE.FIGHT then
        cross_mng_c.cross_act_fight()
    elseif state == CROSS_STATE.PEACE then
        cross_mng_c.cross_act_end()
    elseif state == CROSS_STATE.PREPARE then
        cross_mng_c.cross_act_prepare()
    end
end


_funs["remove_state"] = function(sn, pid, state)
    local ply = getPlayer( pid )
    if ply then
        if ply:get_cross_state() == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
            return
        end
        ply:rem_state( state )
    end
end


_funs["world_event"] = function(sn, id)
    world_event.check_time(sn, id)
end

_funs["cross_migrate_back"] = function(sn, pid)
    local player = getPlayer(pid)
    if player then
        player:cross_migrate_back(-1, -1)
    end
end

_funs["batch_claim_cross_award"] = function(sn, pids)
    for _, pid in pairs(pids) do
        local player = getPlayer(pid)
        if player then
            player:claim_cross_award()
        end
    end
end

_funs["periodic_bihourly_activity"] = function(sn)
    periodic_activity_manager.on_bihour_pass()
    return 1
end

_funs["periodic_upload_score_watcher"] = function(sn, pid, mode)
    local player = getPlayer(pid)
    if not player then
        return
    end
    return player:reupload_periodic_score(mode)
end

_funs["operate_dice"] = function()
    crontab.operate_dice()
end

_funs["ship_fcm"] = function(sn, pid)
    local ply = getPlayer(pid)
    if ply then
        offline_ntf.post(resmng.OFFLINE_NOTIFY_DAILYAWARD, ply)
    end
end

_funs["res_fcm"] = function(sn, pid)
    local ply = getPlayer(pid)
    if ply then
        offline_ntf.post(resmng.OFFLINE_NOTIFY_RESFULL, ply)
    end
end

