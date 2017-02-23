--lxz
--军团建筑科技捐献
local mod = {}

function mod.action(_idx)

    require("frame/debugger")
    local name = tostring(math.floor(gTime % 1000))
    local p = get_one2(name )
    chat(p, "@set_val=gold=100000000")
    Rpc:union_quit(p)
    Rpc:union_create(p, name, name, 40, 1000)
    wait_for_ack(p, "union_on_create")
    
    local num, def = 1000, {}
    for i = 1, num do
        def[i] = get_one2(name .. i)
        Rpc:union_quit( def[i] )
        Rpc:union_apply( def[i],p.uid)
        chat(def[i], "@set_val=gold=100000000")
        chat(def[i], "@additem=7001001=100")
        chat(def[i], "@additem=7001002=100")
        chat(def[i], "@additem=7001003=100")
        
        chat(def[i], "@additem=7002001=100")
        chat(def[i], "@additem=7002002=100")
        chat(def[i], "@additem=7002003=100")
        
        chat(def[i], "@additem=7003001=100")
        chat(def[i], "@additem=7003002=100")
        chat(def[i], "@additem=7003003=100")
        
        chat(def[i], "@additem=7004001=100")
        chat(def[i], "@additem=7004002=100")
        chat(def[i], "@additem=7004003=100")

        Rpc:union_load( def[i],"build" )
        sync(def[i])
        
        local id = 1
        local item = def[i].buildlv.log[id].cons
        local c = resmng.get_conf("prop_union_buildlv",def[i].buildlv.buildlv[id].id + 1 )
        local num = c.BonusID[1][2][2][3]    
        for _,v in pairs(def[i]._item ) do
            if v[2] == item[2] then item[3] =  v[3] - item[3] end
            if v[2] == c.BonusID[1][2][2][2] then  num = v[3] + num  end  
        end
        local silver = def[i].silver + c.BonusID[1][2][1][3] 
        local exp = def[i].buildlv.buildlv[id].exp + c.DonateExp

        Rpc:union_buildlv_donate(def[i],id)
        Rpc:union_load( def[i],"build" )
        sync(def[i])

        for _,v in pairs(def[i]._item ) do
            if v[2] == item[2] then 
                if item[3] ~=  v[3]  then 
                    lxz() 
                    return "fail"  
                end
            end
            if v[2] == c.BonusID[1][2][2][2]  then 
                if num ~= v[3] then 
                    lxz(v,num) 
                    return "fail"  
                end
            end  
        end
        if silver ~= def[i].silver then lxz() return "fail" end  
        if exp < c.UpExp then
            if  exp ~= def[i].buildlv.buildlv[id].exp then lxz(def[i].buildlv.buildlv[id],exp) return "fail" end
        else
            if  exp - c.UpExp  ~= def[i].buildlv.buildlv[id].exp then lxz() return "fail" end
            if  c.ID  ~= def[i].buildlv.buildlv[id].id then lxz() return "fail" end
        end

        id = 2
        item = def[i].buildlv.log[id].cons
        c = resmng.get_conf("prop_union_buildlv",def[i].buildlv.buildlv[id].id + 1 )
        num = c.BonusID[1][2][2][3]    
        for _,v in pairs(def[i]._item ) do
            if v[2] == item[2] then item[3] =  v[3] - item[3] end
            if v[2] == c.BonusID[1][2][2][2] then  
                num = v[3] + num 
            end  
        end
        local silver = def[i].silver + c.BonusID[1][2][1][3] 
        local exp = def[i].buildlv.buildlv[id].exp + c.DonateExp
        Rpc:union_buildlv_donate(def[i],id)
        Rpc:union_load( def[i],"build" )
        sync(def[i])

        for _,v in pairs(def[i]._item ) do
            if v[2] == item[2] then 
                if item[3] ~=  v[3]  then 
                    lxz() 
                    return "fail"  
                end
            end
            if v[2] == c.BonusID[1][2][2][2]  then 
                if num ~= v[3] then 
                    lxz(v,c) 
                    return "fail"  
                end
            end  
        end
        if silver ~= def[i].silver then lxz() return "fail" end  
        if exp < c.UpExp then
            if  exp ~= def[i].buildlv.buildlv[id].exp then lxz(def[i].buildlv.buildlv[id],exp) return "fail" end
        else
            if  exp - c.UpExp  ~= def[i].buildlv.buildlv[id].exp then lxz() return "fail" end
            if  c.ID  ~= def[i].buildlv.buildlv[id].id then lxz() return "fail" end
        end

        id = 3
        item = def[i].buildlv.log[id].cons
        c = resmng.get_conf("prop_union_buildlv",def[i].buildlv.buildlv[id].id + 1 )
        num = c.BonusID[1][2][2][3]    
        for _,v in pairs(def[i]._item ) do
            if v[2] == item[2] then item[3] =  v[3] - item[3] end
            if v[2] == c.BonusID[1][2][2][2] then  num = v[3] + num  end  
        end
        local silver = def[i].silver + c.BonusID[1][2][1][3] 
        local exp = def[i].buildlv.buildlv[id].exp + c.DonateExp
        Rpc:union_buildlv_donate(def[i],id)
        Rpc:union_load( def[i],"build" )
        sync(def[i])

        for _,v in pairs(def[i]._item ) do
            if v[2] == item[2] then 
                if item[3] ~=  v[3]  then 
                    lxz() 
                    return "fail"  
                end
            end
            if v[2] == c.BonusID[1][2][2][2]  then 
                if num ~= v[3] then 
                    lxz(v,c) 
                    return "fail"  
                end
            end  
        end
        if silver ~= def[i].silver then lxz() return "fail" end  
        if exp < c.UpExp then
            if  exp ~= def[i].buildlv.buildlv[id].exp then lxz(def[i].buildlv.buildlv[id],exp) return "fail" end
        else
            if  exp - c.UpExp  ~= def[i].buildlv.buildlv[id].exp then lxz() return "fail" end
            if  c.ID  ~= def[i].buildlv.buildlv[id].id then lxz() return "fail" end
        end

        Rpc:union_quit( def[i] )
    end

    return "ok"
end

return mod
