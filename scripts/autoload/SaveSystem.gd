extends Node
## File-based save/load. JSON in user://savegame.json.
## Phase 1: single-slot, single-character save.
##
## Save shape:
## {
##   "version": 1,
##   "stats": { ...CharacterStats fields... },
##   "equipment": { "weapon": "item_id", "offhand": null, "armor": "..." },
##   "inventory": ["item_id", "item_id", ...],
##   "stats_runtime": { "current_hp": float, "current_mana": float },
##   "dungeons_completed": int,
##   "play_time_seconds": float
## }

const SAVE_PATH: String = "user://savegame.json"
const META_PATH: String = "user://meta.json"
const STASH_PATH: String = "user://stash.json"
const STASH_CAPACITY: int = 50
const VERSION: int = 1

# Cached deserialized save (set by load_save), applied to the next player spawn.
var pending_load_data: Dictionary = {}

# Class chosen on the ClassSelect screen for the next New Game session.
# Read by PlayerController._ready when no save data is being applied.
var pending_class: String = ""

# Difficulty chosen on the ClassSelect screen for the upcoming dungeon.
# Read by DungeonGenerator on _ready.
var pending_difficulty: String = "Normal"

# Persistent meta-state across all characters
var unlocked_difficulties: Array = ["Normal"]
var current_run_difficulty: String = "Normal"  # active during a run

# Cross-character stash (shared). Stored as Item instances; persisted to
# user://stash.json as save-entry dicts {id, upgrade}.
var stash: Array[Item] = []

# Endless mode tracking (per-run, not persisted)
var endless_mode: bool = false
var current_endless_floor: int = 0

# Run-level transient state used by the area-complete screen
var run_summary: Dictionary = {}


func _ready() -> void:
	_load_meta()
	_load_stash()


func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var arr = parsed.get("unlocked_difficulties", ["Normal"])
		if arr is Array:
			unlocked_difficulties = arr
		if not "Normal" in unlocked_difficulties:
			unlocked_difficulties.append("Normal")


func _save_meta() -> void:
	var data := {"unlocked_difficulties": unlocked_difficulties}
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not open meta file for writing: " + META_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func unlock_difficulty(tier: String) -> bool:
	if tier in unlocked_difficulties:
		return false
	unlocked_difficulties.append(tier)
	_save_meta()
	return true


# --- Cross-character stash ----------------------------------------

func _load_stash() -> void:
	stash.clear()
	if not FileAccess.file_exists(STASH_PATH):
		return
	var f := FileAccess.open(STASH_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Array):
		return
	for entry in parsed:
		var item := _item_from_save_entry(entry)
		if item:
			stash.append(item)


func _save_stash() -> void:
	var entries: Array = []
	for item in stash:
		entries.append({"id": item.item_id, "upgrade": item.upgrade_level})
	var f := FileAccess.open(STASH_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(entries, "\t"))
	f.close()


func stash_add(item: Item) -> bool:
	if item == null or stash.size() >= STASH_CAPACITY:
		return false
	stash.append(item)
	_save_stash()
	return true


func stash_take(index: int) -> Item:
	if index < 0 or index >= stash.size():
		return null
	var item := stash[index]
	stash.remove_at(index)
	_save_stash()
	return item


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_player(player: PlayerController) -> bool:
	if player == null or player.stats == null:
		return false
	var data := _serialize_player(player)
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not open save file for writing: " + SAVE_PATH)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	print("[SaveSystem] Saved to %s" % SAVE_PATH)
	return true


func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("[SaveSystem] Save file is corrupt or empty")
		return false
	pending_load_data = parsed
	return true


func apply_to_player(player: PlayerController) -> bool:
	if pending_load_data.is_empty() or player == null:
		return false
	_deserialize_into_player(player, pending_load_data)
	pending_load_data = {}
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## Build an Item from a save entry: either a plain id string (legacy) or
## a dict with {id, upgrade}. Re-applies upgrade() upgrade_level times so
## the item's stat scaling matches.
func _item_from_save_entry(entry) -> Item:
	var id: String = ""
	var upgrades: int = 0
	if entry is Dictionary:
		id = String(entry.get("id", ""))
		upgrades = int(entry.get("upgrade", 0))
	elif entry is String:
		id = entry
	if id == "":
		return null
	var item := ItemDatabase.create_by_id(id)
	if item == null:
		return null
	for _i in range(upgrades):
		item.upgrade()
	return item


# --- Serialization --------------------------------------------------

