module("troop_mng", package.seeall)

troop_id_map = troop_id_map or {}
gTroopActionTrigger = {}
send_report = {}


function load_data(t)
    local troop = troop_t.load_data(t)
    if not troop then return end

    local id = troop._id
    if troop_id_map[ id ] then
        WARN( "troop_mng.load_data, already have %d", id )
        return
    end

    troop_id_map[troop._id] = troop
    -- check_troop will handle
    --local obj = get_ety(t.target_eid)
    --if obj then
    --    if t:is_go() and (t:get_base_action() == TroopAction.HoldDefense 
    --        or t:get_base_action() == TroopAction.HoldDefenseNPC
    --        or t:get_base_action() == TroopAction.HoldDefenseKING
    --        or t:get_base_action() == TroopAction.HoldDefenseLT)
    --        then
    --        if obj == nil then return troop:back() end

    --    elseif t:is_settle() then
    --        if obj and is_union_building( obj ) then
    --            if t:get_base_action() == TroopAction.Gather then

    --            else
    --                obj.my_troop_id = t._id
    --            end
    --            --union_build_t.mark(obj)
    --            --save_ety(obj)
    --        end
    --    end
    --else

    --end
end

function check_troop( tm_shutdown )
    local dels = {}
    for tid, troop in pairs( troop_id_map ) do
        local valid = true
        local owner = get_ety( troop.owner_eid )
        local target = get_ety( troop.target_eid )

        local action = troop.action
        local baction = action % 100

        if not target then
            valid = false
        else
            if troop:is_go() or troop:is_back() then
                if troop.tmOver and troop.tmOver > tm_shutdown then
                    local v = troop
                    local dist = c_calc_distance( v.curx or v.sx, v.cury or v.sy, v.dx, v.dy )
                    local use_time = dist / v.speed
                    v.use_time = use_time
                    etypipe.add(v)
                    gEtys[ v.eid ] = v
                    c_troop_set_state( v.eid, v.tmCur, v.curx or v.sx, v.cury or v.sy, v.speed )

                    if troop:is_go() then
                        troop:add_link()
                        if owner and (is_npc_city(owner) or is_lost_temple(owner) or is_king_city(owner) or is_monster_city(owner) or is_monster(owner) ) then
                            monster_city.add_leave_troop(owner, troop._id)
                        end

                        if target and (is_npc_city(target) or is_lost_temple(target) or is_king_city(target) or is_monster_city(target) or is_monster(target)) then
                            monster_city.add_atk_troop(target, troop._id)
                        end
                    end
                else
                    valid = false
                end

            elseif troop:is_settle() then
                if is_union_building( target ) and bacion == TroopAction.Gather then
                    if not target.my_troop_id then target.my_troop_id = {} end
                    if type( target.my_troop_id ) == "number" then
                        local ids = {}
                        table.insert( ids, target.my_troop_id )
                        target.my_troop_id = ids
                    end
                    setIns( target.my_troop_id, tid )
                else
                    target.my_troop_id = tid
                end
                --union_build_t.save(target,true)

            elseif troop:is_ready() then
                if troop.action == TroopAction.DefultFollow then
                    if owner.my_troop_id ~= tid then
                        local otroop = get_troop( owner.my_troop_id )
                        if otroop then
                            dels[ owner.my_troop_id ] = otroop
                            owner.my_troop_id = tid
                        end
                    end

                    local chg = false
                    for pid, arm in pairs( troop.arms or {} ) do
                        if arm.mkdmg then
                            local info = {}
                            info.live_soldier = arm.live_soldier
                            info.pid = pid
                            troop.arms[ pid ] = info
                            chg = true
                        end
                    end
                    if chg then troop:save() end

                elseif troop.is_mass == 1 then
                    troop:add_link()

                end
            end
        end

        if not valid then
            dels[ tid ] = troop
        else
            if not troop.culture then troop.culture = 1 end
            if not troop.flag then troop.flag = 0 end
            if not troop.soldier_num then troop.soldier_num = {1,0,0,0} end

            if action == TroopAction.DefultFollow then
                for pid, _ in pairs( troop.arms or {} ) do
                    if type(pid) == "number" and pid >= 10000 and pid ~= owner.pid then
                        local ply = getPlayer( pid )
                        if ply then ply:add_busy_troop( tid ) end
                    end
                end
            else
                for pid, _ in pairs( troop.arms or {} ) do
                    if type(pid)=="number" and pid >= 10000 then
                        local ply = getPlayer( pid )
                        if ply then ply:add_busy_troop( tid ) end
                    end
                end
            end
        end
    end

    for tid, troop in pairs( dels ) do
        delete_troop( troop )
        for pid, arm in pairs(troop.arms or {}) do
            if type(pid)=="number" and pid >= 10000 then
                local p = getPlayer(pid)
                if p then
                    p:add_soldiers( arm.live_soldier or {} )
                    for _, hid in pairs( arm.heros or {} ) do
                        if hid ~= 0 then
                            local h = heromng.get_hero_by_uniq_id(hid)
                            if h then
                                if h.status == HERO_STATUS_TYPE.MOVING then p:hero_set_free( h ) end
                                h.troop = 0
                            end
                        end
                    end
                end
            end
        end
    end
end


function create_troop(action, owner, target, arm)
   if not owner then return end

    local d = {}
    d._id = generate_id()
    d.eid = 0
    d.action = action

    d.owner_eid = owner.eid
    d.owner_pid = owner.pid or 0
    d.owner_uid = owner.uid or 0
    d.sx, d.sy = get_ety_pos(owner)
    d.curx, d.cury = d.sx, d.sy
    d.propid = 11001001
    d.be_atk_list = {}
    d.is_mass = 0

    d.owner_propid = owner.propid
    if is_ply( owner ) then
        d.name = owner.name
    else
        d.name = ""
    end

    if not target then
        d.target_eid = 0
        d.target_pid = 0
        d.target_uid = 0
        d.dx, d.dy = d.sx, d.sy
    else
        d.target_eid = target.eid
        d.target_pid = target.pid or 0
        d.target_uid = target.uid or 0
        d.dx, d.dy = get_ety_pos(target)
    end

    if arm then
        local pid = owner.pid or 0
        arm.pid = pid
        arm.live_soldier = arm.live_soldier or {}
        d.arms = {}
        d.arms[ pid ] = arm
    else
        local pid = owner.pid or 0
        d.arms = {}
        d.arms[ pid ] = {pid=pid, live_soldier={}}
    end

    if arm and arm.pid >= 10000 and arm.heros then
        for i = 1, 4, 1 do
            local id = arm.heros[ i ]
            if id ~= 0 then
                local h = heromng.get_hero_by_uniq_id(id)
                if h ~= nil then
                    h.troop = d._id
                end
            end
        end
    end

    d.culture = owner.culture or 1
    d.flag = 0
    d.fid = 0
    d.extra = {}

    troop_id_map[ d._id ] = d

    if is_ply( owner ) then
        if action == TroopAction.DefultFollow and owner == target then
        else
            owner:add_busy_troop(d._id)
        end
    end
    setmetatable(d, troop_t.__troop_mt)
    d:save()

    return d
end


function delete_troop( info )
    local troop
    local troop_id
    if type( info ) == "table" then
        troop = info
        troop_id = troop._id
    else
        troop = troop_id_map[ info ]
        troop_id = info
    end

    if troop == nil then return end
    if troop.eid and gEtys[ troop.eid ] == troop then
        rem_ety(troop.eid)
    end

	troop_id_map[troop_id] = nil
    gPendingDelete.troop[ troop_id ] = 0
    troop.delete = true
    troop:notify_owner()

    for pid, _ in pairs(troop.arms) do
        if type(pid)=="number" and pid >= 10000 then
            local ply = getPlayer(pid)
            if ply then
                ply:rem_busy_troop(troop_id)
            end
        end
    end

    monitoring(MONITOR_TYPE.TROOP)
end


function get_troop(troop_id)
    if not troop_id or troop_id == 0 then return nil end
	return troop_id_map[troop_id]
end

function generate_id()
    while true do
        local sn = getSn("troop")
        if sn >= 2147483648 then
            _G.gSns[ "troop" ] = 1
        else
            if not troop_id_map[ sn ]  then return sn end
        end
    end
end

function trigger_event(troop, action)
    action = action or troop:get_base_action()

    if troop:is_back() then
        troop:home()
    else
        union_hall_t.battle_room_remove(troop)
        if gTroopActionTrigger[action] == nil then return troop:back() end
        troop:settle()

        --如果到达后目标位置不一样，就返回
        if action ~= TroopAction.Camp and action ~= TroopAction.SiegeTaskNpc 
            and action ~= TroopAction.TaskSpyPly
            and action ~= TroopAction.TaskAtkPly
            and action ~= TroopAction.VisitHero
            then
            local target = get_ety( troop.target_eid )
            if not target then
                if action == TroopAction.SiegeMonster then back_sinew(troop) end
                return troop:back()
            end

            local x, y = get_ety_pos( target )
            if x ~= troop.dx or y ~= troop.dy then return troop:back() end
        end

        gTroopActionTrigger[action](troop)

        if not troop.delete then
            troop:save()
            troop:notify_owner()
        end
    end
end


------------------------------------------------------------------------------------------------
--action的触发回调------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
--单独攻击玩家城堡
gTroopActionTrigger[TroopAction.SiegePlayer] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    local x, y = get_ety_pos( dest )
    if x ~= troop.dx or y ~= troop.dy then return troop:back() end

    local owner = getPlayer(troop.owner_pid)
    if not owner then return troop:back() end
    if owner.uid > 0 and owner.uid == dest.uid then return troop:back() end

    if dest:is_shell() then
        owner:send_system_notice( resmng.MAIL_10019 )
        troop:back()
        return
    end

    local defense_troop = dest:get_defense_troop()
    local win, total_round = fight.pvp(TroopAction.SiegePlayer, troop, defense_troop)

    --- cross rank
    cross_score.process_troop(RANK_ACTION.NORMAL, troop)
    cross_score.process_troop(RANK_ACTION.NORMAL, defense_troop)



    local d2h = owner:get_num( "SiegeWounded_R" )
    if d2h > 0 then
        troop:handle_dead( TroopAction.SiegePlayer, 0, 0, d2h * 0.0001 )
        owner:rem_buf( resmng.BUFF_SiegeWounded or -1 )
    end

    if win then troop.flag = 1 end
    local troops = troop:back() -- troopback first, for some unexpect mistake

    local rages = nil
    local capture = 0
    if win then
        if is_ply( owner ) then
            union_task.ok( owner, dest, UNION_TASK.HERO)
            union_task.ok( owner, dest, UNION_TASK.PLY) --攻击胜利后领取军团悬赏任务
        end
        dest:city_break( owner )
        rages = fight.rage(troop, dest)

        dumpTab( rages, "rages" )

        for _, one in pairs( troops ) do
            one.win = 1
            local pid = one.owner_pid
            local tmp_player = getPlayer( pid )
            if tmp_player then
                local rage = rages[ one.owner_pid ]
                if rage then
                    dumpTab( rage, "rage" )
                    one.goods = rage
                    one.goods_reason = VALUE_CHANGE_REASON.RAGE
                    one:save()
                    if tmp_player then
                        local total = 0
                        for k, v in pairs(rage) do
                            if v[1] == "res" then
                                total = total + v[3] * RES_RATE[ v[2] ]
                                --成就
                                local ach_index = "ACH_TASK_ATK_RES"..v[2]
                                tmp_player:add_count(resmng[ach_index], v[3])
                            end
                        end
                        task_logic_t.process_task(tmp_player, TASK_ACTION.LOOT_RES, 1, total)
                        tmp_player:add_count( resmng.ACH_COUNT_RESOURCE_ROB, total )
                    end
                end
                --成就
                tmp_player:add_count( resmng.ACH_COUNT_PVPWIN, 1 )
                tmp_player:add_count( resmng.ACH_TASK_ATK_PLAYER_WIN, 1 )
                --任务
                task_logic_t.process_task( tmp_player, TASK_ACTION.ATTACK_PLAYER_CITY, 1, 1 )
            end
        end

        local heroA, heroD = fight.hero_capture(troop, defense_troop)
        if heroA and heroD then
            if heroD.status == HERO_STATUS_TYPE.BUILDING then dest:hero_offduty(heroD) end
            INFO("Capture Hero, %s -> %s", heroA._id, heroD._id)
            heromng.capture(heroA._id, heroD._id)
            capture = heroD.propid
        end
    else
        for k, v in pairs(troops) do
            v.win = 0
            local tmp_player = getPlayer(k)
            if tmp_player ~= nil then
                --成就
                owner:add_count(resmng.ACH_TASK_ATK_PLAYER_FAIL, 1)
                task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_PLAYER_CITY, 1, 0)
            end
        end
    end
    troop:save()

    mark_support_arm( defense_troop, troop )

    defense_troop:handle_dead( TroopAction.SiegePlayer, 0, 0, 1 )
    defense_troop:save()

    Rpc:upd_arm(dest, defense_troop.arms[ dest.pid ].live_soldier or {})

    --发邮件
    player_t.generate_fight_mail(troop, defense_troop, win, capture, rages, total_round)
    if win then 
        local sum = 0
        for k, num in pairs( rages[owner.pid] or {}) do
            sum = sum + calc_res(k,num)
        end
        union_mission.ok( owner, UNION_MISSION_CLASS.ACK_PLY,sum) 
    end  


    union_relation.add(troop)
    add_union_log(troop,win)
