module( "player_t", package.seeall  )
module_class( "player_t", PLAYER_INIT, "player" )

--gChat = gChat or {}
gBlockAccounts = gBlockAccounts or false
gPriority = gPriority or {}
g_online_num = g_online_num  or 0

gClientExtra = gClientExtra or false
gClientExtras = gClientExtras or false

gClientExtraPost = gClientExtraPost or false
gIpPermit = gIpPermit or false
gSysOption = gSysOption or {} -- system wide, client should known these
gTotalCreate = gTotalCreate or 0
gSwapOutQueue = gSwapOutQueue or {}
gSwapState = gSwapState or 0
gTotalMarkL = 18000
gTotalMarkH = 20000

gUnionOpening = gUnionOpening or {}

gPendingChat = gPendingChat or {}

function init()
    _example = PLAYER_INIT
end

gDelayAction = gDelayAction or {}
gPendingBonus = gPendingBonus or {}

can_ply_join_act = can_ply_join_act or {}  --玩家是否可以参加活动
can_ply_opt_act = can_ply_opt_act or {}   --玩家时刻可以设操控活动

function can_move_to(self, x, y)
    if x < 0 or y < 0 then return false end
    if x >= 1280 or y >= 1280 then return false end
    local lv_castle = self:get_castle_lv()
    local lv_pos = c_get_zone_lv( math.floor(x/16), math.floor(y/16) )
    return can_enter( lv_castle, lv_pos )
end

function change_language(self,lang)
    if lang ~= self.language then
        self.language = lang
    end
end

function change_nation(self,nation)
    if nation ~= self.nation then
        self.nation = nation
        self.flag = nation
    end
end

function is_show_nation(self,nation)
    if nation ~= self.show_nation then
        self.show_nation = nation
    end
end

function create(account, map, pid, culture)
    local eid = get_eid_ply()
    if not eid then return end

    pid = pid or getId("pid")
    local p = copyTab(player_t._example)

    if culture < 1 or culture > 4 then culture = 1 end

    local idx = ( math.floor( pid / 1250 ) % 4 ) + 1
    local born = { 1, 3, 4, 2 }
    local x, y = c_get_pos_born( born[idx] )
    if not x then return WARN("[NoRoom], pid=%d, culture=%d", pid, culture) end

    p.x = x
    p.y = y

    p.culture = culture
    p.propid = culture * 1000 + 1

    local photo_tab = DEFAULT_PHOTO[ culture ]
    if photo_tab then
        p.photo = photo_tab[ math.random( 1, #photo_tab ) ]
    end

    p._id = pid
    p.pid = pid
    p.eid = eid
    p.smap = map -- 生成角色时所在的服务器
    p.map = map -- 当前所在的临时服务器
    p.emap = gMapID -- 当前归属的服务器
    p.name = string.format("K%da%d", gMapID, p.pid)
    p.reg_name = p.name
    p.account = account
    p.language = 10000
    p.sinew = 100
    p.sinew_tm = gTime
    p.tm_lv = gTime
    p.tm_lv_castle = gTime
    p.mail_sys = gSysMailSn
    p.tm_create = gTime
    p.month_award_1st = gTime
    p.gold = 999999999

    p.gacha_yinbi_first = true  --银币首抽
    p.gacha_jinbi_first = true  --金币首抽

    p.online_award_time = gTime
    p.online_award_num = 0
    p.online_award_on_day_pass = 0
    p.fb_login = -2

    local ply = player_t.new(p)
    gPlys[ p.pid ] = ply
    local acc = gAccounts[ p.account ]
    if not acc then
        acc = {}
        gAccounts[ p.account ] =  acc
    end
    acc[ p.pid ] = { map=gMapID, smap=p.smap or gMapID }

    rawset( ply, "eid", eid )
    rawset( ply, "pid", pid )
    rawset( ply, "size", 4 )

    rawset( ply, "_ef", {} )
    rawset( ply, "_ef_hero", {} )
    rawset( ply, "aid", {} )
    rawset( ply, "ntodo", 0 )
    rawset( ply, "uname", "" )
    rawset( ply, "nprison", 0 )
    rawset( ply, "_first_blood", {} )
    rawset( ply, "_equip", {} )
    rawset( ply, "_item", {} )
    rawset( ply, "_hero", {} )
    rawset( ply, "_mail", {} )
    rawset( ply, "_count", {})
    rawset( ply, "_ache", {} )
    rawset( ply, "_operate_activity", {} )
    rawset( ply, "_pay_state", {} )

    gEtys[ eid ] = ply
    etypipe.add(ply)

    insert_global( "players", pid, { account=account, name=p.name, tm_create=gTime, map=gMapID, smap=map, emap=gMapID, ip=ip, propid=p.propid,  lv=1, photo=p.photo, language=p.language, uid=0, uname="", ualias="", uflag=0} )
    update_global( "accounts", account, { [pid] = { emap = gMapID, map=gMapID, smap=map } } )
        
    local default_build = {}
    for _, v in pairs(resmng.prop_citybuildview) do
        if v.Bborn == 1 then
            table.insert(default_build, v.PropId)
        end
    end

    local bs = {}
    for _, build_propid in ipairs(default_build) do
        local conf = resmng.get_conf("prop_build", build_propid)
        local build_idx = ply:calc_build_idx(conf.Class, conf.Mode, 1)
        bs[ build_idx ] = build_t.create(build_idx, pid, build_propid, 0, 0, BUILD_STATE.WAIT)
    end

    local build_idx = ply:calc_build_idx(BUILD_CLASS.FUNCTION,  BUILD_FUNCTION_MODE.HOSPITAL, 1)
    bs[ build_idx ] = build_t.create(build_idx, pid, resmng.BUILD_HOSPITAL_3, 109, 0, BUILD_STATE.WAIT)
    ply._build = bs

    local base = culture * 1000000
    local arms = { [base+1001]=750, [base+2001]=750, [base+3001]=750, [base+4001]=750 }
    local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply, {live_soldier=arms})
    ply.my_troop_id = troop._id

    init_task( ply )

    local heroid = 201
    if culture == 2 then heroid = 205
    elseif culture == 3 then heroid = 204
    elseif culture == 4 then heroid = 206 end
    ply._hero[ 1 ] = hero_t.create_hero( 1, ply.pid, heroid )
    
    -- register chat accout
    local cival_bufs = {
        resmng.CIVIL_BUFF_CHINA, 
        resmng.CIVIL_BUFF_ARAB, 
        resmng.CIVIL_BUFF_ROMAN, 
        resmng.CIVIL_BUFF_SLAV, 
    }
    add_buf( ply, cival_bufs[ culture ], -1 )
    add_buf( ply, resmng.BUFF_SHELL, 24 * 3600 )

    initEffect( ply )

    create_chat_account(ply)



    init_offline_ntf_list( ply )

    return ply
end

function init_offline_ntf_list(self)
    local sub_ntf_list = self.sub_ntf_list or {}
    for k, v in pairs(resmng.prop_offline_notify or {}) do
        if v.Default == 1 then
            sub_ntf_list[k] = 1
        else
            sub_ntf_list[k] = 0
        end
    end
    self.sub_ntf_list = sub_ntf_list
end

function build_top(self)
    self:build_all()
    --self:build_file() -- 建筑野地
    local bs = self:get_build()
    for k, v in pairs( bs ) do
        local id = v.propid
        while true do
            id = id + 1
            local conf = resmng.get_conf( "prop_build", id )
            if not conf then break end
            self:do_upgrade( k )
        end
    end
end

function build_file(self)
    local default_build = {
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_FARM_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_HOSPITAL_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_LOGGINGCAMP_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_MINE_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_QUARRY_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
        resmng.BUILD_MILITARYTENT_1,
    }

    local bs = self:get_build()
    local idx = 1
    for _, build_propid in ipairs(default_build) do
        local conf = resmng.get_conf("prop_build", build_propid)
        local build_idx = self:calc_build_idx(conf.Class, conf.Mode, idx % 8 + 1)
        idx = idx + 1
        if not bs[ build_idx ] then
            bs[ build_idx ] = build_t.create(build_idx, self.pid, build_propid, 0, 0, BUILD_STATE.WAIT)
            Rpc:stateBuild(self, bs[ build_idx ]._pro)
            if conf.Effect then self:ef_add( conf.Effect ) end
        end
    end
    if self:get_castle_lv() == 1 then self:do_upgrade( 1 ) end

    self:refresh_black_marcket()
    self:refresh_res_market()
end

function build_all(self)
    local default_build = {
        resmng.BUILD_CASTLE_1,
        resmng.BUILD_ALTAR_1,
        resmng.BUILD_WALLS_1,
        resmng.BUILD_RANGE_1,
        resmng.BUILD_BLACKMARKET_1,
        resmng.BUILD_FORGE_1,
        resmng.BUILD_FACTORY_1,
        resmng.BUILD_EMBASSY_1,
        resmng.BUILD_RESOURCESMARKET_1,
        resmng.BUILD_HALLOFHERO_1,
        resmng.BUILD_HALLOFWAR_1,
        resmng.BUILD_PRISON_1,
        resmng.BUILD_STABLES_1,
        resmng.BUILD_MARKET_1,
        resmng.BUILD_DAILYQUEST_1,
        resmng.BUILD_ACADEMY_1,
        resmng.BUILD_BARRACKS_1,
        resmng.BUILD_STOREHOUSE_1,
        resmng.BUILD_DRILLGROUNDS_1,
        resmng.BUILD_TUTTER_LEFT_1,
        resmng.BUILD_TUTTER_RIGHT_1,
        resmng.BUILD_WATCHTOWER_1,
    }

    local bs = self:get_build()
    for _, build_propid in ipairs(default_build) do
        local conf = resmng.get_conf("prop_build", build_propid)
        if conf then
            local build_idx = self:calc_build_idx(conf.Class, conf.Mode, 1)
            if not bs[ build_idx ] then
                bs[ build_idx ] = build_t.create(build_idx, self.pid, build_propid, 0, 0, BUILD_STATE.WAIT)
                Rpc:stateBuild(self, bs[ build_idx ]._pro)
                if conf.Effect then self:ef_add( conf.Effect ) end
            end
        end
    end
    if self:get_castle_lv() == 1 then self:do_upgrade( 1 ) end

    self:refresh_black_marcket()
    self:refresh_res_market()
end

function build_farm( self )
    self.field = 5
    local bs = self:get_build()
    for mode = 1, 4, 1 do
        for sn = 1, 5, 1 do
            local build_idx = self:calc_build_idx(1, mode, sn)
            if not bs[ build_idx ] then
                local farm= build_t.create(build_idx, self.pid, 1000000 + mode * 1000 + 1, 100+(mode-1)*5 + sn, 0, BUILD_STATE.CREATE)
                bs[ build_idx ] = farm
                farm.tmSn = 1
                self:doTimerBuild( 1, build_idx )
                Rpc:stateBuild(self, bs[ build_idx ]._pro)
            end
        end
    end
end


function set_ply_map(gate, proc, map, pid)
    pushHead(gate, 0, 9)  -- set server id
    pushInt(pid)
    pushInt(map)
    pushString(proc)
    pushOver()
end

function change_server(gate, proc, map)
    pushHead(gate, 0, 13) -- change server id
    pushInt(map) -- server id
    pushString(proc)
    pushOver()
end

function get_pay_token(self)
    local input = {
        appid = APP_ID,
        uid = self.account,
        server_id = gMapID,
        notify_url = config.Tool_Url,
        timestamp = gTime,
    }
    local pay_token = c_encode_aes( "APP_KEY", "1234567890123456", Json.encode( input ) )
    return c_encode_base64( pay_token )
end

function calc_sig(d) --签名算法
    local t = {}
    d.server_call = 1
    d.timestamp = gTime
    d.appid =  APP_ID 
    for k,_ in pairs(d) do  
        table.insert(t,k)  
    end
    table.sort(t)
    local sig = APP_KEY
    for _,k in pairs(t) do  
        sig = sig..d[k]
    end
    return c_md5(sig)
end

function upload_user_info(p)--推送到经分系统
    --http://doc.pf.dev.tapenjoy.com/ucenter/api/#title-14
    local sn 
    if config.Login_url then
        local d = {}
        d.ctype = config.ctype or 10 
        d.cid = p.account
        d.pid = tostring(p.pid)
        d.server_id = tostring(p.map) 
        d.channel_id = "1" 
        d.level = p:get_castle_lv() 
        d.sig = calc_sig(d)
        sn = to_tool( 0, {url=config.Login_url,method="post",body=Json.encode(d) } )
    end
    return sn
end

function upload_user_info2(p)--推送到登录系统
    --http://doc.pf.dev.tapenjoy.com/igedas/api/#title-5
    local sn 
    if config.Login2_url then
        local d = {}
        d.ctype = config.ctype or 10 
        d.cid = p.account
        d.pid = tostring(p.pid)
        d.pname = tostring(p.name)
        d.server_id = tostring(p.map) 
        d.level = p.lv 
        d.fcm_token = p.fcm_id 
        d.last_login = p.tm_login 
        d.last_logout = p.tm_logout 
        d.ctime = p.tm_create 
        local tm = os.date("%Y%m%d", gTime)
        local info = dbmng:getOne().onlines:find({_id=tm.."_"..p.pid})
        if info then
            while info:hasNext() do
                local dd = info:next()
                d.online_time = dd.online
                break
            end
        end
        d.clevel = p:get_castle_lv() 
        d.power = p:get_pow()
        d.guild_id = p.uid 
        local u = unionmng.get_union(p.uid) or {}
        d.guild_name = u.name 
        local c = resmng.get_conf("prop_language_cfg",p.language)
        if c then d.language = c.LanKey end
        d.pay_amount = p.rmb*100 
        d.vip = p.vip_lv 
        d.sig = calc_sig(d)
        sn = to_tool( 0, {url=config.Login2_url,method="post",body=Json.encode(d) } )
    end
    return sn
end


function upload_37task(p,task_id)
    --http://doc.pf.dev.tapenjoy.com/ucenter/api/#title-14
    local sn
    if config.task_37url then
        local d = {}
        d.pid = "1" 
        d.uid = p.openid
        d.server_id = tostring(p.map) 
        d.role_id = tostring(p.pid)
        d.task_id = tostring(task_id) 
        d.sig = calc_sig(d)
        sn = to_tool( 0, {url=config.task_37url,method="post",body=Json.encode(d) } )
    end
    return sn
end




function upload_user_ack(self)
    return
end

function tlog_ten(p,name,...)--接腾海外讯经分
    if config.Place ~= 1 then return end
    local info 
    if name == "GameSvrState" then
        info = {
        name,
        tms2str(),
        config.GameHost or "0.0.0.0",
        gMapID,
        }
    elseif name == "onlinecnt" then
        info = {
        name,
        }
    else
        info = {
        name,
        gMapID,
        tms2str(),
        p.vGameAppid or "NULL",
        p.PlatID or 0,
        gMapID,
        p.account,
        }
    end

    for _, v in pairs( {...} ) do
        if type(v) == "number" and v > (2^31-1) then
            table.insert(info,1987654321)
        else
            table.insert(info,v)
        end
    end

    if name == "PlayerRegister" or name == "PlayerLogin" or name == "PlayerLogout" then
        local c = resmng.get_conf("prop_language_cfg",p.language)
        if c then
            table.insert(info,c.TencentID or 6 )
        else
            table.insert(info,6 )
        end
    end

    if config.tlog == 3 then lxz(info) end
    info = table.concat(info, '|')
    c_tlog2(1,info)

end

function tlog_ten2(p,name,...)--接腾国内讯经分
    if config.Place ~= 2 then return end
    local info 
    if name == "GameSvrState" then
        info = {
        name,
        tms2str(),
        config.GameHost or "0.0.0.0",
        gMapID,
        }
    elseif name == "OnlineCount" then
        info = {
        name,
        }
    elseif name == "ASMIadInfo" then
        info = {
        name,
        gMapID,
        tms2str(),
        p.vGameAppid or "NULL",
        p.PlatID or 0,
        gMapID,
        p.account or "NULL",
        p.pid or 0,
        p.name or 0,
        }
    else
        info = {
        name,
        gMapID,
        tms2str(),
        p.vGameAppid or "NULL",
        p.PlatID or 0,
        gMapID,
        p.account or "NULL",
        p.pid or 0,
        p.name or 0,
        p:get_castle_lv() or 0,
        }
    end

    for _, v in pairs( {...} ) do
        if type(v) == "number" and v > (2^31-1) then
            table.insert(info,1987654321)
        else
            table.insert(info,v)
        end
    end

    if name == "PlayerRegister" or name == "PlayerLogin" or name == "PlayerLogout" then
        local c = resmng.get_conf("prop_language_cfg",p.language)
        if c then
            table.insert(info,c.TencentID or 6 )
        else
            table.insert(info,6 )
        end
    end

   if config.tlog == 2 then lxz(info) end
    info = table.concat(info, '|')
    c_tlog2(1,info)

end

function pre_tlog(p,name,...)

    if not config.TlogSwitch then return end

    local info = {}
    if name == "GameSvrState" then
        info = {
        name,
        config.APP_ID,
        config.SERVER_ID,
        config.PLAT_ID,
        tms2str(),
        gTime,
        }
    elseif name == "UnionList" then
        info = {
        name,
        config.APP_ID,
        config.SERVER_ID,
        config.PLAT_ID,
        tms2str(),
        gTime,
        0,
        }
    else
        info = {
        name,
        config.APP_ID,
        config.SERVER_ID,
        config.PLAT_ID,
        tms2str(),
        gTime,
        tms2str(p.tm_create),
        p.tm_create,
        tms2str(p.tm_create),
        p.tm_create,
        tms2str(p.tm_create),
        p.tm_create,
        0,
        "vOS",
        "vDID",
        "vMAC",
        "vIDFA",
        "vGAID",
        "vAndroidID",
        "vUDID",
        "vOpenUDID",
        "vIMEI",
        "vClientVersion",
        "vPackageName",
        "vChannel",
        p.ip or "",
        "40",
        p.account,
        p.pid,
        p.name,
        p:get_castle_lv(),
        p.vip_lv,
        (p.rmb or 0),
        tostring(p.smap),
        p.reg_name,
        1,
        tostring(self.language),
        }
    end

    for _, v in pairs( {...} ) do
        if type(v) == "number" and v > (2^31-1) then
            table.insert(info,1987654321)
        else
            table.insert(info,v)
        end
    end

    if name == "NewPlayerNode" then
        table.insert( info, tostring(math.ceil((gTime-p.tm_create)/60)) ) 
        for i=2,10 do table.insert(info,"null") end
    else
        for i=1,10 do table.insert(info,"null") end
    end

    if config.tlog == 1 then lxz(info) end
    info = table.concat(info, '|')
    c_tlog(info)
end

local function verify_signature(uid, token, expire, time, extra, sig)                                                                                                                                                                   
    local calc_sig = c_md5(APP_KEY..tostring(expire)..extra..tostring(time)..token..uid)                                                                                                                                                
    if calc_sig ~= sig then                                                                                                                                                                                                             
        INFO( "verify_signature, miss, %s, %s, %s, %s, %s",  expire, extra, time, token, uid )
        return false                                                                                                                                                                                                                    
    end                                                                                                                                                                                                                                 
    return true                                                                                                                                                                                                                         
end                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                        
local function verify_time(time)
    if config.IsEnableGm == 1 then
        return true
    end                                                                                                                                                                                                        
    if gTime > time + (3*86400) then                                                                                                                                                                                                    
        return false                                                                                                                                                                                                                    
    end                                                                                                                                                                                                                                 
    return true                                                                                                                                                                                                                         
end

function get_block_accounts()
    if gBlockAccounts then return gBlockAccounts end
    local db = dbmng:getOne()
    local info = db.block_account:find({}) 
    local blocks = {}
    while info:hasNext() do
        local node = info:next()
        blocks[ node._id ] = node.tick
    end
    if not gBlockAccounts then
        gBlockAccounts = blocks 
    end
    return gBlockAccounts
end


function set_block( open_id, tick )
    local acc = gAccounts[ open_id ]
    if acc then
        for pid, _ in pairs( acc ) do
            local p = getPlayer( pid )
            if p then
                if p:is_online() then
                    break_player( pid )
                end
            end
        end
    end

    local blocks = get_block_accounts()
    blocks[ open_id ] = gTime + tick
    gPendingSave.block_account[ open_id ].tick = gTime + tick
end

function is_block_account( open_id )
    local blocks = get_block_accounts()
    local tick = blocks[ open_id ]  or 0
    return tick > gTime
end

function debug_login_with_pid(sockid, pid, from_map)
    pushHead(_G.GateSid, 0, 21)  -- NET_SET_IN_QUEUE
    pushInt(sockid)
    pushInt(from_map)
    pushOver()

    p = getPlayer(pid)
    if not p then
        return
    end
    p:upload_user_info()
    p.sockid = sockid

    Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.SUCCESS)
    pushHead(_G.GateSid, 0, 9)  -- set server id
    pushInt(sockid)
    pushInt(from_map)
    pushInt(p.pid)
    pushOver()
    player_t.login( p, p.pid )

end

function load_one(pid)
    return swap_in( pid )

    --local db = dbmng:getOne()
    --local info = db.player:find({_id=pid})
    --while info:hasNext() do
    --    local data = info:next()

    --    if  data.pid and data.account and data.eid==0 then
    --        local eid = get_eid_ply()
    --        if not eid then return end
    --        local token = data.token
    --        data.token = nil

    --        local p = player_t.wrap( data )
    --        gPlys[ data.pid ] = p
    --        if data.emap == gMapID then
    --            local acc = gAccounts[ data.account ]
    --            if not acc then
    --                acc = {}
    --                gAccounts[ data.account ] = acc
    --            end
    --            acc[ data.pid ] = { data.map, data.smap or gMapID }
    --        end

    --        rawset(p, "eid", eid)
    --        rawset(p, "pid", data.pid)
    --        rawset(p, "size", 4)
    --        rawset(p, "token", token )
    --        rawset(p, "uname", "")

    --        local lv_castle = p:get_castle_lv()
    --        local x, y
    --        if lv_castle < 6 then
    --            x, y = get_pos_by_range_lv( 1, 1 )
    --        elseif lv_castle < 10 then
    --            x, y = get_pos_by_range_lv( 1, 2 )
    --        elseif lv_castle < 12 then
    --            x, y = get_pos_by_range_lv( 1, 3 )
    --        elseif lv_castle < 15 then
    --            x, y = get_pos_by_range_lv( 1, 4 )
    --        else
    --            x, y = get_pos_by_range_lv( 1, 5 )
    --        end
    --        p.x = x
    --        p.y = y
    --        p.eid = eid
    --        gPendingSave.player[ p._id ].eid = eid
    --        gEtys[ eid ] = p
    --        union_member_t.load(pid)
    --        restore_handler.load_build(pid)
    --        restore_handler.load_hero(pid)
    --        p._equip = {}
    --        local info = db.equip:find({pid=pid})
    --        while info:hasNext() do
    --            local t = info:next()
    --            p._equip[ t._id ] = t
    --        end
    --        p._count = {}
    --        local info = db.count:find({pid=pid})
    --        while info:hasNext() do
    --            local line = info:next()
    --            local player = getPlayer(line._id)
    --            if player ~= nil then
    --                line._id = nil
    --                player._count = line
    --            end
    --        end
    --        local t = troop_mng.get_troop(p.my_troop_id)
    --        if t then 
    --            t.owner_eid = eid
    --            gPendingSave.troop[ t._id ].owner_eid = eid
    --        end
    --        local propid = p.culture * 1000 + p:get_castle_lv()
    --        if p.propid ~= propid then p.propid = propid end
    --        p.nprison = p:get_prison_count()
    --        p:initEffect(true)
    --        etypipe.add(p) 
    --        return p
    --   end
    --end
end

------------web client--------------------------

function gm_login(open_id, sockid, from_map)
    pushHead(_G.GateSid, 0, 21)  -- NET_SET_IN_QUEUE
    pushInt(sockid)
    pushInt(from_map)
    pushOver()

    local pid = getId("pid")
    local p = {pid = pid, sockid = sockid, open_id = open_id, is_web_client = 1}
    gPlys[ p.pid ] = p

    Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.SUCCESS)
    pushHead(_G.GateSid, 0, 9)  -- set server id
    pushInt(sockid)
    pushInt(from_map)
    pushInt(p.pid)
    pushOver()
end

function query_json(self, param_json)
    if not self.is_web_client then
        WARN("recv invalid gm pkg form pid=%d", self.pid)
        --return
    end

    INFO("recv param_json, len=%d, str=%s", string.len(param_json), param_json)
    local param_tab = _G.Json.decode(param_json)
    dumpTab(param_tab, "web client gm", true)

    local ret_tab = gmcmd.handle_web_gmcmd(param_tab)
    local ret_tab = {ack ="ok"}

    local ret_json = _G.Json.encode(ret_tab)
    Rpc:query_json_ack(self, ret_json)
end
---------------------------------------------------

function firstPacket2(self, sockid, server_id, info, ip)
    --dumpTab( info, "loginInfo", 100, true)
    local from_map = info.server_id
    local cival = info.cival
    local pid = info.pid
    local signature = info.signature
    local time = info.time
    local open_id = info.open_id
    local token = info.token
    local token_expire = info.token_expire
    local extra = info.extra or ""
    local version = info.version
    local device = string.gsub( info.device or "unknown", ",", "_")
    local os = string.gsub(info.os or "unknown", ",", "_")
    os = string.gsub(os,"|"," ") 
    os = string.sub(os,1,64) 
    device = string.gsub(device,"|"," ") 
    device = string.sub(device,1,64) 
    local batterylv = tostring( info.batteryLevel or "-1" )

    
    if config.IsEnableGm == 1 and info.debug then
        debug_login_with_pid(sockid, pid, from_map)
        return
    end

    if info.web_client and info.open_id == "1" then
        gm_login(open_id, sockid, server_id)
        return
    end

    if login_queue.is_in_queue(sockid) then
        Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.IN_QUEUE)
        INFO( "firstPacket2, already in login queue, ip=%s, from=%s, sockid=0x%08x, civil=%d, pid=%d, token=%s, time=%d, open_id=%s, did=%s, signature = %s, token=%s", ip, from_map,  sockid , cival, pid, token, time, open_id, info.did or "unknonw", signature, token)
        return
    end

    INFO( "firstPacket2, from,%s, sockid,%d, ip,%s, open_id,%s, pid,%d, did,%s, cival,%d, signature,%s, time,%s, token,%s, token_expire,%s, version,%s, os,%s, device,%s, batterylv,%s, extra,%s",
    from_map, sockid , ip, open_id, pid, info.did, cival, signature,  time, token,  token_expire, version, os, device, batterylv, extra )

    if is_block_account( open_id ) then
        Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.BLOCK_ACCOUNT)
        INFO( "firstPacket2, block_account, ip=%s, from=%s, sockid=0x%08x, civil=%d, pid=%d, token=%s, time=%d, open_id=%s, did=%s, signature = %s, token=%s", ip, from_map,  sockid , cival, pid, token, time, open_id, info.did or "unknonw", signature, token)
        return
    end

    if config.Version then
        if version < config.Version then
            INFO( "firstPacket2, WRONG_VERSION, ip=%s, open_id=%s, version=%d, valid=%d", ip, open_id, version, config.Version )
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.VERSION_NOT_MATCH)
            return
        end
    end

    if config.IpPermit then
        if not config.IpPermit[ ip ] then 
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.SERVER_MAINTAIN)
            return
        end
    end

    if _G.white_list.active == "true" then
        local list = get_white_list("list")
        if not list[open_id] then
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.SERVER_MAINTAIN)
            return
        end
    end

    --[[
    if verify_signature(open_id, token, token_expire, time, extra, signature) == false then
        Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.TOKEN_INVAILD)
        INFO( "firstPacket2, token_invalid, from=%s, sockid=0x%08x, civil=%d, pid=%d, token=%s, time=%d, open_id=%s, did=%s, signature = %s, token=%s", from_map,  sockid , cival, pid, token, time, open_id, info.did or "unknonw", signature, token)
        return
    end
    --]]


    if pid == -2 then
        pushHead(_G.GateSid, 0, 21)  -- NET_SET_IN_QUEUE
        pushInt(sockid)
        pushInt(gMapID)
        pushOver()
        return
    end


    --local gameappid = info.info.vGameAppid
    --if not config.GameAppIDs[ gameappid ] then
    --    Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.TOKEN_INVAILD)
    --    WARN( "firstPacket2, gameappid_invalid, from=%s, sockid=0x%08x, civil=%d, pid=%d, token=%s, time=%d, open_id=%s, did=%s, signature = %s, token=%s, gameappid=%s", from_map,  sockid , cival, pid, token, time, open_id, info.did or "unknonw", signature, token, gameappid or "NULL" )
    --    return
    --end

    local pack = {}
    table.insert(pack, sockid)
    table.insert(pack,  pid)
    table.insert(pack,  open_id)
    table.insert(pack,  ip)
    table.insert(pack,  cival)
    table.insert(pack,  token)
    table.insert(pack,  from_map)
    table.insert(pack,  info.did)
    table.insert(pack,  info.info)
    table.insert(pack,  device )
    table.insert(pack,  os )
    table.insert(pack,  batterylv )
    return handle_login_from_queue(table.unpack(pack))
    
end

function handle_login_from_queue(sockid, pid, open_id, ip, cival, token, from_map, did, client, device, os, batterylv )
    if not client then
        --WARN( "%s, %s, %s, %s, %s, %s, %s, %s", open_id, ip, cival, token, from_map, did, client or "unknown" )
        --print( sockid, pid, open_id, ip, cival, token, from_map, did, client )
        return
    end

    if gPriority[ open_id ] then
        pid = gPriority[ open_id ]
        gPriority[ open_id ] = nil
    end

    if pid > 0 then
        local p = getPlayer( pid )
        if not p then
            INFO( "firstPacket2, open_id=%s, pid=%d, not found, set pid = 0", open_id, pid )
            pid = 0
        else
            if p.account ~= open_id then
                INFO( "firstPacket2, open_id=%s, pid=%d, p.acount (%s) ~= open_id, set pid = 0", open_id, pid, p.account )
                pid = 0 
            end
        end
    end

    if pid == 0 then
        local acc = gAccounts[ open_id ]
        if acc then
            local tick = 0
            for k, v in pairs( acc ) do
                local ply = getPlayer( k )
                if not ply then 
                    local tm_swap = v.tm_swap
                    if tm_swap and gTime - tm_swap < 5 then 
                        local pack = { sockid, pid, open_id, ip, cival, token, from_map, did, client }
                        return handle_login_from_queue(table.unpack(pack))
                    end
                    ply = load_one(k) 
                end
                if not ply then return end
                if ply.tm_login > tick or ply.tm_logout > tick then
                    tick = math.max( ply.tm_login, ply.tm_logout )
                    pid = k
                end
            end
        else
            --INFO( "firstPacket2, new_account, open_id,%s, did,%s, ip,%s", open_id, did or "unknown", ip or "unknown" )
        end

        if pid == 0 then
            INFO( "firstPacket2, TimeMark,%d, create_account, open_id,%s, pid,0, did,%s, ip,%s, device,%s, os,%s, batterylv,%s", gTime, open_id, did or "unknown", ip or "unknown", device, os, batterylv )
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.NO_CHARACTER)
            return
        else
            --INFO( "firstPacket2, open_id=%s, pid=0, pid=%d, last_hit", open_id, pid )
        end
    end

    local p = false
    if pid == -1 then
        --查看是否建号超过4个
        local count = 0
        for k, v in pairs(gAccounts[open_id] or {}) do
            count = count + 1
        end
        if count >= 1000 then
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.FULL)
            local acc = gAccounts[ open_id ]
            if acc then
                local tick = 0
                for k, v in pairs( acc ) do
                    local ply = getPlayer( k )
                    if not ply then ply = load_one(k) end
                    if ply then
                        if ply.tm_login > tick or ply.tm_logout > tick then
                            tick = math.max( ply.tm_login, ply.tm_logout )
                            pid = k
                        end
                    end
                end
            else
                INFO( "firstPacket2, new_account, open_id=%s, did=%s, ip=%s", open_id, did or "unknown", ip or "unknown" )
            end

            if pid == 0 then
                --INFO( "firstPacket2, send_to_socket, no_character, new_account, open_id,%s, did,%s, ip,%s", open_id, did or "unknown", ip or "unknown" )
                Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.NO_CHARACTER)
                return
            else
                INFO( "firstPacket2, open_id=%s, pid=0, pid=%d, last_hit", open_id, pid )
            end
        else
            if get_sys_status( "NoCreateRole" ) == "yes" then 
                Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.FULL)
                INFO( "[NoCreateRole], open_id=%s, ip=%s", open_id, ip )
                return
            end

            if config.MaxPlayer and gTotalCreate >= config.MaxPlayer then
                Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.FULL)
                INFO( "[MaxPlayer], open_id=%s, ip=%s, max=%d, cur=%d", open_id, ip, config.MaxPlayer, gTotalCreate )
                return
            end

            pid = getId("pid")
            p = player_t.create(open_id, gMapID, pid, cival, ip)
            if not p then
                Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.LOGIN_ERROR)
                return
            end

            
            --gPendingInsert.online[ pid ] = { online = 0, pid=pid, uid=open_id, did=did, create=gTime, ip=ip} 
            gTotalCreate = gTotalCreate + 1
            p:add_bonus("mutex_award", {{"item", 2025001, 1, 10000}}, VALUE_CHANGE_REASON.REASON_LV_ITEM)
            p:add_bonus("mutex_award", {{"item", 2026001, 1, 10000}}, VALUE_CHANGE_REASON.REASON_LV_ITEM_GOLD)

            send_system_notice( p, 10106 )
            if p.tm_create - act_mng.start_act_tm >= 3 * 86400 then
                local prop = resmng.get_conf("prop_mail", 10105)
                if prop then
                    p:send_system_notice(10105, {}, {})
                end
            end

            INFO( "[TotalCreate], %d", gTotalCreate )
            --todo, for xuezhan
            p.ip = ip
            for k, v in pairs( client or {}) do 
                if type(v)=="string" then 
                    p[k] = string.gsub(v,"|"," ") 
                    if k== "GLVersion" then 
                        p[k] = string.sub(p[k],1,256) 
                    elseif k== "ClientVersion"  
                        and k== "SystemSoftware"  
                        and k== "SystemHardware" 
                        and k== "TelecomOper" 
                        and k== "Network"  
                        and k== "CpuHardware"  
                        and k== "GLRender"  
                        and k== "DeviceId"  then
                        p[k] = string.sub(p[k],1,64) 
                    end
                else 
                    p[k] = v 
                end
            end
            p:pre_tlog("PlayerRegister",device,os,"oper","wifi","800","600",2000)

            --p:tlog_ten("PlayerRegister",
            --            p.ClientVersion or "NULL", p.SystemSoftware or "NULL", p.SystemHardware or "NULL",
            --            p.TelecomOper or "NULL", p.Network or "NULL", 
            --            p.ScreenWidth or 0, p.ScreenHight or 0, p.Density or 0, p.RegChannel or 0, 
            --            p.CpuHardware or "NULL", p.Memory or 0, 
            --            p.GLRender or "NULL", p.GLVersion or "NULL", p.DeviceId or "NULL", 
            --            p.ip or "0.0.0.0" )
            --p:tlog_ten2("PlayerRegister",
            --            p.ClientVersion or "NULL", p.SystemSoftware or "NULL", p.SystemHardware or "NULL",
            --            p.TelecomOper or "NULL", p.Network or "NULL", 
            --            p.ScreenWidth or 0, p.ScreenHight or 0, p.Density or 0, p.RegChannel or 0, 
            --            p.CpuHardware or "NULL", p.Memory or 0, 
            --            p.GLRender or "NULL", p.GLVersion or "NULL", p.DeviceId or "NULL", 
            --            p.ip or "0.0.0.0" )

            INFO( "firstPacket2, TimeMark,%d, create_character, open_id,%s, pid,%s, did,%s, ip,%s, device,%s, os,%s, batterylv,%s, idx,%d, cival,%d, %s", gTime, open_id, pid, did or "unknown", ip, device, os, batterylv, count+1, cival, p.ClientVersion or "NULL" )
            --p.sockid = sockid
        end
    end

    p = getPlayer(pid)
    if not p then
        Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.LOGIN_ERROR)
        return
    end

    if p.account ~= open_id then
        Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.PID_ERROR)
    end

    if gTime < (p.nologin_time or 0) then
        Rpc:tips(p, 3, resmng.NOLOGIN_TIME, {tms2str(p.nologin_time)})
        Rpc:logout(p)
        return
    end

    if p.token ~= token then
        p.token = token
        gPendingSave.player[ p.pid ].token = token
    end

    INFO( "firstPacket2, TimeMark,%d, login, open_id,%s, pid,%d, did,%s, ip,%s, device,%s, os,%s, batterylv,%s, lv,%d, tmcreate,%d", gTime, open_id, p.pid, did or "unknown", ip or "unknown", device, os, batterylv, (p.propid or 1001)%1000, p.tm_create )

    p:upload_user_info()

    local acc = gAccounts[ open_id ]
    if acc then
        for k, v in pairs( acc ) do
            local one = getPlayer( k )
            if one then
                if rawget( one, "gid" ) then
                    onBreak( one, one.sockid or 0 )
                end
            end
        end
    end

    p.sockid = sockid
    p.ip = ip
    --Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.SUCCESS)
    Rpc:first_packet_ack(p, LOGIN_ERROR.SUCCESS)

    INFO( "[LOGIN], on, pid,%d, open_id,%s, sock,%d, lv,%s, gold,%s, exp,%s, ip,%s, name,%s", p.pid, p.account, p.sockid or 0, p.propid % 1000, p.gold, p.exp, p.ip or 0, p.name )

    if p.map ~= gMapID and p.map ~= 0 then
        pushHead(_G.GateSid, 0, 9)  -- set server id
        pushInt(sockid)
        pushInt(p.map)
        pushInt(p.pid)
        pushOver()
        local info = {}
        info.token = p.token
        info.sockid = p.sockid
        info.ip = p.ip
        Rpc:callAgent(p.map, "agent_login", p.pid, info)

        rawset( p, "gid", _G.GateSid )
        rawset( p, "tick", gTime )
        p.tm_login = gTime
        if p.tm_logout == gTime then p.tm_logout = gTime - 1 end
        mark_access( p.pid )

    else

        pushHead(_G.GateSid, 0, 9)  -- set server id
        pushInt(sockid)
        pushInt(from_map)
        pushInt(p.pid)
        pushOver()
        player_t.login( p, p.pid )
    end

    if client.vGameAppid ~= p.gameappid then p.gameappid = client.vGameAppid end

    --todo
    for k, v in pairs( client or {}) do 
        if type(v)=="string" then 
            rawset( p, k, string.gsub( v, "|", " " ) )
            if k== "GLVersion" then 
                p[k] = string.sub(p[k],1,256) 
            elseif k== "ClientVersion"  
                and k== "SystemSoftware"  
                and k== "SystemHardware" 
                and k== "TelecomOper" 
                and k== "Network"  
                and k== "CpuHardware"  
                and k== "GLRender"  
                and k== "DeviceId"  then
                p[k] = string.sub(p[k],1,64) 
            end
        else 
            rawset(p, k, v)
        end
    end
    p:pre_tlog("PlayerLogin",p.gold,0,device,os,"oper","wifi","800","600",2000)
    return p

    --p:tlog_ten("PlayerLogin",p:get_castle_lv(),0,
    --                    p.ClientVersion or "NULL", p.SystemSoftware or "NULL", p.SystemHardware or "NULL",
    --                    p.TelecomOper or "NULL", p.Network or "NULL", 
    --                    p.ScreenWidth or 0, p.ScreenHight or 0, p.Density or 0, p.RegChannel or 0, 
    --                    p.pid,p.name,
    --                    p.CpuHardware or "NULL", p.Memory or 0, 
    --                    p.GLRender or "NULL", p.GLVersion or "NULL", p.DeviceId or "NULL", 
    --                    p.ip or "0.0.0.0",0)
    --p:tlog_ten2("PlayerLogin",0,
    --                    p.ClientVersion or "NULL", p.SystemSoftware or "NULL", p.SystemHardware or "NULL",
    --                    p.TelecomOper or "NULL", p.Network or "NULL", 
    --                    p.ScreenWidth or 0, p.ScreenHight or 0, p.Density or 0, p.RegChannel or 0, 
    --                    p.CpuHardware or "NULL", p.Memory or 0, 
    --                    p.GLRender or "NULL", p.GLVersion or "NULL", p.DeviceId or "NULL", 
    --                    p.ip or "0.0.0.0",0)

    --if p.PlatID ==0 then
    --    if p.attribution == "true"then p.attribution = 1 else p.attribution = 0 end 
    --    p.ConversionDate = string.gsub(p.ConversionDate or "1970-01-01 00:00:00","T"," ")
    --    p.ConversionDate = string.gsub(p.ConversionDate or "1970-01-01 00:00:00","Z","")
    --    p.ClickDate = string.gsub(p.ClickDate or "1970-01-01 00:00:00","T"," ")
    --    p.ClickDate = string.gsub(p.ClickDate or "1970-01-01 00:00:00","Z","")
    --    p:tlog_ten2("ASMIadInfo",p.attribution, p.OrgName or "NULL", p.CampaignId or 0, p.CampaignName or "NULL", 
    --    p.ConversionDate, p.ClickDate,
    --    p.AdgroupId or 0, p.AdgroupName or "NULL", p.KeyWord or "NULL")
    --end
