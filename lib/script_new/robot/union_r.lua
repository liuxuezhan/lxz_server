module("Ply")

function union_get(self,pack)
    --lxz(pack.key)
    local u = get_union(self,pack.uid)
    if not u then return end
    if pack.key == "info" then
    elseif pack.key == "ply" then
    elseif pack.key == "member" then
        for _, v in pairs( pack.val or {} ) do
            local t = rpchelper.decode_rpc(v,"unionmember")
            if not u.member then
                u.member = {}
            end
            u.member[t.pid] = t
        end
    elseif pack.key == "apply" then
    elseif pack.key == "mass" then
    elseif pack.key == "aid" then
    elseif pack.key == "tech" then
        _union[pack.uid].tech = pack.val.info 
    elseif pack.key == "donate" then
    elseif pack.key == "fight" then
    elseif pack.key == "build" then
        if pack.val then
            u.build = pack.val.build 
        end

        for k, v in pairs( u.build ) do
            Rpc:get_eye_info(self,v.eid)
            if v.state == BUILD_STATE.CREATE  then
                local  arm = {[1010]=100000,[2010]=100000,[3010]=100000,[4010]=100000,}
                Rpc:union_build(self, v.eid, {live_soldier=arm} )
            end
        end

        union_gather(self)
        union_restore(self)
        --lxz(u.uid,u.build)
    elseif pack.key == "mall" then
    elseif pack.key == "item" then
    elseif pack.key == "word" then
        u.word = pack.val
    elseif pack.key == "relation" then
    elseif pack.key == "mars" then
    elseif pack.key == "enlist" then
    elseif pack.key == "union_donate" then
        u.donate = pack.val 
    elseif pack.key == "ef" then
    end
end

function union_on_create(self,pack)
    self.uid = pack.uid
    local us = get_union(self)
    us[pack.uid] = pack
    Rpc:union_list(self,"")
end

function union_broadcast(self,what,mode,pack)
    if self.uid then
        Rpc:union_get(self,what,self.uid)
    end
end



function get_union(self,uid)
    if not _union then
        _union = {}
        Rpc:union_list(self,"")
    end
    if  uid then
        return _union[uid] 
    else
        return _union 
    end
end

function union_help_get(self,pack)
    Rpc:union_help_set(self,0)
end

function union_list(self,pack)
   -- lxz(pack)
    _union={}  
    for k, v in pairs( pack.list ) do
        _union[v.uid] = v
        Rpc:union_get(self,"info",v.uid)
        Rpc:union_get(self,"ply",v.uid)
        Rpc:union_get(self,"member",v.uid)
        Rpc:union_get(self,"apply",v.uid)
        Rpc:union_get(self,"mass",v.uid)
        Rpc:union_get(self,"aid",v.uid)
        Rpc:union_get(self,"tech",v.uid)
        Rpc:union_get(self,"donate",v.uid)
        Rpc:union_get(self,"build",v.uid)
        Rpc:union_get(self,"mall",v.uid)
        Rpc:union_get(self,"item",v.uid)
        Rpc:union_get(self,"word",v.uid)
        Rpc:union_get(self,"relation",v.uid)
        Rpc:union_get(self,"mars",v.uid)
        Rpc:union_get(self,"enlist",v.uid)
        Rpc:union_get(self,"union_donate",v.uid)
        Rpc:union_get(self,"ef",v.uid)
        Rpc:union_help_get(self)
    end
end

function union_plan(self,ps)
    union_add(self)
    for k, v in pairs( ps or {} ) do
        if k=="rank" then
            union_rank(self,v)
        elseif k=="help" then
            union_help(self,HELP_TYPE.CONSTRUCT)
        elseif k=="donate" then
            union_donate(self)
        elseif k=="build" then
            union_build(self,v)
        elseif k=="buildlv" then
            union_buildlv(self,v)
        elseif k=="word" then
            union_word(self)
        elseif k=="god" then
            union_god(self)
        elseif k=="fight" then
            union_fight(self,is_monster)
        end
    end
end

function union_add(self)

 --   if self.robot_id > 1000 then lxz(self.uid,self.robot_id) end
    if not self.uid then return end
    if self.uid < 10000 then 
        if self.robot_id % g_membercount == 1 then
            Rpc:union_quit(self)
            local name  = tostring(math.random(100,999) )
            Rpc:union_create(self,gName..name,name,40,1000)
            Rpc:union_list(self,"")
        else 
            for k, v in pairs( _union or {} ) do
                --lxz(v.name,gName,v.membercount)
                if string.find(v.name,gName) and v.membercount < g_membercount  then
                    Rpc:union_quit(self)
                    Rpc:union_apply(self,v.uid)
                    self.uid = v.uid
                    local leader = _ply[v.leader]
                    if leader then
                        --Rpc:request_empty_pos(self,leader.x,leader.y,2,{key="move"})
                    end
                    Rpc:union_list(self,"")
                    return
                end
            end
            Rpc:union_list(self,"")
        end
    end
end

function union_rank(self,r)
    local u = get_union(self,self.uid) 
    if not u  then
        lxz()
        return
    end
    if u.leader == self.name then
        for _, v in pairs( u.member or {} ) do
            Rpc:union_member_rank(self, v.pid, r)
        end
    end
end

function union_help(self,class)
    if self.union_help_num then
        return 
    end
    self.union_help_num = 1 
    if class == HELP_TYPE.HEAL then
        local f = do_task[TASK_ACTION.CURE] 
        f(self, v, 2, 0 ,0)
    elseif class == HELP_TYPE.CONSTRUCT then
        local cur,x = self:getBuildNum(1, 1)
        local f = funcAction.construct 
        f(self,1,1,1,x)
    elseif class == HELP_TYPE.UPGRADE then
        self:build_up(0,0,30,1,1)
    elseif class == HELP_TYPE.RESEARCH then
        tech(self,1001001,5,0)
    elseif class == HELP_TYPE.CAST then
        Rpc:equip_forge(self,6)
    end
