--@zoumuyu 玩家离线事件
module("todo", package.seeall)

function add_to_do(pid, command, ...)
    if is_online(pid) then
        local ply = get_ply(pid)
        player_t[command](ply, ...)
    else
        local ply = get_ply_info(pid)
        if not ply then
            WARN("zhoujy_warning: add_to_do can not get ply, pid=%d", pid)
            return
        end
        ply.ntodo = (ply.ntodo or 0) + 1
        local id = bson.objectid()
        local task = {_id = id, pid = ply.pid, command = command, ntodo = ply.ntodo, time = gTime, args = {...}}
        gPendingInsert.todo[id] = task
    end
end

function after_ply_loggin(ply)
    if ply.ntodo and ply.ntodo > 0 then
        local db = dbmng:getOne(ply.pid) 
        local info = db.todo:find( {pid=ply.pid} )
        if info then
            local tbl = {}
            while info:hasNext() do
                local task = info:next()
                table.insert(tbl, task)
            end
            table.sort(tbl, function(a, b ) return (a.ntodo < b.ntodo) end)
            for _, v in ipairs(tbl) do
                gPendingDelete.todo[ v._id ] = 1
                player_t[ v.command ]( ply, table.unpack( v.args ) )   
            end
        end
        ply.ntodo = 0
    end
end

function is_online(pid)
    return playermng.is_online(pid)
end

function get_ply(pid)
    return getPlayer(pid)
end

function get_ply_info(pid)--离线dna    
    return getPlayerInfo(pid)
end

