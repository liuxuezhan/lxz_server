module("player_t")

-- make troop from home
-- siege
-- union_mass_create
-- gather
-- hold_defense
-- spy
-- union_save_res
-- union_get_res
-- union_build
-- union_fix_build
-- union_upgrade_build


function get_my_arm(self)
    local troop = troop_mng.get_troop(self.my_troop_id)
    if not troop then troop = self:get_my_troop() end
    return troop:get_arm_by_pid(self.pid)
end

function get_my_troop(self)
    local tr = troop_mng.get_troop(self.my_troop_id)
    if tr then return tr end
    WARN("get_my_troop, not found my_troop, pid=%d", self.pid)
    return self:init_my_troop()
end

function init_my_troop(self)
    local my_troop = troop_mng.get_troop(self.my_troop_id)
    if my_troop ~= nil then return my_troop end

    local troop = troop_mng.create_troop(TroopAction.DefultFollow, self, self)
    troop.arms = {}
    self.my_troop_id = troop._id
    return troop
end

function add_busy_troop(self, troop_id)
    for k, v in ipairs(self.busy_troop_ids) do
        if v == troop_id then
            return false
        end
    end
    table.insert(self.busy_troop_ids, troop_id)
    return true
end

function rem_busy_troop(self, troop_id)
    for k, v in ipairs(self.busy_troop_ids) do
        if v == troop_id then
            Rpc:stateTroop(self, {_id=troop_id, delete=true})
            table.remove(self.busy_troop_ids, k)
            return true
        end
    end
end

function rm_busy_troop(self, troop_id)
    local idx = 0
    for k, v in ipairs(self.busy_troop_ids) do
        if v == troop_id then
            idx = k
            break
        end
    end
    if idx > 0 then
        table.remove(self.busy_troop_ids, idx)
        return true
    else
        return nil
    end
end

function is_eid_valid(self, dest_eid)
    --错误的eid
    local dest_obj = get_ety(dest_eid)
    if dest_obj == nil then return false end

     --不能是自己
    if dest_eid == self.eid then return false end

    return true
end


-- WARNING!!! this function should be call just before create_troop, because here will deduct arm
function check_arm(self, arm)
    if self:is_troop_full() then 
        self:add_debug("CountTroop") 
        return 
    end

    local my_troop = troop_mng.get_troop(self.my_troop_id)
    if my_troop == nil then 
        LOG("没部队")
        return false 
    end
    local live = my_troop:get_live()

    local total_num = 0
    local valid_pos = {false, false, false, false} --步骑弓车，对应英雄的位置判断能不能有英雄
    for k, v in pairs(arm.live_soldier or {}) do
        if v <= 0 then 
            WARN("人数不足1")
            return 
        end
        if live[k] == nil or live[k] < v then 
            WARN("人数不足2")
            return false 
        end
        total_num = total_num + v
        local pos = math.floor(k/1000)
        valid_pos[pos] = true
    end

    local count_soldier = self:get_val("CountSoldier")
    if total_num < 1 or total_num > count_soldier then 
        self:add_debug(string.format( "CountSoldier, %d, %d", total_num, count_soldier)) 
        return 
    end

    local hsgo = {0,0,0,0}
    local hs = arm.heros or {}
    for i = 1, 4, 1 do
        local idx = hs[ i ]
        if idx and idx ~= 0 and valid_pos[i] then
            local h = self:get_hero(idx)
            if h and h.hp > 0 then
                if h.status == HERO_STATUS_TYPE.FREE then
                    hsgo[ i ] = h._id
                elseif h.status == HERO_STATUS_TYPE.BUILDING then
                    self:hero_offduty(h)
                    hsgo[ i ] = h._id
                end
            end
        end
    end
    arm.heros = hsgo

    for id, num in pairs(arm.live_soldier or {}) do
        live[ id ] = live[ id ] - num
    end

    local tlive = {}
    for k, v in pairs( live ) do
        if v >= 1 then
            tlive[ k ] = math.floor( v )
        end
    end
    my_troop.arms[ self.pid ].live_soldier = tlive

    for k, v in ipairs(hsgo) do
        if v ~= 0 then
            heromng.go_to_battle(v)
        end
    end
    self:mark_action( notify_arm )

    arm.pid = self.pid

    return true
end

-- troop start from home
-- troop start from home
-- troop start from home

