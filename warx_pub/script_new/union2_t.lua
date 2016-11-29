-- Hx@2015-11-30 : 军团类
module( "union2_t", package.seeall )
module_class("union2_t", {
    uid = 0,
    _id = 0,
    map_id = 0,
    flag = 1, -- 军团标识
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
    abd_city_time = 0,  -- npc 弃城的时间，每天只能弃城一次
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
    buf = {},--总动员
    chat_room = "", -- 聊天room
    mc_point = 0,  --怪物攻城活动积分
    kill = 0,      --军团杀敌数
    kw_bufs = {}, -- 王城战buf
    restore = {},
    market = {},

})

--

function load()
    local db = dbmng:getOne()
    local info = db.union2_t:find({})
    while info:hasNext() do
        local union = union2_t.wrap(info:next())
        unionmng._us2[union.uid] = union
        if union:is_new() and union.new_union_sn > new_union._id   then
            new_union._id =  union.new_union_sn
        end
        union:init()
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

function get_leader(self)
    local map_id = self.map_id
    local func = "get_remote_leader"
    local param = {"union", self.uid}
    local leader =  remote_func(map_id, func, param)
    if leader then return leader end
end

function get_members(self)
    return self._members
end

function get_all_members(self)
    if self._members then return self._members end
    local map_id = self.map_id
    local func = "get_remote_members"
    local param = {"union", self.uid}
    local _members =  remote_func(map_id, func, param)
    if _members then
        self._members = _members
        return self._members
    end
end

function get_build(self, idx)
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
    if self.build then return self.build end
    local map_id = self.map_id
    local func = "get_remote_build"
    local param = {"union", self.uid}
    local build = remote_func(map_id, func, param)
    if build then
        self.build = build
        return self.build
    end
end

function get_tech(self, idx)
    if not idx then
        if self._tech then return self._tech end
        local map_id = self.map_id
        local func = "get_remote_tech"
        local param = {"union", self.uid}
        local tech = remote_func(map_id, func, param)
        if tech then
            self._tech = tech
            return self._tech
        end
    end
    self:init_tech(idx)
    return self._tech[idx]
    
end

function get_god(self)
    if self.god then return self.god end
    local map_id = self.map_id
    local func = "get_remote_god"
    local param = {"union", self.uid}
    local god = remote_func(map_id, func, param)
    if god then
        self.god = god
        return self.god
    end
end


-- 怪物攻城 monster_city
-- 设置军团在怪物攻城中的状态

function set_mc_start(self, time, ply)
    if ply then
        ply:add_debug("cross gs can not join mc")
        return
    end
    if os.date("%d", self.set_mc_time) ~= os.date("%d", gTime) and self.monster_city_stage == 0 then
    local now = os.date("*t", gTime)
    local hour = now.hour
    if hour > time then  --只能设置当天的怪物定时器
        return
    end

        timer.del(self.mc_timer)
        local leftTime = get_left_time(time)
        self.mc_start_time = time
        self.set_mc_time = gTime
        -- to do
        --
        local prop = resmng.get_conf("prop_act_notify", resmng.MC_TIMESET)
        if prop then
            if prop.Chat2 then
                self:union_chat("", prop.Chat2, {ply.name, time})
            end
        end
        local mc_ntf_time = leftTime - 30 * 60
        if mc_ntf_time <= 0 then
            mc_ntf_time = 10
        end

        if player_t.debug_tag then
            leftTime = 10
        end

        self.mc_timer = timer.new("mc_notify", mc_ntf_time, resmng.MC_PREPARE, self.uid)

        self.mc_timer = timer.new("monster_city", leftTime, self.uid, 1)
    else
        return false
    end
end

function mc_notify(self, notify_id)
    for k, v in pairs(self.npc_citys) do
        local city = get_monster_city(v)
    end
    local prop = resmng.get_conf("prop_act_notify", notify_id)
    if prop then
        if prop.Chat2 then
            self:union_chat("", prop.Chat2, {})
        end
    end
end

