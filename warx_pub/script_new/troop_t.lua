module("troop_t", package.seeall)

__troop_mt = {__index = troop_t}
function new()
    local obj = {}
    setmetatable(obj, __troop_mt)
    obj:init()
    return obj
end

function load_data(data)
    setmetatable(data, __troop_mt)
    if data.action == TroopAction.DefultFollow then
        for pid, _ in pairs(data.arms) do
            if pid ~= data.owner_pid then
                local ply = getPlayer(pid)
                if ply then
                    ply:add_busy_troop(data._id)
                end
            end
        end
        local A = get_ety(data.owner_eid)
        if A and A.my_troop_id ~= data._id then
            A.my_troop_id = data._id
        end
    else
        if data.arms then
            for pid, _ in pairs(data.arms) do
                if pid >= 10000 then
                    local ply = getPlayer(pid)
                    if ply then
                        ply:add_busy_troop(data._id)
                    end
                end
            end
        else
            if data.owner_pid >= 10000 then
                local ply = getPlayer(data.owner_pid)
                if ply then
                    ply:add_busy_troop(data._id)
                end
            end
        end

        local owner = get_ety(data.owner_eid)
        local target =  get_ety(data.target_eid)

        if data:is_go() then
            if owner and (is_npc_city(owner) or is_lost_temple(owner) or is_king_city(owner) or is_monster_city(owner) or is_monster(owner) ) then
                monster_city.add_leave_troop(owner, data._id)
            end

            if target and (is_npc_city(target) or is_lost_temple(target) or is_king_city(target) or is_monster_city(target) or is_monster(target)) then
                monster_city.add_atk_troop(target, data._id)
            end
            data:add_link()
        end

        if data:is_settle() then
            if target and is_union_building( target ) then
                if data:get_base_action() == TroopAction.Gather then
                    if not target.my_troop_id then target.my_troop_id = {} end
                    table.insert(target.my_troop_id,data._id)
                else
                    target.my_troop_id = data._id
                end
            end
        end
    end

    if not data.culture then data.culture = 1 end
    if not data.flag then data.flag = 0 end
    if not data.soldier_num then data.soldier_num = {1,0,0,0} end
    return data
end

function add_link( self )
    if self:is_go() then
        local action = self:get_base_action()
        if action ~= TroopAction.Camp then
            local dest = get_ety( self.target_eid )
            if dest then
                local comings = dest.troop_comings
                if not comings then
                    dest.troop_comings = { [ self._id ] = action } 
                else
                    comings[ self._id ] = action
                end

                if not is_ply( dest ) then
                    if dest.pid and dest.pid >= 10000 then
                        local A = getPlayer( dest.pid )
                        if A and A ~= dest then
                            local comings = A.troop_comings
                            if not comings then
                                A.troop_comings = { [ self._id ] = action } 
                            else
                                comings[ self._id ] = action
                            end
                        end
                    end
                end
            end
        end
    end
end


function save(self)
    if self:get_base_action() ~= TroopAction.Monster then
        gPendingInsert.troop[ self._id ] = self
    end
end


function get_base_action(self)
    return math.floor(self.action % 100)
end

function is_ready(self)
    return self.action < 100
end

function is_go(self)
    return self.action > 100 and self.action < 200
end

function is_settle(self)
    return self.action > 200 and self.action < 300
end

function is_back(self)
    return self.action > 300 and self.action < 400
end

function calc_troop_speed(self)
    local action = self:get_base_action()
    local speed = TroopSpeed[ action ]
    if speed then return speed / 60 end

    local arm = self.arms and self.arms[ self.owner_pid ]
    if not arm then
        return 1 / 60
    else
        local speed = math.huge
        local hit = false
        for id, num in pairs(arm.live_soldier or {}) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                if speed > conf.Speed then
                    speed = conf.Speed
                    hit = true
                end
            end
        end
        if hit then
            local owner = get_ety( self.owner_eid )
            local union = unionmng.get_union(self.owner_uid)
            if is_ply( owner ) then
                if action == TroopAction.SiegeMonster or action == TroopAction.SiegeNpc or action == TroopAction.HoldDefense then
                    speed = speed * ( 1 + owner:get_num( "SpeedMarchPvE_R" ) * 0.0001 )
                elseif action == TroopAction.King then
                    speed = speed * ( 1 + owner:get_num( "SpeedMarch_R" ) * 0.0001 )
                elseif action == TroopAction.JoinMass then
                    speed = speed * ( 1 + ( owner:get_num( "SpeedMarch_R") + owner:get_num( "SpeedMarchMass_R") ) * 0.0001 )
                else
                    speed = speed * ( 1 + owner:get_num( "SpeedMarch_R") * 0.0001 )
                end
            end
            return speed / 60
        else
            return 10 / 60
        end
    end
end


function go(self, speed)
    self.action = self:get_base_action() + 100
    self:start_march(speed)
end

function settle(self)
    self.action = self:get_base_action() + 200
    if self.eid > 0 then
        rem_ety(self.eid)
        --self.eid = 0
    end
end

