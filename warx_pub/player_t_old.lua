module( "player_t", package.seeall  )
module_class( "player_t", PLAYER_INIT, "player" )


--gChat = gChat or {}
gBlockAccounts = false
gOnlines = gOnlines or {}
g_online_num = g_online_num  or 0

gClientExtra = gClientExtra or false
gClientExtraPost = gClientExtraPost or false
gIpPermit = gIpPermit or false

function init()
    _example = PLAYER_INIT
end

gDelayAction = gDelayAction or {}
can_ply_join_act = {}  --玩家是否可以参加活动
can_ply_opt_act = {}   --玩家时刻可以设操控活动

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

function create(account, map, pid, culture)
    local eid = get_eid_ply()
    if not eid then return end

    pid = pid or getId("pid")
    local p = copyTab(player_t._example)

    -- Hx@2015-12-24 : lazy init union when login, not here
    --ply._union = union_member_t.create(pid, 0, 0)
    if culture < 1 or culture > 4 then culture = 1 end
    --local x, y = c_get_pos_born( culture )
    --if not x then return WARN("pid=%d, no room", pid) end

    local idx = ( math.floor( pid / 2500 ) % 4 ) + 1
    local born = { 1, 3, 4, 2 }
    local x, y = c_get_pos_born( born[idx] )
    if not x then return WARN("pid=%d, no room", pid) end

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
    p.gold = 50

    p.gacha_yinbi_first = true  --银币首抽
    p.gacha_jinbi_first = true  --金币首抽

    p.online_award_time = gTime
    p.online_award_num = 0
    p.online_award_on_day_pass = 0

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
    rawset( ply, "_tit_point", {} )
    rawset( ply, "_ache", {} )

    gEtys[ eid ] = ply
    etypipe.add(ply)

    insert_global( "players", pid, { account=account, name=p.name, tmCreate=gTime, map=gMapID, smap=map, emap=gMapID } )
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

    ply:init_task()

    local heroid = 201
    if culture == 2 then heroid = 205
    elseif culture == 3 then heroid = 204
    elseif culture == 4 then heroid = 206 end
    ply._hero[ 1 ] = hero_t.create_hero( 1, ply.pid, heroid )

    ply:initEffect()
    --gPendingInsert.item[ pid ] = {}
    
    -- register chat accout
    --create_chat_account(ply)
    ply:add_buf( resmng.BUFF_SHELL, 24 * 3600 )

    ply:init_offline_ntf_list()
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
        local build_idx = self:calc_build_idx(conf.Class, conf.Mode, 1)
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

function upload_user_info(self)
    local send = {}
    send.url = config.Login_url
    send.method = "post"
    send.type = "login_server"
    send.uid = self.account
    send.token = self.token
    send.pid = tostring(self.pid)
    send.pname = tostring(self.name)
    send.server_id = tostring(gMapID)
    send.is_server = "1"
    send.timestamp = tostring(gTime)
    send.appid = APP_ID
    send.ext_info = string.format("{\"level\":%d,\"civil\":%d}", self.lv, self.culture)
    send.sig = c_md5(APP_KEY..send.ext_info.."1"..tostring(self.pid)..tostring(self.name)..tostring(gmapID)..tostring(gTime)..self.token..self.account)
    --to_tool(0, send)
end

function upload_user_ack(self)
    return
end

function pre_tlog(self,name,...)

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
        tms2str(self.tm_create),
        self.tm_create,
        tms2str(self.tm_create),
        self.tm_create,
        tms2str(self.tm_create),
        self.tm_create,
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
        self.ip or "",
        "40",
        self.account,
        self.pid,
        self.name,
        self:get_castle_lv(),
        self.vip_lv,
        (self.rmb or 0),
        tostring(self.smap),
        self.reg_name,
        1,
        tostring(self.language),
        }
    end

    for _, v in pairs( {...} ) do
        if type(v) == "number" and v > math.pow(2,32) then
            table.insert(info,2100000000)
        else
            table.insert(info,v)
        end
    end

	if name == "UnionList" and #info ==11 then
		for i=1,8 do table.insert(info,"null") end
	else
		for i=1,10 do table.insert(info,"null") end
	end

    --lxz(info)
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

function firstPacket2(self, sockid, server_id, info)
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
    local ip = pullString()

    if config.IsEnableGm == 1 and info.debug then
        debug_login_with_pid(sockid, pid, from_map)
        return
    end

    --[[
    INFO( "firstPacket2, from=%s, sockid=%d, ip=%s, open_id=%s, pid=%d, did=%s, cival=%d, signature=%s, time=%s, toke=%s, token_expire=%s, version=%s, extra=%s",
    from_map, sockid , ip, open_id, pid, info.did, cival, signature,  time, token,  token_expire, version, extra )
    --]]

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

    if verify_time(time) == false then
        Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.TOKEN_OUT_OF_DATE)
        INFO( "firstPacket2, verify_time, from=%s, sockid=0x%08x, civil=%d, pid=%d, token=%s, time=%d, open_id=%s, did=%s, signature = %s, token=%s", from_map,  sockid , cival, pid, token, time, open_id, info.did or "unknonw", signature, token)
        return
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
                if ply then
                    if ply.tm_login > tick or ply.tm_logout > tick then
                        tick = math.max( ply.tm_login, ply.tm_logout )
                        pid = k
                    end
                end
            end
        else
            INFO( "firstPacket2, new_account, open_id=%s, did=%s, ip=%s", open_id, info.did or "unknown", ip or "unknown" )
        end

        if pid == 0 then
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.NO_CHARACTER)
            return
        else
            INFO( "firstPacket2, open_id=%s, pid=0, pid=%d, last_hit", open_id, pid )
        end
    end

    local p = false
    if pid == -1 then
        --查看是否建号超过4个
        local count = 0
        for k, v in pairs(gAccounts[open_id] or {}) do
            count = count + 1
        end
        if count >= 4 then
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.LOGIN_ERROR)
            return
        end

        pid = getId("pid")
        
        p = player_t.create(open_id, gMapID, pid, cival)
        if not p then
            Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.LOGIN_ERROR)
            return
        end
        gPendingInsert.online[ pid ] = { online = 0, pid=pid, uid=open_id, did=info.did, create=gTime, ip=ip} 

        INFO( "firstPacket2, create_character, open_id=%s, new pid=%d", open_id, pid )

        --todo, for xuezhan
        p.ip = ip
        p:pre_tlog("PlayerRegister","iphone6","ios","oper","wifi","800","600",2000)
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

    p:upload_user_info()
    p.sockid = sockid

    --Rpc:sendToSock(sockid, "first_packet_ack", LOGIN_ERROR.SUCCESS)
    Rpc:first_packet_ack(p, LOGIN_ERROR.SUCCESS)

    INFO( "[LOGIN], from=%s, ip=%s, open_id=%s, did=%s, pid=%d, name=%s, lv=%s, gold=%s", from_map, ip, open_id, info.did, pid, p.name, p.lv, p.gold )

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
    else
        pushHead(_G.GateSid, 0, 9)  -- set server id
        pushInt(sockid)
        pushInt(from_map)
        pushInt(p.pid)
        pushOver()
        player_t.login( p, p.pid )
    end

    --todo
    p.ip = ip
    p:pre_tlog("PlayerLogin",p.gold,0,"iphone6","ios","oper","wifi","800","600",2000)
    return p
