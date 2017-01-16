
local OnRpc = {}

function OnRpc.onLogin( p, pid, name )
    local idx = p.idx
    local node = gHavePlayers[ idx ]
    print( "login", node.account, pid )

    if not node.pid then node.pid = pid end
    node.online = true

    p.pid = pid
    p.name = name
    p.online = gTime
    gPlys[ pid ] = p
end

function OnRpc.getTime( p,tag,tm,sm)
    p.stm = tm - gTime
end

function OnRpc.loadData( p, info )
    local key = info.key
    local val = info.val
    if key == "pro" then
        for k, v in pairs( val ) do
            p[ k ] = v
        end
    elseif key == "build" then
        local bs = {}
        for k, v in pairs( val ) do
            bs[ v.idx ] = v
        end
        p._build = bs

    elseif key == "troop" then
        p._troop = {}
        for _, v in pairs( val ) do
            p._troop[ v._id] = v
        end
    else
        dumpTab( info, "loadData" )
        p[ "_" .. key ] = val
    end
end


function OnRpc.stateItem( p, info )
    if not p._item then p._item = {} end
    for k, v in pairs( info ) do
        local idx = v[1]
        local node = p._item[ idx ]
        if not node then
            p._item[ idx ] = v
        else
            for ik, iv in pairs( v ) do
                node[ ik ] = iv
            end
        end
    end
end

function OnRpc.stateBuild( p, info )
    if not p._build then p._build = {} end
    local build = p._build[ info.idx ]
    if build then
        for k, v in pairs( info ) do
            build[ k ] = v
        end
    else
        p._build[ info.idx ] = info
    end
end

function OnRpc.statePro( p, info )
    for k, v in pairs( info ) do
        p[ k ] = v
    end
end

function OnRpc.sync( p, sn )
    if not p.sn or sn >= p.sn then
        p.sn = sn
    end
end

function OnRpc.stateTroop( p, info )
    local id = info._id
    if not p._troop then p._troop = {} end
    if info.delete then
        p._troop[ id ] = nil
    else
        p._troop[ id ] = info 
    end
end

function OnRpc.stateHero( p, info )
    if not p._hero then p._hero = {} end
    local node = p._hero[ info.idx ]
    if node then
        for k, v in pairs( info ) do
            node[ k ] = v 
        end
    else
        p._hero[ info.idx ] = info
    end
end

function OnRpc.addEty( p, info )
    if not p._etys then p._etys = {} end
    local obj = etypipe.parse( info )
    p._etys[ obj.eid ] = obj
    p._tick_add_ety = c_msec()
end


function OnRpc.addEtys( p, info )
    for k, v in pairs( info ) do
        OnRpc.addEty( p, v )
    end
    p._tick_add_ety = c_msec()
end


function OnRpc.upd_arm( p, info )
    p._arm = info
end

function OnRpc.get_city_for_robot_ack(p, mode, eid)
    if mode == ACT_NAME.NPC_CITY then
        p.npc_eid = eid
    end
    if mode == ACT_NAME.KING then
        p.king_eid = eid
    end
    if mode == ACT_NAME.LOST_TEMPLE then
        p.lt_eid = eid
    end
end

function OnRpc.union_on_create(p,pack)
    p.uid = pack.uid
    if not _us then _us = {}  end
    _us[p.uid] = pack
    _us[p.uid].build = {}
end

function OnRpc.union_load(p,pack)
    if not _us then _us = {}  end
    if not _us[p.uid] then _us[p.uid] = {}  end
    u = _us[p.uid] 
    if pack.key == "info" then
        u = pack.val
    elseif pack.key == "ply" then
    elseif pack.key == "member" then
        for _, v in pairs( pack.val or {} ) do
            local t = rpchelper.decode_rpc(v,"unionmember")
            if not u.member then u.member = {} end
            u.member[t.pid] = t
        end
    elseif pack.key == "apply" then
        u._apply = pack.val
    elseif pack.key == "mass" then
    elseif pack.key == "aid" then
    elseif pack.key == "tech" then
        u.tech = pack.val.info 
    elseif pack.key == "donate" then
        p.donate = pack.val
    elseif pack.key == "union_donate" then
        u.donate = pack.val
    elseif pack.key == "fight" then--room
    elseif pack.key == "build" then
        if pack.val then u.build = pack.val.build end
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
    elseif pack.key == "ef" then
    end
end

function OnRpc.union_broadcast(p,key,mode,data)
    if key == "build" then
        if mode == 2 then 
            _us[p.uid].build[data.idx] = data
        end
    end
end

function OnRpc.ack_troop_info(p, info)
    local count = 0
    for k, arm in pairs(info.arms or {}) do
        for _, num in pairs(arm) do
            count = count + num
        end
    end
    p.arm_count = count
end

return OnRpc

