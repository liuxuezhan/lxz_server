module("player_t")

function mail_read_by_class( self, class, mode, lv )
    local db = self:getDb()
    if db then
        local qinfo = { to=self.pid, tm_drop = 0, tm_read = 0} 
        if class ~= -1 then qinfo.class = class end
        if mode ~= -1 then qinfo.mode = mode end
        if lv ~= -1 then qinfo.lv = lv end

        db.mail:update( qinfo, { [ "$set" ] = { tm_read = gTime } }, false, true )
        local info = db:runCommand("getLastError")
        self:reply_ok("mail_read_by_class", 0)
    end
end


function mail_drop_by_class( self, class, mode, lv )
    local db = self:getDb()
    if db then
        local qinfo = { to=self.pid, tm_drop = 0, tm_lock = 0} 
        if class ~= -1 then qinfo.class = class end
        if mode ~= -1 then qinfo.mode = mode end
        if lv ~= -1 then qinfo.lv = lv end
        local info = db.mail:find( qinfo )
        local ms = {}
        while info:hasNext() do
            local m = info:next()
            if m then
                if m.its == 0 or m.tm_fetch > 0 then
                    m.tm_drop = gTime
                    gPendingSave.mail[ m._id ].tm_drop = gTime
                    INFO("[mail], drop, pid=%d, id=%s", self.pid, m._id )
                end
            end
        end
        self:reply_ok("mail_drop_by_class", 0)
    end
end

function mail_lock_by_sn(self,sns)
    local db = self:getDb()
    if db then
        if next( sns ) then
            local info = db.mail:find( { to=self.pid, _id={ ["$in"] = sns }, tm_drop = 0, tm_lock = 0 } )
            local ms = {}
            while info:hasNext() do
                local m = info:next()
                if m then
                    m.tm_lock = gTime
                    gPendingSave.mail[ m._id ].tm_lock = gTime
                    self:reply_ok("mail_lock_by_sn", m.idx)
                    --INFO("[mail], lock, pid=%d, id=%s", self.pid, m._id )
                end
            end
        end
    end
end

function mail_unlock_by_sn(self,sns)
    local db = self:getDb()
    if db then
        if next( sns ) then
            local info = db.mail:find( { to=self.pid, _id={ ["$in"] = sns }, tm_drop = 0, tm_lock = { ["$ne"] = 0 } } )
            local ms = {}
            while info:hasNext() do
                local m = info:next()
                if m then
                    m.tm_lock = 0
                    gPendingSave.mail[ m._id ].tm_lock = 0
                    self:reply_ok("mail_unlock_by_sn", m.idx)
                    --INFO("[mail], unlock, pid=%d, id=%s", self.pid, m._id )
                end
            end
        end
    end
end

function mail_drop_by_sn(self,sns)
    local db = self:getDb()
    if db then
        if next( sns ) then
            local info = db.mail:find( { to=self.pid, _id={ ["$in"] = sns }, tm_drop = 0, tm_lock = 0 } )
            local ms = {}
            while info:hasNext() do
                local m = info:next()
                if m and (m.tm_fetch > 0 or m.its == 0) then
                    INFO("[mail], drop, pid=%d, id=%s", self.pid, m._id )
                    m.tm_drop = gTime
                    gPendingSave.mail[ m._id ].tm_drop = gTime
                    self:reply_ok("mail_drop_by_sn", m.idx)
                end
            end
        end
    end
end

function mail_read_by_sn(self, sns)
    local spid = self.pid
    for _, sn in pairs( sns ) do
        local idx, pid = string.match(sn, "(%d+)_(%d+)")
        if tonumber(pid) == spid then
            gPendingSave.mail[ sn ].tm_read = gTime
            self:reply_ok("mail_read_by_sn", idx)
            --INFO("[mail], read, pid=%d, id=%s", self.pid, m._id )
        end
    end
end

function mail_fetch_by_sn(self, sns)
    local db = self:getDb()
    if db then
        local info = db.mail:find( { to=self.pid, _id={ ["$in"] = sns }, tm_drop = 0, tm_fetch = 0 } )
        local msg = {}
        local ids = {}
        while info:hasNext() do
            local m = info:next()
            if m then
                if m.its ~= 0 then
                    INFO("[mail], fetch, pid,%d, id,%s", self.pid, m._id )
                    m.tm_fetch = gTime
                    -- here can not use gPending, for fetch many times in short time
                    --gPendingSave.mail[ m._id ].tm_fetch = gTime
                    self:add_bonus("mutex_award", m.its, VALUE_CHANGE_REASON.REASON_MAIL_AWARD)
                    self:reply_ok("mail_fetch_by_sn", m.idx)
                    table.insert(msg, m._id)
                    table.insert( ids, m._id )
                end
            end
        end

        db.mail:update( { _id={ ["$in"] = ids } }, { [ "$set" ] = { tm_fetch = gTime } }, false, true )
        local info = db:runCommand("getLastError")

        Rpc:mail_fetch_resp(self, msg)
    end
