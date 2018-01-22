module("player_t")

function ache_info_req(self)
    local info = {}
    info.count = self:get_count()
    info.ache = self:get_ache()
    info.ache_point = self.ache_point
    Rpc:ache_info_ack(self, info)
end 

function is_already_ache(self, idx)
    local ache_stat = self:get_ache()
    if ache_stat[idx] then return true end
end


function get_ache_reward(self, idx)
    local aches = self:get_ache()
    if aches[ idx ] then return end

    local aconf = resmng.get_conf( "prop_achievement", idx )
    if not aconf then return end

    local var = aconf.Var
    if var == resmng.ACH_LEVEL_CASTLE then
        if self:get_castle_lv() < aconf.Count then return end
    elseif var == resmng.ACH_LEVEL_PLAYER then
        if self.lv < aconf.Count then return end
    else
        if self:get_count( var ) < aconf.Count then return end
    end
    
    aches[ idx ] = gTime
    gPendingSave.ache[ self.pid ][ idx ] = gTime
    Rpc:set_ache( self, idx, gTime )

    local reward = aconf.Reward
    if reward then self:add_bonus( "mutex_award", reward, VALUE_CHANGE_REASON.REASON_ACHE) end

    local point = 0
    local confs = resmng.prop_achievement
    for k, v in pairs( aches ) do
        if k ~= "_id" then
            local conf = confs[ k ]
            if conf then
                point = point + conf.Point
            elseif type(k) == "string" then
                WARN( "[GET_ACHE_REWARD], id,%s, pid,%d", k, self.pid )
            else
                WARN( "[GET_ACHE_REWARD], id,%d, pid,%d", k, self.pid )
            end
        end
    end
    self.ache_point = point

    ache_info_req(self)
    try_upgrade_title( self )
    INFO( "[ACHE], pid=%d, idx=%d", self.pid, idx )
end


function try_upgrade_title( self )
    if self.title == 0 then return end

    local conf = resmng.get_conf( "prop_title", self.title )
    if not conf then return end

    local nidx = conf.NextID
    if not nidx then return end

    local nconf = resmng.get_conf( "prop_title", nidx )
    if not nconf then return end

    if self.ache_point >= nconf.Point then
        self.title = nidx
        self:rem_buf( conf.Buff )
        self:add_buf( nconf.Buff, -1 )
    end
end


function use_title_req(self, title)
    if title == self.title then return end

    local nconf = resmng.get_conf( "prop_title", title )
    if not nconf then return end
    if self.ache_point < nconf.Point then return end
    for k, v in pairs( nconf.Achievement or {} ) do
        if not is_already_ache( self, v ) then return end
    end

    if self.title > 0 then
        local conf = resmng.get_conf( "prop_title", self.title ) 
        if conf then
            if conf.Buff then
                self:rem_buf( conf.Buff )
            end
        end
    end

    self.title = title
    if nconf.Buff then self:add_buf( nconf.Buff, -1 ) end
end

function rem_title_req(self, idx)
    if self.title > 0 then
        local conf = resmng.get_conf( "prop_title", self.title )
        if conf then
            if conf.Buff then
                self:rem_buf( conf.Buff )
            end
        end
    end
    self.title = 0
end

function get_ache( self, id )
    if not self._ache then
        local db = self:getDb()
        local info = db.ache:findOne({_id=self.pid})
        if not self._ache then self._ache = info or {} end
    end
    if id then return self._ache[ id ] else return self._ache end
end


function get_count( self, id )
    if not self._count then 
        local db = self:getDb()
        local info = db.count:findOne( {_id = self.pid } )
        if not self._count then self._count = info or {} end
    end

    if id then 
        return self._count[ id ] or 0 
    else 
        return self._count 
    end
end

gPendingCount = gPendingCount or {}
function add_count( self, key, val )
    if self._count then
        do_add_count( self, key, val )
    else
        local pid = self.pid
        local node = gPendingCount[ pid ]
        if not node then
            node = {}
            gPendingCount[ pid ] = node
            action( handle_pending_count, pid )
        end
        table.insert( node, { key, val } )
    end
end

function handle_pending_count( pid )
    local p = getPlayer( pid )
    if p then
        local node = gPendingCount[ pid ]
        gPendingCount[ pid ] = nil
        for _, v in pairs( node ) do
            do_add_count( p, v[1], v[2] )
        end
    end
end

function do_add_count( self, key, val )
    local counts = self:get_count()
    INFO( "[ADD_COUNT], pid=%d, key=%d, old=%d, add=%d", self.pid, key, counts[key] or 0, val or 0 )
    counts[ key ] = ( counts[ key ] or 0 ) + val
    gPendingSave.count[ self.pid ][key] = counts[ key ]
    Rpc:set_count( self, key, counts[ key ] )
    if key == resmng.ACH_COUNT_KILL_POW then union_mission.ok(self,UNION_MISSION_CLASS.KILL,val) end
end

