-- Hx@2015-11-30 : 军团类
module_class("union_t", {
    uid = 0,
    _id = 0,
    name = "",
    alias = "",
    level = 0,
    language = "",
    credit = 0,
    membercount = 0,
    mars = 0,       --战神
    leader = 0,
    tech_mark = {},
    donate = 0,
    note_in = "",
    note_out = "",
    battle_room_ids = {},
    npc_citys = {}, -- 领土争夺占领的城市
    can_atk_citys = {}, --玩家攻击的城市
    atk_id = 0,  -- 领土争夺好招攻击的对象
    def_id =  0, -- 领土争夺好招防御的对象
    declare_wars = {}, -- 宣战的城市
    last_declare_time = 0, --上次成功宣战的时间
    monster_city_stage = 0, -- 怪物攻城的波次
    mc_timer = 0, -- 怪物攻城定时器
    set_mc_time = 999, -- 设置mc 开始的时间
    mc_start_time = 999, -- 设置mc 开始的时间
    enlist = {}, --招募信息
    rank_alias = {"","","","","",""}, --军阶称谓
    tm_buf_over = 0,
    chat_room = "", -- 聊天room
})




-- 怪物攻城 monster_city
-- 设置军团在怪物攻城中的状态
--

function set_mc_start(self, time)
    if os.date("%d", self.set_mc_time) ~= os.date("%d", gTime) and self.monster_city_stage == 0 then

        timer.del(self.mc_timer)
        local leftTime = get_left_time(time)
        self.mc_start_time = time
        self.set_mc_time = gTime
        -- to do
        self.mc_timer = timer.new("monster_city", time, self.uid, 1)
    else
        return false
    end
end

function get_default_time(self)
    -- base on language
    return 14
end

function get_left_time(endTime)
    local now = os.date("*t", gTime)
    local hour = now.hour
    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0, sec=0 }

    temp.hour = endTime
    return os.time(temp)
end

function set_default_start(self)
    if self.mc_start_time == 999 then
        self.mc_start_time =  get_default_time(self)
    end
    timer.del(self.mc_timer)
    local time = get_left_time(self.mc_start_time)
    self.mc_timer = timer.new("monster_city", time, self.uid, 1)
end

function get_monster_info(self)
    local info = {}
    for k, v in pairs(npc_citys) do
        local city = get_monster_city(v)
        if city then
            table.insert(info, city)
        end
    end
    return info
end

function get_monster_city(eid)
        local cityId = monster_city.citys[eid]
        if cityId then
            local city = get_ety(cityId)
            return city
        end

        local city = monster_city.gen_monster_city(eid)
        if city then
            return city
        end

        return
end

function set_mc_state(self, stage)
    local prop = {}
    if not stage then
        prop = resmng.prop_mc_stage[self.monster_city_stage]
        stage = prop.NextStage
    end

    prop = resmng.prop_mc_stage[stage]

    self.monster_city_stage = stage

    for k, v in pairs(self.npc_citys) do
        local city = get_monster_city(v)
        if city then
            monster_city.monster_city_job(self, city, stage, prop.Spantime)
        end
    end

    -- 发放活动邮件
    if self.monster_city_stage == prop.NextStage then
        for k, v in pairs(self.npc_citys) do
            local city = get_monster_city(v)
            if city then
                monster_city.send_act_award(city)
            end
        end
    end

    local time = prop.Spantime
    if prop.NextStage ~= stage then
        set_mc_timer(self, time, prop.NextStage)
    end

    if prop.NextStage == stage then
        for k, v in pairs(self.npc_citys) do
            local city = get_monster_city(v)
            if city then
                rem_ety(city.eid)
            end
        end
    end

end

function set_mc_timer(self, time, stage)
    local timeId = timer.new("monster_city", time, self.uid, stage)
    self.mc_timer = timerId
end

--- monster_city
----------------------------------------------------


-----------------
--npc city
function can_atk_npc(self, destEid)
    if not self.declare_wars[ destEid ] then
        return false
    end
    return true
end

function clear_declare(self)
    self.declare_wars = nil
end

function try_declare_tw(self, npcId)
if can_declare_war(self, npcId) == true then
    do_declare_tw(self, npcId)
end
end

function do_declare_tw(self, npcEid)

    local level = resmng.prop_world_unit[get_ety(npcEid).propid].Lv
    local prop = resmng.prop_tw_consume[ level]

    local declare_union = {}
    if self.declare_wars  then
        declare_union = self.declare_wars
    end
    declare_union[npcEid] = npcEid
    self.declare_wars = declare_union
    self.last_declare_time = gTime
    self.credit = self.credit - prop.Consume
end

function check_time_limit(self, npcId)
    return true
end

function can_declare_war(self, npcId)
    if check_conditon(self, npcId) then
        if check_time_limit(self, npcId) then
            try_reset_declare_data(self)

            if self.declare_wars and  #self.declare_wars >= 3 then
                return false
            else
                if is_already_declare(self, npcId) then
                    return false
                else
                    return can_npc_be_declare(self,npcId)
                end

            end
        else
            return false
        end
    else
        return false
    end
end

-- 城市是否相连
function can_npc_be_declare(self, npcId)
    --[[if self.npc_citys and (self.npc_citys ~= {}) then
        local propid =  gEtys[ npcId ].propid
        for k, v in pairs(self.npc_citys) do
            for k, v in pairs(resmng.prop_world_unit[ gEtys[ v ] ].Neighbor) do
                if v == propid then
                    return true
                end
            end
        end
        return false
    else
       self.npc_citys = {}
    end--]]
    return true