func _serialize_player(player: PlayerController) -> Dictionary:
	var s: CharacterStats = player.stats
	var inv: Inventory = player.get_node_or_null("Inventory") as Inventory
	var data: Dictionary = {
		"version": VERSION,
		"stats": {
			"class_type": s.class_type,
			"character_name": s.character_name,
			"level": s.level,
			"xp": s.xp,
			"strength": s.strength,
			"agility": s.agility,
			"intelligence": s.intelligence,
			"stamina": s.stamina,
			"gold": s.gold,
			"soul_shards": s.soul_shards,
			"essence": s.essence,
			"unspent_attribute_points": s.unspent_attribute_points,
			"unspent_skill_points": s.unspent_skill_points,
			"best_endless_floor": s.best_endless_floor,
			"completed_quest_ids": s.completed_quest_ids,
		},
		"active_quests": QuestSystem.serialize(),
		"runtime": {
			"current_hp": player.health.current_health if player.health else 0.0,
			"current_mana": player.current_mana,
		},
		"equipment": {},
		"inventory": [],
		"play_time_seconds": GameState.run_stats.get("play_time_seconds", 0.0),
		"dungeons_completed": GameState.run_stats.get("dungeons_completed", 0),
	}
	if inv:
		# Save equipped items with their upgrade level so it survives reload
		for slot in Inventory.SLOTS:
			var item: Item = inv.equipment[slot]
			if item:
				data.equipment[slot] = {"id": item.item_id, "upgrade": item.upgrade_level}
			else:
				data.equipment[slot] = ""
		for it in inv.items:
			data.inventory.append({"id": it.item_id, "upgrade": it.upgrade_level})
	return data


func _deserialize_into_player(player: PlayerController, data: Dictionary) -> void:
	if not data.has("stats"):
		return
	var s: CharacterStats = player.stats
	var sd: Dictionary = data.stats
	s.class_type = sd.get("class_type", "Guardian")
	s.character_name = sd.get("character_name", "Hero")
	s.level = int(sd.get("level", 1))
	s.xp = int(sd.get("xp", 0))
	s.strength = int(sd.get("strength", 12))
	s.agility = int(sd.get("agility", 6))
	s.intelligence = int(sd.get("intelligence", 4))
	s.stamina = int(sd.get("stamina", 10))
	s.gold = int(sd.get("gold", 0))
	s.soul_shards = int(sd.get("soul_shards", 0))
	s.essence = float(sd.get("essence", 0.0))
	s.unspent_attribute_points = int(sd.get("unspent_attribute_points", 0))
	s.unspent_skill_points = int(sd.get("unspent_skill_points", 0))
	s.best_endless_floor = int(sd.get("best_endless_floor", 0))
	# Quest completion record
	var cq_raw = sd.get("completed_quest_ids", [])
	if cq_raw is Array:
		s.completed_quest_ids.clear()
		for id in cq_raw:
			s.completed_quest_ids.append(String(id))
	# Restore active quests
	var aq = data.get("active_quests", [])
	if aq is Array:
		QuestSystem.deserialize(aq)
	else:
		QuestSystem.clear_all()

	# Restore inventory (must happen before equip so refresh_stats is correct)
	var inv: Inventory = player.get_node_or_null("Inventory") as Inventory
	if inv:
		inv.items.clear()
		for slot in Inventory.SLOTS:
			inv.equipment[slot] = null
		# Inventory items — entries may be plain strings (old saves) or dicts
		for entry in data.get("inventory", []):
			var item := _item_from_save_entry(entry)
			if item:
				inv.items.append(item)
		# Equipped items
		var eq: Dictionary = data.get("equipment", {})
		for slot in Inventory.SLOTS:
			var item2 := _item_from_save_entry(eq.get(slot, ""))
			if item2:
				inv.equipment[slot] = item2
		inv._refresh_stats()
		inv.items_changed.emit()

	# Runtime resources (apply after equipment so maxes are correct)
	var rd: Dictionary = data.get("runtime", {})
	if player.health:
		player.health.set_max_health(s.max_hp(), false)
		var current_hp = clamp(float(rd.get("current_hp", s.max_hp())), 1.0, s.max_hp())
		player.health.current_health = current_hp
		player.health.is_dead = false
		player.health.health_changed.emit(current_hp, s.max_hp())
	player.current_mana = clamp(float(rd.get("current_mana", s.max_mana())), 0.0, s.max_mana())

	# Gold UI refresh
	EventBus.player_gold_changed.emit(s.gold)
	EventBus.player_stats_changed.emit()
