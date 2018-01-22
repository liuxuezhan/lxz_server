--军团
--日志:定时任务
local t1 = {}

function t1.action(idx)
    local a = union_create("555",10)
    local b = union_create("666",10)

    while true do
        lxz()
        for i, p in pairs(a) do
            mission_do(p,b[i])
        lxz()
            atk(p,b[i])
        lxz()
            build_all(p)
        lxz()
            union_tech(p,1001)
        lxz()
        end
        lxz()
        for _, v in pairs(a) do Rpc:union_help_set(v, 0) end

        for i, p in pairs(b) do
            lxz()
            atk(p,a[i])
        lxz()
            mission_do(p,a[i])
        lxz()
            build_all(p)
        lxz()
            union_tech(p,1001)
        lxz()
        end
        lxz()
        for _, v in pairs(b) do Rpc:union_help_set(v, 0) end
    end
    return "ok"
end

function build_all(p)
    for idx, v in pairs(p._build or {} ) do
        build_up(p, v.propid + 1)
    end

    for idx, v in pairs(p._build or {} ) do
        if v.tmSn then
            Rpc:union_help_add(p,v.tmSn)
            sync(p)
            --Rpc:acc_build(p, idx, ACC_TYPE.GOLD)
        end
    end

end

return t1
