module("rank_mng")

gRanks = gRanks or {}

function init() 
    gRanks = {}
    local db = dbmng:getOne()
    for k, v in pairs( resmng.prop_rank ) do
        local t = { 
           -- sl=skiplist(), 
            alls={}, ntop=v.Num, nall=v.Limit, top=0, all=0, num=0, skey=v.Skeys[1], skeys=v.Skeys, detail=rank_function[ v.IsPerson ] }
            gRanks[ k ] = t

            local tab = string.format("rank%d", k )
            local info = db[tab]:find( {} )
            while info:hasNext() do
            local data = info:next()
            local key = data._id
            table.remove( data.v, 1 )
            add_data( k, key, data.v )
        end
        load_rank(k)
    end
    --fill()
end

function rem_data( idx, key )
    local node = gRanks[ idx ]
    if not node then return end

    key = tonumber( key )
    local n = node.alls[ key ]
    if n then
        local tab = string.format( "rank%d", idx )

        local score = n[2] * node.skey
        node.sl:delete( score, tostring( key ) )

        node.alls[ key ] = nil
        gPendingDelete[tab][ key ] = 1

        if n.tops then
            if n.ranks[ key ] then 
                n.ranks[ key ] = nil 
                node.tops = nil
            end
        end
    end
end

function add_data( idx, key, data )
    local node = gRanks[ idx ]
    if not node then return end

    key = tonumber( key )

    local tab = string.format( "rank%d", idx )

    local n = node.alls[ key ]
    if n then
        local old = n[2] * node.skey
        local new = data[1] * node.skey
        if old == new then
            table.insert( data, 1, key )
            node.alls[ key ] = data
            gPendingSave[tab][ key ].v = data

        else
            local top = node.top
            node.sl:delete( old, tostring( key ) )
            node.sl:insert( new, tostring( key ) )
            table.insert( data, 1, key )
            node.alls[ key ] = data
            gPendingSave[tab][ key ].v = data

            if node.tops then
                if top == 0 or old <= top or new <= top then 
                    if node.ranks then
                        local idx = node.ranks[ key ]
                        if idx then
                            local pre = node.tops[ idx - 1 ]
                            local nxt = node.tops[ idx + 1 ]

                            local nochg = false
                            if idx == 1 and nxt and new <= nxt[2] * node.skey then
                                nochg = true
                            elseif pre and nxt and new >= pre[2] * node.skey and new <= nxt[2] * node.skey then
                                nochg = true
                            end
                            if nochg then
                                node.tops[ idx ] = node.detail( data )
                                node.time = gTime
                                return
                            end
                        end
                    end
                    node.tops = nil
                end
            end
        end
        return
    end

    if data[1] == 0 then return end
    
    local score = data[1] * node.skey
    table.insert( data, 1, key )

    if node.num <= node.nall then
        node.tops = nil
        --node.sl:insert( score, tostring(key) )
        node.alls[ key ] = data
        gPendingSave[tab][ key ].v = data
        node.num = node.num + 1

    else
        if node.top == 0 or node.all == 0 then load_rank( idx ) end
        if node.num > 2 * node.nall then load_rank( idx ) end

        if score <= node.all then
            if score <= node.top then node.tops = nil end
            node.sl:insert( score, tostring(key) )
            node.alls[ key ] = data
            gPendingSave[tab][ key ].v = data
            node.num = node.num + 1
        end
    end
end

function get_node(idx)
    local node = gRanks[ idx ]
    return node
end

function load_rank( which )
    local node = gRanks[ which ]
    if not node then return gTime, {} end

    if node.tops then return node.time, node.tops end

    print( "recalc rank", which )

    local sl = node.sl
    if not sl then
            return gTime,{}
    end
    local count = sl:get_count();
    local infos = sl:get_rank_range( 1, node.nall )

    local ntop = node.ntop
    local nall = node.nall

    node.all = 0
    node.top = 0

    local tops = {}
    local alls = node.alls
    local score = 0
    local num = 0
    for idx, v in ipairs( infos ) do
        local key = tonumber( v )
        local info = alls[ key ]
        num = num + 1
        if idx < ntop then
            table.insert( tops, info )

        elseif idx == ntop then
            table.insert( tops, info )
            score = info[2]
            node.top = info[2] * node.skey

        elseif idx < nall then
            if info[ 2 ] == score then table.insert( tops, info ) end

        elseif idx == nall then
            node.all = info[2] * node.skey

        else
            break
        end
    end
    node.num = num

    local skeys = node.skeys 
    local sfunc = function( A, B ) 
        for k, v in ipairs( skeys ) do
            local diff = A[ k+1 ] * skeys[ k ] - B[ k+1 ] * skeys[ k ]
            if diff ~= 0 then return diff < 0 end
        end
        return A[1] < B[1]
    end
    table.sort(tops, sfunc )

    local res = {}
    for i = 1, node.ntop, 1 do
        local t = tops[ i ]
        if not t then break end
        local n = node.detail( t )
        table.insert( res, n)
    end

    local ranks = {}
    for k, v in ipairs( tops ) do ranks[ v[1] ] = k end

    node.tops = res
    node.ranks = ranks

    local tab = string.format( "rank%d", which )
    local alls = node.alls
    local func_cb = function ( key )
        key = tonumber( key )
        gPendingDelete[ tab ][ key ] = 1
        alls[ key ] = nil
    end
    sl:delete_by_rank( num + 1, count + 1, func_cb )
    node.time = gTime
    return node.time, node.tops
