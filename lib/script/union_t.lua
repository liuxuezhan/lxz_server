-- Hx@2015-11-30 : 军团类
module_class("union_t", {
    uid = 0,
    _id = 0,
    flag = 0, -- 军团标识
    name = "",
    alias = "",
    level = 0,
    language = "",
    credit = 0,
    membercount = 0,
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
    mc_start_time = 20, -- 设置mc 开始的时间
    mc_reward_pool = {}, -- 怪物攻城的奖励池
    enlist = {}, --招募信息
    rank_alias = {"","","","","",""}, --军阶称谓
    tm_buf_over = 0,
    chat_room = "", -- 聊天room
    mc_point = 0,  --怪物攻城活动积分
    kill = 0,      --军团杀敌数

})

--

function load()
    local db = dbmng:getOne()
    local info = db.union:find({})
    while info:hasNext() do
        local union = union_t.new(info:next())
        unionmng._us[union.uid] = union
        if union.new_union_sn and union.new_union_sn > new_union._id   then
            new_union._id =  union.new_union_sn
        end
    end

    info = db.union_log:find({})
    while info:hasNext() do
        local lg = info:next()
        local u = unionmng.get_union(lg._id)
        if u then
            u.log = lg.log
            local csn = 0
            for _, v in pairs(lg.log or {}) do
                if csn < v.sn then
                    csn = v.sn
                end
            end
            u.log_csn = csn
        end
    end
end

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
        self.mc_timer = timer.new("monster_city", leftTime, self.uid, 1)
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
    time = os.time(temp)
    return (gTime - time)
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
        if city then return city end
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
        self.monster_city_stage = 0
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
    self.donate = self.donate - prop.Consume
end

function check_time_limit(self, npcId)
    return true
end

function can_declare_war(self, npcId)

    if is_npc_city_full(self) then
        return false
    end

    if check_conditon(self, npcId) then
        if check_time_limit(self, npcId) then
            try_reset_declare_data(self)

            if self.declare_wars and  #self.declare_wars >= 3 then
                return false
            else
                if is_already_declare(self, npcId) then
                    return false
                else
                    return can_npc_be_declare(self,npcId) and npc_city.can_npc_be_declare(npcId)
                end

            end
        else
            return false
        end
    else
        return false
    end
end

function get_tab_nums(tab)
    local num = 0
    for k, v in pairs(tab) do
        num = num + 1
    end
    return num
end

-- 城市是否相连
function can_npc_be_declare(self, npcId)
    local num = get_tab_nums(self.npc_citys)
    if self.npc_citys and num ~= 0 then
        local propid =  gEtys[ npcId ].propid
        for k, v in pairs(self.npc_citys) do
            for _, va in pairs(resmng.prop_world_unit[ gEtys[ v ].propid ].Neighbor or {} ) do
                if va == propid then
                    return true
                end
            end
        end
        return false
    else
       self.npc_citys = {}
    end
    return true
end

function is_npc_city_full(self)
    local limit = 1
    local prop = resmng.prop_tw_union_consume[1]
    if prop then
        if (self.membercount - prop.Condition[1] ) > 0 then
            limit = math.floor((self.membercount -  prop.Condition[1]) /  prop.Condition[2]) + 1 or 0
        end
        local num = get_tab_nums(self.npc_citys or {})
        return num >= limit
    end
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
    if npc then
        local prop = resmng.prop_tw_consume[npc.lv]
        local cond1 = check_mem(self, prop)
        local cond2 = check_score(self, prop)
        return cond1 and cond2
    end
end
-- union member level limit
function check_mem(self, prop)
    local num = 0
    if self._members then
        for k, v in pairs(self._members) do
            local lv = v:get_castle_lv()
            if lv then

                if  lv >= prop.Condition[1] then
                    num = num +1
                end
            end
        end
    else
        num = 0
    end
    return num >= prop.Condition[2]
end

function check_score(self, prop)
    return self.donate >= prop.Consume
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
function create(A, name, alias, language, propid)

    local id = getId("union")
    local data = {
        uid=id,_id=id,name=name,alias=alias,level=1,language=language,credit=0,
        membercount=0,leader=A.pid, note_in="",note_out="",invites = {},
        enlist = {check = 0 ,text="",lv=0, pow=0}, --招募信息
        rank_alias = {"","","","","",""}, --军阶称谓
        tm_buf_over = 0,
    }

    local union = new(data)
    if not union_god.set(union,propid) then
        return
    end

    unionmng.add_union(union)
    gPendingSave.union[union._id] = union._pro

    union:add_member(A,A)
    A:set_rank(resmng.UNION_RANK_5)

    gPendingSave.union_log[id] = {_id=id}

    --- create chat room
    --Rpc:create_room(A, tostring(union.uid), CHAT_HOST, A.chat_account)
    return union
