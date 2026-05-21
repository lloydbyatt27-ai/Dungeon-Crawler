class_name ItemDatabase
extends RefCounted
## Phase 1 hand-authored item templates with rarity-weighted random generation.
## Phase 2 will replace this with an affix-based procedural system.

const ITEM_TEMPLATES: Array = [
	# --- Weapons (COMMON) ---
	{ "id": "rusty_dagger", "name": "Rusty Dagger", "type": "WEAPON", "rarity": "COMMON",
	  "weapon_damage": 4.0 },
	{ "id": "iron_sword", "name": "Iron Sword", "type": "WEAPON", "rarity": "COMMON",
	  "weapon_damage": 8.0, "strength_bonus": 1 },
	{ "id": "hand_axe", "name": "Hand Axe", "type": "WEAPON", "rarity": "COMMON",
	  "weapon_damage": 9.0 },

	# --- Weapons (UNCOMMON) ---
	{ "id": "steel_blade", "name": "Steel Blade", "type": "WEAPON", "rarity": "UNCOMMON",
	  "weapon_damage": 14.0, "strength_bonus": 2, "crit_chance_bonus": 0.02 },
	{ "id": "warhammer", "name": "Warhammer", "type": "WEAPON", "rarity": "UNCOMMON",
	  "weapon_damage": 18.0, "strength_bonus": 3 },
	{ "id": "swift_blade", "name": "Swift Blade", "type": "WEAPON", "rarity": "UNCOMMON",
	  "weapon_damage": 12.0, "agility_bonus": 3, "crit_chance_bonus": 0.03 },

	# --- Weapons (RARE) ---
	{ "id": "flameblade", "name": "Flameblade", "type": "WEAPON", "rarity": "RARE",
	  "weapon_damage": 22.0, "strength_bonus": 4, "crit_chance_bonus": 0.05, "crit_damage_bonus": 0.30,
	  "description": "Searing edge, glows faintly red." },
	{ "id": "executioners_axe", "name": "Executioner's Axe", "type": "WEAPON", "rarity": "RARE",
	  "weapon_damage": 30.0, "strength_bonus": 6,
	  "description": "Heavy, slow, devastating." },

	# --- Armor (COMMON) ---
	{ "id": "padded_jerkin", "name": "Padded Jerkin", "type": "ARMOR", "rarity": "COMMON",
	  "armor": 5.0, "max_hp_bonus": 15.0 },
	{ "id": "leather_armor", "name": "Leather Armor", "type": "ARMOR", "rarity": "COMMON",
	  "armor": 8.0, "max_hp_bonus": 12.0, "stamina_bonus": 1 },

	# --- Armor (UNCOMMON) ---
	{ "id": "chain_mail", "name": "Chain Mail", "type": "ARMOR", "rarity": "UNCOMMON",
	  "armor": 18.0, "max_hp_bonus": 25.0, "stamina_bonus": 2 },
	{ "id": "scale_mail", "name": "Scale Mail", "type": "ARMOR", "rarity": "UNCOMMON",
	  "armor": 22.0, "max_hp_bonus": 20.0, "strength_bonus": 1 },

	# --- Armor (RARE) ---
	{ "id": "plate_mail", "name": "Plate Mail", "type": "ARMOR", "rarity": "RARE",
	  "armor": 32.0, "max_hp_bonus": 50.0, "stamina_bonus": 3, "strength_bonus": 1,
	  "description": "Heavy and slow, but blunts most blows." },
	{ "id": "guardians_aegis", "name": "Guardian's Aegis", "type": "ARMOR", "rarity": "RARE",
	  "armor": 28.0, "max_hp_bonus": 75.0, "stamina_bonus": 4,
	  "description": "Worn by warriors of the Code." },

	# --- Off-hands (COMMON) ---
	{ "id": "wooden_shield", "name": "Wooden Shield", "type": "OFFHAND", "rarity": "COMMON",
	  "armor": 4.0, "max_hp_bonus": 10.0 },

	# --- Off-hands (UNCOMMON) ---
	{ "id": "iron_shield", "name": "Iron Shield", "type": "OFFHAND", "rarity": "UNCOMMON",
	  "armor": 10.0, "max_hp_bonus": 20.0, "stamina_bonus": 1 },
	{ "id": "spiked_buckler", "name": "Spiked Buckler", "type": "OFFHAND", "rarity": "UNCOMMON",
	  "armor": 6.0, "weapon_damage": 4.0, "strength_bonus": 1 },

	# --- Off-hands (RARE) ---
	{ "id": "tower_shield", "name": "Tower Shield", "type": "OFFHAND", "rarity": "RARE",
	  "armor": 18.0, "max_hp_bonus": 45.0, "stamina_bonus": 2, "strength_bonus": 1,
	  "description": "A wall of iron between you and the world." },

	# --- Helmets (COMMON) ---
	{ "id": "leather_cap", "name": "Leather Cap", "type": "HELMET", "rarity": "COMMON",
	  "armor": 3.0, "max_hp_bonus": 6.0 },
	{ "id": "iron_helm", "name": "Iron Helm", "type": "HELMET", "rarity": "COMMON",
	  "armor": 6.0, "max_hp_bonus": 8.0, "stamina_bonus": 1 },
	# --- Helmets (RARE) ---
	{ "id": "crown_of_vigil", "name": "Crown of Vigil", "type": "HELMET", "rarity": "RARE",
	  "armor": 14.0, "max_hp_bonus": 30.0, "stamina_bonus": 2, "intelligence_bonus": 2,
	  "description": "Forged for sentinels of the inner sanctum." },

	# --- Gloves (COMMON) ---
	{ "id": "leather_gloves", "name": "Leather Gloves", "type": "GLOVES", "rarity": "COMMON",
	  "armor": 2.0, "agility_bonus": 1 },
	{ "id": "iron_gauntlets", "name": "Iron Gauntlets", "type": "GLOVES", "rarity": "COMMON",
	  "armor": 5.0, "strength_bonus": 1 },
	# --- Gloves (RARE) ---
	{ "id": "gauntlets_of_power", "name": "Gauntlets of Power", "type": "GLOVES", "rarity": "RARE",
	  "armor": 10.0, "weapon_damage": 4.0, "strength_bonus": 3, "crit_damage_bonus": 0.20,
	  "description": "Each strike lands as if from twice your weight." },

	# --- Boots (COMMON) ---
	{ "id": "worn_boots", "name": "Worn Boots", "type": "BOOTS", "rarity": "COMMON",
	  "armor": 2.0, "agility_bonus": 1 },
	{ "id": "iron_boots", "name": "Iron Boots", "type": "BOOTS", "rarity": "COMMON",
	  "armor": 5.0, "max_hp_bonus": 8.0 },
	# --- Boots (RARE) ---
	{ "id": "boots_of_swiftness", "name": "Boots of Swiftness", "type": "BOOTS", "rarity": "RARE",
	  "armor": 8.0, "agility_bonus": 4, "crit_chance_bonus": 0.04,
	  "description": "Hard to follow, harder to catch." },

	# --- Boss-locked LEGENDARY drops ---
	{ "id": "chieftains_cleaver", "name": "Chieftain's Cleaver", "type": "WEAPON", "rarity": "LEGENDARY",
	  "weapon_damage": 28.0, "strength_bonus": 5, "stamina_bonus": 2,
	  "crit_chance_bonus": 0.08, "crit_damage_bonus": 0.40,
	  "description": "Pried from the hands of a goblin chief. Still warm." },
	{ "id": "kings_regalia", "name": "Regalia of the Skeleton King", "type": "ARMOR", "rarity": "LEGENDARY",
	  "armor": 36.0, "max_hp_bonus": 80.0, "stamina_bonus": 4, "intelligence_bonus": 3,
	  "crit_damage_bonus": 0.20,
	  "description": "Cold and weightless, yet stops a blade like solid stone." },

	# --- Iron Conclave (4-piece set) ---
	{ "id": "iron_conclave_helm", "name": "Iron Conclave Helm", "type": "HELMET", "rarity": "EPIC",
	  "set_id": "iron_conclave",
	  "armor": 18.0, "max_hp_bonus": 30.0, "stamina_bonus": 2,
	  "description": "Part of the Iron Conclave set." },
	{ "id": "iron_conclave_armor", "name": "Iron Conclave Cuirass", "type": "ARMOR", "rarity": "EPIC",
	  "set_id": "iron_conclave",
	  "armor": 36.0, "max_hp_bonus": 60.0, "stamina_bonus": 3,
	  "description": "Part of the Iron Conclave set." },
	{ "id": "iron_conclave_gloves", "name": "Iron Conclave Gauntlets", "type": "GLOVES", "rarity": "EPIC",
	  "set_id": "iron_conclave",
	  "armor": 14.0, "strength_bonus": 3,
	  "description": "Part of the Iron Conclave set." },
	{ "id": "iron_conclave_boots", "name": "Iron Conclave Greaves", "type": "BOOTS", "rarity": "EPIC",
	  "set_id": "iron_conclave",
	  "armor": 12.0, "agility_bonus": 2, "stamina_bonus": 1,
	  "description": "Part of the Iron Conclave set." },

	# --- Stormcaller Vestments (3-piece set) ---
	{ "id": "stormcaller_cap", "name": "Stormcaller Hood", "type": "HELMET", "rarity": "EPIC",
	  "set_id": "stormcaller",
	  "armor": 8.0, "max_mana_bonus": 30.0, "intelligence_bonus": 3,
	  "description": "Part of the Stormcaller Vestments set." },
	{ "id": "stormcaller_robe", "name": "Stormcaller Robe", "type": "ARMOR", "rarity": "EPIC",
	  "set_id": "stormcaller",
	  "armor": 20.0, "max_mana_bonus": 60.0, "intelligence_bonus": 5,
	  "description": "Part of the Stormcaller Vestments set." },
	{ "id": "stormcaller_gloves", "name": "Stormcaller Wraps", "type": "GLOVES", "rarity": "EPIC",
	  "set_id": "stormcaller",
	  "armor": 6.0, "intelligence_bonus": 3, "max_mana_bonus": 20.0,
	  "description": "Part of the Stormcaller Vestments set." },

	# --- Gems (MISC, socketed into other items via the Forge) ---
	{ "id": "gem_ruby", "name": "Ruby", "type": "MISC", "rarity": "UNCOMMON",
	  "weapon_damage": 4.0, "description": "Socket into a weapon for +damage." },
	{ "id": "gem_sapphire", "name": "Sapphire", "type": "MISC", "rarity": "UNCOMMON",
	  "max_mana_bonus": 15.0, "description": "Socket for +max mana." },
	{ "id": "gem_emerald", "name": "Emerald", "type": "MISC", "rarity": "UNCOMMON",
	  "max_hp_bonus": 20.0, "description": "Socket for +max HP." },
	{ "id": "gem_topaz", "name": "Topaz", "type": "MISC", "rarity": "UNCOMMON",
	  "agility_bonus": 2, "description": "Socket for +agility." },
	{ "id": "gem_diamond", "name": "Diamond", "type": "MISC", "rarity": "RARE",
	  "crit_chance_bonus": 0.03, "description": "Socket for +crit chance." },
	{ "id": "gem_amethyst", "name": "Amethyst", "type": "MISC", "rarity": "UNCOMMON",
	  "intelligence_bonus": 2, "description": "Socket for +intelligence." },
	{ "id": "gem_onyx", "name": "Onyx", "type": "MISC", "rarity": "UNCOMMON",
	  "armor": 4.0, "description": "Socket for +armor." },

	# --- Potions (CONSUMABLE) ---
	{ "id": "potion_health_small", "name": "Minor Health Potion", "type": "CONSUMABLE", "rarity": "COMMON",
	  "potion_effect": "heal", "potion_value": 60.0, "sell_value_override": 18,
	  "description": "Restores 60 HP. Hotkey 1-4 to use from your belt." },
	{ "id": "potion_health_large", "name": "Greater Health Potion", "type": "CONSUMABLE", "rarity": "UNCOMMON",
	  "potion_effect": "heal", "potion_value": 200.0, "sell_value_override": 60,
	  "description": "Restores 200 HP. Hotkey 1-4 to use from your belt." },
	{ "id": "potion_mana_small", "name": "Minor Mana Potion", "type": "CONSUMABLE", "rarity": "COMMON",
	  "potion_effect": "mana", "potion_value": 40.0, "sell_value_override": 18,
	  "description": "Restores 40 mana." },
	{ "id": "potion_mana_large", "name": "Greater Mana Potion", "type": "CONSUMABLE", "rarity": "UNCOMMON",
	  "potion_effect": "mana", "potion_value": 130.0, "sell_value_override": 55,
	  "description": "Restores 130 mana." },
]