function siege(self, dest_eid, arm)
    local dest = get_ety(dest_eid)
    if not dest then 
        self:add_debug("not ety:"..dest_eid) 
        return 
    end

    if not self:can_move_to(dest.x, dest.y)  then
        self:add_debug("can not move by castle lv") 
        if not player_t.debug_tag then
            return 
        end
    end

    local action = 0
    if is_monster(dest) then
        if not monster.can_atk_monster[dest.grade](self) then
            self:add_debug( "no npc occupy" )

            if not player_t.debug_tag then
                return 
            end
        end
        local prop = resmng.prop_world_unit[dest.propid]
        if prop then
            if prop.Declare == 1 then
                return
            end
        end

        action = TroopAction.SiegeMonster
        if self:get_sinew() < 10 then
            WARN("没体力")
            self:add_debug( "not enough sinew" )
            return
        end

    elseif is_ply(dest) then
        if dest.uid == self.uid and self.uid ~= 0 then return end
        action = TroopAction.SiegePlayer

    elseif is_npc_city(dest) and can_atk_npc(self, dest_eid) then
        action = TroopAction.SiegeNpc

    elseif is_lost_temple(dest)  then
        if not can_ply_join_act[ACT_TYPE.LT](self) then
            self:add_debug( "can not play level limit" )
            if not debug_tag then
                return 
            end
        end
        action = TroopAction.SiegeNpc

    elseif is_camp( dest ) then
        if ( self.uid ~= dest.uid) or (self.uid == 0 and dest.uid == 0) then action = TroopAction.SiegeCamp end

    elseif is_king_city(dest) then
        if not can_ply_join_act[ACT_TYPE.KING](self) then
            self:add_debug( "can not play level limit" )
            if not debug_tag then
                return 
            end
        end
        action = TroopAction.King

    elseif is_monster_city(dest) then
        action = TroopAction.AtkMC
        if not can_ply_join_act[ACT_TYPE.MC](self) then
            self:add_debug( "can not play level limit" )
            if not debug_tag then
                return 
            end
        end

        if not monster_city.can_atk_def_mc(dest, self.pid) then
            self:add_debug( "already atk or no right" )
            if not debug_tag then
                return 
            end
        end

    elseif is_res(dest) then
        if dest.pid and dest.pid > 0 then
            if ( self.uid ~= dest.uid) or (self.uid == 0 and dest.uid == 0) then 
                action = TroopAction.Gather
            end
        end

    elseif is_union_building(dest) then
        if not union_build_t.can_troop( TroopAction.SiegeUnion, self, dest_eid ) then return end
        action = TroopAction.SiegeUnion

    end

    if action == 0 then return end
    if self:check_troop_action( dest, action ) then return end

    if not self:check_arm(arm) then return end
    local troop = troop_mng.create_troop(action, self, dest, arm)

    if troop.action ==  TroopAction.SiegeNpc then
        troop.atk_uid = dest.uid
    end

    troop:go()
    if action ~= TroopAction.SiegeMonster then union_hall_t.battle_room_create(troop) end

    if is_monster(dest) then
        dest:mark()
        self:dec_sinew( 10 )

    elseif is_ply(dest) then

    elseif is_camp(dest) then
        union_hall_t.battle_room_create(troop)

    elseif is_res(dest) then

    end
end

--攻击任务npc怪物
function siege_task_npc(self, task_id, dest_eid, x, y, arm)
    local task_data = self:get_task_by_id(task_id)
    if task_data == nil or task_data.task_status ~= TASK_STATUS.TASK_STATUS_ACCEPTED then
        WARN("任务不存在")
        return
    end
    if not self:check_arm(arm) then 
        return 
    end

    local prop_task = resmng.prop_task_detail[task_id]
    if prop_task == nil then
        return
    end
    local key, monster_id = unpack(prop_task.FinishCondition)
    
    local troop = troop_mng.create_troop(TroopAction.SiegeTaskNpc, self, self, arm)
    troop.target_eid = dest_eid
    troop.target_propid = monster_id
    troop.dx = x
    troop.dy = y
    troop:set_extra("npc_task_id", task_id)
    local speed = nil
    if task_id == resmng.TASK_130010101 then
        local dis = calc_line_length(self.x, self.y, x, y)
        speed = math.ceil(dis / 10)
    end
    troop:go(speed) 
end

function gather(self, dest_eid, arm)
    local dest = get_ety(dest_eid)
    if not dest then return end
    if not self:can_move_to(dest.x, dest.y)  then return self:add_debug("can not move by castle lv") end

    local conf = resmng.get_conf("prop_world_unit", dest.propid)
    if not conf then return end
    if not conf.ResMode then return end

    local mode = conf.ResMode 
    if not mode then return end
    if self:get_castle_lv() < Gather_Level[ mode ] then return self:add_debug("can not gather by castle level") end

    if self:check_troop_action( dest, TroopAction.Gather ) then return end

    if not self:check_arm(arm) then return end
    local troop = troop_mng.create_troop(TroopAction.Gather, self, dest, arm)
    troop:go()

    if is_res(dest) then farm.mark(dest) end
end


function spy(self, dest_eid)
    local dest = get_ety(dest_eid)
    if not dest then return end
    if not self:can_move_to(dest.x, dest.y)  then return self:add_debug("can not move by castle lv") end
    if self:is_troop_full() then return self:add_debug("CountTroop") end

    if self:check_troop_action( dest, TroopAction.Spy ) then return end

    if is_ply(dest) then
        if dest.uid == self.uid and self.uid ~= 0 then return end

    elseif is_res(dest) then
        if dest.pid > 0 then
            if dest.uid == self.uid and self.uid ~= 0 then return end
        end
    end
    local troop = troop_mng.create_troop(TroopAction.Spy, self, dest)
    troop:go()
    self:add_count( resmng.ACH_COUNT_SCOUT, 1 )
end


function camp(self, x, y, arm)
    if x < 1 or x >= 1278 then return end
    if y < 1 or y >= 1278 then return end
    if c_map_test_pos(x, y, 2) ~= 0 then 
        self:add_debug( string.format("camp, map_test_pos, x = %d, y = %d, w = %d", x, y, 2 ) )
        return 
    end

    if not check_camp_cond(self, x, y, arm) then
        return
    end

    if not self:check_arm(arm) then return end
    local troop = troop_mng.create_troop(TroopAction.Camp, self, self, arm)
    troop.target_eid = 0
    troop.dx = x+1
    troop.dy = y+1
    troop:go()
end

function check_camp_cond(self, x, y, arm) -- 王城海域不能驻军
    local lv = c_get_zone_lv(math.floor(x/16), math.floor(y/16)) 
    return lv < 6
end

