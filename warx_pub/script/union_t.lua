-- Hx@2015-11-30 : 军团类
module( "union_t", package.seeall )

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
    npc_citys = {}, -- 领土争夺占领的城市
    --can_atk_citys = {}, --玩家攻击的城市
    atk_id = 0,  -- 领土争夺好招攻击的对象
    def_id =  0, -- 领土争夺好招防御的对象
    declare_wars = {}, -- 宣战的城市
    declare_tm = 0, -- 宣战的次数
    abd_city_time = 0,  -- npc 弃城的时间，每天只能弃城一次
    last_declare_time = 0, --上次成功宣战的时间
    monster_city_stage = 0, -- 怪物攻城的波次
    mc_timer = 0, -- 怪物攻城定时器
    mc_ntf_timer = 0, -- 怪物攻城定时器
    set_mc_time = 999, -- 设置mc 开始的时间
    mc_start_time = {12, 30}, -- 设置mc 开始的时间
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
    mc_act_ply = {}, -- 参见本次mc活动玩家
    mc_ply_rank = {}, -- 参见本次mc活动玩家
    mc_reward_pool = {},  -- 本次mc奖励
    mc_trs = {},          --mc出发的攻打npc部队
    mc_grade = 1,
    last_join_act_tm = 0,
    act_rank = {},
    activity  = 0,
    build_first1  = 0,
    build_first2  = 0,
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

function get_all_members(self)
    return self._members
end


function get_god(self)
    return self.god
end

function get_leader(self)
    local leader = getPlayer(self.leader)
    if leader then return leader end
end

function get_remote_members(self, map_id, id, arg)
    return self._members
end

function get_remote_build(self, map_id, id)
    Rpc:callAgent(map_id, "agent_syn_call_ack", id, self.build or {})
end

function get_remote_tech(self, map_id, id, idx)
    return self:get_tech(idx)
end

function get_remote_god(self, map_id, id)
    return self.god
end

function get_remote_leader(self, map_id, id)
    return self:get_leader()
end

function get_remote_info(self, map_id, id)
    return self:get_info()
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

function set_mc_start(self, time, grade, ply)
    if grade > 3 or grade <= 0 then
        return
    end
    
    local langs = {
        resmng.MC_DIFFICULTY_SETTING_LOW,
        resmng.MC_DIFFICULTY_SETTING_MID,
        resmng.MC_DIFFICULTY_SETTING_HIGH,
    }

    local state, start_tm, end_tm = monster_city.get_mc_state()
    local next_st_tm, next_end_tm = monster_city.get_next_active_tm()
    if self.set_mc_time < gTime and self.monster_city_stage == 0 then 
        local now = os.date("*t", gTime)
        local leftTime = get_left_time({time, 30})
        if leftTime <= 0 then
            return 
        end
        timer.del(self.mc_timer)
        timer.del(self.mc_ntf_timer)
        self.mc_start_time = {time, 30}
        if state == 1 then
            self.set_mc_time = end_tm
        else
            self.set_mc_time = next_end_tm
        end

        local days = get_diff_days(leftTime + gTime, gTime)

        local days_lang = {
            resmng.ACTIVITIES_MC_DAY_1,
            resmng.ACTIVITIES_MC_DAY_2,
            resmng.ACTIVITIES_MC_DAY_3,
            resmng.ACTIVITIES_MC_DAY_4,
            resmng.ACTIVITIES_MC_DAY_5
        }
        -- to do
        --
        local prop = resmng.get_conf("prop_act_notify", resmng.MC_TIMESET)
        if prop then
            if prop.Chat2 then
                self:union_chat("", prop.Chat2, {ply.name, time, langs[grade], days_lang[days]})
            end
        end

        local mc_ntf_time = leftTime - 30 * 60
        if mc_ntf_time <= 0 then
            mc_ntf_time = 10
        end

        if player_t.debug_tag then
            leftTime = 10
        end

        self.mc_ntf_timer = timer.new("mc_notify", mc_ntf_time, resmng.MC_PREPARE, self.uid, days)

        self.mc_timer = timer.new("monster_city", leftTime, self.uid, 1)
        self.mc_grade = grade
        self.monster_city_stage = 0
        local _members = self:get_members()
        for _, player in pairs(_members or {}) do
            player:send_system_notice(resmng.MAIL_10064, {}, {ply.name, time, langs[grade], days_lang[days]})
        end
    else
        return false
    end
end

function mc_notify(self, notify_id)

    if self.set_mc_time < gTime then
        self.set_mc_time = gTime + 5400  -- when default timer set do set 
    end

    self.mc_act_ply = {}
    self.mc_reward_pool = {}

    for k, v in pairs(self.npc_citys or {}) do
        local city = monster_city.gen_monster_city(v)
    end
    local prop = resmng.get_conf("prop_act_notify", notify_id)
    if prop then
        if prop.Chat2 then
            self:union_chat("", prop.Chat2, {})
        end
    end

    local _members = self:get_members()
    for _, ply in pairs(_members or {}) do
        ply:send_system_notice(resmng.MAIL_10060, {})
    end
end

function add_mc_reward(self, rewards) 
    local pool = self.mc_reward_pool or {}
    for k, v in pairs(rewards or {}) do
        if v[2] then
            if v[2] == 11 then
                self.mc_point = self.mc_point + v[3]
            end
            local award = pool[v[2]]
            if not award then
                award = v
            else
                award[3] = award[3] + v[3]
            end
            pool[v[2]] = award
        end
    end
    self.mc_reward_pool = pool
end

function get_default_time(self)
    -- base on language
    return {2, 30}
