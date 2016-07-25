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
                local ply = getPlayer(pid)
                if ply then
                    print( data._id, pid )
                    ply:add_busy_troop(data._id)
                end
            end
        else
            local ply = getPlayer(data.owner_pid)
            if ply then
                ply:add_busy_troop(data._id)
            end
        end

        --把攻击该玩家的部队，标记到玩家身上
        local dest_ply = getPlayer(data.target_pid)
        if dest_ply then
            if dest_ply.be_ack == nil then
                dest_ply.be_ack = {}
            end
            dest_ply.be_ack[data._id] = {id=data._id}
        end
    end
    if not data.culture then data.culture = 1 end
    if not data.soldier_num then data.soldier_num = {1,0,0,0} end
    return data
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
        if hit then return speed / 60
        else return 1 / 60 end
    end
end


function go(self)
    self.action = self:get_base_action() + 100
    self:start_march()
end

function settle(self)
    self.action = self:get_base_action() + 200
    if self.eid > 0 then 
        rem_ety(self.eid)
        self.eid = 0
    end
end

--function back(self)
--    self.action = self:get_base_action() + 300
--    local ts = {}
--
--    while true do
--        local troop = self:split_one()
--        troop.sx, troop.sy = troop.dx, troop.dy
--
--        local owner = get_ety(troop.owner_eid)
--        troop.dx, troop.dy = get_ety_pos(owner)
--
--        troop:start_march() -- here will notify owner
--        ts[ owner.pid ] = troop
--        if troop == self then return ts end
--    end
--end
--
function back(self)
    local action = self:get_base_action() + 300
    
    if self.is_mass ~= 1 then
        local owner = get_ety(self.owner_eid)
        if owner then
            self.action = action
            self.sx, self.sy = self.dx, self.dy
            self.dx, self.dy = get_ety_pos(owner)
            self:start_march()
            return { [self.owner_pid] = self}
        end
    else
        troop_mng.delete_troop(self._id)

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
                    troop.sx, troop.sy = sx, sy
                    troop.dx, troop.dy = get_ety_pos(ply)
                    troop:start_march()
                    ts[ pid ] = troop
                end
            end
        end
        return ts
    end
end


function home(self)
    local pid = self.owner_pid
    if pid == 0 then return end
    local owner = getPlayer(pid)
    if not owner then return end

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

    local home_troop = owner:get_my_troop()
    if home_troop then
        local homes = home_troop.arms[ pid ].live_soldier
        local flag = false
        for k, v in pairs(arm.live_soldier or {}) do
            if v > 0 then
                homes[ k ] = (homes[ k ] or 0) + v
                flag = true
            end
        end
        if flag then 
            Rpc:upd_arm(owner, homes) 
            home_troop:save()
        end
    end

    local count_cure = owner:troop_cure(self)
    if count_cure and count_cure > 0 then owner:recalc_food_consume() end

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

    for pid, armA in pairs(A.arms or {}) do
        A.arms[ pid ] = nil
        local armB = armsB[ pid ]
        if not armB then
            armsB[ pid ] = armA
        else
            do_add_arm_to(armA, armB)
        end
    end
    if A.owner_pid > 0 then
        local ply = getPlayer(A.owner_pid)
        if ply then
            ply:add_busy_troop(B._id)
            B:notify_player(ply)
        end
    end
    troop_mng.delete_troop(A._id)
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


function split_one(self)
    for pid, arm in pairs(self.arms or {}) do
        if pid ~= self.owner_pid then
            self.arms[ pid ] = nil
            local owner = getPlayer(pid)
            owner:rem_busy_troop(self._id)

            local target = get_ety(self.target_eid)
            local troop = troop_mng.create_troop(self.action, owner, target, arm)
            troop.curx = self.curx
            troop.cury = self.cury
            return troop
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
            if not other then return self end
        end

        self.arms[ pid ] = nil
        local owner = getPlayer(pid)
        owner:rem_busy_troop(self._id)

        local target = get_ety(self.target_eid)
        local troop = troop_mng.create_troop(self.action, owner, target, arm)
        troop.curx = self.curx
        troop.cury = self.cury
        return troop
    end
