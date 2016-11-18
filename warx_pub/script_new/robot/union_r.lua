module("Ply")

function union_mission_get(self,pack)
    local u = get_union(self,self.uid)
    if not u then return end
    u.mission = pack
end

function union_load(self, pack)
    union_get(self,pack)
end
function union_battle_room_list_resp(self,pack)
    local u = get_union(self,self.uid) 
    if not u then return end
    u.room = pack
end

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
        u._apply = pack.val
    elseif pack.key == "mass" then
    elseif pack.key == "aid" then
    elseif pack.key == "tech" then
        _union[pack.uid].tech = pack.val.info 
    elseif pack.key == "donate" then
        slef.donate = pack.val
    elseif pack.key == "union_donate" then
        u.donate = pack.val
    elseif pack.key == "fight" then--room
    elseif pack.key == "build" then
        if pack.val then
            u.build = pack.val.build 
        end
    elseif pack.key =="buildlv" then--军团建筑捐献
        if not u.buildlv then u.buildlv = {} end
        for k, v in pairs(pack.val) do
            u.buildlv[v.class]=v
        end

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

function union_broadcast(self,key,mode,data)
    local us = get_union(self,self.uid)
    if not us then return end

    if "member" == key then         
        if not us.member then
            us.member = {}
        end
        if UNION_MODE.ADD == mode then          
            if data.pid == self.pid then 
                Rpc:union_load(self,"info")
                Rpc:union_load(self,"member")    ---新加入军团，立即load最新的盟友数据
                Rpc:union_help_get(self)        ---新加入的军团，load他们的求助列表
                Rpc:union_load(self,"relation")  ---新加入军团，load外交关系
            else        
                us.member[data.pid] = data             
            end             
        elseif UNION_MODE.DELETE == mode then           
            us.member[data.pid] = nil
        else
            us.member[data.pid] = data             
        end
    else     
        --lxz(key,self.uid)
        if self.uid then 
        Rpc:union_get(self,key,self.uid)
        end
    end
end



function get_union(self,uid)
    if not _union then _union = {} end

    if not next(_union) then Rpc:union_list(self,"") end

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
    --lxz(pack)
    if not _union then _union = {} end
    for k, v in pairs( pack.list ) do
        local t = rpchelper.decode_rpc(v,"union")
        _union[t.uid] = t
    end
end

function union_plan(self,ps)
    for k, v in pairs( ps or {} ) do
        if k=="add" then
            union_add(self)
        elseif k=="rank" then
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


function union_mission()
    for i = config.g_start,config.g_start+config.g_num  do
        local name = config.gName..i
        local self = g_name[name]  
        if self then
            if self.active and gTime - self.active  > 1 then
                Ply.pending( self )
                Rpc:union_mission_get(self) 
                if not self.uid then return end
                local u = get_union(self,self.uid)
                if not u then 
                --    require("frame/debugger")
                    Ply.union_add(self,2)
                    return 
                end
                local m = u.mission 
                if m then
                    if m.state ==  TASK_STATUS.TASK_STATUS_ACCEPTED then
                       local c = resmng.prop_union_task[m.propid]
                       if c.Class == 1 then
                            Rpc:union_buildlv_donate(self,1)
                       elseif c.Class == 2 then
                            Ply.union_help(self,HELP_TYPE.CONSTRUCT)
                       elseif c.Class == 3 then
                            Ply.union_donate(self)
                       elseif c.Class == 4 then
                           for k, v in pairs( resmng.prop_task_daily) do
                               Rpc:daily_task_done(self,k) 
                           end
                       elseif c.Class == 5 then
                           Ply.union_gather(self)
                       elseif c.Class == 6 then
                           Rpc:chat(self, 0, "@addarm=1010=100000", 0 )
                       elseif c.Class == 7 then
                           Rpc:union_god_add(self,1 )
                       elseif c.Class == 8 then
                           for k, v in pairs( resmng.prop_union_mall) do
                               Rpc:union_mall_add (self, k,1)   --军团长采购道具
                               Rpc:union_mall_buy (self, k,1)    --军团成员买道具
                           end
                       end
                    else
                        Rpc:union_mission_set(self) 
                    end

                end
            end
        end
    end
end

function union_add(self,num)
    local g_membercount =  num or 50 
    local u = get_union(self,self.uid or 0)
    if not u then 
        Rpc:union_quit(self)
        Rpc:union_list(self,"")
        for k, v in pairs( _union or {} ) do
            if v.name and string.find(v.name,config.gName) and v.membercount < g_membercount  then
                Rpc:union_apply(self,v.uid)
                self.uid = v.uid
                return
            end
        end
        local uname  = tostring(math.random(100,999) )
        Rpc:union_create(self,self.acc,uname,40,1000)
    else
        union_rank(self,resmng.UNION_RANK_4)
    end
end

function union_rank(self,r)
    --Rpc:union_get(self,"member",self.uid)
    local u = get_union(self,self.uid) 
    if not u  then return end
    if u.leader==self.name then
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
    if u.leader~=self.name then return end
    local obj 
    if u.build and next(u.build) then
        for k, v in pairs( u.build  or {} ) do
            if v.state == BUILD_STATE.CREATE  then
                local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
                Rpc:union_build(self, v.eid, {live_soldier=arm} )
            end

            local c = resmng.prop_world_unit[v.propid]
            if is_union_miracal(v.propid) then
                obj = v
            end

            if v.propid == propid then
                return
            end
        end
    end

    if obj then
        Rpc:request_empty_pos(self,obj.x,obj.y,2,{key="build",propid =propid,idx = 0,name="test" })
    else
        Rpc:request_empty_pos(self,self.x,self.y,2,{key="build",propid =10001001,idx=0,name="test" })
    end
    Rpc:union_get(self,"build",self.uid)

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
    if next(u.room or {} )  then
        for _, v in pairs( u.room ) do
            if v.is_mass == 1 then
                Rpc:union_mass_join(self,v.ack.eid, v.ack.troop_id, { live_soldier = arm } )
                return
            end
        end
    else
        Rpc:union_battle_room_list(self)
    end

    local l = get_target( self, fun )
    if l  then
        local v = l[ 1 ] 
        Rpc:union_mass_create(self,v.eid, MassTime.Level1, { live_soldier = arm } )
        return
    end
end

function union_fight2(self,fun)
    local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
    local l = get_target( self, fun )
    if l  then
        local v = l[ 1 ] 
        Rpc:siege( self, v.eid, { live_soldier = arm } )
        return
    end
end