end


function login(self, pid)
    local gid = self.gid or GateSid

    local p = getPlayer(pid)
    if p then
        p.gid = gid
        p.emap = gMapID
        rawset( p, "tick", gTime )

        local pay_token = get_pay_token(self)
        Rpc:onLogin(p, p.pid, p.name)

        if p.tm_logout == gTime then p.tm_logout = gTime - 1 end
        p.tm_login = gTime
        gOnlines[ pid ] = p

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

        --if not self.tm_check then self.tm_check = timer.new( "check", math.random(1200,3600), pid ) end

        g_online_num = (g_online_num  or 0) + 1

        if gClientExtra then Rpc:do_string( p, gClientExtra ) end

        return
    end
    LOG("player:login, pid=%d, gid=%d, not found player", pid, gid)
end

function king_online(self)
    if self.officer == KING then
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

function onBreak(self)
    if self.tm_login == gTime then self.tm_login = gTime - 1 end
    self.tm_logout = gTime

    INFO("[LOGIN], off, pid=%d, lv=%s, gold=%s, name=%s", self.pid or 0, self.lv, self.gold, self.name or "unknonw")
    self.gid = nil
    self:remEye()
    if g_online_num and  g_online_num  > 0 then g_online_num = g_online_num  - 1 end

    local u  = unionmng.get_union(self.uid)
    if u then
        u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=self.pid,tm_login=self.tm_login,tm_logout=self.tm_logout})
    end
    self:pre_tlog("PlayerLogout",self.gold,0)
    mark_online( self )
end


function is_online(self)
    if not self.gid then return false end
    return gTime - ( self.tick or 0 ) < 150
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
        local union = unionmng.get_union(uid) or {}
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
                end
            end
        end
    end
end

function get_rank(self)
    return self._union.rank
end

function set_rank(self, val)
    if val < resmng.UNION_RANK_1  or val >resmng.UNION_RANK_5 then
        return
    end

    local mode = 0
    if self._union  then
        if  val == self._union.rank  then
            return
        elseif  val > (self._union.rank or 0)   then
            mode = resmng.UNION_MODE.RANK_UP
        else
            mode = resmng.UNION_MODE.RANK_DOWN
        end
    else
        mode = resmng.UNION_MODE.RANK_UP
    end
    self._union.rank = val
    INFO( "[UNION], rank, pid=%d, uid=%d rank=%d", self.pid, self.uid,val )
    gPendingSave.union_member[self.pid] = self._union
    local u = unionmng.get_union(self:get_uid())
    if u  then
        u:notifyall(resmng.UNION_EVENT.MEMBER, mode, self:get_union_info())
    end
end

function union_data(self)
    return self._union
end


function get_union_info(self)
    return {
        pid = self.pid,
        propid = self.propid,
        name = self.name,
        lv = self.lv,
        language = self.language,
        rank = player_t.get_rank(self),
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

--}}}

function mark_online( self )
    local pid = self.pid
    local mark = rawget( self, "tick_mark" ) or 0
    if gTime - mark < 90 then
        local dura = gTime - mark
        local db = dbmng:tryOne()
        if db then
            db.online:update( {_id=pid}, { ["$inc"] = {online=dura } }, true )
        end
    end
    rawset( self, "tick_mark", gTime )
    if not gOnlines[ pid ] then gOnlines[ pid ] = self end
end


function getTime(self, tag)
    Rpc:getTime(self, tag, gTime, gMsec, gBootTime)
    mark_online( self )
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
    local db = dbmng:tryOne(1)
    if not db then return end

    --local hit = false
    --local cur = gFrame
    --for pid, chgs in pairs(_cache) do
    --    if not chgs._n_ then
    --        db.player:update({_id=pid}, {["$set"]=chgs}, true)
    --        --dumpTab(chgs, string.format("update player, pid = %d", pid))
    --        local p = getPlayer(pid)
    --        if p then
    --            Rpc:statePro(p, chgs)
    --        end
    --        chgs._n_ = cur
    --        hit =true
    --    end
    --end
    --if hit then
    --    gen_checker(db, cur, _cache, "player")
    --    hit = false
    --end

    --for pid, chgs in pairs(_cache_items) do
    --    if not chgs._n_ then
    --        db.item:update({_id=pid}, {["$set"]=chgs})
    --        local p = getPlayer(pid)
    --        Rpc:stateItem(p, chgs)
    --        dumpTab( chgs, "itemchgs" )
    --        chgs._n_ = cur
    --        hit = true

    --        for k, v in pairs(chgs) do
    --            if k ~= "_n_" then
    --                if v[3] <= 0 then
    --                    db.item:update({_id=pid}, {["$unset"]={[k]=1}})
    --                    p._item[ v[1] ] = nil
    --                end
    --            end
    --        end
    --    end
    --end
    --if hit then gen_checker(db, cur, _cache_items, "item")  end
    
    while next( gDelayAction ) do
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
        if flag and code == "ok" then break end
    end

    local notifys = troop_t.gPendingNotify
    troop_t.gPendingNotify = {}
    for tid, troop in pairs( notifys ) do
        troop:do_notify_owner()
    end
    
    for k, v in pairs( gSync ) do
        Rpc:sync( k, v )
    end
    gSync = {}

    gLastCheck, p = next( gPlys, gLastCheck )
    if p then
        if gTime - (p.tick or 0) > 1200 then
            player_t.unload( p )
        end
    end
end

function unload( p )
    local offset = gTime - ( rawget( p, "tm_unload" ) or 0 )
    if offset > 1200 and not gInit then
        if p._build then p._build = nil end
        if p._item then p._item = nil end
        if p._mail then p._mail = nil end
        if p._cur_task_list then clear_task( p ) end
        rawset( p, "tm_unload", gTime )
    end
end


gGlobalThreadDelayAction = gGlobalThreadDelayAction or {}
function thread_delay_aciton()
    local co = coroutine.running()
    local q_actions = gDelayAction
    while true do
        local pid, actions = next( q_actions ) 
        while not pid do 
            if gCoroBad[ co ] then return "ok" end
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
    local res = {}
    local notifys = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) + v
        res[ k ] = t[k]
        --LOG( "ef_add, pid=%d, k=%s, v=%s", self.pid, k, v )

        if not init and g_ef_notify[ k ] then notifys[ g_ef_notify[ k ] ] = 1 end

        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        if not init then LOG("ef_add, pid=%d, what=%s, num=%d", self.pid, k, v) end
    end
    if not init then
        --Rpc:stateEf(self, res)
        for func, _ in pairs( notifys ) do
            func( self )
        end
    end