end


function mail_load( self, sn )
    local mail_sys = self.mail_sys or 0
    if mail_sys < _G.gSysMailSn then
        local count = #gSysMail -- the bigger sn, be post at tail
        local news = {}
        for idx = count, 1, -1 do
            local v = gSysMail[ idx ]
            if mail_sys < v.idx then table.insert(news, 1, v)
            else break end
        end

        for _, v in ipairs(news) do
            local m = copyTab(v)
            m.copy = v._id
            self:mail_new(m, true)
        end
        self.mail_sys = _G.gSysMailSn
    end

    local db = self:getDb()
    local info = db.mail:find( { to=self.pid, idx={ ["$gte"] = sn }, tm_drop = 0 } )
    local ms = {}
    local num = 0
    while info:hasNext() do
        local m = info:next()
        if m.tm_drop == 0 then
            table.insert( ms, m )
            num = num + 1
            if num >= 100 then
                Rpc:mail_load(self, ms)
                num = 0
                ms = {}
            end
        end
    end
    if #ms > 0 then Rpc:mail_load( self, ms ) end
    Rpc:mail_load(self, {})
end

function mail_load_by_idx( self, ids )
    local pid = self.pid
    local ms = {}
    local num = 0

    local max_id = -1
    local min_id = math.huge
    local needs = {}
    for _, id in pairs( ids ) do
        if id > max_id then max_id = id end
        if id < min_id then min_id = id end
        needs[ id ] = 1
        num = num + 1
    end
    INFO( "mail_load_by_idx, pid=%d, num=%d", self.pid, num )

    if num == 0 then return end

    num = 0
    local db = self:getDb()
    local info = db.mail:find( {to=pid, idx={["$gte"]=min_id, ["$lte"]=max_id}, tm_drop = 0} )
    while info:hasNext() do
        local m = info:next()
        local idx = m.idx
        if needs[ idx ] then
            table.insert( ms, m )
            needs[ idx ] = nil
            num = num + 1
            if num >= 50 then
                Rpc:mail_load(self, ms)
                num = 0
                ms = {}
            end
        end
    end
    local max_idx = self.mail_max

    local mails = rawget( self, "_mail" )
    for idx, _ in pairs( needs ) do
        if idx <= max_idx then
            local _id = string.format( "%d_%d", idx, pid )
            if mails and mails[ _id ] then
                table.insert( ms, mails[ _id ] )
            else
                local m = { _id=string.format("%d_%d", idx, pid ), idx=idx, tm=-1}
                table.insert( ms, m )
                num = num + 1
                if num >= 50 then
                    Rpc:mail_load(self, ms)
                    num = 0
                    ms = {}
                end
            end
        end
    end

    if #ms > 0 then Rpc:mail_load( self, ms ) end
    Rpc:mail_load(self, {})
end

function mail_compensate( self )
    local mail_sys = self.mail_sys or 0
    if mail_sys < _G.gSysMailSn then
        local count = #gSysMail -- the bigger sn, be post at tail
        local news = {}
        for idx = count, 1, -1 do
            local v = gSysMail[ idx ]
            if mail_sys < v.idx then table.insert(news, 1, v)
            else break end
        end

        for _, v in ipairs(news) do
            local m = copyTab(v)
            m.copy = v._id
            self:mail_new(m, true)
        end
        self.mail_sys = _G.gSysMailSn
    end
end

