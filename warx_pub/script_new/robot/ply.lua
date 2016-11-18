module("Ply", package.seeall)

local _mt = {__index = Ply}

function new(acc)
    local pid = -1
    for k, v in pairs( gNames[acc] or {} ) do
        if v.smap and v.smap == config.Map then--源服务器
            pid =  tonumber(k)
            break
        end
    end

    local t = {acc=acc, pid=pid,action={{"login"}}}
    return setmetatable(t, _mt)
end

function handle_network(self, sid, pktype)
    if pktype == 10 then -- connect complete
        _G.gLogin = _G.gLogin + 1
        self.gid = sid
        local token = "c67sahejr578aqo3l8912oic9"
        local msg = c_md5(c_md5(gTime..self.acc..token)..APP_SECRET)
        lxz(self.pid)
        Rpc:firstPacket(self,config.Map,  config.get_cival(self), self.pid, msg, gTime, self.acc,token)
    elseif pktype == 11 then -- connect fail

    elseif pktype == 6 then -- close

    end
end

function robot_first(self)
    handle_network(self, self.fd, 10)
end

gActionIndex = 0

function pending( self )
    if self.gid then skiplist.delete( gRid, tostring(self.gid) ) end
    self.active = gTime
    gActionIndex = gActionIndex + 1
    skiplist.insert( gRid, tostring( self.gid ), gActionIndex )
end

function OnError( self,id,code)
    for _, v in pairs( Rpc.localF ) do
        if v.id == id  then
            lxz(v)
        end
    end
end

function onLogin(self, pid, name )
    --print("login:",self.acc)
    g_login = (g_login  or 0) + 1
    self.pid = pid
    self.name = name
    self.tmLogin = gTime

    if not _ply then
        _ply={}
    end
    _ply[name] = self
    funcAction.login( self )
end

function notify_server(self, str )
    --print(str)
end

function response_empty_pos(self,x,y,pack)
    if pack.key == TASK_ACTION.ATTACK_SPECIAL_MONSTER then
        local eid = get_npc_eid()
        if not eid then
            lxz(npc)
            return
        end
        local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
        Rpc:siege_task_npc(self, pack.task_id, eid, x, y, {live_soldier=arm} )
    elseif pack.key == "move" then
        Rpc:migrate(self,x,y)
    elseif pack.key == "build" then
        Rpc:union_build_setup(self,pack.idx,pack.propid,x,y,pack.name)
    end
end

function get_eye_info(self,eid,pack)
    if is_union_building(eid) then
        if pack.res then 
            for _, v in pairs( pack.res ) do
                if self.pid == v.pid  then
                    self.restore = v.res
                end
            end
        end
    end
end

function loadData(self, data)
    --lxz( "load data:"..data.key)
    if data.key == "task" then
        if not self._task then
            self._task = {}
        end
        for _, v in pairs( data.val ) do
            self._task[v.task_id] = v
        end
        --lxz(self._task)
    elseif data.key == "ef" then
        self._ef = data.val
    elseif data.key == "hero" then
        self._hero = {}
        for k, v in pairs(data.val) do self._hero[v.idx] = v end
    elseif data.key == "pro" then
        for k, v in pairs(data.val) do self[k] = v end
        self.pro = data.val
        local x = data.val.x
        local y = data.val.y
        local move = 32
        for zx = x - move, x + move, 10 do
            for zy = y - move, y + move, 10 do
                if zx > 0 and zx < 1280 then
                    if zy > 0 and zy < 1280 then
                        Rpc:movEye( self, config.Map, zx, zy )
                    end
                end
            end
        end
        Rpc:movEye( self, config.Map, 640, 640 )
        Rpc:movEye( self, config.Map, 640, 610 )
        Rpc:movEye( self, config.Map, 610, 640 )
        Rpc:movEye( self, config.Map, 640, 670 )
        Rpc:movEye( self, config.Map, 670, 640 )

