module("public_t")

function firstPacket(player, uid, account, pasw)
    local process = pullString()

    local magic = pullInt()
    LOG("firstPacket, account=%s, process=%s, magic=%d", account, process, magic)
    if magic ~= 20100731 then return end

    local p = gAccs[ account ]
    if not p then
        LOG("firstPacket, account=%s, process=%s, account not in local", account, process)
        local dg = dbmng:getGlobal()
        local info = dg.ply:findOne({_id=account})

        -- steer to map server the player belong to
        if info then
            if info.map == gMapID then
                LOG("firstPacket, account=%s, pid=%d, process=%s, account in map %d, missing, recreate", account, info.pid, process, info.map)
                p = player_t.create(account, info.pid)
            else
                LOG("firstPacket, account=%s, pid=%d, process=%s, account in map %d", account, info.pid, process, info.map)
                local map = info.map
                local pid = info.pid
                set_ply_map(player.gid, process, map, pid)
                return
            end
        end

        -- steer to map server the system recomment
        local steer = gSysConfig.steer
        if steer and steer ~= gMapID then
            LOG("firstPacket, account=%s, pid=%d, process=%s, account steer to map %d", account, info.pid, process, steer)
            change_server(player.gid, process, steer)
            return
        end
    end

    if not p then
        p = player_t.create(account)
        if p then
            LOG("firstPacket, account=%s, pid=%d, process=%s, create new player in local ", account, p.pid, process)
            local dg = dbmng:getGlobal()
            dg.ply:insert({_id=account, pid=p._id, map=p.map, create=gTime, state=0})
        end
    end
    if not p then return INFO("NOT HANDLE WHY") end

    local map = p.map
    local pid = p._id

    LOG("firstPacket, setSrvID, pid=%d, map=%d, proc=%s, gid=%d", pid, map, process, player.gid)

    player_t.set_ply_map(player.gid, process, map, pid)
    return
end


function gm_platform(player, cmd)
    INFO("platform_gm cmd=%s", cmd)
    local tb = string.split(cmd, "=")
    gmmng:do_public_gm(tb)
end


