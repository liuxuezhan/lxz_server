module("troop_t", package.seeall)

gPendingNotify = gPendingNotify or {}

__troop_mt = {__index = troop_t}
function new()
    local obj = {}
    setmetatable(obj, __troop_mt)
    obj:init()
    return obj
end

function wrap( data )
    return setmetatable(data, __troop_mt)
end

function load_data(data)
    setmetatable(data, __troop_mt)
end

function add_link( self )
    if self:is_go() or ( self.is_mass == 1 and self:is_ready() ) then
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
                if dest.on_troop_coming then dest:on_troop_coming( self ) end

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
                            if A.on_troop_coming then A:on_troop_coming( self ) end
                        end
                    end
                end
            end
        end
    elseif self:is_back() then
        local owner = get_ety( self.owner_eid )
        if is_ply( owner ) then
            local target = get_ety( self.target_eid )
            if target then
                owner:detach_ety( target )
            end
        end
    end
end


function save(self)
    local action = self:get_base_action()
    if action ~= TroopAction.Monster then
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
    local speed = 1
    local node = resmng.get_conf( "prop_troop_action", action )
    if node then
        if node.Default and node.Default > 0 then
            speed = node.Default
        else
            local arm = self.arms and self.arms[ self.owner_pid ]
            if arm then
                local hit = 0
                local min_speed = math.huge
                for id, num in pairs(arm.live_soldier or {}) do
                    if num > 0 then
                        local conf = resmng.get_conf("prop_arm", id)
                        if conf then
                            if conf.Speed < min_speed then
                                min_speed = conf.Speed
                                hit = 1
                            end
                        end
                    end
                end

                if arm.amend and arm.amend.relive then
                    for id, num in pairs(arm.amend.relive or {}) do
                        if num > 0 then
                            local conf = resmng.get_conf("prop_arm", id)
                            if conf then
                                if conf.Speed < min_speed then
                                    min_speed = conf.Speed
                                    hit = 1
                                end
                            end
                        end
                    end
                end


                if hit == 1 then
                    speed = min_speed
                    local owner = get_ety( self.owner_eid )
                    if owner and is_ply( owner ) then
                        if node.SpeedMarch > 0    then speed = speed * ( 1 + owner:get_num( "SpeedMarch_R" ) * 0.0001 ) end
                        if node.SpeedMarchPvE > 0 then speed = speed * ( 1 + owner:get_num( "SpeedMarchPvE_R" ) * 0.0001 ) end
                        if node.SpeedRally > 0    then speed = speed * ( 1 + owner:get_num( "SpeedRally_R" ) * 0.0001 ) end
                        if node.SpeedCavaran > 0  then speed = speed * ( 1 + owner:get_num( "SpeedCavaran_R" ) * 0.0001 ) end

                        if node.SpeedMarch > 0 then
                            if owner:get_buf( resmng.BUFF_SPEED_TROOP ) then
                                self.state = set_bit( self.state, TroopState.TurboSpeed )
                            end
                        end
                    end
                end
            end
        end
    end
    return speed / 60
end


function go(self, speed)
    if self.is_mass ~= 1 and self.owner_pid >= 10000 then
        local owner = getPlayer( self.owner_pid )
        if owner and owner:is_shell() then
            if self:is_pvp() then
                owner:rem_buf( resmng.BUFF_SHELL )
            end
        end
    end

    self.action = self:get_base_action() + 100
    self:start_march(speed)
end

function settle(self)
    self.action = self:get_base_action() + 200
    if self.eid > 0 then
        --rem_ety(self.eid)
        gEtys[ self.eid ] = nil
        --self.eid = 0
    end
end

function get_pos( self )
    if self:is_ready() then
        return self.sx, self.sy

    elseif self:is_go() then
        local x, y = c_get_actor_pos( self.eid )
        if not x then return self.dx, self.dy
        else return x, y end

    elseif self:is_settle() then
        return self.dx, self.dy

    elseif self:is_back() then
        local x, y = c_get_actor_pos( self.eid )
        if not x then return self.dx, self.dy
        else return x, y end

    end
end

function is_multiple( self )
    local count = 0
    for pid, arm in pairs( self.arms or {} ) do
        if pid >= 10000 then
            count = count + 1
            if count > 1 then return true end
        end
    end
