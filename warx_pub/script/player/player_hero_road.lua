module("player_t")


-- self.hero_road_cur_chapter
-- self.hero_road_chapter =
-- {
-- 	[id] =
-- 	{
-- 		state=HERO_ROAD_CHAPTER_STATE.CAN_ACCEPT,
-- 		task_line={
--			[1]={cur_id=id,is_finish=true,get_award=true}
--		}
-- 	}
-- }

function can_open_hero_road(self, prop_chapter)
	local pre_chapters = prop_chapter.ChapterCon
	for k, v in pairs(pre_chapters or {}) do
		local has_chapter = self.hero_road_chapter[v]
		if has_chapter == nil then
			return false
		end
		if has_chapter.state == HERO_ROAD_CHAPTER_STATE.ACCEPTED then
			return false
		end
		if has_chapter.state ~= HERO_ROAD_CHAPTER_STATE.ALL_FINISHED then
			return false
		end
	end
--	local pre_lv = prop_chapter.CastleLv
--	if pre_lv == nil then
--		return true
--	end
--	if pre_lv > self:get_castle_lv() then
--		return false
--	end
	return true
end

function is_any_chapter_running(self)
	if self.hero_road_cur_chapter ~= 0 then
		return true
	end
	return false
end

function accept_hero_road_chapter(self, chapter_id)
	local prop_chapter = resmng.get_conf("prop_hero_road_chapter", chapter_id)
	if prop_chapter == nil then
		return
	end

	local task_array = prop_chapter.TaskList
	if task_array == nil then
		return
	end

	--判断是否接过任务了
	local chapter_data = self.hero_road_chapter[chapter_id]
	if chapter_data ~= nil then
		return
	end

	--判断没有进行中的章节
--	if self:is_any_chapter_running() == true then
--		return
--	end

	--判断前置条件
	if self:can_open_hero_road(prop_chapter) == false then
		return
	end

	local start_task = task_array[1]
	if chapter_data == nil then
		chapter_data = {}
		chapter_data.task_line = {}
		self.hero_road_chapter[chapter_id] = chapter_data
	end

	--if chapter_data.task_line[line_id] == nil then
	--	chapter_data.task_line[line_id] = {}
	--end
	
	local line_data = chapter_data.task_line
	
	chapter_data.state = HERO_ROAD_CHAPTER_STATE.ACCEPTED
	line_data.cur_id = start_task
	
	self.hero_road_chapter = self.hero_road_chapter
	self.hero_road_cur_chapter = chapter_id

	--接任务
	self:accept_task({start_task})
	-- local prop_task = resmng.get_conf("prop_task_detail", start_task)
	-- if prop_task == nil then
	-- 	return
	-- end
	-- self:add_task_data(prop_task)

end	

function get_hero_road_chapter_award(self, chapter_id)
	if self.hero_road_cur_chapter ~= chapter_id then
		return
	end

	local chapter_data = self.hero_road_chapter[chapter_id]
	if chapter_data == nil then
		return
	end

	local prop_chapter = resmng.get_conf("prop_hero_road_chapter", chapter_id)
	if prop_chapter == nil then
		return
	end

    if chapter_data.state == HERO_ROAD_CHAPTER_STATE.CAN_FINISHED then
        self:add_bonus("mutex_award", prop_chapter.AwardEnd, VALUE_CHANGE_REASON.REASON_TASK)
        chapter_data.state = HERO_ROAD_CHAPTER_STATE.ALL_FINISHED
    end
	self.hero_road_chapter = self.hero_road_chapter

end

function get_hero_road_task_award(self, chapter_id, task_id)
	if self.hero_road_cur_chapter ~= chapter_id then
		return
	end

	local chapter_data = self.hero_road_chapter[chapter_id]
	if chapter_data == nil or chapter_data.task_line == nil then
		return
	end

	local line_data = chapter_data.task_line
	if line_data.cur_id ~= task_id then
		return
	end
	if line_data.is_finish == true then
		return
	end

	local prop_chapter = resmng.get_conf("prop_hero_road_chapter", chapter_id)
	if prop_chapter == nil then
		return
	end
	local task_array = prop_chapter.TaskList
	if task_array == nil then
		return
	end

	if self:can_finish_task(task_id) == false then
		return
	end

	if task_id == task_array[2] then--如果是最后一个任务
	--	self.hero_road_cur_chapter = 0
		chapter_data.state = HERO_ROAD_CHAPTER_STATE.FINISHED
		line_data.is_finish = true
        chapter_data.state = HERO_ROAD_CHAPTER_STATE.CAN_FINISHED

		--判断是否所有支线完成
		--local line_num = 0
		--for k, v in pairs (chapter_data.task_line or {}) do
		--	if v.is_finish == true then
	--			line_num = line_num + 1
	--		end
	--	end
	--	if line_num == #prop_chapter.TaskList then
			--chapter_data.state = HERO_ROAD_CHAPTER_STATE.CAN_FINISHED
	--	end
	else
        local prop_task = resmng.get_conf("prop_task_detail", task_id)
        if not prop_task then
            WARN("hero task prop error %s", prop_task.ID)
            return
        end
        if not prop_task.NextTask then
            WARN("hero task prop error %s", prop_task.ID)
            return
        end

		line_data.cur_id = prop_task.NextTask
		--接任务
		self:accept_task({line_data.cur_id})
		-- local prop_task = resmng.get_conf("prop_task_detail", line_data.cur_id)
		-- if prop_task == nil then
		-- 	return
		-- end
		-- self:add_task_data(prop_task)
	end
	self.hero_road_chapter = self.hero_road_chapter

	self:finish_task(task_id)
end


