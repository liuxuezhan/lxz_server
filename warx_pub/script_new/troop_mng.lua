module("troop_mng", package.seeall)

troop_id_map = troop_id_map or {}
gTroopActionTrigger = {}
send_report = {}


function load_data(t)
    local troop = troop_t.load_data(t)
    local id = troop._id
    if troop_id_map[ id ] then
        WARN( "troop_mng.load_data, already have %d", id )
        return
    end

    troop_id_map[troop._id] = troop
    local obj = get_ety(t.target_eid)
    if t:is_go() and t:get_base_action() == TroopAction.HoldDefense then 
        if obj == nil then return troop:back() end
        if not obj.hold_troop then
            obj.hold_troop = {}
        end
        obj.hold_troop[t._id] = 1  
    end
end

function create_troop(action, owner, target, arm)
    if not owner then return end

    local d = {}
    d._id = generate_id()
    d.eid = 0
    d.action = action
    print( "create_troop", d._id, action, owner.eid )

    d.owner_eid = owner.eid
    d.owner_pid = owner.pid or 0
    d.owner_uid = owner.uid or 0
    d.sx, d.sy = get_ety_pos(owner)
    d.curx, d.cury = d.sx, d.sy
    d.propid = 11001001
    d.be_atk_list = {}

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

    if arm and arm.pid > 0 and arm.heros then
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

    if is_ply( owner ) and owner:is_shell() then
        if d:is_pvp() then
            owner:rem_buf( resmng.BUFF_SHELL )
        end
    end

    return d
end


function delete_troop(troop_id)
    local troop = troop_id_map[ troop_id ]
    if troop == nil then return end

    if troop.eid then gEtys[ troop.eid ] = nil end
	troop_id_map[troop_id] = nil
    gPendingDelete.troop[ troop_id ] = 0
    troop.delete = true

    local owner_pid = troop.owner_pid
    for pid, _ in pairs(troop.arms) do
        if pid >= 10000 then
            local ply = getPlayer(pid)
            if ply then ply:rem_busy_troop(troop_id) end
        end
    end
    monitoring(MONITOR_TYPE.TROOP)
end


function get_troop(troop_id)
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
        if action ~= TroopAction.Camp and action ~= TroopAction.SiegeTaskNpc then
            local target = get_ety( troop.target_eid )
            if not target then return troop:back() end
            local x, y = get_ety_pos( target )
            if x ~= troop.dx or y ~= troop.dy then
                return troop:back()
            end
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
    local d2h = owner:get_num( "SiegeWounded_R" )
    if d2h > 0 then 
        troop:handle_dead( TroopAction.SiegePlayer, 0, 0, d2h * 0.0001 )
        owner:rem_buf( resmng.BUFF_SiegeWounded or -1 )
    end

    if win then troop.flag = 1 end
    local troops = troop:back(8) -- troopback first, for some unexpect mistake

    local rages = nil
    local capture = 0
    if win then
        if is_ply( owner ) then
            union_task.ok( owner, dest, UNION_TASK.HERO)
            union_task.ok( owner, dest, UNION_TASK.PLY) --攻击胜利后领取军团悬赏任务
        end
        dest:city_break( owner )
        rages = fight.rage(troop, dest) 

        for _, one in pairs( troops ) do
            one.win = 1
            local pid = one.owner_pid
            local tmp_player = getPlayer( pid )
            if tmp_player then
                local rage = rages[ one.owner_pid ]
                if rage then
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

    --for pid, arm in pairs(defense_troop.arms) do
    --    local hurt = arm.hurt_soldier
    --    if not hurt then
    --        hurt = {}
    --        arm.hurt_soldier = hurt
    --    end
    --    for id, num in pairs(arm.dead_soldier or {}) do
    --        hurt[ id ] = (hurt[ id ] or 0) + num
    --    end
    --    arm.dead_soldier = {}
    --end
    dest:troop_cure(defense_troop)
    Rpc:upd_arm(dest, defense_troop.arms[ dest.pid ].live_soldier or {}) 

    defense_troop:handle_dead( TroopAction.SiegePlayer, 0, 0, 1 )
    defense_troop:save()
    
    --发邮件
    player_t.generate_fight_mail(troop, defense_troop, win, capture, rages, total_round)

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
    local defense_troop = get_ety_arms(dest)

    local win = fight.pvp(TroopAction.SiegeUnion, troop, defense_troop)
    if win then troop.flag = 1 end
    local troops = troop:back() -- troopback first, for some unexpect mistake

    if win then
        union_build_t.fire(dest)

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

    --if  defense_troop then
    --    for pid, arm in pairs(defense_troop.arms) do
    --        local hurt = arm.hurt_soldier
    --        if not hurt then
    --            hurt = {}
    --            arm.hurt_soldier = hurt
    --        end

    --        for id, num in pairs(arm.dead_soldier or {}) do
    --            hurt[ id ] = (hurt[ id ] or 0) + num
    --        end
    --        arm.dead_soldier = {}

    --    end
    --end

    defense_troop:handle_dead( TroopAction.SiegeUnion, 0, 0, 1 )
    union_relation.add(troop)

    --发邮件
    player_t.generate_fight_mail(troop, defense_troop, win)

