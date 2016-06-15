--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_tw_limit = {

	[UNION_TECH_CLASS_1] = { ID = UNION_TECH_CLASS_1, Primary = {"or",{1,3000},{2,3000}}, Medium = {"or",{1,3000},{2,3000},{3,10}}, Senior = {"or",{1,3000},{2,3000},{3,20}}, Cond = {}, Pincome = {200,200,40}, Mincome = {1000,1000,200}, Sincome = {1000,1000,200}, TmAdd = 720,},
	[UNION_TECH_CLASS_2] = { ID = UNION_TECH_CLASS_2, Primary = {"or",{1,5000},{2,5000}}, Medium = {"or",{1,5000},{2,5000},{3,10}}, Senior = {"or",{1,5000},{2,5000},{3,20}}, Cond = {}, Pincome = {200,200,40}, Mincome = {1000,1000,200}, Sincome = {1000,1000,200}, TmAdd = 720,},
	[UNION_TECH_CLASS_3] = { ID = UNION_TECH_CLASS_3, Primary = {"or",{1,7000},{2,7000}}, Medium = {"or",{1,7000},{2,7000},{3,10}}, Senior = {"or",{1,7000},{2,7000},{3,20}}, Cond = {}, Pincome = {200,200,40}, Mincome = {1000,1000,200}, Sincome = {1000,1000,200}, TmAdd = 720,},
	[UNION_TECH_CLASS_4] = { ID = UNION_TECH_CLASS_4, Primary = {"or",{1,9000},{2,9000}}, Medium = {"or",{1,9000},{2,9000},{3,10}}, Senior = {"or",{1,9000},{2,9000},{3,20}}, Cond = {}, Pincome = {200,200,40}, Mincome = {1000,1000,200}, Sincome = {1000,1000,200}, TmAdd = 720,},
	[UNION_TECH_CLASS_5] = { ID = UNION_TECH_CLASS_5, Primary = {"or",{1,11000},{2,11000}}, Medium = {"or",{1,11000},{2,11000},{3,10}}, Senior = {"or",{1,11000},{2,11000},{3,20}}, Cond = {}, Pincome = {200,200,40}, Mincome = {1000,1000,200}, Sincome = {1000,1000,200}, TmAdd = 720,},
}