end

function login_fb_req(self)
    local Lv = resmng.prop_facebook_login_award[1].CastleLv
    if self:get_castle_lv() < Lv then
        return
    end
    if self.fb_login == -2 then
        self.fb_login = -1
    elseif self.fb_login == 0 then
        self.fb_login = 1
    end
end

function get_fb_award_req(self)
    local award = {}
    if self.fb_login == -1 then
        award = resmng.prop_facebook_login_award[1].Item
    end
    if self.fb_login == 1 then
        award = resmng.prop_facebook_login_award[2].Item
    end
    self.fb_login = 2
    self:add_bonus(award[1], award[2], VALUE_CHANGE_REASON.REASON_LOGIN_FACE_BOOK)
end


function login(self, pid)
    local gid = self.gid or GateSid

    local p = getPlayer(pid)
    if p then
        p.gid = gid
        rawset( p, "tick", gTime )
        rawset( p, "_auto_mass", nil )

        local pay_token = get_pay_token(self)
        Rpc:onLogin(p, p.pid, p.name)

        local last_access = math.max( p.tm_create, p.tm_login )
        last_access = math.max( last_access, p.tm_logout )
        if gTime - last_access >= 1800 then initEffect( p ) end

        if p.tm_logout == gTime then p.tm_logout = gTime - 1 end
        if p.tm_login > p.tm_logout and p.tm_login > gBootTime then
            WARN( "double login, maybe duplicate, pid=%d", pid )
        else
            p.tm_login = gTime
            g_online_num = (g_online_num  or 0) + 1
--          c_set_online( g_online_num )
        end


        local u  = unionmng.get_union(p.uid)
        if u then
            u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=p.pid,tm_login=p.tm_login,tm_logout=p.tm_logout})
        end

        p:king_online()

        p:get_build()
        p:vip_signin()

        if not p._union then
            union_member_t.create(p, 0, 0)
--          new_union.add(p)
        end

        --跨天
        --if self.cross_time == 0 then self.cross_time = gTime end
        if get_diff_days(gTime, self.cross_time) > 0 then self:on_day_pass() end
        if self.foodUse == 0 then self:recalc_food_consume() end

        if gClientExtra then Rpc:do_string( p, gClientExtra ) end
        if gClientExtras then
            for _, v in ipairs( gClientExtras ) do
                Rpc:do_string( p, v )
            end
        end

        mail_compensate( p )

        return
    end
    LOG("player:login, pid=%d, gid=%d, not found player", pid, gid)
end

function king_online(self)
    if self:get_officer() == KING then
        local u = self:get_union() or {}
        if u then
            local prop = resmng.get_conf("prop_act_notify", resmng.KING_ONLINE)
            if prop then
                if prop.Notify then
                    Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify, {self.name, u.alias})
                end
                if prop.Chat1 then
                    player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "king online", prop.Chat1, {self.name, u.alias})
                end
            end
        else
            local prop = resmng.get_conf("prop_act_notify", resmng.KING_ONLINE_NOUNION)
            if prop then
                if prop.Notify then
                    Rpc:tips({pid=-1,gid=_G.GateSid}, 2, prop.Notify, {self.name})
                end
                if prop.Chat1 then
                    player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "king online", prop.Chat1, {self.name})
                end
            end
        end
    end
end

function change_officer(self, index)
    local cross_state = self:get_cross_state()
    if cross_state == PLAYER_CROSS_STATE.IN_CROSS_SERVER then
        local officer = self:get_officer()
        if index == officer then
            return
        end
        if 0 ~= officer then
            king_city.rem_officer_buff(self)
            self.cross_officer[gMapID] = 0
        end
        self.cross_officer[gMapID] = index
        self.cross_officer = self.cross_officer
        king_city.add_officer_buff(self)
        etypipe.add(self)
    elseif cross_state == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
        local code = remote_func(self.map, "remote_change_officer", {"player", self.pid, index})
        if E_TIMEOUT == code then
            -- 由于跨服，超时返回后，原玩家可能已经被弃用
            local player = getPlayer(self.pid)
            if nil ~= player then
                player:add_to_do("change_officer", index)
            end
        end
    else
        if index == self.officer then
            return
        end
        if 0 ~= self.officer then
            king_city.rem_officer_buff(self)
            self.officer = 0
        end
        self.officer = index
        king_city.add_officer_buff(self)
        etypipe.add(self)
    end
end

function remote_change_officer(self, index)
    self.officer = index
end

function get_officer(self)
    local cross_state = self:get_cross_state()
    if cross_state == PLAYER_CROSS_STATE.IN_CROSS_SERVER then
        return self.cross_officer[gMapID] or 0
    else
        return self.officer
    end
end

function fetch_online_time( pid, mark )
    local node = gOnlines[ pid ]
    if node then
        mark = mark or gTime
        local count = mark - node[1]
        node[1] = mark
        return count
    end
    return 0
end


function mark_online_time( pid, mark )
    local p = getPlayer( pid )
    if p then
        local node = gOnlines[ pid ]
        if node then
            local t1 = node[1]
            local t2 = gTime
            local t0 = _G.gDayStart
            local db = dbmng:getOne()
            if db then
                if t1 >= t0  then
                    local dura = math.max( 0, t2 - t1 )
                    local id = string.format( "%d_%d", _G.gDayCur, pid )
                    --db.onlines:update( {_id=id, day=_G.gDayCur, pid=pid}, { ["$inc"]={online=dura} }, true )
                    db.onlines:update( {_id=id, day=_G.gDayCur, pid=pid}, { ["$inc"]={online=dura}, ["$set"]={create=p.tm_create, ip=p.ip} }, true )

                else
                    local dura = math.max( 0, t2 - t0 )
                    local id = string.format( "%d_%d", _G.gDayCur, pid )
                    --db.onlines:update( {_id=id, day=_G.gDayCur, pid=pid}, { ["$inc"]={online=dura} }, true )
                    db.onlines:update( {_id=id, day=_G.gDayCur, pid=pid}, { ["$inc"]={online=dura}, ["$set"]={create=p.tm_create, ip=p.ip} }, true )

                    local dura = math.max( 0, t0 - t1 )
                    local id = string.format( "%d_%d", _G.gDayPre, pid )
                    --db.onlines:update( {_id=id, day=_G.gDayPre, pid=pid}, { ["$inc"]={online=dura} }, true )
                    db.onlines:update( {_id=id, day=_G.gDayCur, pid=pid}, { ["$inc"]={online=dura}, ["$set"]={create=p.tm_create, ip=p.ip} }, true )
                end

                node[1] = gTime
            end
        end

        --mark = mark or gTime
        --local clv = p:get_castle_lv()
        --local dura = fetch_online_time( pid, mark )
        --local update = string.format( "INSERT INTO tcaplus (pid, day, gameappid, platid, openid, zoneareaid, level, viplevel, money, diamond, iFriends, regtime, lastime, online, nlogin) VALUES (%d, FROM_UNIXTIME(%d,\"%%Y%%m%%d\"), \"%s\", %d, \"%s\", %d, %d, %d, %d, %d, %d, FROM_UNIXTIME(%d, \"%%Y%%m%%d\"), FROM_UNIXTIME(%d, \"%%Y%%m%%d\"), %d, %d) ON DUPLICATE KEY UPDATE level=%d, viplevel=%d, money=%d, lastime=FROM_UNIXTIME(%d, \"%%Y%%m%%d\"), online=online+%d, nlogin=nlogin+1", p.pid, mark, config.APP_ID, 1, p.account, gMapID, clv, p.vip_lv, p.gold, 0, 0, p.tm_create, p.tm_login, dura, 1, clv, p.vip_lv, p.gold, p.tm_login, dura )
        --to_tool( 0, {type="mysql", pid = pid, sql_query=update})

        --local db = dbmng:tryOne()
        --if db then
        --    db.online:update( {_id=p.pid}, { ["$inc"] = {online=dura } }, true )
        --end
    end
end

function onBreak(p, sockid)
    if p.is_web_client then
        INFO("[LOGIN], web client break pid=%d", p.pid)
        gPlys[p.pid] = nil
        login_queue.after_break(sockid)  --退出队列
        return
    end
    if p.pid ~= 0 then
        if not gOnlines[ p.pid ] then return end

        rawset( p, "gid", nil )

        INFO( "[LOGIN], of, pid,%d, open_id,%s, sock,%d, lv,%s, gold,%s, exp,%s, ip,%s, name,%s", p.pid, p.account, p.sockid or 0, p.propid % 1000, p.gold, p.exp, p.ip or 0, p.name )
        if p.tm_login == gTime then p.tm_login = gTime - 1 end
        p.tm_logout = gTime
        mark_online_time( p.pid )

        p:remEye()

        if g_online_num and  g_online_num  > 0 then 
            g_online_num = g_online_num  - 1 
           --c_set_online( g_online_num )
        end
        gOnlines[ p.pid ] = nil

        local u  = unionmng.get_union(p.uid)
        if u then
            u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=p.pid,tm_login=p.tm_login,tm_logout=p.tm_logout})
        end
        if p:get_cross_state() == PLAYER_CROSS_STATE.IN_CROSS_SERVER then
            remote_cast(p.emap, "onCrossServerBreak", {"player", p.pid, sockid})
        end
        p:upload_user_info2()
        p:pre_tlog("PlayerLogout",p.gold,0)

        --p:tlog_ten("PlayerLogout", gTime-p.tm_login, p:get_castle_lv(), 0,
        --                p.ClientVersion or "NULL", p.SystemSoftware or "NULL", p.SystemHardware or "NULL",
        --                p.TelecomOper or "NULL", p.Network or "NULL", 
        --                p.ScreenWidth or 0, p.ScreenHight or 0, 
        --                p.Density or 0, p.RegChannel or 0, 
        --                p.CpuHardware or "NULL", p.Memory or 0, 
        --                p.GLRender or "NULL", p.GLVersion or "NULL", p.DeviceId or "NULL", 
        --                p.ip or "0.0.0.0" )
        --p:tlog_ten2("PlayerLogout", gTime-p.tm_login, 0,
        --                p.ClientVersion or "NULL", p.SystemSoftware or "NULL", p.SystemHardware or "NULL",
        --                p.TelecomOper or "NULL", p.Network or "NULL", 
        --                p.ScreenWidth or 0, p.ScreenHight or 0, 
        --                p.Density or 0, p.RegChannel or 0, 
        --                p.CpuHardware or "NULL", p.Memory or 0, 
        --                p.GLRender or "NULL", p.GLVersion or "NULL", p.DeviceId or "NULL", 
        --                p.ip or "0.0.0.0" )
    end
    login_queue.after_break(sockid)  --退出队列
end

function onCrossServerBreak(self, sockid)
    if self.sockid == sockid then
        self.tm_logout = gTime
        rawset(self, "gid", nil)
        gOnlines[self.pid] = nil
    end
end

function is_online(self)
    return self.gid
end

function debugInput(self, str)
    if self.pid == 0 then
        loadstring(str)()
    end
end

function get_user_simple_info(self, pid)
    local p = getPlayer(pid)
    if p then
        Rpc:on_get_user_simple_info(self, p.pid, p.vip_lv, p.name, p.photo, p.photo_url)
    end
end

function get_user_info(self, pid, what)
    local t = {}
    t.key = what

    local pb = getPlayer(pid)
    if not pb then
        --nil
    elseif what == "base" then
        local union = unionmng.get_union(pb.uid) or {}
        t.val = {
            pid = pb.pid,
            name = pb.name,
            vip_lv = pb.vip_lv,
            lv = pb.lv,
            uid = pb.uid,
            uname = union.alias or "",
            photo = pb.photo,
            photo_url = pb.photo_url
        }
    elseif what == "pro" then
        t.val = {
            pid = pb.pid,
            name = pb.name,
            lv = pb.lv,
            uid = pb:get_uid(),
        }
    elseif what == "ef" then
    elseif what == "aid" then
        t.val = {
            max = 6666
        }
    end
    if not t.val then t.val = {} end
    Rpc:get_user_info(self, t)
end

