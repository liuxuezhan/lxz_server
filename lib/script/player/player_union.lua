module("player_t")

--{{{ create & destory
function union_load(self, what)
    local union = unionmng.get_union(self:get_uid())
    local result = {
        key = what,
        val = {},
    }
    if not union then
        --nil
    elseif what == "info" then
        result.val = union:get_info()
    elseif what == "member" then
        result.val = union:get_member_info()
    elseif what == "relation" then
        result.val = union_relation.list(union)
    elseif what == "ply" then --邀请列表
        local l = {}
        local num = 50  
        local u = unionmng.get_union(self:get_uid())
        if u then
            for k, v in pairs(gPlys or {}) do
                if k~=0 then
                    if (v.uid == 0)and (v.language == u.language) and (not u:get_invite(v.pid)) 
                        and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                        table.insert(l,{pid=v.pid,name=v.name,language=v.language,photo=v.photo, 
                        pow=calc_pow(v.lv,v.builds,v.arms,v.equips,v.techs,v.genius)})
                        if #l > num then break end
                    end
                end
            end
            if #l < num then 
                for k, v in pairs(gPlys or {}) do
                    if k~=0 then
                        if (v.uid==0)and(v.language ~= u.language) and (not u:get_invite(v.pid)) 
                            and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                            table.insert(l,{pid=v.pid,name=v.name,language=v.language,photo=v.photo, 
                            pow=calc_pow(v.lv,v.builds,v.arms,v.equips,v.techs,v.genius)})
                            if #l > num then break end
                        end
                    end
                end
            end
        end
        result.val = l 
    elseif what == "apply" then
        local info = {}
        if union_t.is_legal(self, "Invite") then
            for k, v in pairs(union.applys) do
                if gTime > v.tm + 60*60*24*2 then
                    union:remove_apply( v.pid)
                else
                    local A  = getPlayer(v.pid)
                    local data = A:get_union_info()
                    data.rank = 0
                    table.insert(info, data)
                end
            end
        end
        result.val = info
    elseif what == "mass" then
        local info = {}
        for idx, _ in pairs(union.mass or {}) do
            table.insert(info, union:get_mass_simple_info(idx))
        end
        result.val = info
    elseif what == "tech" then
        local l = {}
        for _, v in pairs(union._tech or {}) do
            table.insert(l,v)
        end
        result.val = {info=l, mark=union.tech_mark}
    elseif what == "donate" then
        result.val = {donate=self._union.donate,tmOver=self._union.tmDonate, flag=union_member_t.get_donate_flag(self)}
    elseif what == "mars" then --膜拜
        result.val = {mars=union.god,log = self._union.god_log,}
    elseif what == "" then
        result.val = {donate=self._union.donate,tmOver=self._union.tmDonate, flag=union_member_t.get_donate_flag(self)}
    elseif what == "mall" then
        result.val.mall = union_mall.get(self.uid)
        result.val.gift = union_item.show(self)
    elseif what == "aid" then
        for _, At in ipairs(self.aid) do
            table.insert(result.val, At._pro)
        end
    elseif what == "fight" then
        room.load_fight(result,self.pid)
    elseif what == "build" then
        result.val= {}
        result.val.build =  get_build_list(self)
        result.val = union_buildlv.get(self)
    elseif what == "word" then
        result.val = union_word.list(self.pid,union)
        --Rpc:tips(self, resmng.BLACKMARCKET_TEXT_NEED_TIPS,{})
    end

    result.val = result.val or {}
    Rpc:union_load(self, result)
end

function union_relation_set(self,uid,type)
    union_relation.set(self,uid,type)
end

function get_build_list(self)
    local l = {}
    local union = unionmng.get_union(self:get_uid())
    if union then
        for _, v in pairs(union.build) do
            local t = copyTab(v)
            local c = resmng.get_conf("prop_world_unit",v.propid)
            if c.Mode == UNION_CONSTRUCT_TYPE.RESTORE then
                if union_build_t.get_res_count(union) > 0 then
                    t.go_state=1
                else
                    t.go_state=0
                end
            else
                if v.my_troop_id then
                    t.go_state=1
                else
                    t.go_state=0
                end
            end
        end
    end
    return l
end

function union_create(self, name, alias, language, mars)
    if not union_t.is_legal(self, "Create") then
        ack(self, "union_create", resmng.E_DISALLOWED) return
    end

    if not self:condCheck(CREATEUNION.condition) then
        ack(self, "union_create", resmng.E_CONDITION_FAIL) return
    end

    if not self:condCheck(CREATEUNION.consume) then
        ack(self, "union_create", resmng.E_CONSUME_FAIL) return
    end

    for _, v in pairs(unionmng.get_all()) do
        if v.name == name then
            ack(self, "union_create", resmng.E_DUP_NAME) return
        end
        if v.alias == alias then
            ack(self, "union_create", resmng.E_DUP_ALIAS) return
        end
    end

    self:consume(CREATEUNION.consume, 1, VALUE_CHANGE_REASON.UNION_CREATE)

    local union = union_t.create(self, name, alias, language, mars)

    -- register union chat room
    create_chat_room(union)

    Rpc:union_on_create(self, union:get_info())
    --任务
    task_logic_t.process_task(self, TASK_ACTION.JOIN_PLAYER_UNION)

    self.uname = alias
    etypipe.add(self)
end
-- 创建聊天room
function create_chat_room(union)
    to_tool(0, {type = "chat", cmd = "create_room", name = tostring(union.pid), server ="conference."..CHAT_HOST, host = CHAT_HOST })
end

function union_destory(self)
    if #self.busy_troop_ids > 0 then
        ack(self, "union_destory", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "Destory") then
        ack(self, "union_destory", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_destory", resmng.E_NO_UNION) return
    end

    unionmng.rm_union(u)
end
--}}}

--{{{ basic info
function union_set_info(self, info)
    local u = self:union()
    if not u then return end

    --TODO: 敏感词检查，长度检查，唯一性检查
    if union_t.is_legal(self, "ChgName") and info.name then
        u.name = info.name
    end
    if union_t.is_legal(self, "ChgAlias") and info.alias then
        u.alias = info.alias
    end
    if union_t.is_legal(self, "ChgFlag") and info.flag then
        --TODO: 扣钱
        u.flag = info.flag
    end

    if union_t.is_legal(self, "ChgRankAlias") and info.rank_alias then
        for i =1,6 do
            u.rank_alias[i] = tostring( info.rank_alias[i] or "" )
        end
        u.rank_alias = u.rank_alias
    end

    if union_t.is_legal(self, "ChgFlag") and info.language then
        u.language = info.language
    end

    ack(self, "union_set_info", resmng.E_OK)
end
--}}}

--{{{ member
function union_rm_member(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_rm_member", resmng.E_NO_PLAYER) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_rm_member", resmng.E_NO_UNION) return
    end

    local ret = union:kick(self, B)
    if ret ~= resmng.E_OK then ack(self, "union_rm_member", ret) end
end

function union_add_member(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_add_member", resmng.E_NO_PLAYER) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_add_member", resmng.E_NO_UNION) return
    end

    local ret = union:accept_apply(self, B)
    if ret ~= resmng.E_OK then
        ack(self, "union_add_member", ret)
    end
end

function union_apply(self, uid)
    if #self.busy_troop_ids > 0 then
        ack(self, "union_apply", resmng.E_DISALLOWED) return
    end

    local old_union = unionmng.get_union(self:get_uid())
    if old_union and not union_t.is_legal(self, "Join") then
       ack(self, "union_apply", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(uid)
    if not u then
        ack(self, "union_apply", resmng.E_NO_UNION) return
    end

    if not self:union_enlist_check(uid) then
        ack(self, "union_apply", resmng.E_NO_UNION) return
    end

    if u.enlist.check == 0  then
        u:add_member(self)
    else
        u:add_apply(self)
        if u:get_apply(self.pid) then
            Rpc:union_reply(self, u.uid, resmng.UNION_STATE.APPLYING)
        elseif u:has_member(self) then
            Rpc:union_reply(self, u.uid, resmng.UNION_STATE.IN_UNION)
        end
    end

end

function union_quit(self)
    for _, tid in pairs(self.busy_troop_ids) do
        self:troop_recall(tid)
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then return end
    local ret = u:quit(self)
    ack(self, "union_quit", ret)

    if ret == resmng.E_OK then
        self.uname = ""
        etypipe.add(self)
    end
end

function union_reject(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_reject", resmng.E_NO_PLAYER) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_reject", resmng.E_NO_UNION) return
    end

    local ret = union:reject_apply(self, B)
    if ret == resmng.E_OK then
        Rpc:union_reply(B, self.uid, resmng.UNION_STATE.NONE)
    end
    ack(self, "union_reject", ret)
end

function union_enlist_set(self, check,text,lv,pow)
    local u = unionmng.get_union(self:get_uid())
    u.enlist = {check = check ,text=text,lv=lv, pow=pow}
end

function union_enlist_check(self, uid)
    local u = unionmng.get_union(uid)
    local b = self:get_build(1)
    local c = resmng.get_conf("prop_build",b.propid)
    if c.Lv < u.enlist.lv then
        return false
    end

    local p = calc_pow(self.lv,self.builds,self.arms,self.equips,self.techs,self.genius)
    if p < u.enlist.pow then
        return false
    end

    return true
end

function union_info(self,uid)
    local u = unionmng.get_union(uid)
    if u then
        local l = {}
        l.enlist = u.enlist
        Rpc:union_info(self, l)
    end
end

function union_list(self,name)

    local data = {name = name,list={}}
    if name ~= "" then
        for _, u in pairs(unionmng.get_all() or {} ) do
            if string.find(u.name,name) or string.find(u.alias,name)then
                info = u:get_info()
                info.state = resmng.UNION_STATE.NONE
                if info.uid == self:get_uid() then
                    info.state = resmng.UNION_STATE.IN_UNION
                elseif u:get_apply(self.pid) then
                    info.state = resmng.UNION_STATE.APPLYING
                end
                table.insert(data.list,info)
            end
        end
        Rpc:union_list(self, data)
        return
    end

    local pow1 = 0
    local uid1 =0
    for _, u in pairs(unionmng.get_all() or {} ) do --第一军团
        local info = u:get_info()
        if not info.new_union_sn then
            if self.languge == u.language and  info.pow > pow1 then
                  pow1=info.pow
                  uid1 = info.uid
            end
        end
    end

    local len = 0
    local uid2 = 0
    for _, u in pairs(unionmng.get_all() or {} ) do --第二军团
        local info = u:get_info()
        if (not info.new_union_sn) and ( u.uid ~= uid1  ) then
            local p = getPlayer(u.leader)
            local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
            if self.languge == u.language and  (l < len or len == 0) then
                  len =l
                  uid2 = info.uid
            end
        end
    end

    local pow3 = 0
    local uid3 = 0
    for _, u in pairs(unionmng.get_all() or {} ) do--第三军团
        local info = u:get_info()
        if (not info.new_union_sn) and u.uid ~= ( uid1 and uid2 )then
            if info.pow > pow3 then
                pow3 = info.pow
                uid3 = info.uid
            end
        end
    end

    local union = unionmng.get_union(uid1)
    if union then
        local info  = union:get_info()
        local p = getPlayer(union.leader)
        local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
        if l < 10000 then
            info.range = UNION_RANGE.NEAR
        elseif l < 62500 then
            info.range = UNION_RANGE.NORMAL
        else
            info.range = UNION_RANGE.FAR
        end

        info.state = resmng.UNION_STATE.NONE
        if info.uid == self:get_uid() then
            info.state = resmng.UNION_STATE.IN_UNION
        elseif union:get_apply(self.pid) then
            info.state = resmng.UNION_STATE.APPLYING
        end
        table.insert(data.list,info)
    end

    union = unionmng.get_union(uid2)
    if union then
        local info  = union:get_info()
        local p = getPlayer(union.leader)
        local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
        if l < 10000 then
            info.range = UNION_RANGE.NEAR
        elseif l < 62500 then
            info.range = UNION_RANGE.NORMAL
        else
            info.range = UNION_RANGE.FAR
        end
        info.state = resmng.UNION_STATE.NONE
        if info.uid == self:get_uid() then
            info.state = resmng.UNION_STATE.IN_UNION
        elseif union:get_apply(self.pid) then
            info.state = resmng.UNION_STATE.APPLYING
        end
        table.insert(data.list,info)
    end

    union = unionmng.get_union(uid3)
    if union then
        local info  = union:get_info()
        local p = getPlayer(union.leader)
        local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
        if l < 10000 then
            info.range = UNION_RANGE.NEAR
        elseif l < 62500 then
            info.range = UNION_RANGE.NORMAL
        else
            info.range = UNION_RANGE.FAR
        end
        info.state = resmng.UNION_STATE.NONE
        if info.uid == self:get_uid() then
            info.state = resmng.UNION_STATE.IN_UNION
        elseif union:get_apply(self.pid) then
            info.state = resmng.UNION_STATE.APPLYING
        end
        table.insert(data.list,info)
    end

    for _, u in pairs(unionmng.get_all() or {} ) do--同语言军团
        local info = u:get_info()
        if (not info.new_union_sn) and u.uid ~= (uid1 and uid2 and uid3 )then
            local p = getPlayer(u.leader)
            local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
            if l < 10000 then
                info.range = UNION_RANGE.NEAR
            elseif l < 62500 then
                info.range = UNION_RANGE.NORMAL
            else
                info.range = UNION_RANGE.FAR
            end
            info.state = resmng.UNION_STATE.NONE
            if info.uid == self:get_uid() then
                info.state = resmng.UNION_STATE.IN_UNION
            elseif u:get_apply(self.pid) then
                info.state = resmng.UNION_STATE.APPLYING
            end

            if self.languge == u.language then
                if #data.list < 101 then
                    table.insert(data.list,info)
                else
                    break
                end
            end
        end
    end

    for _, u in pairs(unionmng.get_all() or {} ) do--不同语言军团
        local info = u:get_info()
        if (not info.new_union_sn) and u.uid ~= (uid1 and uid2 and uid3 )then
            local p = getPlayer(u.leader)
            local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
            if l < 10000 then
                info.range = UNION_RANGE.NEAR
            elseif l < 62500 then
                info.range = UNION_RANGE.NORMAL
            else
                info.range = UNION_RANGE.FAR
            end
            info.state = resmng.UNION_STATE.NONE
            if info.uid == self:get_uid() then
                info.state = resmng.UNION_STATE.IN_UNION
            elseif u:get_apply(self.pid) then
                info.state = resmng.UNION_STATE.APPLYING
            end

            if self.languge ~= u.language then
                if #data.list < 101 then
                    table.insert(data.list,info)
                else
                    break
                end
            end
        end
    end

    Rpc:union_list(self, data)
end

function union_invite(self, pid)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_invite", resmng.E_NO_PLAYER) return
    end
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_invite", resmng.E_NO_UNION) return
    end

    local ret = union:send_invite(self, B)
    ack(self, "union_invite", ret)
    local mail = {class = MAIL_CLASS.REPORT, mode = MAIL_REPORT_MODE.UNION_INVITE, content = self:get_uid()}
    B:mail_new(mail)
end

function union_help_add(self, type,idx)
    if type == "build" then
        local build = self:get_build(idx)
        union_help.add(self,build.tmSn)
    elseif type == "equip" then
        local b = self:get_build_extra(BUILD_CLASS.FUNCTION, BUILD_FUNCTION_MODE.FORGE)
        union_help.add(self,b.tmSn)
    elseif type == "cure_hero" then
        local hero = self:get_hero(hero_idx)
        union_help.add(self,hero.tmSn)
    elseif type == "cure_arm" then
        union_help.add(self,self.tm_cure)
    end
end

function union_accept_invite(self, uid)
    if #self.busy_troop_ids > 0 then
        ack(self, "union_accept_invite", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(uid)
    if not union then
        ack(self, "union_accept_invite", resmng.E_NO_UNION) return
    end
    local ret = union:accept_invite(self)
    if ret ~= E_OK then
        ack(self, "union_accept_invite", ret) return
    end

    union:broadcast("union_add_member", self:get_union_info())
end

function union_member_rank(self, pid, r)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_member_rank", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_member_rank", resmng.E_NO_UNION) return
    end
    local ret = u:set_member_rank(self, B, r)
    ack(self, "union_member_rank", ret)
end

function union_member_title(self, pid, t)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_member_title", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_member_title", resmng.E_NO_UNION) return
    end

    if not u:has_member(self, B) then return resmng.E_FAIL end
    if self:get_rank() >= resmng.UNION_RANK_4 then
        B._union.title = t
        gPendingSave.union_member[B.pid] = B._union
        u:notifyall("member", resmng.OPERATOR.UPDATE, B:get_union_info())
        return resmng.E_OK
    else
        return resmng.E_FAIL
    end
    ack(self, "union_member_rank", ret)
end

function union_leader_auto(self )--自动移交军团长,返回是否删除军团

    if self:get_rank()~= resmng.UNION_RANK_5  then
        return false
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_leader_update", resmng.E_NO_UNION) return
    end

    local pid = 0
    local rank = 0
    for id, v in pairs(u._members) do
        local B = getPlayer(id)
        if B:get_rank() > rank and id ~= self.pid then
            pid = id
            rank = B:get_rank()
        end
    end

    if pid == 0  then
        return true
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_leader_update", resmng.E_NO_PLAYER) return false
    end

    u.leader = pid
    local ret = u:set_member_rank(self, B,resmng.UNION_RANK_5)
    ack(self, "union_lead_update", ret)
    local ret = u:set_member_rank(B, self,resmng.UNION_RANK_4)
    ack(self, "union_lead_update", ret)
    return false
end

function union_leader_update(self, pid)--手工移交军团长

    if self:get_rank()~= resmng.UNION_RANK_5  then
        return false
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_leader_update", resmng.E_NO_UNION) return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_leader_update", resmng.E_NO_PLAYER) return
    end
    if B:get_rank()~= resmng.UNION_RANK_4 or not u:has_member(B) then return false  end

    u.leader = pid
    local ret = u:set_member_rank(self, B,resmng.UNION_RANK_5)
    ack(self, "union_lead_update", ret)
    local ret = u:set_member_rank(B, self,resmng.UNION_RANK_4)
    ack(self, "union_lead_update", ret)
end

function union_member_mark(self, pid, mark)
    local B = getPlayer(pid)
    if not B then
        ack(self, "union_member_mark", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_member_mark", resmng.E_NO_UNION) return
    end

    local ret = u:set_member_mark(self, B, mark)
    ack(self, "union_member_mark", ret)
end
--}}}

--{{{ mass


--}}}

--{{{ aid
function add_aid(self, At)
    table.insert(self.aid, At)

    --Rpc:union_state_aid(self, {At._pro})
end

function rm_aid(self, pid)
    for i = #self.aid, 1, -1 do
        local At = self.aid[i]
        if At.pid == pid then
            local p = getPlayer(pid)
            p:troop_back(At)
            --Rpc:union_state_aid(self, {At._pro})
            table.remove(self.aid, i)
            return
        end
    end
    ack(self, "rm_aid", resmng.E_NO_TROOP)
end

function get_aid(self, pid)
    for _, At in pairs(self.aid) do
        if At.pid == pid then
            return At
        end
    end
    return nil
end

function union_aid_count(self, pid)
    local data = { pid = pid, }
    local A = getPlayer(pid)
    if A then
        data.max = A:get_max_aid()
        data.cur = A:get_aid_count()
    end
    Rpc:union_aid_count(self, data)
end

function get_aid_count(self)
    local count = 0
    for _, At in pairs(self.aid) do
        count = count + troop_t.sum(At)
    end
    return count
end

function get_max_aid(self)
    --TODO: get right num
    return 5000
    --return self:get_val("MaxAid")
end


--}}}
function union_troop_buf(self)

    if not self:doUpdateRes(resmng.DEF_RES_GOLD, -20000, VALUE_CHANGE_REASON.UNION_TASK) then
        return
    end
    local buf = {Atk_R=2000,Def_R=2000,SpeedMarch_R=500,}
    local u = unionmng.get_union(self.uid)
    for _,v  in pairs(u._members ) do
        local p = getPlayer(v.pid)
        p:ef_add(buf)
    end
    u.tm_buf_over = gTime + 8*60*60
    timer.new("union_troop_buf", 8*60*60 , self.uid,buf )
end

--{{{ tech & donate
function union_tech_info(self, idx)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_info", resmng.E_NO_UNION) return
    end
    local tech = union:get_tech(idx)
    local donate = union_member_t.get_donate_cache(self,idx)
    Rpc:union_tech_info(self, {
        idx = tech.idx,
        id = tech.id,
        exp = tech.exp,
        tmOver = tech.tmOver,
        tmStart = tech.tmStart,
        donate = donate,
    })
end

function union_tech_mark(self, info)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_mark", resmng.E_NO_UNION) return
    end
    local ret = union:set_tech_mark(info)
    ack(self, "union_tech_mark", ret)
end

function union_mall_add(self,propid,num)

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_mall_add", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "AddItem") then
        ack(self, "AddItem no rank", resmng.E_DISALLOWED) return
    end

    local c = resmng.get_conf("prop_union_mall",propid)
    if not c then
        ack(self, " no item", resmng.E_DISALLOWED) return
    end

    local cc = resmng.get_conf("prop_union_tech",c.ConditionLv[2] )
    if u._tech[1005] then
        local cur = resmng.get_conf("prop_union_tech",u._tech[1005].id)
        if cur.Lv < cc.Lv then
            ack(self, " no tech", resmng.E_DISALLOWED) return
        end
    else
        if 0 < cc.Lv then
            ack(self, " no tech", resmng.E_DISALLOWED) return
        end
    end

    if c.Donate*num > u.donate then
        ack(self, " no donate", resmng.E_DISALLOWED) return
    end

    u.donate = u.donate - c.Val*num

    union_mall.add(self,propid,num)
end

function union_mall_mark(self,propid,flag)
    local c = resmng.get_conf("prop_union_mall",propid)
    if not c then
        ack(self, " no item", resmng.E_DISALLOWED) return
    end
    union_mall.mark(self,propid,flag)
end

function union_mall_log(self,type)
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_mall_log", resmng.E_NO_UNION) return
    end

    local d = union_mall.get_log(u,type)
    Rpc:union_mall_log(self, d)
end

function union_mall_buy(self,propid,num)
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_mall_add", resmng.E_NO_UNION) return
    end

    local c = resmng.prop_union_mall[propid]
    local d = self:union_data()
    if c.Val*num > d.donate then
        ack(self, " no donate", resmng.E_DISALLOWED) return
    end

    d.donate= d.donate-c.Val*num
    local ret = union_mall.buy(self,propid,num)
    Rpc:union_donate_info(self, ret)
end

function union_donate_clear(self)
    union_member_t.clear_tmdonate(self)
    Rpc:union_donate_info(self, {tmOver=self._union.tmDonate,flag=union_member_t.get_donate_flag(self)})
end

function union_donate(self, idx, type)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_donate", resmng.E_NO_UNION) return
    end
    local tech = union:get_tech(idx)
    if not tech then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    local c = resmng.get_conf("prop_union_tech",tech.id+1)
    if not c then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if not resmng.prop_union_tech[tech.id + 1] then
        ack(self, "union_donate", resmng.E_NO_UNION) return
    end

    local conf = resmng.get_conf("prop_union_donate",union_tech_t.get_class(tech.idx))
    if not conf then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if union_member_t.get_donate_flag(self) == 1 then
        ack(self, "union_donate", resmng.E_TIMEOUT) return
    end

    local donate = union_member_t.get_donate_cache(self,idx)
    if donate[type] == 0 then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if not union:can_donate(idx) then
        ack(self, "union_donate", resmng.E_DISALLOWED) return
    end

    local cost = nil
    local reward = nil
    if type == resmng.TECH_DONATE_TYPE.PRIMARY then
        cost = conf.Primary[donate[type]]
        reward = conf.Pincome
    elseif type == resmng.TECH_DONATE_TYPE.MEDIUM then
        if donate[type] == 1 then
            cost = conf.Primary[donate[resmng.TECH_DONATE_TYPE.PRIMARY]]
        elseif donate[type] == 2 then
            cost = conf.Medium
        end
        reward = conf.Mincome
    elseif type == resmng.TECH_DONATE_TYPE.SENIOR then
        if donate[type] == 1 then
            cost = conf.Primary[donate[resmng.TECH_DONATE_TYPE.PRIMARY]]
        elseif donate[type] == 2 then
            cost = conf.Senior
        end
        reward = conf.Sincome
    end
    if not cost or not reward then
        ack(self, "union_donate", resmng.E_FAIL) return
    end

    if cost[1] ~=resmng.DEF_RES_GOLD then
        if not self:do_dec_res(cost[1], cost[2], VALUE_CHANGE_REASON.UNION_DONATE) then
            return 
        end
    else
        if not self:doUpdateRes(cost[1], -cost[2], VALUE_CHANGE_REASON.UNION_DONATE) then
            return
        end
    end

    union_member_t.add_donate(self,reward[1])
    union:add_donate(reward[2],self)
    union_member_t.add_techexp(self,reward[3])

    local mode = math.floor(tech.exp/c.Exp)
    union_tech_t.add_exp(tech,reward[3])

    union.donate_rank = {}
    union_member_t.add_donate_cooldown(self,conf.TmAdd)
    
    if mode ~= math.floor(tech.exp/c.Exp) then
        union_member_t.random_donate_cons(self,idx, true,type)
    else
        union_member_t.random_donate_cons(self,idx, false,type)
    end

    self:union_tech_info(idx)
    Rpc:union_donate_info(self, {tmOver=self._union.tmDonate,flag=union_member_t.get_donate_flag(self)})
    task_logic_t.process_task(self, TASK_ACTION.UNION_TECH_DONATE, 1)
    ack(self, "union_donate", resmng.E_OK)
end

function union_tech_upgrade(self, idx)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "TechUp") then
        ack(self, "union_tech_upgrade", resmng.E_DISALLOWED) return
    end

    local ret = union:upgrade_tech(idx)
    ack(self, "union_tech_upgrade", ret)
end

function union_donate_rank(self, what)
    local u = unionmng.get_union(self:get_uid())
    if not u then return end
    local result = { what = what, val = {} }
    local rank = u:get_donate_rank(what)
    result.val = rank
    Rpc:union_donate_rank(self, result)
end

--}}}

