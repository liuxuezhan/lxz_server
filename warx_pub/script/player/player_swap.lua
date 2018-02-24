module("player_t")

function can_swap_out( self, urgent )
    if is_online( self ) then return end
    if self.tm_login == 0 then return end
    if self.uid > 0 then return end
    if next( self.busy_troop_ids ) then return end
    if next( self.troop_comings or {} ) then return end
    if self.emap ~= gMapID then return end

    local clv = self.propid % 1000
    if clv > 5 then return end
    local clv2loss = {
        [1] = 14400, -- 1 hour
        [2] = 14400, -- 2 hour
        [3] = 14400,-- 4 hour
        [4] = 28800, -- 8 hour
        [5] = 57600, -- 16 hour
    }

    local offtm = gTime - math.max( math.max( self.tm_login, self.tm_logout ), self.tm_create )
    if offtm < clv2loss[ clv ] then return end

    local acc = gAccounts[ self.account ]
    if acc then
        local count = 0
        for k, v in pairs( acc ) do
            count = count + 1
        end
        if count > 1 then return end
        local tm_swap = acc[ self.pid ].tm_swap
        if tm_swap and gTime - tm_swap < 10 then return end
    end

    local hs = self:get_hero()
    for _, v in pairs( hs ) do
        local status = v.status
        if status == HERO_STATUS_TYPE.BEING_CAPTURED then return end
        if status == HERO_STATUS_TYPE.BEING_IMPRISONED then return end
        if status == HERO_STATUS_TYPE.BEING_EXECUTED then return end
    end
    return 1
end

function swap_out( self )
    local pid = self.pid
    local acc = gAccounts[ self.account ]
    if acc then
        local tm_swap = acc[ pid ] and acc[ pid ].tm_swap
        if tm_swap and gTime - tm_swap < 5 then return end
    end

    local hmng = heromng._heros
    local hs = self:get_hero()
    for k, v in pairs( hs or {}) do hmng[ v._id ] = nil end

    troop_mng.troop_id_map[ self.my_troop_id ] = nil

    local tms = get_player_timer( self )
    if tms then
        for k, v in pairs( tms ) do timer.del( v._id  ) end
        gPendingInsert.player_timer[ pid ] = { _id=pid, tms=tms }
    end

    rem_ety( self.eid )
    gPlys[ pid ] = nil

    local eid = self.eid
    self.eid = 0
    gPendingSave.player[ pid ].eid = 0
    rank_mng.rem_person_data( pid )
    gTotalCreate = gTotalCreate - 1

    local acc = gAccounts[ self.account ]
    if acc then acc[ pid ].tm_swap = gTime end

    WARN( "[SWAP], out, pid,%d, openid,%s, eid,%d, lv,%d, total,%d", pid, self.account, eid, self.propid%1000, gTotalCreate )

    return 1
end


function restore_player_timer( self )
    local pid = self.pid
    local db = dbmng:getOne()
    local info = db.player_timer:findOne({_id=pid})
    if info then
        local sfunc = function ( A, B ) return A.over < B.over end
        local tms = info.tms
        if tms then
            table.sort( tms, sfunc )
            for _, node in ipairs( tms ) do 
                node.delete = nil
                timer.reopen_timer( node ) 
            end
        end
        gPendingDelete.player_timer[ pid ] = 1
    end
end

function get_near_pos( self )
    local conf = resmng.get_conf( "prop_world_unit", self.propid )
    if conf then
        local x, y = c_get_ply_pos_near( self.x, self.y, conf.Size )
        if x then return x, y end
        local x, y = c_get_pos_born( self.culture )
        return x, y
    end
end


function swap_in( pid )
    local db = dbmng:getOne()
    local info = db.player:findOne({_id=pid})
    if info and info.pid and info.eid == 0 then
        local eid = get_eid()
        local p = player_t.wrap( info )

        p._pro.eid = eid
        gPendingSave.player[ pid ].eid = eid

        local acc = gAccounts[ p.account ]
        if acc then acc[ pid ].tm_swap = gTime end
        
        rawset(p, "eid", eid)
        rawset(p, "pid", pid)
        rawset(p, "size", 4)
        rawset(p, "uname", "")
        restore_home_troop( p )

        gEtys[ p.eid ] = p
        gPlys[ p.pid ] = p
        initEffect( p )

        restore_player_timer( p )

        local x, y = get_near_pos( p )
        if x then
            p.x = x
            p.y = y
            etypipe.add( p )
            gTotalCreate = gTotalCreate + 1
            WARN( "[SWAP], in, pid,%d, openid,%s, eid,%d, lv,%d, total,%d", p.pid, p.account, eid, p.propid%1000, gTotalCreate )
            return p

        else
            gEtys[ p.eid ] = nil
            gPlys[ p.pid ] = nil
            p.eid = 0
            gPendingSave.player[ p.pid ].eid = 0
            WARN( "[SWAP], in, pid,%d, openid,%s, eid,%d, lv,%d, total,%d, fail", p.pid, p.account, eid, p.propid%1000, gTotalCreate )
        end
    end
end