end

function get_left_time(time)
    local now = os.date("*t", gTime)
    local temp = { year=now.year, month=now.month, day=now.day, hour=0, min=0, sec=0 }

    temp.hour = time[1]
    temp.min = time[2]
    local  tm = os.time(temp)

    local active_day, start_tm, end_tm = monster_city.get_mc_state()
    local next_st_tm, next_end_tm = monster_city.get_next_active_tm()
    if active_day == 1 then
        if tm > gTime then
            return (tm - gTime)
        else 
            return next_st_tm +  time[1] * 3600 + time[2] * 60 - gTime 
        end
    else
        return next_st_tm +  time[1] * 3600 + time[2] * 60 - gTime
    end
end

function set_default_start(self)
    --if  os.date("%d", self.set_mc_time) == os.date("%d", gTime) then
    --    return
    --end
    local time = timer.get(self.mc_timer)
    if time then
        if time.over > gTime then
            return
        end
    end

    if self.set_mc_time >= gTime then
        return
    end

    timer.del(self.mc_timer)
    timer.del(self.mc_ntf_timer)
    local time = get_left_time(self.mc_start_time or self:get_default_time())
    if player_t.debug_tag then
        time = 10
    end
    local mc_ntf_time = time - 30 * 60
    if mc_ntf_time <= 0 then
        mc_ntf_time = 10
    end

    if time <= 0 and time >= -60 then
        time = 10
    end

    self.mc_ntf_timer = timer.new("mc_notify", mc_ntf_time, resmng.MC_PREPARE, self.uid)
    self.mc_timer = timer.new("monster_city", time, self.uid, 1)
    self.mc_grade = 1
    self.monster_city_stage = 0
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
end

function get_live_mc(eid)
    local cityId = monster_city.citys[eid]
    if cityId then
        local city = get_ety(cityId)
        if city then return city end
    end
end

function get_mc_rank(self, version)
    local mc_ply_rank = self.mc_ply_rank or {}
    local mc_rank_info = {}
    if version == 0 or (mc_ply_rank.version or 1 )> version then
        for k, v in pairs(mc_ply_rank) do
            if k ~= "version" then
                local info =  rank_mng.rank_function[1](k)  
                local rank = {}
                rank[1] = v
                rank[2] = info
                mc_rank_info[k] = rank
            end
        end
        self.mc_rank_info = mc_rank_info
    end
    return mc_ply_rank.version or 0, mc_rank_info
end

function set_mc_state(self, stage)
    npc_city.reset_do_mc_citys()
    self:reset_npc_info_pack()

    local prop = {}
    if not stage then
        prop = resmng.prop_mc_stage[self.monster_city_stage]
        stage = prop.NextStage
    end

    if stage == 1 then
        local active_day, st_tm, end_tm = monster_city.get_mc_state()
        if active_day == 1 then
            self.set_mc_time = end_tm
        end
        
        self.mc_ply_rank = {}
        self.mc_act_ply = {}
        self.mc_reward_pool = {}

        local prop = resmng.get_conf("prop_act_notify", resmng.MC_OPEN)
        if prop then
            if prop.Chat2 then
                self:union_chat("", prop.Chat2, {})
            end
        end

        local _members = self:get_members()
        for _, ply in pairs(_members or {}) do
            ply:send_system_notice(resmng.MAIL_10061, {}, {})
            offline_ntf.post(resmng.OFFLINE_NOTIFY_REBEL, ply)
        end
        --offline ntf
        --offline_ntf.post(resmng.OFFLINE_NOTIFY_REBEL, self)
    end

    prop = resmng.prop_mc_stage[stage]

    self.mc_trs = {}

    self.monster_city_stage = stage

    --if get_table_valid_count(self.npc_citys or {})  == 0 then
    --    monster_city.send_union_act_award(self)
    --    self.monster_city_stage = 0
    --    return
    --end

    local mc_num = 0
    for k, v in pairs(self.npc_citys) do
        local city = get_monster_city(v)
        if city then
            mc_num = mc_num + 1
            monster_city.monster_city_job(self, city, stage, prop.Spantime)
        end
    end

    if mc_num == 0 then
        monster_city.send_union_act_award(self)
        self.monster_city_stage = 0
        npc_city.reset_do_mc_citys()
        return
    end

    local time = prop.Spantime
    if prop.NextStage ~= stage then
        set_mc_timer(self, time, prop.NextStage)
    end

    --if prop.NextStage == stage then
    --    self.monster_city_stage = 0
    --end

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
    self.declare_tm = 0
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
    self.declare_tm = self.declare_tm + 1
    self.last_declare_time = gTime
    self.donate = self.donate - prop.Consume
    self:reset_npc_info_pack()
end

function check_time_limit(self, npcId)
    return true
end

function can_declare_war(self, npcId)
    --print("npc full or not")

    if is_npc_city_full(self) then
        return false
    end

    if check_conditon(self, npcId) then
        if check_time_limit(self, npcId) then
            try_reset_declare_data(self)
            print("delacre num full or not")

            --if self.declare_wars and  get_table_valid_count(self.declare_wars or {}) >= 3 then
            if self.declare_tm >= 3 then
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
    --print("npc citys connect or not")
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
        self.last_declare_time = gTime
        self.declare_wars = {}
        self.declare_tm = 0
        self.send_declare_city = {}
    end
end

function check_conditon(self, npcId)
    local npc = get_ety(npcId)
    if npc then
        local prop = resmng.prop_tw_consume[npc.lv]
        local cond1 = check_mem(self, prop)
        local cond2 = check_score(self, prop)
        --print("union member and score saticfy or not", cond1, cond2)
        return cond1 and cond2
    end
