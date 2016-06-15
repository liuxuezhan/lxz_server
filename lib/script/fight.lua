module("fight", package.seeall)
--clean in crontab, every minute
gFightReports = gFightReports or {}

function init_arg_match()
    local t = {}
    for amode = 1, 4, 1 do
        local tt = {}
        t[amode] = tt
        for dmode = 1, 4, 1 do
            local ttt = {
                [1] = {"Atk_R", string.format("Atk%d_R", amode), string.format("AAtk%d_R",dmode), "Imp_R", string.format("Imp%d_R", amode), string.format("AImp%d_R", dmode)},
                [2] = {"Imm_R", string.format("Imm%d_R", dmode), string.format("DImm%d_R",amode)}
            }
            tt[ dmode] = ttt
        end
    end
    gArgMatch = t
end

init_arg_match()


local function _calc_atk(A, As, D, Ds)
    local amode = A.mode
    local dmode = D.mode

    A.hit = dmode

    local node = gArgMatch[ amode ][ dmode ]

    local atkR = 0
    for _, v in pairs(node[1]) do atkR = atkR + (A.ef[ v ] or 0) end

    atkR = (1 + atkR * 0.0001)

    local mul = 1 + atkR * 0.0001
    local total = 0
    for _, a in pairs(A.objs) do
        if a.num > 0 then
            total = total + a.prop.Atk *a.num * mul
        end
    end
    return total
end


local function _apply_dmg(D, amode, total)
    local dmode = D.mode
    local node = gArgMatch[ amode ][ dmode ]

    local immR = 0
    for _, v in pairs(node[2]) do immR = immR + (D.ef[ v ] or 0) end
    immR = (1 + immR * 0.0001)

    local dmgAll = 0
    for _, d in pairs(D.objs) do
        if d.num > 0 then
            -- ############################ --
            local dmg = total * d.pow / D.pow
            dmg = dmg * (1-d.prop.Imm * immR)
            -- ############################ --
            --print(string.format("amode=%d, dmode=%d, dmg=%f", amode, dmode, dmg))

            if dmg < 0 then dmg = 0 end

            local most = d.hpAll
            if dmg > most then dmg = most end

            d.dmg = (d.dmg or 0) + dmg
            dmgAll = dmgAll + 0
        end
    end
    return dmgAll
end

local function _attack(A, As, D, Ds, mode, rate)
    rate = rate or 1

    local amode = A.mode
    local dmode = D.mode

    A.hit = dmode

    local node = gArgMatch[ amode ][ dmode ]

    local atkR = 0
    local immR = 0

    for _, v in pairs(node[1]) do atkR = atkR + (A.ef[ v ] or 0) end
    for _, v in pairs(node[2]) do immR = immR + (D.ef[ v ] or 0) end

    atkR = (1 + atkR * 0.0001)
    immR = (1 + immR * 0.0001)

    local atkImm0 = 0
    local atkImmN = 0

    if mode == 0 then
        local k = "AtkImmCom"
        atkImm0 = D.ef[k] or 0
        k = string.format("AtkImmCom%d", amode)
        atkImmN = D.ef[k] or 0
    elseif mode ==  1 then
        local k = "AtkImmTac"
        atkImm0 = D.ef[k] or 0
        k = string.format("AtkImmTac%d", amode)
        atkImmN = D.ef[k] or 0
    end

    for _, a in pairs(A.objs) do
        if a.num > 0 then

            local atk = a.prop.Atk * atkR * a.num * rate
            atk = atk * (1 - atkImm0 * 0.0001) * (1 - atkImmN * 0.0001)

            for _, d in pairs(D.objs) do
                if d.num > 0 then
                    -- ############################ --
                    local dmg = atk * d.pow / D.pow
                    dmg = dmg * (1-d.prop.Imm * immR)
                    -- ############################ --

                    if a.hero or d.hero or Ds.monster then
                        -- nothing
                    else
                        dmg = dmg * math.pow(1.2, a.prop.Lv - d.prop.Lv)
                    end

                    if dmg < 0 then dmg = 0 end

                    --local most = d.hpAll - d.dmg
                    local most = d.hpAll
                    if dmg > most then dmg = most end

                    if mode == 0 then a.mkdmg0 = (a.mkdmg0 or 0) + dmg
                    elseif mode == 1 then a.mkdmg1 = (a.mkdmg1 or 0) + dmg end

                    a.mkdmg = (a.mkdmg or 0) + dmg

                    d.dmg = (d.dmg or 0) + dmg
                    --print(string.format("amode=%d, dmode=%d, dmg=%f", amode, dmode, dmg))
                    --LOG("_attack %d:%4.2f -> %d:%4.2f, dmg=%6.2f", a.id, a.num, d.id, d.num, dmg)
                end
            end
        end
    end
end


function _calc(As)
    local res = {0,0,0,0}
    local heros = {0,0,0,0}
    local total = 0
    for mode = 1, 4, 1 do
        local lives = 0
        local A = As.arms[mode]
        if A and A.num > 0 then
            -- xixue
            local dmgToHp0 = A.ef.DmgToHp0 or 0
            local dmgToHp1 = A.ef.DmgToHp1 or 0

            local hpR = A.ef.HpR or 0
            for _, v in pairs(A.objs) do
                if v.num > 0 then
                    v.dmg = v.dmg or 0

                    local tohp = 0
                    if dmgToHp0 > 0 then tohp = tohp + (v.mkdmg0 or 0) * dmgToHp0 * 0.0001 end
                    if dmgToHp1 > 0 then tohp = tohp + (v.mkdmg1 or 0) * dmgToHp1 * 0.0001 end
                    v.dmg = v.dmg - tohp
                    if v.dmg < 0 then v.dmg = 0 end

                    -- ############################ --
                    local dead = v.dmg / (v.prop.Hp * (1 + hpR * 0.0001))
                    v.num = v.num - dead
                    if v.num < 0 then v.num = 0 end
                    -- ############################ --

                    v.dmg = 0
                    v.mkdmg0 = 0
                    v.mkdmg1 = 0
                end

                if v.hero and v.lead then heros[ mode ] = v.num end

                lives = lives + v.num
            end
            A.num = lives
            total = total + lives
        end
        res[mode] = math.ceil(lives)
    end
    return res, math.ceil(total), heros
end


