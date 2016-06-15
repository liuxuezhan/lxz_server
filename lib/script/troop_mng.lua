module("troop_mng")

troop_id_map = troop_id_map or {}
gTroopActionTrigger = {}


function load_data(t)
    local troop = troop_t.load_data(t)
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

    d.owner_eid = owner.eid
    d.owner_pid = owner.pid or 0
    d.owner_uid = owner.uid or 0
    d.sx, d.sy = get_ety_pos(owner)
    d.curx, d.cury = d.sx, d.sy

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
        d.arms = {}
        d.arms[ pid ] = arm
    else
        local pid = owner.pid or 0
        d.arms = {}
        d.arms[ pid ] = {pid=pid}
    end

    d.culture = owner.culture or 1
    d.extra = {}

    troop_id_map[ d._id ] = d
    --if action ~= TroopAction.DefultFollow and is_ply(owner) then owner:add_busy_troop(d._id) end

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


function delete_troop(troop_id)
    local troop = troop_id_map[ troop_id ]
    if troop == nil then return end
    troop.delete = true

	troop_id_map[troop_id] = nil
    gPendingDelete.troop[ troop_id ] = 0

    local owner_pid = troop.owner_pid
    for pid, _ in pairs(troop.arms) do
        if pid > 0 and pid ~= owner_pid then
            local ply = getPlayer(pid)
            if ply then ply:rem_busy_troop(troop_id) end
        end
    end

    local ply = getPlayer(owner_pid)
    if ply and owner_pid > 0 then ply:rem_busy_troop(troop_id) end
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
    print(string.format("troop trigger, troop = %d, action = %d", troop._id, troop.action))

    if troop:is_back() then 
        troop:home()
    else
        union_hall_t.battle_room_remove(troop)
        if gTroopActionTrigger[action] == nil then return troop:back() end
        troop:settle()
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
    local defense_troop = dest:get_defense_troop()

    --local win = fight.pvp("siege", troop, defense_troop)
    --local troops = troop:back() -- troopback first, for some unexpect mistake

    local troops = troop:back() -- troopback first, for some unexpect mistake
    local win = fight.pvp("unknown", troop, defense_troop)

    local rages = nil
    local capture = 0
    if win then
        dest:city_break( owner )
        rages = fight.rage(troop, dest) 
        for pid, rage in pairs(rages or {}) do
            local one = troops[ pid ]
            if one then
                one.goods = rage
                one.goods_reason = VALUE_CHANGE_REASON.RAGE
                one:save()
            end
            --任务
            local tm_player = getPlayer(pid)
            if tm_player ~= nil then
                local total = 0
                for k, v in pairs(rage) do
                    if v[1] == "res" then
                        total = total + v[3]
                    end
                end
                task_logic_t.process_task(tm_player, TASK_ACTION.LOOT_RES, 1, total)
                task_logic_t.process_task(tm_player, TASK_ACTION.ATTACK_PLAYER_CITY, 1, 1)
            end
        end

        local heroA, heroD = fight.hero_capture(troop, defense_troop)
        if heroA and heroD then
            if heroD.status == HERO_STATUS_TYPE.BUILDING then D:hero_offduty(heroD) end
            WARN("Capture Hero, %s -> %s", heroA._id, heroD._id)
            heromng.capture(heroA._id, heroD._id)
            capture = heroD.propid
        end
    else
        for k, v in pairs(troops) do
            local tmp_player = getPlayer(k)
            if tmp_player ~= nil then
                task_logic_t.process_task(tm_player, TASK_ACTION.ATTACK_PLAYER_CITY, 1, 0)
            end
        end
    end

    for pid, arm in pairs(defense_troop.arms) do
        local hurt = arm.hurt_soldier
        if not hurt then
            hurt = {}
            arm.hurt_soldier = hurt
        end
        for id, num in pairs(arm.dead_soldier or {}) do
            hurt[ id ] = (hurt[ id ] or 0) + num
        end
        arm.dead_soldier = {}
    end

    dest:troop_cure(defense_troop)
    Rpc:upd_arm(dest, defense_troop.arms[ dest.pid ].live_soldier or {}) 
    
    --发邮件
    player_t.generate_fight_mail(troop, defense_troop, win, capture, rages)

    player_t.rm_watchtower_info(troop)
    union_relation.add(troop)
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
    
	local defense_troop = dest:get_my_troop()

	--开战
	--fight.pvp("jungle", ack_troop, defense_troop)
    --local ts = ack_troop:back()

    local ts = ack_troop:back()
	local win = fight.pvp("jungle", ack_troop, defense_troop)

    delete_troop(defense_troop._id)
    dest.my_troop_id = nil
    if dest.hp <= 0 then
        if dest.grade ~= BOSS_TYPE.NORMAL then
            timer.new("boss", BossRbTime[dest.grade], dest.zx, dest.zy, dest.grade)
        end
        monster.increase_kill_score(dest)
        rem_ety(dest.eid)
    else
        etypipe.add(dest)
    end

    --任务
    local mid = dest.propid
    for k, v in pairs(ts) do
        local tmp_player = getPlayer(k)
        if tmp_player ~= nil then
            task_logic_t.process_task(tmp_player, TASK_ACTION.ATTACK_LEVEL_MONSTER, mid, 1)
        end
    end