--集结
function union_mass_create(self, dest_eid, wait_time, arm)
    if self:check_mass_time(wait_time) == false then return end
    if self.uid == 0 then return end

    local D = get_ety(dest_eid)
    if not D then 
        INFO("没目标")
        return 
    end

    local action = 0
    if is_monster(D) then
        D.aimed = self.eid
        D:mark()
        action = TroopAction.SiegeMonster
        local prop = resmng.prop_world_unit[D.propid]
        if prop then
            if prop.Declare == 0 then
                return
            end
        end
    elseif is_ply(D) then
        if D.uid == self.uid then return end
        action = TroopAction.SiegePlayer
    elseif is_npc_city(D) then
        if can_atk_npc(self, dest_eid) then
            action = TroopAction.SiegeNpc
        end
    elseif is_king_city(D) then
        if not can_ply_join_act[ACT_TYPE.KING](self) then
            self:add_debug( "can not play level limit" )
            if not debug_tag then
                return 
            end
        end
        action = TroopAction.King
    elseif is_lost_temple(D) then
        action = TroopAction.SiegeNpc
    elseif is_monster_city(D) then
        action = TroopAction.AtkMC
        if not monster_city.can_atk_def_mc(D, self.pid) then
            self:add_debug( "already atk or no right" )
            return 
        end
    else
        --todo
        return
    end

    if self:check_troop_action( D, action) then return end

    local num = 0
    for id, n in pairs( arm.live_soldier or {} ) do num = num + n end
    if num > self:get_val("CountRallySoldier") then
        self:add_debug( "CountRallySoldier, %d, %d", num, self:get_val("CountRallySoldier") )
        return
    end

    if not self:check_arm(arm) then return end
    local troopA = troop_mng.create_troop(action, self, D, arm)
    troopA.arms[ self.pid ].tm_join = gTime
    troopA.is_mass = 1
    troopA.tmStart = gTime
    troopA.tmOver = gTime + wait_time
    troopA.tmSn = timer.new("troop_action", wait_time, troopA._id)
    troopA:notify_owner()

    union_hall_t.battle_room_create(troopA)
    reply_ok(self, "union_mass_create", troopA._id)
end

function get_aid_count(self)
    local count = 0
    local troop = self:get_my_troop()
    if troop then
        for pid, arm in pairs( troop.arms or {} ) do
            if pid ~= self.pid then
                for id, num in pairs( arm.live_soldier or {} ) do
                    count = count + num
                end
            end
        end
    end

    local comings = self.troop_comings
    if comings then
        for tid, action in pairs( comings ) do
            if action == TroopAction.SupportArm then
                local troop = troop_mng.get_troop( tid )
                if troop then
                    count = count + troop:get_troop_total_soldier()
                end
            end
        end
    end
    return count
end


function get_mass_count( T, troopT )
    local dest_troop_id = troopT._id
    local num = troopT:get_troop_total_soldier()
    local comings = T.troop_comings
    if comings then
        for tid, action in pairs( comings ) do
            if action == TroopAction.JoinMass then
                local troop = troop_mng.get_troop( tid )
                if troop and troop:is_go() and troop.dest_troop_id == dest_troop_id then
                    num = num + troop:get_troop_total_soldier()
                end
            end
        end
    end
    return num
end

--参与集结
function union_mass_join(self, dest_eid, dest_troop_id, arm)
    local T = get_ety(dest_eid)
    if not T then return end
    if not is_ply(T) then return end
    if not ( self.uid > 0 and self.uid == T.uid ) then return end

    local troopT = troop_mng.get_troop(dest_troop_id)
    if not troopT then 
        LOG("没部队")
        return 
    end

    local num = T:get_mass_count( troopT )
    for id, n in pairs( arm.live_soldier or {} ) do
        num = num + n
    end

    print( "union_mass_join, self+comming+me", num )
    print( "union_mass_join, CountRallySoldier", T:get_val( "CountRallySoldier" ) )

    if num > T:get_val("CountRallySoldier") then
        Rpc:tips(self, 3, resmng.UNION_MASS_JOIN ,{})
        return
    end

    if troopT.owner_eid ~= T.eid then return end
    if not troopT:is_ready() then return end

    local dest = get_ety(troopT.target_eid)
    if not dest then return end

    if self:check_troop_action( dest, troopT.action) then return end

    if not self:check_arm(arm)  then return end
    local troopA = troop_mng.create_troop(TroopAction.JoinMass, self, T, arm)
    troopA.dest_troop_id = dest_troop_id
    troopA:go()

    troopT:add_mark_id(troopA._id)


    if is_monster_city(dest) then
        if not dest:can_atk_def_mc(self.pid) then
            self:add_debug( "already atk" )
            return 
        end
    end

    local troopD = dest:get_my_troop()
    if not troopD then return end

    union_hall_t.battle_room_update(OPERATOR.UPDATE, troopT, troopD)
end

