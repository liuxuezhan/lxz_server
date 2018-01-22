_name = "robot"

function back( p )
    local back = {}
    for k, v in pairs( p._troop or {} ) do table.insert(back,k) end
    for _, v in pairs( back ) do Rpc:troop_recall(p,v) end
    sync( p )
    while next(p._troop or {} ) do
        for k, v in pairs( p._troop or {} ) do 
            troop_acc(p,v._id)  
            --lxz()
            --wait_for_ack( p, "upd_arm" )
        end
        Rpc:loadData( p, "troop" )
        sync( p )
    end
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
                    lxz( tx, ty )
                    Rpc:union_build_setup(p,0,propid,tx,ty,"test")
                    sync( p )
                end
            end
        end
    end
    lxz()
end

function build( p, obj,f )
    if obj.state == BUILD_STATE.WAIT then return end
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
                    --wait_for_ack( p, "stateTroop" )
                    if f then 
                        obj = _us[p.uid].build[obj.idx]
                        if obj.state == BUILD_STATE.WAIT then
                            chat( p, "@undebug" ) 
                            return
                        end
                    else 
                        wait_for_ack( p, "union_broadcast" ) 
                        return 
                    end
                end
            end
        end
    end
end

function atk( p, obj )
    back(p)
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
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    local arms = {}
    local heros = {}
    for id, num in pairs( p._arm ) do 
        if num >= 10000 then
            arms[ id ] = 10000 
            local hero = get_hero( p )
            if not hero then lxz() return "nohero" end
            Rpc:hero_cure_quick(p, hero.idx, 10)
            sync( p )
            local conf = resmng.get_conf( "prop_arm", id )
            heros[conf.Mode] = hero.idx
            break 
        end
    end

    Rpc:siege(p, obj.eid, {live_soldier=arms,heros=heros } ) 
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

function gather( p, obj )
    back(p)
    chat( p, "@ef_add=CountSoldier=1000000" )
    chat( p, "@ef_add=CountTroop=2" )
    chat( p, "@addarm=4010=10000000" )
    chat( p, "@addbuf=1=-1" )
    chat( p, "@ef_add=SpeedGather_R=90000000" )
    sync( p )

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
                if  v.action < 200 then troop_acc(p,v._id) return end
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
        if t and (t.tmOver or 0)  > get_tm(p) + 2 then
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


local gActionIdx = 0
function start_action(mod)
    gActionIdx = gActionIdx + 1
    local t1 = require( mod )
    local tips = t1.action( gActionIdx )
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

function sync( p, functor )
    local sn = getSn( "sync" )
    Rpc:sync( p, sn )

    while not functor do
        if p.sn and p.sn >= sn then return end
        wait_for_ack( p, "sync" )
    end

    p._sync_func = p._sync_func or {}
    p._sync_func[sn] = functor
end

function get_account( idx, cival )
    local node = false
    if idx then
        node = gHavePlayers[ idx ]
        if node then
            if node.online then return node end
        end
    else
        local i = 1
        while true do
            if not gHavePlayers[ i ] then
                idx = i
                break
            else
                i = i + 1
            end
        end
    end

    if not node then
        node = { account = c_md5( tostring( idx ) ), idx = idx, pid=0 }
        if cival then node.cival = cival end

        gHavePlayers[ idx ] = node
    end

    local sid = connect(config.GateHost, config.GatePort, 1, 0 )
    if sid then
        node.action = "login"
        node.gid = sid
        gConns[ sid ] = node
        wait_for_ack( node, "onLogin" )
        return node
    end
end

function get_account2( name,url_s,url_u,key,idx )
    local data = {}
    local appid = "045fce0de7f9b8ee9bf12e28c2d6d2cd"
    data.appid = appid 
    data.platform = 1
    data.sig = create_http_sign(data,key)
    local info = post_to( url_s or "http://gw-warx.dev.tapenjoy.com/api/servers/lists", data )
    if not info then return end
    local ip = info.data[gMapID].ip 

    local cid = name 
    local data = {}
    data.appid = appid
    data.ctype = 0
    data.cid = cid
    data.open_udid = cid
    data.os = "android"
    data.language = "cn"
    data.locale = "ase"
    data.mac = "mac"
    data.device_info = "device_info"
    local sig = create_http_sign(data,key)
    data.sig = sig
    info = post_to( url_u or "http://uc.dev.tapenjoy.com/api/user/login", data )

    local node = info.data
    node.map = gMapID
    node.account = node.uid
    node.did = UDID
    node.pid = 0
    if not idx then
        local i = 1
        while true do
            if not gHavePlayers[ i ] then
                idx = i
                break
            else i = i + 1 end
        end
    end
    node.idx = idx
    gHavePlayers[ idx ] = node

    local sid = connect(ip, 8001, 1, 0 )
    if sid then
        node.action = "test_login"
        node.gid = sid
        gConns[ sid ] = node
        wait_for_ack( node, "onLogin" )
        loadData( node )
        Rpc:set_client_parm(node, "guidedclass","1|2|3|4|5|6|7|9|10|12|13|14|15|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|40|43|44|45|46|47|48|49|50|51|52|53|55|56|57|66|67|68|101|102|103|104|105")  
        sync(node)
        return node 
    end