-- p:mail_new({from=from, name=name, class=class, title="hello", content="world", its={{1001,100}}})
function mail_new(self, v, is_compensate)
    if self.map ~= gMapID then
        self:add_to_do("mail_new", v, is_compenstate)
        return
    end

    v.its = v.its or 0
    if v.its == 0 then

    elseif type(v.its) == "table" then
        if get_table_valid_count(v.its) == 0 then v.its = 0 end
    else
        WARN( "mail_new, its error" )
        dumpTab( v, "mail_new" )
        return
    end

    local sn = self.mail_max + 1
    self.mail_max = sn

    v._id = string.format("%d_%d", sn, self.pid)
    v.idx = sn
    v.from = v.from or 0
    v.to = self.pid
    v.tm_read = 0
    v.tm_fetch = 0
    v.tm_drop = 0
    v.tm_lock = 0
    v.tm = v.tm or gTime
    v.class = v.class or 0
    v.mode = v.mode or 0
    v.lv = v.lv or 0
    
    gPendingInsert.mail[ v._id ] = v

    if not rawget( self, "_mail" ) then rawset( self, "_mail", {} ) end
    self._mail[ v._id ] = v

    if self:is_online() then
        Rpc:mail_notify( self, {v} )
    end

    local got = v.its
    if got ~= 0 then got = 1 end
    local sys = v.from
    if sys == 0 then sys = 1 end

    self:pre_tlog("PlayerMailFlow",got, sys, "null" , "null" , "null" , "null" , v.from, "null", "null"  )
end


function test_mail_all(self, class, title, content, its)
    mail_all({class=class, title=title, content=content, its=its})
end

function mail_send_union(self, title, content)
    local union = self:get_union()
    if union then
        local v = {}
        v.title = title
        v.content = content
        v.alias = union.alias
        v.pname = self.name
        v.photo = self.photo
        local members = union:get_members()
        if members then
            for _, p in pairs( members ) do
                local m = {class=MAIL_CLASS.UNION, mode=MAIL_UNION_MODE.ANNOUNCE, from=self.pid, content=v, its=0, lv = self.pid}
                p:mail_new( m )
            end
        end
    end
end

function is_troop_no_soldier(troop)
    if troop.action == TroopAction.DefultFollow then
        return false
    end
    for pid, arm in pairs(troop.arms or {}) do
        for k, v in pairs(arm.live_soldier or {}) do
            if v > 0 then
                return false
            end
        end
        for k, v in pairs(arm.dead_soldier or {}) do
            if v > 0 then
                return false
            end
        end
    end
    return true
end

