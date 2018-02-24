--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_resource = {

	[DEF_RES_FOOD] = { ID = DEF_RES_FOOD, CodeKey = "food", Name = LG_RESOURCE_NAME_124100000, Mul = 1, Open = 1, Desc = LG_RESOURCE_DESC_124200000, Color = 1,},
	[DEF_RES_WOOD] = { ID = DEF_RES_WOOD, CodeKey = "wood", Name = LG_RESOURCE_NAME_124100001, Mul = 1, Open = 1, Desc = LG_RESOURCE_DESC_124200001, Color = 1,},
	[DEF_RES_IRON] = { ID = DEF_RES_IRON, CodeKey = "iron", Name = LG_RESOURCE_NAME_124100002, Mul = 5, Open = 10, Desc = LG_RESOURCE_DESC_124200002, Color = 1,},
	[DEF_RES_ENERGY] = { ID = DEF_RES_ENERGY, CodeKey = "energy", Name = LG_RESOURCE_NAME_124100003, Mul = 20, Open = 15, Desc = LG_RESOURCE_DESC_124200003, Color = 1,},
	[DEF_RES_GOLD] = { ID = DEF_RES_GOLD, CodeKey = "gold", Name = LG_RESOURCE_NAME_124100005, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200005, Color = 4,},
	[DEF_RES_SILVER] = { ID = DEF_RES_SILVER, CodeKey = "silver", Name = LG_RESOURCE_NAME_124100007, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200007, Color = 3,},
	[DEF_RES_PERSONALHONOR] = { ID = DEF_RES_PERSONALHONOR, CodeKey = "personalhonor", Name = LG_RESOURCE_NAME_124100008, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200008, Color = 2,},
	[DEF_RES_UNITHONOR] = { ID = DEF_RES_UNITHONOR, CodeKey = "unithonor", Name = LG_RESOURCE_NAME_124100009, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200009, Color = 2,},
	[DEF_RES_MONSTER_GOLD] = { ID = DEF_RES_MONSTER_GOLD, CodeKey = "monster_gold", Name = LG_RESOURCE_NAME_124100010, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200010, Color = 3,},
	[DEF_RES_LORDEXP] = { ID = DEF_RES_LORDEXP, CodeKey = "exp", Name = LG_RESOURCE_NAME_124100011, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200011, Color = 3,},
	[DEF_RES_HEROEXP] = { ID = DEF_RES_HEROEXP, CodeKey = "heroexp", Name = LG_RESOURCE_NAME_124100012, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200012, Color = 2,},
	[DEF_RES_LORDSINEW] = { ID = DEF_RES_LORDSINEW, CodeKey = "sinew", Name = LG_RESOURCE_NAME_124100013, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200013, Color = 2,},
	[DEF_RES_VIPEXP] = { ID = DEF_RES_VIPEXP, CodeKey = "vip_exp", Name = LG_RESOURCE_NAME_124100014, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200014, Color = 3,},
	[DEF_RES_MARSEXP] = { ID = DEF_RES_MARSEXP, CodeKey = "mars_exp", Name = LG_RESOURCE_NAME_124100015, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200015, Color = 2,},
	[DEF_RES_KING_GOLD] = { ID = DEF_RES_KING_GOLD, CodeKey = "kw_gold", Name = LG_RESOURCE_NAME_124100016, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200016, Color = 3,},
	[DEF_RES_TC_GOLD] = { ID = DEF_RES_TC_GOLD, CodeKey = "manor_gold", Name = LG_RESOURCE_NAME_124100017, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200017, Color = 3,},
	[DEF_RES_AT_GOLD] = { ID = DEF_RES_AT_GOLD, CodeKey = "relic_gold", Name = LG_RESOURCE_NAME_124100018, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200018, Color = 3,},
	[DEF_RES_SNAMAN_STONE] = { ID = DEF_RES_SNAMAN_STONE, CodeKey = "snaman_stone", Name = LG_RESOURCE_NAME_124100019, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200019, Color = 3,},
	[DEF_RES_CRS_GOLD] = { ID = DEF_RES_CRS_GOLD, CodeKey = "cross_gold", Name = LG_RESOURCE_NAME_124100020, Mul = nil, Open = nil, Desc = LG_RESOURCE_DESC_124200020, Color = 4,},
	[DEF_RES_REFUGEE] = { ID = DEF_RES_REFUGEE, CodeKey = "refugee", Name = LG_RESOURCE_NAME_124100021, Mul = 14, Open = nil, Desc = LG_RESOURCE_DESC_124200021, Color = 3,},
}
