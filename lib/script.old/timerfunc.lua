module("timer")

_funs["toGate"] = function(sn, ip, port)
        conn.toGate(ip, port)
    end

_funs["toMongo"] = function(sn, host, port, db)
        conn.toMongo(host, port, db)
    end

_funs["cron"] = function(sn)
        local nextCron = 60 - (gTime % 60) + 30
        timer.new("cron", nextCron)

        mem_info()
        monster.loop()
        farm.loop()
        crontab.loop()
        fight.clean_report()

        _G.gSysStatus.tick = gTime
        gPendingSave.status[ gMapID ].tick = gTime
        
        --print("crontab, gTime = ", gTime)
    end

_funs["cure"] = function(sn, pid)
    local p = getPlayer(pid)
    if p then
        p:addTips("timeout cure")
        p.tm_cure = 0
        p.cure_start = 0
        p.cure_over = 0
        p:cure_off()

        p:add_home_arm( p.cures )
        p.cures = {}
    end
end

_funs["hero_cure"] = function(sn, pid, hidx, tohp)
    local p = getPlayer( pid )
    if p then
        local hero = p:get_hero( hidx )
        if hero and hero.tmSn == sn then
            --任务
            task_logic_t.process_task(p, TASK_ACTION.CURE, 1, (tohp - hero.hp))

            hero.status = HERO_STATUS_TYPE.FREE
            hero.hp = math.floor( tohp )
            hero.tmSn = 0
            hero.tmStart = 0
            hero.tmOver = 0
        end
    end
end

_funs["troop"] = function(sn, pid, tid)
        local p = getPlayer(pid)
        p:doTimerTroop(sn, tid)
    end

_funs["union_troop_buf"] = function(sn, uid,buf)
    local u = unionmng.get_union(uid)
    for _,v  in pairs(u._members ) do
        local p = getPlayer(v.pid)
        p:ef_rem(buf)
    end
end

_funs["monster"] = function(sn, zx, zy, grade)
    monster:do_time_boss(sn, zx, zy, grade)
end

_funs["monster_city"] = function(sn, uid, stage)
    local union = unionmng.get_union(uid)
    if union then
        union_t.set_mc_state(union, stage)
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
        if state == 1 then
            lost_temple.start_lt()
        elseif state == 2 then
            lost_temple.end_lt()
        end
    end
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
        p:doTimerBuild(sn, build_idx, ...)
    end

_funs["learn_tech"] = function(sn, pid, build_idx, tech_id)
    local p = getPlayer(pid)
    if p then
        p:doTimerBuild(sn, build_idx, tech_id)
    else
        ERROR("[timerfunc.learn_tech]: get player failed. pid = %d, build_idx = %d, tech_id = %d.", pid, build_idx, tech_id)
    end
end

_funs["mass"] = function(sn, uid, idx)
    local union = unionmng.get_union(uid)
    union:do_timer_mass(sn, idx)
end

_funs["uniontech"] = function(sn, uid, idx)
    local union = unionmng.get_union(uid)
    union:do_timer_tech(sn, idx)
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


_funs["kill_hero"] = function(sn, pid, build_idx, hero_id, buff_id, buff_time)
    local p = getPlayer(pid)
    if p then
        -- p:real_kill_hero(hero_id, buff_id, buff_time)
        p:doTimerBuild(sn, build_idx, hero_id, buff_id, buff_time)
    end
end

_funs["delete_kill_buff"] = function(sn, pid, buff_id)
    local p = getPlayer(pid)
    if p then
        p:update_kill_buff(buff_id)
    end
end

_funs["destroy_dead_hero"] = function(sn, hero_id)
    local hero = heromng.get_hero_by_uniq_id(hero_id)
    if hero and hero.status ~= HERO_STATUS_TYPE.DEAD then
        heromng.destroy_hero(hero_id)
    end
end

_funs["buf"] = function(sn, pid, bufid, tmOver)
    local p = getPlayer(pid)
    if p then
        p:rem_buf(bufid, tmOver)
    end
end


_funs["union_gather_empty"] = function(sn, eid)
    local dest = get_ety(eid)
    if dest and dest.tmSn == sn then
        dest.val = 0
        dest.speed = 0
        dest.tmStart = 0
        dest.tmOver = 0
        dest.tmSn = 0

        local u = unionmng.get_union(dest.uid)
        union_build_t.remove_build(u, dest.idx)

        for _, tid in pairs(dest.my_troop_id) do
            local troop = troop_mng.get_troop(tid)
            if troop then

                local count = troop:get_extra("speed") * (gTime - troop:get_extra("tm"))
                local mode = troop:get_extra("mode")
                local gains = {}
                table.insert(gains, { "res", mode, math.ceil(count) })

                troop_mng.mount_bonus(troop, gains, VALUE_CHANGE_REASON.GATHER)
                troop:clr_extra("speed")
                troop:clr_extra("tm")
                troop:clr_extra("mode")
                troop.tmSn = 0
                local p = get_ety(troop.owner_pid)
                if p  then
                    union_mission.ok(p,UNION_MISSION_CLASS.GATHER ,calc_res(mode,count))
                end
                troop_mng.troop_back(tr)
            end
        end
        dest.my_troop_id = {}
        union_build_t.mark(dest)
    end
end


_funs["union_build_complete"] = function(sn, eid)
    local dest = get_ety(eid)
    if dest and dest.tmSn == sn then
        for _, tid in pairs(dest.my_troop_id) do
            local troop = troop_mng.get_troop(tid)
            if troop then
                troop.tmSn = 0
                troop_mng.troop_back(troop)
            end
        end
        dest.hp = resmng.get_conf("prop_world_unit", dest.propid).Hp
        dest.tmStart = 0
        dest.tmOver = 0
        dest.tmSn = 0
        dest.speed = 0
        dest.state = BUILD_STATE.WAIT
        dest.my_troop_id = nil 
        union_build_t.mark(dest)
    end
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
    local wall = ply:get_wall()
    local cur = wall:get_extra( "cur" )
    if not cur then return end

    local fire = wall:get_extra( "fire" )
    if not fire then return end
    if gTime > fire then 
        wall:clr_extra( "fire" )
        return 
    end

    local dura = 1
    local black = 0
    if is_in_black_land( ply.x, ply.y ) then 
        cur = cur - WALL_FIRE_IN_BLACK_LAND
        black = 1
    else 
        cur = cur - 1 
        dura = WALL_FIRE_SECONDS
    end

    if cur <= 0 then
        local x, y = c_get_pos_by_lv(1,4,4)
        if x then
            --call back all troop
            c_rem_ety(ply.eid)
            ply.x = x
            ply.y = y
            etypipe.add(ply)
        end
        wall:clr_extras( { "cur", "last", "fire", "black" } )

    else
        wall:set_extra( "cur", cur )
        wall:set_extra( "black", black )
        timer.new( "city_fire", dura, pid )
    end
end

