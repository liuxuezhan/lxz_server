--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_union_donate = {

	[UNION_TECH_CLASS_1] = { ID = UNION_TECH_CLASS_1, Primary = {{1,3000,50},{2,3000,50}}, Medium = {6,10}, Senior = {6,20}, Pincome = {100,100,40}, Mincome = {500,500,200}, Sincome = {2500,2500,1000}, TmAdd = 720,},
	[UNION_TECH_CLASS_2] = { ID = UNION_TECH_CLASS_2, Primary = {{1,5000,50},{2,5000,50}}, Medium = {6,10}, Senior = {6,20}, Pincome = {100,100,100}, Mincome = {500,500,500}, Sincome = {2500,2500,2500}, TmAdd = 720,},
	[UNION_TECH_CLASS_3] = { ID = UNION_TECH_CLASS_3, Primary = {{1,5000,25},{2,5000,25},{3,1000,25},{4,200,25}}, Medium = {6,10}, Senior = {6,20}, Pincome = {100,100,160}, Mincome = {500,500,800}, Sincome = {2500,2500,4000}, TmAdd = 720,},
	[UNION_TECH_CLASS_4] = { ID = UNION_TECH_CLASS_4, Primary = {{1,9000,25},{2,9000,25},{3,1800,25},{4,320,25}}, Medium = {6,10}, Senior = {6,20}, Pincome = {100,100,220}, Mincome = {500,500,1100}, Sincome = {2500,2500,5500}, TmAdd = 720,},
}
