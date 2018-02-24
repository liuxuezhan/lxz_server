
--gPendingSave.mail[ "1_270130" ].tm_lock = gTime
COMMON_WRITE_CONCERN = {w=1, wtimeout=5000} -- 故意不使用j=true的选项，3.2后默认50ms刷一次，参考：https://docs.mongodb.com/manual/core/journaling/
gUpdateCallBack = gUpdateCallBack or {}

gPendingSaveOp = gPendingSaveOp or {}
gPendingSave = gPendingSave or {}
gPendingDelete = gPendingDelete or {}
gPendingInsert = gPendingInsert or {}

gPendingReady = gPendingReady or {}
gPendingReadyOp = gPendingReayOp or {}


gPendingActions = gPendingActions or {}

gThreadAction = gThreadAction or false
gThreadActionState = gThreadActionState or "unable"
gThreadActionTime = gThreadActionTime or 0

local bson_encode_order = bson.encode_order
-- can use version

function registe_update_callback( tab, func )
    gUpdateCallBack[ tab ] = func
end

function init_pending()
    setmetatable( gPendingSaveOp, {
        __index = function(t,k)
            local n = {}
            rawset(t, k, n )
            return n
        end
        }
    )

    __mt_rec = {
        __newindex = function (t, k, v)
            rawset(t, k, v)
            gPendingSaveOp[ t.__name ][ k ] = 0
        end,

        __index = function (t, k)
            local node = {}
            gPendingSaveOp[ t.__name ][ k ] = 0
            rawset( t, k, node )
            return node
        end
    }
    __mt_tab = {
        __index = function (t, k)
            local node = { __name = k }
            setmetatable(node, __mt_rec)
            t[ k ] = node
            return node
        end
    }
    setmetatable(gPendingSave, __mt_tab)

    __mt_del_rec = {
        __newindex = function (t, k, v)
            local at = {}
            gPendingSave[ t.tab_name ][ k ] = at
            gPendingSaveOp[ t.tab_name ][ k ] = -1
        end
    }
    __mt_del_tab = {
        __index = function (t, k)
            local node = {tab_name=k}
            setmetatable(node, __mt_del_rec)
            t[ k ] = node
            return node
        end
    }
    setmetatable(gPendingDelete, __mt_del_tab)

    __mt_new_rec = {
        __newindex = function (t, k, v)
            gPendingSave[ t.tab_name ][ k ] = v
            gPendingSaveOp[ t.tab_name ][ k ] = 1
        end
    }
    __mt_new_tab = {
        __index = function (t, k)
            local node = {tab_name=k}
            setmetatable(node, __mt_new_rec)
            t[ k ] = node
            return node
        end
    }
    setmetatable(gPendingInsert, __mt_new_tab)
end


function make_ready()
    local cbs = gUpdateCallBack
    local update = false
    local cur = gFrame
    local cb_map = {}
    local actions = gPendingActions

    for tab, doc in pairs(gPendingSave) do
        local ops = gPendingSaveOp[ tab ]
        local cb = nil
        local docs_upd = {}
        local docs_del = {}

        local ready = gPendingReady[ tab ] 
        if not ready then
            ready = {}
            gPendingReady[ tab ] = ready 
        end

        local readyOp = gPendingReadyOp[ tab ]
        if not readyOp then
            readyOp = {}
            gPendingReadyOp[ tab ] = readyOp
        end

        for id, chgs in pairs(doc) do
            if id ~= "__name" and id ~= "__cache" then
                update = true
                local op = ops[ id ]

                doc[ id ] = nil
                ops[ id ] = nil

                if not op then
                    WARN( "[SAVE], no op, %s, %s", tab, id )

                else
                    if op == 0 then
                        local pre_op = readyOp[ id ]
                        if not pre_op then
                            readyOp[ id ] = 0
                            ready[ id ] = chgs

                        elseif pre_op >= 0 then
                            local node = ready[ id ]
                            if not node then
                                node = {}
                                ready[ id ] = node
                            end
                            for k, v in pairs( chgs ) do node[ k ] = v end

                        elseif pre_op == -1 then
                            WARN( "update after delete" )

                        end


                    elseif op == 1 then
                        readyOp[ id ] = 1
                        ready[ id ] = chgs

                    elseif op == -1 then
                        readyOp[ id ] = -1
                        ready[ id ] = -1

                    end

                    if cb == nil then
                        cb = cbs[ tab ]
                        if cb == nil then
                            if _G[ tab ] and type( _G[ tab ] ) == "table" then
                                if _G[ tab ].on_check_pending then
                                    cb = _G[ tab ].on_check_pending
                                    if cb == nil then cb = false end
                                end
                            end
                            cbs[ tab ] = cb
                        end
                    end

                    if cb then
                        cb_map[cb] = cb_map[cb] or {}
                        cb_map[cb][id] = chgs
                    end
                end

            end
        end
    end

    if update then
        for cb, params in pairs(cb_map) do
            for id, chgs in pairs(params) do
                cb(nil, id, chgs )
            end
        end
        return true
    end