end

function on_check_pending(db, _id, chgs)
    local u = unionmng.get_union(_id)
    if u then
        db.union:update({_id=_id}, {["$set"]= chgs})
        chgs.uid = _id
        u:notifyall(resmng.UNION_EVENT.INFO, resmng.UNION_MODE.UPDATE, chgs)
    end
end

function get_ef(self)--军团buf
    if self._ef then
        return self._ef
    end

    self._ef = {}
    if self._tech then
        for _, v in pairs(self._tech) do
            local c = resmng.get_conf("prop_union_tech", v.id)
            if c then
                for k, num in pairs(c.Effect or  {} ) do
                    self._ef[k] = (self._ef[k] or 0) + num
                end
            end
        end
    end

    if self.buildlv then
        for _, v in pairs(self.buildlv.data or {} ) do
            local c = resmng.get_conf("prop_union_buildlv", v.id)
            if c then
                for k, num in pairs(c.Effect or  {} ) do
                    self._ef[k] = (self._ef[k] or 0) + num
                end
            end
        end
    end

    if self.god  then
        local c = resmng.get_conf("prop_union_god", self.god.propid)
        if c then
            for k, num in pairs(c.Effect or  {} ) do
                self._ef[k] = (self._ef[k] or 0) + num
            end
        end
    end

    return self._ef
end

function get_castle_ef(self,p)--奇迹buf
    local sn = math.huge
    local bc = {}
    if p then
        for k, v in pairs(self.build or {} ) do
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
    if self.new_union_sn then
        return 200
    end
    local c = resmng.get_conf("prop_effect_type", "CountMember")
    local num = get_val_by("CountMember",self:get_ef())
    return ((c.Default or 0) + num)
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
    if self.god then
        info.mars_propid = self.god.propid
    end
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
    info.rank_alias = self.rank_alias
    info.enlist= self.enlist
    return info
end


function destory(self)

    for k, v in pairs(self.build) do
        union_build_t.remove_build(v)
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


function add_member(self, A,B)
    if self.membercount >= self:get_memberlimit() then
        WARN("军团人数满")
        return  
    end

    if self:has_member(A) then return resmng.E_ALREADY_IN_UNION end
    local old = unionmng.get_union(A:get_uid())
    if old then
        Rpc:tips(B,1,resmng.UNION_ADD_MEMBER_1,{},{})
        self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=0})
        return  
    end

    A._union.tmJoin = gTime
    A._union.rank = resmng.UNION_RANK_1
    A:set_uid(self.uid)
    gPendingSave.union_member[A.pid] = A._union 
    A.uname = self.alias
    etypipe.add(A)

    self.pow = (self.pow or 0) + A:get_pow()
    if self.pow > 0 and not self.new_union_sn then rank_mng.add_data( 5, self.uid, { self.pow } ) end

    self._members[A.pid] = A
    self.membercount = tabNum(self._members)
    local t = A:get_union_info()
    t.uid = self.uid
    self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.ADD, t)

    self.donate_rank = {} --清除捐献排行
    task_logic_t.process_task(A, TASK_ACTION.JOIN_PLAYER_UNION)
    send_chat_invite(self.chat_room, A)

    return resmng.E_OK
end

function rm_member(self, A,kicker)
    kicker = kicker or {}
    if not self:has_member(A) then return resmng.E_NO_UNION end
    A:recall_all()
    union_build_t.restore_del_res(self.uid,A.pid) 

    local f 
    if not self.new_union_sn then
        f = A:union_leader_auto()--移交军团长
    end

    self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.DELETE, {name=A.name,pid=A.pid,kicker=kicker.pid})
    self._members[A.pid] = nil
    self.membercount = tabNum(self._members)

    self.pow = (self.pow or 0) - A:get_pow()
    if self.pow > 0 and not self.new_union_sn then rank_mng.add_data( 5, self.uid, { self.pow } ) end

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

    return self:rm_member(B,A)
end

