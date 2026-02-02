--[[
	Shared config for crates, weapons (rarities/odds), and upgrades.
	
	Currency System:
	- Keys: Used to buy crates, earned by selling weapons
	- XP: Used to buy upgrades, earned from gameplay
	
	Odds are "1 in X" (e.g. 100000 = 0.001% chance).
]]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Exotic" | "Divine"

export type WeaponDef = {
	id: string,
	name: string,
	rarity: Rarity,
	odds: number, -- "1 in X" (e.g. 100000)
}

export type CrateDef = {
	id: string,
	name: string,
	keyCost: number,
	description: string,
	weaponPool: { string }, -- weapon ids
}

export type UpgradeDef = {
	id: string,
	name: string,
	xpCost: number,
	description: string,
	maxLevel: number?, -- nil = infinite/consumable
}

local Config = {}

-- Rarity display order and colors (for UI)
Config.Rarities = {
	Common = { order = 1, color = Color3.fromRGB(176, 176, 176) },
	Uncommon = { order = 2, color = Color3.fromRGB(94, 255, 94) },
	Rare = { order = 3, color = Color3.fromRGB(94, 150, 255) },
	Epic = { order = 4, color = Color3.fromRGB(190, 94, 255) },
	Legendary = { order = 5, color = Color3.fromRGB(255, 170, 0) },
	Mythic = { order = 6, color = Color3.fromRGB(255, 50, 100) },
	Exotic = { order = 7, color = Color3.fromRGB(220, 20, 60) },
	Divine = { order = 8, color = Color3.fromRGB(0, 255, 255) },
}

