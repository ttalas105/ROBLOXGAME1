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
			"w_rusty_sword", "w_wooden_bow", "w_iron_dagger", "w_club", "w_spear",
			"w_steel_sword", "w_hunting_bow", "w_mace", "w_halberd",
			"w_flame_blade", "w_frost_bow", "w_void_dagger", "w_storm_hammer",
			"w_dragon_slayer", "w_phoenix_bow", "w_shadow_reaper",
			"w_excalibur", "w_infinity_edge", "w_cosmic_scythe",
		},
		unlockCondition = nil, -- always available; later: "arena_1_complete"
	},
	-- Placeholder for future cases (unlock after arena)
	-- { id = "case_premium", name = "Premium Case", keyCost = 50, weaponPool = {...}, unlockCondition = "arena_1_complete" },
}
