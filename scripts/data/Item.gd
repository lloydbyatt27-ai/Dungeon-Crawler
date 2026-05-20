class_name Item
extends Resource
## Self-contained item data. Generated from ItemDatabase or hand-authored.
## Equipping applies stat bonuses to the character's CharacterStats.

enum ItemType { WEAPON, OFFHAND, ARMOR, CONSUMABLE, MISC }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var item_id: String = ""
@export var display_name: String = "Unknown Item"
@export var description: String = ""
@export var item_type: ItemType = ItemType.MISC
@export var rarity: Rarity = Rarity.COMMON
@export var level: int = 1

# Combat stats
@export var weapon_damage: float = 0.0   # added to player base attack damage
@export var armor: float = 0.0           # armor rating → damage reduction

# Stat bonuses
@export var max_hp_bonus: float = 0.0
@export var max_mana_bonus: float = 0.0
@export var strength_bonus: int = 0
@export var agility_bonus: int = 0
@export var intelligence_bonus: int = 0
@export var stamina_bonus: int = 0
@export var crit_chance_bonus: float = 0.0
@export var crit_damage_bonus: float = 0.0

@export var sell_value: int = 1
@export var upgrade_level: int = 0   # 0 = base; +1, +2, ... from forge upgrades


func get_slot() -> String:
	match item_type:
		ItemType.WEAPON:  return "weapon"
		ItemType.OFFHAND: return "offhand"
		ItemType.ARMOR:   return "armor"
		_: return ""


func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:    return Color(0.85, 0.85, 0.85)
		Rarity.UNCOMMON:  return Color(0.3, 0.95, 0.3)
		Rarity.RARE:      return Color(0.4, 0.6, 1.0)
		Rarity.EPIC:      return Color(0.85, 0.4, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.7, 0.2)
	return Color.WHITE


func get_rarity_name() -> String:
	return Rarity.keys()[rarity].capitalize()


func type_name() -> String:
	return ItemType.keys()[item_type].capitalize()


## Returns the display name with the upgrade-level suffix appended.
func display_with_upgrade() -> String:
	if upgrade_level <= 0:
		return display_name
	return "%s +%d" % [display_name, upgrade_level]


## Apply a 25 percent increase to all stat bonuses and bump upgrade_level.
## Caps at +5.
func upgrade() -> bool:
	if upgrade_level >= 5:
		return false
	upgrade_level += 1
	var f := 0.25
	weapon_damage *= 1.0 + f
	armor *= 1.0 + f
	max_hp_bonus *= 1.0 + f
	max_mana_bonus *= 1.0 + f
	strength_bonus = int(round(strength_bonus * (1.0 + f)))
	agility_bonus = int(round(agility_bonus * (1.0 + f)))
	intelligence_bonus = int(round(intelligence_bonus * (1.0 + f)))
	stamina_bonus = int(round(stamina_bonus * (1.0 + f)))
	crit_chance_bonus *= 1.0 + f
	crit_damage_bonus *= 1.0 + f
	sell_value = int(sell_value * (1.0 + f))
	return true


## Soul-shard cost to upgrade from current level to current+1.
func upgrade_cost() -> int:
	if upgrade_level >= 5:
		return -1
	return (upgrade_level + 1) * 5 * (int(rarity) + 1)


func tooltip_text() -> String:
	var lines: Array = []
	lines.append("%s" % display_name)
	lines.append("%s %s (Lv %d)" % [get_rarity_name(), type_name(), level])
	lines.append("")
	if weapon_damage > 0: lines.append("+%d Weapon Damage" % int(weapon_damage))
	if armor > 0:         lines.append("+%d Armor" % int(armor))
	if max_hp_bonus > 0:  lines.append("+%d Max HP" % int(max_hp_bonus))
	if max_mana_bonus > 0: lines.append("+%d Max Mana" % int(max_mana_bonus))
	if strength_bonus > 0: lines.append("+%d Strength" % strength_bonus)
	if agility_bonus > 0:  lines.append("+%d Agility" % agility_bonus)
	if intelligence_bonus > 0: lines.append("+%d Intelligence" % intelligence_bonus)
	if stamina_bonus > 0:  lines.append("+%d Stamina" % stamina_bonus)
	if crit_chance_bonus > 0: lines.append("+%.0f%% Crit Chance" % (crit_chance_bonus * 100.0))
	if crit_damage_bonus > 0: lines.append("+%.0f%% Crit Damage" % (crit_damage_bonus * 100.0))
	if description != "":
		lines.append("")
		lines.append(description)
	return "\n".join(lines)
