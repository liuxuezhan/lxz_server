module("custom_rank_mng", package.seeall)

ranks = ranks or {}
tops = tops or {}
refs = refs or {}

function init()
    local max_rank_id = 0
    for k, v in pairs(rank_mng.gRanks) do
        if k > max_rank_id then
            max_rank_id = k
        end
    end
    refs = createRef(1024, max_rank_id)
    load_from_db()
end

function load_from_db()
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = "custom_ranks"})
    if info then
        info._id = nil
        ranks = info
    end

    for k, v in pairs(ranks or {}) do
        load_rank(v)
    end
end

function load_rank(rank)
    local index = refs:ref()
    if nil == index then
        ERROR("[CustomRank]no more rank index when load rank %d", rank.id)
        return
    end
    rank.index = index
    local db  = dbmng:getOne()
    local sl = skiplist.new(rank.index, table.unpack(rank.skeys))
    local tab = get_table_name(rank.id)
    local info = db[tab]:find({})
    while info:hasNext() do
        local data = info:next()
        skiplist.insert(rank.index, data._id, table.unpack(data.v))
    end
end

function get_rank_id(class, mode, id)
    return class * 1000000 + mode * 1000 + id
end

function reset_rank(class)
    local dels = {}
    for k, v in pairs(ranks) do
        if nil == class or v.class == class then
            local tab = get_table_name(v.id)
            delete_col(tab)
            skiplist.clear(v.index)
            refs:unref(v.index)
            table.insert(dels, v.id)
        end
    end
    for k, v in pairs(dels) do
        ranks[v] = nil
        tops[v] = nil
    end
    gPendingInsert.status.custom_ranks = ranks
end

function update_top_cache(rank)
    local info = skiplist.get_range_with_score(rank.index, 1, rank.ntops)
    if not info then
        return
    end
    local the_tops = {}
    local the_ranks = {}
    local count = #info
    for i = 1, count, 2 do
        local id = info[i]
        local score = info[i + 1]
        local detail = _G[rank.getter].get_info(rank.mode, id)
        table.insert(the_tops, {score, detail})
        the_ranks[id] = #the_tops
    end
    local top = {}
    top.tops = the_tops
    top.ranks = the_ranks
    top.time = gTime
    tops[rank.id] = top
end

function create_rank(rank_id, skeys, ntops, class, mode, info_getter)
    if ranks[rank_id] then
        return
    end
    local index = refs:ref()
    if nil == index then
        ERROR("[CustomRank]no more rank index when load rank %d", rank.id)
        return
    end
    local rank = {
        id = rank_id,
        index = index,
        skeys = skeys,
        ntops = ntops,
        class = class,
        mode = mode,
        getter = info_getter or "custom_rank_mng"
    }
    ranks[rank_id] = rank
    gPendingSave.status.custom_ranks[rank_id] = rank
    local tab = get_table_name(rank_id)

    local sl = skiplist.new(rank.index, table.unpack(skeys))
end

function delete_rank(rank_id)
    local rank = ranks[rank_id]
    if not rank then
        return
    end

    ranks[rank_id] = nil
    tops[rank_id] = nil
    skiplist.clear(rank.index)
    refs:unref(rank.index)

    delete_col(get_table_name(rank_id))
    gPendingSave.status.custom_ranks = ranks
end

function get_table_name(rank_id)
    return string.format("custom_rank_%d", rank_id)
end

function add_data(rank_id, key, data, load_detail)
    local rank = ranks[rank_id]
    if not rank then
        WARN("[CustomRank] Rank %d hasn't been created, add data failed.", rank_id)
        return
    end

    local pos = skiplist.insert(rank.index, key, table.unpack(data))
    local tab = get_table_name(rank_id)
    gPendingSave[tab][key].v = data

    if pos then
        local top = tops[rank_id]
        if 0 == pos and top then
            pos = top.ranks[key]
            if pos then
                top.time = gTime
                local info = top.tops[pos]
                if info then
                    if info[2][1] == key then
                        info[1] = data[1]
                    end
                end
            end
        elseif pos <= rank.ntops then
            tops[rank_id] = nil

            if load_detail then
                action(_G[rank.getter].get_info, rank.mode, key)
            end
        end
    end
end

function rem_data(rank_id, key)
    local rank = ranks[rank_id]
    if not rank then
        WARN("[CustomRank] Rank %d hasn't been created, remove data failed.", rank_id)
        return
    end
    local pos = skiplist.delete(rank.index, key)
    local tab = get_table_name(rank_id)
    gPendingDelete[tab][key] = 0

    if pos and pos <= rank.ntops then
        tops[rank_id] = nil
    end
end

function get_rank_info(rank_id)
    local rank = ranks[rank_id]
    if not rank then
        return gTime, {}
    end
    local top = tops[rank_id]
    if top then
        return top.time, top.tops
    end

    update_top_cache(rank)
    top = tops[rank_id]
    if not top then
        return gTime, {}
    end
    return top.time, top.tops
end

function get_info(mode, id)
    if mode == CUSTOM_RANK_MODE.PLY then
        return rank_mng.get_info(1, id)
    elseif mode == CUSTOM_RANK_MODE.UNION then
        return rank_mng.get_info(0, id)
    elseif mode == CUSTOM_RANK_MODE.GS then
        return {id}
    end
end

function get_rank(rank_id, key)
    local rank = ranks[rank_id]
    if not rank then
        WARN("[CustomRank] Rank %d hasn't been created, get rank failed.", rank_id)
        return 0
    end
    local top = tops[rank_id]
    if top and top.ranks[key] then
        return top.ranks[key]
    end
    return skiplist.get_rank(rank.index, key) or 0
end

function get_range(rank_id, start, tail)
    local rank = ranks[rank_id]
    if not rank then
        WARN("[CustomRank] Rank %d hasn't been created, get range failed.", rank_id)
        return
    end
    return skiplist.get_range(rank.index, start, tail)
end

function get_range_with_score(rank_id, start, tail)
    local rank = ranks[rank_id]
    if not rank then
        WARN("[CustomRank] Rank %d hasn't been created, get range failed.", rank_id)
        return
    end
    local info = skiplist.get_range_with_score(rank.index, start, tail)
    if not info then
        return
    end
    return info
end

function get_score(rank_id, key)
    local rank = ranks[rank_id]
    if not rank then
        WARN("[CustomRank] Rank %d hasn't been created, get score failed.", rank_id)
        return
    end
    return skiplist.get_score(rank.index, key) or 0
end

