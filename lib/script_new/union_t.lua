-- Hx@2015-11-30 : 军团类
module_class("union_t", {
    uid = 0,
    _id = 0,
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
    market = {}
})

--

function load()
    local db = dbmng:getOne()
    local info = db.union_t:find({})
    while info:hasNext() do
        local union = union_t.wrap(info:next())
        if union.uid ~= 0  then
            unionmng._us[union.uid] = union
            if union:is_new() and union.new_union_sn > new_union._id   then
                new_union._id =  union.new_union_sn
            end
            union:init()
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


function get_members(self)
    return self._members
end
function get_build(self)
    return self.build
end

function get_god(self)
    return self.god
end

function get_leader(self)
    local leader = getPlayer(self.leader)
    if leader then return leader end
end

function get_remote_members(self, map_id, id, arg)
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, self._members or {})
end

function get_remote_build(self, map_id, id)
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, self.build or {})
end

function get_remote_tech(self, map_id, id)
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, self._tech or {})
end

function get_remote_god(self, map_id, id)
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, self._god or {})
end

function get_remote_leader(self, map_id, id)
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, self:get_leader())
end

function  get_remote_member_info(self, map_id, id, R0)
    local val = {}
    for _, A in pairs(self._members or {}) do
        if not R0  and player_t.get_rank(A) == resmng.UNION_RANK_0 then
        else
            table.insert(val, rpchelper.parse_rpc(player_t.get_union_info(A),"unionmember"))
        end
    end
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, val)
end
-- 怪物攻城 monster_city
-- 设置军团在怪物攻城中的状态

function set_mc_start(self, time, ply)
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

function get_live_mc(eid)
    local cityId = monster_city.citys[eid]
    if cityId then
        local city = get_ety(cityId)
        if city then return city end
    end
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

    local time = prop.Spantime
    if prop.NextStage ~= stage then
        set_mc_timer(self, time, prop.NextStage)
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
    print("union member ", num)
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
        info.leader = getPlayer(self.leader).name
    end
    info.pow = self:union_pow()
    info.tm_buf_over = self.tm_buf_over
    info.rank_alias = self.rank_alias
    info.enlist= self.enlist
    return info
end


function destory(self)

    if self:is_new() then
        return
    end

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
    gPendingDelete.union_t[ self.uid ] = 0

    for k, v in pairs(resmng.prop_rank) do
        if v.IsPerson ~= 1 then
            rank_mng.rem_data( k, self.uid )
        end
    end
    LOG("[Union] destory, uid:%s", self.uid)
end


function add_member(self, A,B)
    if self.membercount >= self:get_memberlimit() then
        INFO("军团人数满")
        return
    end

    if self:has_member(A) then return resmng.E_ALREADY_IN_UNION end
    local old = unionmng.get_union(A:get_uid())
    if old then
        Rpc:tips(B,1,resmng.UNION_ADD_MEMBER_1,{})
        self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=0})
        return
    end

    A:set_uid(self)

    self.pow = (self.pow or 0) + A:get_pow()
    if self.pow > 0 and not self:is_new() then rank_mng.add_data( 5, self.uid, { self.pow } ) end

    self._members[A.pid] = A
    self.membercount = tabNum(self._members)
    local t = A:get_union_info()
    t.uid = self.uid
    self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.ADD, t)

    self.donate_rank = {} --清除捐献排行
    --任务
    task_logic_t.process_task(A, TASK_ACTION.JOIN_PLAYER_UNION)
    task_logic_t.process_task(A, TASK_ACTION.OCC_NPC_CITY)
    send_chat_invite(self.chat_room, A)

    return resmng.E_OK
end

function rm_member(self, A,kicker)
    kicker = kicker or {}
    if not self:has_member(A) then return resmng.E_NO_UNION end
    A:recall_all()
    union_build_t.restore_del_res(self.uid,A.pid)

    local f
    if not self:is_new() then
        f = A:union_leader_auto()--移交军团长
    end

    self:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.DELETE, {name=A.name,pid=A.pid,kicker=kicker.pid})
    self._members[A.pid] = nil
    self.membercount = tabNum(self._members)

    self.pow = (self.pow or 0) - A:get_pow()
    if self.pow > 0 and not self:is_new() then rank_mng.add_data( 5, self.uid, { self.pow } ) end

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
    if k then
        self.invites[k]=nil
        gPendingSave.union_t[self.uid].invites = self.invites
    end
end

function add_invite(self, pid)
    assert(pid)

    local k, v = self:get_invite(pid)
    if not v then
        table.insert(self.invites, {tm=gTime,pid=pid})
        gPendingSave.union_t[self.uid].invites = self.invites
    else
        self.invites[k].tm = gTime
        gPendingSave.union_t[self.uid].invites = self.invites
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
    if not idx then
        return self._tech
    end
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
        INFO("没有下一级:"..tech.id+1) 
        return
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
    for _, A in pairs(self._members) do
        union_member_t.clear_donate_data(A,resmng.DONATE_RANKING_TYPE.DAY)
        union_member_t.clear_donate_data(A,resmng.DONATE_RANKING_TYPE.DAY_B)
    end