function declare_tw_req(self, dest_eid)  
    local dest = get_ety(dest_eid)
    if not dest then return end

    if not self:can_move_to(dest.x, dest.y)  then 
        self:add_debug("can not move by castle lv") 
        if not debug_tag then
            return 
        end
    end

    if not  can_ply_join_act[ACT_TYPE.NPC](self) then
        add_debug(self, "等级不够 宣战失败")
        if not debug_tag then
            return 
        end
    end

    if not  can_ply_opt_act[ACT_TYPE.NPC](self) then
        add_debug(self, "军团等级不够 宣战失败")
        if not debug_tag then
            return 
        end
    end

    local union = self.union(self) 
    if not union then 
        add_debug(self, "没有军团 宣战失败")
        if not debug_tag then
            return 
        end
    end
    
    for k, v in pairs(self.busy_troop_ids) do
        local tr = troop_mng.get_troop(v)
        if tr then
            if tr.target_eid == dest_eid and tr.action == (TroopAction.Declare + 100) then
                add_debug(self, "宣战失败 有宣战兵在路上")
                if not debug_tag then
                    return 
                end
            end
        end
    end

    if not union:can_declare_war(dest_eid) then
        add_debug(self, "宣战失败 军团的积分 或者 人数不够 或者 城市不相连 或者 次数限制")
        if not debug_tag then
            return 
        end
    end
    local target = get_ety(dest_eid)
    if not target then return end

    local troop = troop_mng.create_troop(TroopAction.Declare, self, target)

    troop:go()
end

function decalre_atk_mc(self, dest_eid)
    local dest = get_ety(dest_eid)
    if not dest then return end

    local troop = troop_mng.create_troop(TroopAction.Declare, self, dest)
    troop:go()
end

function union_aid_count(self, pid)
    local data = { pid = pid, }
    local A = getPlayer(pid)
    if A then
        data.max = A:get_val( "CountRelief" )
        data.cur = A:get_aid_count()
    end
    Rpc:union_aid_count(self, data)
end

function support_arm(self, dest_eid, arm)
    local dest = get_ety(dest_eid)
    if not dest then return end
    if not ( dest.uid > 0 and dest.uid == self.uid ) then return end

    if not is_ply(dest) then return end
    if not self:can_move_to(dest.x, dest.y)  then return self:add_debug("can not move by castle lv") end

    if not self:check_arm(arm) then return end

    local max = dest:get_val( "CountRelief" )
    local cur = dest:get_aid_count()
    local can = max - cur

    local total = cur
    for k, v in pairs( arm.live_soldier or {} ) do
        total = total + v
    end
    if total == 0 then return self:add_debug( "arm count == 0" ) end
    if total > max then 
        Rpc:tips(self, 3, resmng.NOTIFY_MARCH_FULL, {})
        return
    end

    local troop = troop_mng.create_troop(TroopAction.SupportArm, self, dest, arm)
    troop:go()
    
    local troopT = dest:get_my_troop()
    troopT:add_mark_id(troop._id)
    troop.dest_troop_id = troopT._id

    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, dest)
    Rpc:aid_notify( self )
end

function support_res(self, dest_eid, res)
    local dest = get_ety(dest_eid)
    if not dest then return end
    if not is_ply(dest) then return end
    if self.uid == 0 then return end
    if dest.uid ~= self.uid then return end
    if self:is_troop_full() then self:add_debug("CountTroop") return end

    local limit_load = 0
    local tax = 100
    local build_data = self:get_market()
    local build_id = resmng.BUILD_MARKET_1
    if build_data ~= nil then
        build_id = build_data.propid
    end
    local prop_build = resmng.prop_build[build_id]
    if prop_build ~= nil then
        tax = prop_build.Effect.CountTax
        limit_load = prop_build.Effect.CountResSupport_A
    end
    local ratio = (100 - tax) / 100
    --判断负重
    local cur_load = 0
    local dest_load = 0
    for mode, num in pairs( res ) do
        cur_load = cur_load + num * RES_RATE[mode]
    end
    if cur_load > limit_load then
        return
    end
     
    local num = 0
    local have = self.res
    for mode, num in pairs( res ) do
        if mode <= 0 and mode >= 4 then return end
        if self:get_res_num_normal( mode ) < num then return end
    end

    local goods = {}
    for mode, num in pairs( res ) do
        if num > 0 then
            self:do_dec_res( mode, num, VALUE_CHANGE_REASON.SUPPORT_RES)
            table.insert( goods, { "res", mode, num } )
            dest_load = dest_load + math.floor(num * ratio * RES_RATE[mode])
        end
    end

    local troop = troop_mng.create_troop(TroopAction.SupportRes, self, dest)
    troop:add_goods( goods, VALUE_CHANGE_REASON.SUPPORT_RES)
    troop:set_extra("tax", tax)
    troop:go()
end



------------------------ new version ------------------
------------------------ new version ------------------
------------------------ new version ------------------
--联盟仓库存资源
function union_save_res(self, dest_eid, res)
    local dest = get_ety(dest_eid)
    if not dest then return end

    if self:is_troop_full() then self:add_debug("CountTroop") return end

    if not union_build_t.can_troop( TroopAction.SaveRes, self, dest_eid, res) then return end

    local troop = troop_mng.create_troop(TroopAction.SaveRes, self, dest)
    troop:go()
    troop:set_extra("union_save_res", res) 

    --把资源扣除
    self:do_dec_res(resmng.DEF_RES_FOOD, res[resmng.DEF_RES_FOOD], VALUE_CHANGE_REASON.REASON_UNION_SAVE_RESTORE)
    self:do_dec_res(resmng.DEF_RES_WOOD, res[resmng.DEF_RES_WOOD], VALUE_CHANGE_REASON.REASON_UNION_SAVE_RESTORE)
    self:do_dec_res(resmng.DEF_RES_IRON, res[resmng.DEF_RES_IRON], VALUE_CHANGE_REASON.REASON_UNION_SAVE_RESTORE)
    self:do_dec_res(resmng.DEF_RES_ENERGY, res[resmng.DEF_RES_ENERGY], VALUE_CHANGE_REASON.REASON_UNION_SAVE_RESTORE)
end

