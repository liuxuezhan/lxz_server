module("monster", package.seeall)
local zset = require "frame/zset"

distrib = distrib or {}
boss_grade = boss_grade or {}
boss_special = boss_special or {}
super_boss = super_boss or 0
scan_id = scan_id or 0
openStage = openStage or {}
topKillerByPid = topKillerByPid or {}
topHurtByPid = topHurtByPid or {}
bossKillTimes = bossKillTimes or {}
bossKillScore = bosskillScore or {}
bossHurtRankByPropid = bossHurtRankByPropid  or {}

can_atk_monster = {}

initDbList =
{
  "bossKillTimes",
  "bossKillScore",
  "bossHurtRankByPropid",
  "openStage"
}
initRedisList =
{
    "topKillerByPid",
    "topHurtByPid"
}

lv_1_boss =
{
   2019005,
   2020005,
   2021005,
   2022005
}

lv_1_boss_num = 80
lv_1_block_num = 3380

npc_boss_rule =
{
[1] = {0,4,3,0},
[2] = {0,3,2,0},
[3] = {0,2,1,0},
[4] = {0,1,0,0},
}


_mt = {__index = monster}

function update_top_killer(key, score)
    local org_score = rank_mng.get_score(11, key) or 0
    --local org_score = 100
    score = score + org_score
    rank_mng.add_data(11, key, {score})


    --local pid = tostring(key)
    --local topKiller = topKillerByPid:score(pid) or 0
    --topKillerByPid:add(topKiller + 1, pid)
    --gPendingSave.status[ "topKillerByPid" ][ pid ] = topKiller + 1
end

function get_top_hurter_by_propid(propid)
    return bossHurtRankByPropid[ propid ]
end

function get_player_score(rankName, pid)
    return monster[ rankName ]:score(pid)
end

function get_top_killer_rank(key)
    local pid = tostring(key)
    local topKillers = topKillerByPid:range(1, 200) or {}
    local myScore = topKillerByPid:score(pid) or 0
    local myRank = topKillerByPid:rank(pid) or 0
    --print( topKillers, {myScore, myRank})
    return topKillers, myScore, myRank

end

function get_top_hurter_rank(key)
    local pid = tostring(key)
    local topHurts = topHurtByPid:range(1, 200) or {}
    local myScore = topHurtByPid:score(pid) or 0
    local myRank = topHurtByPid:rank(pid) or 0
    --print( topHurts, {myScore, myRank})
    return topHurts, myScore, myRank
end

function try_update_top_hurter_by_propid(propid, pid, hurt, name)
    local topHurter = bossHurtRankByPropid[ propid ] or {}
    if (not topHurter.hurt) or topHurter.hurt < hurt then
        local info = {pid=pid, hurt=hurt, name=name}
        bossHurtRankByPropid[ propid ] = info
        gPendingSave.status.bossHurtRankByPropid[ propid ] = info
    end
end


function check_stage_condition(stage)
    local cfg = resmng.prop_boss_unlock[stage]
    local result = 1
    --[[for k, v in pairs(cfg.Cond) do
        local killTimes = bossKillTimes[k] or 0
        if killTimes >= v then
            result = reslut and 1
        else
            result = reslut and 0
        end
    end
    return result--]]
    if not cfg then
        return false
    end
    return (bossKillScore.score or 0 ) > cfg.Cond
end

function try_upgrade_stage()
    local stageCfg = resmng.prop_boss_unlock
    if (openStage.num or 1) >= #stageCfg then
        return openStage.num or 1
    end
    while check_stage_condition(openStage.num + 1) do
        openStage.num = openStage.num + 1
        gPendingSave.status[ "openStage" ].num = openStage.num
    end
end

function checkin(m)
    local zx = m.zx
    local zy = m.zy
    local idx = zy * 80 + zx
    local node = distrib[ idx ]
    if not node then
        node = {}
        distrib[ idx ] = node
    end
    table.insert(node, {[ "eid" ] = m.eid, [ "grade" ] = m.grade})
end

function checkout(m)
    local x = m.zx
    local y = m.zy
    do_check(x, y)
end

function get_random_level(min, max)
    local index = math.random(min, max)
    return index
end