end

function ef_rem(self, eff)
    if not eff then return end
    local t = self._ef
    local res = {}
    local notifys = {}
    for k, v in pairs(eff) do
        t[k] = (t[k] or 0) - v
        res[ k ] = t[k]
        if math.abs(t[k]) <= 0.00001 then t[k] = nil end
        if g_ef_notify[ k ] then notifys[ g_ef_notify[ k ] ] = 1 end
        --LOG("ef_rem, pid=%d, what=%s, num=%d", self.pid, k, v)
        --print( "ef_rem", self.pid, k, v, t[k] )
    end
    --Rpc:stateEf(self, res)
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
        if troop and troop:is_action( TroopAction.Gather ) then
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

        if info[i] ~= queues[i] then
            queues[ i ] = info[ i ]
            self.build_queue = info
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
            offline_ntf.post(resmng.OFFLINE_NOTIFY_PROTECT, self, {}, {})
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
    end
end

function doConsume(self, class, mode, num, why)
    if class == resmng.CLASS_RES then
        --return self:doUpdateRes(mode, -num, why)
        self:do_dec_res(mode, num, why)
        return true

    elseif class == resmng.CLASS_ITEM then
        return self:dec_item_by_item_id(mode, num, why)
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



function add_bonus(self, bonus_policy, tab, reason, ratio )
    if bonus_policy == nil or tab == nil or reason == nil then
        return false
    end
    ratio = ratio or 1
    local get_tab = player_t.bonus_func[bonus_policy](self, tab)
    if get_tab and #get_tab > 0 then
        local msg_notify = {}
        for k, v in pairs(get_tab) do
            self:do_add_bonus(v[1], v[2], v[3], ratio, reason)
            v[3] = v[3] * ratio
            table.insert(msg_notify, v)
            if v[1] == "item" then
                local prop_tab = resmng.get_conf("prop_item", v[2])
                if prop_tab and prop_tab.Open == 1 then
                    table.remove(msg_notify)
                end
            end
        end
        Rpc:notify_bonus(self, msg_notify)
    end
    return true
end

function do_add_bonus(self, class, mode, num, ratio, reason)
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
            self:addItem(mode, real_num, reason)
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
    dumpTab(arg, "QryCross")
    local code = 0
    Rpc:onAckCross(_G.gAgent, smap, sn, code, arg)
end

function onAckCross(self, smap, sn, code, res)
    LOG("onAckCross, smap=%d, sn=%d, code=%d", smap, sn, code)
    if code == 0 then dumpTab(res, "AckCross") end
    local co = getCoroPend("rpc", sn)
    if co then
        coroutine.resume(co, code, res)
    end
end

function testQryCross(self)
    -- -2, the pid is minus, means the map 2, pid 0
    local code, tab = self:qryCross(2, "sayHello", {a=1, b="string"})
    LOG("qryCross, code=%d", code)
    if code == 0 then dumpTab(tab) end
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
            self:add_debug( "[EF], %s = %d", k, v )
            INFO( "[SHOWEF], EF, %s, %s", k, v )
        end

        local ef_u, ef_ue = self:get_union_ef()
        for k, v in pairs( ef_u or {} ) do
            self:add_debug( "[EF_U], %s = %d", k, v )
            INFO( "[SHOWEF], EF_U, %s, %s", k, v )
        end

        for k, v in pairs( ef_ue or {}) do
            self:add_debug( "[EF_UE], %s = %d", k, v )
            INFO( "[SHOWEF], EF_UE, %s, %s", k, v )
        end

        for k, v in pairs( kw_mall.gsEf or {}) do
            self:add_debug( "[EF_GS], %s = %s", k, v )
            INFO( "[SHOWEF], EF_GS, %s, %s", k, v )
        end


    elseif choose == "showgsef" then
        for k, v in pairs( kw_mall.gsEf ) do
            if k ~= "_id" then
                self:add_debug( "gs [EF], %s = %d", k, v )
            end
        end
    elseif choose == "showuef" then
        local u = unionmng.get_union(self.uid)
        if u then
            for k, v in pairs( u:get_ef() or {} ) do
                self:add_debug( "union [EF], %s = %d", k, v )
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
        local u = self:union()
        for _, v in pairs(u.build or {}) do v.val = 100 end
        --[[
        union_item.add(self,{"mutex_award",{{"item",2012009,1,10000},}} ,UNION_ITEM.TASK)--加入军团礼物
        debug_tag = 1
        union_buildlv_donate(self,1)
        debug_tag = nil
        self:add_buf( 50003001, -1 ) --行军队列无限
        local param = {player_id = tostring(self.pid), order_id = tostring(gTime), pay_amount = "1", product_id = 1}
        agent_t.do_gm_cmd["pay"](param)
        --]]

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
    elseif choose == "addac" then
        local idx = tonumber(tb[2])
        local val = tonumber(tb[3])
        self:add_count(idx,val)
    elseif choose == "addache" then
        local point = tb[2]
        self.ache_point = (self.ache_point or 0) + point
        self:try_upgrade_titles()
    elseif choose == "setache" then
        local idx = tb[2]
        --local aconf = resmng.get_conf( "prop_achievement", idx )
        --if not aconf then return end
        --local var = aconf.Var
        --local cconf = resmng.get_conf( "prop_achievement_var", var )
        --if not cconf then return end
        self:set_ache( tonumber(idx), gTime )
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
       -- king_city.fight_kw()
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
        local _members =  remote_func(map_id, func, param)
        print("debug", _members)
        Rpc:callAgent(8, "agent_syn_call", 1, "hahah", {1,1})
    elseif choose == "time" then --跨服
        local time = os.time()
        self:add_debug(string.format("time is %d", time))
        local map_id = tonumber(tb[2])
    elseif choose == "jump" then --跨服
        local map_id = tonumber(tb[2])
        self:ply_change_server(map_id, self.x, self.y)
        --self:cross_migrate(map_id, self.x, self.y)
    elseif choose == "jumpback" then --跨服
        local map_id = tonumber(tb[2])
        self:cross_migrate_back(map_id, self.x, self.y)
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
        self:build_all()
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
    elseif choose == "finishtask" then
        local task_id = tonumber(get_parm(1))
        self:gm_finish_task(task_id)
    elseif choose == "accepttask" then
        local task_id = tonumber(get_parm(1))
        self:gm_accept_task(task_id)
    elseif choose == "cleargacha" then
        self:gacha_on_day_pass()

    elseif choose == "setvip" then
        self.vip_lv = tonumber(get_parm(1))
    elseif choose == "sysmail" then
        self:send_system_notice(10031, {"hello"}, {"hello"}, {{"item", resmng.ITEM_2100013, 3, 10000}})
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
        --[[set_sys_status("start", gTime)
        world_event.reinit_world_event()
        weekly_activity.reinit_weekly_activity()
        operate_activity.reinit_operate_activity()--]]
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
    elseif what == "tit_point" then
        val = self:get_tit_point()
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
    end
    return val
