module( "upgrade", package.seeall )
for k, v in pairs(king_city.officers or {}) do
    local ply = gePlayer(v[1])
    local union = unionmng.get_union(ply.uid)
    if union then
        v[5] = union.name
        v[6] = union.alias
    end
end

for k, v in pairs(king_city.kings or {}) do
    local ply = getPlayer(v[2])
    local union = unionmng.get_union(ply.uid)
    if union then
        v[14] = union.alias
    end
end
