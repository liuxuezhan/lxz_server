module("player_t")

function init()
    _example.lv = 1
    _example.exp = 0

    _example.vip_lv = 1
    _example.vip_exp = 0
    _example.vip_login = 0
    _example.vip_nlogin = 0
    _example.vip_gift = 0

    _example.photo = 1
    _example.name = "unknown"
    _example.photo_url = ""
    _example.x = 0
    _example.y = 0
    _example.eid = 0
    _example.pid = 0
    _example.uid = 0
    _example.rmb = 0
    _example.gold = 1000000
    _example.silver = 1000000
    _example.sinew = 100
    _example.tm_sinew = 0
    _example.culture = 1
    _example.field = 2
    _example.tm_login = 0

    _example.cds = {}
    _example.bufs = {}

    _example.res={{0,0},{0,0},{0,0},{0,0}} -- for protect resource

    _example.foodUse = 0
    _example.foodTm = gTime
    _example.talent = 0
    _example.genius = {}
    _example.tech = {}
    _example.my_troop_id = 0
    _example.busy_troop_ids = {}

    _example.mail_sys = 0
    _example.mail_max = 0

    _example.cival = 0  --civalization

    _example.kwseason = 0 -- 王城战评价的期数
    _example.officer = 0 -- 王城战职务
    _example.vote_time = 0 -- 王城战投票购买时间
    _example.tm_union = 0 -- 进入军团的时间
    
    _example.activity = 0  --每日任务活跃度
    _example.activity_box = {}  --每日活跃度箱子领取
    _example.daily_refresh_num = 0 --每日任务免费刷新剩余次数
    _example.daily_refresh_time = 0 --每日任务免费刷新时间

    _example.def_heros = {}  -- 守城英雄

    _example.online_award_on_day_pass = 0 --跨天标记
    _example.online_award_time = 0 --上一次在线奖励时间
    _example.online_award_num = 0 --在线奖励领奖进度

    _example.cross_time = 0 --玩家跨天时间记录

    _example.month_award_time = 0 --玩家月登陆领奖时间
    _example.month_award_com = 0 --玩家补签次数
    _example.month_award_cur = 0 --玩家月登陆当前月

    _example.hurts = {}     -- soldiers who are waiting for cure
    _example.cures = {}     -- soldiers who are curing
    _example.tm_cure = 0     -- timer 
    _example.cure_start = 0     -- timer  start
    _example.cure_over = 0     -- timer  over

    _example.language = 10000


    _example.gacha_yinbi_num = 0  --银币抽卡次数
    _example.gacha_yinbi_cd = 0  --银币抽卡CD
    _example.gacha_yinbi_index = 1  --银币抽卡的位置
    _example.gacha_jinbi_num = 0  --金币抽卡次数
    _example.gacha_jinbi_cd = 0  --金币抽卡CD
    _example.gacha_jinbi_index = 1 --金币抽卡的位置
    _example.gacha_hunxia_index = 1  --魂匣抽卡的位置
    _example.gacha_gift = 0  --抽卡奖励值
    _example.gacha_box = 0  --抽卡奖励值箱子

    _example.chat_account = "" --聊天账号
    _example.chat_psw = ""    --聊天密码
    _example.gacha_yinbi_first = false  --银币首抽
    _example.gacha_jinbi_first = false  --金币首抽

end

function can_move_to(self, x, y)
    return true
    --local lv_castle = self:get_castle_lv()
    --local lv_pos = c_get_zone_lv( math.floor(x/16), math.floor(y/16) )
    --if lv_castle <=  5 then return lv_pos <= 1 end
    --if lv_castle <=  9 then return lv_pos <= 2 end 
    --if lv_castle <= 11 then return lv_pos <= 3 end 
    --if lv_castle <= 14 then return lv_pos <= 4 end 
    --return true
end

function change_language(self,lang)
    self.language = lang
end

function create(account, map, pid)
    local eid = get_eid_ply()
    if not eid then return end

    pid = pid or getId("pid")
    local x, y = c_get_pos_by_lv(1,4,4)
    if not x then return INFO("!!!! NO ROOM FOR NEW PLAYER") end

    local p = copyTab(player_t._example)
    p._id = pid
    p.pid = pid
    p.eid = eid
    p.map = gMapID
    p.smap = map
    p.x = x
    p.y = y
    p.name = string.format("K%da%d", gMapID, p.pid)
    p.account = account
    p.language = 10000
    p.tm_sinew = gTime
    p.culture = math.random(1,4)
    p.cross_time = gTime

    local ply = player_t.new(p)
    ply.eid = eid
    ply.propid = resmng.PLY_CITY_WEST_1

    player_t._cache[pid] = p

    local default_build = {}
    for _, v in pairs(resmng.prop_citybuildview) do
        if v.Bborn == 1 then
            table.insert(default_build, v.PropId)
        end
    end

    local bs = {}
    for _, build_propid in ipairs(default_build) do
        local conf = resmng.get_conf("prop_build", build_propid)
        local build_idx = ply:calc_build_idx(conf.Class, conf.Mode, 1)
        bs[ build_idx ] = build_t.create(build_idx, pid, build_propid, 0, 0, BUILD_STATE.WAIT)
    end
    ply._build = bs
    
    local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
    ply.my_troop_id = troop._id

    ply:initEffect()

    ply._item = {}
    gPendingInsert.item[ pid ] = {}

    ply._hero = {}
    ply._email = {}
    ply.size = 4

    -- Hx@2015-12-24 : lazy init union when login, not here
    --ply._union = union_member_t.create(pid, 0, 0)

    gEtys[ eid ] = ply
    ply.uname = ""
    etypipe.add(ply)

    -- register chat accout
    --Rpc:create_chat_accont(ply, tostring(pid), CHAT_HOST, tostring(pid))
    create_chat_account(ply)

    return ply
end


function build_all(self)
    local default_build = {
        resmng.BUILD_CASTLE_1,
        resmng.BUILD_ALTAR_1,
        resmng.BUILD_WALLS_1,
        resmng.BUILD_RANGE_1,
        resmng.BUILD_BLACKMARKET_1,
        resmng.BUILD_FORGE_1,
        resmng.BUILD_FACTORY_1,
        resmng.BUILD_EMBASSY_1,
        resmng.BUILD_RESOURCESMARKET_1,
        resmng.BUILD_HALLOFHERO_1,
        resmng.BUILD_HALLOFWAR_1,
        resmng.BUILD_PRISON_1,
        resmng.BUILD_STABLES_1,
        resmng.BUILD_MARKET_1,
        resmng.BUILD_DAILYQUEST_1,
        resmng.BUILD_ACADEMY_1,
        resmng.BUILD_BARRACKS_1,
        resmng.BUILD_STOREHOUSE_1,
        resmng.BUILD_DRILLGROUNDS_1,
        resmng.BUILD_TUTTER_LEFT_1,
        resmng.BUILD_TUTTER_RIGHT_1,
        resmng.BUILD_WATCHTOWER_1,
    }

    local bs = self:get_build()
    for _, build_propid in ipairs(default_build) do
        local conf = resmng.get_conf("prop_build", build_propid)
        local build_idx = self:calc_build_idx(conf.Class, conf.Mode, 1)
        if not bs[ build_idx ] then
            bs[ build_idx ] = build_t.create(build_idx, self.pid, build_propid, 0, 0, BUILD_STATE.WAIT)
            Rpc:stateBuild(self, bs[ build_idx ]._pro)
        end
    end

    self:refresh_black_marcket()
    self:refresh_res_market()

end


function create_character(self, info)
    dumpTab(info, "create_character")

    local account = info.account
    local process = info.process
    local name = info.name

    local gate = self.gid

    if not process or not account then
        WARN("create_character, name=%s, not enough param", name)
        return
    end

    local p = gAccs[ account ]
    if not p then
        p = player_t.create(account, gMapID)
        p.name = name
        if p then
            LOG("firstPacket, account=%s, pid=%d, process=%s, create new player in local ", account, p.pid, process)
            local dg = dbmng:getGlobal()
            dg.ply:insert({_id=account, pid=p._id, map=p.map, create=gTime, state=0})
            set_ply_map(gate, process, p.map, p.pid)
        else
            --sendCertify()
        end
    end
end


function set_ply_map(gate, proc, map, pid)
    pushHead(gate, 0, 9)  -- set server id
    pushInt(pid)
    pushInt(map)
    pushString(proc)
    pushOver()
end

function change_server(gate, proc, map)
    pushHead(gate, 0, 13) -- change server id
    pushInt(map) -- server id
    pushString(proc)
    pushOver()
end

function firstPacket(self, uid, account, pasw)
    print("firstPacket", uid, account, pasw)

    local process = pullString()
    if self.pid ~= 0 then return LOG("duplicate firstPacket, uid=%d, account=%s, process=%s", uid, account, process) end

    local magic = pullInt()
    LOG("firstPacket, account=%s, pid=%d, process=%s, magic=%d", account, self.pid, process, magic)
    if magic ~= 20100731 then return end
    local gateid = self.gid

    local p = gAccs[ account ]
    if not p then
        LOG("firstPacket, account=%s, pid=%d, process=%s, account not in local", account, self.pid, process)
        local dg = dbmng:getGlobal()
        local info = dg.ply:findOne({_id=account})

        -- steer to map server the player belong to
        if info then
            if info.map == gMapID then
                LOG("firstPacket, account=%s, pid=%d, process=%s, account in map %d, missing, recreate", account, info.pid, process, info.map)
                p = player_t.create(account, gMapID, info.pid)
            else
                LOG("firstPacket, account=%s, pid=%d, process=%s, account in map %d", account, info.pid, process, info.map)
                local map = info.map
                local pid = info.pid
                set_ply_map(gateid, process, map, pid)
                return
            end
        end

        -- steer to map server the system recomment
        local steer = gSysConfig.steer
        if steer and steer ~= gMapID then
            LOG("firstPacket, account=%s, pid=%d, process=%s, account steer to map %d", account, self.pid, process, steer)
            change_server(gateid, process, steer)
            return
        end
    end

    if not p then
        p = player_t.create(account, gMapID)
        if p then
            LOG("firstPacket, account=%s, pid=%d, process=%s, create new player in local ", account, p.pid, process)
            local dg = dbmng:getGlobal()
            dg.ply:insert({_id=account, pid=p._id, map=p.map, create=gTime, state=0})
        end
    end
    if not p then return INFO("NOT HANDLE WHY") end

    local map = p.map
    local pid = p._id
    LOG("firstPacket, setSrvID, pid=%d, map=%d, proc=%s, gid=%d", pid, map, process, self.gid)

    set_ply_map(gateid, process, map, pid)
    return
