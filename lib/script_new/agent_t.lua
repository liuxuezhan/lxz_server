module( "agent_t" )

function agent_move_eye( self, pid, x, y )
    c_mov_eye(pid, x, y)
end


function agent_remove_eye( self, pid )
    c_rem_eye( pid )
end

function agent_syn_call(self, id, func, arg)
    --print("sync all ", id, func, arg)
    if arg[1] == "union" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            union_t[func](union, self.pid, id, unpack(arg))
        end
    elseif arg[1] == "union_relation" then
        local uid = arg[2]
        local union = unionmng.get_union(uid)
        if union then
            table.remove(arg, 1)
            table.remove(arg, 1)
            local val = union_relation.list(union)
            Rpc:callAgent(map_id, "agent_syn_call_ack", id, val or {})
        end
    elseif arg[1] == "player" then
        local pid = arg[2]
        local ply = getPlayer(pid)
        if ply then
            table.remove(arg, 1)
            table.remove(arg, 1)
            player_t[func](ply, unpack(arg))
        end
    elseif arg[1] == "union_relation" then
    end
end

function agent_syn_call_ack(self, id, ret)
    --print("sync all back ", id, ret)
    local co = getCoroPend("syncall", id) 
    coroutine.resume(co, ret)
end

function agent_migrate_ack(self, pid, map, ret)
    if ret ~= -1 then
        local ply = getPlayer(pid)
        if ply then
            local build = ply._build or {}
            for k, v in pairs(build) do
                build_t.clr(v)
            end
            ply._build = nil
        end

        local hero = ply._hero or {}
        for k, v in pairs(hero) do
            hero_t.clr(v)
        end
        ply._hero = nil

        local equip = ply._equip or {}
        for k, v in pairs(equip) do
            v:clr()
            gPendingSave.equip[ k ] = v
        end
        ply._equip = nil

        local item = ply.item or {}
        gPendingSave.item[ pid ] = nil
        ply.item = nil

        local count = ply._count or {}
        for k, v in pairs(count) do
            gPendingSave.count[ ply.pid ][k] = nil
        end
        ply._count = nil

        local ache = ply._ache or {}
        for k, v in pairs(ache) do
            gPendingSave.ache[ ply.pid ][k] = nil
        end
        ply._ache = nil

        --local arm = data.arm
        --local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
        --ply.my_troop_id = troop._id
        --for id, num in pairs( arm ) do
        --    troop:add_soldier( id, num )
        --end

        local db = ply:getDb()
        db.task:delete({_id=ply.pid}) 
    else
        self:add_debug( "can not move" )
    end
end


    function agent_migrate( self, pid, x, y, data , task, timers, union_pro)
    --print("jump to server ", pid)
        -- 是否有空位    
        local from = self.pid
        if c_map_test_pos( x, y, 4 ) ~= 0 then
            Rpc:callAgent( from, "agent_migrate_ack", pid, -1 ) 
            return
        end

        local eid = get_eid_ply()

    local pro = data._pro
    pro.eid = eid
    pro.map = gMapID
    local ply = player_t.new( pro )
    --ply.x = x
    --ply.y = y
    ply.sockid = data.sockid 
    ply.tm_login = data.tm_login
    rawset( ply, "eid", eid )

    local build = data._build or {}
    local bs = {}
    for k, v in pairs( build ) do
        b = v._pro
        bs[ b.idx ] = build_t.new( b )
    end
    ply._build = bs


    local hero = data._hero or {}
    local hs = {}
    for k, v in pairs(hero) do
        hs[v.idx] = hero_t.new(v)
    end
    ply._hero = hs

    local equip = data._equip or {}
    local es = {}
    for k, v in pairs(equip) do
        local id = getId("equip")
        v._id = id
        gPendingSave.equip[ id ] = v
        es[id] = v
    end
    ply._equip = es


    local item = data.item or {}
    gPendingInsert.item[ pid ] = item
    ply.item = item

    local count = data._count or {}
    for k, v in pairs(count) do
        gPendingSave.count[ ply.pid ][k] = v
    end
    ply._count = count

    local ache = data._ache or {}
    for k, v in pairs(ache) do
        gPendingSave.ache[ ply.pid ][k] = v
    end
    ply._ache = ache

    --local arm = data.arm
    --local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
    --ply.my_troop_id = troop._id
    --for id, num in pairs( arm ) do
    --    troop:add_soldier( id, num )
    --end
    ply:initEffect()

    ply:init_task()
    ply:init_from_db(task)
    local db = ply:getDb()
    db.task:update({_id=ply.pid}, {["$set"]=task}, true) 


    player_t._cache[pid] = pro
    gEtys[ eid ] = ply
    ply.size = 4
    etypipe.add(ply)

    for k, v in pairs(timers) do
        timer._sns[v._id] = v
        timer.newTimer(v)
        timer.mark(v)
    end

    local union = unionmng.get_union(ply.uid)
    if not union then
        local u = union2_t.new(union_pro)
        u.map_id = self.pid
        unionmng.add_union2(u)
        ply._union = u
    else
        ply._union = union
    end

    --Rpc:callAgent( self.pid, "agent_migrate_ack", pid, self.pid, pid ) 

    if ply then
        pushHead(_G.GateSid, 0, 9)  -- set server id
        pushInt(ply.sockid)
        pushInt(self.pid)
        pushInt(ply.pid)
        pushOver()
        player_t.login( ply, ply.pid )
    end

end

function ack_tool(pid, sn, data)
    if data.api then
        player_t[data.api](data)
    end
end

