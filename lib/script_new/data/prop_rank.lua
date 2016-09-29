--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_rank = {

	[RANK_1] = { ID = RANK_1, Name = LG_RANK_NAME_165100001, Class = 1, ListA = LG_RANK_LISTA_165200001, ListB = LG_RANK_LISTB_165300001, Num = 150, Limit = 1000, IsPerson = 1, Keys = {"clv", "time"}, Skeys = {-1,1},},
	[RANK_2] = { ID = RANK_2, Name = LG_RANK_NAME_165100002, Class = 1, ListA = LG_RANK_LISTA_165200002, ListB = LG_RANK_LISTB_165300002, Num = 150, Limit = 1000, IsPerson = 1, Keys = {"lv", "time"}, Skeys = {-1,1},},
	[RANK_3] = { ID = RANK_3, Name = LG_RANK_NAME_165100003, Class = 1, ListA = LG_RANK_LISTA_165200003, ListB = LG_RANK_LISTB_165300003, Num = 150, Limit = 1000, IsPerson = 1, Keys = {"pow"}, Skeys = {-1},},
	[RANK_4] = { ID = RANK_4, Name = LG_RANK_NAME_165100004, Class = 1, ListA = LG_RANK_LISTA_165200004, ListB = LG_RANK_LISTB_165300004, Num = 150, Limit = 1000, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_5] = { ID = RANK_5, Name = LG_RANK_NAME_165100005, Class = 2, ListA = LG_RANK_LISTA_165200005, ListB = LG_RANK_LISTB_165300005, Num = 150, Limit = 1000, IsPerson = 0, Keys = {"union_pow"}, Skeys = {-1},},
	[RANK_6] = { ID = RANK_6, Name = LG_RANK_NAME_165100006, Class = 2, ListA = LG_RANK_LISTA_165200006, ListB = LG_RANK_LISTB_165300006, Num = 150, Limit = 1000, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_7] = { ID = RANK_7, Name = LG_RANK_NAME_165100007, Class = 3, ListA = LG_RANK_LISTA_165200007, ListB = LG_RANK_LISTB_165300007, Num = 150, Limit = 9999999, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_8] = { ID = RANK_8, Name = LG_RANK_NAME_165100008, Class = 3, ListA = LG_RANK_LISTA_165200008, ListB = LG_RANK_LISTB_165300008, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_9] = { ID = RANK_9, Name = LG_RANK_NAME_165100009, Class = 3, ListA = LG_RANK_LISTA_165200009, ListB = LG_RANK_LISTB_165300009, Num = 150, Limit = 9999999, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_10] = { ID = RANK_10, Name = LG_RANK_NAME_165100010, Class = 3, ListA = LG_RANK_LISTA_165200010, ListB = LG_RANK_LISTB_165300010, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_11] = { ID = RANK_11, Name = LG_RANK_NAME_165100011, Class = 3, ListA = LG_RANK_LISTA_165200011, ListB = LG_RANK_LISTB_165300011, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_12] = { ID = RANK_12, Name = LG_RANK_NAME_165100012, Class = 3, ListA = LG_RANK_LISTA_165200012, ListB = LG_RANK_LISTB_165300012, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_13] = { ID = RANK_13, Name = LG_RANK_NAME_165100013, Class = 3, ListA = LG_RANK_LISTA_165200013, ListB = LG_RANK_LISTB_165300013, Num = 150, Limit = 9999999, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
}