end

    --打怪
gTroopActionTrigger[TroopAction.SiegeMonster] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then 
        ack_troop:back() 
        local ply = getPlayer( ack_troop.owner_pid )
        if ply then ply:inc_sinew( 10 ) end
        return
    end

    if dest.grade ==  BOSS_TYPE.SUPER then
        local king = king_city.get_cur_king() or {}
        if king[3] then
            if king[3] ~= ack_troop.owner_uid then
                ack_troop:back()
                return
            end
        end
    end

	local defense_troop = dest:get_my_troop()

	local win = fight.pvp(TroopAction.SiegeMonster, ack_troop, defense_troop)

    monster.calc_hp( dest, defense_troop )

    if win then ack_troop.flag = 1 end
    local ts = ack_troop:back(8)

    local report = {}
    report.win = win
    report.monster = dest.propid
    report.x = dest.x
    report.y = dest.y
    report.hp = dest.hp
    local hp_lost = dest.hp_before - dest.hp
    report.hp_lost = hp_lost

    ack_troop:handle_dead( TroopAction.SiegeMonster, 0.95, 0, 1 )
    local result = ack_troop:statics()

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

            for k, v in pairs( its ) do
                local tmp = awards[ 1 ]
                if k == "final" then tmp = awards[ 2 ] end
                for key, item in pairs( v ) do
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

    for k, v in pairs(ts) do
        v.win = win
        local tmp_player = getPlayer(k)
        if tmp_player ~= nil then
            task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_LEVEL_MONSTER, mid, 1)
        end
    end

end

--攻击任务npc怪物
gTroopActionTrigger[TroopAction.SiegeTaskNpc] = function(ack_troop)
    local dx = ack_troop.dx
    local dy = ack_troop.dy
    --开战
    --
    local ts = ack_troop:back(8)
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


    ack_troop:handle_dead( TroopAction.SiegeTaskNpc, 0.95, 0, 1 )
    local result = ack_troop:statics()

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
    dest_troop:rem_mark_id(troop._id) --删除标记在目标troop上的troopid
    troop:merge(dest_troop)
end


gTroopActionTrigger[TroopAction.SupportArm] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local dest = get_ety(troop.target_eid)
    if dest == nil then return troop:back() end

    if not (dest.uid > 0 and dest.uid == ply.uid) then return troop:back() end

    local dest_troop = dest:get_my_troop()
    if not dest_troop then return troop:back() end

    troop:merge(dest_troop)
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
        dest:add_bonus("mutex_award", troop.goods, troop.goods_reason, ratio) 
        troop.goods = nil 
    end
end


