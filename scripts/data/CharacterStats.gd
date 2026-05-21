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
@export var soul_shards: int = 0
@export var essence: float = 0.0

# Unspent points
@export var unspent_attribute_points: int = 0
@export var unspent_skill_points: int = 0

# Endless mode record
@export var best_endless_floor: int = 0

# Quests already completed by this character (prevents repeats)
@export var completed_quest_ids: Array[String] = []

# Skill upgrade ranks (0..MAX_SKILL_RANK per skill_id). Spent via the
# SkillsUI panel using `unspent_skill_points`. Each rank grants:
#   damage skill (aoe/cone/projectile): +20% damage and -10% cooldown
#   buff skill:                          +25% duration
@export var skill_ranks: Dictionary = {}
const MAX_SKILL_RANK: int = 3

# Permadeath flag chosen at character creation. If true, death wipes the
# save file and returns to the main menu.
@export var hardcore: bool = false

# Player's chosen 3 active skills. Empty array means "use class defaults".
# Populated when the player visits the Skill Trainer and rearranges their
# loadout, or via the first sync in PlayerController on a fresh character.
@export var active_skill_ids: Array[String] = []

# Paragon progression — once level hits LEVEL_CAP, all further xp banks
# here and each completed paragon level grants +1 unspent_attribute_point.
# No cap — paragon is the endgame treadmill.
@export var paragon_level: int = 0
@export var paragon_xp: int = 0

# Equipment bonuses — set by Inventory whenever items are equipped/unequipped.
# Not exported; recomputed at runtime from the current loadout.
var bonus_strength: int = 0
var bonus_agility: int = 0
var bonus_intelligence: int = 0
var bonus_stamina: int = 0
var bonus_max_hp: float = 0.0
var bonus_max_mana: float = 0.0
var bonus_weapon_damage: float = 0.0
var bonus_armor: float = 0.0
var bonus_crit_chance: float = 0.0
var bonus_crit_damage: float = 0.0

const LEVEL_CAP: int = 50


## Reset all attributes to the chosen class's starting preset.
## Called from ClassSelect after the player picks their class.
func apply_class_preset(class_id: String) -> void:
	var data: Dictionary = ClassDatabase.get_class_data(class_id)
	class_type = class_id
	level = 1
	xp = 0
	unspent_attribute_points = 0
	unspent_skill_points = 0
	gold = 0
	essence = 0.0
	var s: Dictionary = data.get("stats", {})
	strength = int(s.get("strength", 12))
	agility = int(s.get("agility", 6))
	intelligence = int(s.get("intelligence", 4))
	stamina = int(s.get("stamina", 10))


# --- Effective attributes (base + equipment bonus) -------------------

func effective_strength() -> int:    return strength + bonus_strength
func effective_agility() -> int:     return agility + bonus_agility
func effective_intelligence() -> int: return intelligence + bonus_intelligence
func effective_stamina() -> int:     return stamina + bonus_stamina


# --- Derived stats (formulas mirror the design doc) ------------------

func max_hp() -> float:
	return 50.0 + effective_stamina() * 10.0 + level * 8.0 + bonus_max_hp

func max_mana() -> float:
	return 20.0 + effective_intelligence() * 2.0 + level * 3.0 + bonus_max_mana

func melee_damage_mult() -> float:
	return 1.0 + effective_strength() * 0.02

func ranged_damage_mult() -> float:
	return 1.0 + effective_agility() * 0.025

func spell_damage_mult() -> float:
	return 1.0 + effective_intelligence() * 0.03

func attack_speed_mult() -> float:
	return 1.0 + effective_agility() * 0.005

func dodge_chance() -> float:
	return min(0.60, effective_agility() * 0.005)

func crit_chance() -> float:
	return 0.05 + effective_agility() * 0.002 + bonus_crit_chance

func crit_damage_mult() -> float:
	return 1.5 + bonus_crit_damage