end

function add_union_log(troop,win)
    local A = getPlayer(troop.owner_pid) or {}
    local D = get_ety(troop.target_eid) or {}


    local Au = unionmng.get_union(A.uid) or {}
    local Au_name
    if Au then
        Au_name = Au.alias
    end

    local Du = unionmng.get_union(D.uid) or {}
    local Du_name
    if Du then
        Du_name = Du.alias
    end

    local log = {
        action = troop.is_mass or 0,
        win = win,
        A = {
            pid = A.pid,
            name = A.name,
            uid = A.uid,
            alias= Au_name,
            x = A.x,
            y = A.y,
        },
        D = {
            pid = D.pid,
            name = D.name,
            uid = D.uid,
            alias= Du_name,
            x = D.x,
            y = D.y,
        }
    }
    if next(Au) then Au:add_log(resmng.UNION_EVENT.FIGHT,resmng.UNION_MODE.ADD, log) end
    if next(Du) then Du:add_log(resmng.UNION_EVENT.FIGHT,resmng.UNION_MODE.ADD, log) end
end

--单独攻击军团建造
gTroopActionTrigger[TroopAction.SiegeUnion] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    local owner = getPlayer(troop.owner_pid)
    local defense_troop = get_home_troop(dest)

    local win = fight.pvp(TroopAction.SiegeUnion, troop, defense_troop)
    if win then troop.flag = 1 end
    local troops = troop:back() -- troopback first, for some unexpect mistake

    if win then
        for _, one in pairs( troops ) do
            one.win = 1
            local pid = one.owner_pid
            local tmp_player = getPlayer( pid )
            if tmp_player then
                one:save()
                local total = 0
                task_logic_t.process_task(tmp_player, TASK_ACTION.LOOT_RES, 1, total)
                tmp_player:add_count( resmng.ACH_COUNT_PVPWIN, 1 )
                --task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_PLAYER_CITY, 1, 1)
            end
        end

    else
        for k, v in pairs(troops) do
            v.win = 0
            local tmp_player = getPlayer(k)
            if tmp_player ~= nil then
                --task_logic_t.process_task(tm_player, TASK_ACTION.ATTACK_PLAYER_CITY, 1, 0)
            end
        end
    end

    if defense_troop ~= nil then
        defense_troop:handle_dead( TroopAction.SiegeUnion, 0, 0, 1 )
        union_relation.add(troop)
    end

    --发邮件
    player_t.generate_fight_mail(troop, defense_troop, win)
    if win then
        union_build_t.fire(dest)
    end
end

function back_sinew(troop)
    if troop.is_mass  == 1 then
        for pid, _ in pairs(troop.arms or {}) do
            local ply = getPlayer(pid)
            if ply then
                ply:inc_sinew( 10 )
            end
        end
    else
        local owner = getPlayer(troop.owner_pid)
        if owner then
            owner:inc_sinew( 5 )
        end
    end
end

    --打怪
gTroopActionTrigger[TroopAction.SiegeMonster] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        if ack_troop.owner_pid >= 10000 then
            local p = getPlayer( ack_troop.owner_pid )
            if p then
                Rpc:tips( p, 1, resmng.TIPS_TARGET_DISAPPEARED, {} )
            end
        end
        back_sinew(ack_troop)
        ack_troop:back()
        return
    end

    if not is_monster( dest ) then
        back_sinew(ack_troop)
        ack_troop:back()
        return
    end

    if dest.grade ==  BOSS_TYPE.SUPER then
        local king = king_city.get_cur_king() or {}
        if king[3] then
            if king[3] ~= ack_troop.owner_uid then
                back_sinew(ack_troop)
                ack_troop:back()
                return
            end
        end
    end

	local defense_troop = dest:get_my_troop()

	local win = fight.pvp(TroopAction.SiegeMonster, ack_troop, defense_troop)

    monster.calc_hp( dest, defense_troop )
    local finfo = fight.gFightReports[ ack_troop.eid ]
    if finfo then
        local report = finfo[2]
        if report then
            local node = report[ #report ]
            node.hp = dest.hp
        end
    end

    local dmg_prop = resmng.prop_damage_rate[resmng.BOSS]
    local dmg_rate = 0.995
    if dmg_prop then
        dmg_rate = 1 - dmg_prop.Damage_rate
    end
    ack_troop:handle_dead( TroopAction.SiegeMonster, dmg_rate, 0, 1 )
    if win then ack_troop.flag = 1 end
    local ts = ack_troop:back()

    local report = {}
    report.win = win
    report.monster = dest.propid
    report.x = dest.x
    report.y = dest.y
    report.hp = dest.hp
    local hp_lost = dest.hp_before - dest.hp
    report.hp_lost = hp_lost

    --世界事件
    if dest.hp <= 0 then
        world_event.process_world_event(WORLD_EVENT_ACTION.ATTACK_MONSTER, dest.propid)
    end

    local result = ack_troop:statics()

    monster.send_union_item(dest, ack_troop.owner_pid)
    for pid, arm in pairs( ack_troop.arms or {} ) do
        local A = getPlayer( pid )
        if A then
            A:add_count( resmng.ACH_COUNT_ATTACK_MONSTER, 1 )
            local info = result[ pid ]
            if info then
                report.live = info.live
                report.hurt = info.hurt
                report.lost = info.lost
            else
                report.live = 0
                report.hurt = 0
                report.lost = 0
            end

            monster.try_update_top_hurter_by_propid(dest.propid, pid, arm.mkdmg, A.name)
            local its = monster.get_jungle_reward( dest, pid, arm.mkdmg, ack_troop.mkdmg , hp_lost / 100, ack_troop.is_mass )
            local awards = {{},{}}

            local rate = 1 + A:get_num( "HeroPveExp_R" ) * 0.0001

            for k, v in pairs( its or {}) do
                local tmp = awards[ 1 ]
                if k == "final" then tmp = awards[ 2 ] end
                for key, item in pairs( v or {}) do
                    if item[1] == "hero_exp" then
                        for _, hid in pairs( arm.heros or {} ) do
                            if hid ~= 0 then
                                table.insert( tmp, { "hero_exp", hid, math.floor(item[3] * rate) } )
                            end
                        end
                    else
                        table.insert( tmp, item )
                    end
                end
            end
            local pool = {}
            for k, v in pairs(awards[1] or {}) do
                if v[2] then
                    local award = pool[v[2]]
                    if not award then
                        award = v
                    else
                        award[3] = award[3] + v[3]
                    end
                    pool[v[2]] = award
                end
            end
            awards[1] = pool
            report.its = awards
            report.replay_id = ack_troop.replay_id

            A:report_new( MAIL_REPORT_MODE.JUNGLE, report )
            dumpTab(awards, "awards")

            A:add_bonus( "mutex_award", awards[1], VALUE_CHANGE_REASON.JUNGLE)
            A:add_bonus( "mutex_award", awards[2], VALUE_CHANGE_REASON.JUNGLE)
        end
    end
    delete_troop(defense_troop._id)
    dest.my_troop_id = nil
    if dest.hp <= 0 then
        if dest.grade ~= BOSS_TYPE.NORMAL and  dest.grade ~= BOSS_TYPE.SUPER and  dest.grade ~= BOSS_TYPE.SPECIAL then
            timer.new("monster", BossRbTime[dest.grade], dest.zx, dest.zy, dest.grade, dest.npc_id)
        end

        if dest.grade == BOSS_TYPE.NORMAL then
            monster.respawn(dest.zx, dest.zy, dest.grade)
        end

        local prop = resmng.prop_world_unit[dest.propid]
        local point = 1
        if prop then
            point = prop.Boss_point or 1
        end

        for pid, _v in pairs(ack_troop.arms or {}) do

            if get_table_valid_count(ack_troop.arms) > 1 then
                break
            end

            monster.update_top_killer(pid, point)
        end

        monster.increase_kill_score(dest)

        rem_ety(dest.eid)
    else
        dest:mark()
        etypipe.add(dest)
    end

    --任务
    local mid = dest.propid
    if win then win = 1 end
    local prop_monster = resmng.prop_world_unit[mid]

    for k, v in pairs(ts or {}) do
        v.win = win
        local tmp_player = getPlayer(k)
        if tmp_player ~= nil then
            task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_LEVEL_MONSTER, mid, 1)

            --周限时活动
            if prop_monster ~= nil then
                weekly_activity.process_weekly_activity(tmp_player, WEEKLY_ACTIVITY_ACTION.ATK_MONSTER, prop_monster.Clv, 1)
            end
        end
    end

    


    if ack_troop.is_mass == 0 then
        local p = getPlayer( ack_troop.owner_pid )
        if p then union_mission.ok(p,UNION_MISSION_CLASS.AI,1) end
    else
        for pid, _ in pairs(ack_troop.arms or {}) do
            local p = getPlayer( pid )
            if p then
                if pid == ack_troop.owner_pid then
                    union_mission.ok(p,UNION_MISSION_CLASS.AI, 2 * dest.Lv) 
                end
                union_mission.ok(p,UNION_MISSION_CLASS.AI,2) 
            end
        end
    end

end

--攻击任务npc怪物
gTroopActionTrigger[TroopAction.SiegeTaskNpc] = function(ack_troop)
    local dx = ack_troop.dx
    local dy = ack_troop.dy
    --开战
    --
    local tmp_player = getPlayer(ack_troop.owner_pid)
    if tmp_player == nil then return end

    local task_id = ack_troop:get_extra("npc_task_id")
    local task_data = tmp_player:get_task_by_id(task_id)
    if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then return end

    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then return end

    local key, monster_id = unpack(prop_task.FinishCondition)
    local defense_troop = nil
    local conf = resmng.get_conf("prop_world_unit", monster_id)
    if conf == nil then return end

    local arm = {}
    arm.live_soldier = {}
    for k, v in pairs(conf.Arms) do
        if v[1] ~= nil then
            arm.live_soldier[ v[1] ] = v[2]
        end
    end
    defense_troop = {owner_eid=0, owner_pid=0,arms={[0]=arm}, sx=dx, sy=dy, owner_propid=monster_id}
    local win = fight.pvp(TroopAction.SiegeTaskNpc, ack_troop, defense_troop)

    local live_total = 0
    local all_total = 0
    for k, v in pairs(defense_troop.arms) do
        for i, j in pairs(v.live_soldier) do
            local prop_tab = resmng.prop_arm[i]
            if prop_tab ~= nil then
                live_total = live_total + prop_tab.Pow * j
                all_total = all_total + prop_tab.Pow * j
                if v.dead_soldier[i] ~= nil then
                    all_total = all_total + prop_tab.Pow * v.dead_soldier[i]
                end
            end
        end
    end

    local awards = {{},{}}
    local before_hp = task_data.hp or 100
    local hp = math.ceil(before_hp - (all_total - live_total) * 100 / all_total)
    if hp <= 0 then
        local prop_tab = resmng.prop_world_unit[monster_id]
        if prop_tab == nil then
            return
        end
        tmp_player:add_bonus(prop_tab.Fix_award[1], prop_tab.Fix_award[2], VALUE_CHANGE_REASON.REASON_TASK_NPC_AWARD)
        awards[1] = prop_tab.Fix_award[2]
    end

    local report = {}
    report.win = win
    report.monster = monster_id
    report.x = dx - 1
    report.y = dy - 1
    report.hp = hp
    report.hp_lost = before_hp - hp

    local dmg_prop = resmng.prop_damage_rate[resmng.BOSS]
    local dmg_rate = 0.985
    if dmg_prop then
        dmg_rate = 1 - dmg_prop.Damage_rate
    end
    ack_troop:handle_dead( TroopAction.SiegeTaskNpc, dmg_rate, 0, 1 )
    local result = ack_troop:statics()
    local ts = ack_troop:back()


    local A = getPlayer( ack_troop.owner_pid )
    if A then
        A:add_count( resmng.ACH_COUNT_ATTACK_MONSTER, 1 )
        local info = result[ ack_troop.owner_pid ]
        if info then
            report.live = info.live
            report.hurt = info.hurt
            report.lost = info.lost
        else
            report.live = 0
            report.hurt = 0
            report.lost = 0
        end

        report.its = awards
        report.replay_id = ack_troop.replay_id
        A:report_new( MAIL_REPORT_MODE.JUNGLE, report )
    end

    --任务
    task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_SPECIAL_MONSTER, monster_id, hp, ack_troop.target_eid)