--{{{ log
function union_log(self, sn, mode)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    local result = {
        mode = mode,
        sn = sn,
        val = {},
    }
    if mode and mode ~= 0 then
        result.val = union:get_log_by_mode(mode, sn)
    else
        result.val = union:get_log_by_sn(sn)
    end
    Rpc:union_log(self, result)
end
--}}}

function union_set_note_in(self, what)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "SetNoteIn") then
        ack(self, "set_note_in no rank", resmng.E_DISALLOWED) return
    end
    union:set_note_in(self.pid,what)
end

function union_task_get (self )--发布悬赏任务
    local l = union_task.get(self:get_uid())
    Rpc:union_task_get(self,l)
end

function union_mission_log (self,type,id )--获取定时任务日志
    local list =union_mission.get_log(self:get_uid(),type,id)
    Rpc:union_mission_log(self,list)
end

function union_mission_get (self )--获取定时任务
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_mission_get", resmng.E_NO_UNION) return
    end

    local inf = union_mission.get(self.pid,self:get_uid())
    Rpc:union_mission_get(self,inf)
end

function union_mission_update (self )--刷新定时任务
    union_mission.update(self.uid,self)
end

function union_mission_chat (self )
    if not union_t.is_legal(self, "Mission") then
        return
    end
    union_mission.update_chat(self)