function can_atk_npc(self, destEid)

    if player_t.debug_tag == 1 then
        return true
    end

    if not  can_ply_join_act[ACT_TYPE.NPC](self) then
        add_debug(self, "等级不够 无法参加")
        if not debug_tag then
            return 
        end
    end
    local union = player_t.union(self)
    return union_t.can_atk_npc(union, destEid) and npc_city.can_atk_npc(self, destEid)
end

--联盟仓库取资
function union_get_res(self, dest_eid, res)
    local dest = get_ety(dest_eid)
    if not dest then return end

    if self:is_troop_full() then self:add_debug("CountTroop") return end

    if not union_build_t.can_troop( TroopAction.GetRes, self, dest_eid, res) then return end

    local troop = troop_mng.create_troop(TroopAction.GetRes, self, dest)
    troop:go()
    troop:set_extra("union_expect_res", res) 
end



-- troop start from home
-- troop start from home
-- troop start from home
--

--检查集结的时间
function check_mass_time(self, time)
    if time ~= MassTime.Level1 and time ~= MassTime.Level2 and time ~= MassTime.Level3 and time ~= MassTime.Level4 then
        return false
    end
    return true
end

--驻守
function hold_defense(self, dest_eid, arm)
    --todo
    --if is_union_building(dest_eid) and not union_build_t.can_troop( TroopAction.HoldDefense,self,dest_eid) then return end

    local dest = get_ety(dest_eid)
    if not dest then return end

    if is_npc_city(dest) then
        if not can_ply_join_act[ACT_TYPE.NPC](self) then
            add_debug(self, "等级不够 宣战失败")
            if not debug_tag then
                return 
            end
        end
    end

    if is_king_city(dest) then
        if not can_ply_join_act[ACT_TYPE.KING](self) then
            add_debug(self, "等级不够 宣战失败")
            if not debug_tag then
                return 
            end
        end
    end

    if is_lost_temple(dest) then
        if not can_ply_join_act[ACT_TYPE.LT](self) then
            add_debug(self, "等级不够 宣战失败")
            if not debug_tag then
                return 
            end
        end
    end

    if not self:check_arm(arm) then return end
    local troop = troop_mng.create_troop(TroopAction.HoldDefense, self, dest, arm)
    troop:go()
    if not dest.hold_troop then  
        dest.hold_troop = {}  
    end
    dest.hold_troop[troop._id] = 1  
    union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, dest)
end



--侦查
--function spy(self, dest_eid)
--    if self:is_eid_valid(dest_eid) == false then return end
--    if self:is_troop_full() then return end
--    --todo
--
--    local dest_obj = get_ety(dest_eid)
--    local sx, sy = get_ety_pos(self)
--    local dx, dy = get_ety_pos(dest_obj)
--
--    local troop = troop_mng.create_troop(self.eid, dest_eid, TroopAction.Spy, sx, sy, dx, dy)
--    self:add_busy_troop(troop._id)
--    troop.owner_pid = self.pid
--    troop.union_id = self:get_uid()
--
--    if is_ply(dest_obj) then troop.dest_uid = dest_obj.uid else troop.dest_uid = 0 end 
--
--    troop.speed = (FixTroopSpeed.Spy / 60)
--    troop:start_march() 
--
--
--    --local dest = get_ety(dest_eid)
--    --if not dest then return end
--end


function union_build(self, dest_eid, arm)
    local dest = get_ety(dest_eid)
    if not dest then return end

    if not union_build_t.can_troop( TroopAction.UnionBuild, self, dest_eid) then 
        return 
    end

    if not self:check_arm(arm)  then 
        return 
    end
    local troop = troop_mng.create_troop(TroopAction.UnionBuild, self, dest, arm)
    troop:go()
    if not dest.hold_troop then  
        dest.hold_troop = {}  
    end
    dest.hold_troop[troop._id] = 1  
end


function union_fix_build(self, dest_eid, arm)
    local dest = get_ety(dest_eid)
    if not dest then return end

    if not union_build_t.can_troop( TroopAction.UnionFixBuild, self, dest_eid) then return end
    if not self:check_arm(arm)  then return end
    local troop = troop_mng.create_troop(TroopAction.UnionFixBuild, self, dest, arm)
    troop:go()
    if not dest.hold_troop then  
        dest.hold_troop = {}  
    end
    dest.hold_troop[troop._id] = 1  
end


--升级建筑
function union_upgrade_build(self, dest_eid, arm)
    local dest = get_ety(dest_eid)
    if not dest then return end

    if not union_build_t.can_troop( TroopAction.UnionUpgradeBuild, self, dest_eid) then return end

    if not self:check_arm(arm)  then return end
    local troop = troop_mng.create_troop(TroopAction.UnionUpgradeBuild, self, dest, arm)
    troop:go()
    if not dest.hold_troop then  
        dest.hold_troop = {}  
    end
    dest.hold_troop[troop._id] = 1  
    dest.state = BUILD_STATE.UPGRADE 
    etypipe.add(dest)
end

--买特产
function buy_specialty(self, dest_eid, item)
    if self:is_eid_valid(dest_eid) == false then
        return
    end 

    local dest_obj = get_ety(dest_eid)
    
    --BuySpecialty    = 19,  --买特产
end

--上架特产
function confirm_specialty(self, dest_eid, item)  

    if self:is_eid_valid(dest_eid) == false then
        return
    end 

    local dest_obj = get_ety(dest_eid)
    --ConfirmSpecialty = 20, --上架特产
end

--下架特产
function cancle_specialty(self, dest_eid, item)

    if self:is_eid_valid(dest_eid) == false then
        return
    end 

    local dest_obj = get_ety(dest_eid)
    --CancleSpecialty = 21,  --下架特产
