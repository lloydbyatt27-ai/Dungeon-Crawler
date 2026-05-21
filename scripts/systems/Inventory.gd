class_name Inventory
extends Node
## Holds the player's items and equipment slots, manages gold, and pushes
## equipment bonuses back to CharacterStats for the rest of the systems to read.

signal items_changed
signal equipment_changed(slot: String, item)
signal belt_changed
signal glyphs_changed

const MAX_INVENTORY_SIZE: int = 24
const SLOTS: Array = ["weapon", "offhand", "armor", "helmet", "gloves", "boots"]
const POTION_BELT_SIZE: int = 4

var items: Array[Item] = []
var equipment: Dictionary = {
	"weapon": null,
	"offhand": null,
	"armor": null,
	"helmet": null,
	"gloves": null,
	"boots": null,
}

# 4-slot potion belt (1-4 hotkeys). Each entry is either an Item or null.
var potion_belt: Array = [null, null, null, null]

# 3-slot glyph rack. Glyph effects multiply skill stats globally — read
# by SkillSystem when computing damage / cooldown / buff duration.
const GLYPH_SLOT_COUNT: int = 3
var glyph_slots: Array = [null, null, null]

var _player: PlayerController


func _ready() -> void:
	_player = get_parent() as PlayerController


# --- Items ----------------------------------------------------------

func add_item(item: Item) -> bool:
	if item == null:
		return false
	if items.size() >= MAX_INVENTORY_SIZE:
		return false
	items.append(item)
	items_changed.emit()
	EventBus.item_picked_up.emit(item)
	return true


func remove_item(item: Item) -> bool:
	if items.has(item):
		items.erase(item)
		items_changed.emit()
		return true
	return false


# --- Equipment ------------------------------------------------------

func equip(item: Item) -> bool:
	var slot := item.get_slot()
	if slot == "" or not equipment.has(slot):
		return false
	# Swap out current item if any
	var current = equipment[slot]
	if current:
		if items.size() >= MAX_INVENTORY_SIZE:
			return false  # no room to put the old one back
		items.append(current)
	if items.has(item):
		items.erase(item)
	equipment[slot] = item
	equipment_changed.emit(slot, item)
	items_changed.emit()
	_refresh_stats()
	EventBus.item_equipped.emit(item, slot)
	return true


func unequip(slot: String) -> bool:
	var current = equipment.get(slot)
	if current == null:
		return false
	if items.size() >= MAX_INVENTORY_SIZE:
		return false
	equipment[slot] = null
	items.append(current)
	equipment_changed.emit(slot, null)
	items_changed.emit()
	_refresh_stats()
	return true


# --- Potion belt ----------------------------------------------------

## Move a potion from the backpack into the first free belt slot.
## Returns the belt index, or -1 if there was no room.
func belt_assign(item: Item) -> int:
	if item == null or not item.is_potion():
		return -1
	if not items.has(item):
		return -1
	for i in range(POTION_BELT_SIZE):
		if potion_belt[i] == null:
			potion_belt[i] = item
			items.erase(item)
			belt_changed.emit()
			items_changed.emit()
			return i
	return -1


## Move a belt potion back to the backpack (or drop it if there's no room).
func belt_take(slot: int) -> bool:
	if slot < 0 or slot >= POTION_BELT_SIZE:
		return false
	var item: Item = potion_belt[slot]
	if item == null:
		return false
	if items.size() >= MAX_INVENTORY_SIZE:
		return false
	potion_belt[slot] = null
	items.append(item)
	belt_changed.emit()
	items_changed.emit()
	return true


## Consume the potion in the given belt slot, applying its effect to the
## player. Returns true if a potion was actually used (slot non-empty and
## the resource it heals wasn't already at maximum).
func use_belt_potion(slot: int) -> bool:
	if slot < 0 or slot >= POTION_BELT_SIZE:
		return false
	var potion: Item = potion_belt[slot]
	if potion == null or _player == null:
		return false
	var applied: bool = false
	match potion.potion_effect:
		"heal":
			if _player.health and _player.health.current_health < _player.health.max_health:
				_player.health.heal(potion.potion_value)
				applied = true
		"mana":
			if _player.stats and _player.current_mana < _player.stats.max_mana():
				_player.current_mana = min(_player.stats.max_mana(),
					_player.current_mana + potion.potion_value)
				applied = true
	if not applied:
		return false
	potion_belt[slot] = null
	belt_changed.emit()
	items_changed.emit()
	EventBus.show_floating_text.emit(
		"+%d %s" % [int(potion.potion_value), "HP" if potion.potion_effect == "heal" else "Mana"],
		_player.global_position + Vector3(0, 2.1, 0),
		Color(0.55, 1.0, 0.55) if potion.potion_effect == "heal" else Color(0.5, 0.7, 1.0)
	)
	return true


# --- Glyph slots ----------------------------------------------------