end

function union_mission_set (self )--领取定时任务
    if not union_t.is_legal(self, "Mission") then
        return
    end

    union_mission.set(self.uid)
end
function union_word_add (self,...)
    union_word.add(self.pid,...)
end
function union_word_update (self,... )
    union_word.update(self.pid,...)
end
function union_word_del (self,... )
    union_word.del(...)
end

function union_task_add (self, type, eid, hero,task_num, mode, res,res_num )--发布悬赏任务
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_task_add", resmng.E_NO_UNION) return
    end

    local dp = get_ety(eid)
    if not dp then
        ack(self, "union_task_add", resmng.E_NO_UNION) return
    end
    union_task.add(self,type,eid,hero,task_num,mode,res,res_num)
end
--{{{ build

function union_buildlv_donate(self, mode)

    if not union_buildlv.add_buildlv_donate(self,mode) then
        ack(self, "union_build_donate", resmng.E_FAIL) return
    else
        Rpc:union_buildlv_donate(self, union_buildlv.get_buildlv(self:get_uid(),mode))
    end
end

function union_build_setup(self, idx,propid, x, y)
    local u = self:union()
    if not u then
        ack(self, "union_build_setup no union", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "BuildPlace") then
    --    ack(self, "union_build_setup no rank", resmng.E_DISALLOWED) return
    end

    union_build_t.create(self.uid, idx, propid, x, y)
end

function union_build_remove(self, idx)
    local u = self:union()
    if not u then return end

    local bcc = resmng.prop_world_unit[u.build[idx].propid]
    if not bcc then return false end

    local ret = union_build_t.remove_build(u,idx)

--拆除奇迹相关建筑
    if bcc.Mode == resmng.CLASS_UNION_BUILD_CASTLE or resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        for k, v in pairs(u.build) do
            local cc = resmng.prop_world_unit[v.propid]
            if not u:can_castle(bcc) then
                u:remove_build(k)
            end
        end
    end
end

function union_build_upgrade(self, idx)
    local u = self:union()
    if not u then return end

    local ret = u:upgrade_build(self, idx)
    if ret == resmng.E_OK then
        union_mission.ok(self,"build_upgrade",1)
    end
end


--}}}
--}}}