end


function make_action()
    local cbs = gUpdateCallBack
    local update = false
    local cur = gFrame
    local cb_map = {}
    local actions = gPendingActions
    local db = dbmng:tryOne(1)

    for tab, doc in pairs(gPendingReady) do
        local ops = gPendingReadyOp[ tab ]
        local docs_upd = {}
        local docs_del = {}


        for id, chgs in pairs(doc) do
            update = true
            local op = ops[ id ]

            doc[ id ] = nil
            ops[ id ] = nil


            if not op then
                WARN( "[SAVE], no op, %s, %s", tab, id )

            else
                if op == 1 then
                    LOG( "[DB] insert, %s, %s", tab, id )
                    lxz(chgs)
                    db[ tab ]:update({_id=id}, chgs , true)
                    --table.insert( docs_upd, { q={_id=id}, u=chgs, upsert=true, multi=false })
                    if #docs_upd > 900 then
                        table.insert( actions, bson_encode_order( "update", tab, "updates", docs_upd, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN ) )
                        docs_upd = {}
                    end

                elseif op == -1 then
                    LOG( "[DB] delete, %s, %s", tab, id )
                    db[ tab ]:delete({_id=id})
                    --table.insert( docs_del, { q={_id=id}, limit=1 } )

                    if #docs_del > 900 then
                        table.insert( actions, bson_encode_order( "delete", tab, "deletes", docs_del, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN ) )
                        docs_del = {}
                    end

                else
                    LOG( "[DB] update, %s, %s", tab, id )
                    db[ tab ]:update({_id=id}, chgs, true)
                    --table.insert( docs_upd, { q={_id=id}, u={["$set"]=chgs}, upsert=true, multi=false })

                    if #docs_upd > 900 then
                        table.insert( actions, bson_encode_order( "update", tab, "updates", docs_upd, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN ) )
                        docs_upd = {}
                    end
                end
            end
        end
        if #docs_upd > 0 then table.insert( actions, bson_encode_order( "update", tab, "updates", docs_upd, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN ) ) end
        if #docs_del > 0 then table.insert( actions, bson_encode_order( "delete", tab, "deletes", docs_del, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN ) ) end
    end
    return true
end