function back(self, delay)
    local action = self:get_base_action() + 300
    if self.is_mass ~= 1 then
        local owner = get_ety(self.owner_eid)
        if owner then
            if delay then 
                self.delay = gTime
                timer.new( "troop_back", delay, self._id )
            else
                self.action = action
                self.sx, self.sy = self.dx, self.dy
                self.dx, self.dy = get_ety_pos(owner)
                self:start_march()
            end
            return { [self.owner_pid] = self}
        end
    else
        troop_mng.delete_troop(self._id)
        if self:is_go() then c_rem_ety( self.eid ) end

        local target = get_ety(self.target_eid)
        local id = self._id
        local curx, cury = self.curx, self.cury
        local sx, sy = self.dx, self.dy

        local ts = {}
        for pid, arm in pairs(self.arms) do
            if pid > 0 then
                local ply = getPlayer(pid)
                if ply then
                    local troop = troop_mng.create_troop(action, ply, target, arm)
                    troop.curx, troop.cury = curx, cury
                    if delay then 
                        troop.delay = gTime
                        timer.new( "troop_back", delay, troop._id )
                        troop:notify_owner()
                    else
                        troop.sx, troop.sy = curx, cury
                        troop.dx, troop.dy = get_ety_pos(ply)
                        troop.flag = self.flag
                        troop:start_march()
                    end
                    ts[ pid ] = troop
                end
            end
        end
        return ts
    end
end

function home_hurt_tr(self) --伤兵直接回城

    if self.owner_pid == 0 then return end

    local arms = copyTab(self.arms or {})
    for pid, arm in pairs(arms or {}) do
        for k, v in pairs(arm.live_soldier or {}) do
             arm.live_soldier[k] = 0
        end
        arm.heros = {0,0,0,0}
    end

    convert_hurt(arms, 0.95)

    for pid, arm in pairs(arms or {}) do
        local owner = getPlayer(pid)
        if owner then
            owner:add_soldiers( arm.live_soldier or {} )
            local count_cure = owner:troop_cure(self, arms)

            for _, hid in pairs(arm.heros or {}) do
                if hid ~= 0 then
                    local h = heromng.get_hero_by_uniq_id(hid)
                    if h then
                        if h.status == HERO_STATUS_TYPE.MOVING then h.status = HERO_STATUS_TYPE.FREE end
                        if h.prisoner and h.prisoner ~= 0 then
                            local hero = heromng.get_hero_by_uniq_id(h.prisoner)
                            if hero then
                                if not owner:imprison(hero) then
                                    owner:release(hero)
                                end
                            end
                            h.prisoner = 0
                        end
                        h.troop = 0
                    end
                end
            end
        end

    end

    for k, arm in pairs(self.arms or {}) do
        arm.hurt_soldier = nil
        arm.dead_soldier = nil
    end
end


function home(self)
    local pid = self.owner_pid
    if pid == 0 then return end
    local owner = getPlayer(pid)
    if not owner then return end

    while true do
        local troop = self:split_one()
        if troop == self then break end
        troop:back()

        for bid, arm in pairs( self.arms or {} ) do
            if bid ~= pid then
                self.arms[ bid ] = nil
                local ply = getPlayer( bid )
                if ply then
                    ply:rem_busy_troop( self._id )

                    local target = get_ety(self.target_eid)
                    local troop = troop_mng.create_troop(self.action, ply, target, arm)
                    troop.curx = self.curx
                    troop.cury = self.cury
                    troop:back()
                end
            end
        end
    end

    troop_mng.delete_troop(self._id)

    if self.goods then
        dumpTab(self.goods, "troop_goods")
        owner:add_bonus("mutex_award", self.goods, self.goods_reason)
    end

    local arm = self.arms and self.arms[ pid ]
    if not arm then return end

    for _, hid in pairs(arm.heros or {}) do
        if hid ~= 0 then
            local h = heromng.get_hero_by_uniq_id(hid)
            if h then
                if h.status == HERO_STATUS_TYPE.MOVING then h.status = HERO_STATUS_TYPE.FREE end
                if h.prisoner and h.prisoner ~= 0 then
                    local hero = heromng.get_hero_by_uniq_id(h.prisoner)
                    if hero then
                        if not owner:imprison(hero) then
                            owner:release(hero)
                        end
                    end
                    h.prisoner = 0
                end
                h.troop = 0
            end
        end
    end
    owner:add_soldiers( arm.live_soldier )
    owner:troop_cure(self)

    for _, hid in pairs(arm.heros or {}) do
        if hid ~= 0 then
            local h = heromng.get_hero_by_uniq_id(hid)
            if h then
                if h.status == HERO_STATUS_TYPE.MOVING then h.status = HERO_STATUS_TYPE.FREE end
                if h.prisoner and h.prisoner ~= 0 then
                    local hero = heromng.get_hero_by_uniq_id(h.prisoner)
                    if hero then
                        if not owner:imprison(hero) then
                            owner:release(hero)
                        end
                    end
                    h.prisoner = 0
                end
                h.troop = 0
            end
        end
    end
end