end

g_no_arm_troop = {
    [ TroopAction.Spy ] = 1,
    [ TroopAction.SaveRes ] = 1,
    [ TroopAction.GetRes ] = 1,
    [ TroopAction.Declare ] = 1,
    [ TroopAction.SupportRes ] = 1,
    [ TroopAction.VisitHero ] = 1,
    [ TroopAction.VisitNpc ] = 1,
}

function back( self )

    if is_multiple( self ) then
        troop_mng.delete_troop(self._id)
        if self:is_go() then c_rem_ety( self.eid ) end

        local action = self.action
        local target = get_ety(self.target_eid)
        local curx, cury = self:get_pos()
        local flag = self.flag
        local fid = self.fid

        local ts = {}
        for pid, arm in pairs( self.arms or {} ) do
            if pid >= 10000 then
                local ply = getPlayer( pid )
                if ply then
                    local one = troop_mng.create_troop( action, ply, target, arm )
                    one.fid = fid
                    one.curx, one.cury = curx, cury
                    one.flag = flag
                    if not target then one.target_propid = self.target_propid end
                    one:back()
                    ts[ pid ] = one
                end
            end
        end
        return ts
    end

    local bs_action = self:get_base_action()
    self.action = bs_action + 300

    local owner = get_ety( self.owner_eid )
    local target = get_ety( self.target_eid )

    --self.curx, self.cury = curx, cury

    local x, y = c_get_actor_pos( self.eid )
    if x then self.curx, self.cury = x, y end

    --if target then self.sx, self.sy = get_ety_pos( target )
    --else self.sx, self.sy = self.curx, self.cury end

    if self.curx and self.cury then
        self.sx, self.sy = self.curx, self.cury
    else
        if target then self.sx, self.sy = get_ety_pos( target ) end
    end
    self.dx, self.dy = get_ety_pos( owner )

    if not g_no_arm_troop[ bs_action ] then
        if self:check_no_arm() then
            if self:check_no_hero() then
                troop_mng.delete_troop( self._id )
                return {}
            else
                self.action = TroopAction.HeroBack + 300
            end
        end
    end

    self:start_march()

    return { [self.owner_pid]= self }
end

function home(self)
    local pid = self.owner_pid
    if pid == 0 then return end

    local owner = getPlayer(pid)
    if not owner then return end

    local troopid = self._id

    for bid, arm in pairs( self.arms or {} ) do
        if bid ~= pid then
            self.arms[ bid ] = nil
            local ply = getPlayer( bid )
            if ply then
                ply:rem_busy_troop( troopid )
                Rpc:stateTroop(ply, {_id=troopid, delete=true})
                local troop = troop_mng.create_troop( TroopAction.JoinMass, ply, owner, arm )
                troop.curx, troop.cury = get_ety_pos( owner )
                troop:back()
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
                if h.status == HERO_STATUS_TYPE.MOVING then owner:hero_set_free( h )  end
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
    if arm.amend then
        if arm.amend.relive then
            owner:add_soldiers( arm.amend.relive )
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

function try_make_leader(self, enter_tr)
    if self:check_no_hero() then
        if not enter_tr:check_no_hero() then
            self.owner_pid = enter_tr.owner_pid
        end
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
            tr.fid = self.fid
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
            back_live_soldier[id] = num
            num = 0
        else
            live_soldier[id] = nil
            back_live_soldier[id] = count
            num = num - count
        end
    end

    if not is_own_hero(hold_tr, pid) then
        for index , v in pairs(arm.heros or {}) do
            live_heros[index] = v
            arm.heros[index] = nil
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
    local owner_pid = self.owner_pid
    for pid, arm in pairs(self.arms or {}) do
        if pid ~= owner_pid then
            self.arms[ pid ] = nil
            self:save()

            local owner = getPlayer(pid)
            if owner then
                owner:rem_busy_troop(self._id)
                Rpc:stateTroop(owner, {_id=self._id, delete=true})

                local target = get_ety(self.target_eid)
                local troop = troop_mng.create_troop(self.action, owner, target, arm)
                troop.curx = self.curx
                troop.cury = self.cury
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
                if k >= 10000 and k ~= pid then
                    other = getPlayer(k)
                    self.owner_eid = other.eid
                    self.owner_pid = other.pid
                    self.owner_uid = other.uid
                    break
                end
            end
        end

        self.arms[ pid ] = nil
        self:save()

        local troop = false
        local owner = getPlayer(pid)
        if owner then
            owner:rem_busy_troop(self._id)
            Rpc:stateTroop(owner, {_id=self._id, delete=true})

            local target = get_ety(self.target_eid)
            troop = troop_mng.create_troop(self.action, owner, target, arm)
            troop.fid = self.fid
            troop.curx = self.curx
            troop.cury = self.cury
        end

        for k, v in pairs( self.arms ) do
            if k >= 10000 then
                return troop
            end
        end

        if self.action ~= TroopAction.DefultFollow then troop_mng.delete_troop( self._id ) end
        return troop
    end
