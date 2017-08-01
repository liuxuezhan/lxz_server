--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_hero_task_detail = {

	[HERO_TASK_130010101] = { ID = HERO_TASK_130010101, Title = LG_TASK_TITLE_130030001, Name = LG_TASK_DETAIL_NAME_130010003, Desc = LG_TASK_DETAIL_DESC_130200025, TaskType = 1, Action = 1, Dure = 5400, AccGold = 50, AccTime = 60, HelpAccTime = 60, HelpLimitTm = 60, HeroNum = 1, HelpHeroNum = 0, EventCondition = nil, Bonus = {{"item",2019001,1,10000},{"item",4004001,1,10000},{"item",4005001,1,10000},{"item",7023010,12,10000},{"res",12,20,10000}}, EventBonus = {{"item",2019001,1,10000},{"item",4004001,1,10000},{"item",4005001,1,10000},{"item",7023010,12,10000},{"res",12,20,10000}},},
	[HERO_TASK_130010102] = { ID = HERO_TASK_130010102, Title = LG_TASK_TITLE_130030001, Name = LG_TASK_DETAIL_NAME_130010005, Desc = LG_TASK_DETAIL_DESC_130200025, TaskType = 1, Action = 2, Dure = 7200, AccGold = 50, AccTime = 60, HelpAccTime = 60, HelpLimitTm = 60, HeroNum = 1, HelpHeroNum = 0, EventCondition = nil, Bonus = {{"item",2019001,1,10000},{"item",8009002,1,10000},{"item",8009001,1,10000},{"res",12,20,10000}}, EventBonus = {{"item",2019001,1,10000},{"item",8009002,1,10000},{"item",8009001,1,10000},{"res",12,20,10000}},},
	[HERO_TASK_130010103] = { ID = HERO_TASK_130010103, Title = LG_TASK_TITLE_130030001, Name = LG_TASK_DETAIL_NAME_130010002, Desc = LG_TASK_DETAIL_DESC_130200029, TaskType = 2, Action = 3, Dure = 10800, AccGold = 50, AccTime = 60, HelpAccTime = 60, HelpLimitTm = 60, HeroNum = 3, HelpHeroNum = 2, EventCondition = {{"Nature",2,1},{"Culture",2,1}}, Bonus = {{"item",2019001,1,10000},{"item",4003001,20,10000},{"item",7020001,1,10000},{"res",12,20,10000}}, EventBonus = {{"item",2019001,1,10000},{"item",4003001,20,10000},{"item",7020001,1,10000},{"res",12,20,10000}},},
}
