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


function toMongo(host, port, db, user, pwd, mechanism, tips, is_reconnect)
    local mt = {
        onClose = function (self)
            self.state = 0
            LOG("connect Mongo %s:%d be close", self.host, self.port)
            dbmng:conn_close(self.sid)
            gConns[ self.sid ] = nil
        end,

        onConnectOk = function (self)
            --self.state = 1
            local t = mongo.client2(self.host, self.port, self.sid, self.tips == "Global")
            dbmng:conn_new(self.host, self.port, self.db, self.user, self.pwd, self.mechanism, self.sid, t[ self.db ], self.tips)
            if self.is_reconnect then
                mongo_save_mng.on_db_reconnect(self.tips == "Global")
            end
        end,

        onConnectFail = function (self) 
            LOG("connect Mongo  %s:%d fail", self.host, self.port)
            timer.new("toMongo", 5, self.host, self.port, self.db, self.user, self.pwd, self.mechanism, self.tips, self.is_reconnect)
            gConns[ self.sid ] = nil
        end,
    }
    mt.__index = mt
    local sid = connect(host, port, 0, 2)
    local t = { host=host, port=port, sid=sid, state=0, db=db, user=user, pwd=pwd, mechanism=mechanism, tips=tips, action="db", is_reconnect=is_reconnect}
    gConns[ sid ] = t
    return setmetatable(t, mt)
end


function toSrv(host, port)

end

return conn

