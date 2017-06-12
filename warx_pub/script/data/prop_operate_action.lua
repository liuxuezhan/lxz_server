--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_operate_action = {

	[OPERATE_ACTION_1] = { ID = OPERATE_ACTION_1, Action = {"gacha",2}, Num = 2, Score = 0, Bonus = {"mutex_award",{{"soldier",4004,100,10000},{"res",2,100000,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100000,},
	[OPERATE_ACTION_2] = { ID = OPERATE_ACTION_2, Action = {"gacha",1}, Num = 30, Score = 0, Bonus = {"mutex_award",{{"soldier",3004,100,10000},{"res",2,100000,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100001,},
	[OPERATE_ACTION_3] = { ID = OPERATE_ACTION_3, Action = {"black_market"}, Num = 20, Score = 0, Bonus = {"mutex_award",{{"soldier",2004,100,10000},{"res",1,100000,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100002,},
	[OPERATE_ACTION_4] = { ID = OPERATE_ACTION_4, Action = {"resource_market"}, Num = 5, Score = 0, Bonus = {"mutex_award",{{"soldier",1004,100,10000},{"res",1,100000,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100003,},
	[OPERATE_ACTION_7] = { ID = OPERATE_ACTION_7, Action = {"kill_soldier",1}, Num = nil, Score = 5, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_8] = { ID = OPERATE_ACTION_8, Action = {"kill_soldier",2}, Num = nil, Score = 10, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_9] = { ID = OPERATE_ACTION_9, Action = {"kill_soldier",3}, Num = nil, Score = 20, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_10] = { ID = OPERATE_ACTION_10, Action = {"kill_soldier",4}, Num = nil, Score = 37, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_11] = { ID = OPERATE_ACTION_11, Action = {"kill_soldier",5}, Num = nil, Score = 65, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_12] = { ID = OPERATE_ACTION_12, Action = {"kill_soldier",6}, Num = nil, Score = 108, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_13] = { ID = OPERATE_ACTION_13, Action = {"kill_soldier",7}, Num = nil, Score = 169, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_14] = { ID = OPERATE_ACTION_14, Action = {"kill_soldier",8}, Num = nil, Score = 252, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_15] = { ID = OPERATE_ACTION_15, Action = {"kill_soldier",9}, Num = nil, Score = 363, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_16] = { ID = OPERATE_ACTION_16, Action = {"kill_soldier",10}, Num = nil, Score = 507, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_17] = { ID = OPERATE_ACTION_17, Action = {"occupy_city",4}, Num = nil, Score = 500, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_18] = { ID = OPERATE_ACTION_18, Action = {"occupy_city",3}, Num = nil, Score = 2000, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_19] = { ID = OPERATE_ACTION_19, Action = {"occupy_city",2}, Num = nil, Score = 10000, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_20] = { ID = OPERATE_ACTION_20, Action = {"occupy_city",1}, Num = nil, Score = 50000, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_21] = { ID = OPERATE_ACTION_21, Action = {"union_fight",10000}, Num = nil, Score = 1, Bonus = nil, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_NIL,},
	[OPERATE_ACTION_22] = { ID = OPERATE_ACTION_22, Action = {"collect_grade_hero",4}, Num = 1, Score = 0, Bonus = {"mutex_award",{{"item",5001304,1,10000},{"res",6,100,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100004,},
	[OPERATE_ACTION_23] = { ID = OPERATE_ACTION_23, Action = {"collect_grade_hero",4}, Num = 2, Score = 0, Bonus = {"mutex_award",{{"item",2012031,1,10000},{"res",6,200,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100005,},
	[OPERATE_ACTION_24] = { ID = OPERATE_ACTION_24, Action = {"collect_grade_hero",4}, Num = 3, Score = 0, Bonus = {"mutex_award",{{"item",2012036,1,10000},{"res",6,400,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100006,},
	[OPERATE_ACTION_25] = { ID = OPERATE_ACTION_25, Action = {"collect_grade_hero",4}, Num = 4, Score = 0, Bonus = {"mutex_award",{{"item",2012032,1,10000},{"res",6,600,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100007,},
	[OPERATE_ACTION_26] = { ID = OPERATE_ACTION_26, Action = {"collect_grade_hero",4}, Num = 5, Score = 0, Bonus = {"mutex_award",{{"item",2012032,1,10000},{"res",6,800,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100008,},
	[OPERATE_ACTION_27] = { ID = OPERATE_ACTION_27, Action = {"collect_grade_hero",3}, Num = 1, Score = 0, Bonus = {"mutex_award",{{"item",2012020,5,10000},{"res",6,50,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100009,},
	[OPERATE_ACTION_28] = { ID = OPERATE_ACTION_28, Action = {"collect_grade_hero",3}, Num = 2, Score = 0, Bonus = {"mutex_award",{{"item",2012025,5,10000},{"res",6,50,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100010,},
	[OPERATE_ACTION_29] = { ID = OPERATE_ACTION_29, Action = {"collect_grade_hero",3}, Num = 3, Score = 0, Bonus = {"mutex_award",{{"item",2012021,5,10000},{"res",6,100,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100011,},
	[OPERATE_ACTION_30] = { ID = OPERATE_ACTION_30, Action = {"collect_grade_hero",3}, Num = 4, Score = 0, Bonus = {"mutex_award",{{"item",2012026,5,10000},{"res",6,100,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100012,},
	[OPERATE_ACTION_31] = { ID = OPERATE_ACTION_31, Action = {"collect_grade_hero",3}, Num = 5, Score = 0, Bonus = {"mutex_award",{{"item",2012031,1,10000},{"res",6,200,10000}}}, Parm1 = nil, Parm2 = nil, Parm3 = nil, Name = LG_OPERATE_ACTION_NAME_175100013,},
}
