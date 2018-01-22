local t1 = {}


function t1.action( idx )
    local total = 0
    local t1 = c_msec()
    local count = 50000

    while total < count do
        if total - gCountLoadData < 200 then
            total = total + 1
            action( start_action, "forqc/test/t_gm" )
        else
            WARN( "total = %d, gCountLoadData = %d", total, gCountLoadData )
            wait_for_time( 1 )
            --wait( 1 )
        end
    end

    while gCountLoadData  < count do
        WARN( "Count = %d", gCountLoadData )
        --wait_for_time( 1 )
        wait( 1 )
    end

    local t2 = c_msec()
    WARN( "Count = %d, use = %d", count, t2 - t1 )
    return "ok"
end

return t1