end

function is_npc_city_full(self)
    -- to do
    return false
end

--城市是否已经宣战
function is_already_declare(self, npcId)
    local res = false
    if not self.declare_wars then
        return false
    end
    for k, v in pairs(self.declare_wars) do
        res = res or (v == npcId)
    end
    return res
end

function try_reset_declare_data(self)
    if os.date("%d", self.last_declare_time or 0 ) ~= os.date("%d",gTime) then
        last_declare_time = gTime
        self.declare_wars = {}
        self.send_declare_city = {}
    end
end

function check_conditon(self, npcId)
    local npc = get_ety(npcId)
    --for test
    return true
    --[[if npc then
        local prop = resmng.prop_tw_consume[npc.lv]
        local cond1 = check_mem(self, prop)
        local cond2 = check_score(self, prop)
        return cond1 and cond2
    end--]]
end
-- union member level limit
function check_mem(self, prop)
    local num = 0
    if self._members then
        for k, v in pairs(self._members) do
            if v.lv >= prop.Condition[1] then
                num = num +1
            end
        end
    else
        num = 0
    end
    return num >= prop.Condition[2]
end

function check_score(self, prop)
    return self.credit >= prop.Consume
end

function deal_new_npc_city(self, eid)
    local npcCitys = self.npc_citys or {}
    --table.insert(npcCitys, eid)
    npcCitys[eid] = eid
    self.npc_citys = npcCitys
end

function union_can_atk_citys(self)
    local citys = {}
    local citysPropid = {}
    for k, v in pairs(self.npc_citys) do
        local city = get_ety(v)
        if city then
            citysPropid[city.propid] = city.propid
        end
    end
    for k, v in pairs(self.npc_citys) do
        local city = get_ety(v)
        if city then
            local prop = resmng.prop_world_unit[city.propid]
            if prop then
                for k, v in pairs(prop.Neighbor) do
                    if not citysPropid[v] then
                        citys[v] = v
                    end
                end
            end
        end
    end
    self.can_atk_citys = citys
end

----------------npc city
------------------------------------------------

function init(self)
    if not self._members then self._members = {} end
    if not self.applys then self.applys = {} end
    if not self._invites then self._invites = {} end
    if not self.mass then self.mass = {} end
    if not self._tech then self._tech = {} end
    if not self.log then self.log = {} end
    table.sort(self.log, function(l, r)
        return l.sn > r.sn
    end)
    if not self._fight then self._fight = {} end
    setmetatable(self._fight, {__mode="v"})
    if not self.donate_rank then self.donate_rank = {} end
    if not self.mission then self.mission = {} end
    if not self.build then self.build = {} end
end