end

--攻击任务npc怪物
gTroopActionTrigger[TroopAction.SiegeTaskNpc] = function(ack_troop)
    --开战
    local ts = ack_troop:back()
    local tmp_player = getPlayer(ack_troop.owner_pid)
    if tmp_player == nil then
        return 
    end
    local task_id = ack_troop:get_extra("npc_task_id")
    local task_data = tmp_player:get_task_by_id(task_id)
    if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then
        return
    end

    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then
        return
    end
    local key, monster_id = unpack(prop_task.FinishCondition)
    local defense_troop = nil
    local conf = resmng.get_conf("prop_world_unit", monster_id)
    if conf == nil then
        return
    end
    local arm = {}
    arm.live_soldier = {}
    for k, v in pairs(conf.Arms) do
        if v[1] ~= nil then
            arm.live_soldier[ v[1] ] = v[2]
        end
    end
    defense_troop = {owner_eid=0, owner_pid=0,arms={[0]=arm}}
    fight.pvp("task", ack_troop, defense_troop)
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
    local hp = task_data.hp or 100
    hp = math.ceil(hp - (all_total - live_total) * 100 / all_total)
    if hp <= 0 then
        --发奖
        local prop_tab = resmng.prop_world_unit[monster_id]
        if prop_tab == nil then
            return
        end
        tmp_player:add_bonus(prop_tab.Fix_award[1], prop_tab.Fix_award[2], VALUE_CHANGE_REASON.REASON_TASK_NPC_AWARD)
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
    if not dest_troop:is_ready() then return troop:back() end
    dest_troop:rem_mark_id(troop._id) --删除标记在目标troop上的troopid
    troop:merge(dest_troop)
end


gTroopActionTrigger[TroopAction.SupportArm] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local dest = get_ety(troop.target_eid)
    if dest == nil then return troop:back() end

    local dest_troop = dest:get_my_troop()
    if not dest_troop then return troop:back() end

    troop:merge(dest_troop)
    player_t.rm_watchtower_info(troop)
end

gTroopActionTrigger[TroopAction.SupportRes] = function(troop)
    troop:back()

    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return end

    local dest = get_ety(troop.target_eid)
    if dest == nil then return end

    if not is_ply( dest ) then return end

    if ply.uid > 0 and ply.uid == dest.uid then
        local tax = troop:get_extra("tax")
        local ratio = (100 - tax) / 100
        dest:add_bonus("mutex_award", troop.goods, troop.goods_reason, ratio) 
        troop.goods = nil 
    end
    player_t.rm_watchtower_info(troop)
end


