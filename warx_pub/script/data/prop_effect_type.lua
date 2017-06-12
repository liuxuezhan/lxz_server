--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_effect_type = {

	["CountSoldier"] = { ID = "CountSoldier", Index = 1, Default = 3000, BuffName = LG_EFFECT_TYPE_NAME_108000000, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100000,},
	["CountTrain"] = { ID = "CountTrain", Index = 2, Default = 5, BuffName = LG_EFFECT_TYPE_NAME_108000001, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100001,},
	["CountTroop"] = { ID = "CountTroop", Index = 3, Default = 1, BuffName = LG_EFFECT_TYPE_NAME_108000002, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100002,},
	["CountCure"] = { ID = "CountCure", Index = 4, Default = 5000, BuffName = LG_EFFECT_TYPE_NAME_108000003, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100003,},
	["CountConsumeCure"] = { ID = "CountConsumeCure", Index = 5, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000004, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100004,},
	["CountPrisoner"] = { ID = "CountPrisoner", Index = 6, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000005, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100005,},
	["CountWeight"] = { ID = "CountWeight", Index = 7, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000006, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100006,},
	["CountStore"] = { ID = "CountStore", Index = 8, Default = 250000, BuffName = LG_EFFECT_TYPE_NAME_108000007, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100007,},
	["CountResSupport"] = { ID = "CountResSupport", Index = 112, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000111, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100111,},
	["CountRes"] = { ID = "CountRes", Index = 110, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000109, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100109,},
	["CountRes1"] = { ID = "CountRes1", Index = 9, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000008, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100008,},
	["CountRes2"] = { ID = "CountRes2", Index = 10, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000009, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100009,},
	["CountRes3"] = { ID = "CountRes3", Index = 11, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000010, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100010,},
	["CountRes4"] = { ID = "CountRes4", Index = 12, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000011, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100011,},
	["SpeedRes"] = { ID = "SpeedRes", Index = 111, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000110, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100110,},
	["SpeedRes1"] = { ID = "SpeedRes1", Index = 13, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000012, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100012,},
	["SpeedRes2"] = { ID = "SpeedRes2", Index = 14, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000013, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100013,},
	["SpeedRes3"] = { ID = "SpeedRes3", Index = 15, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000014, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100014,},
	["SpeedRes4"] = { ID = "SpeedRes4", Index = 16, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000015, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100015,},
	["SpeedGather"] = { ID = "SpeedGather", Index = 17, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000016, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100016,},
	["SpeedGather1"] = { ID = "SpeedGather1", Index = 18, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000017, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100017,},
	["SpeedGather2"] = { ID = "SpeedGather2", Index = 19, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000018, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100018,},
	["SpeedGather3"] = { ID = "SpeedGather3", Index = 20, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000019, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100019,},
	["SpeedGather4"] = { ID = "SpeedGather4", Index = 21, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000020, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100020,},
	["SpeedCure"] = { ID = "SpeedCure", Index = 22, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000021, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100021,},
	["SpeedTrain"] = { ID = "SpeedTrain", Index = 23, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000022, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100022,},
	["SpeedConsume"] = { ID = "SpeedConsume", Index = 24, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000023, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100023,},
	["SpeedMarch"] = { ID = "SpeedMarch", Index = 25, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000024, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100024,},
	["SpeedMarchPvE"] = { ID = "SpeedMarchPvE", Index = 26, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000025, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100025,},
	["SpeedRecover"] = { ID = "SpeedRecover", Index = 27, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000026, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100026,},
	["SpeedBuild"] = { ID = "SpeedBuild", Index = 28, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000027, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100027,},
	["SpeedTech"] = { ID = "SpeedTech", Index = 29, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000028, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100028,},
	["BuildFreeTime"] = { ID = "BuildFreeTime", Index = 115, Default = 300, BuffName = LG_EFFECT_TYPE_NAME_108000114, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100114,},
	["CountBuild"] = { ID = "CountBuild", Index = 123, Default = 1, BuffName = LG_EFFECT_TYPE_NAME_108000122, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100122,},
	["SpeedForge"] = { ID = "SpeedForge", Index = 124, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000123, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100123,},
	["SilverCoinConsume"] = { ID = "SilverCoinConsume", Index = 125, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000124, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100124,},
	["SpeedBurn"] = { ID = "SpeedBurn", Index = 126, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000125, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100125,},
	["StateShell"] = { ID = "StateShell", Index = 127, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000126, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100126,},
	["Atk"] = { ID = "Atk", Index = 30, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000029, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100029,},
	["Atk1"] = { ID = "Atk1", Index = 31, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000030, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100030,},
	["Atk2"] = { ID = "Atk2", Index = 32, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000031, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100031,},
	["Atk3"] = { ID = "Atk3", Index = 33, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000032, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100032,},
	["Atk4"] = { ID = "Atk4", Index = 34, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000033, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100033,},
	["AAtk1"] = { ID = "AAtk1", Index = 35, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000034, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100034,},
	["AAtk2"] = { ID = "AAtk2", Index = 36, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000035, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100035,},
	["AAtk3"] = { ID = "AAtk3", Index = 37, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000036, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100036,},
	["AAtk4"] = { ID = "AAtk4", Index = 38, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000037, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100037,},
	["Def"] = { ID = "Def", Index = 39, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000038, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100038,},
	["Def1"] = { ID = "Def1", Index = 40, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000039, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100039,},
	["Def2"] = { ID = "Def2", Index = 41, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000040, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100040,},
	["Def3"] = { ID = "Def3", Index = 42, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000041, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100041,},
	["Def4"] = { ID = "Def4", Index = 43, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000042, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100042,},
	["Imm"] = { ID = "Imm", Index = 44, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000043, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100043,},
	["Imm1"] = { ID = "Imm1", Index = 45, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000044, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100044,},
	["Imm2"] = { ID = "Imm2", Index = 46, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000045, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100045,},
	["Imm3"] = { ID = "Imm3", Index = 47, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000046, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100046,},
	["Imm4"] = { ID = "Imm4", Index = 48, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000047, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100047,},
	["DImm1"] = { ID = "DImm1", Index = 49, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000048, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100048,},
	["DImm2"] = { ID = "DImm2", Index = 50, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000049, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100049,},
	["DImm3"] = { ID = "DImm3", Index = 51, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000050, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100050,},
	["DImm4"] = { ID = "DImm4", Index = 52, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000051, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100051,},
	["AtkImmCom"] = { ID = "AtkImmCom", Index = 53, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000052, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100052,},
	["AtkImmCom1"] = { ID = "AtkImmCom1", Index = 54, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000053, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100053,},
	["AtkImmCom2"] = { ID = "AtkImmCom2", Index = 55, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000054, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100054,},
	["AtkImmCom3"] = { ID = "AtkImmCom3", Index = 56, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000055, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100055,},
	["AtkImmCom4"] = { ID = "AtkImmCom4", Index = 57, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000056, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100056,},
	["AtkImmTac"] = { ID = "AtkImmTac", Index = 58, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000057, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100057,},
	["AtkImmTac1"] = { ID = "AtkImmTac1", Index = 59, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000058, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100058,},
	["AtkImmTac2"] = { ID = "AtkImmTac2", Index = 60, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000059, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100059,},
	["AtkImmTac3"] = { ID = "AtkImmTac3", Index = 61, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000060, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100060,},
	["AtkImmTac4"] = { ID = "AtkImmTac4", Index = 62, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000061, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100061,},
	["Imp"] = { ID = "Imp", Index = 63, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000062, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100062,},
	["Imp1"] = { ID = "Imp1", Index = 64, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000063, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100063,},
	["Imp2"] = { ID = "Imp2", Index = 65, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000064, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100064,},
	["Imp3"] = { ID = "Imp3", Index = 66, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000065, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100065,},
	["Imp4"] = { ID = "Imp4", Index = 67, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000066, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100066,},
	["AImp1"] = { ID = "AImp1", Index = 68, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000067, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100067,},
	["AImp2"] = { ID = "AImp2", Index = 69, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000068, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100068,},
	["AImp3"] = { ID = "AImp3", Index = 70, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000069, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100069,},
	["AImp4"] = { ID = "AImp4", Index = 71, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000070, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100070,},
	["DDef1"] = { ID = "DDef1", Index = 72, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000071, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100071,},
	["DDef2"] = { ID = "DDef2", Index = 73, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000072, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100072,},
	["DDef3"] = { ID = "DDef3", Index = 74, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000073, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100073,},
	["DDef4"] = { ID = "DDef4", Index = 75, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000074, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100074,},
	["Hp"] = { ID = "Hp", Index = 76, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000075, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100075,},
	["Hp1"] = { ID = "Hp1", Index = 77, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000076, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100076,},
	["Hp2"] = { ID = "Hp2", Index = 78, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000077, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100077,},
	["Hp3"] = { ID = "Hp3", Index = 79, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000078, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100078,},
	["Hp4"] = { ID = "Hp4", Index = 80, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000079, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100079,},
	["DHp1"] = { ID = "DHp1", Index = 81, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000080, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100080,},
	["DHp2"] = { ID = "DHp2", Index = 82, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000081, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100081,},
	["DHp3"] = { ID = "DHp3", Index = 83, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000082, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100082,},
	["DHp4"] = { ID = "DHp4", Index = 84, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000083, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100083,},
	["TacticsAtk"] = { ID = "TacticsAtk", Index = 85, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000084, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100084,},
	["TacticsAtk1"] = { ID = "TacticsAtk1", Index = 86, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000085, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100085,},
	["TacticsAtk2"] = { ID = "TacticsAtk2", Index = 87, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000086, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100086,},
	["TacticsAtk3"] = { ID = "TacticsAtk3", Index = 88, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000087, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100087,},
	["TacticsAtk4"] = { ID = "TacticsAtk4", Index = 89, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000088, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100088,},
	["TacticsCd"] = { ID = "TacticsCd", Index = 90, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000089, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100089,},
	["TacticsBlock"] = { ID = "TacticsBlock", Index = nil, Default = nil, BuffName = LG_NIL, BuffDesc = LG_NIL,},
	["TacticsAll"] = { ID = "TacticsAll", Index = 91, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000090, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100090,},
	["TacticsMore"] = { ID = "TacticsMore", Index = 92, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000091, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100091,},
	["ExtraAtk"] = { ID = "ExtraAtk", Index = 119, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000118, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100118,},
	["DmgToHp0"] = { ID = "DmgToHp0", Index = 120, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000119, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100119,},
	["CounterAtk"] = { ID = "CounterAtk", Index = 121, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000120, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100120,},
	["Damage"] = { ID = "Damage", Index = 122, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000121, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100121,},
	["Captive"] = { ID = "Captive", Index = 93, Default = 1000, BuffName = LG_EFFECT_TYPE_NAME_108000092, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100092,},
	["CounterCaptive"] = { ID = "CounterCaptive", Index = 94, Default = 0, BuffName = LG_EFFECT_TYPE_NAME_108000093, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100093,},
	["HeroPveExp"] = { ID = "HeroPveExp", Index = 114, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000113, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100113,},
	["SiegeWounded"] = { ID = "SiegeWounded", Index = 95, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000094, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100094,},
	["SiegeKillArmy"] = { ID = "SiegeKillArmy", Index = 96, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000095, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100095,},
	["CountMember"] = { ID = "CountMember", Index = 97, Default = 50, BuffName = LG_EFFECT_TYPE_NAME_108000096, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100096,},
	["CountRallySoldier"] = { ID = "CountRallySoldier", Index = 98, Default = 20000, BuffName = LG_EFFECT_TYPE_NAME_108000097, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100097,},
	["CountRallyPlayer"] = { ID = "CountRallyPlayer", Index = 99, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000098, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100098,},
	["SpeedRally"] = { ID = "SpeedRally", Index = 100, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000099, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100099,},
	["CountDailyStore"] = { ID = "CountDailyStore", Index = 101, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000100, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100100,},
	["CountHelp"] = { ID = "CountHelp", Index = 102, Default = 3, BuffName = LG_EFFECT_TYPE_NAME_108000101, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100101,},
	["CountUnionStore"] = { ID = "CountUnionStore", Index = 103, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000102, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100102,},
	["SpeedCaravan"] = { ID = "SpeedCaravan", Index = 104, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000103, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100103,},
	["CountRelief"] = { ID = "CountRelief", Index = 105, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000104, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100104,},
	["WeightDeal"] = { ID = "WeightDeal", Index = 106, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000105, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100105,},
	["TimeHelp"] = { ID = "TimeHelp", Index = 107, Default = 30, BuffName = LG_EFFECT_TYPE_NAME_108000106, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100106,},
	["CountGarrison"] = { ID = "CountGarrison", Index = 108, Default = 0, BuffName = LG_EFFECT_TYPE_NAME_108000107, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100107,},
	["Vip10"] = { ID = "Vip10", Index = 113, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000112, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100112,},
	["SilverGachaCount"] = { ID = "SilverGachaCount", Index = 116, Default = 30, BuffName = LG_EFFECT_TYPE_NAME_108000115, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100115,},
	["HotGachaOpen"] = { ID = "HotGachaOpen", Index = 117, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000116, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100116,},
	["PlunderCount"] = { ID = "PlunderCount", Index = 118, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000117, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100117,},
	["VipSign"] = { ID = "VipSign", Index = 130, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000129, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100129,},
	["BombardmentDamage"] = { ID = "BombardmentDamage", Index = 128, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000127, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100127,},
	["MonsterDamage"] = { ID = "MonsterDamage", Index = 129, Default = nil, BuffName = LG_EFFECT_TYPE_NAME_108000128, BuffDesc = LG_EFFECT_TYPE_BUFFDESC_108100128,},
}
