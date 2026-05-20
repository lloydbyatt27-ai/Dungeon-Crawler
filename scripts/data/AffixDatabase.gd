class_name AffixDatabase
extends RefCounted
## Prefix and suffix pools for procedural item generation. Each affix carries:
##   - a display word that becomes part of the item name
##   - an offsets dict (stat_name → value range)
##   - an applies_to whitelist by item type (or empty for "any")
##
## Generation rolls a base item, picks N prefixes + M suffixes by rarity,
## and sums the stat contributions onto the item.

const PREFIXES: Array = [
	# --- Damage-flavored (apply to weapons) ---
	{"name": "Vicious",   "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(2, 5)}},
	{"name": "Cruel",     "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(4, 9), "crit_chance_bonus": Vector2(0.02, 0.05)}},
	{"name": "Burning",   "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(1, 3)}},
	{"name": "Frozen",    "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(1, 3)}},
	{"name": "Shadow",    "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(2, 4), "crit_damage_bonus": Vector2(0.10, 0.25)}},
	{"name": "Piercing",  "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(3, 6)}},
	# --- Defense-flavored (armor / offhand) ---
	{"name": "Sturdy",    "applies": ["ARMOR", "OFFHAND"], "stats": {"armor": Vector2(2, 5)}},
	{"name": "Reinforced","applies": ["ARMOR", "OFFHAND"], "stats": {"armor": Vector2(4, 9), "max_hp_bonus": Vector2(8, 18)}},
	{"name": "Heavy",     "applies": ["ARMOR"], "stats": {"armor": Vector2(6, 14), "max_hp_bonus": Vector2(15, 30)}},
	# --- Any slot ---
	{"name": "Blessed",   "applies": [], "stats": {"max_hp_bonus": Vector2(6, 15)}},
	{"name": "Mystic",    "applies": [], "stats": {"max_mana_bonus": Vector2(5, 12), "intelligence_bonus": Vector2(1, 2)}},
	{"name": "Swift",     "applies": [], "stats": {"agility_bonus": Vector2(1, 3)}},
	{"name": "Mighty",    "applies": [], "stats": {"strength_bonus": Vector2(1, 3)}},
	{"name": "Hardy",     "applies": [], "stats": {"stamina_bonus": Vector2(1, 3)}},
]

const SUFFIXES: Array = [
	{"name": "of Haste",       "applies": [], "stats": {"agility_bonus": Vector2(1, 3)}},
	{"name": "of the Bear",    "applies": [], "stats": {"stamina_bonus": Vector2(2, 4), "max_hp_bonus": Vector2(8, 18)}},
	{"name": "of the Wolf",    "applies": [], "stats": {"agility_bonus": Vector2(2, 4)}},
	{"name": "of the Sage",    "applies": [], "stats": {"intelligence_bonus": Vector2(2, 4), "max_mana_bonus": Vector2(8, 16)}},
	{"name": "of the Bull",    "applies": [], "stats": {"strength_bonus": Vector2(2, 4)}},
	{"name": "of Slaying",     "applies": ["WEAPON"], "stats": {"crit_chance_bonus": Vector2(0.03, 0.08)}},
	{"name": "of Carnage",     "applies": ["WEAPON"], "stats": {"crit_damage_bonus": Vector2(0.15, 0.35)}},
	{"name": "of the Vampire", "applies": ["WEAPON"], "stats": {"weapon_damage": Vector2(2, 5)}},
	{"name": "of the Mountain","applies": ["ARMOR"],  "stats": {"armor": Vector2(4, 10), "stamina_bonus": Vector2(1, 3)}},
	{"name": "of Warding",     "applies": ["ARMOR", "OFFHAND"], "stats": {"armor": Vector2(3, 7)}},
	{"name": "of Vigor",       "applies": [], "stats": {"max_hp_bonus": Vector2(10, 25)}},
	{"name": "of Insight",     "applies": [], "stats": {"max_mana_bonus": Vector2(8, 20)}},
]


## Roll a prefix/suffix that's eligible for the given item type. Returns null
## if none match (shouldn't happen with the current pools).
static func roll_prefix(item_type: String, rng: RandomNumberGenerator) -> Dictionary:
	return _roll_from(PREFIXES, item_type, rng)


static func roll_suffix(item_type: String, rng: RandomNumberGenerator) -> Dictionary:
	return _roll_from(SUFFIXES, item_type, rng)


static func _roll_from(pool: Array, item_type: String, rng: RandomNumberGenerator) -> Dictionary:
	var candidates: Array = []
	for entry in pool:
		var applies: Array = entry.get("applies", [])
		if applies.is_empty() or item_type in applies:
			candidates.append(entry)
	if candidates.is_empty():
		return {}
	return candidates[rng.randi() % candidates.size()]


## Roll a magnitude inside the affix's range and add to the item's stats.
static func apply_to_item(item: Item, affix: Dictionary, rng: RandomNumberGenerator) -> void:
	if affix.is_empty():
		return
	var stats: Dictionary = affix.get("stats", {})
	for stat_name in stats:
		var range_v: Vector2 = stats[stat_name]
		var lo: float = range_v.x
		var hi: float = range_v.y
		var value: float = rng.randf_range(lo, hi)
		# Integer bonuses round; float bonuses (crit / armor) stay decimal
		match stat_name:
			"strength_bonus", "agility_bonus", "intelligence_bonus", "stamina_bonus":
				item.set(stat_name, int(item.get(stat_name)) + int(round(value)))
			_:
				item.set(stat_name, float(item.get(stat_name)) + value)