func hp_regen_per_sec() -> float:
	return (max_hp() * 0.005) + (effective_stamina() * 0.05)

func mana_regen_per_sec() -> float:
	return (max_mana() * 0.01) + (effective_intelligence() * 0.04)

func cooldown_reduction() -> float:
	# % reduction (cap 50%)
	return min(0.5, effective_intelligence() * 0.001)

func damage_reduction() -> float:
	# Armor → DR curve from the design doc, capped at 75%
	var armor := bonus_armor
	if armor <= 0:
		return 0.0
	return min(0.75, armor / (armor + 100.0 + level * 10.0))


# --- Progression ------------------------------------------------------

func xp_to_next_level() -> int:
	if level >= LEVEL_CAP:
		return xp_to_next_paragon()
	return int(100.0 * pow(level, 1.7))


## Paragon's curve mirrors the late-game level curve but grows linearly
## with paragon level, so each tier takes a bit longer than the last
## without becoming unattainable.
func xp_to_next_paragon() -> int:
	return int(100.0 * pow(LEVEL_CAP, 1.7) * (1.0 + paragon_level * 0.05))


func attribute_points_per_level() -> int:
	# 3 per level, +1 at milestone levels (10, 20, 30, 40, 50)
	if level % 10 == 0:
		return 4
	return 3


## Returns a dict describing the outcome of gaining XP:
##   { "levels_gained": int, "attr_delta": Dictionary,
##     "skill_points_gained": int, "paragon_gained": int }
func gain_xp(amount: int) -> Dictionary:
	var result := {
		"levels_gained": 0,
		"attr_delta": {"strength": 0, "agility": 0, "intelligence": 0, "stamina": 0},
		"skill_points_gained": 0,
		"paragon_gained": 0,
	}

	# Pre-cap: standard level-up loop
	if level < LEVEL_CAP:
		xp += amount
		while xp >= xp_to_next_level() and level < LEVEL_CAP:
			xp -= xp_to_next_level()
			level += 1
			result.levels_gained += 1
			_auto_allocate(result.attr_delta)
			unspent_skill_points += 1
			result.skill_points_gained += 1
		# Overflow rolls into paragon as soon as the cap is hit
		if level >= LEVEL_CAP:
			paragon_xp += xp
			xp = 0
	else:
		# Post-cap: everything banks straight to paragon
		paragon_xp += amount

	# Paragon level-up loop — each paragon = +1 attribute point bank
	while paragon_xp >= xp_to_next_paragon():
		paragon_xp -= xp_to_next_paragon()
		paragon_level += 1
		unspent_attribute_points += 1
		result.paragon_gained += 1

	return result


func _auto_allocate(delta: Dictionary) -> void:
	# Auto-allocate based on the class preset in ClassDatabase.
	# Later we'll surface the choice via a UI.
	var class_data: Dictionary = ClassDatabase.get_class_data(class_type)
	var preset: Dictionary = class_data.get("auto_allocate", {"strength": 2, "stamina": 1})
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


func skill_rank(skill_id: String) -> int:
	return int(skill_ranks.get(skill_id, 0))


## Returns true if a rank was successfully purchased.
func invest_skill_point(skill_id: String) -> bool:
	if unspent_skill_points <= 0:
		return false
	var cur := skill_rank(skill_id)
	if cur >= MAX_SKILL_RANK:
		return false
	skill_ranks[skill_id] = cur + 1
	unspent_skill_points -= 1
	return true


func xp_progress_ratio() -> float:
	if level >= LEVEL_CAP:
		var needed := xp_to_next_paragon()
		if needed <= 0:
			return 1.0
		return clamp(float(paragon_xp) / float(needed), 0.0, 1.0)
	var needed_l := xp_to_next_level()
	if needed_l <= 0:
		return 1.0
	return clamp(float(xp) / float(needed_l), 0.0, 1.0)