end

function loadData(self, what)--本函数严禁加日志
    local t = {}
    t.key = what
    if what == "pro" then
        t.val = self._pro
    elseif what == "ef_eid" then
        local e = get_ety(self.ef_eid)
        if e then
            t.val = { eid=e.eid, uid = e.uid, propid=e.propid }
        else
            t.val = { eid = 0, uid = 0, propid = 0 }
        end
    elseif what == "item" then
        t.val = self:get_item()

    elseif what == "equip" then
        t.val = self:get_equip()

    elseif what == "ef" then
        t.val = self._ef

    elseif what == "ef_hero" then
        t.val = self._ef_hero

    elseif what == "build" then
        local ts = {}
        for k, v in pairs(self:get_build() or {}) do
            table.insert(ts, v._pro)
        end
        t.val = ts

    elseif what == "tech" then
        t.val = self.tech

    elseif what == "hero" then
        local ts = {}
        for k, v in pairs(self._hero or {}) do
            local h = copyTab(v._pro)
            table.insert(ts, h)
        end
        t.val = ts

    elseif what == "troop" then
        local data = {}
        for _, tid in pairs(self.busy_troop_ids) do
            local tr = troop_mng.get_troop(tid)
            if tr then
                table.insert( data, tr:get_info() )
            end
        end
        t.val = data

    elseif what == "ache" then
        t.val = self:get_ache()

    elseif what == "count" then
        t.val = self:get_count()

    elseif what == "arm" then
        local my_troop = troop_mng.get_troop(self.my_troop_id)
        if my_troop ~= nil then
            local a = my_troop.arms[ self.pid ]
            if a then a = a.live_soldier end
            a = {}
            t.val = a
        end

    elseif what == "task" then
        t.val = self:packet_all_task_id()

    elseif what == "watch_tower" then
        t.val = watch_tower.packet_watchtower_info(self)

    elseif what == "client_parm" then
        if gTime - self.tm_create < 20 then
            t.val = {}
        else
            t.val = self:load_client_parm()
        end

    elseif what == "target" then
        t.val = self:packet_target_task()

    elseif what == "done" then
        INFO( "[login], pid=%d, loaddone", self.pid )

    end

    if not t.val then t.val = {} end
    Rpc:loadData(self, t)

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
            Rpc:monster_declare( self, infos ) 
        end

        if not self.ntodo or self.ntodo > 0 then
            local db = self:getDb()
            local info = db.todo:find( {pid=self.pid} )
            if info then
                while info:hasNext() do
                    local task = info:next()
                    gPendingDelete.todo[ task._id ] = 1
                    player_t[ task.command ]( self, table.unpack( task.args ) )
                end
            end
            rawset( self, "ntodo", 0 )
        end

        if self.mail_sys ~= gSysMailSn then
            mail_compensate( self )
        end

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

        local timers = self:get_build_timers_and_del()

       local db = self:getDb()
       local info = db.mail:find( { to=self.pid, tm_drop = 0 } )
       local ms = {}
       while info:hasNext() do
           local m = info:next()
           if m.tm_drop == 0 then
               table.insert( ms, m )
           end
       end

        local troop = self:get_my_troop(self.my_troop_id)

        self:get_first_blood()  -- load frist blood
        self:get_equip()        -- load equip
        self:get_item()        -- load item
        self:get_hero()        -- load hero
        --self:get_mail()        -- load mail
        self:get_count()        -- load count
        self:get_tit_point()        -- load count
        self:get_build()         -- load build
        self:get_title()        -- load title
        self:load_task_from_db()  -- load task


        Rpc:callAgent(map_id, "change_server", self.pid, x, y, self, timers, {}, troop, ms)

         self:movEye(map_id, x, y)
    end
end

function cross_migrate(self, map_id, x, y)

    if #self.busy_troop_ids > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end

    if not self:can_move_to(x, y)  then return self:add_debug("can not move by castle lv") end

    if map_id ~= gMapID then

        local u = self:get_union()
        if not u then
            return 
        end
        if u:is_new() then
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

        local timers = self:get_build_timers_and_del()

       -- local db = self:getDb()
       -- Blocal task_db = db.task:find({pid=self.pid})
       -- local task = {}
       -- while task_db:hasNext() do
       --     local unit = task_db:next()
       --     task[unit.task_id] = unit
       -- end
       --
       local db = self:getDb()
       local info = db.mail:find( { to=self.pid, tm_drop = 0 } )
       local ms = {}
       while info:hasNext() do
           local m = info:next()
           if m.tm_drop == 0 then
               table.insert( ms, m )
           end
       end

        local troop = self:get_my_troop(self.my_troop_id)

        self:get_first_blood()  -- load frist blood
        self:get_equip()        -- load equip
        self:get_item()        -- load item
        self:get_hero()        -- load hero
        --self:get_mail()        -- load mail
        self:get_count()        -- load count
        self:get_tit_point()        -- load count
        self:get_build()         -- load build
        self:get_title()        -- load title
        self:load_task_from_db()  -- load task


        if u then
            Rpc:callAgent(map_id, "agent_migrate", self.pid, x, y, self, timers, u._pro, troop, ms)
        end

         self:movEye(map_id, x, y)
    end
end

function cross_migrate_back(self, map_id, x, y)
    for _, id in pairs(self.busy_troop_ids or {}) do
        local tr = self:troop_recall(id, true )
        if tr then
            tr:home()
        end
    end

    if #self.busy_troop_ids > 0 then return ack(self, "migrate", resmng.E_TROOP_BUSY, 0) end

    if not self:can_move_to(x, y)  then return self:add_debug("can not move by castle lv") end

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

    if map_id ~= gMapID then
        if self.emap == gMapID then
            local ef_u,ef_ue = self:get_union_ef()
            self.ef_u = ef_u
            self.ef_ue = ef_ue
        else
            self.ef_u = {}
            self.ef_ue = {}
        end

        local timers = self:get_build_timers_and_del()
        local union = unionmng.get_union(self.uid)
        local troop = self:get_my_troop(self.my_troop_id)

        self:get_first_blood()  -- load frist blood
        self:get_equip()        -- load equip
        self:get_item()        -- load item
        self:get_hero()        -- load hero
        --self:get_mail()        -- load mail
        self:get_count()        -- load count
        self:get_tit_point()        -- load count
        self:get_build()         -- load build
        self:get_title()        -- load title
        self:load_task_from_db()  -- load task

        local db = self:getDb()
        local info = db.todo:find( {pid=self.pid} )  -- back add to do
        --local info = db.todo:find()
        local todos = {}
        if info then
            while info:hasNext() do
                local todo = info:next()
                table.insert(todos, todo)
            end
        end

       local info = db.mail:find( { to=self.pid, tm_drop = 0 } )
       local mails = {}
       while info:hasNext() do
           local m = info:next()
           if m.tm_drop == 0 then
               table.insert( mails, m )
           end
       end

        if union then
            Rpc:callAgent(map_id, "agent_migrate_back", self.pid, x, y, self, timers, union._pro, troop, todos, mails)
        end

    end
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

