_name = "robot"

function get_one2(acc,culture )
    local pid = -1
    local culture = culture or 1
    local tm = 0  

    os.execute("python forqc/new.py "..acc)
    dofile( "/tmp/new.lua" )
    if _pids[acc] then
        for k, v in pairs( _pids[acc].pid or {} ) do
            if v.map == getMap() and v.tm > tm then 
                cluture = v.culture
                pid = k 
                tm = v.tm
            end
        end
        local sid = connect(config.GateHost, config.GatePort, 0, 0 )
        if sid then
            local node = {  gid = sid, 
                            account = acc, 
                            pid = pid, 
                            token = _pids[acc].token, 
                            openid = _pids[acc].open_id, 
                            action = "login", 
                            idx = _pids[acc].signature, 
                            time=_pids[acc].time, 
                            culture = culture, 
                            _etys = {},
                        }
            gConns[ sid ] = node
            gHavePlayers[node.idx] = node 
            wait_for_ack( node, "onLogin" )
            loadData( node )
            sync( node )
            back( node )
            return node
        end
    end
end

function back( p )
    local back = {}
    for k, v in pairs( p._troop or {} ) do table.insert(back,k) end
    for _, v in pairs( back ) do Rpc:troop_recall(p,v) end
    while next(p._troop) do
        sync( p )
        for k, v in pairs( p._troop or {} ) do 
            troop_acc(p,v._id)  
            wait_for_ack( p, "upd_arm" )
        end
    end
    --lxz(p._troop)
end

function set_build( p, propid, x, y, range )
    range = range or 50
    if _us and _us[p.uid] then
        while true do
            for k, v in pairs( _us[p.uid].build or {} ) do
                if v.propid == propid  then
                    p._etys[ v.eid ] = v
                    return v
                end
            end
            local tx = x + math.random( 1, 2 * range ) - range
            local ty = y + math.random( 1, 2 * range ) - range
            if tx >= 0 and tx < 1280 then
                if ty >= 0 and ty < 1280 then
                    print( tx, ty )
                    Rpc:union_build_setup(p,0,propid,tx,ty,"")
                    sync( p )
                end
            end
        end
    end
end

function build( p, obj,f )
    chat( p, "@initarm" )
    sync( p )
    local arms = {}
    for id, num in pairs( p._arm ) do arms[ id ] = 10000 break end
    Rpc:union_build(p, obj.eid, {live_soldier=arms} ) 
    if f then chat( p, "@debug" ) end
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
                    wait_for_ack( p, "stateTroop" )
                    if f then chat( p, "@undebug" ) end
                    return 
                end
            end
        end
    end
end

function atk( p, obj )
    chat( p, "@initarm" )
    sync( p )
    local arms = {}
    for id, num in pairs( p._arm ) do arms[ id ] = 10000 break end
    Rpc:siege(p, obj.eid, {live_soldier=arms} ) 
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
                    wait_for_ack( p, "stateTroop" )
                    return 
                end
            end
        end
    end
end

function gather( p, obj )
    chat( p, "@initarm" )
    local arms = {}
    for id, num in pairs( p._arm ) do arms[ id ] = 10000 break end
    Rpc:gather(p, obj.eid, {live_soldier=arms} ) 
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
                    wait_for_ack( p, "stateTroop" )
                    return 
                end
            end
        end
    end

end

function troop_acc( p, id)
    chat( p, "@set_val=gold=100000000" )
    sync( p )
    while true do
        local flag = false
        local t = p._troop[id]
        if t and t.tmOver > get_tm(p) + 2 then
            Rpc:troop_acc( p, t._id, 7014001 )
            sync( p )
        else
            return 
        end
    end
end

