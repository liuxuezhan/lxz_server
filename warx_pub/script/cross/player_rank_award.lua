module("player_rank_award", package.seeall)

local t_name = "player_rank_award"

function add_award(pid, class, mode, mail_id, award, param)
    local award = {
        _id = getSn("player_rank_award"),
        pid = pid,
        class = class,
        mode = mode,
        mail_id = mail_id,
        award = award,
        param = param,
        claim_time = 0,
        create_time = gTime,
    }
    gPendingInsert[t_name][award._id] = award
end

function claim_all_awards(pid)
    local db = dbmng:getOne()
    if db then
        local info = db[t_name]:find({pid = pid, claim_time = 0})
        local awards = {}
        while info:hasNext() do
            local award = info:next()
            if award then
                gPendingSave[t_name][award._id].claim_time = gTime
                table.insert(awards, {award._id, award.mail_id, award.award, award.param})
            end
        end
        if #awards > 0 then
            return awards
        end
    end
end

