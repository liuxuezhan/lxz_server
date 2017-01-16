local packet = packet or {}

function packet:checkBuf()
    return checkBuf()
end

function packet:ReadChar()
    return pullChar()
end

function packet:ReadUchar()
    return pullUchar()
end

function packet:ReadShort()
    return pullShort()
end

function packet:ReadUshort()
    return pullUshort()
end

function packet:ReadInt()
    return pullInt()
end

function packet:ReadUint()
    return pullUint()
end

function packet:ReadString()
    return pullString()
end

function packet:ReadPack()
    return pullPack()
end

function packet:WriteChar(v)
    pushChar(v)
end

function packet:WriteUchar(v)
    pushUchar(v)
end

function packet:WriteShort(v)
    pushShort(v)
end

function packet:WriteUshort(v)
    pushUshort(v)
end

function packet:WriteInt(v)
    pushInt(v)
end

function packet:WriteUint(v)
    pushUint(v)
end

function packet:WriteString(v)
    pushString(v)
end

function packet:WritePack(v)
    pushPack(v)
end

return packet
