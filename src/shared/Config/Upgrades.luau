--[[
	Upgrade/consumable definitions: id, name, coinCost, type (e.g. "consumable").
]]
return {
	{ id = "health_potion_small", name = "Small Health Potion", coinCost = 20, type = "consumable", effect = "heal_25" },
	{ id = "health_potion_medium", name = "Health Potion", coinCost = 50, type = "consumable", effect = "heal_50" },
	{ id = "health_potion_large", name = "Large Health Potion", coinCost = 120, type = "consumable", effect = "heal_100" },
	{ id = "damage_boost_small", name = "Damage Boost (5 min)", coinCost = 75, type = "consumable", effect = "damage_boost_10" },
	{ id = "speed_boost_small", name = "Speed Boost (5 min)", coinCost = 60, type = "consumable", effect = "speed_boost_15" },
}