--merge A to B
function merge(A, B)
    local armsB = B.arms
    if not armsB then
        armsB = {}
        B.arms = armsB
    end

    A.arms = A.arms or {}
    for pid, armA in pairs(A.arms) do
        A.arms[ pid ] = {}
        local armB = armsB[ pid ]
        if not armB then
            armsB[ pid ] = armA
            armA.tm_join = gTime
        else
            do_add_arm_to(armA, armB)
        end
    end

    for pid, _ in pairs( B.arms or {} ) do
        if pid >= 10000 then
            local ply = getPlayer(pid)
            if ply then
                B:notify_player(ply)
                if A.arms[ pid ] then
                    ply:add_busy_troop( B._id )
                end
            end
        end
    end
    troop_mng.delete_troop(A._id)
    B:save()
end

-- here, src, dst is means troop.arms[ Aid ], troop.arms[ Bid ]
function add_to(A, B)
    local armsB = B.arms
    if not armsB then
        armsB = {}
        B.arms = armsB
    end

    for pid, armA in pairs(A.arms or {}) do
        local armB = armsB[ pid ]
        if not armB then
            armsB[ pid ] = armA
        else
            do_add_arm_to(armA, armB)
        end
    end
end


function do_add_arm_to(src, dst)
    for k, v in pairs(src) do
        if not dst[ k ] then
            dst[ k ] = v
        else
            local node = dst[ k ]
            if k == "live_soldier" or k == "hurt_soldier" or k == "dead_soldier" then
                for id, num in pairs(v) do
                    node[ id ] = (node[ id ] or 0) + num
                end
            elseif k == "heros" then
                for idx, hid in pairs(v) do
                    if not node[ idx ] or node[ idx ] == 0 then
                        node[ idx ] = hid
                    else
                        table.insert(node, hid)
                    end
                end
            elseif k == "pid" then

            end
        end
    end
end

function add_arm(self, pid, arm)
    local tab = self.arms and self.arms[ pid ]
    if not tab then
        tab = self.arms
        if not tab then
            tab = {}
            self.arms = tab
        end
        tab = tab[ pid ]
        if not tab then
            tab = {pid=pid}
            self.arms[ pid ] = tab
        end
    end
    tab.pid = pid
    do_add_arm_to(arm, tab)
    self:save()
    return true
end


function add_to(A, B)
    local armsB = B.arms
    if not armsB then
        armsB = {}
        B.arms = armsB
    end

    for pid, armA in pairs(A.arms or {}) do
        local armB = armsB[ pid ]
        if not armB then
            armsB[ pid ] = armA
        else
            do_add_arm_to(armA, armB)
        end
    end
end

function get_arm_num(arm)
    local t = 0
    for id, num in pairs(arm.live_soldier or {}) do
        t = t + num
    end
    return t
end

function back_overflow_arm(self, num, hold_tr) --按个人驻守上限遣返
    local hold_arms = hold_tr.arms or {}
    for pid, arm in pairs(self.arms or {}) do
        local hold_arm = hold_arms[pid] or {}
        local hold_num = get_arm_num(hold_arm)
        local ply = getPlayer(pid)
        local count_soldier = 0
        if ply then
            count_soldier = ply:get_val("CountSoldier")
        end
        local left = count_soldier - hold_num
        local count = get_arm_num(arm)
        
        if left <= 0 then
            local tr = self:split_pid(pid)
            tr:back()
        else
            if (count - left) > 0 then
                if left > num then
                    local hold_arm = split_part_arm_and_back(self, pid, arm, (count - left + num), hold_tr)
                    self.arms[pid] = hold_arm
                    num = 0
                else
                    local tr = self:split_pid(pid)
                    tr:back()
                    num = num - left
                end
            else
                if count > num then
                    local hold_arm = split_part_arm_and_back(self, pid, arm, num, hold_tr )
                    self.arms[pid] = hold_arm
                    num = 0
                else
                    local tr = self:split_pid(pid)
                    tr:back()
                    num = num - count
                end
            end
        end
    end
end

function split_tr_by_num_and_back(self, num, hold_tr) -- 部队需要遣返的部队数量
    local hold_arms = hold_tr.arms or {}
    local single_tot_back_num = 0 --单个玩家的派遣上限遣返
    for pid, arm in pairs(self.arms or {}) do
        local hold_arm = hold_arms[pid] or {}
        local hold_num = get_arm_num(hold_arm)
        local ply = getPlayer(pid)
        local count_soldier = 0
        if ply then
            count_soldier = ply:get_val("CountSoldier")
        end
        local left = count_soldier - hold_num
        local count = get_arm_num(arm)
        if left <= 0 then
            single_tot_back_num = single_tot_back_num + count
        else
            if count >= left then
                single_tot_back_num = single_tot_back_num + count - left
            end
        end
    end

    if single_tot_back_num <= 0 and num <= 0 then
        self:try_back_overflow_hero(hold_tr)
        return
    end

    if single_tot_back_num < num then
        back_overflow_arm(self, num - single_tot_back_num, hold_tr)
    else
        back_overflow_arm(self, 0, hold_tr)
    end
end