end

function post_to( url, data )
    local tmpfile = string.format( "download.%d", gTime )
    os.execute( "rm -rf ".. tmpfile )

    print( url )

    local info = Json.encode( data )
    local cmd = string.format( "curl -X POST -s -o %s -d \'%s\' %s", tmpfile, info, url )

    os.execute( cmd )
    local f = io.open( tmpfile, "r" )
    if not f then return end
    local str = f:read()
    os.execute( "rm -rf ".. tmpfile )
    return Json.decode( str )
end

function create_http_sign(tab,key)
    local sign = key or "1a4d7ea4895af21dd945ead32e9b1eae"
    local tab_key = {}
    tab.timestamp = gTime
    for k,v in pairs(tab) do
        table.insert(tab_key, k)
    end
    table.sort(tab_key, function ( a, b )
        return tostring(a) < tostring(b)
    end)
    for i=1,#tab_key do
        sign = sign.. tostring(tab[tab_key[i]])
    end
    return c_md5(sign)
end




function get_tm( p )
    return (gTime + p.stm)
end

function logout( p )
    local sid = p.gid
    shutdown( sid )
    gConns[ sid ] = nil
    if p.pid then gPlys[ p.pid ] = nil end
    gHavePlayers[ p.idx ].online = nil
end


function loadData( p )
    --Rpc:get_device_grade( p, "All Series (ASUS)", "NVIDIA GeForce GT 610", 3192, 4 )
    Rpc:getTime( p, gTime )
    Rpc:loadData( p, "pro" )
    Rpc:loadData( p, "build" )
    Rpc:union_load( p, "info" )
    Rpc:union_load( p, "build" )
    Rpc:loadData( p, "ef_eid" )
    Rpc:loadData( p, "item" )
    Rpc:loadData( p, "hero" )
    Rpc:loadData( p, "troop" )
    Rpc:loadData( p, "equip" )
    Rpc:loadData( p, "arm" )
    Rpc:loadData( p, "task" )
    Rpc:get_gs_buf( p )
    Rpc:loadData( p, "watch_tower" )
    Rpc:loadData( p, "client_param" )
    Rpc:loadData( p, "first_blood" )
    Rpc:loadData( p, "sys_option" )
    Rpc:act_info_req( p )
    Rpc:push_ntf_list_req( p, {} )
    Rpc:loadData( p, "tech" )
    Rpc:loadData( p, "done" )
    --Rpc:chat_account_info_req( p )
    Rpc:up_jpush_info_req( p, {} )
    Rpc:get_server_tag_req( p )
    Rpc:ache_info_req( p )
    Rpc:get_world_event_process( p )
    Rpc:operate_activity_list( p )
    Rpc:fetch_chat( p, -1, -1, 10 )
    --Rpc:union_mission_log( p, 0, 0 )
    Rpc:get_can_buy_list_req( p )
    sync( p )
    Rpc:addEye( p, gMapID, p.x, p.y )
    sync( p )

    Rpc:accept_hero_road_chapter(p, 1)
    Rpc:set_client_parm(p, "guidedclass","1|2|3|4|5|6|7|9|10|12|13|14|15|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31|32|33|34|35|36|37|38|40|43|44|45|46|47|48|49|50|51|52|53|55|56|57|66|67|68|101|102|103|104|105")  
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
        wait_for_time( 10 )
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
        --local conf = resmng.get_conf( "prop_build", build.propid )
        local conf = resmng.prop_build[build.propid]
        if conf then
            if conf.Class == class and conf.Mode == mode then return build, conf end
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
        chat( p, "@adddaoju="..itemid.."="..need )
        sync( p )
        return get_item( p, itemid )
    else
        chat( p, "@adddaoju="..itemid.."="..itemnum )
        sync( p )
        return get_item( p, itemid )
    end
end

function get_born_heroid(player)
    local heroid = 201
    if 2 == player.culture then
        heroid = 205
    elseif 3 == player.culture then
        heroid = 204
    elseif 4 == player.culture then
        heroid = 206
    end
    return heroid
end

function get_born_hero(player)
    return get_hero(player, get_born_heroid(player))
end

function get_hero( p, id )
    for k, v in pairs( p._hero or {} ) do
        if (not id) or (v.propid == id) then return v end
    end
    id = id or 201

    local c = resmng.get_conf( "prop_hero_basic", id )
    chat( p, "@adddaoju="..c.PieceID.."="..c.CallPrice )
    Rpc:call_hero_by_piece( p, id )
    sync( p )

    for k, v in pairs( p._hero or {} ) do
        if v.propid == id then return v end
    end
end