--{{{ union
function get_uid(self)
    return self.uid
    --if self._union then return self._union.uid or 0 end
    --return 0
end

function set_uid(self, u)
    if u then
        union_member_t.join_union( self, u )
        self.uid = u.uid
        self.uname = u.alias
        self.uflag = u.flag
        self.join_tm = self.join_tm + 1
        etypipe.add(self)
        rank_mng.update_info_player( self.pid )

        local troop = troop_mng.get_troop(self.my_troop_id)
        if troop ~= nil then troop.owner_uid = u.uid end
        INFO( "[UNION], jion, pid=%d, uid=%d", self.pid, self.uid )

    else
        INFO( "[UNION], leave, pid=%d, uid=%d", self.pid, self.uid )
        union_member_t.leave_union( self )
        self.uid   = 0
        self.uname = ""
        self.uflag = 0
        etypipe.add(self)
        rank_mng.update_info_player( self.pid )

        local troop = troop_mng.get_troop(self.my_troop_id)
        if troop ~= nil then troop.owner_uid = 0 end

        for _, tid in pairs( self.busy_troop_ids or {} ) do
            local troop = troop_mng.get_troop( tid )
            if troop then
                if troop.action == TroopAction.DefultFollow and troop.owner_eid ~= self.eid then
                    self:troop_recall( tid, true )
                end

                if troop:is_settle() and troop:get_base_action() == TroopAction.HoldDefense or
                    action == TroopAction.HoldDefenseNPC or
                    action == TroopAction.HoldDefenseKING or
                    action == TroopAction.HoldDefenseLT
                then
                    local target = get_ety( troop.target_eid )
                    if target and target.uid and target.uid > 0 then
                        self:troop_recall( tid, true )
                    end
                end
            end
        end
    end

    update_global_player_info( self )

    local uid = 0
    if u then uid = u.uid end

    for _, tid in pairs( self.busy_troop_ids or {} ) do
        local troop = troop_mng.get_troop( tid )
        if troop then
            troop.owner_uid = uid
            troop_t.flush_data( troop )

            if troop:is_settle() then
                local action = troop_t.get_base_action( troop )
                if action == TroopAction.Gather then
                    local target = get_ety( troop.target_eid )
                    if target and is_res( target ) then
                        target.uid = uid
                        etypipe.add( target )
                        gPendingSave.farm[ target.eid ].uid = uid
                    end
                elseif action == TroopAction.Dig then
                    local target = get_ety( troop.target_eid )
                    if target and is_dig( target ) then
                        target.uid = uid
                        etypipe.add( target )
                        gPendingSave.unit[ target.eid ].uid = uid
                    end
                elseif action == TroopAction.Camp then
                    local target = get_ety( troop.target_eid )
                    if target and is_camp( target ) then
                        target.uid = uid
                        if u then 
                            target.uname = u.alias
                            target.uflag = u.flag
                        else
                            target.uname = ""
                            target.uflag = 0
                        end
                        etypipe.add( target )
                        gPendingSave.unit[ target.eid ].uid = uid
                    end
                end
            end
        end
    end
end

function get_rank(self)
    return self._union.rank
end

function set_rank(p, val)
    if val < resmng.UNION_RANK_1  or val >resmng.UNION_RANK_5 then
        return
    end

    if p:get_cross_state() == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
        local ret = remote_func(p.map, "set_rank", {"player", p.pid, val})
        if ret == E_OK then
            p._union.rank = val
        end
        return
    end

    local mode = 0
    if p._union  then
        if  val == p._union.rank  then
            return
        elseif  val > (p._union.rank or 0)   then
            mode = resmng.UNION_MODE.RANK_UP
        else
            mode = resmng.UNION_MODE.RANK_DOWN
        end
    else
        mode = resmng.UNION_MODE.RANK_UP
    end
    p._union.rank = val
    INFO( "[UNION], rank, pid=%d, uid=%d rank=%d", p.pid, p.uid,val )
    gPendingSave.union_member[p.pid] = p._union
    local u = unionmng.get_union(p:get_uid())
    if u  then
        if val == resmng.UNION_RANK_5 then
            p._union.title = ""
            local d = resmng.get_conf("prop_act_notify", resmng.NEW_LEADER)
            u:union_chat("", d.Chat2, {p.name})
        end
        u:notifyall(resmng.UNION_EVENT.MEMBER, mode, p:get_union_info())
        u:add_log(resmng.UNION_EVENT.MEMBER, mode, {name=p.name,rank=p:get_rank()})
    end
end

function union_data(p)
    if not p._union then union_member_t.load(p.pid) end
    return p._union
end


function get_union_info(self)
    return {
        pid = self.pid,
        propid = self.propid,
        name = self.name,
        lv = self.lv,
        language = self.language,
        nation = self.nation,
        rank = player_t.get_rank(self),
        map = self.map,
        title = self._union.title,
        tm_join = self._union.tmJoin,
        photo = self.photo,
        eid = self.eid,
        x = self.x,
        y = self.y,
        pow = player_t.get_pow(self),
        tm_login = self.tm_login,
        tm_logout = self.tm_logout,
        buildlv = player_t.get_castle_lv(self),
        donate = self._union.donate,
    }
end

function get_intro(self)
    local t = {
        pid = self.pid,
        name = self.name,
        lv = self.lv,
        uid = self:get_uid(),
        photo = self.photo,
    }
    local u = unionmng.get_union(self:get_uid())
    if u then
        t.uid = u.uid
        t.alias = u.alias
        t.flag = u.flag
        t.rank = u.rank
    end
    return t
end

function union(self)
    return unionmng.get_union(self:get_uid())
end



function getTime(self, tag)
    Rpc:getTime(self, tag, gTime, gMsec, gBootTime)
end


function on_check_pending(db, id, chgs)
    if not chgs._a_ then
        local p = getPlayer( id )
        if p then
            Rpc:statePro(p, chgs)
        end
    end
end
registe_update_callback( "player", player_t.on_check_pending )


gSync = {}

function check_pending()
    local flag = false
    for k, v in pairs( gDelayAction or {} ) do
        flag = true 
        break
    end
    if flag then
    --while next( gDelayAction ) do
        local co, flag, code
        if #gGlobalThreadDelayAction > 0 then
            co = table.remove( gGlobalThreadDelayAction )
            coro_mark( co, "outpool" )
            flag, code = coroutine.resume( co )
        else
            co = coroutine.create( thread_delay_aciton )
            coro_mark_create( co, "delay_action" )
            coro_mark( co, "outpool" )
            flag, code = coroutine.resume( co )
        end
        --if flag and code == "ok" then break end
    end

    local notifys = troop_t.gPendingNotify
    troop_t.gPendingNotify = {}
    for tid, troop in pairs( notifys ) do
        troop:do_notify_owner()
    end
   
    notifys = gPendingBonus
    gPendingBonus = {}
    for pid, infos in pairs( notifys ) do
        local p = getPlayer( pid )
        if p and is_online( p ) then
            Rpc:notify_bonus( p, infos )
            --dumpTab( infos, "Rpc,bonus", 100, true )
        end
    end

    if not gInit then
        gLastCheck, p = next( gPlys, gLastCheck )
        if p then
            if gTime - (p.tick or 0) > 1200 then
                local access = rawget( p, "_access" ) 
                if (not access) or (gTime - access > 1200) then
                    if p._client_param then p._client_param = nil end
                    if p._build then p._build = nil end
                    if p._item then p._item = nil end
                    if p._mail then p._mail = nil end
                    if p.yueka then p.yueka = nil end
                    if p._operate_activity then p._operate_activity = nil end 
                    if p._pay_state then p._pay_state = nil end
                    if p._cur_task_list then clear_task( p ) end
                end

                if gSwapState == 1 then
                    if can_swap_out( p ) == 1 then
                        table.insert( gSwapOutQueue, p.pid )
                    end
                else
                    if not is_online( p ) then

                    end
                end
            else
                INFO( "[GhostInvite], check, routing, %d,%s", p.pid, p.name )
                check_union_active( p )
            end
        end

        while #gSwapOutQueue > 10 do
            local pid = table.remove( gSwapOutQueue, 1 )
            local p = getPlayer( pid )
            if p then
                if not is_online( p ) then
                    if can_swap_out( p ) == 1 then
                        swap_out( p )
                    end
                end
            end
        end

        if gSwapState == 0 then
            if gTotalCreate >= gTotalMarkH then
                gSwapState = 1
                WARN( "gSwapState = %d, gTotalCreate = %d", gSwapState, gTotalCreate )
            end
        elseif gSwapState == 1 then
            if gTotalCreate <= gTotalMarkL then
                gSwapState = 0
                WARN( "gSwapState = %d, gTotalCreate = %d", gSwapState, gTotalCreate )
            end
        end
    end
end

function frame_end() 
    for k, v in pairs( gSync ) do
        if is_online( k ) then Rpc:sync( k, v ) end
    end
    gSync = {}
end


gGlobalThreadDelayAction = gGlobalThreadDelayAction or {}
function thread_delay_aciton()
    local co = coroutine.running()
    local co_info = gCoroMark[ co ]

    local q_actions = gDelayAction
    while true do
        local pid, actions = next( q_actions ) 
        while not pid do 

            if co_info.nest > 100 then 
                WARN( "[COROUTINE], %s, threadDelayAction, nest=%d, out", co, co_info.nest ) 
                return "ok"
            end

            if #gGlobalThreadDelayAction >= 2 then return "ok" end

            table.insert( gGlobalThreadDelayAction, co )
            coroutine.yield( "ok" )
            pid, actions = next( q_actions )
        end

        q_actions[ pid ] = nil
        local A = getPlayer( pid )
        if A then
            for func, v in pairs( actions ) do
                if v == 0 then
                    actions[ func ] = 1
                    func( A )
                end
            end
        end
    end
end


-- _ef,
-- _ef_build
-- _ef_equip
-- _ef_tech
-- _ef_talent
-- _ef_hero
-- _ef_union todo
function initEffect(self, init)
    local ef = {}
    local pow = 0
    local conf = resmng.prop_level[ self.lv ]
    if conf then pow = resmng.prop_level[ self.lv ].Pow end

    local ptab = resmng.prop_effect_type
    for k, v in pairs(ptab) do
        if v.Default and v.Default ~= 0 then
            ef[ k ] = v.Default
        end
    end

    -- build
    local pow_build = 0
    local bs = self:get_build()
    if bs then
        local ptab = resmng.prop_build
        for _, v in pairs(bs) do
            local node = ptab[ v.propid ]
            if node then
                if node.Pow then
                    pow_build = pow_build + ( node.Pow or 0 )
                end

                if node.Effect then
                    for ek, ev in pairs( node.Effect ) do ef[ ek ] = ( ef[ ek ] or 0 ) + ev end
                end
            end
        end
    end
    self.pow_build = pow_build
    pow = pow + pow_build

    -- equip
    local es = self:get_equip()
    if es then
        local ptab = resmng.prop_equip
        for k, v in pairs(es) do
            if v.pos > 0 then
                local node = ptab[ v.propid ]
                if node then
                    for ek, ev in pairs( node.Effect ) do ef[ ek ] = ( ef[ ek ] or 0 ) + ev end
                    if node.Pow then pow = pow + node.Pow end
                end
            end
        end
    end

    -- tech
    local ptab = resmng.prop_tech
    for _, v in pairs(self.tech or {}) do
        local node = ptab[ v ]
        if node then
            for ek, ev in pairs( node.Effect ) do ef[ ek ] = ( ef[ ek ] or 0 ) + ev end
            if node.Pow then pow = pow + node.Pow end
        end
    end

    -- genius
    local ptab = resmng.prop_genius
    for _, v in pairs(self.genius or {}) do
        local node = ptab[ v ]
        if node and node.Effect then
            for ek, ev in pairs( node.Effect ) do ef[ ek ] = ( ef[ ek ] or 0 ) + ev end
        end
    end

    -- bufs
    local ptab = resmng.prop_buff
    for k, v in pairs(self.bufs or {}) do
        local bufid = v[1]
        local over = v[3] or 0
        if over >= gTime or over == -1 then
            local node = ptab[ bufid ]
            if node and node.Value then
                for ek, ev in pairs( node.Value ) do ef[ ek ] = ( ef[ ek ] or 0 ) + ev end
            end
        end
    end

    self._ef = ef

    pow = pow + self:calc_pow_arm()
    pow = pow + self:calc_pow_hero()

    if pow ~= self.pow then self.pow = pow end
    self.pow_last = pow

    if self.tm_lv == 0 then self.tm_lv = gTime end
    if self.tm_lv_castle == 0 then self.tm_lv_castle = gTime end

    self:recalc_build_queue()

end


function calc_pow_arm( self )
    local pow = 0
    local troop = self:get_my_troop()
    if troop then pow = pow + troop:calc_pow(self.pid) end

    for k, v in pairs(self.busy_troop_ids) do
        troop = troop_mng.get_troop(v)
        if troop then pow = pow + troop:calc_pow(self.pid) end
    end
    pow =  math.floor(pow)
    self.pow_arm = pow
    return pow
end


function recalc_pow_arm( self )
    local old = self.pow_arm or 0
    self:calc_pow_arm()
    local new = self.pow_arm or 0

    if old ~= new then
        if new > old then self:inc_pow( new - old ) else self:dec_pow( old - new ) end
    end
end


function calc_pow_hero( self )
    local pow = 0
    local hs = self:get_hero()
    for _, h in pairs( hs or {} ) do
        if h.status < HERO_STATUS_TYPE.BEING_CAPTURED then
            pow = pow + h:calc_fight_power()
        end
    end
    pow = math.floor( pow )
    self.pow_hero = pow
    return pow
end


function calc_diff(A, B) -- A, original; B, new one
    local C = {}
    for k, v in pairs(A or {}) do
        C[k] = (B[k] or 0) - v
    end
    for k, v in pairs(B or {}) do
        if not A[k] then
            C[k] = B[k]
        end
    end
    return C
end

function ef_chg(self, A, B) -- A, original; B, new, for upgrade
    local C = calc_diff(A, B)
    self:ef_add(C)
end


function ef_add(self, eff, init)
    if not eff then return end
    local t = self._ef
    if not t then
        t = {}
        self._ef = t
    end
    local res = {}
    local notifys = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) + v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end

        if g_ef_notify[ k ] then notifys[ g_ef_notify[ k ] ] = 1 end
        LOG( "ef_add, pid=%d, k=%s, v=%s, n=%s", self.pid, k, v or 0, t[k] or 0 )
    end

    for func, _ in pairs( notifys ) do
        func( self )
    end
end

function ef_rem(self, eff)
    if not eff then return end
    local t = self._ef
    if not t then return end
    local res = {}
    local notifys = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) - v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end

        if g_ef_notify[ k ] then notifys[ g_ef_notify[ k ] ] = 1 end
        LOG( "ef_rem, pid=%d, k=%s, v=%s, n=%s", self.pid, k, v or 0, t[k] or 0 )
    end

    for func, _ in pairs( notifys ) do
        func( self )
    end
end

function get_num(self, what, ...) -- VALUE DIRECTLY
    local ef_u,ef_ue = self:get_union_ef()
    local ef_s = self._ef
    local ef_gs = kw_mall.gsEf or {} -- globle buff
    if ... == nil then
        return get_num_by( what, ef_s, ef_u,ef_ue, ef_gs )
    else
        return get_num_by( what, ef_s, ef_u,ef_ue, ef_gs, ... )
    end
end

function get_val(self, what, ...)
    local ef_u,ef_ue = self:get_union_ef()
    local ef_s = self._ef
    local ef_gs = kw_mall.gsEf or {} -- globle buff
    if ... == nil then
        return get_val_by(what, ef_s, ef_u, ef_ue, ef_gs)
    else
        return get_val_by(what, ef_s, ef_u, ef_ue, ef_gs, ...)
    end
end

function is_state( self, state )
    return get_bit( self.state, state ) == 1
end

function add_state( self, state )
    local old = self.state
    self.state = set_bit( old, state )
    if self.state ~= old then
        etypipe.add( self )
    end
end

function rem_state( self, state )
    local old = self.state
    self.state = clr_bit( old, state )
    if self.state ~= old then
        etypipe.add( self )
    end
end

function recalc_build_res( self )
    local bs = self:get_build()
    for k, v in pairs( bs ) do
        local class = math.floor( v.propid / 1000000 )
        if class == BUILD_CLASS.RESOURCE then
            v:recalc()
        end
    end
end

function recalc_build_train( self )
    local bs = self:get_build()
    for k, v in pairs( bs ) do
        local class = math.floor( v.propid / 1000000 )
        if class == BUILD_CLASS.ARMY then
            v:recalc()
        end
    end
end

function recalc_troop_gather( self )
    for k, v in pairs( self.busy_troop_ids ) do
        local troop = troop_mng.get_troop(v)
        if troop and troop:is_action( TroopAction.Gather ) and troop:is_settle() then
            troop:recalc_gather()
        end
    end
end

function recalc_build_queue( self )
    local val = self:get_val( "CountBuild" )
    local queues = self.build_queue
    local info = {}
    for i = 1, val, 1 do
        if queues[ i ] and queues[ i ] > 0 then
            local valid = false
            local idx = queues[ i ]
            local build = self:get_build( idx )
            if build then
                local state = build.state
                if state == BUILD_STATE.CREATE or state == BUILD_STATE.UPGRADE or state == BUILD_STATE.DESTROY then
                    valid = true
                end
            end
            if valid then 
                info[ i ] = idx
            else 
                info[ i ] = 0 
            end
        else
            info[ i ] = 0
        end
    end

    for k, v in pairs( info ) do
        if info[ k ] ~= queues[ k ] then
            self.build_queue = info
            return
        end
    end

    for k, v in pairs( queues ) do
        if info[ k ] ~= queues[ k ] then
            self.build_queue = info
            return
        end
    end
end


function recalc_shell( self )
    local shells = {
        [ resmng.BUFF_SHELL ] = CastleState.Shell,
        [ resmng.BUFF_SHELL_ROOKIE ] = CastleState.ShellRokie,
        [ resmng.BUFF_SHELL_CROSS ] = CastleState.ShellCross,
    }

    for buf, state in pairs( shells ) do
        local remain = self:get_buf_remain( buf )
        if remain > 0 and not self:is_state( state ) then
            self:add_state( state )
        elseif remain == 0 and self:is_state( state ) then
            self:rem_state( state )
            --offline_ntf.post(resmng.OFFLINE_NOTIFY_PROTECT, self, {}, {})
        end
    end
end

g_ef_notify = {
    SpeedRes_R =    recalc_build_res,
    SpeedRes1_R =   recalc_build_res,
    SpeedRes2_R =   recalc_build_res,
    SpeedRes3_R =   recalc_build_res,
    SpeedRes4_R =   recalc_build_res,
    SpeedTrain_R =  recalc_build_train,
    SpeedConsume_R =recalc_food_consume,
    SpeedRecover_R = do_recalc_sinew,

    SpeedGather =   recalc_troop_gather,
    SpeedGather1=   recalc_troop_gather,
    SpeedGather2=   recalc_troop_gather,
    SpeedGather3=   recalc_troop_gather,
    SpeedGather4=   recalc_troop_gather,

    SpeedGather_R = recalc_troop_gather,
    SpeedGather1_R= recalc_troop_gather,
    SpeedGather2_R= recalc_troop_gather,
    SpeedGather3_R= recalc_troop_gather,
    SpeedGather4_R= recalc_troop_gather,

    CountWeight_R = recalc_troop_gather,
    CountBuild_A = recalc_build_queue,

    StateShell = recalc_shell,
}

--------------------------------------------------------------------------------
-- Function : 获取指定effect的ef, ef_a, ef_r
-- Argument : self, what
-- Return   : ef, ef_a, ef_r
-- Others   : NULL
--------------------------------------------------------------------------------
function get_val_extra(self, what, ...)
    --local node = resmng.get_conf("prop_effect_type", what)
    --if not node then
    --    return 0
    --end

    local bidx = what
    local ridx = string.format("%s_R", what)
    local eidx = string.format("%s_A", what)

    local sf = self._ef
    local hf = self._ef_hero or {}
    local uf = self._ef_union or {}

    local b = (sf[bidx] or 0) + (hf[bidx] or 0) + (uf[bidx] or 0)
    local r = (sf[ridx] or 0) + (hf[ridx] or 0) + (uf[ridx] or 0)
    local e = (sf[eidx] or 0) + (hf[eidx] or 0) + (uf[eidx] or 0)
    r =  (10000 + r) * 0.0001

    return b, r, e
end

function getDb(self)
    return dbmng:getOne(self.pid)
end

function doCondCheck(self, class, mode, lv, ...)
    if class == "OR" then
        for _, v in pairs({mode, lv, ...}) do
            if self:doCondCheck(unpack(v)) then return true end
        end
        return false

    elseif class == "AND" then
        for _, v in pairs({mode, lv, ...}) do
            if not self:doCondCheck(unpack(v)) then return false end
        end
        return true

    elseif class == resmng.CLASS_RES then
        return self:get_res_num(mode) >= lv

    elseif class == resmng.CLASS_GLOB_RES then
        return kw_mall.get_kw_point() >= lv

    elseif class == resmng.CLASS_BUILD then
        local t = resmng.prop_build[ mode ]
        if t then
            local c = t.Class
            local m = t.Mode
            local l = t.Lv
            for _, v in pairs(self:get_build()) do
                local n = resmng.prop_build[ v.propid ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_GENIUS then
        local t = resmng.prop_genius[ mode ]
        if t then
            local c = t.Class
            local m = t.Mode
            local l = t.Lv
            for _, v in pairs(self.genius) do
                local n = resmng.prop_genius[ v ]
                if n and n.Class == c and n.Mode == m and n.Lv >= l then return true end
            end
        end
    elseif class == resmng.CLASS_TECH then
        local t = resmng.get_conf("prop_tech", mode)
        if t then
            for _, v in pairs(self.tech) do
                local n = resmng.get_conf("prop_tech", v)
                if n and t.Class == n.Class and t.Mode == n.Mode and t.Lv <= n.Lv then
                    return true
                end
            end
        end
    elseif class == resmng.CLASS_ITEM then
        return self:get_item_num(mode) >= lv
    elseif class == resmng.CLASS_PLAYER_LEVEL then
        return self.lv >= mode
    elseif class == resmng.CLASS_UNION_LEVEL then
        local union = unionmng.get_union(self:get_uid())
        if union == nil then
            return false
        end
        return union.level >= mode
    elseif class == resmng.CLASS_TASK_FINISH then
        local taskid = mode
        return is_task_finished( self, taskid )
    elseif class == resmng.CLASS_HERO_EQUIP then
        local eq = self:get_hero_equip(mode)
        if eq then
            return true
        end
        return false
    elseif class == resmng.CLASS_HERO_EQUIP_GRADE then
        local n = self:get_hero_equip_num_by_class_mode(mode[1], mode[2])
        return n >= num
    end

    -- default return false
    return false
end

function condCheck(self, tab, num)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if class == "OR" or class == "AND" then
                if not self:doCondCheck( unpack(v) ) then return false end
            else
                if not self:doCondCheck( class, mode, math.ceil( (lv or 0)* num ) ) then return false end
            end
        end
    end
    return true
end

function consCheck(self, tab, num)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if class == "OR" or class == "AND" then
                if not self:doCondCheck( unpack(v) ) then return false end
            else
                if not self:doCondCheck( class, mode, math.ceil( (lv or 0) * num ) ) then return false end
            end
        end
    end
    return true
end

function consume(self, tab, num, why)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if class ~= resmng.CLASS_GLOB_RES then
                if not self:doConsume(class, mode, lv * num, why) then return false end
            elseif class == resmng.CLASS_GLOB_RES then  -- 国王币消耗
                kw_mall.do_consume(lv * num)
            end
        end
        return true
    end
    return false
end

function doConsume(self, class, mode, num, why)
    if class == resmng.CLASS_RES then
        --return self:doUpdateRes(mode, -num, why)
        self:do_dec_res(mode, num, why)
        return true
    elseif class == resmng.CLASS_ITEM then
        return self:dec_item_by_item_id(mode, num, why)
    elseif class == resmng.CLASS_HERO_EQUIP then
        return self:del_hero_equip(mode, why)
    elseif class == resmng.CLASS_HERO_EQUIP_GRADE then
        return self:del_hero_equip_by_class_mode(mode[1], mode[2], num, why)
    end
end

function obtain(self, tab, num, why)
    if tab then
        num = num or 1
        for _, v in pairs(tab) do
            local class, mode, lv = unpack(v)
            if not self:doObtain(class, mode, math.ceil(lv * num), why) then return false end
        end
    end
end

function doObtain(self, class, mode, num, why)
    if class == resmng.CLASS_RES then
        --return self:doUpdateRes(mode, -num, why)
        self:do_inc_res_normal(mode, num, why)
    elseif class == resmng.CLASS_RES_PROTECT then
        self:do_inc_res_protect(mode, num, why)
    elseif class == resmng.CLASS_ITEM then
        self:inc_item(mode, num, why)
    end
    return true
end



player_t.bonus_func = {}
player_t.bonus_func["mutual_award"] = function(self, tab)
    local get_tab = {}
    if tab ~= nil then
        local p = math.random(AWARD_RANDOM_SUM)
        local cur_p = 0
        local msg_notify = {}
        for k, v in pairs(tab) do
            local class, mode, num, pro = unpack(v)
            pro = pro or AWARD_RANDOM_SUM
            cur_p = cur_p + pro
            if cur_p >= p then
                table.insert(get_tab, {class, mode, num})
                return get_tab
            end
        end
    end
    return get_tab
end



player_t.bonus_func["mutex_award"] = function(self, tab)
    local get_tab = {}
    if tab ~= nil then
        for k, v in pairs(tab) do
            local class, mode, num, pro = unpack(v)
            pro = pro or AWARD_RANDOM_SUM
            local p = math.random(AWARD_RANDOM_SUM)
            if pro >= p then
                table.insert(get_tab, {class, mode, num})
            end
        end
    end
    return get_tab
end



function add_bonus(self, bonus_policy, tab, reason, ratio,cost )
    if bonus_policy == nil or tab == nil or reason == nil then
        return false
    end
    ratio = ratio or 1
    local get_tab = player_t.bonus_func[bonus_policy](self, tab)
    if get_tab and #get_tab > 0 then

        local msg_notify = {}
        for k, v in pairs(get_tab) do
            self:do_add_bonus(v[1], v[2], v[3], ratio, reason,cost)
            v[3] = v[3] * ratio
            table.insert(msg_notify, v)
            if v[1] == "item" then
                local prop_tab = resmng.get_conf("prop_item", v[2])
                if prop_tab and prop_tab.Open == 1 then
                    table.remove(msg_notify)
                end
            end
        end

        if #msg_notify > 0 then
            local node = gPendingBonus[ self.pid ]
            if not node then
                gPendingBonus[ self.pid ] = msg_notify
            else
                for _, v in pairs( msg_notify ) do
                    table.insert( node, v )
                end
            end
        end

        --Rpc:notify_bonus(self, msg_notify)
    end
    return true
end

function do_add_bonus(self, class, mode, num, ratio, reason,cost)
    if not num then
        ERROR( "do_add_bonus, pid=%d, class=%s, mode=%s", self.pid, class, mode )
        return
    end
    INFO( "[ADD_BONUS], pid=%d, class=%s, mode=%s, num=%s, ratio=%s, reason=%s", self.pid, class, mode, num, ratio, reason )
    local real_num = math.floor(num * ratio)
    if class == "item" then
        local itemp = resmng.get_conf("prop_item", mode)
        if itemp then
            if itemp.Open == 1 then
                if itemp.Action then
                    if self:do_item_check( itemp ) then
                        if not debug.getinfo( 50, "n" )  then
                            player_t.use_item_logic[itemp.Action](self,itemp.ID, real_num, itemp)
                            return
                        else
                            WARN( "do_add_bonus, deep loop, id = %d, num = %d", itemp.ID, real_num )
                        end
                    end
                end
            end
            self:addItem(mode, real_num, reason,cost)
        else
            ERROR( "do_add_bonus, class=%s, mode=%s, num=%s", class, mode, num )
        end

    elseif class == "res" then
        self:do_inc_res_normal(mode, real_num, reason)
    elseif class == "respicked" then
        self:do_inc_res_protect(mode, real_num, reason)
    elseif class == "soldier" then
        self:add_soldier(arm_id(self.culture, mode), real_num)

    elseif class == "hero_exp" then
        local hero = heromng.get_hero_by_uniq_id(mode)
        if hero ~= nil then
            real_num = num * ratio
            hero:gain_exp(real_num)
        end
    elseif class == "hero_attr" then
        local hero = heromng.get_hero_by_uniq_id(mode.h_id)
        if hero ~= nil then
            hero:add_attr(mode.mode, num)
        end
    elseif class == "hero" then
        self:make_hero(mode)

    elseif class == "equip" then
        self:equip_add(mode, reason)
    end
end

function add_bonus_not_notify(self, bonus_policy, tab, reason, ratio)
    if bonus_policy == nil or tab == nil or reason == nil then
        return false
    end
    ratio = ratio or 1
    local get_tab = player_t.bonus_func[bonus_policy](self, tab)
    if get_tab and #get_tab > 0 then
        for k, v in pairs(get_tab) do
            self:do_add_bonus(v[1], v[2], v[3], ratio, reason)
        end
    end
    return true
end

-- when troop march through the country boundary
function qryCross(self, toPid, cmd, param)
    local sn = getSn("qryCross")
    local smap = gMapID
    local spid = self.pid

    LOG("qryCross, smap=%d, sn=%d", smap, sn)
    Rpc:onQryCross(_G.gAgent, toPid, sn, smap, spid, cmd, param)
    return putCoroPend("rpc", sn)
end

function onQryCross(self, toPid, sn, smap, spid, cmd, arg)
    LOG("onQryCross, toPid=%d, smap=%d, spid=%d, sn=%d, cmd=%s", toPid, smap, spid, sn, cmd)
    --dumpTab(arg, "QryCross")
    local code = 0
    Rpc:onAckCross(_G.gAgent, smap, sn, code, arg)
end

function onAckCross(self, smap, sn, code, res)
    LOG("onAckCross, smap=%d, sn=%d, code=%d", smap, sn, code)
    --if code == 0 then dumpTab(res, "AckCross") end
    local co = getCoroPend("rpc", sn)
    if co then
        coroutine.resume(co, code, res)
    end
end

function testQryCross(self)
    -- -2, the pid is minus, means the map 2, pid 0
    local code, tab = self:qryCross(2, "sayHello", {a=1, b="string"})
    LOG("qryCross, code=%d", code)
    --if code == 0 then dumpTab(tab) end
end

local function sendCertify(proc, code)
    pushHead(gateid, 0, gNetPt.NET_CERTIFY)  -- NET_CERTIFY
    pushInt(code)
    pushString(proc)
    pushOver()
end


function gm_user(self, cmd)
    INFO( "gm_user, pid=%d, cmd=%s", self.pid, cmd )
    local tb = string.split(cmd, "=")
    local choose = tb[1]

    --- user gmcmd
    local content = {}
    content.cmd = tb[1]
    local param = copyTab(tb)
    table.remove(param, 1)
    content.param = param
    local pids = {self.pid}
    content.pids = pids
    local ret = gmcmd.do_cmd(content)
    if type(ret.msg) == "string" then
        if string.len( ret.msg ) > 0 then
          --  self:add_debug("gm result ", ret.msg)
        end
    else
        chat_tab(self, ret.msg)
        --self:add_debug("gm result ~p", ret.msg)
    end

    function get_parm(idx)
        if idx < 1 or tb[idx + 1] == nil then
            return 0
        end
        return tb[idx + 1]
    end

    if choose == "showbuf" then
        for k, v in pairs( self.bufs ) do
            self:add_debug( "%d, %d, %d, %d", v[1], v[2], v[3], v[3]-gTime )
        end
        coro_info()

    elseif choose == "pow" then
        self:add_debug( string.format( "pow = %d", self.pow ) )


    elseif choose == "addexp" then
        local value = get_parm(1)
        self:add_exp(tonumber(value))
    elseif choose == "build_exp" then
        local mode = tonumber(get_parm(1))
        local exp = tonumber(get_parm(2))
        local t = union_buildlv.get_buildlv(self.uid,mode)
        t.exp = exp
    elseif choose == "build_lv" then
        local mode = tonumber(get_parm(1))
        local lv = tonumber(get_parm(2))
        local t = union_buildlv.get_buildlv(self.uid,mode)
        t.id = mode*1000 + lv
    elseif choose == "god_exp" then
        local exp = get_parm(1)
        union_god.add_exp(self,exp)
    elseif choose == "tech_exp" then
        local idx = tonumber(get_parm(1))
        local exp = tonumber(get_parm(2))
        local u = unionmng.get_union(self.uid)
        local tech = u:get_tech(idx)
        union_tech_t.add_exp(tech,exp)

    elseif choose == "showef" then
        for k, v in pairs( self._ef ) do
            self:add_debug( "EF, %s = %d", k, v )
            INFO( "SHOWEF, EF, %s, %s", k, v )
        end

        local ef_u, ef_ue = self:get_union_ef()
        for k, v in pairs( ef_u or {} ) do
            self:add_debug( "EF_U, %s = %d", k, v )
            INFO( "SHOWEF, EF_U, %s, %s", k, v )
        end

        for k, v in pairs( ef_ue or {}) do
            self:add_debug( "EF_UE, %s = %d", k, v )
            INFO( "SHOWEF, EF_UE, %s, %s", k, v )
        end

        for k, v in pairs( kw_mall.gsEf or {}) do
            self:add_debug( "EF_GS, %s = %s", k, v )
            INFO( "SHOWEF, EF_GS, %s, %s", k, v )
        end


    elseif choose == "showgsef" then
        for k, v in pairs( kw_mall.gsEf ) do
            if k ~= "_id" then
                self:add_debug( "gs EF, %s = %d", k, v )
            end
        end
    elseif choose == "showuef" then
        local u = unionmng.get_union(self.uid)
        if u then
            for k, v in pairs( u:get_ef() or {} ) do
                self:add_debug( "union EF, %s = %d", k, v )
            end
        end

    elseif choose == "initef" then
        self:initEffect()

    elseif choose == "clearcure" then
        self.cures = {}
        self.hurts = {}
        self.tm_cure = 0
        self.cure_start = 0
        self.cure_over = 0
    elseif choose == "clearcd" then
        self.cds = {}

    elseif choose == "bossaward" then
        monster.send_score_award()
    elseif choose == "undebug" then
        debug_tag = nil
        union_item._tm = 24*60*60
    elseif choose == "debug" then
        debug_tag = 1
        union_item._tm = 60
        self._union.god_log.tm = 0
        crontab.union_donate_week()
    elseif choose == "debug1" then
        debug_tag = 1
    elseif choose == "lxz" then
        --player_t.check_say2()
        gTotalMarkH = 0 
        gTotalMarkL = 0 
        -- _lxz_sn = (_lxz_sn or gTime ) + 1
        -- local t = { pid=1,cpid="wm.app.credit1",order_id=_lxz_sn,quantity=123,ext_info=Json.encode({player_id=self.pid,}),}  
        -- agent_t.do_gm_cmd["pay"]( t )
        -- _lxz_sn = (_lxz_sn or gTime ) + 1
        -- local t = { pid=19,cpid="wm.app.credit9",order_id=_lxz_sn,quantity=123,ext_info=Json.encode({player_id=self.pid,}),}  
        -- agent_t.do_gm_cmd["pay"]( t )
        -- self:send_union_build_mail(resmng.MAIL_10074, {}, {})
        -- self:send_union_build_mail(resmng.MAIL_10075, {}, {})
        -- self:send_union_build_mail(resmng.MAIL_10076, {}, {})
        -- local u = self:union()
        -- for _, v in pairs(u.build or {}) do v.val = 100 end
        -- union_item.add(self,{"mutex_award",{{"item",2012009,1,10000},}} ,UNION_ITEM.TASK)--加入军团礼物
        -- debug_tag = 1
        -- union_buildlv_donate(self,1)
        -- debug_tag = nil
        -- self:add_buf( 50003001, -1 ) --行军队列无限
        -- local param = {player_id = tostring(self.pid), order_id = tostring(gTime), pay_amount = "1", product_id = 1}

    elseif choose == "bossscore" then
        local score = tonumber(tb[2])
        monster.bossKillScore.score = (monster.bossKillScore.score or 0) + score
        monster.try_upgrade_stage()
    elseif choose == "cleartw" then
        local union = self:union()
        if union then
            union_t.clear_declare(union, 1)
        end
        npc_city.clear_union()
    elseif choose == "rtnpc" then
        local castle = self:get_build(1)
        castle.propid = 6
        self:set_rank(resmng.UNION_RANK_4)
    elseif choose == "starttw" then
       npc_city.start_tw()
    elseif choose == "randomtw" then
        npc_city.tw_random_award()
    elseif choose == "fighttw" then
        npc_city.fight_tw()
    elseif choose == "endtw" then
       npc_city.end_tw()
    elseif choose == "twaward" then
        npc_city.send_score_award()
        rank_mng.clear(14)
    elseif choose  == "actinfo" then -- 开启怪物攻城
        act_info_req(self)
    elseif choose  == "npcinfo" then -- 开启怪物攻城
        npc_act_info_req(self)
    elseif choose == "buildall" then
        self:build_all()

    elseif choose == "buildtop" then
        self:build_top()

    elseif choose == "abdnpc" then
            local eid = tonumber(tb[2])
            self:abandon_npc(eid)
    elseif choose == "buildfarm" then
        self:build_farm()
    elseif choose == "addnpc" then -- 给自己增加npc城市
        local union = self:union()
        if union then
            local eid = tonumber(tb[2])
            local npcCitys = union.npc_citys
            npcCitys[eid] = eid
            union.npc_citys = npcCitys
            local npc = get_ety(eid)
            if npc then
                npc.uid = union.uid
            end
        end
    elseif choose == "mcaward" then
        monster_city.send_score_award()
    elseif choose  == "setmc" then -- 开启怪物攻城
        local time = tonumber(tb[2])
        self:set_mc_start_time_req(time)
    elseif choose  == "startmc" then -- 开启怪物攻城
        local union = self:union()
        if union then
            union_t.set_mc_state(union, 1)
        end
    elseif choose  == "mcinfo" then -- 开启怪物攻城
        mc_info_req(self)
    elseif choose == "mc" then
        local step = tonumber(tb[2])
        local union = self:union()
        if union then
            if step == 1 then
                union:mc_notify(resmng.MC_PREPARE)
            end
            union_t.set_mc_state(union, step)
        end
    elseif choose == "mall" then
        kw_mall.refresh_kw_mall()
        self:refresh_mall(1)
        self:refresh_mall(2)
        self:refresh_mall(3)
        kw_mall_info_req(self, 1)
    elseif choose == "query_json" then
        --self:query_json( tb[2] or "{\"mode\": 1, \"code\" : \"king_city.hot_update = function() local i= 3 print("aaa") end\"}")
        king_city.hot_update()

    elseif choose == "addp" then
        self.kw_gold = self.kw_gold + 1000000
        self.manor_gold = self.manor_gold + 1000000
        self.relic_gold = self.relic_gold + 1000000
    elseif choose == "login" then
        self:upload_user_info()
    elseif choose == "chat" then
        --create_chat_account(self)
        chat_account_info_req(self)
    elseif choose == "room" then
        local union = unionmng.get_union(self.uid)
        if union then
            create_chat_room(union)
        end
    elseif choose == "ltaward" then
        lost_temple.send_score_award()
    elseif choose == "startlt" then
        lost_temple.start_lt()
    elseif choose == "trylt" then
        lost_temple.try_start_lt()
    elseif choose == "endlt" then
        lost_temple.end_lt()
    elseif choose  == "ltinfo" then -- 遗迹塔活动页面
        lost_temple.test(self)
        lt_info_req(self)

    elseif choose == "ache" then
        self:ache_info_req()
    elseif choose == "hero_task" then
        self:get_hero_task_list_req()
    elseif choose == "refresh_hero_task" then
        self:refresh_hero_task_list_req()
    elseif choose == "addac" then
        local idx = tonumber(tb[2])
        local val = tonumber(tb[3])
        self:add_count(idx,val)
    elseif choose == "addache" then
        local point = tb[2]
        self.ache_point = (self.ache_point or 0) + point
        self:try_upgrade()
    elseif choose == "setache" then
        local idx = tb[2]
        --local aconf = resmng.get_conf( "prop_achievement", idx )
        --if not aconf then return end
        --local var = aconf.Var
        --local cconf = resmng.get_conf( "prop_achievement_var", var )
        --if not cconf then return end
        --self:set_ache( tonumber(idx), gTime )
        --self.ache_point = (self.ache_point or 0) + cconf.Point
        self:try_upgrade_titles()
    elseif choose == "trykw" then
        king_city.try_unlock_kw()
    elseif choose == "startkw" then
        --king_city.unlock_kw()
        king_city.prepare_kw()
    elseif choose == "kingme" then
        self.officer = KING
    elseif choose == "fightkw" then
       king_city.fight_kw()
    elseif choose == "clearkw" then
        king_city.clear_officer()
    elseif choose == "peacekw" then
        king_city.pace_kw()
    elseif choose == "endkw" then
      --  king_city.pace_kw()
    elseif choose  == "kwinfo" then -- 王城战活动页面
        kw_info_req(self)
    elseif choose == "king" then
        king_city.select_default_king()
    elseif choose == "gsking" then
        self:king_info_req()
    elseif choose == "kingct" then --世界boss 加积分
        local uid = tonumber(tb[2])
        local kingCity = king_city.get_king()
        kingCity.uid = uid
    elseif choose == "addscore" then --世界boss 加积分
        local score = tonumber(tb[2])
        monster.bossKillScore.score = score
        gPendingSave.status[ "bossKillScore" ].score =  score
        monster.try_upgrade_stage()
    elseif choose == "forceboss" then --世界boss 加积分
        local lv = tonumber(tb[2])
        local propid, x, y = monster.force_born(math.floor(self.x/16), math.floor(self.y/16), lv)
        self:add_debug(string.format("boss pos , %d, %d", x, y))
    elseif choose == "syncall" then --同步call
        local union = unionmng:get_union(self.uid)
        local map_id = 8
        local func = "get_remote_members"
        local param = {"union", 1001}
        local ret, _members =  remote_func(map_id, func, param)
        print("debug", _members)
        Rpc:callAgent(8, "agent_syn_call", 1, "hahah", {1,1})
    elseif choose == "time" then --跨服
        local time = os.time()
        self:add_debug(string.format("time is %d", time))
        local map_id = tonumber(tb[2])
    elseif choose == "changeserver" then
        local map_id = tonumber(tb[2])
        self:ply_change_server(map_id, self.x, self.y)
    elseif choose == "jump" then --跨服
        local map_id = tonumber(tb[2])
        --self:ply_change_server(map_id, self.x, self.y)
        self:cross_migrate(map_id, self.x, self.y)
    elseif choose == "jumpback" then --跨服
        local map_id = tonumber(tb[2])
        self:cross_migrate_back(self.x, self.y)
    elseif choose == "upgs" then --跨服
        crontab.upload_gs_info()
    elseif choose == "crosst" then --跨服
        self:cross_act_st_req()
    elseif choose == "crossgm" then --跨服
        Rpc:callAgent(gCenterID, "cross_gm", tb)
    elseif choose == "eyemove" then --跨服
        local map_id = tonumber(tb[2])
        self:movEye(map_id, 1200, 1200)

    elseif choose == "daypass" then  -- 世界boss跨天
        monster.on_day_pass()
        npc_city.on_day_pass()
        npc_city.try_start_tw()
        king_city.try_unlock_kw()
        self:on_day_pass()

    elseif choose == "addarm" then
        local id = tonumber(tb[2])
        local num = tonumber(tb[3])
        self:add_soldier(arm_id(self.culture, id), num)

    elseif choose == "addgold" then
        local num = tonumber(tb[2])
        self.gold = num

    elseif choose == "addbuf" then
        local id = tonumber(tb[2])
        local count = tonumber(tb[3])
        self:add_buf( id, count )

    elseif choose == "skill" then
      --  self:launch_talent_skill(tonumber(get_parm(1)))
    elseif choose == "reload" then
        os.execute("./reload.sh")
        do_reload()
        player_t.add_chat(self, 0, 0, {pid=0}, "ok", 0, {})

    elseif choose == "ef_add" then
        local key = tb[2]
        local val = tonumber(tb[3])
        self:ef_add({[ key ] = val })

    elseif choose == "set_val" then
        local key = tb[2]
        local val = tonumber(tb[3])
        self[ key ] = val

    elseif choose == "set_ef" then
        local key = tb[2]
        local val = tonumber(tb[3])
        self._ef[ key ] = val

    elseif choose == "mars_tm" then
        self._union.god_log.tm = 0

    elseif choose == "title" then
        self:title_info_req()

    elseif choose == "foract" then
        self:ef_add({CountTroop=10, CountSoldier=1000000, Captive=100000})
        self:add_soldier(arm_id( self.culture, 1010), 100000)
        self:add_soldier(arm_id( self.culture, 2010), 100000)
        self:add_soldier(arm_id( self.culture, 3010), 100000)
        self:add_soldier(arm_id( self.culture, 4010), 100000)
        local union = self:union()
        if union then
            union.donate = union.donate + 9900000
        end
        self._union.donate = self._union.donate + 9900000
        gPendingSave.union_member[self.pid] = self._union
    elseif choose == "all" then
        --self:build_all()
        self:ef_add({CountTroop=10, CountSoldier=1000000, Captive=100000})
        self:add_soldier(arm_id( self.culture, 1010), 100000)
        self:add_soldier(arm_id( self.culture, 2010), 100000)
        self:add_soldier(arm_id( self.culture, 3010), 100000)
        self:add_soldier(arm_id( self.culture, 4010), 100000)
        self.gold = 100000
        self.silver = 100000
        self.kw_gold = 100000
        self.manor_gold = 100000
        self.relic_gold = 100000
        self.monster_gold = 100000
        kw_mall.kw_point = 1000000
        self.res = {
            {5000000,5000000},
            {5000000,5000000},
            {5000000,5000000},
            {5000000,5000000}
        }
        self:inc_sinew( 100) 

        for _, h in pairs(self._hero or {}) do h.hp = h.max_hp end
        --for _, h in pairs(self._hero or {}) do h.hp = 0 end

        --self:recalc_food_consume()

        local troop = self:get_my_troop()
        if troop then Rpc:upd_arm(self, troop:get_live(self.pid)) end

        local union = self:union()
        if union then
            union.donate = union.donate + 9900000
        end
        self._union.donate = self._union.donate + 9900000
        gPendingSave.union_member[self.pid] = self._union

    elseif choose == "test" then
        --local clv = tonumber(tb[2])
        --self:search_entity( 0, clv )
        --
        --self:display_ntf( {mode=DISPLY_MODE.ACHEVEMENT, id=10101}
        self.ache_point = 0
        self.hurts = {[arm_id(self.culture, 1010)]=10000}
        self.cures = {}
        --self.res = { {0,0},{0,0},{0,0},{0,0} }
        local troop = self:get_my_troop()
        troop.arms[ self.pid ] = { live_soldier = {} }

        --for _, h in pairs(self._hero or {}) do h.hp = 0 end
        --self:ef_add( {CountSoldier = 40000 } )
        Rpc:upd_arm(self, troop:get_live(self.pid))

    elseif choose == "clearres" then
        self.res = { {0,0},{0,0},{0,0},{0,0} }
        self.foodTm = gTime
        self.gold = 0
        self.silver = 0

    elseif choose == "adddaoju" then
        local itemid = tonumber(tb[2])
        local itemnum = tonumber(tb[3])
        local conf = resmng.get_conf("prop_item", itemid)
        if conf and itemnum > 0 then
            self:add_debug(string.format("additem, %d, %d", itemid, itemnum))
            --self:inc_item(itemid, itemnum, VALUE_CHANGE_REASON.DEBUG)
            self:add_bonus("mutex_award", {{"item", itemid, itemnum, 10000}}, VALUE_CHANGE_REASON.DEBUG)
        end

    elseif choose == "clearitem" then
        local items = self:get_item()
        local its = copyTab( items )
        for k, v in pairs( its ) do
            if type( v ) == "table" then
                self:dec_item( v[1], v[3], VALUE_CHANGE_REASON.DEBUG )
            end
        end

    elseif choose == "addequip" then
        local id = tonumber(tb[2])
        if resmng.prop_equip[ id ] then
            self:equip_add( id, VALUE_CHANGE_REASON.DEBUG )
        end

    elseif choose == "addres" then
        local mode = tonumber(tb[2])
        local num = tonumber(tb[3])
        self:do_inc_res_normal(mode, num, VALUE_CHANGE_REASON.DEBUG)

    elseif choose == "setres" then
        local mode = tonumber(tb[2])
        local num = tonumber(tb[3])
        self.res[mode][1] = num
        self.res = self.res


    elseif choose == "initres" then
        self.res = { {100000,0}, {100000,0}, {100000,0}, {100000,0} }


    elseif choose == "cleararm" then
        local troop = self:get_my_troop()
        troop.arms = {}

    elseif choose == "initarm" then
        self.cures = {}
        self.hurts = {}
        local troop = self:get_my_troop()
        local cul = self.culture
        troop.arms[ self.pid ].live_soldier = { [arm_id(cul,1005)]=10000, [arm_id(cul,2005)]=10000, [arm_id(cul,3005)]=10000, [arm_id(cul,4005)]=10000 }

        for k, v in pairs( self:get_hero() ) do
            if v.status == HERO_STATUS_TYPE.MOVING or v.status == HERO_STATUS_TYPE.FREE then
                self:hero_set_free( v )
                v.hp = v.max_hp * 0.5
                hero_t.mark_recalc( v )
            end
        end
        troop:save()
        Rpc:upd_arm(self, troop:get_live(self.pid))

        self:mark_action( recalc_pow_arm )
        self:mark_action( recalc_food_consume )
        self:mark_action( notify_arm )


    elseif choose == "back" then
        for _, tid in pairs(self.busy_troop_ids) do
            self:troop_recall(tid)
        end

   -- elseif choose == "addallitem" then
    elseif choose == "addalli" then
       -- if true then return end

        local its = {
            [1] = {1, 4001001, 10000},
            [2] = {2, 4001002, 10000},
            [3] = {3, 4001003, 10000},
            [4] = {4, 4001004, 10000},

            -- 碎片
            [5] = {5, 4002001, 20000},
            [6] = {6, 4002002, 20000},
            [7] = {7, 4002003, 20000},
            [8] = {8, 4002004, 20000},

            -- 经验书
            [9] = {9,  4003001, 30000},
            [10] = {10, 4003002, 30000},
            [11] = {11, 4003003, 30000},

            -- 特定技能书
            [12] = {12, 5001101, 40000},
            [13] = {13, 5001201, 40000},
            [14] = {14, 5001301, 40000},
            [15] = {15, 5001401, 40000},
            [16] = {16, 5001501, 40000},
            [17] = {17, 5001601, 40000},

            -- 通用技能书
            [22] = {22, 5002001, 50000},
            [23] = {23, 5002002, 50000},
            [24] = {24, 5002003, 50000},
            [25] = {25, 5002004, 50000},

            -- 重置技能书
            [26] = {26, 5003001, 10000},

            [27] = {27, 6001001, 60000},
            [28] = {28, 6002001, 60000},
            [29] = {29, 6003001, 60000},
            [30] = {30, 6004001, 60000},
            [31] = {31, 6005001, 60000},
            [32] = {32, 6006001, 60000},
        }

        num = #its
        for k, v in pairs(resmng.prop_item) do
            if v.Class == 4 and v.Mode == 2 then
                num = num + 1
                table.insert(its, {num, k, 10000})
            end
        end

        for k, v in pairs( its ) do
            self:inc_item( v[2], v[3], VALUE_CHANGE_REASON.DEBUG )
        end

        --self._item = its
        --player_t._cache_items[ self.pid ] = its
        self.gold = 100000
        self.silver = 100000


    elseif choose == "dailyactivity" then
        self.activity = tonumber(get_parm(1))
    elseif choose == "dailyresetbox" then
        self.activity_box = {}
    elseif choose == "dailyactivity_refresh" then
        Rpc:callAgent(gCenterID, "periodic_activity_gm_refresh_activity", tonumber(get_parm(1)), tonumber(get_parm(2)))
    elseif choose == "finishtask" then
        local task_id = tonumber(get_parm(1))
        self:gm_finish_task(task_id)
    elseif choose == "accepttask" then
        local task_id = tonumber(get_parm(1))
        self:gm_accept_task(task_id)
    elseif choose == "cleargacha" then
        self:gacha_on_day_pass()
    elseif choose == "37chat" then
        to_37_chat_center(self, 1, tb[2])
    elseif choose == "setvip" then
        self.vip_lv = tonumber(get_parm(1))
    elseif choose == "sys_mail" then
        self:send_system_notice(10001, {"hello"}, {"hello"}, {{"item", resmng.ITEM_2100013, 3, 10000}})
        --self:send_system_notice(10001)
        --self:send_system_notice(10002)
        --self:send_system_city_move(20001, 1510001, {x=1170, y=1210, target_pid=100000,icon=1}, {"jim"})

    elseif choose == "reset_hero" then
        for k, v in pairs( self:get_hero() ) do
            if v.status == HERO_STATUS_TYPE.MOVING or v.status == HERO_STATUS_TYPE.FREE then
                self:hero_set_free( v )
                v.hp = math.floor(v.max_hp * 0.5)
            end
        end
    elseif choose == "addbuf" then
        local bufid = tonumber(get_parm(1))
        local count = tonumber(get_parm(2))
        self:add_buf( bufid, count )

    elseif choose == "cleartroop" then
        for k, v in pairs( self.busy_troop_ids ) do
            local troop = troop_mng.get_troop( v )
            if troop then
                troop_mng.delete_troop( v )
            end
        end
        self.busy_troop_ids = {}


    elseif choose == "setphoto" then
        self.photo =  tonumber(get_parm(1))

    elseif choose == "robot" then
        if tonumber( get_parm( 1 ) ) == 1 then
            config.Robot = true
        else
            config.Robot = nil
        end

    elseif choose == "search" then
        local propid = tonumber( get_parm( 1 ) )
        self:search_entity( 0, propid )

    elseif choose == "traintime" then
        for mode = 1, 4, 1 do
            local idx = self:calc_build_idx(BUILD_CLASS.ARMY, mode )
            local build = self:get_build( idx )
            if build then
                self:add_debug( string.format( "ARMY %d, diff = %d", mode, build.tmOver - gTime ) )
            else
                self:add_debug( string.format( "ARMY %d, diff = %d", mode, -1) )
            end
        end

    elseif choose == "lvbuild" then
        local class = tonumber(get_parm(1))
        local mode = tonumber(get_parm(2))
        local lv = tonumber(get_parm(3))

        local propid = class * 1000000 + mode * 1000 + lv
        local dst = resmng.get_conf( "prop_build", propid )
        if dst then
            local build_idx = self:calc_build_idx(class, mode, 1)
            local bs = self:get_build()
            local build = bs[ build_idx ]
            if build then
                local src = resmng.get_conf( "prop_build", build.propid )
                if src then
                    if dst.Lv > src.Lv then
                        local dif = dst.Lv - src.Lv
                        for i =1, dif, 1 do
                            self:do_upgrade( build_idx )
                        end
                    else
                        build.propid = propid
                        self:ef_chg(src.Effect or {}, dst.Effect or {})
                    end
                end
            end
        end
        upload_user_info(self)

    elseif choose == "world_event" then
        local id = tonumber(get_parm(1))
        local num = tonumber(get_parm(2))
        world_event.gm_finish_world_event(id, num)

    elseif choose == "massgo" then
        for _, tid in pairs( self.busy_troop_ids ) do
            local tr = troop_mng.get_troop(tid)
            if tr and tr.is_mass == 1 and tr:is_ready() then
                timer.adjust( tr.tmSn, gTime )
            end
        end
    elseif choose == "opt" then
        --operate_activity.gm()
        self:operate_on_day_pass()

    elseif choose == "renwu" then
        local st = c_msec()
        self:on_day_pass_daily_task()
        LOG("taskstatics:daily_on_day_pass:"..(c_msec()-st))

    elseif choose == "kaifu" then
        gmcmd.kaifu()
        set_sys_status("start", gTime)
        world_event.reinit_world_event()
        weekly_activity.reinit_weekly_activity()
        operate_activity.reinit_operate_activity()
        daily_activity.reinit_daily_activity()

    elseif choose == "swapout" then
        local pid = tonumber(get_parm(1))
        local p = getPlayer( pid )
        if p then
            swap_out( p )
        end
    end
end

function qryInfo(self, aid)
    if aid == 0 then aid = self.pid end
    local p = getPlayer(aid)
    if p then
        Rpc:qryInfo(self, p._pro)
    end
end

function get_one(self, what)--本函数严禁加日志
    local val = {}
    if what == "pro" then
        val = self._pro
    elseif what == "ef_eid" then
        local e = get_ety(self.ef_eid)
        if e then
            val = { eid=e.eid, uid = e.uid, propid=e.propid }
        else
            val = { eid = 0, uid = 0, propid = 0 }
        end
    elseif what == "item" then
        val = self:get_item()

    elseif what == "equip" then
        val = self:get_equip()

    elseif what == "ef" then
        val = self._ef

    elseif what == "ef_hero" then
        val = self._ef_hero

    elseif what == "build" then
        local ts = {}
        for k, v in pairs(self:get_build() or {}) do
            table.insert(ts, v._pro)
        end
        val = ts

    elseif what == "tech" then
        val = self.tech

    elseif what == "hero" then
        local ts = {}
        for k, v in pairs(self._hero or {}) do
            local h = copyTab(v._pro)
            table.insert(ts, h)
        end
        val = ts

    elseif what == "troop" then
        local data = {}
        for _, tid in pairs(self.busy_troop_ids) do
            local tr = troop_mng.get_troop(tid)
            if tr then
                table.insert( data, tr:get_info() )
            end
        end
        val = data

    elseif what == "ache" then
        val = self:get_ache()

    elseif what == "count" then
        val = self:get_count()

    elseif what == "arm" then
        local my_troop = troop_mng.get_troop(self.my_troop_id)
        if my_troop ~= nil then
            local a = my_troop.arms[ self.pid ]
            if a then a = a.live_soldier end
            if not a then a = {} end
            val = a
        end

    elseif what == "task" then
        val = self:packet_all_task_id()

    elseif what == "watch_tower" then
        val = watch_tower.packet_watchtower_info(self)

    elseif what == "client_parm" then
        val = self:load_client_parm()

    elseif what == "target" then
        val = self:packet_target_task()
    elseif what == "37_pids" then
        for pid, _ in pairs( gAccounts[self.account] or {} ) do
            local p = getPlayer( pid )
            table.insert(val,{ dsid=gMap,drid=pid,drname=p.name,drlevel=p:get_castle_lv()})
        end
    end
    return val
end

function first_blood_info_req(self)
    local pack = self:get_first_blood()
    Rpc:first_blood_info_ack(self, pack)
end


function loadData(p, what)--本函数严禁加日志
    local t = {}
    t.key = what
    if what == "pro" then
        t.val = p._pro
    elseif what == "ef_eid" then
        local e = get_ety(p.ef_eid)
        if e then
            t.val = { eid=e.eid, uid = e.uid, propid=e.propid }
        else
            t.val = { eid = 0, uid = 0, propid = 0 }
        end
    elseif what == "item" then
        t.val = p:get_item()

    elseif what == "equip" then
        t.val = p:get_equip()
    elseif what == "hero_equip" then
        local ts = {}
        for k, v in pairs( p:get_hero_equip() or {}) do
            table.insert(ts, v._pro)
        end
        t.val = ts

    elseif what == "ef" then
        t.val = p._ef

    elseif what == "ef_hero" then
        t.val = p._ef_hero

    elseif what == "build" then
        local ts = {}
        for k, v in pairs(p:get_build() or {}) do
            table.insert(ts, v._pro)
        end
        t.val = ts

    elseif what == "tech" then
        t.val = p.tech

    elseif what == "hero" then
        local ts = {}
        for k, v in pairs(p._hero or {}) do
            local h = copyTab(v._pro)
            table.insert(ts, h)
        end
        t.val = ts

    elseif what == "troop" then
        local data = {}
        for _, tid in pairs(p.busy_troop_ids) do
            local tr = troop_mng.get_troop(tid)
            if tr then
                table.insert( data, tr:get_info() )
            end
        end
        t.val = data

    elseif what == "ache" then
        t.val = p:get_ache()

    elseif what == "count" then
        t.val = p:get_count()

    elseif what == "arm" then
        local my_troop = troop_mng.get_troop(p.my_troop_id)
        if my_troop ~= nil then
            local a = my_troop.arms[ p.pid ]
            if a then a = a.live_soldier end
            if not a then a = {} end
            t.val = a
        end

    elseif what == "task" then
        t.val = p:packet_all_task_id()
        --lxz(p.pid,t.val)

    elseif what == "watch_tower" then
        t.val = watch_tower.packet_watchtower_info(p)

    elseif what == "client_parm" then
        if gTime - p.tm_create < 20 then
            t.val = {}
        else
            t.val = p:load_client_parm()
        end

    elseif what == "target" then
        t.val = p:packet_target_task()

    elseif what == "first_blood" then
        t.val = p:get_first_blood()

    elseif what == "sys_option" then
        t.val = gSysOption
    elseif what == "yueka" then
        t.val = yueka_t.get(p)
    elseif what == "operate_activity"  then
        if not p._operate_activity then 
            local t = load_operate_activity(p) or {}
            if not p._operate_activity then rawset(p, "_operate_activity", t) end
        end
        t.val = p._operate_activity
    
    elseif what == "done" then
        INFO( "[login], pid=%d, loaddone", p.pid )
    end

    if not t.val then t.val = {} end
    Rpc:loadData(p, t)

    if what == "done" then
        if npc_city.cur_declares then 
            local infos = {}
            for k, v in pairs(npc_city.cur_declares or {}) do
                local eid = npc_city.get_npc_eid_by_propid(k)
                local npc = get_ety(eid)
                if npc then
                    if npc.state == TW_STATE.FIGHT then
                        infos[k] = v
                    end
                end
            end
            Rpc:monster_declare( p, infos ) 
        end

        if not p.ntodo or p.ntodo > 0 then
            local db = p:getDb()
            local info = db.todo:find( {pid=p.pid} )
            if info then
                local list = {}
                while info:hasNext() do
                    local task = info:next()
                    if task.command == "display_ntf" and task.args[1].mode == DISPLY_MODE.NPC then
                        if #list > 0 then
                            local has_same = false
                            for k, v in pairs(list or {}) do
                                if v.command == "display_ntf" and v.args[1].mode == DISPLY_MODE.NPC then
                                    if v.args[1].npc_id == task.args[1].npc_id then
                                        has_same = true
                                        if task.time > v.time then
                                            gPendingDelete.todo[ v._id ] = 1
                                            list[k] = task
                                        else
                                            gPendingDelete.todo[ task._id ] = 1
                                        end
                                    end
                                end
                            end
                            if has_same == false then
                                table.insert(list, task)
                            end
                        else
                            table.insert(list, task)
                        end
                    else
                        table.insert(list, task)
                    end
                end

                for _, task in pairs(list or {}) do
                    gPendingDelete.todo[ task._id ] = 1
                    player_t[ task.command ]( p, table.unpack( task.args ) )
                end
            end
            rawset( p, "ntodo", 0 )
        end

        if p.mail_sys ~= gSysMailSn then
            mail_compensate( p )
        end

        if gOperateDiceTime > 0 then
            operate_dice_query( p )
        end
        p:claim_cross_award()

        if gClientExtraPost then Rpc:do_string( p, gClientExtraPost ) end

    end
end



function get_room(self,rid)
    local info = room.get_info(rid)
    Rpc:get_room(self, rid,info)
end


function qryblock(self, ...)
    local pid = self.pid
    local gid = self.gid
    for _, v in pairs({...}) do
        if v >= 0 then
            c_qry_block(pid, gid, v)
        end
    end
end

function ply_change_server(self, map_id, x, y)
    if self.tm_create + CROSS_SERVER_MOVE_TIME < gTime then
        return
    end
    if self:get_castle_lv() > 5 then
        return
    end

    if #self.busy_troop_ids > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end

    if not self:can_move_to(x, y)  then return self:add_debug("can not move by castle lv") end

    if map_id ~= gMapID then

        if self.emap == gMapID then
            local ef_u,ef_ue = self:get_union_ef()
            self.ef_u = ef_u
            self.ef_ue = ef_ue
        else
            self.ef_u = {}
            self.ef_ue = {}
        end

        local data = self:player_data_pull(false, true)

        Rpc:callAgent(map_id, "change_server", self.pid, x, y, data)

         self:movEye(map_id, x, y)
    end
end

function cross_migrate(self, map_id, x, y)
    if #self.busy_troop_ids > 0 then
        WARN("[CrossWar]busy troop %d", self.pid)
        return ack(self, "migrate", resmng.E_TROOP_BUSY, 0)
    end

    if not self:can_move_to(x, y)  then
        WARN("[CrossWar]can't move to  %d|%d|%d", self.pid, x, y)
        return self:add_debug("can not move by castle lv")
    end

    if self.emap == map_id then
        WARN("[CrossWar]the target server is the current server  %d|%d", self.pid, map_id)
        return
    end
    if check_ply_cross(self) then
        -- 跨服时，不能再跳转到其他服务器
        WARN("[CrossWar]player is local player  %d", self.pid)
        return
    end
    if not cross_act.is_fighting() then
        WARN("[CrossWar]the server is not in the cross war  %d", self.pid)
        return
    end
    if not cross_act.is_in_group(map_id) then
        WARN("[CrossWar]the server is not in the cross war group %d", self.pid)
        return
    end

    if map_id ~= gMapID then
        if self:get_item_num(CROSS_MIGRATE_ITEM) < 1 and self.gold < MIGRATE_GOLD then
            WARN("[CrossWar]player has no cross migrate item %d", self.pid)
            return
        end

        local u = self:get_union()
        if not u then
            WARN("[CrossWar]player has no union %d", self.pid)
            return 
        end
        if u:is_new() then
            WARN("[CrossWar]player's union is new %d", self.pid)
            return
        end

        if self.emap == gMapID then
            local ef_u,ef_ue = self:get_union_ef()
            self.ef_u = ef_u
            self.ef_ue = ef_ue
        else
            self.ef_u = {}
            self.ef_ue = {}
        end

        local data = self:player_data_pull(false, false)
        Rpc:callAgent(map_id, "agent_migrate", self.pid, x, y, data, u._pro)

        self:remEye()
    end
end

function cross_migrate_back(self, x, y)
    for _, id in pairs(self.busy_troop_ids or {}) do
        local tr = self:troop_recall(id, true )
        if tr then
            tr:home()
        end
    end

    if #self.busy_troop_ids > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end

    if -1 ~= x and -1 ~= y then
        if not self:can_move_to(x, y) then
            return self:add_debug("can not move by castle lv")
        end
    end

    local comings = self.troop_comings
    if comings then
        for tid, action in pairs( comings ) do
            local troop = troop_mng.get_troop( tid )
            if troop and troop:is_go() then
                local action = troop:get_base_action()
                if action == TroopAction.SiegePlayer or action == TroopAction.MonsterAtkPly or action == TroopAction.SupportArm or action == TroopAction.Spy then
                    c_troop_set_speed( troop.eid, 2000, 1 )
                    triggers_t.arrived_target( troop.dx, troop.dy, troop.eid )
                end
            end
        end
    end

    if self.emap ~= gMapID then
        if self.emap == gMapID then
            local ef_u,ef_ue = self:get_union_ef()
            self.ef_u = ef_u
            self.ef_ue = ef_ue
        else
            self.ef_u = {}
            self.ef_ue = {}
        end

        local data = self:player_data_pull(true, true)
        Rpc:callAgent(self.emap, "agent_migrate_back", self.pid, x, y, data, {})
        self:remEye()
    end
end

function on_cross_migrate(self)
    if self:get_item_num(CROSS_MIGRATE_ITEM) < 1 then
        self:dec_gold(MIGRATE_GOLD, VALUE_CHANGE_REASON.MIGRATE )
    else
        self:dec_item_by_item_id(CROSS_MIGRATE_ITEM, 1, VALUE_CHANGE_REASON.MIGRATE)
    end
    local timer_id, tm = timer.new("cross_migrate_back", 4 * 3600, self.pid)
    action(function() self:set_mark("cross_migrate_back", timer_id) end)
    local info = {
        tm_over = tm.over,
    }
    Rpc:cross_auto_migrate_back_info(self, info)
end

function on_cross_login(self)
    action(function()
        local timer_id = self:get_mark("cross_migrate_back")
        if timer_id then
            local tm = timer.get(timer_id)
            if tm then
                local info = {
                    tm_over = tm.over,
                }
                Rpc:cross_auto_migrate_back_info(self, info)
            end
        end
    end)
end

function clear_cross_data(self)
    if next(self.cross_officer or {}) then
        self.cross_officer = {}
    end
end

function claim_cross_award(self)
    Rpc:callAgent(gCenterID, "claim_player_cross_award", self.pid)
end

function get_build_timers_and_del(self)
    local bs = self:get_build()
    local timers = {}
    for k, v in pairs(bs or {}) do
        local tm  = timer.get(v.tmSn)
        if tm then
            table.insert(timers, tm)
            timer.del(v.tmSn)
        end

    end
    return timers
end

function addEye(self, map, x, y)
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end

    if map == gMapID then
        c_add_eye(self.pid, x, y)
    else
        if not self.eyes then self.eyes = {} end
        self.eyes[ map ] = 1
        c_rem_eye( self.pid )
        Rpc:callAgent( map, "agent_add_eye", self.pid, x, y )
    end
end

function movEye(self, map, x, y)
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end

    if map == gMapID then
        c_mov_eye(self.pid, x, y)
    else
        if not self.eyes then self.eyes = {} end
        self.eyes[ map ] = 1
        c_rem_eye( self.pid )
        Rpc:callAgent( map, "agent_mov_eye", self.pid, x, y )
    end
end

function remEye(self)
    if self.pid < 0  then return end
    c_rem_eye(self.pid)
    if self.eyes then
        for map, v in pairs( self.eyes ) do
            Rpc:callAgent( map, "agent_rem_eye", self.pid)
        end
        self.eyes = nil
    end
end


function say(self, saying, i)
    if (gTime - self.tm_create) > 1800 then return  end
    LOG("[SAY], pid,%d, tm,%d, lv,%d, say,%s, ", self.pid, gTime - self.tm_create, self.propid % 1000, saying )

    --local t = {}
    --for v in string.gmatch(saying,'[^,]+') do
    --    table.insert(t,v)
    --end
    --Rpc:say1(self, saying, i)
end

function say1( self, saying, i )
    if i == 1 then
        INFO( "[ClientSpecial], pid,%d, say,%s, i,%d, ip,%s, name,%s", self.pid, saying, i, self.ip or "",  self.name  )
    elseif i == 0 then
        Rpc:say1( self, saying, i )
    end
end


function check_say2(day)
    local a,b={},{}
    day = day or 1
    local db = dbmng:getOne()
    local info = db.say:find()
    if info then
        while info:hasNext() do
            local num = 0
            local d = info:next()
            if d.tm > day *24*60*60  then b[d.pid] = 1 end
            if d.tm < 10*60 then 
                a[d.pid] = a[d.pid] or {} 
                a[d.pid][d.say] = (a[d.pid][d.say] or 0) + 1 
            end
        end

    end

    for pid, v in pairs(b) do 
        b[pid] = a[pid]
        a[pid] = nil 
    end

    local t,num= {},0
    for pid, v in pairs(a) do 
        num = num + 1
        for k, n in pairs(v) do 
            for k, v in pairs(t) do LOG("[SAYa]%d, %d, %s", pid,n,k ) end
            t[k] = (t[k] or 0 ) + n 
        end
    end

    for k, v in pairs(t) do 
        LOG("[SAYa1]%f,%s",(v/num),k )
    end

    t,num= {},0
    for pid, v in pairs(b) do 
        num = num + 1
        for k, n in pairs(v) do 
            for k, v in pairs(t) do LOG("[SAYb]%d, %d, %s", pid,n,k ) end
            t[k] = (t[k] or 0 ) + n 
        end
    end

    for k, v in pairs(t) do 
        LOG("[SAYb1]%f,%s",(v/num),k )
    end
end


function runCommand(self, str)
    function run()
        Rpc:runCommand(self, {info=loadstring(str)()})
    end
    local result = xpcall(run, function(e)
        WARN(e..debug.stack(1))
        --Rpc:runCommand(self, {err=e, stack=debug.traceback()})
    end)
end

function can_food(self,num)
    local foodUse = self.foodUse * self:get_num("FoodUse_R")
    local use = math.ceil((gTime - self.foodTm) *  foodUse / 3600)
    local have = self.food

    if use >= have then
        have = 0
    else
        have = have - use
    end

    return have > num
end

function resetfood(self)
    local foodUse = self.foodUse * self:get_num("FoodUse_R")
    local use = math.ceil((gTime - self.foodTm) *  foodUse / 3600)
    local have = self.food
    if use >= have then have = 0
    else have = have - use end

    self.food = have
    self.foodTm = gTime

    INFO( "resetfood" )

    --if save then self:save("player", self.pid, {food=have, foodTm=gTime}) end
    return self.food
end


--------------------------------------------------------------------------------
-- Function : 查询玩家资源数量
-- Argument : self, res_type
-- Return   : succ - number; fail - false
-- Others   : NULL
--------------------------------------------------------------------------------
function get_res_num(self, mode)
    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            return self[ key ] or 0
        end
    else
        local node = self.res[ mode ]
        if node then
            if mode == resmng.DEF_RES_FOOD then
                local store = self:get_val("CountStore")
                if store > node[1] then
                    return node[1] + node[2]
                else
                    local consume = self.foodUse * (gTime - self.foodTm) / 3600
                    local have = node[1] - consume
                    if have < store then have = store end
                    return have + node[2]
                end
            else
                return node[1] + node[2]
            end
        end
    end
    return 0
end

function get_res_num_normal(self, mode)
    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            return self[ key ] or 0
        end
    else
        local node = self.res[ mode ]
        if node then
            if mode == resmng.DEF_RES_FOOD then
                local store = self:get_val("CountStore")
                if store > node[1] then
                    return node[1]
                else
                    local consume = self.foodUse * (gTime - self.foodTm) / 3600
                    local have = node[1] - consume
                    if have < store then have = store end
                    return have
                end
            else
                return node[1]
            end
        end
    end
    return 0
end

function refresh_food(self)
    local node = self.res[ resmng.DEF_RES_FOOD ]
    local store = self:get_val("CountStore")
    local have = node[1]
    if store >= have then

    else
        local consume = self.foodUse * (gTime - self.foodTm) / 3600
        have = have - consume
        if have < store then have = store end
        have = math.floor(have)
        node[1] = have
    end
    self.foodTm = gTime
end

function get_sinew( self )
    self:do_recalc_sinew()
    return self.sinew
end


function dec_sinew( self, num )
    if num < 0 then return end
    self:do_recalc_sinew()
    local val = self.sinew - num
    if val < 0 then val = 0 end
    self.sinew = val
end

function inc_sinew( self, num )
    if num < 0 then return end
    self:do_recalc_sinew()
    self.sinew = self.sinew + num
end

function do_recalc_sinew( self )
    self.sinew = recalc_sinew( self.sinew, self.sinew_tm, gTime, 1 + self.sinew_speed * 0.0001 )
    self.sinew_tm = gTime
    self.sinew_speed = self:get_num( "SpeedRecover_R" )
end

function recalc_food_consume(self)
    self:refresh_food()
    local consume = 0
    for _, tid in pairs(self.busy_troop_ids) do
        local troop = troop_mng.get_troop(tid)
        if troop and troop.arms then
            local arm = troop.arms[ self.pid ]
            if arm then
                for id, num in pairs(arm.live_soldier or {}) do
                    local conf = resmng.get_conf("prop_arm", id)
                    if conf then
                        consume = consume + conf.Consume * num
                    end
                end
            end
        end
    end

    local home = troop_mng.get_troop(self.my_troop_id)
    if home then
        local arm = home.arms[ self.pid ]
        if arm then
            for id, num in pairs(arm.live_soldier or {}) do
                local conf = resmng.get_conf("prop_arm", id)
                if conf then
                    consume = consume + conf.Consume * num
                end
            end
        end
    end

    local m = self:get_num("SpeedConsume_R")
    local rate = 1 + m * 0.0001
    if rate < 0.05 then rate = 0.05 end
    consume = consume * rate

    self.foodTm = gTime
    self.foodUse = math.floor(consume)
end


function do_inc_res_protect(self, mode, num, reason)
    if not reason then
        ERROR("do_inc_res_normal: pid = %d, don't use the default reason.", self.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then
        WARN("do_inc_res, pid=%d, num=%d, reason=%s, num<0", self.pid, num, reason)
        return
    end
    INFO( "[RES], inc, pid=%d, mode=%d, num=%d, reason=%s, protect", self.pid, mode, num, reason or 0 )

    if mode > resmng.DEF_RES_ENERGY then
        self:do_inc_res_normal( mode, num, reason )
    else
        if mode == resmng.DEF_RES_FOOD then self:refresh_food() end
        local node = self.res[ mode ]
        if not node then return end
        node[2] = node[2] + num
        self.res = self.res
        self:pre_tlog("MoneyFlow",0,calc_res(mode,num),10 + mode,0,calc_res(mode,node[2]),reason )
    end
end

function do_inc_res_normal(p, mode, num, reason)
    if mode < 1 then return end

    if not reason then
        ERROR("do_inc_res_normal: pid = %d, don't use the default reason.", p.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then
        WARN("do_inc_res, pid=%d, num=%d, reason=%s, num<0", p.pid, num, reason)
        return
    end
    num = math.floor( num )

    INFO( "[RES], inc, pid=%d, mode=%d, num=%d, reason=%s, normal", p.pid, mode, num, reason or 0)

    if mode <= resmng.DEF_RES_ENERGY then
        local node = p.res[ mode ]
        if not node then return end
        if mode == resmng.DEF_RES_FOOD then p:refresh_food() end
        node[1] = math.floor(node[1] + num)
        p.res = p.res
            
        p:pre_tlog("MoneyFlow",0,calc_res(mode,num),10 + mode,0,calc_res(mode,node[1]),reason )

    elseif mode == resmng.DEF_RES_MARSEXP then
        union_god.add_exp(p,num)

    elseif mode == resmng.DEF_RES_PERSONALHONOR then
        union_member_t.add_donate(p, num,reason)
        local union = unionmng.get_union(p:get_uid())
        if union then union:add_donate(num * 1.4, p) end
    elseif mode == resmng.DEF_RES_UNITHONOR then
        -- 不做任何事情

    elseif mode == resmng.DEF_RES_LORDEXP then
        p:add_exp(num)

    elseif mode == resmng.DEF_RES_VIPEXP then
        p:vip_add_exp(num)

    elseif mode == resmng.DEF_RES_LORDSINEW then
        p:inc_sinew( num )

    else
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            p[ key ] = math.floor((p[ key ] or 0) + num)
            if mode == resmng.DEF_RES_GOLD  then
                p:pre_tlog("MoneyFlow",0,num,2,0,p[key],reason )
                --p:tlog_ten("MoneyFlow",0,p:get_castle_lv(),p[key],num,0,reason,0,1,p.ip or "0.0.0.0" )
                --p:tlog_ten2("MoneyFlow",0,p[key],num,0,reason,0,1,p.ip or "0.0.0.0" )
            elseif mode == resmng.DEF_RES_SILVER  then
                p:pre_tlog("MoneyFlow",0,num,1,0,p[key],reason )
            end
        end
    end
end

function do_dec_res(p, mode, num, reason)
    if not reason then
        ERROR("do_dec_res: pid = %d, don't use the default reason.", p.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then
        WARN("do_dec_res, pid=%d, num=%d, reason=%s, num>=0", p.pid, num, reason)
        return
    end

    num = math.floor(num)
    if num < 1 then num = 1 end

    INFO( "[RES], dec, pid=%d, mode=%d, num=%d, reason=%s", p.pid, mode, num, reason or 0)

    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            if p[ key ] and p[ key ] >= num then
                p[ key ] = math.floor(p[ key ] - num)
                if  mode ==resmng.DEF_RES_GOLD  then
                    p:add_count( resmng.ACH_COUNT_GOLD_COST, num )
                    p:pre_tlog("MoneyFlow",0,num,2,1,p[key],reason )
                    --p:tlog_ten("MoneyFlow",0,p:get_castle_lv(),p[key],num,0,reason,1,1,p.ip or "0.0.0.0")
                    --p:tlog_ten2("MoneyFlow",0,p[key],num,0,reason,1,1,p.ip or "0.0.0.0")
                    union_mission.ok(p,UNION_MISSION_CLASS.COST, num)
                elseif mode == resmng.DEF_RES_SILVER  then
                    p:pre_tlog("MoneyFlow",0,num,1,1,p[key],reason )
                end
                return true
            end
            INFO( "[RES], dec, not enough, pid=%d, mode=%d, num=%s, have=%s", p.pid, mode, num, p[ key ] or 0 )
            return false
        end
    else
        local node = p.res[ mode ]
        if not node then return end

        if mode == resmng.DEF_RES_FOOD then p:refresh_food() end

        if node[1] >= num then
            node[1] = math.floor(node[1] - num)
            p.res = p.res
            return true

        elseif node[1] + node[2] >= num then
            num = num - node[1]
            node[1] = 0
            node[2] = math.floor(node[2] - num)
            p.res = p.res
            return true

        else
            INFO( "[RES], dec, not enough, pid=%d, mode=%d, num=%s, have=[%s, %s]", p.pid, mode, num, node[1], node[2] )
            return false

        end
    end
end

function reCalcFood(self)
    self:resetfood()
    local use = 0
    local live = self:get_live()
    for k, v in pairs(live or {}) do
        local node = resmng.prop_arm[k]
        if node ~= nil then
            use = use + node.Consume * v
        end
    end

    for k, v in pairs(self.busy_troop_ids or {}) do
        local troop = troop_mng.get_troop(v)
        local arm = troop:get_arm_by_pid(self.pid)
        if arm ~= nil then
            for i, j in pairs(arm.soldier or {}) do
                local node = resmng.prop_arm[i]
                if node ~= nil then
                    use = use + node.Consume * j
                end
            end
        end
    end

    use = math.ceil(use)
    self.foodUse = use
    self.foodTm = gTime

    INFO( "reCalcFood" )
end


function mark_action_by_pid( pid, action )
    if not action then return end
    local node = gDelayAction[ pid ]
    if not node then
        gDelayAction[ pid ] = { [ action ] = 0 }
    else
        node[ action ] = 0
    end
end

function mark_action( self, action )
    if not action then
        MARK("mark_action")
        return
    end
    local node = gDelayAction[ self.pid ]
    if not node then
        gDelayAction[ self.pid ] = { [ action ] = 0 }
    else
        node[ action ] = 0
    end
end

function notify_arm( self )
    local troop = self:get_my_troop()
    if troop then
        troop:save()
        Rpc:upd_arm( self, troop.arms[ self.pid ].live_soldier )
    end
end

function add_soldier( self, id, num )
    id = arm_id( self.culture, id )
    local troop = self:get_my_troop()
    if troop then
        local conf = resmng.get_conf( "prop_arm", id )
        if conf then
            if num > 0 then
                troop:add_soldier( id, num )
                self:mark_action( recalc_pow_arm )
                self:mark_action( recalc_food_consume )
                self:mark_action( notify_arm )
                --troop:save()
            end
        end
    end
end

function rem_soldier( self, id, num )
    if num < 0 then
        WARN( "[REM_SOLDIER], NUM_ERROR, pid=%d, id=%d, num=%d", self.pid, id, num )
        return false
    end

    local troop = self:get_my_troop()
    if troop then
        if troop:rem_soldier( id, num ) then
            self:mark_action( recalc_pow_arm )
            self:mark_action( recalc_food_consume )
            self:mark_action( notify_arm )
            troop:save()
            return true
        end
    end
end

function add_soldiers( self, soldiers )
    local troop = self:get_my_troop()
    if troop then
        local count = troop:add_soldiers( soldiers )
        if count > 0 then
            self:mark_action( recalc_pow_arm )
            self:mark_action( recalc_food_consume )
            self:mark_action( notify_arm )
            troop:save()
        end
    end
end

function testPack(self, i1, p2, s3)
    LOG("testPack, i1=%d, s3=%s", i1,s3)
    LOG("testPack, pack = ")
    --dumpTab(p2)
    Rpc:testPack(self, i1, p2, s3)
end

function add_debug(self, val, ...)
    if ... then val = string.format( val, ... ) end
    INFO( "[DEBUG], pid,%d, %s", self.pid, val ) 
    --Rpc:notify_server(self, val)
    --player_t.add_chat(self, 0, 0, {pid=0},  val, 0, {} )
    return false
end

function add_chat( to, channel, id, speaker, word, lang, args )
    lang = lang or 0
    args = args or {}

    if to.pid == -1 and speaker.pid == 0 and channel == resmng.ChatChanelEnum.World then
        id = 0
        channel = ChatChanelEnum.Culture
    end

    local idx = id * 10 + channel
    if channel == resmng.ChatChanelEnum.Notice then
        idx = 0
    end

    local node = gChat[ idx ]
    if not node then
        node = { sn = 0, list = {} }
        gChat[ idx ] = node
    end
    local sn = node.sn + 1
    node.sn = sn
    local list = node.list
    table.insert( list, { sn, gTime, speaker, word, lang, args, id, channel } )

    if #list > 100 then table.remove( list, 1 ) end
    Rpc:chat( to, channel, sn, speaker, word, lang, args, id, channel)
end

function fetch_chat( self, channel, sn, count )
    --self:add_debug( "just for test" )

    local idx = 0
    if channel == resmng.ChatChanelEnum.World then
        idx = 0
    elseif channel == resmng.ChatChanelEnum.Union then
        idx = self.uid * 10 + channel

    elseif channel == resmng.ChatChanelEnum.Culture then
        idx = channel

    elseif channel == resmng.ChatChanelEnum.Notice then
        idx = 0

    elseif channel == -1 then
        self:fetch_chat( resmng.ChatChanelEnum.World, -1, count )
        self:fetch_chat( resmng.ChatChanelEnum.Union, -1, count )
        self:fetch_chat( resmng.ChatChanelEnum.Culture, -1, count )
        return

    else
        return
    end

    local node = gChat[ idx ]
    if node then
        local list = node.list
        local num = #list
        if num > 0 then
            if sn < 0 then
                local start = num - count
                if start < 1 then start = 1 end
                local infos = {}
                for i = start, num, 1 do
                    table.insert( infos, list[ i ] )
                end
                Rpc:fetch_chat( self, channel, infos )
                return
            else
                local first = list[1][1]
                local offset = sn - first
                if offset > 0 then
                    local start = offset - count - 1
                    if start < 1 then start = 1 end
                    local infos = {}
                    for i = start, offset, 1 do
                        table.insert( infos, list[ i ] )
                    end
                    Rpc:fetch_chat( self, channel, infos )
                    return
                end
            end
        end
    end
    Rpc:fetch_chat( self, channel, {} )
end

function chat_p2p(self, pid, word)
    local ply = getPlayer(pid)
    if ply then
        offline_ntf.post(resmng.OFFLINE_NOTIFY_MAIL, self, self:get_union() or {}, word)
    end
end

function chat(self, channel, word, sn)
    --gm
    if gTime < (self.nospeak_time or 0 ) then
        Rpc:tips(self, 3, resmng.NOSPEAK_TIME, {tms2str(self.nospeak_time)})
        return
    end

    local lvip = nil
    if self:is_vip_enable() then lvip = self.vip_lv end
    local officer = self:get_officer()

    local speaker = { pid = self.pid, photo = self.photo, name = self.name, vip = lvip , officer = officer, title = self.title, nation = self.nation, show_nation = self.show_nation, map = self.map, emap = self.emap}
    --print("is valid string ", is_valid_name(word))
    if config.IsEnableGm == 1 then
        local ctr = string.sub(word, 1, 1)
        if ctr == "@" then
            self:gm_user(string.sub(word, 2, -1))
            return
        end
    else
        if not is_valid_name(word) then
            ack(self, "chat", resmng.E_DISALLOWED, 0)
        end
    end

    local u = self:union()
    if u then
        speaker.uname = u.alias
        speaker.union_rank = self:get_rank()
    end

    LOG( "[CHAT], pid=%d, channel=%d, %s", self.pid, channel, word )

    --if officer == KING then 
    --    word = string.format( "<color=#ffb804ff>%s</color>", word )
    --end
    --
    --
    local is_in_async_list = function(channel)
        local list = config.AsynChatList or {}
        if list[channel] == 1 then
            return true
        end
        return false
    end

    if is_in_async_list(channel) then
        local tool_sn = async_chat(self, channel, word)
        local tab = 
        {
            ply = self,
            channel = channel,
            speaker = speaker,
            word = word,
        }
        gPendingChat[tool_sn] = tab
        return
    end

    do_chat( self, channel, speaker, word) 
end

function do_chat( ply, channel, speaker, word)
    if channel == resmng.ChatChanelEnum.World then
        add_chat({pid=-1,gid=_G.GateSid}, channel, 0, speaker, word, 0, {} )

    elseif channel == resmng.ChatChanelEnum.Union then
        local u = ply:union()
        if not u then return end
        local pids = {}
        local _members = u:get_members()
        for pid, v in pairs(_members or {}) do
            if v:is_online() then
                table.insert(pids, pid)
            end
        end
        add_chat(pids, channel, u.uid, speaker,  word, 0, {} )

    elseif channel == resmng.ChatChanelEnum.Culture then
        --local pids = {}
        --local culture = self.culture
        --for pid, v in pairs(gPlys) do
        --    if v.culture == culture and v:is_online() then
        --        table.insert(pids, pid)
        --    end
        --end
        --player_t.add_chat(pids, channel, culture, speaker, word, 0, {})

    elseif channel == resmng.ChatChanelEnum.Notice then
        if not ply:dec_item_by_item_id( resmng.ITEM_NOTICE, 1, VALUE_CHANGE_REASON.USE_ITEM ) then 
            if not ply:dec_gold( 500, VALUE_CHANGE_REASON.CHAT_NOTICE ) then
                return 
            end
        end
        player_t.add_chat({pid=-1,gid=_G.GateSid}, channel, 0, speaker, word, 0, {} )

    end

    reply_ok(ply, "chat", sn)

    --to_37_chat_center(ply, channel, word)
end


function reset_genius( self, mode )
    if self.lv >= 20 then
        if self:get_item_num( resmng.ITEM_TALENT_RESET ) > 0 then
            self:dec_item_by_item_id( resmng.ITEM_TALENT_RESET, 1, VALUE_CHANGE_REASON.GENIUS_RESET )
        elseif self.gold >= resmng.GENIUS_RESET_COST then
            self:dec_gold( resmng.GENIUS_RESET_COST, VALUE_CHANGE_REASON.GENIUS_RESET )
        else
            ack( self, "reset_genius", resmng.E_NO_RMB )
            return
        end

        self.talent = self.lv - 10
        for k, v in pairs( self.genius ) do
            local conf = resmng.get_conf( "prop_genius",  v )
            if conf then
                if conf.Effect then
                    self:ef_rem( conf.Effect )
                end
            end
        end
        self.genius = {}
    end
end


function do_genius( self, id1, id2 )
    if (self.talent or 0) < 1 then return end
    INFO( "do_genius, %d -> %d", id1, id2 )

    local conf1
    local conf2 = resmng.get_conf( "prop_genius", id2 )
    if not conf2 then return end

    local tab = self.genius
    if id1 == 0 then
        local class_mode = math.floor( conf2.ID / 1000 ) 
        for k, v in pairs( tab ) do
            if math.floor( v / 1000 ) == class_mode then return end
        end
        if self.talent < conf2.Lv then return end
        if not self:condCheck( conf2.Cond ) then return end

    else
        conf1 = resmng.get_conf( "prop_genius", id1 )
        if not conf1 then return end

        if conf1.Class ~= conf2.Class then return end
        if conf1.Mode ~= conf2.Mode then return end
        if conf1.Lv >= conf2.Lv then return end

        if self.talent < conf2.Lv - conf1.Lv then return end
        if not self:condCheck( conf2.Cond ) then return end

        if not setRem( tab, id1 ) then return end
        self:ef_rem( conf1.Effect )

        local cds = self.cds
        if conf2.Skill then
            local skill = resmng.get_conf( "prop_skill", conf2.Skill )
            if skill then
                local cd = skill.Cd
                for _, v in pairs( cds or {} ) do
                    if v[1] == "genius" then
                        local one  = resmng.get_conf( "prop_genius", v[2] )
                        if one then
                            if one.Class == conf2.Class and one.Mode == conf2.Mode then
                                v[2] = id
                                local remain = v[4] - gTime
                                if cd < remain then
                                    v[4] = gTime + cd
                                end
                                self.cds = cds
                            end
                        end
                    end
                end
            end
        end
    end

    self:ef_add( conf2.Effect )
    setIns( tab, id2 )
    self.genius = tab
    INFO( "do_genius, ok, %d -> %d", id1, id2 )

    if not conf1 then 
        self.talent = self.talent - conf2.Lv
    else
        self.talent = self.talent - ( conf2.Lv - conf1.Lv )
    end
end


--function do_genius(self, id)
--    if (self.talent or 0) < 1 then return end
--    INFO( "do_genius, id=%d", id )
--
--    local conf = resmng.get_conf("prop_genius", id)
--    if not conf then
--        ERROR("do_genius: get prop_genius config failed. pid = %d, genius_id = %d.", self.pid, id)
--        return
--    end
--
--    if not self:condCheck(conf.Cond) then return end
--
--    local tab = self.genius or {}
--    local old_id = 0
--    if conf.Lv > 1 then
--        old_id = id - 1
--        local old_conf = resmng.get_conf("prop_genius", old_id)
--        if not old_conf then
--            ERROR("do_genius: get prop_genius config failed. pid = %d, old_genius_id = %d.", self.pid, old_id)
--            return
--        else
--            if setRem( tab, old_id ) then self:ef_chg( old_conf.Effect, conf.Effect )
--            else return end
--        end
--    else
--        if is_in_table( tab, id ) then return end
--        self:ef_add(conf.Effect)
--    end
--
--    local cds = self.cds
--    if conf.Skill then
--        local skill = resmng.get_conf( "prop_skill", conf.Skill )
--        if skill then
--            local cd = skill.Cd
--            for _, v in pairs( cds or {} ) do
--                if v[1] == "genius" then
--                    local one  = resmng.get_conf( "prop_genius", v[2] )
--                    if one then
--                        if one.Class == conf.Class and one.Mode == conf.Mode then
--                            v[2] = id
--                            local remain = v[4] - gTime
--                            if cd < remain then
--                                v[4] = gTime + cd
--                            end
--                            self.cds = cds
--                        end
--                    end
--                end
--            end
--        end
--    end
--
--    setIns( tab, id )
--    for k, v in pairs( tab ) do
--        INFO( "do_genius, remain, id=%d", v )
--    end
--    self.genius = tab
--    self.talent = self.talent-1
--end
--

function notify(self, chg)
    Rpc:statePro(self, chg)
    --dumpTab( chg, "statePro", 100, true )
    --INFO( "Rpc, statePro, notify" )
end

function query_fight_info(self, fid)
    local node = fight.gFightReports[ fid ]
    if node then
        Rpc:fightInfo(self, node[2])
    else
        reply_ok(self, "query_fight_info", 0, E_NO_REPORT)
    end
end

function request_fight_replay(self, replay_id)
    local db = self:getDb()
    local info = db.replay:find({_id = replay_id})
    if info and info:hasNext() then
        local m = info:next()
        Rpc:fightInfo(self, m[2])
    else
        Rpc:response_fight_replay(self, 1)
    end
end


function move_to_map( self, map, x, y )
    local data = {}
    data.pro = self._pro
    data.build = self._build
    data.item = self._item

    local troop = self:get_my_troop()
    data.arm = troop.arms[ self.pid ].live_soldier or {}

end

function get_pos_by_range_lv( a, b )
    local min = math.min(a, b)
    local max = math.max(a, b)
    local lv = 1
    if max > min then
        local total = 0
        for idx = min, max, 1 do
            total = total + RANGE_LV[ idx ]
        end

        local rate = math.random( 1, total )
        local total = 0
        for idx = min, max, 1 do
            total = total + RANGE_LV[ idx ]
            if rate <= total then
                lv = idx
                break
            end
        end
    else
        lv = min
    end
    for i = 1, 16, 1 do
        local x, y = c_get_pos_by_lv(lv, 4, 4 )
        if x then return x, y end
    end
end

function migrate_random( self )
    local itemid = resmng.ITEM_RANDOMMOVE
    --if self:get_item_num( itemid ) < 1 then return self:add_debug( "no item ITEM_RANDOMMOVE" ) end
    if self:get_item_num( itemid ) < 1 then return INFO( "[migrate random]no item ITEM_RANDOMMOVE" ) end
    for _, tid in pairs( self.busy_troop_ids or {} ) do
        local troop = troop_mng.get_troop( tid )
        if troop then
            if troop.owner_eid ~= self.eid then return end
            if troop.action ~= TroopAction.DefultFollow then return end
        end
    end

    local lv_castle = self:get_castle_lv()
    local x, y
    if lv_castle < 6 then
        x, y = get_pos_by_range_lv( 1, 1 )
    elseif lv_castle < 10 then
        x, y = get_pos_by_range_lv( 1, 2 )
    elseif lv_castle < 12 then
        x, y = get_pos_by_range_lv( 1, 3 )
    elseif lv_castle < 15 then
        x, y = get_pos_by_range_lv( 1, 4 )
    else
        x, y = get_pos_by_range_lv( 1, 5 )
    end
    if x then
        if self:do_migrate( x, y ) == "ok" then
            self:dec_item_by_item_id( itemid, 1, VALUE_CHANGE_REASON.USE_ITEM)
        end
    end
end

function migrate_zone( self, itemid )
    if self:get_item_num( itemid ) < 1 then return self:add_debug( "no item" ) end
    local x, y
    if itemid == resmng.ITEM_ZONEMOVE1 then
        x, y = get_pos_by_range_lv( 1, 1 )
    elseif itemid == resmng.ITEM_ZONEMOVE2 then
        x, y = get_pos_by_range_lv( 2, 2 )
    elseif itemid == resmng.ITEM_ZONEMOVE3 then
        x, y = get_pos_by_range_lv( 3, 3 )
    elseif itemid == resmng.ITEM_ZONEMOVE4 then
        x, y = get_pos_by_range_lv( 4, 4 )
    elseif itemid == resmng.ITEM_ZONEMOVE5 then
        x, y = get_pos_by_range_lv( 5, 5 )
    end

    if x then
        if self:do_migrate( x, y ) == "ok" then
            self:dec_item_by_item_id( itemid, 1, VALUE_CHANGE_REASON.USE_ITEM)
        end
    end
end

function migrate( self, x, y )
    local tab = {
        [1] = resmng.ITEM_ZONEMOVE1,
        [2] = resmng.ITEM_ZONEMOVE2,
        [3] = resmng.ITEM_ZONEMOVE3,
        [4] = resmng.ITEM_ZONEMOVE4,
        [5] = resmng.ITEM_ZONEMOVE5,
        [6] = resmng.ITEM_ADVANCEDMOVE,
        [7] = resmng.ITEM_WARBANDMOVE
    }
    --判断是否在奇迹范围
    local itemid=nil
    if check_ply_cross(self) then
        itemid = CROSS_MIGRATE_ITEM
        if self:get_item_num(itemid) < 1 then
            itemid = nil
        end
    else
        local prop_castle = resmng.get_conf("prop_world_unit", self.propid)
        if prop_castle == nil then
            ERROR("migrate find player castle error! propid=%d", self.propid)
        end
        local union = unionmng.get_union(self.uid)
        if prop_castle ~= nil and union ~= nil and union:is_in_miracal_range(x, y, prop_castle.Size/2) == true then
            if self:get_item_num( resmng.ITEM_WARBANDMOVE ) >= 1 then
                itemid = resmng.ITEM_WARBANDMOVE
            end
        end
        if itemid == nil then
            local lv = get_pos_lv( x, y )
            itemid = tab[ lv ]
            if self:get_item_num( itemid ) < 1 then
                itemid = resmng.ITEM_ADVANCEDMOVE
                if self:get_item_num( itemid ) < 1 then
                    itemid = nil
                end
            end
        end
    end
    if nil == itemid then
        if self.gold < 2000 then return end
    end

    if self:do_migrate( x, y ) == "ok" then
        if itemid then
            self:dec_item_by_item_id( itemid, 1, VALUE_CHANGE_REASON.MIGRATE )
            task_logic_t.process_task(self, TASK_ACTION.USE_ITEM, itemid, 1)
        else
            self:dec_gold( 2000, VALUE_CHANGE_REASON.MIGRATE )
            task_logic_t.process_task(self, TASK_ACTION.USE_ITEM, resmng.ITEM_ADVANCEDMOVE, 1)
        end
        local u = unionmng.get_union(self.uid)
        if u then
            u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, self:get_union_info())
        end
        reply_ok( self, "migrate", 0)
    end
end

function do_migrate(self, x, y)
    if x < 0 or y < 0 then return false end
    if x + 3 >= 1280 then return false end
    if y + 3 >= 1280 then return false end

    if x == self.x and y == self.y then 
        self:add_debug( "same pos" )
        return false 
    end

    if #self.busy_troop_ids > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end

    if not self:can_move_to(x, y)  then return self:add_debug("can not move by castle lv") end

    local sx = self.x
    local sy = self.y

    local comings = self.troop_comings
    if comings then
        for tid, action in pairs( comings ) do
            local troop = troop_mng.get_troop( tid )
            if troop and troop:is_go() then
                local action = troop:get_base_action()
                if action == TroopAction.SiegePlayer or action == TroopAction.MonsterAtkPly or action == TroopAction.Spy then
                    c_troop_set_speed( troop.eid, 2000, 1 )
                    WARN( "troop_arrive, eid=%d", troop.eid )
                    triggers_t.arrived_target( troop.dx, troop.dy, troop.eid )
                    WARN( "troop_arrive, after eid=%d", troop.eid )
                end
            end
        end
    end

    local home = self:get_my_troop()
    if home then
        home.dx = x
        home.dy = y
        home.sx = x
        home.sy = y
        local info = false
        for k, v in pairs( home.arms or {} ) do
            if k ~= self.pid then
                local dp = getPlayer( k )
                if dp and dp:is_online() then
                    if not info then info = home:get_info() end
                    Rpc:stateTroop( dp, info )
                end
            end
        end
    end

    if math.abs( x - sx ) >= 4 or math.abs( y - sy ) >= 4 then
        if c_map_test_pos_for_ply( x, y, 4 ) ~= 0 then
            Rpc:tips(self, 1, resmng.TIPS_OVERLAP, {})
            --self:add_debug( "overlap" )
            return
        end
    else
        local minx, maxx = sx, sx + 3
        local miny, maxy = sy, sy + 3
        for tx = x, x + 3, 1 do
            if tx >= 1280 then return false end
            for ty = y, y + 3, 1 do
                if ty >= 1280 then return false end
                if not (tx >= minx and tx <= maxx and ty >= miny and ty <= maxy) then
                    if c_map_test_pos_for_ply( tx, ty, 1 ) ~= 0 then
                        INFO( "[Migrate], overlap, pid=%d, (%d,%d)->(%d,%d)", self.pid, self.x, self.y, x, y )
                        return
                    end
                end
            end
        end
    end

    --c_rem_ety(self.eid)
    self.x = x
    self.y = y
    etypipe.add(self)

    self:add_count( resmng.ACH_COUNT_MIGRATE, 1 )
    reply_ok(self, "migrate", y*65536+x)
    union_build_t.ply_move(self)

    if self:is_wall_fire() then self:wall_fire( 0 ) end

    --任务
    local zone_lv = get_pos_lv(x, y)
    task_logic_t.process_task(self, TASK_ACTION.MOVE_TO_ZONE, zone_lv)

    if zone_lv == 6 then self:rem_shell() end

    return "ok"
end

function get_active(self)
    return self.active
end

function add_exp(self, value)
    if value <= 0 then return end

    local limit_level = #resmng.prop_level
    local add_exp = value
    local old_level = self.lv
    while(true) do
        if self.lv >= limit_level then
            break
        end
        local limit_exp = resmng.prop_level[self.lv + 1].Exp
        local need_exp = limit_exp - self.exp
        if add_exp >= need_exp then
            self.lv = self.lv + 1
            self.exp = 0
            add_exp = add_exp - need_exp

            if self.lv == 20 then
                self.talent = 10
            elseif self.lv > 20 then
                self.talent = self.talent + 1
            end
        else
            self.exp = self.exp + add_exp
            break
        end
    end
    INFO( "add_exp, pid=%d, add=%d, sum=%d, lv=%d, oldlv=%d", self.pid, math.floor( value ), math.floor(self.exp), self.lv, old_level )

    if self.lv > old_level then
        INFO( "add_exp, pid=%d, value=%d, lv,%d,%d", self.pid, math.floor( value ), old_level, self.lv )
        self.tm_lv = gTime
        rank_mng.add_data(2, self.pid, {self.lv, self.tm_lv} )
        --升级触发全部写到这个函数
        self:on_level_up( old_level, self.lv )
    end
    --self:try_add_tit_point(resmng.ACH_LEVEL_PLAYER)

end

function on_level_up(self, old_level, new_level)
    local diff = new_level - old_level
    self:inc_pow( resmng.prop_level[ new_level ].Pow - resmng.prop_level[ old_level ].Pow )

    for i = old_level + 1, new_level, 1 do
        local prop = resmng.prop_level[i]
        if prop then
            for k, v in pairs(prop.Bonus or {}) do
                local its = player_t.bonus_func[ v[1] ]( prop, v[2])
                self:send_system_notice(resmng.MAIL_10045, {}, {i}, its)
            end
        end
    end

    update_global_player_info( self )

    --升级要触发事情
    --任务
    --task_logic_t.process_task(self, TASK_ACTION.ROLE_LEVEL_UP)

    local hs = self:get_hero()
    for _, h in pairs( hs ) do
        if h.lv == old_level then
            h:gain_exp( 0 )
        end
    end
end

function update_global_player_info( self )
    local info = { pid=self.pid, account=self.account, lv=self.lv, propid=self.propid, tm_create=self.tm_create, map=self.map, emap=self.emap, smap=self.smap, name=self.name, language=self.language, photo=self.photo, account=self.account}
    if self.uid > 0 then
        local u  = unionmng.get_union(self.uid)
        if u then
            info.uid = self.uid
            info.uname = u.name
            info.ualias = u.alias
            info.uflag = u.flag 
            update_global( "players", self.pid, info )
            return
        end
    end

    info.uid = 0
    info.uname = ""
    info.ualias = ""
    info.uflag = 0
    update_global( "players", self.pid, info )
end

function on_day_pass(self)
    self.cross_time = gTime
    self:on_day_pass_online_award()
    --self:on_day_pass_month_award()
    self:on_day_pass_daily_task()
    self:refresh_black_marcket()
    self:refresh_res_market()
    self:gacha_on_day_pass()
    self:vip_signin()
    self:add_count( resmng.ACH_COUNT_SIGNIN, 1 )
    self.siege_dig = 0
    --self.count_dig = 0
    self:operate_on_day_pass()
    self.tributes = {0,0,0,0}
    if self.fb_login ~= -2 then
        self.fb_login = 0
    end
end

function is_sys_name( name )
    local len = string.len( name )
    local pat = string.match( name, "K%d+a%d+" )
    if pat and string.len( pat ) == len then return true end
end


function change_name(p, name)
    local old = p.name

    --if not is_valid_name(name) then
    --    ack(p, "change_name", resmng.E_DISALLOWED )
    --    INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", 1, p.pid, old, name )
    --    return
    --end

    --if not is_inputlen_avaliable( name, CHA_LIMIT.Lord_Name ) then 
    --    ack(p, "change_name", resmng.E_DISALLOWED )
    --    INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", 2, p.pid, old, name )
    --    return 
    --end

    ----包含屏蔽字
    --if is_include_filter_server(name) == true then
    --    ack(p, "change_name", resmng.E_DISALLOWED )
    --    INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", 3, p.pid, old, name )
    --    return
    --end


    local c = (resmng.prop_language_cfg[p.language] or {}).Limit
    local flag, code = check_name_avalible( name,c )
    if flag ~= true then
        ack(p, "change_name", resmng.E_DISALLOWED )
        INFO("[ChangeName], code=%s, pid=%d, old=%s, new=%s", code, p.pid, old, name )
    end

    if is_sys_name( name ) then 
        ack(p, "change_name", resmng.E_DISALLOWED )
        INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", 4, p.pid, old, name )
        return
    end

    for k, v in pairs(gPlys) do
        if v.name == name then
            ack(p, "change_name", resmng.E_DUP_NAME)
            INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", 5, p.pid, old, name )
            return
        end
    end

    local old = p.name
    local code = want_insert_unique_name( "name_ply", name, { pid=p.pid, account=p.account, map=gMapID, time=gTime, action="change"} )
    if code ~= 0 then
        ack(p, "change_name", resmng.E_DUP_NAME)
        INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", code, p.pid, old, name )
        return
    end
 
    local db = dbmng:getGlobal()
    if db then db.name_ply:delete( {_id=old} ) end

    if not p:dec_item_by_item_id( resmng.ITEM_CHANGE_NAME, 1, VALUE_CHANGE_REASON.CHANGE_NAME ) then
        local price = get_item_price( resmng.ITEM_CHANGE_NAME )
        if p.gold < price then return end
        p:dec_gold( price, VALUE_CHANGE_REASON.CHANGE_NAME )
    end

    p.name = name
    etypipe.add(p)
    rank_mng.update_info_player( p.pid )

    update_global_player_info( p )

    INFO("[ChangeName], code=%d, pid=%d, old=%s, new=%s", 0, p.pid, old, name )

    for _, tid in pairs( p.busy_troop_ids or {} ) do
        local troop = troop_mng.get_troop( tid )
        if troop and troop.owner_pid == p.pid and troop.action == TroopAction.Camp + 200 then
            local camp = get_ety( troop.target_eid )
            if camp and is_camp( camp ) then
                camp.name = name
                etypipe.add( camp )
                gPendingSave.unit[ camp.eid ].uid = uid
            end
        end
    end

    --task_logic_t.process_task(p, TASK_ACTION.LORD_RENAME, 1)
    --rank_mng.change_name( 1, p.pid, name )
    --rank_mng.change_name( 2, p.pid, name )
    --rank_mng.change_name( 3, p.pid, name )
    --rank_mng.change_name( 4, p.pid, name )

    local u  = unionmng.get_union(p.uid)
    if u then
        u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=p.pid,uid=p.uid,name=p.name})
        u.donate_rank={}
    end
end

init()

function reply_ok(self, funcname, d1)
    ack(self, funcname, resmng.E_OK, d1 or 0)
end


--------------------------------------------------------------------------------
-- Function : 计算消除CD所需的金币
-- Argument : self, cd
-- Return   : number
-- Others   : NULL
--------------------------------------------------------------------------------
function calc_cd_golds(self, cd)
    -- TODO: 策划规则未定
    return cd
end

function do_load_equip(self)
    local db = self:getDb()
    local info = db.equip:find({pid=self.pid})
    local bs = {}
    while info:hasNext() do
        local b = info:next()
        bs[ b._id ] = b
    end
    return bs
end

function get_equip(self, id)
    if not self._equip then self._equip = self:do_load_equip() end
    if id then
        return self._equip[ id ]
    else
        return self._equip
    end
end

function equip_add(self, propid, why)
    local id = getId("equip")
    local t = {_id = id, propid=propid, pid=self.pid, pos=0}
    gPendingSave.equip[ id ] = t
    self:get_equip()
    self._equip[ id ] = t
    Rpc:equip_add(self, t)
    --任务
    task_logic_t.process_task(self, TASK_ACTION.MAKE_EQUIP, propid, 1)
    --task_logic_t.process_task(self, TASK_ACTION.GET_EQUIP, propid, 1)


    local conf = resmng.get_conf( "prop_equip", propid )
    if conf then
        local quality = conf.Class
        for q = 1, quality, 1 do
            local key = string.format( "ACH_EQUIP_QUALITY_%d", q )
            self:add_count( resmng[ key ], 1 )
        end
    end
    INFO("equip_add: pid = %d, item_id = %d, reason = %d.", self.pid, propid, why)
end

function equip_rem(self, id, why)
    self:get_equip()
    local node = self._equip[ id ]

    self._equip[ id ] = nil
    gPendingSave.equip[ id ].pos = -1
    Rpc:equip_rem(self, id)

    local conf = resmng.get_conf( "prop_equip", node.propid )
    if conf then
        local quality = conf.Class
        for q = 1, quality, 1 do
            local key = string.format( "ACH_EQUIP_QUALITY_%d", q )
            self:add_count( resmng[ key ], -1 )
        end
    end
    INFO("equip_add: pid = %d, item_sn = %d, reason = %d.", self.pid, id, why)
end


function equip_on(self, id)
    local n = self:get_equip(id)
    if not n then return end
    if n.pos > 0 then return end
    local prop = resmng.get_conf("prop_equip", n.propid)
    if not prop then return end

    if prop.Lv > self.lv then
        ack(self, "equip_on", resmng.E_LV)
        return
    end

    local idx = prop.Pos

    local ns = self:get_equip()
    for _, v in pairs(ns) do
        if v.pos == idx then return end
    end

    self:inc_pow(prop.Pow)
    self:ef_add(prop.Effect)
    n.pos = idx

    gPendingSave.equip[ id ].pos = idx
    reply_ok(self, "equip_on", id)
end


function equip_off(self, id)
    local n = self:get_equip(id)
    if not n then return end
    if n.pos == 0 then return end
    n.pos = 0
    gPendingSave.equip[ id ].pos = 0

    local conf = resmng.get_conf("prop_equip", n.propid)
    if conf then
        self:ef_rem(conf.Effect)
        if conf.Pow then self:dec_pow(conf.Pow) end
    end
    reply_ok(self, "equip_off", id)
end

function require_online_award_time(self)
    local is_end = self:is_online_award_end()
    if is_end == true then
        Rpc:get_online_award_time_resp(self, 1, 0)
        return
    end
    local timestamp = self:get_online_award_next_time()
    Rpc:get_online_award_time_resp(self, 0, timestamp)
end

function require_online_award(self)
   self:get_online_award()
   local timestamp = self:get_online_award_next_time()
   if timestamp == -1 then
       Rpc:get_online_award_time_resp(self, 1, 0)
   else
       Rpc:get_online_award_time_resp(self, 0, timestamp)
   end
end


--lost temple
function get_lt_award(self, idx)
    local lv = self:get_castle_lv() or 0
    local prop = resmng.prop_lt_reward[lv]
    if prop and not self.lt_award_st[idx] then
        local cond = prop.Cond[idx] or 0
        local score = rank_mng.get_score(10, self.pid) or 0
        if cond <= score then
            local award = prop.Award[idx]
            if award then
                self:add_bonus("mutex_award", award, VALUE_CHANGE_REASON.REASON_LT)
                local lt_award_st = self.lt_award_st
                lt_award_st[idx] = idx
                self.lt_award_st = lt_award_st
            end
        end
    end
    self:lt_info_req()
end

function lt_map_info_req(self)
    local lts = get_lt_map_info()
    if lts then
        Rpc:lt_map_info_ack(self, lts)
    end
end

function get_lt_map_info()
    if lost_temple.map_lts then
        return lost_temple.map_lts
    end

    local lts = {}
    for k, v in pairs(lost_temple.seq_citys[3] or {}) do
        local lt = get_ety(v)
        if not lt then
            table.remove(lost_temple.seq_citys[3], k)
        else
            table.insert(lts, {lt.eid, lt.propid, lt.x, lt.y})
        end
    end
    for k, v in pairs(lost_temple.seq_citys[2] or {}) do
        local lt = get_ety(v)
        if not lt then
            table.remove(lost_temple.seq_citys[2], k)
        else
            table.insert(lts, {lt.eid, lt.propid, lt.x, lt.y})
        end
    end
    lost_temple.map_lts = lts
    return lts
end

function lt_info_req(self)
    if self.lt_time < lost_temple.start_time then
        self.lt_time = gTime
        self.lt_award_st = {}
    end
    local pack = {}
    pack.state = lost_temple.actState
    pack.end_time = lost_temple.end_time
    local id = lost_temple.actState
    local prop = resmng.prop_lt_stage[id]
    if prop then
        if pack.end_time  < gTime then
            pack.end_time = lost_temple.end_time + prop.Spantime
        else
            pack.end_time = lost_temple.start_time + prop.Spantime 
        end
    end
    pack.lt_award_st = self.lt_award_st
    local pointType = POINT_MALL_TYPE[POINT_MALL.RELIC]
    pack.point = rank_mng.get_score(10, self.pid) or 0
    pack.credit = self[pointType]
    pack.upoint = rank_mng.get_score(9, self.uid) or 0
    local time = timer.get(lost_temple.actTimer)
    pack.state = lost_temple.actState
    if time then
      --  pack.end_time = time.over
    end
    local citys = {}
    for k, v in pairs(self.lt_citys or {}) do --我拥有的
        local lt = get_ety(v)
        if not lt then
            self.lt_citys[k] = nil
        else
            local city = format_lt_city(lt)
            if city then table.insert(citys, city) end
        end
    end

    for k, v in pairs(lost_temple.seq_citys[3] or {}) do

        local lt = get_ety(v)
        if not lt then
            table.remove(lost_temple.seq_citys[3], k)
        else
            local lt_citys = self.lt_citys or {}
            if not lt_citys[lt.eid] then
                local city = format_lt_city(lt)
                if city then
                    table.insert(citys, city)
                end
            end
        end
    end

    for k, v in pairs(lost_temple.seq_citys[2] or {}) do
        local lt = get_ety(v)
        if not lt then
            table.remove(lost_temple.seq_citys[2], k)
        else
            local lt_citys = self.lt_citys or {}
            if not lt_citys[lt.eid] then
                local city = format_lt_city(lt)
                if city then table.insert(citys, city) end
            end
        end
    end
    pack.citys = citys
    Rpc:lt_info_ack(self, pack)

end

function lt_citys_info_req(self, index)
    local pack = pack
    local citys = {}
    for i = index , index + 10 do
        local eid = lost_temple.seq_citys[1][i]
        if eid then
            local lt = get_ety(eid)
            if lt then
                local city = format_lt_city(lt)
                if city then table.insert(citys, city) end
            end
        else
            table.remove(lost_temple.seq_citys[1], i)
        end
    end
    pack.citys = citys
    Rpc:lt_citys_info_ack(self, pack)
end

function format_lt_city(lt)
    local city = {}
    if lt then
        local def_tr = troop_mng.get_troop(lt.my_troop_id)
        local def_num = 0
        if def_tr then
            def_num = def_tr:get_troop_total_soldier()
        end
        local ply = get_ply_by_troop(lt.my_troop_id)
        if ply then
            local owner = get_ply_base_info(ply)
            if owner then
                owner.def_num = def_num
                city.owner = owner
            end
        end
        ply = {}
        local tr =  monster_city.get_fast_troop(lt, ETY_TROOP.ATK)
        if tr then
            ply = get_ply_by_troop(tr._id)
            if ply then
                local atker = get_ply_base_info(ply)
                if atker then
                    city.atker = atker
                    city.atker.tmOver = tr.tmOver
                end
            end
        end
       city.state = lt.state
       city.startTime = lt.startTime
       city.endTime = lt.endTime
       city.x = lt.x
       city.y = lt.y
       if def_tr then
           city.def_arms = def_tr.arms
       end
       city.propid = lt.propid
    end
    if city ~= {} then return city end
end

function get_ply_base_info(ply)
    local info = {}
    if ply then
        info.name = ply.name
        info.photo = ply.photo
        local union  = unionmng.get_union(ply.uid)
        if union then
            info.alias = union.alias
        end
    end
    return info
end

function get_ply_by_troop(troopId)
    local tr = troop_mng.get_troop(troopId)
    if tr then
        local ply = get_ety(tr.owner_eid)
        if ply and is_ply(ply) then
            return ply
        end
    end
end
---act info
function act_info_tag_req(self, act_type)
    local tag = 0
    if act_type == ACT_TYPE.NPC then
        tag = npc_city.act_tag
    elseif act_type == ACT_TYPE.MC then
        local union = unionmng.get_union(self.uid)
        if union then
            tag = union.act_mc_tag
        end
    elseif act_type == ACT_TYPE.KING then
        tag = king_city.act_tag
    elseif act_type == ACT_TYPE.LT then
        tag = lost_temple.act_tag
    end

    tag = tag or 0

    Rpc:act_info_tag_ack(self, tag)

end

----npc city
--
function npc_info_by_propid_req(self, propid)
    local eid = npc_city.get_npc_eid_by_propid(propid)
    if not eid then
        return
    end

    local npc = get_ety(eid)
    if not npc then
        return
    end

    local city = {}
    local num, max , pow = npc:hold_limit(self)
    local def_union = unionmng.get_union(npc.uid)
    npc_city.format_union(npc)
    city.unions = npc.unions
    city.armsNum = num
    city.armsPow = pow
    city.propid = npc.propid
    city.state = npc.state
    city.startTime = npc.startTime
    city.endTime = npc.endTime
    city.kw_buff = npc.kw_buff
    local uinfo = {}
    if def_union then
        uinfo.pow = def_union:union_pow()
        uinfo.membercount = def_union.membercount
        uinfo.flag = def_union.flag
        city.uinfo = uinfo
    end

    Rpc:npc_info_by_propid_ack(self, city)
end

function union_npc_info_req(self)
    local union = unionmng.get_union(self.uid)
    if not union then
        return
    end
    local state, startTime, endTime = npc_city.get_npc_state()
    local pointType = POINT_MALL_TYPE[POINT_MALL.MANOR]
    local pack = {}
    if union.npc_info_pack then
        pack = union.npc_info_pack
    end
    pack.tw_credit = self[pointType] or 0
    pack.tw_state = state
    pack.tw_endTime = endTime
    pack.mc_startTime = union.mc_start_time or union:get_default_time()
    pack.mc_state = union.monster_city_stage
    local pointType1 = POINT_MALL_TYPE[POINT_MALL.MONSTER]
    pack.mc_credit = self[pointType1] or 0
    pack.abd_tm = union.abd_city_time
    pack.declare_time = union.declare_tm
    local can_atks = union:union_can_atk_citys()
    local can_atk_citys = {}
    for k, v in pairs(can_atks or {}) do
        local eid = npc_city.have[v] or 0
        local npc = get_ety(eid)
        local city = {}
        if npc and not union.declare_wars[eid] then
            local num, max , pow = npc:hold_limit(self)
            local def_union = unionmng.get_union(npc.uid)
            npc_city.format_union(npc)
            city.unions = npc.unions
            city.armsNum = num
            city.armsPow = pow
            city.propid = npc.propid
            city.state = npc.state
            city.startTime = npc.startTime
            city.endTime = npc.endTime
            city.kw_buff = npc.kw_buff
            local uinfo = {}
            if def_union then
                uinfo.pow = def_union:union_pow()
                uinfo.membercount = def_union.membercount
                uinfo.flag = def_union.flag
                city.uinfo = uinfo
            end
            table.insert(can_atk_citys, city)
        end
    end
    pack.can_atk_citys = can_atk_citys

    local declare_citys = {}
    for k, v in pairs(union.declare_wars or {}) do
        local npc = get_ety(v)
        local city = {}
        if npc then
            local num, max = npc:hold_limit(self)
            local def_union = unionmng.get_union(npc.uid)
            npc_city.format_union(npc)
            city.unions = npc.unions
            city.armsNum = num
            --city.armsNum = num
            city.propid = npc.propid
            city.state = npc.state
            city.startTime = npc.startTime
            city.endTime = npc.endTime
            city.kw_buff = npc.kw_buff
            local uinfo = {}
            if def_union then
                uinfo.pow = def_union:get_pow()
                uinfo.membercount = def_union.membercount
                uinfo.flag = def_union.flag
                city.uinfo = uinfo
            end
            table.insert(declare_citys, city)
        end
    end
    pack.declare_citys = declare_citys

    if union.npc_info_pack then
        Rpc:union_npc_info_ack(self, pack)
        return
    end

    pack.reward = 0
    local citys = {}
    for k, v in pairs(union.npc_citys or {}) do
        local npc = get_ety(v)
        local city = {}
        if npc then
            local num, max, pow= npc:hold_limit(self)
            local def_union = unionmng.get_union(npc.uid)
            npc_city.format_union(npc)
            city.unions = npc.unions
            city.armsNum = num
            city.armsPow = pow
            city.propid = npc.propid
            city.state = npc.state
            city.startTime = npc.startTime
            city.endTime = npc.endTime
            city.kw_buff = npc.kw_buff
            local mc = union_t.get_live_mc(v)
            if mc then
                city.is_mc_atk = true
            end
            local uinfo = {}
            if def_union then
                uinfo.pow = def_union:get_pow()
                uinfo.membercount = def_union.membercount
                uinfo.flag = def_union.flag
                city.uinfo = uinfo
            end
            table.insert(citys, city)
        end
    end
    pack.citys = citys
    union.npc_info_pack = pack
    Rpc:union_npc_info_ack(self, pack)
end

function get_npc_buff_req(self)
    local pack = {}
    for k, v in pairs(npc_city.citys) do
        local city = get_ety(k)
        if city then
            local conf = resmng.get_conf( "prop_world_unit", city.propid ) 
            if conf then
                if conf.Lv == 1 then
                    local union = unionmng.get_union(city.uid) or {}
                    local info = {propid = city.propid, uid = city.uid, uname = union.name, ualias = union.alias, uflag = union.flag, buf = city.kw_buff}
                    table.insert(pack, info)
                end
            end
        end
    end
    Rpc:get_npc_buff_ack(self, pack)
end

function npc_act_info_req(self)
    local pack = {}
    local union = unionmng.get_union(self.uid)
    local state, startTime, endTime = npc_city.get_npc_state()
    local pointType = POINT_MALL_TYPE[POINT_MALL.MANOR]
    pack.credit = self[pointType] or 0
    pack.state = state
    pack.endTime = endTime
    if union then
        local can_atks = union:union_can_atk_citys()
        local can_atk_citys = {}
        for k, v in pairs(can_atks or {}) do
            local eid = npc_city.have[v] or 0
            local npc = get_ety(eid)
            local city = {}
            if npc and not union.declare_wars[eid] then
                local num, max , pow = npc:hold_limit(self)
                local def_union = unionmng.get_union(npc.uid)
                npc_city.format_union(npc)
                city.unions = npc.unions
                city.hold_limit = max
                city.armsNum = num
                city.armsPow = pow
                city.propid = npc.propid
                city.state = npc.state
                city.startTime = npc.startTime
                city.endTime = npc.endTime
                city.kw_buff = npc.kw_buff
                local uinfo = {}
                if def_union then
                    uinfo.pow = def_union:union_pow()
                    uinfo.membercount = def_union.membercount
                    uinfo.flag = def_union.flag
                    city.uinfo = uinfo
                end
                table.insert(can_atk_citys, city)
            end
        end
        pack.can_atk_citys = can_atk_citys

        pack.reward = 0
        local citys = {}
        for k, v in pairs(union.npc_citys or {}) do
            local npc = get_ety(v)
            local city = {}
            if npc then
                local num, max, pow= npc:hold_limit(self)
                local def_union = unionmng.get_union(npc.uid)
                npc_city.format_union(npc)
                city.unions = npc.unions
                city.armsNum = num
                city.hold_limit = max
                city.armsPow = pow
                city.propid = npc.propid
                city.state = npc.state
                city.startTime = npc.startTime
                city.endTime = npc.endTime
                city.kw_buff = npc.kw_buff
                local uinfo = {}
                if def_union then
                    uinfo.pow = def_union:get_pow()
                    uinfo.membercount = def_union.membercount
                    uinfo.flag = def_union.flag
                    city.uinfo = uinfo
                end
                table.insert(citys, city)
            end
        end
        for k, v in pairs(union.declare_wars or {}) do
            local npc = get_ety(v)
            local city = {}
            if npc then
                local num, max = npc:hold_limit(self)
                local def_union = unionmng.get_union(npc.uid)
                npc_city.format_union(npc)
                city.unions = npc.unions
                city.armsNum = num
                city.hold_limit = max
                city.propid = npc.propid
                city.state = npc.state
                city.startTime = npc.startTime
                city.endTime = npc.endTime
                city.kw_buff = npc.kw_buff
                local uinfo = {}
                if def_union then
                    uinfo.pow = def_union:get_pow()
                    uinfo.membercount = def_union.membercount
                    uinfo.flag = def_union.flag
                    city.uinfo = uinfo
                end
                table.insert(citys, city)
            end
        end
        pack.citys = citys
        Rpc:npc_act_info_ack(self, pack)
    else
        Rpc:npc_act_info_ack(self, pack)
    end
end

function get_union_npc_req(self)
    local union = unionmng.get_union(self.uid)
    local npc_citys = {}
    if union then
        for k, v in pairs(union.npc_citys) do
            local city = get_ety(v)
            if city then
                table.insert(npc_citys, city.propid)
            end
        end
        local pack = {}
        pack.npc_citys = npc_citys
        Rpc:get_union_npc_ack(self, pack)
    end
end


function get_random_award_req(self, eid)
    npc_city.get_random_award(self.pid, eid)
end

function get_can_atk_citys_req(self)
    local pack = {}
    local union = unionmng.get_union(self.uid)
    if union then
        --union:union_can_atk_citys()
        --pack.can_atk_citys = union.can_atk_citys
        pack.can_atk_citys = union:union_can_atk_citys()
    end
    Rpc:get_can_atk_citys_ack(self, pack)
end

function acc_tower_recover_req(eid)
    local city = get_ety(eid)
    if city and  resmng.prop_world_unit[city.propid].Lv == CITY_TYPE.TOWER then

    end
end


function get_npc_map_req(self)

    subscribe_ntf.add_sub_group("map_info", self.pid)

    local pack = npc_city.map_pack or {}
    pack.def = 0
    pack.atk = 0
    if not npc_city.map_pack then
        local map = {}
        pack.s_id = gMapID
        local occupys = npc_city.monster_occupys
        for k, v in pairs(npc_city.citys) do
            local city = get_ety(k)
            if city then
                npc_city.format_union(city)

                --local name = union.name or ""
                --local union = unionmng.get_union(city.uid) or {}

                local name = ""
                local info = {city.eid, city.uid, "", city.propid, city.unions, city.state, city.startTime, city.endTime, city.unions, city.royal}

                local union = unionmng.get_union(city.uid)
                if union then
                    info[3] = union.name 
                else
                    if city.last_uid == 0 then
                        local conf = resmng.get_conf( "prop_world_unit", city.propid )
                        local flag = conf and conf.Flag
                        --{"AT","ATLANTIS",6,5}
                        if flag and flag[4] ~= 0 then
                            info[2] = flag[4]
                            info[3] = flag[2]
                            local uinfo = { flag[4], flag[2], flag[3], flag[1] }
                            -- id, name, flag, alise
                            info[5][1] = uinfo
                        end
                    end
                end

                if occupys then
                    local t = occupys[ city.propid ]
                    if t and city.uid == 0 then
                        local conf = resmng.get_conf( "prop_default_union", t )
                        if conf then
                            info[2] = conf.ID
                            info[3] = conf.Fullname
                            local uinfo = { conf.ID, conf.Fullname,  conf.Flag, conf.Shortname }
                            info[5][1] = uinfo
                        end
                    end
                end

                table.insert( map, info )
            end
        end
        local king_city = king_city.get_king()
        if king_city then
            local union = unionmng.get_union(king_city.uid) or {}
            local name = union.name or ""
            table.insert(map, {king_city.eid, king_city.uid, name, king_city.propid, {{union.uid, union.name, union.flag, union.alias}}, king_city.state, king_city.startTime, king_city.endTime, king_city.royal})
        end
        pack.map = map
        npc_city.map_pack = pack
    end
    local union = unionmng.get_union(self.uid)
    if union then
        pack.atk = union.atk_id
        pack.def = union.def_id
    end
    Rpc:get_npc_map_ack(self, pack)
    player_t.get_do_mc_npc_req( self )
    player_t.lt_map_info_req( self )
end

function get_city_for_robot_req(self, mode, cond)
    local lv = cond.lv
    if mode == ACT_NAME.NPC_CITY then
        lv = lv or 4
        local npc_id = cond.npc_id
        for k, eid in pairs(npc_city.citys) do
            local city = get_ety(eid)
            if not npc_id  then
                if city.lv == lv then
                    Rpc:get_city_for_robot_ack(self, mode, eid)
                    break
                end
            else
                if npc_id == city.propid then
                    Rpc:get_city_for_robot_ack(self, mode, eid)
                    break
                end
            end
        end
    end

    if  mode == ACT_NAME.LOST_TEMPLE then
        lv = lv or 1
        for k, eid in pairs(lost_temple.citys) do
            local city = get_ety(eid)
            local prop = resmng.prop_world_unit[city.propid]
            if prop.Mode == lv then
                Rpc:get_city_for_robot_ack(self, mode, eid)
                break
            end
        end
    end

    if  mode == ACT_NAME.KING then
        lv = lv or 1
        for k, eid in pairs(king_city.citys) do
            local city = get_ety(eid)
            local prop = resmng.prop_world_unit[city.propid]
            if prop.Lv == lv then
                Rpc:get_city_for_robot_ack(self, mode, eid)
                break
            end
        end
    end
end

function tag_npc_req(self, act, eid)
    if not can_ply_opt_act[ACT_TYPE.NPC](self) then
        --self:add_debug("no union right to do it")
        return
    end
    local union = self:union()
    if union then
        if act == 1 then
            if union.def_id == eid then
                union.def_id = 0
            end
            union.atk_id = eid
           -- union.def_id = 0
        elseif act == 2 then
            if union.atk_id == eid then
                union.atk_id = 0
            end
           -- union.atk_id = 0
            union.def_id = eid
        end
    end
    local pack = {}
    pack.atk = union.atk_id
    pack.def = union.def_id
    Rpc:tag_npc_ack(self, pack)
end

function untag_npc_req(self, eid)
    if not can_ply_opt_act[ACT_TYPE.NPC](self) then
        --self:add_debug("no union right to do it")
        return
    end
    local pack = {}
    local union = self:union()
    if union then
        if union.atk_id == eid then
            union.atk_id = 0
        elseif union.def_id == eid  then
            union.def_id = 0
        end
    end
    pack.atk = union.atk_id
    pack.def = union.def_id
    Rpc:tag_npc_ack(self, pack)
end



function get_union_npc_rank_req(self)
    local rank = npc_city.union_rank or {}
    --local version, tops = rank_mng.load_rank( 13 )
    --for k, v in pairs( tops ) do
    --    local id = v[2][1]
    --    local score = v[1]
    --    local name = v[ 2 ][2]
    --    table.insert( rank, { id, name, score } )
    --end
    --
    if not npc_city.union_rank then
        local points = {}
        local prop_world_unit = resmng.prop_world_unit
        local occupys = npc_city.monster_occupys
        for k, v in pairs( npc_city.citys ) do
            local city = get_ety( k )
            if city then
                local uid = city.uid
                local conf = prop_world_unit[ city.propid ]
                points[uid] = points[uid] or {}
                if (not uid) or (uid == 0) then
                    if occupys and occupys[ city.propid ] then
                        local uid = occupys[ city.propid ]
                        points[uid] = points[uid] or {}
                        points[ uid ] = { ( points[ uid ][1] or 0 ) + conf.Boss_point, (points[uid][2] or 0 )+ 1}
                    else
                        local conf = prop_world_unit[ city.propid ]
                        local uid = conf and conf.Flag and conf.Flag[4]
                        if uid then
                            points[uid] = points[uid] or {}
                            points[ uid ] = {( points[ uid ][1] or 0 ) + conf.Boss_point, (points[uid][2] or 0 )+ 1} 
                        end
                    end
                else
                    points[ uid ] = { (points[ uid ][1] or 0) + conf.Boss_point, (points[uid][2] or 0 )+ 1}
                end
            end
        end

        for uid, point in pairs( points ) do
            if uid < 10000 then
                local conf = resmng.prop_default_union[ uid ]
                if conf then
                    table.insert( rank, { uid = conf.ID, name = conf.Fullname, alias = conf.Shortname, flag = conf.Flag, score = point[1], num = point[2] } )
                end
            else
                local union = unionmng.get_union( uid )
                if union then
                    table.insert( rank, { uid = uid, name = union.name, alias = union.alias, flag = union.flag, score = point[1], num = point[2] } )
                end
            end
        end
        npc_city.union_rank = rank
    end

    Rpc:get_union_npc_rank_ack( self, { s_id = gMapID, rank=rank } )
end

function npc_log_req(self)
    Rpc:npc_log_ack(self, npc_city.npc_logs or {})
end

function npc_info_req(self, eid)
    local pack = {}
    local npc = get_ety(eid)
    if npc then
        npc_city.format_union(npc)
        pack.unions = npc.unions or {}
        pack.state = npc.state
        pack.startTime = npc.startTime
        pack.endTime = npc.endTime
        pack.eid = npc.eid
        pack.propid = npc.propid
        pack.troop = npc:get_my_troop()
        Rpc:npc_info_ack(self, pack)
    end
end

function abd_npc_cond_req(self, eid)

    if player_t.debug_tag then
        abandon_npc(self, eid)
    end

    local pack = {}
    pack.eid = eid
    local union = self:get_union()
    if union then
        pack.abd_time_left = can_date(union.abd_city_time)
        Rpc:abd_npc_cond_ack(self, pack)
    end
end

function abandon_npc(p, eid)
    if not  can_ply_opt_act[ACT_TYPE.NPC](p) then
       -- add_debug(p, "军团等级不够 宣战失败")
        if not player_t.debug_tag then
            return
        end
    end

    local u = unionmng.get_union(p.uid)
    if u then
        if not can_date(u.abd_city_time) then
            ack(p, "abandon_npc", resmng.E_DISALLOWED )
            return
        end
    else
        return
    end
    local npc = get_ety(eid)
    if npc and (npc.uid ~= 0 or npc.uid ~= npc.propid) then
        if npc.uid == p.uid then
            npc_city.abandon_npc(npc)
            u:add_log(resmng.UNION_EVENT.ABANDON_NPC,resmng.UNION_MODE.ADD,{ name=p.name,propid=npc.propid })
        end
    end
end

function act_info_req(self)
    local pack = {}
    for k, v in pairs(ACT_NAME) do
        local act ={}
        if v == ACT_NAME.MONSTER_CITY then
            local union = unionmng.get_union(self.uid)
            if union then
                act.state = union.monster_city_stage
                local clock = timer.get(union.mc_timer)
                if clock then
                    act.end_time = clock.over
                else
                    act.end_time = union.get_left_time(union.mc_start_time) + gTime
                end
            end
        end

        if v == ACT_NAME.LOST_TEMPLE then
            act.state = lost_temple.actState
            act.end_time = lost_temple.end_time
            local id = lost_temple.actState
            local prop = resmng.prop_lt_stage[id]
            if prop then
                if act.end_time < gTime then
                    act.end_time = lost_temple.end_time + prop.Spantime
                else
                    act.end_time = lost_temple.start_time + prop.Spantime
                end
            end
        end

        if v == ACT_NAME.NPC_CITY then
            local state, startTime, endTime = npc_city.get_npc_state()
            act.state= state
            act.end_time = endTime
        end

        if v == ACT_NAME.KING then
            act.state = king_city.state
            local clock = timer.get(king_city.timerId)
            if clock then
                act.end_time = clock.over
            elseif act_mng.start_act_tm and king_city.state == KW_STATE.LOCK then
                local prop = resmng.prop_kw_stage[KW_STATE.LOCK]
                local time =  60 * 86400 
                if prop then
                    time = prop.Spantime + 3 * 86400
                end
                act.endTime = act_mng.start_act_tm + time - (king_city.start_tm or 0)
            end
        end

        if v == ACT_NAME.REFUGEE then
            act.state = refugee.act_state
            act.end_time = cross_act.tm_over
        end

        if v == ACT_NAME.CROSS_NPC then
            act.state = cross_act.act_state
            act.end_time = cross_act.tm_over
        end
        pack[v] = act
    end

    --周限时活动,这个是后面设计加在这个地方的，所以比较特殊
    if self.map == gMapID then
        pack["weekly_activity"] = weekly_activity.pack_activity(self)
        pack["daily_activity"] = daily_activity.pack_activity(self, PERIODIC_ACTIVITY.DAILY)
    end

    Rpc:act_info_ack(self, pack)
end

---npc city
------------------------------------
function boss_rank_req(self)
    local topKillers, myScore, myRank = monster.get_top_killer_rank(self.pid)
    local topHurts, score, rank = monster.get_top_hurter_rank(self.pid)

    local killInfo =  {}
    local hurtsInfo = {}
    for k, v in pairs(topKillers) do
        killInfo[k] = {get_ply_info( v ), monster.get_player_score("topKillerByPid", v)}
    end
    for k, v in pairs(topHurts) do
        hurtsInfo[k] = {get_ply_info(v), monster.get_player_score("topHurtByPid", v)}
    end
    local pack = {}
    pack.topKillers = killInfo
    pack.myKillScore = myScore
    pack.mykillRank = myRank
    pack.topHurts = hurtsInfo
    pack.myHurtScore = score
    pack.myHurtRank = rank
    Rpc:boss_rank_ack(self, pack)
end

function gen_boss_req(self, mode, lv)  -- for robot 
    while true do
        local propid, x, y, eid = monster.force_born(math.floor(self.x/16), math.floor(self.y/16), tonumber(lv))
        print("boss info ", propid, eid)
        if eid then
            Rpc:gen_boss_eid_ack(self, eid)
            break
        end
    end
end

function get_ply_info(pid)
    return gPlys[tonumber(pid)]
end

function get_hold_limit(self,dp)
    if not dp then return end
    local num ,limit=0,0
    local u = unionmng.get_union(dp.uid)
    if not u then return end

    local tr = troop_mng.get_troop(dp.my_troop_id)
    if tr then num = tr:get_troop_total_soldier() end

    for tid, action in pairs( dp.troop_comings or {} ) do
        local troop = troop_mng.get_troop( tid )
        if troop and troop:is_go() then
            if action == TroopAction.UnionBuild or action == TroopAction.UnionFixBuild or action == TroopAction.UnionUpgradeBuild or action == TroopAction.HoldDefense or
                action == TroopAction.HoldDefenseNPC or
                action == TroopAction.HoldDefenseLT or
                action == TroopAction.HoldDefenseKING
                then
                num = num + troop:get_troop_total_soldier()
            end
        end
    end

    limit = union_build_t.get_hold_limit( dp )

    return num,limit
end

function get_hold_info(self,dp)
    local troops = {}
    local troop = troop_mng.get_troop(dp.my_troop_id)
    if troop then
        for k, v in pairs(troop.arms) do
            local single = self:fill_player_info_by_arm(v, troop.action, troop.owner_pid)
            if single then
                single._id = troop._id
                single.tmStart = troop.tmStart
                single.tmOver = troop.tmOver
                single.action = troop.action
                table.insert(troops, single)
            end
        end
    end

    for tid, action in pairs( dp.troop_comings or {} ) do
        if action == TroopAction.SupportArm or action == TroopAction.HoldDefense or action == TroopAction.UnionBuild or
                action == TroopAction.HoldDefenseNPC or
                action == TroopAction.HoldDefenseKING or
                action == TroopAction.HoldDefenseLT
            then
            local troop = troop_mng.get_troop( tid )
            if troop and troop:is_go() then
                local single = self:fill_player_info_by_arm(troop:get_arm_by_pid(troop.owner_pid), troop.action, troop.owner_pid)
                single._id = troop._id
                single.tmStart = troop.tmStart
                single.tmOver = troop.tmOver
                single.action = troop.action
                if action == TroopAction.HoldDefenseNPC or action == TroopAction.HoldDefenseKING or action == TroopAction.HoldDefenseLT then
                    if troop.owner_uid == self.uid then
                        table.insert(troops, single)
                    end
                else 
                    table.insert(troops, single)
                end
            end
        end
    end
    return troops
end

function get_eye_info_by_propid(self, propid)
    local eid 
    if is_type_propid(propid, EidType.KingCity) then
        eid = king_city.get_city_by_propid(propid)
    end
    if is_type_propid(propid, EidType.NpcCity) then
        eid = npc_city.get_npc_eid_by_propid(propid) 
    end
    if eid then
        self:get_eye_info(eid)
    end
end

function get_eye_info(self,eid)--查询大地图建筑信息
    local dp = get_ety(eid)
    if not dp then return end
    local pack ={}

    if is_monster(dp) then
        local score = monster.get_top_hurter_by_propid(dp.propid)
        Rpc:get_eye_info(self, eid, score or {pid=0,name="system",hurt=0})
    elseif is_king_city(dp) then
        king_city.eye_info(dp, pack)
        pack.troop = self:get_hold_info(dp)
        pack.canVote = (self.kwseason ~= king_city.season)

        local union = self:get_union()
        if union then
           -- king_city.add_kw_buff(union, self) -- not use
        end
        pack.hold_num, pack.hold_limit = npc_city.hold_limit(dp, self)
        local all_hold_num, _hold_limit = npc_city.hold_num_limit(dp, self)
        if union then
           --king_city.rem_kw_buff(union, self) -- not use
        end

        pack.all_hold_num = all_hold_num or 0
        pack.troop_pow = npc_city.get_troop_info(dp)

        local hold_tr = troop_mng.get_troop(dp.my_troop_id)
        if hold_tr then
            pack.owner_pid = hold_tr.owner_pid
        end
        Rpc:get_eye_info(self, eid, pack)

    elseif is_npc_city(dp) then
        npc_city.eye_info(dp, pack)
        pack.hold_num,pack.hold_limit = npc_city.hold_limit(dp, self)
        local all_hold_num, _hold_limit = npc_city.hold_num_limit(dp, self)
        pack.all_hold_num = all_hold_num or 0
        pack.troop = self:get_hold_info(dp)
        pack.troop_pow = npc_city.get_troop_info(dp)

        local hold_tr = troop_mng.get_troop(dp.my_troop_id)
        if hold_tr then
            pack.owner_pid = hold_tr.owner_pid
        end
        Rpc:get_eye_info(self, eid, pack)

    elseif is_lost_temple(dp) then
        lost_temple.eye_info(dp, pack)
        pack.hold_num,pack.hold_limit = npc_city.hold_limit(dp, self)
        local all_hold_num, _hold_limit = npc_city.hold_num_limit(dp, self)
        pack.all_hold_num = all_hold_num or 0
        pack.troop_pow = npc_city.get_troop_info(dp)
        pack.troop = self:get_hold_info(dp)

        local hold_tr = troop_mng.get_troop(dp.my_troop_id)
        if hold_tr then
            pack.owner_pid = hold_tr.owner_pid
        end

        Rpc:get_eye_info(self, eid, pack)

    elseif is_monster_city(dp) then
        monster_city.eye_info(dp, pack)
        Rpc:get_eye_info(self, eid, pack)

    elseif is_res(dp) then
        if dp.pid == self.pid then
           local troop = troop_mng.get_troop( dp.my_troop_id )
           if troop then
               pack = troop:get_info()
               pack.extra = troop.extra
               Rpc:get_eye_info(self, eid, pack)
           end

        else
            local pack = {}
            local pid = dp.pid
            local uid = dp.uid
            local dply = getPlayer( pid )
            if dply then
                pack.name = dply.name
                local union = dply:get_union()
                if union then
                    pack.alias = union.alias
                end
            end
            Rpc:get_eye_info(self, eid, pack)
        end

    elseif is_camp( dp ) then
        if dp.pid and dp.pid >= 10000 then
            if self.uid > 0 and self.uid == dp.uid then
                local troop = troop_mng.get_troop( dp.my_troop_id )
                if troop then
                    pack = troop:get_info()
                    pack.extra = troop.extra
                    Rpc:get_eye_info(self, eid, pack)
                end
            else
                local pack = {}
                local pid = dp.pid
                local uid = dp.uid
                local dply = getPlayer( pid )
                if dply then
                    pack.name = dply.name
                    local union = dply:get_union()
                    if union then
                        pack.alias = union.alias
                    end
                end
                Rpc:get_eye_info(self, eid, pack)
            end
        end

    elseif is_dig( dp ) then
        local owner = getPlayer( dp.pid )
        if owner then
            pack.pid = owner.pid
            pack.name = owner.name
            pack.photo = owner.photo
            pack.itemid = dp.itemid
            local union = unionmng.get_union( owner.uid )
            if union then
                pack.alias = union.alias
            end
            Rpc:get_eye_info(self, eid, pack)
        end

    elseif is_union_building(dp) then
        local u = unionmng.get_union(dp.uid)
        if not u then
            ack(self, "get_eye_info", resmng.E_NO_UNION) return
        end

        if dp.uid ~= self.uid then --其他军团建筑
            INFO("不能查询其他军团建筑")
            return
        end

        pack.tmStart = dp.tmStart_b
        pack.tmOver = dp.tmOver_b
        pack.hold_num,pack.hold_limit = self:get_hold_limit(dp)

        local info = {}
        info.state = dp.state
        info.hp = dp.hp
        info.val = dp.val

        info.tmStart = dp.tmStart_g
        info.tmOver = dp.tmOver_g
        info.speed = dp.speed_g --采集速度

        info.tmStart_f = dp.tmStart_f
        info.tmOver_f = dp.tmOver_f
        info.speed_f = dp.speed_f

        info.tmStart_b = dp.tmStart_b
        info.tmOver_b = dp.tmOver_b
        info.speed_b = dp.speed_b

        pack.dp = info
        if dp.state == BUILD_STATE.CREATE or dp.state == BUILD_STATE.UPGRADE then
            pack.troop = self:get_hold_info(dp)
            Rpc:get_eye_info(self, eid, pack)
            return
        end

        if is_union_restore(dp.propid) then
            pack.limit = union_build_t.get_restore_limit(self,dp)
            local u = unionmng.get_union(self.uid)
            pack.res = u:get_restore_detail() or {}
            Rpc:get_eye_info(self,eid,pack)

        elseif is_union_miracal(dp.propid) then
            pack.troop = self:get_hold_info(dp)
            Rpc:get_eye_info(self,eid,pack)
            return
        elseif is_union_superres(dp.propid) then

            local troop = {}
            if type(dp.my_troop_id)=="table" then
                for _, tid in pairs(dp.my_troop_id or {} ) do
                    local tm_troop = troop_mng.get_troop(tid)
                    if tm_troop then
                        local single = self:fill_player_info_by_arm(tm_troop:get_arm_by_pid(tm_troop.owner_pid), tm_troop.action, tm_troop.owner_pid)
                        single._id = tm_troop._id
                        single.tmStart = tm_troop.tmStart
                        single.tmOver = tm_troop.tmOver
                        single.speed = tm_troop:get_extra("speed")
                        single.speedb = tm_troop:get_extra("speedb")
                        single.action = tm_troop.action
                        table.insert(troop, single)
                    end
                end
            end

            for tid, action in pairs( dp.troop_comings or {} ) do
                if action == TroopAction.Gather then
                    local t = troop_mng.get_troop( tid )
                    if t and t:is_go() then
                        local single = self:fill_player_info_by_arm(t:get_arm_by_pid(t.owner_pid), t.action, t.owner_pid)
                        single._id = t._id
                        single.tmStart = t.tmStart
                        single.tmOver = t.tmOver
                        single.speed = 0
                        single.speedb = 0
                        single.action = t.action
                        table.insert(troop, single)
                    end
                end
            end
            pack.troop = troop
            Rpc:get_eye_info(self,eid,pack)
            return
        end
    end
end
------ king city
--
function king_info_req(self)
    local pack = {}
    local kings = king_city.kings
    local king = {}
    if kings then
        local now_king = kings[king_city.season]
        if now_king then
            local king_ply = getPlayer(now_king[2])
            if king_ply then
                king.name = king_ply.name
                king.flag = king_ply.flag
                pack.king = king
            else
                king.name = now_king[6]
                king.flag = now_king[7]
                pack.king = king
            end
        end
    end
    pack.season = king_city.season
    pack.gs_name = tostring(gMapID)
    pack.s_id = _G.gSysStatus._id
    Rpc:king_info_ack(self, pack)
end

function kw_info_req(self)
    local pack = {}
    local pointType = POINT_MALL_TYPE[POINT_MALL.KING]
    pack.credit = kw_mall.get_kw_point()
    local time = timer.get(king_city.timerId)
    pack.state = king_city.state
    if time then
        pack.endTime = time.over
    elseif act_mng.start_act_tm and king_city.state == KW_STATE.LOCK then
        local prop = resmng.prop_kw_stage[KW_STATE.LOCK]
        local time =  60 * 86400 
        if prop then
            time = prop.Spantime + 3 * 86400
        end
        pack.endTime = act_mng.start_act_tm + time - (king_city.start_tm or 0)
    end

    local kingCity = king_city.get_king()
    if kingCity then
        local union = unionmng.get_union(kingCity.uid)
        if union then
            pack.kualias = union.alias
            pack.kuname = union.name
            local kings = king_city.kings
            local king = {}
            if kings then
                local now_king = kings[king_city.season]
                if now_king then
                    local king_ply = getPlayer(now_king[2])
                    if king_ply then
                        king.name = king_ply.name
                        king.photo = king_ply.photo
                        king.lv = king_ply:get_castle_lv()
                        pack.king = king
                    else
                        king.name = now_king[6]
                        king.photo = now_king[7]
                        king.lv = now_king[8]
                        pack.king = king
                    end
                end
            end
            local ply = getPlayer(union.leader)
            local nextking = {}
            if ply and not pack.king then
                nextking.name = ply.name
                nextking.photo = ply.photo
                nextking.lv = ply:get_castle_lv()
                pack.nextking = nextking
            end
        end
    end

    local citys = {}
    for k, v in pairs(king_city.citys) do
        local kc = get_ety(v)
        local city = {}
        if kc then
            city.x = kc.x
            city.y = kc.y
            city.uid = kc.uid
            local union = unionmng.get_union(kc.uid)
            if union then
                city.uname = union.name
                city.ualias = union.alias
                city.flag = union.flag
            end
            city.state = kc.state
            city.startTime = kc.startTime
            city.endTime = kc.endTime
            city.status = kc.status
            city.propid = kc.propid

            local prop = resmng.prop_world_unit[kc.propid]
            if prop and prop.Lv == CITY_TYPE.FORT then
                local time = timer.get(kc.timers.troop)
                if time then
                    city.tmOver = time.over
                end
                --[[local tr = monster_city.get_fast_troop(kc, ETY_TROOP.LEAVE)
                if tr then
                    city.tmOver = tr.tmOver
                end--]]
            end
        end
        table.insert(citys, city)
    end
    pack.citys = citys
    pack.rewardTm = gTime + 1000
    Rpc:kw_info_ack(self, pack)

end

function change_world_name_by_king_req(self, name)
    local kings = king_city.kings 
    if kings then
        local now_king = kings[king_city.season]
        if self.pid == now_king[2] and now_king.change_name == nil then
            local code = want_insert_unique_name( "king_server_name", name, { pid=self.pid, account=self.account, map=gMapID, time=gTime, action="create"} )
            if code ~= 0 then
                ack(self, "change_world_name_by_king_req", resmng.E_DUP_NAME, resmng.E_DUP_NAME)
                return
            end
            delete_global_data("king_server_name", king_city.king_server_name)
--            now_king.change_server_name = true
            king_city.king_server_name = name
            gPendingSave.status["kwState"].king_server_name = name
            kings[king_city.season] = now_king
            ack(self, "change_world_name_by_king_req", resmng.E_OK, resmng.E_OK)
        end
    end
end

function delete_global_data(tbl, name)
    local db = dbmng:getGlobal()
    if not db then
        return -3
    end

    local docs = {}
    docs[1] = {
        q = {_id = name},
        limit = 1,
    }
    local info = db:runCommand("delete", tbl, "deletes", docs,  "ordered", false , "writeConcern", mongo_save_mng.COMMON_WRITE_CONCERN)

    local is_error = false
    if info.ok ~= nil and info.ok == 1 then
        if info.errmsg or info.writeErrors or info.writeConcernError then
            is_error = true
        end
    else
        is_error = true
    end

    if is_error then
        LOG("delete_global_data catch error ok=%s, code=%s, errmsg=%s, writeConcernError=%s", info.ok, info.code, info.errmsg, info.writeErrors, info.writeConcernError)
        dumpTab(info, "delete_global_data", nil, true) 
        return -1
    end
    
    return 0
end

function server_map_king_info(self)
    local msg = {}
    local kings = king_city.kings
    if kings then
        local now_king = kings[king_city.season]
        if now_king then
            local king_ply = getPlayer(now_king[2])
            if king_ply then
                msg.king_name = king_ply.name
                msg.king_culture = king_ply.culture
                msg.change_server_name = now_king.change_server_name
                local union = unionmng.get_union(king_ply.uid)
                if union then
                    msg.king_lan = union.language
                end
            else
                msg.king_name = now_king[6]
                local union = unionmng.get_union(now_king[3])
                if union then
                    msg.king_lan = union.language
                end
            end
        end
    end

    msg.king_server_name = king_city.king_server_name
    msg.sid = gMapID
    msg.state = king_city.state

    Rpc:server_map_king_info_resp(self, msg)
end

function select_officer_req(self, pid, index)
    if index == KING then
        king_city.select_king_by_leader(self, pid)
    else
        king_city.select_officer(self, pid, index)
    end
    officers_info_req(self)
end

function rem_officer_req(self,index)
    king_city.rem_officer(self,  index)
    officers_info_req(self)
end


function mark_king_req(self, score)
    if king_city.season == self.kwseason then
        return
    end
    if self:get_officer() == KING then
        return
    end
    local point = king_city.mark_king(score) or 0
    self.kwseason = king_city.season
    --Rpc:mark_king_ack(point)
    --officers_info_req(self)
end

function officers_info_req(self)
    local pack = {}
    local officers = {}
    local has_king = false
    for  k, v in pairs(king_city.officers) do
        local officer = {}
        local ply = getPlayer(v[1])

        if k == KING then
            has_king = true
        end
        if ply then
            officer.index = k
            officer.pid = ply.pid
            officer.name = ply.name
            officer.photo = ply.photo
            officer.lv = ply:get_castle_lv()
            local union = unionmng.get_union(ply.uid)
            if union then
                officer.u_name = union.name
                officer.u_alias = union.alias
            end
        else
            officer.index = k
            officer.pid = v[1]
            officer.name = v[2]
            officer.photo = v[3]
            officer.lv = v[4]
            officer.u_name = v[5]
            officer.u_alias = v[6]
        end
        officers[k] = officer
    end

    if has_king == false then
        local king_city = king_city.get_king()
        local win_u = unionmng.get_union(king_city.uid)
        if win_u then
            local candidate = {}
            local ply = win_u:get_leader()
            if ply then
                candidate.name = ply.name
                candidate.union = win_u.alias
            end
            pack.candidate = candidate
        end
    end

    pack.officers = officers
    Rpc:officers_info_ack(self, pack)
end

function honour_wall_req(self)
    local pack = {}
    local kings = {}
    local season = king_city.season
    local start_year = os.date("%Y", get_sys_status("start") or 0 ) or 0
    pack.start_year = start_year
    for k, v in pairs(king_city.kings) do
        local ply = getPlayer(v[2])
        local plyName = v[6]
        local plyPhoto = v[13] or 1
        local unionName = v[9]
        local unionalias = v[14]
        if ply then
            plyName = ply.name
            plyPhoto = ply.photo
        end
        local union = unionmng.get_union(v[3])
        if union then
            unionName = union.name
            unionalias = union.alias
        end
        local year = os.date("%Y", v[5]) or 0
        local point = string.format("%0.2f", (v[4] / v[10] or 1))
        table.insert(kings, {k, v[2], plyName, unionName, unionalas, tonumber(point), v[5], math.floor(year - start_year + 1), plyPhoto})
    end
    pack.kings = kings
    pack.season = season
    --pack.canVote = (self.kwseason ~= season)
    Rpc:honour_wall_ack(self, pack)
end

function kw_mall_buy_req(self, mode, index, num)
    if mode == POINT_MALL.KING then
        kw_mall.buy(self, index)
        kw_mall_info_req(self, mode)
    else
        self:mall_buy(mode, index, num)
    end
    kw_mall_info_req(self, mode)
end

function kw_want_buy_req(self, index)
    kw_mall.want_buy(self, index)
    kw_mall_info_req(self, POINT_MALL.KING)
end


function kw_mall_info_req(self, mode)
    local pack = {}
    if mode == POINT_MALL.KING then
        pack.goods = kw_mall.shelf
        pack.point = kw_mall.kw_point
        if gTime > kw_mall.refresh_time then
            kw_mall.refresh_kw_mall()
        end
        pack.refresh_tm = kw_mall.refresh_time
        pack.have_vote = (not can_date(self.vote_time))
    else
        local mall = self:mall_info(mode)
        local pointType = POINT_MALL_TYPE[mode]
        pack.point = self[pointType]
        if mall then
            pack.goods = mall.shelf
            pack.refresh_tm = mall.next_time
            pack.refresh_count= mall.nrefresh + 1
        end
    end

    Rpc:kw_mall_info_ack(self, pack)
end

function find_player_by_name_req(self, name)
    local pack = {}
    local db = dbmng:getOne()
    local info = db.player:findOne({name = name}, {pid=1})
    pack.name = name
    if info  then
        local p = getPlayer( info.pid )
        if p then
            pack.pid = p.pid
            pack.name = p.name
            pack.photo = p.photo
            pack.photo_url = p.photo_url
            pack.lv = p:get_castle_lv()
            pack.vip_lv = p.vip_lv
            pack.uid = p.uid
            pack.officer = p:get_officer()
            local union = unionmng.get_union(p.uid)
            if union then pack.ualias = union.alias or "" end
            if union then pack.uname = union.name or "" end
        end
    end
    Rpc:find_player_by_name_ack(self, pack)
end

function get_store(self)
    local stores = {0,0,0,0}
    local rate = {1, 1, 0.2, 0.05}

    local count = self:get_val("CountStore")
    for k, v in pairs(rate) do
        stores[ k ] = math.floor(rate[ k ] * count)
    end
    return stores
end


function get_res_over_store(self)
    local stores = self:get_store()
    self:refresh_food()

    local res = {0,0,0,0}
    for k, v in pairs(self.res) do
        if v[1] > stores[ k ] then
            res[ k ] = math.floor(v[1] - stores[ k ])
        end
    end
    return res
end

function get_farms(self)
    local clv = self:get_castle_lv()
    local class = BUILD_CLASS.RESOURCE
    local bs = {}
    for mode = 1, 4, 1 do
        if clv >= Gather_Level[ mode ] then
            local max_seq = BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]
            for seq  = 1, max_seq, 1 do
                local build_idx = self:calc_build_idx(class, mode, seq)
                local build = self:get_build(build_idx)
                if not build then break end
                if build.state == BUILD_STATE.WORK then
                    if gTime - build.tmStart > 600 then
                        build.mode = mode
                        table.insert(bs, build)
                    end
                end
            end
        end
    end
    return bs
end

function qry_troop_info(self, tid)
    local troop = troop_mng.get_troop(tid)
    if troop == nil then
        return
    end
    local info = troop:get_info()
    info.extra = troop.extra
    Rpc:ack_troop_info(self, info)

    --for pid, arm in pairs(troop.arms) do
    --    if pid == self.pid then
    --        local t = {}
    --        t.soldiers = arm.live_soldier
    --        local heros = {}
    --        for k, v in pairs(arm.heros) do
    --            if v ~= 0 then
    --                local h = heromng.get_hero_by_uniq_id(v)
    --                if h then
    --                    table.insert(heros, { h.propid, h.lv })
    --                end
    --            end
    --        end
    --        t.heros = heros
    --        t.bufs = troop.bufs -- { {bufid, tmOver}, {bufid, tmOver} }
    --        t.extra = troop.extra -- {speed=10, speedb=8, count=10, start=1923333, cache=199}
    --        t._id = tid
    --        Rpc:ack_troop_info(self, t)
    --        return
    --    end
    --end
end

-- count == -1, means a buf forever
function add_buf(self, bufid, count)
    if count <= 0 and count ~= -1 then
        WARN( "add_buf, pid=%d, buf=%d, count=%d", self.pid, bufid, count)
        return
    end

    local node = resmng.prop_buff[ bufid ]
    if node then
        local dels = {}
        local bufs = self.bufs
        if node.Mutex == 1 then  -- 互斥
            local group = node.Group
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    table.insert(dels, v)
                end
            end

        elseif node.Mutex == 2 then -- 高级替换低级
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.Lv > lv then return end
                    table.insert(dels, v)
                end
            end
        elseif node.Mutex == 3 then -- 相同的就叠加时间
            local group = node.Group
            local lv = node.Lv
            for k, v in ipairs(bufs) do
                local b = resmng.get_conf("prop_buff", v[1])
                if b and b.Group == group then
                    if b.ID == bufid then
                        if count == -1 then
                            v[3] = -1
                        else
                            local remain = v[3] - gTime
                            if remain < 0 then remain = 0 end
                            remain = remain + count
                            local tmOver = gTime + remain
                            v[3] = tmOver
                            timer.new("buf", remain, self.pid, bufid, tmOver)
                        end
                        INFO( "add_buf, pid=%d, bufid=%d, count=%d", self.pid, bufid, count )
                        self.bufs = bufs
                        return
                    end
                end
            end
        end

        if #dels > 0 then
            for _, v in pairs( dels ) do
                self:rem_buf( v[1], v[3] )
            end
        end

        local tmOver = gTime + count
        if count == -1 then tmOver = -1 end
        local buf = {bufid, gTime, tmOver}
        table.insert(bufs, buf)
        self.bufs = bufs
        if node.Value then self:ef_add(node.Value) end

        INFO( "add_buf, pid=%d, bufid=%d, count=%d", self.pid, bufid, count )

        if count ~= -1 then
            timer.new("buf", count, self.pid, bufid, tmOver)
        end

        return buf
    end
end

function check_buf( self )

end


function rem_buf(self, bufid, tmOver)
    local bufs = self.bufs
    local remain = 0
    for k, v in pairs(bufs) do
        --v = {bufid, tmStart, tmOver}
        if v[1] == bufid then
            if not tmOver or tmOver == v[3] then
                table.remove(bufs, k)
                local node = resmng.prop_buff[ bufid ]
                if node and node.Value then self:ef_rem(node.Value) end
                self.bufs = bufs

                local r = v[3] - gTime
                if r > 0 then remain = r end

                if node and node.IsInform then
                    if node.IsInform > 0 then
                        self:add_to_do( "notify_buf", bufid, v[2], v[3] )
                    end
                end

                INFO( "rem_buf, pid=%d, bufid=%d, tmOver=%d", self.pid, bufid, tmOver or 0 )
            end
        end
    end
    return remain
end

function notify_buf( self, bufid, start, over )
    Rpc:notify_buf( self, bufid, start, over )
end

function notify_build_upgrade(self , build_idx)
    Rpc:notify_build_upgrade(self, build_idx)
end

function get_buf( self, bufid )
    local bufs = self.bufs
    for k, v in pairs(bufs or {}) do
        --v = {bufid, tmStart, tmOver}
        if v[1] == bufid then
            return v
        end
    end
end

function get_buf_remain( self, bufid )
    local b = player_t.get_buf( self, bufid )
    if b then
        return b[3] - gTime
    end
    return 0
end

function get_do_mc_npc_req(self)  --正在进行mc 活动的npc城市
    local citys = get_do_mc_npc_info()
    if citys then
        Rpc:get_do_mc_npc_ack(self, citys)
    end
end

function get_do_mc_npc_info()
    if npc_city.do_mc_citys  then
        return npc_city.do_mc_citys 
    end
    local citys = {}
    for k, v in pairs(npc_city.citys or {}) do
        local city = get_ety(k)
        if city then
            local union = unionmng.get_union(city.uid)
            if union then
                if union.monster_city_stage ~= 0 then
                    table.insert(citys, {city.propid, city.eid})
                end
            end
        end
    end
    npc_city.do_mc_citys = citys
    return citys
end

--- 怪物攻城
function mc_info_req(self)
    local pack = {}
    local union = unionmng.get_union(self.uid)
    local pointType = POINT_MALL_TYPE[POINT_MALL.MONSTER]
    pack.credit = self[pointType]
    pack.point = 0
    local active_st_tm , active_end_tm = monster_city.get_active_tm() 
    if union then
        pack.startTm = union.mc_start_time or union:get_default_time()
        pack.set_mc_time = union.set_mc_time
        pack.mc_grade = union.mc_grade or 1
        if pack.mc_grade >= 1 then
            local clock = timer.get(union.mc_timer)
            if clock then
                pack.deadline = clock.over
            else
                pack.deadline = union.get_left_time(union.mc_start_time) + gTime
            end
        end
        if pack.deadline > active_end_tm then
            pack.active_st_tm , pack.active_end_tm = monster_city.get_next_active_tm()
        else
            pack.active_st_tm = active_st_tm
            pack.active_end_tm = active_end_tm
        end
        --pack.canSetTime = ( os.date("%d", union.set_mc_time) ~= os.date("%d", gTime) and union.monster_city_stage == 0)
        pack.canSetTime = (union.set_mc_time < gTime) and union.monster_city_stage == 0
        pack.stage = union.monster_city_stage or 0
        pack.maxStage = 20
        pack.point = union.mc_point
        --[[for k, v in pairs(union.mc_reward_pool) do
            if v[2] == 11 then
                point = point + v[3]
            end
        end
        pack.point = point--]]
        pack.reward = self[pointType]
        pack.award = union.mc_reward_pool
        local citys = {}
        for k, v in pairs (union.npc_citys or {}) do
            local city = {}
            local npc = get_ety(v)
            if npc then
                local def_tr = npc:get_my_troop()
                city.hold_num,city.hold_limit = npc_city.hold_limit(npc, self)
                city.propid = npc.propid
                local mc = union_t.get_live_mc(v)
                if mc then
                    city.endTime = mc.endTime
                    if def_tr then
                        city.def_num = def_tr:get_troop_total_soldier()
                        --pack.def_tr = def_tr
                    end
                    local troop = monster_city.get_fast_troop(npc, ETY_TROOP.ATK)
                    if troop and troop._id then
                        --city.armId =  mc.propid % (1000 * 1000) * 1000 + union.monster_city_stage
                        city.armId = troop.mcid
                        city.troopId = troop._id
                        city.tmOver = troop.tmOver
                    else
                        city.armId = mc.propid % (1000000) * 1000 + pack.stage + 1
                    end
                    if mc.defend_id then
                        local defCity = get_ety(mc.defend_id)
                        if defCity then
                            city.defX = defCity.x
                            city.defY = defCity.y
                            city.defEid = defCity.eid
                        end
                    end
                end
                if get_table_valid_count(city) > 0 then table.insert(citys, city) end
            end
        end
        pack.citys = citys
    end
    Rpc:mc_info_ack(self, pack)
end

function set_mc_start_time_req(self, time, grade)
    if not can_ply_opt_act[ACT_TYPE.MC](self) then
        Rpc:tips(self, 1, resmng.ACTIVITIES_MONSTER_SET_TIP, {})
        return
    end

    local u = unionmng.get_union(self.uid)
    if u then
        union_t.set_mc_start(u, time, grade, self)
        player_t.pre_tlog(nil,"UnionList",u.uid,u.name,u.language,3,
            tostring(u.mc_start_time[1]),u.membercount,u.activity or 0 ) 
        mc_info_req(self)
    end
end

function add_tips( self, mode, id, param )
    Rpc:tips(self, mode, id, param or {} )
end

function get_mc_akt_info_req(self)
    local union = unionmng.get_union(self.uid)
    local pack = {}
    if union then
        pack.info = union_t.get_monster_info(union)
    end
    Rpc:get_mc_akt_info_ack(self, pack)
end

function load_msg_list(self, what, sn, count, new)
    local mlist = msglist.get(what)
    if mlist then
        local infos
        if new == 1 then
            infos = mlist:msg_load_new(sn, count)
        else
            infos = mlist:msg_load_old(sn, count)
        end
        Rpc:msg_load(self, what, sn, count, new, infos)
        return
    end
    Rpc:msg_load(self, what, sn, count, new, {})
end

function get_pow(self)
    return self.pow or 0
end

function refresh_rank_pow( self )
    local delta = self.pow - ( self.pow_last or self.pow )
    if delta ~= 0 then
        self.pow_last = self.pow
        rank_mng.add_data( 3, self.pid, { self.pow } )
        local union = self:get_union()
        if union then
            union.pow = (union.pow or 0) + delta
            rank_mng.add_data( 5, union.uid, { union.pow } )
            union_mission.ok(self,UNION_MISSION_CLASS.POW, delta)
        end

        --运营活动
        operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.FIGHT_POWER, self.pow)

    end
end


function inc_pow(self, num)
    if num and num > 0 then
        self.pow = (self.pow or 0) + num
        self:mark_action( refresh_rank_pow )
    end
end

function dec_pow(self, num)
    if num and num > 0 then
        self.pow = self.pow - num
        self:mark_action( refresh_rank_pow )
    end
end

function get_live(self)
    local troop = self:get_my_troop()
    if troop then
        return troop:get_live(self.pid)
    end
end


---- chat admin
function chat_account_info_req(self)
    if self.chat_account == self.pid then
        Rpc:chat_account_info_ack(self, self.chat_account, self.chat_psw, config.Chat_addr or CHAT_ADDR)
    else
        self:create_chat_account()
    end
end

function create_chat_account(ply)
    --to_tool(0, {type = "chat", cmd = "create_chat", user = tostring(ply.pid), host = CHAT_HOST, password = tostring(ply.pid)})
   to_tool(0, {url = config.Chat_url or CHAT_URL, type = "chat", method = "post", cmd = "create_chat", user = tostring(ply.pid), host = CHAT_HOST,password = tostring(ply.pid)})
end

--- register result  chat call back
function create_chat(info)
    if info.result == 1 then
        local ply = getPlayer(tonumber(info.pid))
        if ply then
            ply.chat_account = ply.pid
            ply.chat_psw = ply.pid
            ply.chat_addr = config.Chat_addr or CHAT_ADDR
            Rpc:chat_account_info_ack(ply, ply.chat_account, ply.chat_psw, ply.chat_addr)
        end
    end
end

function create_room(info)
    if info.result == 1 then
        local union = unionmng.get_union(tonumber(info.uid))
        if union then
            union.chat_room = tostring(union.uid)
        end
    end
end

function testCross( self, a1, a2 )
    print( string.format( "CrossCall, from %d to %d, a1=%s, a2=%s", self.pid, _G.gMapID, a1, a2 ) )
end

function ack_tool( self, sn, info )
    if info.api then
        player_t[info.api](info)
    end
end

function city_break( self, attacker )
    self:release_all_prisoner()
    self:wall_fire( 1800 )
    self:add_count(resmng.ACH_COUNT_DEFENSE_LOSE, 1)
end

function vip_add_exp( p, exp )
    if exp <= 0 then return end
    exp = p.vip_exp + exp
    p.vip_exp = exp

    local lv = p.vip_lv
    local tolv = lv
    local node = false
    for k, v in ipairs( resmng.prop_vip ) do
        if k >= lv then
            if exp >= v.Exp then
                tolv = k
                node = v
            else
                break
            end
        end
    end

    if tolv > lv then
        p.vip_lv = tolv
        local src = resmng.get_conf( "prop_vip", lv)
        local remain = p:rem_buf( src.Buf )
        p:add_buf( node.Buf, remain + ( tolv - lv ) * 24 * 3600 )
        p:pre_tlog("PlayerVipExpFlow",exp,lv,0,0)
        --p:tlog_ten2("VipLevelFlow",lv,tolv)
        local pack = {}  ----  display 
        pack.mode = DISPLY_MODE.VIP
        pack.lv = tolv
        p:add_to_do("display_ntf", pack)
    end
end

function vip_signin( self )
    if self.vip_lv < 1 then self.vip_lv = 1 end
    local dif = get_diff_days( self.vip_login, gTime )
    if dif == 0 then
        -- nothting, already done
    elseif dif == 1 then
        self.vip_lv_old = self.vip_lv
        self.vip_login = gTime
        local node = resmng.get_conf( "prop_vip", self.vip_lv )
        local exp = node.Base + node.Acc * self.vip_nlogin
        if exp > node.Max then exp = node.Max end
        self:vip_add_exp( exp )
        self.vip_nlogin = self.vip_nlogin + 1

    elseif dif > 1 then
        self.vip_lv_old = self.vip_lv
        self.vip_login = gTime
        local node = resmng.get_conf( "prop_vip", self.vip_lv )
        self:vip_add_exp( node.Base )
        self.vip_nlogin = 1

    end
end

function vip_enable( p, dura )
    local conf = resmng.get_conf( "prop_vip", p.vip_lv )
    local buf = p:get_buf( conf.Buf )
    if buf then
        p:rem_buf( buf[1], buf[3] )
        p:add_buf( conf.Buf, buf[3] - gTime + dura )
    else
        p:add_buf( conf.Buf, dura )
    end

end

function is_vip_enable( self )
    local conf = resmng.get_conf( "prop_vip", self.vip_lv )
    return self:get_buf( conf.Buf )
end

function dec_gold( self, num, reason )
    if num <= 0 then return end
    if self.gold < num then return end
    self:do_dec_res(resmng.DEF_RES_GOLD, num, reason)
    return self.gold
end

function vip_buy_gift( self, idx )
    if idx <= 0 then return end
    if idx > self.vip_lv then return end
    if get_bit( self.vip_gift, idx ) == 1 then return end

    local conf = resmng.get_conf( "prop_vip", self.vip_lv )
    local buf = self:get_buf( conf.Buf )
    if not buf then return end

    local conf = resmng.get_conf( "prop_vip", idx )
    if not self:dec_gold( conf.PriceNow, VALUE_CHANGE_REASON.VIP_BUY) then return end

    self:add_bonus("mutex_award", {{"item", conf.Gift, 1, 10000}}, VALUE_CHANGE_REASON.VIP_BUY)
    --self:add_bonus("mutex_award", conf.Gift, VALUE_CHANGE_REASON.VIP_BUY)
    self.vip_gift = set_bit( self.vip_gift, idx )
end


function report_new( self, mode, m )
    local lv = 0
    if mode == MAIL_REPORT_MODE.PANJUN then lv = m.dest.eid end
    self:mail_new( { class = MAIL_CLASS.REPORT, mode = mode, lv = lv, content = m } )
end



function report_load( self, mode )
    local db = self:getDb()
    local tab = string.format("report%d", mode)
    local info = db[tab]:find({_id=self.pid})
    if info:hasNext() then
        local t = info:next()

        local count = #(t.vs)
        if count > 50 then
            local vs = t.vs
            for i = count, 50, -1 do
                table.remove( vs, 1 )
            end
        end

        Rpc:report_load(self, mode, t.vs )
        return
    end
    Rpc:report_load(self, mode, {})
end

function report_del( self, mode )
    local db = self:getDb()
    local tab = string.format("report%d", mode)
    local info = db[tab]:delete({_id=self.pid})
    reply_ok(self, "report_rem", mode)
end

function set_culture( self, culture )
    if culture >= 1 and culture <= 4 then
        self.culture = culture
        self.propid = culture * 1000 + self:get_castle_lv()
        reply_ok( self, "set_culture", culture )
        etypipe.add( self )
        return
    end
    ack( self, "set_culture", E_NO_CONF )
end

function syn_back_code(self, syn)
    Rpc:syn_back_code_resp(self, syn)
end

function load_rank( self, idx, version )

    if idx == 27 then -- 军团内怪物攻城积分特殊出来
        local union = unionmng.get_union(self.uid)
        if not union then
            return 
        end

        local ver, info = union:get_mc_rank(version)

        if ver == version and ver ~= 0 then
            Rpc:rank_pos( self, idx, 0 )
            return
        end

        local extra = {}
        local countdown = get_rank_countdown(idx)
        if countdown then
            extra.countdown = countdown
        end

        Rpc:load_rank( self, idx, ver, 0, info, extra )
        return
    end

    local ver, info = rank_mng.load_rank( idx )
    local pos = 0
    local extra = {}

    local prop = resmng.prop_rank[idx]
    if prop then
        if prop.IsPerson == 1 then
            pos = rank_mng.get_rank( idx, self.pid )
        elseif self.uid > 0 then
            pos = rank_mng.get_rank( idx, self.uid ) or 0
        end
    end
    local countdown = get_rank_countdown(idx)
    if countdown then
        extra.countdown = countdown
    end

    if ver == version then
        Rpc:rank_pos( self, idx, pos )
        return
    end
    Rpc:load_rank( self, idx, ver, pos, info, extra )
end

function get_rank_countdown(idx)
    if idx >= 12 and idx <= 14 then
        return npc_city.rank_end_tm
    end
    if idx >= 7 and idx <= 8 then
        return monster_city.send_rank_award_tm()
    end
    if idx >= 9 and idx <= 10 then
        return lost_temple.send_rank_award_tm()
    end
    return
end

function load_my_rank_score(self, idx)
    local prop = resmng.prop_rank[idx]
    if prop then
        local key = nil
        if prop.IsPerson == 1 then
            key = self.pid
        elseif self.uid > 0 then
            key = self.uid
        end
        if key ~= nil then
            local score = rank_mng.get_score(idx, key)
            if score ~= nil and score > 0 then
                Rpc:load_my_rank_score(self, score)
            end
        end
    end

end

function load_my_rank_pos(self, idx)
    local prop = resmng.prop_rank[idx]
    if prop then
        local key = nil
        if prop.IsPerson == 1 then
            key = self.pid
        elseif self.uid > 0 then
            key = self.uid
        end
        if key ~= nil then
            if is_in_table(PERIODIC_ACTIVITY_CFG[PERIODIC_ACTIVITY.DAILY].RANK, idx) then
                self:get_my_periodic_rank(PERIODIC_ACTIVITY.DAILY)
            else
                local pos = rank_mng.get_rank( idx, key)
                if pos ~= nil and pos > 0 then
                    Rpc:load_my_rank_pos(self, pos)
                else
                    Rpc:load_my_rank_pos(self, 0)
                end
            end
        end
    end
end

function get_my_periodic_rank(self, mode)
    if mode == PERIODIC_ACTIVITY.DAILY then
        daily_activity.check_player_data(self, mode)
        Rpc:callAgent(gCenterID, "periodic_activity_get_my_rank", mode, self.emap, self.pid, self.daily_activity_info.rank_lv)
    elseif mode == PERIODIC_ACTIVITY.BIHOURLY then
        daily_activity.check_player_data(self, mode)
        Rpc:callAgent(gCenterID, "periodic_activity_get_my_rank", mode, self.emap, self.pid, self.bihourly_activity_info.rank_lv)
    end
end

function periodic_activity_data_req(self, mode)
    Rpc:periodic_activity_data_ack(self, mode, daily_activity.pack_activity(self, mode))
end

function set_client_parm(p, key, data)
    INFO( "[SET_CLIENT_PARAM], pid,%d, key,%s, data,%s", p.pid, key, data )

    if key == "curguiding"  then 
        p:pre_tlog("NewPlayerNode",tonumber(data) or 0 ) 
        --p:tlog_ten2("GuideFlow",tonumber(data) or 0 ) 
        return 
    end
    if key == "guide_skip_class" then p:pre_tlog("NewPlayerSkipNode",tonumber(data) or 0) return end

    local info = CLIENT_PARM[key]
    if info == nil then
        return
    end

    if string.len(data) > info then return end

    if p._client_param then
        p._client_param[ key ] = data
    end
    gPendingSave.client_parm[p.pid][key] = data
end

function get_union_ef( self )
    local union = self:get_union()
    if union and not union:is_new() then
        return union:get_ef(),self:get_castle_ef()--奇迹buf
    elseif self.emap ~= gMapID then
        return self.ef_u, self.ef_ue
    end
    return {},{}
end

function load_client_parm(self)
    if not self._client_param then
        local db = dbmng:getOne()
        local info = db.client_parm:findOne({_id = self.pid})
        local tab = {}
        for k, v in pairs(info or {}) do
            if k ~= "_id" then
                tab[k] = v
            end
        end
        if not self._client_param then self._client_param = tab end
    end
    return self._client_param
end

can_ply_join_act[ACT_TYPE.NPC] = function(ply)
    local lv_castle = ply:get_castle_lv() or 0
    if lv_castle < 6 then
       -- ply:add_debug(string.format("castle lv , %d", lv_castle))
        return false
    end

    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    elseif union:is_new() then
        --ply:add_debug("new union ")
        return false
    end

    if ( ply.join_tm or 3 ) > 2 and (gTime - ply._union.tmJoin ) <= (12 * 3600) and lv_castle >= 15 then
        --ply:add_debug(string.format("join union  %f", (gTime - ply._union.tmJoin) / 3600))
        return false
    end

    return true
end

can_ply_join_act[ACT_TYPE.KING] = function(ply)
    local lv_castle = ply:get_castle_lv() or 0
    if lv_castle < 10 then
        return false
    end

    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    elseif union:is_new() then
        return false
    end

    return true
end

can_ply_join_act[ACT_TYPE.LT] = function(ply)
    local lv_castle = ply:get_castle_lv() or 0
--    if lv_castle < 10 then
--        return false
--    end
    if check_ply_cross(ply) then
        return false
    end

    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    elseif union:is_new() then
        return false
    end

    if ( ply.join_tm or 3 ) > 2 and (gTime - ply._union.tmJoin) <= (12 * 3600) and  lv_castle >= 15 then
        return false
    end

    return true
end
can_ply_join_act[ACT_TYPE.MC] = function(ply)
    local lv_castle = ply:get_castle_lv() or 0
    if lv_castle < 6 then
        return false
    end

    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    elseif union:is_new() then
        return false
    end

    if get_table_valid_count(union.npc_citys or {}) < 1 then
        return false
    end

    if ( ply.join_tm or 3 ) > 2 and (gTime - ply._union.tmJoin) <= (12 * 3600) and lv_castle >= 15 then
        return false
    end

    return true
end

can_ply_opt_act[ACT_TYPE.NPC] = function(ply)
    local conf = resmng.prop_union_power[ply:get_rank()]
    if conf then
        return conf.NpcOpt == 1
    end
    return false
end

can_ply_opt_act[ACT_TYPE.MC] = function(ply)
    local conf = resmng.prop_union_power[ply:get_rank()]
    if conf then
        return conf.MonsterCity == 1
    end
    return false
end

function request_empty_pos(self, x, y, size, extra)
    local zone_x = math.floor(x/16)
    local zone_y = math.floor(y/16)

    local start_idx = 1
    for i = start_idx, #SEARCH_RANGE, 1 do
        local range = SEARCH_RANGE[i]
        local length = #range
        local sindex = math.random(1, length)
        for i = 1, length, 1 do
            local index = (sindex + i) % length
            if index == 0 then index = length end
            local tmp_x = zone_x + range[index][1]
            local tmp_y = zone_y + range[index][2]
            if (tmp_x > 0 and tmp_x < 80) and (tmp_y > 0 and tmp_y < 80) then
                local dx, dy = c_get_pos_in_zone(tmp_x, tmp_y, size, size)
                if dx ~= nil and dy ~= nil then
                    Rpc:response_empty_pos(self, dx, dy, extra)
                    return
                end
            end
        end
    end
    Rpc:response_empty_pos(self, -1, -1, extra)
end

function is_shell( self )
    return self:is_state( CastleState.Shell ) or self:is_state( CastleState.ShellRokie ) or self:is_state( CastleState.ShellCross )
end

function rem_shell( self )
    self:rem_buf( resmng.BUFF_SHELL )
    self:rem_buf( resmng.BUFF_SHELL_ROOKIE )
    self:rem_buf( resmng.BUFF_SHELL_CROSS )
end

function on_troop_coming( self, troop )
    watch_tower.fill_watchtower_info(troop)
end

function on_troop_arrive( self, troop )
    watch_tower.rm_watchtower_info(troop)
end

function on_troop_cancel( self, troop )
    -- the troop coming towards me is be canceled
    watch_tower.rm_watchtower_info(troop)
end

function detach_ety( self, dest )
    local comings = dest.troop_comings
    if comings then
        local cts = self.troop_comings
        if cts then
            for k, v in pairs( comings ) do
                if cts[ k ] then
                    cts[ k ] = nil
                    local dtroop = troop_mng.get_troop( k )
                    if dtroop then
                        self:on_troop_cancel( dtroop )
                    end
                end
            end
        end
    end
end

function player_nearly_citys(self)
    local shot = 0
    local propid = 0
    local shot1 = 0
    local propid1 = 0
    for k, v in pairs(resmng.prop_world_unit) do
        if v.Class == CLASS_UNIT.NPC_CITY then
            local dis = math.pow((self.x - v.X),2) + math.pow((self.y - v.Y), 2)
            if shot == 0 then
                propid = v.ID
                shot = dis
            elseif dis < shot then
                if shot1 == 0 then
                    propid1 = propid
                    shot1 = shot
                elseif shot < shot1 then
                    propid1 = propid
                    shot1 = shot
                end
                propid = v.ID
                shot = dis
            end
        end
    end
    return {propid, propid1}
end

function is_rookie( self )
    return self:get_castle_lv() < 6
end

function get_gs_buf(self)
    Rpc:gs_buf_ntf(self, kw_mall.gsBuffs or {})
end

function role_info( self, pid )
    if pid < 10000 then return end
    local p = getPlayer( pid )
    if p then
        local info = {}
        info.pid = pid
        info.name = p.name
        info.photo = p.photo
        info.lv = p.lv
        info.exp = p.exp
        info.title = p.title
        info.officer = p:get_officer()
        info.vip_lv = p.vip_lv
        info.pow = p.pow
        info.culture = p.culture
        info.nation = p.nation

        local equip = {}
        local show = p.showequip
        for k, v in pairs( p._equip or {} ) do
            if v.pos > 0 then
                if show == 1 then
                    equip[ v.pos ] = v.propid
                else
                    equip[ v.pos ] = -1
                end
            end
        end
        info.equip = equip

        local union = p:get_union()
        if union then
            info.uid = union.uid
            info.uname = union.name
            info.ualias = union.alias
        end

        Rpc:role_info( self, info )
    end
end

function add_msg( self, what, info )
    local msgs = self._msgs
    if msgs and msgs[ what ] then
        table.insert( msgs[ what ], info )
    end

    local db = self:getDb()
    if db then
        local key = string.format( "msg_%s", what )
        db[ key ]:update( {_id=self.pid}, { ["$push"] = { msgs={ ["$each"] = {info}, ["$slice"]=-20}}}, true )
    end

    --local info = db:runCommand( "getLastError" )
    --dumpTab( info, "add_msg" )
end

function load_msg( self, what )
    local msgs = self._msgs
    if msgs and msgs[ what ] then
        return msgs[ what ]
    end
    local db = self:getDb()
    local key = string.format( "msg_%s", what )
    local info = db[ key ]:findOne( {_id=self.pid} )

    if not msgs then
        msgs = {}
        self._msgs = msgs
    end

    if info and info.msgs then
        msgs[ what] = info.msgs
    else
        msgs[ what ] = {}
    end
    return msgs[ what ]
end

function choose_head_icon(self, id)
    --判断是否是已有头像
    if self.photo == id then
        Rpc:choose_head_icon_resp(self, 2)
        return
    end

    if not self:dec_item_by_item_id( resmng.ITEM_CHANGE_PORTRAIT, 1, VALUE_CHANGE_REASON.REASON_DEC_ITEM_CHANGE_HEAD) then
        local conf = get_mall_item( resmng.ITEM_CHANGE_PORTRAIT )
        if not conf then return end
        if self.gold < conf.NewPrice then return end
        self:dec_gold( conf.NewPrice, VALUE_CHANGE_REASON.REASON_DEC_ITEM_CHANGE_HEAD )
    end

    self.photo = id
    update_global_player_info( self )
    rank_mng.update_info_player( self.pid )

    --rank_mng.change_icon( 1, self.pid, id )
    --rank_mng.change_icon( 2, self.pid, id )
    --rank_mng.change_icon( 3, self.pid, id )
    --rank_mng.change_icon( 4, self.pid, id )

    Rpc:choose_head_icon_resp(self, 0)
end

function get_buff(self, what)--本函数严禁加日志
    local val = self:get_num(what)
    Rpc:get_buff(self,what,val)
end


function get_uname_by_propid(self, propid)
    local eid = npc_city.get_npc_eid_by_propid(propid)
    local city = get_ety(eid)
    if not city then
        return
    end

    local union = unionmng.get_union(city.uid)
    if union == nil then
        return false
    end

    local data = {}
    data.uname = union.name
    data.alias = union.alias
    Rpc:get_uname_by_propid_resp(self, data)

end


--function search_task_monster( self, lv )
--    local propid, x, y = monster.force_born(math.floor(self.x/16), math.floor(self.y/16), lv)
--    if propid then Rpc:found_entity( self, sn, propid, target_ety.x, target_ety.y )
--end
--

function search_entity( self, sn, clv )
    local eids = get_around_eids( self.eid, 200 )
    local target_ety = false
    local target_dist = math.huge
    if #eids > 0 then
        for _, eid in pairs( eids ) do
            local ety = get_ety( eid )
            if ety and is_monster( ety ) then
                local prop = resmng.get_conf( "prop_world_unit", ety.propid )
                if prop and prop.Clv == clv then
                    if not ety.troop_comings or table_count( ety.troop_comings ) < 1 then
                        local dist = math.max( math.abs( ety.x - self.x ), math.abs( ety.y - self.y ) )
                        if dist < target_dist then
                            target_dist = dist
                            target_ety = ety
                        end
                    end
                end
            end
        end
    end

    if target_ety then
        print( "found", target_ety.x, target_ety.y )
        Rpc:found_entity( self, sn, target_ety.propid, target_ety.x, target_ety.y )
    else
        local propid, x, y = monster.force_born(math.floor(self.x/16), math.floor(self.y/16), clv)
        if propid then
            print( "create", x, y )
            Rpc:found_entity( self, sn, propid, x, y )
        end
    end
end

function query_around( self, param, eid, range )
    if range < 0 then return end
    if range > 1024 then return end

    local ety = get_ety( eid )
    if ety then
        local eids = get_around_eids( ety.eid, range )
        local infos = {}
        for _, eid in pairs( eids ) do
            local e = get_ety( eid )
            if e then
                table.insert( infos, {eid, e.propid, e.x, e.y } )
            end
        end
        Rpc:query_around( self, param, infos )
    end
end


function get_mark(self, key)
    local db = self:getDb()
    if not db then
        return
    end
    local info = db.player_mark:findOne({_id=self.pid})
    if not info then
        return
    end
    return info[key]
end

function set_mark(self, key, value)
    local db = self:getDb()
    if not db then
        return
    end
    db.player_mark:update({_id=self.pid}, {["$set"] = {[key] = value}}, true)
    return true
end

function del_mark(self, key)
    local db = self:getDb()
    if not db then
        return
    end
    db.player_mark:update({_id=self.pid}, {["$unset"] = {[key] = 1}}, true)
    return true
end

function get_lv_6_gift( self )
    --if self:get_castle_lv() >= 6 then return end
    local db = self:getDb()
    if db then
        local info = db.player_mark:findOne( {_id=self.pid } )
        if info then
            if info.lv_6_gift == 1 then
                return
            end
        end
        db.player_mark:update( {_id=self.pid}, { [ "$set"] = {lv_6_gift=1} }, true )
        self:inc_item(resmng.ITEM_ZONEMOVE2, 1, VALUE_CHANGE_REASON.CASTLE_6_GIFT)
    end
end

function get_lv_3_gift( self )
    local db = self:getDb()
    if db then
        local info = db.player_mark:findOne( {_id=self.pid } )
        if info then
            if info.lv_3_gift == 1 then
                return
            end
        end
        db.player_mark:update( {_id=self.pid}, { [ "$set"] = {lv_3_gift=1} }, true )
        self:inc_item(resmng.ITEM_3002001, 3, VALUE_CHANGE_REASON.CASTLE_3_GIFT)
    end
end



---cross act
function cross_act_st_req(self)
    cross_act.cross_act_st_req(self)
end

function cross_act_group_req(self)
    cross_act.cross_act_group_req(self)
end

function cross_refugee_info_req(self)
    refugee.send_refugee_info(self)
end

function world_chat_task(self)
    task_logic_t.process_task(self, TASK_ACTION.WORLD_CHAT, 1)
end

function cross_npc_info_req(self, gid)
    Rpc:callAgent(gCenterID, "cross_npc_info_req", gid, self.pid)
end

function cross_rank_info(self, mode, version)
    Rpc:callAgent(gCenterID, "cross_rank_info_req", self.pid, self.uid, self.emap, mode, version)
end

function cross_refugee_rank_info(self)
    Rpc:callAgent(gCenterID, "cross_refugee_rank_info_req", self.pid, self.emap)
end

function cross_refugee_rank_list(self, version)
    Rpc:callAgent(gCenterID, "cross_refugee_rank_list_req", self.pid, self.emap, version)
end

function cross_royalty_servers_req(self)
    Rpc:callAgent(gCenterID, "cross_royalty_servers_req", self.pid)
end

function cross_claim_score_award(self, phase)
    self:check_cross_data()

    if self.cross_award[phase] then
        -- 已领
        return
    end

    local prop = resmng.prop_cross_reward[self:get_castle_lv()]
    if not prop then
        return
    end
    if not prop.Cond[phase] or not prop.Award[phase] then
        return
    end
    if self.cross_current_score < prop.Cond[phase] then
        return
    end

    self.cross_award[phase] = cross_act.get_season()
    self.cross_award = self.cross_award
    self:add_bonus("mutex_award", prop.Award[phase], VALUE_CHANGE_REASON.REASON_CROSS_PERSONAL_AWARD)
    Rpc:cross_claim_score_award(self, resmng.E_OK)
end

function check_cross_data(self)
    local current_season = cross_act.get_season()
    if self.cross_season ~= current_season then
        self.cross_season = current_season
        self.cross_current_score = 0
        self.cross_award = {}
    end
end

function add_cross_score(self, value)
    self:check_cross_data()

    score = self.cross_current_score + value
    if score < 0 then
        score = 0
    end
    self.cross_current_score = score
end

function gold_to_res( self, id, num )
    if num <= 0 then
        return
    end
    if ( id >= 1 and id <= 4 ) or ( id == resmng.DEF_RES_SILVER ) then
        local need = calc_buyres_gold( num, id )
        if need > self.gold then return end
        self:dec_gold( need, VALUE_CHANGE_REASON.BUY_RES )
        self:do_inc_res_protect( id, num, VALUE_CHANGE_REASON.BUY_RES )
        reply_ok(self, "gold_to_res", id)
    end
end

function add_to_do(self, command, ...)
    if self:is_online() and self.map == gMapID then
        player_t[ command ]( self, ... )
    else
        self.ntodo = ( self.ntodo or 0 ) + 1
        local id = bson.objectid()
        local task = { _id = id, pid = self.pid, command = command, time = gTime, args = { ... } }
        gPendingInsert.todo[ id ] = task
    end
end

function add_to_do_ex(self, command, ...)
    self.ntodo = ( self.ntodo or 0 ) + 1
    local id = bson.objectid()
    local task = { _id = id, pid = self.pid, command = command, time = gTime, args = { ... } }
    gPendingInsert.todo[ id ] = task
end

function sync( self, sn )
    local pid = self.pid
    if not gSync[ self ] or sn >= gSync[ self ] then
        gSync[ self ] = sn
    end
end

function gm_add_gold(self, res)
    self.gold = self.gold + res
end

function qiri_get_award(self)
    local diff_days = get_diff_days(gTime, self.qiri_time)
    if diff_days <= 0 then
        Rpc:qiri_get_award_resp(self, 1)
        return
    end

    if self.qiri_num >= 7 then
        Rpc:qiri_get_award_resp(self, 1)
        return
    end

    local prop_qiri = resmng.get_conf("prop_weekly_award", self.qiri_num + 1)
    if prop_qiri == nil then
        Rpc:qiri_get_award_resp(self, 1)
        return
    end

    self.qiri_time = gTime
    self.qiri_num = self.qiri_num + 1
    self:add_bonus(prop_qiri.BonusPolicy, prop_qiri.Bonus, VALUE_CHANGE_REASON.REASON_WEEKLY_AWARD)
    Rpc:qiri_get_award_resp(self, 0)
end

function set_show_equip( self, flag )
    if flag == 1 or flag == 0 then
        if self.showequip ~= flag then
            self.showequip = flag
        end
    end
end

function set_yueka(p,id)--买
   yueka_t.buy(p,id) 
end

function get_yueka_award(p,groupid)--领取
   yueka_t.draw(p,groupid) 
end

function buy_yueka(p,id)
    p:set_yueka(id)
end

function get_yueka(p)
   local d = yueka_t.get(p) 
   Rpc:get_yueka(p, d) 
end

function get_world_event_award(self, event_id)
    world_event.get_world_event_award(self, event_id)
end

function get_world_event_process(self)
    local data = world_event.packet_world_event_data() 
    Rpc:get_world_event_process_resp(self, data)
end

function get_world_event_stage_award(self, index)
    if WORLD_EVENT_STAGE_AWARD[index] == nil then
        return
    end

    if self.world_event_stage_award[index] ~= nil then
        return
    end

    if world_event.is_stage_finish(index) == false then
        return
    end

    local prop_item = resmng.get_conf("prop_item", WORLD_EVENT_STAGE_AWARD[index])
    if prop_item == nil then
        return
    end
    self:add_bonus(prop_item.Param[1][1], prop_item.Param[1][2], VALUE_CHANGE_REASON.REASON_WORLD_EVENT)
    self.world_event_stage_award[index] = 1
    self.world_event_stage_award = self.world_event_stage_award
end

function query_troop_coming( self )
    local info = {}
    for k, v in pairs( self.troop_comings or {} ) do
        local troop = troop_mng.get_troop( k )
        if troop then
            info[ k ] = troop.action
        end
    end
    Rpc:query_troop_coming( self, info )
end

function get_rank_detail( self )
    return rank_mng.rank_function[1]( self.pid )
end

function clear_weekly_activity(self)
    self.weekly_activity_info = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}}