end


function check_no_arm(self)
    local ret = true
    for _, arm in pairs(self.arms or {}) do
        for id, num in pairs(arm.live_soldier or {}) do
            if num > 0 then
                return false
            end
        end

        local amend = arm.amend
        if amend then
            for id, num in pairs( amend.relive or {} ) do
                if num > 0 then
                    return false
                end
            end
        end
    end
    return ret
end

function check_no_hero(self)
    local ret = true
    for _, arm in pairs(self.arms or {}) do
        for mode, id in pairs( arm.heros or {} ) do
            if id ~= 0 then
                return false
            end
        end
    end
    return ret
end

function start_march(self, default_speed)
    if self.eid and get_ety( self.eid ) == self then

    else
        self.eid = get_eid_troop()
    end

    self.curx = self.curx or self.sx
    self.cury = self.cury or self.sy

    local speed = default_speed or self:calc_troop_speed()

    local dist = c_calc_distance( self.curx, self.cury, self.dx, self.dy )
    local use_time = dist / speed

    self.speed0 = speed
    self.speed = speed
    self.tmStart = gTime
    self.use_time = use_time
    self.tmOver = math.ceil( gTime + use_time )
    self.tmCur = gTime
    self.propid = 11001001
    self.mcid = self.mcid or 0
    self.be_atk_list = self.be_atk_list or {}

    local arminfo = {0,0,0,0}
    local heros = {0,0,0,0}
    for _, arm in pairs(self.arms or {}) do
        for id, num in pairs(arm.live_soldier or {}) do
            local mode = math.floor(id / 1000) % 10
            arminfo[ mode ] = arminfo[ mode ] + num
        end

        local relive = arm.amend and arm.amend.relive
        if relive then
            for id, num in pairs( relive or {} ) do
                local mode = math.floor(id / 1000) % 10
                arminfo[ mode ] = arminfo[ mode ] + num
            end
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

    local owner = get_ety(self.owner_eid)
    if owner then
        self.owner_propid = owner.propid
        if is_ply( owner ) then
            self.name = owner.name
            local u = owner:get_union()
            if u then
                self.alias = u.alise
                if u:is_mobilize() then 
                    self.state = set_bit( self.state, TroopState.Mobilize )
                end
            end
        end
    end

    local target = get_ety(self.target_eid)
    if target then
        self.target_propid = target.propid
        if is_ply( target ) then
            self.target_name = target.name
            local u = target:get_union()
            if u then
                self.target_alias = u.alias
            end
        else
            if target.pid and target.pid >= 10000 then
                local ply = getPlayer( target.pid )
                if ply then
                    self.target_name = ply.name
                    local u = ply:get_union()
                    if u then self.target_alias = u.alias end
                end

            elseif target.uid then
                local u = unionmng.get_union( target.uid )
                if u then self.target_alias = u.alias end
            end
        end

    elseif self:get_base_action() == TroopAction.Camp then
        if is_ply( owner ) then
            self.target_propid = CLASS_UNIT.Camp * 1000000 + owner.culture * 1000 + 1
        end
    end

    self.fid = self.fid or 0
    self.alias = ""
    if is_ply( owner ) then
        local u = owner:get_union()
        if u then
            self.alias = u.alias
        end
    end
    gEtys[self.eid] = self
    etypipe.add(self)

    --print( "start_march", self.sx, self.sy, self.dx, self.dy, self.speed, self.action )
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