--detail
--[[
msg_send = {
    room_id=""
    tmStart=0
    tmOver=0
    is_mass=0
    dest_id=0
    is_march=0

    ack = {
        troop_id = 0
        uid = 0
        name = ""
        alias = ""
        x = 0
        y = 0
        players = {
            [1] = {
                pid=1
                name=""
                photo=0
                heros={1002,1003,0,1004}
                heros_lv={1,2,0,1}
                soldier = {
                    {id=1002,num=100}
                    {id=2001,num=100}
                }
                tmStart=0
                tmOver=0
                total_soldier=0
            }
            [2] = {
                pid=2
                name=""
                photo=0
                heros={1002,1003,0,1004}
                heros_lv={1,2,0,1}
                soldier = {
                    {id=1002,num=100}
                    {id=2001,num=100}
                }
                tmStart=0
                tmOver=0
                total_soldier=0
            }
        }
    }

    defense = {}--同上ack
}
--]]

function get_battle_room_unit(self, troop_id, uid)
    local troop = troop_mng.get_troop(troop_id)
    if troop == nil then
        return nil
    end

    local unit = {}
    unit.troop_id = troop_id
    unit.uid = uid
    unit.players = {}
    local union = unionmng.get_union(uid)
    if union ~= nil then
        unit.name = union.name
        unit.alias = union.alias
    end

    local single = {}
    local dest = get_ety(troop.owner_eid)
    if is_ply(dest) then
        single.name = dest.name
    elseif is_monster(dest) then
        single.monster = dest.propid
    end

    table.insert(unit.players, single)
    return unit