end

--gAccs[ "loon" ]  = {_id="loon", [ 10001 ] = {map=3, smap=3, }}

function firstPacket2(self, sockid, from_map, account, pasw)
    print( string.format( "firstPacket2, account=%s, from=%s, to=%s, sockid=0x%08x", account, from_map, gMapID, sockid ) )

    local p = false
    local acc = gAccounts[ account ]
    if acc then
        for pid, v in pairs( acc ) do
            if type( pid ) == "number" then
                if v.smap == from_map then
                    p = getPlayer( pid )
                    -- if act, should load player here
                    if not p then 
                        WARN(" account = %s, smap=%d, not found", account, from_map )
                        return
                    end
                    break
                end
            end
        end
    end

    if not p then
        p = player_t.create(account, from_map)
        if not p then return end

        local dg = dbmng:getGlobal()
        local info = { [p.pid] = {map=p.map, smap=from_map} }
        dg.account:update({_id=account}, {["$set"] = info }, true)
        local info = dg:runCommand("getLastError")
    end

    if p then
        pushHead(_G.GateSid, 0, 9)  -- set server id
        pushInt(sockid)
        pushInt(from_map)
        pushInt(p.pid)
        pushOver()
        player_t.login( p, p.pid )
    end

end

function first_login(self)
    --给玩家加上默认troop
    self:init_my_troop()
    self:inc_arm(1001, 10000)
    self:inc_arm(2001, 10000)
    self:inc_arm(3001, 10000)
    self:inc_arm(4001, 10000)

    --接任务
    self:init_task()
    self:take_life_task()
    self:take_daily_task()

    --开启在线领奖
    self:open_online_award()
    --首抽
    self.gacha_yinbi_first = true  --银币首抽
    self.gacha_jinbi_first = true  --金币首抽
end

function login(self, pid)
    local gid = self.gid or GateSid

    local p = getPlayer(pid)
    if p then
        p.gid = gid
        INFO("[LOGIN], on, pid=%d, name=%s", pid, p.name)
        --如果是第一次登陆，初始化玩家数据
        if p.tm_login == 0 then p:first_login() end
        p.tm_login = gTime
        if p.tmLogout and p.tmLogout == gTime then p.tmLogout = gTime - 1 end

        Rpc:onLogin(p, p.pid, p.name)
        p:get_build()
        p:vip_signin()

        --p._pro.rmb =  100000
        --p._pro.gold = 100000

        --p._pro.res[1][1] = 500000
        --p._pro.res[1][2] = 500000

        --p._pro.res[2][1] = 500000
        --p._pro.res[2][2] = 500000

        --p._pro.res[3][1] = 500000
        --p._pro.res[3][2] = 500000

        --p._pro.res[4][1] = 500000
        --p._pro.res[4][2] = 500000
        --p:get_item()

        -- Hx@2015-12-24 : lazy init union part, in case db:union_member was deleted manually
        if not p._union then 
            union_member_t.create(p, 0, 0) 
            new_union.add(p)
        end

        --跨天
        if self.cross_time == 0 then self.cross_time = gTime end
        if get_diff_days(gTime, self.cross_time) > 0 then self:on_day_pass() end
        if self.foodUse == 0 then self:recalc_food_consume() end

        return
    end
    LOG("player:login, pid=%d, gid=%d, not found player", pid, gid)
end

function onBreak(self)
    INFO("[LOGIN], off, pid=%d, gid=%d, name=%s", self.pid or 0, self.gid or 0, self.name or "unknonw")
    self.gid = nil
    self.tmLogout = gTime
    -- find some way to remove player's email
    --self._mail = nil
    c_rem_eye(self.pid)
end

function is_online(self)
    if self.tm_login then
        if not self.tmLogout then return true end
        if self.tm_login > self.tmLogout then return true end
    end
end


function debugInput(self, str)
    if self.pid == 0 then
        loadstring(str)()
    end
end

function get_user_simple_info(self, pid)
    local p = getPlayer(pid)
    if p then
        Rpc:on_get_user_simple_info(self, p.pid, p.vip_lv, p.name, p.photo, p.photo_url)
    end
end

function get_user_info(self, pid, what)
    local t = {}
    t.key = what

    local pb = getPlayer(pid)
    if not pb then
        --nil
    elseif what == "pro" then
        t.val = {
            pid = pb.pid,
            name = pb.name,
            lv = pb.lv,
            uid = pb:get_uid(),
        }
    elseif what == "ef" then
    elseif what == "aid" then
        t.val = {
            max = 6666
        }
    end
    if not t.val then t.val = {} end
    Rpc:get_user_info(self, t)
end

--{{{ union
function get_uid(self)
    return self.uid
    --if self._union then return self._union.uid or 0 end
    --return 0
end

function set_uid(self, val)
    self.uid = val
    local troop = troop_mng.get_troop(self.my_troop_id)
    if troop ~= nil then
        troop.union_id = val
    end
    --self._union.uid = val
end

function get_rank(self)
    return self._union.rank
end

function set_rank(self, val)
    self._union.rank = val
    gPendingSave.union_member[self.pid] = self._union 
end

function union_data(self)
    return self._union
end

function leave_union(self)
    union_member_t.leave_union(self)
    self:set_uid(0)
end

function on_join_union(self, uid)
    self._union.tmJoin = gTime
    self._union.rank = resmng.UNION_RANK_1
    self:set_uid(uid)
    etypipe.add(self)
    gPendingSave.union_member[self.pid] = self._union 
end

function get_union_info(self)
    return {
        pid = self.pid,
        name = self.name,
        lv = self.lv,
        rank = self:get_rank(),
        title = self._union.title,
        photo = self.photo,
        eid = self.eid,
        x = self.x,
        y = self.y,
        pow = calc_pow(self.lv,self.builds,self.arms,self.equips,self.techs,self.genius),
    }
end

function get_intro(self)
    local t = {
        pid = self.pid,
        name = self.name,
        lv = self.lv,
        uid = self:get_uid(),
        photo = self.photo,
    }
    local u = unionmng.get_union(self:get_uid())
    if u then
        t.uid = u.uid
        t.alias = u.alias
        t.flag = u.flag
        t.rank = u.rank
    end
    return t
end

function union(self)
    return unionmng.get_union(self:get_uid())
end

--}}}

function initObj(self)
    if not self.aid then self.aid = {} end
    --setmetatable(self.aid, {__mode="v"})
    --if not self._troop then self._troop = {} end
end

function getTime(self)
    Rpc:getTime(self, gTime)
end


function get_db_checker(db, frame)
    local f = function( )
        local info = db:runCommand("getPrevError")
        if info.ok then
            local dels = {}
            local its = _cache
            local cur = gFrame

            for k, v in pairs(its) do
                local n = v._n_
                if n then
                    if n == frame then
                        table.insert(dels, k)
                    elseif cur - n > 100 then
                        v._n_ = nil
                    end
                end
            end
            for _, v in pairs(dels) do its[ v ] = nil end

            dels = {}
            its = _cache_items
            for k, v in pairs(its) do
                local n = v._n_
                if n then
                    if n == frame then
                        table.insert(dels, k)
                    elseif cur - n > 100 then
                        v._n_ = nil
                    end
                end
            end
            for _, v in pairs(dels) do its[ v ] = nil end

        end
    end
    return coroutine.wrap(f)
end


function check_pending()
    local db = dbmng:tryOne(1)
    if not db then return end
    local hit = false
    local cur = gFrame
    for pid, chgs in pairs(_cache) do
        if not chgs._n_ then
            db.player:update({_id=pid}, {["$set"]=chgs}, true)
            dumpTab(chgs, string.format("update player, pid = %d", pid))
            local p = getPlayer(pid)
            Rpc:statePro(p, chgs)
            chgs._n_ = cur
            hit =true
        end
    end

    for pid, chgs in pairs(_cache_items) do
        if not chgs._n_ then
            db.item:update({_id=pid}, {["$set"]=chgs})
            local p = getPlayer(pid)
            Rpc:stateItem(p, chgs)
            chgs._n_ = cur
            hit = true

            for k, v in pairs(chgs) do
                if k ~= "_n_" then
                    if v[3] <= 0 then
                        db.item:update({_id=pid}, {["$unset"]={[k]=1}})
                        p._item[ v[1] ] = nil
                    end
                end
            end
        end
    end

    if hit then get_db_checker(db, gFrame)() end
end


-- _ef,
-- _ef_build
-- _ef_equip
-- _ef_tech
-- _ef_talent
-- _ef_hero
-- _ef_union todo
function initEffect(self)
    self._ef = {}
    local conf = resmng.prop_level[ self.lv ]
    if conf then
        self.pow = resmng.prop_level[ self.lv ].Pow
    else
        self.pow = 0
    end

    local ptab = resmng.prop_effect_type
    for k, v in pairs(ptab) do
        if v.Default and v.Default ~= 0 then
            self:ef_add({[k] = v.Default}, true)
        end
    end

    -- build
    local bs = self:get_build()
    if bs then
        local ptab = resmng.prop_build
        for _, v in pairs(bs) do
            local node = ptab[ v.propid ]
            if node then
                self:ef_add(node.Effect, true)
                self:inc_pow(node.Pow)
            end
        end
    end

    -- equip
    local es = self:get_equip()
    if es then
        local ptab = resmng.prop_build
        for k, v in pairs(es) do
            local node = ptab[ v.propid ]
            if node then
                self:ef_add(node.Effect, true)
                self:inc_pow(node.Pow)
            end
        end
    end

    -- tech
    local ptab = resmng.prop_tech
    for _, v in pairs(self.tech or {}) do
        local node = ptab[ v ]
        if node then
            self:ef_add(node.Effect, true)
            self:inc_pow(node.Pow)
        end
    end

    -- genius
    local ptab = resmng.prop_genius
    for _, v in pairs(self.genius or {}) do
        local node = ptab[ v ]
        if node and node.Effect then
            self:ef_add(node.Effect, true)
        end
    end

    -- bufs
    local ptab = resmng.prop_buff
    for k, v in pairs(self.bufs or {}) do
        local bufid = v[1]
        local over = v[2]
        if over > gTime then
            local node = ptab[ bufid ]
            if node and node.Effect then
                self:ef_add(node.Effect, true)
            end
        end
    end

    self.pow_arm = self:calc_pow_arm()
    self:inc_pow(self.pow_arm)
