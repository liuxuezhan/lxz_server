--军团
--悬赏任务:玩家,npc城市,英雄

local mod = {}

function mod.action( _idx )

    local a = union_create()
    local b = union_create()

    Rpc:union_task_add(a[1], UNION_TASK.PLY, b[1].eid, "",2, 1, 1,30*20000, 100, 100  )--发布玩家悬赏任务
    sync( a[1] )

    atk(a[2],b[1])
    Rpc:union_task_get(a[1])
    wait_for_ack( a[1], "union_task_get" )

    Rpc:get_can_atk_citys_req(a[2]) 
    wait_for_ack( a[2], "get_can_atk_citys_ack")
    Rpc:union_task_add(a[2], UNION_TASK.NPC, a[2].city_propid[1], "",1, 1, 1,30*20000, 100, 100  )--发布NPC悬赏任务
    sync( a[2] )
    atk(a[1],_npc[a[2].city_propid[1]])
    Rpc:union_task_get(a[1])
    wait_for_ack( a[1], "union_task_get" )

    local hero = get_hero( b[1] )
    Rpc:hero_cure_quick(b[1], hero.idx, 10)
    chat( b[1], "@addarm=1001=10" )
    sync( b[1] )

    chat( a[1], "@eff_add=Captive_R=10000" )
    atk(a[1],b[1])

    Rpc:union_task_add(b[1], UNION_TASK.HERO, a[1].eid, hero._id,1, 1, 1,30*20000, 100, 100  )--发布英雄悬赏任务
    sync( b[1] )
    atk(b[2],a[1])

    return "ok"

end

return mod

