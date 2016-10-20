--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_achievement = {

	[ACHIEVEMENT_10101] = { ID = ACHIEVEMENT_10101, Name = LG_ACHIEVEMENT_NAME_164100001, Desc = LG_ACHIEVEMENT_DESC_164200010, Class = 1, Mode = 1, Lv = 1, Var = ACH_COUNT_KILL, Count = 1000, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_10102] = { ID = ACHIEVEMENT_10102, Name = LG_ACHIEVEMENT_NAME_164100001, Desc = LG_ACHIEVEMENT_DESC_164200010, Class = 1, Mode = 1, Lv = 2, Var = ACH_COUNT_KILL, Count = 10000, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10103] = { ID = ACHIEVEMENT_10103, Name = LG_ACHIEVEMENT_NAME_164100001, Desc = LG_ACHIEVEMENT_DESC_164200010, Class = 1, Mode = 1, Lv = 3, Var = ACH_COUNT_KILL, Count = 100000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10104] = { ID = ACHIEVEMENT_10104, Name = LG_ACHIEVEMENT_NAME_164100001, Desc = LG_ACHIEVEMENT_DESC_164200010, Class = 1, Mode = 1, Lv = 4, Var = ACH_COUNT_KILL, Count = 1000000, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_10105] = { ID = ACHIEVEMENT_10105, Name = LG_ACHIEVEMENT_NAME_164100001, Desc = LG_ACHIEVEMENT_DESC_164200010, Class = 1, Mode = 1, Lv = 5, Var = ACH_COUNT_KILL, Count = 10000000, Point = 15, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_10106] = { ID = ACHIEVEMENT_10106, Name = LG_ACHIEVEMENT_NAME_164100001, Desc = LG_ACHIEVEMENT_DESC_164200010, Class = 1, Mode = 1, Lv = 6, Var = ACH_COUNT_KILL, Count = 100000000, Point = 15, Reward = {{"res",6,2000,10000}},},
	[ACHIEVEMENT_10201] = { ID = ACHIEVEMENT_10201, Name = LG_ACHIEVEMENT_NAME_164100002, Desc = LG_ACHIEVEMENT_DESC_164200020, Class = 1, Mode = 2, Lv = 1, Var = ACH_COUNT_RESOURCE_ROB, Count = 100000, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_10202] = { ID = ACHIEVEMENT_10202, Name = LG_ACHIEVEMENT_NAME_164100002, Desc = LG_ACHIEVEMENT_DESC_164200020, Class = 1, Mode = 2, Lv = 2, Var = ACH_COUNT_RESOURCE_ROB, Count = 1000000, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10203] = { ID = ACHIEVEMENT_10203, Name = LG_ACHIEVEMENT_NAME_164100002, Desc = LG_ACHIEVEMENT_DESC_164200020, Class = 1, Mode = 2, Lv = 3, Var = ACH_COUNT_RESOURCE_ROB, Count = 10000000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10204] = { ID = ACHIEVEMENT_10204, Name = LG_ACHIEVEMENT_NAME_164100002, Desc = LG_ACHIEVEMENT_DESC_164200020, Class = 1, Mode = 2, Lv = 4, Var = ACH_COUNT_RESOURCE_ROB, Count = 50000000, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_10205] = { ID = ACHIEVEMENT_10205, Name = LG_ACHIEVEMENT_NAME_164100002, Desc = LG_ACHIEVEMENT_DESC_164200020, Class = 1, Mode = 2, Lv = 5, Var = ACH_COUNT_RESOURCE_ROB, Count = 200000000, Point = 15, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_10206] = { ID = ACHIEVEMENT_10206, Name = LG_ACHIEVEMENT_NAME_164100002, Desc = LG_ACHIEVEMENT_DESC_164200020, Class = 1, Mode = 2, Lv = 6, Var = ACH_COUNT_RESOURCE_ROB, Count = 1000000000, Point = 15, Reward = {{"res",6,1000,10000}},},
	[ACHIEVEMENT_10301] = { ID = ACHIEVEMENT_10301, Name = LG_ACHIEVEMENT_NAME_164100003, Desc = LG_ACHIEVEMENT_DESC_164200030, Class = 1, Mode = 3, Lv = 1, Var = ACH_COUNT_PVPWIN, Count = 3, Point = 3, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_10302] = { ID = ACHIEVEMENT_10302, Name = LG_ACHIEVEMENT_NAME_164100003, Desc = LG_ACHIEVEMENT_DESC_164200030, Class = 1, Mode = 3, Lv = 2, Var = ACH_COUNT_PVPWIN, Count = 10, Point = 3, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10303] = { ID = ACHIEVEMENT_10303, Name = LG_ACHIEVEMENT_NAME_164100003, Desc = LG_ACHIEVEMENT_DESC_164200030, Class = 1, Mode = 3, Lv = 3, Var = ACH_COUNT_PVPWIN, Count = 100, Point = 6, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10304] = { ID = ACHIEVEMENT_10304, Name = LG_ACHIEVEMENT_NAME_164100003, Desc = LG_ACHIEVEMENT_DESC_164200030, Class = 1, Mode = 3, Lv = 4, Var = ACH_COUNT_PVPWIN, Count = 1000, Point = 6, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10305] = { ID = ACHIEVEMENT_10305, Name = LG_ACHIEVEMENT_NAME_164100003, Desc = LG_ACHIEVEMENT_DESC_164200030, Class = 1, Mode = 3, Lv = 5, Var = ACH_COUNT_PVPWIN, Count = 8000, Point = 9, Reward = {{"res",6,800,10000}},},
	[ACHIEVEMENT_10306] = { ID = ACHIEVEMENT_10306, Name = LG_ACHIEVEMENT_NAME_164100003, Desc = LG_ACHIEVEMENT_DESC_164200030, Class = 1, Mode = 3, Lv = 6, Var = ACH_COUNT_PVPWIN, Count = 50000, Point = 9, Reward = {{"res",6,1900,10000}},},
	[ACHIEVEMENT_10401] = { ID = ACHIEVEMENT_10401, Name = LG_ACHIEVEMENT_NAME_164100004, Desc = LG_ACHIEVEMENT_DESC_164200040, Class = 1, Mode = 4, Lv = 1, Var = ACH_COUNT_CURE, Count = 1000, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_10402] = { ID = ACHIEVEMENT_10402, Name = LG_ACHIEVEMENT_NAME_164100004, Desc = LG_ACHIEVEMENT_DESC_164200040, Class = 1, Mode = 4, Lv = 2, Var = ACH_COUNT_CURE, Count = 10000, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10403] = { ID = ACHIEVEMENT_10403, Name = LG_ACHIEVEMENT_NAME_164100004, Desc = LG_ACHIEVEMENT_DESC_164200040, Class = 1, Mode = 4, Lv = 3, Var = ACH_COUNT_CURE, Count = 100000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10404] = { ID = ACHIEVEMENT_10404, Name = LG_ACHIEVEMENT_NAME_164100004, Desc = LG_ACHIEVEMENT_DESC_164200040, Class = 1, Mode = 4, Lv = 4, Var = ACH_COUNT_CURE, Count = 400000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10405] = { ID = ACHIEVEMENT_10405, Name = LG_ACHIEVEMENT_NAME_164100004, Desc = LG_ACHIEVEMENT_DESC_164200040, Class = 1, Mode = 4, Lv = 5, Var = ACH_COUNT_CURE, Count = 2000000, Point = 15, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_10406] = { ID = ACHIEVEMENT_10406, Name = LG_ACHIEVEMENT_NAME_164100004, Desc = LG_ACHIEVEMENT_DESC_164200040, Class = 1, Mode = 4, Lv = 6, Var = ACH_COUNT_CURE, Count = 10000000, Point = 15, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_10501] = { ID = ACHIEVEMENT_10501, Name = LG_ACHIEVEMENT_NAME_164100005, Desc = LG_ACHIEVEMENT_DESC_164200050, Class = 1, Mode = 5, Lv = 1, Var = ACH_COUNT_TRAIN, Count = 100, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_10502] = { ID = ACHIEVEMENT_10502, Name = LG_ACHIEVEMENT_NAME_164100005, Desc = LG_ACHIEVEMENT_DESC_164200050, Class = 1, Mode = 5, Lv = 2, Var = ACH_COUNT_TRAIN, Count = 1000, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10503] = { ID = ACHIEVEMENT_10503, Name = LG_ACHIEVEMENT_NAME_164100005, Desc = LG_ACHIEVEMENT_DESC_164200050, Class = 1, Mode = 5, Lv = 3, Var = ACH_COUNT_TRAIN, Count = 10000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10504] = { ID = ACHIEVEMENT_10504, Name = LG_ACHIEVEMENT_NAME_164100005, Desc = LG_ACHIEVEMENT_DESC_164200050, Class = 1, Mode = 5, Lv = 4, Var = ACH_COUNT_TRAIN, Count = 100000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10505] = { ID = ACHIEVEMENT_10505, Name = LG_ACHIEVEMENT_NAME_164100005, Desc = LG_ACHIEVEMENT_DESC_164200050, Class = 1, Mode = 5, Lv = 5, Var = ACH_COUNT_TRAIN, Count = 1000000, Point = 15, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_10506] = { ID = ACHIEVEMENT_10506, Name = LG_ACHIEVEMENT_NAME_164100005, Desc = LG_ACHIEVEMENT_DESC_164200050, Class = 1, Mode = 5, Lv = 6, Var = ACH_COUNT_TRAIN, Count = 10000000, Point = 15, Reward = {{"res",6,1000,10000}},},
	[ACHIEVEMENT_10601] = { ID = ACHIEVEMENT_10601, Name = LG_ACHIEVEMENT_NAME_164100006, Desc = LG_ACHIEVEMENT_DESC_164200060, Class = 1, Mode = 6, Lv = 1, Var = ACH_COUNT_SCOUT, Count = 10, Point = 3, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_10602] = { ID = ACHIEVEMENT_10602, Name = LG_ACHIEVEMENT_NAME_164100006, Desc = LG_ACHIEVEMENT_DESC_164200060, Class = 1, Mode = 6, Lv = 2, Var = ACH_COUNT_SCOUT, Count = 100, Point = 3, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10603] = { ID = ACHIEVEMENT_10603, Name = LG_ACHIEVEMENT_NAME_164100006, Desc = LG_ACHIEVEMENT_DESC_164200060, Class = 1, Mode = 6, Lv = 3, Var = ACH_COUNT_SCOUT, Count = 1000, Point = 6, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_10604] = { ID = ACHIEVEMENT_10604, Name = LG_ACHIEVEMENT_NAME_164100006, Desc = LG_ACHIEVEMENT_DESC_164200060, Class = 1, Mode = 6, Lv = 4, Var = ACH_COUNT_SCOUT, Count = 5000, Point = 6, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_10605] = { ID = ACHIEVEMENT_10605, Name = LG_ACHIEVEMENT_NAME_164100006, Desc = LG_ACHIEVEMENT_DESC_164200060, Class = 1, Mode = 6, Lv = 5, Var = ACH_COUNT_SCOUT, Count = 20000, Point = 9, Reward = {{"res",6,1000,10000}},},
	[ACHIEVEMENT_10606] = { ID = ACHIEVEMENT_10606, Name = LG_ACHIEVEMENT_NAME_164100006, Desc = LG_ACHIEVEMENT_DESC_164200060, Class = 1, Mode = 6, Lv = 6, Var = ACH_COUNT_SCOUT, Count = 100000, Point = 9, Reward = {{"res",6,2000,10000}},},
	[ACHIEVEMENT_20101] = { ID = ACHIEVEMENT_20101, Name = LG_ACHIEVEMENT_NAME_164100007, Desc = LG_ACHIEVEMENT_DESC_164200070, Class = 2, Mode = 1, Lv = 1, Var = ACH_COUNT_RESEARCH, Count = 1, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_20102] = { ID = ACHIEVEMENT_20102, Name = LG_ACHIEVEMENT_NAME_164100007, Desc = LG_ACHIEVEMENT_DESC_164200070, Class = 2, Mode = 1, Lv = 2, Var = ACH_COUNT_RESEARCH, Count = 10, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20103] = { ID = ACHIEVEMENT_20103, Name = LG_ACHIEVEMENT_NAME_164100007, Desc = LG_ACHIEVEMENT_DESC_164200070, Class = 2, Mode = 1, Lv = 3, Var = ACH_COUNT_RESEARCH, Count = 100, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20104] = { ID = ACHIEVEMENT_20104, Name = LG_ACHIEVEMENT_NAME_164100007, Desc = LG_ACHIEVEMENT_DESC_164200070, Class = 2, Mode = 1, Lv = 4, Var = ACH_COUNT_RESEARCH, Count = 200, Point = 10, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_20105] = { ID = ACHIEVEMENT_20105, Name = LG_ACHIEVEMENT_NAME_164100007, Desc = LG_ACHIEVEMENT_DESC_164200070, Class = 2, Mode = 1, Lv = 5, Var = ACH_COUNT_RESEARCH, Count = 400, Point = 15, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_20106] = { ID = ACHIEVEMENT_20106, Name = LG_ACHIEVEMENT_NAME_164100007, Desc = LG_ACHIEVEMENT_DESC_164200070, Class = 2, Mode = 1, Lv = 6, Var = ACH_COUNT_RESEARCH, Count = 900, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_20201] = { ID = ACHIEVEMENT_20201, Name = LG_ACHIEVEMENT_NAME_164100008, Desc = LG_ACHIEVEMENT_DESC_164200080, Class = 2, Mode = 2, Lv = 1, Var = ACH_COUNT_GATHER, Count = 100000, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_20202] = { ID = ACHIEVEMENT_20202, Name = LG_ACHIEVEMENT_NAME_164100008, Desc = LG_ACHIEVEMENT_DESC_164200080, Class = 2, Mode = 2, Lv = 2, Var = ACH_COUNT_GATHER, Count = 1000000, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20203] = { ID = ACHIEVEMENT_20203, Name = LG_ACHIEVEMENT_NAME_164100008, Desc = LG_ACHIEVEMENT_DESC_164200080, Class = 2, Mode = 2, Lv = 3, Var = ACH_COUNT_GATHER, Count = 10000000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20204] = { ID = ACHIEVEMENT_20204, Name = LG_ACHIEVEMENT_NAME_164100008, Desc = LG_ACHIEVEMENT_DESC_164200080, Class = 2, Mode = 2, Lv = 4, Var = ACH_COUNT_GATHER, Count = 100000000, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20205] = { ID = ACHIEVEMENT_20205, Name = LG_ACHIEVEMENT_NAME_164100008, Desc = LG_ACHIEVEMENT_DESC_164200080, Class = 2, Mode = 2, Lv = 5, Var = ACH_COUNT_GATHER, Count = 1000000000, Point = 15, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_20206] = { ID = ACHIEVEMENT_20206, Name = LG_ACHIEVEMENT_NAME_164100008, Desc = LG_ACHIEVEMENT_DESC_164200080, Class = 2, Mode = 2, Lv = 6, Var = ACH_COUNT_GATHER, Count = 10000000000, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_20301] = { ID = ACHIEVEMENT_20301, Name = LG_ACHIEVEMENT_NAME_164100009, Desc = LG_ACHIEVEMENT_DESC_164200090, Class = 2, Mode = 3, Lv = 1, Var = ACH_COUNT_ACC, Count = 1, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_20302] = { ID = ACHIEVEMENT_20302, Name = LG_ACHIEVEMENT_NAME_164100009, Desc = LG_ACHIEVEMENT_DESC_164200090, Class = 2, Mode = 3, Lv = 2, Var = ACH_COUNT_ACC, Count = 10, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20303] = { ID = ACHIEVEMENT_20303, Name = LG_ACHIEVEMENT_NAME_164100009, Desc = LG_ACHIEVEMENT_DESC_164200090, Class = 2, Mode = 3, Lv = 3, Var = ACH_COUNT_ACC, Count = 100, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20304] = { ID = ACHIEVEMENT_20304, Name = LG_ACHIEVEMENT_NAME_164100009, Desc = LG_ACHIEVEMENT_DESC_164200090, Class = 2, Mode = 3, Lv = 4, Var = ACH_COUNT_ACC, Count = 500, Point = 10, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_20305] = { ID = ACHIEVEMENT_20305, Name = LG_ACHIEVEMENT_NAME_164100009, Desc = LG_ACHIEVEMENT_DESC_164200090, Class = 2, Mode = 3, Lv = 5, Var = ACH_COUNT_ACC, Count = 2000, Point = 15, Reward = {{"res",6,600,10000}},},
	[ACHIEVEMENT_20306] = { ID = ACHIEVEMENT_20306, Name = LG_ACHIEVEMENT_NAME_164100009, Desc = LG_ACHIEVEMENT_DESC_164200090, Class = 2, Mode = 3, Lv = 6, Var = ACH_COUNT_ACC, Count = 10000, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_20401] = { ID = ACHIEVEMENT_20401, Name = LG_ACHIEVEMENT_NAME_164100010, Desc = LG_ACHIEVEMENT_DESC_164200100, Class = 2, Mode = 4, Lv = 1, Var = ACH_COUNT_ATTACK_MONSTER, Count = 1, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_20402] = { ID = ACHIEVEMENT_20402, Name = LG_ACHIEVEMENT_NAME_164100010, Desc = LG_ACHIEVEMENT_DESC_164200100, Class = 2, Mode = 4, Lv = 2, Var = ACH_COUNT_ATTACK_MONSTER, Count = 10, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20403] = { ID = ACHIEVEMENT_20403, Name = LG_ACHIEVEMENT_NAME_164100010, Desc = LG_ACHIEVEMENT_DESC_164200100, Class = 2, Mode = 4, Lv = 3, Var = ACH_COUNT_ATTACK_MONSTER, Count = 100, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_20404] = { ID = ACHIEVEMENT_20404, Name = LG_ACHIEVEMENT_NAME_164100010, Desc = LG_ACHIEVEMENT_DESC_164200100, Class = 2, Mode = 4, Lv = 4, Var = ACH_COUNT_ATTACK_MONSTER, Count = 1000, Point = 10, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_20405] = { ID = ACHIEVEMENT_20405, Name = LG_ACHIEVEMENT_NAME_164100010, Desc = LG_ACHIEVEMENT_DESC_164200100, Class = 2, Mode = 4, Lv = 5, Var = ACH_COUNT_ATTACK_MONSTER, Count = 5000, Point = 15, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_20406] = { ID = ACHIEVEMENT_20406, Name = LG_ACHIEVEMENT_NAME_164100010, Desc = LG_ACHIEVEMENT_DESC_164200100, Class = 2, Mode = 4, Lv = 6, Var = ACH_COUNT_ATTACK_MONSTER, Count = 20000, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_20501] = { ID = ACHIEVEMENT_20501, Name = LG_ACHIEVEMENT_NAME_164100011, Desc = LG_ACHIEVEMENT_DESC_164200110, Class = 2, Mode = 5, Lv = 1, Var = ACH_LEVEL_CASTLE, Count = 10, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_20502] = { ID = ACHIEVEMENT_20502, Name = LG_ACHIEVEMENT_NAME_164100011, Desc = LG_ACHIEVEMENT_DESC_164200110, Class = 2, Mode = 5, Lv = 2, Var = ACH_LEVEL_CASTLE, Count = 15, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20503] = { ID = ACHIEVEMENT_20503, Name = LG_ACHIEVEMENT_NAME_164100011, Desc = LG_ACHIEVEMENT_DESC_164200110, Class = 2, Mode = 5, Lv = 3, Var = ACH_LEVEL_CASTLE, Count = 20, Point = 10, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_20504] = { ID = ACHIEVEMENT_20504, Name = LG_ACHIEVEMENT_NAME_164100011, Desc = LG_ACHIEVEMENT_DESC_164200110, Class = 2, Mode = 5, Lv = 4, Var = ACH_LEVEL_CASTLE, Count = 24, Point = 10, Reward = {{"res",6,700,10000}},},
	[ACHIEVEMENT_20505] = { ID = ACHIEVEMENT_20505, Name = LG_ACHIEVEMENT_NAME_164100011, Desc = LG_ACHIEVEMENT_DESC_164200110, Class = 2, Mode = 5, Lv = 5, Var = ACH_LEVEL_CASTLE, Count = 27, Point = 15, Reward = {{"res",6,1100,10000}},},
	[ACHIEVEMENT_20506] = { ID = ACHIEVEMENT_20506, Name = LG_ACHIEVEMENT_NAME_164100011, Desc = LG_ACHIEVEMENT_DESC_164200110, Class = 2, Mode = 5, Lv = 6, Var = ACH_LEVEL_CASTLE, Count = 30, Point = 15, Reward = {{"res",6,1500,10000}},},
	[ACHIEVEMENT_20601] = { ID = ACHIEVEMENT_20601, Name = LG_ACHIEVEMENT_NAME_164100012, Desc = LG_ACHIEVEMENT_DESC_164200120, Class = 2, Mode = 6, Lv = 1, Var = ACH_COUNT_MIGRATE, Count = 1, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_20602] = { ID = ACHIEVEMENT_20602, Name = LG_ACHIEVEMENT_NAME_164100012, Desc = LG_ACHIEVEMENT_DESC_164200120, Class = 2, Mode = 6, Lv = 2, Var = ACH_COUNT_MIGRATE, Count = 4, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_20603] = { ID = ACHIEVEMENT_20603, Name = LG_ACHIEVEMENT_NAME_164100012, Desc = LG_ACHIEVEMENT_DESC_164200120, Class = 2, Mode = 6, Lv = 3, Var = ACH_COUNT_MIGRATE, Count = 10, Point = 10, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_20604] = { ID = ACHIEVEMENT_20604, Name = LG_ACHIEVEMENT_NAME_164100012, Desc = LG_ACHIEVEMENT_DESC_164200120, Class = 2, Mode = 6, Lv = 4, Var = ACH_COUNT_MIGRATE, Count = 80, Point = 10, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_20605] = { ID = ACHIEVEMENT_20605, Name = LG_ACHIEVEMENT_NAME_164100012, Desc = LG_ACHIEVEMENT_DESC_164200120, Class = 2, Mode = 6, Lv = 5, Var = ACH_COUNT_MIGRATE, Count = 500, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_20606] = { ID = ACHIEVEMENT_20606, Name = LG_ACHIEVEMENT_NAME_164100012, Desc = LG_ACHIEVEMENT_DESC_164200120, Class = 2, Mode = 6, Lv = 6, Var = ACH_COUNT_MIGRATE, Count = 2000, Point = 15, Reward = {{"res",6,1800,10000}},},
	[ACHIEVEMENT_30101] = { ID = ACHIEVEMENT_30101, Name = LG_ACHIEVEMENT_NAME_164100013, Desc = LG_ACHIEVEMENT_DESC_164200130, Class = 3, Mode = 1, Lv = 1, Var = ACH_LEVEL_PLAYER, Count = 10, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_30102] = { ID = ACHIEVEMENT_30102, Name = LG_ACHIEVEMENT_NAME_164100013, Desc = LG_ACHIEVEMENT_DESC_164200130, Class = 3, Mode = 1, Lv = 2, Var = ACH_LEVEL_PLAYER, Count = 20, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30103] = { ID = ACHIEVEMENT_30103, Name = LG_ACHIEVEMENT_NAME_164100013, Desc = LG_ACHIEVEMENT_DESC_164200130, Class = 3, Mode = 1, Lv = 3, Var = ACH_LEVEL_PLAYER, Count = 30, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_30104] = { ID = ACHIEVEMENT_30104, Name = LG_ACHIEVEMENT_NAME_164100013, Desc = LG_ACHIEVEMENT_DESC_164200130, Class = 3, Mode = 1, Lv = 4, Var = ACH_LEVEL_PLAYER, Count = 40, Point = 10, Reward = {{"res",6,500,10000}},},
	[ACHIEVEMENT_30105] = { ID = ACHIEVEMENT_30105, Name = LG_ACHIEVEMENT_NAME_164100013, Desc = LG_ACHIEVEMENT_DESC_164200130, Class = 3, Mode = 1, Lv = 5, Var = ACH_LEVEL_PLAYER, Count = 50, Point = 15, Reward = {{"res",6,1300,10000}},},
	[ACHIEVEMENT_30201] = { ID = ACHIEVEMENT_30201, Name = LG_ACHIEVEMENT_NAME_164100014, Desc = LG_ACHIEVEMENT_DESC_164200140, Class = 3, Mode = 2, Lv = 1, Var = ACH_COUNT_SIGNIN, Count = 1, Point = 3, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_30202] = { ID = ACHIEVEMENT_30202, Name = LG_ACHIEVEMENT_NAME_164100014, Desc = LG_ACHIEVEMENT_DESC_164200140, Class = 3, Mode = 2, Lv = 2, Var = ACH_COUNT_SIGNIN, Count = 7, Point = 3, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30203] = { ID = ACHIEVEMENT_30203, Name = LG_ACHIEVEMENT_NAME_164100014, Desc = LG_ACHIEVEMENT_DESC_164200140, Class = 3, Mode = 2, Lv = 3, Var = ACH_COUNT_SIGNIN, Count = 30, Point = 6, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30204] = { ID = ACHIEVEMENT_30204, Name = LG_ACHIEVEMENT_NAME_164100014, Desc = LG_ACHIEVEMENT_DESC_164200140, Class = 3, Mode = 2, Lv = 4, Var = ACH_COUNT_SIGNIN, Count = 90, Point = 6, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_30205] = { ID = ACHIEVEMENT_30205, Name = LG_ACHIEVEMENT_NAME_164100014, Desc = LG_ACHIEVEMENT_DESC_164200140, Class = 3, Mode = 2, Lv = 5, Var = ACH_COUNT_SIGNIN, Count = 180, Point = 9, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_30206] = { ID = ACHIEVEMENT_30206, Name = LG_ACHIEVEMENT_NAME_164100014, Desc = LG_ACHIEVEMENT_DESC_164200140, Class = 3, Mode = 2, Lv = 6, Var = ACH_COUNT_SIGNIN, Count = 300, Point = 9, Reward = {{"res",6,600,10000}},},
	[ACHIEVEMENT_30301] = { ID = ACHIEVEMENT_30301, Name = LG_ACHIEVEMENT_NAME_164100015, Desc = LG_ACHIEVEMENT_DESC_164200150, Class = 3, Mode = 3, Lv = 1, Var = ACH_COUNT_BUY_RES, Count = 10, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_30302] = { ID = ACHIEVEMENT_30302, Name = LG_ACHIEVEMENT_NAME_164100015, Desc = LG_ACHIEVEMENT_DESC_164200150, Class = 3, Mode = 3, Lv = 2, Var = ACH_COUNT_BUY_RES, Count = 50, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30303] = { ID = ACHIEVEMENT_30303, Name = LG_ACHIEVEMENT_NAME_164100015, Desc = LG_ACHIEVEMENT_DESC_164200150, Class = 3, Mode = 3, Lv = 3, Var = ACH_COUNT_BUY_RES, Count = 250, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30304] = { ID = ACHIEVEMENT_30304, Name = LG_ACHIEVEMENT_NAME_164100015, Desc = LG_ACHIEVEMENT_DESC_164200150, Class = 3, Mode = 3, Lv = 4, Var = ACH_COUNT_BUY_RES, Count = 1000, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_30305] = { ID = ACHIEVEMENT_30305, Name = LG_ACHIEVEMENT_NAME_164100015, Desc = LG_ACHIEVEMENT_DESC_164200150, Class = 3, Mode = 3, Lv = 5, Var = ACH_COUNT_BUY_RES, Count = 5000, Point = 15, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_30306] = { ID = ACHIEVEMENT_30306, Name = LG_ACHIEVEMENT_NAME_164100015, Desc = LG_ACHIEVEMENT_DESC_164200150, Class = 3, Mode = 3, Lv = 6, Var = ACH_COUNT_BUY_RES, Count = 30000, Point = 15, Reward = {{"res",6,2000,10000}},},
	[ACHIEVEMENT_30401] = { ID = ACHIEVEMENT_30401, Name = LG_ACHIEVEMENT_NAME_164100016, Desc = LG_ACHIEVEMENT_DESC_164200160, Class = 3, Mode = 4, Lv = 1, Var = ACH_COUNT_DAILY_REWARD, Count = 20, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_30402] = { ID = ACHIEVEMENT_30402, Name = LG_ACHIEVEMENT_NAME_164100016, Desc = LG_ACHIEVEMENT_DESC_164200160, Class = 3, Mode = 4, Lv = 2, Var = ACH_COUNT_DAILY_REWARD, Count = 100, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30403] = { ID = ACHIEVEMENT_30403, Name = LG_ACHIEVEMENT_NAME_164100016, Desc = LG_ACHIEVEMENT_DESC_164200160, Class = 3, Mode = 4, Lv = 3, Var = ACH_COUNT_DAILY_REWARD, Count = 300, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30404] = { ID = ACHIEVEMENT_30404, Name = LG_ACHIEVEMENT_NAME_164100016, Desc = LG_ACHIEVEMENT_DESC_164200160, Class = 3, Mode = 4, Lv = 4, Var = ACH_COUNT_DAILY_REWARD, Count = 1000, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_30405] = { ID = ACHIEVEMENT_30405, Name = LG_ACHIEVEMENT_NAME_164100016, Desc = LG_ACHIEVEMENT_DESC_164200160, Class = 3, Mode = 4, Lv = 5, Var = ACH_COUNT_DAILY_REWARD, Count = 3000, Point = 15, Reward = {{"res",6,600,10000}},},
	[ACHIEVEMENT_30406] = { ID = ACHIEVEMENT_30406, Name = LG_ACHIEVEMENT_NAME_164100016, Desc = LG_ACHIEVEMENT_DESC_164200160, Class = 3, Mode = 4, Lv = 6, Var = ACH_COUNT_DAILY_REWARD, Count = 10000, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_30501] = { ID = ACHIEVEMENT_30501, Name = LG_ACHIEVEMENT_NAME_164100017, Desc = LG_ACHIEVEMENT_DESC_164200171, Class = 3, Mode = 5, Lv = 1, Var = ACH_EQUIP_QUALITY_1, Count = 6, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_30502] = { ID = ACHIEVEMENT_30502, Name = LG_ACHIEVEMENT_NAME_164100017, Desc = LG_ACHIEVEMENT_DESC_164200172, Class = 3, Mode = 5, Lv = 2, Var = ACH_EQUIP_QUALITY_2, Count = 6, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30503] = { ID = ACHIEVEMENT_30503, Name = LG_ACHIEVEMENT_NAME_164100017, Desc = LG_ACHIEVEMENT_DESC_164200173, Class = 3, Mode = 5, Lv = 3, Var = ACH_EQUIP_QUALITY_3, Count = 6, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30504] = { ID = ACHIEVEMENT_30504, Name = LG_ACHIEVEMENT_NAME_164100017, Desc = LG_ACHIEVEMENT_DESC_164200174, Class = 3, Mode = 5, Lv = 4, Var = ACH_EQUIP_QUALITY_4, Count = 6, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30505] = { ID = ACHIEVEMENT_30505, Name = LG_ACHIEVEMENT_NAME_164100017, Desc = LG_ACHIEVEMENT_DESC_164200175, Class = 3, Mode = 5, Lv = 5, Var = ACH_EQUIP_QUALITY_5, Count = 6, Point = 15, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_30506] = { ID = ACHIEVEMENT_30506, Name = LG_ACHIEVEMENT_NAME_164100017, Desc = LG_ACHIEVEMENT_DESC_164200176, Class = 3, Mode = 5, Lv = 6, Var = ACH_EQUIP_QUALITY_6, Count = 6, Point = 15, Reward = {{"res",6,1300,10000}},},
	[ACHIEVEMENT_30601] = { ID = ACHIEVEMENT_30601, Name = LG_ACHIEVEMENT_NAME_164100018, Desc = LG_ACHIEVEMENT_DESC_164200180, Class = 3, Mode = 6, Lv = 1, Var = ACH_COUNT_GACHA, Count = 100, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_30602] = { ID = ACHIEVEMENT_30602, Name = LG_ACHIEVEMENT_NAME_164100018, Desc = LG_ACHIEVEMENT_DESC_164200180, Class = 3, Mode = 6, Lv = 2, Var = ACH_COUNT_GACHA, Count = 1000, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_30603] = { ID = ACHIEVEMENT_30603, Name = LG_ACHIEVEMENT_NAME_164100018, Desc = LG_ACHIEVEMENT_DESC_164200180, Class = 3, Mode = 6, Lv = 3, Var = ACH_COUNT_GACHA, Count = 4000, Point = 10, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_30604] = { ID = ACHIEVEMENT_30604, Name = LG_ACHIEVEMENT_NAME_164100018, Desc = LG_ACHIEVEMENT_DESC_164200180, Class = 3, Mode = 6, Lv = 4, Var = ACH_COUNT_GACHA, Count = 10000, Point = 10, Reward = {{"res",6,700,10000}},},
	[ACHIEVEMENT_30605] = { ID = ACHIEVEMENT_30605, Name = LG_ACHIEVEMENT_NAME_164100018, Desc = LG_ACHIEVEMENT_DESC_164200180, Class = 3, Mode = 6, Lv = 5, Var = ACH_COUNT_GACHA, Count = 25000, Point = 15, Reward = {{"res",6,1200,10000}},},
	[ACHIEVEMENT_30606] = { ID = ACHIEVEMENT_30606, Name = LG_ACHIEVEMENT_NAME_164100018, Desc = LG_ACHIEVEMENT_DESC_164200180, Class = 3, Mode = 6, Lv = 6, Var = ACH_COUNT_GACHA, Count = 50000, Point = 15, Reward = {{"res",6,1700,10000}},},
	[ACHIEVEMENT_40101] = { ID = ACHIEVEMENT_40101, Name = LG_ACHIEVEMENT_NAME_164100019, Desc = LG_ACHIEVEMENT_DESC_164200190, Class = 4, Mode = 1, Lv = 1, Var = ACH_NUM_HERO, Count = 4, Point = 4, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_40102] = { ID = ACHIEVEMENT_40102, Name = LG_ACHIEVEMENT_NAME_164100019, Desc = LG_ACHIEVEMENT_DESC_164200190, Class = 4, Mode = 1, Lv = 2, Var = ACH_NUM_HERO, Count = 10, Point = 4, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40103] = { ID = ACHIEVEMENT_40103, Name = LG_ACHIEVEMENT_NAME_164100019, Desc = LG_ACHIEVEMENT_DESC_164200190, Class = 4, Mode = 1, Lv = 3, Var = ACH_NUM_HERO, Count = 20, Point = 8, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40104] = { ID = ACHIEVEMENT_40104, Name = LG_ACHIEVEMENT_NAME_164100019, Desc = LG_ACHIEVEMENT_DESC_164200190, Class = 4, Mode = 1, Lv = 4, Var = ACH_NUM_HERO, Count = 30, Point = 8, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_40105] = { ID = ACHIEVEMENT_40105, Name = LG_ACHIEVEMENT_NAME_164100019, Desc = LG_ACHIEVEMENT_DESC_164200190, Class = 4, Mode = 1, Lv = 5, Var = ACH_NUM_HERO, Count = 50, Point = 12, Reward = {{"res",6,500,10000}},},
	[ACHIEVEMENT_40106] = { ID = ACHIEVEMENT_40106, Name = LG_ACHIEVEMENT_NAME_164100019, Desc = LG_ACHIEVEMENT_DESC_164200190, Class = 4, Mode = 1, Lv = 6, Var = ACH_NUM_HERO, Count = 100, Point = 12, Reward = {{"res",6,1600,10000}},},
	[ACHIEVEMENT_40201] = { ID = ACHIEVEMENT_40201, Name = LG_ACHIEVEMENT_NAME_164100020, Desc = LG_ACHIEVEMENT_DESC_164200200, Class = 4, Mode = 2, Lv = 1, Var = ACH_COUNT_KILL_HERO, Count = 1, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_40202] = { ID = ACHIEVEMENT_40202, Name = LG_ACHIEVEMENT_NAME_164100020, Desc = LG_ACHIEVEMENT_DESC_164200200, Class = 4, Mode = 2, Lv = 2, Var = ACH_COUNT_KILL_HERO, Count = 10, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40203] = { ID = ACHIEVEMENT_40203, Name = LG_ACHIEVEMENT_NAME_164100020, Desc = LG_ACHIEVEMENT_DESC_164200200, Class = 4, Mode = 2, Lv = 3, Var = ACH_COUNT_KILL_HERO, Count = 100, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_40204] = { ID = ACHIEVEMENT_40204, Name = LG_ACHIEVEMENT_NAME_164100020, Desc = LG_ACHIEVEMENT_DESC_164200200, Class = 4, Mode = 2, Lv = 4, Var = ACH_COUNT_KILL_HERO, Count = 400, Point = 10, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_40205] = { ID = ACHIEVEMENT_40205, Name = LG_ACHIEVEMENT_NAME_164100020, Desc = LG_ACHIEVEMENT_DESC_164200200, Class = 4, Mode = 2, Lv = 5, Var = ACH_COUNT_KILL_HERO, Count = 1000, Point = 15, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_40206] = { ID = ACHIEVEMENT_40206, Name = LG_ACHIEVEMENT_NAME_164100020, Desc = LG_ACHIEVEMENT_DESC_164200200, Class = 4, Mode = 2, Lv = 6, Var = ACH_COUNT_KILL_HERO, Count = 5000, Point = 15, Reward = {{"res",6,1400,10000}},},
	[ACHIEVEMENT_40301] = { ID = ACHIEVEMENT_40301, Name = LG_ACHIEVEMENT_NAME_164100021, Desc = LG_ACHIEVEMENT_DESC_164200211, Class = 4, Mode = 3, Lv = 1, Var = ACH_HERO_QUALITY_1, Count = 4, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_40302] = { ID = ACHIEVEMENT_40302, Name = LG_ACHIEVEMENT_NAME_164100021, Desc = LG_ACHIEVEMENT_DESC_164200212, Class = 4, Mode = 3, Lv = 2, Var = ACH_HERO_QUALITY_2, Count = 4, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40303] = { ID = ACHIEVEMENT_40303, Name = LG_ACHIEVEMENT_NAME_164100021, Desc = LG_ACHIEVEMENT_DESC_164200213, Class = 4, Mode = 3, Lv = 3, Var = ACH_HERO_QUALITY_3, Count = 4, Point = 10, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40304] = { ID = ACHIEVEMENT_40304, Name = LG_ACHIEVEMENT_NAME_164100021, Desc = LG_ACHIEVEMENT_DESC_164200214, Class = 4, Mode = 3, Lv = 4, Var = ACH_HERO_QUALITY_4, Count = 4, Point = 10, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_40305] = { ID = ACHIEVEMENT_40305, Name = LG_ACHIEVEMENT_NAME_164100021, Desc = LG_ACHIEVEMENT_DESC_164200215, Class = 4, Mode = 3, Lv = 5, Var = ACH_HERO_QUALITY_5, Count = 4, Point = 15, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_40306] = { ID = ACHIEVEMENT_40306, Name = LG_ACHIEVEMENT_NAME_164100021, Desc = LG_ACHIEVEMENT_DESC_164200216, Class = 4, Mode = 3, Lv = 6, Var = ACH_HERO_QUALITY_6, Count = 4, Point = 15, Reward = {{"res",6,800,10000}},},
	[ACHIEVEMENT_40401] = { ID = ACHIEVEMENT_40401, Name = LG_ACHIEVEMENT_NAME_164100022, Desc = LG_ACHIEVEMENT_DESC_164200221, Class = 4, Mode = 4, Lv = 1, Var = ACH_HERO_LEVEL_1, Count = 4, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_40402] = { ID = ACHIEVEMENT_40402, Name = LG_ACHIEVEMENT_NAME_164100022, Desc = LG_ACHIEVEMENT_DESC_164200222, Class = 4, Mode = 4, Lv = 2, Var = ACH_HERO_LEVEL_2, Count = 4, Point = 5, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40403] = { ID = ACHIEVEMENT_40403, Name = LG_ACHIEVEMENT_NAME_164100022, Desc = LG_ACHIEVEMENT_DESC_164200223, Class = 4, Mode = 4, Lv = 3, Var = ACH_HERO_LEVEL_3, Count = 4, Point = 10, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_40404] = { ID = ACHIEVEMENT_40404, Name = LG_ACHIEVEMENT_NAME_164100022, Desc = LG_ACHIEVEMENT_DESC_164200224, Class = 4, Mode = 4, Lv = 4, Var = ACH_HERO_LEVEL_4, Count = 4, Point = 10, Reward = {{"res",6,600,10000}},},
	[ACHIEVEMENT_40405] = { ID = ACHIEVEMENT_40405, Name = LG_ACHIEVEMENT_NAME_164100022, Desc = LG_ACHIEVEMENT_DESC_164200225, Class = 4, Mode = 4, Lv = 5, Var = ACH_HERO_LEVEL_5, Count = 4, Point = 15, Reward = {{"res",6,1300,10000}},},
	[ACHIEVEMENT_40501] = { ID = ACHIEVEMENT_40501, Name = LG_ACHIEVEMENT_NAME_164100023, Desc = LG_ACHIEVEMENT_DESC_164200231, Class = 4, Mode = 5, Lv = 1, Var = ACH_HERO_SKILL_1, Count = 4, Point = 6, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_40502] = { ID = ACHIEVEMENT_40502, Name = LG_ACHIEVEMENT_NAME_164100023, Desc = LG_ACHIEVEMENT_DESC_164200232, Class = 4, Mode = 5, Lv = 2, Var = ACH_HERO_SKILL_2, Count = 4, Point = 6, Reward = {{"res",6,100,10000}},},
	[ACHIEVEMENT_40503] = { ID = ACHIEVEMENT_40503, Name = LG_ACHIEVEMENT_NAME_164100023, Desc = LG_ACHIEVEMENT_DESC_164200233, Class = 4, Mode = 5, Lv = 3, Var = ACH_HERO_SKILL_3, Count = 4, Point = 12, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_40504] = { ID = ACHIEVEMENT_40504, Name = LG_ACHIEVEMENT_NAME_164100023, Desc = LG_ACHIEVEMENT_DESC_164200234, Class = 4, Mode = 5, Lv = 4, Var = ACH_HERO_SKILL_4, Count = 4, Point = 12, Reward = {{"res",6,400,10000}},},
	[ACHIEVEMENT_40505] = { ID = ACHIEVEMENT_40505, Name = LG_ACHIEVEMENT_NAME_164100023, Desc = LG_ACHIEVEMENT_DESC_164200235, Class = 4, Mode = 5, Lv = 5, Var = ACH_HERO_SKILL_5, Count = 4, Point = 18, Reward = {{"res",6,700,10000}},},
	[ACHIEVEMENT_40506] = { ID = ACHIEVEMENT_40506, Name = LG_ACHIEVEMENT_NAME_164100023, Desc = LG_ACHIEVEMENT_DESC_164200236, Class = 4, Mode = 5, Lv = 6, Var = ACH_HERO_SKILL_6, Count = 4, Point = 18, Reward = {{"res",6,1300,10000}},},
	[ACHIEVEMENT_40601] = { ID = ACHIEVEMENT_40601, Name = LG_ACHIEVEMENT_NAME_164100024, Desc = LG_ACHIEVEMENT_DESC_164200241, Class = 4, Mode = 6, Lv = 1, Var = ACH_HERO_STAR_2, Count = 4, Point = 5, Reward = {{"res",6,50,10000}},},
	[ACHIEVEMENT_40602] = { ID = ACHIEVEMENT_40602, Name = LG_ACHIEVEMENT_NAME_164100024, Desc = LG_ACHIEVEMENT_DESC_164200242, Class = 4, Mode = 6, Lv = 2, Var = ACH_HERO_STAR_3, Count = 4, Point = 5, Reward = {{"res",6,200,10000}},},
	[ACHIEVEMENT_40603] = { ID = ACHIEVEMENT_40603, Name = LG_ACHIEVEMENT_NAME_164100024, Desc = LG_ACHIEVEMENT_DESC_164200243, Class = 4, Mode = 6, Lv = 3, Var = ACH_HERO_STAR_4, Count = 4, Point = 10, Reward = {{"res",6,300,10000}},},
	[ACHIEVEMENT_40604] = { ID = ACHIEVEMENT_40604, Name = LG_ACHIEVEMENT_NAME_164100024, Desc = LG_ACHIEVEMENT_DESC_164200244, Class = 4, Mode = 6, Lv = 4, Var = ACH_HERO_STAR_5, Count = 4, Point = 10, Reward = {{"res",6,900,10000}},},
	[ACHIEVEMENT_40605] = { ID = ACHIEVEMENT_40605, Name = LG_ACHIEVEMENT_NAME_164100024, Desc = LG_ACHIEVEMENT_DESC_164200245, Class = 4, Mode = 6, Lv = 5, Var = ACH_HERO_STAR_6, Count = 4, Point = 15, Reward = {{"res",6,1400,10000}},},
}