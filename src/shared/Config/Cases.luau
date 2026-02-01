--[[
	Case definitions: id, name, keyCost, weaponPool (weapon ids from Weapons config).
	Case 1 = starter; Case 2+ unlock after beating arena bosses (handled later).
]]
return {
	{
		id = "case_starter",
		name = "Starter Case",
		keyCost = 10,
		weaponPool = {
			"w_iron_daggers", "w_metal_sword", "w_wood_scythe", "w_wooden_bow", "w_rusty_spear",
			"w_training_axe", "w_broken_mace", "w_slingshot", "w_iron_club", "w_short_sword",
			"w_pistol_chainsaw_sword", "w_spikey_scythe", "w_crossbow", "w_warhammer", "w_dual_steel_daggers",
			"w_flame_baton", "w_heavy_cleaver", "w_shock_rod", "w_bone_crusher",
			"w_blazefang_sword", "w_stormcaller_spear", "w_blood_moon_scythe",
		},
		unlockCondition = nil, -- always available; later: "arena_1_complete"
	},
	-- Placeholder for future cases (unlock after arena)
	-- { id = "case_premium", name = "Premium Case", keyCost = 50, weaponPool = {...}, unlockCondition = "arena_1_complete" },
}
