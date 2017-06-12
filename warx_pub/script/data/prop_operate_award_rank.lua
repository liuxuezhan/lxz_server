--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_operate_award_rank = {

	[OPERATE_AWARD_RANK_1] = { ID = OPERATE_AWARD_RANK_1, RankRange = {1,1}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,8000,10000}}},},
	[OPERATE_AWARD_RANK_2] = { ID = OPERATE_AWARD_RANK_2, RankRange = {2,2}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,5000,10000}}},},
	[OPERATE_AWARD_RANK_3] = { ID = OPERATE_AWARD_RANK_3, RankRange = {3,3}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,3000,10000}}},},
	[OPERATE_AWARD_RANK_4] = { ID = OPERATE_AWARD_RANK_4, RankRange = {4,4}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,2000,10000}}},},
	[OPERATE_AWARD_RANK_5] = { ID = OPERATE_AWARD_RANK_5, RankRange = {5,5}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,1500,10000}}},},
	[OPERATE_AWARD_RANK_6] = { ID = OPERATE_AWARD_RANK_6, RankRange = {6,6}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,1000,10000}}},},
	[OPERATE_AWARD_RANK_7] = { ID = OPERATE_AWARD_RANK_7, RankRange = {7,7}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,900,10000}}},},
	[OPERATE_AWARD_RANK_8] = { ID = OPERATE_AWARD_RANK_8, RankRange = {8,8}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,800,10000}}},},
	[OPERATE_AWARD_RANK_9] = { ID = OPERATE_AWARD_RANK_9, RankRange = {9,9}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,700,10000}}},},
	[OPERATE_AWARD_RANK_10] = { ID = OPERATE_AWARD_RANK_10, RankRange = {10,10}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,600,10000}}},},
	[OPERATE_AWARD_RANK_11] = { ID = OPERATE_AWARD_RANK_11, RankRange = {11,20}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,500,10000}}},},
	[OPERATE_AWARD_RANK_12] = { ID = OPERATE_AWARD_RANK_12, RankRange = {21,50}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,400,10000}}},},
	[OPERATE_AWARD_RANK_13] = { ID = OPERATE_AWARD_RANK_13, RankRange = {51,100}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,300,10000}}},},
	[OPERATE_AWARD_RANK_14] = { ID = OPERATE_AWARD_RANK_14, RankRange = {101,200}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,200,10000}}},},
	[OPERATE_AWARD_RANK_15] = { ID = OPERATE_AWARD_RANK_15, RankRange = {201,400}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,150,10000}}},},
	[OPERATE_AWARD_RANK_16] = { ID = OPERATE_AWARD_RANK_16, RankRange = {401,1000}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,100,10000}}},},
	[OPERATE_AWARD_RANK_17] = { ID = OPERATE_AWARD_RANK_17, RankRange = {1001,999999}, Mail = 10048, Bonus = {"mutex_award",{{"res",6,50,10000}}},},
	[OPERATE_AWARD_RANK_18] = { ID = OPERATE_AWARD_RANK_18, RankRange = {1,1}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,5000,10000}}},},
	[OPERATE_AWARD_RANK_19] = { ID = OPERATE_AWARD_RANK_19, RankRange = {2,2}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,3000,10000}}},},
	[OPERATE_AWARD_RANK_20] = { ID = OPERATE_AWARD_RANK_20, RankRange = {3,3}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,2000,10000}}},},
	[OPERATE_AWARD_RANK_21] = { ID = OPERATE_AWARD_RANK_21, RankRange = {4,5}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,1000,10000}}},},
	[OPERATE_AWARD_RANK_22] = { ID = OPERATE_AWARD_RANK_22, RankRange = {6,10}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,800,10000}}},},
	[OPERATE_AWARD_RANK_23] = { ID = OPERATE_AWARD_RANK_23, RankRange = {11,20}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,600,10000}}},},
	[OPERATE_AWARD_RANK_24] = { ID = OPERATE_AWARD_RANK_24, RankRange = {21,50}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,400,10000}}},},
	[OPERATE_AWARD_RANK_25] = { ID = OPERATE_AWARD_RANK_25, RankRange = {51,100}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,300,10000}}},},
	[OPERATE_AWARD_RANK_26] = { ID = OPERATE_AWARD_RANK_26, RankRange = {101,200}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,200,10000}}},},
	[OPERATE_AWARD_RANK_27] = { ID = OPERATE_AWARD_RANK_27, RankRange = {201,400}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,150,10000}}},},
	[OPERATE_AWARD_RANK_28] = { ID = OPERATE_AWARD_RANK_28, RankRange = {401,1000}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,100,10000}}},},
	[OPERATE_AWARD_RANK_29] = { ID = OPERATE_AWARD_RANK_29, RankRange = {1001,999999}, Mail = 10049, Bonus = {"mutex_award",{{"res",6,50,10000}}},},
	[OPERATE_AWARD_RANK_30] = { ID = OPERATE_AWARD_RANK_30, RankRange = {1,1}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,1000,10000},{"item",2010083,1,10000}}},},
	[OPERATE_AWARD_RANK_31] = { ID = OPERATE_AWARD_RANK_31, RankRange = {2,2}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,800,10000},{"item",2010082,1,10000}}},},
	[OPERATE_AWARD_RANK_32] = { ID = OPERATE_AWARD_RANK_32, RankRange = {3,3}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,500,10000},{"item",2010081,1,10000}}},},
	[OPERATE_AWARD_RANK_33] = { ID = OPERATE_AWARD_RANK_33, RankRange = {4,5}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,300,10000},{"item",2010080,1,10000}}},},
	[OPERATE_AWARD_RANK_34] = { ID = OPERATE_AWARD_RANK_34, RankRange = {6,10}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,200,10000},{"item",2010080,1,10000}}},},
	[OPERATE_AWARD_RANK_35] = { ID = OPERATE_AWARD_RANK_35, RankRange = {11,20}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,100,10000},{"item",2010080,1,10000}}},},
	[OPERATE_AWARD_RANK_36] = { ID = OPERATE_AWARD_RANK_36, RankRange = {21,50}, Mail = 10050, Bonus = {"mutex_award",{{"res",6,50,10000},{"item",2010079,1,10000}}},},
}