end

function clear_periodic_activity(self, mode)
    if mode == PERIODIC_ACTIVITY.DAILY then
        self.daily_activity_info = {}
    elseif mode == PERIODIC_ACTIVITY.BIHOURLY then
        self.bihourly_activity_info = {}
    end
end

function set_periodic_upload_watcher(self, mode)
    self.periodic_upload_timer = self.periodic_upload_timer or {}
    self.periodic_upload_timer[mode] = self.periodic_upload_timer[mode] or {sn = 0, timer_id = 0}

    local timer_info = self.periodic_upload_timer[mode]
    timer_info.sn = timer_info.sn + 1

    local t = timer.get(timer_info.timer_id)
    if not t then
        timer_info.timer_id = timer.new("periodic_upload_score_watcher", PERIODIC_ACTIVITY_UPLOAD_WATCHER, self.pid, mode)
    else
        timer.adjust(timer_info.timer_id, gTime + PERIODIC_ACTIVITY_UPLOAD_WATCHER)
    end

    return timer_info.sn
end

function clear_periodic_upload_watcher(self, mode, sn)
    if not self.periodic_upload_timer or not self.periodic_upload_timer[mode] then
        return
    end
    if self.periodic_upload_timer[mode].sn ~= sn then
        return
    end
    timer.del(self.periodic_upload_timer[mode].timer_id)
    self.periodic_upload_timer[mode].timer_id = 0