end
-- union member level limit
function check_mem(self, prop)
    return check_mem_number(self, prop.Condition[1]) >= prop.Condition[2]
end

function check_mem_number(self, castle_lv)
    local num = 0
    local _members = self:get_all_members()
    if _members then
        for k, v in pairs(_members or {}) do
            local lv = v:get_castle_lv()
            if lv then
                if lv >= castle_lv then
                    num = num +1
                end
            end
        end
    end
    return num
end

function remote_check_mem_number(self, map_id, id, castle_lv)
    local num = self:check_mem_number(castle_lv)
    return {num}
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
    for k, v in pairs(self.npc_citys or {}) do
        local city = get_ety(v)
        if city then
            citysPropid[city.propid] = city.propid
        end
    end
    for k, v in pairs(self.npc_citys or {}) do
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
           citys =  leader:player_nearly_citys()
        end
        for _, v in pairs({3010004, 3020004, 3030004, 3030004}) do
            if not is_in_table(citys, v) then
                table.insert(citys, v)
            end
        end
    end
    --self.can_atk_citys = citys
    return citys
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
    if not self.battle_room_ids then self.battle_room_ids = {} end

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

    local u = new(data)
    if not union_god.set(u,propid) then return end

    u.flag = 1
    local conf = resmng.get_conf( "prop_union_god", propid )
    if conf then u.flag = conf.Mode end

    unionmng.add_union(u)

    u:add_member(A,A)
    A:set_rank(resmng.UNION_RANK_5)

    gPendingSave.union_log[id] = {_id=id}

    insert_global( "unions", id, { name=name, alias=alias, tmCreate=gTime, map=gMapID} )

        player_t.pre_tlog(nil,"UnionList",u.uid,u.name,u.language,0,
            tostring(u.mc_start_time[1]),u.membercount,u.activity or 0 ) 

    return u
end

function on_check_pending(db, _id, chgs)
    local u = unionmng.get_union(_id)
    if u then
        chgs.uid = _id
        u:notifyall(resmng.UNION_EVENT.INFO, resmng.UNION_MODE.UPDATE, chgs)
    end
end

function ef_init(self)
    local old = self._ef
    self._ef = nil
    local new = self:get_ef()

    if old then
        for k, fun in pairs(player_t.g_ef_notify) do
            if old[ k ] ~= new[ k ] then
                for _, p in pairs(self._members) do fun(p) end
            end
        end
    end
end


function get_ef(self, old)--军团buf
    if self._ef then return self._ef end

    self._ef = {}
    local ef = self._ef
    for _, v in pairs(self.buf) do
        local n = resmng.prop_buff[v[1]] or {}
        for k, num in pairs(n.Value or  {} ) do
            ef[ k ] = ( ef[ k ] or 0 ) + num
        end
    end

    if self._tech then
        for _, v in pairs(self._tech) do
            local c = resmng.get_conf("prop_union_tech", v.id)
            if c then
                for k, num in pairs(c.Effect or  {} ) do
                    ef[ k ] = ( ef[ k ] or 0 ) + num
                end
            end
        end
    end

    if self.god  then
        local c = resmng.get_conf("prop_union_god", self.god.propid)
        if c then
            for k, num in pairs(c.Effect or  {} ) do
                ef[ k ] = ( ef[ k ] or 0 ) + num
            end
        end
    end

    for _, t in pairs(self.build or {} ) do
        local c = resmng.get_conf("prop_world_unit",t.propid)
        if c and is_union_restore(t.propid) and t.state == BUILD_STATE.WAIT then
            for k, num in pairs(c.Buff3 or  {} ) do
                ef[ k ] = ( ef[ k ] or 0 ) + num
            end
        end
    end

    for k, fun in pairs(player_t.g_ef_notify) do
        if self._ef[k] then
            for _, p in pairs(self._members) do fun(p) end
        end
    end

    return self._ef
end

-- count == -1, means a buf forever
function add_buf(self, bufid, count)
    if count <= 0 and count ~= -1 then
        INFO( "[UNION]add_buf pid=%d, uid=%d, buf=%d, count=%d", self.pid,self.uid, bufid, count)
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
                        self:ef_init()
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
        self:ef_init()

        --lxz(string.format("add_buf, pid=%d, bufid=%d, count=%d", self.uid, bufid, count))

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
                self:ef_init()
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


function check(self)
    if not self:is_new() then
        local p = getPlayer(self.leader)
        if  (not p) or (p.uid ~=self.uid)  then
            unionmng.rm_union(self)
            INFO("[UNION] union_t check pid=%d uid=%d not uid=%d",p.pid,p.uid,self.uid)
            return false
        end
    end
    return true
end

function get_info(u)
    local info = {}

    info.uid = u.uid
    info.new_union_sn = u.new_union_sn or 0
    info.name = u.name
    info.alias = u.alias
    info.level = u.level
    if u.god then 
        info.mars_propid = u.god.propid 
    end
    info.membercount = u.membercount 
    info.memberlimit = u:get_memberlimit()
    info.language = u.language
    info.flag = u.flag
    info.note_in = u.note_in
    if u.leader and u.leader~=0  then
        info.leader = getPlayer(u.leader).name
    end
    info.pow = u:union_pow()
    info.tm_buf_over = u.tm_buf_over
    info.rank_alias = u.rank_alias
    info.enlist= u.enlist
    info.online = 0
    info.online_h = 0
    for _, p in pairs(u._members or {} ) do
        if p:is_online() then  info.online = info.online + 1 end
        local tm = math.max( p.tm_login or 0, p.tm_logout or 0 )
        if (tm > gTime-2*60*60) and (tm < gTime) then 
            info.online_h = info.online_h + 1
        end
    end
    return info