function addEye(self, x, y)
    --local x = self.x
    --local y = self.y
    local lv = 0
    if x < 0 or x >= 1280 then return end
    if y < 0 or y >= 1280 then return end
    c_add_eye(x, y, lv, self.pid, self.gid)
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
        Rpc:callAgent( map, "agent_move_eye", self.pid, x,  y )

        local zx = math.floor(x / 16)
        local zy = math.floor(y / 16)

        if zx == 0 or zx == 1279 then c_rem_eye( self.pid ) end
        if zy == 0 or zy == 1279 then c_rem_eye( self.pid ) end
    end
end

function remEye(self)
    if self.pid < 0  then return end
    c_rem_eye(self.pid)
    if self.eyes then
        for map, v in pairs( self.eyes ) do
            Rpc:callAgent( map, "agent_remove_eye", self.pid)
        end
        self.eyes = nil
    end
end


--function movEye(self, x, y)
--    if x < 0 or x >= 1280 then return end
--    if y < 0 or y >= 1280 then return end
--    LOG("moveEye, x=%d, y=%d, x=%s, y=%s", x,y,x/16, y/16)
--    c_mov_eye(self.pid, x, y)
--end

function say(self, saying, i)
    LOG("pid=%d, say, i=%d, frame=%d", self.pid, i, gFrame)
    Rpc:say1(self, saying, i)
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
    end
end

