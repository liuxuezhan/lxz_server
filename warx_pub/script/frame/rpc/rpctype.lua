local RpcType = {}


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
	_write=function( packet, v )
	    v:write(packet)
	end,
	_read=function( packet )
	    local array = Array()
	    array:read(packet)
	    return array
	end,
	_check=function( v )
	    return Array:check(v)
	end,
}

RpcType.struct = {
	_write=function( packet, v )
	    v:write(packet)
	end,
	_read=function( packet )
	    local struct = Struct()
	    struct:read(packet)
	    return struct
	end,
	_check=function( v )
	    return Struct:check(v)
	end,
}

RpcType.__struct = {
    helloTest = "int id, int pid, string text",
}


return RpcType