local function _apply_dmg_buf(D, A)
    for mode, arm in pairs(D.arms) do
        if arm.num > 0 and arm.bufdmg then
            for k, v in pairs(arm.bufdmg) do
                --v = {count, total, amode, anode}
                if v[1] > 0 then
                    v[1] = v[1] - 1
                    local total = v[2]
                    local amode = v[3]
                    local anode = v[4]
                    local dmg = _apply_dmg(arm, amode, total)
                    anode.mkdmg = (anode.mkdmg or 0) + dmg
                end
            end
        end
    end
end


local function _apply_dmg_tower(D, A)
end

local _fight_seqs = {
        [1] = {3,1,4,2},
        [2] = {1,2,4,3},
        [3] = {2,3,4,1},
        [4] = {4,1,2,3},
    }

-- A, D = arms
-- first,buf dmg
-- next, tower dmg
-- last, force dmg
-- todo, about atk sequence
local function _round(A, D)
    for amode, a in pairs(A.arms) do
        local double = a.ef.AtkDouble or 0
        if a.num > 0 then
            if a.mode == 4 then
                local rate = {0.05, 0.05, 0.05, 1}
                local sum = 0
                for dmode, d in pairs(D.arms) do
                    if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
                end

                for dmode, d in pairs(D.arms) do
                    if d.num > 0 then
                        local r = d.pow * rate[dmode] / sum
                        _attack(a, A, d, D, 0, r)
                        if double > 0 then _attack(a, A, d, D, 0, r * double) end
                    end
                end
            else
                local seq = _fight_seqs[ a.mode ]
                for _, dmode in ipairs(seq) do
                    local d = D.arms[ dmode ]
                    if d and d.num > 0 then
                        _attack(a, A, d, D, 0, 1)
                        if double > 0 then _attack(a, A, d, D, 1 * double) end
                        break
                    end
                end
            end
        end
    end
end


local function _tactics(As, Ds, round, report, who)
    local flag = false
    for amode, A in pairs(As.arms) do
        if A.num > 0 and amode ~= 4 then
            if not A.tacTm then A.tacTm = 0 end
            local cd =  10 * (1 - (A.ef.TacticsCD or 0) * 0.0001)
            if round - A.tacTm >= cd then
                A.tacTm = round
                if (not A.ef.TacticsBlock) or (A.ef.TacticsBlock == 0) then
                    if _fight_seqs[ amode ][1] == A.hit or (A.ef.TacticdAll or 0) > 0 then

                        local D = Ds.arms[ A.hit ]
                        local k = string.format("TacticsAtk%d", amode)
                        local extra = (A.ef.TacticsAtk or 0) + (A.ef[ k ] or 0)

                        _attack(A, As, D, Ds, 1, 2 * (1 + extra * 0.0001))
                        flag = true
                        table.insert(report, {round, 4, who, A.mode, "tactics"})

                        local more = A.ef.TacticsMore or 0
                        if more > 0 then
                            for _, D in pairs(Ds.arms) do
                                if D.num > 0 and D.mode ~= A.hit then
                                    _attack(A, As, D, Ds, 1, 2 * more * (1 + extra * 0.0001))
                                end
                            end
                        end
                        --todo, trig other
                    end
                end
            end
        end
    end
    return flag
end


function _get_num(A)
    local res = {0,0,0,0}
    for mode = 1,4,1 do
        local arm = A.arms[ mode ]
        if arm then res[mode] = math.ceil(arm.num) end
    end
    return res
end

local function _all_dead(T)
    for _, v in pairs(T.arms) do
        if v.num > 0 then return false end
    end
    return true
end

vfunc_cond = {}
vfunc_cond["AND"] = function (A, As, Ds, ...)  -- A obj, D obj, A arms, D arms
    for _, v in pairs({...}) do
        if not do_cond(A, As, Ds, unpack(v)) then return false end
    end
    return true
end

vfunc_cond["OR"] = function (A, As, Ds, ...)  -- A obj, D obj, A arms, D arms
    for _, v in pairs({...}) do
        if do_cond(A, As, Ds, unpack(v)) then return true end
    end
end

