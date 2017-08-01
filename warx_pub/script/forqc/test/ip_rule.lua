local t1 = {}

function t1.action( idx )
    local sid = connect( "192.168.100.12", 6001, 0, 0 )
    if sid then
        local node = {}
        node.action = "ip_rule"
        node.gid = sid
        --node.func = t1.add_white
        --node.func = t1.add_black
        node.func = t1.clear
        gConns[ sid ] = node
    end
end


function t1.add_white( node )
    print( " function t1.add_white( node ) ") 
    pushHead2s( node.gid, hashStr( "firstPacket" ) )
    pushInt( hashStr( "ip_rule" ) )
    pushInt( hashStr( "ip_rule_add_white" ) )
    --pushInt( c_inet_addr( "192.168.103.189" ) )
    pushInt( c_inet_addr( "192.168.103.188" ) )
    pushOver()
end

function t1.add_black( node )
    print( " function t1.add_black( node )" )
    pushHead2s( node.gid, hashStr( "firstPacket" ) )
    pushInt( hashStr( "ip_rule" ) )
    pushInt( hashStr( "ip_rule_add_black" ) )
    --pushInt( c_inet_addr( "192.168.101.40" ) )
    pushInt( c_inet_addr( "192.168.103.189" ) )
    pushOver()
end

function t1.clear( node )
    print( "function t1.clear( node )" )
    pushHead2s( node.gid, hashStr( "firstPacket" ) )
    pushInt( hashStr( "ip_rule" ) )
    pushInt( hashStr( "ip_rule_add_black" ) )
    pushInt( 0 )
    pushOver()
end



return t1