function hero_star_up( p, h, star )
    local hero_basic_conf = resmng.get_conf( "prop_hero_basic", h.propid )

    local itemid = hero_basic_conf.PieceID 
    local itemnum = 0

    for i = 2, star, 1 do
        local conf = resmng.prop_hero_star_up[ i ]
        itemnum = itemnum + conf.StarUpPrice
    end
    itemnum = itemnum + 500

    chat( p, "@adddaoju="..itemid.."="..itemnum )
    for i = 2, star, 1 do
        Rpc:hero_star_up( p, h.idx )
    end
    sync( p )

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
    local num = math.ceil(total/ 10)
    Rpc:loadData(p, "item")
    wait_for_ack(p, "loadData")
    local idx = item_idx(p, 4003001)
    if idx then
        Rpc:hero_lv_up(p, h.idx, idx, num)
        sync(p)
    end
end

function item_idx(p, item_id)
    for k, v in pairs(p._item) do
        if v[2] == item_id then
            return k
        end
    end
end


function use_hero_skill_item( p, hero, itemid, itemnum, sn )
    sn = sn or 1 
    local item = create_item( p, itemid, itemnum )
    Rpc:use_hero_skill_item( p, hero.idx, sn, item[1], itemnum )
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

function condCheck(p, tab, num)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if class == "OR" or class == "AND" then 
                if not doCondCheck(p, unpack(v) ) then return false 
                end
            elseif not doCondCheck(p, class, mode, math.ceil( (lv or 0)* num ) ) then 
                return false
            end
        end
    end
    return true
end