function get_default_time(self)
    -- base on language
    return 16
end

function get_left_time(endTime)
    local now = os.date("*t", gTime)
    local hour = now.hour
    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0, sec=0 }

    temp.hour = endTime
    time = os.time(temp)
    return (time - gTime)
end

function set_default_start(self)
    if self.mc_start_time == 999 then
        self.mc_start_time =  get_default_time(self)
    end
    timer.del(self.mc_timer)
    local time = get_left_time(self.mc_start_time)
    if player_t.debug_tag then
        time = 10
    end
    mc_ntf_time = time - 30 * 60

    timer.new("mc_notify", mc_ntf_time, resmng.MC_PREPARE, self.uid)
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

    if stage == 1 then
        local prop = resmng.get_conf("prop_act_notify", resmng.MC_OPEN)
        if prop then
            if prop.Chat2 then
                self:union_chat("", prop.Chat2, {})
            end
        end
    end

    prop = resmng.prop_mc_stage[stage]

    self.monster_city_stage = stage

    if get_table_valid_count(self.npc_citys or {})  == 0 then
        return
    end



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
    end

    if prop.NextStage == stage then
        self.monster_city_stage = 0
        for k, v in pairs(self.npc_citys) do
            local city = get_monster_city(v)
            if city then

                local def_mc = monster_city.citys[city.eid]
                for eid, _ in pairs(def_mc or {}) do
                    local def = get_ety(eid)
                    if def then
                        monster_city.remove_city(def)
                    end
                end
                monster_city.citys[city.eid] = nil

                monster_city.citys[v] = nil
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
    print("npc full or not")

    if is_npc_city_full(self) then
        return false
    end

    if check_conditon(self, npcId) then
        if check_time_limit(self, npcId) then
            try_reset_declare_data(self)
            print("delacre num full or not")

            if self.declare_wars and  get_table_valid_count(self.declare_wars or {}) >= 3 then
                return false
            else
                print("alread declare or not")
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
    print("npc citys connect or not")
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
        if player_t.debug_tag then
            limit = 100
        end
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
        print("union member and score saticfy or not", cond1, cond2)
        return cond1 and cond2
    end
end
-- union member level limit
function check_mem(self, prop)
    local num = 0
    local _members = self:get_all_members()
    if _members then
        for k, v in pairs( _members or {}) do
            local lv = player_t:get_castle_lv(v)
            if lv then
                if  lv >= prop.Condition[1] then
                    num = num +1
                end
            end
        end
    else
        num = 0
    end
    print("union member ", num)
    return num >= prop.Condition[2]
end

function check_score(self, prop)
    --跨服不消耗积分
    return true
    --return self.donate >= prop.Consume
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
    if get_table_valid_count(self.npc_citys or {}) == 0 then
        local leader = getPlayer(self.leader)
        if leader then
           local propid =  leader:player_nearly_citys()
           citys[propid] = propid
        end
    end
    self.can_atk_citys = citys
end



----------------npc city
------------------------------------------------

function init(self)
    --if not self._members then self._members = {} end
    if not self.applys then self.applys = {} end
    --if not self._invites then self._invites = {} end
    if not self.mass then self.mass = {} end
    --if not self._tech then self._tech = {} end
    if not self.log then self.log = {} end
    table.sort(self.log, function(l, r)
        return l.sn > r.sn
    end)
    if not self._fight then self._fight = {} end
    setmetatable(self._fight, {__mode="v"})
    if not self.donate_rank then self.donate_rank = {} end
    --if not self.mission then self.mission = {} end
    --if not self.build then self.build = {} end
end