end

function tech_exp_full(data)
    local conf = resmng.prop_union_tech[data.id+1]
    if conf then
        if data.exp >= conf.Exp * conf.Star then
            return true
        else
            return false
        end
    end
    return false
end

function union_donate(self)
    local u = get_union(self,self.uid) 
    if not u then return end
    for _, v in pairs( u.tech or {} ) do
        if tech_exp_full(v) then 
            Rpc:union_tech_upgrade(self,v.idx)
        else
            Rpc:union_donate_clear(self)
            Rpc:union_donate(self,v.idx,1)
            return
        end
    end
end

function union_build(self,propid)
    local u = get_union(self,self.uid) 
    if not u then return end
    local obj 
    if u.build and next(u.build) then
        for _, v in pairs( u.build or {} ) do
            local c = resmng.prop_world_unit[v.propid]
            if v.propid == propid then
                return 
            end
            if (c.Mode == resmng.CLASS_UNION_BUILD_CASTLE or c.Mode == resmng.CLASS_UNION_BUILD_MINI_CASTLE) and v.state == BUILD_STATE.WAIT  then
                obj = v
                break
            end
        end
    end

    if obj then
        Rpc:request_empty_pos(self,obj.x,obj.y,2,{key="build",propid =propid,idx = 0,name="test" })
    else
        Rpc:request_empty_pos(self,self.x,self.y,2,{key="build",propid =10001001,idx=0,name="test" })
    end

end

function union_buildlv(self,mode)
    --[[
    Rpc:chat(self, 0, "@additem=7001001=1000", 0 )
    Rpc:chat(self, 0, "@additem=7001002=1000", 0 )
    Rpc:chat(self, 0, "@additem=7001003=1000", 0 )

    Rpc:chat(self, 0, "@additem=7002001=1000", 0 )
    Rpc:chat(self, 0, "@additem=7002002=1000", 0 )
    Rpc:chat(self, 0, "@additem=7002003=1000", 0 )

    Rpc:chat(self, 0, "@additem=7003001=1000", 0 )
    Rpc:chat(self, 0, "@additem=7003002=1000", 0 )
    Rpc:chat(self, 0, "@additem=7003003=1000", 0 )

    Rpc:chat(self, 0, "@additem=7004001=1000", 0 )
    Rpc:chat(self, 0, "@additem=7004002=1000", 0 )
    Rpc:chat(self, 0, "@additem=7004003=1000", 0 )
    --]]

    Rpc:union_buildlv_donate(self,mode)
    local u = get_union(self,self.uid) 
    if not u then return end
    for _, v in pairs( u.build or {} ) do
        local c = resmng.prop_world_unit[v.propid]
        if c.BuildMode == mode  and v.state == BUILD_STATE.WAIT  then
            Rpc:union_build_up(self,v.idx,BUILD_STATE.UPGRADE)
            local  arm = {[1010]=100000,[2010]=100000,[3010]=100000,[4010]=100000,}
            Rpc:union_build(self, v.eid, {live_soldier=arm} )
            return 
        end
    end
end

function union_word(self,what)
    if not self.uid then return end
    local u = get_union(self,self.uid) 
    if not u then return end
    if u.word then
        for _, v in pairs( u.word or {} ) do
            Rpc:union_word_update(self,v.wid,"机器人测试1","hello word1"  )
            Rpc:union_word_top(self,v.wid,1 )
        end
    else
        Rpc:union_word_add(self,self.uid,"机器人测试","hello word"  )
    end
end

function union_god(self)
    Rpc:union_god_add(self,1 )
end

function union_gather(self)
    local u = get_union(self,self.uid) 
    if not u then return end
    local  arm = {live_soldier = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}}
    if u.build and next(u.build) then
        for _, v in pairs( u.build or {} ) do
            local c = resmng.prop_world_unit[v.propid]
            if c and c.BuildMode ==3  and v.state == BUILD_STATE.WAIT  then
                Rpc:gather(self,v.eid,arm)
                return 
            end
        end
        union_build(self,10007001)
    else
        union_build(self,10007001)
    end
end

function union_restore(self)
    local u = get_union(self,self.uid) 
    if not u then return end
    if u.build and next(u.build) then
        for _, v in pairs( u.build or {} ) do
            local c = resmng.prop_world_unit[v.propid]
            if c and c.BuildMode ==2  and v.state == BUILD_STATE.WAIT  then
                if self.restore then
                    Rpc:union_get_res(self,v.eid,self.restore)
                else
                    local res = {self.res[1][1]/2,self.res[2][1]/2,self.res[3][1]/2,self.res[4][1]/2,} 
                    Rpc:union_save_res(self,v.eid,res)
                end
                return 
            end
        end
    else
        union_build(self,10004001)
    end
end

function union_fight(self,fun)
    local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
    local u = get_union(self,self.uid) 
    if not u then return end
    for _, v in pairs( u.room or {} ) do
        if v.is_mass == 1 then
            Rpc:union_mass_join(self,v.ack.eid, v.ack.troop_id, { live_soldier = arm } )
            Rpc:union_battle_room_list(self)
            return
        end
    end

    local l = get_target( self, fun )
    if not next(l) then return end

    local v = l[ math.random( 1, #l ) ] 
    Rpc:union_mass_create(self,v.eid, MassTime.Level1, { live_soldier = arm } )
--    lxz(self.acc,u.name)
    Rpc:union_battle_room_list(self)
    return
end

function union_battle_room_list_resp(self,pack)
    local u = get_union(self,self.uid) 
    if not u then return end
    u.room = pack
end
