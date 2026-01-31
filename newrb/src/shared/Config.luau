--[[
	Shared config for crates, weapons (rarities/odds), and upgrades.
	
	Currency System:
	- Keys: Used to buy crates, earned by selling weapons
	- XP: Used to buy upgrades, earned from gameplay
	
	Odds are "1 in X" (e.g. 100000 = 0.001% chance).
]]

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"

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
}

-- Weapons with their rarities and odds
Config.Weapons = {
	-- Common (1 in 2)
	rusty_sword = { id = "rusty_sword", name = "Rusty Sword", rarity = "Common", odds = 2 },
	wooden_bow = { id = "wooden_bow", name = "Wooden Bow", rarity = "Common", odds = 2 },
	iron_dagger = { id = "iron_dagger", name = "Iron Dagger", rarity = "Common", odds = 2 },
	broken_axe = { id = "broken_axe", name = "Broken Axe", rarity = "Common", odds = 2 },
	
	-- Uncommon (1 in 10)
	steel_blade = { id = "steel_blade", name = "Steel Blade", rarity = "Uncommon", odds = 10 },
	hunter_bow = { id = "hunter_bow", name = "Hunter Bow", rarity = "Uncommon", odds = 10 },
	shadow_dagger = { id = "shadow_dagger", name = "Shadow Dagger", rarity = "Uncommon", odds = 10 },
	battle_axe = { id = "battle_axe", name = "Battle Axe", rarity = "Uncommon", odds = 10 },
	
	-- Rare (1 in 100)
	flame_axe = { id = "flame_axe", name = "Flame Axe", rarity = "Rare", odds = 100 },
	frost_staff = { id = "frost_staff", name = "Frost Staff", rarity = "Rare", odds = 100 },
	thunder_blade = { id = "thunder_blade", name = "Thunder Blade", rarity = "Rare", odds = 100 },
	
	-- Epic (1 in 1000)
	storm_cleaver = { id = "storm_cleaver", name = "Storm Cleaver", rarity = "Epic", odds = 1000 },
	void_scythe = { id = "void_scythe", name = "Void Scythe", rarity = "Epic", odds = 1000 },
	phoenix_bow = { id = "phoenix_bow", name = "Phoenix Bow", rarity = "Epic", odds = 1000 },
	
	-- Legendary (1 in 10000)
	dragon_slayer = { id = "dragon_slayer", name = "Dragon Slayer", rarity = "Legendary", odds = 10000 },
	crown_blade = { id = "crown_blade", name = "Crown Blade", rarity = "Legendary", odds = 10000 },
	
	-- Mythic (1 in 100000)
	godly_katana = { id = "godly_katana", name = "Godly Katana", rarity = "Mythic", odds = 100000 },
	celestial_bow = { id = "celestial_bow", name = "Celestial Bow", rarity = "Mythic", odds = 100000 },
}

-- Crates (bought with keys)
Config.Crates = {
	starter = {
		id = "starter",
		name = "Starter Crate",
		keyCost = 5,
		description = "A basic crate with common weapons.",
		weaponPool = {
			"rusty_sword", "wooden_bow", "iron_dagger", "broken_axe",
			"steel_blade", "hunter_bow", "shadow_dagger", "battle_axe",
			"flame_axe", "frost_staff", "thunder_blade",
			"storm_cleaver", "void_scythe", "phoenix_bow",
			"dragon_slayer", "crown_blade",
			"godly_katana", "celestial_bow",
		},
	},
	warrior = {
		id = "warrior",
		name = "Warrior Crate",
		keyCost = 15,
		description = "Higher chance of rare swords and axes.",
		weaponPool = {
			"steel_blade", "battle_axe",
			"flame_axe", "thunder_blade",
			"storm_cleaver",
			"dragon_slayer", "crown_blade",
			"godly_katana",
		},
	},
	hunter = {
		id = "hunter",
		name = "Hunter Crate",
		keyCost = 15,
		description = "Bows and ranged weapons.",
		weaponPool = {
			"wooden_bow", "hunter_bow",
			"frost_staff",
			"phoenix_bow",
			"celestial_bow",
		},
	},
	legendary = {
		id = "legendary",
		name = "Legendary Crate",
		keyCost = 50,
		description = "Better odds for rare items!",
		weaponPool = {
			"flame_axe", "frost_staff", "thunder_blade",
			"storm_cleaver", "void_scythe", "phoenix_bow",
			"dragon_slayer", "crown_blade",
			"godly_katana", "celestial_bow",
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
Config.StartingKeys = 25
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
