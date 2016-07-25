module("arm_t", package.seeall)

function new()
	local obj = {}
	setmetatable(obj, {__index=arm_t})
	obj:init()
	return obj
end

function init(self)
	self.pid = 0
	self.live_soldier = {} --self.live_soldier[1002] = 99
	self.dead_soldier = {} --self.dead_soldier[1002] = 30
	self.hurt_soldier = {} --self.hurt_soldier[1002] = 10
	self.heros = {0,0,0,0}  --self.heros[1] = 1_60001
end

function get_soldier_num_by_id(self, soldier_id)	
	if self.live_soldier[soldier_id] == nil then 
		return 0
	end
	return self.live_soldier[soldier_id]
end

function add_soldier(self, soldier_id, num)
	if self.live_soldier[soldier_id] ~= nil then
		self.live_soldier[soldier_id] = self.live_soldier[soldier_id] + num
	else
		self.live_soldier[soldier_id] = num
	end
end

function add_dead_soldier(self, soldier_id, num)
	if self.dead_soldier[soldier_id] ~= nil then
		self.dead_soldier[soldier_id] = self.dead_soldier[soldier_id] + num
	else
		self.dead_soldier[soldier_id] = num
	end
end
function add_hurt_soldier(self, soldier_id, num)
	if self.hurt_soldier[soldier_id] ~= nil then
		self.hurt_soldier[soldier_id] = self.hurt_soldier[soldier_id] + num
	else
		self.hurt_soldier[soldier_id] = num
	end
end
function can_rm_soldier(self, soldier_id, num)
	if self.live_soldier[soldier_id] == nil or self.live_soldier[soldier_id] < num then
		return false
	end
	return true
end

function rm_soldier(self, soldier_id, num)
	if self:can_rm_soldier(soldier_id, num) == true then
		self.live_soldier[soldier_id] = self.live_soldier[soldier_id] - num
		return true
	end
	return false
end

function get_soldier_tab(self)
	return self.live_soldier
end

function get_total_soldier(self)
    local total = 0
    for k, v in pairs(self.live_soldier) do 
       total = total + v 
    end
    return total
end

function get_pid(self)
	return self.pid
end

function set_pid(self, pid)
	self.pid = pid
end

function get_heros(self)
	return self.heros
end

function get_hero_index(self, hero_id)
	for k, v in pairs(self.heros) do
		if v == hero_id and v ~= 0 then
			return k
		end
	end
end

function add_hero(self, k, hero_id)
    local heros = self.heros
    if heros[ k ] == 0 then
        if self:get_hero_index(hero_id) then return false end
        self.heros[ k ] = hero_id
        return true
    end
end

function clear_hero(self)
    self.heros = {0,0,0,0}
end

function rm_hero(self, hero_id)
    for k, v in pairs(self.heros) do
        if v == hero_id then 
            self.heros[ k ] = 0 
            return true
        end
    end
end

function calc_arm_speed(self)
	--local speed = 1024
	--for k, v in pairs(self.live_soldier) do
	--	local temp_speed = resmng.prop_arm[k].Speed
	--	if speed > temp_speed then
	--		speed = temp_speed
	--	end
	--end
	--return speed

    local speed = math.huge
    for k, v in pairs(self.live_soldier) do
        local temp_speed = resmng.prop_arm[k].Speed
        if speed > temp_speed then
            speed = temp_speed
        end
    end
    if speed == math.huge then return end
    if speed < 0.001 then return end
    return speed
end

--判断是否能扣除部队
function can_deduct_arm(self, deduct_arm)
	for k, v in pairs(deduct_arm.live_soldier) do
		if self:can_rm_soldier(k, v) == false then
			return false
		end
	end
	return true
end

--扣除部队
function deduct_arm(self, deduct_arm)
	if self:can_deduct_arm(deduct_arm) == false then
		return false
	end
	for k, v in pairs(deduct_arm.live_soldier or {}) do
		self:rm_soldier(k, v)
	end
	for k, v in pairs(deduct_arm.heros or {}) do
		self:rm_hero(v)
	end
end

--[[
function calc_hurt_soldier(self)
    for k, v in pairs(self.live_soldier) do
        local hurts = v.num0 - v.num
        if self.hurt[k] == nil then
            self.hurt[k] = hurts
        else
            self.hurt[k] = self.hurt[k] + hurts
        end
    end
end
--]]




