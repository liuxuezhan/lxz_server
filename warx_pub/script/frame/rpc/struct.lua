local Struct = {}
mkcall(Struct)

local mt = {
    __index = function(table, key)
        if Struct[key] then 
            return Struct[key]
        else
            return table.data_[key]
        end

    end,
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

    ar:WriteString( self.type_ )
    rpc._write(ar, self.data_)
end

function Struct.read( self, ar )
    self.type_ = ar:ReadString()
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


Struct.UnionMember = "int pid, string name, int lv"
Struct.UnionUnion = "int uid, struct UnionMember members"



return Struct


--local Struct = {}
--
--Struct.PlyInfo = "int pid, int photo"
--Struct.UnionMember = "int uid, Struct PlyInfo ply, string uname"
--
--RpcType._struct = Struct
--

-- Protocol.Server
--agent_test_struct = "int id, Array Struct UnionMember mems, string name",
--example
--

--    local mems = {
--        { uid = 1, ply = { pid = 1, photo =1, item={sn=1,photo=1} }, uname = "foo", sex=0, lv = 5 },
--        { uid = 2, ply = { pid = 2, photo =2 }, uname = "bar", sex=1, lv = 6 }
--    }
--    Rpc:callAgent( 3, "agent_test_struct", 1, mems, "kidworm" )
--