end

function do_battle_room_title(room)
    if room.title then return room.title end

    local troop = troop_mng.get_troop(room._id)
    if not troop then return nil end

    local info = { {}, {} }
    local A = get_ety(troop.owner_eid)
    local D = get_ety(troop.target_eid)

    for k, v in ipairs({A, D}) do
        local node = info[ k ]
        if k == 1 then node.troop_id = room._id
        else node.troop_id = v.my_troop_id or 0 end

        node.uid = v.uid
        node.players = {}

        local union = unionmng.get_union(v.uid)
        if union then
            node.name = union.name
            node.alias = union.alias
        else
            node.name = "uname"
            node.alias = "ualias"
        end

        node.players = {}
        if is_ply(v) then table.insert(node.players, { name = v.name })
        else table.insert(node.players, { monster = v.propid }) end
    end
    room.title = info
    return info
end


function union_battle_room_list(self)
    local union = unionmng.get_union(self.uid)
    if union == nil then return end

    local msg_send = {}
    local dels = {}
    for k, v in ipairs(union.battle_room_ids or {}) do
        local room = union_hall_t.get_battle_room(v)
        if room ~= nil then
            local info = do_battle_room_title(room)
            if info then
                local unit = {}
                unit.ack = info[1]
                unit.defense = info[2]
                unit.is_mass = room.is_mass
                unit.room_id = room._id
                table.insert(msg_send, unit)
            end

            --local ack_troop = troop_mng.get_troop(room.ack_troop_id)
            --if ack_troop then
            --    local ack_unit = self:get_battle_room_unit(room.ack_troop_id, room.ack_uid)
            --    local defense_unit = self:get_battle_room_unit(room.defense_troop_id, room.defense_uid)
            --    if ack_unit ~= nil and defense_unit ~= nil then
            --        local unit = {}
            --        unit.ack = ack_unit
            --        unit.defense = defense_unit
            --        unit.is_mass = ack_troop.is_mass
            --        unit.room_id = room._id
            --        table.insert(msg_send, unit)
            --    end
            --end
        else
            table.insert(dels, 1, k)
        end
    end
    for k, v in ipairs(dels) do
        table.remove(union.battle_room_ids, v)
    end

    dumpTab(msg_send, "union_battle_room_list")
    Rpc:union_battle_room_list_resp(self, msg_send)
