--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_buildlv = {

	[UNION_BUILD_CASTLE_LEVEL_1] = { ID = UNION_BUILD_CASTLE_LEVEL_1, Mode = 1, Lv = 1, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,15}}, PersiaCons = {{1000,100,15}}, ArabCons = {{1000,100,15}}, SlavicCons = {{1000,100,15}},},
	[UNION_BUILD_CASTLE_LEVEL_2] = { ID = UNION_BUILD_CASTLE_LEVEL_2, Mode = 1, Lv = 2, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,16}}, PersiaCons = {{1000,100,16}}, ArabCons = {{1000,100,16}}, SlavicCons = {{1000,100,16}},},
	[UNION_BUILD_CASTLE_LEVEL_3] = { ID = UNION_BUILD_CASTLE_LEVEL_3, Mode = 1, Lv = 3, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,17}}, PersiaCons = {{1000,100,17}}, ArabCons = {{1000,100,17}}, SlavicCons = {{1000,100,17}},},
	[UNION_BUILD_STORE_LEVEL_1] = { ID = UNION_BUILD_STORE_LEVEL_1, Mode = 2, Lv = 1, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,18}}, PersiaCons = {{1000,100,18}}, ArabCons = {{1000,100,18}}, SlavicCons = {{1000,100,18}},},
	[UNION_BUILD_STORE_LEVEL_2] = { ID = UNION_BUILD_STORE_LEVEL_2, Mode = 2, Lv = 2, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,19}}, PersiaCons = {{1000,100,19}}, ArabCons = {{1000,100,19}}, SlavicCons = {{1000,100,19}},},
	[UNION_BUILD_STORE_LEVEL_3] = { ID = UNION_BUILD_STORE_LEVEL_3, Mode = 2, Lv = 3, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,20}}, PersiaCons = {{1000,100,20}}, ArabCons = {{1000,100,20}}, SlavicCons = {{1000,100,20}},},
	[UNION_BUILD_SUPERRES_LEVEL_1] = { ID = UNION_BUILD_SUPERRES_LEVEL_1, Mode = 3, Lv = 1, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,21}}, PersiaCons = {{1000,100,21}}, ArabCons = {{1000,100,21}}, SlavicCons = {{1000,100,21}},},
	[UNION_BUILD_SUPERRES_LEVEL_2] = { ID = UNION_BUILD_SUPERRES_LEVEL_2, Mode = 3, Lv = 2, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,22}}, PersiaCons = {{1000,100,22}}, ArabCons = {{1000,100,22}}, SlavicCons = {{1000,100,22}},},
	[UNION_BUILD_SUPERRES_LEVEL_3] = { ID = UNION_BUILD_SUPERRES_LEVEL_3, Mode = 3, Lv = 3, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,23}}, PersiaCons = {{1000,100,23}}, ArabCons = {{1000,100,23}}, SlavicCons = {{1000,100,23}},},
	[UNION_BUILD_TUTTER_LEVEL_1] = { ID = UNION_BUILD_TUTTER_LEVEL_1, Mode = 4, Lv = 1, Mul = 2, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,24}}, PersiaCons = {{1000,100,24}}, ArabCons = {{1000,100,24}}, SlavicCons = {{1000,100,24}},},
	[UNION_BUILD_TUTTER_LEVEL_2] = { ID = UNION_BUILD_TUTTER_LEVEL_2, Mode = 4, Lv = 2, Mul = 2, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,25}}, PersiaCons = {{1000,100,25}}, ArabCons = {{1000,100,25}}, SlavicCons = {{1000,100,25}},},
	[UNION_BUILD_TUTTER_LEVEL_3] = { ID = UNION_BUILD_TUTTER_LEVEL_3, Mode = 4, Lv = 3, Mul = 2, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,26}}, PersiaCons = {{1000,100,26}}, ArabCons = {{1000,100,26}}, SlavicCons = {{1000,100,26}},},
	[UNION_BUILD_MARCKET_LEVEL_1] = { ID = UNION_BUILD_MARCKET_LEVEL_1, Mode = 5, Lv = 1, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,27}}, PersiaCons = {{1000,100,27}}, ArabCons = {{1000,100,27}}, SlavicCons = {{1000,100,27}},},
	[UNION_BUILD_MARCKET_LEVEL_2] = { ID = UNION_BUILD_MARCKET_LEVEL_2, Mode = 5, Lv = 2, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,28}}, PersiaCons = {{1000,100,28}}, ArabCons = {{1000,100,28}}, SlavicCons = {{1000,100,28}},},
	[UNION_BUILD_MARCKET_LEVEL_3] = { ID = UNION_BUILD_MARCKET_LEVEL_3, Mode = 5, Lv = 3, Mul = 1, Effect = nil, UpExp = 15000, DonateExp = 100, BonusID = nil, ChinaCons = {{1000,100,29}}, PersiaCons = {{1000,100,29}}, ArabCons = {{1000,100,29}}, SlavicCons = {{1000,100,29}},},
}