end

--参加集结
gTroopActionTrigger[TroopAction.JoinMass] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return end

    local dest_troop = get_troop(troop.dest_troop_id)
    if dest_troop == nil then return troop:back() end

    if not (dest_troop.owner_uid > 0 and dest_troop.owner_uid == ply.uid) then return troop:back() end

    if not dest_troop:is_ready() then return troop:back() end
    --dest_troop:rem_mark_id(troop._id) --删除标记在目标troop上的troopid
    troop:merge(dest_troop)

    union_hall_t.battle_room_update(OPERATOR.UPDATE, dest_troop )
end


gTroopActionTrigger[TroopAction.SupportArm] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local dest = get_ety(troop.target_eid)
    if dest == nil then return troop:back() end

    if not (dest.uid > 0 and dest.uid == ply.uid) then return troop:back() end

    local dest_troop = dest:get_my_troop()
    if not dest_troop then return troop:back() end

    dumpTab( dest_troop, "SupportArm1" )
    troop:merge(dest_troop)
    dumpTab( dest_troop, "SupportArm2" )
    ply:date_add("aid")
end

gTroopActionTrigger[TroopAction.SupportRes] = function(troop)
    troop:back()

    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return end

    local dest = get_ety(troop.target_eid)
    if dest == nil then return end

    if not is_ply( dest ) then return end

    if not (dest.uid > 0 and dest.uid == ply.uid) then return end

    if ply.uid > 0 and ply.uid == dest.uid then
        local tax = troop:get_extra("tax")
        local ratio = (100 - tax) / 100
        local goods = troop.goods
        troop.goods = nil
        for _, v in pairs( goods ) do
            v[3] = math.floor( v[3] * ratio )
        end
        dest:add_bonus("mutex_award", goods, troop.goods_reason)
        dest:send_system_support_res( ply, goods )
    end
end


gTroopActionTrigger[TroopAction.Camp] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    local prop = resmng.get_conf("prop_world_unit", CLASS_UNIT.Camp * 1000000 + ply.culture * 1000 + 1)
    if not prop then return troop:back() end

    local x = troop.dx - 1
    local y = troop.dy - 1
    if c_map_test_pos_for_ply(x, y, prop.Size) ~= 0 then return troop:back() end
    troop.tmStart = 0
    troop.tmOver = 0

    local eid = get_eid_camp()
    local camp = {_id=eid, eid=eid, x=x, y=y, propid=prop.ID, size=prop.Size, pid=ply.pid, uid=ply.uid, extra={tid=troop._id}, my_troop_id=troop._id }
    local info = ply:get_name_info()
    camp.name, camp.uname, camp.uflag = info.name, info.alias, info.flag
    gEtys[ eid ] = camp
    etypipe.add(camp)
    troop.target_eid = eid

    gPendingSave.unit[ eid ] = camp
end

--采集
gTroopActionTrigger[TroopAction.Gather] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    if math.abs(troop.dx - dest.x) > 4 then return troop:back() end
    if math.abs(troop.dy - dest.y) > 4 then return troop:back() end

    local ply = getPlayer(troop.owner_pid)
    if not ply then return troop:back() end

	--sanshimark 判断是否已经被占了
    if dest.pid and dest.pid >= 10000  and not is_union_building(dest) then
        local dply = getPlayer(dest.pid)
        if dply then
            if ply.uid == dply.uid and ply.uid ~= 0 then
                troop:back()
                return
            end

            local dtroop = get_troop(dest.extra.tid)
            if dtroop then
                local atk_win = fight.pvp(TroopAction.Gather, troop, dtroop)
                dtroop:handle_dead( TroopAction.Gather, 0, 0, 1 )
                troop:handle_dead( TroopAction.Gather, 0, 0, 1 )
                if atk_win then
                    dtroop:back()

                    local prop = resmng.get_conf( "prop_world_unit", dest.propid )
                    if prop then dest.val = prop.Count end
                    do_gather(troop, dest)

                    --给失败方发邮件
                    local union = unionmng.get_union(ply.uid)
                    local abbr = nil
                    if union ~= nil then
                        dply:send_system_notice(resmng.MAIL_10027, {}, {prop.Name, dest.x, dest.y, union.alias, ply.name})
                    else
                        dply:send_system_notice(resmng.MAIL_10030, {}, {prop.Name, dest.x, dest.y, ply.name})
                    end

                else
                    troop:back()
                end
                player_t.generate_fight_mail(troop, dtroop, atk_win)
                union_relation.add(troop)
                return
            end
        end
    end

    do_gather(troop, dest)
end

--采集
gTroopActionTrigger[TroopAction.Refugee] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    if math.abs(troop.dx - dest.x) > 4 then return troop:back() end
    if math.abs(troop.dy - dest.y) > 4 then return troop:back() end

    local ply = getPlayer(troop.owner_pid)
    if not ply then return troop:back() end

	--sanshimark 判断是否已经被占了
    if dest.pid and dest.pid >= 10000 then
        local dply = getPlayer(dest.pid)
        if dply then
            if dply.uid ~= ply.uid or (dply.uid == 0 and dply.uid == 0) then
                --local dtroop = get_troop(dest.extra.tid)
                local dtroop = dest:get_my_troop()
                if dtroop then
                    local atk_win = fight.pvp(TroopAction.Refugee, troop, dtroop)
                    dtroop:handle_dead( TroopAction.Refugee, 0, 0, 1 )
                    troop:handle_dead( TroopAction.Refugee, 0, 0, 1 )
                    if atk_win then

                        local prop = resmng.get_conf( "prop_world_unit", dest.propid )
                        if prop then dest.val = prop.Count end
                        refugee.after_fight(troop)

                        dtroop:back()
                     --   do_gather(troop, dest)

                    --    --给失败方发邮件
                    --    local union = unionmng.get_union(ply.uid)
                    --    local abbr = nil
                    --    if union ~= nil then
                    --        dply:send_system_notice(resmng.MAIL_10027, {}, {prop.Name, dest.x, dest.y, union.alias, ply.name})
                    --    else
                    --        dply:send_system_notice(resmng.MAIL_10030, {}, {prop.Name, dest.x, dest.y, ply.name})
                    --    end

                    else
                        troop:back()
                    end
                    player_t.generate_fight_mail(troop, dtroop, atk_win)
                    return
                end
            else
                troop:back()
            end
        end
    else
        refugee.after_fight(troop)
    end
end

gTroopActionTrigger[TroopAction.SiegeCamp] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    if math.abs(troop.dx - dest.x) > 4 then return troop:back() end
    if math.abs(troop.dy - dest.y) > 4 then return troop:back() end

    local ply = getPlayer(troop.owner_pid)
    if not ply then return troop:back() end

    if dest.pid and dest.pid >= 10000 then
        local dply = getPlayer(dest.pid)
        if dply then
            if dply.uid ~= ply.uid or (dply.uid == 0 and dply.uid == 0) then
                local dtroop = get_troop(dest.extra.tid)
                if dtroop then
                    local atk_win = fight.pvp(TroopAction.SiegeCamp, troop, dtroop)
                    if atk_win then
                        dtroop:back()
                        rem_ety( dest.eid )
                    end
                    player_t.generate_fight_mail(troop, dtroop, atk_win)
                    troop:back()
                end
            end
        end
    end
end



function do_gather(troop, dest)
    local mode = resmng.get_conf("prop_world_unit", dest.propid).ResMode
    troop.extra = {mode=mode}
    troop:recalc()
    troop.tmStart = gTime

    if is_union_building(dest) then
        local A = get_ety( troop.owner_eid )
        if not A then return troop:back() end
        if A.uid ~= dest.uid then return troop:back() end
        if dest.state ~= BUILD_STATE.WAIT then return troop:back() end

        if not dest.my_troop_id then
            dest.my_troop_id = {}
        elseif type( dest.my_troop_id ) == "number" then
            dest.my_troop_id = { dest.my_troop_id }
        end
        setIns( dest.my_troop_id, troop._id )

        local dura = (troop:get_extra("count") - troop:get_extra("cache")) / troop:get_extra("speed")
        dura = math.ceil(dura)
        troop.tmOver = gTime + dura
        troop.tmSn = timer.new("troop_action", dura, troop._id)
        union_build_t.recalc_gather( dest )

    else
        dest.my_troop_id = troop._id
        local speed = troop:get_extra("speed")
        local dura = math.min(dest.val, troop:get_extra("count") - troop:get_extra("cache")) / speed
        dura = math.ceil(dura)

        troop.tmOver = gTime + dura
        troop.tmSn = timer.new("troop_action", dura, troop._id)

        local ply = getPlayer(troop.owner_pid)
        dest.pid = ply.pid
        dest.uid = ply.uid
        dest.extra = {speed=speed, start=gTime, count=dest.val-troop:get_extra("cache"), tm=gTime, tid=troop._id}

        local turbo = 0
        for _, bufid in pairs( { resmng.BUFF_SPEED_RES_1, resmng.BUFF_SPEED_RES_2, resmng.BUFF_SPEED_RES_3, resmng.BUFF_SPEED_RES_4 } ) do
            if ply:get_buf( bufid ) then
                turbo = 1
                break
            end
        end
        if turbo == 1 then dest.extra.turbo = 1 end

        farm.mark(dest)
        etypipe.add(dest)
    end
end

function generate_spy_report(ply, spied_ply, def_troop, content)
    local b = ply:get_watchtower()
    local cur_watchtower_lv = 1
    if b ~= nil then
        local prop_tab = resmng.prop_build[b.propid]
        if prop_tab ~= nil then
            cur_watchtower_lv = prop_tab.Lv
        end
    end
    --cur_watchtower_lv = 30
    content.watch = cur_watchtower_lv

    --伪装的buff
    local fake = player_t.get_buf_remain( spied_ply, resmng.BUFF_FAKE )
    if fake > 0 then fake = 2 else fake = 1 end

    --自己的部队
    content.my_troop = {}
    local my_troop = content.my_troop
    my_troop.soldier = {}
    my_troop.soldier_total = 0
    local my_arm = troop_t.get_arm_by_pid(def_troop, def_troop.owner_pid)
    for k, v in pairs(my_arm.live_soldier or {}) do
        table.insert(my_troop.soldier, {k, v*fake})
        my_troop.soldier_total = my_troop.soldier_total + v*fake
    end
    my_troop.hero = {}
    local def_hero = my_arm.heros
    for k, v in pairs(def_hero or {}) do
        local hero = heromng.get_hero_by_uniq_id(v)
        if hero == nil then
            table.insert(my_troop.hero, {0, 0, 0, 0, 0})
        else
            table.insert(my_troop.hero, {hero.propid, hero.star, hero.lv, hero.hp, hero.max_hp})
        end
    end
    if cur_watchtower_lv < 4 then
        my_troop.soldier_total = nil
    end
    if cur_watchtower_lv < 10 then
        my_troop.soldier = nil
    end
    if cur_watchtower_lv < 12 then
        my_troop.hero = nil
    end


    --援军
    content.other_troop = {}
    content.other_soldier_total = 0
    for pid, arm in pairs(def_troop.arms or {}) do
        if pid ~= spied_ply.pid then
            local ply = {}
            if cur_watchtower_lv >= 14 then
                ply.name = getPlayer(pid).name
                ply.lv = getPlayer(pid).lv
            end

            ply.soldier = {}
            for k, v in pairs(arm.live_soldier or {}) do
                table.insert(ply.soldier, {k, v*fake})
                content.other_soldier_total = content.other_soldier_total + v * fake
            end
            if cur_watchtower_lv < 16 then
                ply.soldier = nil
            end

            if cur_watchtower_lv >= 18 then
                ply.hero = {}
                for k, v in pairs(arm.heros or {}) do
                    local hero = heromng.get_hero_by_uniq_id(v)
                    if hero == nil then
                        table.insert(ply.hero, {0, 0, 0, 0, 0})
                    else
                        table.insert(ply.hero, {hero.propid, hero.star, hero.lv, hero.hp, hero.max_hp})
                    end
                end
            end

            table.insert(content.other_troop, ply)
        end
    end
    if cur_watchtower_lv < 14 then
        content.other_troop = nil
    end
    if cur_watchtower_lv < 4 then
        content.other_soldier_total = nil
    end

    --科技
    if cur_watchtower_lv >= 28 then
        content.tech = {}
        for k, v in pairs(spied_ply.tech or {}) do
            table.insert(content.tech, v)
        end
    end

    --天赋
    if cur_watchtower_lv >= 17 then
        content.genius = {}
        table.insert(content.genius, {1,0})
        table.insert(content.genius, {2,0})
        table.insert(content.genius, {3,0})
        for k, v in pairs(spied_ply.genius or {}) do
            local prop_tab = resmng.prop_genius[v]
            local class = prop_tab.Class
            if class == 1 then
                content.genius[1][2] = content.genius[1][2] + prop_tab.Lv
            elseif class == 2 then
                content.genius[2][2] = content.genius[2][2] + prop_tab.Lv
            elseif class == 3 then
                content.genius[3][2] = content.genius[3][2] + prop_tab.Lv
            end
        end
    end

    --装备
    if cur_watchtower_lv >= 30 then
        content.equip = {}
        local ply_equip = player_t.get_equip(spied_ply)
        for k, v in pairs(ply_equip or {}) do
            if v.pos > 0 then
                table.insert(content.equip, v.propid)
            end
        end
    end