function quit(self, A)
    if not is_legal(A, "Quit") then return resmng.E_DISALLOWED end

    return self:rm_member(A)
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
    if not pid then
        WARN("not pid")
        return 
    end

    for k, v in pairs(self.applys) do
        if pid == v.pid then
            if (v.tm + 60*60*48) > gTime then
                return k 
            else
                self.applys[k]=nil
                gPendingSave.union[self.uid].applys = self.applys
                return 
            end
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
    if not self:has_member(A) then 
        WARN("")
        return 
    end
    if not is_legal(A, "Invite") then 
        WARN("")
        return  
    end
    if self:remove_apply(B.pid) then
        self:notifyall(resmng.UNION_EVENT.REJECT, resmng.UNION_MODE.DELETE, {B.pid})
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
    self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, A:get_union_info())
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

function notifyall(self, what, mode, data)
    local pids = {}
    for _, p in pairs(self._members) do
        if p:is_online() then
            table.insert(pids, p.pid)
        end
    end
    if #pids == 0 then return end
    Rpc:union_broadcast(pids, what, mode, data)
    if (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.ADD ) 
        or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.DELETE ) 
        or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.RANK_UP ) 
        or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.RANK_DOWN ) 
        or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.TITLE ) 
        or (what ==resmng.UNION_EVENT.TECH and mode ==resmng.UNION_MODE.ADD ) 
        or (what ==resmng.UNION_EVENT.BUILDLV and mode ==resmng.UNION_MODE.UPDATE ) 
        or (what ==resmng.UNION_EVENT.BUILD_SET and mode ==resmng.UNION_MODE.ADD ) 
        or (what ==resmng.UNION_EVENT.MISSION and mode ==resmng.UNION_MODE.GET ) 
        or (what ==resmng.UNION_EVENT.MISSION and mode ==resmng.UNION_MODE.OK ) 
        or (what ==resmng.UNION_EVENT.TASK and mode ==resmng.UNION_MODE.ADD ) 
        or (what ==resmng.UNION_EVENT.FIGHT and mode ==resmng.UNION_MODE.ADD ) 
     then
        self:add_log(what, mode,data)
    end
end


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


function upgrade_tech(self, idx)
    local tech = self:get_tech(idx)
    if not tech or not union_tech_t.is_exp_full(tech) then
        return resmng.E_FAIL
    end

    local next_conf = resmng.get_conf("prop_union_tech",tech.id + 1)
    if not next_conf then
        return resmng.E_MAX_LV
    end

    if tech.tmOver ~= 0 then
        return resmng.E_FAIL
    end

    local c = resmng.get_conf("prop_union_tech",tech.id )
    local tm = c.TmLevelUp
    tech.tmStart = gTime
    tech.tmOver = gTime + tm
    tech.tmSn = timer.new("uniontech", tm, self.uid, idx)

    self:notifyall(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.UPDATE, { idx=tech.idx,id=tech.id,tmStart=tech.tmStart, tmOver=tech.tmOver })

    return resmng.E_OK
end

function do_timer_tech(self, tsn, idx)
    local tech = self:get_tech(idx)
    if not tech then
        WARN("timer got no tech") return
    end

    local next_conf = resmng.get_conf("prop_union_tech",tech.id + 1)
    if not next_conf then
        WARN("没有下一级:"..tech.id+1) return
    end

    tech.id = next_conf.ID
    tech.exp = tech.exp - next_conf.Exp * next_conf.Star
    tech.tmSn = 0
    tech.tmStart = 0
    tech.tmOver = 0
    self._ef = nil
    gPendingSave.union_tech[tech._id] = tech
    self:notifyall(resmng.UNION_EVENT.TECH, resmng.UNION_MODE.ADD, { idx=tech.idx,id=tech.id,exp=tech.exp,tmOver=tech.tmOver,tmStart=tech.tmStart })
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
            local conf = resmng.get_conf("prop_union_tech",id)
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


function add_log(self, what, op,data)

    self.log_csn = (self.log_csn or 0 ) + 1 
    local log = {
        sn = self.log_csn,
        tm = gTime,
        mode = what,
        op = op,
        data = data,
    }

    local len = #self.log
    for i = #self.log, 1, -1 do
        if self.log[i].tm < (gDayStart or gTime) - 2592000 then
            table.remove(self.log, i)
        end
    end

    if #self.log > 100 then
        for i = 1, 50 do
            table.remove(self.log, i)
        end
    end

    table.insert(self.log, log)
    dbmng:getOne().union_log:update( {_id=self._id}, { ["$push"]={ log={["$each"]={log}, ["$slice"]=-100 }} }, true )
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

    local result = {}
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
end

