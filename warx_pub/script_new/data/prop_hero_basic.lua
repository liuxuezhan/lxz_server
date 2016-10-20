--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_hero_basic = {

	[HERO_1] = { ID = HERO_1, Mode = 0, Name = LG_HERO_BASIC_NAME_111100000, Desc = LG_HERO_BASIC_DESC_111200000, Type = 3, Star = 3, PieceID = 4002001, CallPrice = 20, MaxStar = 27, Quality = 4, Atk = 5793, Def = 3205, HP = 188773, GrowDelta = {5793,3205,188773}, BasicSkill = {}, TalentSkill = 20001002, Nature = 1, Culture = 1, LevelParam1 = 23441, LevelParam2 = 1848,},
	[HERO_2] = { ID = HERO_2, Mode = 0, Name = LG_HERO_BASIC_NAME_111100001, Desc = LG_HERO_BASIC_DESC_111200001, Type = 4, Star = 1, PieceID = 4002002, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6383, Def = 3501, HP = 172139, GrowDelta = {6383,3501,172139}, BasicSkill = {}, TalentSkill = 20002001, Nature = 1, Culture = 1, LevelParam1 = 29762, LevelParam2 = 1848,},
	[HERO_3] = { ID = HERO_3, Mode = 0, Name = LG_HERO_BASIC_NAME_111100002, Desc = LG_HERO_BASIC_DESC_111200002, Type = 2, Star = 1, PieceID = 4002003, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5964, Def = 4063, HP = 167095, GrowDelta = {5964,4063,167095}, BasicSkill = {}, TalentSkill = 20003001, Nature = 3, Culture = 1, LevelParam1 = 17088, LevelParam2 = 1848,},
	[HERO_4] = { ID = HERO_4, Mode = 0, Name = LG_HERO_BASIC_NAME_111100003, Desc = LG_HERO_BASIC_DESC_111200003, Type = 1, Star = 1, PieceID = 4002004, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 7687, Def = 2674, HP = 146995, GrowDelta = {7687,2674,146995}, BasicSkill = {}, TalentSkill = 20004001, Nature = 4, Culture = 1, LevelParam1 = 32523, LevelParam2 = 1848,},
	[HERO_5] = { ID = HERO_5, Mode = 0, Name = LG_HERO_BASIC_NAME_111100004, Desc = LG_HERO_BASIC_DESC_111200004, Type = 4, Star = 1, PieceID = 4002005, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6621, Def = 3406, HP = 165979, GrowDelta = {6621,3406,165979}, BasicSkill = {}, TalentSkill = 20005001, Nature = 2, Culture = 1, LevelParam1 = 29947, LevelParam2 = 1848,},
	[HERO_6] = { ID = HERO_6, Mode = 0, Name = LG_HERO_BASIC_NAME_111100005, Desc = LG_HERO_BASIC_DESC_111200005, Type = 1, Star = 1, PieceID = 4002006, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 7486, Def = 2691, HP = 150938, GrowDelta = {7486,2691,150938}, BasicSkill = {}, TalentSkill = 20006001, Nature = 3, Culture = 1, LevelParam1 = 31139, LevelParam2 = 1848,},
	[HERO_7] = { ID = HERO_7, Mode = 0, Name = LG_HERO_BASIC_NAME_111100006, Desc = LG_HERO_BASIC_DESC_111200006, Type = 3, Star = 1, PieceID = 4002007, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5715, Def = 3129, HP = 191382, GrowDelta = {5715,3129,191382}, BasicSkill = {}, TalentSkill = 20007001, Nature = 1, Culture = 1, LevelParam1 = 23132, LevelParam2 = 1848,},
	[HERO_8] = { ID = HERO_8, Mode = 0, Name = LG_HERO_BASIC_NAME_111100007, Desc = LG_HERO_BASIC_DESC_111200007, Type = 2, Star = 1, PieceID = 4002008, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5822, Def = 3928, HP = 171280, GrowDelta = {5822,3928,171280}, BasicSkill = {}, TalentSkill = 20008001, Nature = 2, Culture = 1, LevelParam1 = 15184, LevelParam2 = 1848,},
	[HERO_9] = { ID = HERO_9, Mode = 0, Name = LG_HERO_BASIC_NAME_111100008, Desc = LG_HERO_BASIC_DESC_111200008, Type = 4, Star = 1, PieceID = 4002009, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6432, Def = 3403, HP = 170857, GrowDelta = {6432,3403,170857}, BasicSkill = {}, TalentSkill = 20009001, Nature = 4, Culture = 3, LevelParam1 = 27195, LevelParam2 = 1848,},
	[HERO_10] = { ID = HERO_10, Mode = 0, Name = LG_HERO_BASIC_NAME_111100009, Desc = LG_HERO_BASIC_DESC_111200009, Type = 3, Star = 1, PieceID = 4002010, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5844, Def = 3129, HP = 187157, GrowDelta = {5844,3129,187157}, BasicSkill = {}, TalentSkill = 20010001, Nature = 3, Culture = 3, LevelParam1 = 22717, LevelParam2 = 1848,},
	[HERO_11] = { ID = HERO_11, Mode = 0, Name = LG_HERO_BASIC_NAME_111100010, Desc = LG_HERO_BASIC_DESC_111200010, Type = 4, Star = 1, PieceID = 4002011, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6717, Def = 3607, HP = 163552, GrowDelta = {6717,3607,163552}, BasicSkill = {}, TalentSkill = 20011001, Nature = 4, Culture = 3, LevelParam1 = 29234, LevelParam2 = 1848,},
	[HERO_12] = { ID = HERO_12, Mode = 0, Name = LG_HERO_BASIC_NAME_111100011, Desc = LG_HERO_BASIC_DESC_111200011, Type = 2, Star = 1, PieceID = 4002012, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5889, Def = 4171, HP = 169142, GrowDelta = {5889,4171,169142}, BasicSkill = {}, TalentSkill = 20012001, Nature = 2, Culture = 3, LevelParam1 = 16009, LevelParam2 = 1848,},
	[HERO_13] = { ID = HERO_13, Mode = 0, Name = LG_HERO_BASIC_NAME_111100012, Desc = LG_HERO_BASIC_DESC_111200012, Type = 1, Star = 1, PieceID = 4002013, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 7682, Def = 2646, HP = 147097, GrowDelta = {7682,2646,147097}, BasicSkill = {}, TalentSkill = 20013001, Nature = 2, Culture = 3, LevelParam1 = 32037, LevelParam2 = 1848,},
	[HERO_14] = { ID = HERO_14, Mode = 0, Name = LG_HERO_BASIC_NAME_111100013, Desc = LG_HERO_BASIC_DESC_111200013, Type = 3, Star = 1, PieceID = 4002014, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6082, Def = 3270, HP = 179778, GrowDelta = {6082,3270,179778}, BasicSkill = {}, TalentSkill = 20014001, Nature = 2, Culture = 3, LevelParam1 = 26157, LevelParam2 = 1848,},
	[HERO_15] = { ID = HERO_15, Mode = 0, Name = LG_HERO_BASIC_NAME_111100014, Desc = LG_HERO_BASIC_DESC_111200014, Type = 2, Star = 1, PieceID = 4002015, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5923, Def = 4030, HP = 168277, GrowDelta = {5923,4030,168277}, BasicSkill = {}, TalentSkill = 20015001, Nature = 4, Culture = 3, LevelParam1 = 15679, LevelParam2 = 1848,},
	[HERO_16] = { ID = HERO_16, Mode = 0, Name = LG_HERO_BASIC_NAME_111100015, Desc = LG_HERO_BASIC_DESC_111200015, Type = 4, Star = 1, PieceID = 4002016, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6747, Def = 3341, HP = 162898, GrowDelta = {6747,3341,162898}, BasicSkill = {}, TalentSkill = 20016001, Nature = 1, Culture = 2, LevelParam1 = 29390, LevelParam2 = 1848,},
	[HERO_17] = { ID = HERO_17, Mode = 0, Name = LG_HERO_BASIC_NAME_111100016, Desc = LG_HERO_BASIC_DESC_111200016, Type = 1, Star = 1, PieceID = 4002017, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 7574, Def = 2815, HP = 149157, GrowDelta = {7574,2815,149157}, BasicSkill = {}, TalentSkill = 20017001, Nature = 2, Culture = 2, LevelParam1 = 33360, LevelParam2 = 1848,},
	[HERO_18] = { ID = HERO_18, Mode = 0, Name = LG_HERO_BASIC_NAME_111100017, Desc = LG_HERO_BASIC_DESC_111200017, Type = 3, Star = 1, PieceID = 4002018, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 6114, Def = 3063, HP = 178919, GrowDelta = {6114,3063,178919}, BasicSkill = {}, TalentSkill = 20018001, Nature = 3, Culture = 2, LevelParam1 = 24583, LevelParam2 = 1848,},
	[HERO_19] = { ID = HERO_19, Mode = 0, Name = LG_HERO_BASIC_NAME_111100018, Desc = LG_HERO_BASIC_DESC_111200018, Type = 1, Star = 6, PieceID = 4002019, CallPrice = 65, MaxStar = 27, Quality = 4, Atk = 7603, Def = 2742, HP = 148604, GrowDelta = {7603,2742,148604}, BasicSkill = {1002001,2005001,3002001}, TalentSkill = 20019003, Nature = 4, Culture = 4, LevelParam1 = 32777, LevelParam2 = 1848,},
	[HERO_20] = { ID = HERO_20, Mode = 0, Name = LG_HERO_BASIC_NAME_111100019, Desc = LG_HERO_BASIC_DESC_111200019, Type = 2, Star = 1, PieceID = 4002020, CallPrice = 10, MaxStar = 27, Quality = 4, Atk = 5964, Def = 4117, HP = 167055, GrowDelta = {5964,4117,167055}, BasicSkill = {}, TalentSkill = 20020001, Nature = 3, Culture = 4, LevelParam1 = 15556, LevelParam2 = 1848,},
	[HERO_101] = { ID = HERO_101, Mode = 0, Name = LG_HERO_BASIC_NAME_111100020, Desc = LG_HERO_BASIC_DESC_111200020, Type = 1, Star = 1, PieceID = 4002101, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 7464, Def = 2733, HP = 151653, GrowDelta = {7614,2740,153664}, BasicSkill = {}, TalentSkill = 20101001, Nature = 3, Culture = 1, LevelParam1 = 22211, LevelParam2 = 1848,},
	[HERO_102] = { ID = HERO_102, Mode = 0, Name = LG_HERO_BASIC_NAME_111100021, Desc = LG_HERO_BASIC_DESC_111200021, Type = 2, Star = 1, PieceID = 4002102, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 7624, Def = 2637, HP = 148730, GrowDelta = {7616,2707,156233}, BasicSkill = {}, TalentSkill = 20102001, Nature = 1, Culture = 1, LevelParam1 = 21934, LevelParam2 = 1848,},
	[HERO_103] = { ID = HERO_103, Mode = 0, Name = LG_HERO_BASIC_NAME_111100022, Desc = LG_HERO_BASIC_DESC_111200022, Type = 4, Star = 1, PieceID = 4002103, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 6719, Def = 3521, HP = 163599, GrowDelta = {6721,3441,157966}, BasicSkill = {}, TalentSkill = 20103001, Nature = 3, Culture = 1, LevelParam1 = 20208, LevelParam2 = 1848,},
	[HERO_104] = { ID = HERO_104, Mode = 0, Name = LG_HERO_BASIC_NAME_111100023, Desc = LG_HERO_BASIC_DESC_111200023, Type = 1, Star = 1, PieceID = 4002104, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 7410, Def = 2661, HP = 152289, GrowDelta = {7614,2543,158491}, BasicSkill = {}, TalentSkill = 20104001, Nature = 1, Culture = 3, LevelParam1 = 20630, LevelParam2 = 1848,},
	[HERO_105] = { ID = HERO_105, Mode = 0, Name = LG_HERO_BASIC_NAME_111100024, Desc = LG_HERO_BASIC_DESC_111200024, Type = 2, Star = 1, PieceID = 4002105, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 5813, Def = 3860, HP = 171746, GrowDelta = {6114,3680,172451}, BasicSkill = {}, TalentSkill = 20105001, Nature = 2, Culture = 3, LevelParam1 = 10213, LevelParam2 = 1848,},
	[HERO_106] = { ID = HERO_106, Mode = 0, Name = LG_HERO_BASIC_NAME_111100025, Desc = LG_HERO_BASIC_DESC_111200025, Type = 3, Star = 1, PieceID = 4002106, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 5860, Def = 3193, HP = 185981, GrowDelta = {6180,2983,193854}, BasicSkill = {}, TalentSkill = 20106001, Nature = 2, Culture = 3, LevelParam1 = 16586, LevelParam2 = 1848,},
	[HERO_107] = { ID = HERO_107, Mode = 0, Name = LG_HERO_BASIC_NAME_111100026, Desc = LG_HERO_BASIC_DESC_111200026, Type = 2, Star = 1, PieceID = 4002107, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 6004, Def = 4113, HP = 167386, GrowDelta = {5980,4143,168627}, BasicSkill = {}, TalentSkill = 20107001, Nature = 3, Culture = 2, LevelParam1 = 11489, LevelParam2 = 1848,},
	[HERO_108] = { ID = HERO_108, Mode = 0, Name = LG_HERO_BASIC_NAME_111100027, Desc = LG_HERO_BASIC_DESC_111200027, Type = 1, Star = 1, PieceID = 4002108, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 7364, Def = 2687, HP = 153529, GrowDelta = {7614,2643,158233}, BasicSkill = {}, TalentSkill = 20108001, Nature = 2, Culture = 2, LevelParam1 = 21430, LevelParam2 = 1848,},
	[HERO_109] = { ID = HERO_109, Mode = 0, Name = LG_HERO_BASIC_NAME_111100028, Desc = LG_HERO_BASIC_DESC_111200028, Type = 3, Star = 1, PieceID = 4002109, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 6079, Def = 3074, HP = 179320, GrowDelta = {6406,2864,186199}, BasicSkill = {}, TalentSkill = 20109001, Nature = 2, Culture = 4, LevelParam1 = 15926, LevelParam2 = 1848,},
	[HERO_110] = { ID = HERO_110, Mode = 0, Name = LG_HERO_BASIC_NAME_111100029, Desc = LG_HERO_BASIC_DESC_111200029, Type = 4, Star = 1, PieceID = 4002110, CallPrice = 10, MaxStar = 14, Quality = 3, Atk = 6444, Def = 3544, HP = 170799, GrowDelta = {6390,3520,176404}, BasicSkill = {}, TalentSkill = 20110001, Nature = 3, Culture = 4, LevelParam1 = 20663, LevelParam2 = 1848,},
	[HERO_201] = { ID = HERO_201, Mode = 0, Name = LG_HERO_BASIC_NAME_111100030, Desc = LG_HERO_BASIC_DESC_111200030, Type = 4, Star = 1, PieceID = 4002201, CallPrice = 10, MaxStar = 9, Quality = 2, Atk = 6730, Def = 3354, HP = 164304, GrowDelta = {6672,3368,169832}, BasicSkill = {}, TalentSkill = 20201001, Nature = 1, Culture = 1, LevelParam1 = 14107, LevelParam2 = 1848,},
	[HERO_202] = { ID = HERO_202, Mode = 0, Name = LG_HERO_BASIC_NAME_111100031, Desc = LG_HERO_BASIC_DESC_111200031, Type = 2, Star = 1, PieceID = 4002202, CallPrice = 10, MaxStar = 9, Quality = 2, Atk = 5828, Def = 4074, HP = 173850, GrowDelta = {5822,4062,177778}, BasicSkill = {}, TalentSkill = 20202001, Nature = 3, Culture = 1, LevelParam1 = 8037, LevelParam2 = 1848,},
	[HERO_203] = { ID = HERO_203, Mode = 0, Name = LG_HERO_BASIC_NAME_111100032, Desc = LG_HERO_BASIC_DESC_111200032, Type = 3, Star = 1, PieceID = 4002203, CallPrice = 10, MaxStar = 9, Quality = 2, Atk = 5780, Def = 3028, HP = 191044, GrowDelta = {5742,3118,200728}, BasicSkill = {}, TalentSkill = 20203001, Nature = 3, Culture = 3, LevelParam1 = 12350, LevelParam2 = 1848,},
	[HERO_204] = { ID = HERO_204, Mode = 0, Name = LG_HERO_BASIC_NAME_111100033, Desc = LG_HERO_BASIC_DESC_111200033, Type = 1, Star = 1, PieceID = 4002204, CallPrice = 10, MaxStar = 9, Quality = 2, Atk = 7334, Def = 2638, HP = 154486, GrowDelta = {7614,2582,162154}, BasicSkill = {}, TalentSkill = 20204001, Nature = 3, Culture = 3, LevelParam1 = 14945, LevelParam2 = 1848,},
	[HERO_205] = { ID = HERO_205, Mode = 0, Name = LG_HERO_BASIC_NAME_111100034, Desc = LG_HERO_BASIC_DESC_111200034, Type = 1, Star = 1, PieceID = 4002205, CallPrice = 10, MaxStar = 9, Quality = 2, Atk = 7422, Def = 2718, HP = 152484, GrowDelta = {7616,2624,155400}, BasicSkill = {}, TalentSkill = 20205001, Nature = 3, Culture = 2, LevelParam1 = 15193, LevelParam2 = 1848,},
	[HERO_206] = { ID = HERO_206, Mode = 0, Name = LG_HERO_BASIC_NAME_111100035, Desc = LG_HERO_BASIC_DESC_111200035, Type = 4, Star = 1, PieceID = 4002206, CallPrice = 10, MaxStar = 9, Quality = 2, Atk = 6400, Def = 3588, HP = 172462, GrowDelta = {6374,3556,164856}, BasicSkill = {}, TalentSkill = 20206001, Nature = 3, Culture = 4, LevelParam1 = 14901, LevelParam2 = 1848,},
	[HERO_301] = { ID = HERO_301, Mode = 0, Name = LG_HERO_BASIC_NAME_111100036, Desc = LG_HERO_BASIC_DESC_111200036, Type = 4, Star = 1, PieceID = 4002301, CallPrice = 10, MaxStar = 5, Quality = 1, Atk = 6657, Def = 3527, HP = 166467, GrowDelta = {6953,3363,170617}, BasicSkill = {}, TalentSkill = 20301001, Nature = 3, Culture = 4, LevelParam1 = 8447, LevelParam2 = 1848,},
	[HERO_302] = { ID = HERO_302, Mode = 0, Name = LG_HERO_BASIC_NAME_111100037, Desc = LG_HERO_BASIC_DESC_111200037, Type = 4, Star = 1, PieceID = 4002302, CallPrice = 10, MaxStar = 5, Quality = 1, Atk = 6640, Def = 3477, HP = 167507, GrowDelta = {6787,3477,175683}, BasicSkill = {}, TalentSkill = 20302001, Nature = 1, Culture = 2, LevelParam1 = 8724, LevelParam2 = 1848,},
	[HERO_303] = { ID = HERO_303, Mode = 0, Name = LG_HERO_BASIC_NAME_111100038, Desc = LG_HERO_BASIC_DESC_111200038, Type = 4, Star = 1, PieceID = 4002303, CallPrice = 10, MaxStar = 5, Quality = 1, Atk = 6483, Def = 3390, HP = 171300, GrowDelta = {6700,3303,169387}, BasicSkill = {}, TalentSkill = 20303001, Nature = 2, Culture = 1, LevelParam1 = 8292, LevelParam2 = 1848,},
	[HERO_304] = { ID = HERO_304, Mode = 0, Name = LG_HERO_BASIC_NAME_111100039, Desc = LG_HERO_BASIC_DESC_111200039, Type = 4, Star = 1, PieceID = 4002304, CallPrice = 10, MaxStar = 5, Quality = 1, Atk = 6390, Def = 3310, HP = 173570, GrowDelta = {6547,3150,168210}, BasicSkill = {}, TalentSkill = 20304001, Nature = 4, Culture = 3, LevelParam1 = 7909, LevelParam2 = 1848,},
	[HERO_1001] = { ID = HERO_1001, Mode = 1, Name = LG_HERO_BASIC_NAME_111100040, Desc = LG_HERO_BASIC_DESC_111200040, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 5722, Def = 3241, HP = 190428, GrowDelta = {5900,3126,183071}, BasicSkill = {}, TalentSkill = 20011001, Nature = 3, Culture = 105, LevelParam1 = 24833, LevelParam2 = 1848,},
	[HERO_1002] = { ID = HERO_1002, Mode = 1, Name = LG_HERO_BASIC_NAME_111100041, Desc = LG_HERO_BASIC_DESC_111200041, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 5947, Def = 3904, HP = 169255, GrowDelta = {5995,4138,172622}, BasicSkill = {}, TalentSkill = 20108001, Nature = 1, Culture = 105, LevelParam1 = 16393, LevelParam2 = 1848,},
	[HERO_1003] = { ID = HERO_1003, Mode = 1, Name = LG_HERO_BASIC_NAME_111100042, Desc = LG_HERO_BASIC_DESC_111200042, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 7638, Def = 2753, HP = 147779, GrowDelta = {7615,2716,148650}, BasicSkill = {}, TalentSkill = 20108001, Nature = 2, Culture = 101, LevelParam1 = 31477, LevelParam2 = 1848,},
	[HERO_1004] = { ID = HERO_1004, Mode = 1, Name = LG_HERO_BASIC_NAME_111100043, Desc = LG_HERO_BASIC_DESC_111200043, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 7326, Def = 2873, HP = 153688, GrowDelta = {7615,2744,148167}, BasicSkill = {}, TalentSkill = 20104001, Nature = 4, Culture = 104, LevelParam1 = 31823, LevelParam2 = 1848,},
	[HERO_1005] = { ID = HERO_1005, Mode = 1, Name = LG_HERO_BASIC_NAME_111100044, Desc = LG_HERO_BASIC_DESC_111200044, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 7325, Def = 2647, HP = 153933, GrowDelta = {7615,2567,161090}, BasicSkill = {}, TalentSkill = 20108001, Nature = 3, Culture = 101, LevelParam1 = 29759, LevelParam2 = 1848,},
	[HERO_1006] = { ID = HERO_1006, Mode = 1, Name = LG_HERO_BASIC_NAME_111100045, Desc = LG_HERO_BASIC_DESC_111200045, Type = 4, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 6554, Def = 3483, HP = 167804, GrowDelta = {6703,3517,166787}, BasicSkill = {}, TalentSkill = 20102001, Nature = 1, Culture = 106, LevelParam1 = 29500, LevelParam2 = 1848,},
	[HERO_1007] = { ID = HERO_1007, Mode = 1, Name = LG_HERO_BASIC_NAME_111100046, Desc = LG_HERO_BASIC_DESC_111200046, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 5849, Def = 4161, HP = 170023, GrowDelta = {5995,4119,162667}, BasicSkill = {}, TalentSkill = 20104001, Nature = 2, Culture = 102, LevelParam1 = 16339, LevelParam2 = 1848,},
	[HERO_1008] = { ID = HERO_1008, Mode = 1, Name = LG_HERO_BASIC_NAME_111100047, Desc = LG_HERO_BASIC_DESC_111200047, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 5884, Def = 2986, HP = 186275, GrowDelta = {5899,3042,194345}, BasicSkill = {}, TalentSkill = 20106001, Nature = 4, Culture = 104, LevelParam1 = 24138, LevelParam2 = 1848,},
	[HERO_1009] = { ID = HERO_1009, Mode = 1, Name = LG_HERO_BASIC_NAME_111100048, Desc = LG_HERO_BASIC_DESC_111200048, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 7445, Def = 2723, HP = 151454, GrowDelta = {7615,2646,154045}, BasicSkill = {}, TalentSkill = 20102001, Nature = 3, Culture = 106, LevelParam1 = 30675, LevelParam2 = 1848,},
	[HERO_1010] = { ID = HERO_1010, Mode = 1, Name = LG_HERO_BASIC_NAME_111100049, Desc = LG_HERO_BASIC_DESC_111200049, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 7264, Def = 2689, HP = 155220, GrowDelta = {7614,2609,159860}, BasicSkill = {}, TalentSkill = 20104001, Nature = 1, Culture = 106, LevelParam1 = 30246, LevelParam2 = 1848,},
	[HERO_1011] = { ID = HERO_1011, Mode = 1, Name = LG_HERO_BASIC_NAME_111100050, Desc = LG_HERO_BASIC_DESC_111200050, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 7672, Def = 2642, HP = 147301, GrowDelta = {7615,2645,154415}, BasicSkill = {}, TalentSkill = 20102001, Nature = 2, Culture = 101, LevelParam1 = 30644, LevelParam2 = 1848,},
	[HERO_1012] = { ID = HERO_1012, Mode = 1, Name = LG_HERO_BASIC_NAME_111100051, Desc = LG_HERO_BASIC_DESC_111200051, Type = 4, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 27, Quality = 4, Atk = 6450, Def = 3325, HP = 169552, GrowDelta = {6702,3153,176535}, BasicSkill = {}, TalentSkill = 20108001, Nature = 4, Culture = 101, LevelParam1 = 26477, LevelParam2 = 1848,},
	[HERO_1201] = { ID = HERO_1201, Mode = 1, Name = LG_HERO_BASIC_NAME_111100052, Desc = LG_HERO_BASIC_DESC_111200052, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 6057, Def = 3783, HP = 166854, GrowDelta = {5994,3903,175587}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 101, LevelParam1 = 10816, LevelParam2 = 1848,},
	[HERO_1202] = { ID = HERO_1202, Mode = 1, Name = LG_HERO_BASIC_NAME_111100053, Desc = LG_HERO_BASIC_DESC_111200053, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7284, Def = 2869, HP = 155087, GrowDelta = {7614,2803,149763}, BasicSkill = {}, TalentSkill = 20108001, Nature = 1, Culture = 101, LevelParam1 = 22733, LevelParam2 = 1848,},
	[HERO_1203] = { ID = HERO_1203, Mode = 1, Name = LG_HERO_BASIC_NAME_111100054, Desc = LG_HERO_BASIC_DESC_111200054, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7471, Def = 2907, HP = 151100, GrowDelta = {7616,2816,143954}, BasicSkill = {}, TalentSkill = 20101001, Nature = 2, Culture = 101, LevelParam1 = 22841, LevelParam2 = 1848,},
	[HERO_1204] = { ID = HERO_1204, Mode = 1, Name = LG_HERO_BASIC_NAME_111100055, Desc = LG_HERO_BASIC_DESC_111200055, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 6111, Def = 3107, HP = 180059, GrowDelta = {5900,3214,180526}, BasicSkill = {}, TalentSkill = 20106001, Nature = 4, Culture = 101, LevelParam1 = 17839, LevelParam2 = 1848,},
	[HERO_1205] = { ID = HERO_1205, Mode = 1, Name = LG_HERO_BASIC_NAME_111100056, Desc = LG_HERO_BASIC_DESC_111200056, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 6020, Def = 4029, HP = 167169, GrowDelta = {5994,4080,165203}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 104, LevelParam1 = 11313, LevelParam2 = 1848,},
	[HERO_1206] = { ID = HERO_1206, Mode = 1, Name = LG_HERO_BASIC_NAME_111100057, Desc = LG_HERO_BASIC_DESC_111200057, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7276, Def = 2769, HP = 155309, GrowDelta = {7614,2707,155404}, BasicSkill = {}, TalentSkill = 20108001, Nature = 1, Culture = 104, LevelParam1 = 21955, LevelParam2 = 1848,},
	[HERO_1207] = { ID = HERO_1207, Mode = 1, Name = LG_HERO_BASIC_NAME_111100058, Desc = LG_HERO_BASIC_DESC_111200058, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7639, Def = 2666, HP = 148307, GrowDelta = {7614,2699,154081}, BasicSkill = {}, TalentSkill = 20101001, Nature = 2, Culture = 104, LevelParam1 = 21870, LevelParam2 = 1848,},
	[HERO_1208] = { ID = HERO_1208, Mode = 1, Name = LG_HERO_BASIC_NAME_111100059, Desc = LG_HERO_BASIC_DESC_111200059, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 6001, Def = 3166, HP = 183239, GrowDelta = {5900,3257,180349}, BasicSkill = {}, TalentSkill = 20106001, Nature = 4, Culture = 104, LevelParam1 = 18079, LevelParam2 = 1848,},
	[HERO_1209] = { ID = HERO_1209, Mode = 1, Name = LG_HERO_BASIC_NAME_111100060, Desc = LG_HERO_BASIC_DESC_111200060, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 5816, Def = 3907, HP = 171233, GrowDelta = {5996,3673,174496}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 102, LevelParam1 = 10196, LevelParam2 = 1848,},
	[HERO_1210] = { ID = HERO_1210, Mode = 1, Name = LG_HERO_BASIC_NAME_111100061, Desc = LG_HERO_BASIC_DESC_111200061, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7216, Def = 2661, HP = 156456, GrowDelta = {7614,2559,162817}, BasicSkill = {}, TalentSkill = 20108001, Nature = 1, Culture = 102, LevelParam1 = 20755, LevelParam2 = 1848,},
	[HERO_1211] = { ID = HERO_1211, Mode = 1, Name = LG_HERO_BASIC_NAME_111100062, Desc = LG_HERO_BASIC_DESC_111200062, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7537, Def = 2720, HP = 149923, GrowDelta = {7616,2656,152676}, BasicSkill = {}, TalentSkill = 20101001, Nature = 2, Culture = 102, LevelParam1 = 21538, LevelParam2 = 1848,},
	[HERO_1212] = { ID = HERO_1212, Mode = 1, Name = LG_HERO_BASIC_NAME_111100063, Desc = LG_HERO_BASIC_DESC_111200063, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 5870, Def = 2986, HP = 186951, GrowDelta = {5900,2983,195130}, BasicSkill = {}, TalentSkill = 20106001, Nature = 4, Culture = 102, LevelParam1 = 16563, LevelParam2 = 1848,},
	[HERO_1213] = { ID = HERO_1213, Mode = 1, Name = LG_HERO_BASIC_NAME_111100064, Desc = LG_HERO_BASIC_DESC_111200064, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 5986, Def = 3841, HP = 167453, GrowDelta = {5996,3757,173534}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 103, LevelParam1 = 10422, LevelParam2 = 1848,},
	[HERO_1214] = { ID = HERO_1214, Mode = 1, Name = LG_HERO_BASIC_NAME_111100065, Desc = LG_HERO_BASIC_DESC_111200065, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7220, Def = 2780, HP = 156483, GrowDelta = {7614,2713,155931}, BasicSkill = {}, TalentSkill = 20108001, Nature = 1, Culture = 103, LevelParam1 = 22002, LevelParam2 = 1848,},
	[HERO_1215] = { ID = HERO_1215, Mode = 1, Name = LG_HERO_BASIC_NAME_111100066, Desc = LG_HERO_BASIC_DESC_111200066, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7621, Def = 2896, HP = 148399, GrowDelta = {7614,2880,141964}, BasicSkill = {}, TalentSkill = 20101001, Nature = 2, Culture = 103, LevelParam1 = 23351, LevelParam2 = 1848,},
	[HERO_1216] = { ID = HERO_1216, Mode = 1, Name = LG_HERO_BASIC_NAME_111100067, Desc = LG_HERO_BASIC_DESC_111200067, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 6016, Def = 3039, HP = 182854, GrowDelta = {5900,3123,187494}, BasicSkill = {}, TalentSkill = 20106001, Nature = 4, Culture = 103, LevelParam1 = 17332, LevelParam2 = 1848,},
	[HERO_1217] = { ID = HERO_1217, Mode = 1, Name = LG_HERO_BASIC_NAME_111100068, Desc = LG_HERO_BASIC_DESC_111200068, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 6031, Def = 4013, HP = 167763, GrowDelta = {5994,4214,166420}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 105, LevelParam1 = 11678, LevelParam2 = 1848,},
	[HERO_1218] = { ID = HERO_1218, Mode = 1, Name = LG_HERO_BASIC_NAME_111100069, Desc = LG_HERO_BASIC_DESC_111200069, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7346, Def = 2879, HP = 153631, GrowDelta = {7616,2771,147793}, BasicSkill = {}, TalentSkill = 20108001, Nature = 1, Culture = 105, LevelParam1 = 22484, LevelParam2 = 1848,},
	[HERO_1219] = { ID = HERO_1219, Mode = 1, Name = LG_HERO_BASIC_NAME_111100070, Desc = LG_HERO_BASIC_DESC_111200070, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 7650, Def = 2796, HP = 148067, GrowDelta = {7614,2836,146650}, BasicSkill = {}, TalentSkill = 20101001, Nature = 2, Culture = 105, LevelParam1 = 22983, LevelParam2 = 1848,},
	[HERO_1220] = { ID = HERO_1220, Mode = 1, Name = LG_HERO_BASIC_NAME_111100071, Desc = LG_HERO_BASIC_DESC_111200071, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 14, Quality = 3, Atk = 5770, Def = 3119, HP = 190206, GrowDelta = {5899,3133,190034}, BasicSkill = {}, TalentSkill = 20106001, Nature = 4, Culture = 105, LevelParam1 = 17396, LevelParam2 = 1848,},
	[HERO_1301] = { ID = HERO_1301, Mode = 1, Name = LG_HERO_BASIC_NAME_111100072, Desc = LG_HERO_BASIC_DESC_111200072, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5786, Def = 3792, HP = 174078, GrowDelta = {5996,3558,182750}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 101, LevelParam1 = 7044, LevelParam2 = 1848,},
	[HERO_1302] = { ID = HERO_1302, Mode = 1, Name = LG_HERO_BASIC_NAME_111100073, Desc = LG_HERO_BASIC_DESC_111200073, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7362, Def = 2730, HP = 153708, GrowDelta = {7614,2632,155982}, BasicSkill = {}, TalentSkill = 20205001, Nature = 1, Culture = 101, LevelParam1 = 15240, LevelParam2 = 1848,},
	[HERO_1303] = { ID = HERO_1303, Mode = 1, Name = LG_HERO_BASIC_NAME_111100074, Desc = LG_HERO_BASIC_DESC_111200074, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7468, Def = 2836, HP = 151672, GrowDelta = {7614,2788,148078}, BasicSkill = {}, TalentSkill = 20204001, Nature = 2, Culture = 101, LevelParam1 = 16139, LevelParam2 = 1848,},
	[HERO_1304] = { ID = HERO_1304, Mode = 1, Name = LG_HERO_BASIC_NAME_111100075, Desc = LG_HERO_BASIC_DESC_111200075, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5696, Def = 3146, HP = 192936, GrowDelta = {5900,3078,191038}, BasicSkill = {}, TalentSkill = 20206001, Nature = 4, Culture = 101, LevelParam1 = 12203, LevelParam2 = 1848,},
	[HERO_1305] = { ID = HERO_1305, Mode = 1, Name = LG_HERO_BASIC_NAME_111100076, Desc = LG_HERO_BASIC_DESC_111200076, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5738, Def = 3958, HP = 175256, GrowDelta = {5996,3712,176250}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 104, LevelParam1 = 7350, LevelParam2 = 1848,},
	[HERO_1306] = { ID = HERO_1306, Mode = 1, Name = LG_HERO_BASIC_NAME_111100077, Desc = LG_HERO_BASIC_DESC_111200077, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7272, Def = 2790, HP = 155630, GrowDelta = {7616,2702,154496}, BasicSkill = {}, TalentSkill = 20205001, Nature = 1, Culture = 104, LevelParam1 = 15645, LevelParam2 = 1848,},
	[HERO_1307] = { ID = HERO_1307, Mode = 1, Name = LG_HERO_BASIC_NAME_111100078, Desc = LG_HERO_BASIC_DESC_111200078, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7452, Def = 2744, HP = 151832, GrowDelta = {7614,2642,153202}, BasicSkill = {}, TalentSkill = 20204001, Nature = 2, Culture = 104, LevelParam1 = 15298, LevelParam2 = 1848,},
	[HERO_1308] = { ID = HERO_1308, Mode = 1, Name = LG_HERO_BASIC_NAME_111100079, Desc = LG_HERO_BASIC_DESC_111200079, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5948, Def = 2994, HP = 185758, GrowDelta = {5900,3100,193254}, BasicSkill = {}, TalentSkill = 20206001, Nature = 4, Culture = 104, LevelParam1 = 12277, LevelParam2 = 1848,},
	[HERO_1309] = { ID = HERO_1309, Mode = 1, Name = LG_HERO_BASIC_NAME_111100080, Desc = LG_HERO_BASIC_DESC_111200080, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5860, Def = 3880, HP = 173582, GrowDelta = {5996,3938,178112}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 102, LevelParam1 = 7788, LevelParam2 = 1848,},
	[HERO_1310] = { ID = HERO_1310, Mode = 1, Name = LG_HERO_BASIC_NAME_111100081, Desc = LG_HERO_BASIC_DESC_111200081, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7230, Def = 2852, HP = 156358, GrowDelta = {7614,2722,151834}, BasicSkill = {}, TalentSkill = 20205001, Nature = 1, Culture = 102, LevelParam1 = 15766, LevelParam2 = 1848,},
	[HERO_1311] = { ID = HERO_1311, Mode = 1, Name = LG_HERO_BASIC_NAME_111100082, Desc = LG_HERO_BASIC_DESC_111200082, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7634, Def = 2842, HP = 148494, GrowDelta = {7614,2830,144666}, BasicSkill = {}, TalentSkill = 20204001, Nature = 2, Culture = 102, LevelParam1 = 16378, LevelParam2 = 1848,},
	[HERO_1312] = { ID = HERO_1312, Mode = 1, Name = LG_HERO_BASIC_NAME_111100083, Desc = LG_HERO_BASIC_DESC_111200083, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 6038, Def = 3100, HP = 182422, GrowDelta = {5900,3108,183358}, BasicSkill = {}, TalentSkill = 20206001, Nature = 4, Culture = 102, LevelParam1 = 12317, LevelParam2 = 1848,},
	[HERO_1313] = { ID = HERO_1313, Mode = 1, Name = LG_HERO_BASIC_NAME_111100084, Desc = LG_HERO_BASIC_DESC_111200084, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5992, Def = 3792, HP = 171126, GrowDelta = {5996,4070,179708}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 103, LevelParam1 = 8041, LevelParam2 = 1848,},
	[HERO_1314] = { ID = HERO_1314, Mode = 1, Name = LG_HERO_BASIC_NAME_111100085, Desc = LG_HERO_BASIC_DESC_111200085, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7282, Def = 2802, HP = 155448, GrowDelta = {7614,2724,153608}, BasicSkill = {}, TalentSkill = 20205001, Nature = 1, Culture = 103, LevelParam1 = 15771, LevelParam2 = 1848,},
	[HERO_1315] = { ID = HERO_1315, Mode = 1, Name = LG_HERO_BASIC_NAME_111100086, Desc = LG_HERO_BASIC_DESC_111200086, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 7534, Def = 2732, HP = 150528, GrowDelta = {7614,2726,152558}, BasicSkill = {}, TalentSkill = 20204001, Nature = 2, Culture = 103, LevelParam1 = 15775, LevelParam2 = 1848,},
	[HERO_1316] = { ID = HERO_1316, Mode = 1, Name = LG_HERO_BASIC_NAME_111100087, Desc = LG_HERO_BASIC_DESC_111200087, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 9, Quality = 2, Atk = 5876, Def = 3244, HP = 187420, GrowDelta = {5900,3268,179990}, BasicSkill = {}, TalentSkill = 20206001, Nature = 4, Culture = 103, LevelParam1 = 12951, LevelParam2 = 1848,},
	[HERO_1317] = { ID = HERO_1317, Mode = 1, Name = LG_HERO_BASIC_NAME_111100088, Desc = LG_HERO_BASIC_DESC_111200088, Type = 2, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 5, Quality = 2, Atk = 5758, Def = 4106, HP = 173640, GrowDelta = {5996,3730,168354}, BasicSkill = {}, TalentSkill = 20104001, Nature = 3, Culture = 105, LevelParam1 = 7391, LevelParam2 = 1848,},
	[HERO_1318] = { ID = HERO_1318, Mode = 1, Name = LG_HERO_BASIC_NAME_111100089, Desc = LG_HERO_BASIC_DESC_111200089, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 5, Quality = 2, Atk = 7256, Def = 2700, HP = 155644, GrowDelta = {7614,2522,159630}, BasicSkill = {}, TalentSkill = 20205001, Nature = 1, Culture = 105, LevelParam1 = 14611, LevelParam2 = 1848,},
	[HERO_1319] = { ID = HERO_1319, Mode = 1, Name = LG_HERO_BASIC_NAME_111100090, Desc = LG_HERO_BASIC_DESC_111200090, Type = 1, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 5, Quality = 2, Atk = 7664, Def = 2632, HP = 148298, GrowDelta = {7614,2708,155996}, BasicSkill = {}, TalentSkill = 20204001, Nature = 2, Culture = 105, LevelParam1 = 15661, LevelParam2 = 1848,},
	[HERO_1320] = { ID = HERO_1320, Mode = 1, Name = LG_HERO_BASIC_NAME_111100091, Desc = LG_HERO_BASIC_DESC_111200091, Type = 3, Star = 1, PieceID = nil, CallPrice = nil, MaxStar = 5, Quality = 2, Atk = 5696, Def = 3102, HP = 192944, GrowDelta = {5900,3030,193772}, BasicSkill = {}, TalentSkill = 20206001, Nature = 4, Culture = 105, LevelParam1 = 12013, LevelParam2 = 1848,},
}