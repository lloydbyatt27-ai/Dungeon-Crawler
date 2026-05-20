class_name CharacterStats
extends Resource
## Persistent character data. Lives on the player; survives across scenes.
## Derived stats (HP, mana, damage scaling) are computed methods so they
## always reflect the current attribute values.

@export var class_type: String = "Guardian"
@export var character_name: String = "Hero"

# Progression
@export var level: int = 1
@export var xp: int = 0

# Attributes
@export var strength: int = 12
@export var agility: int = 6
@export var intelligence: int = 4
@export var stamina: int = 10

# Currency
@export var gold: int = 0
@export var essence: float = 0.0

# Unspent points
@export var unspent_attribute_points: int = 0
@export var unspent_skill_points: int = 0

const LEVEL_CAP: int = 50

# Class presets: how attributes auto-allocate on level-up until we add UI
const AUTO_ALLOCATE: Dictionary = {
	"Guardian":  {"strength": 2, "stamina": 1},
	"Mercenary": {"strength": 1, "agility": 1, "stamina": 1},
	"Disciple":  {"intelligence": 2, "stamina": 1},
	"Prowler":   {"agility": 2, "strength": 1},
	"Scout":     {"agility": 2, "stamina": 1},
}


# --- Derived stats (formulas mirror the design doc) ------------------

func max_hp() -> float:
	return 50.0 + stamina * 10.0 + level * 8.0

func max_mana() -> float:
	return 20.0 + intelligence * 2.0 + level * 3.0

func melee_damage_mult() -> float:
	return 1.0 + strength * 0.02

func ranged_damage_mult() -> float:
	return 1.0 + agility * 0.025

func spell_damage_mult() -> float:
	return 1.0 + intelligence * 0.03

func attack_speed_mult() -> float:
	return 1.0 + agility * 0.005

func dodge_chance() -> float:
	return min(0.60, agility * 0.005)

func crit_chance() -> float:
	return 0.05 + agility * 0.002

func crit_damage_mult() -> float:
	return 1.5  # equipment will add to this later

func hp_regen_per_sec() -> float:
	return (max_hp() * 0.005) + (stamina * 0.05)

func mana_regen_per_sec() -> float:
	return (max_mana() * 0.01) + (intelligence * 0.04)

func cooldown_reduction() -> float:
	# % reduction (cap 50%)
	return min(0.5, intelligence * 0.001)


# --- Progression ------------------------------------------------------

func xp_to_next_level() -> int:
	if level >= LEVEL_CAP:
		return 0x7FFFFFFF  # effectively infinity
	return int(100.0 * pow(level, 1.7))


func attribute_points_per_level() -> int:
	# 3 per level, +1 at milestone levels (10, 20, 30, 40, 50)
	if level % 10 == 0:
		return 4
	return 3


## Returns a dict describing the outcome of gaining XP:
##   { "levels_gained": int, "attr_delta": Dictionary, "leftover_xp": int }
func gain_xp(amount: int) -> Dictionary:
	var result := {
		"levels_gained": 0,
		"attr_delta": {"strength": 0, "agility": 0, "intelligence": 0, "stamina": 0},
		"skill_points_gained": 0,
	}
	if level >= LEVEL_CAP:
		return result

	xp += amount
	while xp >= xp_to_next_level() and level < LEVEL_CAP:
		xp -= xp_to_next_level()
		level += 1
		result.levels_gained += 1
		_auto_allocate(result.attr_delta)
		unspent_skill_points += 1
		result.skill_points_gained += 1

	if level >= LEVEL_CAP:
		xp = 0
	return result


func _auto_allocate(delta: Dictionary) -> void:
	# Phase 1: auto-allocate based on class preset. Later we'll banked points
	# for the player to spend in a UI.
	var preset: Dictionary = AUTO_ALLOCATE.get(class_type, AUTO_ALLOCATE["Guardian"])
	for attr in preset:
		var amount: int = int(preset[attr])
		_grant_attr(attr, amount)
		delta[attr] += amount

	# Milestone bonus point banks instead of auto-allocating
	if level % 10 == 0:
		unspent_attribute_points += 1


func _grant_attr(attr_name: String, amount: int) -> void:
	match attr_name:
		"strength": strength += amount
		"agility": agility += amount
		"intelligence": intelligence += amount
		"stamina": stamina += amount


func xp_progress_ratio() -> float:
	var needed := xp_to_next_level()
	if needed <= 0:
		return 1.0
	return clamp(float(xp) / float(needed), 0.0, 1.0)
