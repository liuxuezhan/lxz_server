local skynet = require "skynet"
local mysql = require "mysql"
require "skynet.manager"    -- import skynet.register
local command={}


local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

function command.get(db,sql,...)
    lxz(sql)
    --local res =  db:query(sql )
    local res = db:query("select * from cats order by id asc")
    lxz(res)
    return res
end

local function test2( db)
    local i=1
    while true do
        local    res = db:query("select * from cats order by id asc")
        skynet.error ( "test2 loop times=" ,i,"\n","query result=",dump( res ) )
        res = db:query("select * from cats order by id asc")
        skynet.error ( "test2 loop times=" ,i,"\n","query result=",dump( res ) )

        skynet.sleep(1)
        i=i+1
    end
end
local function test3( db)
    local i=1
    while true do
        local    res = db:query("select * from cats order by id asc")
        skynet.error ( "test3 loop times=" ,i,"\n","query result=",dump( res ) )
        res = db:query("select * from cats order by id asc")
        skynet.error ( "test3 loop times=" ,i,"\n","query result=",dump( res ) )
        skynet.sleep(1)
        i=i+1
    end
end
skynet.start(function()

    local function on_connect(db)
        db:query("set charset utf8");
    end
    local db=mysql.connect({
        host="127.0.0.1",
        port=3306,
        database="server1",
        user="root",
        password="root",
        max_packet_size = 1024 * 1024,
        on_connect = on_connect
    })

    if not db then
        skynet.error("failed to connect")
	return
    end
    skynet.error("testmysql success to connect to mysql server")


    res = db:query("select * from cats order by id asc")
    skynet.error ( dump( res ) )

    -- test in another coroutine
   -- skynet.fork( test2, db)
    -- skynet.fork( test3, db)

    skynet.error ("escape string test result=", mysql.quote_sql_str([[\mysql escape %string test'test"]]) )

    -- bad sql statement
    local res =  db:query("select * from notexisttable" )
    skynet.error( "bad query test result=" ,dump(res) )

    skynet.dispatch("lua", function(session, address, cmd, sql,...)
	lxz()
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(db,sql,...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
    skynet.register "mysql_server" --真SMYSQL真真真真agent真真

    --db:disconnect()
    --skynet.exit()
end)

