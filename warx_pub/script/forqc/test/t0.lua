local t1 = {}


function t1.action( idx )
    local total = 0
    for i = 1, 8192, 1 do
        if total - gCountLoadData < 100 then
            total = total + 1
            action( start_action, "forqc/test/t1" )
        else
            wait_for_time( 1 )
        end
    end
    return "ok"
end


return t1