gTroopActionTrigger[TroopAction.Camp] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    local prop = resmng.get_conf("prop_world_unit", CLASS_UNIT.Camp * 1000000 + ply.culture * 1000 + 1)
    if not prop then return troop:back() end

    local x = troop.dx - 1
    local y = troop.dy - 1
    if c_map_test_pos(x, y, prop.Size) ~= 0 then return troop:back() end
    troop.tmStart = 0
    troop.tmOver = 0

    local eid = get_eid_camp()
    local camp = {_id=eid, eid=eid, x=x, y=y, propid=prop.ID, size=prop.Size, pid=ply.pid, uid=ply.uid, extra={tid=troop._id}, my_troop_id=troop._id }
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
    if dest.pid and dest.pid > 0  and not is_union_building(dest) then
        local dply = getPlayer(dest.pid)
        if dply then
            if dply.uid ~= ply.uid or (dply.uid == 0 and dply.uid == 0) then
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

                        --local make = dtroop:get_extra("speed") * (gTime - dtroop:get_extra("start"))
                        --dest.val = dest.val - make
                        --local cache = dtroop:get_extra("cache")
                        --dtroop:set_extra("cache", cache + make)
                        --dtroop:set_extra("start", gTime)
                        --do_gather(dtroop, dest)
                    end
                    player_t.generate_fight_mail(troop, dtroop, atk_win)
                    union_relation.add(troop)
                    return
                end
            else
                troop:back()
            end
        end
    end

    do_gather(troop, dest)
end

gTroopActionTrigger[TroopAction.SiegeCamp] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then return troop:back() end

    if math.abs(troop.dx - dest.x) > 4 then return troop:back() end
    if math.abs(troop.dy - dest.y) > 4 then return troop:back() end

    local ply = getPlayer(troop.owner_pid)
    if not ply then return troop:back() end

    if dest.pid and dest.pid > 0 then
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

        if not dest.my_troop_id then dest.my_troop_id = {} end
        table.insert(dest.my_troop_id, troop._id)
        local dura = (troop:get_extra("count") - troop:get_extra("cache")) / troop:get_extra("speed")
        dura = math.ceil(dura)
        troop.tmOver = gTime + dura
        troop.tmSn = timer.new("troop_action", dura, troop._id)
        save_ety(dest)

    else
        dest.my_troop_id = troop._id
        local speed = troop:get_extra("speed")
        local dura = math.min(dest.val, troop:get_extra("count") - troop:get_extra("cache")) / speed
        dura = math.ceil(dura)

        print( "do_gather", speed, dura, speed * dura )

        troop.tmOver = gTime + dura
        troop.tmSn = timer.new("troop_action", dura, troop._id)

        local ply = getPlayer(troop.owner_pid)
        dest.pid = ply.pid
        dest.uid = ply.uid
        dest.extra = {speed=speed, start=gTime, count=dest.val, tm=gTime, tid=troop._id}
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
    local fake = spied_ply:get_buf_remain( resmng.BUFF_FAKE )
    if fake > 0 then fake = 2 else fake = 1 end

    --自己的部队
    content.my_troop = {}
    local my_troop = content.my_troop
    my_troop.soldier = {}
    my_troop.soldier_total = 0
    local my_arm = def_troop:get_arm_by_pid(def_troop.owner_pid)
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
        for k, v in pairs(spied_ply._equip or {}) do
            table.insert(content.equip, v.propid)
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

    generate_spy_report(player, spied_ply, spied_ply:get_my_troop(), content)
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
                local mode = node.Mode
                local speed = node.Speed
                local count = node.Count
                local b, m, a = spied_ply:get_val_extra("Res"..mode.."Speed")
                local make = math.floor((gTime - v.tmStart) * (speed * m + a) / 3600)
                if make > count then 
                    make = count 
                end
                res0[mode] = res0[mode] + make
            end
        end

        local castle_lv = spied_ply:get_castle_lv()
        for i = 1, 4, 1 do
            local prop_res = resmng.get_conf("prop_resource", i)
            if castle_lv >= prop_res.Open then
                table.insert(content.res, {spied_ply:get_res_num(i), res0[i]})
            end
        end
    end

    --英雄
    content.my_troop.hero = {}
    local def_hero = spied_ply:get_defense_heros()
    for k, v in pairs(def_hero) do
        local hero = heromng.get_hero_by_uniq_id(v)
        if hero == nil then
            table.insert(content.my_troop.hero, {0, 0, 0, 0, 0})
        else
            table.insert(content.my_troop.hero, {hero.propid, hero.star, hero.lv, hero.hp, hero.max_hp})
        end
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
    if prop_miracle.Mode ~= 1 and prop_miracle.Mode ~= 2 then
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

    --玩家城堡
    if is_ply( dest_obj ) == true then
        if spy_castle(player, dest_obj, mail_content) ~= true then
            return
        end
        spied_propid = dest_obj.propid

    elseif is_camp( dest_obj ) == true then
    --帐篷
        spy_camp(player, dest_obj, mail_content)
        spied_propid = dest_obj.propid

    elseif is_res( dest_obj ) == true then
    --资源点
        spy_res(player, dest_obj, mail_content)
        spied_propid = dest_obj.propid

    elseif is_npc_city(dest_obj) == true then
    --NPC城市
        spy_npc_city(player, dest_obj, mail_content)

    elseif is_union_building(dest_obj) == true then
    --军团奇迹
        spy_union_miracle(player, dest_obj, mail_content)
        
    elseif is_lost_temple(dest_obj) == true then
    --遗迹塔
        spy_losttemp(player, dest_obj, mail_content)

    elseif is_king_city(dest_obj) == true then
    --王城，守卫塔，要塞
        spy_king_city(player, dest_obj, mail_content)

    else
        return
    end
    
    --给被侦查的玩家发邮件
    local prop_spied = resmng.get_conf("prop_world_unit", spied_propid)
    if prop_spied then
        local union = unionmng.get_union(player.uid)
        local abbr = nil
        local spied_ply = getPlayer(dest_obj.pid)
        if union ~= nil then
            spied_ply:send_system_notice(resmng.MAIL_10026, {}, {prop_spied.Name, dest_obj.x, dest_obj.y, union.alias, player.name})
        else
            spied_ply:send_system_notice(resmng.MAIL_10029, {}, {prop_spied.Name, dest_obj.x, dest_obj.y, player.name})
        end
    end

    mail_content.eid = spy_troop.target_eid
    local mail = {class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.SPY, content = mail_content}
    player:mail_new(mail)