end

function start_march(self)
    if self.eid > 0 then
        rem_ety(self.eid)
        self.eid = 0
    end

    self.eid = get_eid_troop()
    local distance = calc_line_length(self.curx, self.cury, self.dx, self.dy)
    local speed = self:calc_troop_speed()
    local use_time = math.ceil(distance / speed)

    self.speed0 = speed
    self.speed = speed
    self.tmStart = gTime
    self.tmOver = gTime + use_time
    self.tmCur = gTime

    local arminfo = {0,0,0,0}
    for _, arm in pairs(self.arms or {}) do
        for id, num in pairs(arm.live_soldier or {}) do
            local mode = math.floor(id / 1000)
            arminfo[ mode ] = arminfo[ mode ] + num
        end
    end
    self.soldier_num = arminfo
    etypipe.add(self)
    c_add_actor(self.eid, self.curx, self.cury, self.dx, self.dy, gTime, self.speed)
    gEtys[self.eid] = self

    self:save()
    self:notify_owner()
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

function mount_bonus(self, goods, reason)
    --tab = {
    --    {"type",id,num} --格式，经验类型比较特殊，id,num代表一个区间，从这个区间随机一个值
    --    {"item",10002,99}
    --    {"exp",1,1000} --代表从1到1000随机加一个数
    --    {"res",1,1000}
    --    {"soldier",1001,10000}
    --    {"heroexp",1,1000}  --代表给hero_id是1的英雄加1000经验
    --}
    if tab == nil then return end
    if reason == nil then ERROR("mount_bonus wrong!! no reason, troop_id:%d", troop._id) end

    if not self.goods then 
        self.goods = goods
        self.goods_reason = reason
    else
        for k, v in pairs(goods) do
            table.insert(self.goods, v)
        end
        if not self.goods_reason then self.goods_reason = reason end
    end
end


--function calc_pow(self, pid)
--    local pow = 0
--    local arm = self.arms[ pid ]
--    if arm then
--        local prop_arm = resmng.prop_arm
--        for id, num in pairs(arm.live_soldier) do
--            pow = pow + (prop_arm[ id ].Pow or 0) * num
--        end
--    end
--    return pow
--end
--

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

function get_ef(self)
    local ef = {}
    local owner = self.owner_pid
    if owner <= 0 then return ef end
    local arm = self.arms[ owner ]
    if not arm or (not arm.heros) then return ef end
    for idx = 1, 4, 1 do
        local heroid = arm.heros[ idx ]
        if heroid ~= 0 then
            local hero = heromng.get_hero_by_uniq_id(hero_id)
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
    local info = { _id = self._id, eid = self.eid, tmStart = self.tmStart, tmOver = self.tmOver, action = self.action, x = self.dx, y = self.dy, target=self.target_eid }
    local arms = {}
    for pid, arm in pairs( self.arms or {} ) do
        arms[ pid ] = arm.live_soldier or {}
    end
    info.arms = arms

    if self.status == TroopStatus.Moving then
        info.curx = self.curx
        info.cury = self.cury
        info.tmCur = self.tmCur
    end
    return info
end

function attach(self, ety)
    if ety == nil then return end
    local troop_hold_type = resmng.prop_world_unit[ety.propid].TroopHold
    if troop_hold_type == 1 then
        --单只可融合部队
        local dest_troop = troop_mng.get_troop(ety.my_troop_id or 0)
        if not dest_troop then ety.my_troop_id = self._id
        else self:merge(dest_troop) end

    elseif troop_hold_type == 2 then 
        --单只非融合部队 
        ety.my_troop_id = self._id

    elseif troop_hold_type == 3 then
        --多只非融合部队
        if not ety.my_troop_id or ety.my_troop_id == 0 then 
            ety.my_troop_id = { self._id }
        else
            table.insert(ety.my_troop_id, self._id)
        end
    end
