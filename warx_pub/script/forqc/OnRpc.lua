
local OnRpc = {}

function OnRpc.first_packet_ack( p, code )
    if code == 8 then
        local info = {}
        local idx = p.idx
        info.server_id = p.map or config.Map
        info.cival = ( idx % 4 ) + 1
        info.pid = -1 
        info.token_expire = gTime + 36000
        info.extra = ""
        info.time = gTime
        info.token = c_md5( p.account )
        info.open_id = p.account

        info.signature = c_md5( APP_KEY .. tostring( info.token_expire ) .. info.extra .. tostring( info.time ) .. info.token .. info.open_id )
        info.version = 10000000
        Rpc:firstPacket( p, p.map or config.Map, info )
    end
end

function OnRpc.onLogin( p, pid, name )
    p.action = "player"
    p.pid = pid
    p.name = name
    p.online = gTime
    gPlys[ pid ] = p

    Rpc:getTime(p,1)
    print( "onLogin", pid )

    if type( idx ) == "number" then
        --local chg_name = string.format("R_%s", idx )
        local chg_name = make_name.make_name()
        if name ~= chg_name then
            change_name( p, chg_name )
        end
    end
end

function OnRpc.getTime( p,tag,tm,sm)
    p.stm = tm - gTime
end


gCountLoadData = 0
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
    elseif key == "done" then
        gCountLoadData = gCountLoadData + 1
        if gCountLoadData % 100 == 0 then
            WARN( "USE_TIME, count=%d, use=%d", gCountLoadData, c_msec() - gActionStart )
        end

    else
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
        p.utech = pack.val.info 
    elseif pack.key == "donate" then
        p.donate = pack.val
    elseif pack.key == "union_donate" then
        p.union_donate = pack.val
    elseif pack.key == "fight" then--room
    elseif pack.key == "build" then
        p.buildlv = {} 
        for k, v in pairs(pack.val) do
            if k == "build" then
                for _, v in pairs(pack.val.build or {} ) do
                    if not u.build then u.build = {} end 
                    u.build[v.idx] = v 
                end
            else
                p.buildlv[k]=v
            end
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
--        lxz(mode,data)
        if mode == resmng.OPERATOR.UPDATE then 
            _us[p.uid].build[data.idx] = data
        elseif mode == resmng.OPERATOR.DELETE then 
            _us[p.uid].build[data.idx] = nil
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

function OnRpc.finish_task_resp(p, ret)
    p.task_resp = ret
end

function OnRpc.union_task_get(p, info)
    p.union_task = info
end

function OnRpc.get_can_atk_citys_ack(p,info)
    p.city_propid = {}
    if not _npc then 
        Rpc:get_npc_map_req(p)
        wait_for_ack( p, "get_npc_map_ack")
    end
    for _, propid in pairs(info.can_atk_citys or {}) do
        table.insert(p.city_propid,propid)
    end
end

function OnRpc.get_npc_map_ack(p,info)
    _npc = {} 
    for _, v in pairs(info.map or {}) do
        _npc[v[4]]={ eid = v[1], propid=v[4] }
    end
end

function OnRpc.get_buff(p,k,v)
    if not p.buf then  p.buff = {} end
    p.buff[k] = v
end

function OnRpc.gen_boss_eid_ack(p, eid)
    p.boss_eid = eid
end

function OnRpc.get_eye_info(p, eid, info)
    p.eye_info = info
end

function OnRpc.ety_info_ack(p, info)
    p.ety_info = info
end

function OnRpc.union_tech_info(p, info)
    p.union_tech_info = info
end

function OnRpc.union_donate_info(p, info)
    p.union_donate_info = info
end
function OnRpc.union_buildlv_donate(p, info)
    p.union_buildlv_donate = info
end
function OnRpc.union_tech_info(p, pack)
    p.union_tech_info = pack 
end

function OnRpc.union_mission_get(p,info)
    p.utask = info
end

function OnRpc.dbg_show( p, info )
    local obj = info.ack
    local func = function ( ... )
        local str = string.format( ... )
        print( str )
    end

    if type( obj ) == "table" then
        doDumpTab( obj, nil, 20, 0, true, func )
    else
        print( obj )
    end
end

function OnRpc.get_characters( p, info )
    dumpTab( info, "get_characters" )
end

return OnRpc

