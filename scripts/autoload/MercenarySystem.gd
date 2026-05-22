extends Node
## Mercenary roster. Tracks the player's hired follower (if any) across runs.
## Per-character — written into the same savegame.json under the
## "mercenary" key by SaveSystem.

const FILE_PATH: String = "user://mercenary.json"

# Progression — mercenaries gain XP from enemy kills while deployed.
# 5 XP per regular kill, 60 per boss. Levels follow xp_for_next() below.
const MAX_LEVEL: int = 20
const XP_PER_KILL: int = 5
const XP_PER_BOSS: int = 60
const PER_LEVEL_DAMAGE_MULT: float = 0.05  # +5%/level
const PER_LEVEL_HP_MULT: float = 0.05      # +5%/level

# "" = no merc hired, otherwise one of MERC_TYPES below.
var current_type: String = ""
var level: int = 1
var xp: int = 0
# Specialization path chosen at level 5. Empty = not yet picked.
var specialization: String = ""
const SPEC_UNLOCK_LEVEL: int = 5

# Live mercenary instances in the current scene. Mercenary._ready calls
# `register()`, `_on_died` and despawn flows call `unregister()`. Cached
# here so XP events don't have to call get_nodes_in_group every kill.
var _active_mercs: Array[Node] = []


signal merc_leveled_up(new_level: int)


# --- Active merc registry --------------------------------------

func register(merc: Node) -> void:
	if merc and not (merc in _active_mercs):
		_active_mercs.append(merc)


func unregister(merc: Node) -> void:
	_active_mercs.erase(merc)


func has_active_in_scene() -> bool:
	# Prune any stale references before answering — queue_free'd nodes
	# can hang around in this list until their next frame.
	for m in _active_mercs.duplicate():
		if not is_instance_valid(m):
			_active_mercs.erase(m)
	return not _active_mercs.is_empty()


## Despawn every active mercenary in the scene. Used by PauseMenu's
## hire/dismiss flow so existing mercs are cleaned up before swapping.
func despawn_active() -> void:
	for m in _active_mercs.duplicate():
		if is_instance_valid(m):
			m.queue_free()
	_active_mercs.clear()


## Lookup a spec definition by merc type + id. Returns {} if not found.
func _find_spec(merc_type: String, spec_id: String) -> Dictionary:
	for spec in SPECIALIZATIONS.get(merc_type, []):
		if spec.get("id", "") == spec_id:
			return spec
	return {}

## Specializations available per merc type. Picked once at SPEC_UNLOCK_LEVEL
## and locked in until the merc is dismissed. Each entry is a stat-mult
## bundle applied on top of base + level scaling.
const SPECIALIZATIONS: Dictionary = {
	"warrior": [
		{"id": "bulwark",     "name": "Bulwark",     "desc": "+50% HP. The unkillable wall.",
		 "hp_mult": 1.5, "dmg_mult": 1.0, "cd_mult": 1.0},
		{"id": "berserker",   "name": "Berserker",   "desc": "+40% damage. Death-or-glory.",
		 "hp_mult": 0.9, "dmg_mult": 1.4, "cd_mult": 1.0},
	],
	"archer": [
		{"id": "volley",      "name": "Volley",      "desc": "+50% damage. Each shot stings.",
		 "hp_mult": 1.0, "dmg_mult": 1.5, "cd_mult": 1.0},
		{"id": "sharpshooter","name": "Sharpshooter","desc": "-30% attack cooldown.",
		 "hp_mult": 1.0, "dmg_mult": 1.0, "cd_mult": 0.7},
	],
	"mage": [
		{"id": "storm",       "name": "Storm",       "desc": "+60% damage. Calls the lightning.",
		 "hp_mult": 1.0, "dmg_mult": 1.6, "cd_mult": 1.0},
		{"id": "frostbinder", "name": "Frostbinder", "desc": "+20% damage, +20% HP, -15% cooldown.",
		 "hp_mult": 1.2, "dmg_mult": 1.2, "cd_mult": 0.85},
	],
}


## Returns the data dict for the current spec, or empty if not chosen.
func current_spec_data() -> Dictionary:
	if current_type == "" or specialization == "":
		return {}
	return _find_spec(current_type, specialization)


func spec_unlocked() -> bool:
	return has_active_merc() and level >= SPEC_UNLOCK_LEVEL


func choose_spec(spec_id: String) -> bool:
	if not spec_unlocked():
		return false
	if _find_spec(current_type, spec_id).is_empty():
		return false
	specialization = spec_id
	_save()
	# Rescale any live mercenaries to apply the new bonuses
	for m in _active_mercs:
		if is_instance_valid(m) and m.has_method("apply_level_scaling"):
			m.apply_level_scaling()
	return true


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
	EventBus.enemy_died.connect(_on_enemy_died)


func xp_for_next() -> int:
	return int(100.0 * pow(level, 1.5))


func damage_multiplier() -> float:
	return 1.0 + PER_LEVEL_DAMAGE_MULT * float(max(level - 1, 0))


func hp_multiplier() -> float:
	return 1.0 + PER_LEVEL_HP_MULT * float(max(level - 1, 0))


func _on_enemy_died(enemy: Node, _pos: Vector3) -> void:
	if not has_active_merc():
		return
	# Only award XP when a merc is actually present in the scene.
	# Uses the cached registry instead of get_nodes_in_group (which
	# would allocate an Array on every enemy death — and there can be
	# dozens per second in a packed room).
	if not has_active_in_scene():
		return
	var amount: int = XP_PER_KILL
	if enemy and "is_boss" in enemy and enemy.is_boss:
		amount = XP_PER_BOSS
	_gain_xp(amount)


func _gain_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += amount
	var leveled := false
	while xp >= xp_for_next() and level < MAX_LEVEL:
		xp -= xp_for_next()
		level += 1
		leveled = true
	if leveled:
		merc_leveled_up.emit(level)
		var players := get_tree().get_nodes_in_group("player")
		var anchor: Vector3 = Vector3.ZERO
		if not players.is_empty():
			anchor = (players[0] as Node3D).global_position + Vector3(0, 3.0, 0)
		EventBus.show_floating_text.emit(
			"%s reached Lv %d" % [current_data().get("display_name", "Mercenary"), level],
			anchor,
			Color(0.55, 0.85, 0.45)
		)
		# Rescale any active mercenary instances on the fly so the buff
		# applies mid-run, not just on next spawn.
		for m in _active_mercs:
			if is_instance_valid(m) and m.has_method("apply_level_scaling"):
				m.apply_level_scaling()
	_save()


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
		level = clamp(int(parsed.get("level", 1)), 1, MAX_LEVEL)
		xp = max(0, int(parsed.get("xp", 0)))
		specialization = String(parsed.get("specialization", ""))


func _save() -> void:
	var data := {"type": current_type, "level": level, "xp": xp, "specialization": specialization}
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func hire(merc_type: String) -> bool:
	if not MERC_TYPES.has(merc_type):
		return false
	# Swapping merc types resets level/xp/spec. Same type = keep progression.
	if current_type != merc_type:
		level = 1
		xp = 0
		specialization = ""
	current_type = merc_type
	_save()
	return true


func dismiss() -> void:
	current_type = ""
	level = 1
	xp = 0
	specialization = ""
	_save()


func has_active_merc() -> bool:
	return current_type != "" and MERC_TYPES.has(current_type)


func current_data() -> Dictionary:
	return MERC_TYPES.get(current_type, {})