end

function calc_pow_arm(self)
    local pow = 0
    local troop = self:get_my_troop()
    if troop then pow = pow + troop:calc_pow(self.pid) end

    for k, v in pairs(self.busy_troop_ids) do
        troop = troop_mng.get_troop(v)
        if troop then pow = pow + troop:calc_pow() end
    end
    return math.floor(pow)
end


function calc_diff(A, B) -- A, original; B, new one
    local C = {}
    for k, v in pairs(A) do
        C[k] = (B[k] or 0) - v
    end
    for k, v in pairs(B) do
        if not A[k] then
            C[k] = B[k]
        end
    end
    return C
end

function ef_chg(self, A, B) -- A, original; B, new, for upgrade
    local C = calc_diff(A, B)
    self:ef_add(C)
end

function ef_add(self, eff, init)
    if not eff then return end
    local t = self._ef
    local res = {}
    for k, v in pairs(eff) do
        if type(v) == "table" then pause() end
        t[k] = (t[k] or 0) + v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        if not init then LOG("ef_add, pid=%d, what=%s, num=%d", self.pid, k, v) end
    end
    if not init then Rpc:stateEf(self, res) end
end

function ef_rem(self, eff)
    if not eff then return end
    local t = self._ef
    local res = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) - v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        LOG("ef_rem, pid=%d, what=%s, num=%d", self.pid, k, v)
    end
    Rpc:stateEf(self, res)
end

function get_num(self, what, ...) -- VALUE DIRECTLY
    if ... == nil then
        return self._ef[ what ] or 0 
    else
        local v = 0
        for _, t in pairs({...}) do
            v = v + (t[ what ] or 0)
        end
        return v
    end
end

function get_nums(self, what, ...)
    if ... == nil then
        return get_nums_by(what, self._ef)
    else
        return get_nums_by(what, ...)
    end
end

function get_val(self, what, ...)
    if ... == nil then
        return get_val_by(what, self._ef)
    else
        return get_val_by(what, ...)
    end
end

-- get_valr(self, "Atk") will fetch (1 + Atk_R / 10000)
function get_valr(self, what, ...) -- multiple
    return (10000 + self:get_num(what.."_R", ...)) * 0.0001
end

-- get_vala(self, "Atk") will fetch Atk_A
function get_vala(self, what, ...) -- add
    return self:get_num(what.."_A", ...)
end


--------------------------------------------------------------------------------
-- Function : 获取指定effect的ef, ef_a, ef_r
-- Argument : self, what
-- Return   : ef, ef_a, ef_r
-- Others   : NULL
--------------------------------------------------------------------------------
function get_val_extra(self, what, ...)
    --local node = resmng.get_conf("prop_effect_type", what)
    --if not node then
    --    return 0
    --end

    local bidx = what
    local ridx = string.format("%s_R", what)
    local eidx = string.format("%s_A", what)

    local sf = self._ef
    local hf = self._ef_hero or {}
    local uf = self._ef_union or {}

    local b = (sf[bidx] or 0) + (hf[bidx] or 0) + (uf[bidx] or 0)
    local r = (sf[ridx] or 0) + (hf[ridx] or 0) + (uf[ridx] or 0)
    local e = (sf[eidx] or 0) + (hf[eidx] or 0) + (uf[eidx] or 0)
    r =  (10000 + r) * 0.0001

    return b, r, e
end

function getDb(self)
    return dbmng:getOne(self.pid)
end