end

function spy_castle(player, dest_obj, content)
    local spied_ply = dest_obj
    --成就
    player:add_count(resmng.ACH_TASK_SPY_PLAYER, 1)
    --任务
    task_logic_t.process_task(player, TASK_ACTION.SPY_PLAYER_CITY, 1)

    if spied_ply:is_shell() then
        player:send_system_notice( resmng.MAIL_10020 )
        return false
    end
    if spied_ply:get_buf_remain( resmng.BUFF_ANTI_SPY ) > 0 then
        player:send_system_notice( resmng.MAIL_10021 )
        return false
    end

    generate_spy_report(player, spied_ply, spied_ply:get_defense_troop(), content)
    local cur_watchtower_lv = content.watch
    --玩家信息
    content.photo = spied_ply.photo
    local union = unionmng.get_union(spied_ply.uid)
    if union ~= nil then
        content.union_abbr = union.alias
    end
    content.player_name = spied_ply.name
    content.x = spied_ply.x
    content.y = spied_ply.y

    spied_ply:refresh_food()

    --计算未收取的资源
    if cur_watchtower_lv >= 2 then
        content.res = {}
        local res0 = {0, 0, 0, 0}
        for k, v in pairs(spied_ply:get_build()) do
            local node = resmng.prop_build[v.propid]
            if node ~= nil and node.Class == BUILD_CLASS.RESOURCE then
                local make = spied_ply:get_res_remain( v )
                local mode = node.Mode
                res0[mode] = res0[mode] + make
            end
        end

        local castle_lv = spied_ply:get_castle_lv()
        local res1 = spied_ply:get_res_over_store()
        for i = 1, 4, 1 do
            local prop_res = resmng.get_conf("prop_resource", i)
            if castle_lv >= prop_res.Open then
                table.insert(content.res, {res1[i], res0[i]})
            end
        end
        dumpTab( content.res, "spy_res" )
    end

    --城防值
    if cur_watchtower_lv >= 6 then
        local wall = spied_ply:get_wall()
        local conf = resmng.get_conf("prop_build", wall.propid)
        if conf ~= nil then
            content.def_default = conf.Param.Defence
        end
        content.def_value = wall:get_extra("cur")
    end

    --建筑
    content.build = {0,0,0,0,0}
    local tutter_lv = 0
    local tutter_id = 0
    for k, v in pairs(spied_ply:get_build() or {}) do
        local b = resmng.prop_build[v.propid]
        if b ~= nil then
            if b.Mode == BUILD_FUNCTION_MODE.EMBASSY then
                if cur_watchtower_lv >= 19 then
                    content.build[1] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.HALLOFWAR then
                if cur_watchtower_lv >= 22 then
                    content.build[2] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.WATCHTOWER then
                if cur_watchtower_lv >= 20 then
                    content.build[3] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.TUTTER_LEFT then
                if cur_watchtower_lv >= 24 then
                    content.build[4] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.TUTTER_RIGHT then
                if cur_watchtower_lv >= 24 then
                    content.build[5] = b.ID
                end
            end
        end
    end
    if cur_watchtower_lv < 19 then
        content.build = nil
    end

    return true
end

function spy_res(player, dest_obj, content)
    spied_ply = getPlayer(dest_obj.pid)
    local def_troop = troop_mng.get_troop(dest_obj.extra.tid)
    if def_troop then
        generate_spy_report(player, spied_ply, def_troop, content)
    else
        return
    end

    --玩家信息
    content.photo = spied_ply.photo
    local union = unionmng.get_union(spied_ply.uid)
    if union ~= nil then
        content.union_abbr = union.alias
    end
    content.player_name = spied_ply.name
    content.x = spied_ply.x
    content.y = spied_ply.y
end

function spy_camp(player, dest_obj, content)
    spied_ply = getPlayer(dest_obj.pid)
    local def_troop = troop_mng.get_troop(dest_obj.extra.tid)
    if def_troop then
        generate_spy_report(player, spied_ply, def_troop, content)
    else
        return
    end

    --玩家信息
    content.photo = spied_ply.photo
    local union = unionmng.get_union(spied_ply.uid)
    if union ~= nil then
        content.union_abbr = union.alias
    end
    content.player_name = spied_ply.name
    content.x = spied_ply.x
    content.y = spied_ply.y
end

function spy_npc_city(player, dest_obj, content)
    content.build_id = dest_obj.propid
    content.x = dest_obj.x
    content.y = dest_obj.y
    local prop_build = resmng.get_conf("prop_world_unit", dest_obj.propid)
    if prop_build ~= nil then
        if prop_build.Class == 3 then
            task_logic_t.process_task(player, TASK_ACTION.SPY_NPC_CITY, prop_build.Lv)
        end
        if prop_build.Class == 4 and prop_build.Mode == 1 and prop_build.Lv == 1 then
            task_logic_t.process_task(player, TASK_ACTION.SPY_NPC_CITY, 5)
        end
    end

    local located_troop = troop_mng.get_my_troop(dest_obj)
    if located_troop == nil then
        content.no_troop = true
        return
    end
    local spied_ply = getPlayer(located_troop.owner_pid)
    generate_spy_report(player, spied_ply, located_troop, content)
end

function spy_union_miracle(player, dest_obj, content)
    content.build_id = dest_obj.propid
    content.x = dest_obj.x
    content.y = dest_obj.y
    local prop_miracle = resmng.get_conf("prop_world_unit", dest_obj.propid)
    if prop_miracle == nil then
        return
    end
    if prop_miracle.Class ~= 10 or prop_miracle.Mode < 20 then
        return
    end

    local located_troop = troop_mng.get_my_troop(dest_obj)
    if located_troop == nil then
        content.no_troop = true
        return
    end
    local spied_ply = getPlayer(located_troop.owner_pid)
    generate_spy_report(player, spied_ply, located_troop, content)
end

function spy_losttemp(player, dest_obj, content)
    content.build_id = dest_obj.propid
    content.x = dest_obj.x
    content.y = dest_obj.y

    local prop_build = resmng.get_conf("prop_world_unit", dest_obj.propid)
    if prop_build == nil then
        return
    end

    local located_troop = troop_mng.get_my_troop(dest_obj)
    if located_troop == nil then
        content.no_troop = true
        return
    end
    local spied_ply = getPlayer(located_troop.owner_pid)
    generate_spy_report(player, spied_ply, located_troop, content)
end

function spy_king_city(player, dest_obj, content)
    content.build_id = dest_obj.propid
    content.x = dest_obj.x
    content.y = dest_obj.y

    local prop_build = resmng.get_conf("prop_world_unit", dest_obj.propid)
    if prop_build == nil then
        return
    end

    local located_troop = troop_mng.get_my_troop(dest_obj)
    if located_troop == nil then
        content.no_troop = true
        return
    end
    local spied_ply = getPlayer(located_troop.owner_pid)
    generate_spy_report(player, spied_ply, located_troop, content)
end

--侦查
gTroopActionTrigger[TroopAction.Spy] = function(spy_troop)
    spy_troop:back()

    local player = get_ety(spy_troop.owner_eid)
    if not player then return end

    local dest_obj = get_ety(spy_troop.target_eid)
    if not dest_obj then return end

    local mail_content = {}
    local spied_propid = 0
    local owner_propid = 0
    --玩家城堡
    if is_ply( dest_obj ) == true then
        if spy_castle(player, dest_obj, mail_content) ~= true then
            return
        end
        owner_propid = dest_obj.propid

    elseif is_camp( dest_obj ) == true then
    --帐篷
        spy_camp(player, dest_obj, mail_content)
        owner_propid = dest_obj.propid

    elseif is_res( dest_obj ) == true then
    --资源点
        spy_res(player, dest_obj, mail_content)
        owner_propid = dest_obj.propid

    elseif is_npc_city(dest_obj) == true then
    --NPC城市
        spy_npc_city(player, dest_obj, mail_content)
        spied_propid = dest_obj.propid

    elseif is_union_building(dest_obj) == true then
    --军团奇迹
        spy_union_miracle(player, dest_obj, mail_content)
        spied_propid = dest_obj.propid

    elseif is_lost_temple(dest_obj) == true then
    --遗迹塔
        spy_losttemp(player, dest_obj, mail_content)
        spied_propid = dest_obj.propid

    elseif is_king_city(dest_obj) == true then
    --王城，守卫塔，要塞
        spy_king_city(player, dest_obj, mail_content)
        spied_propid = dest_obj.propid

    else
        return
    end

    --给被侦查的玩家发邮件
    local prop_owner = resmng.get_conf("prop_world_unit", owner_propid)
    if prop_owner then
        local union = unionmng.get_union(player.uid)
        local spied_ply = getPlayer(dest_obj.pid)
        if union ~= nil and string.len(union.alias) >= 3 then
            spied_ply:send_system_notice(resmng.MAIL_10026, {union.alias, player.name}, {prop_owner.Name, dest_obj.x, dest_obj.y, union.alias, player.name})
        else
            spied_ply:send_system_notice(resmng.MAIL_10029, {player.name}, {prop_owner.Name, dest_obj.x, dest_obj.y, player.name})
        end
    end

    --给被侦查的玩家发邮件
    local prop_spied = resmng.get_conf("prop_world_unit", spied_propid)
    if prop_spied then
        local union = unionmng.get_union(player.uid)

        local def_troop = troop_mng.get_troop(dest_obj.my_troop_id)
        if def_troop ~= nil then
            for k, v in pairs(def_troop.arms or {}) do
                local spied_ply = getPlayer(k)
                if union ~= nil and string.len(union.alias) >= 3 then
                    spied_ply:send_system_notice(resmng.MAIL_10026, {union.alias, player.name}, {prop_spied.Name, dest_obj.x, dest_obj.y, union.alias, player.name})
                else
                    spied_ply:send_system_notice(resmng.MAIL_10029, {player.name}, {prop_spied.Name, dest_obj.x, dest_obj.y, player.name})
                end
            end
        end
    end

    mail_content.eid = spy_troop.target_eid
    local mail = {class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.SPY, content = mail_content}
    player:mail_new(mail)
end

--攻打fake ply
gTroopActionTrigger[TroopAction.TaskAtkPly] = function(ack_troop)
    local dx = ack_troop.dx
    local dy = ack_troop.dy
    --开战
    --
    local owner = getPlayer(ack_troop.owner_pid)
    if owner == nil then return ack_troop:back() end

    local task_id = ack_troop:get_extra("atk_ply_task_id")
    local task_data = owner:get_task_by_id(task_id)
    if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then return end

    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then return end

    local key, ply_id = unpack(prop_task.FinishCondition)
    local defense_troop = nil
    local conf = resmng.get_conf("prop_fake_ply", ply_id)
    if conf == nil then return end

    local troop_id = task_data.troop_id
    
    if troop_id then
        defense_troop = troop_mng.get_troop(troop_id)
    else
        troop_id = troop_mng.generate_id()
        defense_troop = {_id = troop_id, owner_eid=0, owner_pid=0,arms={[0]=arm}, sx=dx, sy=dy, owner_propid=ply_id}
        defense_troop.action = TroopAction.TaskAtkPly
        troop_t.load_data(defense_troop)
        local arm = {}
        arm.live_soldier = {}
        for k, v in pairs(conf.Arms) do
            if v[1] ~= nil then
                arm.live_soldier[ v[1] ] = v[2]
            end
        end
        troop_id_map[ defense_troop._id ] = defense_troop
        task_data.troop_id = troop_id
        troop_t.save(defense_troop)
    end

    local win, total_round = fight.pvp(TroopAction.SiegeNpc, ack_troop, defense_troop)

    local d2h = owner:get_num( "SiegeWounded_R" )
    if d2h > 0 then 
        ack_troop:handle_dead( TroopAction.SiegePlayer, 0, 0, d2h * 0.0001 )
        owner:rem_buf( resmng.BUFF_SiegeWounded or -1 ) 
    end

    if win then ack_troop.flag = 1 end 
    local troops = ack_troop:back() -- troopback first, for some unexpect mistake

    local rages = nil 
    local capture = 0
    if win then
        --dest:city_break( owner )
        --rages = fight.rage(troop, dest)

        rages = {[ack_troop.owner_pid] = conf.Rages}

        dumpTab( rages, "rages" )

        for _, one in pairs( troops ) do
            one.win = 1
            local pid = one.owner_pid
            local tmp_player = getPlayer( pid )
            if tmp_player then
                local rage = rages[ one.owner_pid ]
                if rage then
                    dumpTab( rage, "rage" )
                    one.goods = rage
                    one.goods_reason = VALUE_CHANGE_REASON.RAGE
                    one:save()
                    if tmp_player then
                        local total = 0
                        for k, v in pairs(rage) do
                            if v[1] == "res" then
                                total = total + v[3] * RES_RATE[ v[2] ]
                                --成就
                                local ach_index = "ACH_TASK_ATK_RES"..v[2]
                                tmp_player:add_count(resmng[ach_index], v[3])
                            end
                        end
                        task_logic_t.process_task(tmp_player, TASK_ACTION.LOOT_RES, 1, total)
                        tmp_player:add_count( resmng.ACH_COUNT_RESOURCE_ROB, total )
                    end
                end
                --成就
                --tmp_player:add_count( resmng.ACH_COUNT_PVPWIN, 1 )
                --tmp_player:add_count( resmng.ACH_TASK_ATK_PLAYER_WIN, 1 )
                --任务
                task_logic_t.process_task( tmp_player, TASK_ACTION.ATTACK_SPECIAL_PLY, ply_id, 1 )
            end
        end

        --local heroA, heroD = fight.hero_capture(troop, defense_troop)
        --if heroA and heroD then
        --    if heroD.status == HERO_STATUS_TYPE.BUILDING then dest:hero_offduty(heroD) end
        --    INFO("Capture Hero, %s -> %s", heroA._id, heroD._id)
        --    heromng.capture(heroA._id, heroD._id)
        --    capture = heroD.propid
        --end
    else
        for k, v in pairs(troops) do
            v.win = 0
            local tmp_player = getPlayer(k)
            if tmp_player ~= nil then
                --成就
                owner:add_count(resmng.ACH_TASK_ATK_PLAYER_FAIL, 1)
                task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_SPECIAL_PLY, 1, 0)
            end
        end
    end
    ack_troop:save()