end


function destory(u)

    if u:is_new() then return end


    local dels = {}
    for k, v in pairs(u.build) do table.insert( dels, k ) end
    for _, k in pairs( dels ) do union_build_t.remove( u.build[ k ] ) end
    
    for _, A in pairs(u._members) do
        A:set_uid()
    end

    union_word.clear(u.uid)
    union_mall.clear(u.uid)
    union_buildlv.clear(u.uid)
    union_mission.clear(u)
    union_task.clear(u.uid)
    union_tech_t.clear(u.uid)
    union_relation.clear(u.uid)
    union_god.clear(u.uid)


    gPendingDelete.union_log[ u.uid ] = 0
    gPendingDelete.union_t[ u.uid ] = 0

    for k, v in pairs(resmng.prop_rank) do
        if v.IsPerson ~= 1 then rank_mng.rem_data( k, u.uid ) end
    end
    INFO("[Union] destory, uid:%s", u.uid)
    local db = dbmng:getGlobal()
    if db then db.name_union:delete( {_id=u.name} ) end
    player_t.pre_tlog(nil,"UnionList",u.uid,u.name,u.language,2,
        tostring(u.mc_start_time[1]),u.membercount,u.activity or 0 ) 
    npc_city.clear_npcs_by_uid(u.uid)
    king_city.clear_npcs_by_uid(u.uid)
end


function add_member(u, A,B)
    if u.membercount >= u:get_memberlimit() then
        INFO( "[UNION], add_member, full, uid=%d, pid=%d", u.uid, A.pid )
        return -1
    end

    if u:has_member(A) then return resmng.E_ALREADY_IN_UNION end
    local old = unionmng.get_union(A:get_uid())
    if old then
        if B then Rpc:tips(B,1,resmng.UNION_ADD_MEMBER_1,{}) end
        u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=0})
        return
    end

    A:set_uid(u)
    etypipe.add(A)
    u._members[A.pid] = A
    u.membercount = tabNum(u._members)

    u.pow = (u.pow or 0) + A:get_pow()
    if u.pow > 0 and not u:is_new() then rank_mng.add_data( 5, u.uid, { u.pow } ) end


    local t = A:get_union_info()
    t.uid = u.uid

    u.donate_rank = {} --清除捐献排行
    for _, v in pairs(UNION_CONSTRUCT_TYPE) do
        union_buildlv.get_cons(A,v,1)
    end
    u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.ADD, t)
    u:add_log(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.ADD, {name=t.name})
    --任务
    task_logic_t.process_task(A, TASK_ACTION.JOIN_PLAYER_UNION)
    task_logic_t.process_task(A, TASK_ACTION.OCC_NPC_CITY)
    task_logic_t.process_task(A, TASK_ACTION.UNION_CASTLE_EFFECT)
    --send_chat_invite(u.chat_room, A)

    if 9 < u.membercount and u.build_first1 ~= 1  then
        for _, p in pairs(u._members) do
            p:send_union_build_mail(resmng.MAIL_10074, {}, {})
        end
        u.build_first1 = 1  
    end
    if not next(A._union.history) then
        A:send_system_notice(resmng.MAIL_10082, {}, {})
    end
    union_member_t.add_history(A,{
        uid=A:get_uid(),
        tmJoin = A._union.tmJoin,
        tmLeave = 0,
        rank = A._union.rank,
    })
    --A:tlog_ten2("GuildFlow",A.vip_lv,4,u.uid,0,u.membercount)
    return 0
end

function rm_member(u, A,kicker)
    kicker = kicker or {}
    u:has_member(A) 
    A:recall_all()

    local troop = A:get_my_troop()
    if troop then

        for pid, _ in pairs(  troop.arms or {} ) do
            if pid  ~= A.pid then
                local dest = getPlayer( pid )
                dest:troop_recall( troop._id, true )
            end
        end

        for tid, action in pairs( A.troop_comings or {} ) do
            if action == TroopAction.SupportArm then
                local tr = troop_mng.get_troop( tid )
                if tr and tr:is_go() and tr.dest_troop_id == troop._id then
                    local dest = getPlayer( tr.owner_pid )
                    dest:troop_recall( tid, true )
                end
            end
        end
    end

    local store = A._union and A._union.restore_sum
    if store then
        local total = 0
        local gains = {}
        for mode, num in pairs( store ) do
            if num > 0 then
                store[ mode ] = 0
                table.insert( gains, { "res", mode, num } )
                total = total + num
            end
        end
        if total > 0 then
            local one  
            local l = math.huge
            for k, v in pairs( u.build or {} ) do
                if is_union_restore( v.propid ) and v.state == BUILD_STATE.WAIT then
                    local z = math.pow(math.abs(A.x-v.x),2) + math.pow(math.abs(A.y-v.y),2)
                    if l > z then
                        one = v
                        l = z
                    end
                end
            end
            if one then
                local troop = troop_mng.create_troop(TroopAction.GetRes, A, one)
                troop.curx, troop.cury = get_ety_pos(one)
                troop:back()
                troop:add_goods( gains, VALUE_CHANGE_REASON.REASON_UNION_GET_RESTORE )
            end
        end
    end

    local f
    if not u:is_new() then f = A:union_leader_auto() end --移交军团长

    u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.DELETE, {name=A.name,pid=A.pid,kname=kicker.name, kicker=kicker.pid})
    u:add_log(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.DELETE, {name=A.name,kname=kicker.name})
    A:set_uid()
    etypipe.add(A)
    u._members[A.pid] = nil
    u.membercount = tabNum(u._members)

    u.pow = (u.pow or 0) - A:get_pow()
    if u.pow > 0 and not u:is_new() then rank_mng.add_data( 5, u.uid, { u.pow } ) end

    for _, v in pairs(u.help or {}) do
        local t = timer.get(v.id)
        if t and A.pid == t.param[1] then 
            t.is_help = 1 
            union_help.del(A,v.id) 
        end
    end


    u.donate_rank = {} --清除捐献排行
    if f then 
        unionmng.rm_union(u) 
        --A:tlog_ten2("GuildFlow",A.vip_lv,2,u.uid,0,0)
    end

    u:clear_score_by_pid(A.pid)  --清除军团积分

    if #A._union.history < 4 then
        for _, u in pairs(A:union_hot()) do
            if u.membercount < u:get_memberlimit() then
                local leader = getPlayer(u.leader)
                leader:union_invite(A.pid)
                break;
            end
        end
    end

    --A:tlog_ten2("GuildFlow",A.vip_lv,5,u.uid,0,u.membercount)
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
                INFO("[UNION]uid matching but not in member list, pid:%s, uid:%s", A.pid, self.uid)
                return false
            end
        end
    end
    return true