gTroopActionTrigger[TroopAction.Camp] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    local prop = resmng.get_conf("prop_world_unit", CLASS_UNIT.Camp * 1000000 + ply.culture * 1000 + 1)
    if not prop then return troop:back() end

    local x = troop.dx
    local y = troop.dy
    if c_map_test_pos(x, y, prop.Size) ~= 0 then return troop:back() end

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
    if dest.pid > 0 then
        local dply = getPlayer(dest.pid)
        if dply then
            if dply.uid ~= ply.uid or (dply.uid == 0 and dply.uid == 0) then
                local dtroop = get_troop(dest.extra.tid)
                if dtroop then
                    local atk_win = fight.pvp("wild", troop, dtroop)
                    union_relation.add(troop)
                    if atk_win then
                        dtroop:back()
                        gather_stop(dtroop, dest)
                        do_gather(troop, dest)
                    else
                        troop:back()
                        local make = dtroop:get_extra("speed") * (gTime - dtroop:get_extra("start"))
                        dest.val = dest.val - make
                        local cache = dtroop:get_extra("cache")
                        dtroop:set_extra("cache", cache + make)
                        dtroop:set_extra("start", gTime)
                        do_gather(dtroop, dest)
                    end
                    return
                end
            end
            player_t.rm_watchtower_info(troop)
        end
    end
    do_gather(troop, dest)
end


function do_gather(troop, dest)
    local mode = resmng.get_conf("prop_world_unit", dest.propid).ResMode
    troop:set_extra("mode", mode)
    troop:recalc()
    troop.tmStart = gTime
    if is_union_building(dest) then
        if not dest.my_troop_id then dest.my_troop_id = {} end
        table.insert(dest.my_troop_id, troop._id)

        local dura = (troop:get_extra("count") - troop:get_extra("cache")) / troop:get_extra("speed")
        dura = math.ceil(dura)
        troop.tmOver = gTime + dura
        self.tmSn = timer.new("troop_action", dura, troop._id)

        union_build_t.troop_update(dest, "gather")
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
        dest.extra = {speed=speed, start=gTime, count=dest.val, tm=gTime, tid=troop._id}
        farm.mark(dest)
        etypipe.add(dest)
    end
end

--侦查
gTroopActionTrigger[TroopAction.Spy] = function(spy_troop)
    spy_troop:back()

    local player = get_ety(spy_troop.owner_eid)
    if not player then return end

	local dest_obj = get_ety(spy_troop.target_eid)
    if not dest_obj then return end

    if is_res(dest_obj) then
        if dest_obj.pid > 0 then
            if dest_obj.uid ~= player.uid or dest_obj.uid + player.uid == 0 then
                local dtroop = troop_mng.get_troop(dest_obj.extra.tid)
                if dtroop then
                    local unit_arm = {}
                    local live = dtroop:get_live(dest_obj.pid)
                    if live then
                        for k, v in pairs(live) do
                            if v > 0 then table.insert(unit_arm, {id=k, num=v}) end
                        end
                    end

                    local dply = getPlayer(dest_obj.pid)
                    local content = {name = dply.name, photo = dply.photo, x = dest_obj.x, y = dest_obj.y, arms = unit_arm, res0 = {0,0,0,0}, res1 = {0,0,0,0}}
                    local mail = {class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.SPY, content = content}
                    player:mail_new(mail)
                    dply:mail_new({class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.BE_SPY, content = {name = player.name, photo = player.photo}})
                end
            end
        end
        return
    end

    if is_ply( dest_obj ) then dest_obj:refresh_food() end
    
    local res1 = {
        dest_obj:get_res_num_normal(1), 
        dest_obj:get_res_num_normal(2),
        dest_obj:get_res_num_normal(3),
        dest_obj:get_res_num_normal(4)
    }
    local res0 = {0, 0, 0, 0}

    for k, v in pairs(dest_obj:get_build()) do
        local node = resmng.prop_build[v.propid]
        if node ~= nil and node.class == BUILD_CLASS.RESOURCE then
            local mode = node.Mode
            local speed = node.Speed
            local count = node.Count
            local b, m, a = dest_obj:get_val_extra(string.format("Res%dSpeed"), mode)
            local make = math.floor((gTime - v.tmStart) * (speed * m + a) / 3600)
            if make > count then 
                make = count 
            end
            res0[mode] = res0[mode] + make
        end
    end

    local unit_arm = {}
    local troop = get_my_troop(dest_obj)
    if troop then
        local live = troop:get_live()
        if live then
            for k, v in pairs(live) do
                if v > 0 then table.insert(unit_arm, {id=k, num=v}) end
            end
        end
    end

    local content = {name = dest_obj.name, photo = dest_obj.photo, x = dest_obj.x, y = dest_obj.y, arms = unit_arm, res0 = res0, res1 = res1}
    local mail = {class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.SPY, content = content}
    player:mail_new(mail)
    dest_obj:mail_new({class = MAIL_CLASS.FIGHT, mode = MAIL_FIGHT_MODE.BE_SPY, content = {name = player.name, photo = player.photo}})
  
    --任务
    if is_ply(dest_obj) == true then
        task_logic_t.process_task(player, TASK_ACTION.SPY_PLAYER_CITY, 1)
    elseif is_npc_city(dest_obj) == true then 
        task_logic_t.process_task(player, TASK_ACTION.SPY_NPC_CITY, 1)
    end
    player_t.rm_watchtower_info(spy_troop)
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

    if dest.uid == ack_troop.owner_uid then
        trigger_event(ack_troop, TroopAction.HoldDefense)
        return
    end
    
	local defense_troop = dest:get_my_troop()

	--开战
	local win = fight.pvp("todo", ack_troop, defense_troop)
    if win then
        local p = get_ety(ack_troop.owner_eid)
        --union_task.ok(p,dest_player,UNION_TASK.NPC) --攻击胜利后领取军团悬赏任务
    end
    if is_npc_city(dest) then
        npc_city.after_fight(ack_troop, defense_troop)
    end
    if is_lost_temple(dest) then
        lost_temple.after_fight(ack_troop, defense_troop)
    end

	--回城
    npc_city.deal_troop(ack_troop, defense_troop)
