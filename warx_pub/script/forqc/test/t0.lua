local t1 = {}


function t1.action( idx )
    local total = 0
    local t1 = c_msec()
    local count = 20000
    for i = 1, count, 1 do
        if total - gCountLoadData < 80 then
            total = total + 1
            action( start_action, "forqc/test/t1" )
        else
            WARN( "total = %d, gCountLoadData = %d", total, gCountLoadData )
            wait_for_time( 1 )
        end
    end
    local t2 = c_msec()

    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    return "ok"
end

return t1

