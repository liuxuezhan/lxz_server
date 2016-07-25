--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_gacha_piont = {

	[GACHA_PIONT_1] = { ID = GACHA_PIONT_1, Require = 50, BonusPolicy = "mutex_award", Bonus = {{"item",1006001,1,10000}},},
	[GACHA_PIONT_2] = { ID = GACHA_PIONT_2, Require = 200, BonusPolicy = "mutex_award", Bonus = {{"item",1006003,1,10000}},},
	[GACHA_PIONT_3] = { ID = GACHA_PIONT_3, Require = 500, BonusPolicy = "mutex_award", Bonus = {{"item",1006004,1,10000}},},
}
