module("tribute_exchange", package.seeall)

g_exchanges = g_exchanges or {}
--g_exchanges = {
--    [NPC_CITY_1] = {
--        tick = gTime + TRIBUTE_EXCHANGE_LOOP,
--        its = {
--            [ITEM_7001001] = { value=5, total=100, special=0, id=1 }, 
--        }
--    }
--}

g_tribute_special = g_tribute_special or {}
--g_tribute_special = { [ ITEM_7001001 ] = 1 }


function update_price( city )
    local propid = city.propid
    local exchgs = g_exchanges[ propid ]
    if not exchgs then 
        exchgs = {
            tick = gTime + TRIBUTE_EXCHANGE_LOOP,
            its = {}
        }
        g_exchanges[ propid ] = exchgs
    end
    exchgs.tick = gTime + TRIBUTE_EXCHANGE_LOOP

    local its = {}
    for id, v in pairs( resmng.prop_tribute_exchange ) do
        if v.City == propid then
            local item = v.Item
            local it = exchgs.its[ item ]
            if not it then
                if g_tribute_special[ item ] then
                    it = { value = v.Open2, total = 0, special = 1, id = id, prev = 0 }
                else
                    it = { value = v.Open, total = 0, special = 0, id = id, prev = 0 }
                end
            else
                local value = it.value
                local total = it.total
                local prev = it.prev or 0
                --if total > v.Step then value = value - v.Delta else value = value + v.Delta end

                if total > prev then 
                    value = value - v.Delta 
                elseif total < prev then
                    value = value + v.Delta 
                end

                if g_tribute_special[ item ] then
                    if value > v.Max2 then value = v.Max2 end
                    if value < v.Min2 then value = v.Min2 end
                    it.special = 1
                else
                    if value > v.Max then value = v.Max end
                    if value < v.Min then value = v.Min end
                    it.special = 0
                end
                it.value = value
                it.prev = it.total
                it.total = 0
                it.id = id
            end
            its[ item ] = it
        end
    end
    exchgs.its = its

    gPendingInsert.tribute_exchange[ propid ] = exchgs

    return exchgs
end


function reset_special( )
    local old = g_tribute_special
    local class = ITEM_CLASS.TRIBUTE
    local its = {}
    for id, item in pairs( resmng.prop_item ) do
        if item.Class == class then
            if not old[ id ] then
                table.insert( its, id )
            end
        end
    end
    local new = {}
    local idx = math.random( 1, #its )
    local id = table.remove( its, idx )
    new[ id ] = 1

    idx = math.random( 1, #its )
    id = table.remove( its, idx )
    new[ id ] = 1

    g_tribute_special = new
    set_sys_status( "tribute_special", new )

    local old_citys = g_exchanges

    local p_tribute_exchange = resmng.prop_tribute_exchange
    local citys = {}
    for cid, city in pairs( resmng.prop_world_unit ) do
        if city.Class == EidType.NpcCity then
            if old_citys[ cid ] then
                citys[ cid ] = old_citys[ cid ]
                local its = citys[ cid ].its

                for tid, _ in pairs( old or {} ) do
                    local item = its[ tid ]
                    if item then
                        item.special = 0
                        local info = p_tribute_exchange[ item.id ]
                        if info then
                            item.value = info.Open
                        end
                    end
                end

                for tid, _ in pairs( new or {} ) do
                    local item = its[ tid ]
                    if item then
                        local info = p_tribute_exchange[ item.id ]
                        if info then
                            item.special = 1
                            item.value = info.Open2
                        end
                    end
                end

            else
                local eid = npc_city.get_npc_eid_by_propid( cid )
                if eid then
                    local dest = get_ety( eid )
                    if is_npc_city( dest ) then
                        local exchgs = update_price( dest )
                        citys[ cid ] = exchgs
                    end
                end
            end

            gPendingInsert.tribute_exchange[ cid ] = citys[ cid ]
        end
    end
    g_exchanges = citys
end


function check_exchange( city, res, tribute )
    if not is_npc_city( city ) then return end
    local its = g_exchanges[ city.propid ]
    if not its then return end
    its = its.its

    local total_res = 0
    local res_rate = RES_RATE
    for mode, num in pairs( res ) do
        if num > 0 then
            total_res = total_res + RES_RATE[ mode ] * num
            INFO( "check_exchange, res, mode=%d, num=%d", mode, num )
        end
    end

    local total_tributes = 0
    for id, num in pairs( tribute ) do
        if num > 0 then
            local it = its[ id ]
            if not it then return end
            total_tributes = total_tributes + it.value * num
            INFO( "check_exchange, tri, mode=%d, num=%d, value=%d", id, num, it.value )
        end
    end

    total_tributes = total_tributes * RES_RATE[ 4 ]
    if total_res ~= total_tributes then return end

    return true
end

function get_exchange( city )
    local propid = city.propid
    local node = g_exchanges[ propid ]

    if not node then
        update_price( city )
    elseif node.tick < gTime then
        update_price( city )
    end

    return g_exchanges[ propid ]
end