end

function get_rank( idx, key )
    local node = gRanks[ idx ]
    if node then
        if node.tops then 
            if node.ranks[ key ] then return node.ranks[ key ] end
        end

        local n = node.alls[ key ]
        if not n then return 0 end

        local score = n[2] * node.skey 
        local rank = node.sl:get_rank( score,  tostring(key) )
        if rank and rank <= node.nall then return rank end
    end
    return 0
end

function get_range(idx, start, tail)
    local node = gRanks[ idx ]
    if node then
        local sl = node.sl
        if sl then
            local count = sl:get_count();
            local infos = sl:get_rank_range( start, tail, node.nall )
            return infos
        end
    end
end

function get_score(idx, key)
    local node = gRanks[ idx ]
    if node then
        local n = node.alls[ key ]
        if not n then return 0 end

        return n[2]
    end
end


rank_function = {}
rank_function[1] = function( data )
    local info = {}
    info[1] = data[1] -- key, pid
    info[2] = data[2] -- score, lv

    local pid = data[1]
    local ply = getPlayer( pid )
    if ply then
        table.insert( info, ply.name )
        table.insert( info, ply.photo )
        local u = ply:get_union()
        if u then
            table.insert( info, u.alias )
            table.insert( info, u.name )
        else
            table.insert( info, "" )
            table.insert( info, "" )
        end
    end
    return info
end

rank_function[0] = function( data )
    local info = {}
    info[1] = data[1] -- pid
    info[2] = data[2] -- lv
    --info[3] = data[3] -- time

    local uid = data[1]
    local u = unionmng.get_union( uid )
    if u then
        table.insert( info, u.flag )
        table.insert( info, u.alias )
        table.insert( info, u.name )
        local leader = getPlayer( u.leader )
        if leader then
            table.insert( info, leader.name )
        else
            table.insert( info, "" )
        end
    else
        table.insert( info, 1 )
        table.insert( info, "" )
        table.insert( info, "" )
        table.insert( info, "" )
    end
    return info
end


function fill()
    print( "rank fill" )
    restore_handler.load_count()

    for k, v in pairs( resmng.prop_rank ) do
        clear( k )
    end

    for k, v in pairs( gPlys ) do
        add_data( 1, k, { v:get_castle_lv(), v.tm_lv_castle } )
        add_data( 2, k, { v.lv, v.tm_lv} )
        add_data( 3, k, { v:get_pow() } )
        add_data( 4, k, { v:get_count( resmng.ACH_COUNT_KILL ) } )
    end

    for k, v in pairs( unionmng.get_all() ) do
        if not v.new_union_sn then
            add_data( 5, k, { v:get_pow() } )
            add_data( 6, k, { v.kill } )
        end
    end

    for k, v in pairs( resmng.prop_rank ) do
        load_rank( k )
    end
    print( "rank fill done" )
end


function clear( idx )
    local node = gRanks[ idx ]
    if node then
        node.sl = nil
        node.sl = skiplist()
        node.tops = {}
        node.alls = {}
        node.top = 0
        node.all = 0
        node.num = 0
        node.time = gTime

        local tab = string.format( "rank%d", idx )
        local db = dbmng:getOne()
        db[ tab ]:delete( {} )
        gPendingSave[ tab ] = nil
        local info = db:runCommand("getLastError")
    end
end

function change_name( idx, key, name )
    local node = gRanks[ idx ]
    if node then
        if node.ranks and node.tops then
            local i = node.ranks[ key ]
            if i then
                local t = node.tops[ i ]
                if t then
                    local conf = resmng.get_conf( "prop_rank", idx )
                    local detail = conf.IsPerson
                    if detail == 1 then
                        t[3] = name
                        node.time = gTime
                    end
                end
            end
        end
    end
end

