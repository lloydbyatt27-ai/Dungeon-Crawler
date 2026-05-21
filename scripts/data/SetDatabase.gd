class_name SetDatabase
extends RefCounted
## Equipment-set definitions. Wearing N pieces of a set grants the
## cumulative bonuses listed under `tiers[N]`. Bonuses are merged into
## CharacterStats by Inventory._refresh_stats after individual item
## bonuses are summed.

const SETS: Dictionary = {
	"iron_conclave": {
		"display_name": "Iron Conclave",
		"piece_ids": ["iron_conclave_helm", "iron_conclave_armor",
		              "iron_conclave_gloves", "iron_conclave_boots"],
		# Bonuses keyed by piece count required to activate them.
		"tiers": {
			2: {"max_hp_bonus": 50.0},
			3: {"strength_bonus": 3, "stamina_bonus": 3},
			4: {"bonus_armor": 50.0, "crit_chance_bonus": 0.05},
		},
		"tier_descriptions": {
			2: "+50 Max HP",
			3: "+3 Strength, +3 Stamina",
			4: "+50 Armor, +5% Crit Chance",
		},
	},
	"stormcaller": {
		"display_name": "Stormcaller Vestments",
		"piece_ids": ["stormcaller_cap", "stormcaller_robe", "stormcaller_gloves"],
		"tiers": {
			2: {"max_mana_bonus": 30.0, "intelligence_bonus": 2},
			3: {"crit_damage_bonus": 0.30, "max_mana_bonus": 50.0},
		},
		"tier_descriptions": {
			2: "+30 Max Mana, +2 Intelligence",
			3: "+30% Crit Damage, +50 Max Mana",
		},
	},
	"bandits_cloak": {
		"display_name": "Bandit's Cloak",
		"piece_ids": ["bandit_hood", "bandit_gloves", "bandit_boots"],
		"tiers": {
			2: {"agility_bonus": 3, "crit_chance_bonus": 0.05},
			3: {"crit_damage_bonus": 0.30, "max_hp_bonus": 30.0},
		},
		"tier_descriptions": {
			2: "+3 Agility, +5% Crit Chance",
			3: "+30% Crit Damage, +30 Max HP",
		},
	},
	"wildheart": {
		"display_name": "Wildheart",
		"piece_ids": ["wildheart_helm", "wildheart_armor", "wildheart_boots"],
		"tiers": {
			2: {"max_hp_bonus": 60.0},
			3: {"strength_bonus": 5, "stamina_bonus": 5, "max_hp_bonus": 50.0},
		},
		"tier_descriptions": {
			2: "+60 Max HP",
			3: "+5 Strength, +5 Stamina, +50 Max HP",
		},
	},
	"suns_vigil": {
		"display_name": "Sun's Vigil",
		"piece_ids": ["vigil_sword", "vigil_helm", "vigil_gloves", "vigil_armor"],
		"tiers": {
			2: {"strength_bonus": 5},
			3: {"weapon_damage": 20.0},
			4: {"crit_chance_bonus": 0.15},
		},
		"tier_descriptions": {
			2: "+5 Strength",
			3: "+20 Weapon Damage",
			4: "+15% Crit Chance",
		},
	},
}


## Returns the set definition Dictionary, or empty Dictionary if unknown.
static func get_set(set_id: String) -> Dictionary:
	return SETS.get(set_id, {})


## Count how many distinct set pieces (by piece_id) are equipped right now.
## Duplicate pieces don't count twice.
static func count_pieces(set_id: String, equipped_items: Array) -> int:
	var def: Dictionary = get_set(set_id)
	if def.is_empty():
		return 0
	var seen: Dictionary = {}
	for it in equipped_items:
		if it == null:
			continue
		if it.set_id != set_id:
			continue
		if it.item_id in def.piece_ids and not seen.has(it.item_id):
			seen[it.item_id] = true
	return seen.size()


## Apply set bonuses to a CharacterStats given the currently-equipped items
## list. Cumulative — each tier requirement met adds its bonuses.
static func apply_to_stats(stats: CharacterStats, equipped_items: Array) -> void:
	# Bucket equipped items by set
	var by_set: Dictionary = {}
	for it in equipped_items:
		if it == null or it.set_id == "":
			continue
		if not by_set.has(it.set_id):
			by_set[it.set_id] = []
		by_set[it.set_id].append(it)
	for set_id in by_set:
		var count: int = count_pieces(set_id, by_set[set_id])
		var def: Dictionary = get_set(set_id)
		for tier in def.get("tiers", {}):
			if count >= int(tier):
				_apply_bonus_dict(stats, def.tiers[tier])


static func _apply_bonus_dict(stats: CharacterStats, b: Dictionary) -> void:
	stats.bonus_strength += int(b.get("strength_bonus", 0))
	stats.bonus_agility += int(b.get("agility_bonus", 0))
	stats.bonus_intelligence += int(b.get("intelligence_bonus", 0))
	stats.bonus_stamina += int(b.get("stamina_bonus", 0))
	stats.bonus_max_hp += float(b.get("max_hp_bonus", 0.0))
	stats.bonus_max_mana += float(b.get("max_mana_bonus", 0.0))
	stats.bonus_armor += float(b.get("bonus_armor", 0.0))
	stats.bonus_crit_chance += float(b.get("crit_chance_bonus", 0.0))
	stats.bonus_crit_damage += float(b.get("crit_damage_bonus", 0.0))
	stats.bonus_weapon_damage += float(b.get("weapon_damage", 0.0))