function doCondCheck(p, class, mode, lv, ...)
    if class == "OR" then
        local f,c,m,l 
        for _, v in pairs({mode, lv, ...}) do
            if doCondCheck(p,unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then 
        for _, v in pairs({mode, lv, ...}) do
            if not doCondCheck(p,unpack(v)) then return false, class, mode, lv end
        end
        return true

    elseif class == resmng.CLASS_RES then
        -- if mode == resmng.DEF_RES_FOOD then
        --     if p.food - (gTime-p.foodTm)*p.foodUse / 3600 >= lv then return true end
        -- elseif mode == resmng.DEF_RES_WOOD then
        --     if p.wood >= lv then return true end
        -- end
    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            for _, v in pairs( p._build or {} ) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == t.Class and n.Mode == t.Mode then 
                    if n.Lv >= t.Lv then return true 
                    else build_up(p,v.propid+1,1) return end
                end
            end
            build_up( p, mode - t.Lv + 1 , 1 )
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = resmng.prop_genius[ mode ]
        if t then
            for _, v in pairs(p.genius) do
                local n = resmng.prop_genius[ v ]
                if n and n.Class == t.Class and n.Mode == t.Mode then
                    if n.Lv >= t.Lv then return true end
                    genius(p,t.ID,n.Lv+1)
                    return
                end
            end
            genius(p,mode,1)
        end
    elseif class == resmng.CLASS_TECH then
        local t = resmng.prop_tech[ mode ]
        if t then
            for _, v in pairs(p._tech or {} ) do
                local n = resmng.prop_tech[ v ]
                if n and n.Class == t.Class and n.Mode == t.Mode then 
                    if n.Lv >= t.Lv then return true end
                    tech(p, mode,n.Lv+1)
                    return
                end
            end
            tech(p, mode,1)
        end
    elseif class == resmng.CLASS_TASK_FINISH then
        return is_task_finished(p, mode)
    end
    return false, class, mode, lv
end

function tech(p, id,lv,add,quick)
    local c = resmng.prop_tech[id]
    for _, v in pairs(p._tech or {} ) do
        local n = resmng.prop_tech[ v ]
        if n and n.Class == c.Class and n.Mode == c.Mode then 
            if n.Lv >= lv then return true end

            id = c.Class*1000*1000 + c.Mode*1000 
            for i=n.Lv+1,lv do
                c = resmng.prop_tech[id+i]
                if not  condCheck(p,c.Cond) then return end
                tech_do(p,c.ID,add,quick)
            end
            return true
        end
    end

    lv = lv or c.Lv + 1
    for i=1,lv do
        id = c.Class*1000*1000 + c.Mode*1000 
        c = resmng.prop_tech[id+i]
        if not condCheck(p,c.Cond) then return end
        tech_do(p,c.ID,add,quick)
    end
    return true  
end


function tech_do(p, id,add,quick)
    local v = resmng.prop_tech[id] 
    local buff = {}
    for k, v in pairs( add or v.Effect ) do 
        Rpc:get_buff( p, k )
        wait_for_ack( p, "get_buff" )
        buff[k]=p.buff[k]
    end

    quick = quick or 1
    Rpc:learn_tech(p,1001,id,quick)
    Rpc:loadData( p, "tech" )
    sync(p)
    for what, _ in pairs( buff ) do 
        Rpc:get_buff( p, what )
        wait_for_ack( p, "get_buff" )
        if not add[what] then 
            if  v.Lv > 1 then
                add[what] = v.Effect[what] - resmng.prop_tech[v.ID-1].Effect[what]
            else
                add[what] = v.Effect[what] 
            end
        end
        if buff[what] + add[what]  == p.buff[what] then 
            os.execute("echo tech,"..id..",ok >> /tmp/check.csv")
        else
            lxz(what) 
            os.execute("echo tech,"..id..",fail,"..what.." >> /tmp/check.csv")
        end
    end
end

function genius(p, id,lv,add)
    local c = resmng.prop_genius[id]
    for _, v in pairs(p.genius or {} ) do
        local n = resmng.prop_genius[ v ]
        if n and n.Class == c.Class and n.Mode == c.Mode then 
            if n.Lv >= lv then return true end

            id = c.Class*1000*1000 + c.Mode*1000 
            for i=n.Lv+1,lv do
                c = resmng.prop_genius[id+i]
                if not  condCheck(p,c.Cond) then return end
                genius_do(p,c,add)
            end
            return true
        end
    end

    lv = lv or c.Lv + 1
    for i=1,c.Lv do
        id = c.Class*1000*1000 + c.Mode*1000 
        c = resmng.prop_genius[id+i]
        if not condCheck(p,c.Cond) then return end
        genius_do(p,c,add)
    end
    return true  
end

function genius_do(p, v, add )
    lxz(v.ID)
    local buff = {}

    for k, v in pairs( add or v.Effect ) do 
        Rpc:get_buff( p, k )
        wait_for_ack( p, "get_buff" )
        buff[k]=p.buff[k]
    end

    Rpc:do_genius(p,v.ID)
    Rpc:loadData( p, "pro" )
    sync(p)
    if not next(buff) then return end
    for what, _ in pairs( buff ) do 
        Rpc:get_buff( p, what )
        wait_for_ack( p, "get_buff" )
        if not add then 
            if  v.Lv > 1 then
                local del = 0 
                if resmng.prop_genius[v.ID-1].Effect then del = resmng.prop_genius[v.ID-1].Effect[what] or 0 end
                add[what] = v.Effect[what] - del 
            else
                add[what] = v.Effect[what] 
            end
        end
        if buff[what] + add[what]  == p.buff[what] then 
            os.execute("echo genius,"..v.ID..",ok >> /tmp/check.csv")
        else
            lxz(what) 
            os.execute("echo genius,"..v.ID..",fail,"..what.." >> /tmp/check.csv")
        end
    end
end



function build_up( p, propid, quick )
    local t = resmng.prop_build[ propid ]
    if  not t then  lxz(propid) return end

    for _, b in pairs(p._build or {} ) do
        local n = resmng.prop_build[ b.propid ]
        if n and n.Class == t.Class and n.Mode == t.Mode then 
            local i = 1
            local c = resmng.prop_build[b.propid+i]
            if  c  then
                while t.Lv >= c.Lv do
                    if not condCheck(p,c.Cond)  then return false end
                    if not quick then Rpc:one_key_upgrade_build(p,b.idx)
                    else Rpc:upgrade(p,b.idx) end
                    i = i + 1
                    c = resmng.prop_build[b.propid+i]
                    if  not c then break end
                end
            end
        end
    end

end


local no_need_build_list = {
    [resmng.BUILD_MANOR_1] = 1,
    [resmng.BUILD_MONSTER_1] = 1,
    [resmng.BUILD_RELIC_1] = 1,
}

function find_enabled_pos(p)
    local x = 100
    while true do
        local tag = true
        for k, v in pairs(p._build or {}) do
            if v.x == x then
                tag = false
            end
        end
        if tag == true then
            return x
        end
        x = x + 1
    end
end

function construct(p, propid)
    if no_need_build_list[propid] then return end

    local node = resmng.prop_build[ propid ]
    if not node then return end

    if node.Lv ~= 1 then
        for k, v in pairs(resmng.prop_build or {}) do
            if v.Class == node.Class and v.Mode == node.Mode and v.Lv == 1 then
                node = v
            end
        end
    end

    if node and node.Lv == 1 then
        if condCheck(p, node.Cond) then
            local max_seq = (BUILD_MAX_NUM[node.Class] and BUILD_MAX_NUM[node.Class][node.Mode]) or 1
            local x = 0
            if max_seq > 1 then x = find_enabled_pos(p) end
            lxz(p.pid.." construct "..node.ID)
            Rpc:construct(p, x, 0, node.ID)
        else
            for _, v in pairs(node.Cond or {}) do
                if v[1] == 2 then build_or_upgrade(p, v[2]) end
            end
        end
    end
end

function is_already_build(p, propid)
    local prop = resmng.prop_build[propid]
    for _, v in pairs(p._build or {}) do
        if v.propid == propid then
            return true
        end
        local build_prop =  resmng.prop_build[v.propid]
        if build_prop.Class == prop.Class and build_prop.Mode == prop.Mode and build_prop.Lv > prop.Lv then
            return true
        end
    end
    return false
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

    Rpc:get_city_for_robot_req(p, ACT_NAME.LOST_TEMPLE, {lv = city_lv})
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
    for k, v in pairs(p._troop or {}) do
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
            --print(t.tmOver,get_tm(p))
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

    Rpc:get_city_for_robot_req(p, ACT_NAME.KING, {lv = city_lv})
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
    for k, v in pairs(p._troop or {}) do
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
            --print(t.tmOver,get_tm(p))
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

    Rpc:get_city_for_robot_req(p, ACT_NAME.NPC_CITY, {lv = city_lv})
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
    for k, v in pairs(p._troop or {}) do
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
            --print(t.tmOver,get_tm(p))
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
    for k, v in pairs(p._troop or {}) do
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
    -- local s_p = get_one(true)
    local name = tostring(math.random(100,999))
    local s_p = get_account(name)
    loadData(s_p)
    chat( s_p, "@lvbuild=0=0=30" )

    Rpc:spy(p, s_p.eid)
    sync(p)
    print("spy ply from to ", p.pid, s_p.pid)

    local tid = 0
    for k, v in pairs(p._troop or {}) do
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
    local name = tostring(math.random(100,999))
    local s_p = get_account(name)
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
    for k, v in pairs(p._troop or {}) do
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
        --local p = get_one(true)
        local name = tostring(math.random(100,999))
        local p = get_account(name)
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

function get_arm_id_by_mode_lv(mode, lv, class)
    for k, v in pairs(resmng.prop_arm or {}) do
        if v.Class == class and v.Mode == mode and v.Lv == lv then
            return k
        end
    end
end

function tele_debug( p )
    print( "l login" )
    print( "p print" )
    print( "s set" )
    print( "r run" )
    print( "q quit" )
    print( "h help" )

    while true do
        print( ">" )
        local line = io.read( "*line" )
        if line then
            if string.len( line ) > 0 then
                local info = string.split( line, " " )
                if info[1] == "p" then
                    Rpc:dbg_show( p, info[ 2 ] )
                    wait_for_ack( p, "dbg_show" )

                elseif info[1] == "l" then
                    Rpc:dbg_ask( p, info[ 2 ] )
                    wait_for_ack( p, "dbg_show" )

                elseif info[1] == "r" then
                    Rpc:dbg_run( p, string.sub( line, 2, -1 ) )
                    wait_for_ack( p, "dbg_show" )

                elseif info[1] == "s" then
                    if #info == 3 then
                        Rpc:dbg_set( p, info[2], info[3] )
                        wait_for_ack( p, "dbg_show" )
                    end

                elseif info[1] == "h" then
                    print( "l login" )
                    print( "p print" )
                    print( "s set" )
                    print( "r run" )
                    print( "q quit" )

                elseif info[1] == "q" then
                    Rpc:dbg_ask( p, "a" )
                    os.exit(-1)

                end
            end
            wait_for_time( 1 )
        end
    end
end


function union_tech(p,id)
    require("union_tech_t")
    chat(p, "@set_val=gold=100000000")
    chat(p, "@addres=1=10000000")
    chat(p, "@addres=2=10000000")
    chat(p, "@addres=3=10000000")
    chat(p, "@addres=4=10000000")
    sync(p)
    local info = {}
    Rpc:union_tech_info(p, id)
    sync(p)
    local cur = p.union_tech_info
    if not cur then  return end
    local res = p.res
    local gold = p.gold
    table.insert(info,cur)
    local sn = 1
    local reward = {} 
    local res_val =  {} 

    Rpc:union_load(p,"donate")
    Rpc:union_load(p,"union_donate")
    sync(p)
    local donate = p.donate
    local old = p.union_donate
    if (donate.tmOver or 0)  < get_tm(p) then donate.tmOver = get_tm(p) end

    for  i =3,1,-1 do
        if cur.donate[i]~= 0 then 
            sn = i
            Rpc:union_donate(p, id, i)
            sync(p)
        end
    end

    local new = p.union_tech_info
    table.insert(info,new)
    local c = resmng.get_conf("prop_union_donate",union_tech_t.get_class(id))

    --资源检查
    if  sn == 1 then
        res_val =  c.Primary[cur.donate[sn]] 
        reward = c.Pincome 
        if #info > 1 then 
            local i = #info
            for  j = 1,3 do
                if info[i-1].donate[j] ~= 0 and  info[i].donate[j] == 0 then  
                    lxz(info)
                    return -1 
                end
            end
        end
    elseif  sn == 2 then
        res_val =  c.Medium 
        reward = c.Mincome 
    elseif  sn == 3 then
        res_val =  c.Senior 
        reward = c.Sincome 
    end
    Rpc:union_load(p,"donate")
    Rpc:union_load(p,"union_donate")
    sync(p)

    if res_val[1] < 5 then
        if p.res[res_val[1]][1]  + res_val[2] >  res[res_val[1]][1] or  p.res[res_val[1]][1]  + res_val[2] <  res[res_val[1]][1]  - 200  then 
            lxz(p.res,res_val,res) 
            return -1 
        end
    elseif res_val == 6 then
        if p.gold  + res_val[2] ~= gold then lxz() return -1  end
        gold = p.gold
    end

    lxz(old)
    if  old  + reward[1] * 1.4 ~= p.union_donate then 
        lxz()
        return -1 
    end

    if  cur.exp  + reward[3] ~= new.exp  then 
        lxz()
        return -1 
    end

    if  donate.donate  + reward[1] ~= p.donate.donate then 
        lxz()
        return -1 
    end

    if  donate.tmOver ~= 0 and ( donate.tmOver  + c.TmAdd <  p.donate.tmOver - 10 or donate.tmOver  + c.TmAdd >  p.donate.tmOver )  then 
        lxz(donate)
        lxz(p.donate)
        return -1 
    end

    if p.donate.flag == 1 then 
        local g =  0
        gold = p.gold
        if p.donate.CD_num < #resmng.CLEAR_DONATE_COST then
            g = resmng.CLEAR_DONATE_COST[p.donate.CD_num +1]
        else g = resmng.CLEAR_DONATE_COST[#resmng.CLEAR_DONATE_COST] end
        Rpc:union_donate_clear(p) 
        sync(p)
        if p.gold  + g ~= gold then lxz(p.gold ,g ,gold) return -1 end
    end 

    if union_tech_t.is_exp_full(new ) then 
        Rpc:union_tech_upgrade(p,id) 
        return 0
    end
    return 1
end

function mission_set(p,c)
    Rpc:union_mission_get(p)
    sync(p)
    --lxz(p.utask)
    local num = 0
    for k, v in pairs( p.utask.cur ) do
        if v.state ==  TASK_STATUS.TASK_STATUS_CAN_ACCEPT then
            if c then
                if v.class == c then 
                    Rpc:union_mission_set(p,k)
                    break
                end
            else
                Rpc:union_mission_set(p,k)
                num = num + 1
            end
            if num == 3 then break end
        end
    end
    sync(p)
end

function mission_do(p,b)

    Rpc:union_mission_get(p)
    sync(p)
    if not p.utask then return end

    for _, v in pairs( p.utask.cur or {}  ) do
        if v.state ==  TASK_STATUS.TASK_STATUS_ACCEPTED then
            if v.class == UNION_MISSION_CLASS.ACT_PLY then atk(p,b)
            elseif v.class == 12 then union_tech(p,1001)
            elseif v.class == 11 then buildlv(p)
            elseif v.class == 13 then Rpc:chat(p, 0, "@addarm=1010=100000", 0 )
            elseif v.class == 14 then Rpc:union_god_add(p,3 )
            elseif v.class == 21 then 
                build_all(p)
                Rpc:union_help_set(p, 0) 
            elseif v.class == 22 then
                for k, v in pairs( resmng.prop_task_daily) do Rpc:daily_task_done(p,k) end
            elseif v.class == 23 then 
                for _, v in pairs( _us[p.uid].build or {}  ) do
                    local c = resmng.get_conf("prop_world_unit", v.propid)
                    if c.BuildMode == 3  then gather(p,v) end
                end
            elseif v.class == 24 then
                for k, v in pairs( resmng.prop_union_mall) do
                    Rpc:union_mall_add (p, k,1)   --军团长采购道具
                    Rpc:union_mall_buy (p, k,1)    --军团成员买道具
                end
            end
        end

    end

    Rpc:union_mission_get(p)
    sync(p)
    for k, v in pairs( p.utask.cur ) do
        if v.state == 5 then Rpc:union_mission_add(p,k) end
    end
end

function union_create(name,num)
    num = num or 10
    name = math.random(100,999)
    local ps = {}
    local a = get_account(name)
    loadData( a )
    lxz(a.pid)
    local u = _us[a.uid] 
    if u and u.leader ~= a.name then
        chat( a, "@set_val=gold=100000000" )
        --chat( a, "@buildtop" )
        chat( a, "@addbuf=1=-1" )
        Rpc:union_quit(a)
        Rpc:union_create(a,"robot"..name,tostring(name),40,1000)
        wait_for_ack( a, "union_on_create" )
    end
    mission_set(a) 
    table.insert(ps,a)
    lxz(_us[a.uid].name) 

    if num > 1 then
        for i = 2,num do
            local p = get_account()
            loadData( p )
            if p.uid ~= a.uid then
                Rpc:union_quit(p)
                Rpc:union_apply( p,ps[1].uid)
                chat( p, "@set_val=gold=100000000" )
                chat( p, "@buildtop" )
                chat( p, "@addbuf=1=-1" )
                chat( p, "@ef_add=SpeedGather_R=90000000" )
                sync( p)
            end
            table.insert(ps,p)
        end
    end

    if num < 10 then return ps end 

    -- local id = 10021001
    -- local obj = set_build(a, id, a.x, a.y ) 
    -- sync(a)
    -- build(a,obj,1)
    -- sync(a)

    -- id = 10007001
    -- local obj2 = set_build(a, id, obj.x, obj.y, 14 ) 
    -- sync(a)
    -- build(a,obj2,1)


    -- -- id = 10031001
    -- -- obj2 = set_build(a, id, obj.x+50, obj.y+50, 14 ) 
    -- -- sync(a)
    -- -- build(a,obj2,1)

    -- id = 10004001
    -- lxz()
    -- obj2 = set_build(a, id, obj.x, obj.y, 14 ) 
    -- sync(a)
    -- build(a,obj2,1)


    return ps 
end

function buildlv(p)

    chat(p, "@adddaoju=7001001=100")
    chat(p, "@adddaoju=7001002=100")
    chat(p, "@adddaoju=7001003=100")

    chat(p, "@adddaoju=7002001=100")
    chat(p, "@adddaoju=7002002=100")
    chat(p, "@adddaoju=7002003=100")

    chat(p, "@adddaoju=7003001=100")
    chat(p, "@adddaoju=7003002=100")
    chat(p, "@adddaoju=7003003=100")

    chat(p, "@adddaoju=7004001=100")
    chat(p, "@adddaoju=7004002=100")
    chat(p, "@adddaoju=7004003=100")

    for id = 1,3 do
        if not ubuildlv_check(p,id) then return end
    end

    return true
end

function ubuildlv_check(p,id)
    lxz(p.pid,p.buildlv)
    if (p.buildlv.buildlv[id].id % 1000) == 10 then lxz("满级") return  end
    local v = p.buildlv.log[id]
    if not can_date(v.tm,gTime) then lxz("已捐") return  true end
    local item = v.cons
    local c = resmng.get_conf("prop_union_buildlv",p.buildlv.buildlv[id].id + 1 )
    if c then 
        local cc = resmng.get_conf("prop_union_buildlv",p.buildlv.buildlv[id].id  )
        local old = AddBonus_on(p, cc.BonusID)
        --lxz(p.silver,old)
        local exp = p.buildlv.buildlv[id].exp + c.DonateExp

        Rpc:union_buildlv_donate(p,id)
        Rpc:union_load( p,"build" )
        sync(p)

        if not AddBonus_off(p,old) then lxz() return end

        if exp < c.UpExp then
            if  exp ~= p.buildlv.buildlv[id].exp then lxz(p.buildlv.buildlv[id],exp) return end
        else
            if  exp - c.UpExp  ~= p.buildlv.buildlv[id].exp then lxz() return end
            if  c.ID  ~= p.buildlv.buildlv[id].id then lxz() return end
        end
    end
    return true
end


function get_val(player, what, ...)
    --local ef_u,ef_ue = player:get_union_ef()
    local ef_u, ef_ue = {}, {}
    local ef_s = player._ef
    local ef_gs = {}
    --local ef_gs = kw_mall.gsEf or {} -- globle buff
    if ... == nil then
        return get_val_by(what, ef_s, ef_u, ef_ue, ef_gs)
    else
        return get_val_by(what, ef_s, ef_u, ef_ue, ef_gs, ...)
    end
end

function is_task_finished(player, task_id)
    for k, v in pairs(player._task.finish) do
        if v == task_id then
            return true
        end
    end
    for k, v in pairs(player._task.cur) do
        if v.task_id == task_id and v.task_status == TASK_STATUS.TASK_STATUS_CAN_FINISH then
            return true
        end
    end
end

function get_troop(player, troop_id)
    return player._troop[troop_id]
end

function AddBonus_on(p,Param,t)
    local old = {}
    if  t == "AddBuf" then
        local cc = resmng.buff[Param[1]]
        for k, v in pairs( cc.Value ) do 
            Rpc:get_buff( p, k )
            wait_for_ack( p, "get_buff" )
            old[k]=p.buff[k] + v
        end
    else
        for _, v in pairs( Param[1][2] or c.Param[1][2] ) do 
            if v[1] =="item" then
                old.item = old.item or {}
                for _, obj in pairs(p._item or {} ) do
                    if v[2]==obj[2] then
                        old.item[v[2]]= old.item[v[2]] or 0  + obj[3] 
                    end
                end
                old.item[v[2]]= (old.item[v[2]] or 0 ) + v[3] 
            elseif v[1] == "res" then
                old.res = res_on(p,v,old.res)
            elseif v[1] == "respicked" then
            elseif v[1] == "soldier" then
            elseif v[1] == "hero_exp" then
            elseif v[1] == "hero_buff" then
            elseif v[1] == "hero" then
            elseif v[1] == "equip" then
            end
        end
    end
    return old
end

function AddBonus_off(p,old,t)
    if  t == "AddBuf" then
        for what, v in pairs( old ) do 
            Rpc:get_buff( p, what )
            wait_for_ack( p, "get_buff" )
            if v  ~= p.buff[what] then return end
        end
    else
        for name, o in pairs( old ) do 
            if name =="item" then
                Rpc:loadData( p, "item" )
                sync(p)
                for k, v in pairs(o or {} ) do
                    for idx, vv in pairs(p._item) do
                        if vv[2] ==  k then
                            --                 if c.ID == 7021001  then pause() end
                            if v ~= vv[3] then lxz(k) return end 
                        end
                    end
                end

            elseif name =="res" then
                if not res_off(p,o) then return end
            elseif name =="personalhonor" then
            elseif name =="gold" then
            elseif name =="silver" then
            elseif name =="unithonor" then
            elseif name =="personalhonor" then
            elseif name =="personalhonor" then
            elseif name =="personalhonor" then
            end
        end
    end
    return true
end


function res_on(p,v,res)
    res = res or {}
    local id = v[2]
    local num = v[3]
    if id <= resmng.DEF_RES_ENERGY  then
        res[id] = (p.res[id][1] or 0) + num 
    elseif id == resmng.DEF_RES_MARSEXP then
        res[id] = res[id] or {}  
        while p.uid == 0  do 
            local name = tostring(math.random(100,999))
            Rpc:union_create(p, "robot"..name, name, 40, 1000)
            wait_for_ack(p, "union_on_create")
        end
        Rpc:union_load(p,"mars")
        sync(p)
        local god = p.mars.mars 
        local c = resmng.prop_union_god[god.propid + 1] 
        res[id].propid =  god.propid 
        res[id].exp =  god.exp + num 
        if res[id].exp >= c.Exp  then
            res[id].propid =  res[id].propid + 1
            res[id].exp = res[id].exp - c.Exp
        end
    elseif id == resmng.DEF_RES_PERSONALHONOR then
        res[id] = res[id] or {}  
        while p.uid == 0  do 
            local name = tostring(math.random(100,999))
            Rpc:union_create(p, "robot"..name, name, 40, 1000)
            wait_for_ack(p, "union_on_create")
        end
        Rpc:union_load(p,"donate")
        Rpc:union_load(p,"union_donate")
        sync(p)
        res[id].donate = (p.donate.donate or 0)  + num 
        res[id].union_donate = (p.union_donate or 0) + num*1.4
    elseif id == resmng.DEF_RES_LORDEXP then
        res[id] = res[id] or {exp=p.exp,lv=p.lv}  
        while(true) do
            local limit_exp = resmng.prop_level[p.lv + 1].Exp
            local need_exp = limit_exp - p.exp
            if num >= need_exp then
                res[id].lv = res[id].lv + 1
                res[id].exp = 0
                num = num - need_exp
            else
                res[id].exp = res[id].exp + num
                break
            end
        end

    elseif id == resmng.DEF_RES_VIPEXP then
        res[id] = res[id] or {exp = p.vip_exp + num, lv = p.vip_lv}
        for k, v in ipairs( resmng.prop_vip ) do
            if k >= p.vip_lv then
                if res[id].exp >= v.Exp then res[id].lv = k
                else break end
            end
        end

    elseif id == resmng.DEF_RES_LORDSINEW then
        res.sinew =  p.sinew
    else
        local conf = resmng.get_conf("prop_resource", id)
        if conf then
            local key = conf.CodeKey
            res[id] = (p[ key ] or 0 ) + num 
        end
    end
    return res
end

function res_off(p,o)
    for id, v in pairs(o or {} ) do
        if id <= resmng.DEF_RES_ENERGY  then
            Rpc:loadData( p, "pro" )
            sync(p)
            if id == 1 then
                if math.abs(v-p.res[id][1])>200  then lxz(p.res) return end    
            else
                if v ~= p.res[id][1]  then lxz(id) return end    
            end
        elseif id == resmng.DEF_RES_MARSEXP then
            Rpc:union_load(p,"mars")
            sync(p)
            local god = p.mars.mars 
            if v.exp ~= god.exp or v.propid ~= god.propid  then lxz(v) return end    
        elseif id == resmng.DEF_RES_PERSONALHONOR then
            Rpc:union_load(p,"donate")
            Rpc:union_load(p,"union_donate")
            sync(p)
            if math.abs(v.donate) ~= p.donate.donate 
                or math.abs(v.union_donate) ~= p.union_donate  then lxz(v) return end    
            elseif id == resmng.DEF_RES_LORDEXP then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v.exp ~= p.exp or v.lv ~= p.lv  then lxz(v) return end    
            elseif id == resmng.DEF_RES_VIPEXP then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v.exp ~= p.vip_exp or v.lv ~= p.vip_lv  then lxz(v) return end    
            elseif id == resmng.DEF_RES_LORDSINEW then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.sinew  then lxz(v) return end    
            elseif id == resmng.DEF_RES_TC_GOLD then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.manor_gold  then lxz(v) return end    
            elseif id == resmng.DEF_RES_GOLD then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.gold  then lxz(v) return end    
            elseif id == resmng.DEF_RES_SILVER then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.silver  then lxz(v) return end    
            elseif id == resmng.DEF_RES_KING_GOLD then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.kw_gold  then lxz(v) return end    
            elseif id == resmng.DEF_RES_AT_GOLD then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.relic_gold  then lxz(v) return end    
            elseif id == resmng.DEF_RES_SNAMAN_STONE then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.snaman_stone  then lxz(v) return end    
            elseif id == resmng.DEF_RES_CRS_GOLD then
                Rpc:loadData( p, "pro" )
                sync(p)
                if v ~= p.cross_gold  then lxz(v) return end    
            else
                lxz(id) 
                return     
            end
        end
        return true
    end



