local RpcType = {}

RpcType.byte = {
    _write=function( packet, v )
        packet:WriteChar(v)
    end,
    _read=function( packet )
        return packet:ReadChar()
    end
}

RpcType.bool = {
    _write=function( packet, v )
        if v then
            packet:WriteChar(1)
        else
            packet:WriteChar(0)
        end
    end,
    _read=function( packet )
        local byte = packet:ReadChar()
        return byte ~= 0
    end
}

RpcType.short = {
    _write=function( packet, v )
        packet:WriteShort(v)
    end,
    _read=function( packet )
        return packet:ReadShort()
    end
}

RpcType.ushort = {
    _write=function( packet, v )
        packet:WriteUshort(v)
    end,
    _read=function( packet )
        return packet:ReadUshort()
    end
}

RpcType.int = {
    _write=function( packet, v )
        if not packet then debug.traceback() end
        packet:WriteInt(v)
    end,
    _read=function( packet )
        return packet:ReadInt()
    end
}

RpcType.uint = {
    _write=function( packet, v )
        packet:WriteUint(v)
    end,
    _read=function( packet )
        return packet:ReadUint()
    end
}

RpcType.string = {
    _write=function( packet, v )
        packet:WriteString(v)
    end,
    _read=function( packet )
        return packet:ReadString()
    end
}

RpcType.pack = {
    _write=function( packet, v )
        --packet:WritePack(MsgPack.pack(v))
        packet:WritePack(cmsgpack.pack(v))
    end,
    _read=function( packet )
        --return MsgPack.unpack(packet:ReadPack())
        return cmsgpack.unpack(packet:ReadPack())
    end,
    _check=function(v)
        return type(v) == "table"
    end,
}

RpcType.array = {
    _write=function( packet, value, idx, define )
        local what = define[ idx ]
        local node = RpcType[ what ]
        if node then
            local count = 0
            local offset = bufOffSet()
            packet:WriteUint( 0 )

            for k, v in pairs( value ) do
                node._write( packet, v, idx+1, define )
                count = count + 1
            end
            pushIntAt( offset, count )
        else
            error(string.format("invalid rpc_type! what=%s", what))
        end
    end,

    _read=function( packet, idx, define )
        local what = define[ idx ]
        local node = RpcType[ what ]
        if node then
            local count = packet:ReadUint()
            local as = {}
            for i = 1, count, 1 do
                local t = node._read( packet, idx+1, define )
                table.insert( as, t )
            end
            return as
        end
    end
}

RpcType.struct = {
    _write=function( packet, value, idx, define )
        local stype = define[ idx ]
        local node = RpcType._struct[ stype ]
        if node then
            for i, v in ipairs( node ) do
                RpcType[ v.t ]._write( packet, value[ v.n ], 1, v.d )
            end
        else
            error(string.format("invalid rpc_type! stype=%s", stype))
        end
    end,

    _read=function( packet, idx, define )
        local stype = define[ idx ]
        local node = RpcType._struct[ stype ]
        local res = {}
        local remain_len = nil
        if node then
            for k, v in ipairs( node ) do
                -- checkBuf是为了兼容act项目的网页客户端登录
                remain_len = packet:checkBuf()
                if remain_len and remain_len > 0 then
                    res[ v.n ] = RpcType[ v.t ]._read( packet, 1, v.d )
                else
                    break
                end
            end
        end
        return res
    end
}

return RpcType
