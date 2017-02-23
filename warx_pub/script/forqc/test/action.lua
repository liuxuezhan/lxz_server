_name = "robot"

function get_one2(acc,culture )
    local pid = -1
    local culture = culture or 1
    local tm = 0  

    os.execute("python forqc/new.py "..acc.." "..getMap())
    dofile( "/tmp/new_"..getMap()..".lua" )
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
            return node
        end
    end
end

function back( p )
    local back = {}
    for k, v in pairs( p._troop or {} ) do table.insert(back,k) end
    for _, v in pairs( back ) do Rpc:troop_recall(p,v) end
    while next(p._troop or {} ) do
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
        for i=1,range * range do
            for k, v in pairs( _us[p.uid].build or {} ) do
                if v.propid == propid  then
                    if not p._etys then p._etys={}  end 
                    p._etys[ v.eid ] = v
                    return v
                end
            end
            local tx = x + math.random( 1, 2 * range ) - range
            local ty = y + math.random( 1, 2 * range ) - range
            if tx >= 0 and tx < 1280 then
                if ty >= 0 and ty < 1280 then
--                 print( tx, ty )
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
                    if f then 
                        chat( p, "@undebug" ) 
                    else
                        wait_for_ack( p, "union_broadcast" )
                    end
                    return 
                end
            end
        end
    end
end

function atk( p, obj )

    if is_npc_city(obj) then
        chat( p, "@debug" )
        Rpc:declare_tw_req(p, obj.eid)
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
                    wait_for_ack( p, "stateTroop" )
                    back(p)
                    chat( p, "@fighttw" )
                    break
                end
            end
        end
    end

    chat( p, "@addarm=4010=10000" )
    local arms = {}
    local heros = {}
    for id, num in pairs( p._arm ) do 
        arms[ id ] = 10000 
        local hero = get_hero( p, 1 )
        if not hero then return "nohero" end
        Rpc:hero_cure_quick(p, hero.idx, 10)
        sync( p )
        local conf = resmng.get_conf( "prop_arm", id )
        heros[conf.Mode] = hero.idx
        break 
    end

    Rpc:siege(p, obj.eid, {live_soldier=arms,heros=heros } ) 
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
--                    wait_for_ack( p, "stateTroop" )
                    return 
                end
            end
        end
    end
end

function gather( p, obj )
    local arms = {}
    for id, num in pairs( p._arm ) do 
        local c = resmng.get_conf( "prop_arm", id )
        if c.Mode == 4 and c.Lv == 10 then
            arms[ id ] = 100000 
            break 
        end
    end
    Rpc:gather(p, obj.eid, {live_soldier=arms} ) 
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
                    return 
                end
            end
        end
    end

end

function save_res( p, obj )
    Rpc:union_save_res(p, obj.eid, {[1]=100*1000} ) 
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
                    return 
                end
            end
        end
    end

end
function get_res( p, obj )
    Rpc:union_get_res(p, obj.eid, {[1]=100*1000} ) 
    while true do
        sync( p )
        for k, v in pairs( p._troop or {}  ) do
            if v.target == obj.eid then 
                if  v.action < 200 then 
                    troop_acc(p,v._id) 
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


function get_one( is_new, culture )
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
                if is_new then t.culture = culture end
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
    sync( p )
    if p.uid and p.uid ~= 0  then 
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
    itemnum = itemnum + 500

    chat( p, "@clearitem" )
    chat( p, string.format("@additem=%d=%d", itemid, itemnum ) )

    for i = 2, star, 1 do
        Rpc:hero_star_up( p, h.idx )
    end
    sync( p )

    local item = get_item( p, itemid )
    if item[3] == 1 then return "ok" end
end

function hero_lv_up(p, h, lv)
    local h_lv = h.lv
    local quality = h.quality
    local total = 0
    for i = h_lv + 1 , lv, 1 do
        local exp_conf = resmng.get_conf("prop_hero_lv_exp", i)
        local need = exp_conf.NeedExp[quality]
        total = total + need
    end
    local num = math.ceil(total/ 1000)
    local cmd = "@additem=" .. "4003003=" .. tostring(num)
    chat(p, cmd)
    loadData(p)
    local idx = item_idx(p, 4003003)
    Rpc:hero_lv_up(p, h.idx, idx, num)
    sync(p)
end

function item_idx(p, item_id)
    for k, v in pairs(p._item) do
        if v[2] == item_id then
            return k
        end
    end
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

function atk_lt(p, city_lv)
    city_lv = city_lv or 1
    if city_lv == 0 then
        city_lv = 1
    end

    local force_tb = 
    {
        {96000, 35000, 40000},
        {71000, 35000, 30000}, 
        {40000, 20000, 20000}, 
    }

    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addbuf=1=-1" )
    chat(p, "@debug1")
    local cmd = "@resetcity=" .. tostring(ACT_NAME.LOST_TEMPLE)
    chat(p, cmd)

    chat(p, "@startlt")
    WARN("startlt")

    Rpc:get_city_for_robot_req(p, ACT_NAME.LOST_TEMPLE, city_lv)
    wait_for_ack(p, "get_city_for_robot_ack")
    local eid = p.lt_eid
    WARN("get lt %d", eid)
    --local eid = 729095
    p.lt_eid = nil

    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)

    chat(p, "@all")
    local arms = {}
    chat( p, "@addarm=1001010=999999999" )
    for id, num in pairs(p._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end
    Rpc:siege(p, eid, {live_soldier = arms})
    WARN("siege king  %d ", eid)
    sync(p)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    --wait_for_ack( p, "stateTroop" ) 

end

function atk_king(p, city_lv)
    city_lv = city_lv or 1
    if city_lv == 0 then
        city_lv = 1
    end

    local force_tb = 
    {
        {178000, 50000, 30000},
        {178000, 50000, 30000},
        {7800, 50000, 30000},
    }

    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addbuf=1=-1" )
    chat(p, "@debug1")
    local cmd = "@resetcity=" .. tostring(ACT_NAME.KING)
    chat(p, cmd)

    chat(p, "@fightkw")
    WARN("fightkw")

    Rpc:get_city_for_robot_req(p, ACT_NAME.KING, city_lv)
    wait_for_ack(p, "get_city_for_robot_ack")
    local eid = p.king_eid
    WARN("get king %d", eid)
    --local eid = 729095
    p.king_eid = nil

    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)

    chat(p, "@all")
    local arms = {}
    chat( p, "@addarm=1001010=999999999" )
    for id, num in pairs(p._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
            break
        end
    end
    Rpc:siege(p, eid, {live_soldier = arms})
    WARN("siege king  %d ", eid)
    sync(p)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "stateTroop" ) 

