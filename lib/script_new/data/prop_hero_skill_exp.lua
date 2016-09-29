--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_hero_skill_exp = {

	[HERO_BASIC_SKILL_LV_1] = { ID = HERO_BASIC_SKILL_LV_1, NeedExp = nil, TotalExp = {0,0,0,0,0,0},},
	[HERO_BASIC_SKILL_LV_2] = { ID = HERO_BASIC_SKILL_LV_2, NeedExp = {480,480,600,800,1200,1600}, TotalExp = {480,480,600,800,1200,1600},},
	[HERO_BASIC_SKILL_LV_3] = { ID = HERO_BASIC_SKILL_LV_3, NeedExp = {960,960,1200,1600,2400,3200}, TotalExp = {1440,1440,1800,2400,3600,4800},},
	[HERO_BASIC_SKILL_LV_4] = { ID = HERO_BASIC_SKILL_LV_4, NeedExp = {1440,1440,1800,2400,3600,4800}, TotalExp = {2880,2880,3600,4800,7200,9600},},
	[HERO_BASIC_SKILL_LV_5] = { ID = HERO_BASIC_SKILL_LV_5, NeedExp = {1920,1920,2400,3200,4800,6400}, TotalExp = {4800,4800,6000,8000,12000,16000},},
	[HERO_BASIC_SKILL_LV_6] = { ID = HERO_BASIC_SKILL_LV_6, NeedExp = {2400,2400,3000,4000,6000,8000}, TotalExp = {7200,7200,9000,12000,18000,24000},},
	[HERO_BASIC_SKILL_LV_7] = { ID = HERO_BASIC_SKILL_LV_7, NeedExp = {2880,2880,3600,4800,7200,9600}, TotalExp = {10080,10080,12600,16800,25200,33600},},
	[HERO_BASIC_SKILL_LV_8] = { ID = HERO_BASIC_SKILL_LV_8, NeedExp = {3456,3456,4320,5760,8640,11520}, TotalExp = {13536,13536,16920,22560,33840,45120},},
	[HERO_BASIC_SKILL_LV_9] = { ID = HERO_BASIC_SKILL_LV_9, NeedExp = {4080,4080,5100,6800,10200,13600}, TotalExp = {17616,17616,22020,29360,44040,58720},},
	[HERO_BASIC_SKILL_LV_10] = { ID = HERO_BASIC_SKILL_LV_10, NeedExp = {4800,4800,6000,8000,12000,16000}, TotalExp = {22416,22416,28020,37360,56040,74720},},
}