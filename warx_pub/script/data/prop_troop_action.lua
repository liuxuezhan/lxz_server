--
-- $Id$
--

module( "resmng" )
svnnum("$Id$")

prop_troop_action = {

	[DefultFollow] = { TroopAction = DefultFollow, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[Wait] = { TroopAction = Wait, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[SiegePlayer] = { TroopAction = SiegePlayer, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[Back] = { TroopAction = Back, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[JoinMass] = { TroopAction = JoinMass, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 1, SpeedCavaran = 0, Default = nil, IsPvp = 2, CanSpecial = 0,},
	[HoldDefense] = { TroopAction = HoldDefense, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[Mass] = { TroopAction = Mass, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 2, CanSpecial = 0,},
	[Gather] = { TroopAction = Gather, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 2, CanSpecial = 0,},
	[SiegeMonster] = { TroopAction = SiegeMonster, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[Monster] = { TroopAction = Monster, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[Spy] = { TroopAction = Spy, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 100, IsPvp = 1, CanSpecial = 1,},
	[SiegeCamp] = { TroopAction = SiegeCamp, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[SaveRes] = { TroopAction = SaveRes, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 10, IsPvp = 0, CanSpecial = 1,},
	[GetRes] = { TroopAction = GetRes, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 10, IsPvp = 0, CanSpecial = 1,},
	[UnionBuild] = { TroopAction = UnionBuild, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[UnionFixBuild] = { TroopAction = UnionFixBuild, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[WaitMass] = { TroopAction = WaitMass, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[MassMonster] = { TroopAction = MassMonster, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[BuySpecialty] = { TroopAction = BuySpecialty, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 1,},
	[ConfirmSpecialty] = { TroopAction = ConfirmSpecialty, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 1,},
	[CancleSpecialty] = { TroopAction = CancleSpecialty, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 1,},
	[UnionBuilding] = { TroopAction = UnionBuilding, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[UnionUpgradeBuild] = { TroopAction = UnionUpgradeBuild, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[Declare] = { TroopAction = Declare, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 100, IsPvp = 0, CanSpecial = 1,},
	[SiegeNpc] = { TroopAction = SiegeNpc, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[Tower] = { TroopAction = Tower, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[King] = { TroopAction = King, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[HeroBack] = { TroopAction = HeroBack, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 100, IsPvp = 0, CanSpecial = 1,},
	[MonsterAtkPly] = { TroopAction = MonsterAtkPly, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 4, IsPvp = 0, CanSpecial = 0,},
	[SiegeMonsterCity] = { TroopAction = SiegeMonsterCity, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = 20, IsPvp = 0, CanSpecial = 0,},
	[SiegeTaskNpc] = { TroopAction = SiegeTaskNpc, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[AtkMC] = { TroopAction = AtkMC, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[SiegeUnion] = { TroopAction = SiegeUnion, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[LostTemple] = { TroopAction = LostTemple, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[SupportArm] = { TroopAction = SupportArm, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[SupportRes] = { TroopAction = SupportRes, SpeedMarch = 0, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 1, Default = 10, IsPvp = 0, CanSpecial = 1,},
	[Camp] = { TroopAction = Camp, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[Refugee] = { TroopAction = Refugee, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 0, CanSpecial = 0,},
	[HoldDefenseNPC] = { TroopAction = HoldDefenseNPC, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[HoldDefenseKING] = { TroopAction = HoldDefenseKING, SpeedMarch = 1, SpeedMarchPvE = 0, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
	[HoldDefenseLT] = { TroopAction = HoldDefenseLT, SpeedMarch = 1, SpeedMarchPvE = 1, SpeedRally = 0, SpeedCavaran = 0, Default = nil, IsPvp = 1, CanSpecial = 0,},
}