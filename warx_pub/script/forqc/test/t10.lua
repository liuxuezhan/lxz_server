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

    local p3 = get_one2("r03")
    chat( p3, "@set_val=gold=100000000" )
    chat( p3, "@buildtop" )
    chat( p3, "@addbuf=1=-1" )
    sync( p3 )

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

    Rpc:union_task_add(p, UNION_TASK.PLY, p3.eid, "",2, 1, 1,30*20000, 100, 100  )--发布悬赏任务
    sync( p )

    pause()
    atk(p2,p3)

    return "ok"

end




return mod