end

function donate_summary_week(self)
    local t = get_donate_rank(self,resmng.DONATE_RANKING_TYPE.WEEK)
    for k, v in pairs(t) do
        local val = {}
        if k == 1 then
            val = resmng.prop_item[1013161].Param[2] 
        elseif k == 2 then
            val = resmng.prop_item[1013162].Param[2] 
        elseif k == 3 then
            val = resmng.prop_item[1013163].Param[2] 
        end
        local p = getPlayer(v.pid)
        p:send_system_notice(10024, {}, {t[1].name,t[2].name,t[3].name}, val)
        union_member_t.clear_donate_data(p,resmng.DONATE_RANKING_TYPE.WEEK)
    end

    local t = get_donate_rank(self,resmng.DONATE_RANKING_TYPE.WEEK_B)
    for _, v in pairs(t) do
        local val = {}
        if k == 1 then
            val = resmng.prop_item[1013164].Param[2] 
        elseif k == 2 then
            val = resmng.prop_item[1013165].Param[2] 
        elseif k == 3 then
            val = resmng.prop_item[1013166].Param[2] 
        end
        local p = getPlayer(v.pid)
        p:send_system_notice(10025, {}, {t[1].name,t[2].name,t[3].name}, val)
        union_member_t.clear_donate_data(p,resmng.DONATE_RANKING_TYPE.WEEK_B)
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
            local b = {}
            b.xx,b.yy = (x+r),(y+r)--目标中心点
            b.x = v.x - cc.Range + r --可以放置范围的左下角
            b.y = v.y - cc.Range + r
            b.s = 2*cc.Range + cc.Size - 2*r
            if b.xx >= b.x and b.xx <= (b.x+b.s) and b.yy >= b.y and b.yy <= (b.y+b.s) then
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
            local b = {}
            b.xx,b.yy = (x+r),(y+r)--目标中心点
            b.x = v.x - cc.Range - r --不可以放置范围的左下角
            b.y = v.y - cc.Range - r
            b.s = 2*cc.Range + cc.Size + 2*r
            if b.xx >= b.x and b.xx <= (b.x+b.s) and b.yy >= b.y and b.yy <= (b.y+b.s) then
                if b.xx > b.x and b.xx < (b.x+b.s) and b.yy > b.y and b.yy < (b.y+b.s) then
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
            INFO( "不在奇迹范围内 \n" )
            return false
        end
    else
        if self:can_other_castle( x, y,bcc.Size/2) then
            INFO("奇迹不能建造在其他奇迹范围内\n")
            return false
        end
    end


    local b = union_buildlv.get_buildlv(self._id,bcc.BuildMode)
    if not b then
        INFO("建筑等级 错误\n")
        return false
    end

    local bb = resmng.get_conf("prop_union_buildlv",b.id)
    if not bb then
        INFO("propid 错误\n")
        return false
    end
    --等级
    if bb.Lv < bcc.Lv then
        INFO("等级不够\n")
        return false
    end
    --数量
    local num = self:get_ubuild_num(bcc.Mode)
    local sum = self:get_build_count(bcc.Mode)
    if sum >= num then
        INFO("数量达到上限:"..sum..":"..num)
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
    local c,c2
    if mode == resmng.CLASS_UNION_BUILD_CASTLE or mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        c = resmng.get_conf("prop_world_unit",10*1000*1000 + resmng.CLASS_UNION_BUILD_CASTLE*1000 + 1)
        c2 = resmng.get_conf("prop_world_unit",10*1000*1000 + resmng.CLASS_UNION_BUILD_MINI_CASTLE*1000 + 1)
    else
        c = resmng.get_conf("prop_world_unit",10*1000*1000 + mode*1000 + 1)
    end

    for k, v in pairs(self.build) do
        local cc = resmng.get_conf("prop_world_unit",v.propid)
        if ((c and cc.BuildMode == c.BuildMode ) or (c2 and cc.BuildMode == c2.BuildMode) ) and v.state ~=BUILD_STATE.DESTROY then
            count = count + 1
        end
    end
    return count
end

function get_ubuild_num(self,mode)--计算军团建筑上限数量

    local base = get_castle_count(self.membercount)

    if mode == resmng.CLASS_UNION_BUILD_CASTLE or mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        return base
    else

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

function is_new( self )
    if self.uid < 10000 then
        return true
    else
        return false
    end
end


function union_chat(self, word, chatid, args)
    local pids = {}
    for pid, v in pairs(self._members) do
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