---------------------------------------------- send mail
    local ack_mail = {}
    ack_mail.tech = fight.get_troop_buf(ack_troop)
    local ack_ply = getPlayer(ack_troop.owner_pid)
    if ack_ply ~= nil then
        local union = unionmng.get_union(ack_ply.uid)
        if union ~= nil then
            ack_mail.union_abbr = union.alias
        end
        ack_mail.owner_name = ack_ply.name
        ack_mail.owner_pid = ack_ply.pid
        ack_mail.x = ack_ply.x
        ack_mail.y = ack_ply.y
        ack_mail.photo = ack_ply.photo
    end

    ack_mail.arms = {}
    for pid, arm in pairs(ack_troop.arms or {}) do
        local unit = {}
        local tmp_ply = getPlayer(pid)
        if tmp_ply ~= nil then
            unit.name = tmp_ply.name
        end
        unit.power = arm.lost or 0

        --hero:{propid, stars, lv, cur_hp, max_hp, catch}
        unit.hero = {}
        for _, uid in pairs(arm.heros or {}) do
            local hero = {}
            local h = heromng.get_hero_by_uniq_id(uid)
            if h ~= nil then
                hero[1] = h.propid
                hero[2] = h.star
                hero[3] = h.lv
                hero[4] = h.hp
                hero[5] = h.max_hp
            else
                hero[1] = 0
            end
            table.insert(unit.hero, hero)
        end

        unit.kill = arm.kill_soldier or {}
        unit.death = arm.dead_soldier or {}
        unit.live = arm.live_soldier or {}
        --unit.hurt = arm.hurt_soldier

        local amend = arm.amend
        if amend then unit.amend = amend
        else unit.amend = { dead = arm.dead_soldier } end

        ack_mail.arms[pid] = unit
    end


    ack_mail.res = {}
    ack_mail.res_flag = 1
    for pid, res in pairs(rages or {}) do
        local unit = {0, 0, 0, 0}
        for k, v in pairs(res) do
            unit[v[2]] = v[3]
        end
        ack_mail.res[pid] = unit
    end


    --防守方邮件
    local def_mail = {}
    --local def_obj = get_ety(ack_troop.target_eid)
    def_mail.propid = conf.Propid or 1001
    def_mail.x = dx   --战斗发生的地点
    def_mail.y = dy   --战斗发生的地点

    def_mail.tech = conf.Tech or {}
    --def_mail.owner_name = conf.Name or ""
    def_mail.owner_name = "aaaa"
    def_mail.owner_pid = 0
    --def_mail.photo = conf.Photo 
    def_mail.photo = 1
    def_mail.catch_hero = 0
    def_mail.tech = fight.get_troop_buf(ack_troop)

    --def_mail.catch_hero = catch_hero

    def_mail.arms = {}
    for pid, arm in pairs(defense_troop.arms or {}) do
        local unit = {}
        local tmp_ply = getPlayer(pid)
        if tmp_ply ~= nil then
            unit.name = tmp_ply.name
        end
        unit.power = arm.lost or 0

        --hero:{propid, stars, lv, cur_hp, max_hp, catch}
        unit.hero = {}
        for _, uid in pairs(arm.heros or {}) do
            local hero = {}
            local h = heromng.get_hero_by_uniq_id(uid)
            if h ~= nil then
                hero[1] = h.propid
                hero[2] = h.star
                hero[3] = h.lv
                hero[4] = h.hp
                hero[5] = h.max_hp
            else
                hero[1] = 0
            end
            table.insert(unit.hero, hero)
        end

        unit.kill = arm.kill_soldier or {}
        unit.hurt = arm.hurt_soldier or {}
        unit.death = arm.dead_soldier or {}
        unit.live = arm.live_soldier or {}
        --unit.hurt = arm.hurt_soldier
        --
        --
        local amend = arm.amend
        if amend then unit.amend = amend
        else unit.amend = { dead = arm.dead_soldier } end

        def_mail.arms[pid] = unit
    end

    local ack_mode = nil
    local def_mode = nil
    if win then
        ack_mode = MAIL_FIGHT_MODE.ATTACK_SUCCESS
        def_mode = MAIL_FIGHT_MODE.DEFEND_FAIL
    else
        ack_mode = MAIL_FIGHT_MODE.ATTACK_FAIL
        def_mode = MAIL_FIGHT_MODE.DEFEND_SUCCESS
    end

    local content = {ack_mail=ack_mail, def_mail=def_mail, replay_id=ack_troop.replay_id}
    --发送邮件
    if total_round ~= nil and total_round <= 1 and is_win == false then
        for pid, arm in pairs(ack_troop.arms or {}) do
            local tmp_ply = getPlayer(pid)
            if tmp_ply ~= nil then
                tmp_ply:send_system_notice(resmng.MAIL_10028)
            end
        end
    else
        for pid, arm in pairs(ack_troop.arms or {}) do
            local tmp_ply = getPlayer(pid)
            if tmp_ply ~= nil then
                local tmp = copyTab(content)
                tmp.ack_mail.res_flag = 1
                tmp_ply:mail_new({from=0, name="", class=MAIL_CLASS.FIGHT, mode=ack_mode, title="", content=content, its={}})
            end
        end
    end
------------------------------------------send mail
    add_union_log(ack_troop,win) 

    if win then
        troop_mng.delete_troop(defense_troop)
    end
end


function task_spy_report(ply, conf, def_troop, content)
    local b = ply:get_watchtower()
    local cur_watchtower_lv = 1
    if b ~= nil then
        local prop_tab = resmng.prop_build[b.propid]
        if prop_tab ~= nil then
            cur_watchtower_lv = prop_tab.Lv
        end
    end
    --cur_watchtower_lv = 30
    content.watch = cur_watchtower_lv

    local fake = 1

    --自己的部队
    content.my_troop = {}
    local my_troop = content.my_troop
    my_troop.soldier = {}
    my_troop.soldier_total = 0
    local my_arm = troop_t.get_arm_by_pid(def_troop, def_troop.owner_pid)
    for k, v in pairs(my_arm.live_soldier or {}) do
        table.insert(my_troop.soldier, {k, v*fake})
        my_troop.soldier_total = my_troop.soldier_total + v*fake
    end
    my_troop.hero = {}
    local def_hero = my_arm.heros
    for k, v in pairs(def_hero or {}) do
        local hero = heromng.get_hero_by_uniq_id(v)
        if hero == nil then
            table.insert(my_troop.hero, {0, 0, 0, 0, 0})
        else
            table.insert(my_troop.hero, {hero.propid, hero.star, hero.lv, hero.hp, hero.max_hp})
        end
    end
    if cur_watchtower_lv < 4 then
        my_troop.soldier_total = nil
    end
    if cur_watchtower_lv < 10 then
        my_troop.soldier = nil
    end
    if cur_watchtower_lv < 12 then
        my_troop.hero = nil
    end

    --科技
    if cur_watchtower_lv >= 28 then
        content.tech = {}
        for k, v in pairs(conf.Tech or {}) do
            table.insert(content.tech, v)
        end
    end

    --天赋
    if cur_watchtower_lv >= 17 then
        content.genius = {}
        table.insert(content.genius, {1,0})
        table.insert(content.genius, {2,0})
        table.insert(content.genius, {3,0})
        for k, v in pairs(conf.Genius or {}) do
            local prop_tab = resmng.prop_genius[v]
            local class = prop_tab.Class
            if class == 1 then
                content.genius[1][2] = content.genius[1][2] + prop_tab.Lv
            elseif class == 2 then
                content.genius[2][2] = content.genius[2][2] + prop_tab.Lv
            elseif class == 3 then
                content.genius[3][2] = content.genius[3][2] + prop_tab.Lv
            end
        end
    end

    --装备
    if cur_watchtower_lv >= 30 then
        content.equip = {}
        for k, v in pairs(conf.Equip or {}) do
            if v.pos > 0 then
                table.insert(content.equip, v.propid)
            end
        end
    end
end

--侦查fake ply
gTroopActionTrigger[TroopAction.TaskSpyPly] = function(ack_troop)
    local dx = ack_troop.dx
    local dy = ack_troop.dy
    --开战
    --
    local tmp_player = getPlayer(ack_troop.owner_pid)
    if tmp_player == nil then return end

    local task_id = ack_troop:get_extra("spy_ply_task_id")
    local task_data = tmp_player:get_task_by_id(task_id)
    if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then return end


    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then return end

    local key, ply_id = unpack(prop_task.FinishCondition)

    task_logic_t.process_task(tmp_player, TASK_ACTION.SPY_SPECIAL_PLY, ply_id)

    local defense_troop = nil
    local conf = resmng.get_conf("prop_fake_ply", ply_id)
    if conf == nil then return end

    local mail_content = {}
    local arm = {}
    arm.live_soldier = {}
    for k, v in pairs(conf.Arms) do
        if v[1] ~= nil then
            arm.live_soldier[ v[1] ] = v[2]
        end
    end
    defense_troop = {owner_eid=0, owner_pid=0,arms={[0]=arm}, sx=dx, sy=dy, owner_propid=ply_id}

    local content = {}
    task_spy_report(tmp_player, conf, defense_troop, content)
    local cur_watchtower_lv = content.watch
    content.photo = 1
    content.player_name = conf.Name
    content.x = dx
    content.y = dy

    if cur_watchtower_lv >= 2 then
        content.res = {}
        local res0 = conf.Res0
        local res1 = conf.Res1
        for i = 1, 4, 1 do
            local prop_res = resmng.get_conf("prop_resource", i)
            table.insert(content.res, {res1[i], res0[i]})
        end
    end
    content.build = {0,0,0,0,0}
    local tutter_lv = 0
    local tutter_id = 0
    for k, v in pairs(conf.build or  {}) do
        local b = resmng.prop_build[v]
        if b ~= nil then
            if b.Mode == BUILD_FUNCTION_MODE.EMBASSY then
                if cur_watchtower_lv >= 19 then
                    content.build[1] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.HALLOFWAR then
                if cur_watchtower_lv >= 22 then
                    content.build[2] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.WATCHTOWER then
                if cur_watchtower_lv >= 20 then
                    content.build[3] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.TUTTER_LEFT then
                if cur_watchtower_lv >= 24 then
                    content.build[4] = b.ID
                end
            elseif b.Mode == BUILD_FUNCTION_MODE.TUTTER_RIGHT then
                if cur_watchtower_lv >= 24 then
                    content.build[5] = b.ID
                end
            end
        end
    end
    if cur_watchtower_lv < 19 then
        content.build = nil
    end

    content.eid = ack_troop.target_eid
    local mail = {class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.SPY, content = content}
    tmp_player:mail_new(mail)

    --成就
    --tmp_player:add_count(resmng.ACH_TASK_SPY_PLAYER, 1)
    --任务
end