end

--单独攻击王城战建筑
gTroopActionTrigger[TroopAction.King] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then return ack_troop:back() end

    if dest.uid == ack_troop.owner_uid then
        gTroopActionTrigger[TroopAction.HoldDefense](ack_troop)
        return
    end
    
	local defense_troop = dest:get_my_troop()

	--开战
    dumpTab(ack_troop, "dest_player, before")
    if defense_troop then
        local win = fight.pvp("todo", ack_troop, defense_troop)
        if win then
            local p = get_ety(ack_troop.start_eid)
        end
    end
    
    king_city.after_fight(ack_troop, defense_troop)

    union_hall_t.battle_room_remove( ack_troop )

    dumpTab(ack_troop, "dest_player, after")
	--回城
    --
    king_city.deal_troop(ack_troop, defense_troop)
    
end



--驻守
gTroopActionTrigger[TroopAction.HoldDefense] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local obj = get_ety(troop.target_eid)
    if obj == nil then return troop:back() end
    obj.hold_troop[troop._id] = nil  

    -- 查看是否可以驻守
    if obj.uid ~= troop.owner_uid then
        if is_npc_city(obj) then
            trigger_event(troop, TroopAction.SeigeNpc)
        end
        if is_king_city(obj) then
            trigger_event(troop, TroopAction.King)
        end
        return
    end

    local tr = troop_mng.get_troop(obj.my_troop_id)
    if (not tr) or tr.owner_eid == obj.eid then 
        troop:settle()
        obj.my_troop_id = troop._id
    else 
        troop:merge(tr) 
    end
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
	local win = fight.pvp("todo", ack_troop, defense_troop)
    if win then
        local p = get_ety(ack_troop.start_eid)
    end

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
	local win = fight.pvp("todo", ack_troop, defense_troop)
    if win then
        local p = get_ety(ack_troop.start_eid)
    end

    monster_city.after_fight(ack_troop, defense_troop)
end

--玩家攻击怪物防守裂隙
gTroopActionTrigger[TroopAction.AtkMC] = function(ack_troop)
	local dest = get_ety(ack_troop.target_eid)
    if not dest then
        ack_troop:back()
    end

    if not dest:can_be_atk() then
        local ply = get_ety(ack_troop.owner_eid)
        if ply then
            self:add_debug("alread be atk")
        end
        ack_troop:back()
    end

	local defense_troop = dest:get_my_troop()

	--开战
	local win = fight.pvp("todo", ack_troop, defense_troop)
    if win then
        local p = get_ety(ack_troop.start_eid)
    end

    monster_city.after_been_atk(ack_troop, defense_troop)
end


