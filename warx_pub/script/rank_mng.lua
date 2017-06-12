module("rank_mng", package.seeall)

gRanks = gRanks or {}

gRankInfoPlayer = gRankInfoPlayer or {}
gRankInfoUnion = gRankInfoUnion or {}

-- tops, 前100， 排好序的数组
-- ranks, 前100， 以pid做key, val 是排行

function init()
    gRanks = {}
    local db = dbmng:getOne()
    for k, v in pairs( resmng.prop_rank ) do
        local sl = skiplist.new( k, table.unpack( v.Skeys ) )
        local t = { id=k, ntop=v.Num, nall=v.Limit, detail=rank_function[ v.IsPerson ], is_person = v.IsPerson } -- infos, tops, ranks, time
        gRanks[ k ] = t
        local tab = string.format("rank%d", k )
        local info = db[tab]:find( {} )
        local is_person = v.IsPerson
        while info:hasNext() do
            local data = info:next()
            if data._id >= 10000 then
                skiplist.insert( k, data._id, table.unpack( data.v ) )
            end
        end
        load_rank(k)
    end
end

function reset_rank()
    for k, v in pairs( resmng.prop_rank ) do
        clear( k )
    end
end

function load_rank( which )
    local node = gRanks[ which ]
    if not node then return gTime, {} end

    if node.tops then return node.time, node.tops end
    local info = skiplist.get_range_with_score( which, 1, node.ntop )
    if info then
        local tops = {}
        local ranks = {}

        local count = #info
        for i = 1, count, 2 do
            local id = info[ i ]
            local score = info[ i + 1 ]
            local detail = get_info( node.is_person, id, true )
            local p = { score, detail }
            table.insert( tops, p )
            ranks[ id ] = #tops
        end
        node.tops = tops        -- index to info
        node.ranks = ranks      -- key to index
        node.time = gTime

        return node.time, node.tops
    end
    return gTime, {}
end

function get_info( is_person, id, init )
    if is_person == 0 then
        local info = gRankInfoUnion[ id ]
        if info then return info end

        local info = rank_function[ 0 ]( id )
        if info then 
            gRankInfoUnion[ id ] = info
            if not init then gPendingInsert.rank_info_union[ id ] = info end
            return info 
        end

        local db = dbmng:getOne()
        local info = db.rank_info_union:findOne( {_id=id } )
        if info then
            info._id = nil
            gRankInfoUnion[ id ] = info
            return info
        end

        db = dbmng:getGlobal()
        local info = db.unions:findOne( {_id=id} )
        if info then
            local map = info.emap
            if map then
                local info =  remote_func(map, "get_rank_detail", {"union", id})
                if info then
                    gRankInfoUnion[ id ] = info
                    if not init then gPendingInsert.rank_info_union[ id ] = info end
                    return info
                end
            end
        end

    elseif is_person == 1 then
        local info = gRankInfoPlayer[ id ]
        if info then return info end

        local info = rank_function[ 1 ]( id )
        if info then 
            gRankInfoPlayer[ id ] = info
            if not init then gPendingInsert.rank_info_player[ id ] = info end
            return info 
        end

        local db = dbmng:getOne()
        local info = db.rank_info_player:findOne( {_id=id } )
        if info then
            info._id = nil
            gRankInfoPlayer[ id ] = info
            return info
        end

        db = dbmng:getGlobal()
        local info = db.players:findOne( {_id=id} )
        if info then
            local map = info.emap
            if map then
                local info = remote_func(map, "get_rank_detail", {"player", id})
                if info then
                    gRankInfoPlayer[ id ] = info
                    if not init then gPendingInsert.rank_info_player[ id ] = info end
                    return info
                end
            end
        end
    end
    return {}
end


