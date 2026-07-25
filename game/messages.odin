package game

MSG_TITLE :: "GIGAWATT GALAXY"

MSG_NEW_GAME :: "new game"
MSG_EXIT :: "exit"
MSG_RESUME :: "resume"
MSG_RESTART :: "restart"
MSG_MAIN_MENU :: "main menu"

MSG_PAUSED :: "PAUSED"

MSG_TUTORIAL_START :: "DRAG AND RELEASE TO LAUNCH YOUR FIRST ASTEROID"

Messages :: enum {
	Title,
	NewGame,
	Exit,
	Resume,
	Restart,
	MainMenu,
	Paused,
	Tutorial_Start,

	// Celestials
	Celestial_None,
	Celestial_Asteroid,
	Celestial_Moonlet,
	Celestial_DwarfPlanet,
	Celestial_SubEarth,
	Celestial_SuperEarth,
	Celestial_MegaEarth,
	Celestial_MiniNeptune,
	Celestial_SubNeptune,
	Celestial_SuperNeptune,
	Celestial_GiantPlanet,
	Celestial_SuperJupiter,
	Celestial_Star,
	Celestial_Unknown,

	// Control Menu
	ControlMenu_TabDirect,
	ControlMenu_TabEmitter,
	ControlMenu_TabHardware,
	ControlMenu_Payload,
	ControlMenu_Cadence,
	ControlMenu_PresetBurst,
	ControlMenu_PresetSteady,
	ControlMenu_PresetSustained,
	ControlMenu_PresetTrickle,
	ControlMenu_HardwareComingSoon,

	// Modifiers
	Modifier_GravityBoost,
	Modifier_EnergyMagnet,
	Modifier_Inf,

	// Upgrade Categories
	UpgradeCategory_Physics,
	UpgradeCategory_Economy,
	UpgradeCategory_Automation,
	UpgradeCategory_Hardware,

	// Upgrade Menu & Tooltips
	UpgradeMenu_Header,
	UpgradeMenu_Owned,
	UpgradeMenu_Energy,
	UpgradeMenu_Hint,
	UpgradeMenu_Max,
	UpgradeMenu_Base,
	UpgradeMenu_Level,
	UpgradeMenu_Effect,
	UpgradeMenu_Capability,
	UpgradeMenu_Unlocks,
	UpgradeMenu_Cost,
	UpgradeMenu_Status,
	UpgradeMenu_StatusMaxed,
	UpgradeMenu_StatusPrereqLocked,
	UpgradeMenu_StatusNeedLifetimeEnergy,
	UpgradeMenu_StatusNeedCelestial,
	UpgradeMenu_StatusNeedUpgrades,
	UpgradeMenu_ClickToBuy,
	UpgradeMenu_InsufficientEnergy,

	// Upgrade Names & Descriptions
	Upgrade_GravityTuning_Name,
	Upgrade_GravityTuning_Desc,
	Upgrade_OrbitalYield_Name,
	Upgrade_OrbitalYield_Desc,
	Upgrade_CollectorReach_Name,
	Upgrade_CollectorReach_Desc,
	Upgrade_MoonletFoundry_Name,
	Upgrade_MoonletFoundry_Desc,
	Upgrade_LaunchEfficiency_Name,
	Upgrade_LaunchEfficiency_Desc,
	Upgrade_SlingshotForesight_Name,
	Upgrade_SlingshotForesight_Desc,
	Upgrade_StarFurnace_Name,
	Upgrade_StarFurnace_Desc,
	Upgrade_SalvageRights_Name,
	Upgrade_SalvageRights_Desc,
	Upgrade_EmitterLogistics_Name,
	Upgrade_EmitterLogistics_Desc,
	Upgrade_EmitterPersistence_Name,
	Upgrade_EmitterPersistence_Desc,
	Upgrade_ResearchGrants_Name,
	Upgrade_ResearchGrants_Desc,
	Upgrade_TractorField_Name,
	Upgrade_TractorField_Desc,
	Upgrade_StellarLegacy_Name,
	Upgrade_StellarLegacy_Desc,
}

Messages_Language :: enum {
	En,
}