--{{{ basic
function create(A, name, alias, language, propid)
    -- can not do
    return 
end

function on_check_pending(db, _id, chgs)
    local u = unionmng.get_union(_id)
    if u then
        chgs.uid = _id
        u:notifyall(resmng.UNION_EVENT.INFO, resmng.UNION_MODE.UPDATE, chgs)
    end
end

function get_ef(self)--军团buf

    if self._ef then return self._ef end

    self._ef = {}
    for _, v in pairs(self.buf) do
        local n = resmng.prop_buff[v1] or {}
        for k, num in pairs(n.Value or  {} ) do
            self._ef[k] = (self._ef[k] or 0) + num
        end
    end

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

    if self.god  then
        local c = resmng.get_conf("prop_union_god", self.god.propid)
        if c then
            for k, num in pairs(c.Effect or  {} ) do
                self._ef[k] = (self._ef[k] or 0) + num
            end
        end
    end

    for _, t in pairs(self.build or {} ) do
        local c = resmng.get_conf("prop_world_unit",t.propid)
        if c.Mode == resmng.CLASS_UNION_BUILD_RESTORE then
            for k, num in pairs(c.Buff3 or  {} ) do
                self._ef[k] = (self._ef[k] or 0) + num
            end
        end
    end

    return self._ef
end

-- count == -1, means a buf forever
function add_buf(self, bufid, count)
    if count <= 0 and count ~= -1 then
        WARN( "add_buf, pid=%d, buf=%d, count=%d", self.uid, bufid, count)
        return
    end

    local node = resmng.prop_buff[ bufid ]
    if node then
        local dels = {}
        local bufs = self.buf
        if node.Mutex == 1 then  -- 互斥
            local group = node.Group
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    table.insert(dels, v)
                end
            end

        elseif node.Mutex == 2 then -- 高级替换低级
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.Lv > lv then return end
                    table.insert(dels, v)
                end
            end
        elseif node.Mutex == 3 then -- 相同的就叠加时间
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.ID == bufid then
                        if count == -1 then
                            v[3] = -1
                        else
                            local remain = v[3] - gTime
                            if remain < 0 then remain = 0 end
                            local tmOver = gTime + remain + count
                            v[3] = tmOver
                            timer.new("union_buf", remain, self.uid, bufid, tmOver)
                        end
                        self.buf = bufs
                        self._ef = nil
                        return
                    end
                end
            end
        end

        if #dels > 0 then
            for _, v in pairs( dels ) do
                self:rem_buf( v[1], v[3] )
            end
        end

        local tmOver = gTime + count
        if count == -1 then tmOver = -1 end
        local buf = {bufid, gTime, tmOver}
        table.insert(bufs, buf)
        self.buf = bufs
        self._ef = nil

        print(string.format("add_buf, pid=%d, bufid=%d, count=%d", self.uid, bufid, count))

        if count ~= -1 then
            timer.new("union_buf", count, self.uid, bufid, tmOver)
        end

        return buf
    end
end


function rem_buf(self, bufid, tmOver)
    local bufs = self.buf
    for k, v in pairs(bufs) do
        --v = {bufid, tmStart, tmOver}
        if v[1] == bufid then
            if not tmOver or tmOver == v[3] then
                table.remove(bufs, k)
                local node = resmng.prop_buff[ bufid ]
                self.buf = bufs
                self._ef = nil
                print(string.format("rem_buf, pid=%d, bufid=%d, buf_tmOver=%d, tmOver=%d, now=%d", self.uid, bufid, v[3], tmOver or 0, gTime))
                return v[3]
            end
        end
    end
end

function get_memberlimit(self)--军团人数上限
    if self:is_new() then
        return 50
    end
    local c = resmng.get_conf("prop_effect_type", "CountMember")
    if not c then c = {} end
    local num = get_val_by("CountMember",self:get_ef())
    return ((c.Default or 0) + num)
end

function get_day_store(self,p,dp)--仓库每日上限
    local bc = resmng.get_conf("prop_world_unit", dp.propid)
    if not bc then bc = {} end
    return p:get_val("CountDailyStore",bc.Buff)
end

function get_sum_store(self,p,dp)--仓库总上限
    local bc = resmng.get_conf("prop_world_unit", dp.propid)
    if not bc then bc = {} end
    return p:get_val("CountUnionStore",bc.Buff3)
end

function check(self)
    if not self:is_new() then
        local p = getPlayer(self.leader)
        if  p.uid ~=self.uid  then
            unionmng.rm_union(self)
            return false
        end
    end
    return true
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
        local leader = self:get_leader()
        if leader then
            info.leader = leader._pro.name
        end
    end
    info.pow = self:union_pow()
    info.tm_buf_over = self.tm_buf_over
    info.rank_alias = self.rank_alias
    info.enlist= self.enlist
    return info
end


function destory(self)
    -- can not do
end


function add_member(self, A,B)
    -- can not do
    return 
end

function rm_member(self, A,kicker)
    -- can not do
    return
end

function kick(self, A, B)
    -- can not do
    return
end

function quit(self, A)
    -- can not do
    return
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
            local _members = self:get_members() or {}
            if not _members[A.pid] then
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
        gPendingSave.union_t[self.uid].applys = self.applys
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
                gPendingSave.union_t[self.uid].applys = self.applys
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
    gPendingSave.union_t[self.uid].applys = self.applys

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
    -- can no do
    return
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
    --can not do
    return 
end


function remove_invite(self, k)
    --can not do
end

function add_invite(self, pid)
    -- can not do
end

function get_invite(self, pid)
    -- can not do
end

function notifyall(self, what, mode, data)
    local pids = {}
    local _members = self:get_members()
    for _, p in pairs(_members or {}) do
        if player_t.is_online(p) then
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

function can_donate(self, idx)
    -- can not do
    return false
end

function add_donate(self, num,p)
    -- can not do
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
    -- can not do
    return
end

function do_timer_tech(self, tsn, idx)
    -- can not do

end


function get_donate_rank(self, what)
    if not self.donate_rank[what] then
        local result = {}
        local _members = self:get_members()
        for _, v in pairs(_members or {}) do
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
                        return false
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
    -- can not do
end

function donate_summary_week(self)
    -- can not do
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

    if  not self.log then
        self.log = {}
        self.log_csn = 0
    end

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
    -- can not do
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
    -- can not do
    return false
end

function out_castle(v,x,y,r)  --在奇迹有效范围外
    -- can not do
    return true
end

function can_castle(self,x,y,r)  --在奇迹有效范围内
    -- can not do
    return false
end

function can_other_castle(self, x, y,r)  --奇迹不能建造在其他奇迹范围内
    -- can not do
    return false
end

function can_build(self, id, x, y)
    return false 
end

function get_build_count(self, mode)--计算军团建筑已有数量
    local count = 0

    for k, v in pairs(self.build) do
        if is_union_miracal(v.propid) and v.state ~=BUILD_STATE.DESTROY then
            count = count + 1
        end
    end
    return count
end

function get_ubuild_num(self,mode)--计算军团建筑上限数量

    local base = get_castle_count(self.membercount)
    local id = 10*1000*1000+mode*1000+1

    if is_union_miracal(id) then
        return base
    else
        local b = resmng.get_conf("prop_world_unit",id)
        local c = resmng.get_conf("prop_union_buildlv",b.BuildMode*1000+1)
        if c then
            return base*c.Mul
        end
    end

    return 0
end

--}}}

function union_pow(self)
    local pow = 0
    local _members = self:get_members()
    for _, v in pairs(_members or {}) do
        pow = pow + player_t.get_pow(v)
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

function is_new( self )
    if self.uid < 10000 then
        return true
    else
        return false
    end
end


function union_chat(self, word, chatid, args)
    local pids = {}
    local _members = self:get_members()
    for pid, v in pairs(_members or {}) do
        if v:is_online() then
             table.insert(pids, pid)
         end
    end
    Rpc:chat(pids, resmng.ChatChanelEnum.Union, 0, 0, "system", word, chatid, args)
end

function clear_kw_buff(self)
    self.kw_bufs = nil
end

function add_kw_buf(self, eid)
    local kw_bufs = self.kw_bufs or {}
    kw_bufs[eid] = eid
    self.kw_bufs = kw_bufs
end