function add_data( idx, key, data, init )
    local node = gRanks[ idx ]
    if not node then return end

    key = tonumber( key )

    if node.is_person == 0 then
        local union = unionmng.get_union( key )
        if not union then return end
        if union:is_new() then return end
    end

    local rank = skiplist.insert( idx, key, table.unpack( data ) )

    if not init then
        local tab = string.format( "rank%d", idx )
        gPendingSave[tab][ key ].v = data 
    end

    if rank then
        if rank == 0 and node.ranks and node.tops then
            rank = node.ranks[ key ]
            if rank then
                node.time = gTime
                local info = node.tops[ rank ]
                if info then
                    if info[2][1] == key then
                        info[1] = data[1]
                    end
                end
            end

        elseif rank <= node.ntop then
            node.tops = nil
        end
    end
end


function rem_data( idx, key )
    local node = gRanks[ idx ]
    if not node then return end

    key = tonumber( key )
    local rank = skiplist.delete( idx, key )
    local tab = string.format( "rank%d", idx )
    gPendingDelete[tab][ key ] = 1

    if rank and rank <= node.ntop then
        node.tops = nil
    end
end


function update_info_player( pid )
    local ninfo = rank_function[ 1 ]( pid )
    local oinfo = gRankInfoPlayer[ pid ]
    if oinfo then
        for k, v in pairs( ninfo ) do
            oinfo[ k ] = v
        end
    end
    gPendingInsert.rank_info_player[ pid ] = ninfo

    for k, v in pairs( gRanks ) do
        if v.is_person == 1 then
            if v.ranks and v.ranks[ pid ] then
                v.time = gTime
            end
        end
    end
end

function update_info_union( uid )
    local ninfo = rank_function[ 0 ]( uid )
    local oinfo = gRankInfoUnion[ uid ]
    if oinfo then
        for k, v in pairs( ninfo ) do
            oinfo[ k ] = v
        end
    end
    gPendingInsert.rank_info_union[ uid ] = ninfo

    for k, v in pairs( gRanks ) do
        if v.is_person ~= 1 then
            if v.ranks and v.ranks[ uid ] then
                v.time = gTime
            end
        end
    end
end


function get_rank( idx, key )
    local node = gRanks[ idx ]
    if node then
        if node.tops then
            if node.ranks[ key ] then return node.ranks[ key ] end
        end
        return skiplist.get_rank( idx, key ) or 0
    end
    return 0
end

function get_range(idx, start, tail)
    local node = gRanks[ idx ]
    if node then
        return skiplist.get_range( idx, start, tail )
    end
end


rank_function = {}
rank_function[1] = function( pid )
    -- pid, name, photo, alias, uname
    local ply = getPlayer( pid )
    if ply then
        local info = { pid }
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
        return info
    end
end


rank_function[0] = function( uid )
    -- uid, name, flag, alias, lname
    local u = unionmng.get_union( uid )
    if u then
        local info = { uid }
        table.insert( info, u.name )
        table.insert( info, u.flag )
        table.insert( info, u.alias )

        local leader = getPlayer( u.leader )
        if leader then
            table.insert( info, leader.name )
        else
            table.insert( info, "" )
        end
        return info
    end
end


function fill()
    --print( "rank fill" )
    --restore_handler.load_count()

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
        if not v:is_new() then
            add_data( 5, k, { v:get_pow() } )
            add_data( 6, k, { v.kill } )
        end
    end

    for k, v in pairs( resmng.prop_rank ) do
        load_rank( k )
    end

    --print( "rank fill done" )
end


function clear( idx )
    local node = gRanks[ idx ]
    if node then
        node.id = idx
        node.tops = nil
        node.infos = nil
        node.ranks = nil
        node.time = 0
        local tab = string.format( "rank%d", idx )
        local db = dbmng:getOne()
        db[ tab ]:delete( {} )
        gPendingSave[ tab ] = nil
        local info = db:runCommand("getLastError")
        skiplist.clear( idx )
    end
end

-- todo
function get_score( mode, key )
    return skiplist.get_score( mode, key )
end