function get_log_by_sn(self, sn)
    local result = {}
    if not self.log then
        return {}
    end

    local idx = 0
    if sn == 0 then
        idx = #self.log
    else
        idx = log_qfind(self.log, sn)
        if not idx then return result end
    end

    while idx > 0  do
        local log = self.log[idx]
        if log then
            if #result >= 20 then break end
            table.insert(result, log)
        end
        idx = idx - 1
    end
    return result
end


function in_castle(v,x,y,r)  --在奇迹有效范围内
    local cc = resmng.get_conf("prop_world_unit",v.propid)
    if not cc then return false end
    if  v.state ~=BUILD_STATE.DESTROY and  v.state ~=BUILD_STATE.CREATE then
        if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
            xx,yy = (x+r),(y+r)
            local c_x = v.x - cc.Range + r
            local c_y = v.y - cc.Range + r
            local s = 2*cc.Range + cc.Size - 2*r
            if xx >= c_x and xx <= (c_x+s) and yy >= c_y and yy <= (c_y+s) then
                return true
            end
        end
    end
    return false
end

function out_castle(v,x,y,r)  --在奇迹有效范围外
    local cc = resmng.get_conf("prop_world_unit",v.propid)
    if not cc then return true end

    if  v.state ~=BUILD_STATE.DESTROY then
        if cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or cc.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
            xx,yy = (x+r),(y+r)
            local c_x = v.x - cc.Range + r
            local c_y = v.y - cc.Range + r
            local s = 2*cc.Range + cc.Size - 2*r
            if xx >= c_x and xx <= (c_x+s) and yy >= c_y and yy <= (c_y+s) then
                if xx > c_x and xx < (c_x+s) and yy > c_y and yy < (c_y+s) then
                    return false
                else
                    return true
                end
            end
        end
    end
    return true
end

function can_castle(self,x,y,r)  --在奇迹有效范围内
    for k, v in pairs(self.build or {} ) do
        if in_castle(v,x,y,r)  then
            return true
        end
    end
    return false
end

function can_other_castle(self, x, y,r)  --奇迹不能建造在其他奇迹范围内
    for _, t in pairs(unionmng.get_all() or {}  ) do
        for k, v in pairs(t.build or {} ) do
            if not out_castle(v,x,y,r)  then
                return true
            end
        end
    end
    return false
end

function can_build(self, id, x, y)
    local bcc = resmng.get_conf("prop_world_unit",id)
    if not bcc then return false end

    if bcc.Mode ~= resmng.CLASS_UNION_BUILD_CASTLE and bcc.Mode ~= resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        if not self:can_castle( x, y,bcc.Size/2) then
            WARN( "不在奇迹范围内 \n" )
            return false
        end
    else
        if self:can_other_castle( x, y,bcc.Size/2) then
            WARN("奇迹不能建造在其他奇迹范围内\n")
            return false
        end
    end


    local b = union_buildlv.get_buildlv(self._id,bcc.BuildMode)
    if not b then
        ERROR("建筑等级 错误\n")
        return false
    end

    local bb = resmng.get_conf("prop_union_buildlv",b.id)
    if not bb then
        ERROR("propid 错误\n")
        return false
    end
    --等级
    if bb.Lv < bcc.Lv then
        WARN("等级不够\n")
        return false
    end
    --数量
    local num = self:get_ubuild_num(bcc.Mode)
    if self:get_build_count(bcc.Mode) >= num then
        WARN("数量达到上限\n")
        return false
    end

    if bcc.BuildMode ==  UNION_CONSTRUCT_TYPE.SUPERRES  then
        --超级矿排他
        for k, v in pairs(self.build) do
            local cc = resmng.get_conf("prop_world_unit",v.propid)
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

    for k, v in pairs(self.build) do
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
        for k, v in pairs(self.build) do
            local cc = resmng.get_conf("prop_world_unit",v.propid)
            if cc and cc.Mode == resmng.CLASS_UNION_BUILD_CASTLE then
                base = base + 1
            end
        end
        local b = resmng.get_conf("prop_world_unit",10*1000*1000+mode*1000+1)
        if not b then
            return 0
        end
        local c = resmng.get_conf("prop_union_buildlv",b.BuildMode*1000+1)
        if c then
            return base*c.Mul
        end
    end

    return 0
end


function get_build(self, idx )
    if idx then
        if self.build then
            local e = get_ety(self.build[idx].eid)
            if e  then
                return e
            end
        end
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
        pow = pow + v:get_pow() 
    end
    self.pow = pow
    return pow
end

function get_pow( self )
    local pow = self.pow
    if not pow or pow == 0 then
        pow = self:union_pow()
    end
    return pow
end