function try_back_overflow_hero(self, hold_tr)
    for pid, arm in pairs(self.arms or {}) do
        local back_heros = {}
        for index, hero in pairs(arm.heros or {}) do
            if is_own_hero(hold_tr, pid, index) then
                back_heros[index] = hero
                arm.heros[index] = nil
            end
        end
        if get_table_valid_count(back_heros) > 0 then
            local owner = getPlayer(pid)
            local target = get_ety(self.target_eid)
            local tr = troop_mng.create_troop(self.action, owner, target)
            tr:add_arm(pid, {live_soldier = {}, heros = back_heros})
            tr.curx = self.curx
            tr.cury = self.cury
            tr:back()
        end
    end
end

function split_part_arm_and_back(self, pid, arm, num, hold_tr)

    local live_soldier = {}
    local live_heros = {0,0,0,0}
    local back_live_soldier = arm.live_soldier or {}
    local index = 0
    for id, count in pairs(arm.live_soldier or {}) do
        index = index + 1
        if count > num then
            live_soldier[id] = count - num

            if not is_own_hero(hold_tr, pid, index) then
                live_heros[index] = arm.heros[index]
                arm.heros[index] = nil
            end

            back_live_soldier[id] = num
            num = 0
        else
            live_soldier[id] = nil
            back_live_soldier[id] = count
            num = num - count
        end
    end

    arm.heros = arm.heros
    local back_arm = arm
    back_arm.live_soldier = back_live_soldier

    local remain_arm = {}
    remain_arm.heros = live_heros
    remain_arm.live_soldier = live_soldier
    remain_arm.kill_soldier = arm.kill_soldier
    remain_arm.pid = pid

    local owner = getPlayer(pid)
    local target = get_ety(self.target_eid)
    local tr = troop_mng.create_troop(self.action, owner, target, back_arm)
    tr.curx = self.curx
    tr.cury = self.cury
    tr:back()
    return remain_arm
end


function split_one(self)
    for pid, arm in pairs(self.arms or {}) do
        if pid ~= self.owner_pid then
            self.arms[ pid ] = nil
            local owner = getPlayer(pid)
            if owner then
                owner:rem_busy_troop(self._id)
                local target = get_ety(self.target_eid)
                local troop = troop_mng.create_troop(self.action, owner, target, arm)
                troop.curx = self.curx
                troop.cury = self.cury
                self:save()
                return troop
            end
        end
    end
    return self
end


function split_pid(self, pid)
    local arm = self.arms and self.arms[ pid ]
    if arm then
        if pid == self.owner_pid then
            local other = false
            for k, v in pairs(self.arms) do
                if k > 0 and k ~= pid then
                    other = getPlayer(k)
                    self.owner_eid = other.eid
                    self.owner_pid = other.pid
                    self.owner_uid = other.uid
                    break
                end
            end
        end

        self.arms[ pid ] = nil
        local owner = getPlayer(pid)
        owner:rem_busy_troop(self._id)

        local target = get_ety(self.target_eid)
        local troop = troop_mng.create_troop(self.action, owner, target, arm)
        troop.curx = self.curx
        troop.cury = self.cury

        for k, v in pairs( self.arms ) do
            if k > 0 then
                return troop
            end
        end
        troop_mng.delete_troop( self._id )
        self:save()

        return troop
    end
end

function start_march(self, default_speed)
    local have_eid = false
    if self.eid and self.eid > 0 then
        local ety = get_ety( self.eid )
        if not ety or ety == self then
            have_eid = true
        end
    end

    if not have_eid then self.eid = get_eid_troop() end

    local speed = default_speed or self:calc_troop_speed()
    local dist, zone = calc_distance( self.curx, self.cury, self.dx, self.dy )
    zone = zone or 0
    local use_time = math.ceil( dist / speed + zone / (speed * 0.1) )

    local in_black = is_in_black_land( self.curx, self.cury )

    self.speed0 = speed
    self.speed = speed
    self.tmStart = gTime
    self.tmOver = gTime + use_time
    self.tmCur = gTime
    self.propid = 11001001
    self.mcid = self.mcid or 0
    self.be_atk_list = self.be_atk_list or {}

    local arminfo = {0,0,0,0}
    local heros = {0,0,0,0}
    for _, arm in pairs(self.arms or {}) do
        for id, num in pairs(arm.live_soldier or {}) do
            local mode = math.floor(id / 1000)
            arminfo[ mode ] = arminfo[ mode ] + num
        end

        for mode, id in pairs( arm.heros or {} ) do
            if id ~= 0 then
                if type( id ) == "number" then
                    local h = resmng.prop_hero[ id ]
                    if h then heros[ mode ] = h.id end
                else
                    local h = heromng.get_hero_by_uniq_id( id )
                    if h then heros[  mode ] = h.propid end
                end
            end
        end
    end
    self.soldier_num = arminfo
    self.heros = heros

    if in_black then self.speed = speed * 0.1 end

    local owner = get_ety(self.owner_eid)
    local target = get_ety(self.target_eid)
    if target then
        self.target_propid = target.propid
    elseif self.action == TroopAction.Camp + 100 then
        self.target_propid = resmng.CAMP_WEST_1
    end

    self.alias = ""
    if is_ply( owner ) then
        local u = owner:get_union()
        if u then
            self.alias = u.alias
        end
    end
    etypipe.add(self)

    c_add_actor(self.eid, self.curx, self.cury, self.dx, self.dy, gTime, self.speed)
    gEtys[self.eid] = self

    self.speed = speed

    self:save()
    self:notify_owner()

    if is_npc_city(owner) then
        if self.owner_uid == 0 then
            local union = unionmng.get_union(owner.uid)
            if union then
                union.act_mc_tag = gTime
            end
        else
            npc_city.act_tag = gTime
        end
    end

    if is_lost_temple(owner) then
        lost_temple.act_tag = gTime
    end

    if is_king_city(owner) then
        king_city.act_tag = gTime
    end

    if (is_npc_city(owner) or is_lost_temple(owner) or is_king_city(owner) or is_monster_city(owner) or is_monster(owner) ) and owner ~= target then
        monster_city.add_leave_troop(owner, self._id)
    end

    if (is_npc_city(target) or is_lost_temple(target) or is_king_city(target) or is_monster_city(target) or is_monster(target)) and owner ~= target then
        monster_city.add_atk_troop(target, self._id)
    end

    self:add_link()
    
    monitoring(MONITOR_TYPE.TROOP)
