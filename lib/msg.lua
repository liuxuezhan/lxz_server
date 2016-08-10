local json = require "json"
local msg = {}
function msg.pack(t)
    t = json.encode(t) 
    return t
end

function msg.unpack(t)
    t = json.decode(t) 
    return t
end
return msg