## Equip a glyph from the backpack into the first empty glyph slot.
func glyph_equip(item: Item) -> int:
	if item == null or not item.is_glyph() or not items.has(item):
		return -1
	for i in range(GLYPH_SLOT_COUNT):
		if glyph_slots[i] == null:
			glyph_slots[i] = item
			items.erase(item)
			glyphs_changed.emit()
			items_changed.emit()
			return i
	return -1


## Unequip a glyph slot back to the backpack.
func glyph_unequip(slot: int) -> bool:
	if slot < 0 or slot >= GLYPH_SLOT_COUNT:
		return false
	var item: Item = glyph_slots[slot]
	if item == null:
		return false
	if items.size() >= MAX_INVENTORY_SIZE:
		return false
	glyph_slots[slot] = null
	items.append(item)
	glyphs_changed.emit()
	items_changed.emit()
	return true


## Sum the `glyph_value` of every equipped glyph matching `effect`. Returns
## the aggregate multiplier (e.g. two +15% Ember Glyphs → 0.30).
func glyph_total(effect: String) -> float:
	var total: float = 0.0
	for g in glyph_slots:
		if g and g.glyph_effect == effect:
			total += g.glyph_value
	return total


# --- Gold -----------------------------------------------------------

func add_gold(amount: int) -> void:
	if _player == null or _player.stats == null:
		return
	_player.stats.gold += amount
	EventBus.player_gold_changed.emit(_player.stats.gold)


func spend_gold(amount: int) -> bool:
	if _player == null or _player.stats == null:
		return false
	if _player.stats.gold < amount:
		return false
	_player.stats.gold -= amount
	EventBus.player_gold_changed.emit(_player.stats.gold)
	return true


# --- Sell / Salvage --------------------------------------------------

const SHARD_BY_RARITY: Dictionary = {
	Item.Rarity.COMMON:    1,
	Item.Rarity.UNCOMMON:  3,
	Item.Rarity.RARE:      8,
	Item.Rarity.EPIC:      20,
	Item.Rarity.LEGENDARY: 50,
}


## Sell an inventory item to a vendor for gold (= item.sell_value).
## Returns the gold gained, or 0 on failure (also fails if the item is pinned).
func sell_item(item: Item) -> int:
	if not items.has(item) or item.pinned:
		return 0
	var gold_gained: int = max(1, item.sell_value)
	items.erase(item)
	_player.stats.gold += gold_gained
	items_changed.emit()
	EventBus.player_gold_changed.emit(_player.stats.gold)
	return gold_gained


## Salvage an inventory item into Soul Shards (count depends on rarity).
## Returns the shards gained, or 0 on failure (also fails if the item is pinned).
func salvage_item(item: Item) -> int:
	if not items.has(item) or item.pinned:
		return 0
	var shards: int = SHARD_BY_RARITY.get(item.rarity, 1)
	items.erase(item)
	if _player.stats:
		_player.stats.soul_shards += shards
		EventBus.player_shards_changed.emit(_player.stats.soul_shards)
	items_changed.emit()
	return shards


# --- Stat application ----------------------------------------------

func _refresh_stats() -> void:
	if _player == null or _player.stats == null:
		return
	var s: CharacterStats = _player.stats
	# Zero out current bonuses
	s.bonus_strength = 0
	s.bonus_agility = 0
	s.bonus_intelligence = 0
	s.bonus_stamina = 0
	s.bonus_max_hp = 0.0
	s.bonus_max_mana = 0.0
	s.bonus_weapon_damage = 0.0
	s.bonus_armor = 0.0
	s.bonus_crit_chance = 0.0
	s.bonus_crit_damage = 0.0
	# Sum equipped items
	for slot in equipment:
		var item: Item = equipment[slot]
		if item == null:
			continue
		s.bonus_strength += item.strength_bonus
		s.bonus_agility += item.agility_bonus
		s.bonus_intelligence += item.intelligence_bonus
		s.bonus_stamina += item.stamina_bonus
		s.bonus_max_hp += item.max_hp_bonus
		s.bonus_max_mana += item.max_mana_bonus
		s.bonus_weapon_damage += item.weapon_damage
		s.bonus_armor += item.armor
		s.bonus_crit_chance += item.crit_chance_bonus
		s.bonus_crit_damage += item.crit_damage_bonus
	# Apply set bonuses (counted from currently-equipped pieces)
	var equipped_list: Array = []
	for slot in equipment:
		equipped_list.append(equipment[slot])
	SetDatabase.apply_to_stats(s, equipped_list)
	# Push updated maxes onto runtime resources
	if _player.health:
		_player.health.set_max_health(s.max_hp(), false)
		_player.health.damage_reduction = s.damage_reduction()
	# Clamp current mana
	if _player.current_mana > s.max_mana():
		_player.current_mana = s.max_mana()
	EventBus.player_stats_changed.emit()