end


function notify_owner(self)
    local info
    if self.delete then
        info = {_id = self._id, delete = true }
    else
        info = self:get_info()
    end
    local pids = {}
    if not next(self.arms or {})then
        table.insert(pids, self.owner_pid)
    else
        for pid, _ in pairs(self.arms) do table.insert(pids, pid) end
    end
    print( "notify_owner", self._id )
    Rpc:stateTroop(pids, info)
end

function notify_player(self, ply)
    local info
    if self.delete then
        info = {_id = self._id, delete = true }
    else
        info = self:get_info()
    end
    Rpc:stateTroop(ply, info)
end

function mount_bonus(troop, tab, reason)
    if tab == nil or troop == nil then
        return
    end
    if reason == nil then
        ERROR("mount_bonus wrong!! no reason, troop_id:%d", troop._id)
    end
    troop:add_goods(tab,reason)
end


function set_extra(self, key, val)
    self.extra[key] = val
    self:save()
end

function get_extra(self, key)
    return self.extra[key]
end

function clr_extra(self, key)
    self.extra[key] = nil
    self:save()
end

function add_tr_ef(self, bufid)
    WARN( "add_tr_buf, tr_id=%d, buf=%d", self._id, bufid)
    local t = self.ef_extra or {}
    local node = resmng.prop_buff[ bufid ]
    if node then
        if node.Value then 
            for k, v in pairs(node.Value) do
                t[k] = (t[k] or 0) + v
                LOG( "ef_add, tr_id=%d, k=%s, v=%s", self._id, k, v )
            end
        end
    end
    print(string.format("add_tr_buf, bufid=%d", bufid))
    self.ef_extra = t
end

function rem_tr_ef(self, bufid)
    WARN( "rem_tr_buf, tr_id=%d, buf=%d", self._id, bufid)
    local t = self.ef_extra or {}
    local node = resmng.prop_buff[bufid]
    if node then
        if node.Value then
            for k, v in pairs(node.Value) do
                t[k] = (t[k] or 0) - v
                if math.abs(t[k]) <= 0.00001 then t[k] = nil end
                LOG( "ef_rem, tr_id=%d, k=%s, v=%s", self._id, k, v )
            end
        end
    end
    print(string.format("rem_tr_buf, bufid=%d", bufid))
    self.ef_extra = t
end

function clear_tr_ef(self)
    self.ef_extra = nil
end

function get_ef(self)
    local ef = {}
    local owner = self.owner_pid
    if owner <= 0 then return ef end
    local arm = self.arms[ owner ]
    if not arm or (not arm.heros) then return ef end
    for idx = 1, 4, 1 do
        local heroid = arm.heros[ idx ]
        if heroid ~= 0 then
            local hero = heromng.get_hero_by_uniq_id(heroid)
            if hero then
                local _ef = hero:get_ef()
                if _ef then
                    for k, v in pairs(_ef) do
                        ef[ k ] = (ef[ k ] or 0) + v
                    end
                end
            end
        end
    end

    for _, b in pairs(self.bufs or {}) do
        local id = b[1]
        local over = b[2]
        if over == 0 or over > gTime then
            local conf = resmng.get_conf("prop_buff", id)
            if conf then
                for k, v in pairs(conf.Value) do
                    ef[ k ] = (ef[k] or 0) + v
                end
            end
        end
    end
    return ef
end


