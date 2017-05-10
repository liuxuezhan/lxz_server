
local t1 = {}

function t1.action( idx )
    local p = get_account( idx )
    print( "get player", p.pid )

    print( "l login" )
    print( "p print" )
    print( "s set" )
    print( "r run" )
    print( "q quit" )
    print( "h help" )

    while true do
        print( ">" )
        local line = io.read( "*line" )
        if line then
            if string.len( line ) > 0 then
                local info = string.split( line, " " )
                if info[1] == "p" then
                    Rpc:dbg_show( p, info[ 2 ] )
                    wait_for_ack( p, "dbg_show" )

                elseif info[1] == "l" then
                    Rpc:dbg_ask( p, info[ 2 ] )
                    wait_for_ack( p, "dbg_show" )

                elseif info[1] == "r" then
                    Rpc:dbg_run( p, string.sub( line, 2, -1 ) )
                    wait_for_ack( p, "dbg_show" )

                elseif info[1] == "s" then
                    if #info == 3 then
                        Rpc:dbg_set( p, info[2], info[3] )
                        wait_for_ack( p, "dbg_show" )
                    end

                elseif info[1] == "h" then
                    print( "l login" )
                    print( "p print" )
                    print( "s set" )
                    print( "r run" )
                    print( "q quit" )

                elseif info[1] == "q" then
                    Rpc:dbg_ask( p, "a" )
                    os.exit(-1)

                end
            end
            wait_for_time( 1 )
        end
    end
end

return t1