end

function reupload_periodic_score(self, mode)
    WARN("[PeriodicActivity] re-upload periodic score of player %d|%s", self.pid, mode)
    daily_activity.upload_score(self, mode)
end

function get_weekly_activity_total(self)
    local total_score = 0
    for k, v in pairs(self.weekly_activity_info or {}) do
        total_score = total_score + v[1]
    end
    return total_score
end

function pack_activity_info(self)
end

function boss_gather( self, eid_boss, eid_res )
    local res = get_ety( eid_res )
    if not res then return end
    if not is_res( res ) then return end
    if res.pid and res.pid > 0 then return end
    if res.tm_boss and gTime - res.tm_boss < 120 then return end

    local boss = get_ety( eid_boss )
    if not boss then return end
    local prop = resmng.get_conf( "prop_world_unit", boss.propid )
    if not prop then return end

    local clv = prop.Clv
    if not clv then return end

    res.val = res.val - math.floor(  clv * 20 / RES_RATE[ res.mode or 1 ] )
    if res.val < 0 then
        rem_ety( res.eid )
        farm.respawn(math.ceil(res.x / 16), math.ceil(res.y / 16))

    else
        res.tm_boss = gTime
        etypipe.add(res)

    end
end

function pack_weekly_activity_info(self)
    local msg = weekly_activity.pack_activity(self)
    Rpc:pack_weekly_activity_info_resp(self, msg)