--[[--驻守
gTroopActionTrigger[TroopAction.HoldDefense] = function(troop)
    local ply = getPlayer(troop.owner_pid)
    if ply == nil then return troop:back() end

    local obj = get_ety(troop.target_eid)
    if obj == nil then return troop:back() end

    -- 查看是否可以驻守
    if obj.defender ~= troop.owner_uid then
        if is_npc_city(obj) then
            gTroopActionTrigger[TroopAction.SeigeNpc](troop)
        end
        if is_king_city(obj) then
            gTroopActionTrigger[TroopAction.King](troop)
        end
        return
    end

    local tr = troop_mng.get_troop(obj.my_troop_id)
    if not tr then 
        obj.my_troop_id = troop._id
    else
        troop:merge(tr)
    end
    --任务
    -- task_logic_t.process_task(ply, TASK_ACTION.UNION_AID, 1)
end--]]


gTroopActionTrigger[TroopAction.SaveRes] = function(troop)
	local dest_obj = get_ety(troop.target_eid)
	if dest_obj == nil then
        --sanshimark回去的资源
        exception_troop_back(troop)
		return
	end

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

    local res = troop:get_extra("union_expect_res")
    --从仓库扣除
    union_build_t.restore_del_res(dest_obj,troop.owner_pid,res) 
    --放到部队上
    local real_res={}
    for k, v in pairs(res) do
        table.insert(real_res, {"res",k,v})
    end
    troop:mount_bonus(real_res,"union_expect_res")

    --回家
    troop:back()
end

--建造联盟建筑
gTroopActionTrigger[TroopAction.UnionBuild] = function(troop)
    local dest = get_ety(troop.target_eid)
    if not dest then 
        exception_troop_back(troop)
		return
	end

    local speed = 10000
    for pid, arm in pairs(troop.arms) do
        for id, num in pairs(arm.live_soldier or {}) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                speed = speed + conf.BuildSpeed * num
            end
        end
    end

    if speed <= 0 then 
        exception_troop_back(troop)
		return
    end
    troop:set_extra("speed", speed)

    if not dest.my_troop_id then dest.my_troop_id = {} end
    table.insert(dest.my_troop_id, troop._id)

    troop.action = TroopAction.UnionBuilding
    troop.tmStart = gTime
    troop.tmOver = 0
    troop.tmSn = 0

    union_build_t.troop_update(dest, "build")
end

--修联盟建筑
gTroopActionTrigger[TroopAction.UnionFixBuild] = function(troop)

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


--升级联盟建筑
gTroopActionTrigger[TroopAction.UnionUpgradeBuild] = function(troop)

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
            player_t.get_watchtower_info(troop)
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
    local mode = troop:get_extra("mode") or 1
    local gains = {}
    table.insert(gains, { "res", mode, math.ceil(count) })

    --troop_mng.mount_bonus(troop, gains, VALUE_CHANGE_REASON.GATHER)
    troop:add_goods(gains, VALUE_CHANGE_REASON.GATHER)
    troop.extra = {}

    local owner = getPlayer(troop.owner_pid)
    if owner then
        local content = {x=dp.x, y=dp.y, carry = {{1,mode,math.ceil(count)}}, buildid=dp.propid }
        local mail = {class=MAIL_CLASS.REPORT, mode=MAIL_REPORT_MODE.GATHER, content=content}
        owner:mail_new(mail)
        union_mission.ok(owner,UNION_MISSION_CLASS.GATHER ,calc_res(mode,count))
    end

    if dp then
        if is_union_building(dp) then
            for k, v in pairs(dp.my_troop_id or {}) do
                if k == troop.owner_pid then
                    table.remove(dp.my_troop_id, k)
                    break
                end
            end
            union_build_t.troop_update(dp, "gather")
        else
            dp.val = dp.val - count
            if dp.val < 1 then 
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
        for _, tid in pairs(troop.mark_troop_ids or {}) do
            local one = troop_mng.get_troop(tid)
            if one and one.owner_pid == pid  then
                troop:rem_mark_id(tid)
                local x, y = c_get_actor_pos(one.eid)
                if x then
                    one.curx, one.cury = x, y
                    one.tmCur = gTime
                    one:back()
                end
                return
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

    for _, tid in pairs(troop.mark_troop_ids or {}) do
        local one = troop_mng.get_troop(tid)
        if one then
            local x, y = c_get_actor_pos(one.eid)
            if x then
                one.curx, one.cury = x, y
                one.tmCur = gTime
                one:back()
            end
        end
    end
end


function get_my_troop( obj )
    return get_troop(obj.my_troop_id)
end