function get_boss_mod(date, civil, grade, lv)
    local index = 0
    local bossList = {}

    if grade == BOSS_TYPE.SPECIAL then  -- 对特殊做处理
        bossList = lv_1_boss
    else
        local tip = tostring(civil) .. "_" .. tostring(lv)
        bossList = resmng.prop_boss_mod_by_date[tonumber(date)][tip][grade]
    end

    if (not bossList) or (not next(bossList)) then
        return
    end

    index=  math.random(#bossList)
    return bossList[index]
end

function get_boss_level(propid)
    --[[local bossLevel = 0
    local bossLevelRange = {}
    bossLevelRange = resmng.prop_boss_level[level].BossLevelRange
    if bossLevelRange == nil then
        bossLevel = 1
    else
        bossLevel = get_random_level(bossLevelRange.min, bossLevelRange.max)
    end
    return bossLevel--]]
    --print("propid", propid)
    local prop = resmng.prop_world_unit[propid]
    if not prop then
        WARN("world boss not prop by propid = %d", propid)
        return
    end
    local bossLevel =  prop.Lv or 1
    return bossLevel
end

function get_boss_pos_in_zone(tx, ty, prop, grade)
    local x, y
    local r = prop.Size or 1
    if grade == BOSS_TYPE.NORMAL then
        x, y = c_get_pos_in_zone(tx, ty, r, r)
    elseif grade == BOSS_TYPE.SPECIAL then
        x, y = c_get_pos_in_zone(tx, ty, r, r)
    elseif grade == BOSS_TYPE.ELITE then
        --x, y = monster_city.get_pos_in_range(tx, ty, 0, 0, r)
        x, y = c_get_pos_in_zone(tx, ty, r, r)
    elseif grade == BOSS_TYPE.LEADER then
       -- x, y = monster_city.get_pos_in_range(tx, ty, 0, 0, r)
        x, y = c_get_pos_in_zone(tx, ty, r, r)
    elseif grade == BOSS_TYPE.SUPER then
        --local pos_arr = {{650,650},{620,620},{650,620},{620,650}}
        --local index_x = math.random(-2, 2)
        --local index_y = math.random(-2, 2)
        --x, y = c_get_pos_in_zone(tx + index_x, ty + index_y, r, r)
        --local index = math.random(#pos_arr)
        --local pos = pos_arr[index] or {}
        --x = pos[1] or 680
        --y = pos[2] or 680
        x, y = super_boss_pos()
    end
    return x, y
end

function super_boss_pos()
    local num = 0
    while true do
        if num > 30 then
            return
        end
        local index_x = math.random(-30, 30)
        local index_y = math.random(-30, 30)
        --if c_map_test_pos_for_ply( 640 + index_x, 640 + index_y, 3 ) then
        if c_map_test_pos( 640 + index_x, 640 + index_y, 3 ) then
            return 640 + index_x, 640 + index_y
        end
        num = num + 1
    end
end

function force_born(tx, ty, clv)
    if clv > 30 then
        return find_advanced_boss(tx, ty, clv)
    end

    local prop = resmng.prop_world_unit
    if prop then
        for k, v in pairs(prop) do
            if v.Class == CLASS_UNIT.MONSTER and v.Mode < 100 and v.Clv == clv then
                local pos_lv = get_pos_lv(v.Lv)
                local tar_x, tar_y = tx, ty
                if pos_lv then
                    tar_x, tar_y = get_near_lv_pos(tx, ty, pos_lv)
                    local idx = tar_y * 80 + tar_x
                    local node = distrib[ idx ]
                    if node then
                        for _, n in pairs( node ) do
                            local m = get_ety( n.eid )
                            if m and is_monster( m ) then
                                local conf = resmng.get_conf( "prop_world_unit", m.propid )
                                if conf and conf.Clv == clv  then
                                    return m.propid, m.x, m.y, m.eid
                                end
                            end
                        end
                    end
                    return gen_task_boss(tar_x, tar_y, v.ID)
                end
                return
            end
        end
    end
end

function find_advanced_boss(tx, ty, clv)
 --   if clv == 40 then
 --       for k, boss_list in pairs(boss_special or {}) do
 --           for idx, eid in pairs(boss_list) do
 --               local boss = get_ety(eid)
 --               if boss then
 --                   local prop = resmng.prop_world_unit[boss.propid]
 --                   if prop then
 --                       if prop.Clv == clv then
 --                           return boss.propid, boss.x, boss.y, boss.eid
 --                       end
 --                   end
 --               end
 --           end
 --       end
 --       local boss = respawn(1, 1, BOSS_TYPE.SPECIAL)
 --       if boss then
 --           return boss.propid, boss.x, boss.y, boss.eid
 --       end
    if clv >= 40 and clv < 200 then
        for k, v in pairs(boss or {}) do
            local ety = get_ety(v)
            local prop = resmng.prop_world_unit[ety.propid]
            if prop.Clv == clv then
                return ety.propid, ety.x, ety.y, ety.eid
            end
        end
    else
        local super = get_ety(super_boss)
        if super then
            return super.propid, super.x, super.y, super.eid
        end
    end
end


function gen_task_boss(tx, ty, propid)
    if tx <= 0 or tx > 80 then
        tx = 1
    end
    if ty <=0 or ty > 80 then
        ty =1
    end

    local prop = resmng.prop_world_unit[propid] 
    if prop then
        local x, y = get_boss_pos_in_zone(tx, ty, prop, BOSS_TYPE.NORMAL)
        if x then
            local eid = get_eid_monster()
            if eid then
                local m = create_monster(prop)
                m._id = eid
                m.eid = eid
                m.x = x
                m.y = y
                m.zx = tx
                m.zy = ty
                m.born = gTime
                if npc_id then
                    m.npc_id = npc_id
                end
                m.grade = BOSS_TYPE.NORMAL
                m.level = prop.Lv
                m.size = prop.Size
                setmetatable(m, _mt)
                gEtys[ eid ] = m
                etypipe.add(m)
                checkin( m )
                return propid, x, y, eid
            end
        end
    end
end

function get_pos_lv(boss_lv)
    local lv_range ={
        {1, 5},
        {6, 9},
        {10, 12},
        {13, 15},
        {16, 25},
    }
    for k , v in pairs(lv_range) do
        if boss_lv >= v[1] and boss_lv <= v[2] then
            return k
        end
    end
end

function get_near_lv_pos(tx, ty, target_lv)
    local cur_lv = c_get_zone_lv(tx, ty)

    if cur_lv == target_lv then
        return tx, ty
    end

    local tag = 1 
    if cur_lv > target_lv then
        tag = -1
    end

    local index = tag
    local index1 = tag

    local dis1 = 40 - tx
    local dis2 = 40 - ty

    if math.abs(dis1) > math.abs(dis2) then
        if tx > 40 then index  = -tag end
        return get_near_lv_pos(tx + index, ty, target_lv)
    elseif math.abs(dis1) < math.abs(dis2) then
        if ty > 40 then index  = -tag end
        return get_near_lv_pos(tx , ty + index, target_lv)
    else
        if tx > 40 then index  = -tag end
        if ty > 40 then index1  = -tag end
        return get_near_lv_pos(tx + index, ty + index1, target_lv)
    end
end

function respawn(tx, ty, grade, npc_id)
    if tx < 0 or ty < 0 then
        return
    end
    --local civil = c_get_civil_lv(tx, ty)
    local lv = c_get_zone_lv(tx, ty)
    local date = os.date("%w", gTime)
    if date == "0" then
        date = "7"
    end

    local civil = c_get_culture(tx * 16, ty * 16)

    if civil == 0 or civil == -1 then
        civil = 1
    end

    local bossMod = 0
    local bossLv = 0
    local bossPropid = get_boss_mod(date, civil, grade, lv)
    if not bossPropid then
        return
    end
    bossLv = get_boss_level(bossPropid)

    local unlockBossCfg = resmng.prop_boss_unlock[openStage.num or 1]
    --check can generate boss by grade and level
    if  unlockBossCfg then
        if grade ~= BOSS_TYPE.SPECIAL then
            if unlockBossCfg.OpenBossLevel[ grade ] < bossLv then
                return
            end
        end
    else
        return
    end

    if grade ~= BOSS_TYPE.NORMAL then
        INFO("[Monster] gen boss prop x = %d, y = %d, date = %d, civil = %d, grade = %d, lv = %d", tx, ty, date, civil, grade, lv)
        --print("[Monster] gen boss prop x = %d, y = %d, date = %d, civil = %d, grade = %d, lv = %d", tx, ty, date, civil, grade, lv)
    end

    --local prop = get_conf(bossMod, bossLv)
    local prop = resmng.prop_world_unit[bossPropid]
    if prop then

        local x, y = get_boss_pos_in_zone(tx, ty, prop, grade)
        if x then
            local eid = get_eid_monster()
            if eid then
                local m = create_monster(prop)

                m._id = eid
                m.eid = eid
                m.x = x
                m.y = y
                m.zx = tx
                m.zy = ty
                m.born = gTime
                if npc_id then
                    m.npc_id = npc_id
                end
                m.grade = grade
                m.level = bossLv
                m.size = prop.Size
                setmetatable(m, _mt)
                gEtys[ eid ] = m
                etypipe.add(m)
                if m.grade >= BOSS_TYPE.ELITE and m.grade < BOSS_TYPE.SUPER then
                    local boss= boss_grade[ m.grade] or {}
                    local idx = m.zy * 80 + m.zx
                    boss[ idx ] = m.eid
                    boss_grade[m.grade] = boss
                    INFO("[Monster] elite and leader boss x = %d, y = %d, zx = %d, zy = %d, grade = %d, idx = %d", m.x , m.y, m.zx, m.zy, m.grade, idx)
                    m:mark()
                elseif m.grade == BOSS_TYPE.SPECIAL then
                    local boss_list = boss_special[lv] or {}
                    local idx = m.zy * 80 + m.zx
                    if not boss_list[idx] then
                        boss_list[idx] = m.eid
                        boss_special[lv] = boss_list
                    else
                        rem_ety(m.eid)
                    end
                    m:mark()
                elseif m.grade == BOSS_TYPE.SUPER then
                    super_boss = m.eid
                    m:mark()
                elseif m.grade == BOSS_TYPE.NORMAL then
                    --m:mark()
                end

                checkin(m)
                boss_notify(m)

                return m
            end
        else
            return
        end
    end
end

function boss_notify(monster)
    local prop = resmng.prop_world_unit[monster.propid]
    if not prop then return end

    local npc_prop = resmng.prop_world_unit[monster.npc_id]
    if not npc_prop then return end

    local notify = resmng.prop_boss_notify[prop.Mode]
    if notify then
        if notify.Notify then
            Rpc:tips({pid=-1,gid=_G.GateSid}, 2, notify.Notify,{prop.Name, npc_prop.Name, monster.x, monster.y})
        end

        if notify.Chat then
            player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", notify.Chat, {monster.x, monster.y, prop.Name, npc_prop.Name, monster.x, monster.y})
        end
    end

    if monster.grade == BOSS_TYPE.SUPER then
        local king_city = king_city.get_king()
        if king_city then
            local king_union = unionmng.get_union(king_city.uid)
            if king_union then
                local conf = resmng.prop_act_notify[resmng.SUPER_BOSS_REFRESH] 
                if conf then
                    if conf.Notify then
                        Rpc:tips({pid=-1,gid=_G.GateSid}, 2, conf.Notify,{monster.x, monster.y, king_union.alias, king_union.name, prop.Name})
                    end

                    if conf.Chat1 then
                        player_t.add_chat({pid=-1,gid=_G.GateSid}, 0, 0, {pid=0}, "", conf.Chat1, {monster.x, monster.y, king_union.alias, king_union.name, prop.Name})
                    end

                    if conf.Chat2 then
                        king_union:union_chat("", conf.Chat2, {monster.x, monster.y, king_union.alias, king_union.name, prop.Name})
                    end
                end
                
            end
        end
    end
end


-- refrash elite boss at utc 0
function reset_boss()
    --删除之前的boss
    for _, boss in pairs(boss_grade or {}) do
        for k, v in pairs(boss or {}) do
            local ety = get_ety(v)
            if ety then
                rem_monster(ety)
            end
        end
    end
    boss_grade = {}

   -- for k, v in pairs(resmng.prop_world_unit or {}) do
   --     if v.Class == CLASS_UNIT.NPC_CITY then
   --         local lv = v.Lv
   --         --print("band npc ", v.ID)
   --         local refreshRule = npc_boss_rule[ lv ]
   --         for grade, num in pairs(refreshRule or {}) do
   --             if num ~= 0 then
   --                 for i = 1, num  do
   --                     respawn(math.floor(v.X/16), math.floor(v.Y/16), grade, v.ID)
   --                 end
   --             end
   --         end
   --     end
   -- end
end

-- refresh leader boss
function reset_leader_boss()
    --to do
end

function reset_super_boss()
    rem_super_boss()
    for k, v in pairs(resmng.prop_world_unit or {}) do
        if v.Class == CLASS_UNIT.KING_CITY and v.Lv == CITY_TYPE.KING_CITY then
            respawn(math.floor(v.X/16), math.floor(v.Y/16), BOSS_TYPE.SUPER, v.ID)
        end
    end
end

function rem_super_boss()
    rem_ety(super_boss)
    super_boss = 0
end


function on_day_pass()
    reset_boss()
    reset_leader_boss()
end


function init_db_list()
    for k, v in pairs(initDbList or {}) do
        monster[ v ] = init_db(v)
    end
end

function init_db(key)
    local db = dbmng:getOne()
    local info = db.status:findOne({_id = key})
    --dumpTap(info, Key)
    if not info then
        info = {_id = key}
        db.status:insert(info)
    end
    return info
end

function init_redis_list()
    for k, v in pairs(initRedisList or {}) do
        local info = init_db(v)
        monster[ v ] = init_redis(v, info)
    end
end

function init_redis(key, info)
    local zset = zset.new()
    for k, v in pairs(info or {}) do
        if k ~= "_id" and v ~= {} then
            if key == "topKillerByPid" then
                zset:add(v, tostring(k))
             --   zset:add(v[ "hurt" ], v[ "pid" ])
            elseif key == "topHurtByPid" then
                zset:add(v[ "hurt" ], v[ "pid" ] )
              --  zset:add(v[2], v[1])
            end
        end
    end
    return zset
end

function check_init()
    openStage.num = openStage.num or 1
end

function init_global()
    init_db_list()
    --init_redis_list()
    check_init()
end

-- 加载数据库中的boss  初始与npc_city 等绑定的 boss
function load_from_db()
    local db = dbmng:getOne()
    local info = db.monster:find({})
    local have = {}
    local tag = true
    while info:hasNext() do
        tag = true
        local m = info:next()
        m.hp = m.hp or 0
        if m.hp > 0 then
            setmetatable(m, _mt)
            gEtys[ m.eid ] = m
            if m.grade >= BOSS_TYPE.ELITE and m.grade < BOSS_TYPE.SUPER then
                local boss = boss_grade[m.grade] or {}
                local idx = m.zy * 80 + m.zx
                if boss[idx] or (not can_born_boss(m.zx, m.zy, m.grade)) then
                    tag = false
                    gPendingDelete.monster[ m._id ] = 0
                else
                    boss[idx] = m.eid
                    boss_grade[m.grade] = boss
                end
            elseif m.grade == BOSS_TYPE.SUPER then
                super_boss = m.eid
            elseif m.grade == BOSS_TYPE.SPECIAL then
                local lv = c_get_zone_lv(m.zx, m.zy)
                local boss_list = boss_special[lv] or {}
                local idx = m.zy * 80 + m.zx
                if not boss_list[idx] then
                    boss_list[idx] = m.eid
                    boss_special[lv] = boss_list
                else
                    tag = false
                    gPendingDelete.monster[ m._id ] = 0
                end
            end
            if tag == true then
                etypipe.add(m)
                checkin(m)
            end
        else
            gPendingDelete.monster[ m._id ] = 0
        end
    end
   init_global()
   try_upgrade_stage()
   --gen_all_boss()
end

function gen_all_boss()
    for i = 1, 80, 1 do
        for j = 1, 80, 1 do
            do_check(i, j)
        end
    end
end

function do_check(zx, zy, isloop)
    zx = math.floor(zx)
    zy = math.floor(zy)
    if zx >= 0 and zx < 80 and zy >= 0 and zy < 80 then

        if ( zx == 39 or zx == 40 ) and ( zy == 39 or zy == 40 ) then return end -- skip the black land 

        local idx = zy * 80 + zx
        local node = distrib[ idx ]
        local normalNum = 0

        local news = {}
        for k, v in pairs(node or {})  do
            local eid = v.eid
            local ety = get_ety(eid)
            if ety then
                if ety.grade == BOSS_TYPE.NORMAL then
                    if can_date(ety.born)  then
                        rem_monster(ety)
                    else
                        normalNum = normalNum + 1
                        table.insert(news, {[ "eid" ] = v.eid, [ "grade" ] = v.grade})
                    end
                else
                    --table.insert(news, v)
                    table.insert(news, {[ "eid" ] = v.eid, [ "grade" ] = v.grade})
                end
            end
        end

        --print("normal monster num ", normalNum)

        distrib[ idx ] = news

        local num = #news
        local access = c_get_map_access(zx, zy)
        --test
        --if math.abs(gTime - access) >= 3600 then
        if access ~= 0 and math.abs(gTime - access) >= 3600 then
            if num == 0 then
                distrib[ idx ] = nil
            end
        elseif normalNum < 2 then
            for i = normalNum+1, 2, 1 do
                respawn(zx, zy, BOSS_TYPE.NORMAL)
            end
        end

        if can_born_boss(zx, zy, BOSS_TYPE.ELITE) then
            respawn(zx, zy, BOSS_TYPE.ELITE)
        end

        if can_born_boss(zx, zy, BOSS_TYPE.LEADER) then
            respawn(zx, zy, BOSS_TYPE.LEADER)
        end
    end

    --local lv = c_get_zone_lv(zx, zy) --一级资源带 特殊boss
    --if lv == 1 then
    --    local boss_list = boss_special[lv] or {}
    --    if get_table_valid_count(boss_list) < lv_1_boss_num then
    --        local index = math.random(lv_1_block_num)
    --        if index <= lv_1_boss_num then
    --            local idx = zy * 80 + zx
    --            if not boss_list[idx] then
    --                respawn(zx, zy, BOSS_TYPE.SPECIAL)
    --            end
    --        end
    --    end
    --end
end

function can_born_boss(zx, zy, boss_type)
    if boss_type == BOSS_TYPE.ELITE then
        if zy % 2 == 1 and zx % 2 == 1 then
            return false
        elseif zy % 2 == 0 and zx % 2 == 0 then
            return false
        end
    elseif boss_type == BOSS_TYPE.LEADER then
        if not (zx % 2 == 1 and zy % 2 == 1 and (zx + zy) % 4 == 0 ) then
            return false
        end
    end

    local boss = boss_grade[boss_type] or {}
    local idx = zy * 80 + zx
    if boss[idx] then
        return false
    end
    return true
end

function loop()
    local idx = scan_id
    for i = 1, 80, 1 do
        if idx >= 6400 then idx = 0 end
        scan_id = idx
        if distrib[ idx ] then
            local zx = idx % 80
            local zy = math.floor(idx / 80)
            do_check(zx, zy, true)
        end
        idx = idx + 1
    end
end

function gen_boss_reward(prop, pid)
    local Rewards = {}
    local fixAward = {}
    if prop.Fix_award then
        --fixAward = player_t.bonus_func[ prop.Fix_award[1] ](prop, prop.Fix_award[2])
        for k, v in pairs(prop.Fix_award or {}) do
            local award = player_t.bonus_func[ v[1] ](prop, v[2])
            for k, v in pairs(award or {}) do
                table.insert(fixAward, v)
            end
        end
    end

    local baseAward = {}
    if prop.Base_award then
        baseAward = player_t.bonus_func[ prop.Base_award[1] ](prop, prop.Base_award[2])
    end

    local extraAward = {}
    if prop.Extra_award then
        extraAward = player_t.bonus_func[ prop.Extra_award[1] ](prop, prop.Extra_award[2])
    end

    local extraAwardSingle = {}
    if prop.Extra_award_single then
        extraAwardSingle = player_t.bonus_func[ prop.Extra_award_single[1] ](prop, prop.Extra_award_single[2])
    end

    local finalAward = {}
    if prop.Final_award then
        for k, v in pairs(prop.Final_award or {}) do
            local award = player_t.bonus_func[ v[1] ](prop, v[2])
            table.insert(finalAward, award)
        end
       -- finalAward = player_t.bonus_func[ prop.Final_award[1] ](prop, prop.Final_award[2])
    end

    local unitAward = {}
    if player_t.debug_tag then
        award = {"mutex_award",{{"item",2010009,1,10000}}}
        unitAward = award
    end

    if prop.Unit_award then
        unitAward =  prop.Unit_award
        --unitAward = player_t.bonus_func[ prop.Unit_award[1] ](prop, prop.Unit_award[2])
    end

    local taskAward = {}
    if prop.Task_award then
        local ply = getPlayer(pid)
        if ply then
            local task = ply:get_task_by_id(prop.Task_award[1])
            if task then
                if task.task_status == TASK_STATUS.TASK_STATUS_ACCEPTED then
                    taskAward = player_t.bonus_func[ prop.Task_award[2][1] ](prop, prop.Task_award[2][2]) 
                end
            end
        end
    end

    return {
        fix = fixAward,
        base = baseAward,
        extra = extraAward,
        extra_single = extraAwardSingle,
        final = finalAward,
        unit = unitAward,
        task = taskAward,
    }

    --[[if prop.Rewards then
        for k, v in pairs(prop.Rewards) do
        local awards = {}
        for k, v in pairs(k) do
        --{BonusPolicy, Bonus}
        --v[1], v[2]
        local award = player_t.bonus_func[ v[1] ](prop, v[2])
        table.insert(awards, award)
        end
        local award = player_t.bonus_func[ v[1] ](prop, v[2])
        table.insert(Rewards, awards)
        end
    end--]]

    --[[return {
        fix = {{"item", 1002001, 1000}},
        base = {{"item", 1002001, 1000}},
        extra = {{"item", 1002001, 1000}},
        final = {{"item", 1002001, 1000}},
        unit = {{"item", 1002001, 1000}},
    }--]]
    --return Rewards
end

function create_monster(prop)
  --  local arms = {     -- 产生怪时，不生成部队
  --      {num=0, mode=1, objs={}},
  --      {num=0, mode=2, objs={}},
  --      {num=0, mode=3, objs={}},
  --      {num=0, mode=4, objs={}}
  --  }

  --  for _, v in ipairs(prop.Arms or {}) do
  --      local id = v[1]
  --      local num = v[2]
  --      local p = resmng.prop_arm[ id ]
  --      if p then
  --          local arm = arms[ p.Mode ]
  --          table.insert(arm.objs, {id=id, num=num})
  --          arm.num = arm.num + num
  --      end
  --  end

 --[[   if prop.Heros then
        for mode, v in pairs(prop.Heros) do
            local p = resmng.prop_hero[ v ]
            if p then
                local arm = arms[ mode ]
                table.insert(arm.objs, {id=v, num=1, hero=1})
                arm.num = arm.num + 1
            end
        end
    end--]]
    --return {propid=prop.ID, arms=arms, born=gTime, hp = hp}
    return {propid=prop.ID, born=gTime, hp = 100}
end

function init_def_troop(m)
    m.action = "defend"
    m.aid=m.eid
    return m
end

function mark(m)
    if m.marktm then
        m.marktm = gTime
        gPendingSave.monster[ m.eid ] = m
    else
        m.marktm = gTime
        gPendingInsert.monster[ m.eid ] = m
    end
end


function damage_hp(m, dt)
    local live = 0
    local dead = 0
    for k, v in pairs(dt.arms or {}) do
        for k, v in pairs(v.live_soldier or {}) do
            live = live + v
        end
        for k, v in pairs(v.dead_soldier or {}) do
            dead = dead + v
        end
    end
    local hp = dead / (dead + live) * 100
    --todo
    return hp
end


function increase_kill_times(m)
    local killTimes =  bossKillTimes.killTimes[ m.grade ]
    killTimes = killTimes + 1
    bossKillTimes[m.grade] = killTimes
    local storeKey = "killTimes." .. tostring(m.grade)
    gPendingSave.status[ "bossKillTimes" ][storeKey] = killTimes
end

function increase_kill_score(m)
    local score = resmng.prop_world_unit[m.propid].Boss_point or 0
    bossKillScore.score = (bossKillScore.score or 0 ) + score
    gPendingSave.status[ "bossKillScore" ].score =  bossKillScore.score
    --世界事件
    world_event.process_world_event(WORLD_EVENT_ACTION.MONSTER_POINT, score)
    try_upgrade_stage()
end

--function troop_home(m, dt)
--    -- cal hp of boss and other
--    local reduceHp = damage_hp(m, dt)
--    m.hp = m.hp - reduceHp
--    if m.hp > 0 then
----[[        local arms = m.arms
--        for _, arm in pairs(arms) do
--            for _, obj in pairs(arm.objs) do
--                obj.hurt = 0
--                obj.dead = 0
--            end
--        end --]]
--        m:mark()
--        etypipe.add(m)
--    else
--        rem_monster(ety)
--        timer:new("boss", BossRbTime[m.grade], m.zx, m.zy, m.grade)
--    end
--end

function rem_monster(self)
    if self.grade >= BOSS_TYPE.ELITE and self.grade < BOSS_TYPE.SUPER then 
        local boss = boss_grade[self.grade] or {} 
        local idx = self.zy * 80 + self.zx 
        boss[idx] = nil
        boss_grade[self.grade] = boss
    end

    if  self.grade == BOSS_TYPE.SUPER then
        super_boss = 0
    end

    if self.grade == BOSS_TYPE.SPECIAL then
        local lv = c_get_zone_lv(self.zx, self.zy)
        local boss_list = boss_special[lv] or {}
        local idx = self.zy * 80 + self.zx
        boss_list[idx] = nil
        boss_special[lv] = boss_list
    end

    troop_mng.delete_troop(self.my_troop_id)

    rem_ety(self.eid)

end

function troop_back(troop)
    local city = get_ety(troop.start_eid)
    local arms = troop.arms
    local start_eid = troop.dest_eid
    local sx = troop.dx
    local sy = troop.dy
    local troopId = troop._id
    troop_mng.delete_troop(troopId)

    for k, v in pairs(arms or {}) do
        if k ~= city.propid then
            local mine = getPlayer(k)
            if mine ~= nil then
                --mine:rem_busy_troop(troopId)
                local dx, dy = get_ety_pos(mine)
                local backTroop = troop_mng.create_troop(start_eid, mine.eid, TroopAction.Back, sx, sy, dx, dy)
                backTroop.owner_pid = v.pid
                backTroop.owner_eid = mine.eid
                backTroop:add_arm(v.pid, v)
                backTroop.speed = backTroop:calc_troop_speed()
                backTroop:start_march()
                mine:add_busy_troop(backTroop._id)
            end
        end
    end
end

function get_conf(mod, lv)
    for k, v in pairs(resmng.prop_world_unit or {}) do
        if v.Class == CLASS_UNIT.MONSTER and v.Mode == mod and v.Lv == lv then
            return v
        end
    end
    return nil
end

function do_time_boss(sn, zx, zy, grade, npc_id)
    respawn(zx, zy, grade, npc_id)
end

function can_date(time)--是否跨天
    if get_diff_days( gTime, time ) > 0 then
        return true
    end
    return false
end

function test_monster()
   on_day_pass()
   print("test_monster")
    --- test
   print(openStage)
   respawn(1, 1, 1)
   do_check(1, 1)
   try_update_top_hurt(1, 100)
   try_update_top_hurt(3, 100)
   try_update_top_hurt(4, 300)
   try_update_top_hurt(5, 200)
   try_update_top_hurt(6, 100)
   try_update_top_hurt(2, 100)
   try_update_top_hurt(1, 1000)
   update_top_killer(1, 100)
   update_top_killer(1, 100)
   update_top_killer(2)
   update_top_killer(2)
   update_top_killer(2)
   update_top_killer(3)
   local topKillers, myScore, myRank = monster.get_top_killer_rank(1)
   local topHurts, score, rank = monster.get_top_hurter_rank(1)

   local killInfo =  {}
   local hurtsInfo = {}
   for k, v in pairs(topKillers) do
       killInfo[k] = {player_t.get_ply_info(v), monster.get_player_score("topKillerByPid", v)}
   end
   for k, v in pairs(topHurts) do
       hurtsInfo[k] = {player_t.get_ply_info(v), monster.get_player_score("topHurtByPid", v)}
   end
   local pack = {}
   pack.topKillers = killInfo
   pack.myKillScore = myScore
   pack.mykillRank = myRank
   pack.topHurts = hurtsInfo
   pack.myHurtScore = score
   pack.myHurtRank = rank
   print("test_end")
end


function get_my_troop(self)
    local tr = false
    if self.my_troop_id then
        tr = troop_mng.get_troop(self.my_troop_id)
        if tr then return tr end
    end

    local conf = resmng.get_conf("prop_world_unit", self.propid)
    if conf then
        local sx, sy = get_ety_pos(self)
        tr = troop_mng.create_troop(TroopAction.Monster, self, self)
        local arm = {}
        for _, v in pairs(conf.Arms or {}) do
            if v[1] ~= nil then
                arm[ v[1] ] = v[2]
            end
        end
        tr:add_arm(0, {live_soldier=arm, heros=conf.Heros or {0,0,0,0}})

    end
    if tr then
        self.my_troop_id = tr._id
        mark(self)
        return tr
    end
end

function calc_hp( self, troop )
    local cur = 0
    local max = 0
    for _, arm in pairs(troop.arms or {}) do
        local live = arm.live_soldier or {}
        local dead = arm.dead_soldier or {}

        for id, num in pairs(live or {}) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                cur = cur + conf.Pow * num
                max = max + conf.Pow * (num + (dead[ id ] or 0))
            end
        end
    end

    local lost = math.floor((max-cur) * 10000 / max + 0.1) / 100
    self.hp_before = self.hp
    if self.hp <= lost then
        lost = self.hp
        self.hp = 0
        return 0
    elseif  self.grade == BOSS_TYPE.NORMAL then
        self.hp = 100
        return self.hp - lost 
    else
        self.hp = self.hp - lost
        return self.hp
    end
end

function make_reward_num(key, rewards, factor, pid, monster)
    if factor == 0 then 
        factor = 0.000001
    end
    local newFactor = 1
    local cp_rewards = copyTab(rewards)
    if key == "base" or key == "extra" or key == "extra_single" then
        local ply = getPlayer(pid)
        local prop = resmng.prop_world_unit[monster.propid]
        if ply and prop then
            newFactor = math.max(0.1, math.min(1, 1 - (ply:get_castle_lv() - prop.Lv)/prop.Attenuation))
        end

    end
    for k, v in pairs(cp_rewards or {}) do
        local num = v[3] * factor * newFactor
        local num1 = math.floor(num)
        if math.random(100) < ((num - num1) * 100) then
            num1 = num1 + 1
        end
        if num1 == 0 then
            cp_rewards[k] = nil
        else
            v[3] =  num1
        end
    end
    local pool =  {}
    for k, v in pairs(cp_rewards or {}) do
        if v[2] then
            local award = pool[v[2]]
            if not award then
                award = v
            else
                award[3] = award[3] + v[3]
            end
            pool[v[2]] = award
        end
    end
    return pool

end

function trans_num(reward, rate)
    for k, v in pairs(reward or {}) do
        v[3] =  math.ceil( v[3] * rate + 0.1)
    end
    return reward
end

function send_union_item(self, pid)
    local prop = resmng.prop_world_unit[self.propid]
    local rewards = {}
    if prop then
        rewards = gen_boss_reward(prop)
    end
    if rewards.unit and self.hp <= 0 then
        if get_table_valid_count(rewards.unit) > 1 then
            local ply = getPlayer(pid)
            if ply then
                local union = unionmng.get_union(ply.uid)
                if union and not check_union_cross(union) then  --跨服不加军团礼包
                    local _members = union:get_members()
                    for _, meb  in pairs(_members or {}) do
                        if meb:get_castle_lv() >= 6  then  --6级一下无礼包
                            --print("monster.lua:793", v[1][2], ",", UNION_ITEM.BOSS, ",", self.propid, ",", pid)
                            union_item.add(meb, rewards.unit, UNION_ITEM.BOSS, self.propid, pid)
                            --meb:add_bonus(v[1], v[2], VALUE_CHANGE_REASON.REASON_MONSTER)
                        end
                    end
                end
            end
        end
    end
end

function get_jungle_reward(self, pid, mkdmg, totalDmg , hp_lost, is_mass)
    local prop = resmng.prop_world_unit[self.propid]
    local gen_award = {}
    if prop then
        gen_award = gen_boss_reward(prop, pid)
    end

    if totalDmg == 0 then
        totalDmg = 1
    end
    local rate = 1.5
    if is_mass ~= 1 then
        rate= 0.5
    end
    if not hp_lost then
        hp_lost = 0
    end
    local rewards = {}
    for k, v in pairs(gen_award or {}) do
        local val = copyTab(v)
        if k == "fix" then  -- fix award
            rewards[ k ] = trans_num(val , rate)
        elseif k == "task" then
            rewards[k] = val
        elseif k == "base"  then  -- base  extra award
            local value = make_reward_num(k, val, mkdmg / totalDmg * hp_lost, pid, self )
            if totalDmg == 0 then
                rewards[ k ] = trans_num(value , rate)
            else
                rewards[ k ] = trans_num(value , rate)
            end
        elseif k == "extra" then
            if is_mass == 1 then
                local value = make_reward_num(k, val, mkdmg / totalDmg * hp_lost, pid, self )
                rewards[ k ] = value
            end
        elseif k == "extra_single" then
            if not is_mass  or is_mass == 0 then
                local value  = make_reward_num(k, val, mkdmg / totalDmg * hp_lost, pid, self )
                rewards[ k ] = value
            end
        elseif k == "final" and self.hp <= 0 then
            rewards[k] = {}
            for key, award in pairs(val or {}) do
                for _, item in pairs(award or {}) do
                    table.insert(rewards[ k ], item)
                end
            end
        end
    end

    return rewards
end


can_atk_monster[BOSS_TYPE.NORMAL] = function(ply, monster)
    local prop = resmng.prop_world_unit[monster.prop_id]
    if prop then
        if ply:get_castle_lv() or 1 < prop.Attack_lv then
            return false
        end
    end
    return true
end
can_atk_monster[BOSS_TYPE.SPECIAL] = function(ply, monster)
    local prop = resmng.prop_world_unit[monster.prop_id]
    if prop then
        if ply:get_castle_lv() or 1 < prop.Attack_lv then
            return false
        end
    end
    return true
end
can_atk_monster[BOSS_TYPE.ELITE] = function(ply, monster)

    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    end

    --if npc_city.get_city_num(union.npc_citys, 4, OPT_TYPE.LT) < 1 then
    --    return false
    --end

    local prop = resmng.prop_world_unit[monster.prop_id]
    if prop then
        if ply:get_castle_lv() or 1 < prop.Attack_lv then
            return false
        end
    end
    return true
end
can_atk_monster[BOSS_TYPE.LEADER] = function(ply, monster)

    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    end

    --if npc_city.get_city_num(union.npc_citys, 3, OPT_TYPE.LT) < 1 then
    --    return false
    --end

    local prop = resmng.prop_world_unit[monster.prop_id]
    if prop then
        if ply:get_castle_lv() or 1 < prop.Attack_lv then
            return false
        end
    end
    return true
end
can_atk_monster[BOSS_TYPE.SUPER] = function(ply, monster)
    local union = unionmng.get_union(ply.uid)
    if not union then
        return false
    end

    local king = king_city.get_king()
    if king then
        if king.uid ~= ply.uid then
            Rpc:tips(ply, 1, resmng.TIPS_NO_KINGCITY, {})
            return false
        end
    end

    local prop = resmng.prop_world_unit[monster.prop_id]
    if prop then
        if ply:get_castle_lv() or 1 < prop.Attack_lv then
            return false
        end
    end

    return true
end


function send_score_award()
    local prop = resmng.prop_boss_rank_award
    if prop then
        local num = 1
        for k, v in pairs(prop or {}) do
            local plys = rank_mng.get_range(11, v.Rank[1], v.Rank[2])
            for idx, pid in pairs(plys or {}) do
                local score = rank_mng.get_score(11, tonumber(pid)) or 0
                local ply = getPlayer(tonumber(pid))
                INFO("monster person rank %d, %d, %d", num, tonumber(pid), score)
                if ply then
                    ply:send_system_notice(10015, {num}, v.Award)
                end
                num = num + 1
            end
        end
    end
end
