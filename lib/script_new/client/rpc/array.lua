Array = {}
--mkcall(Array)

local mt = {
    __index = Array,
    __call = function(self,...)
        return self:getData()
    end,
}

function Array.new( typename )
    local array = {}
    setmetatable( array, mt )
    array:init( typename )
    return array
end

function Array.init( self, typename )
    if typename then
        if not RpcType[typename] and not RpcType.__struct[typename] then
            error( "[Array:init] RpcType required, got unknown type, "..typename )
        end
    end
    typename = typename or ""

    self.type_ = typename
    self.data_ = {}
end

function Array.check( self, array )
    return type(array)=="table" and getmetatable(array)==mt
end

function Array.write( self, ar )
    local rpc = RpcType[self.type_]
    assert( rpc )

    ar:writeString( self.type_ )
    local size = #self.data_
    ar:writeUshort( size )
    for k, v in ipairs(self.data_) do
        rpc:_write(ar, v)
    end
end

function Array.read( self, ar )
    self.type_ = ar:readString()
    local rpc = RpcType[self.type_]
    assert( rpc )

    local size = ar:readUshort()

    local data = {}
    for i = 1, size do
        table.insert( data, rpc:_read(ar) )
    end
    self.data_ = data
end

function Array.insert( self, pos, v )
    if not v then
        table.insert( self.data_, pos )
    else
        table.insert( self.data_, pos, v )
    end
end

function Array.remove( self, pos )
    return table.remove( self.data_, pos )
end

function Array.size( self )
    return #self.data_
end

function Array.sort( self, comp )
    table.sort( self.data_, comp )
end

function Array.getData( self )
	return self.data_
end