function load_account()
    local db = dbmng:getOne()
    local infos = db.player:find( {}, {pid=1, account=1, token=1, culture=1} )
    local openids = g_openids
    while infos:hasNext() do
        local info = infos:next()
        local node = openids[ info.account ]
        if node then
            --node.token = info.token
            node.pid = info.pid
            node.culture = info.culture
        end
    end

    local ts = {}
    for k, v in pairs( openids ) do
        v.openid = k
        local idx = tonumber( string.sub( v.account, 7 ) )
        v.idx = idx
        ts[ idx ] = v
    end

    gHavePlayers = ts
    g_openids = nil
    print( "load_account", #gHavePlayers )
    begJob()
end


function start_action(mod, idx)
    local t1 = require( mod )
    local tips = t1.action( 0 )
    print( tips, mod )
    if tips=="ok" then
        os.execute("echo "..mod..">> /tmp/check.csv")
    end
end

function wait_for_ack( p, fname )
    local node = gCoroWaitForAck[ p.gid ]
    if not node then 
        node = {}
        gCoroWaitForAck[ p.gid ] = node
    end
    local co = coroutine.running()
    table.insert( node, { fname, co } )
    coroutine.yield( "rpc" )
end

function wait_for_time( secs )
    local sn = getSn( "wait_for_time" )
    timer.new_ignore( "wait_for_time", secs, sn )
    local co = coroutine.running()
    gCoroWaitForTime[ sn ] = co
    coroutine.yield( "wait_for_time" )
end

function sync( p )
    local sn = getSn( "sync" )
    Rpc:sync( p, sn )
    
    while true do
        if p.sn and p.sn >= sn then return end
        wait_for_ack( p, "sync" )
    end
end

function do_get_one( culture )
    for k, v in ipairs( gHavePlayers ) do
        if not gPlys[ v[1] ] then
            if not culture or v[4] == culture then
                table.remove( gHavePlayers, k )
                table.insert( gHavePlayers, v )
                return v[2], v[1], v[3]
            end
        end
    end

end


function do_get_new_one()
    while true do
        local account 
        while true do
            local idx = getSn( _name )
            if idx >= 20000 then  idx = setsnstart( _name ) end
            account = _name..idx 
            local hit = false

            for _, v in pairs( ghaveplayers or {} ) do
                if v[ 2 ] == account then
                    hit = true
                    break
                end
            end
            if not hit then break end
        end

        return account, -1, "c67sahejr578aqo3l8912oic9"
    end
end


function get_one( is_new )
    local idx 
    if is_new then
        for k, v in ipairs( gHavePlayers ) do
            if not v.pid then
                idx = k
                break
            end
        end
    else
        for k, v in pairs( gHavePlayers ) do
            if v.pid and not v.online then
                idx = k
                break
            end
        end
    end

    if idx then
        local node = gHavePlayers[ idx ]
        if node then
            if not node.token then
                local openid, token, signature, time = make_login( node.account )
                node.token = token
                node.time = time
            end
            local sid = connect(config.GateHost, config.GatePort, 0, 0 )
            if sid then
                local t = { action= "login", gid = sid, idx = idx }
                gConns[ sid ] = t
                wait_for_ack( t, "onLogin" )
                return t
            end
        end
    end
end

function get_account( idx ) -- robot_idx
    local node = gHavePlayers[ idx ]
    if node then
        if not node.token then
            local openid, token, signature, time = make_login( node.account )
            node.token = token
            node.time = time
        end
        local sid = connect(config.GateHost, config.GatePort, 0, 0 )
        if sid then
            local t = { action= "login", gid = sid, idx = idx }
            gConns[ sid ] = t
            wait_for_ack( t, "onLogin" )
            return t
        end
    end
end


function get_tm( p )
    return (gTime + p.stm)
end

function logout( p )
    local sid = p.gid
    shutdown( sid )
    gConns[ sid ] = nil
    print( "logout", gHavePlayers[ p.idx ].account, p.pid )
    if p.pid then gPlys[ p.pid ] = nil end
    gHavePlayers[ p.idx ].online = nil
end


function loadData( p )
    Rpc:getTime(p,1)
    Rpc:loadData( p, "pro" )
    Rpc:loadData( p, "item" )
    Rpc:loadData( p, "equip" )
    Rpc:loadData( p, "build" )
    Rpc:loadData( p, "hero" )
    Rpc:loadData( p, "troop" )
    Rpc:loadData( p, "arm" )
    if p.uid ~= 0  then 
        Rpc:union_load( p, "info" )
        Rpc:union_load( p, "member" )
        Rpc:union_load( p, "build" )
    end
    Rpc:loadData( p, "ef_eid" )
    sync( p )
end

function chat( p, str )
    Rpc:chat( p, 0, str, 0 )
    sync( p )
end

function buy_item( p, id, num )
    Rpc:buy_item( p, id, num, 0 )
    sync( p )
end

function get_eye( p, range )
    p._etys = {}
    local sx = p.x
    local sy = p.y
    local x = sx - range
    p._tick_add_ety = c_msec()
    while x < sx + range + 1 do
        local y = sy - range
        while y < sy + range + 1 do
            if x >= 0 and x < 1280 and y >= 0 and y < 1280 then
                Rpc:movEye( p, gMapID, x, y )
            end
            y = y + 16
        end
        x = x + 16
    end

    while true do
        wait_for_time( 2 )
        print( "wait_for_time, back", c_msec(), p._tick_add_ety )
        if c_msec() - p._tick_add_ety > 2000 then 
            return p._etys
        end
    end
end

function move_to( p, dx, dy, range )
    range = range or 50
    buy_item( p, 36, 1 )
    while true do
        local tx = dx + math.random( 1, 2 * range ) - range
        local ty = dy + math.random( 1, 2 * range ) - range
        if tx >= 0 and tx < 1280 then
            if ty >= 0 and ty < 1280 then
                print( tx, ty )
                Rpc:migrate( p, tx, ty )
                sync( p )
                if p.x == tx and p.y == ty then
                    return
                end
            end
        end
    end
end


function get_build( p, class, mode )
    for _, build in pairs( p._build or {} ) do
        local conf = resmng.get_conf( "prop_build", build.propid )
        if conf then
            if conf.Class == class and conf.Mode == mode then return build end
        end
    end
end

function get_item( p, itemid )
    for _, v in pairs( p._item or {} ) do
        if v[ 2 ] == itemid and v[3] > 0 then return v end
    end
end

function create_item( p, itemid, itemnum )
    local item = get_item( p, itemid )
    if item and item[3] > 0 then
        local need = itemnum - item[3]
        chat( p, string.format("@additem=%d=%d", itemid, need) )
        sync( p )
        return get_item( p, itemid )
    else
        chat( p, string.format("@additem=%d=%d", itemid, itemnum ))
        sync( p )
        return get_item( p, itemid )
    end
end


function get_hero( p, id )
    for k, v in pairs( p._hero or {} ) do
        if v.propid == id then return v end
    end

    local conf = resmng.get_conf( "prop_hero_basic", id )
    if not conf then return end

    if not conf.PieceID or not conf.CallPrice then return end

    local itemid = conf.PieceID
    local itemnum = conf.CallPrice

    chat( p, "@clearitem" )
    chat( p, string.format("@additem=%d=%d", itemid, itemnum ) )

    local item = get_item( p, itemid )
    if not item then return end
    if item[3] ~= itemnum then return end

    Rpc:call_hero_by_piece( p, id )
    sync( p )

    for k, v in pairs( p._hero or {} ) do
        if v.propid == id then return v end
    end
end

function hero_star_up( p, h, star )
    local hero_basic_conf = resmng.get_conf( "prop_hero_basic", h.propid )
    local star_up_conf    = resmng.get_conf("prop_hero_star_up", h.star + 1)

    local itemid = hero_basic_conf.PieceID 
    local itemnum = 0

    for i = 2, star, 1 do
        local conf = resmng.prop_hero_star_up[ i ]
        itemnum = itemnum + conf.StarUpPrice
    end
    itemnum = itemnum + 1

    chat( p, "@clearitem" )
    chat( p, string.format("@additem=%d=%d", itemid, itemnum ) )

    for i = 2, star, 1 do
        Rpc:hero_star_up( p, h.idx )
    end
    sync( p )

    local item = get_item( p, itemid )
    if item[3] == 1 then return "ok" end
end


function use_hero_skill_item( p, hero, itemid, itemnum, skill_idx )
    local item = create_item( p, itemid, itemnum )
    Rpc:use_hero_skill_item( p, hero.idx, skill_idx, item[1], itemnum )
    sync( p )
end

function hero_learn_skill( p, hero, skillid )
    local conf_skill = resmng.get_conf( "prop_skill", skillid )
    if not conf_skill then return false end

    local pskill  
    if conf_skill.Lv > 1 then
        for k, v in pairs( resmng.prop_skill ) do
            if v.Class == conf_skill.Class and v.Mode == conf_skill.Mode and v.Lv == 1 then
                pskill = v
                break
            end
        end
    else
        pskill = conf_skill
    end
    
    local skill_idx = conf_skill.Class 
    if not skill_idx then return false end
    if skill_idx < 1 then return false end
    if skill_idx > 6 then return false end

    local skill_node = hero.basic_skill[ skill_idx ]
    if not skill_node then
        for k, v in pairs( resmng.prop_hero_star_up ) do
            local info = v.StarStatus
            if info[1] == skill_idx and info[2] == 1 then
                hero_star_up( p, hero, k )
                break
            end
        end
    end
    local skill_node = hero.basic_skill[ skill_idx ]
    if not skill_node then return false end

    if skill_node[1] ~= 0 then
        local oskill = resmng.get_conf( "prop_skill", skill_node[1] )
        if not oskill then return false end
        if oskill.Class ~= conf_skill.Class or oskill.Mode ~= conf_skill.Mode then 
            create_item( p, RESET_SKILL_ITME, 1 )
            Rpc:reset_skill( p, hero.idx, pskill.Class )
        end
    end

    local itemid 
    for k, v in pairs( resmng.prop_item ) do
        if v.Class == ITEM_CLASS.SKILL and v.Mode == ITEM_SKILL_MODE.SPECIAL_BOOK then
            if v.Param[1] == skillid then
                itemid = k
                break
            end
        end
    end
end


timer._funs[ "wait_for_time" ] = function( tsn, sn )
    local co = gCoroWaitForTime[ sn ]
    if co then
        gCoroWaitForTime[ sn ] = nil
        coroutine.resume( co )
    end
end