function do_notify_owner(self, chgs)
    local pids = {}
    if not next(self.arms or {}) then
        if self.owner_pid >= 10000 then table.insert(pids, self.owner_pid) end
    else
        for pid, _ in pairs(self.arms) do
            if pid >= 10000 then table.insert(pids, pid) end
        end
    end

    if #pids > 0 then
        local info
        if self.delete then
            info = {_id = self._id, delete = true }
        else
            if chgs then
                info = chgs
                info._id = self._id
            else
                info = self:get_info()
            end
        end
        Rpc:stateTroop(pids, info)
    end
end


function notify_owner(self, info)
    gPendingNotify[ self._id ] = self
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
    local info = { _id = self._id, eid = self.eid, tmStart = self.tmStart, tmOver = self.tmOver, action = self.action, dx=self.dx, dy=self.dy, sx=self.sx, sy=self.sy, target=self.target_eid, is_mass=self.is_mass}
    local arms = {}
    local heros = {}
    for pid, arm in pairs( self.arms or {} ) do
        local node = arm.live_soldier or {}

        if arm.amend and arm.amend.relive then
            node = copyTab( node )
            for id, num in pairs( arm.amend.relive ) do
                node[ id ] = ( node[ id ] or 0 ) + num
            end
        end
        arms[ pid ] = node

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
        info.propid = owner.propid
        if is_ply( owner ) then
            info.name = owner.name
            local union = owner:get_union()
            if union then
                info.alias = union.alias
            end
        end
    else
        WARN( "troop_no_onwer, id=%d, action=%d, owner_eid=%d, owner_pid=%d, ", self._id, self.action, self.owner_eid, self.owner_pid )
    end

    if self:is_go() or self:is_back() then
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

function calc_dmg(self, pid)
    local pow = 0
    local arm = self.arms and self.arms[ pid ]
    if arm then
        local prop_arm = resmng.prop_arm
        if arm.kill_soldier_soldier then
            for id, num in pairs(arm.kill_soldier) do
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
                end
            end

        end

        local amend = arm.amend and arm.amend.relive
        if amend then
            for id, num in pairs( amend ) do
                local prop = prop_arm[ id ]
                if prop and prop.Pow then
                    pow = pow + (prop.Pow or 0) * num
                end
            end
        end
    end
    return pow
end

function calc_left_pow(self, pid)
    local pow = 0
    local arm = self.arms and self.arms[ pid ]
    if arm then
        local prop_arm = resmng.prop_arm
        if arm.live_soldier then
            for id, num in pairs(arm.live_soldier) do
                local prop = prop_arm[ id ]
                if prop and prop.Pow then
                    pow = pow + (prop.Pow or 0) * num
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
    if num < 1 then return end
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
        if num > 0 then
            live[ id ] = ( live[ id ] or 0 ) + num
            count = count + num
        end
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

    local ef = self:get_ef()
    local u_ef = {}
    local obj = get_ety( troop.target_eid )
    if obj and is_union_superres(obj.propid) then
        local c = resmng.get_conf("prop_world_unit",obj.propid)
        u_ef = c.Buff
    end
    speed_gather = speed_gather * (1 + ( ply:get_num( key ) + ply:get_num( "SpeedGather_R" ) + get_num_by("SpeedGather_R",u_ef ) ) * 0.0001 ) / div
    count_gather = count_gather * (1 + ( ply:get_num( "CountWeight_R") + ( ef.CountWeight_R or 0 ) ) * 0.0001 ) / mul

    return speed_gather, count_gather, speed_base / div
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
        if arm.amend and arm.amend.relive then
            for id, num in pairs( arm.amend.relive ) do
                t = t + num
            end
        end
    end
    return t
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

        local live_num = lives[ id ] - dead
        if live_num < 0 then
            dead = lives[id]
            lives[id] = nil
        else
            lives[id] = live_num
        end

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
        if arm.amend and arm.amend.relive then
            for id, num in pairs( arm.amend.relive ) do
                if num > 0 then return true end
            end
        end
    end
    return false
end