end


function do_battle_room_info(room)
    if room.info then return room.info end

    local troop = troop_mng.get_troop(room._id)
    if not troop then return nil end

    local info = { {}, {} }
    local A = get_ety(troop.owner_eid)
    local D = get_ety(troop.target_eid)

    for k, v in ipairs({A, D}) do
        local node = info[ k ]
        if k == 1 then node.troop_id = room._id
        else node.troop_id = v.my_troop_id or 0 end

        node.uid = v.uid
        local union = unionmng.get_union( v.uid )
        if union then
            node.name = union.name
            node.alias = union.alias
        end

        node.players = {}
        local hit = v.pid or 0
        if is_ply(v) then table.insert(node.players, { name=v.name, photo=v.photo, pid=v.pid} )
        else table.insert(node.players, { monster=v.propid} ) end

        if k == 1 then node.x, node.y = troop.sx, troop.sy
        else node.x, node.y = troop.dx, troop.dy end

        if k == 2 then troop = troop_mng.get_troop(node.troop_id) end
        if troop then
            for pid, arm in pairs(troop.arms) do
                if pid ~= hit and pid > 0 then
                    local p = getPlayer(pid)
                    if p then
                        if is_ply(p) then 
                            table.insert(node.players, { name=p.name, photo=p.photo, pid=p.pid} )
                        end
                    end
                end
            end

            for _, tid in pairs(troop.mark_troop_ids or {}) do
                local t = troop_mng.get_troop(tid)
                if t then
                    local p = getPlayer(t.owner_pid)
                    if p then
                        table.insert(node.players, { name=p.name, photo=p.photo, pid=p.pid} )
                    end
                end
            end
        end
    end
    room.info = info
    return info
end


