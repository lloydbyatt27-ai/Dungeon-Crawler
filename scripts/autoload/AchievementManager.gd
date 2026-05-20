extends Node
## Tracks long-running counters (kills, bosses, crits, shapeshifts) and
## fires achievement_unlocked when thresholds are met. State persists in
## user://achievements.json, shared across all characters on this install.

signal achievement_unlocked(id: String, def: Dictionary)

const FILE_PATH: String = "user://achievements.json"

var unlocked: Dictionary = {}   # id → true
var counters: Dictionary = {
	"kills": 0,
	"bosses": 0,
	"crits": 0,
	"shapeshifts": 0,
}


func _ready() -> void:
	_load_state()
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.sfx_hit_landed.connect(_on_hit_landed)
	EventBus.player_shapeshifted.connect(_on_shapeshifted)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.player_stats_changed.connect(_on_stats_changed)


# --- Event handlers ----------------------------------------------

func _on_enemy_died(_enemy: Node, _pos: Vector3) -> void:
	counters.kills += 1
	_check("first_blood", counters.kills >= 1)
	_check("veteran", counters.kills >= 100)
	_check("exterminator", counters.kills >= 500)
	_save_state()


func _on_boss_defeated(_boss: Node) -> void:
	counters.bosses += 1
	_check("first_boss", counters.bosses >= 1)
	_check("boss_hunter", counters.bosses >= 5)
	if SaveSystem.current_run_difficulty == "Hell":
		_check("hell_walker", true)
	_save_state()


func _on_hit_landed(is_crit: bool) -> void:
	if not is_crit:
		return
	counters.crits += 1
	_save_state()


func _on_shapeshifted(_form_name: String, active: bool) -> void:
	if not active:
		return
	counters.shapeshifts += 1
	_check("shapeshifter", counters.shapeshifts >= 10)
	_save_state()


func _on_item_picked_up(item) -> void:
	if item == null:
		return
	if int(item.rarity) >= Item.Rarity.RARE:
		_check("collector", true)
	if int(item.rarity) >= Item.Rarity.LEGENDARY:
		_check("treasure_hoarder", true)


func _on_gold_changed(new_total: int) -> void:
	if new_total >= 1000:
		_check("wealthy", true)


func _on_stats_changed() -> void:
	# Forge Master — any item at +5
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var inv = players[0].get_node_or_null("Inventory")
		if inv:
			for item in inv.items:
				if item and item.upgrade_level >= 5:
					_check("forge_master", true)
					break
			for slot in Inventory.SLOTS:
				var equipped = inv.equipment.get(slot)
				if equipped and equipped.upgrade_level >= 5:
					_check("forge_master", true)
					break
	# Endless milestone
	if SaveSystem.endless_mode and SaveSystem.current_endless_floor >= 5:
		_check("veteran_descender", true)


# --- Core ---------------------------------------------------------

func _check(id: String, condition: bool) -> void:
	if not condition or unlocked.get(id, false):
		return
	var def: Dictionary = AchievementDatabase.get_def(id)
	if def.is_empty():
		return
	unlocked[id] = true
	achievement_unlocked.emit(id, def)
	_save_state()


# --- Persistence -------------------------------------------------

func _load_state() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	var u = parsed.get("unlocked", [])
	if u is Array:
		for id in u:
			unlocked[String(id)] = true
	var c = parsed.get("counters", {})
	if c is Dictionary:
		for k in counters.keys():
			counters[k] = int(c.get(k, counters[k]))


func _save_state() -> void:
	var data := {
		"unlocked": unlocked.keys(),
		"counters": counters,
	}
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func reset_all() -> void:
	# Dev utility — wipe achievements and counters
	unlocked.clear()
	for k in counters.keys():
		counters[k] = 0
	_save_state()
