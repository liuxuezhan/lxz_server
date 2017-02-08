--lxz
--军团任务

local mod = {}

function mod.action( _idx )
    local p = get_one2("r01")
    chat( p, "@set_val=gold=100000000" )
    chat( p, "@buildtop" )
    chat( p, "@addbuf=1=-1" )
    chat( p, "@addres=1=10000000" )
    sync( p )

    local p2 = get_one2("r02")
    chat( p2, "@set_val=gold=100000000" )
    chat( p2, "@buildtop" )
    chat( p2, "@addbuf=1=-1" )
    sync( p2 )

    local p3 = get_one2("r13")
    chat( p3, "@set_val=gold=100000000" )
    chat( p3, "@buildtop" )
    chat( p3, "@addbuf=1=-1" )
    sync( p3 )

    local p4 = get_one2("r04")
    chat( p4, "@set_val=gold=100000000" )
    chat( p4, "@buildtop" )
    chat( p4, "@addbuf=1=-1" )
    sync( p4 )

    if p.uid < 10000 then
        Rpc:union_quit( p )
        sync( p )
    end

    if p.uid == 0 then
        Rpc:union_create(p,tostring(p.pid),p.account,40,1000)
        wait_for_ack( p, "union_on_create" )
    end

    if p2.uid ~= p.uid then
        Rpc:union_quit( p2 )
        Rpc:union_apply(p2,p.uid)
        sync( p2 )
    end

    if p3.uid < 10000 then
        Rpc:union_quit( p3 )
        sync( p3 )
    end

    if p3.uid == 0 then
        Rpc:union_create(p3,tostring(p3.pid),"r03",40,1000)
        wait_for_ack( p3, "union_on_create" )
    end

    if p4.uid ~= p3.uid then
        Rpc:union_quit( p4 )
        Rpc:union_apply(p4,p3.uid)
        sync( p4 )
    end

    Rpc:union_task_add(p, UNION_TASK.PLY, p3.eid, "",2, 1, 1,30*20000, 100, 100  )--发布玩家悬赏任务
    sync( p )

    atk(p2,p3)
    Rpc:union_task_get(p)
    wait_for_ack( p, "union_task_get" )

    Rpc:get_can_atk_citys_req(p2) 
    wait_for_ack( p2, "get_can_atk_citys_ack")
    Rpc:union_task_add(p2, UNION_TASK.NPC, p2.city_propid[1], "",1, 1, 1,30*20000, 100, 100  )--发布NPC悬赏任务
    sync( p2 )
    atk(p,_npc[p2.city_propid[1]])
    Rpc:union_task_get(p)
    wait_for_ack( p, "union_task_get" )

    local hero = get_hero( p3, 1 )
    if not hero then return "nohero" end
    Rpc:hero_cure_quick(p3, hero.idx, 10)
    chat( p3, "@addarm=1001=10" )
    sync( p3 )

    chat( p, "@eff_add=Captive_R=10000" )
--    pause()
    atk(p,p3)

    Rpc:union_task_add(p3, UNION_TASK.HERO, p.eid, hero._id,1, 1, 1,30*20000, 100, 100  )--发布英雄悬赏任务
    sync( p3 )
    atk(p4,p)

    return "ok"

end




return mod

