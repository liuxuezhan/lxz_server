local packet = packet or {}

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