function get_info(self)
    local info = { _id = self._id, eid = self.eid, tmStart = self.tmStart, tmOver = self.tmOver, action = self.action, dx=self.dx, dy=self.dy, sx=self.sx, sy=self.sy, target=self.target_eid }
    local arms = {}
    local heros = {}
    for pid, arm in pairs( self.arms or {} ) do
        arms[ pid ] = arm.live_soldier or {}
        local hs = {}
        if pid >= 10000 then
            for k, v in pairs( arm.heros or {} ) do
                if v ~= 0 then
                    local h = heromng.get_hero_by_uniq_id( v )
                    if h then
                        hs[ k ] = { h.propid, h.lv, h.star }
                    end
                end
            end
        else
            for k, v in pairs( arm.heros or {} ) do
                if v ~= 0 then hs[k] = v end
            end
        end
        heros[ pid ] = hs
    end
    info.arms = arms
    info.heros = heros
    info.extra = self.extra or {}

    local owner = get_ety( self.owner_eid )
    if owner then
        if is_ply( owner ) then
            info.name = owner.name
            local union = owner:get_union()
            if union then
                info.alias = union.alias
            end

        elseif owner.propid then
            info.propid = owner.propid
        end
    else
        WARN( "troop_no_onwer, id=%d, action=%d, owner_eid=%d, owner_pid=%d, ", self._id, self.action, self.owner_pid )
    end

    if self.status == TroopStatus.Moving then
        info.curx = self.curx
        info.cury = self.cury
        info.tmCur = self.tmCur
    end
    return info
end

function is_empty(self)
    for k, v in pairs(self.arms or {}) do
        return false
    end
    return true
end

function get_tr_pow(self)
    local pow = 0
    for k, v  in pairs(self.arms) do
        pow = pow + calc_pow(self, k)
    end
    return pow
end

function calc_pow(self, pid)
    local pow = 0
    local arm = self.arms and self.arms[ pid ]
    if arm then
        local prop_arm = resmng.prop_arm
        if arm.live_soldier then
            for id, num in pairs(arm.live_soldier) do
                local prop = prop_arm[ id ]
                if prop and prop.Pow then
                    pow = pow + (prop.Pow or 0) * num
                else
                    Mark("calc_pow, id = %d", id)
                    dumpTab(self, "calc_pow_error")
                end
            end
        end
    end
    return pow
end


function lost_pow(self, pid)
    local pow = 0
    local arm = self.arms and self.arms[ pid ]
    if arm then
        local prop_arm = resmng.prop_arm
        if arm.dead_soldier then
            for id, num in pairs(arm.dead_soldier) do
                local prop = prop_arm[ id ]
                if prop and prop.Pow then
                    pow = pow + (prop.Pow or 0) * num
                else
                    Mark("calc_pow, id = %d", id)
                    dumpTab(self, "calc_pow_error")
                end
            end
        end
    end
    return pow
end

function add_soldier(self, id, num)
    local arms = self.arms
    if not arms then
        arms = {}
        self.arms = {}
    end

    local pid = self.owner_pid
    local arm = arms[ pid ]
    if not arm then
        arm = {}
        arms[ pid ] = arm
    end

    local live = arm.live_soldier
    if not live then
        live = {}
        arm.live_soldier = live
    end

    live[ id ] = (live[ id ] or 0) + num
end

function rem_soldier(self, id, num)
    local arms = self.arms
    if not arms then return end

    local pid = self.owner_pid
    local arm = arms[ pid ]
    if not arm then return end
    local live = arm.live_soldier
    if not live then return end
    
    if live[ id ] and live[ id ] >= num then 
        live[ id ] = live[ id ] - num
        if live[ id ] <= 0 then live[ id ] = nil end
        return true
    end
end



function add_soldiers( self, soldiers ) 
    local arms = self.arms
    if not arms then
        arms = {}
        self.arms = {}
    end

    local pid = self.owner_pid
    local arm = arms[ pid ]
    if not arm then
        arm = {}
        arms[ pid ] = arm
    end

    local live = arm.live_soldier
    if not live then
        live = {}
        arm.live_soldier = live
    end

    local count = 0
    for id, num in pairs( soldiers ) do
        live[ id ] = ( live[ id ] or 0 ) + num
        count = count + num
        soldiers[ id ] = 0
    end
    return count
end


function get_live(self, pid)
    pid = pid or self.owner_pid
    local arms = self.arms
    if not arms then return {} end

    local arm = arms[ pid ]
    if not arm then return {} end

    local live = arm.live_soldier
    if not live then return {} end

    return live
end

function is_action(self, action)
    return self:is_settle() and self:get_base_action() == action
end

function get_gather_power(self, mode)
    local troop = self
    local ply = getPlayer(self.owner_pid)
    if not ply then return end

    local lv = c_get_zone_lv(math.floor(troop.dx/16), math.floor(troop.dy/16))
    if lv > 5 then lv = 5 end
    if lv < 1 then lv = 1 end
    local speed_gather = SPEED_GATHER[ lv ]
    local speed_base = speed_gather

    local count_gather = 0
    for _, arm in pairs(troop.arms) do
        for id, num in pairs(arm.live_soldier) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                count_gather = count_gather + conf.Weight * num
            end
        end
    end

    local key = string.format("SpeedGather%d_R", mode)
    local mul = resmng.get_conf("prop_resource", mode).Mul
    local div = mul * 3600

    speed_gather = speed_gather * (1 + ( ply:get_num( key ) + ply:get_num( "SpeedGather_R" )) * 0.0001 ) / div
    count_gather = count_gather * (1 + ply:get_num( "CountWeight_R") * 0.0001 ) / mul
    return speed_gather, count_gather, speed_base / div