-- Weapons with their rarities and odds
Config.Weapons = {
	-- Common (1 in 2)
	iron_daggers = { id = "iron_daggers", name = "Iron Daggers", rarity = "Common", odds = 2 },
	metal_sword = { id = "metal_sword", name = "Metal Sword", rarity = "Common", odds = 2 },
	wood_scythe = { id = "wood_scythe", name = "Wood Scythe", rarity = "Common", odds = 2 },
	wooden_bow = { id = "wooden_bow", name = "Wooden Bow", rarity = "Common", odds = 2 },
	rusty_spear = { id = "rusty_spear", name = "Rusty Spear", rarity = "Common", odds = 2 },
	training_axe = { id = "training_axe", name = "Training Axe", rarity = "Common", odds = 2 },
	broken_mace = { id = "broken_mace", name = "Broken Mace", rarity = "Common", odds = 2 },
	slingshot = { id = "slingshot", name = "Slingshot", rarity = "Common", odds = 2 },
	iron_club = { id = "iron_club", name = "Iron Club", rarity = "Common", odds = 2 },
	short_sword = { id = "short_sword", name = "Short Sword", rarity = "Common", odds = 2 },
	
	-- Rare (1 in 100)
	pistol = { id = "pistol", name = "Pistol", rarity = "Rare", odds = 100 },
	chainsaw_sword = { id = "chainsaw_sword", name = "Chainsaw Sword", rarity = "Rare", odds = 100 },
	spikey_scythe = { id = "spikey_scythe", name = "Spikey Scythe", rarity = "Rare", odds = 100 },
	crossbow = { id = "crossbow", name = "Crossbow", rarity = "Rare", odds = 100 },
	war_hammer = { id = "war_hammer", name = "War Hammer", rarity = "Rare", odds = 100 },
	dual_steel_daggers = { id = "dual_steel_daggers", name = "Dual Steel Daggers", rarity = "Rare", odds = 100 },
	flame_baton = { id = "flame_baton", name = "Flame Baton", rarity = "Rare", odds = 100 },
	heavy_cleaver = { id = "heavy_cleaver", name = "Heavy Cleaver", rarity = "Rare", odds = 100 },
	shock_rod = { id = "shock_rod", name = "Shock Rod", rarity = "Rare", odds = 100 },
	bone_crusher = { id = "bone_crusher", name = "Bone Crusher", rarity = "Rare", odds = 100 },
	
	-- Epic (1 in 1000)
	blazefang_sword = { id = "blazefang_sword", name = "Blazefang Sword", rarity = "Epic", odds = 1000 },
	stormcaller_spear = { id = "stormcaller_spear", name = "Stormcaller Spear", rarity = "Epic", odds = 1000 },
	gravewarden_axe = { id = "gravewarden_axe", name = "Gravewarden Axe", rarity = "Epic", odds = 1000 },
	frostbound_bow = { id = "frostbound_bow", name = "Frostbound Bow", rarity = "Epic", odds = 1000 },
	blood_moon_scythe = { id = "blood_moon_scythe", name = "Blood Moon Scythe", rarity = "Epic", odds = 1000 },
	arcane_warhammer = { id = "arcane_warhammer", name = "Arcane Warhammer", rarity = "Epic", odds = 1000 },
	shadowstep_daggers = { id = "shadowstep_daggers", name = "Shadowstep Daggers", rarity = "Epic", odds = 1000 },
	venom_lash_whip = { id = "venom_lash_whip", name = "Venom Lash Whip", rarity = "Epic", odds = 1000 },
	runic_crossbow = { id = "runic_crossbow", name = "Runic Crossbow", rarity = "Epic", odds = 1000 },
	inferno_flail = { id = "inferno_flail", name = "Inferno Flail", rarity = "Epic", odds = 1000 },
	
	-- Legendary (1 in 10000)
	dragonheart_greatsword = { id = "dragonheart_greatsword", name = "Dragonheart Greatsword", rarity = "Legendary", odds = 10000 },
	tempest_glaive = { id = "tempest_glaive", name = "Tempest Glaive", rarity = "Legendary", odds = 10000 },
	reaper_king_scythe = { id = "reaper_king_scythe", name = "Reaper King Scythe", rarity = "Legendary", odds = 10000 },
	celestial_longbow = { id = "celestial_longbow", name = "Celestial Longbow", rarity = "Legendary", odds = 10000 },
	obsidian_colossus_hammer = { id = "obsidian_colossus_hammer", name = "Obsidian Colossus Hammer", rarity = "Legendary", odds = 10000 },
	voidfang_daggers = { id = "voidfang_daggers", name = "Voidfang Daggers", rarity = "Legendary", odds = 10000 },
	phoenix_blade = { id = "phoenix_blade", name = "Phoenix Blade", rarity = "Legendary", odds = 10000 },
	thunderlord_mace = { id = "thunderlord_mace", name = "Thunderlord Mace", rarity = "Legendary", odds = 10000 },
	blood_oath_spear = { id = "blood_oath_spear", name = "Blood Oath Spear", rarity = "Legendary", odds = 10000 },
	spectral_greatshield = { id = "spectral_greatshield", name = "Spectral Greatshield", rarity = "Legendary", odds = 10000 },
	
	-- Exotic (1 in 50000)
	chrono_blade = { id = "chrono_blade", name = "Chrono Blade", rarity = "Exotic", odds = 50000 },
	soul_devourer_scythe = { id = "soul_devourer_scythe", name = "Soul Devourer Scythe", rarity = "Exotic", odds = 50000 },
	eclipse_bow = { id = "eclipse_bow", name = "Eclipse Bow", rarity = "Exotic", odds = 50000 },
	storm_gods_hammer = { id = "storm_gods_hammer", name = "Storm God's Hammer", rarity = "Exotic", odds = 50000 },
	void_monarch_daggers = { id = "void_monarch_daggers", name = "Void Monarch Daggers", rarity = "Exotic", odds = 50000 },
	infernal_tyrant_sword = { id = "infernal_tyrant_sword", name = "Infernal Tyrant Sword", rarity = "Exotic", odds = 50000 },
	plaguebearer_flail = { id = "plaguebearer_flail", name = "Plaguebearer Flail", rarity = "Exotic", odds = 50000 },
	astral_lance = { id = "astral_lance", name = "Astral Lance", rarity = "Exotic", odds = 50000 },
	grim_covenant_axe = { id = "grim_covenant_axe", name = "Grim Covenant Axe", rarity = "Exotic", odds = 50000 },
	worldrender_greatsword = { id = "worldrender_greatsword", name = "Worldrender Greatsword", rarity = "Exotic", odds = 50000 },
	
	-- Divine (1 in 100000)
	anris_blade_of_ascension = { id = "anris_blade_of_ascension", name = "Anri's Blade of Ascension", rarity = "Divine", odds = 100000 },
	arbels_astral_singularity = { id = "arbels_astral_singularity", name = "Arbel's Astral Singularity", rarity = "Divine", odds = 100000 },
	farids_titanbreaker_gauntlets = { id = "farids_titanbreaker_gauntlets", name = "Farid's Titanbreaker Gauntlets", rarity = "Divine", odds = 100000 },
	rajans_mindweaver_blade = { id = "rajans_mindweaver_blade", name = "Rajan's Mindweaver Blade", rarity = "Divine", odds = 100000 },
	thomass_fang_of_twin_realms = { id = "thomass_fang_of_twin_realms", name = "Thomas's Fang of the Twin Realms", rarity = "Divine", odds = 100000 },
	aydins_gilded_dominion = { id = "aydins_gilded_dominion", name = "Aydin's Gilded Dominion", rarity = "Divine", odds = 100000 },
	aryas_courtmaster_chakram = { id = "aryas_courtmaster_chakram", name = "Arya's Courtmaster Chakram", rarity = "Divine", odds = 100000 },
	kims_architect_of_whispers = { id = "kims_architect_of_whispers", name = "Kim's Architect of Whispers", rarity = "Divine", odds = 100000 },
	salims_equilibrium_staff = { id = "salims_equilibrium_staff", name = "Salim's Equilibrium Staff", rarity = "Divine", odds = 100000 },
}

