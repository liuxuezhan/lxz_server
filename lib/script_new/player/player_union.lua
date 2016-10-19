module("player_t")

--{{{ create & destory
function union_load(self, what)
    local ret = union_select(self,self.uid,what)
    if ret then
        Rpc:union_load(self, ret)
    end
end

function union_get(self, what,uid)
    local ret = union_select(self,uid,what)
    if ret then
        Rpc:union_get(self, ret)
    end
end

function remote_union_select(union, ply, uid, what)
    local map_id = union.map_id
    local func = "union_load"
    local param = {"player", ply.pid, what, uid}
    remote_cast(map_id, func, param)
end

function union_select(self, uid,what)
    --uid = self.uid
    local union = unionmng.get_union(uid)

    local result = {
        uid = uid,
        key = what,
        val = {},
    }
    if not union then
        --nil
    elseif union.map_id then -- cross gs
        remote_union_select(union, self, uid, what)
        return
    elseif what == "info" then
        result.val = union:get_info()
    elseif what == "member" then
        local R0 =  union_t.is_legal(self, "Invite")
        if not union.map_id then
            local _members = union:get_members()
            for _, A in pairs(_members or {}) do
                if not R0  and player_t.get_rank(A) == resmng.UNION_RANK_0 then
                else
                    table.insert(result.val, rpchelper.parse_rpc(player_t.get_union_info(A),"unionmember"))
                end
            end
        else
            local map_id = union.map_id
            local func = "get_remote_member_info"
            local param = {"union", union.uid, R0}
            local val =  remote_func(map_id, func, param)
            if val then
                result.val = val
            end
        end
    elseif what == "relation" then
        if not union.map_id then
            result.val = union_relation.list(union)
        else
            local map_id = union.map_id
            local func = "get_remote_member_relation"
            local param = {"union", union.uid}
            local val =  remote_func(map_id, func, param)
            if val then
                result.val = val
            end
        end
    elseif what == "mass" then
        local info = {}
        for idx, _ in pairs(union.mass or {}) do
            table.insert(info, union:get_mass_simple_info(idx))
        end
        result.val = info
    elseif what == "tech" then
        local l = {}
        local _tech = union:get_tech()
        for _, v in pairs(_tech or {}) do
            table.insert(l,v)
        end
        result.val = {info=l, mark=union.tech_mark}
    elseif what == "donate" then
        result.val = {donate=self._union.donate,tmOver=self._union.tmDonate,CD_num = self._union.CD_doante_num or 0, flag=union_member_t.get_donate_flag(self)}
    elseif what == "mars" then --膜拜
        local god = union:get_god()
        result.val = {mars=god,log = self._union.god_log,}
    elseif what == "mall" then
        result.val.mall = union_mall.get(self.uid)
        result.val.gift = union_item.show(self)
    elseif what == "aid" then
        result.val = self:get_aid_info()
    elseif what == "build" then
        if not union:is_new() then
            if union.map_id then
                local map_id = union.map_id
                local func = "union_get"
                local param = {"player", self.pid, what, uid}
                remote_cast(map_id, func, param)
            else
                result.val= {}
                result.val = union_buildlv.get(self)
                result.val.build =  get_build_list(union)
            end
        end
    elseif what == "word" then
        result.val = union_word.list(self.pid,union)
        --Rpc:tips(self, resmng.BLACKMARCKET_TEXT_NEED_TIPS,{})
    elseif what == "ef" then
        local _ef = union:get_ef()
        result.val = {ef = _ef, ef_ex = self:get_castle_ef()}
    elseif what == "buf" then
        result.val = {buf = union.buf}
    elseif what == "union_donate" then
        result.val = union.donate
    end

    result.val = result.val or {}
    return result
end

function union_search(self, what)
    local l = {}
    local num = 50
    local u = unionmng.get_union(self:get_uid())
    if not u then  return end

    if what ~= "" then
        local info = dbmng:getOne().player:find({name={["$regex"]=what}})
        while info:hasNext() do
            local p = info:next()
            local v = getPlayer(p.pid)
            if (v.uid == 0)and (not u:get_invite(v.pid)) and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                l[v.pid]={pid=v.pid,name=v.name,language=v.language,photo=v.photo,uid=v.uid, pow=v:get_pow()}
            end
        end
    else
        local info = dbmng:getOne().player:find({language=u.language,uid=0})
        while info:hasNext() do
            local p = info:next()
            local v = getPlayer(p.pid)
            if (not u:get_invite(v.pid)) and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                l[v.pid]={pid=v.pid,name=v.name,language=v.language,photo=v.photo, pow=v:get_pow()}
                if #l > num then break end
            end
        end
        if #l < num then
            local info = dbmng:getOne().player:find({language={["$ne"]=u.lanuage},uid=0})
            while info:hasNext() do
                local p = info:next()
                local v = getPlayer(p.pid)
                if (not u:get_invite(v.pid)) and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                    l[v.pid]={pid=v.pid,name=v.name,language=v.language,photo=v.photo, pow=v:get_pow()}
                    if #l > num then break end
                end
            end
        end
    end
    Rpc:union_search(self, l)
end

function union_relation_set(self,uid,type)
    if not check_union_cross(uid) then
        union_relation.set(self,uid,type)
    else
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
end

function get_build_list(union)
    local l = {}
    if union then
        local build = union:get_build()
        for _, t in pairs(build or {}) do
            local c = resmng.get_conf("prop_world_unit",t.propid)
            if c.Mode == UNION_CONSTRUCT_TYPE.RESTORE then
                if union_build_t.get_res_count(union) > 0 then
                    t.ga_state = 1
                else
                    t.ga_state = 0
                end
            else
                if t.my_troop_id then
                    t.ga_state = 1
                else
                    t.ga_state = 0
                end
            end
            table.insert(l,t)
        end
    end
    return l
end

function union_create(self, name, alias, language, mars)
    if check_ply_cross(self) then
        ack(self, "union_create", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "Create") then
        ack(self, "union_create", resmng.E_DISALLOWED) return
    end

    if not self:condCheck(CREATEUNION.condition) then
        ack(self, "union_create", resmng.E_CONDITION_FAIL) return
    end

    for _, v in pairs(unionmng.get_all()) do
        if v.name == name then
            ack(self, "union_create", resmng.E_DUP_NAME) return
        end
        if v.alias == alias then
            ack(self, "union_create", resmng.E_DUP_ALIAS) return
        end
    end

    if self:get_castle_lv() < resmng.CREATEUNION.lv   then
        if not self:do_dec_res(resmng.DEF_RES_GOLD, resmng.CREATEUNION.cost, VALUE_CHANGE_REASON.UNION_CREATE ) then
            WARN("金钱不足")
            return
        end
    end

    local union = union_t.create(self, name, alias, language, mars)

    -- register union chat room
    create_chat_room(union)

    local c = resmng.get_conf("prop_language_cfg",union.language)
    if not c  then
        WARN("没有propid:"..union.language)
        return
    end
    Rpc:tips({pid=-1,gid=_G.GateSid}, 2,resmng.NOTIFY_UNION_CREATE,{self.name,c.Text,union.name})
    Rpc:union_on_create(self, union:get_info())
    --任务
    task_logic_t.process_task(self, TASK_ACTION.JOIN_PLAYER_UNION)

    self.uname = alias
    etypipe.add(self)
end
-- 创建聊天room
function create_chat_room(union)
    to_tool(0, {type = "chat", cmd = "create_room", name = tostring(union.uid), server ="conference."..CHAT_HOST, host = CHAT_HOST })
end

function union_destory(self)
    if check_ply_cross(self) then
        ack(self, "union_destory", resmng.E_DISALLOWED) return
    end

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

    if check_ply_cross(self) then
        ack(self, "union_set_info", resmng.E_DISALLOWED) return
    end

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
        if self:do_dec_res(resmng.DEF_RES_GOLD, UNION_CHANGEFLAGPRICE, VALUE_CHANGE_REASON.UNION_FLAG) then
            u.flag = info.flag
        end
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

    if check_ply_cross(self) then
        ack(self, "union_rm_member", resmng.E_DISALLOWED) return
    end

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

    if check_ply_cross(self) then
        ack(self, "union_add_member", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_add_member", resmng.E_NO_PLAYER) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_add_member", resmng.E_NO_UNION) return
    end

    if not u:has_member(self) then return resmng.E_NO_UNION end
    if not union_t.is_legal(self, "Invite") then
        return resmng.E_DISALLOWED
    end

    if not u:get_apply(pid) then
        WARN(u.uid..":没有申请:"..pid)
        return
    end

    u:remove_apply(pid)
    u:add_member(B,self)
end

function union_apply(self, uid)

    if check_ply_cross(self) then
        ack(self, "union_apply", resmng.E_DISALLOWED) return
    end

    if #self.busy_troop_ids > 0 then
        WARN("有troop") return
    end

    local old_union = unionmng.get_union(self:get_uid())
    if old_union and not union_t.is_legal(self, "Join") then
       WARN("在军团里:"..old_union._id) return
    end

    local u = unionmng.get_union(uid)
    if not u then
        WARN("没军团:"..uid) return
    end

    if not self:union_enlist_check(uid) then
        return
    end

    if u.enlist.check == 0  then
        u:add_member(self)
    else
        u:add_apply(self)
        if u:get_apply(self.pid) then
            Rpc:union_reply(self, u.uid,u.name, resmng.UNION_STATE.APPLYING)
        elseif u:has_member(self) then
            Rpc:union_reply(self, u.uid,u.name, resmng.UNION_STATE.IN_UNION)
        end
    end

end

function union_quit(self)

    if check_ply_cross(self) then
        ack(self, "union_quit", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then return end
    local ret = u:quit(self)
    ack(self, "union_quit", ret)
end

function union_reject(self, pid)

    if check_ply_cross(self) then
        ack(self, "union_reject", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        WARN("")
        return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        WARN("")
        return
    end

    local ret = union:reject_apply(self, B)
    if ret == resmng.E_OK then
        Rpc:union_reply(B, union.uid,union.name, resmng.UNION_STATE.NONE)
    end
end

function union_enlist_set(self, check,text,lv,pow)
    local u = unionmng.get_union(self:get_uid())
    u.enlist = {check = check ,text=text,lv=lv, pow=pow}
end

function union_enlist_check(self, uid)
    local u = unionmng.get_union(uid)

    local lv = self:get_castle_lv(self)

    if lv < u.enlist.lv then
        WARN("等级不足:"..lv..":"..u.enlist.lv)
        return false
    end

    local p = self:get_pow()
    if p < u.enlist.pow then
        WARN("战力不足:"..p..":"..u.enlist.pow)
        return false
    end

    return true
end

function sort_info(self,union)
    if union then
        local info  = union:get_info()
        local p = union:get_leader()
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
        info = rpchelper.parse_rpc(info,"union")
        return info
    end
end

function union_list(self,name)

    local ret = {name = name,list={}}
    if name ~= "" then
        local data = dbmng:getOne().union_t:find({name={["$regex"]=name}})
        while data:hasNext() do
            local u = data:next()
            u = unionmng.get_union(u.uid)
            if u  and u:check() then
                local info = sort_info(self,u)
                if info  then
                    ret.list[info.uid]=info
                end
            else
                WARN("警告："..u.uid)
            end
        end

        data = dbmng:getOne().union_t:find({alias={["$regex"]=name}})
        while data:hasNext() do
            local u = data:next()
            u = unionmng.get_union(u.uid)
            if u and u:check() then
                local info = sort_info(self,u)
                if info  then
                    ret.list[info.uid]=info
                end
            end
        end
        Rpc:union_list(self, ret)
        return
    end

    local u1,u2,u3 
    local u4 = {}
    local u5 = {}
    local len = math.huge

    local us = rank_mng.get_range(5,1,20000)
    for k, uid in pairs( us ) do
        if uid == 0 then break end
        local u = unionmng.get_union(uid)
        if u and (not u:is_new()) and u:check() then 
            if self.language == u.language then
                if not u1  then 
                    u1 = u 
                else
                    local p = u:get_leader()
                    local l = math.pow(math.abs(p.x-self.x),2) + math.pow(math.abs(p.y-self.y),2)
                    if (l < len or len == 0) then
                        table.insert(u4,u2)
                        len =l
                        u2 = u
                    else
                        table.insert(u4,u)
                    end
                end

            else
                if not u3  then 
                    u3 = u 
                else
                    table.insert(u5,u)
                end
            end

            if k > 200 and u1 and u2 and u3 and ( (#u4 or 0) + (#u5 or 0) > 197 ) then
                break
            end
        end
    end

    local info = sort_info(self,u1)
    if info then table.insert(ret.list,info) end
    local info = sort_info(self,u2)
    if info then table.insert(ret.list,info) end
    local info = sort_info(self,u3)
    if info then table.insert(ret.list,info) end
    for _, v in pairs( u4 ) do
        local info = sort_info(self,v)
        if info then table.insert(ret.list,info) end
    end
    for _, v in pairs( u5 ) do
        local info = sort_info(self,v)
        if info then table.insert(ret.list,info) end
    end

    Rpc:union_list(self, ret)
end

function union_invite(self, pid)

    if check_ply_cross(self) then
        ack(self, "union_invite", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_invite", resmng.E_NO_PLAYER) return
    end
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_invite", resmng.E_NO_UNION) return
    end

    local ret = union:send_invite(self, B)
    B:send_system_union_invite(30001, self.pid, {uid=union.uid}, {self.name,union.name})
    ack(self, "union_invite", ret)
end

function union_invite_migrate(self,pids)
    local u = unionmng.get_union(self:get_uid())
    if not u then WARN("没有军团") return end

    for _, v in pairs( u.build ) do
        local c = resmng.get_conf("prop_world_unit",v.propid)
        if c.Mode == resmng.CLASS_UNION_BUILD_CASTLE then
            for _, pid in pairs(pids) do
                local p = getPlayer(pid)
                if u:has_member(p) then 
                    p:send_system_city_move(20001, self.pid, {x=c.x, y=c.y}, {"jim"})
                end
            end
        end
    end

end

function union_accept_invite(self, uid)
    if #self.busy_troop_ids > 0 then
        ack(self, "union_accept_invite", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(uid)
    if not u then
        ack(self, "union_accept_invite", resmng.E_NO_UNION) return
    end

    if u:has_member(self) then
        WARN("[Union]: acceptInvite, already in Union, player:%s, union:%s", self.pid, u.uid)
        return
    end

    for k, v in pairs(u.invites) do
        if v.pid == self.pid then
            u:remove_invite(k)
        end
    end
    u:add_member(self,self)
end

function union_reject_invite(self, uid)

    local u = unionmng.get_union(uid)
    if not u then
        ack(self, "union_reject_invite", resmng.E_NO_UNION) return
    end

    if u:has_member(self) then
        WARN("[Union]: RejectInvite, already in Union, player:%s, union:%s", self.pid, u.uid)
        return
    end

    for k, v in pairs(u.invites) do
        if v.pid == self.pid then
            u:remove_invite(k)
        end
    end
end

function union_member_rank(self, pid, r)

    if check_ply_cross(self) then
        ack(self, "union_member_rank", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_member_rank", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_member_rank", resmng.E_NO_UNION) return
    end

    if not u:has_member(self, B) then return  end

    if self:get_rank() >= r then
        B:set_rank(r)
    end
end

function union_member_title(self, pid, t)

    if check_ply_cross(self) then
        ack(self, "union_member_title", resmng.E_DISALLOWED) return
    end

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
        u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.TITLE, B:get_union_info())
        return resmng.E_OK
    else
        return resmng.E_FAIL
    end
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
    local _members = u:get_members()
    for id, v in pairs(_members or {}) do
        local B = getPlayer(id)
        if B and B:get_rank() > rank and id ~= self.pid then
            pid = id
            rank = B:get_rank()
        end
    end

    if pid == 0  then
        return true
    end

    local B = getPlayer(pid)
    if not B then
        WARN("")
        return false
    end

    self:set_rank(resmng.UNION_RANK_4)
    B:set_rank(resmng.UNION_RANK_5)
    u.leader = pid
    return false
end

function union_leader_update(self, pid)--手工移交军团长

    if check_ply_cross(self) then
        ack(self, "union_leader_update", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        WARN("")
        return
    end

    local leader = getPlayer(u.leader)
    if not leader then
        WARN("没有军团长")
        return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_leader_update", resmng.E_NO_PLAYER) return
    end

    if self:get_rank()== resmng.UNION_RANK_5 and B:get_rank()== resmng.UNION_RANK_4 and  u:has_member(B) then
        leader:set_rank(resmng.UNION_RANK_4)
        B:set_rank(resmng.UNION_RANK_5)
        u.leader = pid
    end

    if u:has_member(B) and B:get_rank()== resmng.UNION_RANK_4 and  (not leader:is_online()) and leader.tm_logout + 5*24*60*60 <  gTime then
        if leader.pid ~= self.pid and  (not self:do_dec_res(resmng.DEF_RES_GOLD, 1000, VALUE_CHANGE_REASON.UNION_RANK )) then
            WARN("金钱不足")
            return
        end

        leader:set_rank(resmng.UNION_RANK_4)
        B:set_rank(resmng.UNION_RANK_5)
        u.leader = pid
    end
end

function union_member_mark(self, pid, mark)

    if check_ply_cross(self) then
        ack(self, "union_member_mark", resmng.E_DISALLOWED) return
    end

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

function union_troop_buf(self)
    if not union_t.is_legal(self, "Global2") then
        WARN("没权限")
        return
    end
    if not self:do_dec_res(resmng.DEF_RES_GOLD, 20000, VALUE_CHANGE_REASON.UNION_TASK) then
        return
    end
    local u = unionmng.get_union(self.uid)
    u:add_buf(90001001,8*60*60)
    Rpc:tips({pid=-1,gid=_G.GateSid}, 2,resmng.UNION_ADD_BUF,{u.name})
end

--{{{ tech & donate
function union_tech_info(self, idx)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_info", resmng.E_NO_UNION) return
    end

    if union.map_id then
        local map_id = union.map_id
        local func = "union_tech_info"
        local param = {"player", self.pid, idx}
        remote_cast(map_id, func, param)
        return
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

    if check_ply_cross(self) then
        ack(self, "union_tech_mark", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_mark", resmng.E_NO_UNION) return
    end
    union:set_tech_mark(info)
end

function union_mall_add(self,propid,num)

    if check_ply_cross(self) then
        ack(self, "union_mall_add", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        WARN("")
        return
    end

    if not union_t.is_legal(self, "AddItem") then
        WARN("没权限")
        return
    end

    local c = resmng.get_conf("prop_union_mall",propid)
    if not c then
        WARN("")
        return
    end

    local cc = resmng.get_conf("prop_union_tech",c.ConditionLv[2] )
    if u._tech[1005] then
        local cur = resmng.get_conf("prop_union_tech",u._tech[1005].id)
        if cur.Lv < cc.Lv then
            WARN("不能进货")
            return
        end
    else
        if 0 < cc.Lv then
            WARN("不能进货")
            return
        end
    end

    union_mall.add(self,propid,num)
end

function union_mall_mark(self,propid,flag)

    if check_ply_cross(self) then
        ack(self, "union_mall_mark", resmng.E_DISALLOWED) return
    end

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

    if check_union_cross(u) then
        remote_cast(u.map_id, "union_mall_log", {"player", self.pid, type}) 
        return
    end

    local d = union_mall.get_log(u,type)
    Rpc:union_mall_log(self, d)
end

function union_mall_buy(self,propid,num)

    if check_ply_cross(self) then
        ack(self, "union_mall_buy", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_mall_add", resmng.E_NO_UNION) return
    end

    union_mall.buy(self,propid,num)
    Rpc:union_donate_info(self, {donate=self._union.donate,tmOver=self._union.tmDonate,flag=union_member_t.get_donate_flag(self)})
end

function union_donate_clear(self)

    if check_ply_cross(self) then
        ack(self, "union_donate_clear", resmng.E_DISALLOWED) return
    end

    union_member_t.clear_tmdonate(self)
    Rpc:union_donate_info(self, {tmOver=self._union.tmDonate,CD_num = self._union.CD_doante_num, flag=union_member_t.get_donate_flag(self)})
end

function union_donate(self, idx, type)
    if check_ply_cross(self) then
        ack(self, "union_donate", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_donate", resmng.E_NO_UNION) return
    end
    local tech = union:get_tech(idx)
    if not tech then
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
    local conf = resmng.get_conf("prop_union_donate",union_tech_t.get_class(tech.idx))
    if not conf then
        ack(self, "union_donate", resmng.E_FAIL) return
    end
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

    if not self:do_dec_res(cost[1], cost[2], VALUE_CHANGE_REASON.UNION_DONATE) then
        return
    end

    self:add_donate(reward[1], VALUE_CHANGE_REASON.REASON_UNION_DONATE)
    union_member_t.add_techexp(self,reward[3],VALUE_CHANGE_REASON.REASON_UNION_DONATE)
    union_mission.ok(self,UNION_MISSION_CLASS.DONATE,1)

    local c = resmng.get_conf("prop_union_tech", tech.id + 1)
    if not c then return end
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
    --成就
    self:add_count(resmng.ACH_TASK_TECH_DONATE, 1)
    --任务
    task_logic_t.process_task(self, TASK_ACTION.UNION_TECH_DONATE, 1)

    ack(self, "union_donate", resmng.E_OK)
end


function union_tech_upgrade(self, idx)

    if check_ply_cross(self) then
        ack(self, "union_tech_upgrade", resmng.E_DISALLOWED) return
    end

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
    
    if check_union_cross(u) then
        remote_cast(u.map_id, "union_donate_rank", {"player", self.pid, what})
        return
    end

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

    if check_union_cross(union) then
        remote_cast(union.map_id, "union_log", {"player", self.pid, sn, mode})
        return
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

    if check_ply_cross(self) then
        ack(self, "union_set_note_in", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_set_note_in", resmng.E_NO_UNION) return
    end

end

function union_task_get (self )--发布悬赏任务

    local union = unionmng.get_union(self.uid)
    if check_union_cross(union) then
        remote_cast(union.map_id, "union_task_get", {"player", self.pid})
        return
    end

    local l = union_task.get(self:get_uid())
    Rpc:union_task_get(self,l)
end

function union_mission_log (self,type,id )--获取定时任务日志

    local union = unionmng.get_union(self.uid)
    if check_union_cross(union) then
        remote_cast(union.map_id, "union_mission_log", {"player", self.pid, type, id})
        return
    end

    local list =union_mission.get_log(self:get_uid(),type,id)
    Rpc:union_mission_log(self,list)
end

function union_mission_get (self )--获取定时任务
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_mission_get", resmng.E_NO_UNION) return
    end

    if union.map_id then
        remote_cast(union.map_id, "union_mission_get", {"player", self.pid})
        return
    end

    local inf = union_mission.get(self.pid,self:get_uid())
    Rpc:union_mission_get(self,inf)
end

function union_mission_update (self )--刷新定时任务
    if check_ply_cross(self) then
        ack(self, "union_mission_update", resmng.E_DISALLOWED) return
    end

    union_mission.update(self.uid,self)
end

function union_mission_chat (self )
    if check_ply_cross(self) then
        ack(self, "union_mission_chat", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "Mission") then
        return
    end
    union_mission.update_chat(self)
end

function union_mission_set (self )--领取定时任务

    if check_ply_cross(self) then
        ack(self, "union_mission_set", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then WARN() return end

    if not union_t.is_legal(self, "Mission") then
        return
    end

    if union_mission.set(self.uid) then
        union:add_log(resmng.UNION_EVENT.MISSION,resmng.UNION_MODE.GET,{ name=self.name,propid=union_mission._d[union.uid].propid })
        Rpc:union_mission_set(self)
    end
end
function union_word_add (self,...)
    if check_ply_cross(self) then
        ack(self, "union_word_add", resmng.E_DISALLOWED) return
    end

    union_word.add(self.pid,...)
end
function union_word_update (self,... )
    if check_ply_cross(self) then
        ack(self, "union_word_update", resmng.E_DISALLOWED) return
    end
    union_word.update(self.pid,...)
end
function union_word_del (self,... )
    if check_ply_cross(self) then
        ack(self, "union_word_del", resmng.E_DISALLOWED) return
    end
    union_word.del(...)
end

function union_task_add(self, type, eid, hero,task_num, mode, res,res_num )--发布悬赏任务

    if check_ply_cross(self) then
        ack(self, "union_task_add", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        WARN("")
        return
    end

    if type == UNION_TASK.NPC  then
        eid = npc_city.have[eid]
    end

    local dp = get_ety(eid)
    if not dp then
        WARN("没有npc城市")
        return
    end
    union_task.add(self,type,eid,hero,task_num,mode,res,res_num)
    union:add_log(resmng.UNION_EVENT.TASK,resmng.UNION_MODE.ADD,{ name=self.name,type=type,mode=mode })
end
--{{{ build

function union_buildlv_donate(self, mode)
    if check_ply_cross(self) then
        ack(self, "union_buildlv_donate", resmng.E_DISALLOWED) return
    end

    if union_buildlv.add_buildlv_donate(self,mode) then
        Rpc:union_buildlv_donate(self, union_buildlv.get_buildlv(self:get_uid(),mode))
    end
end

function union_build_setup(self, idx,propid, x, y,name)
    if check_ply_cross(self) then
        ack(self, "union_build_setup", resmng.E_DISALLOWED) return
    end

    local u = self:union()
    if not u then
        return
    end

    if not union_t.is_legal(self, "BuildPlace") then
        return
    end

    union_build_t.create(self.uid, idx, propid, x, y,name)
end

function union_build_up(self, idx,state)
    if check_ply_cross(self) then
        ack(self, "union_build_up", resmng.E_DISALLOWED) return
    end

    local u = self:union()
    if not u then return end

    if not union_t.is_legal(self, "BuildUp") then return end

    local e = u:get_build(idx)
    if not e then return end

    e.state = state

    local bcc = resmng.get_conf("prop_world_unit",e.propid) or {}
    if not bcc then return false end

    if bcc.Mode == resmng.CLASS_UNION_BUILD_FARM
        or bcc.Mode ==resmng.CLASS_UNION_BUILD_LOGGINGCAMP
        or bcc.Mode ==resmng.CLASS_UNION_BUILD_MINE
        or bcc.Mode ==resmng.CLASS_UNION_BUILD_QUARRY  then     --采集返回

        for k, v in pairs(e.my_troop_id) do
            local one = troop_mng.get_troop(v)
            one:back()
        end
    end

    save_ety(e)
end

function union_build_remove(self, eid)
    if check_ply_cross(self) then
        ack(self, "union_build_remove", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "BuildUp") then return end
    local u = unionmng.get_union(self:get_uid())
    if not u then return end

    for k, v in ipairs(u.battle_room_ids or {}) do
        local r = union_hall_t.get_battle_room(v)
        if r and r.def_eid == eid then
            Rpc:tips(self, 1,resmng.UNION_BUILD_IN_WAR ,{})
            return
        end
    end
    rem_ety(eid)
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

function coming_hold_tr(ety)
    local coming_hold_tr = {}
    local comings = ety.troop_comings or {}
    for tr_id, action in pairs(comings or {}) do
        local tr = troop_mng.get_troop(tr_id)
        if tr and action == TroopAction.HoldDefense then
                coming_hold_tr[tr._id] = tr._id
        end
    end
    return coming_hold_tr
end

function add_hold_ply(players, trs)
    for k, v in pairs(trs or {}) do
        local tr = troop_mng.get_troop(k)
        if tr then
            local p = getPlayer(tr.owner_pid)
            if p then
                table.insert(players, { name=p.name, photo=p.photo, pid=p.pid} )
            end
        end
    end
end

function add_hold_tr_info(players, trs)
    for k, v in pairs(trs or {}) do
        local tr = troop_mng.get_troop(k)
        if tr then
            local p = getPlayer(tr.owner_pid)
            local t = get_arm_info( tr.owner_pid, tr )
            table.insert(players, t)
        end
    end
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
        node.eid = v.eid
        node.class = get_type(v.eid)
        node.players = {}
        if k == 1 then
            node.troop_id = room._id
            node.action = troop.action
            if is_ply( v ) then
                node.count_max = v:get_val( "CountRallySoldier" )
                node.count_cur = v:get_mass_count( troop )
            end
        else
            node.troop_id = v.my_troop_id or 0
        end

        if is_monster( v ) then
            node.propid = v.propid
            node.monster = v.propid
            node.hp = v.hp
        end

        if is_monster_city(v) then
            if k == 2 then
                node.propid = v.propid
                node.monster_city = v.propid
                local tr = monster_city.get_my_troop(v) or  {}
                node.arms = tr.arms
            end
        end

        if is_npc_city(v) then
            node.propid = v.propid
            local tr = v:get_my_troop() or {}
            node.arms = tr.arms
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        end

        if is_king_city(v) then
            node.propid = v.propid
            local tr = v:get_my_troop() or {}
            node.arms = tr.arms
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        end

        if is_lost_temple(v) then
            node.propid = v.propid
            local tr = v:get_my_troop() or {}
            node.arms = tr.arms
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        end

        node.uid = v.uid

        local union = unionmng.get_union(v.uid)
        if union then
            node.name = union.name
            node.alias = union.alias
        --else
          --  node.name = "uname"
            --node.alias = "ualias"
        end

        if is_ply(v) then table.insert(node.players, { name = v.name })
        elseif is_npc_city(v) and v.uid ~= 0 then
            local troop = v:get_my_troop()
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
            end
        elseif is_monster_city(v) then
            if k == 1 then
                node.monster_city = troop.mcid
            end
        end
        --else
          --  table.insert(node.players, { monster = v.propid }) end
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
        else
            table.insert(dels, 1, k)
        end
    end
    for k, v in ipairs(dels) do
        table.remove(union.battle_room_ids, v)
    end

    --dumpTab(msg_send, "union_battle_room_list")
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
        node.eid = v.eid
        node.class = get_type(v.eid)
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
        if is_ply(v) then
            table.insert(node.players, { name=v.name, photo=v.photo, pid=v.pid} )

        elseif is_res(v) then
            if v.pid and v.pid > 0 then
                local dest = getPlayer( v.pid )
                if dest then
                    table.insert(node.players, { name=dest.name, photo=dest.photo, pid=dest.pid} )
                end
            end

        elseif is_camp(v) then
            if v.pid and v.pid > 0 then
                local dest = getPlayer( v.pid )
                if dest then
                    table.insert(node.players, { name=dest.name, photo=dest.photo, pid=dest.pid} )
                end
            end

        elseif is_monster(v) then
            node.monster = v.propid
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        elseif is_king_city(v) then
            node.propid = v.propid
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        elseif is_lost_temple(v) then
            node.propid = v.propid
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        elseif is_monster_city(v) then
            if k == 1 then
                node.monster_city = troop.mcid
            elseif k == 2 then
                node.monster_city = v.propid
                local tr = monster_city.get_my_troop(v) or  {}
                node.arms = tr.arms
            end
            
            --table.insert(node.players, {monster_city = troop.mcid})
        elseif is_npc_city(v) then
            node.propid = v.propid
            if v.uid == 0 then
                local tr = v:get_my_troop() or {}
                node.arms = tr.arms
            end
            if k == 2 then
                node.coming_hold_tr = coming_hold_tr(v)
                add_hold_ply(node.players, node.coming_hold_tr)
            end
        end

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

        --dumpTab(msg_send, "union_battle_room_info")
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

    for k, v in pairs(tm_heros or {}) do
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
    unit.count = total
    return unit
end

function union_aid_recall( self, pid )
    local dest = getPlayer( pid )
    if not dest then return end
    if dest == self then return end

    local flag = false
    local troop = self:get_my_troop()
    if troop then
        if troop.arms and troop.arms[ pid ] then
            dest:troop_recall( troop._id )
            flag = true
        end
    end

    local comings = self.troop_comings
    if comings then
        for tid, action in pairs( comings ) do
            if action == TroopAction.SupportArm then
                local troop = troop_mng.get_troop( tid )
                if troop and troop.owner_pid == pid then
                    dest:troop_recall( tid )
                    flag = true
                end
            end
        end
    end
    if flag then Rpc:aid_notify( self ) end
end


function get_aid_info( self )
    local info = {}
    local troop = self:get_my_troop()
    if troop then
        for pid, arm in pairs( troop.arms or {} ) do
            if pid ~= self.pid then
                local t = get_arm_info( pid, troop )
                if t then table.insert( info, t ) end
            end
        end
    end

    local comings = self.troop_comings
    if comings then
        for tid, action in pairs( comings ) do
            if action == TroopAction.SupportArm then
                local troop = troop_mng.get_troop( tid )
                if troop then
                    for pid, arm in pairs( troop.arms or {} ) do
                        if pid ~= self.pid then
                            local t = get_arm_info( pid, troop )
                            if t then table.insert( info, t ) end
                        end
                    end
                end
            end
        end
    end
    return info
end

function get_arm_info(pid, troop)
    if pid >= 10000 then
        local arm = troop.arms and troop.arms[ pid ]
        if not arm then return end
        local t = {}

        local p = getPlayer(pid)
        t.pid = p.pid
        t.name = p.name
        t.photo = p.photo

        t.heros = {}
        t.heros_lv = {}
        t.heros_star = {}
        t.heros_hp = {}

        local heros = arm.heros
        if troop.action == TroopAction.DefultFollow and pid == troop.owner_pid then heros = p:get_defense_heros() end
        for _, hid in pairs(heros) do
            if hid ~= 0 then
                local h = heromng.get_hero_by_uniq_id(hid)
                if h then
                    table.insert(t.heros, h.propid)
                    table.insert(t.heros_lv, h.lv)
                    table.insert(t.heros_star, h.star)
                    table.insert(t.heros_hp, h.hp)
                end
            end
        end

        t.soldier = {}
        local total = 0
        for id, num in pairs(arm.live_soldier or {}) do
            table.insert(t.soldier, {id=id, num=num})
            total = total + num
        end
        t.count = total

        t._id = troop._id
        t.tmStart = troop.tmStart
        t.tmOver = troop.tmOver
        t.action = troop.action
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

    if is_npc_city(D) then
        D:get_my_troop()
    end

    for k, v in ipairs({A, D}) do
        local node = info[ k ]
        node.eid = v.eid
        node.class = get_type(v.eid)
        if k == 1 then node.troop_id = room._id
        else node.troop_id = D.my_troop_id or 0 end

        node.uid = v.uid
        node.owner_eid = v.eid
        node.players = {}
        node.action = troop.action
        if is_npc_city(v) then
            node.propid = v.propid
        end

        if k == 1 then
            node.x = troop.sx
            node.y = troop.sy
            node.count_max = A:get_val( "CountRallySoldier" )
            node.count_cur = A:get_mass_count( troop )
        else
            node.x = atk.dx
            node.y = atk.dy
            if is_npc_city(v) then
                local num, max = npc_city.hold_limit(v)
                node.count_cur = num
                node.count_max = max
            end
        end

        local troop = troop_mng.get_troop(node.troop_id)
        if troop then
            node.action = troop.action
            if k == 1 then
                node.x = troop.sx
                node.y = troop.sy
                node.count_max = A:get_val( "CountRallySoldier" )
                node.count_cur = A:get_mass_count( troop )
            else
                node.x = atk.dx
                node.y = atk.dy
                if is_ply(D) then
                    node.count_max = D:get_val( "CountRelief" )
                    node.count_cur = D:get_aid_count()
                end
            end

            for pid, arm in pairs(troop.arms) do
                if pid >= 10000 then
                    local t = get_arm_info(pid, troop)
                    if t then
                        t.tmStart = 0
                        t.tmOver = 0
                        t.tid = troop._id
                        if pid == troop.owner_pid then table.insert(node.players, 1, t)
                        else table.insert(node.players, t) end
                    end
                else
                    table.insert(node.players, {monster=v.propid, total_soldier=0, arm = arm})
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
        elseif not is_ply( v ) then
            node.action = TroopAction.DefultFollow
            node.x = atk.dx
            node.y = atk.dy
        end
        if is_monster(v) then
            node.monster = v.propid
            table.insert( node.players, { monster = v.propid, hp = v.hp } )
        elseif is_king_city(v) then
            node.propid = v.propid
            local tr = v:get_my_troop()
            node.arms = tr.arms
        elseif is_lost_temple(v) then
            node.propid = v.propid
            local tr = v:get_my_troop()
            node.arms = tr.arms
        elseif is_monster_city(v) then
            if k == 1 then
                node.monster_city = troop.mcid
            elseif k == 2 then
                node.monster_city = v.propid
                local tr = monster_city.get_my_troop(v)
                node.arms = tr.arms
            end
            --table.insert(node.players, {monster_city = troop.mcid})
        elseif is_npc_city(v) then
            node.propid = v.propid
            local tr = v:get_my_troop()
            node.arms = tr.arms
        end
    end
    --dumpTab( info, "do_battle_room_detail" )
    room.detail = info
    return info
end

--function get_battle_room_detail(self, troop_id)
--    local troop = troop_mng.get_troop(troop_id)
--    if troop == nil then return nil end
--
--    local unit = {}
--    local union = unionmng.get_union(troop.owner_uid)
--    if union  then
--        unit.name = union.name
--        unit.alias = union.alias
--    end
--
--    unit.troop_id = troop_id
--    unit.uid = troop.owner_uid
--    unit.owner_eid = troop.owner_eid
--    unit.players = {}
--
--    --找出加入这个军队的玩家
--    for k, v in pairs(troop.arms) do
--        local single = self:fill_player_info_by_arm(v, troop.action, troop.owner_pid)
--        if single then
--            single.tmStart = 0
--            single.tmOver = 0
--            single.tid = troop._id
--            table.insert(unit.players, single)
--        end
--    end
--    for k, v in pairs(troop.mark_troop_ids or {}) do
--        local tm_troop = troop_mng.get_troop(v)
--        if tm_troop ~= nil then
--            local single = self:fill_player_info_by_arm(tm_troop:get_arm_by_pid(tm_troop.owner_pid), tm_troop.action, tm_troop.owner_pid)
--            if single then
--                single.tmStart = tm_troop.tmStart
--                single.tmOver = tm_troop.tmOver
--                single.tid = tm_troop._id
--                table.insert(unit.players, single)
--            end
--        end
--    end
--    return unit
--end
--

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
    --dumpTab(info, "battle_room_detail")

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

    --dumpTab( msg_send, "union_battle_room_detail" )
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

function get_union( self )
    return unionmng.get_union( self.uid )
end

function date_add(ply, what)--加日清记录
    if can_date(ply._union.date.tm)  then
        ply._union.date.tm = gTime
        ply._union.date.val = {}
    end

    local sum = ply:get_date(what)
    if what== "build" then --建筑
        if sum < 5 then
            ply._union.date.val[what] = (ply._union.date.val[what] or 0)  + 1
            ply:add_donate(100, VALUE_CHANGE_REASON.REASON_UNION_BUILD)
            Rpc:tips(ply, 1,resmng.UNION_DONATE_BUILD_OK,{(sum+1)})
        else
            Rpc:tips(ply, 1,resmng.UNION_DONATE_BUILD_ERR,{})
        end
    elseif what== "aid" then --援助
        if sum < 5 then
            ply._union.date.val[what] = (ply._union.date.val[what] or 0)  + 1
            ply:add_donate(100, VALUE_CHANGE_REASON.REASON_UNION_AID)
            Rpc:tips(ply, 1,resmng.UNION_DONATE_AID_OK,{(sum+1)})
        else
            Rpc:tips(ply, 1,resmng.UNION_DONATE_AID_ERR,{})
        end
    end
    gPendingSave.union_member[ply.pid].date = ply._union.date
end

function get_date(ply, what)--获取日清记录
    return (ply._union.date.val[what] or 0)
end

function add_donate(self, val, reason)
    local union = unionmng.get_union(self:get_uid())
    if not union then
        WARN("没有军团:"..self:get_uid())
        return
    end
    local award = {{"res", resmng.DEF_RES_PERSONALHONOR, val, 10000}}
    self:add_bonus("mutex_award", award, reason)
end

function get_castle_ef(ply)--奇迹buf
    local e = get_ety(ply.ef_eid)
    if not e then
        return {}
    end
    local c = resmng.get_conf("prop_world_unit", e.propid)
    local ef = {}
    if c.Mode == resmng.CLASS_UNION_BUILD_CASTLE or c.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE then
        if e.uid == ply.uid then
            ef = c.Buff1
        else
            ef = c.Buff2
        end
    end
    return ef
end