--参加集结
gTroopActionTrigger[TroopAction.JoinMass] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return end

    local dest_troop = get_troop(troop.dest_troop_id)
    if dest_troop == nil then return troop:back() end

    if not (dest_troop.owner_uid > 0 and dest_troop.owner_uid == ply.uid) then return troop:back() end

    if not dest_troop:is_ready() then return troop:back() end
    --dest_troop:rem_mark_id(troop._id) --删除标记在目标troop上的troopid
    troop:merge(dest_troop)
end

gTroopActionTrigger[TroopAction.Declare] = function(troop)
    delete_troop(troop._id)

    --local owner = get_ety(troop.owner_eid)
    --if not owner then return end
    ----owner:rem_busy_troop(troop._id)

    local target = get_ety(troop.target_eid)
    if not target then return end

    npc_city.declare_war(troop.owner_eid, troop.target_eid)
end

--attack lost temple
gTroopActionTrigger[TroopAction.LostTemple] = function(ack_troop)
    local dest = get_ety(ack_troop.target_eid)
    if not dest then return ack_troop:back() end

    if is_npc_city(dest) then
        if dest.state ~= TW_STATE.FIGHT then
            ack_troop:back()
        end
    end

    --if ack_troop.atk_uid ~= dest.uid and is_npc_city(dest) then return ack_troop:back() end

    if dest.uid == ack_troop.owner_uid then
        trigger_event(ack_troop, TroopAction.HoldDefenseLT)
        return
    end

	local defense_troop = dest:get_my_troop()

	--开战
	fight.pvp(TroopAction.LostTemple, ack_troop, defense_troop)
    local win = defense_troop:is_no_live_arm()

    local dmg_prop = resmng.prop_damage_rate[resmng.LT]
    local dmg_rate = 0.945
    if dmg_prop then
        dmg_rate = 1 - dmg_prop.Damage_rate
    end
    ack_troop:handle_dead( TroopAction.LostTemple, 0, dmg_rate, 1 )
    if defense_troop.owner_uid ~= 0 then defense_troop:handle_dead( TroopAction.LostTemple, 0, dmg_rate , 1 ) end

    --邮件
    if defense_troop.owner_uid ~= 0 then
        player_t.generate_fight_mail(ack_troop, defense_troop, win)
    else
        send_report[TroopAction.LostTemple](ack_troop, defense_troop)
    end

    if is_lost_temple(dest) then
        for pid, arm in pairs(ack_troop.arms) do
            local ply = getPlayer(pid)
            if ply then
                if not ply.lt_time then
                    ply.lt_time = 0
                end
                if ply.lt_time < lost_temple.start_time then
                    ply.lt_time = gTime
                    ply.lt_award_st = {}
                end
            end
        end
        lost_temple.after_fight(ack_troop, defense_troop)
    end

	--回城
    lost_temple.deal_troop(ack_troop, defense_troop)
    deal_no_arm_troop(ack_troop, defense_troop) 
    union_hall_t.battle_room_remove( ack_troop )
end

gTroopActionTrigger[TroopAction.VisitNpc] = function(ack_troop)
    local dest = get_ety(ack_troop.target_eid)
    if not dest then return ack_troop:back() end

    local player = get_ety(ack_troop.owner_eid)

    local prop = resmng.prop_world_unit[dest.propid]
    if prop then
        task_logic_t.process_task(player, TASK_ACTION.VISIT_NPC, prop.ID, 1)
    end
    ack_troop:back()
end

gTroopActionTrigger[TroopAction.VisitHero] = function(ack_troop)
    local dest = get_ety(ack_troop.target_eid)
    if not dest then return ack_troop:back() end

    local player = get_ety(ack_troop.owner_eid)
    local task_id = ack_troop:get_extra("visit_task_id")
    local task_data = player:get_task_by_id(task_id)
    if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then 
        ack_troop:back()
        return 
    end

    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then
        ack_troop:back()
        return 
    end

    local key, ply_id = unpack(prop_task.FinishCondition)
    task_logic_t.process_task(player, TASK_ACTION.VISIT_HERO, ply_id, 1)
    ack_troop:back()
end

--单独攻击NPC
gTroopActionTrigger[TroopAction.SiegeNpc] = function(ack_troop)
    local dest = get_ety(ack_troop.target_eid)
    if not dest then return ack_troop:back() end

    if dest.uid == ack_troop.owner_uid then
        trigger_event(ack_troop, TroopAction.HoldDefenseNPC)
        return
    end
    
    if is_npc_city(dest) then
        if dest.state ~= TW_STATE.FIGHT then
            ack_troop:back()
            return
        end
    end

	local defense_troop = dest:get_my_troop()

	--开战
	fight.pvp(TroopAction.SiegeNpc, ack_troop, defense_troop)
    local win = defense_troop:is_no_live_arm()

    if win == true then
        local pack = {}
        pack.npc_id = dest.eid
        pack.prop_id = dest.propid
        pack.win = win
        subscribe_ntf.send_sub_ntf( "map_info", "npc_ft_result_ntf", pack)
    end

    ---cross rank
    cross_score.process_troop(RANK_ACTION.NPC_DMG, troop)
    cross_score.process_troop(RANK_ACTION.NPC_DMG, defense_troop)

    local dmg_prop = resmng.prop_damage_rate[resmng.TW]
    local dmg_rate = 0.985
    if dmg_prop then
        dmg_rate = 1 - dmg_prop.Damage_rate
    end
    ack_troop:handle_dead( TroopAction.SiegeNpc, 0, dmg_rate, 1 )
    if defense_troop.owner_uid ~= 0 then defense_troop:handle_dead( TroopAction.SiegeNpc, 0, dmg_rate, 1 ) end

    --邮件
    if defense_troop.owner_uid ~= 0 then
        player_t.generate_fight_mail(ack_troop, defense_troop, win)
    else
        send_report[TroopAction.SiegeNpc](ack_troop, defense_troop)
    end

    local p = get_ety(ack_troop.owner_eid)
    union_task.ok(p,dest,UNION_TASK.NPC) --攻击后领取军团悬赏任务
    union_mission.ok( p, UNION_MISSION_CLASS.NPC_CITY) 

    if is_npc_city(dest) then
        npc_city.after_fight(ack_troop, defense_troop)
    end

	--回城
    npc_city.deal_troop(ack_troop, defense_troop)
    deal_no_arm_troop(ack_troop, defense_troop) 
    union_hall_t.battle_room_remove( ack_troop )

    --任务
    local player = get_ety(ack_troop.owner_eid)
    local prop_build = resmng.get_conf("prop_world_unit", dest.propid)
    if prop_build ~= nil and prop_build.Class == 3 then
        --成就
        local ach_index = "ACH_TASK_ATK_NPC"..prop_build.Lv
        player:add_count(resmng[ach_index], 1)

        task_logic_t.process_task(player, TASK_ACTION.ATTACK_NPC_CITY, prop_build.Lv, 1)
    end
end

--单独攻击王城战建筑
gTroopActionTrigger[TroopAction.King] = function(troop)
	local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    local owner = get_ety( troop.owner_eid )
    if not owner then return troop:back() end

    if dest.uid == owner.uid then
        gTroopActionTrigger[TroopAction.HoldDefenseKING](troop)
        return
    end
	local defense_troop = dest:get_my_troop()

	--开战
    local atk_union = unionmng.get_union(troop.owner_uid)
    if atk_union then
         king_city.add_kw_buff(atk_union, troop)
    end
    local def_union = unionmng.get_union(defense_troop.owner_uid or 0)
    if def_union then
         king_city.add_kw_buff(def_union, defense_troop)
    end

    local win
    if defense_troop then
        fight.pvp(TroopAction.King, troop, defense_troop)

        ---cross rank
        cross_score.process_troop(RANK_ACTION.NPC_DMG, troop)
        cross_score.process_troop(RANK_ACTION.NPC_DMG, defense_troop)

        win = defense_troop:is_no_live_arm()
        if win then
            local p = get_ety(troop.start_eid)
        end
    end

    if atk_union then
        troop:clear_tr_ef()
    end
    if def_union then
        defense_troop:clear_tr_ef()
    end

    --邮件
    if defense_troop.owner_uid ~= 0 then
        player_t.generate_fight_mail(troop, defense_troop, win)
    else
        send_report[TroopAction.King](troop, defense_troop)
    end

    king_city.after_fight(troop, defense_troop)
    deal_no_arm_troop(troop, defense_troop) 
    union_hall_t.battle_room_remove( troop )

	-- do deal_troop in after_fight
    --king_city.deal_troop(troop, defense_troop)


    --成就
    owner:add_count(resmng.ACH_TASK_ATK_NPC5, 1)
    --任务
    task_logic_t.process_task(owner, TASK_ACTION.ATTACK_NPC_CITY, 5, 1)
end



--驻守
gTroopActionTrigger[TroopAction.HoldDefenseNPC] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local obj = get_ety(troop.target_eid)
    if obj == nil then return troop:back() end

    -- 查看是否可以驻守
    if obj.uid ~= troop.owner_uid then
        if is_npc_city(obj) then
            trigger_event(troop, TroopAction.SiegeNpc)
        end
        return
    end

    --活动驻守需要特殊处理
    if is_npc_city(obj) then
        npc_city.try_hold_troop(obj, troop)
        return
    end
end

gTroopActionTrigger[TroopAction.HoldDefenseKING] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local obj = get_ety(troop.target_eid)
    if obj == nil then return troop:back() end

    -- 查看是否可以驻守
    if obj.uid ~= troop.owner_uid then
        if is_king_city(obj) then
            trigger_event(troop, TroopAction.King)
        end
        return
    end

    --活动驻守需要特殊处理
    if is_king_city(obj) then
        npc_city.try_hold_troop(obj, troop)
        return
    end
end

gTroopActionTrigger[TroopAction.HoldDefenseLT] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local obj = get_ety(troop.target_eid)
    if obj == nil then return troop:back() end

    -- 查看是否可以驻守
    if obj.uid ~= troop.owner_uid then
        if is_lost_temple(obj) then
            for pid, arm in pairs(troop.arms) do
                local ply = getPlayer(pid)
                if ply then
                    if ply.lt_time < lost_temple.start_time then
                        ply.lt_time = gTime
                        ply.lt_award_st = {}
                    end
                end
            end
            trigger_event(troop, TroopAction.LostTemple)
        end
        return
    end

    --活动驻守需要特殊处理
    if is_lost_temple(obj) then
        npc_city.try_hold_troop(obj, troop)
        return
    end
end


------------------------ new version ----------------------------------
------------------------ new version ----------------------------------
------------------------ new version ----------------------------------

--怪物攻击玩家
gTroopActionTrigger[TroopAction.MonsterAtkPly] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        rem_ety( ack_troop.owner_eid )
        troop_mng.delete_troop( ack_troop._id )
        return
    end
    local defense_troop = dest:get_defense_troop()
    if not defense_troop then 
        rem_ety( ack_troop.owner_eid )
        troop_mng.delete_troop( ack_troop._id )
        return 
    end

	--开战
	local win = fight.pvp(TroopAction.MonsterAtkPly, ack_troop, defense_troop)
    if win then 
        local p = get_ety(ack_troop.start_eid) 
        ack_troop.flag = 1
    end
    mark_support_arm( defense_troop, ack_troop )


    local copy_tr = copyTab(defense_troop)
    local dmg_prop = resmng.prop_damage_rate[resmng.MC]
    local dmg_rate = 0.95
    if dmg_prop then
        dmg_rate = 1 - dmg_prop.Damage_rate
    end
    defense_troop:handle_dead( TroopAction.SiegeMonsterCity, 0, dmg_rate, 1 )
    send_report[TroopAction.MonsterAtkPly](ack_troop, defense_troop)

    monster_city.after_atk_ply(ack_troop, defense_troop)
end


--怪物攻击玩家占领npc
gTroopActionTrigger[TroopAction.SiegeMonsterCity] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        ack_troop:back()
        return
    end

    if dest.uid == dest.propid or dest.uid == 0 then
        delete_troop(ack_troop._id)
        return
    end

	local defense_troop = dest:get_my_troop()
	--开战
	local win = fight.pvp(TroopAction.SiegeMonsterCity, ack_troop, defense_troop)
    if win then local p = get_ety(ack_troop.start_eid) end

    local city_pro = resmng.prop_world_unit[dest.propid]
    local u = unionmng.get_union(dest.uid)
    if city_pro and u then
        if win and not check_atk_win(ack_troop, defense_troop) then
            king_city.common_ntf(resmng.MC_SUPPORT, {city_pro.Name}, u)
        end
    end

    local copy_tr = copyTab(defense_troop)
    local dmg_prop = resmng.prop_damage_rate[resmng.MC]
    local dmg_rate = 0.95
    if dmg_prop then
        dmg_rate = 1 - dmg_prop.Damage_rate
    end
    defense_troop:handle_dead( TroopAction.SiegeMonsterCity, 0, dmg_rate, 1 )
    send_report[TroopAction.SiegeMonsterCity](ack_troop, defense_troop)

    monster_city.after_fight(ack_troop, defense_troop)

    --if not check_atk_win(ack_troop, defense_troop) then
        local prop = resmng.prop_mc_stage[ack_troop.mcStage]
        if prop then
            if ack_troop.mcStage == prop.NextStage then
                local union = unionmng.get_union(defense_troop.owner_uid)
                if union then
                    local city = union_t.get_monster_city(dest.eid)
                    if city then
                        --monster_city.send_act_award(city)
                        if is_last_mc_fight(ack_troop, defense_troop) then
                            monster_city.send_union_act_award(union)
                            union.monster_city_stage = 0
                        end
                        monster_city.rem_mc_by_npc(dest.eid)
                    end
                end
            end
        end
    --end

    deal_no_arm_troop(ack_troop, defense_troop) 

