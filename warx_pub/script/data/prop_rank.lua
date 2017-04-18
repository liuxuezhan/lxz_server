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
	[RANK_7] = { ID = RANK_7, Name = LG_RANK_NAME_165100007, Class = 3, ListA = LG_RANK_LISTA_165200007, ListB = LG_RANK_LISTB_165300007, Num = 150, Limit = 20, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_8] = { ID = RANK_8, Name = LG_RANK_NAME_165100008, Class = 3, ListA = LG_RANK_LISTA_165200008, ListB = LG_RANK_LISTB_165300008, Num = 150, Limit = 200, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_9] = { ID = RANK_9, Name = LG_RANK_NAME_165100009, Class = 3, ListA = LG_RANK_LISTA_165200009, ListB = LG_RANK_LISTB_165300009, Num = 150, Limit = 100, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_10] = { ID = RANK_10, Name = LG_RANK_NAME_165100010, Class = 3, ListA = LG_RANK_LISTA_165200010, ListB = LG_RANK_LISTB_165300010, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_11] = { ID = RANK_11, Name = LG_RANK_NAME_165100011, Class = 3, ListA = LG_RANK_LISTA_165200011, ListB = LG_RANK_LISTB_165300011, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_12] = { ID = RANK_12, Name = LG_RANK_NAME_165100012, Class = 3, ListA = LG_RANK_LISTA_165200012, ListB = LG_RANK_LISTB_165300012, Num = 150, Limit = 500, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_13] = { ID = RANK_13, Name = LG_RANK_NAME_165100013, Class = 3, ListA = LG_RANK_LISTA_165200013, ListB = LG_RANK_LISTB_165300013, Num = 150, Limit = 20, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_14] = { ID = RANK_14, Name = LG_RANK_NAME_165100013, Class = 3, ListA = LG_RANK_LISTA_165200013, ListB = LG_RANK_LISTB_165300013, Num = 150, Limit = 9999999, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_15] = { ID = RANK_15, Name = LG_RANK_NAME_165100014, Class = 3, ListA = LG_RANK_LISTA_165200014, ListB = LG_RANK_LISTB_165300014, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_16] = { ID = RANK_16, Name = LG_RANK_NAME_165100015, Class = 3, ListA = LG_RANK_LISTA_165200015, ListB = LG_RANK_LISTB_165300015, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_17] = { ID = RANK_17, Name = LG_RANK_NAME_165100016, Class = 3, ListA = LG_RANK_LISTA_165200016, ListB = LG_RANK_LISTB_165300016, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_18] = { ID = RANK_18, Name = LG_RANK_NAME_165100017, Class = 3, ListA = LG_RANK_LISTA_165200017, ListB = LG_RANK_LISTB_165300017, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_19] = { ID = RANK_19, Name = LG_RANK_NAME_165100018, Class = 3, ListA = LG_RANK_LISTA_165200018, ListB = LG_RANK_LISTB_165300018, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_20] = { ID = RANK_20, Name = LG_RANK_NAME_165100019, Class = 3, ListA = LG_RANK_LISTA_165200019, ListB = LG_RANK_LISTB_165300019, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_21] = { ID = RANK_21, Name = LG_RANK_NAME_165100020, Class = 3, ListA = LG_RANK_LISTA_165200020, ListB = LG_RANK_LISTB_165300020, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_22] = { ID = RANK_22, Name = LG_RANK_NAME_165100021, Class = 3, ListA = LG_RANK_LISTA_165200021, ListB = LG_RANK_LISTB_165300021, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_23] = { ID = RANK_23, Name = LG_RANK_NAME_165100022, Class = 3, ListA = LG_RANK_LISTA_165200022, ListB = LG_RANK_LISTB_165300022, Num = 150, Limit = 9999999, IsPerson = 1, Keys = {"score","time"}, Skeys = {-1,1},},
	[RANK_25] = { ID = RANK_25, Name = LG_RANK_NAME_165100024, Class = 3, ListA = LG_RANK_LISTA_165200024, ListB = LG_RANK_LISTB_165300024, Num = 150, Limit = 1000, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
	[RANK_26] = { ID = RANK_26, Name = LG_RANK_NAME_165100025, Class = 3, ListA = LG_RANK_LISTA_165200025, ListB = LG_RANK_LISTB_165300025, Num = 150, Limit = 9999999, IsPerson = 0, Keys = {"union_kill"}, Skeys = {-1},},
	[RANK_27] = { ID = RANK_27, Name = LG_RANK_NAME_165100026, Class = 3, ListA = LG_RANK_LISTA_165200026, ListB = LG_RANK_LISTB_165300026, Num = 150, Limit = 100, IsPerson = 1, Keys = {"kill"}, Skeys = {-1},},
}
