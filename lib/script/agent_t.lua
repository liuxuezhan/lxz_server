module( "agent_t" )

function agent_move_eye( self, pid, x, y )
    c_mov_eye(pid, x, y)
end


function agent_remove_eye( self, pid )
    c_rem_eye( pid )
end


function agent_migrate( self, pid, x, y, data )
    local from = self.pid
    if c_map_test_pos( x, y, 4 ) ~= 0 then
        Rpc:callAgent( from, "agent_migrate_ack", pid, -1 ) 
        return
    end

    local eid = get_eid_ply()

    local pro = data.pro
    pro.eid = eid
    pro.map = gMapID
    local ply = player_t.new( pro )
    rawset( ply, "eid", eid )

    local build = data.build
    local bs = {}
    for k, v in pairs( build ) do
        bs[ v.idx ] = build_t.new( v )
    end
    ply._build = bs

    local item = data.item 
    gPendingInsert.item[ pid ] = item
    ply.item = item

    local arm = data.arm
    local troop = troop_mng.create_troop(TroopAction.DefultFollow, ply, ply)
    ply.my_troop_id = troop._id
    for id, num in pairs( arm ) do
        troop:add_soldier( id, num )
    end
    ply:initEffect()

    player_t._cache[pid] = pro
    gEtys[ eid ] = ply
    ply.size = 4
    etypipe.add(ply)

    Rpc:callAgent( from, "agent_migrate_ack", pid, 0 ) 
end