end

function is_last_mc_fight(ack_troop, defense_troop)
    local union = unionmng.get_union(defense_troop.owner_uid)
    if union then
        local mc_trs = union.mc_trs or {}
        mc_trs[ack_troop._id] = nil
        union.mc_trs = mc_trs
        if get_table_valid_count(mc_trs or {}) == 0 then
            return true
        end
    end
    return false
end

function check_atk_win(atkTroop, defenseTroop)
    return defenseTroop:is_no_live_arm()
end

function calc_lost_hp(troop)
    local cur = 0
    local max = 0
    for _, arm in pairs(troop.arms) do
        local live = arm.live_soldier or {}
        local dead = arm.dead_soldier or {}

        for id, num in pairs(live) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                cur = cur + conf.Pow * num
                max = max + conf.Pow * (num + (dead[ id ] or 0))
            end
        end
    end

    if max == 0 then
        return 0
    end
    return math.floor((max-cur) * 10000 / max + 0.1) / 100
end

function calc_soldier(troop)
    local num = 0
    for k, arm in pairs(troop.arms or {}) do
        for k, v in pairs(arm.dead_soldier or {}) do
            num = num + v
        end
        for k, v in pairs(arm.live_soldier or {}) do
            num = num + v
        end
        for k, v in pairs(arm.hurt_soldier or {}) do
            num = num + v
        end
    end
    return num
end