-- A, self,
-- A attck D, B attack A
vfunc_cond["AMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    return A and A.mode == mode
end

vfunc_cond["DMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    for _, v in pairs(A.as) do
        if v == mode then return true end
    end
end

vfunc_cond["BMODE"] = function (A, As, Ds, mode)
    if not A then return false end
    for _, v in pairs(A.ds) do
        if v == mode then return true end
    end
end


vfunc_cond["RATE"] = function (A, As, Ds, rate)
    return math.random(1,10000) < rate
end

function do_cond(A, As, Ds, Func, ...)
    if vfunc_cond[ Func ] then
       return vfunc_cond[ Func ](A, As, Ds, ...)
   else
       WARN("fight, do_cond, Func = %s", Func)
       return false
   end
end

function buff_check(buf, A, As, Ds)
    local cond = buf.cond
    if cond and #cond > 0 then
        return do_cond(A, As, Ds, unpack(cond))
    else
        return true
    end
end

function skill_check(skill, A, As, Ds)
    local cond = skill.cond
    if cond and #cond > 0 then
        return do_cond(A, As, Ds, unpack(cond))
    else
        return true
    end
end

--function do_add_buf(tab, buf, count)
--    --todo, buf mutex
--    --INFO("BUF add, id=%d, count=%d", buf.ID, count)
--    table.insert(tab, {buf,count})
--end


-- A attack D; B attack A

vfunc_skill = {}
--vfunc_skill[ "AddBuf" ] = function (Target, hero, A, As, Ds, bufid, count)
--    local buf = resmng.prop_buff[ bufid ]
--    if buf then
--        if Target == "A" then
--            do_add_buf(A.buf, buf, count)
--
--        elseif Target == "AS" then
--            for _, v in pairs(As.arms) do
--                do_add_buf(v.buf, buf, count)
--            end
--
--        elseif Target == "D" then
--            for k, v in pairs(A.as) do
--                local D = Ds.arms[ v ]
--                if D then
--                    do_add_buf(D.buf, buf, count)
--                end
--            end
--
--        elseif Target == "DS" then
--            for _, v in pairs(Ds.arms) do
--                do_add_buf(v.buf, buf, count)
--            end
--
--        elseif Target == "B" then
--            for k, v in pairs(A.ds) do
--                local D = Ds.arms[ v ]
--                if D then
--                    do_add_buf(D.buf, buf, count)
--                end
--            end
--        elseif Target == "BS" then
--            for _, v in pairs(Ds.arms) do
--                do_add_buf(v.buf, buf, count)
--            end
--        end
--    end
--end

vfunc_skill[ "DmgBuf" ] = function (Target, hero, A, As, Ds, ratio, count)
    if A.mode == 4 then
        local rate = {0.05, 0.05, 0.05, 1}
        local sum = 0
        for dmode, d in pairs(D.arms) do
            if d.num > 0 then sum = sum + d.pow * rate[ dmode ] end
        end

        for dmode, D in pairs(Ds.arms) do
            if d.num > 0 then
                local r = d.pow * rate[dmode] / sum
                local dmg = _calc_atk(A, As, D, Ds) 
                dmg = dmg * ratio * r
                if not D.bufdmg then D.bufdmg = {} end
                table.insert(D.bufdmg, {count, dmg, A.mode, hero})
            end
        end
    else
        for k, v in pairs(A.as) do
            local D = Ds.arms[ v ]
            if D then
                local dmg = _calc_atk(A, As, D, Ds) 
                dmg = dmg * ratio
                if not D.bufdmg then D.bufdmg = {} end
                table.insert(D.bufdmg, {count, dmg, A.mode, hero})
            end
        end
    end
end


function do_skill_fire(Target, hero, A, As, Ds, Func, ...)
    if vfunc_skill[ Func ] then
        vfunc_skill[ Func ](Target, hero, A, As, Ds, ...)
    end
end

function skill_fire(skill, hero, A, As, Ds)
    local effect = skill.Effect
    if effect then
        for _, e in pairs(effect) do
            do_skill_fire(skill.Target or "A", hero, A, As, Ds, unpack(e))
        end
    end
end

local function _launch_skills(As, Ds, round, report, who)
    for _, A in pairs(As.arms) do
        for _, obj in pairs(A.objs) do
            if obj.hero and obj.lead and obj.num > 0 then
                for _, v in pairs(obj.skills) do
                    local skill = resmng.prop_skill[v]
                    if skill and skill_check(skill, A, As, Ds) then
                        skill_fire(skill, obj, A, As, Ds)
                        table.insert(report, {round, 3, who, A.mode, obj.id, skill.ID, "skills"})
                    end
                end
            end
        end
    end
end

local function _launch_skill(As, Ds, round, report, who)
    for _, A in pairs(As.arms) do
        for _, obj in pairs(A.objs) do
            if obj.hero and obj.lead and obj.num > 0 then
                local skill = resmng.prop_skill[obj.skill]
                if skill and skill_check(skill, A, As, Ds) then
                    skill_fire(skill, obj, A, As, Ds)
                    table.insert(report, {round, 2, who, A.mode, obj.id, skill.ID, "skill"})
                end
            end
        end
    end
end

function do_buf_dec(bs)
    local ns = {}
    local chg = false
    for _, b in pairs(bs) do
        b[2] = b[2] - 1
        if b[2] > 0 then
            table.insert(ns, b)
        else
            chg = true
            --INFO("BUF, del, id=%d", b[1].ID)
        end
    end
    return ns, chg
end

local _mt_eff = { __index = function (tab, key) return 0 end }
function do_buf_recalc(bs, A, As, Ds)
    local es = {}
    for _, v in pairs(bs) do
        local b = v[1]
        if b then
            if buff_check(b, A, As, Ds) then
                for key, val in pairs(b.Effect or {}) do
                    es[ key ] = (es[key] or 0) + val
                end
            end
        end
    end
    return setmetatable(es, _mt_eff)
end

--function refresh_buf(As, Ds)
--    As.buf, chg = do_buf_dec(As.buf or {})
--    As.ef = do_buf_recalc(As.buf or {})
--    for _, A in pairs(As.arms or {}) do
--        A.buf = do_buf_dec(A.buf or {})
--        A.ef = do_buf_recalc(A.buf or {}, A, As, Ds)
--    end
--end


function get_hero(sn)
    local what = type(sn)
    if what == "table" then
        return sn
    elseif what == "string" then
        local idx, pid = string.match(sn, "(%d+)_(%d+)")
        local p = getPlayer(tonumber(pid))
        if p then
            return p:get_hero(tonumber(idx))
        end
    end
end


function _match(As, Ds)
    for _, C in pairs({As, Ds}) do
        for mode, arm in pairs(C.arms) do
            arm.as = {}
            arm.ds = {}
        end
    end

    for amode, A in pairs(As.arms) do
        if A.num > 0 then
            local seq = _fight_seqs[ amode ]
            for _, dmode in pairs(seq) do
                local D = Ds.arms[ dmode ]
                if D and D.num > 0 then
                    table.insert(A.as, dmode)
                    table.insert(D.ds, amode)
                    if amode ~= 4 then break end
                end
            end
        end
    end

    for dmode, D in pairs(Ds.arms) do
        if D.num > 0 then
            local seq = _fight_seqs[ dmode ]
            for _, amode in pairs(seq) do
                local A = As.arms[ amode ]
                if A and  A.num > 0 then
                    table.insert(D.as, amode)
                    table.insert(A.ds, dmode)
                    if dmode ~= 4 then break end
                end
            end
        end
    end
end


fight.pvp = function(action, A0, D0)
    -- Bu,1; Qi,2; Gong,3; Che 4;
    local total = 0

    local A = init_troop(A0)
    local D = init_troop(D0)

    local report = {{0,0,A0.eid, A0.owner_eid, A0.target_eid, A.heroid, D.heroid, D0.sx, D0.sy }}
    table.insert(report, {0, 1, _get_num(A), _get_num(D), A.herohp, D.herohp })
    
    local round = 0
    for i = 1, 30, 1 do
        round = round + 1
        _match(A, D)
        if i == 1 then
            _launch_skills(A, D, i, report, 1)
            _launch_skills(D, A, i, report, 2)
        end

        if (i - 4) % 6 == 0 then
            _launch_skill(A, D, i, report, 1)
            _launch_skill(D, A, i, report, 2)
        end

        refresh_buf(A, D)
        refresh_buf(D, A)

        for _, C in pairs({A, D}) do
            for _, arm in pairs(C.arms) do
                local pow = 0
                local hpR = arm.ef.HpR or 0
                for _, obj in pairs(arm.objs) do
                    if obj.num > 0 then
                        obj.pow = obj.num * obj.prop.Pow
                        pow = pow + obj.pow
                        obj.hpAll = obj.prop.Hp * (1 + hpR * 0.0001) * obj.num
                    end
                end
                arm.pow = pow
            end
        end

        --todo hurt by buf
        --todo hurt by force
        --todo hurt by army

        _apply_dmg_buf(A, D)
        _apply_dmg_buf(D, A)

        _apply_dmg_tower(D, A)

        _round(A, D)
        _round(D, A)

        _tactics(A, D, i, report, 1)
        _tactics(D, A, i, report, 2)

        local ta, la, ha = _calc(A)
        local td, ld, hd = _calc(D)
        table.insert(report, {i, 1, ta, td, ha, hd })

        if la == 0 or ld == 0 then break end
        --if _all_dead(A) or _all_dead(D) then break end
    end

    --dumpTab(report, "fight")

    local losts = {round, -1,}

    -- return lost_pow, live_num, lost num per level
    --local lostA, liveA, deadsA, ndeadA = fight_status(A) 
    --local lostD, liveD, deadsD, ndeadD = fight_status(D)

    local lostA, liveA, make_dmgA, dead_numA, dead_lvlA = fight_status(A) 
    local lostD, liveD, make_dmgD, dead_numD, dead_lvlD = fight_status(D) 

    table.insert(losts, lostA)
    table.insert(losts, lostD)
    table.insert(report, losts)

    calc_kill( A0, make_dmgA, dead_numD, dead_lvlD ) 
    calc_kill( D0, make_dmgD, dead_numA, dead_lvlA )

    dumpTab(A0, "fight_statusA")
    dumpTab(D0, "fight_statusD")

    local win = 0

    if lostA <= lostD then win = 1 else win = 2 end
    if liveD == 0 then win = 1 elseif liveA == 0 then win = 2 end
    table.insert(report, {round, -2, win=win})

    if win==1 then
        A0.win = 1
        D0.win = nil
    else
        A0.win = nil
        D0.win = 1
    end

    -- todo
    --if action == "jungle" then result(action, A0, D0, A, D) end
    result(action, A0, D0, A, D)

    --A = A0
    --D = D0

    ----todo, clean when live long enough

    local pid = 0
    local uid = 0
    local atker = get_ply(A0.owner_eid)
    if atker then
        pid = atker.pid
        uid = atker.uid
    end
    if action == "task" then
        Rpc:battle(atker, A0.eid, A0.owner_eid, A0.target_eid, A0.owner_pid, A0.owner_uid)
    else
        Rpc:around0(A0.target_eid, "battle", A0.eid, A0.owner_eid, A0.target_eid, pid, uid)
    end
    gFightReports[ A0.eid ] = {gTime, report}

    add_union_log(A0,D0) 
    return win == 1
    --return report
end

function result(action, At, Dt, Ainfo, Dinfo)
    if func_result[action] then
        func_result[action](At, Dt, Ainfo, Dinfo)
    else
        --local A = get_ety(At.aid)
        --local D = get_ety(Dt.aid)
        --A:troop_back(At)
        --D:troop_home(Dt)
    end
end


function do_get_troop_statistic(At)
    local totals = {}
    for pid, arm in pairs(At.arms) do
        local node = 0
        if pid > 0 then
            local owner = getPlayer(pid)
            node = {pid, owner.name, owner.propid }
        else
            local owner = get_ety(At.owner_eid)
            if owner then
                node = {0, "", owner.propid}
            else
                node = {0, "", 0}
            end
        end

        local soldiers = {}
        local lives = arm.live_soldier or {}
        local deads = arm.dead_soldier or {}
        local hurts = arm.hurt_soldier or {}

        for id, num in pairs(lives) do
            --local t = {id, num, deads[id] or 0, hurts[id] or 0}
            local t = {id, num, deads[id] or 0, 0}
            table.insert(soldiers, t)
        end
        table.insert(node, soldiers)

        local heros = {}
        for _, hid in pairs(arm.heros) do
            if hid ~= 0 then
                h = heromng.get_hero_by_uniq_id(hid)
                if h then
                    table.insert(heros, {h.propid, h.lv, h.hp/h.max_hp})
                end
            end
        end
        table.insert(node, heros)
        table.insert(totals, node)
    end
    --{
    -- {pid, name, propid, soldiers, heros}
    -- {pid, name, propid, soldiers, heros}
    --}
    return totals
end


function get_troop_buf(At)
    local args = {
        "Atk_R", "Atk1_R", "Atk2_R", "Atk3_R", "Atk4_R",
        "Def_R", "Def1_R", "Def2_R", "Def3_R", "Def4_R",
        "Imm_R", "Imm1_R", "Imm2_R", "Imm3_R", "Imm4_R",
        "Hp_R", "Hp1_R", "Hp2_R", "Hp3_R", "Hp4_R",
        "CountSoldier_A" 
    }
    local buf = {}
    if At.owner_pid and At.owner_pid > 0 then
        local A = getPlayer(At.owner_pid)
        if A then
            local ef = A._ef
            for k, v in pairs(args) do
                if ef[ v ] and ef[ v ] > 0 then buf[ v ] = ef[ v ] end
            end
        end
    end
    return buf
end

--At = {
--    name = "",
--    pid = 10001,
--    owner_pid = 10001,
--    arms = {
--        [pidA] = {
--            pid = pidA,
--            live_soldier = { [1001] = 50, [2001] = 100 },
--            dead_soldier = { [1001] = 30, [2001] = 300 },   -- set by fight
--            hurt_soldier = { [1001] = 20, [3001] = 400 },   -- change from dead_soldier
--            heros = { heroidA, heroidB, heroidC, heroidD }, -- hero = heromng.get_hero_by_id( heroidA )
--            mkdmg = 100001,                                 -- set by fight
--            lost = 10000,                                   -- set by fight
--        },
--        [pidB] = {
--        
--        }
--    }
--}
--


func_result={}
func_result.todo = function(At, Dt, Ainfo, Dinfo)
    local ainfo = do_get_troop_statistic(At)
    local dinfo = do_get_troop_statistic(Dt)
    
    for _, arm in pairs(dinfo) do
        local soldiers = arm[4]
        for _, v in pairs(soldiers) do
            local dead = v[3]
            local hurt = dead
            v[4] = v[3]
            v[3] = 0
        end
    end

    for pid, arm in pairs(Dt.arms) do
        local hurts = arm.hurt_soldier
        if not hurts then 
            hurts = {}
            arm.hurt_soldier = hurts
        end
        local deads = arm.dead_soldier
        if deads then
            for id, num in pairs(deads) do
                hurts[ id ] = (hurts[ id ] or 0) + num
            end
        end
    end

    local abuf = get_troop_buf(At)
    local dbuf = get_troop_buf(Dt)
    local its = {}

    local A = get_ety(At.owner_eid)
    local D = get_ety(Dt.owner_eid)

    if is_ply(A) then
        for pid, _ in pairs(At.arms) do
            local A = getPlayer(pid)
            if A then 
                A:mail_new( {
                    class=MAIL_CLASS.FIGHT, mode=mode,
                    content={x=D.x, y=D.y, A={x=A.x, y=A.y, info=ainfo, buf=abuf}, D={x=D.x, y=D.y, info=dinfo, buf=dbuf}}})
            end
        end
    end

    if is_ply(D) then

        local content = {x=D.x, y=D.y, A={x=A.x, y=A.y, info=ainfo, buf=abuf}, D={x=D.x, y=D.y, info=dinfo, buf=dbuf}}
        local mail = {class=MAIL_CLASS.FIGHT, content=content}

        if tabNum(Dt.arms) > 1 then 
            if Dt.win then mail.mode = MAIL_FIGHT_MODE.DEFEND_MASS_SUCCESS else mail.mode = MAIL_FIGHT_MODE.DEFEND_MASS_FAIL end
        else
            if Dt.win then mail.mode = MAIL_FIGHT_MODE.DEFEND_SUCCESS else mail.mode = MAIL_FIGHT_MODE.DEFEND_FAIL  end
        end

        for pid, _ in pairs(Dt.arms) do
            local D = getPlayer(pid)
            if D then
                D:mail_new(mail)
            end
        end
    end
end

func_result.siege = function(At, Dt)
    local ainfo = do_get_troop_statistic(At)
    local dinfo = do_get_troop_statistic(Dt)
    
    for _, arm in pairs(dinfo) do
        local soldiers = arm[4]
        for _, v in pairs(soldiers) do
            local dead = v[3]
            local hurt = dead
            v[4] = v[3]
            v[3] = 0
        end
    end

    for pid, arm in pairs(Dt.arms) do
        local hurts = arm.hurt_soldier
        if not hurts then 
            hurts = {}
            arm.hurt_soldier = hurts
        end
        local deads = arm.dead_soldier
        if deads then
            for id, num in pairs(deads) do
                hurts[ id ] = (hurts[ id ] or 0) + num
            end
        end
    end

    local abuf = get_troop_buf(At)
    local dbuf = get_troop_buf(Dt)
    local its = {}

    local A = get_ety(At.owner_eid)
    local D = get_ety(Dt.owner_eid)
   
    local rages = {}
    local capture = {}
    if At.win then
        rages = rage(At, D)
        At.rages = rages

        -- capture hero
        local heroA, heroD = hero_capture(At, Dt)
        if heroA and heroD then
            if heroD.status == HERO_STATUS_TYPE.BUILDING then D:hero_offduty(heroD) end
            WARN("Capture Hero, %s -> %s", heroA._id, heroD._id)
            heromng.capture(heroA._id, heroD._id)
            table.insert(capture, {heroA.pid, heroA.propid})
            table.insert(capture, {heroD.pid, heroD.propid})
        end

        if not is_npc_city(D) then
            if D:release_all_prisoner() then
                union_task.ok( A, D, UNION_TASK.HERO)
            end
        end
    end

    local mode = 0
    if tabNum(At.arms) > 1 then 
        if At.win then mode = MAIL_FIGHT_MODE.MASS_SUCCESS else mode = MAIL_FIGHT_MODE.MASS_FAIL end
    else
        if At.win then mode = MAIL_FIGHT_MODE.ATTACK_SUCCESS else mode = MAIL_FIGHT_MODE.ATTACK_FAIL end
    end

    for pid, _ in pairs(At.arms) do
        local A = getPlayer(pid)
        if A then 
            A:mail_new( {
                class=MAIL_CLASS.FIGHT, mode=mode,
                content={x=D.x, y=D.y, A={x=A.x, y=A.y, info=ainfo, buf=abuf}, D={x=D.x, y=D.y, info=dinfo, buf=dbuf}, carry=rages[pid] or {}, capture=capture } 
            })
        end
    end

    local content = {x=D.x, y=D.y, A={x=A.x, y=A.y, info=ainfo, buf=abuf}, D={x=D.x, y=D.y, info=dinfo, buf=dbuf}, carry=its, capture=capture}
    local mail = {class=MAIL_CLASS.FIGHT, content=content}

    if tabNum(Dt.arms) > 1 then 
        if Dt.win then mail.mode = MAIL_FIGHT_MODE.DEFEND_MASS_SUCCESS else mail.mode = MAIL_FIGHT_MODE.DEFEND_MASS_FAIL end
    else
        if Dt.win then mail.mode = MAIL_FIGHT_MODE.DEFEND_SUCCESS else mail.mode = MAIL_FIGHT_MODE.DEFEND_FAIL  end
    end

    for pid, _ in pairs(Dt.arms) do
        local D = getPlayer(pid)
        if D then
            D:mail_new(mail)
        end
    end

    add_union_log(At,Dt) 
end

function add_union_log(At, Dt)
    local A = get_ety(At.owner_eid) or {}
    local D = get_ety(Dt.owner_eid) or {}

    local Au = unionmng.get_union(At.owner_uid) or {}
    local Au_name  
    if Au then
        Au_name = Au.alias
    end
     
    local Du = unionmng.get_union(Dt.owner_uid) or {}
    local Du_name  
    if Du then
        Du_name = Du.alias
    end

    local log = {
        action = At.is_mass or 0,
        A = {
            pid = A.pid,
            name = A.name,
            alias= Au_name,
            win = At.win,
            x = At.sx,
            y = At.sy,
        },
        D = {
            pid = D.pid,
            name = D.name,
            alias= Du_name,
            win = Dt.win,
            x = At.dx,
            y = At.dy,
        }
    }
    if next(Au) then Au:add_log(resmng.EVENT_TYPE.FIGHT, log) end
    if next(Du) then Du:add_log(resmng.EVENT_TYPE.FIGHT, log) end
end

function hero_capture(At, Dt)
    print("hero_capture")
    local pidA = At.owner_pid
    if not pidA then return end
    if pidA == 0 then return end
    local armA = At.arms[ pidA ]
    if not armA then return end

    local pidD = Dt.owner_pid
    if not pidD then return end
    if pidD == 0 then return end
    local armD = Dt.arms[ pidD ]
    if not armD then return end

    local counter = 0
    local hsDeadD = {}
    local hsLiveD = {}
    for _, hero in pairs(armD.heros or {}) do
        if hero ~= 0 then
            local h = heromng.get_hero_by_uniq_id(hero)
            if h then
                if h.hp <= 0 then table.insert(hsDeadD, h) else table.insert(hsLiveD, h) end 
                for _, skillid in pairs(h.basic_skill) do
                    if skillid[1] ~= 0 then
                    local skill = resmng.get_conf("prop_skill", skillid[1])
                        if skill and skill.Type == SKILL_TYPE.FIGHT then
                            for _, e in pairs(skill.Effect) do
                                if e[1] == "AddBuf" and e[3] == 0 then
                                    local buf = resmng.get_conf("prop_buff", e[2])
                                    if buf then
                                        counter = counter + (buf.Value[ "CounterCaptive" ] or 0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #hsDeadD < 1 and #hsLiveD < 1 then return end
    local plD = getPlayer(pidD)
    counter = counter + plD:get_num("CounterCaptive")

    local captive = 0
    local hsDeadA = {}
    local hsLiveA = {}
    for _, hero in pairs(armA.heros or {}) do
        if hero ~= 0 then
            local h = heromng.get_hero_by_uniq_id(hero)
            if h then
                if h.hp <= 0 then table.insert(hsDeadA, h) else table.insert(hsLiveA, h) end 
                for _, skillid in pairs(h.basic_skill) do
                    if skillid[1] ~= 0 then
                        local skill = resmng.get_conf("prop_skill", skillid[1])
                        if skill and skill.Type == SKILL_TYPE.FIGHT then
                            for _, e in pairs(skill.Effect) do
                                if e[1] == "AddBuf" and e[3] == 0 then
                                    local buf = resmng.get_conf("prop_buff", e[2])
                                    if buf then
                                        captive = captive + (buf.Value[ "Captive" ] or 0)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #hsDeadA < 1 and #hsLiveA < 1 then return end
    local plA = getPlayer(pidA)
    captive = captive + plA:get_num("Captive")

    if captive <= counter then return end
    if math.random(1,10000) <= captive - counter then 
        local heroD = false
        if #hsDeadD > 0 then heroD = hsDeadD[ math.random(1, #hsDeadD) ]
        else heroD = hsLiveD[ math.random(1, #hsLiveD) ] end

        local heroA = false
        if #hsLiveA > 0 then heroA = hsLiveA[ math.random(1, #hsLiveA) ]
        else heroA = hsDeadA[ math.random(1, #hsDeadA) ] end

        return heroA, heroD
    end
end

function get_tot_dmg(Dt)
    local dmg = 0
    for k, v in pairs(Dt.arms) do
        dmg = dmg + v.mkdmg
    end
    return dmg
end

function make_reward_num(key, rewards, factor, pid, monster)
    
    local newFactor = 1
    if key == "base" then
        local ply = getPlayer(pid)
        local prop = resmng.prop_world_unit[monster.propid]
        if ply and prop then
            newFactor = math.max(0.1, math.min(1, (ply.lv - prop.Lv)/prop.Attenuation))
        end
        
    end
    for k, v in pairs(rewards) do
        v[3] =  math.floor( v[3] * factor * newFactor)
    end
end

function get_jungle_reward(At, Arm, Dt, pid)
    local rewards = {}
    local monster = get_ety(Dt.owner_eid)
    local totalDmg = get_tot_dmg(At)
    for k, v in pairs(monster.rewards) do
        if k== "fix" then  -- fix award
            rewards[ k ] = v
        elseif k == "base" or k == "extra" then  -- base  extra award
            make_reward_num(k, v, Arm.mkdmg / totalDmg, pid, monster )
            if totalDmg == 0 then
                rewards[ k ] = v
            else
                rewards[ k ] = v
            end
        elseif k == "final" and monster.hp <= 0 then
            rewards[k] = {}
            for key, award in pairs(v) do
                table.insert(rewards[ k ], award[1])
            end
        elseif k == "unit" and monster.hp <= 0 then
            local ply = getPlayer(pid)
            if ply then
                local union = unionmng.get_union(ply.uid)
                if union then
                    for _, meb  in pairs(union._members ) do
                        union_item.add(meb, v[1][2], UNION_ITEM.BOSS, monster.propid, pid)
                    end
                end
            end
            -- final award to do
        end
    end
    return rewards
end

function cal_monster_hp(At, Dt)
    local monster = get_ety(At.target_eid)
    local cur = 0
    local max = 0

    for _, arm in pairs(Dt.arms) do

        local live = arm.live_soldier or {}
        local dead = arm.dead_soldier or {}

        for id, num in pairs(live) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                cur = cur + conf.Pow * num
                max = max + conf.Pow * (num + (dead[ id ] or 0)) 
            end
        end
    end

    local lost = (max-cur) * 100 / max
    monster.hp = monster.hp - lost
    monster.hp = math.floor(monster.hp)
    print("siege monster, hp = ", monster.hp, max, cur) 

end

func_result.jungle = function(At, Dt)
    local ainfo = do_get_troop_statistic(At)
    local dinfo = do_get_troop_statistic(Dt)

    for _, arm in pairs(ainfo) do
        local soldiers = arm[4]
        for _, v in pairs(soldiers) do
            local dead = v[3]
            local relive = math.floor(dead * 0.95)
            local hurt = dead - relive
            v[2] = v[2] + relive        -- live
            v[3] = 0                    -- dead
            v[4] = hurt                 -- hurt
        end
    end


    local D = get_ety(Dt.owner_eid)

    cal_monster_hp(At, Dt)
    for pid, arm in pairs(At.arms) do
        local A = getPlayer(pid)
        monster.try_update_top_hurter_by_propid(D.propid, A.pid, arm.mkdmg, A.name)
        local its = get_jungle_reward(At, arm, Dt, pid)
        local content = {propid=D.propid, x=D.x, y=D.y, A={x=At.sx, y=At.sy, info=ainfo}, D={x=At.dx, y=At.dy, info=dinfo}, carry=its, hp=D.hp}
        local mail = {class=MAIL_CLASS.REPORT, mode=MAIL_REPORT_MODE.JUNGLE, content=content}
        if A then
            A:mail_new(mail)
            if its ~= 0 then
                for _, v in pairs(its) do
                    for key, item in pairs(v) do
                        if item[1] == "hero_exp" then
                            local count = item[3]
                            for _, hid in pairs(arm.heros) do
                                if hid ~= 0 then
                                    h = heromng.get_hero_by_uniq_id(hid)
                                    if h then
                                        h:gain_exp(count)
                                    end
                                end
                            end
                        elseif item[1] == "exp" then
                            A:add_exp(item[3] or 0)

                        elseif item[1] == "item" then
                            A:inc_item(item[2], item[3], VALUE_CHANGE_REASON.JUNGLE)
                        else
                            Mark("can not give reward, monster=%d", D.propid)
                            dumpTab(its, "monster_reward")
                        end
                    end
                end
            end
        end
    end
end

func_result.grab = function(At, Dt)
end

function clean_report()
    local dels = {}
    for k, v in pairs(gFightReports) do
        if gTime - v[1] > 60 then
            table.insert(dels, k)
        end
    end
    for _, v in pairs(dels) do
        gFightReports[ v ] = nil
    end
end



-- new_buf_arangement
-- new_buf_arangement
-- new_buf_arangement
function effect_attach(dst, src) -- attach src to dst
    for k, v in pairs(src or {}) do
        dst[ k ] = (dst[ k ] or 0) + v
    end
end

function effect_detach(src, dst) -- detach dst from src
    for k, v in pairs(dst or {}) do
        src[ k ] = (src[ k ] or 0) - v
    end
end

-- buf = {bufid, count, effect}
function do_add_buf(arm, prop, count)
    table.insert(arm.buf, {prop.ID, count, prop.Value})
    effect_attach(arm.ef, prop.Value)
end

function refresh_buf(T)
    for _, arm in pairs(T.arms) do
        local dels = {}
        for k, v in ipairs(arm.buf) do
            v[2] = v[2] - 1
            if v[2] < 0 then
                effect_detach(arm.ef, v[3])
                table.insert(dels, 1, k)
            end
        end
        for _, idx in ipairs(dels) do
            table.remove(arm.buf, idx)
        end
    end
end

vfunc_skill[ "AddBuf" ] = function (Target, hero, A, As, Ds, bufid, count)
    local buf = resmng.prop_buff[ bufid ]
    if buf then
        if Target == "A" then
            do_add_buf(A, buf, count)

        elseif Target == "AS" then
            for _, v in pairs(As.arms) do
                do_add_buf(v, buf, count)
            end

        elseif Target == "D" then
            for k, v in pairs(A.as) do
                local D = Ds.arms[ v ]
                if D then
                    do_add_buf(D, buf, count)
                end
            end

        elseif Target == "DS" then
            for _, v in pairs(Ds.arms) do
                do_add_buf(v, buf, count)
            end

        elseif Target == "B" then
            for k, v in pairs(A.ds) do
                local D = Ds.arms[ v ]
                if D then
                    do_add_buf(D, buf, count)
                end
            end
        elseif Target == "BS" then
            for _, v in pairs(Ds.arms) do
                do_add_buf(v, buf, count)
            end
        end
    end
end

-- clean : T.win, T.arms.dead_soldier, mkdmg, lost
function init_troop(T)
    local ef = {}
    if T.owner_pid > 0 then
        local p = getPlayer(T.owner_pid)
        if p then
            for _, amode in pairs(gArgMatch) do
                for _, dmode in pairs(amode) do
                    for _, part in pairs(dmode) do
                        for _, k in pairs(part) do
                            local v = p:get_num(k)
                            if v ~= 0 then
                                ef[ k ] = v
                            end
                        end
                    end
                end
            end
        end
    end

    local t = {
        num=0, 
        arms={
            {mode=1, num=0, objs={}, ef=copyTab(ef), buf={}},
            {mode=2, num=0, objs={}, ef=copyTab(ef), buf={}},
            {mode=3, num=0, objs={}, ef=copyTab(ef), buf={}},
            {mode=4, num=0, objs={}, ef=copyTab(ef), buf={}},
        },
        heroid = {0,0,0,0},
        herohp = {0,0,0,0}
    }

    if not is_ply(T.owner_eid) then t.monster = true end

    T.win = nil
    for pid, arm in pairs(T.arms) do
        arm.dead_soldier = nil
        arm.mkdmg = nil
        arm.lost = nil

        local kill = {0,0,0,0}
        for id, num in pairs(arm.live_soldier) do
            local prop = resmng.prop_arm[ id ]
            if prop then
                local pow = num * prop.Pow
                kill[ id ] = 0
                local mode = prop.Mode
                table.insert(t.arms[ mode ].objs, { id=id, num=num, num0=num, prop=prop, link=arm, kill=kill })
                t.arms[ mode ].num = t.arms[ mode ].num + num
                t.num = t.num + num
            end
        end

        for mode, hero in pairs(arm.heros or {}) do
            if hero ~= 0 then
                local h = heromng.get_fight_attr(hero)
                if h then
                    kill[ mode ] = 0
                    local ht = {id=h.id, num=h.num, num0=h.num, prop=h.prop, link=arm, kill=kill, hero=h.hero, skill=h.skill, skills=h.skills}
                    if pid == T.owner_pid then ht.lead = 1 end
                    table.insert(t.arms[ mode ].objs, ht)
                    if pid == T.owner_pid then
                        local pow = h.num * h.prop.Pow
                        t.heroid[ mode ] = h.id
                        t.herohp[ mode ] = h.num
                    end
                end
            end
        end
        arm.kill_soldier = kill
    end
    return t
end


-- return lost_pow, live_num, make_dmg, dead_num, dead_lvl
function fight_status(T)
    local live_num = 0
    local lost_pow = 0
    local make_dmg = 0
    local dead_lvl = {}
    local dead_num = 0

    for mode, arm in pairs(T.arms) do
        for _, obj in pairs(arm.objs) do
            local node = obj.link
            local kill = obj.kill

            local dead = 0
            if obj.hero then
                kill[ mode ] = (obj.mkdmg or 0)
                dead = obj.num0 - obj.num
                if not T.monster then
                    local h = heromng.get_hero_by_uniq_id(obj.hero)
                    if h then h:update_hp(obj.num) end
                end
            else
                kill[ obj.id ] = (obj.mkdmg or 0)

                obj.num = math.ceil(obj.num)
                dead = obj.num0 - obj.num
                dead_num = dead_num + dead

                local deads = node.dead_soldier
                local lives = node.live_soldier

                if not deads then
                    deads = {}
                    node.dead_soldier = deads
                end
                if not lives then
                    lives = {}
                    node.live_soldier = lives
                end
                local id = obj.id
                deads[ id ] = (deads[ id ] or 0) + dead
                lives[ id ] = obj.num

                local lv = obj.prop.Lv
                if not dead_lvl[ lv ] then dead_lvl[ lv ] = 0 end
                dead_lvl[ lv ] = dead_lvl[ lv ] + dead

            end
            node.mkdmg = (node.mkdmg or 0) + (obj.mkdmg or 0)
            node.lost = (node.lost or 0) + obj.prop.Pow * dead

            live_num = live_num + obj.num
            lost_pow = lost_pow + obj.prop.Pow * dead
            make_dmg = make_dmg + (obj.mkdmg or 0)
        end
    end

    return lost_pow, live_num, make_dmg, dead_num, dead_lvl
end


function rage(troop, D)
    if not is_ply(D) then return end
    local weights = {}

    local part = {100/225, 100/225, 25/225, 5/225}
    local erate = { 
        {1, 1, 0.2, 0.05}, 
        {1, 1, 0.2, 0.05}, 
        {5, 5, 1, 0.25}, 
        {20, 20, 4, 1} 
    }

    for pid, arm in pairs(troop.arms) do
        local total = 0
        for id, num in pairs(arm.live_soldier) do
            local conf = resmng.get_conf("prop_arm", id)
            if conf then
                total = total + (conf.Weight or 0) * num
                --print("weight", conf.Weight, num, total)
            end
        end
        total = total * 0.5
        table.insert(weights, {pid, total })
        --print("rage, weights, pid,total=", pid, total)
    end

    local haves = D:get_res_over_store()
    for mode = 1, 4, 1 do print("rage, have, mode, num = ", mode, haves[ mode ]) end

    local farms = D:get_farms()
    local result = {}

    for _, v in pairs(weights) do
        local needs = {0,0,0,0}
        local rages = {0,0,0,0}

        result[ v[1] ] = rages

        --troop.arms[ v[1] ].rages = rages
        for mode = 1, 4, 1 do
            local need= math.floor( v[2] * part[ mode ] )
            --print("need, mode, weight, need = ", mode, v[2], need)

            if haves[ mode ] >= need then
                D:do_dec_res(mode, need, VALUE_CHANGE_REASON.RAGE)
                rages[ mode ] = need
                haves[ mode ] = haves[ mode ] - need
                need = 0
            elseif haves[mode] > 0 then
                D:do_dec_res(mode, haves[mode], VALUE_CHANGE_REASON.RAGE)
                need = need - haves[ mode ]
                rages[ mode ] = haves[ mode ]
                haves[ mode ] = 0
            end

            needs[ mode ] = need

            if need > 0 then
                local class = BUILD_CLASS.RESOURCE
                local max_seq = BUILD_MAX_NUM[class] and BUILD_MAX_NUM[class][mode]
                for seq = 1, max_seq, 1 do
                    local build_idx = D:calc_build_idx(class, mode, seq)
                    local build = D:get_build(build_idx)
                    if not build then break end
                    local get = build:res_reap_some(need)
                    if get > 0 then 
                        need = need - get 
                        rages[ mode ] = rages[ mode ] + get
                        if need == 0 then break end
                    end
                end
            end
            needs[ mode ] = need
        end

        for nmode, need in pairs(needs) do
            if need > 0 then
                for hmode, have in pairs(haves) do
                    if have > 0 then
                        local hnum = math.floor(need * erate[ nmode ][ hmode ])
                        if have > hnum then
                            haves[ hmode ] = haves[ hmode ] - hnum
                            rages[ hmode ] = rages[ hmode ] + hnum
                            need = 0
                            D:do_dec_res(hmode, hnum, VALUE_CHANGE_REASON.RAGE)
                        else
                            haves[ hmode ] = 0
                            rages[ hmode ] = rages[ hmode ] + have
                            need = need - math.floor(have * erate[ hmode ][ nmode ])
                            D:do_dec_res(hmode, hnum, VALUE_CHANGE_REASON.RAGE)
                        end
                    end
                    needs[ nmode ] = need
                    if need <= 0 then break end
                end

                if need > 0 then
                    while #farms > 0 and need > 0 do
                        local farm = farms[1] 
                        local hmode = farm.mode
                        local hnum = need * erate[ nmode ][ hmode ]
                        local get = farm:res_reap_some(hnum)
                        if get > 0 then
                            if get >= hnum then
                                rages[ hmode ] = rages[ hmode ] + hum
                                need = 0
                                break
                            else
                                rages[ hmode ] = rages[ hmode ] + get
                                need = need - get * erate[ hmode ][ nmode ]
                                table.remove(farms, 1)
                            end
                        else
                            table.remove(farms, 1)
                        end
                    end
                end
            end
        end
    end

    local gets = {}
    for pid, rages in pairs(result) do
        local its = {}
        for mode, num in pairs(rages) do
            if num > 0 then
                table.insert(its, {"res", mode, math.floor(num)})
            end
        end
        if #its > 0 then gets[ pid ] = its end
    end

    return gets
end

function calc_kill(troop, make_dmg, kill_num, kill_lvl)
    if make_dmg < 1 then return end

    local calc = 0
    local last = false
    local proptab = resmng.prop_arm
    for pid, arm in pairs(troop.arms or {}) do
        if pid > 0 then
            local p = getPlayer(pid)
            if p then
                local r = arm.mkdmg / make_dmg
                for lv, num in pairs(kill_lvl) do
                    task_logic_t.process_task(p, TASK_ACTION.KILL_SOLDIER, lv, math.floor(r * num))
                end

                local dead = arm.dead_soldier 
                if dead then
                    local num = 0
                    for k, v in pairs(dead) do
                        num = num + v
                    end
                    task_logic_t.process_task(p, TASK_ACTION.DEAD_SOLDIER, num)
                end

                local nkill = r * kill_num
                local total = arm.mkdmg
                if total and total > 0 then
                    local kill = arm.kill_soldier
                    if kill then
                        for id, mkdmg in pairs( kill ) do
                            local n = math.floor( mkdmg * nkill / total )
                            kill[ id ] = n
                            calc = calc + n
                            last = {kill, id, n}
                        end
                    end
                end
            end
        end
    end
    local remain = kill_num - calc
    if remain >= 1 and last then
        last[ 1 ][ last[2] ] = last[3] + remain
    end
end


