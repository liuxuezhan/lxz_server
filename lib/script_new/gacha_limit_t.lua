module("gacha_limit_t", package.seeall)

gacha_world_limit = gacha_world_limit or {}

function get_gacha_world_limit(tab)
	local type, id, num, p = unpack(tab[1])
	local prop_limit = resmng.prop_gacha_world_limit[id]
	if prop_limit == nil then
		return nil
	end
	if gacha_world_limit[id] ~= nil and gacha_world_limit[id] >= prop_limit.Limit then
		local award = {}
		table.insert(award, prop_limit.BonusPolicy)
		table.insert(award, prop_limit.Bonus)
		return award
	else
		return nil
	end
end

function set_gacha_world_limit(tab)
	local type, id, num, p = unpack(tab[1])
	local prop_limit = resmng.prop_gacha_world_limit[id]
	if prop_limit == nil then
		return
	end
    if gacha_world_limit[id] == nil then
        gacha_world_limit[id] = 0
    end
	gacha_world_limit[id] = gacha_world_limit[id] + num

	--存储
    gPendingSave.status.gacha_limit = {[id]=gacha_world_limit[id]}
end

function load_gacha_world_limit()
	local db = dbmng:getOne()
    local info = db.status:findOne({_id="gacha_limit"})
    gacha_world_limit = {}
    for k, v in pairs(info or {}) do
        if k ~= "_id" then
            gacha_world_limit[k] = v
        end
    end
end

function gacha_limit_on_day_pass()
	gacha_world_limit = {}
    gPendingDelete.status.gache_limit = 1
end

