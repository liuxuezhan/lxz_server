local t1 = {}

function t1.action( idx )
    local sid = connect( "192.168.100.12", 6001, 0, 0 )
    if sid then
        local node = {}
        node.action = "ip_rule"
        node.gid = sid
        gConns[ sid ] = node
    end
end
return t1
