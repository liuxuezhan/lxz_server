--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_world_events = {

	[WORLD_EVENT_1] = { ID = WORLD_EVENT_1, TITLE = WE_TITLE_1, DESC = WE_DESC_1, UnlockEvent = LG_NIL, FinishScore = 1, UnlockScore = 0, TmOpenServer = 0, Bonus = {"mutex_award",{{"res",6,100,10000}}}, FinishCondition = {"castle_level",10,3}, OpenMail = nil, Notify = nil,},
	[WORLD_EVENT_2] = { ID = WORLD_EVENT_2, TITLE = WE_TITLE_2, DESC = WE_DESC_2, UnlockEvent = LG_NIL, FinishScore = 1, UnlockScore = 0, TmOpenServer = 0, Bonus = {"mutex_award",{{"res",8,20000,10000}}}, FinishCondition = {"monster_point",300}, OpenMail = nil, Notify = nil,},
	[WORLD_EVENT_3] = { ID = WORLD_EVENT_3, TITLE = WE_TITLE_3, DESC = WE_DESC_3, UnlockEvent = LG_NIL, FinishScore = 3, UnlockScore = 0, TmOpenServer = 0, Bonus = {"mutex_award",{{"res",2,50000,10000}}}, FinishCondition = {"occupy_city",4,2}, OpenMail = nil, Notify = nil,},
	[WORLD_EVENT_4] = { ID = WORLD_EVENT_4, TITLE = WE_TITLE_4, DESC = WE_DESC_4, UnlockEvent = WE_TITLE_3, FinishScore = 6, UnlockScore = 3, TmOpenServer = 172800, Bonus = {"mutex_award",{{"item",3002002,1,10000}}}, FinishCondition = {"hero_num",4,30}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_5] = { ID = WORLD_EVENT_5, TITLE = WE_TITLE_5, DESC = WE_DESC_5, UnlockEvent = WE_TITLE_4, FinishScore = 12, UnlockScore = 6, TmOpenServer = 259200, Bonus = {"mutex_award",{{"item",7018001,1,10000}}}, FinishCondition = {"occupy_city",3,2}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_6] = { ID = WORLD_EVENT_6, TITLE = WE_TITLE_6, DESC = WE_DESC_6, UnlockEvent = WE_TITLE_5, FinishScore = 24, UnlockScore = 12, TmOpenServer = 518400, Bonus = {"mutex_award",{{"item",20001002,1,10000}}}, FinishCondition = {"panjun_kill",200000000}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_7] = { ID = WORLD_EVENT_7, TITLE = WE_TITLE_7, DESC = WE_DESC_7, UnlockEvent = WE_TITLE_6, FinishScore = 48, UnlockScore = 24, TmOpenServer = 691200, Bonus = {"mutex_award",{{"item",7014001,1,10000}}}, FinishCondition = {"monster_point",1300}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_8] = { ID = WORLD_EVENT_8, TITLE = WE_TITLE_8, DESC = WE_DESC_8, UnlockEvent = WE_TITLE_7, FinishScore = 96, UnlockScore = 48, TmOpenServer = 864000, Bonus = {"mutex_award",{{"item",10002001,1,10000}}}, FinishCondition = {"occupy_city",2,2}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_9] = { ID = WORLD_EVENT_9, TITLE = WE_TITLE_9, DESC = WE_DESC_9, UnlockEvent = WE_TITLE_8, FinishScore = 192, UnlockScore = 96, TmOpenServer = 1036800, Bonus = {"mutex_award",{{"item",8002002,1,10000}}}, FinishCondition = {"cure_soldier",4000000}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_10] = { ID = WORLD_EVENT_10, TITLE = WE_TITLE_10, DESC = WE_DESC_10, UnlockEvent = WE_TITLE_9, FinishScore = 384, UnlockScore = 192, TmOpenServer = 1296000, Bonus = {"mutex_award",{{"item",7023007,3,10000}}}, FinishCondition = {"monster_point",14000}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_11] = { ID = WORLD_EVENT_11, TITLE = WE_TITLE_11, DESC = WE_DESC_11, UnlockEvent = WE_TITLE_10, FinishScore = 768, UnlockScore = 384, TmOpenServer = 1728000, Bonus = {"mutex_award",{{"item",7014002,1,10000}}}, FinishCondition = {"union_halltech_lv",10706,1}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_12] = { ID = WORLD_EVENT_12, TITLE = WE_TITLE_12, DESC = WE_DESC_12, UnlockEvent = WE_TITLE_11, FinishScore = 1536, UnlockScore = 768, TmOpenServer = 2160000, Bonus = {"mutex_award",{{"item",7023002,25,10000}}}, FinishCondition = {"gather_num",20,5000000}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_13] = { ID = WORLD_EVENT_13, TITLE = WE_TITLE_13, DESC = WE_DESC_13, UnlockEvent = WE_TITLE_12, FinishScore = 3072, UnlockScore = 1536, TmOpenServer = 2592000, Bonus = {"mutex_award",{{"item",8006001,1,10000}}}, FinishCondition = {"occupy_city",1,2}, OpenMail = 10033, Notify = 60373,},
	[WORLD_EVENT_14] = { ID = WORLD_EVENT_14, TITLE = WE_TITLE_14, DESC = WE_DESC_14, UnlockEvent = WE_TITLE_13, FinishScore = 6144, UnlockScore = 3072, TmOpenServer = 2592000, Bonus = {"mutex_award",{{"item",7023002,25,10000}}}, FinishCondition = {"occupy_king_city",1}, OpenMail = 10033, Notify = 60373,},
}
