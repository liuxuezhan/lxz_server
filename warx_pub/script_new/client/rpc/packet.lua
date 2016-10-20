local packet = packet or {}

function packet:ReadInt()
    return pack.pullInt()
end

function packet:ReadUint()
    return pack.pullUint()
end

function packet:ReadString()
    return pack.pullString()
end

function packet:ReadPack()
    return pack.pullPack()
end

function packet:WriteInt(v)
    pack.pushInt(v)
end

function packet:WriteUint(v)
    pack.pushUint(v)
end

function packet:WriteString(v)
    pack.pushString(v)
end

function packet:WritePack(v)
    pack.pushPack(v)
end

return packet
