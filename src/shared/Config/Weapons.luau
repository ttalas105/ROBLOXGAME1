--[[
	Weapon definitions: id, name, rarity, sellPrice (coins), oddsDenominator (for "1 in X" display).
	oddsDenominator = how rare this weapon is when rolling (higher = rarer).
]]
return {
	-- Common (1 in 2 to 1 in 10)
	{ id = "w_rusty_sword", name = "Rusty Sword", rarity = "Common", sellPrice = 5, oddsDenominator = 2 },
	{ id = "w_wooden_bow", name = "Wooden Bow", rarity = "Common", sellPrice = 5, oddsDenominator = 3 },
	{ id = "w_iron_dagger", name = "Iron Dagger", rarity = "Common", sellPrice = 8, oddsDenominator = 4 },
	{ id = "w_club", name = "Wooden Club", rarity = "Common", sellPrice = 6, oddsDenominator = 5 },
	{ id = "w_spear", name = "Bronze Spear", rarity = "Common", sellPrice = 7, oddsDenominator = 6 },

	-- Uncommon (1 in 25 to 1 in 50)
	{ id = "w_steel_sword", name = "Steel Sword", rarity = "Uncommon", sellPrice = 25, oddsDenominator = 25 },
	{ id = "w_hunting_bow", name = "Hunting Bow", rarity = "Uncommon", sellPrice = 30, oddsDenominator = 30 },
	{ id = "w_mace", name = "Iron Mace", rarity = "Uncommon", sellPrice = 28, oddsDenominator = 35 },
	{ id = "w_halberd", name = "Halberd", rarity = "Uncommon", sellPrice = 32, oddsDenominator = 40 },

	-- Rare (1 in 200 to 1 in 500)
	{ id = "w_flame_blade", name = "Flame Blade", rarity = "Rare", sellPrice = 150, oddsDenominator = 200 },
	{ id = "w_frost_bow", name = "Frost Bow", rarity = "Rare", sellPrice = 160, oddsDenominator = 250 },
	{ id = "w_void_dagger", name = "Void Dagger", rarity = "Rare", sellPrice = 140, oddsDenominator = 300 },
	{ id = "w_storm_hammer", name = "Storm Hammer", rarity = "Rare", sellPrice = 170, oddsDenominator = 400 },

	-- Epic (1 in 5000 to 1 in 10000)
	{ id = "w_dragon_slayer", name = "Dragon Slayer", rarity = "Epic", sellPrice = 800, oddsDenominator = 5000 },
	{ id = "w_phoenix_bow", name = "Phoenix Bow", rarity = "Epic", sellPrice = 850, oddsDenominator = 7500 },
	{ id = "w_shadow_reaper", name = "Shadow Reaper", rarity = "Epic", sellPrice = 900, oddsDenominator = 10000 },

	-- Legendary (1 in 100000)
	{ id = "w_excalibur", name = "Excalibur", rarity = "Legendary", sellPrice = 5000, oddsDenominator = 100000 },
	{ id = "w_infinity_edge", name = "Infinity Edge", rarity = "Legendary", sellPrice = 5000, oddsDenominator = 100000 },
	{ id = "w_cosmic_scythe", name = "Cosmic Scythe", rarity = "Legendary", sellPrice = 5000, oddsDenominator = 100000 },
}