function do_inc_res_normal(self, mode, num, reason)
    if mode < 1 then return end

    if not reason then
        ERROR("do_inc_res_normal: pid = %d, don't use the default reason.", self.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then
        WARN("do_inc_res, pid=%d, num=%d, reason=%s, num<0", self.pid, num, reason)
        return
    end
    num = math.floor( num )

    INFO( "[RES], inc, pid=%d, mode=%d, num=%d, reason=%s, normal", self.pid, mode, num, reason or 0)

    if mode <= resmng.DEF_RES_ENERGY then
        local node = self.res[ mode ]
        if not node then return end
        if mode == resmng.DEF_RES_FOOD then self:refresh_food() end
        node[1] = math.floor(node[1] + num)
        self.res = self.res

    elseif mode == resmng.DEF_RES_MARSEXP then
        union_god.add_exp(self,num)

    elseif mode == resmng.DEF_RES_PERSONALHONOR then
        union_member_t.add_donate(self, num,reason)
        local union = unionmng.get_union(self:get_uid())
        if union then union:add_donate(num * 1.4, self) end
    elseif mode == resmng.DEF_RES_UNITHONOR then
        -- 不做任何事情

    elseif mode == resmng.DEF_RES_LORDEXP then
        self:add_exp(num)

    elseif mode == resmng.DEF_RES_VIPEXP then
        self:vip_add_exp(num)

    elseif mode == resmng.DEF_RES_LORDSINEW then
        self:inc_sinew( num )

    else
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            self[ key ] = math.floor((self[ key ] or 0) + num)
            if mode == resmng.DEF_RES_GOLD  then
                self:pre_tlog("MoneyFlow",0,num,2,0,self[key],reason )
            elseif mode == resmng.DEF_RES_SILVER  then
                self:pre_tlog("MoneyFlow",0,num,1,0,self[key],reason )
            end
        end
    end
end

function do_dec_res(self, mode, num, reason)
    if not reason then
        ERROR("do_dec_res: pid = %d, don't use the default reason.", self.pid)
        reason = resmng.VALUE_CHANGE_REASON.DEFAULT
    end

    if num < 0 then
        WARN("do_dec_res, pid=%d, num=%d, reason=%s, num>=0", self.pid, num, reason)
        return
    end

    num = math.floor(num)

    INFO( "[RES], dec, pid=%d, mode=%d, num=%d, reason=%s", self.pid, mode, num, reason or 0)

    local enough = true
    if mode > resmng.DEF_RES_ENERGY then
        local conf = resmng.get_conf("prop_resource", mode)
        if conf then
            local key = conf.CodeKey
            if self[ key ] and self[ key ] >= num then
                self[ key ] = math.floor(self[ key ] - num)
                if  mode ==resmng.DEF_RES_GOLD  then
                    self:add_count( resmng.ACH_COUNT_GOLD_COST, num )
                    self:pre_tlog("MoneyFlow",0,num,2,1,self[key],reason )
                    union_mission.ok(self,UNION_MISSION_CLASS.COST, num)
                elseif mode == resmng.DEF_RES_SILVER  then
                    self:pre_tlog("MoneyFlow",0,num,1,1,self[key],reason )
                end
            else
                INFO("资源不足:"..self[ key ])
                self[ key ] = 0
                enough = false
            end
        end
    else
        local node = self.res[ mode ]
        if not node then return end

        if mode == resmng.DEF_RES_FOOD then self:refresh_food() end
        if node[1] >= num then
            node[1] = math.floor(node[1] - num)
        else
            num = num - node[1]
            node[1] = 0
            node[2] = math.floor(node[2] - num)
            if node[2] < 0 then
                INFO("资源不足:"..node[2])
                node[2] = 0
                enough = false
            end
        end
        self.res = self.res
    end
    return enough
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
                troop:save()
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
    dumpTab(p2)
    Rpc:testPack(self, i1, p2, s3)
end

function add_debug(self, val, ...)
    if ... then val = string.format( val, ... ) end
    Rpc:notify_server(self, val)
    player_t.add_chat(self, 0, 0, {pid=0},  val, 0, {} )
    return false
end

function add_chat( to, channel, id, speaker, word, lang, args )
    lang = lang or 0
    args = args or {}

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
        idx = self.culture * 10 + channel

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
    local officer = self.officer

    local speaker = { pid = self.pid, photo = self.photo, name = self.name, vip = lvip , officer = officer, title = self.title}
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

    if channel == resmng.ChatChanelEnum.World then
        add_chat({pid=-1,gid=_G.GateSid}, channel, 0, speaker, word, 0, {} )

    elseif channel == resmng.ChatChanelEnum.Union then
        local u = self:union()
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
        local pids = {}
        local culture = self.culture
        for pid, v in pairs(gPlys) do
            if v.culture == culture and v:is_online() then
                table.insert(pids, pid)
            end
        end
        player_t.add_chat(pids, channel, culture, speaker, word, 0, {})

    elseif channel == resmng.ChatChanelEnum.Notice then
        if not self:dec_item_by_item_id( resmng.ITEM_NOTICE, 1, VALUE_CHANGE_REASON.USE_ITEM ) then 
            if not self:dec_gold( 500, VALUE_CHANGE_REASON.CHAT_NOTICE ) then
                return 
            end
        end
        player_t.add_chat({pid=-1,gid=_G.GateSid}, channel, 0, speaker, word, 0, {} )

    end

    reply_ok(self, "chat", sn)
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

function do_genius(self, id)
    if (self.talent or 0) < 1 then return end

    local conf = resmng.get_conf("prop_genius", id)
    if not conf then
        ERROR("do_genius: get prop_genius config failed. pid = %d, genius_id = %d.", self.pid, id)
        return
    end

    if not self:condCheck(conf.Cond) then return end

    local tab = self.genius or {}
    local old_id = 0
    if conf.Lv > 1 then
        old_id = id - 1
        local old_conf = resmng.get_conf("prop_genius", old_id)
        if not old_conf then
            ERROR("do_genius: get prop_genius config failed. pid = %d, old_genius_id = %d.", self.pid, old_id)
            return
        else
            if setRem( tab, old_id ) then self:ef_chg( old_conf.Effect, conf.Effect )
            else return end
        end
    else
        if is_in_table( tab, id ) then return end
        self:ef_add(conf.Effect)
    end

    local cds = self.cds
    if conf.Skill then
        local skill = resmng.get_conf( "prop_skill", conf.Skill )
        if skill then
            local cd = skill.Cd
            for _, v in pairs( cds or {} ) do
                if v[1] == "genius" then
                    local one  = resmng.get_conf( "prop_genius", v[2] )
                    if one then
                        if one.Class == conf.Class and one.Mode == conf.Mode then
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

    setIns( tab, id )
    self.genius = tab
    self.talent = self.talent-1
    dumpTab( tab, "genius" )
end


function notify(self, chg)
    Rpc:statePro(self, chg)
end

function query_fight_info(self, fid)
    local node = fight.gFightReports[ fid ]
    if node then
        --dumpTab(node[2], "query_fight_info")
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
    if self:get_item_num( itemid ) < 1 then return self:add_debug( "no item ITEM_RANDOMMOVE" ) end
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
                if self.gold < 2000 then return end
            end
        end
    end

    if self:do_migrate( x, y ) == "ok" then
        if itemid then
            self:dec_item_by_item_id( itemid, 1, VALUE_CHANGE_REASON.MIGRATE )
            task_logic_t.process_task(self, TASK_ACTION.USE_ITEM, itemid, 1)
        else
            self:dec_gold( 2000, VALUE_CHANGE_REASON.MIGRATE )
            task_logic_t.process_task(self, TASK_ACTION.USE_ITEM, resmng.ITEM_ADVANCEDMOVE, 1)
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
                if action == TroopAction.SiegePlayer or action == TroopAction.MonsterAtkPly or action == TroopAction.SupportArm or action == TroopAction.Spy then
                    c_troop_set_speed( troop.eid, 2000, 1 )
                    triggers_t.arrived_target( troop.dx, troop.dy, troop.eid )
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
                        self:add_debug( "overlap" )
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
    self:try_add_tit_point(resmng.ACH_LEVEL_PLAYER)

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

    --升级要触发事情
    --任务
    task_logic_t.process_task(self, TASK_ACTION.ROLE_LEVEL_UP)

    local hs = self:get_hero()
    for _, h in pairs( hs ) do
        if h.lv == old_level then
            h:gain_exp( 0 )
        end
    end
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
    self.count_dig = 0
    self:operate_on_day_pass()
end


function change_name(self, name)
    if not is_valid_name(name) then
        ack(self, "change_name", resmng.E_DISALLOWED)
    end

    if not is_inputlen_avaliable( name, CHA_LIMIT.Lord_Name ) then return end

    --包含屏蔽字
    if is_include_filter_server(name) == true then
        ack(self, "change_name", resmng.E_DISALLOWED)
        return
    end

    for k, v in pairs(gPlys) do
        if v.name == name then
            ack(self, "change_name", resmng.E_DUP_NAME)
            return
        end
    end

    if not self:dec_item_by_item_id( resmng.ITEM_CHANGE_NAME, 1, VALUE_CHANGE_REASON.CHANGE_NAME ) then
        local price = get_item_price( resmng.ITEM_CHANGE_NAME )
        if self.gold < price then return end
        self:dec_gold( price, VALUE_CHANGE_REASON.CHANGE_NAME )
    end

    self.name = name
    etypipe.add(self)
    rank_mng.update_info_player( self.pid )

    --rank_mng.change_name( 1, self.pid, name )
    --rank_mng.change_name( 2, self.pid, name )
    --rank_mng.change_name( 3, self.pid, name )
    --rank_mng.change_name( 4, self.pid, name )

    local u  = unionmng.get_union(self.uid)
    if u then
        u:notifyall(resmng.UNION_EVENT.MEMBER, resmng.UNION_MODE.UPDATE, {pid=self.pid,uid=self.uid,name=self.name})
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
    --local info = db.equip:find({pid=self.pid, pos={["$gte"]=0}})
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
    task_logic_t.process_task(self, TASK_ACTION.GET_EQUIP, propid, 1)

    self:check_equip_ache() -- ache check

    INFO("equip_add: pid = %d, item_id = %d, reason = %d.", self.pid, propid, why)
end

function check_equip_ache(self)
   self:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_1)
   self:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_2)
   self:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_3)
   self:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_4)
   self:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_5)
   self:try_add_tit_point(resmng.ACH_EQUIP_QUALITY_6)
end

function equip_rem(self, id, why)
    self:get_equip()
    self._equip[ id ] = nil
    gPendingSave.equip[ id ].pos = -1
    Rpc:equip_rem(self, id)

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
function npc_act_info_req(self)
    local pack = {}
    local union = unionmng.get_union(self.uid)
    local state, startTime, endTime = npc_city.get_npc_state()
    local pointType = POINT_MALL_TYPE[POINT_MALL.MANOR]
    pack.credit = self[pointType] or 0
    pack.state = state
    pack.endTime = endTime
    if union then
        union:union_can_atk_citys()
        local can_atk_citys = {}
        for k, v in pairs(union.can_atk_citys or {}) do
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
        union:union_can_atk_citys()
        pack.can_atk_citys = union.can_atk_citys
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

    local pack = {}
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
            local info = {city.eid, city.uid, "", city.propid, city.unions, city.state, city.startTime, city.endTime, city.unions}

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
            table.insert(map, {king_city.eid, king_city.uid, name, king_city.propid, {{union.uid, union.name, union.flag, union.alias}}, king_city.state, king_city.startTime, king_city.endTime})
    end
    pack.map = map
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
    local version, tops = rank_mng.load_rank( 13 )
    local rank = {}
    for k, v in pairs( tops ) do

        local id = v[2][1]
        local score = v[1]
        local name = v[ 2 ][2]

        table.insert( rank, { id, name, score } )
    end

    local points = {}
    local prop_world_unit = resmng.prop_world_unit
    local occupys = npc_city.monster_occupys
    for k, v in pairs( npc_city.citys ) do
        local city = get_ety( k )
        if city then
            if not city.uid or city.uid == 0 then
                if occupys and occupys[ city.propid ] then
                    local uid = occupys[ city.propid ]
                    local conf = prop_world_unit[ city.propid ]
                    points[ uid ] = ( points[ uid ] or 0 ) + conf.Boss_point
                else
                    local conf = prop_world_unit[ city.propid ]
                    local uid = conf and conf.Flag and conf.Flag[4]
                    if uid then
                        points[ uid ] = ( points[ uid ] or 0 ) + conf.Boss_point
                    end
                end
            end
        end
    end

    for uid, point in pairs( points ) do
        local conf = resmng.prop_default_union[ uid ]
        if conf then
            table.insert( rank, { conf.ID, conf.Fullname, point } )
        end
    end

    Rpc:get_union_npc_rank_ack( self, { s_id = gMapID, rank=rank } )
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

