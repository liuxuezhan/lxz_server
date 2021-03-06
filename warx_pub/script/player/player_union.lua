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
    pause()
    local union = unionmng.get_union(uid)

    local result = {
        uid = uid,
        key = what,
        val = {},
    }
    if not union then
        --nil
    elseif what == "mars" then --膜拜
        local god = union:get_god()
        result.val = {mars=god,log = self._union.god_log,}
    elseif what == "donate" then
        if can_date(self._union.CD_doante_tm,gTime)  then self._union.CD_donate_num  = 0 end
        result.val = {donate=self._union.donate,tmOver=self._union.tmDonate,CD_num = self._union.CD_donate_num or 0, flag=union_member_t.get_donate_flag(self)}
    elseif union.map_id then -- cross gs
        remote_union_select(union, self, uid, what)
        return
    elseif what == "info" then
        result.val = union:get_info()
    elseif what == "member" then
        if not union.map_id then
            local _members = union:get_members()
            local tmp = {}
            for _, A in pairs(_members or {}) do
                --if A.uid == uid then
                --    if A._union.rank == resmng.UNION_RANK_0 then
                --        A._union.rank = resmng.UNION_RANK_1
                --    end
                --    table.insert(tmp,player_t.get_union_info(A))
                --end
                if not R0  and player_t.get_rank(A) == resmng.UNION_RANK_0 then

                else
                    table.insert(tmp,player_t.get_union_info(A))
                end
            end
            if tmp then
                result.val = tmp
            end
            Rpc:union_member_get(self, union.uid, tmp )
        else
            local map_id = union.map_id
            local func = "get_remote_member_info"
            local param = {"union", union.uid, R0}
            local ret, val =  remote_func(map_id, func, param)
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
            local ret, val =  remote_func(map_id, func, param)
            if val then
                result.val = val
            end
        end
    elseif what == "apply" then
        local info = {}
        if union_t.is_legal(self, "Invite") then
            for k, v in pairs(union.applys) do
                local p1  = getPlayer(v.pid)
                if p1 then
                    if gTime > v.tm + 60*60*24*2 or p1.uid ~= 0 then
                        union:remove_apply( v.pid)
                    else
                        local data = p1:get_union_info()
                        data.rank = 0
                        table.insert(info, data)
                    end
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
        local _tech = union:get_tech()
        for _, v in pairs(_tech or {}) do
            table.insert(l,v)
        end
        result.val = {info=l, mark=union.tech_mark}
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
        --result.log = self._union.word or {} 
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

function union_search(p, what)
    local d = {}
    local d2 = {}
    local num = 50
    local u = unionmng.get_union(p:get_uid())
    if not u then  return end

    if what ~= "" then
        local c = (resmng.prop_language_cfg[p.language] or {}).Limit
        local code = check_name_avalible( what,c )
        if code ~= true then return end
        if is_sys_name( what ) then return end

        for _,v in pairs(gPlys or {} ) do
            if v.pid >= 10000 and string.find(v.name,what) and (v.uid == 0)and (not u:get_invite(v.pid)) 
                and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                if  num > 0 then
                    d[v.pid]={pid=v.pid,name=v.name,language=v.language,photo=v.photo,uid=v.uid, pow=v:get_pow(), nation = v.nation}
                    num = num - 1
                else 
                    break 
                end
            end
        end
    else
        for _,v in pairs(gPlys or {}) do
            if v.pid >= 10000 and v.uid==0 and (not u:get_invite(v.pid)) 
                and (not u:has_member(v)) and (not u:get_apply(v.pid)) then
                if p.language==v.language and v:is_online() then
                    d[v.pid]={pid=v.pid,online = 1,name=v.name,language=v.language,photo=v.photo, pow=v:get_pow(), nation = v.nation}
                    num = num - 1
                    if num == 0  then break end
                else 
                    d2[v.pid] = v  
                end
            end
        end

        if num > 0 then
            for _,v in pairs(d2 or {})  do
                local online = 0 
                if v:is_online() then online = 1 end
                d[v.pid]={pid=v.pid,online=online,name=v.name,language=v.language,photo=v.photo, pow=v:get_pow(), nation = v.nation}
                num = num - 1
                if num == 0 then break end
            end
        end
    end
    Rpc:union_search(p,what,d)
end

function union_relation_set(self,uid,val)
    if not check_union_cross(uid) then
        union_relation.set(self,uid,val)
    else
        ack(self, "union_relation_set", resmng.E_DISALLOWED) return
    end
end

function get_build_list(union)
    local l = {}
    if union then
        local build = union:get_build()
        for _, t in pairs(build or {}) do
            if is_union_restore(t.propid) then
                local flag = 0
                local mems = union:get_members()
                for _, p in pairs( mems or {} ) do
                    local node = p._union and p._union.restore_sum
                    if node then
                        for mode, num in pairs( node ) do
                            if num > 0 then flag = 1 break end
                        end
                    end
                end
                t.ga_state = flag

            elseif is_union_superres( t.propid ) and t.state == BUILD_STATE.WAIT then
                t.ga_state = 0
                if type( t.my_troop_id ) == "number" then
                    if troop_mng.get_troop( t.my_troop_id ) then t.my_troop_id = { t.my_troop_id }
                    else t.my_troop_id = {} end
                end
                for _, tid in pairs( t.my_troop_id ) do
                    if troop_mng.get_troop( tid ) then
                        t.ga_state = 1
                        break
                    end
                end
            else
                if troop_mng.get_troop( t.my_troop_id ) then t.ga_state = 1
                else t.ga_state = 0 end
            end
            table.insert(l,t)
        end
    end
    return l
end

