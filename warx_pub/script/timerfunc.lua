module("timer")

_funs["cron"] = function(sn)
    timer.cron_base_func()

    if gTime - gThreadActionTime > 10 then
        if gInit ~= "InitCompensate" then
            if gTime - gThreadActionTime > 10 then
                if gThreadAction and gThreadActionState == "idle" and coroutine.status( gThreadAction ) == "suspended" then

                else
                    gThreadAction = nil
                    global_save()
                end
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

    local plys = player_t.gOnlines
    local now = gTime
    local total = 0

    for pid, p in pairs( plys ) do
        local offset = gTime - ( p.tick or 0 ) 
        if offset < 70 then
            total = total + 1
        elseif offset < 140 then
            total = total + 1
            Rpc:activate(p)
        else
            plys[ pid ] = nil
        end
    end

    player_t.g_online_num = total
    INFO( "[Online], %d", total )
    player_t.pre_tlog(nil,"GameSvrState",config.GameHost,(player_t.g_online_num or 0),(get_sys_status("start") or 0) ,0 )
end

_funs["monitor"] = function(sn, num)
    --timer.new("monitor", 20, (num+1))
    --monitoring(MONITOR_TYPE.TOTAL)
    if num % 3 == 0 then
        --monitoring(MONITOR_TYPE.LUAOBJ)
    end
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

_funs["refugee"] = function(sn, state, eid)
    if eid then
        local refugee = get_ety(eid)
        if refugee then
            refugee.finish_grap(refugee)
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
        union_help.del(p,sn)
        p:doTimerBuild(sn, build_idx, ...)
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
    dumpTab(ts, "item")
end

_funs["release_prisoner"] = function(sn, pid, hero_id)
    local p = getPlayer(pid)
    if p then
        p:release_prisoner(hero_id, sn)
    else
        ERROR("[timerfunc.release_prisoner]: get player failed. pid = %d, hero_id = %d.", pid, hero_id)
    end
end

_funs.expiry = function(sn, pid, heroid, over)
    local ply = getPlayer(pid)
    if ply then
        local jail = ply:get_prison()
        if jail then
            local h = jail:release(heroid, over)
            if h then
                ply:release(h)
            end
        end
    end
end


_funs["delete_kill_buff"] = function(sn, pid, buff_id)
    local p = getPlayer(pid)
    if p then
        p:update_kill_buff(buff_id)
    end
end

_funs["destroy_dead_hero"] = function(sn, pid, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if hero and hero.status ~= HERO_STATUS_TYPE.DEAD then
        heromng.destroy_hero(hero_id)
    end
    local p = getPlayer( pid )
    if p then
        p:add_count( resmng.ACH_COUNT_KILL_HERO, 1 )
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
        p:rem_buf( bufid, tmOver )
    end
end



_funs["rem_buf_build"] = function(sn, pid, idx, bufid, tmOver)
    local ply = getPlayer(pid)
    if ply then
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

_funs["check"] = function(sn, pid)
    local ply = getPlayer( pid )
    if not ply then return end
    if ply.tm_check ~= sn then return end

    local offset = gTime - ( ply.tick or 0 )
    LOG( "[check], pid=%d, offset=%d", pid, offset )
    ply:initEffect()

    if offset < 120 then
        ply.tm_check = timer.new( "check", 2400, pid )

    elseif offset < 1200 then
        ply.tm_check = timer.new( "check", 2400, pid )
        if ply.tm_logout < ply.tm_login and ply.tm_login > gBootTime then
            player_t.onBreak( ply )
        end

    else
        LOG( "[check], pid=%d, off", pid )
        ply._mail = nil
        ply._build = nil
        ply._item = nil
        ply.tm_check = nil
        ply:clear_task()

        local home = troop_mng.get_troop( ply.my_troop_id )
        if home then
            for pid, arm in pairs( home.arms or {} ) do
                local info = {}
                info.live_soldier = arm.live_soldier
                info.pid = pid
                home.arms[ pid ] = info
            end
        end
    end
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

_funs["make_group_ntf"] = function(sn, notify_id, time)
    time = time or 0
    cross_mng_c.make_group_ntf(notify_id)
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
        ply:rem_state( state )
    end
end


_funs["world_event"] = function(sn, id)
    world_event.check_time(sn, id)
end