end

function troop_recall(self, dest_troop_id)
    local troop = troop_mng.get_troop(dest_troop_id)
    if troop then
        if troop.delay then return end

        if not (troop.owner_pid == self.pid or (troop.arms and troop.arms[ self.pid ] ) ) then 
            Mark( "troop_recall, self.pid = %d, troop_id = %d", self.pid, dest_troop_id )
            return 
        end

        local action = troop:get_base_action()
        if troop:is_go() then
            if action ~= TroopAction.Camp then
                local D = get_ety( troop.target_eid )
                if D then
                    if D.troop_comings then
                        D.troop_comings[ troop._id ] = nil
                        if D.on_troop_cancel then
                            D:on_troop_cancel( troop )
                        end
                   end
                   if not is_ply( D ) and D.pid and D.pid >= 10000 then
                       local B = getPlayer( D.pid )
                       if B then
                           if B.on_troop_cancel then
                               B:on_troop_cancel( troop )
                           end
                       end
                   end
                end
            end

            if aciton == TroopAction.SiegeCamp then

            end

            if action == TroopAction.Gather then

            end

            if action == TroopAction.SaveRes then
                local res = troop:get_extra("union_save_res")
                --放到部队上
                local real_res={}
                for k, v in pairs(res) do
                    table.insert(real_res, {"res",k,v})
                end
                troop:add_goods(real_res, VALUE_CHANGE_REASON.REASON_UNION_SAVE_RESTORE )
            end

            troop.curx , troop.cury = c_get_actor_pos(troop.eid)
            troop.tmCur = gTime
            union_hall_t.battle_room_remove(troop)

            if troop.is_mass == 1 then
                troop.action = troop:get_base_action() + 300
                --troop.sx, troop.sy = troop.curx, troop.cury
                troop.sx, troop.sy = troop.dx, troop.dy
                troop.dx, troop.dy = get_ety_pos( self )
                troop:start_march()
            else
                troop:back()
            end

            if action == TroopAction.JoinMass then
                local troopT = troop_mng.get_troop(troop.dest_troop_id)
                if troopT then
                    troopT:rem_mark_id(troop._id)
                    local D = get_ety(troopT.target_eid)
                    if D then
                        local troopD = D:get_my_troop()
                        if troopD then
                            union_hall_t.battle_room_update(OPERATOR.UPDATE, troopT, troopD)
                        end
                    end
                end
            elseif action == TroopAction.SupportArm then
                local dest = get_ety(troop.target_eid)
                union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, dest)
            end
        elseif troop:is_settle() then
            local dest = get_ety(troop.target_eid)
            if action == TroopAction.Gather then
                troop:back()
                if is_res(dest) then 
                    dest.my_troop_id = 0
                    self:detach_ety( dest )
                else 
                    remove_id(dest.my_troop_id, troop._id) 
                end
                if dest then troop_mng.gather_stop(troop, dest) end

            elseif action == TroopAction.UnionBuild or action== TroopAction.UnionUpgradeBuild or action == TroopAction.UnionFixBuild then
                local one = troop:split_pid(self.pid)
                one:back()
                save_ety(dest)

            elseif action == TroopAction.Camp then
                troop:back()
                local camp = get_ety(troop.target_eid)
                if camp then
                    self:detach_ety( camp )
                    rem_ety(camp.eid)
                end
            elseif action == TroopAction.HoldDefense then
                local camp = get_ety(troop.target_eid)
                if camp  and camp.hold_troop then
                    camp.hold_troop[troop._id]= nil
                end
                union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, dest)
                local one = troop:split_pid(self.pid)
                if not one then
                    WARN("["..self.pid..":"..troop._id.."]")
                    return 
                end
                one:back()
                if get_table_valid_count(troop.arms) == 0  and dest then 
                    if is_lost_temple(camp) then
                        camp:reset_lt()
                        local citys = self.lt_citys 
                        if  citys then
                            citys[ dest.eid ] = nil
                        end
                    end
                    dest.my_troop_id = nil 
                end
                save_ety(dest)

            else
                -- todo
            end

        elseif troop:is_ready() then
            if troop.action == TroopAction.DefultFollow then
                local dest = get_ety(troop.owner_eid)
                union_hall_t.battle_room_update_ety(OPERATOR.UPDATE, dest)

                local one = troop:split_pid(self.pid)
                if one then
                    one.curx, one.cury = get_ety_pos(dest)
                    one.action = TroopAction.SupportArm
                    one:back()
                end

            elseif troop.is_mass == 1 then
                local pid = self.pid
                if pid == troop.owner_pid then
                    troop_mng.dismiss_mass(troop)
                else
                    troop_mng.do_kick_mass(troop, pid)
                end
            end
        elseif troop:is_back() then
            troop.curx, troop.cury = c_get_actor_pos( troop.eid )
            print( "backing" )
        end
    end
end


function recall_all( self )
    local tids = copyTab( self.busy_troop_ids )
    for _, tid in pairs( tids ) do
        self:troop_recall( tid )
    end
end


function troop_acc(self, troopid, ratio)
    local troop = troop_mng.get_troop(troopid)
    if troop and troop.owner_eid == self.eid and (troop:is_go() or troop:is_back()) then
        troop:acc_march( 2 )
    end
end