end


function recalc(self)
    if self:is_action(TroopAction.Gather) then
        local start = self:get_extra("start") or gTime
        local speed = self:get_extra("speed") or 0
        local cache = self:get_extra("cache") or 0

        cache = cache + (gTime - start) * speed

        local mode = self:get_extra("mode") or 1
        local speed, count, speedb = self:get_gather_power( mode )

        print( string.format( "gather, speed = %s, count = %s", speed, count ) )

        self:set_extra("count", count)
        self:set_extra("start", gTime)
        self:set_extra("cache", cache)
        self:set_extra("speed", speed)
        self:set_extra("speedb", speedb)
    end
end


function recalc_gather( troop )
    local dest = get_ety( troop.target_eid )
    if not dest then return end

    if is_union_building(dest) then
        troop:recalc()
        local dura = math.ceil( (troop:get_extra("count") - troop:get_extra("cache")) / troop:get_extra("speed") )
        troop.tmOver = gTime + dura
        troop.tmSn = timer.new("troop_action", dura, troop._id)
        save_ety(dest)
        troop:notify_owner()

    else
        local speed = troop:get_extra("speed")
        local start = troop:get_extra("start")
        local gain = math.floor( (gTime - start) * speed )
        dest.val = math.floor( dest.val - gain )

        if dest.val > gain then
            dest.val = math.floor( dest.val - gain )
            troop:recalc()
            local speed = troop:get_extra("speed")
            local dura = math.min(dest.val, troop:get_extra("count") - troop:get_extra("cache")) / speed
            dura = math.ceil(dura)
            troop.tmOver = gTime + dura
            troop.tmSn = timer.new("troop_action", dura, troop._id)
            dest.extra = {speed=speed, start=gTime, count=dest.val, tm=gTime, tid=troop._id}
            etypipe.add(dest)
            troop:notify_owner()
        else
            troop_mng.gather_stop( troop, dest )
        end
    end
end


function add_goods(self, goods, reason)
    self.goods = goods
    self.goods_reason = reason
    self:save()
end


function get_troop_total_soldier(self)
    local t = 0
    for pid, arm in pairs(self.arms) do
        for id, num in pairs(arm.live_soldier or {}) do
            t = t + num
        end
    end
    return t
end


function is_no_player(self)

end

function is_empty(self)
    return table_count(self.arms or {}) == 0
end

function apply_dmg( self, dmg )
    local nodes = {}
    local total = 0
    local ptab = resmng.prop_arm
    for pid, arm in pairs( self.arms or {} ) do
        if arm.live_soldier then
            local pow = 0
            local lives = arm.live_soldier
            if lives then
                for id, num in pairs( arm.live_soldier or {}) do
                    local conf = ptab[ id ]
                    if conf then
                        local pow = conf.Pow * num
                        total = total + pow
                        table.insert( nodes, { pow, arm, lives, id, conf.Hp } )
                    end
                end
            end
        end
    end

    local r = dmg / total
    for _, v in pairs( nodes ) do
        local pow = v[1]
        local hit = pow * r
        local dead = math.ceil( hit / v[ 5 ] )

        local arm = v[2]
        local lives = v[3]
        local id = v[4]
        lives[ id ] = lives[ id ] - dead

        local kill = arm.kill_soldier
        if not kill then
            kill = {}
            arm.kill_soldier = kill
        end
        kill[ id ] = (kill[ id ] or 0) + dead
    end
    self:save()
end

function has_alive( self )
    for _, arm in pairs( self.arms or {} ) do
        for id, num in pairs( arm.live_soldier or {} ) do
            if num > 0 then return true end
        end
    end
    return false
end

function dead_to_hurt( self, rate, who )
    rate = rate or 1
    if not who then who = self.owner_pid end
    for pid, arm in pairs( self.arms or {} ) do
        if pid == who then
            local dead = arm.dead_soldier
            if not dead then return end

            local hurt = arm.hurt_soldier
            if not hurt then
                hurt = {}
                arm.hurt_soldier = hurt
            end

            for k, v in pairs( dead ) do
                local d2h = math.floor( v * rate )
                if d2h > 0 then
                    dead[ k ] = v - d2h
                    hurt[ k ] = ( hurt[ k ] or 0 ) + d2h
                end
            end
        end
    end
end

function dead_to_live_and_hurt( self, rate )
    return convert_hurt(self.arms or {}, rate)
end