## Potion item_ids exposed for the Alchemist's stock.
const POTION_IDS: Array = [
	"potion_health_small", "potion_health_large",
	"potion_mana_small", "potion_mana_large",
]

## Gem item_ids — used by drop rolls and the Forge's gem picker.
const GEM_IDS: Array = [
	"gem_ruby", "gem_sapphire", "gem_emerald", "gem_topaz",
	"gem_diamond", "gem_amethyst", "gem_onyx",
]

const RARITY_WEIGHTS: Dictionary = {
	"COMMON":   60,
	"UNCOMMON": 30,
	"RARE":     10,
}

# Number of affixes per rarity tier
const RARITY_AFFIXES: Dictionary = {
	"COMMON":    {"prefixes": 0, "suffixes": 0},
	"UNCOMMON":  {"prefixes": 1, "suffixes": 0},
	"RARE":      {"prefixes": 1, "suffixes": 1},
	"EPIC":      {"prefixes": 2, "suffixes": 1},
	"LEGENDARY": {"prefixes": 0, "suffixes": 0},  # legendaries are hand-tuned
}


## Roll a random item: pick a COMMON base from the pool, then layer affixes
## based on the rolled rarity. Common items stay vanilla; uncommon adds a
## prefix; rare gets a prefix + suffix; epic gets two prefixes + a suffix.
## If type_filter is non-empty, only bases whose ItemType.keys() match are
## eligible (e.g. ["WEAPON"] for a weaponsmith).
static func generate_random_item(item_level: int = 1, type_filter: Array = []) -> Item:
	var rarity_id: String = _pick_rarity()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Pick a base — for Common we use the Common pool; for higher tiers we
	# also start from Common (better) or Uncommon templates to lean on affixes.
	var base_pool: Array = []
	for t in ITEM_TEMPLATES:
		# Use only Common bases for rolled rarities; Uncommon/Rare templates
		# are reserved for boss-tier hand-tuned drops via create_by_id.
		if t.rarity != "COMMON":
			continue
		if not type_filter.is_empty() and not (t.type in type_filter):
			continue
		base_pool.append(t)
	if base_pool.is_empty():
		return null
	var template: Dictionary = base_pool[rng.randi() % base_pool.size()]
	var item := _create_from_template(template, item_level)

	# Promote to the rolled rarity and apply affixes
	item.rarity = Item.Rarity[rarity_id]
	var roll_count: Dictionary = RARITY_AFFIXES.get(rarity_id, {"prefixes": 0, "suffixes": 0})
	var type_id: String = Item.ItemType.keys()[item.item_type]
	var prefix_names: Array = []
	var suffix_names: Array = []
	for _i in range(int(roll_count.prefixes)):
		var pre: Dictionary = AffixDatabase.roll_prefix(type_id, rng)
		if not pre.is_empty():
			AffixDatabase.apply_to_item(item, pre, rng)
			prefix_names.append(pre.name)
	for _i in range(int(roll_count.suffixes)):
		var suf: Dictionary = AffixDatabase.roll_suffix(type_id, rng)
		if not suf.is_empty():
			AffixDatabase.apply_to_item(item, suf, rng)
			suffix_names.append(suf.name)

	# Compose the affixed name: "Vicious Iron Sword of Haste"
	var name_parts: Array = []
	if not prefix_names.is_empty():
		name_parts.append(" ".join(prefix_names))
	name_parts.append(template.name)
	if not suffix_names.is_empty():
		name_parts.append(" ".join(suffix_names))
	item.display_name = " ".join(name_parts)

	# Recompute sell_value to account for new affix stats
	item.sell_value = _compute_sell_value(item)
	# Roll sockets for RARE+ gear (gems themselves don't carry sockets)
	if item.get_slot() != "":
		item.socket_count = _roll_sockets(item.rarity, rng)
	return item