end


gTroopActionTrigger[TroopAction.Declare] = function(troop)
    delete_troop(troop._id)

    local owner = get_ety(troop.owner_eid)
    if not owner then return end
    owner:rem_busy_troop(troop._id)

    local target = get_ety(troop.target_eid)
    if not target then return end

    npc_city.declare_war(troop.owner_eid, troop.target_eid)
end

--单独攻击NPC
gTroopActionTrigger[TroopAction.SiegeNpc] = function(ack_troop)
    local dest = get_ety(ack_troop.target_eid)
    if not dest then return ack_troop:back() end

    if dest.state ~= TW_STATE.FIGHT then
        ack_troop:back()
    end

    if ack_troop.atk_uid ~= dest.uid and is_npc_city(dest) then return ack_troop:back() end

    if dest.uid == ack_troop.owner_uid then
        trigger_event(ack_troop, TroopAction.HoldDefense)
        return
    end
    
	local defense_troop = dest:get_my_troop()

	--开战
	local win = fight.pvp(TroopAction.SiegeNpc, ack_troop, defense_troop)

    ack_troop:handle_dead( TroopAction.SiegeNpc, 0.95, 0, 1 )
    if defense_troop.owner_uid ~= 0 then defense_troop:handle_dead( TroopAction.SiegeNpc, 0.95, 0, 1 ) end

    --邮件
    if defense_troop.owner_pid ~= 0 then
        player_t.generate_fight_mail(ack_troop, defense_troop, win)
    else
        send_report[TroopAction.SiegeNpc](ack_troop, defense_troop)
    end

    if win then
        local p = get_ety(ack_troop.owner_eid)
        union_task.ok(p,dest,UNION_TASK.NPC) --攻击胜利后领取军团悬赏任务
    end

    if is_npc_city(dest) then
        npc_city.after_fight(ack_troop, defense_troop)
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
    npc_city.deal_troop(ack_troop, defense_troop)
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
        gTroopActionTrigger[TroopAction.HoldDefense](troop)
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
        win = fight.pvp(TroopAction.King, troop, defense_troop)
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
    
    king_city.after_fight(troop, defense_troop)
    union_hall_t.battle_room_remove( troop )

	-- do deal_troop in after_fight
    --king_city.deal_troop(troop, defense_troop)

    --邮件
    if defense_troop.owner_pid ~= 0 then
        player_t.generate_fight_mail(troop, defense_troop, win)
    else
        send_report[TroopAction.King](troop, defense_troop)
    end
    
    --成就
    owner:add_count(resmng.ACH_TASK_ATK_NPC5, 1)
    --任务
    task_logic_t.process_task(owner, TASK_ACTION.ATTACK_NPC_CITY, 5, 1)
