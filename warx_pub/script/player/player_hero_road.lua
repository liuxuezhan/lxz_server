module("player_t")

function can_open_hero_road(self, prop_chapter)
	local pre_chapters = prop_chapter.ChapterCon
	for k, v in pairs(pre_chapters or {}) do
		local has_chapter = self.hero_road_chapter[v]
		if has_chapter == nil then
			return false
		end
		if has_chapter.state ~= HERO_ROAD_CHAPTER_STATE.ALL_FINISHED then
			return false
		end
	end
	return true
end

function is_any_chapter_running(self)
    return 0 ~= self.hero_road_cur_chapter
end

function is_chapter_finished(self, chapter_id)
    if self.hero_road_cur_chapter < chapter_id then
        return false
    end
    local chapter_data = self.hero_road_chapter[chapter_id]
    if nil == chapter_data then
        return false
    end
    return chapter_data.state == HERO_ROAD_CHAPTER_STATE.ALL_FINISHED
end

function accept_hero_road_chapter(self, chapter_id)
	local prop_chapter = resmng.get_conf("prop_hero_road_chapter", chapter_id)
	if prop_chapter == nil then
		return
	end

	local task_list = prop_chapter.TaskList[self.culture]
	if task_list == nil then
		return
	end

	--判断是否接过任务了
	local chapter_data = self.hero_road_chapter[chapter_id]
	if chapter_data ~= nil then
		return
	end

	--判断前置条件
	if self:can_open_hero_road(prop_chapter) == false then
		return
	end

	if chapter_data == nil then
		chapter_data = {}
		chapter_data.tasks = {}
		self.hero_road_chapter[chapter_id] = chapter_data
	end

	local tasks = chapter_data.tasks
	
	chapter_data.state = HERO_ROAD_CHAPTER_STATE.ACCEPTED
    local task_array = {}
    for task_id = task_list[1], task_list[2] do
        tasks[task_id] = 0
        table.insert(task_array, task_id)
    end
	
	self.hero_road_chapter = self.hero_road_chapter
	self.hero_road_cur_chapter = chapter_id

	--接任务
	self:accept_task(task_array)
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
        self:add_bonus("mutex_award", prop_chapter.AwardEnd[self.culture], VALUE_CHANGE_REASON.REASON_TASK)
        chapter_data.state = HERO_ROAD_CHAPTER_STATE.ALL_FINISHED
    end
	self.hero_road_chapter = self.hero_road_chapter
end

function get_hero_road_task_award(self, chapter_id, task_id)
	if self.hero_road_cur_chapter ~= chapter_id then
		return
	end

	local chapter_data = self.hero_road_chapter[chapter_id]
	if chapter_data == nil or chapter_data.tasks == nil then
		return
	end

    local tasks = chapter_data.tasks
    if nil == tasks[task_id] then
        return
    end
    if tasks[task_id] > 0 then
        return
    end

	local prop_chapter = resmng.get_conf("prop_hero_road_chapter", chapter_id)
	if prop_chapter == nil then
		return
	end

	if self:can_finish_task(task_id) == false then
		return
	end

    tasks[task_id] = gTime

    local can_finished = true
    for k, v in pairs(tasks) do
        if 0 == v then
            can_finished = false
            break
        end
    end
    if can_finished then
        chapter_data.state = HERO_ROAD_CHAPTER_STATE.CAN_FINISHED
    end

	self.hero_road_chapter = self.hero_road_chapter
	self:finish_task(task_id)
end