## How many sockets to roll for a freshly-generated item. Higher rarity
## leans towards more sockets but with a chance of 0 for variety.
static func _roll_sockets(rarity: Item.Rarity, rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	match rarity:
		Item.Rarity.RARE:
			if r < 0.50: return 1
			if r < 0.75: return 2
			return 0
		Item.Rarity.EPIC:
			if r < 0.30: return 3
			if r < 0.75: return 2
			return 1
		Item.Rarity.LEGENDARY:
			return 3
		_:
			return 0


## Returns a randomly-chosen gem instance, or null if the pool is empty.
static func roll_gem() -> Item:
	if GEM_IDS.is_empty():
		return null
	var id: String = GEM_IDS[randi() % GEM_IDS.size()]
	return create_by_id(id)


## Reforge an item: produce a fresh Item from the same template with new
## randomly-rolled affixes at the item's current rarity. Upgrades, socketed
## gems, and the pinned flag are intentionally lost — pricier than upgrading
## so it's a high-cost rescue for items with bad rolls. Returns null if the
## item's id has no template.
static func reforge(item: Item) -> Item:
	if item == null:
		return null
	var template: Dictionary = {}
	for t in ITEM_TEMPLATES:
		if t.id == item.item_id:
			template = t
			break
	if template.is_empty():
		return null
	var lvl: int = item.level
	var fresh := _create_from_template(template, lvl)
	# Preserve the rolled rarity (don't downgrade legendary back to its template tier)
	fresh.rarity = item.rarity
	# Re-roll affixes for the rarity tier we ended up at
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rarity_id: String = Item.Rarity.keys()[fresh.rarity]
	var roll_count: Dictionary = RARITY_AFFIXES.get(rarity_id, {"prefixes": 0, "suffixes": 0})
	var type_id: String = Item.ItemType.keys()[fresh.item_type]
	var prefix_names: Array = []
	var suffix_names: Array = []
	for _i in range(int(roll_count.prefixes)):
		var pre: Dictionary = AffixDatabase.roll_prefix(type_id, rng)
		if not pre.is_empty():
			AffixDatabase.apply_to_item(fresh, pre, rng)
			prefix_names.append(pre.name)
	for _i in range(int(roll_count.suffixes)):
		var suf: Dictionary = AffixDatabase.roll_suffix(type_id, rng)
		if not suf.is_empty():
			AffixDatabase.apply_to_item(fresh, suf, rng)
			suffix_names.append(suf.name)
	# Compose the affixed name like generate_random_item does.
	var name_parts: Array = []
	if not prefix_names.is_empty():
		name_parts.append(" ".join(prefix_names))
	name_parts.append(template.name)
	if not suffix_names.is_empty():
		name_parts.append(" ".join(suffix_names))
	fresh.display_name = " ".join(name_parts)
	fresh.sell_value = _compute_sell_value(fresh)
	# Fresh socket roll too
	if fresh.get_slot() != "":
		fresh.socket_count = _roll_sockets(fresh.rarity, rng)
	return fresh


## Returns a random set-item piece across all defined sets, or null if there
## are no set templates. Used by boss drop tables.
static func roll_set_piece() -> Item:
	var set_ids: Array = SetDatabase.SETS.keys()
	if set_ids.is_empty():
		return null
	var sid: String = set_ids[randi() % set_ids.size()]
	var pieces: Array = SetDatabase.SETS[sid].get("piece_ids", [])
	if pieces.is_empty():
		return null
	var piece_id: String = pieces[randi() % pieces.size()]
	return create_by_id(piece_id)


static func _compute_sell_value(item: Item) -> int:
	var v: float = item.weapon_damage * 3.0 + item.armor * 2.0 + item.max_hp_bonus * 0.5
	v += (item.strength_bonus + item.agility_bonus + item.intelligence_bonus + item.stamina_bonus) * 5.0
	v += item.crit_chance_bonus * 200.0
	v += item.crit_damage_bonus * 50.0
	v *= 1.0 + float(item.rarity) * 0.5
	return max(1, int(v))


static func create_by_id(item_id: String) -> Item:
	for t in ITEM_TEMPLATES:
		if t.id == item_id:
			return _create_from_template(t, 1)
	return null


static func _pick_rarity() -> String:
	var total := 0
	for k in RARITY_WEIGHTS:
		total += RARITY_WEIGHTS[k]
	var roll := randi() % total
	var accum := 0
	for k in RARITY_WEIGHTS:
		accum += RARITY_WEIGHTS[k]
		if roll < accum:
			return k
	return "COMMON"


static func _create_from_template(t: Dictionary, lvl: int) -> Item:
	var item := Item.new()
	item.item_id = t.id
	item.display_name = t.name
	item.item_type = Item.ItemType[t.type]
	item.rarity = Item.Rarity[t.rarity]
	item.level = lvl
	item.weapon_damage = t.get("weapon_damage", 0.0)
	item.armor = t.get("armor", 0.0)
	item.max_hp_bonus = t.get("max_hp_bonus", 0.0)
	item.max_mana_bonus = t.get("max_mana_bonus", 0.0)
	item.strength_bonus = t.get("strength_bonus", 0)
	item.agility_bonus = t.get("agility_bonus", 0)
	item.intelligence_bonus = t.get("intelligence_bonus", 0)
	item.stamina_bonus = t.get("stamina_bonus", 0)
	item.crit_chance_bonus = t.get("crit_chance_bonus", 0.0)
	item.crit_damage_bonus = t.get("crit_damage_bonus", 0.0)
	item.description = t.get("description", "")
	item.potion_effect = t.get("potion_effect", "")
	item.potion_value = t.get("potion_value", 0.0)
	item.set_id = t.get("set_id", "")
	# Sell value: potions use the explicit override, gear uses the formula.
	if t.has("sell_value_override"):
		item.sell_value = int(t.sell_value_override)
	else:
		var value: float = item.weapon_damage * 3.0 + item.armor * 2.0 + item.max_hp_bonus * 0.5
		value += (item.strength_bonus + item.agility_bonus + item.intelligence_bonus + item.stamina_bonus) * 5.0
		item.sell_value = max(1, int(value * (1.0 + item.rarity * 0.5)))
	return item
