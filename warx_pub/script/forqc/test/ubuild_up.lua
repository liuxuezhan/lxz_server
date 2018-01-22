--军团
--修建军团建筑升级

local mod = {}

function mod.action( _idx )

    local a = union_create(nil,1)

    for i = 1, 100 do
        local p = get_account(1000+i)
        lxz(p.pid)
        loadData(p)
        Rpc:union_quit( p )
        Rpc:union_apply( p,a[1].uid)
        chat(p, "@set_val=gold=100000000")
        chat(p, "@adddaoju=7001001=100")
        chat(p, "@adddaoju=7001002=100")
        chat(p, "@adddaoju=7001003=100")
        
        chat(p, "@adddaoju=7002001=100")
        chat(p, "@adddaoju=7002002=100")
        chat(p, "@adddaoju=7002003=100")
        
        chat(p, "@adddaoju=7003001=100")
        chat(p, "@adddaoju=7003002=100")
        chat(p, "@adddaoju=7003003=100")
        
        chat(p, "@adddaoju=7004001=100")
        chat(p, "@adddaoju=7004002=100")
        chat(p, "@adddaoju=7004003=100")

        chat(p, "@buildtop")
        chat(p, "@jump=1")

        Rpc:union_load( p,"build" )
        Rpc:union_buildlv_donate(p,1)
        --lxz(p[i].union_buildlv_donate)

        Rpc:union_buildlv_donate(p,2)
        --lxz(p[i].union_buildlv_donate)

        Rpc:union_buildlv_donate(p,3)
        --lxz(p[i].union_buildlv_donate)

        Rpc:union_buildlv_donate(p,5)
        sync(p)
        lxz(p.union_buildlv_donate)

        Rpc:union_quit( p)
    end

    sync( a[1] )
    Rpc:union_build_up(a[1],obj.idx,BUILD_STATE.UPGRADE) 
    build(a[1],obj,1)

    return "ok"

end




return mod