function doCondCheck(self, class, mode, lv, ...)
    if class == "OR" then
        for _, v in pairs({mode, lv, ...}) do
            if self:doCondCheck(unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then
        for _, v in pairs({mode, lv, ...}) do
            if not self:doCondCheck(unpack(v)) then return false end
        end
        return true

    elseif class == resmng.CLASS_RES then
        return self:get_res_num(mode) >= lv


    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            local c = t.Class
            local m = t.Mode
            local l = t.Lv
            for _, v in pairs(self:get_build()) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = Data.prop_genius[ mode ]
        if t then
            local c = t.class
            local m = t.mode
            local l = t.lv
            for _, v in pairs(self.genius) do
                local n = Data.prop_genius[ v ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_TECH then
        local t = resmng.get_conf("prop_tech", mode)
        if t then
            for _, v in pairs(self.tech) do
                local n = resmng.get_conf("prop_tech", v)
                if n and t.Class == n.Class and t.Mode == n.Mode and t.Lv <= n.Lv then
                    return true
                end
            end
        end
    elseif class == resmng.CLASS_ITEM then
        return self:get_item_num(mode) >= lv
    elseif class == resmng.CLASS_PLAYER_LEVEL then
        return self.lv >= mode
    elseif class == resmng.CLASS_UNION_LEVEL then
        local union = unionmng.get_union(self:get_uid())
        if union == nil then
            return false
        end
        return union.level >= mode
    end

    -- default return false
    return false
end

function condCheck(self, tab)
    if tab then
        for _, v in pairs(tab) do
            if not self:doCondCheck(unpack(v)) then return false end
        end
    end
    return true
end

function consCheck(self, tab, num)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not self:doCondCheck(class, mode, lv * num) then return false end
        end
    end
    return true
end

function consume(self, tab, num, why)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not self:doConsume(class, mode, lv * num, why) then return false end
        end
    end
end

function doConsume(self, class, mode, num, why)
    if class == resmng.CLASS_RES then
        --return self:doUpdateRes(mode, -num, why)
        self:do_dec_res(mode, num, why)
        return true

    elseif class == resmng.CLASS_ITEM then
        return self:dec_item_by_item_id(mode, num, why)
    end
end

function obtain(self, tab, num, why)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not self:doObtain(class, mode, math.ceil(lv * num), why) then return false end
        end
    end
end

function doObtain(self, class, mode, num, why)
    if class == resmng.CLASS_RES then
        --return self:doUpdateRes(mode, -num, why)
        self:do_inc_res_normal(mode, num, why)
    elseif class == resmng.CLASS_RES_PROTECT then
        self:do_inc_res_protect(mode, num, why)
    elseif class == resmng.CLASS_ITEM then
        self:inc_item(mode, num, why)
    end
    return true
end



player_t.bonus_func = {}
player_t.bonus_func["mutual_award"] = function(self, tab)
    local get_tab = {}
    if tab ~= nil then
        local p = math.random(AWARD_RANDOM_SUM)
        local cur_p = 0
        local msg_notify = {}
        for k, v in pairs(tab) do
            local class, mode, num, pro = unpack(v)
            pro = pro or AWARD_RANDOM_SUM
            cur_p = cur_p + pro
            if cur_p >= p then
                table.insert(get_tab, {class, mode, num})
                return get_tab
            end
        end
    end
    return get_tab
end

player_t.bonus_func["mutex_award"] = function(self, tab)
    local get_tab = {}
    if tab ~= nil then
        for k, v in pairs(tab) do
            local class, mode, num, pro = unpack(v)
            pro = pro or AWARD_RANDOM_SUM
            local p = math.random(AWARD_RANDOM_SUM)
            if pro >= p then
                table.insert(get_tab, {class, mode, num})
            end
        end
    end
    return get_tab
end

function add_bonus(self, bonus_policy, tab, reason, ratio, sup_open)
    if bonus_policy == nil or tab == nil or reason == nil then
        return false
    end
    ratio = ratio or 1
    sup_open = sup_open or true
    local get_tab = player_t.bonus_func[bonus_policy](self, tab)
    if get_tab and #get_tab > 0 then
        local msg_notify = {}
        for k, v in pairs(get_tab) do
            self:do_add_bonus(v[1], v[2], v[3], ratio, reason, sup_open)
            v[3] = v[3] * ratio
            table.insert(msg_notify, v)
        end
        Rpc:notify_bonus(self, msg_notify)
    end
    return true
end

function do_add_bonus(self, class, mode, num, ratio, reason, sup_open)
    local real_num = math.floor(num * ratio)
    if class == "item" then
        if sup_open == true then --获得礼包直接打开
            local prop_tab = resmng.get_conf("prop_item", mode)
            if prop_tab == nil then
                return
            end
            for _, info in pairs(prop_tab.Param) do
                self:add_bonus(info[1], info[2], reason, 1, false)
            end
        else
            self:addItem(mode, real_num)
        end
    elseif class == "res" then
        self:do_inc_res_normal(mode, real_num, reason)
    elseif class == "respicked" then
        self:do_inc_res_protect(mode, real_num, reason)
    elseif class == "exp" then
        real_num = math.random(mode, num) * ratio
        self:add_exp(real_num)
    elseif class == "solider" then
        self:inc_arm(mode, real_num)
    elseif class == "heroexp" then
        local hero = heromng.get_hero_by_uniq_id(mode)
        if hero ~= nil then
            real_num = math.random(mode, num) * ratio
            hero:gain_exp(real_num)
        end
    elseif class == "hero" then
        self:make_hero(mode)
    end
end

function add_bonus_not_notify(self, bonus_policy, tab, reason, ratio)
    if bonus_policy == nil or tab == nil or reason == nil then
        return false
    end
    ratio = ratio or 1
    local get_tab = player_t.bonus_func[bonus_policy](self, tab)
    if get_tab and #get_tab > 0 then
        for k, v in pairs(get_tab) do
            self:do_add_bonus(v[1], v[2], v[3], ratio, reason)
        end
    end
    return true
end

function getCureTime(t)
    return 10
end

function cure(self, hurt)
    local t = {}
    for k, v in pairs(hurt) do
        table.insert(t, {k, v})
    end
    self.tm_cure = timer.new("cure", self:getCureTime(t), self.pid, t)
end

-- when troop march through the country boundary
function qryCross(self, toPid, cmd, param)
    local sn = getSn("qryCross")
    local smap = gMapID
    local spid = self.pid

    LOG("qryCross, smap=%d, sn=%d", smap, sn)
    Rpc:onQryCross(_G.gAgent, toPid, sn, smap, spid, cmd, param)
    return putCoroPend("rpc", sn)
end

function onQryCross(self, toPid, sn, smap, spid, cmd, arg)
    LOG("onQryCross, toPid=%d, smap=%d, spid=%d, sn=%d, cmd=%s", toPid, smap, spid, sn, cmd)
    dumpTab(arg, "QryCross")
    local code = 0
    Rpc:onAckCross(_G.gAgent, smap, sn, code, arg)
end

function onAckCross(self, smap, sn, code, res)
    LOG("onAckCross, smap=%d, sn=%d, code=%d", smap, sn, code)
    if code == 0 then dumpTab(res, "AckCross") end
    local co = getCoroPend("rpc", sn)
    if co then
        coroutine.resume(co, code, res)
    end
end

function testQryCross(self)
    -- -2, the pid is minus, means the map 2, pid 0
    local code, tab = self:qryCross(2, "sayHello", {a=1, b="string"})
    LOG("qryCross, code=%d", code)
    if code == 0 then dumpTab(tab) end
end

local function sendCertify(proc, code)
    pushHead(gateid, 0, gNetPt.NET_CERTIFY)  -- NET_CERTIFY
    pushInt(code)
    pushString(proc)
    pushOver()
end


function gm_user(self, cmd)
    local tb = string.split(cmd, "=")
    local choose = tb[1]

    function get_parm(idx)
        if idx < 1 or tb[idx + 1] == nil then
            return 0
        end
        return tb[idx + 1]
    end

    if choose == "addexp" then
        local value = get_parm(1)
        self:add_exp(tonumber(value))

    elseif choose == "clearcure" then
        self.cures = {}
        self:cure_off()
        self.tm_cure = 0
        self.cure_start = 0
        self.cure_over = 0
        self.hurts = {}

    elseif choose == "cleartw" then
        local union = self:union()
        if union then
            union_t.clear_declare(union, 1)
        end
        npc_city.clear_union()
    elseif choose == "starttw" then
        npc_city.start_tw()
    elseif choose == "fighttw" then
        npc_city.fight_tw()
    elseif choose == "endtw" then
        npc_city.end_tw()
    elseif choose == "buildall" then
        self:build_all()
    elseif choose == "addnpc" then -- 给自己增加npc城市
        local union = self:union()
        if union then
            local eid = tonumber(tb[2])
            local npcCitys = union.npc_citys
            npcCitys[eid] = eid
            union.npc_citys = npcCitys
            local npc = get_ety(eid)
            if npc then
                npc.uid = union.uid
            end
        end
    elseif choose  == "startmc" then -- 开启怪物攻城
        local union = self:union()
        if union then
            union_t.set_mc_state(union, 1)
        end
    elseif choose == "mc" then
        local step = tonumber(tb[2])
        local union = self:union()
        if union then
            union_t.set_mc_state(union, step)
        end
    elseif choose == "startkw" then
        --king_city.unlock_kw()
        king_city.prepare_kw()
    elseif choose == "fightkw" then
        king_city.fight_kw()
    elseif choose == "clearkw" then
        king_city.clear_officer()
    elseif choose == "peacekw" then
        king_city.pace_kw()
    elseif choose == "king" then
        king_city.select_default_king()
    elseif choose == "kingct" then --世界boss 加积分
        local uid = tonumber(tb[2])
        local kingCity = king_city.get_king() 
        kingCity.uid = uid
    elseif choose == "addscore" then --世界boss 加积分
        local score = tonumber(tb[2])
        monster.bossKillScore.score = score
        gPendingSave.status[ "bossKillScore" ].score =  score
        monster.try_upgrade_stage()

    elseif choose == "daypass" then  -- 世界boss跨天
        monster.on_day_pass()

    elseif choose == "getsoldier" then
        self:inc_arm(1001, 100000)
        self:inc_arm(2001, 100000)
        self:inc_arm(3001, 100000)
        self:inc_arm(4001, 100000)
        local my_troop = self:get_my_troop()
        Rpc:upd_arm(self, my_troop.arms[ self.pid ].live_soldier)

        self:recalc_food_consume()

    elseif choose == "addarm" then
        local id = tonumber(tb[2])
        local num = tonumber(tb[3])
        self:inc_arm(id, num)
        local my_troop = self:get_my_troop()
        Rpc:upd_arm(self, my_troop.arms[ self.pid ].live_soldier)

        self:recalc_food_consume()

    elseif choose == "addgold" then
        local num = tonumber(tb[2])
        self.gold = num


    elseif choose == "skill" then
        self:launch_talent_skill(tonumber(get_parm(1)))
    elseif choose == "reload" then
        os.execute("./reload.sh")
        do_load("resmng")
        Rpc:chat(self, 0, 0, 0, "system", "ok")

    elseif choose == "ef_add" then
        local key = tb[2]
        local val = tonumber(tb[3])
        self:ef_add({[ key ] = val })

    elseif choose == "set_val" then
        local key = tb[2]
        local val = tonumber(tb[3])
        self[ key ] = val

    elseif choose == "mars_tm" then
        self._union.god_log.tm = 0
    elseif choose == "all" then
        self:build_all()
        self:ef_add({CountTroop=10, CountSoldier=0, Captive=100000, CounterCaptive=100000 })
        self:inc_arm(1010, 100000)
        self:inc_arm(2010, 100000)
        self:inc_arm(3010, 100000)
        self:inc_arm(4010, 100000)
        union_item.add(self,2009001,UNION_ITEM.TASK)--加入军团礼物
        for _, h in pairs(self._hero or {}) do h.hp = h.max_hp end

        self:recalc_food_consume()

        local troop = self:get_my_troop()
        if troop then Rpc:upd_arm(self, troop:get_live(self.pid)) end

        local union = self:union()
        if union then
            union.donate = union.donate + 9900000 
        end
        self._union.donate = self._union.donate + 9900000 
        gPendingSave.union_member[self.pid] = self._union 

    elseif choose == "test" then
        self.hurts = {}
        self.cures = {}
        local troop = self:get_my_troop()
        troop.arms[ self.pid ].live_soldier = { [1010]=10000 } 
        Rpc:upd_arm(self, troop:get_live(self.pid))


    elseif choose == "additem" then
        local itemid = tonumber(tb[2])
        local itemnum = tonumber(tb[3])
        local conf = resmng.get_conf("prop_item", itemid)
        if conf and itemnum > 0 then
            self:add_debug(string.format("additem, %d, %d", itemid, itemnum))
            self:inc_item(itemid, itemnum, VALUE_CHANGE_REASON.DEBUG)
        end

    elseif choose == "addequip" then
        local id = tonumber(tb[2])
        if resmng.prop_equip[ id ] then
            self:equip_add( id, VALUE_CHANGE_REASON.DEBUG )
        end

    elseif choose == "addres" then
        local mode = tonumber(tb[2])
        local num = tonumber(tb[3])
        self:do_inc_res_normal(mode, num, VALUE_CHANGE_REASON.DEBUG)

    elseif choose == "back" then
        for _, tid in pairs(self.busy_troop_ids) do
            self:troop_recall(tid)
        end

    elseif choose == "addallitem" then
        local its = {
            {1, 4001001, 100},
            {2, 4001002, 100},
            {3, 4001003, 100},
            {4, 4001004, 100},

            -- 碎片
            {5, 4002001, 10000000},
            {6, 4002002, 10000000},
            {7, 4002003, 10000000},
            {8, 4002004, 10000000},

            -- 经验书
            {9, 4003001, 100},
            {10, 4003002, 100},
            {11, 4003003, 100},

            -- 特定技能书
            {12, 5001101, 10000000},
            {13, 5001201, 10000000},
            {14, 5001301, 10000000},
            {15, 5001401, 10000000},
            {16, 5001501, 10000000},
            {17, 5001601, 10000000},

            -- 通用技能书
            {22, 5002001, 100},
            {23, 5002002, 100},
            {24, 5002003, 100},
            {25, 5002004, 100},

            -- 重置技能书
            {26, 5003001, 100},

            -- 城建加速
            --{27, 3000001, 100},
            --{28, 3000002, 100},
            --{29, 3001001, 100},
            --{30, 3001002, 100},
            --{31, 3002001, 100},
            --{32, 3002002, 100},
            --{33, 3003001, 100},
            --{34, 3003002, 100},

            --{35, 6001001, 100},
            --{36, 6001002, 100},
        }

        for k, v in pairs(its) do
            self:inc_item(v[2], v[3], VALUE_CHANGE_REASON.DEBUG)
        end
    elseif choose == "dailyactivity" then
        self.activity = tonumber(get_parm(1))
    elseif choose == "dailyresetbox" then
        self.activity_box = {}
    elseif choose == "finishtask" then
        local task_id = tonumber(get_parm(1))
        self:gm_finish_task(task_id)
    elseif choose == "accepttask" then
        local task_id = tonumber(get_parm(1))
        self:gm_accept_task(task_id)
    elseif choose == "cleargacha" then
        self.gacha_yinbi_num = 0  --银币抽卡次数
        self.gacha_jinbi_num = 0  --金币抽卡次数
        self.gacha_yinbi_cd = 0
        self.gacha_jinbi_cd = 0
        self.gacha_gift = 0  --抽卡奖励值
        self.gacha_box = 0  --抽卡奖励值箱子
        self:inc_item(20001003, 100, VALUE_CHANGE_REASON.DEBUG)
    elseif choose == "setvip" then
        self.vip_lv = tonumber(get_parm(1))
    elseif choose == "sanshi" then
        self:inc_item(1001001, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(1001002, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(1001003, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(4001001, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(4001002, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(4001003, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(4001004, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(8001001, 10, VALUE_CHANGE_REASON.DEBUG)
        self:inc_item(8007001, 20, VALUE_CHANGE_REASON.DEBUG)
    end
end

function qryInfo(self, aid)
    if aid == 0 then aid = self.pid end
    local p = getPlayer(aid)
    if p then
        Rpc:qryInfo(self, p._pro)
    end
end

function loadData(self, what)
    local t = {}
    t.key = what
    if what == "pro" then
        t.val = self._pro

    elseif what == "item" then
        t.val = self:get_item()

    elseif what == "equip" then
        t.val = self:get_equip()

    elseif what == "ef" then
        t.val = self._ef

    elseif what == "ef_hero" then
        t.val = self._ef_hero

    elseif what == "build" then
        local ts = {}
        local count = 0

        for k, v in pairs(self:get_build() or {}) do
            table.insert(ts, v._pro)
            count = count + 1
        end
        t.val = ts

    elseif what == "tech" then
        t.val = self.tech

    elseif what == "hero" then
        local ts = {}
        for k, v in pairs(self._hero or {}) do
            local h = copyTab(v._pro)
            table.insert(ts, h)
        end
        t.val = ts

    elseif what == "troop" then
        local data = {}
        for _, tid in pairs(self.busy_troop_ids) do
            local tr = troop_mng.get_troop(tid)
            if tr then
                table.insert( data, tr:get_info() )
            end
        end
        t.val = data

    elseif what == "ache" then

    elseif what == "arm" then
        local my_troop = troop_mng.get_troop(self.my_troop_id)
        if my_troop ~= nil then
            local a = my_troop.arms[ self.pid ]
            if a then a = a.live_soldier end
            if not a then a = {} end
            t.val = a
        end
        
    elseif what == "task" then
        t.val = self:packet_all_task_id()

    elseif what == "done" then

    elseif what == "watch_tower" then
        t.val = self:packet_watchtower_info()
    end

    if not t.val then t.val = {} end
    LOG("loadData, pid=%d, what=%s", self.pid, what)
    Rpc:loadData(self, t)
    --self:addTips("hello", {1,"hello", {"hello", {"world"}}} )
end

function addEye(self)
    local x = self.x
    local y = self.y
    local lv = 0
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end
    c_add_eye(x, y, lv, self.pid, self.gid)
end

function get_room(self,rid)
    local info = room.get_info(rid)
    Rpc:get_room(self, rid,info)
end


function qryblock(self, ...)
    local pid = self.pid
    local gid = self.gid
    for _, v in pairs({...}) do
        if v >= 0 then
            c_qry_block(pid, gid, v)
        end
    end
end

function remEye(self)
    c_rem_eye(self.pid)
end

function movEye(self, x, y)
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end
    LOG("moveEye, x=%d, y=%d, x=%s, y=%s", x,y,x/16, y/16)
    c_mov_eye(self.pid, x, y)
end

function say(self, saying, i)
    LOG("pid=%d, say, i=%d, frame=%d", self.pid, i, gFrame)
    Rpc:say1(self, saying, i)
end


function runCommand(self, str)
    function run()
        Rpc:runCommand(self, {info=loadstring(str)()})
    end
    local result = xpcall(run, function(e)
        WARN(e..debug.stack(1))
        --Rpc:runCommand(self, {err=e, stack=debug.traceback()})
    end)
end

function can_food(self,num)
    local foodUse = self.foodUse * self:get_num("FoodUse_R")
    local use = math.ceil((gTime - self.foodTm) *  foodUse / 3600)
    local have = self.food

    if use >= have then
        have = 0
    else
        have = have - use
    end

    return have > num
end

function resetfood(self)
    local foodUse = self.foodUse * self:get_num("FoodUse_R")
    local use = math.ceil((gTime - self.foodTm) *  foodUse / 3600)
    local have = self.food
    if use >= have then have = 0
    else have = have - use end

    self.food = have
    self.foodTm = gTime

    --if save then self:save("player", self.pid, {food=have, foodTm=gTime}) end
    return self.food
end


--------------------------------------------------------------------------------
-- Function : 查询玩家资源数量
-- Argument : self, res_type
-- Return   : succ - number; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_res_num(self, mode)
    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            return self[ key ] or 0
        end
    else
        local node = self.res[ mode ]
        if node then
            if mode == resmng.DEF_RES_FOOD then
                local store = self:get_val("CountStore")
                if store > node[1] then
                    return node[1] + node[2] 
                else
                    local consume = self.foodUse * (gTime - self.foodTm) / 3600
                    local have = node[1] - consume
                    if have < store then have = store end
                    return have + node[2]
                end
            else
                return node[1] + node[2]
            end
        end
    end
    return 0
end

function get_res_num_normal(self, mode)
    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            return self[ key ] or 0
        end
    else
        local node = self.res[ mode ]
        if node then
            if mode == resmng.DEF_RES_FOOD then
                local store = self:get_val("CountStore")
                if store > node[1] then
                    return node[1]
                else
                    local consume = self.foodUse * (gTime - self.foodTm) / 3600
                    local have = node[1] - consume
                    if have < store then have = store end
                    return have
                end
            else
                return node[1]
            end
        end
    end
    return 0
end

function refresh_food(self)
    local node = self.res[ resmng.DEF_RES_FOOD ]
    local store = self:get_val("CountStore")
    if store > node[1] then
        self.foodTm = gTime
    else
        local consume = self.foodUse * (gTime - self.foodTm) / 3600
        local have = node[1] - consume
        if have < store then have = store end
        have = math.floor(have)
        node[1] = have
        self.foodTm = gTime
    end
end

function get_sinew( self )
    local sinew, tm = recalc_sinew( self.sinew, self.tm_sinew, gTime, 1)
    return sinew
end


function dec_sinew( self, num )
    if num < 0 then return end
    self:do_recalc_sinew()
    local val = self.sinew - num
    if val < 0 then val = 0 end
    self.sinew = val
end

function inc_sinew( self, num )
    if num < 0 then return end
    self:do_recalc_sinew()
    self.sinew = self.sinew + num
end

function do_recalc_sinew( self )
    self.sinew, self.tm_sinew = recalc_sinew( self.sinew, self.tm_sinew, gTime, 1)
end

function recalc_food_consume(self)
    self:refresh_food()
    local consume = 0
    for _, tid in pairs(self.busy_troop_ids) do
        local troop = troop_mng.get_troop(tid)
        if troop and troop.arms then
            local arm = troop.arms[ self.pid ]
            if arm then
                for id, num in pairs(arm.live_soldier or {}) do
                    local conf = resmng.get_conf("prop_arm", id)
                    if conf then
                        consume = consume + conf.Consume * num
                    end
                end
            end
        end
    end

    local home = troop_mng.get_troop(self.my_troop_id)
    if home then
        local arm = home.arms[ self.pid ]
        if arm then
            for id, num in pairs(arm.live_soldier) do
                local conf = resmng.get_conf("prop_arm", id)
                if conf then
                    consume = consume + conf.Consume * num
                end
            end
        end
    end

    local b, m, a = get_nums_by("SpeedConsume_R", self._ef)
    consume = consume * (1 + m * 0.0001) + a
    self.foodTm = gTime
    self.foodUse = math.floor(consume)
end

function do_inc_res_protect(self, mode, num, reason)
    if not reason then
        ERROR("do_inc_res_normal: pid = %d, don't use the default reason.", self.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then 
        WARN("do_inc_res, pid=%d, num=%d, reason=%s, num<0", self.pid, num, reason)
        return
    end
    INFO("do_inc_res_protect, pid=%d, num=%d, reason=%s", self.pid, num, reason)

    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            self[ key ] = (self[ key ] or 0) + num
        end
    else
        local node = self.res[ mode ]
        if not node then return end
        node[2] = node[2] + num
        self.res = self.res
    end
end

function do_inc_res_normal(self, mode, num, reason)
    if not reason then
        ERROR("do_inc_res_normal: pid = %d, don't use the default reason.", self.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then 
        WARN("do_inc_res, pid=%d, num=%d, reason=%s, num<0", self.pid, num, reason)
        return
    end
    INFO("do_inc_res_normal, pid=%d, num=%d, reason=%s", self.pid, num, reason)

    if mode == resmng.DEF_RES_MARSEXP then
        union_god.add_exp(self,num) 
    elseif mode == resmng.DEF_RES_PERSONALHONOR then
        union_member_t.add_donate(self,num)
    elseif mode == resmng.DEF_RES_UNITHONOR then
        local union = unionmng.get_union(self:get_uid())
        if union then
            union:add_donate(num,self)
        end
    elseif mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            self[ key ] = math.floor((self[ key ] or 0) + num)
        end
    else
        local node = self.res[ mode ]
        if not node then return end
        if mode == resmng.DEF_RES_FOOD then self:refresh_food() end
        node[1] = math.floor(node[1] + num)
        self.res = self.res
    end
end

function do_dec_res(self, mode, num, reason)
    if not reason then
        ERROR("do_dec_res: pid = %d, don't use the default reason.", self.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then 
        WARN("do_dec_res, pid=%d, num=%d, reason=%s, num>=0", self.pid, num, reason)
        return
    end

    num = math.floor(num)

    INFO("do_dec_res, pid=%d, num=%d, reason=%s", self.pid, num, reason)

    local enough = true
    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            if self[ key ] and self[ key ] > num then
                self[ key ] = math.floor(self[ key ] - num)
            else
                self[ key ] = 0
                enough = false
            end
        end
    else
        local node = self.res[ mode ]
        if not node then return end

        if mode == resmng.DEF_RES_FOOD then self:refresh_food() end
        if node[1] >= num then
            node[1] = math.floor(node[1] - num)
        else
            num = num - node[1]
            node[1] = 0
            node[2] = math.floor(node[2] - num)
            if node[2] < 0 then 
                node[2] = 0 
                enough = false
            end
        end
        self.res = self.res
    end
    return enough

end
-- resource function new
-- resource function new
--

function doUpdateRes(self, mode, num, reason)
    -- TODO: 校验 num 大小是否合法

    local what = resmng.prop_resource[mode].CodeKey
    if not what then
        ERROR("doUpdateRes: wrong resource mode. pid = %d, mode = %d", self.pid, mode or -1)
        return false
    end

    reason = reason or VALUE_CHANGE_REASON.DEFAULT
    if reason == VALUE_CHANGE_REASON.DEFAULT then
        ERROR("doUpdateRes: pid = %d, don't use the default reason.", self.pid)
    end

    if what == "food" then
        local useSpeed = self.foodUse * self:get_num("FoodUse_R")
        local use = math.ceil((gTime - self.foodTm) * useSpeed / 3600)
        local have = self.food - use

        if have < 0 then have = 0 end
        local old = have
        have = have + num
        if have == 0 then have = 0 end
        self.food = have
        self.foodTm = gTime
        local tips = string.format("doUpdateRes: pid=%d, what=%s, num=%s, %d->%d, reason=%d", self.pid, what, num, old, have, reason)
        INFO(tips)
    else
        local have = self[ what ] or 0
        if have < 0 then have = 0 end
        local old = have
        have = have + num
        if have < 0 then have = 0 end
        self[ what ] = have
        local tips = string.format("doUpdateRes: pid=%d, what=%s, num=%s, %d->%d, reason=%d", self.pid, what, num, old, have, reason)
        INFO(tips)
    end
    return true
end


function get_build_queue(self)
    local num = 0
    for k, v in pairs(self:get_build()) do
        if v.state == BUILD_STATE.CREATE or v.state == BUILD_STATE.UPGRADE then
            num = num + 1
        end
    end
    return num
end

function reCalcFood(self)
    self:resetfood()
    local use = 0
    local live = self:get_live()
    for k, v in pairs(live or {}) do
        local node = resmng.prop_arm[k]
        if node ~= nil then
            use = use + node.Consume * v
        end
    end

    for k, v in pairs(self.busy_troop_ids) do
        local troop = troop_mng.get_troop(v)
        local arm = troop:get_arm_by_pid(self.pid)
        if arm ~= nil then
            for i, j in pairs(arm.soldier or {}) do
                local node = resmng.prop_arm[i]
                if node ~= nil then
                    use = use + node.Consume * j
                end
            end
        end
    end

    use = math.ceil(use)
    --self.foodUse = use
    self.foodUse = 10
    self.foodTm = gTime
end

-- todo just for test
function addArm(self)
    for k, v in pairs(resmng.prop_arm) do
        self:inc_arm(k, 20000)
    end
    self:recalc_food_consume()
    self:loadData("arm")
end

function addRes(self)
    self.food = (self.food or 0) + 10000
    self.wood = (self.wood or 0) + 10000
end


function troop_init(self, objs, troop)
    for _, v in pairs(objs) do
        local arm = v[1]
        local num = v[2]
        add_soldier(arm, num, troop)
    end
end

function addTips(self, tips, tipt)
    --if tipt then
    --    local str = ""
    --    if type(tipt) == "table" then
    --        str = string.format("%s = %s", tips, sz_T2S(tipt))
    --    else
    --        str = string.format("%s = %s", tips, tostring(tipt))
    --    end
    --    Rpc:tips(self, str, {})
    --else
    --    Rpc:tips(self, tips)
    --end
end

function say2(self, a1, a2, a3)
    LOG("say2, a1=%d, a2[1]=%s, a3=%d", a1, a2["1"], a3)
    dumpTab(a2)
end

function testPack(self, i1, p2, s3)
    LOG("testPack, i1=%d, s3=%s", i1,s3)
    LOG("testPack, pack = ")
    dumpTab(p2)
    Rpc:testPack(self, i1, p2, s3)
end

function add_debug(self, val)
    --Rpc:chat(self, 0, 0, 0, "debug", val)
    Rpc:notify_server(self, val)
end

function chat(self, channel, word, sn)
    --gm
    if config.IsEnableGm == 1 then
        local ctr = string.sub(word, 1, 1)
        if ctr == "@" then
            self:gm_user(string.sub(word, 2, -1))
            return
        end
    end

    if channel == resmng.ChatChanelEnum.World then
        --local count = math.random(1,1024)
        --word = string.rep( word, count, "_" )
        Rpc:chat({pid=-1,gid=_G.GateSid}, channel, self.pid, self.photo, self.name, word)
        --Rpc:chat({self.pid,27001}, channel, self.pid, self.photo, self.name, word)


    elseif channel == resmng.ChatChanelEnum.Union then
        local u = self:union()
        if not u then return end
        local pids = {}
        for pid, v in pairs(u._members) do
            if v:is_online() then
                table.insert(pids, pid)
            end
        end
        Rpc:chat(pids, channel, self.pid, self.photo, self.name, word)

    elseif channel == resmng.ChatChanelEnum.Culture then
        local pids = {}
        local culture = self.culture
        for pid, v in pairs(gPlys) do
            if v.culture == culture and v:is_online() then
                table.insert(pids, pid)
            end
        end
        Rpc:chat(pids, channel, self.pid, self.photo, self.name, word)
    end

    reply_ok(self, "chat", sn)
end


function reset_genius( self, mode )
    if self.lv >= 20 then
        self.talent = self.lv - 10
        self.genius = {}
    end
end

function do_genius(self, id)
    if (self.talent or 0) < 1 then return end

    local conf = resmng.get_conf("prop_genius", id)
    if not conf then
        ERROR("do_genius: get prop_genius config failed. pid = %d, genius_id = %d.", self.pid, id)
        return
    end

    if not self:condCheck(conf.cond) then return end

    local tab = self.genius or {}
    if conf.Lv > 1 then
        local old_id = id - 1
        local old_conf = resmng.get_conf("prop_genius", old_id)
        if not old_conf then
            ERROR("do_genius: get prop_genius config failed. pid = %d, old_genius_id = %d.", self.pid, old_id)
            return
        else
            local idx = is_in_table(tab, old_id)
            if idx then
                table.remove(tab, idx)
                self:ef_rem(old_conf.Effect)
            else
                return 
            end
        end
    else
        if is_in_table( tab, id ) then return end
    end

    table.insert(tab, id)
    self:ef_add(conf.Effect)
    self.genius = tab
    self.talent = self.talent-1
end


function notify(self, chg)
    Rpc:statePro(self, chg)
end

function query_fight_info(self, fid)
    local node = fight.gFightReports[ fid ]
    if node then
        --dumpTab(node[2], "query_fight_info")
        Rpc:fightInfo(self, node[2])
    else
        reply_ok(self, "query_fight_info", 0, E_NO_REPORT)
    end
end

function migrate(self, x, y)
    if #self.busy_troop_ids > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end
    if c_map_test_pos(x, y, 4) ~= 0 then return ack(self, "migrate", resmng.E_NO_ROOM, 0) end
    if not self:can_move_to(x, y)  then return self:add_debug("can not move by castle lv") end

    c_rem_ety(self.eid)
    self.x = x
    self.y = y
    etypipe.add(self)
    reply_ok(self, "migrate", y*65536+x)
end

function get_active(self)
    return self.active
end

function add_exp(self, value)
    if value <= 0 then
        return
    end

    local limit_level = #resmng.prop_level
    local add_exp = value
    local old_level = self.lv
    while(true) do
        if self.lv >= limit_level then
            break
        end
        local limit_exp = resmng.prop_level[self.lv + 1].Exp
        local need_exp = limit_exp - self.exp
        if add_exp >= need_exp then
            self.lv = self.lv + 1
            self.exp = 0
            add_exp = add_exp - need_exp

            if self.lv == 20 then 
                self.talent = 10
            elseif self.lv > 20 then 
                self.talent = self.talent + 1 
            end
        else
            self.exp = self.exp + add_exp
            break
        end
    end

    if self.lv > old_level then
        --升级触发全部写到这个函数
        self:on_level_up(old_level, self.lv)
    end
end

function on_level_up(self, old_level, new_level)
    local diff = new_level - old_level
    self:inc_pow( resmng.prop_level[ new_level ].Pow - resmng.prop_level[ old_level ].Pow )

    --升级要触发事情
    --任务
    task_logic_t.process_task(self, TASK_ACTION.ROLE_LEVEL_UP)
end

function on_day_pass(self)
    self.cross_time = gTime
    self:on_day_pass_online_award()
    self:on_day_pass_month_award()
    self:on_day_pass_daily_task()
    self:refresh_black_marcket()
    self:refresh_res_market()
    self:gacha_on_day_pass()
end



function change_name(self, name)
    for k, v in pairs(gPlys) do
        if v.name == name then
            ack(self, "change_name", resmng.E_DUP_NAME)
            return
        end
    end
    self.name = name
    etypipe.add(self)
end

init()

function reply_ok(self, funcname, d1)
    ack(self, funcname, resmng.E_OK, d1 or 0)
end


--------------------------------------------------------------------------------
-- Function : 计算消除CD所需的金币
-- Argument : self, cd
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_cd_golds(self, cd)
    -- TODO: 策划规则未定
    return cd
end

function do_load_equip(self)
    local db = self:getDb()
    --local info = db.equip:find({pid=self.pid, pos={["$gte"]=0}})
    local info = db.equip:find({pid=self.pid})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[ b._id ] = b
    end
    return bs
end

function get_equip(self, id)
    if not self._equip then self._equip = self:do_load_equip() end
    if id then
        return self._equip[ id ]
    else
        return self._equip
    end
end

function equip_add(self, propid, why)
    local id = getId("equip")
    local t = {_id = id, propid=propid, pid=self.pid, pos=0}
    gPendingSave.equip[ id ] = t
    self:get_equip()
    self._equip[ id ] = t
    Rpc:equip_add(self, t)

    INFO("equip_add: pid = %d, item_id = %d, reason = %d.", self.pid, propid, why)
end

function equip_rem(self, id, why)
    self:get_equip()
    self._equip[ id ] = nil
    gPendingSave.equip[ id ].pos = -1
    Rpc:equip_rem(self, id)

    INFO("equip_add: pid = %d, item_sn = %d, reason = %d.", self.pid, id, why)
end

function equip_on(self, id)
    local n = self:get_equip(id)
    if not n then return end
    if n.pos > 0 then return end
    local prop = resmng.get_conf("prop_equip", n.propid)
    if not prop then return end
    local idx = prop.Pos

    local ns = self:get_equip()
    for _, v in pairs(ns) do
        if v.pos == idx then return end
    end

    self:inc_pow(prop.Pow)
    self:ef_add(prop.Effect)
    n.pos = idx

    gPendingSave.equip[ id ].pos = idx
    reply_ok(self, "equip_on", id)
end

function equip_off(self, id)
    local n = self:get_equip(id)
    if not n then return end
    if n.pos == 0 then return end
    n.pos = 0
    gPendingSave.equip[ id ].pos = 0

    local conf = resmng.get_conf("prop_equip", n.propid)
    if conf then
        self:ef_rem(conf.Effect)
        if conf.Pow then self:dec_pow(conf.Pow) end
    end
    reply_ok(self, "equip_off", id)
end

function require_online_award_time(self)
    local is_end = self:is_online_award_end()
    if is_end == true then
        Rpc:get_online_award_time_resp(self, 1, 0)
        return
    end
    local timestamp = self:get_online_award_next_time()
    Rpc:get_online_award_time_resp(self, 0, timestamp)
end

function require_online_award(self)
   self:get_online_award()
   local timestamp = self:get_online_award_next_time()
   if timestamp == -1 then
       Rpc:get_online_award_time_resp(self, 1, 0)
   else
       Rpc:get_online_award_time_resp(self, 0, timestamp)
   end
end

function require_month_award_process(self)
   local cur_day = get_diff_days(gSysStatus.start, self.month_award_time)
   local month_day = cur_day % 28
   local can_get = 0
   if get_diff_days(gTime, self.month_award_time) > 0 then
       can_get = 1
   end

   Rpc:month_award_process_resp(self, month_day, can_get)
end

function require_get_month_award(self)
    local res = self:month_award_compensation()
    if res == true then res = 1 else res = 0 end
    Rpc:month_award_get_award_resp(self, res)
end

function require_month_award_com(self)
    local res = self:month_award_get_award()
    if res == true then res = 1 else res = 0 end
    Rpc:month_award_com_resp(self, res)
end

function get_cured_left_num(self)
    return 1000
end

function push_hurt_soldier(self, tab)
    local left_num = get_cured_left_num()

end
--------------------------------------
----npc city
--
function get_union_npc_req(self)
    local union = unionmng.get_union(self.uid)
    local npc_citys = {}
    if union then
        for k, v in pairs(union.npc_citys) do
            local city = get_ety(v)
            if city then
                table.insert(npc_citys, city.propid)
            end
        end
        local pack = {}
        pack.npc_citys = npc_citys
        Rpc:get_union_npc_ack(self, pack)
    end
end

function abd_npc_req(self, eid)
    npc_city.abd_npc_req(self, eid)
end

function get_tw_random_award_req(self, eid)
    npc_city.get_random_awrd(self.pid, eid)
end

function get_can_atk_citys_req(self)
    local pack = {}
    local union = unionmng.get_union(self.uid)
    if union then
        union:union_can_atk_citys()
        pack.can_atk_citys = union.can_atk_citys
    end
    Rpc:get_can_atk_citys_ack(self, pack)
end

function acc_tower_recover_req(eid) 
    local city = get_ety(eid)
    if city and  resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.TOWER then

    end
end

function get_npc_map_req(self)
    local pack = {}
    local map = {}
    for k, v in pairs(npc_city.citys) do
        local city = get_ety(k)
        if city then
            local union = unionmng.get_union(city.uid) or {}
            local name = union.name or ""
            table.insert(map, {city.eid, city.uid, name, city.propid})
        end
    end
    pack.map = map
    local union = self:union()
    if union then
        pack.atk = union.atk_id
        pack.def = union.def_id
    end
    Rpc:get_npc_map_ack(self, pack)
end

function tag_npc_req(self, act, eid)
    local union = self:union()
    if union then
        if act == 1 then
            if (union.atk_id or 0) == 0 and (union.def_id or 0) ~= eid then
                union.atk_id = eid
            end
        elseif act == 2 then
            if (union.def_id or 0) == 0 and (union.atk_id or 0) ~= eid then
                union.def_id = eid
            end
        end
    end
    local pack = {}
    pack.atk = union.atk_id
    pack.def = union.def_id
    Rpc:tag_npc_ack(self, pack)
end

function untag_npc_req(self, eid)
    local pack = {}
    local union = self:union()
    if union then
        if union.atk_id == eid then
            union.atk_id = 0
        elseif union.def_id == eid  then
            union.def_id = 0
        end
    end
    pack.atk = union.atk_id
    pack.def = union.def_id
    Rpc:tag_npc_ack(self, pack)
end


function get_union_npc_rank_req(self)
    local pack = {}
    local rank = npc_city.get_union_rank(1) or {}
    local top = {}
    for k, v in pairs(rank) do
        local union = unionmng.get_union(tonumber(v)) 
        if union then
            local score = npc_city.unionTwRank:score(v) or 0 
            table.insert(top, k, {v, union.name, score})
        end
    end
    pack.rank = top
    Rpc:get_union_npc_rank_ack(self, pack)
end

function npc_info_req(self, eid)
    local pack = {}
    local npc = get_ety(eid)
    if npc then
        npc_city.format_union(npc)
    end
    pack.unions = npc.unions or {}
    pack.state = npc.state
    pack.startTime = npc.startTime
    pack.endTime = npc.endTime
    pack.eid = npc.eid
    pack.propid = npc.propid
    Rpc:npc_info_ack(self, pack)
end

---npc city
------------------------------------


function boss_rank_req(self)
    local topKillers, myScore, myRank = monster.get_top_killer_rank(self.pid)
    local topHurts, score, rank = monster.get_top_hurter_rank(self.pid)

    local killInfo =  {}
    local hurtsInfo = {}
    for k, v in pairs(topKillers) do
        killInfo[k] = {get_ply_info( v ), monster.get_player_score("topKillerByPid", v)}
    end
    for k, v in pairs(topHurts) do
        hurtsInfo[k] = {get_ply_info(v), monster.get_player_score("topHurtByPid", v)}
    end
    local pack = {}
    pack.topKillers = killInfo
    pack.myKillScore = myScore
    pack.mykillRank = myRank
    pack.topHurts = hurtsInfo
    pack.myHurtScore = score
    pack.myHurtRank = rank
    Rpc:boss_rank_ack(self, pack)
end

function get_ply_info(pid)
    return gPlys[tonumber(pid)]
end

function get_hold_limit(self,dp)

    if not dp then return end
    local num ,limit=0,0
    local u = unionmng.get_union(dp.uid)
    if not u then return end

    local tr = troop_mng.get_troop(dp.my_troop_id)
    if tr then 
        num = tr:get_troop_total_soldier()
        for k, v in pairs(tr.mark_troop_ids or {}) do 
            local tm_troop = troop_mng.get_troop(v)
            if tm_troop then
                num = num + tm_troop:get_troop_total_soldier()
            end
        end
    end 

    for k, _ in pairs(dp.hold_troop  or {}) do 
        local tm_troop = troop_mng.get_troop(k)
        if tm_troop then
            num = num + tm_troop:get_troop_total_soldier()
        end
    end

    local c = resmng.get_conf("prop_world_unit",dp.propid)
    if c then
        limit = get_val_by("CountGarrison",c.Buff,u:get_ef(),self._ef)
        local b = resmng.get_conf("prop_effect_type", "CountGarrison")
        if b then
            limit = limit+b.Default
        end
    end
    return num,limit
end


function get_eye_info(self,eid)--查询大地图建筑信息
    local dp = get_ety(eid)
    if not dp then return end
    local pack ={}
    pack.hold_num,pack.hold_limit = self:get_hold_limit(dp)

    if is_monster(dp) then
        local score = monster.get_top_hurter_by_propid(dp.propid)
        --if score then
        --    pack.pid = score.pid
        --    local ply = getPlayer(score.pid)
        --    if ply then
        --        pack.name = ply.name
        --    else
        --        pack.name = "system"
        --    end
        --end
        Rpc:get_eye_info(self, eid, score or {pid=0,name="system",hurt=0})

    elseif is_king_city(dp) then
        king_city.eye_info(dp, pack)
        Rpc:get_eye_info(self, eid, pack)
        --]]
    elseif is_monster_city(dp) then
        monster_city.eye_info(dp, pack)
        Rpc:get_eye_info(self, eid, pack)
    end
    if is_union_building(dp) then
        local u = unionmng.get_union(dp.uid)
        if not u then
            ack(self, "get_eye_info", resmng.E_NO_UNION) return
        end
        if dp.uid == self.uid then
            local cc = resmng.prop_world_unit[dp.propid]
            if cc.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
                local info = {}
                info.state = dp.state
                info.hp = dp.hp   
                pack.dp = info
                pack.limit = union_build_t.get_restore_limit(self)
                local u = unionmng.get_union(self.uid)
                if u and u.restore then
                    pack.res = u.restore.sum or {}
                else
                    pack.res =  {}
                end
            elseif cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE 
                or resmng.CLASS_UNION_BUILD_TUTTER1 or resmng.CLASS_UNION_BUILD_TUTTER2 then
                local info = {}
                info.state = dp.state
                info.hp = dp.hp   
                pack.dp = info
                local troop = {}
                local tr = troop_mng.get_troop(dp.my_troop_id)
                if tr then
                    --找出加入这个军队的玩家
                    for k, v in pairs(tr.arms) do
                        local single = self:fill_player_info_by_arm(v, tr.action, tr.owner_pid)
                        single._id = tr._id
                        single.tmStart = 0
                        single.tmOver = 0
                        single.count = tr:get_troop_total_soldier()
                        table.insert(troop, single)
                    end
                    for k, v in pairs(tr.mark_troop_ids or {}) do 
                        local tm_troop = troop_mng.get_troop(v)
                        if tm_troop then
                            local single = self:fill_player_info_by_arm(tm_troop:get_arm_by_pid(tm_troop.owner_pid), tm_troop.action, tm_troop.owner_pid)
                            single._id = tm_troop._id
                            single.tmStart = tm_troop.tmStart
                            single.tmOver = tm_troop.tmOver
                            single.count = tm_troop:get_troop_total_soldier()
                            table.insert(troop, single)
                        end
                    end
                end
                for k, _ in pairs(dp.hold_troop  or {}) do 
                    local tm_troop = troop_mng.get_troop(k)
                    if tm_troop then
                        local single = self:fill_player_info_by_arm(tm_troop:get_arm_by_pid(tm_troop.owner_pid), tm_troop.action, tm_troop.owner_pid)
                        single._id = tm_troop._id
                        single.tmStart = tm_troop.tmStart
                        single.tmOver = tm_troop.tmOver
                        single.count = tm_troop:get_troop_total_soldier()
                        table.insert(troop, single)
                    end
                end
                pack.troop = troop
            else
                local info = {}
                info.state = dp.state
                info.hp = dp.hp   
                info.val = dp.val
                info.tmStart = dp.tmStart
                info.tmOver = dp.tmOver
                info.speed = dp.speed
                pack.dp = info

                local troop = {}
                for _, tid in pairs(dp.my_troop_id or {} ) do
                    local tr = troop_mng.get_troop(tid)
                    if tr then
                        local t = {}
                        t.speed = tr:get_extra("speed")
                        t.speedb = tr:get_extra("speedb")
                        t.tmStart = tr.tmStart
                        t.tmOver = tr.tmOver
                        t.action = tr.action
                        troop[ tr.owner_pid ] = t
                        end
                    end
                    pack.troop = troop
                dumpTab(pack, "get_eye_info")

                --for k, v in pairs(union_build_t.get_troop(dp._id) or {} ) do
                --    local p = getPlayer(v.pid)
                --    local t = p:get_troop(v.idx)
                --    if t then
                --        if t.state == resmng.TroopState.Gather then
                --            t.act_speed = math.ceil(p:get_val("GatherSpeed") / 60)
                --            t.buf_speed = 0
                --        end
                --        table.insert(pack.troop,t)
                --    end
                --end
            end
        end
        Rpc:get_eye_info(self,eid,pack)
    end
end
------ king city
--

function select_officer_req(self, pid, index)
    if index == KING then
        king_city.select_king_by_leader(self, pid)
    else
        king_city.select_officer(self, pid, index)
    end
    officers_info_req(self)
end

function rem_officer_req(self,index)
        king_city.rem_officer(self,  index)
    officers_info_req(self)
end


function mark_king_req(self, score)
    if king_city.season == self.kwseason then
        return
    end
    king_city.mark_king(score)
    officers_info_req(self)
end

function officers_info_req(self)
    local pack = {}
    local officers = {}
    for  k, v in pairs(king_city.officers) do
        local officer = {}
        local ply = getPlayer(v)
        if ply then
            officer.index = k
            officer.pid = ply.pid
            officer.name = ply.name
            officer.photo = ply.photo
            local union = unionmng.get_union(ply.uid)
            if union then
                officer.union = union.alias
            end
            officers[k] = officer
        end
    end

    pack.officers = officers
    Rpc:officers_info_ack(self, pack)
end

function honour_wall_req(self)
    local pack = {}
    local kings = {}
    local season = king_city.season
    for k, v in pairs(king_city.kings) do
        local ply = getPlayer(v[2])
        local plyName = ""
        local unionName = ""
        if ply then
            plyName = ply.name
        end
        local union = unionmng.get_union(v[3])
        if union then
            unionName = union.name
        end
        table.insert(kings, {k, v[2], plyName, unionName, v[4], v[5]})
    end
    if kings == {} then
        kings = {{1, self._id, self.name, "aaa" , 999, gTime}}
    end
    pack.kings = kings
    Rpc:honour_wall_ack(self, pack)
end

function kw_mall_bug_req(self, index)
    kw_mall.buy(self, index)
end

function kw_want_buy_req(self, index)
    kw_mall.want_buy(self, index)
end

function kw_mall_info_req()
    local m = get_ety(kw_mall.kwMallId)
    local pack = {}
    if m then
        pack.goods = m.goods
    end
    Rpc:kw_mall_info_ack(self, pack)
end

function find_player_by_name_req(self, name)
    local pack = {}
    local db = dbmng:getOne()
    local info = db.player:findOne({name = name})
    if info  then
        pack.pid = info.pid
        pack.name = info.name
        pack.photo = info.photo
        pack.lv = info.lv
    end
    Rpc:find_player_by_name_ack(self, pack)
end

function get_store(self)
    local stores = {0,0,0,0}
    local rate = {1, 1, 0.2, 0.05}

    local count = self:get_val("CountStore")
    for k, v in pairs(rate) do
        stores[ k ] = math.floor(rate[ k ] * count)
    end
    return stores
end


function get_res_over_store(self)
    local stores = self:get_store()
    self:refresh_food()
    local res = {0,0,0,0}
    for k, v in pairs(self.res) do
        if v[1] > stores[ k ] then
            res[ k ] = math.floor(v[1] - stores[ k ])
        end
    end
    return res
end

function get_farms(self)
    local class = BUILD_CLASS.RESOURCE
    local bs = {}
    for mode = 1, 4, 1 do
        local max_seq = BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]
        for seq  = 1, max_seq, 1 do
            local build_idx = self:calc_build_idx(class, mode, seq)
            local build = self:get_build(build_idx)
            if not build then break end
            if build.state == BUILD_STATE.WAIT then
                if gTime - build.tmStart > 600 then
                    build.mode = mode
                    table.insert(bs, build)
                end
            end
        end
    end
    return bs
end

function qry_troop_info(self, tid)
    local troop = troop_mng.get_troop(tid)
    for pid, arm in pairs(troop.arms) do
        if pid == self.pid then
            local t = {}
            t.soldiers = arm.live_soldier
            local heros = {}
            for k, v in pairs(arm.heros) do
                if v ~= 0 then
                    local h = heromng.get_hero_by_uniq_id(v)
                    if h then
                        table.insert(heros, { h.propid, h.lv })
                    end
                end
            end
            t.heros = heros
            t.bufs = troop.bufs -- { {bufid, tmOver}, {bufid, tmOver} }
            t.extra = troop.extra -- {speed=10, speedb=8, count=10, start=1923333, cache=199}
            t._id = tid
            Rpc:ack_troop_info(self, t)
            return
        end
    end
end

function add_buf(self, bufid, count)
    local node = resmng.prop_buff[ bufid ]
    if node then
        if count < 1 then count = 1 end

        local dels = {}
        local bufs = self.bufs 
        if node.Mutex == 1 then  -- 互斥
            local group = node.Group
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    table.insert(dels, k)
                end
            end

        elseif node.Mutex == 2 then -- 高级替换低级
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.Lv > lv then return end
                    table.insert(dels, k)
                end
            end
        end

        if #dels > 0 then
            for i = #dels, 1, -1 do
                table.remove(bufs, dels[ i ]) 
            end
        end

        if node.Value then self:ef_add(node.Value) end
        local tmOver = gTime + count
        local buf = {bufid, gTime, tmOver}
        table.insert(bufs, buf)
        self.bufs = bufs
        timer.new("buf", count, self.pid, bufid, tmOver)
        print(string.format("add_buf, pid=%d, bufid=%d, tmStart=%d, count=%d", self.pid, bufid, gTime, count))
        return buf
    end
end


function rem_buf(self, bufid, tmOver)
    local bufs = self.bufs
    for k, v in pairs(bufs) do
        --v = {bufid, tmOver}
        if v[1] == bufid then
            if not tmOver or tmOver == v[3] then
                table.remove(bufs, k)
                local node = resmng.prop_buff[ bufid ]
                if node and node.Value then self:ef_rem(node.Value) end
                self.bufs = bufs
                print(string.format("rem_buf, pid=%d, bufid=%d, tmOver=%d, now=%d", self.pid, bufid, tmOver, gTime))
                return v[3]
            end
        end
    end
end

function get_buf( self, bufid )
    local bufs = self.bufs
    for k, v in pairs(bufs) do
        --v = {bufid, tmStart, tmOver}
        if v[1] == bufid then
            return v
        end
    end
end


--- 怪物攻城
function set_mc_start_time_req(self, time)
    local union = unionmng.get_union(self.uid)
    if union then
        union_t.set_mc_start(union, time)
    end
end

function get_mc_akt_info_req(self)
    local union = unionmng.get_union(self.uid)
    local pack = {}
    if union then
        pack.info = union_t.get_monster_info(union)
    end
    Rpc:get_mc_akt_info_ack(self, pack)
end

function load_msg_list(self, what, sn, count, new)
    local mlist = msglist.get(what)
    if mlist then
        local infos
        if new == 1 then
            infos = mlist:msg_load_new(sn, count)
        else
            infos = mlist:msg_load_old(sn, count)
        end
        Rpc:msg_load(self, what, sn, count, new, infos)
        return
    end
    Rpc:msg_load(self, what, sn, count, new, {})
end

function get_pow(self)
    return self.pow or 0
end

function inc_pow(self, num)
    if num and num > 0 then
        self.pow = self.pow + num
    end
    union_mission.ok(self,UNION_MISSION_CLASS.POW,num)
end

function dec_pow(self, num)
    if num and num > 0 then
        self.pow = self.pow - num
    end
end


function get_live(self)
    local troop = self:get_my_troop()
    if troop then 
        return troop:get_live(self.pid)
    end
end


---- chat admin
function create_chat_account(ply)
    to_tool(0, {type = "chat", cmd = "create_chat", name = tostring(ply.pid), host = CHAT_HOST, password = tostring(ply.pid)})
end

--- register result  chat call back
function create_chat(info)
    if info.result == 1 then
        local ply = getPlayer(tonumber(info.pid))
        if ply then
            ply.chat_account = ply.pid
            ply.chat_psw = ply.pid
        end
    end
end

function create_room(info)
    if info.result == 1 then
        local union = unionmng.get_union(tonumber(info.uid))
        if union then
            union.chat_room = tostring(union.uid)
        end
    end
end

function testCross( self, a1, a2 )
    print( string.format( "CrossCall, from %d to %d, a1=%s, a2=%s", self.pid, _G.gMapID, a1, a2 ) )
end

function ack_tool( self, sn, info )
    if info.api then
        player_t[info.api](info)
    end
    print( "ack_tool", sn )
end

function city_break( self, attacker )
    self:release_all_prisoner()
    self:wall_fire( 1800 )
    if is_ply( attacker ) then 
        union_task.ok( attacker, self, UNION_TASK.HERO)
        union_task.ok( attacker, self, UNION_TASK.PLY) --攻击胜利后领取军团悬赏任务
    end
end

function vip_add_exp( self, exp )
    if exp <= 0 then return end
    self.vip_exp = self.vip_exp + exp
    local lv = self.vip_lv
    local node = resmng.get_conf( "prop_vip", lv + 1 )
    if node then
        if self.vip_exp >= node.Exp then
            self.vip_lv = lv + 1
            local src = resmng.get_conf( "prop_vip", lv)
            local buf = self:get_buf( src.Buf )
            if buf then
                self:rem_buf( buf[1], buf[3] )
                self:add_buf( node.Buf, buf[3] - gTime )
            end
        end
    end
end

function vip_signin( self )
    if self.vip_lv < 1 then self.vip_lv = 1 end
    local dif = get_diff_days( self.vip_login, gTime )
    if dif == 0 then
        -- nothting, already done
    elseif dif == 1 then
        self.vip_login = gTime
        local node = resmng.get_conf( "prop_vip", self.vip_lv )
        local exp = node.Base + node.Acc * self.vip_nlogin 
        if exp > node.Max then exp = node.Max end
        self:vip_add_exp( exp )
        self.vip_nlogin = self.vip_nlogin + 1

    elseif dif > 1 then
        self.vip_login = gTime
        local node = resmng.get_conf( "prop_vip", self.vip_lv )
        self:vip_add_exp( node.Base )
        self.vip_nlogin = 1

    end
end

function vip_enable( self, dura )
    local conf = resmng.get_conf( "prop_vip", self.vip_lv )
    local buf = self:get_buf( conf.Buf )
    if buf then
        self:rem_buf( buf[1], buf[3] )
        self:add_buf( node.Buf, buf[3] - gTime + dura )
    else
        self:add_buf( node.Buf, dura )
    end
end

function vip_buy_gift( self, idx )
    if idx <= 0 then return end
    if idx > self.vip_lv then return end
    if self:get_bit( self.vip_gift, idx ) == 1 then return end

    local conf = resmng.get_conf( "prop_vip", idx )
    if self.gold < conf.Cost then return end
    self:do_dec_res(resmng.CLASS_RES, conf.Cost, VALUE_CHANGE_REASON.VIP_BUY)
    self:add_bonus("mutex_award", conf.Gift, VALUE_CHANGE_REASON.VIP_BUY)
    self.vip_gift = set_but( self.vip_gift, idx )
end