send_report[TroopAction.King] = function(atk_troop, defense_troop)
    local win = defense_troop:is_no_live_arm()
    local atkReport = {}
    atkReport.win = win
    local dest = get_ety(atk_troop.target_eid)
    if dest then
        local target = {}
        target.propid = dest.propid
        target.eid = dest.eid
        target.hp_lost = calc_lost_hp(defense_troop)
        target.soldierNum = calc_soldier(defense_troop)
        atkReport.dest = target
    end

    local dead = 0
    for _, arm in pairs(defense_troop.arms or {}) do
        for k, v in pairs(arm.dead_soldier or {}) do
            dead = dead + v
        end
    end

    atkReport.plys = {}
    for pid, arm in pairs( atk_troop.arms or {} ) do
        local A = getPlayer( pid )
        if A then
            local ply = {}
            ply.name = A.name
            ply.left_pow = math.floor(troop_t.calc_pow(atk_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow(atk_troop, pid))

            local kill_num = 0
            for k, v in pairs(arm.kill_soldier or {}) do
                kill_num = kill_num + v
            end

            if dead == 0 then
                ply.kill_per = 0
            else
                ply.kill_per = math.ceil((kill_num / dead) * 100)
                if ply.kill_per > 100 then  ply.kill_per = 100 end
            end

            local hurt_num = 0
            for k, v in pairs(arm.dead_soldier or {}) do
                hurt_num = hurt_num + (v * 0.05)
            end
            ply.hurt_num = math.floor(hurt_num)
            atkReport.plys[pid] = ply
        end
    end
    atkReport.replay_id = atk_troop.replay_id

    for pid, arm in pairs( atk_troop.arms or {} ) do
        local ply = getPlayer( pid )
        if ply then
            ply:report_new( MAIL_REPORT_MODE.KING, atkReport )
        end
    end

end

send_report[TroopAction.LostTemple] = function(atk_troop, defense_troop)
    local atkReport = {}
    atkReport.win = defense_troop:is_no_live_arm()
    local dest = get_ety(atk_troop.target_eid)
    if dest then
        local target = {}
        target.propid = dest.propid
        target.x = dest.x
        target.y = dest.y
        target.eid = dest.eid
        target.hp_lost = calc_lost_hp(defense_troop)
        target.soldierNum = calc_soldier(defense_troop)
        atkReport.dest = target
    end

    local dead = 0
    for _, arm in pairs(defense_troop.arms or {}) do
        for k, v in pairs(arm.dead_soldier or {}) do
            dead = dead + v
        end
    end

    atkReport.plys = {}
    for pid, arm in pairs( atk_troop.arms or {} ) do
        local A = getPlayer( pid )
        if A then
            local ply = {}
            ply.name = A.name
            ply.left_pow = math.floor(troop_t.calc_left_pow(atk_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow(atk_troop, pid))

            local kill_num = 0
            for k, v in pairs(arm.kill_soldier or {}) do
                kill_num = kill_num + v
            end

            if dead == 0 then
                ply.kill_per = 0
            else
                ply.kill_per = math.ceil((kill_num / dead) * 100)
            end

            local hurt_num = 0
            if arm.amend then
                for k, v in pairs(arm.amend.to_hurt or {}) do
                    hurt_num = hurt_num + v
                end
            end
            ply.hurt_num = math.floor(hurt_num)
            atkReport.plys[pid] = ply
        end
    end
    atkReport.replay_id = atk_troop.replay_id

    for pid, arm in pairs( atk_troop.arms or {} ) do
        local ply = getPlayer( pid )
        if ply then
            ply:report_new( MAIL_REPORT_MODE.LOSTTEMPLE, atkReport )
        end
    end

end


send_report[TroopAction.SiegeNpc] = function(atk_troop, defense_troop)
    local atkReport = {}
    atkReport.win = defense_troop:is_no_live_arm()
    local dest = get_ety(atk_troop.target_eid)
    if dest then
        local target = {}
        target.propid = dest.propid
        target.eid = dest.eid
        target.hp_lost = calc_lost_hp(defense_troop)
        target.soldierNum = calc_soldier(defense_troop)
        atkReport.dest = target
    end

    local dead = 0
    for _, arm in pairs(defense_troop.arms or {}) do
        for k, v in pairs(arm.dead_soldier or {}) do
            dead = dead + v
        end
    end

    atkReport.plys = {}
    for pid, arm in pairs( atk_troop.arms or {} ) do
        local A = getPlayer( pid )
        if A then
            local ply = {}
            ply.name = A.name
            ply.left_pow = math.floor(troop_t.calc_left_pow(atk_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow(atk_troop, pid))

            local kill_num = 0
            for k, v in pairs(arm.kill_soldier or {}) do
                kill_num = kill_num + v
            end

            if dead == 0 then
                ply.kill_per = 0
            else
                ply.kill_per = math.ceil((kill_num / dead) * 100)
            end

            local hurt_num = 0
            if arm.amend then
                for k, v in pairs(arm.amend.to_hurt or {}) do
                    hurt_num = hurt_num + v
                end
            end
            ply.hurt_num = math.floor(hurt_num)
            atkReport.plys[pid] = ply
        end
    end
    atkReport.replay_id = atk_troop.replay_id

    for pid, arm in pairs( atk_troop.arms or {} ) do
        local ply = getPlayer( pid )
        if ply then
            ply:report_new( MAIL_REPORT_MODE.GONGCHENG, atkReport )
        end
    end

end

send_report[TroopAction.AtkMC] = function(atk_troop, defense_troop)
    local report = {}
    report.win = atk_troop.win
    local dest = get_ety(atk_troop.target_eid)
    if dest then
        report.monster = dest.propid
        report.x = dest.x
        report.y = dest.y
        report.hp_lost = calc_lost_hp(defense_troop)
        report.hp = 100 - report.hp_lost
    end

    local prop_arm = resmng.prop_arm
    local result = atk_troop:statics()

    for pid, arm in pairs( atk_troop.arms or {} ) do
        local A = getPlayer( pid )
        local info = result[pid] or {}
        if A then
            A:add_count( resmng.ACH_COUNT_ATTACK_MONSTER, 1 )
            local live = 0
            local hurt = 0
            local lost = 0

            report.live = info.live
            report.hurt = info.hurt
            report.lost = info.lost

            report.replay_id = atk_troop.replay_id
            A:report_new( MAIL_REPORT_MODE.JUNGLE, report )
        end
    end
end

send_report[TroopAction.MonsterAtkPly] = function(atk_troop, defense_troop)
    local report = {}
    report.win = atk_troop.win
    local monster = {}
    monster.propid = atk_troop.mcid

    local dead_num = 0
    for k, arm in pairs(atk_troop.arms or {}) do
        for k, v in pairs(arm.dead_soldier or {}) do
            dead_num = dead_num + v
        end
    end
    monster.dead_num = dead_num
    local owner = get_ety(atk_troop.owner_eid)
    if owner then
        monster.x = owner.x
        monster.y = owner.y
    end

    report.monster = monster

    report.stage = atk_troop.mcStage

    local dest = get_ety(atk_troop.target_eid)
    if dest then
        local target = {}
        target.x = dest.x
        target.y = dest.y
        target.name = dest.name
        target.eid = dest.eid
        report.dest = target
    end

    local prop_arm = resmng.prop_arm
    local plys = {}
    local hurt = 0
    local total_point = 0
    for pid, arm in pairs( defense_troop.arms or {} ) do
        local A = getPlayer( pid )
        local ply = {}
        if A then
            --ply.left_pow = math.floor(defense_troop:calc_pow(pid))
            --ply.lost_pow = math.floor(defense_troop:lost_pow(pid))
            ply.left_pow = math.floor(troop_t.calc_pow(defense_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow(defense_troop, pid))
            ply.point = math.floor(arm.mkdmg)
            total_point = total_point + ply.point
            ply.name = A.name
            local hurt_num = 0
            if arm.amend then
                for k, v in pairs(arm.amend.to_hurt) do
                    hurt_num = hurt_num + v
                end
            end
            ply.hurt_num = hurt_num
            hurt = hurt + hurt_num

            local kill_num = 0
            for k, v in pairs(arm.kill_soldier) do
                kill_num = kill_num + v
            end
            ply.kill_num = kill_num
        end
        plys[pid] = ply
    end
    report.hurt_num = hurt

    report.plys = plys
    report.replay_id = atk_troop.replay_id

    for pid , _ in pairs(defense_troop.arms or {}) do
        local A = getPlayer( pid )
        if A then
            A:report_new( MAIL_REPORT_MODE.PANJUN2, report )
        end
    end
    --世界事件
    world_event.process_world_event(WORLD_EVENT_ACTION.PANJUN_KILL, total_point)

end

--怪物攻击玩家占领npc
send_report[TroopAction.SiegeMonsterCity] = function(atk_troop, defense_troop)
    local win = defense_troop:is_no_live_arm()
    local report = {}
    report.win = win
    local monster = {}
    monster.propid = atk_troop.mcid

    local dead_num = 0
    for k, arm in pairs(atk_troop.arms or {}) do
        for k, v in pairs(arm.dead_soldier or {}) do
            dead_num = dead_num + v
        end
    end
    monster.dead_num = dead_num
    monster.x = atk_troop.sx
    monster.y = atk_troop.sy

    report.monster = monster

    report.stage = atk_troop.mcStage

    local dest = get_ety(atk_troop.target_eid)
    if dest then
        local target = {}
        target.x = dest.x
        target.y = dest.y
        target.propid = dest.propid
        target.eid = dest.eid
        report.dest = target
    end

    local prop_arm = resmng.prop_arm
    local plys = {}

    local total_point = 0
    for pid, arm in pairs( defense_troop.arms or {} ) do
        local A = getPlayer( pid )
        local ply = {}
        if A then
            ply.left_pow = math.floor(troop_t.calc_left_pow(defense_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow(defense_troop, pid))
            ply.point = math.floor(arm.mkdmg)
            total_point = total_point + ply.point
            ply.name = A.name
            local kill_num = 0
            for k, v in pairs(arm.kill_soldier or {}) do
                kill_num = kill_num + v
            end
            ply.kill_num = kill_num
        end
        plys[pid] = ply
    end

    report.plys = plys
    report.replay_id = atk_troop.replay_id

    for pid , _ in pairs(defense_troop.arms or {}) do
        local A = getPlayer( pid )
        if A then
            A:report_new( MAIL_REPORT_MODE.PANJUN, report )
        end
    end
    --世界事件
    world_event.process_world_event(WORLD_EVENT_ACTION.PANJUN_KILL, total_point)


end

--玩家攻击怪物防守裂隙
gTroopActionTrigger[TroopAction.AtkMC] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        ack_troop:back()
        return
    end

    if not monster_city.can_atk_def_mc(dest, ack_troop.owner_pid) then
        local ply = get_ety(ack_troop.owner_eid)
        if ply then
            ply:add_debug("alread be atk")
        end
        if not player_t.debug_tag  then
            ack_troop:back()
            return
        end
    end

    -- only one chance to atk defense mc
    for pid, arm in pairs(ack_troop.arms or {}) do
        local be_atked_list = dest.be_atked_list or {}
        if be_atked_list[pid] then
            local tr  = ack_troop:split_pid(pid)
            if tr then tr:back() end
        else
            be_atked_list[pid] = pid
        end

        dest.be_atked_list = be_atked_list
    end


    if not monster_city.can_be_atk(dest) then  -- not use 2016.10.10
        local ply = get_ety(ack_troop.owner_eid)
        if ply then
            ply:add_debug("alread be atk")
        end
        if not player_t.debug_tag  then
            ack_troop:back()
            return
        end
    end

	local defense_troop = monster_city.get_my_troop(dest)


	--开战
	local win = fight.pvp(TroopAction.AtkMC, ack_troop, defense_troop)
    ack_troop:handle_dead( TroopAction.AtkMC, 0.95, 0, 1 )

    monster_city.after_been_atk(ack_troop, defense_troop)
    union_hall_t.battle_room_remove( ack_troop )
    deal_no_arm_troop(ack_troop, defense_troop) 
end

gTroopActionTrigger[TroopAction.SaveRes] = function(troop)
    troop:back()
	local dest = get_ety(troop.target_eid)
	if dest == nil then return end

    local owner = get_ety( troop.owner_eid )
    if not owner then return end

    local goods = troop.goods
    local res = {}
    for _, v in pairs( goods or {} ) do
        if v[1] == "res" then
            local mode = v[2]
            local num = math.floor( v[3] )
            if num > 0 then res[ mode ] = num end
        end
    end
    if not union_build_t.can_troop( TroopAction.SaveRes, owner, dest.eid, res ) then return end
    troop.goods = nil

    owner:restore_add_res( res )

    local empty = false
    local union = unionmng.get_union( dest.uid )
    if union then
        if not union:is_restore_empty() then
            empty = true
        end
    end

    if empty then
        for k, v in pairs( union.build or {} ) do
            if is_union_restore( v.propid ) and v.state == BUILD_STATE.WAIT then
                v.holding = 1
                etypipe.add( v )
                gPendingSave.union_build[ v._id ].holding = 1
                union:notifyall( "build", resmng.OPERATOR.UPDATE, v )
            end
        end
    end
end

--从联盟仓库取资源
gTroopActionTrigger[TroopAction.GetRes] = function(troop)
    troop:back()
	local dest = get_ety(troop.target_eid)
	if dest == nil then return end

    local owner = get_ety( troop.owner_eid )
    if not owner then return end

    local res = troop:get_extra("union_expect_res")
    if not union_build_t.can_troop( TroopAction.GetRes, owner, dest.eid, res ) then return end

    --从仓库扣除
    local store = owner._union and owner._union.restore_sum
    if not store then return end
    if store then
        if not store then return end
        local gain = {}
        for mode, num in pairs( res ) do
            if num > 0 then
                store[ mode ] = store[ mode ] - num
                table.insert( gain, { "res", mode, num } )
            end
        end
        gPendingSave.union_member[ owner.pid ].restore_sum = store
        troop:add_goods( gain, VALUE_CHANGE_REASON.REASON_UNION_GET_RESTORE )

        for mode, num in pairs( store ) do
            if num > 0 then return end
        end

        local union = unionmng.get_union( dest.uid )
        if union then
            if union:is_restore_empty() then
                for k, v in pairs( union.build or {} ) do
                    if is_union_restore( v.propid ) and v.state == BUILD_STATE.WAIT then
                        v.holding = 0
                        etypipe.add( v )
                        gPendingSave.union_build[ v._id ].holding = 0
                        union:notifyall( "build", resmng.OPERATOR.UPDATE, v )
                    end
                end
            end
        end
    end
end


gTroopActionTrigger[TroopAction.HoldDefense] = function(troop)
    local obj = get_ety(troop.target_eid)
    if not obj then return troop:back() end
    if not is_union_building( obj) then return troop:back() end
    if not is_union_miracal( obj.propid ) then return troop:back() end
    if obj.state ~= BUILD_STATE.WAIT then return troop:back() end

    local ply = get_ety( troop.owner_eid )
    if not ply then return troop:back() end
    if obj.uid ~= ply.uid then return troop:back() end

    if union_build_t.try_hold_troop( obj, troop ) then

    else
        troop:back()
    end
end



--建造联盟建筑
gTroopActionTrigger[TroopAction.UnionBuild] = function(troop)
    local obj = get_ety(troop.target_eid)
    if not obj then return troop:back() end
    if not is_union_building( obj) then return troop:back() end
    if not union_build_t.is_building( obj) then return troop:back() end

    local ply = get_ety( troop.owner_eid )
    if not ply then return troop:back() end
    if obj.uid ~= ply.uid then return troop:back() end

    if union_build_t.try_hold_troop( obj, troop ) then
        union_build_t.recalc_build( obj )
    else
        troop:back()
    end
end


--买特产
gTroopActionTrigger[TroopAction.BuySpecialty] = function(troop)

end

function get_troop_fight_statistic(At)
    local totals = {}
    for pid, arm in pairs(At.arms) do
        local node = 0
        if pid >= 10000 then
            local owner = getPlayer(pid)
            node = {pid, owner.name, owner.propid }
        else
            local owner = get_ety(At.owner_eid)
            node = {0, "", owner.propid }
        end

        local soldiers = {}
        local lives = arm.live_soldier or {}
        local deads = arm.dead_soldier or {}
        local hurts = arm.hurt_soldier or {}

        for id, num in pairs(lives) do
            local t = {id, num, deads[id] or 0, hurts[id] or 0}
            table.insert(soldiers, t)
        end
        table.insert(node, soldiers)

        local heros = {}
        for _, hid in pairs(arm.heros) do
            if hid ~= 0 then
                h = heromng.get_hero_by_uniq_id(hid)
                if h then
                    table.insert(heros, {h.propid, h.lv, h.hp})
                end
            end
        end
        table.insert(node, heros)
        table.insert(totals, node)
    end
    return totals
end

function troop_timer(tsn, tid)
    local troop = get_troop(tid)
    if not troop then return end
    if troop.tmSn ~= tsn then return end
    troop.tmSn = 0

    if is_monster(troop.target_eid) then
        if not troop:is_ready() then return end 
        local monster = get_ety(troop.target_eid)
        if not monster then -- monster already gone
            troop_mng.dismiss_mass(troop)
            return
        else
            local prop = resmng.prop_world_unit[monster.propid]
            if prop then  -- only mass success can atk
                if get_table_valid_count(troop.arms or {}) == 1 then
                    troop_mng.dismiss_mass(troop)
                    local owner = get_ety( troop.owner_eid )
                    if owner then
                        Rpc:tips(owner, 1, resmng.MASS_FAIL_NO_JOINER, {})
                    end
                    return
                end
            end
        end
    end

    if troop:is_ready() then
        troop:go()
        --todo, just for mass?
        if troop.is_mass == 1 then
            --任务
            local mass_type = 0
            if is_ply(troop.target_eid) then
                mass_type = 3
            elseif is_npc_city(troop.target_eid) then
                mass_type = 2
            elseif is_monster(troop.target_eid) then
                mass_type = 1
            end
            for pid, _ in pairs(troop.arms) do
                local A = getPlayer(pid)
                if A then
                    task_logic_t.process_task(A, TASK_ACTION.JOIN_MASS, mass_type, 1)
                    if A.uid then
                        local u = unionmng.get_union( A.uid )
                        if u then u.battle_list = nil end
                    end
                end
            end

            local dest = get_ety(troop.target_eid)
            if dest then
                if dest.uid then
                    local u = unionmng.get_union( dest.uid )
                    if u then u.battle_list = nil end
                end

                local dest_troop = get_troop(dest.my_troop_id)
                if dest_troop then
                    union_hall_t.battle_room_update(OPERATOR.UPDATE, troop, dest_troop)
                end
            end

        end

    elseif troop:is_settle() then
        troop:back()
        local action = troop:get_base_action()
        if action == TroopAction.Gather then troop:gather_stop() end
    end
end


function do_kick_mass(troop, pid)
    if troop.is_mass ~= 1 then return end
    if not troop:is_ready() then return end
    if troop.owner_pid == pid then return end

    local dest = get_ety(troop.target_eid)
    union_hall_t.battle_room_update(OPERATOR.UPDATE, troop)

    local T = getPlayer( troop.owner_pid )
    local arm = troop.arms[ pid ]
    if arm then
        troop.arms[ pid ] = nil
        local A = getPlayer(pid)
        if A then
            A:rem_busy_troop(troop._id)
            Rpc:stateTroop( A, { _id=troop._id, delete=true} )

            local one = troop_mng.create_troop(TroopAction.JoinMass, A, T, arm)
            one.curx, one.cury = get_ety_pos( T )
            one:back()

            if troop.action == TroopAction.SiegeMonster then A:inc_sinew( 10 ) end
            return one
        end

    else
        for tid, action in pairs( T.troop_comings or {} ) do
            local one = troop_mng.get_troop( tid )
            if one and one:is_go() and one.dest_troop_id == troop._id then
                if one.owner_pid == pid then
                    local A = getPlayer( pid )
                    if A then
                        A:troop_recall( tid, true )
                        if troop.action == TroopAction.SiegeMonster then A:inc_sinew( 10 ) end
                        return one
                    end
                end
            end
        end
    end

end

function dismiss_mass(troop)
    if not troop:is_ready() then return end
    union_hall_t.battle_room_remove(troop)

    local pidT = troop.owner_pid
    local T = getPlayer(pidT)
    local x, y = get_ety_pos(T)
    local action = troop.action
    local tid = troop._id

    local arms = troop.arms or {}
    troop.arms = { [ pidT ] = arms[ pidT ] }
    for pid, arm in pairs(arms) do
        if pid >= 10000 then
            local A = getPlayer(pid)
            if A and pid ~= pidT then
                A:rem_busy_troop(tid)
                Rpc:stateTroop( A, { _id=tid, delete=true} )

                if action == TroopAction.SiegeMonster then A:inc_sinew( 10 ) end
                local one = create_troop(TroopAction.JoinMass, A, T, arm)
                one.curx, one.cury = get_ety_pos( T )
                one:back()
            end
        end
    end
    troop:home()

    if T then
        if action == TroopAction.SiegeMonster then T:inc_sinew( 10 ) end
        for tid, taction in pairs( T.troop_comings or {} ) do
            if taction == TroopAction.JoinMass then
                local one = troop_mng.get_troop( tid )
                if one and one:is_go() and one.dest_troop_id == troop._id then
                    local pid = one.owner_pid
                    if pid >= 10000 then
                        local A = getPlayer( pid )
                        if A then
                            A:troop_recall( tid, true )
                            if action == TroopAction.SiegeMonster then A:inc_sinew( 10 ) end
                        end
                    end
                end
            end
        end
    end
end


function get_my_troop( obj )
    return get_troop(obj.my_troop_id)
end

function deal_no_arm_troop(atk_troop, def_troop)
    if is_ply(atk_troop.owner_eid) then
        atk_troop:rem_no_arm_troop()
    end

    if is_ply(def_troop.owner_eid) then
        def_troop:rem_no_arm_troop()
    end
end

function count_soldier( arm )
    if not arm then return 0 end
    local count = 0
    for _, v in pairs( arm or {} ) do
        count = count + v
    end
    return count
end

function mark_support_arm( troop, Atroop )
    if troop.action ~= TroopAction.DefultFollow then return end
    if not ( troop.owner_pid >= 10000 ) then return end
    local infos = {}
    for pid, arm in pairs( troop.arms or {} ) do
        if pid >= 10000 and pid ~= troop.owner_pid then
            local ply = getPlayer( pid )
            if ply then
                local nlive = count_soldier( arm.live_soldier )
                local ndead = count_soldier( arm.dead_soldier )
                table.insert(infos, { ply.pid, ply.name, ply.photo, nlive+ndead, ndead } )
            end
        end
    end
    if #infos > 0 then
        local log = { time=gTime, infos=infos }
        local atker = get_ety( Atroop.owner_eid )
        if atker and is_ply( atker ) then
            log.pid = atker.pid
            log.name = atker.name
            log.photo = atker.photo
            log.win = Atroop.flag or 0
            if atker.uid > 0 then
                local union = unionmng.get_union( atker.uid )
                if union then
                    log.alias = union.alias
                end
            end
        else
            log.propid = Atroop.owner_propid
        end

        dbmng:getOne().log_support_arm:update( {_id=troop.owner_pid}, { ["$push"]={ log={["$each"]={log}, ["$slice"]=-50 }} }, true )
    end
end