end

function acc_troop_by_tid(p, tid)
    chat( p, "@set_val=gold=100000000" )
    buy_item(p, 39, 100)

    ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            --print(t.tmOver,get_tm(a1))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "stateTroop" ) 
end

function atk_by_eid(p, eid, arms)
    Rpc:siege(p, eid, {live_soldier = arms})
    WARN("siege npc  %d ", eid)
    sync(p)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end
    if tid == 0 then
        WARN("no troop")
        return "atk error"
    end

    acc_troop_by_tid(p, tid)

    return tid
end

function atk_npc(p, city_lv)
    city_lv = city_lv or 4
    if city_lv == 0 then
        city_lv = 4
    end
    local force_tb = 
    {
        {207000, 115000, 40000},
        {99000,  55000, 40000},
        {42000, 25000, 40000},
        {25000, 15000, 40000},
    }

    chat( p, "@lvbuild=0=0=30" )
    chat( p, "@buildtop" )
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@addbuf=1=-1" )
    chat(p, "@debug1")
    local cmd = "@resetcity=" .. tostring(ACT_NAME.NPC_CITY)
    chat(p, cmd)

    chat(p, "@starttw")
    WARN("starttw")

    Rpc:get_city_for_robot_req(p, ACT_NAME.NPC_CITY, city_lv)
    wait_for_ack(p, "get_city_for_robot_ack")
    local eid = p.npc_eid
    WARN("get npc %d", eid)
    --local eid = 729095
    p.npc_eid = nil

    local u = gTime % 1000000
    Rpc:union_quit( p ) 
    sync(p)

    Rpc:union_create(p, tostring(u), tostring(u % 1000),40,1000)
    WARN("create u %d ", u)
    sync(p)

    Rpc:declare_tw_req(p, eid) --宣战
    WARN("delcare war  %d ", eid)
    sync(p)

    buy_item(p, 39, 100)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    local ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
            print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack(p, "stateTroop")

    chat(p, "@fighttw")
    chat(p, "@all")
    local arms = {}
    chat( p, "@addarm=1001010=999999" )
    for id, num in pairs(p._arm) do
        if num >  force_tb[city_lv][1] then
            arms[ id ] = force_tb[city_lv][1]
        else
            arms[id] = num
        end
    end
    Rpc:siege(p, eid, {live_soldier = arms})
    WARN("siege npc  %d ", eid)
    sync(p)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
         --   print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack( p, "stateTroop" ) 

end

function spy_ply(p)
    local s_p = get_one(true)
    loadData(s_p)
    chat( s_p, "@lvbuild=0=0=30" )

    Rpc:spy(p, s_p.eid)
    sync(p)
    print("spy ply from to ", p.pid, s_p.pid)

    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == s_p.eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    local ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
         --   print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end

    wait_for_ack(p, "stateTroop")
end

function atk_ply(p)
    local s_p = get_one(true)
    loadData(s_p)
    chat( s_p, "@lvbuild=0=0=30" )
    chat( s_p, "@addres=1=999999999" )
    chat( s_p, "@addres=2=999999999" )

    local h_idx = math.random(20)
    get_hero(s_p, h_idx)

    chat( p, "@set_val=gold=100000000" )
    buy_item(p, 39, 100)
    chat(p, "@all")
    chat( p, "@addbuf=1=-1" )

    local arms = {}
    chat(p, "@initarm")
    for id, num in pairs(p._arm) do
        arms[id] = num
    end
    Rpc:siege(p, s_p.eid, {live_soldier = arms})
    sync(p)

    print("atk ply from to ", p.pid, s_p.pid)


    local tid = 0
    for k, v in pairs(p._troop) do
        if v.target == s_p.eid then
            tid = k
            break
        end
    end

    if tid == 0 then
        WARN("no troop")
        return
    end

    local ts = p._troop
    while true do
        local flag = false
        local t = ts[tid]
        if t then
       --     print(t.tmOver,get_tm(p))
            if t.tmOver > get_tm(p) + 1 then
                 Rpc:troop_acc( p, tid, 7014001 )
                 sync(p)
                 flag = true
            end
        end
        if not flag then break end
    end
end


function join_union(ply, num, level)
    level = level or 10
    for i = 1, num, 1 do
        local p = get_one(true)
        loadData(p)
        local cmd = "@lvbuild=0=0=" .. tostring(level)
        chat( p, cmd )
        Rpc:union_quit( p )
        sync(p)
        Rpc:union_apply(p, ply.uid)
        sync(p)
    end
end

function change_name( p, name )
    chat( p, "@addres=6=200" )
    Rpc:change_name( p, name )
end