function statics( troop )
    local infos = {}
    for pid, arm in pairs( troop.arms or {} ) do
        local live = 0
        local hurt = 0
        local lost = 0

        for id, num in pairs( arm.live_soldier or {} ) do live = live + num end

        local amend = arm.amend
        if amend then
            local conf = resmng.prop_arm
            for id, num in pairs( amend.relive or {} ) do live = live + num end
            for id, num in pairs( amend.back or {} ) do live = live + num end

            for id, num in pairs( amend.cure or {} ) do
                hurt = hurt + num
                local node = conf[ id ]
                if node then lost = lost + node.Pow * num end
            end

            for id, num in pairs( amend.dead or {} ) do
                local node = conf[ id ]
                if node then lost = lost + node.Pow * num end
            end
        else
            for id, num in pairs( arm.dead_soldier or {} ) do
                local node = conf[ id ]
                if node then lost = lost + node.Pow * num end
            end
        end
        infos[ pid ] = { live = live, hurt = hurt, lost = lost }
    end
    return infos
end

function handle_dead( troop, mode, to_live, to_back, to_cure )
    for pid, arm in pairs( troop.arms ) do
        local info = {}
        if arm.dead_soldier then
            local dead = copyTab( arm.dead_soldier )
            info.dead = dead

            if to_live > 0 then
                local node = {}
                for k, v in pairs( dead ) do
                    local n = math.floor( v * to_live )
                    node[ k ] = n
                    dead[ k ] = v - n
                end
                info.relive = node

                for _, id in pairs( arm.heros or {} ) do
                    if id ~= 0 then
                        local h = heromng.get_hero_by_uniq_id( id )
                        if h and h.lost then
                            h.hp = math.floor( h.hp +  h.lost * to_live )
                            if h.hp < 0 then h.hp = 0 end
                            if h.hp > h.max_hp then h.hp = h.max_hp end
                            h.lost = nil
                        end
                    end
                end
            end

            if to_back > 0 then
                local node = {}
                for k, v in pairs( dead ) do
                    local n = math.floor( v * to_back )
                    node[ k ] = n
                    dead[ k ] = v - n
                end
                info.back = copyTab(node)
                if pid >= 10000 then
                    local owner = getPlayer( pid )
                    if owner then
                        owner:add_soldiers( node )
                    end
                end

                for _, id in pairs( arm.heros or {} ) do
                    if id ~= 0 then
                        local h = heromng.get_hero_by_uniq_id( id )
                        if h and h.lost then
                            h.hp = math.floor( h.hp +  h.lost * to_back )
                            if h.hp < 0 then h.hp = 0 end
                            if h.hp > h.max_hp then h.hp = h.max_hp end
                            h.lost = nil
                        end
                    end
                end
            end

            if to_cure > 0 then
                if pid >= 10000 then
                    local owner = getPlayer( pid )
                    if owner then
                        local node = {}
                        for k, v in pairs( dead ) do
                            local n = math.floor( v * to_cure )
                            node[ k ] = n
                            dead[ k ] = v - n
                        end
                        local cure, over = owner:trans_to_hospital( node )
                        info.cure = cure
                        info.to_hurt = node
                        for k, v in pairs( over or {}) do
                            dead[ k ] = dead[ k ] + v
                        end
                    end
                end
            end
        end
        arm.amend = info
    end
end


function acc_march(troop, ratio)
    if troop:is_go() or troop:is_back() then

        local curx, cury = c_get_actor_pos(troop.eid)
        if not curx then return end

        local speed = troop.speed * ratio

        troop.curx = curx
        troop.cury = cury
        troop.tmCur = gTime
        troop.speed = speed

        local dist = c_calc_distance( curx, cury, troop.dx, troop.dy )
        local use_time = dist / speed
        troop.use_time = use_time
        troop.tmOver = math.ceil(gTime + use_time)

        local chg = gPendingSave.troop[ troop._id ]
        chg.curx    = troop.curx
        chg.cury    = troop.cury
        chg.tmCur   = troop.tmCur
        chg.speed   = troop.speed

        c_troop_set_speed( troop.eid, troop.speed, troop.use_time )
        troop:do_notify_owner( {tmOver=troop.tmOver} )
        player_t.update_watchtower_speed(troop)

        if troop:is_go() and troop:get_base_action() == TroopAction.SupportArm then
            if troop.target_pid and troop.target_pid >= 10000 then
                local dest = getPlayer( troop.target_pid )
                if dest then dest:support_notify( troop ) end
            end
        end

        --troop:save()
    end