function convert_hurt(arms, rate)
    local result = {}
    rate = rate or 1
    local prop_arm = resmng.prop_arm
    for pid, arm in pairs( arms or {} ) do
        local nlive = 0
        local nhurt = 0
        local nlost = 0

        local dead = arm.dead_soldier
        if not dead then
            dead = {}
            arm.dead_soldier = dead
        end

        local hurt = arm.hurt_soldier
        if not hurt then
            hurt = {}
            arm.hurt_soldier = hurt
        end

        local live = arm.live_soldier
        if not live then
            live = {}
            arm.live_soldier = live
        end

        for id, num in pairs( live ) do
            local ndead = dead[ id ]
            if ndead and ndead > 0 then
                local n1 = math.floor( ndead * rate )
                local n2 = ndead - n1
                hurt[ id ] = (hurt[ id ] or 0) + n2
                nhurt = nhurt + n2
                live[ id ] = live[ id ] + n1
                nlost = nlost + prop_arm[ id ].Pow * n2
            end
            nlive = nlive + live[ id ]
        end
        result[ pid ] = { live=nlive, hurt=nhurt, lost = nlost }
        arm.dead_soldier = {}

        for mode, id in pairs( arm.heros or {} ) do
            if id ~= 0 then
                local h = heromng.get_hero_by_uniq_id( id )
                if h and h.lost then
                    h.hp = math.floor( h.hp +  h.lost * rate )
                    if h.hp < 0 then h.hp = 0 end
                    if h.hp > h.max_hp then h.hp = h.max_hp end
                    h.lost = nil
                end
            end
        end
    end
    return result
end

function acc_march(troop, ratio)
    if troop:is_go() or troop:is_back() then

        local curx, cury = c_get_actor_pos(troop.eid)
        if not curx then return end
        --local remain = calc_line_length(curx, cury, troop.dx, troop.dy)

        local speed = troop.speed * ratio
        local dist, zone = calc_distance( curx, cury, troop.dx, troop.dy )
        zone = zone or 0
        local use_time = math.ceil( dist / speed + zone / (speed * 0.1) )

        troop.curx = curx
        troop.cury = cury
        troop.tmCur = gTime
        troop.speed = speed
        troop.tmOver = math.ceil(gTime + use_time)

        local chg = gPendingSave.troop[ troop._id ]
        chg.curx    = troop.curx
        chg.cury    = troop.cury
        chg.tmCur   = troop.tmCur
        chg.tmOver  = troop.tmOver
        chg.speed   = troop.speed

        c_add_actor(troop.eid, troop.curx, troop.cury, troop.dx, troop.dy, gTime, troop.speed)
        etypipe.add(troop)
        troop:notify_owner()
        player_t.update_watchtower_speed(troop)

        --troop:save()
    end
end

function enter_black_zone( troop )
    if troop:is_go() or troop:is_back() then
        local curx, cury = c_get_actor_pos(troop.eid)
        if not curx then return end

        local speed = troop.speed
        troop.speed = speed * 0.1
        troop.curx = curx
        troop.cury = cury
        troop.tmCur = gTime
        c_add_actor(troop.eid, troop.curx, troop.cury, troop.dx, troop.dy, gTime, troop.speed)
        etypipe.add(troop)
        troop.speed = speed
    end
end

function leave_black_zone( troop )
    if troop:is_go() or troop:is_back() then
        local curx, cury = c_get_actor_pos(troop.eid)
        if not curx then return end
        troop.curx = curx
        troop.cury = cury
        troop.tmCur = gTime
        c_add_actor(troop.eid, troop.curx, troop.cury, troop.dx, troop.dy, gTime, troop.speed)
        etypipe.add(troop)
    end
end


function is_pvp( troop )
    if troop:is_back() then return false end

    local action = troop:get_base_action()
    if  action == TroopAction.SiegePlayer or
        action == TroopAction.Spy or
        action == TroopAction.SiegeCamp or
        action == TroopAction.SiegeNpc or
        action == TroopAction.King or
        action == TroopAction.SiegeUnion then
        return true
    end

    if action == TroopAction.JoinMass then
        local tid = troop.dest_troop_id
        local troopD = troop_mng.get_troop( tid )
        if troopD then
            action = troopD:get_base_action()
            if  action == TroopAction.SiegePlayer or
                action == TroopAction.Spy or
                action == TroopAction.SiegeCamp or
                action == TroopAction.SiegeNpc or
                action == TroopAction.King or
                action == TroopAction.SiegeUnion then
                return true
            end
        end
    end

    if action == TroopAction.Gather then
        local D = get_ety( troop.target_eid )
        if D and is_res( D ) then
            if D.pid > 0 then
                if not (troop.owner_uid > 0 and troop.owner_uid == D.uid) then return true end
            end

            local comings = D.troop_comings
            if comings then
                for tid, _ in pairs( comings ) do
                    local troopD = troop_mng.get_troop( tid )
                    if troopD then
                        if not (troop.owner_uid > 0 and troop.owner_uid == troopD.owner_uid) then
                            if troop:is_go() then
                                if troop.tmStart > troopD.tmStart then return true end
                            elseif troop:is_ready() then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

function is_robot_troop(self)
    for pid, arm in pairs(self.arms or {}) do
        if pid == 0 then
            return true
        end
    end
    return false
end

function is_own_hero(self, pid, idx)
    local arms = self.arms or {}
    local arm = arms[pid]
    if arm then
        local heros = arm.heros or {}
        if heros[idx] then
            if heros[idx] ~= 0 then
                return true
            end
        end
    end
    return false
end

function get_arm_by_pid(self, pid)
    return self.arms[pid]
end

