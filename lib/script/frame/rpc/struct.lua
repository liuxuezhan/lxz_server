local Struct = {}
mkcall(Struct)

local mt = {
    __index = Struct,
    __call = function(self,...)
        return self:getData()
    end,
}

function Struct.new( typename )
    local struct = {}
    setmetatable( struct, mt )
    struct:init( typename )
    return struct
end

function Struct.init( self, typename )
    if typename then
        if not RpcType[typename] then
            error( "[Struct:init] RpcType required, got unknown type, "..typename )
        end
    end
    typename = typename or ""

    self.type_ = typename
    self.data_ = {}
end

function Struct.check( self, struct )
    return type(struct)=="table" and getmetatable(struct)==mt
end

function Struct.write( self, ar )
    local rpc = RpcType[self.type_]
    assert( rpc )

    ar:writeString( self.type_ )
    rpc:_write(ar, self.data_)
end

function Struct.read( self, ar )
    self.type_ = ar:readString()
    local rpc = RpcType[self.type_]
    assert( rpc )

    self.data_ = rpc:_read(ar)
end

function Struct.getData( self )
	return self.data_
end

function Struct.setData(self, dataArr)
	self.data_ = dataArr
end

return Struct



