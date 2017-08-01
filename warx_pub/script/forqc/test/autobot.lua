local autobot = {}
bot_mng = require "forqc/test/autobot/bot_mng"

function autobot.action( idx )
    do_load("frame/event_handler")

    bot_mng:init("forqc/test/autobot")
    bot_mng:run()
    bot_mng:uninit()
    return "ok"
end

return autobot