function abandon_npc(self, eid)
    if not  can_ply_opt_act[ACT_TYPE.NPC](self) then
       -- add_debug(self, "军团等级不够 宣战失败")
        if not player_t.debug_tag then
            return
        end
    end

    local union = unionmng.get_union(self.uid)
    if union then
        if not can_date(union.abd_city_time) then
            ack(self, "abandon_npc", resmng.E_DISALLOWED )
            return
        end
    else
        return
    end
    local npc = get_ety(eid)
    if npc and (npc.uid ~= 0 or npc.uid ~= npc.propid) then
        if npc.uid == self.uid then
            npc_city.abandon_npc(npc)
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
            end
        end
        pack[v] = act
    end

    --周限时活动,这个是后面设计加在这个地方的，所以比较特殊
    if self.map == gMapID then
        pack["weekly_activity"] = weekly_activity.pack_activity(self)
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
    self:get_eye_info(eid)
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

        dumpTab( info, "get_eye_info" )

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
            dumpTab(pack, "get_eye_info")
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
        local ply = getPlayer(v)

        if ply then
            if k == KING then
                has_king = true
            end
            officer.index = k
            officer.pid = ply.pid
            officer.name = ply.name
            officer.photo = ply.photo
            officer.lv = ply:get_castle_lv()
            local union = unionmng.get_union(ply.uid)
            if union then
                officer.union = union.alias
            end
            officers[k] = officer
        end
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
    for k, v in pairs(king_city.kings) do
        local ply = getPlayer(v[2])
        local plyName = ""
        local unionName = ""
        if ply then
            plyName = ply.name
        end
        local union = unionmng.get_union(v[3])
        if union then
            unionName = union.alias
        end
        local year = os.date("%Y", v[5]) or 0
        local point = string.format("%0.2f", (v[4] / v[10] or 1))
        --kings[k] = {k, v[2], plyName, unionName, tonumber(point), v[5], math.floor(year -start_year + 1), ply.photo}
        table.insert(kings, {k, v[2], plyName, unionName, tonumber(point), v[5], math.floor(year - start_year + 1), ply.photo})
    end
    pack.kings = kings
    pack.season = season
    --pack.canVote = (self.kwseason ~= season)
    Rpc:honour_wall_ack(self, pack)
end

function kw_mall_buy_req(self, mode, index)
    if mode == POINT_MALL.KING then
        kw_mall.buy(self, index)
        kw_mall_info_req(self, mode)
    else
        self:mall_buy(mode, index)
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
            local union = unionmng.get_union(p.uid)
            if union then pack.uname = union.alias or "" end
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
                if build.state == BUILD_STATE.WAIT then
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
    return citys
end

--- 怪物攻城
function mc_info_req(self)
    local pack = {}
    local union = unionmng.get_union(self.uid)
    local pointType = POINT_MALL_TYPE[POINT_MALL.MONSTER]
    pack.credit = self[pointType]
    pack.point = 0
    if union then
        pack.startTm = union.mc_start_time or union:get_default_time()
        --pack.canSetTime = ( os.date("%d", union.set_mc_time) ~= os.date("%d", gTime) and union.monster_city_stage == 0)
        pack.canSetTime = (union.set_mc_time < gTime) and union.monster_city_stage == 0
        pack.stage = union.monster_city_stage
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
                local mc = union_t.get_live_mc(v)
                if mc then
                    city.endTime = mc.endTime
                    if def_tr then
                        pack.def_num = def_tr:get_troop_total_soldier()
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
                    city.propid = npc.propid
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

function set_mc_start_time_req(self, time)
    if not can_ply_opt_act[ACT_TYPE.MC](self) then
        Rpc:tips(self, 1, resmng.ACTIVITIES_MONSTER_SET_TIP, {})
        return
    end

    local u = unionmng.get_union(self.uid)
    if u then
        union_t.set_mc_start(u, time, self)
        player_t.pre_tlog(nil,"UnionList",u.uid,u.name,u.language,3,tostring(time))
        mc_info_req(self)
    end
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
        LOG( "REFRESH_POW, pid=%d, new=%d, old=%d, delta=%d", self.pid, self.pow, self.pow_last, delta )
        self.pow_last = self.pow
        rank_mng.add_data( 3, self.pid, { self.pow } )

        local union = self:get_union()
        if union then
            union.pow = (union.pow or 0) + delta
            rank_mng.add_data( 5, union.uid, { union.pow } )
            union_mission.ok(self,UNION_MISSION_CLASS.POW, delta)
        end
    end
end


function inc_pow(self, num)
    if num and num > 0 then
        self.pow = (self.pow or 0) + num
        self:mark_action( refresh_rank_pow )
        --运营活动
        operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.LORD_FIGHT_POWER, 1, num)
    end
end

function dec_pow(self, num)
    if num and num > 0 then
        self.pow = self.pow - num
        self:mark_action( refresh_rank_pow )
        --运营活动
        operate_activity.process_operate_activity(self, OPERATE_ACTIVITY_ACTION.LORD_FIGHT_POWER, 2, num)
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
        Rpc:chat_account_info_ack(self, self.chat_account, self.chat_psw)
    else
        self:create_chat_account()
    end
end

function create_chat_account(ply)
   to_tool(0, {url = config.Chat_url or CHAT_URL, type = "chat", method = "post", cmd = "create_chat", user = tostring(ply.pid), host = CHAT_HOST,password = tostring(ply.pid)})
end

--- register result  chat call back
function create_chat(info)
    if info.result == 1 then
        local ply = getPlayer(tonumber(info.pid))
        if ply then
            ply.chat_account = ply.pid
            ply.chat_psw = ply.pid
            Rpc:chat_account_info_ack(ply, ply.chat_account, ply.chat_psw)
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
    print( "ack_tool", sn )
end

function city_break( self, attacker )
    self:release_all_prisoner()
    self:wall_fire( 1800 )
end