--[[
        if string.byte( data.val.name, 1, 1 ) == 75 then
            Rpc:change_name( self, name.make_name() )
        end
        --]]

    elseif data.key == "build" then
        self._build = {}
        for _, v in pairs( data.val ) do
            self._build[ v.idx ] = v
        end
    elseif data.key == "troop" then
        local bs = {}
        for k, v in pairs( data.val ) do
            bs[ v._id ] = v
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
            Rpc:troop_acc(self,v._id,0)
        end
        self._troop = bs

    elseif data.key == "done" then
        --self.load_done = true
        --plan_build( self )
        --plan_troop( self )
        pending( self )
    else
        self[ "_" .. data.key ] = data.val
    end

end


function stateTroop(self,data)
    local id = data._id
    if data.delete then
        self._troop[ id ] = nil
    else
        self._troop[ id ] = data
    end
end

function upd_arm( self, info )
    --lxz(info)
    for k, v in pairs(info) do 
        local check = config.g_check.arm 
        if check and  v < check.num then
            Rpc:chat(self, 0, "@addarm="..k.."="..check.num, 0 )
        end
    end
    self._arm = info
end


function union_reply(self, id,stat)
end

function union_add_member(self, pack)
    Rpc:union_add_member(self,pack.pid)
end


function union_build_donate(self,info) 
    if not self.union.buildlv then self.union.buildlv = {} end
    self.union.buildlv[info.class]=info
end

function union_broadcast(self,what,mode,info) 
    if what == "build" then
        if mode == 2 and info.state == resmng.DEF_STATE_IDLE then
            self.union.build[info.idx]= info
        end
    elseif what =="fight" then--军队集结
        if not self.union.mass then self.union.mass = {} end
        if mode == 1 then
            self.union.mass[info.id]= info
        elseif mode == 3 then
            self.union.mass[info.id]= nil
        end
    end
end

function addEty( self, info )

    local pack = etypipe.parse(info)
    if pack.propid == 11001001 then return end


    local zx = math.floor( pack.x / 16 )
    local zy = math.floor( pack.y / 16 )

    --print( "addety",pack.x, pack.y, zx,zy, pack.level)


    local node = gZones[ zx ]
    if not node then 
        node = {}
        gZones[ zx ] = node
    end

    local zone = node[ zy ]
    if not zone then
        zone = {}
        node[ zy ] = zone 
    end
    zone[ pack.eid ] = pack

    gEtys[ pack.eid ] = pack

    if not kings then kings = {} end

    if pack.propid ==4001001  then
        kings[1]=pack
    elseif pack.propid ==4001003  then
        kings[2]=pack
    elseif pack.propid ==4002003  then
        kings[3]=pack
    elseif pack.propid ==4003003  then
        kings[4]=pack
    elseif pack.propid ==4004003  then
        kings[5]=pack
    end

    if not npc then npc = {} end

    if pack.propid >1000  and pack.propid <4031  then
        table.insert(npc,pack)
    end
end


function addEtys(self, infos)
    for _, info in pairs(infos) do 
        addEty( self, info )
    end
end

function remEty( self, eid )
    --print("移除：",eid)
    local ety = gEtys[ eid ]
    if ety then
        local zx = math.floor( ety.x / 16 )
        local zy = math.floor( ety.y / 16 )
        gZones[ zx ][ zy ][ eid ] = nil
    end
end


function stateBuild(self, vs)
    local idx = vs.idx
    if vs.tmSn then
        Rpc:union_help_add(self,vs.tmSn)
        Rpc:acc_build(self, idx, ACC_TYPE.GOLD)
    end
    local b = self:get_build(idx)
    if b then
        for k, v in pairs(vs) do b[k] = v end
    else
        self._build[ idx ] = vs
    end
end




function get_build(self, idx)
    if not idx then return self._build end
    if not self._build then return self._build end
    if not self._build[idx] then 
        return nil
    end
    return self._build[ idx ]
end

function get_build_x(self, x)
    for _, v in pairs(self._build) do 
        if v.x == x then
            return v
        end
    end
end


function checkBuild(self)

end