end

-- chat union room invite
function send_chat_invite(chat_room, B)
    to_tool(0, {url = config.Chat_url or CHAT_URL, type = "chat", cmd = "send_invite", name = chat_room, service="conference."..CHAT_HOST, users = {B.chat_account.."@"..CHAT_HOST} })
end

-- user role in chat room
function set_role(chat_room, jid, role)
    to_tool(0, {url = config.Chat_url or CHAT_URL, type = "chat", cmd = "set_role", name = chat_room, service = "conference."..CHAT_HOST, affiliation=role})
end

function remove_apply(self, pid)
    assert(pid)
    local k = self:get_apply(pid)
    if k then
        self.applys[k]=nil
        local chg = gPendingSave.union_t[self.uid]
        chg.applys = self.applys
        return true
    end
    return false
end

function get_apply(self, pid)
    if not pid then return end
    local v =  self.applys[pid] 
    if v then
        if (v.tm + 60*60*48) > gTime then return pid
        else
            self.applys[pid]=nil
            gPendingSave.union_t[self.uid].applys = self.applys
            return
        end
    end
end

function add_apply(self, B)
    assert(B)
    if self:has_member(B) then return end
    if self:get_apply(B.pid) then return end

    local data = {pid=B.pid, tm=gTime}
    self.applys[data.pid]=data
    gPendingSave.union_t[self.uid].applys = self.applys

    local data = B:get_union_info()
    data.rank = 0

    INFO("[Union] add_apply, pid:%s, uid:%s", B.pid, self.uid)
end

function reject_apply(self, A, B)
    if not self:has_member(A) then return end
    if not is_legal(A, "Invite") then return end
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
        INFO("[Union]: sendInvite, already in union, player:%s", B.pid)
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
        self.invites[pid] = {tm=gTime,pid=pid}
        gPendingSave.union_t[self.uid].invites = self.invites
    else
        self.invites[k].tm = gTime
        gPendingSave.union_t[self.uid].invites = self.invites
    end
end

function get_invite(self, pid)
    local v = self.invites[pid]
    if v then
        if gTime > (v.tm+60*60*24*2)  then
            self:remove_invite( pid)
            return
        else
            return pid, v
        end
    end
end

function notifyall(self, what, mode, data,ply)
    local pids = {}
    for _, p in pairs(self._members) do
        if p ~= ply then
            if p:is_online() then 
                table.insert(pids, p.pid) 
            end
            if what == resmng.UNION_EVENT.WORD then
                if mode == resmng.UNION_MODE.DELETE then 
                    p._union.word = p._union.word or {} 
                    gPendingSave.union_member[p.pid].word = gPendingSave.union_member[p.pid].word  or {} 
                    p._union.word[data[1]]=nil   
                    gPendingSave.union_member[p.pid].word = p._union.word
                else
                    p._union.word = p._union.word or {} 
                    gPendingSave.union_member[p.pid].word = gPendingSave.union_member[p.pid].word  or {} 
                    p._union.word[data[1]]=1   
                    gPendingSave.union_member[p.pid].word[data[1]] = 1 
                end
            end
        end
    end
    if #pids == 0 then return end
    Rpc:union_broadcast(pids, what, mode, data)


    -- local t = UNION_EVENT_LOG
    -- if t[ what ] and t[ what ][ mode ] then
    --     if (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.TITLE ) then
    --         if data.title == "" then return end
    --     end
    --     self:add_log(what, mode, data)
    -- end

    --if (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.ADD )
    --    or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.DELETE )
    --    or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.RANK_UP )
    --    or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.RANK_DOWN )
    --    or (what ==resmng.UNION_EVENT.MEMBER and mode ==resmng.UNION_MODE.TITLE and data.title~="" )
    --    or (what ==resmng.UNION_EVENT.TECH and mode ==resmng.UNION_MODE.ADD )
    --    or (what ==resmng.UNION_EVENT.BUILDLV and mode ==resmng.UNION_MODE.UPDATE )
    --    or (what ==resmng.UNION_EVENT.BUILD_SET and mode ==resmng.UNION_MODE.ADD )
    --    or (what ==resmng.UNION_EVENT.MISSION and mode ==resmng.UNION_MODE.GET )
    --    or (what ==resmng.UNION_EVENT.MISSION and mode ==resmng.UNION_MODE.OK )
    --    or (what ==resmng.UNION_EVENT.TASK and mode ==resmng.UNION_MODE.ADD )
    --    or (what ==resmng.UNION_EVENT.FIGHT and mode ==resmng.UNION_MODE.ADD )
    -- then
    --     self:add_log(what, mode,data)
    --end
    --INFO( "[UNION] notifyall uid=%d what=%s mode=%d ",self.uid,what,mode )