function tag_ety_troop(troop) -- 标记该部队挂着的ety队列
    if troop:is_go() then
        local owner = get_ety(troop.owner_eid)
        if owner and (is_npc_city(owner) or is_lost_temple(owner) or is_king_city(owner) or is_monster_city(owner) or is_monster(owner) ) then
            owner.leave_troop_tag = nil
        end

        local target =  get_ety(data.target_eid)
        if target and (is_npc_city(target) or is_lost_temple(target) or is_king_city(target) or is_monster_city(target) or is_monster(target)) then
            target.atk_troop_tag = nil
        end
    end
end


function troop_arrive_at_time(self, tid, secs)
    local troop = troop_mng.get_troop(troopid)
    if troop and troop.owner_eid == self.eid and troop.status == TroopStatus.Moving then
        local curx, cury = c_get_actor_pos(troop.eid)
        local remain = calc_line_length(curx, cury, troop.dx, troop.dy)

    end
end


function troop_cure(self, troop, arms)
    local arms = arms or troop.arms or {}
    local role = self.pid
    for pid, arm in pairs(arms) do
        if pid == role then
            local count_cure = self:get_val("CountCure")
            local count = 0
            for id, num in pairs(self.hurts or {}) do count = count + num end
            --for id, num in pairs(self.cures or {}) do count = count + num end
            
            local troop_hurt = {}
            local nhurt = 0
            for id, num in pairs(arm.hurt_soldier or {}) do
                table.insert(troop_hurt, {id, num})
                nhurt = nhurt + num
            end

            if arm.pre_hurt then
                for id, num in pairs(arm.pre_hurt or {}) do
                    table.insert(troop_hurt, {id, num})
                    nhurt = nhurt + num
                end
                arm.pre_hurt = nil
            end

            local thurt = arm.hurt_soldier or {}
            local tcure = {}

            if count < count_cure then
                local hurts = self.hurts
                if count + nhurt <= count_cure then
                    for _, v in pairs(troop_hurt) do
                        local id = v[1]
                        local num = v[2]
                        hurts[ id ] = (hurts[ id ] or 0) + num
                        tcure[ id ] = (tcure[ id ] or 0) + num
                    end
                else
                    local sortf = function (ida, idb)
                        local a = resmng.get_conf("prop_arm", ida[1])
                        local b = resmng.get_conf("prop_arm", idb[1])
                        if a and b then
                            if a.Lv > b.Lv then return true end
                            if a.Lv < b.Lv then return false end
                            if a.Mode > b.Mode then return true end
                        end
                        return false
                    end
                    table.sort(troop_hurt, sortf)
                    dumpTab( "troop_hurt", troop_hurt )

                    for _, v in pairs(troop_hurt) do
                        local id = v[1]
                        local num = v[2]
                        if count + num <= count_cure then
                            hurts[ id ] = (hurts[ id ] or 0) + num
                            tcure[ id ] = (tcure[ id ] or 0) + num
                            count = count + num
                        else
                            local remain = count_cure - count
                            if remain > 0 then
                                hurts[ id ] = (hurts[ id ] or 0) + remain
                                tcure[ id ] = (tcure[ id ] or 0) + remain
                                count = count_cure
                                break
                            end
                        end
                    end
                end
                self.hurts = hurts

                local tdead = arm.dead_soldier or {}
                for id, num in pairs( thurt or {}  )do
                    local remain = num - (tcure[ id ] or 0)
                    if remain > 0 then
                        tdead[ id ] = ( tdead[ id ] or 0 ) + remain
                    end
                end
                arm.dead_soldier = tdead
                arm.hurt_soldier = tcure
            else
                arm.dead_soldier = thurt
                arm.hurt_soldier = {}
            end
            return count
        else

        end
    end
    return 0
end

function cure_on( self, start, over, timer_sn)
    local class = BUILD_CLASS.FUNCTION
    local mode = BUILD_FUNCTION_MODE.HOSPITAL
    local max_seq = (BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]) or 1
    for i = 1, max_seq, 1 do
        local idx = self:calc_build_idx(class, mode, i)
        local build = self:get_build( idx )
        if build then
            if build.state == BUILD_STATE.WAIT or build.state == BUILD_STATE.WORK then
                build.state = BUILD_STATE.WORK
                build.tmStart = start
                build.tmOver = over
                if timer_sn then build.tmSn = timer_sn end
            end
        end
    end
end


function cure_off( self )
    local class = BUILD_CLASS.FUNCTION
    local mode = BUILD_FUNCTION_MODE.HOSPITAL

    local max_seq = (BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]) or 1
    for i = 1, max_seq, 1 do
        local idx = self:calc_build_idx(class, mode, i)
        local build = self:get_build( idx )
        if build then
            if build.state == BUILD_STATE.WORK then
                build.state = BUILD_STATE.WAIT
                build.tmStart = 0
                build.tmOver = 0
                build.tmSn = 0
            end
        end
    end
end

function dismiss( self, id, num, ishurt )
    if ishurt == 1 then
        local hurts = self.hurts
        if hurts and hurts[ id ] and hurts[ id ] >= num then
            hurts[ id ] = hurts[ id ] - num
            if hurts[ id ] <= 0 then hurts[ id ] = nil end
            self.hurts = hurts
            reply_ok(self, "dismiss", 0)
        end
    else
        if self:rem_soldier( id, num ) then
            reply_ok(self, "dismiss", 0)
        end
    end
end


