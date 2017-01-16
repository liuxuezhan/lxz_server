module("conn", package.seeall)

function toGate(host, port)
    local mt = {
        onClose = function (self)
            self.state = 0
            LOG("connect Gate %s:%d be close", self.host, self.port)
            timer.new("toGate", 2, self.host, self.port)
            gConns[ self.sid ] = nil
        end,

        onConnectOk = function (self)
            WARN( "connecting to Gate, done")
            self.state = 1
            pushHead(self.sid, 0, gNetPt.NET_SET_MAP_ID)
            pushInt(gMapID)
            pushOver()
            _G.gAgent = {pid=0, account="@ConGate", gid=self.sid}
            _G.GateSid = self.sid
            c_set_gate( self.sid )
        end,

        onConnectFail = function (self) 
            LOG("connect Gate %s:%d fail", self.host, self.port)
            timer.new("toGate", 5, self.host, self.port, self.sid)
            gConns[ self.sid ] = nil
        end,
    }
    mt.__index = mt
    local sid = connect(host, port, 0, 0)
    local t = { host=host, port=port, sid=sid, state=0 }
    gConns[ sid ] = t

    return setmetatable(t, mt)
end


function toMongo(host, port, db, tips)
    local mt = {
        onClose = function (self)
            self.state = 0
            LOG("connect Mongo %s:%d be close", self.host, self.port)
            dbmng:conn_close(self.sid)
            gConns[ self.sid ] = nil
        end,

        onConnectOk = function (self)
            print( "connect mongo, ok" )
            self.state = 1
            local t = mongo.client2(self.host, self.port, self.sid)
            dbmng:conn_new(self.host, self.port, self.db, self.sid, t[ self.db ], self.tips)
        end,

        onConnectFail = function (self) 
            LOG("connect Mongo  %s:%d fail", self.host, self.port)
            timer.new("toMongo", self.host, self.port, self.db, self.tips)
            gConns[ self.sid ] = nil
        end,
    }
    mt.__index = mt
    local sid = connect(host, port, 0, 2)
    local t = { host=host, port=port, sid=sid, state=0, db=db, tips=tips, action="db" }
    gConns[ sid ] = t
    print( "connect", host, port, sid )
    return setmetatable(t, mt)
end


function toSrv(host, port)

end

return conn

