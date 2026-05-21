class_name DifficultyModifierDatabase
extends RefCounted
## Opt-in run modifiers. The player toggles any subset before entering a
## dungeon; the active set lives on SaveSystem.active_modifiers and is read
## by DungeonGenerator, BaseEnemy, and Inventory at the relevant moments.
##
## Each modifier carries an `effects` dict that other systems pattern-match
## on. Keys are intentionally narrow so the implementation stays simple:
##   item_drop_mult, gold_mult, xp_mult, enemy_count_mult,
##   enemy_attack_speed_mult, instant_enrage, disable_potions,
##   boss_drop_mult.

const MODIFIERS: Dictionary = {
	"lean_times": {
		"name": "Lean Times",
		"desc": "Item drops -50%, gold +100%.",
		"effects": {"item_drop_mult": 0.5, "gold_mult": 2.0},
		"color": Color(0.85, 0.85, 0.3),
	},
	"pack_hunt": {
		"name": "Pack Hunt",
		"desc": "+50% enemies per room, +30% XP.",
		"effects": {"enemy_count_mult": 1.5, "xp_mult": 1.3},
		"color": Color(0.95, 0.55, 0.55),
	},
	"no_potions": {
		"name": "Dry Run",
		"desc": "Potion belt disabled. Gold +75%.",
		"effects": {"disable_potions": true, "gold_mult": 1.75},
		"color": Color(0.55, 0.85, 1.0),
	},
	"instant_enrage": {
		"name": "Berserk Bosses",
		"desc": "Bosses start in phase 2. Boss drops +50%.",
		"effects": {"instant_enrage": true, "boss_drop_mult": 1.5},
		"color": Color(1.0, 0.40, 0.30),
	},
	"speed_demon": {
		"name": "Speed Demon",
		"desc": "Enemies attack 30% faster. Gold +50%.",
		"effects": {"enemy_attack_speed_mult": 1.3, "gold_mult": 1.5},
		"color": Color(0.85, 0.55, 1.0),
	},
}


static func all_ids() -> Array:
	return MODIFIERS.keys()


static func get_modifier(id: String) -> Dictionary:
	return MODIFIERS.get(id, {})


## Combined gold multiplier across all active modifiers. Multiplicative —
## three +50% modifiers stack to ×3.375, not ×2.5.
static func combined_mult(active: Array, key: String) -> float:
	var m: float = 1.0
	for id in active:
		var data: Dictionary = MODIFIERS.get(id, {})
		var fx: Dictionary = data.get("effects", {})
		if fx.has(key):
			m *= float(fx[key])
	return m


## True if any active modifier has the given boolean flag set.
static func any_flag(active: Array, key: String) -> bool:
	for id in active:
		var data: Dictionary = MODIFIERS.get(id, {})
		var fx: Dictionary = data.get("effects", {})
		if fx.get(key, false):
			return true
	return false