-- Crates (bought with keys)
Config.Crates = {
	starter = {
		id = "starter",
		name = "Case 1",
		keyCost = 5,
		description = "A basic crate with common weapons.",
		rarityChances = {
			Common = 80,
			Rare = 20,
		},
		weaponPool = {
			-- Common
			"iron_daggers", "metal_sword", "wood_scythe", "wooden_bow", "rusty_spear",
			"training_axe", "broken_mace", "slingshot", "iron_club", "short_sword",
			-- Rare
			"pistol", "chainsaw_sword", "spikey_scythe", "crossbow", "war_hammer",
			"dual_steel_daggers", "flame_baton", "heavy_cleaver", "shock_rod", "bone_crusher",
		},
	},
	case2 = {
		id = "case2",
		name = "Case 2",
		keyCost = 300,
		description = "",
		rarityChances = {
			Common = 70,
			Rare = 30,
		},
		weaponPool = {
			-- Common
			"iron_daggers", "metal_sword", "wood_scythe", "wooden_bow", "rusty_spear",
			"training_axe", "broken_mace", "slingshot", "iron_club", "short_sword",
			-- Rare
			"pistol", "chainsaw_sword", "spikey_scythe", "crossbow", "war_hammer",
			"dual_steel_daggers", "flame_baton", "heavy_cleaver", "shock_rod", "bone_crusher",
		},
	},
	case3 = {
		id = "case3",
		name = "Case 3",
		keyCost = 800,
		description = "",
		rarityChances = {
			Common = 65,
			Rare = 34,
			Epic = 1,
		},
		weaponPool = {
			-- Common
			"iron_daggers", "metal_sword", "wood_scythe", "wooden_bow", "rusty_spear",
			"training_axe", "broken_mace", "slingshot", "iron_club", "short_sword",
			-- Rare
			"pistol", "chainsaw_sword", "spikey_scythe", "crossbow", "war_hammer",
			"dual_steel_daggers", "flame_baton", "heavy_cleaver", "shock_rod", "bone_crusher",
			-- Epic
			"blazefang_sword", "stormcaller_spear", "gravewarden_axe", "frostbound_bow", "blood_moon_scythe",
			"arcane_warhammer", "shadowstep_daggers", "venom_lash_whip", "runic_crossbow", "inferno_flail",
		},
	},
}

-- Upgrades (bought with XP)
Config.Upgrades = {
	-- Permanent upgrades
	luck_boost = {
		id = "luck_boost",
		name = "Luck Boost",
		xpCost = 500,
		description = "+5% better odds on crate rolls",
		maxLevel = 10,
	},
	key_magnet = {
		id = "key_magnet",
		name = "Key Magnet",
		xpCost = 300,
		description = "+10% more keys from selling weapons",
		maxLevel = 5,
	},
	xp_boost = {
		id = "xp_boost",
		name = "XP Boost",
		xpCost = 400,
		description = "+15% XP from all sources",
		maxLevel = 5,
	},
	inventory_expansion = {
		id = "inventory_expansion",
		name = "Inventory Expansion",
		xpCost = 1000,
		description = "+10 inventory slots",
		maxLevel = 10,
	},
	-- Consumables (no max level)
	double_roll = {
		id = "double_roll",
		name = "Double Roll Token",
		xpCost = 200,
		description = "Next crate gives 2 weapons instead of 1",
		maxLevel = nil,
	},
	reroll_token = {
		id = "reroll_token",
		name = "Reroll Token",
		xpCost = 150,
		description = "Reroll a weapon you don't like",
		maxLevel = nil,
	},
}

-- Starting currency
Config.StartingKeys = 10000
Config.StartingXP = 100
Config.BaseInventorySlots = 10

-- Sell value (KEYS earned) per rarity when selling weapons
Config.SellValueByRarity = {
	Common = 1,
	Uncommon = 3,
	Rare = 10,
	Epic = 50,
	Legendary = 250,
	Mythic = 1000,
}

-- Shop square positions in the world (raised higher to be visible)
Config.ShopPositions = {
	CrateShop = Vector3.new(-20, 5, 0),
	SellShop = Vector3.new(0, 5, 0),
	UpgradesShop = Vector3.new(20, 5, 0),
}

Config.ShopSquareSize = Vector3.new(10, 6, 10)

return Config
