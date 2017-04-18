--lxz
--lxz1
local t1 = {}

function t1.action( _idx )
    require("union_tech_t")
    require("frame/debugger")
    local name = tostring(math.floor(gTime%1000))
    local p = get_one2(name)
    chat(p, "@set_val=gold=100000000" )
    chat(p, "@addres=1=10000000")
    chat(p, "@addres=2=10000000")
    chat(p, "@addres=3=10000000")
    chat(p, "@addres=4=10000000")
    sync( p )
    Rpc:union_quit( p )
    Rpc:union_create(p,name,name,40,1000)
    wait_for_ack( p, "union_on_create" )


    Rpc:union_mission_get(p)
    sync(p)
    lxz(p.utask)
    local f = true
    for k, v in pairs( p.utask.cur ) do
        if v.class == 13 then 
            Rpc:union_mission_set(p,k)
            f = false
        end
    end
    if f then 
        Rpc:union_mission_set(p,1)
        Rpc:union_mission_set(p,2)
        Rpc:union_mission_set(p,3)
        Rpc:union_mission_set(p,4)
        Rpc:union_mission_set(p,5)
        Rpc:union_mission_set(p,6)
        Rpc:union_mission_get(p)
        sync(p)
        return
    end
    sync(p)
    Rpc:union_mission_get(p)
    sync(p)
    lxz(p.utask)

    while true do

        local id = 1001
        Rpc:union_donate(p, id, 1)

        --资源检查
        Rpc:union_load(p,"donate")
        Rpc:union_load(p,"union_donate")
        sync(p)
        local new = p.union_tech_info
        if p.donate.flag == 1 then 
            local g =  0
            gold = p.gold
            if p.donate.CD_num < #resmng.CLEAR_DONATE_COST then
                g = resmng.CLEAR_DONATE_COST[p.donate.CD_num +1]
            else g = resmng.CLEAR_DONATE_COST[#resmng.CLEAR_DONATE_COST] end
            Rpc:union_donate_clear(p) 
            sync(p)
        end 

        Rpc:union_mission_get(p)
        sync(p)
        if p.utask.cur[1].state == 5 then 
            Rpc:union_mission_add(p)
            return "ok" 
        end

        if union_tech_t.is_exp_full(new ) then
            Rpc:union_tech_upgrade(p,id)
            break
        end
    end
end

return t1