function cure( self, arm, quick )
    for k, v in pairs( self.cures ) do
        return ack( self, "cure", resmng.E_ALREADY_CURE, 0)
    end

    local hurts = self.hurts
    local total = 0
    local dura = 0
    local res = {0, 0, 0, 0}
    local proptab = resmng.prop_arm

    local consume_rate = self:get_num( "CountConsumeCure_R" ) or 0
    consume_rate = 1 + consume_rate * 0.0001
    self.cure_rate = consume_rate
    
    for id, num in pairs( arm ) do
        if hurts[ id ] and hurts[ id ] >= num then
            total = total + num
            local prop = proptab[ id ]
            if not prop then return ack(self, "cure", resmng.E_NO_CONF, id) end
            dura = dura + prop.TrainTime * 0.05 * num 
            local cons = prop.Cons
            for _, v in pairs( cons ) do
                local mode = v[2]
                local pay = v[3]
                res[ mode ] = res[ mode ] + pay * 0.5 * num * consume_rate
            end
        else
            return ack(self, "cure", resmng.E_NO_HURT, id)
        end
    end
    local count = self:get_val("CountCure")
    if total > count then return ack(self, "cure", resmng.E_NO_CONF, 0) end

    dura = math.ceil( dura / ( 1 + self:get_num( "SpeedCure_R" ) * 0.0001 ) )

    if quick == 1 then
        local cons = {}
        for mode, num in pairs( res ) do
            if num > 0 then table.insert( cons, { resmng.CLASS_RES, mode, num } ) end
        end

        local cons_have, cons_need_buy = self:split_cons(cons)
        local gold_need = calc_cons_value(cons_need_buy) + calc_acc_gold(dura)
        if gold_need > 0 and gold_need > self.gold then return ack(self, "cure", resmng.E_NO_RES, mode) end

        -- 扣除 cons_have 和 gold_need
        self:dec_cons(cons_have, VALUE_CHANGE_REASON.CURE, true)
        if gold_need > 0 then
            self:do_dec_res(resmng.DEF_RES_GOLD, gold_need, VALUE_CHANGE_REASON.CURE)
        end

        local hurts = self.hurts
        local c_count = 0
        for id, num in pairs( arm ) do
            hurts[ id ] = hurts[ id ] - num
            c_count = c_count + num
        end

        local tmps = {}
        for k, v in pairs( hurts ) do
            if v > 0 then tmps[ k ] = v end
        end
        self.hurts = tmps
        self:add_soldiers( arm )

        reply_ok(self, "cure", 0)
        --成就
        self:add_count( resmng.ACH_COUNT_CURE, c_count )
        --任务
        task_logic_t.process_task(self, TASK_ACTION.CURE, 2, c_count)


    else
        for mode, num in pairs( res ) do
            if self:get_res_num( mode ) < math.ceil(num) then return ack(self, "cure", resmng.E_NO_RES, mode) end
        end

        for mode, num in pairs( res ) do
            self:do_dec_res( mode, math.ceil( num ), VALUE_CHANGE_REASON.CURE )
        end

        local hurts = self.hurts
        for id, num in pairs( arm ) do
            hurts[ id ] = hurts[ id ] - num
        end

        local tmps = {}
        for k, v in pairs( hurts ) do
            if v > 0 then tmps[ k ] = v end
        end

        dura = math.ceil( dura )
        self.hurts = tmps
        self.cures = arm
        self.tm_cure = timer.new("cure", dura, self.pid )
        self.cure_start = gTime
        self.cure_over = gTime + dura
        self:cure_on( gTime, gTime+dura, self.tm_cure)
        reply_ok(self, "cure", 0)
    end
end

function cure_acc( self, mode )
    if self.tm_cure and timer.get( self.tm_cure ) then 
        local remain = self.cure_over - gTime 
        remain = math.floor( remain * 0.5 )
        if remain > 1 then
            timer.acc( self.tm_cure, remain )
            self.cure_over = gTime + remain
            self:cure_on( gTime, gTime + remain)
        end
    end
end


function is_troop_full(self)
    if #self.busy_troop_ids  >= self:get_val("CountTroop") then return true end
end


function kick_mass(self, tid, pid)
    local troop = troop_mng.get_troop(tid)
    if not troop then return end
    if troop.owner_pid ~= self.pid then return end
    troop_mng.do_kick_mass(troop, pid)
end


function get_defense_troop(self)
    local troop = self:get_my_troop()
    local heros = self:get_defense_heros()
    if troop.arms[ self.pid ] == nil then
        troop.arms[ self.pid ] = {}
    end
    troop.arms[ self.pid ].heros = heros

    troop.arms[ self.pid ].hurt_soldier = {}
    troop.arms[ self.pid ].dead_soldier = {}
    local live = troop.arms[ self.pid ].live_soldier
    if not live then troop.arms[ self.pid ].live_soldier = {} end

    return troop
end


function do_check_troop_action( self, dest, action )
    local lv = self:get_castle_lv()
    if self:get_buf( resmng.BUFF_SHELL_ROOKIE ) then
        if action == TroopAction.SiegeMonster then return end
        if action == TroopAction.Camp then return end
        if action == TroopAction.UnionBuild then return end
        if action == TroopAction.UnionFixBuild then return end
        if action == TroopAction.HoldDefense and dest:is_union_building() then return end
        if action == TroopAction.Gather and is_res(dest) and dest.pid == 0 and get_table_valid_count( dest.comings or {} ) == 0 then return end
        if action == TroopAction.Gather and is_union_building(dest) then return end
        if action == TroopAction.SaveRes then return end
        return "rookie"
    end
    return 
end


function check_troop_action( self, dest, action )
    local result = do_check_troop_action( self, dest, action ) 
    if result then
        if result == "rookie" then
            Rpc:tips( self, 1, resmng.TIPS_SHELL_ROOKIE, {})
        end
        return result
    end
end