function generate_fight_mail(troop_action, ack_troop, def_troop, is_win, catch_hero, rages, total_round)
    --攻击方邮件
    local ack_mail = {}
    ack_mail.tech = fight.get_troop_buf(ack_troop)
    local ack_ply = getPlayer(ack_troop.owner_pid)
    if ack_ply ~= nil then
        local union = unionmng.get_union(ack_ply.uid)
        if union ~= nil then
            ack_mail.union_abbr = union.alias
        end
        ack_mail.owner_name = ack_ply.name
        ack_mail.owner_pid = ack_ply.pid
        ack_mail.x = ack_ply.x
        ack_mail.y = ack_ply.y
        ack_mail.photo = ack_ply.photo
    end

    ack_mail.arms = {}
    for pid, arm in pairs(ack_troop.arms or {}) do
        local unit = {}
        local tmp_ply = getPlayer(pid)
        if tmp_ply ~= nil then
            unit.name = tmp_ply.name
        end
        unit.power = arm.lost or 0

        --hero:{propid, stars, lv, cur_hp, max_hp, catch}
        unit.hero = {}
        for _, uid in pairs(arm.heros or {}) do
            local hero = {}
            local h = heromng.get_hero_by_uniq_id(uid)
            if h ~= nil then
                hero[1] = h.propid
                hero[2] = h.star
                hero[3] = h.lv
                hero[4] = h.hp
                hero[5] = h.max_hp
            else
                hero[1] = 0
            end
            table.insert(unit.hero, hero)
        end

        unit.kill = arm.kill_soldier or {}
        unit.death = arm.dead_soldier or {}
        unit.live = arm.live_soldier or {}
        --unit.hurt = arm.hurt_soldier

        local amend = arm.amend
        if amend then unit.amend = amend
        else unit.amend = { dead = arm.dead_soldier } end

        ack_mail.arms[pid] = unit
    end


    ack_mail.res = {}
    ack_mail.res_flag = 1
    for pid, res in pairs(rages or {}) do
        local unit = {0, 0, 0, 0}
        for k, v in pairs(res) do
            unit[v[2]] = v[3]
        end
        ack_mail.res[pid] = unit
    end


    --防守方邮件
    local def_mail = {}
    local def_obj = get_ety(ack_troop.target_eid)
    def_mail.propid = def_obj.propid
    def_mail.x = def_obj.x   --战斗发生的地点
    def_mail.y = def_obj.y   --战斗发生的地点

    if def_troop == nil or is_troop_no_soldier(def_troop)  == true then
        def_mail.notroop = true
    else
        def_mail.tech = fight.get_troop_buf(def_troop)
        local def_ply = getPlayer(def_troop.owner_pid)
        if def_ply ~= nil then
            local union = unionmng.get_union(def_ply.uid)
            if union ~= nil then
                def_mail.union_abbr = union.alias
            end
            def_mail.owner_name = def_ply.name
            def_mail.owner_pid = def_ply.pid
            def_mail.photo = def_ply.photo
        end

        def_mail.catch_hero = catch_hero

        def_mail.arms = {}
        for pid, arm in pairs(def_troop.arms or {}) do
            local unit = {}
            local tmp_ply = getPlayer(pid)
            if tmp_ply ~= nil then
                unit.name = tmp_ply.name
            end
            unit.power = arm.lost or 0

            --hero:{propid, stars, lv, cur_hp, max_hp, catch}
            unit.hero = {}
            for _, uid in pairs(arm.heros or {}) do
                local hero = {}
                local h = heromng.get_hero_by_uniq_id(uid)
                if h ~= nil then
                    hero[1] = h.propid
                    hero[2] = h.star
                    hero[3] = h.lv
                    hero[4] = h.hp
                    hero[5] = h.max_hp
                else
                    hero[1] = 0
                end
                table.insert(unit.hero, hero)
            end

            unit.kill = arm.kill_soldier or {}
            unit.hurt = arm.hurt_soldier or {}
            unit.death = arm.dead_soldier or {}
            unit.live = arm.live_soldier or {}
            --unit.hurt = arm.hurt_soldier
            --
            --
            local amend = arm.amend
            if amend then unit.amend = amend
            else unit.amend = { dead = arm.dead_soldier } end

            def_mail.arms[pid] = unit
        end
    end


    local ack_mode = nil
    local def_mode = nil
    if is_win then
        ack_mode = MAIL_FIGHT_MODE.ATTACK_SUCCESS
        def_mode = MAIL_FIGHT_MODE.DEFEND_FAIL
    else
        ack_mode = MAIL_FIGHT_MODE.ATTACK_FAIL
        def_mode = MAIL_FIGHT_MODE.DEFEND_SUCCESS
    end

    local content = {ack_mail=ack_mail, def_mail=def_mail, replay_id=ack_troop.replay_id}
    --发送邮件
    if total_round ~= nil and total_round <= 1 and is_win == false then
        for pid, arm in pairs(ack_troop.arms) do
            local tmp_ply = getPlayer(pid)
            if tmp_ply ~= nil then
                tmp_ply:send_fight_fail_mail(resmng.MAIL_10028)
            end
        end
    else
        for pid, arm in pairs(ack_troop.arms) do
            local tmp_ply = getPlayer(pid)
            if tmp_ply ~= nil then
                local tmp = copyTab(content)
                tmp.ack_mail.res_flag = 1
                tmp_ply:mail_new({from=0, name="", class=MAIL_CLASS.FIGHT, mode=ack_mode, title="", content=content, its={}})
            end
        end
    end

    if def_troop ~= nil then
        for pid, arm in pairs(def_troop.arms or {}) do
            local tmp_ply = getPlayer(pid)
            if tmp_ply ~= nil then
                local tmp = copyTab(content)
                tmp.ack_mail.res_flag = 2
                tmp_ply:mail_new({from=0, name="", class=MAIL_CLASS.FIGHT, mode=def_mode, title="", content=content, its={}})
            end
        end
    end
end

-- player.mail_all({ class=class, title="hello", content="world", its={{1001,100}}})
function mail_all(v)
    v._id = _G.gSysMailSn + 1
    v.idx = v._id
    v.to = 0
    v.from = 0
    _G.gSysMailSn = v._id
    table.insert(gSysMail, v)

    gPendingInsert.mail[ v._id ] = v

    for k, ply in pairs(gPlys) do
        if ply:is_online() then
            --ply:mail_new(copyTab(v))
            mail_compensate( ply )
        end
    end
end

function send_system_to_all(mail_id, title_parm, text_parm, award)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
    }
    content.extra = {}
    content.title_parm = title_parm

    local present = nil
    if award == nil then
        if prop_tab.AddBonus ~= nil then
            present = prop_tab.AddBonus[2]
            table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.PRESENT})
            table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.AWARD})
        end
    else
        present = award
        table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.PRESENT})
        table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.AWARD})
    end
    mail_all({from=0, name="", class=MAIL_CLASS.SYSTEM, mode=MAIL_SYSTEM_MODE.NORMAL, title="", content=content, its=present})
    return true