function union_create(p, name, alias, language, mars)
    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    if not is_inputlen_avaliable(name,(c or {})[CHA_LIMIT.Union_Name]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_create name is limit", p.pid,p.uid )
        return 
    end 
    if not is_inputlen_avaliable(alias,(c or {})[CHA_LIMIT.Union_Alias]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_create alias is limit", p.pid,p.uid )
        return 
    end 

    if check_ply_cross(p) then
        ack(p, "union_create", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(p, "Create") then
        ack(p, "union_create", resmng.E_DISALLOWED) return
    end

    if not p:condCheck(CREATEUNION.condition) then
        ack(p, "union_create", resmng.E_CONDITION_FAIL) return
    end
    
    if string.len(alias) > 3 then return end 

    for _, v in pairs(unionmng.get_all()) do
        if v.name == name then
            ack(p, "union_create", resmng.E_DUP_NAME) return
        end
        if v.alias == alias then
            ack(p, "union_create", resmng.E_DUP_ALIAS) return
        end
    end

    local num = resmng.CREATEUNION.cost2
    if p:get_castle_lv() < resmng.CREATEUNION.lv   then
       num = resmng.CREATEUNION.cost1
    end

    local code = want_insert_unique_name( "name_union", name, { pid=p.pid, account=p.account, map=gMapID, time=gTime, alias=alias, action="create"} )
    if code ~= 0 then
        ack(p, "union_create", resmng.E_DUP_NAME) return
    end

    if not p:do_dec_res(resmng.DEF_RES_GOLD, num, VALUE_CHANGE_REASON.UNION_CREATE ) then
        return
    end


    local u = union_t.create(p, name, alias, language, mars)

    -- register u chat room
    --create_chat_room(u)

    Rpc:tips({pid=-1,gid=_G.GateSid}, 2,resmng.NOTIFY_UNION_CREATE,{p.name,u.language,u.name,u.alias})
    Rpc:union_on_create(p, u:get_info())
    --任务
    --task_logic_t.process_task(p, TASK_ACTION.JOIN_PLAYER_UNION)

    p.uname = alias
    etypipe.add(p)
    --p:tlog_ten2("GuildFlow",p.vip_lv,1,u.uid,0,u.membercount)
end
-- 创建聊天room
function create_chat_room(union)
    to_tool(0, {url = config.Chat_url or CHAT_URL, type = "chat", cmd = "create_room", name = tostring(union.uid), server ="conference."..CHAT_HOST, host = CHAT_HOST })
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
        rank_mng.update_info_union( self.uid )
    end
    if union_t.is_legal(self, "ChgAlias") and info.alias then
        u.alias = info.alias
        rank_mng.update_info_union( self.uid )
    end
    if union_t.is_legal(self, "ChgFlag") and info.flag then
        local c = resmng.get_conf("prop_flag",info.flag)
        if c and c.Price and self:do_dec_res(resmng.DEF_RES_GOLD, c.Price, VALUE_CHANGE_REASON.UNION_FLAG) then
            u.flag = info.flag
            rank_mng.update_info_union( self.uid )
            npc_city.reset_map_pack()
            for _, v in pairs(u.declare_wars or {}) do
                local city = get_ety(v)
                if city then
                    npc_city.format_union(city)
                    etypipe.add(city)
                end
            end
            for _, v in pairs(u.npc_citys or {}) do
                local city = get_ety(v)
                if city then
                    npc_city.format_union(city)
                    etypipe.add(city)
                end
            end
            for _, v in pairs(u._members) do
                v.uflag = u.flag
                etypipe.add(v)
            end

            local bs = u:get_build()
            for _, v in pairs( bs ) do
                if v.state ~= BUILD_STATE.DESTROY then
                    etypipe.add( v )
                end
            end
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
        rank_mng.update_info_union( self.uid )

        player_t.pre_tlog(nil,"UnionList",u.uid,u.name,u.language,1,
            tostring(u.mc_start_time[1]),u.membercount,u.activity or 0 ) 
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
    if B:get_cross_state() ~= PLAYER_CROSS_STATE.IN_LOCAL_SERVER then
        ack(self, "union_rm_member", resmng.E_DISALLOWED)
        return
    end

    local union = unionmng.get_union(self:get_uid())
    if (not union) or union:is_new() then
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
    if B:get_cross_state() ~= PLAYER_CROSS_STATE.IN_LOCAL_SERVER then
        ack(self, "union_add_member", resmng.E_DISALLOWED)
        return
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
        INFO("[UNION] not apply,pid=%d,uid=%d",pid,u.uid)
        return
    end

    u:remove_apply(pid)
    u:add_member(B,self)
end

function union_apply(self, uid)

    if check_ply_cross(self) then
        ack(self, "union_apply", resmng.E_DISALLOWED) return
    end

    --[[
    if #self.busy_troop_ids > 0 then
        WARN("有troop") return
    end
    --]]

    local old_union = unionmng.get_union(self:get_uid())
    if old_union and not union_t.is_legal(self, "Join") then
       INFO("[UNION] union_apply in union pid= %d,uid=%d",self.pid,uid) 
       return
    end

    local u = unionmng.get_union(uid)
    if not u then 
       INFO("[UNION] union_apply not union pid= %d,uid=%d",self.pid,uid) 
       return 
    end

    if not self:union_enlist_check(uid) then return end
    if self.uid ~= 0  then return end

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
    self:deal_quit_for_hero_task()
    ack(self, "union_quit", ret)
end

function union_reject(self, pid)

    if check_ply_cross(self) then
        ack(self, "union_reject", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        INFO("[UNION] union_reject pid=%d not pid= %d",self.pid,pid) 
        return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        INFO("[UNION] union_reject pid=%d not uid= %d",self.pid,self.uid) 
        return
    end

    local ret = union:reject_apply(self, B)
    if ret == resmng.E_OK then
        Rpc:union_reply(B, union.uid,union.name, resmng.UNION_STATE.NONE)
    end
end

function union_enlist_set(p, check,text,lv,pow)

    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    if not is_inputlen_avaliable(text,(c or {})[CHA_LIMIT.Union_Recruit]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_enlist_set text is limit", p.pid,p.uid )
        return 
    end 

    if check_ply_cross(p) then
        ack(p, "union_enlist_set", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(p:get_uid())
    u.enlist = {check = check ,text=text,lv=lv, pow=pow}
end

function union_enlist_check(self, uid)
    local u = unionmng.get_union(uid)

    local lv = self:get_castle_lv(self)

    if lv < u.enlist.lv then
        INFO("[UNION] union_enlist_check lv pid=%d,uid=%uid",self.pid,self.uid)
        return false
    end

    local p = self:get_pow()
    if p < u.enlist.pow then
        INFO("[UNION] union_enlist_check pow pid=%d,uid=%uid",self.pid,self.uid)
        return false
    end

    return true
end

function sort_info(self,u)
    if u then
        local info  = u:get_info()
        info.state = resmng.UNION_STATE.NONE
        if info.uid == self:get_uid() then
            info.state = resmng.UNION_STATE.IN_UNION
        elseif u:get_apply(self.pid) then
            info.state = resmng.UNION_STATE.APPLYING
        end
        return info
    end
end

function union_first_item(p)
    local c = {}
    if not next(p._union.history) then
        c = resmng.get_conf("prop_mail",10082) or {}
    end
    Rpc:union_first_item(p, c.AddBonus or {} )
end

function union_list(p,name)

    if check_ply_cross(p) then
        local u = unionmng.get_union(p.uid)
        if u then
            remote_cast(u.map_id, "union_list", {"player", p.pid, name})
            return
        end
    end
    local max = 100

    local ret = {name = name,list={}}
    if name ~= "" then
        local c = (resmng.prop_language_cfg[p.language] or {}).Limit
        local code = check_name_avalible( name,c )
        if code ~= true then return end
        if is_sys_name( name ) then return end

        for _, u in pairs( unionmng._us or {}  ) do
            if u and not check_union_cross(u) and u:check() and string.find(u.name,name) then
                local info = sort_info(p,u)
                if info then 
                    ret.list[u.uid]=info 
                    max = max - 1
                end
                if 0 == max  then break end
            end
        end

        if max > 0 then
            for _, u in pairs( unionmng._us or {}  ) do
                if u and not check_union_cross(u) and u:check() and string.find(u.alias,name) then
                    local info = sort_info(p,u)
                    if info then 
                        ret.list[u.uid]=info 
                        max = max - 1
                    end
                    if 0 == max  then break end
                end
            end
        end
        
    else
        local us = rank_mng.get_range(5,1,max)
        local num = 0
        for k, uid in pairs( us or {}  ) do
            local u = unionmng.get_union(uid)
            if u and not check_union_cross(u) and u:check() and (not check_union_cross(u) )then
                if p:union_enlist_check(uid) then 
                    local info = sort_info(p,u)
                    if info then ret.list[u.uid]=info end
                    num = num -  1
                    if 0 == num  then break end
                end
            end
        end
        if num > 0  then
            local us = rank_mng.get_range(5,max+1,max+num)
            for k, uid in pairs( us or {}  ) do
                local u = unionmng.get_union(uid)
                if u and not check_union_cross(u) and u:check() and (not check_union_cross(u) )then
                    local info = sort_info(p,u)
                    if info then ret.list[u.uid]=info end
                    num = num -  1
                    if 0 == num  then break end
                end
            end
        end
    end

    --lxz(ret.list)
    Rpc:union_list(p,ret.name,ret.list)
end

function union_invite(self, pid)

    if check_ply_cross(self) then
        ack(self, "union_invite", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_invite", resmng.E_NO_PLAYER) return
    end
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_invite", resmng.E_NO_UNION) return
    end

    local ret = u:send_invite(self, B)
    B:send_system_union_invite(30001, self.pid, {uid=u.uid}, {self.name, u.alias, u.name})
    ack(self, "union_invite", ret)
end

function union_list2(p)
    local ret = p:union_hot() 
    if not next(ret) then return end
    local v = ret[1] or ret[2]
    if v then
        local leader = getPlayer(v.leader)
        if not leader then return end
        Rpc:union_list2(p, {uid= v.uid,alias=v.alias,name=v.name,leader=leader.name,})
    end
end

function union_hot(p)
    local u1,u3
    local us = rank_mng.get_range(5,1,20000)
    for k, uid in pairs( us or {}  ) do
        if uid == 0 then break end
        local u = unionmng.get_union(uid)
        if u and (not u:is_new()) and not check_union_cross(u) and u:check() then 
            if p.language == u.language then
                if not u1  and u.enlist.check == 0  then u1 = u end
            else
                if not u3  and u.enlist.check == 0  then u3 = u end
            end

            if u1 and u3 then break end
        end
    end
    return {u1,u3}
end

function union_invite_migrate(self,pids)

    if check_ply_cross(self) then
        ack(self, "union_invite_migrate", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then INFO("[UNION]union_invite_migrate pid=%d uid=%d",self.pid,self.uid) return end

    local x,y = self.x,self.y
    for _, v in pairs( u.build ) do
        if is_union_miracal_main(v.propid) then
            x,y=v.x,v.y
            break
        end
    end

    for _, pid in pairs(pids) do
        local p = getPlayer(pid)
        if p:get_cross_state() ~= PLAYER_CROSS_STATE.IN_OTHER_SERVER then
            if u:has_member(p) then
                p:send_system_city_move(20001, self.pid, {x=x, y=y}, {self.name})
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
        INFO("[Union]: acceptInvite, already in Union, player:%s, union:%s", self.pid, u.uid)
        return
    end
    if self:get_cross_state() ~= PLAYER_CROSS_STATE.IN_LOCAL_SERVER then
        ack(self, "union_accept_invite", resmng.E_DISALLOWED)
        return
    end

    u:remove_invite(self.pid)
    local ret = u:add_member(self,self) 
    if ret == -1 then Rpc:tips(self, 1,resmng.UNION_FIRST_TIPS_FULL ,{}) end
end

function union_reject_invite(self, uid)

    local u = unionmng.get_union(uid)
    if not u then
        ack(self, "union_reject_invite", resmng.E_NO_UNION) return
    end

    if u:has_member(self) then
        INFO("[Union]: RejectInvite, already in Union, player:%s, union:%s", self.pid, u.uid)
        return
    end

    u:remove_invite(self.pid) 
    for k, v in pairs(u.invites) do
        if v.pid == self.pid then
            u:remove_invite(k)
        end
    end
end

function union_member_rank(self, pid, r)

    if check_ply_cross(self) then ack(self, "union_member_rank", resmng.E_DISALLOWED) return end

    local B = getPlayer(pid)
    if not B then ack(self, "union_member_rank", resmng.E_NO_PLAYER) return end

    if B:get_cross_state() ~= PLAYER_CROSS_STATE.IN_LOCAL_SERVER then
        ack(self, "union_member_rank", resmng.E_DISALLOWED)
        return
    end

    local u = unionmng.get_union(self:get_uid())
    if (not u) or u:is_new() then ack(self, "union_member_rank", resmng.E_NO_UNION) return end

    if not u:has_member(self, B) then return  end

    if self:get_rank() > r and self:get_rank() > B:get_rank()  then
        B:set_rank(r)
    end
end

function union_member_title(p, pid, t)
    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    if not is_inputlen_avaliable(t,(c or {})[CHA_LIMIT.Union_Title_Grant]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_member_title text is limit", p.pid,p.uid )
        return 
    end
    if check_ply_cross(p) then
        ack(p, "union_member_title", resmng.E_DISALLOWED) return
    end

    local B = getPlayer(pid)
    if not B then
        ack(p, "union_member_title", resmng.E_NO_PLAYER) return
    end
    if B:get_cross_state() ~= PLAYER_CROSS_STATE.IN_LOCAL_SERVER then
        ack(p, "union_member_title", resmng.E_DISALLOWED)
        return
    end
    local u = unionmng.get_union(p:get_uid())
    if not u then
        ack(p, "union_member_title", resmng.E_NO_UNION) return
    end

    if not u:has_member(p, B) then return resmng.E_FAIL end

    if not union_t.is_legal(p, "MemMark") then
        INFO("[UNION] union_member_title legal pid=%d uid=%d",p.pid,p.uid)
        return
    end

    B._union.title = t
    gPendingSave.union_member[B.pid].title = B._union.title
    u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.TITLE, B:get_union_info())
    u:add_log(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.TITLE, {name=B.name, title=B._union.title} )
    return resmng.E_OK

end

function union_leader_auto(self )--自动移交军团长,返回是否删除军团

    if self:get_rank()~= resmng.UNION_RANK_5  then return false end

    local u = unionmng.get_union(self:get_uid())
    if not u then ack(self, "union_leader_update", resmng.E_NO_UNION) return end

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

    if pid == 0  then return true end

    local B = getPlayer(pid)
    if not B then
        INFO("[UNION] union_leader_auto pid=%d, uid=%d not pid=%d ",self.pid,self.uid,pid)
        return false
    end

    self:set_rank(resmng.UNION_RANK_4)
    B:set_rank(resmng.UNION_RANK_5)
    u.leader = pid
    rank_mng.update_info_union( u.uid )

    return false
end

function union_leader_update(self, pid)--手工移交军团长

    if check_ply_cross(self) then
        ack(self, "union_leader_update", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        INFO("[UNION] union_leader_update  pid=%d, uid=%d not union ",self.pid,self.uid)
        return
    end

    local leader = getPlayer(u.leader)
    if not leader then
        INFO("[UNION] union_leader_update  pid=%d, uid=%d not leader=%d ",self.pid,self.uid,u.leader)
        return
    end

    local B = getPlayer(pid)
    if not B then
        ack(self, "union_leader_update", resmng.E_NO_PLAYER) return
    end
    if B:get_cross_state() ~= PLAYER_CROSS_STATE.IN_LOCAL_SERVER then
        ack(self, "union_leader_update", resmng.E_DISALLOWED)
        return
    end

    if self:get_rank()== resmng.UNION_RANK_5 and B:get_rank()== resmng.UNION_RANK_4 and  u:has_member(B) then
        leader:set_rank(resmng.UNION_RANK_4)
        B:set_rank(resmng.UNION_RANK_5)
        u.leader = pid
        rank_mng.update_info_union( u.uid )
    end

    if u:has_member(B) and B:get_rank()== resmng.UNION_RANK_4 and  (not leader:is_online()) and leader.tm_logout + 5*24*60*60 <  gTime then
        if leader.pid ~= self.pid and  (not self:do_dec_res(resmng.DEF_RES_GOLD, 1000, VALUE_CHANGE_REASON.UNION_RANK )) then
            INFO("[UNION] union_leader_update  pid=%d, uid=%d not gold ",self.pid,self.uid)
            return
        end

        leader:set_rank(resmng.UNION_RANK_4)
        B:set_rank(resmng.UNION_RANK_5)
        u.leader = pid
        rank_mng.update_info_union( u.uid )
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

function union_troop_buf(p)

    if check_ply_cross(p) then
        ack(p, "union_troop_buf", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(p, "Global2") then return end
    local u = unionmng.get_union(p.uid)
    if not u then return end
    for _, v in pairs(u.buf or {}) do
        if v[1]==90001001 then return end
    end
    if not p:do_dec_res(resmng.DEF_RES_GOLD, 20000, VALUE_CHANGE_REASON.UNION_TASK) then
        return
    end
    u:add_buf(90001001,8*60*60)
    Rpc:tips({pid=-1,gid=_G.GateSid}, 2,resmng.UNION_ADD_BUF,{u.name})
    u:add_log(resmng.UNION_EVENT.BUFF_ALL,resmng.UNION_MODE.ADD,{ name=p.name, })
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
    local donate = union_tech_t.get_donate_cache(self,idx)
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
        remote_cast(self.emap, "union_tech_mark", {"player", self.pid, info})
        return
    end

    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_mark", resmng.E_NO_UNION) return
    end
    union:set_tech_mark(info)
end

function union_mall_add(self,propid,num)
    if check_ply_cross(self) then
        remote_cast(self.emap, "union_mall_add", {"player", self.pid, propid, num})
        return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then return end

    if not union_t.is_legal(self, "AddItem") then return end

    local c = resmng.get_conf("prop_union_mall",propid)
    if not c then return end

    local cc = resmng.get_conf("prop_union_tech",c.ConditionLv[2] )
    if u._tech[1005] then
        local cur = resmng.get_conf("prop_union_tech",u._tech[1005].id)
        if cur.Lv < cc.Lv then return end
    else
        if 0 < cc.Lv then return end
    end

    union_mall.add(self,propid,num)
end

function union_mall_mark(self,propid,flag)
    if check_ply_cross(self) then
        remote_cast(self.emap, "union_mall_mark", {"player", self.pid, propid, flag})
        return
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
        remote_cast(self.emap, "remote_union_mall_buy", {"player", self.pid, propid, num, self._union.donate})
        return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_mall_add", resmng.E_NO_UNION) return
    end

    union_mall.buy(self,propid,num)
    Rpc:union_donate_info(self, {donate=self._union.donate,CD_num = self._union.CD_donate_num, tmOver=self._union.tmDonate,flag=union_member_t.get_donate_flag(self)})
end

function remote_union_mall_buy(self, propid, num, donate)
    local u = unionmng.get_union(self:get_uid())
    if not u then
        ack(self, "union_mall_add", resmng.E_NO_UNION)
        return
    end

    self._union.donate = donate
    union_mall.buy(self, propid, num)
end

function deliver_union_mall_item(self, itemid, num, use_donate)
    self._union.donate = self._union.donate - use_donate
    gPendingSave.union_member[self.pid].donate = self._union.donate
    self:inc_item(itemid, num, VALUE_CHANGE_REASON.UNION_MALL)
end

function union_donate_clear(self)
    if check_ply_cross(self) then
        ack(self, "union_donate_clear", resmng.E_DISALLOWED)
        return
    end
    union_tech_t.clear_tmdonate(self)
    Rpc:union_donate_info(self, {donate=self._union.donate,tmOver=self._union.tmDonate,CD_num = self._union.CD_donate_num, flag=union_member_t.get_donate_flag(self)})
end

function union_donate(self, idx, mode)
    if check_ply_cross(self) then
        ack(self, "union_donate", resmng.E_DISALLOWED)
        return
    end
    if not union_tech_t.donate(self, idx, mode) then return end

    self:union_tech_info(idx)
    Rpc:union_donate_info(self, {donate=self._union.donate, tmOver=self._union.tmDonate, CD_num = self._union.CD_donate_num, flag=union_member_t.get_donate_flag(self)})
    --成就
    self:add_count(resmng.ACH_TASK_TECH_DONATE, 1)
    --任务
    task_logic_t.process_task(self, TASK_ACTION.UNION_TECH_DONATE, 1)

    ack(self, "union_donate", resmng.E_OK)
end


function union_tech_upgrade(self, idx)
    if check_ply_cross(self) then
        ack(self, "union_tech_upgrade", resmng.E_DISALLOWED)
        return
    end
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_tech_upgrade", resmng.E_NO_UNION) return
    end

    if not union_t.is_legal(self, "TechUp") then
        ack(self, "union_tech_upgrade", resmng.E_DISALLOWED) return
    end

    if union.map_id then
        local ret, val = remote_func(union.map_id, "remote_upgrade", {"union_tech", union.uid, idx})
        if val and val[1] then
            ack(self, "union_tech_upgrade", val[1])
        end
    else
        local ret = union_tech_t.upgrade(union,idx)
        ack(self, "union_tech_upgrade", ret)
    end
end

function union_donate_rank(self, what)

    local u = unionmng.get_union(self:get_uid())
    if not u then return end

    if check_union_cross(u) then
        remote_cast(u.map_id, "union_donate_rank", {"player", self.pid, what})
        return
    end

    Rpc:union_donate_rank(self, { what = what, val = u:get_donate_rank(what) or {} })
end

function union_ply_rank_req(self, mode)

    local u = unionmng.get_union(self:get_uid())
    if not u then 
        Rpc:union_ply_rank_ack(self, mode , {})
        return 
    end

    --if check_union_cross(u) then
    --    remote_cast(u.map_id, "union_donate_rank", {"player", self.pid, what})
    --    return
    --end

    local pack = u:get_ply_rank_in_u(mode)
    Rpc:union_ply_rank_ack(self, mode , pack or {})
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
    result.val = union:get_log_by_sn(sn,mode)
    Rpc:union_log(self, result)
end
--}}}

function union_set_note_in(p, what)

    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    if not is_inputlen_avaliable(what,(c or {})[CHA_LIMIT.Union_Notice]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_set_note_in what is limit", p.pid,p.uid )
        return 
    end

    if check_ply_cross(p) then
        ack(p, "union_set_note_in", resmng.E_DISALLOWED) return
    end

    local union = unionmng.get_union(p:get_uid())
    if not union then
        ack(p, "union_set_note_in", resmng.E_NO_UNION) return
    end

    union:set_note_in(p.pid,what)
end

function union_task_get(self )--发布悬赏任务
    local l = union_task.get( self:get_uid(), 0 )
    if l then
        Rpc:union_task_get(self,l)
    end
end

function union_mission_log(self,type,id )--获取定时任务日志
end

function union_mission_get(self )--获取定时任务
    local union = unionmng.get_union(self:get_uid())
    if not union then
        ack(self, "union_mission_get", resmng.E_NO_UNION) return
    end

    local info = copyTab(union_mission.get(union))
    --dumpTab(info, "union mission")
    info.cur_item = self._union.cur_item 
    info.tm_mission = self._union.tm_mission
    Rpc:union_mission_get(self,info)
end

function union_mission_add(self, idx )--领取奖励
    union_mission.add(self, idx)
end

function union_mission_update(self )--刷新定时任务
    if check_ply_cross(self) then
        ack(self, "union_mission_update", resmng.E_DISALLOWED) return
    end

    union_mission.update(self.uid,self)
end

function union_mission_chat(self )
    if check_ply_cross(self) then
        ack(self, "union_mission_chat", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "Mission") then
        return
    end
    union_mission.update_chat(self)
end

function union_mission_set(self,idx )--领取定时任务

    if check_ply_cross(self) then
        ack(self, "union_mission_set", resmng.E_DISALLOWED) return
    end

    local u = unionmng.get_union(self:get_uid())
    if not u then return end

    if not union_t.is_legal(self, "Mission") then return end

    if union_mission.set(self,idx) then
        Rpc:union_mission_set(self)
        union_mission_get(self )--获取定时任务
    end
end

function union_word_update(self,... )
    if check_ply_cross(self) then
        ack(self, "union_word_update", resmng.E_DISALLOWED) return
    end
    union_word.update(self.pid,...)
end

function union_word_del(self,... )
    if check_ply_cross(self) then
        ack(self, "union_word_del", resmng.E_DISALLOWED) return
    end
    union_word.del(...)
end

function union_task_add(self, type, eid, hero,task_num, mode, res,res_num, x, y  )--发布悬赏任务
    local union = unionmng.get_union(self:get_uid())
    if not union then return end

    if type == UNION_TASK.NPC  then eid = npc_city.have[eid] end

    local dp = get_ety(eid)
    if not dp then return end
    local ret = union_task.add(self,type,eid,hero,task_num,mode,res,res_num,x,y) 
    INFO( "[UNION] union_task_add pid=%d, uid=%d, ret = %d", self.pid, self.uid,ret )
    if 0 == ret then
        union:add_log(resmng.UNION_EVENT.TASK,resmng.UNION_MODE.ADD,{ name=self.name,type=type,mode=mode })
    end
end
--{{{ build

function union_buildlv_donate(self, mode)
    if check_ply_cross(self) then
        ack(self, "union_buildlv_donate", resmng.E_DISALLOWED)
        return
    end
    if union_buildlv.add_buildlv_donate(self,mode) then
        Rpc:union_buildlv_donate(self, union_buildlv.get_buildlv(self:get_uid(),mode))
    end
end

function union_build_setup(p, idx, propid, x, y,name)
    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    if not is_inputlen_avaliable(name,(c or {})[CHA_LIMIT.Union_Name_Fac]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_build name is limit", p.pid,p.uid )
        return 
    end
    if check_ply_cross(p) then
        ack(p, "union_build_setup", resmng.E_DISALLOWED) return
    end

    local u = p:union()
    if not u then return end

    if not union_t.is_legal(p, "BuildPlace") then return end

    local ret = union_build_t.create(p.uid, idx, propid, x, y,name)
    if ret then
      INFO( "[UNION] build pid=%d, uid=%d, propid=%d, x=%d, y = %d", p.pid, p.uid,propid,x,y )
    else
      Rpc:tips(p, 3,resmng.WORLDMAP_TIPS_QIJI_NOBUILDED ,{})
    end
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

    if e.state ~= BUILD_STATE.WAIT then return end

    if union_build_t.is_hp_full( e ) then
        if state ~= BUILD_STATE.UPGRADE then return end
    else
        if state ~= BUILD_STATE.FIX then return end
    end

    e.state = state

    if is_union_superres( e.propid ) then
        --todo
    end

    union_build_t.recalc_build( e )

    --local bcc = resmng.get_conf("prop_world_unit",e.propid) or {}
    --if not bcc then return false end

    --if is_union_superres(e.propid)  then     --采集返回
    --    return
    --end

    --union_build_t.mark(e)
    --save_ety(e)

end

function union_build_remove(self, eid)
    if check_ply_cross(self) then
        ack(self, "union_build_remove", resmng.E_DISALLOWED) return
    end

    if not union_t.is_legal(self, "BuildUp") then return end
    local u = unionmng.get_union(self:get_uid())
    if not u then return end

    local e = get_ety( eid )
    if not e then return end

    if e.uid ~= u.uid then return end

    if is_union_miracal( e.propid ) then
        if e.tmOver_f > gTime then return end
        for k, v in ipairs(u.battle_room_ids or {}) do
            local r = union_hall_t.get_battle_room(v)
            if r and r.def_eid == eid then
                Rpc:tips(self, 1,resmng.UNION_BUILD_IN_WAR ,{})
                return
            end
        end
    end
    u:add_log(resmng.UNION_EVENT.BUILD_SET, resmng.OPERATOR.DELETE, {name=self.name,eid_name=e.name, propid=e.propid })
    union_build_t.remove( e )
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

function coming_hold_tr(ety)
    local coming_hold_tr = {}
    local comings = ety.troop_comings or {}
    for tr_id, action in pairs(comings or {}) do
        local tr = troop_mng.get_troop(tr_id)
        if tr and action == TroopAction.HoldDefense or 
                action == TroopAction.HoldDefenseNPC or
                action == TroopAction.HoldDefenseKING or
                action == TroopAction.HoldDefenseLT 
            then
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

--function do_battle_room_title(room)
--    if room.title then return room.title end
--
--    local troop = troop_mng.get_troop(room._id)
--    if not troop then return nil end
--
--    local info = { {}, {} }
--    local A = get_ety(troop.owner_eid)
--    local D = get_ety(troop.target_eid)
--
--    for k, v in ipairs({A, D}) do
--        local node = info[ k ]
--        node.eid = v.eid
--        node.class = get_type(v.eid)
--        node.players = {}
--
--        if k == 2 then troop = get_home_troop( v ) end
--
--        if troop then
--            node.troop_id = troop._id
--            node.action = troop.action
--            node.arms = troop.arms
--        else
--            ndoe.troop_id = 0
--        end
--        node.propid = v.propid
--
--        if is_monster( v ) then
--            node.monster = v.propid
--            node.hp = v.hp
--        end
--
--        if is_monster_city(v) then
--            node.monster_city = v.propid
--        end
--
--        for pid, arm in pairs( troop.arms or {} ) do
--            if pid >= 10000 then
--                local p = getPlayer( pid )
--                if p then
--                    if pid == troop.owner_pid then
--                        table.insert(node.players, 1, { name=p.name, photo=p.photo, pid=p.pid} )
--                    else
--                        table.insert(node.players, { name=p.name, photo=p.photo, pid=p.pid} )
--                    end
--                end
--            end
--        end
--
--        if k == 1 then
--            if is_ply( v ) then
--                node.count_max = v:get_val( "CountRallySoldier" )
--                node.count_cur = v:get_mass_count( troop )
--            end
--
--            if troop:is_ready() then
--                for tid, action in pairs( v.troop_comings or {} ) do
--                    local join = troop_mng.get_troop( tid )
--                    if join and join.dest_troop_id == troop._id and join:is_go() then
--                        local p = get_ety( join.owner_eid )
--                        if p and is_ply( p ) then
--                            table.insert(node.players, { name=p.name, photo=p.photo, pid=p.pid} )
--                        end
--                    end
--                end
--            end
--        else
--            node.coming_hold_tr = coming_hold_tr(v)
--            add_hold_ply(node.players, node.coming_hold_tr)
--        end
--
--        node.uid = v.uid
--        local union = unionmng.get_union(v.uid)
--        if union then
--            node.name = union.name
--            node.alias = union.alias
--        end
--    end
--    room.title = info
--    return info
--end

function get_name_info( ety )
    local info = {}
    info.propid = ety.propid
    info.eid = ety.eid
    local pid = ety.pid
    if pid and pid >= 10000 then
        local ply = getPlayer( pid )
        if ply then
            info.name = ply.name
            local union = ply:get_union()
            if union then
                info.uid = union.uid
                info.alias = union.alias
                info.flag = union.flag
            end
        end
    end

    local uid = ety.uid
    if uid and uid > 0 then
        local union = unionmng.get_union( uid )
        if union then
            info.uid = union.uid
            info.alias = union.alias
            info.flag = union.flag
        end
    end

    if ety.propid and is_union_miracal( ety.propid ) then
        info.name = ety.name
    end

    return info
end

function make_room_list( troop )
    local A = get_ety( troop.owner_eid )
    local D = get_ety( troop.target_eid )
    if A and D then
        local info = {}
        info.id = troop._id
        info.action = troop.action
        info.is_mass = troop.is_mass
        info.list = {}
        info.list.ack = get_name_info( A )
        info.list.def = get_name_info( D )
        info.pos = { {A.x, A.y }, {D.x, D.y} }

        if troop:get_base_action() == TroopAction.SiegeMonsterCity then
            info.list.ack.extra = troop.mcid
        end

        valid = true
        return info
    end
end

function union_battle_room_list(self)
    local union = unionmng.get_union(self.uid)
    if union == nil then return end

    if union.battle_list then
        Rpc:union_battle_room_list_resp(self, union.battle_list)
        return
    end

    local msg_send = {}
    local dels = {}
    for k, v in ipairs(union.battle_room_ids or {}) do
        local valid = false
        local room = union_hall_t.get_battle_room(v)
        if room ~= nil then
            local troop = troop_mng.get_troop( v )
            if troop then
                local info = make_room_list( troop )
                if info then
                    valid = true
                    table.insert( msg_send, info )
                end
            end
        end
        if not valid then table.insert( dels, 1, k ) end
    end

    for k, v in ipairs( dels ) do
        table.remove( union.battle_room_ids, v )
    end

    Rpc:union_battle_room_list_resp(self, msg_send)
    union.battle_list = msg_send
end


function union_battle_room_info(self, room_id)
    local room = union_hall_t.get_battle_room(room_id)
    if not room then return end

    local troop = troop_mng.get_troop(room_id)
    if not troop then return end

    local action = troop.action % 100

    local A = get_ety( troop.owner_eid )
    local D = get_ety( troop.target_eid )
    if A and D then
        local info = {}
        info.id = room_id
        info.tmStart = troop.tmStart
        info.tmOver = troop.tmOver
        info.pos = { { A.x, A.y }, { D.x, D.y } }
        info.ack = {}
        info.def = {}
        local tid = troop._id

        local count = 0
        for pid, arm in pairs( troop.arms or {} ) do
            if pid >= 10000 then
                local ply = getPlayer( pid )
                if ply then
                    if pid == troop.owner_pid then
                        table.insert( info.ack, 1, { propid=ply.propid, pid=ply.pid, photo=ply.photo, tid=tid } )
                    else
                        table.insert( info.ack, { propid=ply.propid, pid=ply.pid, photo=ply.photo, tid=tid } )
                    end
                end
                for _, v in pairs( arm.live_soldier or {} ) do count = count + v end
            else
                table.insert( info.ack, { propid=A.propid, tid=tid } )
                if action == TroopAction.SiegeMonsterCity then
                    local mcid = troop.mcid
                    local conf = resmng.get_conf( "prop_monster_city", mcid )
                    if conf then
                        for _, v in pairs( conf.Arms or {} ) do
                            count = count + v[1][2]
                        end
                    end

                elseif action == TroopAction.MonsterAtkPly then
                    local conf = resmng.get_conf( "prop_world_unit", A.propid ) 
                    if conf then
                        for _, v in pairs( conf.Arms or {} ) do
                            count = count + v[1][2]
                        end
                    end
                end
                break
            end
        end

        for tid, action in pairs( A.troop_comings or {} ) do
            if action == TroopAction.JoinMass then
                local join = troop_mng.get_troop( tid )
                if join and join:is_go() and join.dest_troop_id == troop._id then
                    if join.owner_pid >= 10000 then
                        local ply = getPlayer( join.owner_pid )
                        if ply then
                            table.insert( info.ack, { propid=ply.propid, pid=ply.pid, photo=ply.photo, tid=tid } )
                        end
                        for pid, arm in pairs( join.arms or {} ) do
                            for _, v in pairs( arm.live_soldier or {} ) do count = count + v end
                        end
                    end
                end
            end
        end

        if is_ply(A) then
            info.count_atk = { count, A:get_val( "CountRallySoldier" ) }
        else
            info.count_atk = { count, 0 }
        end

        count=0
        local troopD = get_home_troop( D )
        if troopD then
            local tid = troopD._id
            for pid, arm in pairs( troopD.arms or {} ) do
                for k, v in pairs( arm.live_soldier or {} ) do
                    if not (action == TroopAction.SiegePlayer and pid == troopD.owner_pid) then
                        count = count + v
                    end
                end

                if pid >= 10000 then
                    local ply = getPlayer( pid )
                    if ply then
                        if pid == troopD.owner_pid then
                            table.insert( info.def, 1, { propid=ply.propid, pid=ply.pid, photo=ply.photo, tid=tid } )
                        else
                            table.insert( info.def, { propid=ply.propid, pid=ply.pid, photo=ply.photo, tid=tid } )
                        end
                    end
                else
                    table.insert( info.def, { propid=D.propid, tid=tid } )
                    if is_monster( D ) then
                        local conf = resmng.get_conf( "prop_world_unit", D.propid )
                        if conf then
                            for _, v in pairs( conf.Arms or {} ) do
                                count = count + v[2]
                            end
                            count = math.ceil( count * 0.01 * D.hp )
                        end
                    end
                    break
                end
            end
        end

        for tid, action in pairs( D.troop_comings or {} ) do
            if action == TroopAction.SupportArm or action == TroopAction.HoldDefense or action == TroopAction.HoldDefenseNPC or action == TroopAction.HoldDefenseKING or action == TroopAction.HoldDefenseLT then
                local join = troop_mng.get_troop( tid )
                if join and join:is_go() and join.target_eid == D.eid then
                    if join.owner_pid >= 10000 then
                        local ply = getPlayer( join.owner_pid )
                        if ply then
                            table.insert( info.def, { propid=ply.propid, pid=ply.pid, photo=ply.photo, tid=tid } )
                        end
                        for _, arm in pairs( join.arms or {} ) do
                            for _, v in pairs( arm.live_soldier or {} ) do count = count + v end
                        end
                    end
                end
            end
        end

        local count_max = 0
        if is_ply( D ) then
            count_max = D:get_val( "CountRelief" )
        elseif is_lost_temple(D) or is_npc_city(D) or is_king_city(D) then
            _, count_max = npc_city.hold_limit( D )
        elseif is_union_miracal( D.propid ) then
            count_max = union_build_t.get_hold_limit( D )
        end
        info.count_def = { count, count_max }

        Rpc:union_battle_room_info_resp(self, { id=room_id, action=troop.action, info=info} )
    end
end


function fill_player_info_by_arm(self, arm, troop_action, owner_pid)
    if arm == nil then return end
    if arm.pid < 10000 then return end
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
    unit.heros_maxhp = {}
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
                table.insert(unit.heros_maxhp, hero.max_hp)
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
        for _, hid in pairs(heros or {}) do
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

        t.tid = troop._id
        t.tmStart = troop.tmStart
        t.tmOver = troop.tmOver
        t.action = troop.action
        return t
    end
end


function get_troop_detail( troop )
    local infos = {}
    for pid, arm in pairs( troop.arms or {} ) do
        if pid >= 10000 then
            local ply = getPlayer( pid )
            if ply then
                local info = {}
                info.pid = pid
                info.name = ply.name
                info.tid = troop._id
                info.action = troop.action
                info.tmStart = troop.tmStart
                info.tmOver = troop.tmOver
                local soldier = {}
                for id, num in pairs( arm.live_soldier or {} ) do
                    table.insert( soldier, { id=id, num=num} )
                end
                info.soldier = soldier

                local hs
                if troop.action == TroopAction.DefultFollow and pid == troop.owner_pid then hs = ply:get_defense_heros()
                else hs = arm.heros end

                hs = hs or {0,0,0,0}

                info.heros = {0,0,0,0}
                info.heros_lv = {0,0,0,0}
                info.heros_star = {0,0,0,0}
                info.heros_hp = {0,0,0,0}
                info.heros_maxhp = {0,0,0,0}

                for mode = 1, 4, 1 do
                    local hid = hs[ mode ]
                    if hid ~= 0 then
                        local h = heromng.get_hero_by_uniq_id( hs[ mode ] )
                        if h then
                            info.heros[ mode ] = h.propid
                            info.heros_lv[ mode ] = h.lv
                            info.heros_star[ mode ] = h.star
                            info.heros_hp[ mode ] = h.hp
                            info.heros_maxhp[ mode ] = h.max_hp
                        end
                    end
                end
                --infos[ pid ] = info
                table.insert( infos, info )
            end
        else
            local owner = get_ety( troop.owner_eid )
            if owner then
                if is_monster_city( owner ) then
                    local info = { pid=0 }
                    local soldier = {}
                    for id, num in pairs( arm.live_soldier or {} ) do
                        table.insert( soldier, { id=id, num=num} )
                    end
                    info.soldier = soldier
                    info.heros = arm.heros or {}
                    --infos[ 0 ] = info
                    table.insert( infos, info )

                elseif is_monster( owner ) then
                    --infos[ 0 ] = { hp = owner.hp }
                    table.insert( infos, { pid=0, hp=owner.hp } )
                end
            end
            break
        end
    end
    return infos
end


function union_battle_room_detail(self, room_id)
    local room = union_hall_t.get_battle_room(room_id)
    if room == nil or room.is_mass ~= 1 then return end

    local troop = troop_mng.get_troop(room_id)
    if not troop then return end

    local infoA = {}
    local armya = get_troop_detail( troop )
    infoA.troop_id = troop._id
    infoA.armys = armya

    local A = get_ety( troop.owner_eid )
    if A  then
        for tid, action in pairs( A.troop_comings or {} ) do
            if action == TroopAction.JoinMass then
                local join = troop_mng.get_troop( tid )
                if join and join:is_go() and join.dest_troop_id == troop._id then
                    local infos = get_troop_detail( join )
                    for _, info in pairs( infos or {} ) do
                        table.insert( armya, info )
                    end
                end
            end
        end
        infoA.count_max = A:get_val( "CountRallySoldier" )
    end

    local infoD = {}
    local D = get_ety( troop.target_eid )
    if D then
        local troopD = get_home_troop( D )
        if troopD then
            infoD.troop_id = troopD._id
            local armyb = get_troop_detail( troopD )
            infoD.armys = armyb
            for tid, action in pairs( D.troop_comings or {} ) do
                if action == TroopAction.SupportArm or action == TroopAction.HoldDefense or 
                action == TroopAction.HoldDefenseNPC or
                action == TroopAction.HoldDefenseKING or
                action == TroopAction.HoldDefenseLT 
                then
                    local join = troop_mng.get_troop( tid )
                    if join and join:is_go() and join.target_eid == D.eid then
                        local infos = get_troop_detail( join )
                        for _, info in pairs( infos or {} ) do
                            table.insert( armyb, info )
                        end
                    end
                end
            end
        end

        if is_lost_temple( D ) then
            _, infoD.count_max = npc_city.hold_limit( D )
        elseif is_npc_city( D ) then
            _, infoD.count_max = npc_city.hold_limit( D )
        elseif is_king_city( D ) then
            _, infoD.count_max = npc_city.hold_limit( D )
        elseif is_ply( D ) then
            infoD.count_max = D:get_val( "CountRelief" )
        elseif is_union_miracal( D.propid ) then
            infoD.count_max = union_build_t.get_hold_limit( D )

        end
    end

    Rpc:union_battle_room_detail_resp(self, { id=room_id, action=troop.action, detail={ ack=infoA, def=infoD } })
end

function union_battle_room_detail2(self, room_id)
    local room = union_hall_t.get_battle_room(room_id)
    if room == nil or room.is_mass ~= 1 then return end

    local troop = troop_mng.get_troop(room_id)
    if not troop then return end

    local infoA = get_troop_detail( troop )
    --infoA.troop_id = troop._id
    local A = get_ety( troop.owner_eid )
    if A  then
        for tid, action in pairs( A.troop_comings or {} ) do
            if action == TroopAction.JoinMass then
                local join = troop_mng.get_troop( tid )
                if join and join:is_go() and join.dest_troop_id == troop._id then
                    local infos = get_troop_detail( join )
                    --for pid, info in pairs( infos or {} ) do
                    --    infoA[ pid ] = info
                    --end
                    for _, info in pairs( infos or {} ) do
                        table.insert( infoA, info )
                    end
                end
            end
        end
        infoA.count_max = A:get_val( "CountRallySoldier" )
    end
    infoA.troop_id = troop._id

    local infoD = {}
    local D = get_ety( troop.target_eid )
    if D then
        local troopD = get_home_troop( D )
        if troopD then
            infoD = get_troop_detail( troopD )
            infoD.troop_id = troopD._id
            for tid, action in pairs( D.troop_comings or {} ) do
                if action == TroopAction.SupportArm or action == TroopAction.HoldDefense or 
                action == TroopAction.HoldDefenseNPC or
                action == TroopAction.HoldDefenseKING or
                action == TroopAction.HoldDefenseLT 
                    then
                    local join = troop_mng.get_troop( tid )
                    if join and join:is_go() and join.target_eid == D.eid then
                        local infos = get_troop_detail( join )
                        --for pid, info in pairs( infos or {} ) do
                        --    infoD[ pid ] = info
                        --end

                        for _, info in pairs( infos or {} ) do
                            table.insert( infoD, info )
                        end
                    end
                end
            end
            infoD.troop_id = troopD._id

            if is_lost_temple( D ) then
                _, infoD.count_max = npc_city.hold_limit( D )
            elseif is_npc_city( D ) then
                _, infoD.count_max = npc_city.hold_limit( D )
            elseif is_king_city( D ) then
                _, infoD.count_max = npc_city.hold_limit( D )
            elseif is_ply( D ) then
                infoD.count_max = D:get_val( "CountRelief" )
            end
        end
    end

    --dumpTab({ id=room_id, action=troop.action, detail={ ack=infoA, def=infoD } }, "battle_room_detail" )

    Rpc:union_battle_room_detail_resp(self, { id=room_id, action=troop.action, detail={ ack=infoA, def=infoD } })
end



function union_help_get(self )
    Rpc:union_help_get(self, union_help.get(self))
end

function union_help_get_detail(self )
    Rpc:union_help_get_detail(self, union_help.get_detail(self))
end

function union_help_add(self ,sn)
    union_help.add(self,sn)
end


function union_help_sets(self ,sns)
    union_help.sets(self,sns)
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

function union_word_add(p,uid,title,word,top)
    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    if not is_inputlen_avaliable(title,(c or {})[CHA_LIMIT.Union_Words_Topic]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_word title is limit", p.pid,uid )
        return 
    end 
    if not is_inputlen_avaliable(word,(c or {})[CHA_LIMIT.Union_Words_Content]) then 
        WARN( "[UNION]pid=%d,uid=%d,union_word word is limit", p.pid,uid )
        return 
    end 

    local d = union_word.add(p,uid,title,word)

    if top == 1 then
        d = union_word.top(p,d.wid,top)
        local ply = getPlayer(d.pid)
        if ply then d.name = ply.name end
    end
    Rpc:union_word_add(p, d)
end

function union_word_get(p,uid,wid)
    local u = unionmng.get_union(uid)
    if u then
        local d = union_word.get(p,u,wid)
        Rpc:union_word_get(p, d)
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
    if can_date(ply._union.date.tm,gTime)  then
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
    if not union then return end
    local award = {{"res", resmng.DEF_RES_PERSONALHONOR, val, 10000}}
    self:add_bonus("mutex_award", award, reason)
end

function get_castle_ef(ply)--奇迹buf
    local e = get_ety(ply.ef_eid)
    if not e then return {} end

    local ef = {}
    if is_union_miracal(e.propid) then
        local c = resmng.get_conf("prop_world_unit", e.propid)
        if e.uid == ply.uid then
            ef = c.Buff1
        else
            ef = c.Buff2
        end
    end
    return ef
end

function restore_add_res( ply, res )--存储资源
    local union = unionmng.get_union( ply.uid )
    if not union then return end

    local pid = ply.pid

    local ishold = union:is_restore_empty()

    local udata = ply._union
    if not udata then
        udata = union_member_t.create( ply, ply.uid, 1 )
    end

    if udata.uid ~= ply.uid then
        udata.uid = ply.uid
        udata.restore_sum = {}
        udata.restore_day = {}
        gPendingSave.union_member[ pid ].uid = ply.uid
    end

    local snode = udata.restore_sum
    if not snode then
        snode = {}
        udata.restore_sum = snode
    end

    local total = 0
    for mode, num in pairs( res or {} ) do
        num = math.floor( num )
        if num > 0 then
            snode[ mode ] = ( snode[ mode ] or 0 ) + num
            total = total + calc_res( mode, num )
        end
    end

    local dnode = udata.restore_day
    if not dnode then
        dnode = {0, 0}
        udata.restore_day = dnode
    end

    if can_date( dnode[ 1 ],gTime ) then
        dnode[1] = gTime
        dnode[2] = total
    else
        dnode[ 2 ] = dnode[ 2 ] + total
    end

    gPendingSave.union_member[ pid ].restore_sum = snode
    gPendingSave.union_member[ pid ].restore_day = dnode

    if not ishold and total > 0 then
        for _, v in pairs(union.build or {}) do
            if is_union_restore(v.propid) and v.state== BUILD_STATE.WAIT then--仓库
                v.holding = 1
                gPendingSave.union_build[ v._id ].holding = 1
                etypipe.add( v )
                union:notifyall("build", resmng.OPERATOR.UPDATE, v)
            end
        end
    end
end


function get_res_day( ply )
    local union = unionmng.get_union( ply.uid )
    if not union then return end

    local sum = 0
    local udata = ply._union
    if not udata then return 0 end

    local node = udata.restore_day
    if not node then return 0 end

    if can_date( node[ 1 ],gTime )  then return 0 end

    local sum = node[ 2 ] or 0
    for _, v in pairs(ply.busy_troop_ids) do
        local t  = troop_mng.get_troop(v)
        if t.action == resmng.TroopAction.SaveRes + 100  then
            for _, n in pairs( t.goods or {} ) do
                if n[1] == "res" then
                    sum = sum + calc_res( n[2], n[3] )
                end
            end
        end
    end
    return sum
end

function get_res_count( ply )--计算总存储量
    local union = unionmng.get_union( ply.uid )
    if not union then return end

    local sum = 0
    local udata = ply._union
    if not udata then return 0 end

    local node = udata.restore_sum
    if not node then return 0 end
    local sum = 0
    for mode, num in pairs( node ) do
        if num > 0 then
            sum = sum + calc_res( mode, num )
        end
    end

    for _, v in pairs(ply.busy_troop_ids) do
        local t  = troop_mng.get_troop(v)
        if t.action == resmng.TroopAction.SaveRes + 100  then
            for _, n in pairs( t.goods or {} ) do
                if n[1] == "res" then
                    sum = sum + calc_res( n[2], n[3] )
                end
            end
        end
    end
    return sum
end


function set_auto_mass( self, info )
    if next( info ) then
        rawset( self, "_auto_mass", info )
    else
        rawset( self, "_auto_mass", nil )
    end
end

function get_auto_mass( self )
    local u = unionmng.get_union( self.uid )
    if u then
        local infos = {}
        local _members = u:get_members()
        for pid, p in pairs( _members or {} ) do
            if p:is_online() then
                local info = rawget( p, "_auto_mass" ) 
                if info then
                    infos[ pid ] = info
                end
            end
        end
        Rpc:get_auto_mass( self, infos )
    end
end

function union_power_req(self)
    local u = unionmng.get_union( self.uid )
    if u then
        Rpc:union_power_ack(self, u:get_pow())
    end
end