function get_battle_room_info(self, troop_id, uid, is_mass)
    local troop = troop_mng.get_troop(troop_id)
    if troop == nil then
        return nil
    end

    local unit = {}
    unit.troop_id = troop_id
    unit.uid = uid
    unit.players = {}
    if troop.is_mass == 0 then
        local player = getPlayer(troop.owner_pid)
        if player == nil then
            return nil
        end
        local single = {}
        single.name = player.name
        single.photo = player.photo
        single.pid = player.pid
        table.insert(unit.players, single)
        return unit
    end

    local union = unionmng.get_union(uid)
    if union then
        --return nil
        unit.name = union.name
        unit.alias = union.alias
    else
        unit.name = "none"
        unit.alias = "none"
    end

    --找出加入这个军队的玩家
    for k, v in pairs(troop.arms) do
        if k == 0 then
            local owner = get_ety(troop.owner_eid)
            if is_monster(owner) or is_npc_city(owner) then
                table.insert(unit.players, {monster=owner.propid})
            end
        else
            local tm_player = getPlayer(k)
            if tm_player ~= nil then
                local single = {}
                single.name = tm_player.name
                single.photo = tm_player.photo
                single.pid = tm_player.pid
                table.insert(unit.players, single)
            end
        end
    end
    for k, v in pairs(troop.mark_troop_ids or {}) do
        local tm_troop = troop_mng.get_troop(v)
        if tm_troop ~= nil then
            local tm_player = getPlayer(tm_troop.owner_pid)
            if tm_player ~= nil then
                local single = {}
                single.name = tm_player.name
                single.photo = tm_player.photo
                single.pid = tm_player.pid
                table.insert(unit.players, single)
            end
        end
    end
    return unit
end

--function union_battle_room_info(self, room_id)
--    local room = union_hall_t.get_battle_room(room_id)
--    if room == nil then
--        return
--    end
--
--    local ack_troop = troop_mng.get_troop(room.ack_troop_id)
--    if ack_troop == nil then
--        return
--    end
--
--    local ack_unit =     self:get_battle_room_info(room.ack_troop_id, room.ack_uid, ack_troop.is_mass)
--    local defense_unit = self:get_battle_room_info(room.defense_troop_id, room.defense_uid, ack_troop.is_mass)
--    if ack_unit == nil or defense_unit == nil then
--        return
--    end
--    local msg_send = {}
--    ack_unit.x = ack_troop.sx
--    ack_unit.y = ack_troop.sy
--
--    defense_unit.x = ack_troop.dx
--    defense_unit.y = ack_troop.dy
--
--    msg_send.ack = ack_unit
--    msg_send.defense = defense_unit
--    msg_send.tmStart = ack_troop.tmStart
--    msg_send.tmOver = ack_troop.tmOver
--    msg_send.is_mass = ack_troop.is_mass
--    msg_send.room_id = room_id
--
--    dumpTab(msg_send, "union_battle_room_info")
--    Rpc:union_battle_room_info_resp(self, msg_send)
--end
--

function union_battle_room_info(self, room_id)
    local room = union_hall_t.get_battle_room(room_id)
    if not room then return end

    local troop = troop_mng.get_troop(room_id)
    if not troop then return end

    local info = do_battle_room_info(room)
    if info then
        local msg_send = {}
        msg_send.ack = info[1]
        msg_send.defense = info[2]
        msg_send.tmStart = troop.tmStart
        msg_send.tmOver = troop.tmOver
        msg_send.is_mass = troop.is_mass
        msg_send.room_id = room_id

        dumpTab(msg_send, "union_battle_room_info")
        Rpc:union_battle_room_info_resp(self, msg_send)
    end
end




function fill_player_info_by_arm(self, arm, troop_action, owner_pid)
    if arm == nil then return end
    local player = getPlayer(arm.pid)
    if player == nil then return end

    local unit = {}
    unit.pid = arm.pid
    unit.name = player.name
    unit.photo = player.photo

    unit.heros = {}
    unit.heros_lv = {}
    unit.heros_star = {}
    unit.heros_hp = {}
    local tm_heros = {}
    --如果是城主的部队，英雄要算出来
    if troop_action == TroopAction.DefultFollow and arm.pid == owner_pid then tm_heros = self:get_defense_heros() 
    else tm_heros = arm.heros end

    for k, v in pairs(tm_heros) do
        if v ~= 0 then
            local hero = heromng.get_hero_by_uniq_id(v)
            if hero then
                table.insert(unit.heros, hero.propid)
                table.insert(unit.heros_lv, hero.lv)
                table.insert(unit.heros_star, hero.star)
                table.insert(unit.heros_hp, hero.hp)
            end
        end
    end

    local total = 0
    unit.soldier = {}
    for k, v in pairs(arm.live_soldier) do
        table.insert(unit.soldier, {id=k, num=v})
        total = total + v
    end
    unit.total_soldier = total
    return unit
end

function get_arm_info(pid, troop)
    if pid > 0 then
        local arm = troop.arms and troop.arms[ pid ]
        if not arm then return end
        local t = {}

        local p = getPlayer(pid)
        t.pid = p.pid
        t.name = p.name
        t.photo = p.photo
        t.soldier = {}
        t.heros = {}
        t.heros_lv = {}

        local heros = arm.heros
        if troop.action == TroopAction.DefultFollow and pid == troop.owner_pid then heros = p:get_defense_heros() end
        for _, hid in pairs(heros) do
            if hid ~= 0 then
                local h = heromng.get_hero_by_uniq_id(hid)
                if h then
                    table.insert(t.heros, h.propid)
                    table.insert(t.heros_lv, h.lv)
                end
            end
        end
        local total = 0
        for id, num in pairs(arm.live_soldier or {}) do
            table.insert(t.soldier, {id=id, num=num})
            total = total + num
        end
        t.total_soldier = total

        --if p.pid == troop.owner_pid then table.insert(node.players, 1, t)
        --else table.insert(node.players, t) end

        return t
    end
end