end

function send_system_notice(self, mail_id, title_parm, text_parm, award)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
    }
    content.extra = {}
    content.title_parm = title_parm

    local present = nil
    if award == nil then
        if prop_tab.AddBonus ~= nil then
            present = prop_tab.AddBonus[2]
            table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.PRESENT})
            table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.AWARD})
        end
    else
        present = award
        table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.PRESENT})
        table.insert(content.seq, {type=MAIL_SYSTEM_SEQ.AWARD})
    end
    self:mail_new({from=0, name="", class=MAIL_CLASS.SYSTEM, mode=MAIL_SYSTEM_MODE.NORMAL, title="", content=content, its=present})
    return true
end

function send_system_union_invite(self, mail_id, sender_pid, extra, text_parm)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
        {type=MAIL_SYSTEM_SEQ.RESPONSE},
    }
    content.extra = extra

    local sender = getPlayer(sender_pid)
    if sender ~= nil then
        content.extra.icon = sender.photo
        content.extra.sender_name = sender.name
    end

    self:mail_new({from=0, name="", class=MAIL_CLASS.SYSTEM, mode=MAIL_SYSTEM_MODE.UNION_INVITATION, title="", content=content, its={}})
    return true
end

function send_system_city_move(self, mail_id, sender_pid, extra, text_parm)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
        {type=MAIL_SYSTEM_SEQ.RESPONSE},
    }
    content.extra = extra
    local sender = getPlayer(sender_pid)
    if sender ~= nil then
        content.extra.icon = sender.photo
        content.extra.sender_name = sender.name
    end

    self:mail_new({from=0, name="", class=MAIL_CLASS.SYSTEM, mode=MAIL_SYSTEM_MODE.MOVE_CITY, title="", content=content, its={}})
    return true
end

function send_system_support_res( self, from, res )
    local idx = #res
    local mail_id = resmng.MAIL_SUPPORT_RES_1 + idx - 1
    local param = {}
    for _, v in pairs( res ) do
        local resid = v[2]
        local conf = resmng.get_conf( "prop_resource", resid )
        if conf then
            table.insert( param, conf.Name )
            table.insert( param, v[3] )
        end
    end
    local count = #param / 2
    local mail_id = resmng.MAIL_SUPPORT_RES_1 + count - 1
    table.insert( param, 1, from.name )

    send_system_notice(self, mail_id, {}, param)
end

function get_mail_share(self, mail_id)
    local db = self:getDb()
    local info = db.mail:find({_id=mail_id})
    local msg = {}
    if info:hasNext() then
        msg = info:next()
    end
    Rpc:get_mail_share_resp(self, msg)
end

function send_tribute_mail(self, mail_id, title_parm, text_parm, consume_item, get_item)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.title_parm = title_parm
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
        {type=MAIL_SYSTEM_SEQ.PRESENT_NO_GET},
        {type=MAIL_SYSTEM_SEQ.ITEM, parm=get_item},
        {type=MAIL_SYSTEM_SEQ.CONSUME},
        {type=MAIL_SYSTEM_SEQ.ITEM, parm=consume_item},
    }
    content.extra = {}
    self:mail_new({from=0, name="", class=MAIL_CLASS.SYSTEM, mode=MAIL_SYSTEM_MODE.NORMAL, title="", content=content, its=nil})
    return true
end

function send_union_build_mail(self, mail_id, title_parm, text_parm)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.title_parm = title_parm
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
        {type=MAIL_SYSTEM_SEQ.JUMPTO_UCONSTUCT, parm=self.uid},
    }
    content.extra = {}

    self:mail_new({from=0, name="", class=MAIL_CLASS.SYSTEM, mode=MAIL_SYSTEM_MODE.NORMAL, title="", content=content, its=nil})
    return true
end

function send_fight_fail_mail(self, mail_id, title_parm, text_parm, mail_mode)
    local prop_tab = resmng.get_conf("prop_mail", mail_id)
    if prop_tab == nil then
        return false
    end

    local content = {}
    content.propid = mail_id
    content.title_parm = title_parm
    content.seq = {
        {type=MAIL_SYSTEM_SEQ.NOTICE},
        {type=MAIL_SYSTEM_SEQ.CONTENT, parm=text_parm},
    }
    content.extra = {}

    self:mail_new({from=0, name="", class=MAIL_CLASS.FIGHT, mode=mail_mode or MAIL_FIGHT_MODE.SYS_FAIL, title="", content=content, its=nil})
    return true
end