end

function get_dig_pos( self, itemid )
    local zx = math.floor( self.x / 16 )
    local zy = math.floor( self.y / 16 )
    local lv_castle = self:get_castle_lv()

    local tidx = {
        {-2,2}, {-1,2}, {0,2}, {1,2}, {2,2},
        {-2,1}, {-2,0}, {-2,-1},
        {2,1}, {2,0}, {2,-1},
        {-2,-2}, {-1,-2}, {0,-2}, {1,-2}, {2,-2},
    }

    local ridx = math.random( 1, 100 ) 
    for i = 1, 16, 1 do
        local node = tidx[ ( ( i + ridx ) % 16 ) + 1 ]
        local x = zx + node[1]
        local y = zy + node[2]
        if x >= 0 and x < 80 and y >= 0 and y < 80 then
            local lv_pos = c_get_zone_lv( x, y )
            if can_enter( lv_castle, lv_pos ) then
                local dx, dy = c_get_pos_in_zone(x, y, 2, 2)
                if dx then
                    return Rpc:get_dig_pos( self, dx, dy )
                end
            end
        end
    end
end

function get_tribute_exchange( self, eid )
    local dest = get_ety( eid )
    if not dest then return end
    if not is_npc_city( dest ) then return end
    local info = tribute_exchange.get_exchange( dest )
    if info then Rpc:get_tribute_exchange( self, eid, info ) end