Messages_EN: [Messages_Language][Messages]string = {
	.En = {
		.Title                                = MSG_TITLE,
		.NewGame                              = MSG_NEW_GAME,
		.Exit                                 = MSG_EXIT,
		.Resume                               = MSG_RESUME,
		.Restart                              = MSG_RESTART,
		.MainMenu                             = MSG_MAIN_MENU,
		.Paused                               = MSG_PAUSED,
		.Tutorial_Start                       = MSG_TUTORIAL_START,

		// Celestials
		.Celestial_None                       = "none",
		.Celestial_Asteroid                   = "asteroid",
		.Celestial_Moonlet                    = "moonlet",
		.Celestial_DwarfPlanet                = "dwarf planet",
		.Celestial_SubEarth                   = "sub-earth",
		.Celestial_SuperEarth                 = "super earth",
		.Celestial_MegaEarth                  = "mega earth",
		.Celestial_MiniNeptune                = "mini neptune",
		.Celestial_SubNeptune                 = "sub-neptune",
		.Celestial_SuperNeptune               = "super neptune",
		.Celestial_GiantPlanet                = "giant planet",
		.Celestial_SuperJupiter               = "super jupiter",
		.Celestial_Star                       = "star",
		.Celestial_Unknown                    = "unknown",

		// Control Menu
		.ControlMenu_TabDirect                = "DIRECT LAUNCHES",
		.ControlMenu_TabEmitter               = "AUTOMATED EMITTERS",
		.ControlMenu_TabHardware              = "SPECIAL HARDWARE (COMING SOON)",
		.ControlMenu_Payload                  = "PAYLOAD:",
		.ControlMenu_Cadence                  = "CADENCE:",
		.ControlMenu_PresetBurst              = "BURST",
		.ControlMenu_PresetSteady             = "STEADY",
		.ControlMenu_PresetSustained          = "SUSTAINED",
		.ControlMenu_PresetTrickle            = "TRICKLE",
		.ControlMenu_HardwareComingSoon       = "SPECIAL HARDWARE COMING SOON",

		// Modifiers
		.Modifier_GravityBoost                = "Gravity Boost",
		.Modifier_EnergyMagnet                = "Energy Magnet",
		.Modifier_Inf                         = "INF",

		// Upgrade Categories
		.UpgradeCategory_Physics              = "PHYSICS",
		.UpgradeCategory_Economy              = "ECONOMY",
		.UpgradeCategory_Automation           = "AUTOMATION",
		.UpgradeCategory_Hardware             = "HARDWARE",

		// Upgrade Menu & Tooltips
		.UpgradeMenu_Header                   = "UPGRADES",
		.UpgradeMenu_Owned                    = "Owned",
		.UpgradeMenu_Energy                   = "Energy",
		.UpgradeMenu_Hint                     = "Drag to pan · HOME to recenter",
		.UpgradeMenu_Max                      = "MAX",
		.UpgradeMenu_Base                     = "Base",
		.UpgradeMenu_Level                    = "Level:",
		.UpgradeMenu_Effect                   = "Effect:",
		.UpgradeMenu_Capability               = "Capability:",
		.UpgradeMenu_Unlocks                  = "Unlocks:",
		.UpgradeMenu_Cost                     = "Cost:",
		.UpgradeMenu_Status                   = "Status:",
		.UpgradeMenu_StatusMaxed              = "MAXED",
		.UpgradeMenu_StatusPrereqLocked       = "Locked (Prerequisites unmet)",
		.UpgradeMenu_StatusNeedLifetimeEnergy = "Locked (Need %s Lifetime Energy)",
		.UpgradeMenu_StatusNeedCelestial      = "Locked (Discover %s first)",
		.UpgradeMenu_StatusNeedUpgrades       = "Locked (Need %s upgrades)",
		.UpgradeMenu_ClickToBuy               = "Click to Buy",
		.UpgradeMenu_InsufficientEnergy       = "Insufficient Energy",

		// Upgrade Names & Descriptions
		.Upgrade_GravityTuning_Name           = "Gravity Tuning",
		.Upgrade_GravityTuning_Desc           = "Increases universal gravitational constant.",
		.Upgrade_OrbitalYield_Name            = "Orbital Yield",
		.Upgrade_OrbitalYield_Desc            = "Increases energy generated from orbiting bodies.",
		.Upgrade_CollectorReach_Name          = "Collector Reach",
		.Upgrade_CollectorReach_Desc          = "Expands the reach of cursor collector interaction.",
		.Upgrade_MoonletFoundry_Name          = "Moonlet Foundry",
		.Upgrade_MoonletFoundry_Desc          = "Unlocks Moonlet celestials in the slingshot menu.",
		.Upgrade_LaunchEfficiency_Name        = "Launch Efficiency",
		.Upgrade_LaunchEfficiency_Desc        = "Reduces energy cost of launching celestials.",
		.Upgrade_SlingshotForesight_Name      = "Slingshot Foresight",
		.Upgrade_SlingshotForesight_Desc      = "Extends slingshot orbit trajectory preview duration.",
		.Upgrade_StarFurnace_Name             = "Star Furnace",
		.Upgrade_StarFurnace_Desc             = "Boosts energy output from energy sources.",
		.Upgrade_SalvageRights_Name           = "Salvage Rights",
		.Upgrade_SalvageRights_Desc           = "Increases energy refund when objects leave or decay.",
		.Upgrade_EmitterLogistics_Name        = "Emitter Logistics",
		.Upgrade_EmitterLogistics_Desc        = "Reduces the cost of emitter presets.",
		.Upgrade_EmitterPersistence_Name      = "Emitter Persistence",
		.Upgrade_EmitterPersistence_Desc      = "Increases duration of active emitter stations.",
		.Upgrade_ResearchGrants_Name          = "Research Grants",
		.Upgrade_ResearchGrants_Desc          = "Reduces base cost of all other upgrade nodes.",
		.Upgrade_TractorField_Name            = "Tractor Field",
		.Upgrade_TractorField_Desc            = "Attracts floating energy fragments toward your cursor.",
		.Upgrade_StellarLegacy_Name           = "Stellar Legacy",
		.Upgrade_StellarLegacy_Desc           = "Meta progression placeholder.",
	},
}

// Simple message system to allow for easy localization in the future.
// For now, it just supports English.
t :: proc(g: ^Game, msg: Messages) -> cstring {
	lang := Messages_Language.En
	return cstring(raw_data(Messages_EN[lang][msg]))
}

t_str :: proc(g: ^Game, msg: Messages) -> string {
	lang := Messages_Language.En
	return Messages_EN[lang][msg]
}
