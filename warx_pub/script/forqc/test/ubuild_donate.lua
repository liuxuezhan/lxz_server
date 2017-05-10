--lxz
--军团科技捐献
local mod = {}

function mod.action(_idx)
    require("union_tech_t")
    require("frame/debugger")
    local name = math.floor(gTime % 1000)

    local p = get_account( 1024 )
    Rpc:union_quit(p)

    loadData(p)
    chat(p, "@set_val=gold=100000000")
    chat(p, "@addres=1=10000000")
    chat(p, "@addres=2=10000000")
    chat(p, "@addres=3=10000000")
    chat(p, "@addres=4=10000000")
    chat(p, "@buildtop")
    chat(p, "@addbuf=1=-1")
    sync(p)
    Rpc:union_create(p, tostring(p.pid), tostring(name), 40, 1000)
    wait_for_ack(p, "union_on_create")
    local id =1001
    local info = {}
    while true do
        Rpc:union_tech_info(p, id)
        sync(p)
        local cur = p.union_tech_info
        local res = p.res
        local gold = p.gold
        table.insert(info,cur)
        local sn = 1
        local reward = {} 
        local res_val =  {} 

        Rpc:union_load(p,"donate")
        Rpc:union_load(p,"union_donate")
        sync(p)
        local donate = p.donate
        local union_donate = p.union_donate
        if donate.tmOver < get_tm(p) then donate.tmOver = get_tm(p) end

        for  i =3,1,-1 do
            if cur.donate[i]~= 0 then 
                sn = i
                Rpc:union_donate(p, id, i)
                sync(p)
                break
            end
        end

        local new = p.union_tech_info
        table.insert(info,new)
        local c = resmng.get_conf("prop_union_donate",union_tech_t.get_class(id))

        --资源检查
        if  sn == 1 then
            res_val =  c.Primary[cur.donate[sn]] 
            reward = c.Pincome 
            if #info > 1 then 
                local i = #info
                for  j = 1,3 do
                    if info[i-1].donate[j] ~= 0 and  info[i].donate[j] == 0 then  
                        lxz(info)
                        return "fail"
                    end
                end
            end
        elseif  sn == 2 then
            res_val =  c.Medium 
            reward = c.Mincome 
        elseif  sn == 3 then
            res_val =  c.Senior 
            reward = c.Sincome 
        end
        Rpc:union_load(p,"donate")
        Rpc:union_load(p,"union_donate")
        sync(p)

        if res_val[1] < 5 then
            if p.res[res_val[1]][1]  + res_val[2] >  res[res_val[1]][1] or  p.res[res_val[1]][1]  + res_val[2] <  res[res_val[1]][1]  - 200  then 
                lxz(p.res,res_val,res) 
                return "fail" 
            end
        elseif res_val == 6 then
            if p.gold  + res_val[2] ~= gold then lxz() return "fail" end
            gold = p.gold
        end

        if  union_donate  + reward[1] * 1.4 ~= p.union_donate then 
            lxz()
            return "fail"
        end

        if  cur.exp  + reward[3] ~= new.exp  then 
            lxz()
            return "fail"
        end

        if  donate.donate  + reward[1] ~= p.donate.donate then 
            lxz()
            return "fail"
        end

        if  donate.tmOver ~= 0 and ( donate.tmOver  + c.TmAdd <  p.donate.tmOver - 10 or donate.tmOver  + c.TmAdd >  p.donate.tmOver )  then 
            lxz(donate)
            lxz(p.donate)
            return "fail"
        end

        if p.donate.flag == 1 then 
            local g =  0
            gold = p.gold
            if p.donate.CD_num < #resmng.CLEAR_DONATE_COST then
                g = resmng.CLEAR_DONATE_COST[p.donate.CD_num +1]
            else g = resmng.CLEAR_DONATE_COST[#resmng.CLEAR_DONATE_COST] end
            Rpc:union_donate_clear(p) 
            sync(p)
            if p.gold  + g ~= gold then lxz(p.gold ,g ,gold) return "fail" end
        end 

        if union_tech_t.is_exp_full(new ) then
            Rpc:union_tech_upgrade(p,id)
            break
        end
    end
    lxz(name)

    return "ok"
end

return mod