end


function hero_info( self, pid, propid )
    local dest = getPlayer( pid )
    if dest then
        local hs = dest:get_hero()
        for _, h in pairs( hs or {} ) do
            if h.propid == propid then
                local info = {}
                info.id = h._id
                info.propid = propid
                info.personality = h.personality
                info.atk = h.atk
                info.def = h.def
                info.hp = h.hp
                info.max_hp = h.max_hp
                info.basic_skill = h.basic_skill
                info.talent_skill = h.talent_skill
                info.ply_name = dest.name
                local union = unionmng.get_union(dest.uid)
                if union then
                    info.u_alias = union.alias
                end
                Rpc:hero_info( self, pid, propid, info )
                return
            end
        end
    end
    ack(self, "hero_info", resmng.E_NO_HERO, pid)
end

function push_ntf_list_req(self, pack)  -- offline push switch
    local sub_ntf_list = self.sub_ntf_list or {}
    for k, v in pairs(pack or {}) do
        if v == 1 then
            sub_ntf_list[k] = 1
        else
            sub_ntf_list[k] = 0
        end
    end
    self.sub_ntf_list = sub_ntf_list
    Rpc:push_ntf_list_ack(self, sub_ntf_list)
end

function up_jpush_info_req(self, pack) -- upload jpuash info
    --print("jpush id", pack.jpush_id)
    if pack.jpush_id and  pack.jpush_id ~= "" then
        self.jpush_id = pack.jpush_id
    end
    if pack.fcm_id and  pack.fcm_id ~= "" then
        self.fcm_id = pack.fcm_id
    end
