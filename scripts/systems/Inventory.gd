class_name Inventory
extends Node
## Holds the player's items and equipment slots, manages gold, and pushes
## equipment bonuses back to CharacterStats for the rest of the systems to read.

signal items_changed
signal equipment_changed(slot: String, item)

const MAX_INVENTORY_SIZE: int = 24
const SLOTS: Array = ["weapon", "offhand", "armor"]

var items: Array[Item] = []
var equipment: Dictionary = {
	"weapon": null,
	"offhand": null,
	"armor": null,
}

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
	# Push updated maxes onto runtime resources
	if _player.health:
		_player.health.set_max_health(s.max_hp(), false)
		_player.health.damage_reduction = s.damage_reduction()
	# Clamp current mana
	if _player.current_mana > s.max_mana():
		_player.current_mana = s.max_mana()
	EventBus.player_stats_changed.emit()
