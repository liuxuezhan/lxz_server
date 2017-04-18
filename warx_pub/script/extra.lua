
--local t1 = c_msec()
--local t = snapshot()
--local t2 = c_msec()
--print( "use msec 1", t2 - t1 )

--local count = 1
--for k, v in pairs( t ) do
--    INFO( "MarkTable1, %s", v )
----    print( "key=", k )
----    print( "val=", v )
----    print( "--------")
--    count = count + 1
--    if count >= 10000000 then break end
--end
--
--print( "count = ", count )
--
--local t3 = c_msec()
--print( "use msec 2", t3 - t2 )
--
--function testmem()
--    local pid = c_getpid()
--    print( "child pid =", pid )
--    LOG( "i am the child, pid = %d", pid )
--    snapshot:make( "a.mem" )
--end
--
--c_forkto( testmem )
--
--

            local t = debug.tablemark(10)
            for k, v in pairs( t ) do
                INFO( "MarkTable, Start, %s", v )
            end