function do_battle_room_detail(room)
    if room.detail then return room.detail end

    local troop = troop_mng.get_troop(room._id)
    if not troop then return nil end

    local atk = troop

    local info = { {}, {} }
    local A = get_ety(troop.owner_eid)
    local D = get_ety(troop.target_eid)

    for k, v in ipairs({A, D}) do
        local node = info[ k ]
        if k == 1 then node.troop_id = room._id 
        else node.troop_id = D.my_troop_id or 0 end

        node.uid = v.uid
        node.owner_eid = v.eid
        node.players = {}

        if k == 1 then
            node.x = troop.sx
            node.y = troop.sy
        else
            node.x = atk.dx
            node.y = atk.dy
        end

        local troop = troop_mng.get_troop(node.troop_id)
        if troop then
            for pid, arm in pairs(troop.arms) do
                if pid > 0 then
                    local t = get_arm_info(pid, troop)
                    if t then
                        t.tmStart = 0
                        t.tmOver = 0
                        t.tid = troop._id
                        if pid == troop.owner_pid then table.insert(node.players, 1, t)
                        else table.insert(node.players, t) end
                    end
                else
                    table.insert(node.players, {monster=v.propid, total_soldier=0})
                end
            end

            for _, tid in pairs(troop.mark_troop_ids or {}) do
                local tm_troop = troop_mng.get_troop(tid)
                if tm_troop then
                    local t = get_arm_info(tm_troop.owner_pid, tm_troop)
                    if t then
                        t.tmStart = tm_troop.tmStart
                        t.tmOver = tm_troop.tmOver
                        t.tid = tm_troop._id
                        table.insert(node.players, t)
                    end
                end
            end
        end
    end
    room.detail = info
    return info
end

function get_battle_room_detail(self, troop_id)
    local troop = troop_mng.get_troop(troop_id)
    if troop == nil then return nil end

    local unit = {}
    local union = unionmng.get_union(troop.owner_uid)
    if union  then
        unit.name = union.name
        unit.alias = union.alias
    end

    unit.troop_id = troop_id
    unit.uid = troop.owner_uid
    unit.owner_eid = troop.owner_eid
    unit.players = {}

    --找出加入这个军队的玩家
    for k, v in pairs(troop.arms) do
        local single = self:fill_player_info_by_arm(v, troop.action, troop.owner_pid)
        if single then
            single.tmStart = 0
            single.tmOver = 0
            single.tid = troop._id
            table.insert(unit.players, single)
        end
    end
    for k, v in pairs(troop.mark_troop_ids or {}) do
        local tm_troop = troop_mng.get_troop(v)
        if tm_troop ~= nil then
            local single = self:fill_player_info_by_arm(tm_troop:get_arm_by_pid(tm_troop.owner_pid), tm_troop.action, tm_troop.owner_pid)
            if single then
                single.tmStart = tm_troop.tmStart
                single.tmOver = tm_troop.tmOver
                single.tid = tm_troop._id
                table.insert(unit.players, single)
            end
        end
    end
    return unit
end


--function union_battle_room_detail(self, room_id)
--    local room = union_hall_t.get_battle_room(room_id)
--    if room == nil or room.is_mass ~= 1 then return end
--
--    local troop = troop_mng.get_troop(room_id)
--    if not troop then return end
--    local D = get_ety(troop.target_eid)
--    if not D then return end
--
--    local ack_unit = self:get_battle_room_detail(troop._id, troop.owner_uid)
--    local defense_unit = self:get_battle_room_detail(D.my_troop_id, D.uid)
--
--    local ack_troop = troop_mng.get_troop(room.ack_troop_id)
--    if ack_unit == nil or defense_unit == nil or ack_troop == nil then
--        return
--    end
--    
--    local msg_send = {}
--    ack_unit.x = ack_troop.sx
--    ack_unit.y = ack_troop.sy
--
--    defense_unit.x = ack_troop.dx
--    defense_unit.y = ack_troop.dy
--
--    msg_send.action = ack_troop.action
--    msg_send.ack = ack_unit
--    msg_send.defense = defense_unit
--    msg_send.tmStart = ack_troop.tmStart
--    msg_send.tmOver = ack_troop.tmOver
--    msg_send.is_mass = ack_troop.is_mass
--    msg_send.room_id = room_id
--    if ack_troop.action == TroopAction.WaitMass then
--        msg_send.is_march = 0
--    else
--        msg_send.is_march = 1
--    end
--
--    Rpc:union_battle_room_detail_resp(self, msg_send)
--end
--


function union_battle_room_detail(self, room_id)
    local room = union_hall_t.get_battle_room(room_id)
    if room == nil or room.is_mass ~= 1 then return end

    local troop = troop_mng.get_troop(room_id)
    if not troop then return end

    local info = do_battle_room_detail(room)
    if not info then return end
    dumpTab(info, "battle_room_detail")

    local msg_send = {}
    
    msg_send.action = troop.action
    msg_send.ack = info[1]
    msg_send.defense = info[2]
    msg_send.tmStart = troop.tmStart
    msg_send.tmOver = troop.tmOver
    msg_send.is_mass = troop.is_mass
    msg_send.room_id = room_id

    if troop:is_ready() then msg_send.is_march = 0
    else msg_send.is_march = 1 end

    Rpc:union_battle_room_detail_resp(self, msg_send)
end

function union_help_get(self )
    Rpc:union_help_get(self, union_help.get(self))
end

function union_help_add(self ,sn)
    union_help.add(self,sn)
end

function union_help_set(self ,sn)
    union_help.set(self,sn)
end

function union_word_top(self ,wid,f)
    union_word.top(self,wid,f)
end

function union_word_del(self ,wid)
    union_word.del(self,wid)
end

function union_word_update(self,wid,title,word)
    union_word.update(self,wid,title,word)
end

function union_word_add(self,uid,title,word)
    local d = union_word.add(self,uid,title,word)
    Rpc:union_word_add(self, d)
end

function union_word_get(self,uid,wid)
    local u = unionmng.get_union(uid)
    if u then
        local d = union_word.get(self,u,wid)
        Rpc:union_word_get(self, d)
    end
end

function union_item_get(self,idx)
    union_item.get(self,idx)
end

function union_god_add(self,mode)
    union_god.add(self,mode)
end

function union_god_get(self)
    union_god.get(self)
end

