--军团
--军团建筑被攻击

local mod = {}

function mod.action( _idx )

    local a = union_create()
    local b = get_account()

    local obj = set_build(a[1], 10021001, a[1].x, a[1].y ) 
    atk(b,obj)
    --wait_for_ack( a[1], "union_broadcast" )
    obj = _us[a[1].uid].build[obj.idx]
    if obj.state == BUILD_STATE.CREATE then
        build(a[1],obj,1)
    end
    lxz()
    atk(b,obj)
    lxz()
    --wait_for_ack( a[1], "union_broadcast" )
    obj = _us[a[1].uid].build[obj.idx]
    lxz()

    --local hp = obj.hp
    --Rpc:union_build_up(a[1],obj.idx,BUILD_STATE.FIX) 
    --build(a[1],obj,1)
    lxz()

    return "ok"
end

return mod