function getRes(self, mode)
    if mode == resmng.DEF_RES_FOOD then
        return self.food - (gTime-self.foodTm) * self.foodUse/3600
    elseif mode == resmng.DEF_RES_WOOD then
        return self.wood
    end
end

function getTime( self,tm)
    self.stm = tm
end

function doCondCheck(self, class, mode, lv, ...)
    if class == "OR" then
        local f,c,m,l 
        for _, v in pairs({mode, lv, ...}) do
            if self:doCondCheck(unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then 
        for _, v in pairs({mode, lv, ...}) do
            if not self:doCondCheck(unpack(v)) then return false, class, mode, lv end
        end
        return true

    elseif class == resmng.CLASS_RES then
        if mode == resmng.DEF_RES_FOOD then
            if self.food - (gTime-self.foodTm)*self.foodUse / 3600 >= lv then return true end
        elseif mode == resmng.DEF_RES_WOOD then
            if self.wood >= lv then return true end
        end
    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            for _, v in pairs(self:get_build()) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == t.Class and n.Mode == t.Mode then 
                    if n.Lv >= t.Lv then 
                        return true 
                    else
                        self:build_up(t.Class,t.Mode,n.Lv+1,1)
                        return 
                    end
                end
            end
            self:build_up(t.Class,t.Mode,1,1)
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = resmng.prop_genius[ mode ]
        if t then
            for _, v in pairs(self.genius) do
                local n = resmng.prop_genius[ v ]
                if n and n.Class == t.Class and n.Mode == t.Mode and n.Lv >= t.Lv then return true end
            end
        end
    elseif class == resmng.CLASS_TECH then
        local t = resmng.prop_tech[ mode ]
        if t then
            for _, v in pairs(self._tech or {} ) do
                local n = resmng.prop_tech[ v ]
                if n and n.Class == t.Class and n.Mode == t.Mode then 
                    if n.Lv >= t.Lv then 
                        return true 
                    end
                    tech(self, mode,n.Lv+1)
                    return
                end
            end
            tech(self, mode,1)
        end
    end
    -- default return false
    return false, class, mode, lv
end

function statePro(self,pack)
    -- lxz(pack)
    if pack.tech then
        self._tech = pack.tech
    else
        for k, v in pairs(pack) do self[k] = v end
    end
    local check = config.g_check.gold
    if pack.gold and check and pack.gold < check.num then
        Rpc:chat(self, 0, "@addgold="..check.num, 0 )
        self.gold = check.num
    end
    if pack.sinew and config.g_check.sinew then 
        print("体力",pack.sinew)
        if pack.sinew < 100 then Rpc:buy_item(self,43, 2, 1) end
    end

    if pack.uid then 
        self.uid = pack.uid
    end
end

function tech(self, id,lv,quick)
    quick = quick or 1
    print("tech",id,lv)
    local c = resmng.prop_tech[id]
    for _, v in pairs(self._tech) do
        local n = resmng.prop_tech[ v ]
        if n and n.Class == c.Class and n.Mode == c.Mode then 
            if n.Lv >= lv then
                return true
            end
            id = c.Class*1000*1000 + c.Mode*1000 
            for i=n.Lv+1,lv do
                c = resmng.prop_tech[id+i]
                local f = self:condCheck(c.Cond)
                if not  f then
                    return 
                end
                Rpc:learn_tech(self,1001,c.ID,quick)
            end
            return true
        end
    end

    for i=1,lv do
        id = c.Class*1000*1000 + c.Mode*1000 
        c = resmng.prop_tech[id+i]
        local f = self:condCheck(c.Cond)
        if not f then
            return 
        end
        Rpc:learn_tech(self,1001,c.ID,quick)
    end
        return true  
end

function build_up(self,class, mode,lv,num,quick)
    print("build",class,mode,lv)

    local cur = self:getBuildNum(class, mode)
    if cur < num then 
        local f = funcAction.construct 
        f(self,class,mode,(num-cur))
        return false 
    else
        return true 
    end

    for _, b in pairs(self:get_build()) do
        local n = resmng.prop_build[ b.propid ]
        if n and n.Class == class and n.Mode == mode then 
            local i = 1
            local c = resmng.prop_build[b.propid+i]
            if  c  then
                while lv >= c.Lv do
                    local f = self:condCheck(c.Cond)
                    if not f  then
                        return false
                    end
                    if not quick then
                        Rpc:one_key_upgrade_build(self,b.idx)
                    else
                        Rpc:upgrade(self,b.idx)
                    end
                    i = i + 1
                    c = resmng.prop_build[b.propid+i]
                    if  not c then
                        break
                    end
                end
            end
        end
    end

end

function genius_up(self,id)

    local n = resmng.prop_build[ id ]
    if n then 
        local i = 1
        local c = resmng.prop_genius[id]
        if  c  then
            local f = self:condCheck(C.cond)
            if not f  then
                return false
            end
            if c.Lv > 1 then
                local old_id = id - 1
                local old_conf = resmng.prop_genius[old_id]
                if not old_conf then
                    genius_up(self,old_id)
                    return
                end
            end
            Rpc:do_genius(self,id)
        end
    end

end

function condCheck(self, tab)
    if tab then
        for _, v in pairs(tab) do
            local flag, class, mode, lv = self:doCondCheck(unpack(v))
            if not flag then 
                return flag, class, mode, lv 
            end
        end
    end
    return true
end


function king(self)

    if not self._build then return end
    if not self._build[1] then return end

    if self._build[1].propid< 15 then
        self:build_up(0,0,15,1)
        return 
    end

    if self.uid < 10000 then
        union_add(self)
    else
    --[[
        Rpc:chat(self, 0, "@startkw", 0 )
        Rpc:chat(self, 0, "@peacekw", 0 )
        Rpc:chat(self, 0, "@fightkw", 0 )
        --]]
        local r = math.random(5)
        if  kings[r].uid ~= self.uid then
            local  arm = {[1010]=1000,[2010]=1000,[3010]=1000,[4010]=1000,}
            Rpc:siege( self, kings[r].eid, { live_soldier = arm } )
        end
    end
end

function doAction(self,ps)
    --Rpc:p2p( self, self.pid, {cur=gMsec} )
    --Rpc:chat( self, 0, "hello", 0)
    --self:addAction("idle")
    for k, v in pairs(ps) do
       -- lxz(k)
        if k == "task" then
            self:main_task()
        elseif k == "king" then
            king(self)
        elseif k == "union" then
            union_plan(self,v)
        elseif k == "build" then
            if self._build and self._build[1] and self._build[1].propid< v.lv then
                self:build_up(0,0,v.lv,1)
            end
        end
    end
    pending( self )
end

function addAction(self, act, ...)
    for k, v in pairs(self.action) do
        if v[1] == act then
            WARN("recursion !!!! add act, %s", act)
            return
        end
    end

    table.insert(self.action, 1, {act, {...}})
    gActive[ self.gid ] = self
    self:doAction()
end

function p2p( self, from, info)
    print( "p2p", gMsec - info.cur )
end

function plan_build( self  )
    if not self.load_done then return end

    local queue = 0
    local tab = resmng.prop_build
    local alls = { [0]={}, [1]={}, [2]={} }
    for k, v in pairs( self._build ) do
        if v.state == BUILD_STATE.CREATE or v.state == BUILD_STATE.UPGRADE then
            queue = queue + 1
        end
        local conf = tab[ v.propid ]
        if conf.Class == 0 then
            alls[ conf.Class ][ conf.Mode ] = conf.Lv 
        elseif conf.Class == 1 then
            if not alls[ conf.Class ][ conf.Mode ] then alls[ conf.Class ][ conf.Mode ] = {} end
            table.insert( alls[ conf.Class ][ conf.Mode ], conf.Lv )
        elseif conf.Class == 2 then
            alls[ conf.Class ][ conf.Mode ] = conf.Lv 
        end
    end

    local castle_lv = alls[ 0 ][ 0 ]
    for k, v in pairs( self._build ) do
        local conf = tab[ v.propid ]
        if queue < 2 then
            local nconf = tab[ v.propid + 1 ]
            if nconf then
                if not nconf.Cond or self:condCheck( nconf.Cond ) then
                    Rpc:upgrade( self, v.idx )
                    queue = queue + 1
                    if queue >= 2 then break end
                end
            end
        end

        if conf.Class == 1 then
            if v.state == BUILD_STATE.WORK then
                if gTime - v.tmStart > 120 then
                    Rpc:reap( self, v.idx )
                end
            end
        end
        --todo learn
    end
    if queue < 2 then Rpc:upgrade( self,  1 ) end
end


function get_val( what, ef )
    local base = ef[ what ] or 0
    local mul = ef[ what .. "_R" ] or 0
    local add = ef[ what .. "_A" ] or 0
    return base * ( 1 + mul * 0.0001 ) + add
end

function get_target( self, func,lv )

    local its = {}
    lv = lv or 0
    for x = 1, 80 do
        if x >= 0 and x < 80 then
            local node = gZones[ x ]
            if node then
                for y = 1, 80 do
                    if y >= 0 and y < 80 then
                        local tnode = node[ y ]
                        if tnode then
                            for k, v in pairs( tnode ) do
                                if func( v ) and v.level>lv then 
                                    tnode[k]=nil
                                    return {v}
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


function plan_troop( self )
    if not self.load_done then return end
    local num_troop = 0
    local num_soldier = {0,0,0,0}

    for _, troop in pairs( self._troop ) do
        num_troop = num_troop + 1
        if troop.arms then
            local arm = troop.arms[ self.pid ]
            if arm then
                for k, v in pairs( arm.live_soldier or {}) do
                    local mode = math.floor( v / 1000 )
                    num_soldier[ mode ] = num_soldier[ mode ] + v
                end
            end
        end
    end

    for k, v in pairs( self._arm ) do
        local mode = math.floor( k / 1000 )
        num_soldier[ mode ] = num_soldier[ mode ] + v
    end

    local count_soldier = get_val( "CountSoldier", self._ef )
    local count_train = get_val( "CountTrain", self._ef )
    local count = math.floor( count_soldier * 2 / 4 )

    for mode = 1, 4, 1 do
        if num_soldier[ mode ] < count then
            local idx = 2 * 10000 +  mode * 1000 + 1
            local build = self:get_build( idx )
            if build.state == BUILD_STATE.WORK then
                if gTime > build.tmOver then
                    Rpc:draft( self, idx )
                end

            elseif build.state == BUILD_STATE.WAIT then
                local conf = resmng.prop_build[ build.propid ]
                local armid = mode * 1000 + conf.TrainLv
                Rpc:train( self, idx, armid, count_train )
            end
        end
    end

    local count_troop = get_val( "CountTroop", self._ef )

    if num_troop < count_troop then
        local home = self._arm
        local alls = {}

        for k, v in pairs( home ) do
            if v > 0 then
                table.insert( alls, {k, v} )
            end
        end

        local fun = function( A, B )
            local aid = A[1]
            local bid = B[1]
            local alv = math.floor( aid % 1000 )
            local blv = math.floor( bid % 1000 )
            if alv ~= blv then return alv < blv end
            return aid < bid 
        end

        table.sort( alls, fun )

        local rate = count_troop - num_troop
        local total = 0
        local arm = {}
        for _, v in ipairs( alls ) do
            local num = math.floor( v[2] / rate )
            if num > 0 then
                if total + num < count_soldier then
                    arm[ v[1] ] = num
                    total = total + num
                else
                    num = count_soldier - total
                    arm[ v[1] ] = num
                    break
                end
            end
        end
        
        local targets = get_target( self, is_monster )
        local count = #targets
        if count > 1 then
            local target = targets[ math.random( 1, count ) ] 
            if is_res( target ) then
                Rpc:gather( self, target.eid, { live_soldier = arm } )
            elseif is_monster( target ) then
                Rpc:siege( self, target.eid, { live_soldier = arm } )
            end
        end
    end
end



function union_build_up_pre(self,class,mode)

    if self.union.id == 0 then
        self:addAction("union_add")
        return 
    end

    if class == resmng.CLASS_UNION_BUILD_CASTLE then
        if self.name ~=  self.union.leader then
            return
        end
    elseif class == resmng.CLASS_UNION_BUILD_MINE_CASTLE then
    elseif class == resmng.CLASS_UNION_BUILD_TUTTER then
    elseif class == resmng.resmng.CLASS_UNION_BUILD_MINE then
    end

    --查询玩家建筑
    local cc = nil 
    local idx = 0 
    for _, v in pairs(self.union.build) do
        cc = resmng.prop_union_build[v.id]
        if cc.Class == class and cc.Mode==mode then
            idx = v.idx 
            break
        end
    end
    

--没有建筑
    if idx == 0 then
        self:union_build_setup_pre(class,mode)
        return
    end

    if cc.Lv == 3 then
       return true
    end
--查询玩家建筑捐献等级
    local lv = nil
    if self.union.buildlv[class] and self.union.buildlv[class].id then 
        lv = self.union.buildlv[class].id 
    else
        Rpc:union_build_donate(self,class)
        return 
    end

    local lvcc = resmng.prop_union_buildlv[lv] 
    if cc.Lv >= lvcc.Lv then
        Rpc:union_build_donate(self,class)
        return 
    end

    Rpc:union_build_upgrade(self,idx)
end

function union_build_setup_pre(self,class,mode)
    local num = 0

    if self.union.id == 0 then
        self:addAction("union_add")
        return 
    end

    if class == resmng.CLASS_UNION_BUILD_CASTLE then
        if self.name ~=  self.union.leader then
            return
        end
    elseif class == resmng.CLASS_UNION_BUILD_MINE_CASTLE then
    elseif class == resmng.CLASS_UNION_BUILD_TUTTER then
    elseif class == resmng.resmng.CLASS_UNION_BUILD_MINE then
    end


    for _, v in pairs(self.union.build) do
        local cc = resmng.prop_union_build[v.id]
        if cc.Class == class and cc.Mode==mode then
            num = num +1
        end
    end

    local lv = nil
    if self.union.buildlv[class] and self.union.buildlv[class].id then 
        lv = self.union.buildlv[class].id 
    else
        Rpc:union_build_donate(self,class)
        return 
    end

    local lvcc = resmng.prop_union_buildlv[lv] 
    if num >= lvcc.Num then
        Rpc:union_build_donate(self,class)
        return 
    end

    local id = class*1000*1000+mode*1000+1
    self:addAction("union_build_setup",id,self.x+5*(class+1),self.y+5*(mode+1))
end

function getBuildNum(self, class, mode)
    local num = 0
    local new = 0
    local x = 100
    local idx = class * 10000 +  mode * 100 + 0
    for k, v in pairs(self:get_build() or {} ) do
        if k > idx  and k < idx + 100 then
            num = num + 1
            if v.state and v.state > 0 then
                new = new + 1
            end
        end
    end

    return num, x,new
end


funcAction = {}
funcAction.login = function(self)
    self._build = {}
    self._troop = {}
    self._arm = {}
    self._ef = {}

    Rpc:getTime(self)
    Rpc:loadData( self, "pro" )
    Rpc:loadData( self, "build" )
    Rpc:loadData( self, "ef" )
    Rpc:loadData( self, "ef_eid" )
    Rpc:loadData( self, "item" )
    Rpc:loadData( self, "hero" )
    Rpc:loadData( self, "troop" )
    Rpc:loadData( self, "equip" )
    Rpc:loadData( self, "arm" )
    Rpc:loadData( self, "task" )
    Rpc:get_gs_buf( self )
    Rpc:loadData( self, "watch_tower" )
    Rpc:chat_account_info_req( self )

    Rpc:union_load( self, "info" )
    Rpc:union_load( self, "member" )
    Rpc:union_help_get( self )
    Rpc:union_load( self, "relation" )
    Rpc:chat(self,1,"我是机器人",0)
    Rpc:change_language(self,40)
    Rpc:union_load( self, "tech" )
    Rpc:union_load( self, "mars" )
    Rpc:union_load( self, "buf" )
    Rpc:union_load( self, "union_donate" )
    Rpc:union_load( self, "donate" )
    Rpc:mail_load( self, 0 )
    Rpc:report_load( self, 1 )
    Rpc:report_load( self, 2 )
    Rpc:report_load( self, 3 )
    Rpc:syn_back_code( self, 1 )


    for _, v in pairs(config.gm) do
        Rpc:chat(self, 0, v, 0 )
    end

    Rpc:loadData( self, "tech" )
    Rpc:loadData( self, "done" )
    return true

end


funcAction.union_build_setup = function(self,id,x,y)
    Rpc:union_build_setup(self,id,x,y)
    return true
end


function build_train(self, class, mode,a_lv)

    local f = 0 

    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
           if p.class == class and p.mode == mode and p.trainLv >= a_lv then
                return 1
           end

        end
    end

    self:build_up(class,mode,lv)
    return 0
end

function get_buf(self, what,val)
    self._buf[what]= val
end

function get_res(self, k,v)
    if k=="item" then
        local t = copyTab(v)
        for _, obj in pairs(self._item) do
            for id, _ in pairs(v) do
                if obj[2]==id then
                    t[obj[2]]= obj[3]
                    break
                end
            end
        end
        return t 
    elseif k=="donate" then
        Rpc:union_load( self, "union_donate" )
        Rpc:union_load( self, "donate" )
        local u = get_union(self,pack.uid)
        return { my = self.donate,u=u.donate}  
    elseif k=="hero" then
        return self._hero  
    elseif k=="arm" then
        return self._arm  
    elseif k=="buf" then
        for  what,_ in pairs(v) do
            Rpc:get_buff( self, what )
        end
        return self._buf
    else
        return self[k]
    end
end

function check_on(self, name,check)
    if not self._check then self._check  = {} end
    if not self._check[name] then 
        self._check[name] = {}
        for k, v in pairs(check) do
            self._check[name][k] = {}
            self._check[name][k].dst = v
            self._check[name][k].on = self:get_res(k,v) or 0 
        end
    else
        if check_ret(self,name) then
            WARN(self.account..":"..name..":ok")
            return false
       else
            WARN(self.account..":"..name..":err")
        end
    end

    for k, v in pairs(check) do
        if k == "buff" then
            for what, _ in pairs(v) do
                if not self._check[name][k].on[what]  then 
                    return false
                end
            end
        else
            if not self._check[name][k]  then 
                return false
            end
            if not self._check[name][k].on  then 
                return false
            end
        end
    end

    return true
end

function check_off(self,name)
    for k, v in pairs(self._check[name] or {} ) do
        v.off = self:get_res(k) or 0
    end
end

function check_ret(self,name)
    if not self._check[name].ret then 
        Ply.check_off(self, name)
    end

    for k, v in pairs(self._check[name]) do
        if k == "buff" or k=="item" then
            for what, _ in pairs(v.dst) do
                if (v.off[what] or 0) + v.dst[what]~= (v.on[what] or 0)   then 
                    return false
                end
            end
        else
            if v.off+v.dst~= v.on  then 
                return false
            end
        end
    end
    return true
end

function fight(self, cmd, eid,arms)
--收兵
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == 0 and p.mode == 18 then
                Rpc:draft( self,v.idx)
            end
        end
    end
    --造兵
    for _, v in pairs(arms) do
        for sk, sv in pairs(self.arms) do
            if v[1]==sv[1] and sv[2] < v[2] then
               self:train(math.floor(v[1]/1000),math.floor(v[1]%1000),v[2]-sv[2] )--造兵 
               return true
            end
        end
    end

    if self.union.id ~= 0 then
        local mid = 0
        for k, v in pairs(self.union.mass) do 
            mid = k
            for _, v2 in pairs(v.A) do 
                if v2.pid == self.pid  then
                    mid = -1
                    break
                end
            end
        end

        if mid == 0 then
            self:addAction("fight","union_mass_create",eid,30,arms ) 
        elseif mid == -1 then
        else
            self:addAction("fight","union_mass_join",mid,arms ) 
        end
    else
        self:addAction("fight","seige",eid,arms ) 
    end
    return true
end

funcAction.fight = function(self,cmd,...)
    if self.troop_num > 3 then
        return true
    end

    lxz(self.pid,self.troop_num)
    self.troop_num = self.troop_num + 1 
    Rpc[cmd](Rpc,self,...)
end

function train(self,a_mode,a_lv,num )
    local id = math.floor(a_mode * 1000 + a_lv)
    local idx = 2 * 10000 +  a_mode * 100 + 1
    local num = math.ceil(num/10)
    for i = 1,num do
        Rpc:train(self,idx,id, 10,1) 
    end
end


funcAction.train = function(self, id,num)
    local cur_num = num
    local bs = self:get_build()
    for k, v in pairs(bs) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == 0 and p.mode == 18  and cur_num > 0 then
                if cur_num < p.effect.TrainCount then
                    Rpc:train(self,v.idx,id, cur_num) 
                    cur_num = 0
                    break
                else
                    Rpc:train(self,v.idx,id, p.effect.TrainCount)
                    cur_num = cur_num - p.effect.TrainCount
                end
            end
        end
    end

    return  true 
end

funcAction.construct = function(self, class, mode, num)

    local propid = math.floor(class * 1000*1000 + mode*1000 + 1)
    --[[
    local prop = resmng.prop_build[ propid ]
    if prop.Cond then
        local flag, class, mode, lv = self:condCheck(prop.Cond)
        if not flag then
            self:addAction("get", class, mode, lv)
            return
        end
    end

    if prop.Cons then
        local flag, class, mode, lv = self:condCheck(prop.Cons)
        if not flag then
            self:addAction("get", class, mode, lv)
            return
        end
    end
    --]]

    x =100
    local bs = {}
    for k, v in pairs(self:get_build() or {} ) do
        bs[v.x] = 1
    end

    for i=1,num do 
        while true do
            if not bs[x] then 
                bs[x] = 1
                break 
            end
            x = x + 1
        end

        Rpc:construct(self, x, 0, propid)
    end
    return true
end


funcAction.get = function(self, class, mode, lv)
    if class == resmng.CLASS_RES then
        if self:getRes(mode) >= lv then return true end
        for k, v in pairs(self:get_build()) do
            local p = resmng.prop_build[ v.propid ]
            if p then 
                if p.class == 1 and p.mode == mode then
                    if v.state == resmng.DEF_STATE_IDLE then
                        if gTime - v.tmStart > 10 then
                            Rpc:reap(self, v.idx)
                            v.tmStart = gTime
                        end
                    end
                end
            end
        end

--收城外田
        for _, yv in pairs(self._eye) do
            for k, v in pairs(yv) do
                local type = math.floor(v.eid/65536) 
                if type == 1 and v.val ~= 0 and not v.on then
                    self:addAction("gather", v.eid,{{1001,1},} )
                return
            end
        end
    end

    elseif class == resmng.CLASS_BUILD then

    end
end

funcAction.gather = function(self, eid,arms)
--收兵
    for k, v in pairs(self:get_build()) do
        local p = resmng.prop_build[ v.propid ]
        if p then 
            if p.class == 0 and p.mode == 18 then
                Rpc:draft( self,v.idx)
            end
        end
    end
    --造兵
    for _, v in pairs(arms) do
        for sk, sv in pairs(self.arms) do
            if v[1]==sv[1] and sv[2] < v[2] then
                self:addAction("train",1,1,v[2]-sv[2] )--造兵 
                return true
            end
        end
    end

   cur_num = Rpc:gather( self,eid,arms)
   return true
end


funcAction.idle = function(self)
    --print( "chat" )
    --Rpc:chat(self, 0, "hello", 0)
    --Rpc:chat(self, 0, "@all", 0)
end