--{{{ basic
function create(A, name, alias, language, mars_mode)

    local old = unionmng.get_union(A:get_uid())
    if old then old:rm_member(A) end


    local id = getId("union")
    local data = {
        uid=id,_id=id,name=name,alias=alias,level=1,language=language,credit=0,
        membercount=1,leader=A.pid, note_in="",note_out="",invites = {},
        enlist = {check = 0 ,text="",lv=0, pow=0}, --招募信息
        rank_alias = {"","","","","",""}, --军阶称谓
        tm_buf_over = 0,
    }
    local union = new(data)
    if not union_god.set(union,mars_mode) then
        return
    end

    --hack add member
    union._members[A.pid] = A
    A.uname = union.alias
    etypipe.add(A)

    A:on_join_union(union.uid)

    A:set_uid(union.uid)
    A:set_rank(resmng.UNION_RANK_5)

    unionmng.add_union(union)
    dbmng:getOne().union:insert(union._pro)
    gPendingSave.union_log[id] = {_id=id}

    union:add_log(resmng.EVENT_TYPE.UNION_CREATE, {name=A.name})

    LOG("[Union] create, pid:%s, uid:%s,", A.pid, union.uid)

    --- create chat room
    --Rpc:create_room(A, tostring(union.uid), CHAT_HOST, A.chat_account)
    return union
end

function on_check_pending(db, _id, chgs)
    local u = unionmng.get_union(_id)
    if u then
        db.union:update({_id=_id}, {["$set"]= chgs})
        chgs.uid = _id
        u:notifyall("info", resmng.OPERATOR.UPDATE, chgs)
    end
end

function get_ef(self)--军团buf
    local l = {}
    for _, v in pairs(self._tech) do
        local c = resmng.get_conf("prop_union_tech", v.id)
        if c then
            for k, num in pairs(c.Effect or  {} ) do
                l[k] = (l[k] or 0) + num
            end
        end
    end

    if self.buildlv then
        for _, v in pairs(self.buildlv.data or {} ) do
            local c = resmng.get_conf("prop_union_buildlv", v.id)
            if c then
                for k, num in pairs(c.Effect or  {} ) do
                    l[k] = (l[k] or 0) + num
                end
            end
        end
    end

    if self.god  then
        local c = resmng.get_conf("prop_union_god", self.god.propid)
        if c then
            for k, num in pairs(c.Effect or  {} ) do
                l[k] = (l[k] or 0) + num
            end
        end
    end

    self._ef=l
    return l
end

function get_castle_ef(self,p)--奇迹buf
    local sn = math.huge 
    local bc = {}
    if p then
        for _, v in pairs(self.build or {} ) do
            local c = resmng.get_conf("prop_world_unit", v.propid)
            if c.Mode == resmng.CLASS_UNION_BUILD_CASTLE or c.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                if  union_build_t.can_ef(v,p) and sn > v.sn then
                    sn = v.sn
                    bc= c 
                end
            end
        end
    end
    return bc.Buff
end

function get_memberlimit(self)--军团人数上限
    local c = resmng.get_conf("prop_effect_type", "CountMember")
    local num = get_val_by("CountMember",self:get_ef())
    return (c.Default or 0 + num)
end

function get_day_store(self,p)--仓库每日上限
    local c = resmng.get_conf("prop_effect_type", "CountDailyStore")
    local num = get_val_by("CountDailyStore",self:get_ef(),p._ef)
    return (c.Default or 0  + num)
end

function get_sum_store(self,p)--仓库总上限
    local c = resmng.get_conf("prop_effect_type", "CountUnionStore")
    local num = get_val_by("CountUnionStore",self:get_ef(),p._ef)
    return (c.Default or 0 + num)
end

function get_info(self)
    local info = {}

    info.uid = self.uid
    info.new_union_sn = self.new_union_sn
    info.name = self.name
    info.alias = self.alias
    info.level = self.level
    info.membercount = self.membercount
    info.memberlimit = self:get_memberlimit()
    info.language = self.language
    info.flag = self.flag
    info.note_in = self.note_in
    if self.leader and self.leader~=0  then
        info.leader = getPlayer(self.leader).name
    end
    info.pow = self:union_pow()
    info.tm_buf_over = self.tm_buf_over
    info.donate = self.donate
    info.rank_alias = self.rank_alias
    return info
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-26 : 删除联盟
-- 包括 union, member, fight, build, tech,
-- -----------------------------------------------------------------------------
function destory(self)

    self:broadcast("union_destory")
    for k, v in pairs(self.build) do
        union_build_t.remove_build(self,k)
    end

    for _, A in pairs(self._members) do
        A:leave_union()
    end
    union_word.clear(self.uid)
    union_mall.clear(self.uid)
    union_buildlv.clear(self.uid)
    union_mission.clear(self.uid)
    union_task.clear(self.uid)
    union_tech_t.clear(self.uid)
    union_help.clear(self.uid)
    union_relation.clear(self.uid)
    union_god.clear(self.uid)

    gPendingDelete.union_log[ self.uid ] = 0
    gPendingDelete.union[ self.uid ] = 0

    LOG("[Union] destory, uid:%s", self.uid)
end

--{{{ member
-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 添加移除玩家感觉写的有问题，涉及到的api过多，不够清晰
-- -----------------------------------------------------------------------------
function add_member(self, A)
    if self:has_member(A) then return resmng.E_ALREADY_IN_UNION end
    local old = unionmng.get_union(A:get_uid())
    if old then
        old:quit(A)
    end
    A:on_join_union(self.uid)
    A.uname = self.alias
    etypipe.add(A)

    self._members[A.pid] = A
    self.membercount = tabNum(self._members)
    --self:broadcast("union_add_member", A:get_union_info())
    local t = A:get_union_info()
    t.uid = self.uid
    self:notifyall("member", resmng.OPERATOR.ADD, t)

    self.donate_rank = {} --清除捐献排行
    self:add_log(resmng.EVENT_TYPE.UNION_JOIN, {name=A.name})
    task_logic_t.process_task(A, TASK_ACTION.JOIN_PLAYER_UNION)
    return resmng.E_OK
end

function rm_member(self, A)
    if not self:has_member(A) then return resmng.E_NO_UNION end

    if not self.new_union_sn then
        local f = A:union_leader_auto()--移交军团长
    end

    self:notifyall("member", resmng.OPERATOR.DELETE, {pid=A.pid})
    self._members[A.pid] = nil
    self.membercount = tabNum(self._members)

    A:leave_union()
    A.uname = ""
    etypipe.add(A)

    self.donate_rank = {} --清除捐献排行
    if f then
        unionmng.rm_union(self)
    end
    return resmng.E_OK
end

function kick(self, A, B)
    if not (is_legal(A, "Kick") and A:get_rank() > B:get_rank() ) then
        return resmng.E_DISALLOWED
    end

    local t = B:get_troop()
    for _, v in pairs(t or {}) do
        if v.action == (resmng.TroopAction.Aid or resmng.TroopAction.Mass_Node or resmng.TroopAction.Mass) then
            troopx_back(B, v.idx)
        end
    end

    local ret = self:rm_member(B)
    if ret == resmng.E_OK then
        LOG("[Union], A:%s kick B:%s", A.pid, B.pid)
        self:add_log(resmng.EVENT_TYPE.UNION_KICK, {
            name = A.name,
            k_name = B.name,
        })
    end
    return ret
end

function quit(self, A)
    if not is_legal(A, "Quit") then return resmng.E_DISALLOWED end

    local ret = self:rm_member(A)
    if ret == resmng.E_OK then
        LOG("[Union] quit, pid:%s ", A.pid)
        self:add_log(resmng.EVENT_TYPE.UNION_QUIT, {
            name = A.name,
        })
    end
    return ret
end

function trans(self, A)
    --TODO
end

function has_member(self, ...)
    local arg = {...}
    for i = 1, #arg do
        A = arg[i]
        if self.uid ~= A:get_uid() then
            return false
        else
            if not self._members[A.pid] then
                WARN("uid matching but not in member list, pid:%s, uid:%s", A.pid, self.uid)
                return false
            end
        end
    end
    return true
end

function get_member_info(self)
    local info = {}
    for _, A in pairs(self._members) do
        table.insert(info, A:get_union_info())
    end
    return info
end

function accept_apply(self, A, B)
    if not self:has_member(A) then return resmng.E_NO_UNION end
    if self:has_member(B) then return resmng.E_ALREADY_IN_UNION end
    if not is_legal(A, "Invite") or not is_legal(B, "Join") then
        return resmng.E_DISALLOWED
    end

    if not self:get_apply(B.pid) then return resmng.E_FAIL end

    self:remove_apply(B.pid)

    -- chat admin
    send_chat_invite(self.chat_room, B)

    return self:add_member(B)
end

-- chat union room invite
function send_chat_invite(chat_room, B)
    to_tool(0, {type = "chat", cmd = "send_invite", name = chat_room, service="conference."..CHAT_HOST, users = {B.chat_account.."@"..CHAT_HOST} })
end

-- user role in chat room
function set_role(chat_room, jid, role)
    to_tool(0, {type = "chat", cmd = "set_role", name = chat_room, service = "conference."..CHAT_HOST, affiliation=role})
end

function remove_apply(self, pid)
    assert(pid)
    local k = self:get_apply(pid)
    if k then
        self.applys[k]=nil
        gPendingSave.union[self.uid].applys = self.applys
        return true
    end
    return false
end

function get_apply(self, pid)
    assert(pid)
    for index, v in pairs(self.applys) do
        if pid == v.pid then
                return index
        end
    end
end

function add_apply(self, B)
    assert(B)
    if self:has_member(B) then return end
    if self:get_apply(B.pid) then return end

    local data = {pid=B.pid, tm=gTime}
    table.insert(self.applys, data)
    gPendingSave.union[self.uid].applys = self.applys

    local data = B:get_union_info()
    data.rank = 0

    LOG("[Union] add_apply, pid:%s, uid:%s", B.pid, self.uid)
end

function reject_apply(self, A, B)
    if not self:has_member(A) then return resmng.E_NO_UNION end
    if not is_legal(A, "Invite") then return resmng.E_DISALLOWED end
    if self:remove_apply(B.pid) then
        self:broadcast("union_reject", B.pid)
        --self:notifyall("apply", resmng.OPERATOR.DELETE, B.pid)
        return resmng.E_OK
    else
        return resmng.E_FAIL
    end
end

function set_member_rank(self, A, B, r)
    if not self:has_member(A, B) then return resmng.E_FAIL end
    if not (resmng.UNION_RANK_1 <= r and r <= resmng.UNION_RANK_5) then
        return resmng.E_DISALLOWED
    end

    if A:get_rank() >= r then
        B:set_rank(r)
        LOG("[Union] set_rank, A:%s, B:%s, R:%s", A.pid, B.pid, r)
        self:notifyall("member", resmng.OPERATOR.UPDATE, B:get_union_info())
        return resmng.E_OK
    else
        return resmng.E_FAIL
    end
end

function set_member_mark(self, A, B, mark)
    if not self:has_member(A, B) then return resmng.E_FAIL end
    if not is_legal(A, "MemMark") or not (A:get_rank() > B:get_rank()) then
        return resmng.E_DISALLOWED
    end

    B:union_data().mark = mark
    self:notifyall("member", resmng.OPERATOR.UPDATE, A:get_union_info())
    return resmng.E_OK
end
--}}}

function is_legal(A, what)
    local conf = resmng.prop_union_power[A:get_rank()]
    if not conf then return false end
    if not conf[what] or conf[what] == 0 then return false end
    return true
end

--{{{ invite
function send_invite(self, A, B)
    if not is_legal(A, "Invite") then return resmng.E_DISALLOWED end
    if not self:has_member(A) then return resmng.E_NO_UNION end
    if self:has_member(B) then
        WARN("[Union]: sendInvite, already in union, player:%s", B.pid)
        return resmng.E_ALREADY_IN_UNION
    end

    self:add_invite(B.pid)
    return resmng.E_OK
end

function accept_invite(self, B)
    if self:has_member(B) then
        WARN("[Union]: acceptInvite, already in Union, player:%s, union:%s", B.pid, self.uid)
        return resmng.E_ALREADY_IN_UNION
    end

    for k, v in pairs(self.invites) do
        if v.pid == pid then
            self:remove_invite(k)
        end
    end
    self:add_member(B)
end

function remove_invite(self, k)
    if v then
        self.invites[k]=nil
        gPendingSave.union[self.uid].invites = self.invites
    end
end

function add_invite(self, pid)
    assert(pid)

    local index, invite = self:get_invite(pid)
    if not invite then
        table.insert(self.invites, {tm=gTime,pid=pid})
        gPendingSave.union[self.uid].invites = self.invites
    end
end
function get_invite(self, pid)
    for k, v in pairs(self.invites) do
        if v.pid == pid then
            if gTime > (v.tm+60*60*24*2)  then
                self:remove_invite( k)
                return
            else
                return k, v
            end
        end
    end
end
---}}}

--{{{  broadcast
-- -----------------------------------------------------------------------------
-- Hx@2016-01-05 : use notifyall, merge all broadcast messages
-- Hx@2016-01-25 : 所有联盟广播合并到notifyall下，逐步移除broadcast api,
-- 联盟下非全联盟广播需要自己做
-- -----------------------------------------------------------------------------
function broadcast(self, protocol, ...)
    local pids = {}
    for _, p in pairs(self._members) do
        if p:is_online() then
            table.insert(pids, p.pid)
        end
    end
    if #pids == 0 then return end
    Rpc[protocol](Rpc, pids, ...)
end

function notifyall(self, what, mode, data)
    local pids = {}
    for _, p in pairs(self._members) do
        if p:is_online() then
            table.insert(pids, p.pid)
        end
    end
    if #pids == 0 then return end
    Rpc:union_broadcast(pids, what, mode, data)
end
---}}}

--{{{ mass
-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : mass合并到fight中，这部分重复的api慢慢去掉
-- -----------------------------------------------------------------------------
function mass_add(self, mass)
    self.mass[mass.idx] = mass
    local data = self:get_mass_simple_info(mass.idx)
    --self:broadcast_mass_state(data)
end

function get_mass_simple_info(self, idx)
    assert(idx, "idx,".. debug.stack())
    local mass = self:get_mass(idx)
    if not mass then return end

    local count = 0
    local troops = {}
    for _, tid in ipairs(mass.troops) do
        local t = troop_t.get_by_tid(tid)
        assert(t, string.format("tid:%s,%s",tid, debug.stack()))
        table.insert(troops, {pid=t.pid,state=t.state})
        count = count + troop_t.sum(t)
    end

    local state = 0
    if mass.state == resmng.TroopState.Wait then
        state = resmng.UNION_MASS_STATE.CREATE
    else
        state = resmng.UNION_MASS_STATE.FINISH
    end

    local data = {
        idx = idx,
        pid = mass.pid,
        aeid = mass.eid,
        deid = mass.did,
        tmStart = mass.tmStart,
        tmOver = mass.tmOver,
        max = mass.max,
        count = count,
        troops = troops,
        state = state,
    }

    return data
end

function mass_update(self, idx)
    local mass = self:get_mass(idx)

    local count = 0
    local troops = {}
    for _, tid in ipairs(mass.troops) do
        local t = troop_t.get_by_tid(tid)
        table.insert(troops, {pid=t.pid,state=t.state})
        count = count + troop_t.sum(t)
    end
end

function mass_cancel(self, A, idx)
    local mass = self:get_mass(idx)

    for _, tid in pairs(mass.troops) do
        local t = troop_t.get_by_tid(tid)
        local p = getPlayer(t.pid)
            if t.state == resmng.TroopState.Wait then
                p:troop_back(t)
            end
    end

    local data = {
        idx = mass.idx,
        state = resmng.UNION_MASS_STATE.DESTORY,
    }

    troop_t.del(mass)
    self.mass[idx] = nil
end

function mass_deny(self, idx, pid)

end

function is_player_in_mass(self, idx, pid)
    for tid, _ in pairs(self.mass[idx].troops) do
        local val = string.split(tid, "_")
        if tonumber(val[1]) == pid then
            return true
        end
    end
    return false
end

function get_mass(self, idx)
    if not self.mass then self.mass = {} end
    return self.mass[idx]
end

function broadcast_mass_state(self, data)
    WARN("To Del ".. debug.stack())
    --self:broadcast("union_state_mass", data)
end

function do_timer_mass(self, tsn, idx)
    WARN("[ToDel] "..debug.stack())
end
--}}}

--{{{ tech & donate
function init_tech(self, idx)
    assert(self, debug.stack())
    if not self._tech[idx] then
        self._tech[idx] = union_tech_t.create(idx, self.uid)
    end
end

function get_tech(self, idx)
    self:init_tech(idx)
    return self._tech[idx]
end

function can_donate(self, idx)
    local tech = self:get_tech(idx)
    local conf = false
    if tech then
        conf = resmng.get_conf("prop_union_tech", tech.id + 1)
        if not conf then return end
    end

    if tech and tech.exp < conf.Exp * conf.Star then
        if self:calc_tech() >= TechValidCond[union_tech_t.get_class(idx)] then
            return true
        end
    end
    return false
end

function add_donate(self, num,p)
    self.donate = self.donate + num
    union_mission.ok(p,UNION_MISSION_CLASS.DONATE,num)
end

function calc_tech(self)
    local sum = 0
    for _, v in pairs(self._tech) do
        sum = sum + union_tech_t.get_lv(v)
    end
    return sum
end

function set_tech_mark(self, mark)
    if tabNum(mark) > 2 then return E_FAIL end
    for idx, _ in pairs(mark) do
        if not self:get_tech(tonumber(idx)) then
            return resmng.E_FAIL
        end
    end
    self.tech_mark = mark
    return resmng.E_OK
end

function get_tech_mark(self)
    return self.tech_mark
end

-- Hx@2015-12-23 :
-- 1.use tmOver to set the upgrade time and to identify is in upgrade progress
-- 2.clear tmOver when update finished
function upgrade_tech(self, idx)
    local tech = self:get_tech(idx)
    if not tech or not union_tech_t.is_exp_full(tech) then
        return resmng.E_FAIL
    end

    local next_conf = resmng.prop_union_tech[tech.id + 1]
    if not next_conf then
        return resmng.E_MAX_LV
    end

    if tech.tmOver ~= 0 then
        return resmng.E_FAIL
    end

    local tm = resmng.prop_union_tech[tech.id].TmLevelUp
    tech.tmStart = gTime
    tech.tmOver = gTime + tm
    tech.tmSn = timer.new("uniontech", tm, self.uid, idx)

    self:broadcast("union_tech_update", {
        idx=tech.idx,id=tech.id,tmStart=tech.tmStart, tmOver=tech.tmOver
    })

    return resmng.E_OK
end

function do_timer_tech(self, tsn, idx)
    local tech = self:get_tech(idx)
    if not tech then
        WARN("timer got no tech") return
    end

    local conf = resmng.prop_union_tech[tech.id]
    local next_conf = resmng.prop_union_tech[tech.id + 1]

    tech.id = next_conf.ID
    tech.exp = tech.exp - next_conf.Exp * next_conf.Star
    tech.tmSn = 0
    tech.tmStart = 0
    tech.tmOver = 0
    gPendingSave.union_tech[tech._id] = tech
    self:broadcast("union_tech_update", {
        idx=tech.idx,id=tech.id,exp=tech.exp,tmOver=tech.tmOver,tmStart=tech.tmStart
    })
end

function get_donate_rank(self, what)
    if not self.donate_rank[what] then
        local result = {}
        for _, v in pairs(self._members) do
            table.insert(result, {
                pid=v.pid,
                name=v.name,
                photo=v.photo,
                rank = v:get_rank(),
                donate = v:union_data().donate_data[what],
                techexp = v:union_data().techexp_data[what],
            })
        end
        table.sort(result, function(l, r)
            if l.techexp == r.techexp then
                if l.donate == r.donate then
                    if l.rank == r.rank then
                        --TODO: figt capacity
                        return true
                    else
                        return l.rank > r.rank
                    end
                else
                    return l.donate > r.donate
                end
            else
                return l.techexp > r.techexp
            end
        end)
        self.donate_rank[what] = result
    end
    return self.donate_rank[what]
end

function donate_summary_day(self)
    for _, A in pairs(self._members) do
        union_member_t.clear_donate_data(A,resmng.DONATE_RANKING_TYPE.DAY)
    end
end

function donate_summary_week(self)
    local rank = self:get_donate_rank(resmng.DONATE_RANKING_TYPE.WEEK)
    --TODO reward
    for _, A in pairs(self._members) do
        union_member_t.clear_donate_data(A,resmng.DONATE_RANKING_TYPE.WEEK)
    end
end

function tech_cond_check(self, cond)
    function do_cond_check(self, class, mode, ...)
        if class == "or" then
            for _, v in pairs({mode, lv, ...}) do
                if do_cond_check(unpack(v)) then return true end
            end
            return false
        elseif class == "and" then
            for _, v in pairs({mode, lv, ...}) do
                if not do_cond_check(unpack(v)) then return false end
            end
            return true
        elseif class == resmng.CLASS_UNION_TECH then
            local id = mode
            local conf = resmng.prop_union_tech[id]
            local tech = self:get_tech(conf.Idx)
            if conf and tech and tech.lv >= conf.Lv then
                return true
            end
        end
    end

    if cond then
        for _, v in pairs(cond) do
            if not do_cond_check(unpack(v)) then return false end
        end
    end
    return true
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-29: log 需要使用gDayStart
-- 服务器重启时gDayStart 的初始化点貌似在拉数据之后导致异常??
-- -----------------------------------------------------------------------------

function add_log(self, mode, data)
    LOG("[Union] add log, union:%s, mode:%s", self._id, mode)

    local sn = getId("unionlog")
    self.log_csn = sn
    local log = {
        sn = sn,
        tm = gTime,
        mode = mode,
        data = data,
    }

    local len = #self.log
    for i = #self.log, 1, -1 do
        if self.log[i].tm < (gDayStart or gTime) - 2592000 then
            table.remove(self.log, i)
        end
    end
    if #self.log > 1000 then
        for i = #self.log, 500, -1 do
            table.remove(self.log, i)
        end
    end

    table.insert(self.log, 1, log)
    gPendingSave.union_log[self._id] = self.log
end

local function log_qfind(t, sn)
    local function qfind(l, r)
        local k = math.floor((l + r) / 2)
        --print(l, k, r, sn, t[k].sn)
        if l > r then
            return nil
        elseif sn > t[k].sn then
            return qfind(l, k)
        elseif sn < t[k].sn then
            return qfind(k + 1, r)
        elseif sn == t[k].sn then
            return k
        end
    end
    return qfind(1, #t)
end

function get_log_by_mode(self, mode, sn)
    function check_mode(mode)
        for _, v in pairs(resmng.EventMode) do
            if v == mode then return true end
        end
        return false
    end

    local result = {}
    if not check_mode(mode) then return {} end
    if #self.log == 0 then return result end

    local idx = 0
    if sn ~= 0 then
        idx = log_qfind(self.log, sn)
        if not idx then return result end
    end

    while idx < #self.log do
        idx = idx + 1

        local log = self.log[idx]
        if log and log.mode == mode then
            if #result >= 20 then break end
            table.insert(result, log)
        end
    end
    return result
end

function set_note_in(self,pid,what)
    self.note_in = what
    local p = getPlayer(pid)
    self:add_log(resmng.EVENT_TYPE.SET_NOTE_IN, {name=p.name})
end

function get_log_by_sn(self, sn)
    local result = {}
    if #self.log == 0 then return result end

    local csn = sn
    if csn == 0 then
        csn = self.log_csn
    end

    local idx = 0
    if sn and sn ~= 0 then
        idx = log_qfind(self.log, sn)
        if not idx then return result end
    end

    while idx < #self.log  do
        idx = idx + 1
        local log = self.log[idx]
        if log then
            if #result >= 20 then break end
            table.insert(result, log)
        end
    end
    return result
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-25 : 联盟战争推送
-- 利用troop的脏检查监控字段的变化来实现，比使用在api中插入update更简洁
-- -----------------------------------------------------------------------------
function enroll_fight(self, troop, chgs)
    if troop.action == resmng.TroopAction.Seige then
        if is_ply(troop.aid) and is_ply(troop.did) then
            if not self._fight[troop._id]
                and (troop.state == resmng.TroopState.Wait or troop.state == resmng.TroopState.Go) then
                self._fight[troop._id] = troop
                LOG("[Union] fight add: %s", troop._id)
                --self:notifyall("fight", resmng.OPERATOR.ADD, get_fight_info(troop))
            elseif self._fight[troop._id] then
                if troop.state == resmng.TroopState.Back then
                    self._fight[troop._id] = nil
                    LOG("[Union] fight del: %s", troop._id)
                 --   self:notifyall("fight", resmng.OPERATOR.DELETE, {id=troop.idx})
                else
                    LOG("[Union] fight update: %s", troop._id)
                  --  self:notifyall("fight", resmng.OPERATOR.UPDATE, {id=troop.idx, T=chgs})
                end
            end
        end
    end

    -- Hx@2016-01-26: 集结变化
    -- 集结变化时所有参与者都能知道
    -- 玩家能确定自己是否为集结发起者
    -- TODO:集结的目标援助发生变化时能攻击方能知道
    if troop.action == resmng.TroopAction.Mass then
        if not self._fight[troop._id] then
            self._fight[troop._id] = troop
            LOG("[Union] fight add: %s", troop._id)
            --self:notifyall("fight", resmng.OPERATOR.ADD, get_fight_info(troop))
        elseif self._fight[troop._id] then
            if troop.state == resmng.TroopState.Back then
                self._fight[troop._id] = nil
                LOG("[Union] fight del: %s", troop._id)
             --   self:notifyall("fight", resmng.OPERATOR.DELETE, {id=troop.idx})
            else
                local data = {
                    id = troop.idx,
                    T = {
                        action = chgs.action,
                        state = chgs.state,
                        tmStart = chgs.tmStart,
                        tmOver = chgs.tmOver,
                        eid = chgs.eid,
                        did = chgs.did,
                        sx = chgs.sx,
                        sy = chgs.sy,
                        dx = chgs.dx,
                        dy = chgs.dy,
                    },
                }
                if chgs.troops then
                    data.A = troop_t.get_by_tid(troop._id):atk_general(5)
                    data.As = {
                        total = #troop.troops
                    }
                end

                LOG("[Union] fight update: %s", troop._id)
                room.troop_broadcast(troop,"fight", resmng.OPERATOR.UPDATE)
            end
        end
    end
end

function get_fight_info(troop)
    local xs = {
        id = troop.idx,
        A = troop:atk_general(5),
        D = troop:def_general(5),
        As = {
            total = #troop.troops
        },
        Ds = {
            total = #(troop:owner().aid) + 1
        },
    }

    local Au = troop:owner():union()
    if Au then
        xs.Au = {uid=Au.uid,alias=Au.alias,flag=Au.flag}
    end
    local D = get_ety(troop.did)
    if is_ply(D.eid) then
        xs.Dc = {cival=D.cival}
        local Du = D:union()
        if Du then
            xs.Du = {uid=Du.uid,alias=Du.alias,flag=Du.flag}
        end
    end

    xs.T = {
        action = troop.action,
        state = troop.state,
        tmStart = troop.tmStart,
        tmOver = troop.tmOver,
        eid = troop.eid,
        did = troop.did,
        sx = troop.sx,
        sy = troop.sy,
        dx = troop.dx,
        dy = troop.dy,
        idx = troop.idx,
    }

    return xs
end

-- -----------------------------------------------------------------------------
-- Hx@2016-01-26 : 是否在联盟领地
-- 奇迹&小奇迹
-- AnchorPoint(0,0)
-- -----------------------------------------------------------------------------
function is_in_territory(self, x, y, size)
    for _, v in pairs(self.build) do
        local cc = resmng.prop_world_unit[v.propid]
        if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE
            or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
            if v.x - cc.Range <= x and x <= v.x + cc.Range - size
                and v.y - cc.Range <= y and y <= v.y + cc.Range - size then
                return true
            end
        end
    end
    return false
end

function can_castle(self, bcc)  --在奇迹有效范围内

    if bcc.Mode ~= resmng.CLASS_UNION_BUILD_CASTLE and bcc.Mode ~= resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        for _, v in pairs(self.build or {} ) do
            local cc = resmng.prop_world_unit[v.propid]
            if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE and cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                local c_x = cc.x - cc.Range
                local c_y = cc.y - cc.Range
                local s = 2*cc.Range + cc.Size
                if (bcc.x >=c_x and bcc.x<=c_x+s-bcc.Size) and (bcc.y>=c_y and bcc.y<=c_y+s-bcc.Size)then
                    return true
                end
            end
        end
        return false
    end

    return true

end

function can_other_castle(self, bcc)  --奇迹范围排他性检查
    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        for _, t in pairs(unionmng.get_all() or {}  ) do
            for _, v in pairs(t.build or {} ) do
                local c = resmng.get_conf("prop_world_unit",v.propid)
                if c.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE then
                    if (bcc.x >=v.x-c.Range and bcc.x<=v.x+c.Size+c.Range) and (bcc.y>=v.y-c.Range and bcc.y<=v.y+c.Range+c.Size)then
                        return false
                    end
                end
            end
        end
    end
    return true
end

function can_build(self, id)
    local bcc = resmng.get_conf("prop_world_unit",id)
    if not bcc then return false end

    if not self:can_castle(bcc) then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end

    if not self:can_other_castle(bcc) then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end

    local b = union_buildlv.get_buildlv(self._id,bcc.BuildMode)
    if not b then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end

    local bb = resmng.get_conf("prop_union_buildlv",b.id)
    if not bb then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end
    --等级
    if bb.Lv < bcc.Lv then
        ack(self, "can_build", resmng.E_DISALLOWED,0)
        return false
    end
    --数量
    local num = self:get_ubuild_num(bcc.Mode)
    if self:get_build_count(bcc.Mode) >= num then return false end

    if bcc.BuildMode ==  UNION_CONSTRUCT_TYPE.SUPERRES  then
        --超级矿排他
        for _, v in pairs(self.build) do
            local cc = resmng.get_conf("prop_world_unit",v.id)
            if cc.BuildMode == bcc.buildMode and cc.Mode ~= bcc.Mode then
                ack(self, "can_build", resmng.E_DISALLOWED,0)
                return false
            end
        end
    end
    return true
end

function get_build_count(self, mode)--计算军团建筑已有数量
    local count = 0
    local c = resmng.get_conf("prop_world_unit",10*1000*1000 + mode*1000 + 1)

    for _, v in pairs(self.build) do
        local cc = resmng.get_conf("prop_world_unit",v.propid)
        if cc.BuildMode == c.BuildMode and v.state ~=BUILD_STATE.DESTROY then
            count = count + 1
        end
    end
    return count
end

function get_ubuild_num(self,mode)--计算军团建筑上限数量

    if mode == resmng.CLASS_UNION_BUILD_CASTLE then
        return get_castle_count(self.membercount)
    else
        local base = 0
        for _, v in pairs(self.build) do
            local cc = resmng.get_conf("prop_world_unit",v.id)
            if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE then
                base = base + 1
            end
        end
        local b = resmng.get_conf("prop_world_unit",10*1000*1000+mode*1000+1)
        local c = resmng.get_conf("prop_union_buildlv",b.BuildMode*1000+1)
        if c then
            return base*c.Mul
        end
    end

    return 0
end

function refresh_builds(self)
    for _, v in pairs(self.build) do
        v.ef = nil
    end
end

function valid_build(self, propid)
    local cc = resmng.prop_world_unit[propid]
    if not cc then
        WARN("[Union] build upgrade, not found, propid:%s", b.propid)
        return nil
    end

    local blv = union_buildlv.get_buildlv(self._id,cc.Mode)
    if not blv then return end
    local lvcc = resmng.prop_union_buildlv[blv.id+1]
    if not lvcc then return end

    for _, v in pairs(resmng.prop_world_unit) do
        if v.Class == cc.Class and cc.Mode == v.Mode and v.Lv == cc.Lv+1 then
            return v.ID
        end
    end
    return nil
end

function upgrade_build(self, A, idx)
    local b = self.build[idx]
    if not b then
        WARN("[Union] build upgrade, not found, idx:%s", idx)
        return resmng.E_FAIL
    end

    local id = self:valid_build(b.propid)
    if not id then
        WARN("[Union] build upgrade, valid id nil")
        return resmng.E_FAIL
    end

    if not is_legal(A, "BuildUp") or id == b.propid then
        return resmng.E_DISALLOWED
    end

    local cc = resmng.prop_world_unit[b.propid]
    local nxtcc = resmng.prop_world_unit[id]
    local tm = nxtcc.Dura - cc.Dura

    b.state = BUILD_STATE.UPGRADE
    LOG("[Union] build upgrade, _id:%s, tm:%s, player:%s", b._id, tm, A.pid)
    return resmng.E_OK
end

function get_build(self, idx )
    if idx then
	    return self.build[idx]
    else
	    return self.build
    end
end

--}}}

function add_room_id(self, id)
    for k, v in pairs(self.battle_room_ids or {}) do
        if v == id then return end
    end
    table.insert(self.battle_room_ids, id)
end

function rm_room_id(self, id)
    for k, v in pairs(self.battle_room_ids or {}) do
        if v == id then
            self.battle_room_ids[k] = nil
            break
        end
    end
end

function union_pow(self)
    local pow = 0
    for _, v in pairs(self._members) do
        pow = pow + calc_pow(v.lv,v.builds,v.arms,v.equips,v.techs,v.genius)
    end
    return pow
end