end

function detach(self, ety, pid)
    if ety == nil then return nil end

    local hold_troop_id = ety.my_troop_id
    local troop_hold_type = resmng.prop_world_unit[ety.propid].TroopHold
    if troop_hold_type == 1 then
        --单只可融合部队
        local owner = getPlayer(pid)
        owner:rem_busy_troop(self._id)

        local one =  self:split_pid(pid)
        if one then
            one:save()
            if one == self then
                ety.my_troop_id = 0
            end
            return one
        end

    elseif troop_hold_type == 2 then 
        --单只非融合部队 
        ety.my_troop_id = nil
        return self

    elseif troop_hold_type == 3 then
        --多只非融合部队
        for k, v in pairs(hold_troop_id) do
            if v == self._id then
                hold_troop_id[k] = nil
                self.attach_eid = 0
                return self
            end
        end
    end
    return nil
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

    local count_gather = 0
    for _, arm in pairs(troop.arms) do
        for id, num in pairs(arm.live_soldier) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                count_gather = count_gather + conf.Weight * num
            end
        end
    end

    local ef = troop:get_ef()
    local key = string.format("SpeedGather%d", mode)
    local sgb, sgm, sga = get_nums_by(key, ply._ef, ef)
    local cgb, cgm, cga = get_nums_by("CountGather", ply._ef, ef)

    local mul = resmng.get_conf("prop_resource", mode).Mul 
    local div = mul * 3600
    return speed_gather/div, sgm, sga/div, count_gather/mul, cgm, cga/mul
end


function recalc(self)
    if self:is_action(TroopAction.Gather) then
        local start = self:get_extra("start") or gTime
        local speed = self:get_extra("speed") or 0
        local cache = self:get_extra("cache") or 0

        cache = cache + (gTime - start) * speed

        local mode = self:get_extra("mode") or 1
        local speed_gatherB, speed_gatherM, speed_gatherA, count_gatherB, count_gatherM, count_gatherA = self:get_gather_power(mode)
        local speed = speed_gatherB * (1 + speed_gatherM * 0.0001) + speed_gatherA
        local count = count_gatherB * (1 + count_gatherM * 0.0001) + count_gatherA

        self:set_extra("count", count)
        self:set_extra("start", gTime)
        self:set_extra("cache", cache)
        self:set_extra("speed", speed)
        self:set_extra("speedb", speed_gatherB)
    end
end

function mount_bonus(troop, tab, reason)
    --[[
    tab = {
        {"type",id,num} --格式，经验类型比较特殊，id,num代表一个区间，从这个区间随机一个值
        {"item",10002,99}
        {"exp",1,1000} --代表从1到1000随机加一个数
        {"res",1,1000}
        {"soldier",1001,10000}
        {"heroexp",1,1000}  --代表给hero_id是1的英雄加1000经验
    }
    --]]
    if tab == nil or troop == nil then
        return
    end
    if reason == nil then 
        ERROR("mount_bonus wrong!! no reason, troop_id:%d", troop._id)
    end
    troop:add_goods(tab)
end

function add_goods(self, goods, reason)
    self.goods = goods
    self.goods_reason = reason
    self:save()
end


function add_mark_id(self, troop_id)
    if not self.mark_troop_ids then self.mark_troop_ids = {} end
    for k, v in pairs(self.mark_troop_ids or {}) do
        if v == troop_id then
            return true
        end
    end
    table.insert(self.mark_troop_ids, troop_id)
    self:save()
end


function rem_mark_id(self, troop_id)
    local pos = 0
    for k, v in pairs(self.mark_troop_ids or {}) do
        if v == troop_id then
            table.remove(self.mark_troop_ids, k)
            self:save()
            return true
        end
    end
end

function get_arm_by_pid(self, pid)
    return self.arms[pid]
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