end



--驻守
gTroopActionTrigger[TroopAction.HoldDefense] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local obj = get_ety(troop.target_eid)
    if obj == nil then return troop:back() end
    if obj.hold_troop then   
        obj.hold_troop[troop._id] = nil  
    end

    -- 查看是否可以驻守
    if obj.uid ~= troop.owner_uid then
        if is_npc_city(obj) then
            trigger_event(troop, TroopAction.SiegeNpc)
        end
        if is_king_city(obj) then
            trigger_event(troop, TroopAction.King)
        end
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
            trigger_event(troop, TroopAction.SiegeNpc)
        end
        return
    end

    --活动驻守需要特殊处理
    if is_npc_city(obj) then
        npc_city.try_hold_troop(obj, troop)
        return
    end
    if is_king_city(obj) then
        npc_city.try_hold_troop(obj, troop)
        return
    end
    if is_lost_temple(obj) then
        npc_city.try_hold_troop(obj, troop)
        return
    end

    local tr = troop_mng.get_troop(obj.my_troop_id)
    if (not tr) or tr.owner_eid == obj.eid then 
        troop:settle()
        obj.my_troop_id = troop._id
    else 
        troop:merge(tr) 
    end
    save_ety(obj)
end


------------------------ new version ----------------------------------
------------------------ new version ----------------------------------
------------------------ new version ----------------------------------

--怪物攻击玩家
gTroopActionTrigger[TroopAction.MonsterAtkPly] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        exception_troop_back(ack_troop)
    end
    local defense_troop = dest:get_defense_troop()
    if not defense_troop then return end

	--开战
	local win = fight.pvp(TroopAction.MonsterAtkPly, ack_troop, defense_troop)
    if win then local p = get_ety(ack_troop.start_eid) end

    local copy_tr = copyTab(defense_troop)
    troop_t.dead_to_live_and_hurt( copy_tr, 0.95 )
    send_report[TroopAction.MonsterAtkPly](ack_troop, copy_tr)

    monster_city.after_atk_ply(ack_troop, defense_troop)

end


--怪物攻击玩家占领npc
gTroopActionTrigger[TroopAction.SiegeMonsterCity] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        ack_troop:back()
    end

    if dest.uid == dest.propid or dest.uid == 0 then
        delete_troop(ack_troop._id)
        return
    end

	local defense_troop = dest:get_my_troop()
	--开战
	local win = fight.pvp(TroopAction.SiegeMonsterCity, ack_troop, defense_troop)
    if win then local p = get_ety(ack_troop.start_eid) end

    local copy_tr = copyTab(defense_troop)
    troop_t.dead_to_hurt( copy_tr, 0.05 ) -- 不使用 handle_dead
    send_report[TroopAction.SiegeMonsterCity](ack_troop, copy_tr)

    monster_city.after_fight(ack_troop, defense_troop)
    local prop = resmng.prop_mc_stage[ack_troop.mcStage]
    if prop then
        if ack_troop.mcStage == prop.NextStage then
            local union = unionmng.get_union(defense_troop.owner_uid)
            if union then
                local city = union_t.get_monster_city(dest.eid)
                if city then
                    monster_city.send_act_award(city)
                    monster_city.rem_mc_by_npc(dest.eid)
                end
            end
        end
    end

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
    local atkReport = {}
    atkReport.win = atk_troop.win
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
            ply:report_new( MAIL_REPORT_MODE.GONGCHENG, atkReport )
        end
    end

end