end


--{{{ tech & donate
function init_tech(self, idx)
    assert(self, debug.stack())
    if not self._tech[idx] then
        self._tech[idx] = union_tech_t.create(idx, self.uid)
    end
end

function get_tech(self, idx)
    if not idx then return self._tech end
    self:init_tech(idx)
    return self._tech[idx]
end

function can_donate(self, idx)
    local tech = self:get_tech(idx)
    local conf = false
    if tech then
        conf = resmng.get_conf("prop_union_tech", tech.id + 1)
        if not conf then return false end
    end

    if tech and tech.exp < conf.Exp * conf.Star then
        if self:calc_tech() >= TechValidCond[union_tech_t.get_class(idx)] then
            return true
        end
    end
    return false
end

function remote_can_donate(self, map_id, id, idx)
    local ret = can_donate(self, idx)
    return {ret}
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
    for _, v in pairs(mark) do
        if not self:get_tech(v.id) then return resmng.E_FAIL end
    end
    self.tech_mark = mark
    return resmng.E_OK
end

function get_tech_mark(self)
    return self.tech_mark
end

function sort_donate_rank( l, r )
    if l.donate ~= r.donate then return l.donate > r.donate end
    if l.techexp ~= r.techexp then return l.techexp > r.techexp end
    if l.rank ~= r.rank then return l.rank > r.rank end
    return l.pid > r.pid 
end

function get_donate_rank(u, what)
    if not u.donate_rank[what] then
        local result = {}
        for _, v in pairs(u._members) do
            table.insert(result, {
                pid=v.pid,
                name=v.name,
                photo=v.photo,
                rank = v:get_rank(),
                donate = v:union_data().donate_data[what],
                techexp = v:union_data().techexp_data[what],
            })
        end
        table.sort( result, sort_donate_rank )
        u.donate_rank[what] = result
    end
    return u.donate_rank[what]
end

function donate_summary_day(self)
    for _, A in pairs(self._members) do
        union_member_t.clear_donate_data(A,resmng.DONATE_RANKING_TYPE.DAY)
        union_member_t.clear_donate_data(A,resmng.DONATE_RANKING_TYPE.DAY_B)
    end
    self.donate_rank[resmng.DONATE_RANKING_TYPE.DAY] = nil
    self.donate_rank[resmng.DONATE_RANKING_TYPE.DAY_B] = nil
end

function donate_summary_week(self)
    local t = get_donate_rank(self,resmng.DONATE_RANKING_TYPE.WEEK) or {}
    local one =  resmng.HERO_ALTAR_NO_VALUE
    if t[1] and ( t[1].donate >= UNION_DONATE_LIMIT or player_t.debug_tag) then one =  t[1].name end
    local two =  resmng.HERO_ALTAR_NO_VALUE
    if t[2] and ( t[2].donate >= UNION_DONATE_LIMIT  or player_t.debug_tag) then two =  t[2].name end
    local three =  resmng.HERO_ALTAR_NO_VALUE
    if t[3] and ( t[3].donate >= UNION_DONATE_LIMIT  or player_t.debug_tag) then three =  t[3].name end

    for _, v in pairs(t or {}) do
        local val = nil
        local p = getPlayer(v.pid)
        if p then
            if v.name == one then
                val = resmng.prop_item[UNION_DONATE_WEEK.ONE].Param[1][2] 
            elseif v.name == two then
                val = resmng.prop_item[UNION_DONATE_WEEK.TWO].Param[1][2] 
            elseif v.name == three then
                val = resmng.prop_item[UNION_DONATE_WEEK.THREE].Param[1][2] 
            end
            p:send_system_notice(10024, {}, {one,two,three}, val)
            union_member_t.clear_donate_data(p,resmng.DONATE_RANKING_TYPE.WEEK)
        end
    end
    self.donate_rank[resmng.DONATE_RANKING_TYPE.WEEK] = nil

    if self:is_new() then return end

    t = get_donate_rank(self,resmng.DONATE_RANKING_TYPE.WEEK_B) or {}
    local one =  resmng.HERO_ALTAR_NO_VALUE
    if t[1] and ( t[1].donate >= UNION_DONATE_B_LIMIT  or player_t.debug_tag ) then one =  t[1].name end
    local two =  resmng.HERO_ALTAR_NO_VALUE
    if t[2] and ( t[2].donate >= UNION_DONATE_B_LIMIT  or player_t.debug_tag) then two =  t[2].name end
    local three =  resmng.HERO_ALTAR_NO_VALUE
    if t[3] and ( t[3].donate >= UNION_DONATE_B_LIMIT  or player_t.debug_tag) then three =  t[3].name end
    for _, v in pairs(t or {} ) do
        local val = nil
        local p = getPlayer(v.pid)
        if p then
            if v.name == one then
                val = resmng.prop_item[UNION_DONATE_WEEK.B_ONE].Param[1][2] 
            elseif v.name == two then
                val = resmng.prop_item[UNION_DONATE_WEEK.B_TWO].Param[1][2] 
            elseif v.name == three then
                val = resmng.prop_item[UNION_DONATE_WEEK.B_THREE].Param[1][2] 
            end
            p:send_system_notice(10025, {}, {one,two,three}, val)
            union_member_t.clear_donate_data(p,resmng.DONATE_RANKING_TYPE.WEEK_B)
        end
    end
    self.donate_rank[resmng.DONATE_RANKING_TYPE.WEEK_B] = nil

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
            if conf and tech and tech.lv >= conf.Lv then return true end
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

    local total = #self.log
    while total >= 100 do
        table.remove(self.log, 1)
        total = total - 1
    end

    table.insert(self.log, log)
    dbmng:getOne().union_log:update( {_id=self._id}, { ["$push"]={ log={["$each"]={log}, ["$slice"]=-100 }} }, true )

end

local function log_qfind(t, sn)
    local function qfind(l, r)
        local k = math.floor((l + r) / 2)
        --print(l, k, r, sn, t[k].sn)
        if l > r then return nil
        elseif sn > t[k].sn then return qfind(l, k)
        elseif sn < t[k].sn then return qfind(k + 1, r)
        elseif sn == t[k].sn then return k end
    end
    return qfind(1, #t)
end

function get_log_by_sn(self, sn,mode)
    local result = {}
    if not self.log then return {} end

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
            if mode == "" then
                table.insert(result, log)
            elseif mode == log.mode then
                table.insert(result, log)
            end
        end
        idx = idx - 1
    end
    return result
end

function set_note_in(self,pid,what)
    self.note_in = what
    local p = getPlayer(pid)
end


function in_castle(v,x,y,r)  --在奇迹有效范围内
    if  v.state ~=BUILD_STATE.DESTROY and  v.state ~=BUILD_STATE.CREATE then
        if is_union_miracal(v.propid) then
            local cc = resmng.get_conf("prop_world_unit",v.propid)
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

    if  v.state ~=BUILD_STATE.DESTROY then
        if is_union_miracal(v.propid) then
            local cc = resmng.get_conf("prop_world_unit",v.propid)
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
        if in_castle(v,x,y,r)  then return true end
    end
    return false
end

function can_other_castle(self, x, y,r)  --奇迹不能建造在其他奇迹范围内
    for _, t in pairs(unionmng.get_all() or {}  ) do
        for k, v in pairs(t.build or {} ) do
            if not out_castle(v,x,y,r)  then return true end
        end
    end
    return false
end

function can_build(self, id, x, y)
    local bcc = resmng.get_conf("prop_world_unit",id)
    if not bcc then 
      INFO( "[UNION] 没有军团建筑propid" )
      return false 
    end

    if is_hit_black_land( x, y, bcc.Size ) then 
        print( "hit black" )
        return false 
    end

    if not is_union_miracal(id) then
        if not self:can_castle( x, y,bcc.Size/2) then
            INFO( "[UNION] 不在奇迹范围内" )
            return false
        end
    else
        if self:can_other_castle( x, y,bcc.Size/2) then
            INFO("[UNION]奇迹不能建造在其他奇迹范围内")
            return false
        end

    end


    local b = union_buildlv.get_buildlv(self._id,bcc.BuildMode)
    if not b then INFO("[UNION]建筑等级 错误\n") return false end

    local bb = resmng.get_conf("prop_union_buildlv",b.id)
    if not bb then INFO("[UNION]propid 错误\n") return false end
    --等级
    if bb.Lv < bcc.Lv then INFO("[UNION]等级不够\n") return false end
    --数量
    local num = self:get_ubuild_num(id)
    local sum = self:get_build_count(bcc.BuildMode)
    if sum >= num and (not player_t.debug_tag) then INFO("[UNION]数量达到上限:"..sum..":"..num) return false end

    if is_union_miracal_small( id ) and sum < 1 then INFO("[UNION]先修建大奇迹") return false end

    if is_union_restore(id) then
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
    for k, v in pairs(self.build) do
        local c = resmng.get_conf("prop_world_unit",v.propid)
        if c.BuildMode == mode and v.state ~=BUILD_STATE.DESTROY and v.state ~=BUILD_STATE.CREATE then
            count = count + 1
        end
    end
    return count
end

function get_ubuild_num(self,id)--计算军团建筑上限数量

    local base = get_castle_count(self.membercount)

    if is_union_miracal(id) then
        return base
    else
        local b = resmng.get_conf("prop_world_unit",id)
        local c = resmng.get_conf("prop_union_buildlv",b.BuildMode*1000+1)
        if c then return base*c.Mul end
    end

    return 0
end

function get_build(self, idx )
    if idx then
        if self.build then
            local e = get_ety(self.build[idx].eid)
            if e  then return e end
        end
    else
        return self.build
    end
end

function get_miracal_main(u)
    if not u then return end
    for _, v in pairs( u:get_build() or {} ) do 
        if is_union_miracal_main(v.propid) then return v end
    end
end


--}}}

function union_pow(self)
    local pow = 0
    for _, v in pairs(self._members) do
        pow = pow + v:get_pow()
    end
    if pow > 2100000000 then pow = 2100000000 end
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

function inc_pow(self, pow)
    local pow = self.pow + pow
    if pow < 0 then
        pow = 0
    elseif pow > 2100000000 then
        pow = 2100000000
    end
    self.pow = pow
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
        if v:is_online() then table.insert(pids, pid) end
    end
    player_t.add_chat(pids, resmng.ChatChanelEnum.Union, self.uid, {pid=0}, word, chatid, args)
end

function clear_kw_buff(self)
    self.kw_bufs = nil
end

function add_kw_buf(self, eid)
    local kw_bufs = self.kw_bufs or {}
    kw_bufs[eid] = eid
    self.kw_bufs = kw_bufs
end

function is_mobilize( self )
    for k, v in pairs( self.buf or {} ) do
        if v[1] == UNION_MOBILIZE_EFFECTID and v[3] > gTime then
            return true
        end
    end
end

function get_restore_detail( self )
    local mems = self:get_members()
    local res = {}
    for pid, p in pairs( mems or {} ) do
        local udata = p._union and p._union.restore_sum
        if udata then
            local flag = false
            for mode, num in pairs( udata ) do
                if num > 0 then flag = true break end
            end
            if flag then table.insert( res, { pid=pid, res = udata } ) end
        end
    end
    return res
end

function is_restore_empty( self )
    local mems = self:get_members()
    local res = {}
    for pid, p in pairs( mems or {} ) do
        local udata = p._union and p._union.restore_sum
        if udata then
            for mode, num in pairs( udata ) do
                if num > 0 then return false end
            end
        end
    end
    return true
end

function get_rank_detail( self )
    return rank_mng.rank_function[0]( self.uid )
end

function clear_battle_room(self, room_id)
    self.battle_list = nil
end

function add_score_in_u(self, pid, mode, score)
    self:try_clear_rank()
    local act_rank = self.act_rank or {}
    local rank = act_rank[mode] or {}
    local act_daily_rank = rank[UNION_RANK_MODE.DAILY] or {}
    local act_weekly_rank = rank[UNION_RANK_MODE.WEEKLY] or {}
    local act_permanent_rank = rank[UNION_RANK_MODE.PERMANENT] or {}
    act_daily_rank[pid] = (act_daily_rank[pid] or 0) + score
    act_weekly_rank[pid] = (act_weekly_rank[pid] or 0) + score
    act_permanent_rank[pid] = (act_permanent_rank[pid] or 0) + score
    rank[UNION_RANK_MODE.DAILY] = act_daily_rank
    rank[UNION_RANK_MODE.WEEKLY] = act_weekly_rank
    rank[UNION_RANK_MODE.PERMANENT] = act_permanent_rank
    act_rank[mode] = rank
    self.act_rank = act_rank
    self.last_join_act_tm = gTime
end

function clear_score_by_pid(self, pid)
    local act_rank = self.act_rank or {}

    for k, v in pairs(act_rank or {}) do
        local rank = v
        local act_daily_rank = rank[UNION_RANK_MODE.DAILY] or {}
        local act_weekly_rank = rank[UNION_RANK_MODE.WEEKLY] or {}
        local act_permanent_rank = rank[UNION_RANK_MODE.PERMANENT] or {}
        act_daily_rank[pid] = nil
        act_weekly_rank[pid] = nil
        act_permanent_rank[pid] = nil
        rank[UNION_RANK_MODE.DAILY] = act_daily_rank
        rank[UNION_RANK_MODE.WEEKLY] = act_weekly_rank
        rank[UNION_RANK_MODE.PERMANENT] = act_permanent_rank
        act_rank[k] = v
    end
    self.act_rank = act_rank
end

function get_ply_rank_in_u(self, mode)
    self:try_clear_rank()
    if self.act_rank then
        return self.act_rank[mode]
    end
end

function clear_sigle_rank(self, mode)
    local act_rank = self.act_rank or {}
    for _, v in pairs(act_rank or {}) do
        if v[mode] then
            v[mode] = nil
        end
    end
    self.act_rank = act_rank
end

function try_clear_rank(self)
    if self.last_join_act_tm == 0 then
        return
    end

    if can_date(self.last_join_act_tm, gTime) then
        self:clear_sigle_rank(UNION_RANK_MODE.DAILY)
    end

    if can_weekly(self.last_join_act_tm, gTime) then
        self:clear_sigle_rank(UNION_RANK_MODE.WEEKLY)
    end

end


--迁城用
function is_in_miracal_range(self, x, y, r)  --在奇迹范围内
    for k, v in pairs(self.build or {} ) do
        if v.state ~= BUILD_STATE.DESTROY then
            if is_union_miracal(v.propid) then
                local cc = resmng.get_conf("prop_world_unit",v.propid)

                local offx = math.abs((x + r) - (v.x + cc.Size * 0.5))
                local offy = math.abs((y + r) - (v.y + cc.Size * 0.5))
                if math.max(offx, offy) < (r + cc.Size * 0.5 + cc.Range) then
                    return true
                end
            end
        end
    end
    return false
end

function reset_npc_info_pack(self)
    self.npc_info_pack = nil
end

function remote_union_mission_ok(self, map_id, id, pid, cond, num)
    local player = getPlayer(pid)
    if nil == player then
        WARN("[Cross|Union] can't find player %d when union mission[%s|%d] is ok", pid, cond, num)
        return
    end
    union_mission.ok(player, cond, num)
end

function remote_god_add_exp(self, map_id, id, pid, num)
    local player = getPlayer(pid)
    if nil == player then
        WARN("[Cross|Union] can't find player %d when add god exp %d", pid, num)
        return
    end
    union_god.add_exp(player, num)
end

function is_active( self )
    local func_rank = player_t.get_rank
    local func_tick = player_t.get_last_access
    for _, A in pairs(self._members or {}) do
        if func_rank( A )>= resmng.UNION_RANK_4 then 
            if gTime - func_tick( A ) < 86400 * 2 then
                return true
            end
        end
    end
    return false
end


