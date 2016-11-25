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
    print( "do_skill_effect", func, ... )
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
    if sec < 1 then sec = 1 end
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
            local curx, cury = c_get_actor_pos( troop.eid )
            troop.curx = curx
            troop.cury = cury
            troop.tmCur = gTime
            local dist = c_calc_distance( curx, cury, dx, dy )
            local use_time = sec
            troop.use_time = use_time
            troop.tmOver = math.ceil( gTime + use_time )
            troop.speed = dist / use_time

            c_troop_set_speed( troop.eid, troop.speed, troop.use_time )
            troop:notify_owner()
            troop:save()

       end
    end
end



function get_cd(self, what, id)
    local cds = self.cds 
    for k, v in pairs(cds) do
        --v = {"skill", 10001, tmStart, tmOver}
        if v[1] == what and v[2] == id then
            if v[4] > gTime then
                return v[4]
            else
                table.remove( cds, k )
                self.cds = cds
                return 0
            end
        end
    end
    return 0
end

function get_cd_info( self, what, id )
    local cds = self.cds 
    for k, v in pairs(cds) do
        --v = {"genius", 10001, tmStart, tmOver}
        if v[1] == what and v[2] == id then
            if v[4] > gTime then
                return v
            else
                table.remove( cds, k )
                self.cds = cds
                return
            end
        end
    end
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

function del_cd( self, what, id )
    local cds = self.cds
    for k, v in pairs( cds ) do
        if v[1] == what and v[2] == id then
            table.remove( cds, k )
            self.cds = cds
            return true
        end
    end
end


