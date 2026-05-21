extends Node
## Mercenary roster. Tracks the player's hired follower (if any) across runs.
## Per-character — written into the same savegame.json under the
## "mercenary" key by SaveSystem.

const FILE_PATH: String = "user://mercenary.json"

# "" = no merc hired, otherwise one of MERC_TYPES below.
var current_type: String = ""

const MERC_TYPES: Dictionary = {
	"warrior": {
		"display_name": "Mercenary Warrior",
		"role": "Melee tank",
		"hire_cost": 400,
		"hp": 280.0,
		"damage": 14.0,
		"attack_cd": 1.2,
		"body_color": Color(0.85, 0.55, 0.30),
	},
	"archer": {
		"display_name": "Ranger Companion",
		"role": "Ranged",
		"hire_cost": 600,
		"hp": 180.0,
		"damage": 18.0,
		"attack_cd": 0.9,
		"body_color": Color(0.45, 0.85, 0.50),
	},
	"mage": {
		"display_name": "Acolyte",
		"role": "Spellcaster",
		"hire_cost": 800,
		"hp": 150.0,
		"damage": 22.0,
		"attack_cd": 1.6,
		"body_color": Color(0.55, 0.60, 1.0),
	},
}


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		current_type = String(parsed.get("type", ""))


func _save() -> void:
	var data := {"type": current_type}
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func hire(merc_type: String) -> bool:
	if not MERC_TYPES.has(merc_type):
		return false
	current_type = merc_type
	_save()
	return true


func dismiss() -> void:
	current_type = ""
	_save()


func has_active_merc() -> bool:
	return current_type != "" and MERC_TYPES.has(current_type)


func current_data() -> Dictionary:
	return MERC_TYPES.get(current_type, {})