function vip_add_exp( self, exp )
    if exp <= 0 then return end
    exp = self.vip_exp + exp
    self.vip_exp = exp

    local lv = self.vip_lv
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
        self.vip_lv = tolv
        local src = resmng.get_conf( "prop_vip", lv)
        local remain = self:rem_buf( src.Buf )
        self:add_buf( node.Buf, remain + ( tolv - lv ) * 24 * 3600 )
        self:pre_tlog("PlayerVipExpFlow",exp,lv,0,0)
        local pack = {}  ----  display 
        pack.mode = DISPLY_MODE.VIP
        pack.lv = tolv
        self:add_to_do("display_ntf", pack)
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

function vip_enable( self, dura )
    local conf = resmng.get_conf( "prop_vip", self.vip_lv )
    local buf = self:get_buf( conf.Buf )
    if buf then
        self:rem_buf( buf[1], buf[3] )
        self:add_buf( conf.Buf, buf[3] - gTime + dura )
    else
        self:add_buf( conf.Buf, dura )
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



--function report_new( self, mode, val )
--    if mode < MAIL_REPORT_MODE.GATHER or mode > MAIL_REPORT_MODE.LOSTTEMPLE then return end
--    local maxid = self.report_max
--    if not maxid then
--        maxid = 0
--        for _, v in pairs( self.report_idx ) do
--            if v > maxid then maxid = v end
--        end
--    end
--    maxid = maxid + 1
--    val.tm = gTime
--    val.idx = maxid
--    self.report_idx[ mode ] = maxid
--    self.report_idx = self.report_idx
--
--    local db = dbmng:getOne()
--    local tab = string.format("report%d", mode)
--    --db[tab]:update( {_id=self.pid}, { ["$push"]={ vs={["$each"]={val}, ["$slice"]=-20 }} }, true )
--    --todo
--    db[tab]:update( {_id=self.pid}, { ["$push"]={ vs=val}}, true )
--
--
--    --dumpTab( val, "report" )
--    if self:is_online() then
--        Rpc:report_notify( self, mode, val )
--    end
--end
--

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

        Rpc:load_rank( self, idx, ver, 0, info )
        return
    end

    local ver, info = rank_mng.load_rank( idx )
    local pos = 0

    local prop = resmng.prop_rank[idx]
    if prop then
        if prop.IsPerson == 1 then
            pos = rank_mng.get_rank( idx, self.pid )
        elseif self.uid > 0 then
            pos = rank_mng.get_rank( idx, self.uid ) or 0
        end
    end

    if ver == version then
        Rpc:rank_pos( self, idx, pos )
        return
    end
    Rpc:load_rank( self, idx, ver, pos, info )
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

function set_client_parm(self, key, data)

    if key == "curguiding"  then self:pre_tlog("NewPlayerNode",tonumber(data) or 0 ) return end
    if key == "guide_skip_class" then self:pre_tlog("NewPlayerSkipNode",tonumber(data) or 0) return end

    local info = CLIENT_PARM[key]
    if info == nil then
        return
    end

    if string.len(data) > info then
        return
    end

    gPendingSave.client_parm[self.pid][key] = data
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
    local db = dbmng:getOne()
    local info = db.client_parm:findOne({_id = self.pid})
    local tab = {}
    for k, v in pairs(info or {}) do
        if k ~= "_id" then
            tab[k] = v
        end
    end
    return tab
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

    for _, range in pairs(SEARCH_RANGE) do
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
        info.officer = p.officer
        info.vip_lv = p.vip_lv
        info.pow = p.pow
        info.culture = p.culture

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
    local key = string.format( "msg_%s", what )
    db[ key ]:update( {_id=self.pid}, { ["$push"] = { msgs={ ["$each"] = {info}, ["$slice"]=-20}}}, true )

    local info = db:runCommand( "getLastError" )
    dumpTab( info, "add_msg" )

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
        local eids = get_around_eids( self.eid, range )
        local infos = {}
        for _, eid in pairs( eids ) do
            local e = get_ety( eid )
            if e then
                table.insert( infos, {eid, e.propid, e.x, e.y } )
            end
        end
        dumpTab( infos, "query_around" )
        Rpc:query_around( self, param, infos )
    end
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

---cross act
function cross_act_st_req(self)
    cross_act.cross_act_st_req(self)
end

function world_chat_task(self)
    task_logic_t.process_task(self, TASK_ACTION.WORLD_CHAT, 1)
end

function cross_npc_info_req(self)
    Rpc:callAgent(gCenterID, "cross_npc_info_req", self.pid)
end

function gold_to_res( self, id, num )
    if ( id >= 1 and id <= 4 ) or ( id == resmng.DEF_RES_SILVER ) then
        local need = calc_buyres_gold( num, id )
        if need > self.gold then return end
        self:dec_gold( need, VALUE_CHANGE_REASON.BUY_RES )
        self:do_inc_res_protect( id, num, VALUE_CHANGE_REASON.BUY_RES )
        reply_ok(self, "gold_to_res", id)
    end
end


function add_to_do(self, command, ...)
    if self:is_online() then
        player_t[ command ]( self, ... )
    else
        self.ntodo = ( self.ntodo or 0 ) + 1
        local id = bson.objectid()
        local task = { _id = id, pid = self.pid, command = command, time = gTime, args = { ... } }
        gPendingInsert.todo[ id ] = task
    end
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

function set_yueka(self)
    local sale = gTime - self.tm_create
    local tmp_level = 0
    if sale <= YUEKA_SALE_TIME then --前3天第一档月卡
        tmp_level = 1
    else
        tmp_level = 2
    end
    local cur_day = get_days(gTime)
    if cur_day > self.tm_yueka_end then
        --第一次买
        self.tm_yueka_start = cur_day
        self.tm_yueka_end = cur_day + YUEKA_TOTAL_DAYS - 1 --减去今天能够领奖
        self.yueka_level = tmp_level
    else
        if self.yueka_level ~= tmp_level then
            --月卡出错日志
            return
        end
        --续费
        self.tm_yueka_end = self.tm_yueka_end + YUEKA_TOTAL_DAYS
    end

end

function get_yueka_award(self)
    local cur_day = get_days(gTime)
    if cur_day > self.tm_yueka_end or cur_day <= self.tm_yueka_cur then
        return
    end
    --领取
    self.tm_yueka_cur = cur_day
    local get_day = (cur_day - self.tm_yueka_start) % YUEKA_TOTAL_DAYS
    if get_day == 0 then
        get_day = YUEKA_TOTAL_DAYS
    end
    local id = self.yueka_level * 1000 + get_day
    local prop_yueka = resmng.get_conf("prop_month_card", id)
    if prop_yueka == nil then
        --月卡日志
        return
    end
    self:add_bonus(prop_yueka.Item[1], prop_yueka.Item[2], VALUE_CHANGE_REASON.REASON_YUEKA)
end

function buy_yueka(self)
    self:set_yueka()
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
    Rpc:get_server_tag_ack(self, tag)
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