end


function is_pvp( troop )
    --if troop:is_back() then return false end

    local action = troop:get_base_action()

    local mode = 0
    local node = resmng.get_conf( "prop_troop_action", action )
    if node then mode = node.IsPvp end

    if mode == 0 then return false end
    if mode == 1 then return true end
    if mode == 2 then
        if action == TroopAction.JoinMass then
            local tid = troop.dest_troop_id
            local troopD = troop_mng.get_troop( tid )
            if troopD then
                action = troopD:get_base_action()
                local node = resmng.get_conf( "prop_troop_action", action )
                return node and node.IsPvp == 1 
            end
        elseif action == TroopAction.Gather then
            local D = get_ety( troop.target_eid )
            if D and is_res( D ) then
                if D.pid >= 10000 then
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
        elseif action == TroopAction.Spy then
            local target = get_ety( troop.target_eid )
            if not is_npc_city( target ) then return true end
        end
    end
    return false

    --if is_pvp_action( action ) then return true end

    --if action == TroopAction.JoinMass then
    --    local tid = troop.dest_troop_id
    --    local troopD = troop_mng.get_troop( tid )
    --    if troopD then
    --        action = troopD:get_base_action()
    --        if is_pvp_action( action) then return true end
    --    end
    --end

    --if action == TroopAction.Gather then
    --    local D = get_ety( troop.target_eid )
    --    if D and is_res( D ) then
    --        if D.pid > 0 then
    --            if not (troop.owner_uid > 0 and troop.owner_uid == D.uid) then return true end
    --        end

    --        local comings = D.troop_comings
    --        if comings then
    --            for tid, _ in pairs( comings ) do
    --                local troopD = troop_mng.get_troop( tid )
    --                if troopD then
    --                    if not (troop.owner_uid > 0 and troop.owner_uid == troopD.owner_uid) then
    --                        if troop:is_go() then
    --                            if troop.tmStart > troopD.tmStart then return true end
    --                        elseif troop:is_ready() then
    --                            return true
    --                        end
    --                    end
    --                end
    --            end
    --        end
    --    end
    --end
    --return false
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
    for k, arm in pairs(self.arms or {}) do
        for index, id in pairs(arm.heros or {}) do
            if id ~= 0 then
                return true
            end
        end
    end
    return false
    --local arms = self.arms or {}
    --local arm = arms[pid]
    --if arm then
    --    local heros = arm.heros or {}
    --    if heros[idx] then
    --        if heros[idx] ~= 0 then
    --            return true
    --        end
    --    end
    --end
    --return false
end

function get_arm_by_pid(self, pid)
    return self.arms[pid]
end

function check_status( troop )

    local action = troop.action
    local state = math.floor( action / 100 )
    action = action % 100

    local STATE_GO = 1
    local STATE_SETTLE = 2
    local STATE_BACK = 3
    local STATE_DEL = 4

    local sm = {
        [ TroopAction.SiegePlayer ] = {
            [ STATE_GO ] = {
                [ STATE_BACK ] = true,


            }
        }
    }
end

function back_mass_power(self)
    if self:get_base_action() ~= TroopAction.SiegeMonster then return end

    local T = get_ety(self.target_eid)
    if is_monster(T) then
        for pid, arm in pairs(self.arms) do
            local ply = getPlayer(pid)
            if ply then
                ply:inc_sinew(10)
            end
        end

        for tid, action in pairs( T.troop_comings or {} ) do
            if action == TroopAction.JoinMass then
                local one = troop_mng.get_troop( tid )
                if one and one:is_go() and one.dest_troop_id == troop._id then
                    local x, y = c_get_actor_pos(one.eid)
                    if x then
                        if is_monster(T) then
                            local A = getPlayer(one.owner_pid)
                            if A then
                                A:inc_sinew(10)
                            end
                        end
                    end
                end
            end
        end
    end
end


function is_no_live_arm(self)
    local ret = true
    for pid, arm in pairs(self.arms or {}) do
        for k, v in pairs(arm.live_soldier or {}) do
            if v > 0 then
                return false
            end
        end
    end
    return ret
end