function do_global_saver()
    local co = coroutine.running()
    --WARN( "[GLOBAL_SAVER], born, %s", tostring(co) )
    gThreadAction = co
    gThreadActionState = "start"
    gThreadActionTime = gTime

    local count = 0

    while true do
        while #gPendingActions < 1 do
            make_action()
            if #gPendingActions > 0 then
                break
            else
                gThreadActionState = "idle"
                gThreadActionTime = gTime
                coroutine.yield()
                gThreadActionState = "start"
            end
        end
        gThreadActionTime = gTime
        gThreadActionState = "action"

        local db = dbmng:tryOne()
        if not db then
            --WARN( "[GLOBAL_SAVER], dead, %s, no db connection", tostring(co) )
            if gThreadAction == co then
                gThreadAction = nil
                gThreadActionState = "disconnect"
                gThreadActionTime = 0
            end
            return
        end

        local one = gPendingActions[ 1 ] 
        local info = db:runCommand2( {bson_cmd=one} )

        if info then
            if info.ok and info.ok == 1 then
                if info.errmsg or info.writeErrors or info.writeConcernError then
                    WARN( "[DB], mongo_errord" )
                    dumpTab(info, "check_save", 100, true)
                    dumpTab(bson.decode( one ), "check_save", 100, true)

                end
            else
                WARN( "[DB], mongo_errord" )
                dumpTab(info, "check_save", 100, true)
            end

            if gThreadAction ~= co then
                --WARN( "[GLOBAL_SAVER], dead, %s, be replaced", tostring(co) )
                return
            end

            table.remove( gPendingActions, 1 )
            count = count + 1
            if count > 1024 then
                gThreadAction = nil
                gThreadActionState = "retire"
                gThreadActionTime = 0
                --WARN( "[GLOBAL_SAVER], retire, %s", tostring(co) )
                return
            end
        end
    end
end

function global_saver()
    local co = coroutine.running()
    local flag, code = xpcall( do_global_saver, STACK )
    --if not flag then WARN( "[GLOBAL_SAVER], error, code=%s", code ) end
    if gThreadAction == co then
        gThreadAction = nil
        gThreadActionState = "dead"
        gThreadActionTime = 0
    end
end

function global_save()
    make_ready()
    if gThreadAction then
        if gThreadActionState == "idle" then
            coro_mark( gThreadAction, "outpool" )
            coroutine.resume( gThreadAction )
        end
    else
        local co = coroutine.create( global_saver )
        coro_mark_create( co, "global_saver" )
        coro_mark( co, "outpool" )
        coroutine.resume( co )
    end
end


function dump_pending(filename)
    local file,err = io.open( filename, "wb" )
    if err then
        ERROR("zhoujy_error: dump2file filename=%s catch an error:%s", filename, err)
        return
    end

    make_action()
    local infos = {}
    file:write( "return " )
    file:write( "\n" )
    for _, v in ipairs( gPendingActions ) do
        local info = bson.decode( v )
        if info.update then
            table.insert( infos, { "update", info.update, info.updates } )
        else
            table.insert( infos, { "delete", info.delete, info.deletes } )
        end
    end
    doDumpTab( infos, 4, 20, 0, function (fmt, ...)
            file:write( string.format(fmt, ...) )
            file:write( "\n" )
        end
    )

    file:close()
end

function restore_pending(filename)
    WARN( "[RESTORE_PENDING], %s", filename )
    local code, tab = pcall( dofile, filename  )
    if not code then
        WARN( "[RESTORE_PENDING], %s, error: %s, %s", filename, code, tab )
        os.execute( "exit -1" )
    end

    for _, v in ipairs( tab ) do
        local op = v[1]
        local tab = v[2]
        
        if op == "update" then
            for _, node in pairs( v[3] ) do
                local id = node.q._id
                if node.u[ "$set" ] then
                    gPendingSave[ tab ][ id ] = node.u[ "$set" ]
                else
                    gPendingInsert[ tab ][ id ] = node.u
                end
            end
        elseif op == "delete" then
            for _, node in pairs( v[3] ) do
                local id = node.q._id
                gPendingDelete[ tab ][ id ] = 1
            end
        end
    end
    dumpTab( tab, "restore_pending" )
    global_save()
    os.execute( string.format( "mv %s %s.done", filename, filename ) )
end

function delete_col(tab)
    gPendingSave[tab] = nil
    local actions = gPendingActions
    LOG( "[DB] delete collection %s", tab)
    local docs_del = {{ q={}, limit=0 }}
    table.insert( actions, bson_encode_order( "delete", tab, "deletes",docs_del, "ordered", false, "writeConcern", COMMON_WRITE_CONCERN ) ) 
end

