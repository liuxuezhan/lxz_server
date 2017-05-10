--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_gacha_world_limit = {

	[GACHA_WORLD_LIMIT_1002001] = { ID = GACHA_WORLD_LIMIT_1002001, Limit = 14286000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002002] = { ID = GACHA_WORLD_LIMIT_1002002, Limit = 6260000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002003] = { ID = GACHA_WORLD_LIMIT_1002003, Limit = 289000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002004] = { ID = GACHA_WORLD_LIMIT_1002004, Limit = 160000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002005] = { ID = GACHA_WORLD_LIMIT_1002005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002006] = { ID = GACHA_WORLD_LIMIT_1002006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002007] = { ID = GACHA_WORLD_LIMIT_1002007, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1002008] = { ID = GACHA_WORLD_LIMIT_1002008, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001001] = { ID = GACHA_WORLD_LIMIT_1001001, Limit = 14286000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001002] = { ID = GACHA_WORLD_LIMIT_1001002, Limit = 6260000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001003] = { ID = GACHA_WORLD_LIMIT_1001003, Limit = 289000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001004] = { ID = GACHA_WORLD_LIMIT_1001004, Limit = 160000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001005] = { ID = GACHA_WORLD_LIMIT_1001005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001006] = { ID = GACHA_WORLD_LIMIT_1001006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001007] = { ID = GACHA_WORLD_LIMIT_1001007, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001008] = { ID = GACHA_WORLD_LIMIT_1001008, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003001] = { ID = GACHA_WORLD_LIMIT_1003001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003002] = { ID = GACHA_WORLD_LIMIT_1003002, Limit = 8466000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003003] = { ID = GACHA_WORLD_LIMIT_1003003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003004] = { ID = GACHA_WORLD_LIMIT_1003004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003005] = { ID = GACHA_WORLD_LIMIT_1003005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003006] = { ID = GACHA_WORLD_LIMIT_1003006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003007] = { ID = GACHA_WORLD_LIMIT_1003007, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1003008] = { ID = GACHA_WORLD_LIMIT_1003008, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004001] = { ID = GACHA_WORLD_LIMIT_1004001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004002] = { ID = GACHA_WORLD_LIMIT_1004002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004003] = { ID = GACHA_WORLD_LIMIT_1004003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004004] = { ID = GACHA_WORLD_LIMIT_1004004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004005] = { ID = GACHA_WORLD_LIMIT_1004005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004006] = { ID = GACHA_WORLD_LIMIT_1004006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1004007] = { ID = GACHA_WORLD_LIMIT_1004007, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1005001] = { ID = GACHA_WORLD_LIMIT_1005001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1005002] = { ID = GACHA_WORLD_LIMIT_1005002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1005003] = { ID = GACHA_WORLD_LIMIT_1005003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1005004] = { ID = GACHA_WORLD_LIMIT_1005004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1005005] = { ID = GACHA_WORLD_LIMIT_1005005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7010001] = { ID = GACHA_WORLD_LIMIT_7010001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10002001] = { ID = GACHA_WORLD_LIMIT_10002001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10004001] = { ID = GACHA_WORLD_LIMIT_10004001, Limit = 256000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10004002] = { ID = GACHA_WORLD_LIMIT_10004002, Limit = 228000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10004003] = { ID = GACHA_WORLD_LIMIT_10004003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10004004] = { ID = GACHA_WORLD_LIMIT_10004004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10004005] = { ID = GACHA_WORLD_LIMIT_10004005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10001001] = { ID = GACHA_WORLD_LIMIT_10001001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_10003001] = { ID = GACHA_WORLD_LIMIT_10003001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7014001] = { ID = GACHA_WORLD_LIMIT_7014001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7014002] = { ID = GACHA_WORLD_LIMIT_7014002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7015001] = { ID = GACHA_WORLD_LIMIT_7015001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7016001] = { ID = GACHA_WORLD_LIMIT_7016001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7017001] = { ID = GACHA_WORLD_LIMIT_7017001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7018001] = { ID = GACHA_WORLD_LIMIT_7018001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7019001] = { ID = GACHA_WORLD_LIMIT_7019001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7020001] = { ID = GACHA_WORLD_LIMIT_7020001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7021001] = { ID = GACHA_WORLD_LIMIT_7021001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7022001] = { ID = GACHA_WORLD_LIMIT_7022001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8001001] = { ID = GACHA_WORLD_LIMIT_8001001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8001003] = { ID = GACHA_WORLD_LIMIT_8001003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8006002] = { ID = GACHA_WORLD_LIMIT_8006002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8003001] = { ID = GACHA_WORLD_LIMIT_8003001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8003002] = { ID = GACHA_WORLD_LIMIT_8003002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8004001] = { ID = GACHA_WORLD_LIMIT_8004001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8004002] = { ID = GACHA_WORLD_LIMIT_8004002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8002002] = { ID = GACHA_WORLD_LIMIT_8002002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8002004] = { ID = GACHA_WORLD_LIMIT_8002004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8008001] = { ID = GACHA_WORLD_LIMIT_8008001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8005001] = { ID = GACHA_WORLD_LIMIT_8005001, Limit = 106000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8005002] = { ID = GACHA_WORLD_LIMIT_8005002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8007001] = { ID = GACHA_WORLD_LIMIT_8007001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8007002] = { ID = GACHA_WORLD_LIMIT_8007002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8007003] = { ID = GACHA_WORLD_LIMIT_8007003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8007004] = { ID = GACHA_WORLD_LIMIT_8007004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8009001] = { ID = GACHA_WORLD_LIMIT_8009001, Limit = 46000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8009002] = { ID = GACHA_WORLD_LIMIT_8009002, Limit = 46000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8009003] = { ID = GACHA_WORLD_LIMIT_8009003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_8009004] = { ID = GACHA_WORLD_LIMIT_8009004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3001001] = { ID = GACHA_WORLD_LIMIT_3001001, Limit = 1677000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3001002] = { ID = GACHA_WORLD_LIMIT_3001002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3001003] = { ID = GACHA_WORLD_LIMIT_3001003, Limit = 436000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3002001] = { ID = GACHA_WORLD_LIMIT_3002001, Limit = 5090000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3002002] = { ID = GACHA_WORLD_LIMIT_3002002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3002003] = { ID = GACHA_WORLD_LIMIT_3002003, Limit = 303000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3003001] = { ID = GACHA_WORLD_LIMIT_3003001, Limit = 5270000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3003002] = { ID = GACHA_WORLD_LIMIT_3003002, Limit = 317000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3003003] = { ID = GACHA_WORLD_LIMIT_3003003, Limit = 303000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3004001] = { ID = GACHA_WORLD_LIMIT_3004001, Limit = 5270000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3004002] = { ID = GACHA_WORLD_LIMIT_3004002, Limit = 421000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3004003] = { ID = GACHA_WORLD_LIMIT_3004003, Limit = 57000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3005001] = { ID = GACHA_WORLD_LIMIT_3005001, Limit = 5270000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3005002] = { ID = GACHA_WORLD_LIMIT_3005002, Limit = 421000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_3005003] = { ID = GACHA_WORLD_LIMIT_3005003, Limit = 57000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023001] = { ID = GACHA_WORLD_LIMIT_7023001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023002] = { ID = GACHA_WORLD_LIMIT_7023002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_2007001] = { ID = GACHA_WORLD_LIMIT_2007001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_2011002] = { ID = GACHA_WORLD_LIMIT_2011002, Limit = 394000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_2011003] = { ID = GACHA_WORLD_LIMIT_2011003, Limit = 236000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001021] = { ID = GACHA_WORLD_LIMIT_1001021, Limit = 1933000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001022] = { ID = GACHA_WORLD_LIMIT_1001022, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001023] = { ID = GACHA_WORLD_LIMIT_1001023, Limit = 89000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001024] = { ID = GACHA_WORLD_LIMIT_1001024, Limit = 414000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023005] = { ID = GACHA_WORLD_LIMIT_7023005, Limit = 1143000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023006] = { ID = GACHA_WORLD_LIMIT_7023006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023007] = { ID = GACHA_WORLD_LIMIT_7023007, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023008] = { ID = GACHA_WORLD_LIMIT_7023008, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023009] = { ID = GACHA_WORLD_LIMIT_7023009, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001028] = { ID = GACHA_WORLD_LIMIT_1001028, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001029] = { ID = GACHA_WORLD_LIMIT_1001029, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001030] = { ID = GACHA_WORLD_LIMIT_1001030, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001031] = { ID = GACHA_WORLD_LIMIT_1001031, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001032] = { ID = GACHA_WORLD_LIMIT_1001032, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001033] = { ID = GACHA_WORLD_LIMIT_1001033, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023010] = { ID = GACHA_WORLD_LIMIT_7023010, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023011] = { ID = GACHA_WORLD_LIMIT_7023011, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7023012] = { ID = GACHA_WORLD_LIMIT_7023012, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001034] = { ID = GACHA_WORLD_LIMIT_1001034, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001035] = { ID = GACHA_WORLD_LIMIT_1001035, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001036] = { ID = GACHA_WORLD_LIMIT_1001036, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001037] = { ID = GACHA_WORLD_LIMIT_1001037, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001038] = { ID = GACHA_WORLD_LIMIT_1001038, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_1001039] = { ID = GACHA_WORLD_LIMIT_1001039, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7024001] = { ID = GACHA_WORLD_LIMIT_7024001, Limit = 32000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_4004001] = { ID = GACHA_WORLD_LIMIT_4004001, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_4005001] = { ID = GACHA_WORLD_LIMIT_4005001, Limit = 67000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_7024002] = { ID = GACHA_WORLD_LIMIT_7024002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6001001] = { ID = GACHA_WORLD_LIMIT_6001001, Limit = 42998000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6002001] = { ID = GACHA_WORLD_LIMIT_6002001, Limit = 42998000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6003001] = { ID = GACHA_WORLD_LIMIT_6003001, Limit = 42998000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6004001] = { ID = GACHA_WORLD_LIMIT_6004001, Limit = 42998000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6005001] = { ID = GACHA_WORLD_LIMIT_6005001, Limit = 42998000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6006001] = { ID = GACHA_WORLD_LIMIT_6006001, Limit = 42998000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6001002] = { ID = GACHA_WORLD_LIMIT_6001002, Limit = 15494000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6002002] = { ID = GACHA_WORLD_LIMIT_6002002, Limit = 15494000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6003002] = { ID = GACHA_WORLD_LIMIT_6003002, Limit = 15494000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6004002] = { ID = GACHA_WORLD_LIMIT_6004002, Limit = 15494000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6005002] = { ID = GACHA_WORLD_LIMIT_6005002, Limit = 15494000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6006002] = { ID = GACHA_WORLD_LIMIT_6006002, Limit = 15494000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6001003] = { ID = GACHA_WORLD_LIMIT_6001003, Limit = 3529000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6002003] = { ID = GACHA_WORLD_LIMIT_6002003, Limit = 3529000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6003003] = { ID = GACHA_WORLD_LIMIT_6003003, Limit = 3529000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6004003] = { ID = GACHA_WORLD_LIMIT_6004003, Limit = 3529000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6005003] = { ID = GACHA_WORLD_LIMIT_6005003, Limit = 3529000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6006003] = { ID = GACHA_WORLD_LIMIT_6006003, Limit = 3529000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6001004] = { ID = GACHA_WORLD_LIMIT_6001004, Limit = 1064000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6002004] = { ID = GACHA_WORLD_LIMIT_6002004, Limit = 1064000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6003004] = { ID = GACHA_WORLD_LIMIT_6003004, Limit = 1064000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6004004] = { ID = GACHA_WORLD_LIMIT_6004004, Limit = 1064000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6005004] = { ID = GACHA_WORLD_LIMIT_6005004, Limit = 1064000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6006004] = { ID = GACHA_WORLD_LIMIT_6006004, Limit = 1064000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6001005] = { ID = GACHA_WORLD_LIMIT_6001005, Limit = 72000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6002005] = { ID = GACHA_WORLD_LIMIT_6002005, Limit = 72000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6003005] = { ID = GACHA_WORLD_LIMIT_6003005, Limit = 72000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6004005] = { ID = GACHA_WORLD_LIMIT_6004005, Limit = 72000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6005005] = { ID = GACHA_WORLD_LIMIT_6005005, Limit = 72000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6006005] = { ID = GACHA_WORLD_LIMIT_6006005, Limit = 72000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6001006] = { ID = GACHA_WORLD_LIMIT_6001006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6002006] = { ID = GACHA_WORLD_LIMIT_6002006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6003006] = { ID = GACHA_WORLD_LIMIT_6003006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6004006] = { ID = GACHA_WORLD_LIMIT_6004006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6005006] = { ID = GACHA_WORLD_LIMIT_6005006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6006006] = { ID = GACHA_WORLD_LIMIT_6006006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6007001] = { ID = GACHA_WORLD_LIMIT_6007001, Limit = 133000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6008001] = { ID = GACHA_WORLD_LIMIT_6008001, Limit = 133000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6009001] = { ID = GACHA_WORLD_LIMIT_6009001, Limit = 133000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6007002] = { ID = GACHA_WORLD_LIMIT_6007002, Limit = 341000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6008002] = { ID = GACHA_WORLD_LIMIT_6008002, Limit = 341000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6009002] = { ID = GACHA_WORLD_LIMIT_6009002, Limit = 341000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6007003] = { ID = GACHA_WORLD_LIMIT_6007003, Limit = 31000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6008003] = { ID = GACHA_WORLD_LIMIT_6008003, Limit = 31000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6009003] = { ID = GACHA_WORLD_LIMIT_6009003, Limit = 31000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6007004] = { ID = GACHA_WORLD_LIMIT_6007004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6008004] = { ID = GACHA_WORLD_LIMIT_6008004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6009004] = { ID = GACHA_WORLD_LIMIT_6009004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6007005] = { ID = GACHA_WORLD_LIMIT_6007005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6008005] = { ID = GACHA_WORLD_LIMIT_6008005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6009005] = { ID = GACHA_WORLD_LIMIT_6009005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6007006] = { ID = GACHA_WORLD_LIMIT_6007006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6008006] = { ID = GACHA_WORLD_LIMIT_6008006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6009006] = { ID = GACHA_WORLD_LIMIT_6009006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6010001] = { ID = GACHA_WORLD_LIMIT_6010001, Limit = 17000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6011001] = { ID = GACHA_WORLD_LIMIT_6011001, Limit = 17000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6012001] = { ID = GACHA_WORLD_LIMIT_6012001, Limit = 17000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6010002] = { ID = GACHA_WORLD_LIMIT_6010002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6011002] = { ID = GACHA_WORLD_LIMIT_6011002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6012002] = { ID = GACHA_WORLD_LIMIT_6012002, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6010003] = { ID = GACHA_WORLD_LIMIT_6010003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6011003] = { ID = GACHA_WORLD_LIMIT_6011003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6012003] = { ID = GACHA_WORLD_LIMIT_6012003, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6010004] = { ID = GACHA_WORLD_LIMIT_6010004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6011004] = { ID = GACHA_WORLD_LIMIT_6011004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6012004] = { ID = GACHA_WORLD_LIMIT_6012004, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6010005] = { ID = GACHA_WORLD_LIMIT_6010005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6011005] = { ID = GACHA_WORLD_LIMIT_6011005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6012005] = { ID = GACHA_WORLD_LIMIT_6012005, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6010006] = { ID = GACHA_WORLD_LIMIT_6010006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6011006] = { ID = GACHA_WORLD_LIMIT_6011006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
	[GACHA_WORLD_LIMIT_6012006] = { ID = GACHA_WORLD_LIMIT_6012006, Limit = 100000, BonusPolicy = "mutex_award", Bonus = {{"item",1001021,1,10000}},},
}