function recalc(self)
    if self:is_action(TroopAction.Gather) then
        local start = self:get_extra("start") or gTime
        local speed = self:get_extra("speed") or 0
        local cache = self:get_extra("cache") or 0

        local gain = math.floor( ( gTime - start ) * speed )
        local cache = cache + gain

        local mode = self:get_extra("mode") or 1
        local speed, count, speedb = self:get_gather_power( mode )

        self:set_extra("count", count) -- 负重
        self:set_extra("start", gTime)
        self:set_extra("cache", cache)
        self:set_extra("speed", speed)
        self:set_extra("speedb", speedb)
        --return gain
        return cache
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
        troop:notify_owner()
        union_build_t.recalc_gather( dest )

    else
        local gain = troop:recalc()
        if dest.val > gain then
            local speed = troop:get_extra("speed")
            local turbo = troop:get_extra("turbo")
            local dura = math.min(dest.val - gain, troop:get_extra("count") - gain) / speed
            if dura < 0 then dura = 0 end
            dura = math.ceil(dura)
            troop.tmOver = gTime + dura
            troop.tmSn = timer.new("troop_action", dura, troop._id)
            dest.extra = {speed=speed, start=gTime, count=dest.val-gain, tm=gTime, tid=troop._id, turbo=turbo}
            farm.mark( dest )

            turbo = turbo or 0
            local nturbo = 0
            local ply = getPlayer( troop.owner_pid )
            if ply then
                for _, bufid in pairs( { resmng.BUFF_SPEED_RES_1, resmng.BUFF_SPEED_RES_2, resmng.BUFF_SPEED_RES_3, resmng.BUFF_SPEED_RES_4 } ) do
                    if ply:get_buf( bufid ) then
                        nturbo = 1
                        break
                    end
                end
            end
            if turbo ~= nturbo then dest.extra.turbo = nturbo end

            etypipe.add(dest)
            troop:notify_owner()
        else
            troop:back()
            troop:gather_stop( troop )
        end
    end
end


function gather_gain( troop, dest )
    local gain = math.ceil( (troop:get_extra("speed") or 0) * (gTime - (troop:get_extra("start") or gTime) ) )
    gain = gain + troop:get_extra( "cache" )

    if is_res( dest ) then
        if gain > dest.val then gain = dest.val end
        dest.val = dest.val - gain
    end

    local mode = troop:get_extra("mode") or 1
    local gains = {}
    table.insert(gains, { "res", mode, gain} )
    troop.extra = {}
    troop:add_goods(gains, VALUE_CHANGE_REASON.GATHER)
    return gain
end

function gather_stop(troop)
    local mode = troop:get_extra("mode") or 1
    local count = troop:get_extra("cache") or 0
    local dp = get_ety( troop.target_eid )
    if dp then
        count = troop:gather_gain( dp )
        if is_union_building(dp) then
            setRem( dp.my_troop_id, troop._id )
            union_build_t.recalc_gather(dp)

        else
            if dp.val < 2 then
                rem_ety(dp.eid)
                farm.respawn(math.ceil(dp.x / 16), math.ceil(dp.y / 16), mode)
            else
                dp.pid = 0
                dp.uid = 0
                dp.my_troop_id = 0
                dp.extra = {}
                etypipe.add(dp)
                farm.mark(dp)
            end
        end
    end

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
        --世界事件
        world_event.process_world_event(WORLD_EVENT_ACTION.GATHER_NUM, mode, count)
        --周限时活动
        weekly_activity.process_weekly_activity(owner, WEEKLY_ACTIVITY_ACTION.GATHER, mode, count)
    end
end

function flush_data( troop )
    if troop:is_go() or troop:is_back() then
        local node = etypipe[ EidType.Troop ]
        c_troop_set_data( troop.eid, etypipe.pack( node, troop ) )
    end
end

function rem_no_arm_troop(self)
    for pid, arm in pairs(self.arms or {}) do
        local ret = false
        for mode, id in pairs(arm.heros or {}) do
            if id ~= 0 then
                ret = true
            end
        end

        if ret == false then
            local tag = false
            for id, num in pairs(arm.live_soldier or {}) do
                if num > 0 then
                    tag = true
                end
            end
            if tag == false then
                local tr = self:split_pid(pid)
                tr:back()
            end
        end
    end
end

