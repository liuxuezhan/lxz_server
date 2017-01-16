--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_month_award = {

	[MONTH_AWARD_1] = { ID = MONTH_AWARD_1, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",8,50000,10000}}, Extra = {1,2},},
	[MONTH_AWARD_2] = { ID = MONTH_AWARD_2, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",8001001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_3] = { ID = MONTH_AWARD_3, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",6,150,10000}}, Extra = nil,},
	[MONTH_AWARD_4] = { ID = MONTH_AWARD_4, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",1002005,1,10000}}, Extra = {2,2},},
	[MONTH_AWARD_5] = { ID = MONTH_AWARD_5, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",8004001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_6] = { ID = MONTH_AWARD_6, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",3002002,2,10000}}, Extra = nil,},
	[MONTH_AWARD_7] = { ID = MONTH_AWARD_7, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",4002016,1,10000}}, Extra = {3,2},},
	[MONTH_AWARD_8] = { ID = MONTH_AWARD_8, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",8,75000,10000}}, Extra = {4,2},},
	[MONTH_AWARD_9] = { ID = MONTH_AWARD_9, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",10002001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_10] = { ID = MONTH_AWARD_10, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",6,150,10000}}, Extra = nil,},
	[MONTH_AWARD_11] = { ID = MONTH_AWARD_11, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",2011002,10,10000}}, Extra = {5,2},},
	[MONTH_AWARD_12] = { ID = MONTH_AWARD_12, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",8003001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_13] = { ID = MONTH_AWARD_13, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",3004002,2,10000}}, Extra = nil,},
	[MONTH_AWARD_14] = { ID = MONTH_AWARD_14, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",4002016,2,10000}}, Extra = {6,2},},
	[MONTH_AWARD_15] = { ID = MONTH_AWARD_15, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",8,100000,10000}}, Extra = {7,2},},
	[MONTH_AWARD_16] = { ID = MONTH_AWARD_16, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",7023002,10,10000}}, Extra = nil,},
	[MONTH_AWARD_17] = { ID = MONTH_AWARD_17, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",6,200,10000}}, Extra = nil,},
	[MONTH_AWARD_18] = { ID = MONTH_AWARD_18, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",1002006,1,10000}}, Extra = nil,},
	[MONTH_AWARD_19] = { ID = MONTH_AWARD_19, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",7014001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_20] = { ID = MONTH_AWARD_20, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",3005002,2,10000}}, Extra = nil,},
	[MONTH_AWARD_21] = { ID = MONTH_AWARD_21, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",4002016,3,10000}}, Extra = {8,2},},
	[MONTH_AWARD_22] = { ID = MONTH_AWARD_22, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",8,125000,10000}}, Extra = {9,2},},
	[MONTH_AWARD_23] = { ID = MONTH_AWARD_23, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",8006002,1,10000}}, Extra = nil,},
	[MONTH_AWARD_24] = { ID = MONTH_AWARD_24, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"res",6,250,10000}}, Extra = nil,},
	[MONTH_AWARD_25] = { ID = MONTH_AWARD_25, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",2011002,15,10000}}, Extra = nil,},
	[MONTH_AWARD_26] = { ID = MONTH_AWARD_26, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",8002002,1,10000}}, Extra = nil,},
	[MONTH_AWARD_27] = { ID = MONTH_AWARD_27, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"item",3001002,2,10000}}, Extra = nil,},
	[MONTH_AWARD_28] = { ID = MONTH_AWARD_28, Month = 1, BonusPolicy = "mutex_award", Bonus = {{"hero",16,1,10000}}, Extra = {10,2},},
	[MONTH_AWARD_29] = { ID = MONTH_AWARD_29, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",8,50000,10000}}, Extra = {1,2},},
	[MONTH_AWARD_30] = { ID = MONTH_AWARD_30, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",8001001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_31] = { ID = MONTH_AWARD_31, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",6,200,10000}}, Extra = nil,},
	[MONTH_AWARD_32] = { ID = MONTH_AWARD_32, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",8004001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_33] = { ID = MONTH_AWARD_33, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",2011002,15,10000}}, Extra = {2,2},},
	[MONTH_AWARD_34] = { ID = MONTH_AWARD_34, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",3004002,1,10000}}, Extra = nil,},
	[MONTH_AWARD_35] = { ID = MONTH_AWARD_35, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",4002011,5,10000}}, Extra = {3,2},},
	[MONTH_AWARD_36] = { ID = MONTH_AWARD_36, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",8,75000,10000}}, Extra = {4,2},},
	[MONTH_AWARD_37] = { ID = MONTH_AWARD_37, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",8006002,1,10000}}, Extra = nil,},
	[MONTH_AWARD_38] = { ID = MONTH_AWARD_38, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",6,300,10000}}, Extra = nil,},
	[MONTH_AWARD_39] = { ID = MONTH_AWARD_39, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",8003001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_40] = { ID = MONTH_AWARD_40, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",2011002,15,10000}}, Extra = {5,2},},
	[MONTH_AWARD_41] = { ID = MONTH_AWARD_41, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",3005002,1,10000}}, Extra = nil,},
	[MONTH_AWARD_42] = { ID = MONTH_AWARD_42, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",4002011,5,10000}}, Extra = {6,2},},
	[MONTH_AWARD_43] = { ID = MONTH_AWARD_43, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",8,100000,10000}}, Extra = {7,2},},
	[MONTH_AWARD_44] = { ID = MONTH_AWARD_44, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",1002006,1,10000}}, Extra = nil,},
	[MONTH_AWARD_45] = { ID = MONTH_AWARD_45, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",6,200,10000}}, Extra = nil,},
	[MONTH_AWARD_46] = { ID = MONTH_AWARD_46, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",7014001,1,10000}}, Extra = nil,},
	[MONTH_AWARD_47] = { ID = MONTH_AWARD_47, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",2011002,20,10000}}, Extra = {8,2},},
	[MONTH_AWARD_48] = { ID = MONTH_AWARD_48, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",3004002,2,10000}}, Extra = nil,},
	[MONTH_AWARD_49] = { ID = MONTH_AWARD_49, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",4002016,5,10000}}, Extra = {9,2},},
	[MONTH_AWARD_50] = { ID = MONTH_AWARD_50, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",8,125000,10000}}, Extra = {10,2},},
	[MONTH_AWARD_51] = { ID = MONTH_AWARD_51, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",1001006,1,10000}}, Extra = nil,},
	[MONTH_AWARD_52] = { ID = MONTH_AWARD_52, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"res",6,300,10000}}, Extra = nil,},
	[MONTH_AWARD_53] = { ID = MONTH_AWARD_53, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",8002002,1,10000}}, Extra = nil,},
	[MONTH_AWARD_54] = { ID = MONTH_AWARD_54, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",2011002,20,10000}}, Extra = {11,2},},
	[MONTH_AWARD_55] = { ID = MONTH_AWARD_55, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",3005002,2,10000}}, Extra = nil,},
	[MONTH_AWARD_56] = { ID = MONTH_AWARD_56, Month = 2, BonusPolicy = "mutex_award", Bonus = {{"item",4002016,5,10000}}, Extra = {12,2},},
}