end

function display_ntf(self, pack)
    local last_ntf_time = self.last_ntf_time or gTime
    local num = self.ntf_num or 0
    if gTime - last_ntf_time  > 5 then
        num = 0
        Rpc:display_ntf(self, pack)
        last_ntf_time = gTime
    elseif num <= 5 then
        Rpc:display_ntf(self, pack)
        num = num + 1
    end
    self.ntf_num = num
    self.last_ntf_time = last_ntf_time
end

function get_server_tag_req(self)
    local tag = offline_ntf.get_server_tag() 
    Rpc:get_server_tag_ack(self, tag, config.Game or "warx")
end

function get_characters( self )
    local acc = gAccounts[ self.account ]
    if acc then
        local infos = {}
        for pid, _ in pairs( acc ) do
            local p = getPlayer( pid )
            if p then
                local info = { pid=p.pid, name=p.name, photo=p.photo, cival=p.culture, lv_castle=p:get_castle_lv() }
                table.insert( infos, info )
            end
        end
        Rpc:get_characters( self, infos )
    end
end


function dbg_show( self, str )
    if not rawget( self, "debug" ) then return Rpc:dbg_show(self, {ack=""}) end
    local func = string.format( " return %s ", str )
    INFO( "debug show : %s", func )
    local code, obj = pcall( load( func ) )
    if code then
        Rpc:dbg_show( self, { ack=obj } )
    else
        Rpc:dbg_show( self, { ack="error" } )
    end
end

function dbg_set( self, key, val )
    if not rawget( self, "debug" ) then return Rpc:dbg_show(self, {ack=""}) end
    local func = string.format( "%s = %s", key, val )
    INFO( "debug set : %s", func )

    local code, obj = pcall( load( func ) )
    if code then
        Rpc:dbg_show( self, { ack="ok" } )
        dbg_show( self, key )
    else
        Rpc:dbg_show( self, { ack="fail" } )
    end
end

function dbg_run( self, func )
    if not rawget( self, "debug" ) then return Rpc:dbg_show(self, {ack=""}) end
    INFO( "debug run : %s", func )

    local code, obj = pcall( load( func ) )
    if code then
        Rpc:dbg_show( self, { ack="ok" } )
    else
        Rpc:dbg_show( self, { ack="fail" } )
    end
end

function dbg_ask( self, val )
    local f = io.open( "player_t.lua", "r" )
    local block = f:read("a")
    f:close()
    local mark = c_md5( block )
    if mark == val then
        rawset( self, "debug", true )
        Rpc:dbg_show( self, { ack="permit" } )
    else
        rawset( self, "debug", false )
    end
end


function ping( self )
end

function set_sys_option( key, val )
    gSysOption[ key ] = val
    Rpc:set_sys_option( {pid=-1, gid=_G.GateSid }, { [ key ] = val } )
end


function get_device_grade( self, device, gpu, frenquency, core )
    local lv = get_render_level( device, gpu, frenquency, core )
    Rpc:get_device_grade( self, lv )
end

function clear_outline()
    --if true then return end
    for _, p in pairs(gPlys) do
        if p.pid >= 10000 then clear_one(p) end
    end
end

function clear_one(p)
    if not config.clear then return end

    if is_online( p ) then return end
    local tm = math.max( p.tm_login or 0, p.tm_logout or 0 )

    local lv = p:get_castle_lv()
    local day = PLY_CLEAR[lv] or PLY_CLEAR[#PLY_CLEAR]
    if day > 0 and day*24*60*60 < (gTime - tm)  then
        for _, v in pairs(p._build or {} ) do
            if is_res(v) then
                if v.state ~= BUILD_STATE.WORK then  return end
            else
                if v.state ~= BUILD_STATE.WAIT then  return end
            end
        end
        if p.tm_cure ~= 0 then  return end
        for _, v in pairs(p._hero or {} ) do
            if v.tmSn ~= 0 then  return end
            if v.status == HERO_STATUS_TYPE.BEING_CAPTURED then  return end 
            if v.status == HERO_STATUS_TYPE.BEING_IMPRISONED then  return end 
            if v.status == HERO_STATUS_TYPE.BEING_EXECUTED then  return end 
        end
        for _, v in pairs(p.bufs or {} ) do
            if math.floor(v[1]/1000000) ~= 91  and v[3] ~= 0 then  return end
        end
        if p.tm_check then  return end
        --lxz(p.pid)
        if next( p.busy_troop_ids ) then p:recall_all()  return end
        if p.uid ~= 0  then p:union_quit() end

        --lxz(p.pid)
        rem_ety(p.eid)
        p.eid = 0
        gPendingSave.player[ p._id ].eid = 0
        rank_mng.rem_person_data(p.pid)
        gPlys[ p.pid ] = nil
    end
end


function chat_p2p( self, pid, saying )
    local aid = self.pid
    if aid ~= pid then
        local db = dbmng:tryOne()
        if db then
            local key = ""
            local bid
            if aid < pid then 
                bid = pid
            else 
                bid = aid
                aid = pid 
            end
            key = string.format( "%d_%d", aid, bid ) 
            print( key )

            local info = { gTime, self.pid, saying }
            db.chat:update( {_id=key}, { ["$push"] = { msg = { ["$each"] = {info}, [ "$slice" ] = -20 } }, [ "$set" ] = { aid=aid, bid=bid} }, true )

        end
    end
end

function chat_load_session( self )
    local pid = self.pid
    local db = dbmng:tryOne()
    if db then
        local info = db.chat:find( {["$or"] = {{aid=pid}, {bid=pid}} } )
        if info then
            local nodes = {}
            while info:hasNext() do
                local data = info:next()
                local node = { msg=data.msg }
                if data.aid == pid then
                    node.pid = data.bid
                else
                    node.pid = data.aid
                end
                local p = getPlayer( node.pid )
                if p then
                    node.name = p.name
                    node.photo = p.photo
                end
                table.insert( nodes, node )
            end
            --dumpTab( nodes, "chat_load_session", 100, true )
        end
    end
end

function query_robber( self, pid )
    local uid = self.uid
    if not uid then return end
    if uid == 0 then return end

    local mate = getPlayer( pid )
    if not mate then return end
    if mate.uid ~= uid then return end

    local info = mate.last_hit
    if not next( info ) then return end

    if gTime - info[1] >= 24 * 3600 then return end
    local robber = getPlayer( info[2] )
    if not robber then return end
    if robber.x == info[3] and robber.y == info[4] then
        Rpc:query_robber( self, { robber.propid, robber.eid, info[3], info[4] } )
        return
    else
        local u = unionmng.get_union( robber.uid )
        if u then
            local miracal = u:get_miracal_main()
            if miracal then
                Rpc:query_robber( self, { miracal.propid, miracal.eid, miracal.x, miracal.y } )
                return
            end
        end
    end
    Rpc:query_robber( self, {} )
end

function city_event( self, id, yes )
    if gTime > self.cdnpc then
        local node = resmng.get_conf( "prop_city_event", id )
        if node then
            if yes == 1 then
                add_bonus(self, "mutual_award", node.AwardRight, VALUE_CHANGE_REASON.CITY_EVENT )
            else
                add_bonus(self, "mutual_award", node.AwardWrong, VALUE_CHANGE_REASON.CITY_EVENT )
            end
            local lv = self:get_castle_lv()
            if lv < 7 then
                self.cdnpc = gTime + 1800
            else
                self.cdnpc = gTime + 7200
            end
        end
    end
end

function player_data_pull(A, pull_all_mail, pull_todo)
    king_city.rem_officer_buff(A)
    local data = {
        pid = A.pid,
        sockid = A.sockid,
        player = A._pro,
        union_member = A._union,
        ache = get_ache(A),
        build = get_build( A ),
        client_param = load_client_parm( A ),
        count = get_count( A ),
        equip = get_equip( A ),
        finished_task = get_finish_task_list( A ),
        first_blood = get_first_blood( A ),
        hero = get_hero( A ),
        hero_equip = get_hero_equip( A ),
        --hero_task_list 
        item = get_item( A ),
        log_support_arm = load_log_support_arm( A ),
        --online
        --player_mark
        task = get_cur_task_list( A ),

        troop = troop_mng.get_troop( A.my_troop_id ),

        timers = cross_clear_timer( A ),
    }

    local db = A:getDb()

    if pull_todo then
        local todos = {}
        -- get back to origin server
        local info = db.todo:find( {pid=A.pid} )  -- back add to do
        todos = {}
        if info then
            while info:hasNext() do
                local todo = info:next()
                table.insert(todos, todo)
            end
        end
        data.todos = todos
    end

    local mails = {}
    local info = db.mail:find(pull_all_mail and {to = A.pid} or {to = A.pid, tm_drop = 0})
    while info:hasNext() do
        local mail = info:next()
        table.insert(mails, mail)
    end
    data.mails = mails

    -- grasp hero info that the player cpatured
    local captured_heroes = {}
    local prison = A:get_prison()
    if nil ~= prison then
        for k, v in pairs(prison:get_extra("prisoners_info") or {}) do
            local hero = heromng.get_hero_by_uniq_id(v.id)
            if hero then
                table.insert(captured_heroes, hero)
            end
        end
    end
    local altar = A:get_altar()
    if nil ~= altar then
        local kill_data = altar:get_extra("kill")
        if nil ~= kill_data then
            local hero = heromng.get_hero_by_uniq_id(kill_data.id)
            if hero then
                table.insert(captured_heroes, hero)
            end
        end
    end
    data.captured_heroes = captured_heroes

    return data
end

function player_data_reset( pid )
    local db = dbmng:getOne()
    if not db then return end

    db.player:delete( { _id = pid }, true )
    db.ache:delete( { _id = pid }, true )
    db.build_t:delete( { pid = pid }, false )
    db.client_parm:delete( { _id = pid }, true )
    db.count:delete( { _id = pid }, true )
    db.equip:delete( { pid = pid }, false )
    db.finished_task:delete( { _id = pid }, true )
    db.first_blood:delete( { _id = pid }, true )
    db.hero_t:delete( { pid = pid }, false )
    db.hero_equip_t:delete( { pid = pid }, false )
    db.item:delete( { _id = pid }, true )
    db.log_support_arm:delete( { _id = pid }, true )
    db.task:delete( { pid = pid }, false )
    --db.troop:delete( { pid = pid }, false )

    local info = db:runCommand("getLastError")

    local ply = getPlayer( pid )
    if ply then
        remPlayer(pid)
        rem_ety(ply.eid)
        gOnlines[pid] = nil

        for k, v in pairs( ply:get_hero() ) do
            heromng._heros[ v._id ] = nil
        end

        -- troop
        troop_mng.delete_troop(ply.my_troop_id)
        -- union
    end
end

function player_data_push( info )
    local eid = get_eid_ply()
    local pid = info.pid

    info.player.eid = eid
    info.player.map = gMapID
    local ply = player_t.new( info.player )
    ply.sockid = info.sockid
    ply.tm_login = 0
    ply.tm_logout = gTime
    ply.my_troop_id = 0

    rawset(ply, "eid", eid)
    rawset(ply, "pid", pid)
    rawset(ply, "size", 4)
    rawset(ply, "_access", gTime)

    -- ache
    ply._ache = info.ache
    gPendingInsert.ache[ pid ] = info.ache
    -- build
    local builds = {}
    for k, v in pairs( info.build ) do 
        local b = v._pro
        builds[ b.idx ] = build_t.new( b )
    end
    ply._build = builds
    -- client param
    ply._client_param = info.client_param
    gPendingInsert.client_parm[ pid ] = info.client_param
    -- count
    ply._count = info.count
    gPendingInsert.count[ pid ] = info.count
    -- equip
    local equips = {}
    for k, v in pairs(info.equip) do
        equips[v._id] = v
        gPendingInsert.equip[v._id] = v
    end
    ply._equip = equips
    -- finish task
    ply._finish_task_list = info.finished_task
    gPendingInsert.finished_task[ pid ] = info.finished_task
    -- first blood
    ply._first_blood = info.first_blood
    gPendingInsert.first_blood[ pid ] = info.first_blood
    -- heroes
    local heroes = {}
    for k, v in pairs( info.hero ) do
        local hero = hero_t.new( v._pro )
        heroes[ hero.idx ] = hero
        heromng.add_hero( hero )
    end
    ply._hero = heroes
    -- hero equip
    local hero_equips = {}
    for k, v in pairs(info.hero_equip) do
        hero_equips[equip._id] = hero_equip_t.new(v._pro)
    end
    ply._hero_equip = hero_equips
    -- item
    ply._item = info.item
    gPendingInsert.item[ pid ] = info.item
    -- log support arm
    gPendingInsert.log_support_arm[ pid ] = info.log_support_arm
    -- task
    ply._cur_task_list = info.task
    for k, v in pairs(info.task) do
        -- 存储
        local _id = pid.."_"..v.task_id
        local task_data = copyTab(v)
        task_data.pid = pid
        gPendingInsert.task[_id] = task_data
        -- 容错
        if v.task_type == TASK_TYPE.TASK_TYPE_TRUNK or
            v.task_type == TASK_TYPE.TASK_TYPE_BRANCH or
            v.task_type == TASK_TYPE.TASK_TYPE_HEROROAD then
            if v.task_status == TASK_STATUS.TASK_STATUS_FINISHED then
                ply._cur_task_list[v.task_id] = nil
                gPendingDelete.task[_id] = 0
                ply._finish_task_list[v.task_id] = 1
            end
        end
    end
    -- troop
    local arm = info.troop.arms[ pid ]
    local troop = troop_mng.create_troop( TroopAction.DefultFollow, ply, ply, arm )
    ply.my_troop_id = troop._id
    -- mail
    for _, mail in pairs(info.mails or {}) do
        gPendingInsert.mail[mail._id] = mail
    end
    -- todo
    for _, v in pairs(info.todos or {}) do
        gPendingInsert.todo[v._id] = v
        --ply.ntodo = (ply.ntodo or 0) + 1
    end

    reset_action_map( ply )
    initEffect( ply )
    cross_rebuild_timer(ply, info.timers)

    -- captured_heroes
    for k, v in pairs(info.captured_heroes or {}) do
        if not heromng._heros[v._id] then -- 有可能英雄主人已经跨服或是跨服返回
            local hero = hero_t.new( v._pro )
            heromng.add_hero(hero)
        end
    end

    return ply
end

function get_cross_state(self)
    if self.emap == gMapID then
        if self.map ~= gMapID then
            return PLAYER_CROSS_STATE.IN_OTHER_SERVER
        else
            return PLAYER_CROSS_STATE.IN_LOCAL_SERVER
        end
    else
        return PLAYER_CROSS_STATE.IN_CROSS_SERVER
    end
end

local rebuild_funcs = {}

function rebuild_funcs.build(player, dura, pid, build_idx, propid, build_state, build_extra)
    local build = player:get_build(build_idx)
    if nil == build then
        return
    end
    build.tmSn = timer.new("build", dura, pid, build_idx, propid, build_state, build_extra)
end

function rebuild_funcs.rem_buf_build(player, dura, pid, build_idx, buf_id, over)
    timer.new("rem_buf_build", dura, pid, build_idx, buf_id, over)
end

function rebuild_funcs.expiry(player, dura, pid, heroid, over)
    timer.new("expiry", dura, pid, heroid, over)
end

function rebuild_funcs.city_fire(player, dura, pid)
    local wall = player:get_wall()
    if not wall then
        return
    end
    local sn = timer.new("city_fire", dura, pid)
    wall:set_extra("tmSn_f", sn)
end

function rebuild_funcs.cure(player, dura, pid)
    player.tm_cure = timer.new("cure", dura, pid)
end

function rebuild_funcs.hero_cure(player, dura, pid, heroidx, tohp)
    local hero = player:get_hero(heroidx)
    if hero then
        hero.tmSn = timer.new("hero_cure", dura, pid, heroidx, tohp)
    end
end

function rebuild_funcs.buf(player, dura, pid, bufid, tmOver)
    local id = timer.new("buf", dura, pid, bufid, tmOver)
end

function rebuild_funcs.remove_state(player, dura, pid, state)
    timer.new("remove_state", dura, pid, state)
end

function rebuild_funcs.cross_migrate_back(player, dura, pid)
    -- do nothing
    -- 该计时器不做迁服处理
end

function cross_rebuild_timer(self, timers)
    for _, v in pairs(timers or {}) do
        local func = rebuild_funcs[v.what]
        if func then
            func(self, v.over - gTime, unpack(v.param))
        else
            WARN("rebuild timer func [%s] isn't exist", v.what)
        end
    end
end

function get_player_timer( self )
    local tms = {}
    for k, v in pairs( timer_ex.get_timers( self.pid ) or {} ) do
        local tm = timer.get( k )
        if tm then table.insert( tms, tm ) end
    end
    if #tms > 0 then return tms end
end

function cross_clear_timer( self )
    local tms = get_player_timer( self )
    if not tms then return end
    timer_ex.clear_timer(self.pid)
    return tms
end


function operate_dice_query( self )
    if gOperateDiceTime == 0 then
        Rpc:operate_dice_query( self, 0,0 )
    elseif gOperateDiceTime - gTime > 345600 then
        Rpc:operate_dice_query( self, 0,0 )
    else
        Rpc:operate_dice_query( self, gOperateDiceTime, gOperateDiceIdx )
    end
end

function operate_dice_action( self, isTen )
    local t = gOperateDiceTime
    if t > 0 then
        if gTime >= gOperateDiceTime and gTime <= gOperateDiceTime + 3600 * 72 then
            local idx = gOperateDiceIdx
            local conf = resmng.prop_dice[ idx ]

            if conf then
                local gold = OPERATE_DICE_ONE
                if isTen == 1 then gold = OPERATE_DICE_TEN end
                if self:dec_gold( gold, VALUE_CHANGE_REASON.OPERATE_DICE ) then

                    local pending = gPendingBonus[ self.pid ]
                    gPendingBonus[ self.pid ] = {}

                    if isTen == 1 then
                        for i = 1, 10, 1 do
                            add_bonus( self, "mutual_award", conf.Items, VALUE_CHANGE_REASON.OPERATE_DICE )
                        end
                    else
                        add_bonus( self, "mutual_award", conf.Items, VALUE_CHANGE_REASON.OPERATE_DICE )
                    end

                    local msg_notify = gPendingBonus[ self.pid ]
                    gPendingBonus[ self.pid ] = pending

                    if msg_notify then
                        Rpc:operate_dice_action( self, msg_notify )
                    end
                end
            end
        end
    end
end


--function cross_clear_timer(self)
--    local timers = {}
--    -- build
--    for k, v in pairs(self:get_build()) do
--        -- timer: build
--        local tm = timer.get(v.tmSn)
--        if tm then
--            table.insert(timers, tm)
--            timer.del(v.tmSn)
--        end
--        -- timer: city_fire
--        local tmSn_f = v:get_extra("tmSn_f")
--        if nil ~= tmSn_f then
--            local tm = timer.get(tmSn_f)
--            if tm then
--                table.insert(timers, tm)
--                timer.del(tmSn_f)
--            end
--        end
--    end
--    -- cure
--    if self.tm_cure > 0 then
--        local tm = timer.get(self.tm_cure)
--        if tm then
--            table.insert(timers, tm)
--            timer.del(self.tm_cure)
--        end
--    end
--    -- hero_cure
--    for _, hero in pairs(self:get_hero()) do
--        if hero.tmSn > 0 then
--            local tm = timer.get(hero.tmSn)
--            if tm then
--                table.insert(timers, tm)
--                timer.del(hero.tmSn)
--            end
--        end
--    end
--
--    for k, v in pairs(timer_ex.get_timers(self.pid) or {}) do
--        local tm = timer.get(k)
--        if tm then
--            table.insert(timers, tm)
--        end
--    end
--    timer_ex.clear_timer(self.pid)
--
--    return timers
--end

function local_execute(self, func, ...)
    if self:get_cross_state() == PLAYER_CROSS_STATE.IN_OTHER_SERVER then
        local code, val = remote_func(self.map, func, {"playerex", self.pid, ...})
        if E_TIMEOUT == code then
            local player = getPlayer(self.pid)
            if nil ~= player then
                player:add_to_do(func, ...)
            end
        else
            return unpack(val)
        end
    else
        return self[func](self, ...)
    end
end

function get_last_access( p )
    local last_access = math.max( p.tm_create, p.tm_login )
    local slap = gTime - math.max( last_access, p.tm_logout )
    return math.min( slap, gTime - ( p.tick or 0 ) )
end

function make_ghost_invite( self )
    local tm = rawget( self, "_tm_ghost_invite" ) or 0
    if gTime - tm < 3600 * 24 then return end

    if #gUnionOpening < 1 then return end

    local first = table.remove( gUnionOpening, 1 )
    table.insert( gUnionOpening, first )

    local lang = self.language
    local lang_en = resmng.LANGUAGE_DEF_10
    local u_en = {}

    for k, uid in ipairs( gUnionOpening ) do
        local u = unionmng.get_union( uid )
        if u then
            if u.membercount > 49 then
                table.remove( gUnionOpening, k )
                return
            end
            if u.language == lang then
                if union_enlist_check( self, uid ) then
                    local leader = getPlayer( u.leader )
                    if leader then
                        INFO( "[GhostInvite], add_invite, union,%s, invite,%s, language,%d,%d", u.name, self.name, u.language, self.language )
                        self:send_system_union_invite( 30001, leader.pid, {uid=uid}, { leader.name, u.alias, u.name } )
                        rawset( self, "_tm_ghost_invite", gTime )
                        return
                    end
                end
            elseif u.language == lang_en then
                table.insert( u_en, u )
            end
        end
    end

    if #u_en > 0 then
        for _, u in pairs( u_en ) do
            if union_enlist_check( self, u.uid ) then
                local leader = getPlayer( u.leader )
                if leader then
                    INFO( "[GhostInvite], add_invite, union,%s, invite,%s, language,%d,%d", u.name, self.name, u.language, self.language )
                    self:send_system_union_invite( 30001, leader.pid, {uid=u.uid}, { leader.name, u.alias, u.name } )
                    rawset( self, "_tm_ghost_invite", gTime )
                    return
                end
            end
        end
    end

    for k, uid in ipairs( gUnionOpening ) do
        local u = unionmng.get_union( uid )
        if u then
            if union_enlist_check( self, uid ) then
                local leader = getPlayer( u.leader )
                if leader then
                    INFO( "[GhostInvite], add_invite, union,%s, invite,%s, language,%d,%d", u.name, self.name, u.language, self.language )
                    self:send_system_union_invite( 30001, leader.pid, {uid=uid}, { leader.name, u.alias, u.name } )
                    rawset( self, "_tm_ghost_invite", gTime )
                    return
                end
            end
        end
    end
end

function check_union_active( self )
    if self.emap ~= gMapID then return end
    local uid = self.uid
    if uid ~= 0 then
        local u = unionmng.get_union( uid )
        if u then
            if u.leader == self.pid then
                if u.enlist and u.enlist.check == 0 then
                    local members = u._members 
                    local number = 0
                    local active = 0
                    for _, A in pairs( members or {} ) do
                        number = number + 1
                        if get_last_access( A ) < 86400 then
                            active = active + 1
                        end
                    end
                    if number < 45 and active > 5 then
                        table.insert( gUnionOpening, uid )

                        if #gUnionOpening > 40 then
                            table.remove( gUnionOpening, 1 )
                        end
                        INFO( "[GhostInvite], active_union, union,%s, leader,%s, language,%d, count,%d", u.name, self.name, u.language, #gUnionOpening )
                    end
                end
            else
                --local A = getPlayer( u.leader )
                --if A and get_last_access( A ) < 86400 then

                --else
                --    --make_ghost_invite( self )
                --end
            end
        end
    else
        if get_castle_lv( self ) > 5 then make_ghost_invite( self ) end
    end
end


_G.handle_login_from_queue = player_t.handle_login_from_queue

