module("crontab", package.seeall)

function union_donate_summary()
    local t = os.date("*t", gTime)
    LOG("[Union] summary start")
    local n = 1
    for _, u in pairs(unionmng.get_all()) do

        if n % 50 == 0 then 
            begJob() 
            wait(1) 
        end
        n = n + 1

        u:donate_summary_day()
        if t.wday == 1 then
            u:donate_summary_week()
        end
    end
    LOG("[Union] summary end")
end


