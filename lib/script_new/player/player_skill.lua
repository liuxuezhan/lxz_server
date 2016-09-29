module("player_t")

function launch_talent_skill(self, talentid)
    local gs = self.genius
    local hit = false
    for k, v in pairs(gs) do
        if v == talentid then
            hit = true
            break
        end
    end

    if not hit then return end

    local skillid = false
    local node = resmng.prop_genius[ talentid ]
    if node and node.Skill then
        skillid = node.Skill
    end

    if not skillid then return end
    local skill = resmng.prop_skill[ skillid ]
    if not skill then return end

    if skill.Cd then
        local cdover = self:get_cd("genius", talentid)
        if cdover > gTime then return end
    end

    self:do_skill(skill)

    self:set_cd("genius", talentid, skill.Cd)
    reply_ok(self, "launch_talent_skill", talentid)
end

function do_skill(self, skill)
    for k, v in pairs(skill.Effect) do
        do_skill_effect(self, table.unpack(v))
    end
end

function do_skill_effect(self, func, ...)
    local f = g_skill_effect[ func ]
    if f then f(self, ...) end
end

g_skill_effect = {}
g_skill_effect.AddBuf = function (self, bufid, count)
    local node = resmng.prop_buff[ bufid ]
    if node then
        self:add_buf(bufid, count)
    end
end

g_skill_effect.CallBackTroop = function (self, sec)
    for k, v in pairs(self.busy_troop_ids) do
        local troop  = troop_mng.get_troop(v)
        if troop then
            self:troop_recall( troop._id )
        end
    end

    local dx, dy = get_ety_pos( self )
    for k, v in pairs(self.busy_troop_ids) do
        local troop  = troop_mng.get_troop(v)
        if troop and troop:is_back() then
            local x, y = c_get_actor_pos( troop.eid )

            local distance = math.pow( math.pow( x - dx, 2 ) + math.pow( y - dy, 2 ), 0.5 )
            local speed = distance / sec
            if speed > troop.speed then
                troop.curx, troop.cury = x, y
                troop.speed = speed
                troop.tmOver = gTime + sec
                c_add_actor( troop.eid, troop.curx, troop.cury, troop.dx, troop.dy, gTime, troop.speed)
                etypipe.add( troop )
                troop:notify_owner()

            end
        end
    end
end



function get_cd(self, what, id)
    local cds = self.cds 
    for k, v in pairs(cds) do
        --v = {"skill", 10001, tmStart, tmOver}
        if v[1] == what and v[2] == id then
            return v[4]
        end
    end
    return 0
end

function set_cd(self, what, id, dura)
    if not dura then return end
    if dura <= 0 then return end

    local start = gTime
    local over = gTime + dura
    local hit = false
    local cds = self.cds 
    local dels = {}
    for k, v in ipairs(cds) do
        if v[1] == what and v[2] == id and (not hit) then
            v[3] = start
            v[4] = over
            hit = true
        elseif v[4] < gTime then
            table.insert(dels, 1, k)
        end
    end

    for _, idx in ipairs(dels) do
        table.remove(cds, idx)
    end
       
    if not hit then
        table.insert(cds, {what, id, start, over})
    end

    self.cds = self.cds
end

