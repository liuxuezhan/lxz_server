module("rank_mng", package.seeall)

gRanks = gRanks or {}

-- tops, 前100， 排好序的数组
-- ranks, 前100， 以pid做key, val 是排行
-- alls, 前1000， 以pid做key

function init()
    gRanks = {}
    local db = dbmng:getOne()
    for k, v in pairs( resmng.prop_rank ) do
        local sl = skiplist.new( k, table.unpack( v.Skeys ) )

        local t = { id=k, ntop=v.Num, nall=v.Limit, detail=rank_function[ v.IsPerson ], is_persion = v.IsPerson } -- infos, tops, ranks, time
        gRanks[ k ] = t
        local tab = string.format("rank%d", k )
        local info = db[tab]:find( {} )
        while info:hasNext() do
            local data = info:next()
            skiplist.insert( k, data._id, table.unpack( data.v ) )
        end
        load_rank(k)
    end
    --fill()
end

function load_rank( which )
    local node = gRanks[ which ]
    if not node then return gTime, {} end

    if node.tops then return node.time, node.tops end
    local info = skiplist.get_range_with_score( which, 1, node.ntop )
    if info then
        local oinfos = node.infos or {}
        local ninfos = {}
        local tops = {}
        local ranks = {}

        local count = #info
        for i = 1, count, 2 do
            local id = info[ i ]
            local score = info[ i + 1 ]

            local p = oinfos[ id ]
            if not p then
                p = node.detail( id, score )
            end
            ninfos[ id ] = p
            table.insert( tops, p )
            ranks[ id ] = #tops
        end
        node.tops = tops
        node.infos = ninfos
        node.ranks = ranks
        node.time = gTime

        return node.time, node.tops
    end
    return gTime, {}
end

function add_node( idx, key, val, info, init )

end

function add_data( idx, key, data, init )
    local node = gRanks[ idx ]
    if not node then return end

    key = tonumber( key )

    if node.is_persion == 0 then
        local union = unionmng.get_union( key )
        if not union then return end
        if union:is_new() then return end
    end

    local rank = skiplist.insert( idx, key, table.unpack( data ) )

    if not init then
        local tab = string.format( "rank%d", idx )
        gPendingSave[tab][ key ].v = data 
    end

    --if node.tops and node.infos[ key ] then
    --    node.infos[ key ][ 2 ] = data[ 1 ]
    --end

    if node.infos and node.infos[ key ] then
        node.infos[ key ] = nil
    end


    if rank == 0 then
        node.time = gTime
    elseif rank <= node.ntop then
        node.tops = nil
    end
end

function rem_data( idx, key )
    local node = gRanks[ idx ]
    if not node then return end

    key = tonumber( key )
    local rank = skiplist.delete( idx, key )
    local tab = string.format( "rank%d", idx )
    gPendingDelete[tab][ key ] = 1

    if rank then
        if node.tops then
            if node.infos and node.infos[ key ] then node.infos[ key ] = nil end
            if rank > 0 and rank <= node.ntop then node.tops = nil end
        end
    end
end


function change_name( idx, key, name )
    local node = gRanks[ idx ]
    if node then
        if node.tops then
            local i = node.infos[ key ]
            if i then
                i[3] = name
                node.time = gTime
            end
        end
    end
end

function change_icon( idx, key, icon )
    local node = gRanks[ idx ]
    if node then
        if node.tops then
            local i = node.infos[ key ]
            if i then
                i[4] = icon
                node.time = gTime
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
rank_function[1] = function( id, score )
    local info = { id, score }
    local pid = id
    local ply = getPlayer( pid )
    if ply then
        if  pid < 10000 then pause() end
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

rank_function[0] = function( id, score )
    local info = {id, score}
    local uid = id
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

    print( "rank fill done" )
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