send_report[TroopAction.SiegeNpc] = function(atk_troop, defense_troop)
    local atkReport = {}
    atkReport.win = atk_troop.win
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
            end

            local hurt_num = 0
            for k, v in pairs(arm.amend.to_hurt or {}) do
                hurt_num = hurt_num + v
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

    for pid, arm in pairs( atk_troop.arms or {} ) do
        local A = getPlayer( pid )
        if A then
            A:add_count( resmng.ACH_COUNT_ATTACK_MONSTER, 1 )
            local live = 0
            local hurt = 0
            local lost = 0

            arm.hurt_soldier = arm.hurt_soldier or {}
            local hurts = arm.hurt_soldier
            local deads = arm.dead_soldier or {}
            local lives = arm.live_soldier or {}

            for id, num in pairs( lives ) do
                local dead = deads[ id ] or 0
                if dead > 0 then
                    local relive = math.floor( dead * 0.95 )
                    lives[ id ] = (lives[ id ] or 0) + relive
                    hurts[ id ] = (hurts[ id ] or 0) + dead - relive
                    hurt = hurt + dead - relive
                    lost = lost + prop_arm[ id ].Pow * ( dead - relive )
                end
                live = live + lives[ id ]
            end
            report.live = live
            report.hurt = hurt
            report.lost = lost

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

    for pid, arm in pairs( defense_troop.arms or {} ) do
        local A = getPlayer( pid )
        local ply = {}
        if A then
            --ply.left_pow = math.floor(defense_troop:calc_pow(pid))
            --ply.lost_pow = math.floor(defense_troop:lost_pow(pid))
            ply.left_pow = math.floor(troop_t.calc_pow(defense_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow(defense_troop, pid))
            ply.point = math.floor(arm.mkdmg)
            ply.name = A.name
            local hurt_num = 0
            for k, v in pairs(arm.hurt_soldier) do
                hurt_num = hurt_num + v
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
end

--怪物攻击玩家占领npc
send_report[TroopAction.SiegeMonsterCity] = function(atk_troop, defense_troop)
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

    for pid, arm in pairs( defense_troop.arms or {} ) do
        local A = getPlayer( pid )
        local ply = {}
        if A then
            ply.left_pow = math.floor(troop_t.calc_pow(defense_troop, pid))
            ply.lost_pow = math.floor(troop_t.lost_pow_by_hurt(defense_troop, pid))
            ply.point = math.floor(arm.mkdmg)
            ply.name = A.name
            local kill_num = 0
            for k, v in pairs(arm.kill_soldier) do
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


end

--玩家攻击怪物防守裂隙
gTroopActionTrigger[TroopAction.AtkMC] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        ack_troop:back()
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
    for pid, arm in pairs(ack_troop.arms) do
        local be_atked_list = dest.be_atked_list or {}
        if be_atked_list[pid] then
            local tr  = ack_troop:split_pid(pid)
            if tr then
                tr:back()
            end
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
        end
    end

	local defense_troop = monster_city.get_my_troop(dest)


	--开战
	local win = fight.pvp(TroopAction.AtkMC, ack_troop, defense_troop)
    local result = ack_troop:dead_to_live_and_hurt( 0.95 )

    monster_city.after_been_atk(ack_troop, defense_troop)
    union_hall_t.battle_room_remove( ack_troop )
end

gTroopActionTrigger[TroopAction.SaveRes] = function(troop)
	local dest_obj = get_ety(troop.target_eid)
	if dest_obj == nil then
        --sanshimark回去的资源
        exception_troop_back(troop)
		return
	end

    local owner = get_ety( troop.owner_eid )
    if not owner then troop:back() end
    if dest_obj.uid ~= owner.uid then return troop:back() end

    local res = troop:get_extra("union_save_res")
    --放到仓库里面去
    union_build_t.restore_add_res(dest_obj,troop.owner_pid,res) 

    troop:back()
end

--从联盟仓库取资源
gTroopActionTrigger[TroopAction.GetRes] = function(troop)
	local dest_obj = get_ety(troop.target_eid)
	if dest_obj == nil then
        --sanshimark回去的资源
        exception_troop_back(troop)
		return
	end

    local owner = get_ety( troop.owner_eid )
    if not owner then return troop:back() end
    if dest_obj.uid ~= owner.uid then return troop:back() end

    local res = troop:get_extra("union_expect_res")
    --从仓库扣除
    union_build_t.restore_del_res(dest_obj.uid,troop.owner_pid,dest_obj,res) 
    --放到部队上
    local real_res={}
    for k, v in pairs(res) do
        table.insert(real_res, {"res",k,v})
    end
    --troop:mount_bonus(real_res,"union_expect_res")
    troop:add_goods(real_res, VALUE_CHANGE_REASON.REASON_UNION_GET_RESTORE )

    --回家
    troop:back()
end

function work(obj)
    local bcc = resmng.get_conf("prop_world_unit",obj.propid)
    if not bcc then return end 

    local tr = troop_mng.get_troop(obj.my_troop_id)
    if not tr then
        return
    end


    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINI_CASTLE 
        or  bcc.Mode == resmng.CLASS_UNION_BUILD_TUTTER1 or bcc.Mode ==resmng.CLASS_UNION_BUILD_TUTTER2  then  
        if obj.hp < bcc.Hp then
            trigger_event(tr,TroopAction.UnionFixBuild)
            return
        else
            tr.action = TroopAction.HoldDefense + 200
            tr.tmOver = 0 
            save_ety(tr)
            return
        end
    end

--采集需要分拆队列处理
    local l = {}
    for _, v in pairs(tr.arms) do
        local one = tr:split_pid(v.pid)
        table.insert(l,one)
    end

    obj.my_troop_id = nil

    for _, v in pairs(l) do
        if bcc.Mode == resmng.CLASS_UNION_BUILD_FARM or bcc.Mode ==resmng.CLASS_UNION_BUILD_LOGGINGCAMP or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINE or bcc.Mode ==resmng.CLASS_UNION_BUILD_QUARRY  then 
            v.action = TroopAction.Gather
            trigger_event(v,TroopAction.Gather)
        else
            v:back()
        end
    end
end


--建造联盟建筑
gTroopActionTrigger[TroopAction.UnionBuild] = function(troop)
    local obj = get_ety(troop.target_eid)
    if not obj then 
        exception_troop_back(troop)
		return
	end

    local ply = get_ety( troop.owner_eid )
    if not ply then return troop:back() end
    if obj.uid ~= ply.uid then return troop:back() end


    if obj.hold_troop then   
        obj.hold_troop[troop._id] = nil  
    end

--融合
    local tr = troop_mng.get_troop(obj.my_troop_id)
    if (not tr) or tr.owner_eid == obj.eid then 
        troop:settle()
        obj.my_troop_id = troop._id
    else 
        troop:merge(tr) 
    end

    save_ety(obj)

end

--买特产
gTroopActionTrigger[TroopAction.BuySpecialty] = function(troop)
	local dest_obj = get_ety(troop.target_eid)
    for k, v in pairs(troop.arms) do
        local p = getPlayer(v.pid)
        task_logic_t.process_task(p, TASK_ACTION.MARKET_BUY_NUM,1)
    end
end

--上架特产
gTroopActionTrigger[TroopAction.ConfirmSpecialty] = function(troop)
	local dest_obj = get_ety(troop.target_eid)
    for k, v in pairs(troop.arms) do
        union_build_t.market_add(dest_obj,v.pid,item) 
    end
end

--下架特产
gTroopActionTrigger[TroopAction.CancleSpecialty] = function(troop)
	local dest_obj = get_ety(troop.target_eid)
    for k, v in pairs(troop.arms) do
        union_build_t.market_del(dest_obj,v.pid,item) 
    end
end

function get_troop_fight_statistic(At)
    local totals = {}
    for pid, arm in pairs(At.arms) do
        local node = 0
        if pid > 0 then
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
        local monster = get_ety(troop.target_eid)
        if not monster then -- monster already gone
            troop:back()
            return
        else
            local prop = resmng.prop_world_unit[monster.propid]
            if prop then  -- only mass success can atk
                if prop.Declare == 1 and get_table_valid_count(troop.arms or {}) == 1 then
                    troop:back()
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
                end
            end

            local dest = get_ety(troop.target_eid)
            if dest then
                local dest_troop = get_troop(dest.my_troop_id)
                if dest_troop then
                    union_hall_t.battle_room_update(OPERATOR.UPDATE, troop, dest_troop)
                end
            end
        end

    elseif troop:is_settle() then
        troop:back()
        local action = troop:get_base_action()
        if action == TroopAction.Gather then
            local dest = get_ety(troop.target_eid)
            if dest then gather_stop(troop, dest) end
        end
    end
end

function gather_stop(troop, dp)
    local count = math.floor((troop:get_extra("speed") or 0) * (gTime - (troop:get_extra("start") or gTime)))
    count = count + (troop:get_extra("cache") or 0)

    if count > troop:get_extra("count") then count = troop:get_extra("count") end
    if count > dp.val then count = dp.val end


    local mode = troop:get_extra("mode") or 1
    local gains = {}
    table.insert(gains, { "res", mode, math.ceil(count) })

    troop.extra = {}

    local owner = getPlayer(troop.owner_pid)
    if owner then
        local content = {x=dp.x, y=dp.y, carry = {{"res", mode, math.ceil(count)}}, buildid=dp.propid }
        owner:report_new( MAIL_REPORT_MODE.GATHER, content )

        union_mission.ok(owner,UNION_MISSION_CLASS.GATHER ,calc_res(mode,count))
        owner:add_count( resmng.ACH_COUNT_GATHER, count * RES_RATE[ mode ] )
        --成就
        local ach_index = "ACH_TASK_GATHER_RES"..mode
        owner:add_count(resmng[ach_index], count)
        --任务
        task_logic_t.process_task(owner, TASK_ACTION.GATHER, mode, count)

        local gain = math.floor( count * RES_RATE[ mode ] )
        local fbox = gain / 10000 * 0.023
        print( "gather_stop", gain, fbox )
        local nbox = math.floor( fbox )
        if math.random(1, 100) <= ( fbox - nbox) * 100 then nbox = nbox + 1 end
        if nbox > 0 then
            table.insert(gains, { "item", resmng.ITEM_MATERIAL_BOX, nbox })
        end
    end
    troop:add_goods(gains, VALUE_CHANGE_REASON.GATHER)

    if dp then
        if is_union_building(dp) then
            for k, v in pairs(dp.my_troop_id or {}) do
                if k == troop.owner_pid then
                    table.remove(dp.my_troop_id, k)
                    break
                end
            end
            save_ety(dp)
        else
            dp.val = math.floor( dp.val - count )
            if dp.val < 2 then 
                rem_ety(dp.eid)
            else
                dp.pid = 0
                dp.uid = 0
                dp.my_troop_id = 0
                etypipe.add(dp)
                farm.mark(dp)
            end
        end
    end
end


function do_kick_mass(troop, pid)
    local dest = get_ety(troop.target_eid)
    local dest_troop = dest:get_my_troop()
    union_hall_t.battle_room_update(OPERATOR.UPDATE, troop)

    local arm = troop.arms[ pid ]
    if arm then
        troop.arms[ pid ] = nil
        local T = getPlayer(troop.owner_pid)
        local A = getPlayer(pid)
        local sx, sy = get_ety_pos(A)
        local dx, dy = get_ety_pos(T)
        local one = troop_mng.create_troop(TroopAction.JoinMass, A, T, arm)
        one.curx = dx
        one.cury = dy
        one:back()
        A:rem_busy_troop(troop._id)

    else
        local target 
        if troop:is_ready() then
            target = get_ety( troop.owner_eid )

        elseif troop:is_settle() then
            target = get_ety( toop.target_eid )
        end

        if target then
            for tid, action in pairs( target.troop_comings or {} ) do
                local one = troop_mng.get_troop( tid )
                if one and one:is_go() and one.dest_troop_id == troop._id then
                    if one.owner_pid == pid then
                        local x, y = c_get_actor_pos(one.eid)
                        if x then
                            one.curx, one.cury = x, y
                            one.tmCur = gTime
                            one:back()
                        end
                    end
                end
            end
        end
    end
end

function dismiss_mass(troop)
    union_hall_t.battle_room_remove(troop)
    
    local pidT = troop.owner_pid
    local T = getPlayer(pidT)
    local x, y = get_ety_pos(T)
    for pid, arm in pairs(troop.arms) do
        local A = getPlayer(pid)
        if pid ~= pidT then
            local one = create_troop(TroopAction.JoinMass, A, T, arm)
            one.curx, one.cury = x, y
            one:back()
            troop.arms[ pid ] = nil
            A:rem_busy_troop(troop._id)
        end
    end

    troop:home()

    if T then
        for tid, action in pairs( T.troop_comings or {} ) do
            if action == TroopAction.JoinMass then
                local one = troop_mng.get_troop( tid )
                if one and one:is_go() and one.dest_troop_id == troop._id then
                    local x, y = c_get_actor_pos(one.eid)
                    if x then
                        one.curx, one.cury = x, y
                        one.tmCur = gTime
                        one:back()
                    end
                end
            end
        end
    end
end


function get_my_troop( obj )
    return get_troop(obj.my_troop_id)
end

