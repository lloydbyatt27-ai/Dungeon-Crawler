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
const STASH_CAPACITY: int = 50           # legacy single-tab capacity
const STASH_TAB_COUNT: int = 4
const STASH_TAB_CAPACITY: int = 40
const STASH_TAB_NAMES: Array = ["General", "Gems", "Sets", "Dump"]
const VERSION: int = 1

# Cached deserialized save (set by load_save), applied to the next player spawn.
var pending_load_data: Dictionary = {}

# Class chosen on the ClassSelect screen for the next New Game session.
# Read by PlayerController._ready when no save data is being applied.
var pending_class: String = ""
var pending_hardcore: bool = false

# Difficulty chosen on the ClassSelect screen for the upcoming dungeon.
# Read by DungeonGenerator on _ready.
var pending_difficulty: String = "Normal"

# Persistent meta-state across all characters
var unlocked_difficulties: Array = ["Normal"]
var current_run_difficulty: String = "Normal"  # active during a run

# Auto-pickup filter. Items with rarity below this value won't auto-pick
# when the player walks over them. 0 = pick up everything.
var loot_filter_min_rarity: int = 0

# Classes the player has unlocked across all characters. Guardian and
# Mercenary are the starter pool; the other three unlock via milestones
# defined in ClassDatabase (`unlock` field).
var unlocked_classes: Array = ["Guardian", "Mercenary"]
# Total dungeon runs completed across all characters (drives the Scout
# unlock). Persisted in meta.json.
var meta_dungeons_completed: int = 0

# Cross-character stash, organized into named tabs. Persisted to
# user://stash.json as {"tabs": [[entry, ...], ...]} or — for backward
# compatibility with single-tab saves from W24 — a top-level Array.
var stash_tabs: Array = []  # Array[Array[Item]] — outer indexed 0..STASH_TAB_COUNT-1

# Legacy alias: `stash` continues to point at tab 0 so older callers
# (Stash NPC opened signal, save migration) keep working. Typed as Array
# (without an element type) so the property assignment doesn't trip the
# GDScript variant-narrowing checks.
var stash: Array:
	get:
		if stash_tabs.is_empty():
			_init_stash_tabs()
		return stash_tabs[0]
	set(value):
		if stash_tabs.is_empty():
			_init_stash_tabs()
		stash_tabs[0] = value

# Endless mode tracking (per-run, not persisted)
var endless_mode: bool = false
var current_endless_floor: int = 0

# Run-level transient state used by the area-complete screen
var run_summary: Dictionary = {}


func _ready() -> void:
	_init_stash_tabs()
	_load_meta()
	_load_stash()
	EventBus.boss_defeated.connect(_check_boss_unlock)
	EventBus.player_leveled_up.connect(_check_level_unlock)
	EventBus.dungeon_completed.connect(_on_dungeon_completed)


func unlock_class(class_id: String) -> bool:
	if class_id in unlocked_classes:
		return false
	unlocked_classes.append(class_id)
	_save_meta()
	EventBus.show_floating_text.emit(
		"Class unlocked: %s" % class_id,
		Vector3.ZERO,
		Color(1, 0.78, 0.35)
	)
	return true


func _check_boss_unlock(_boss: Node) -> void:
	for cid in ClassDatabase.CLASSES:
		var data: Dictionary = ClassDatabase.CLASSES[cid]
		var unlock = data.get("unlock", {})
		if unlock.get("kind", "") == "boss" and not (cid in unlocked_classes):
			unlock_class(cid)


func _check_level_unlock(new_level: int) -> void:
	for cid in ClassDatabase.CLASSES:
		var data: Dictionary = ClassDatabase.CLASSES[cid]
		var unlock = data.get("unlock", {})
		if unlock.get("kind", "") == "level" \
				and new_level >= int(unlock.get("value", 999)) \
				and not (cid in unlocked_classes):
			unlock_class(cid)


func _on_dungeon_completed(_zone_id: String) -> void:
	meta_dungeons_completed += 1
	for cid in ClassDatabase.CLASSES:
		var data: Dictionary = ClassDatabase.CLASSES[cid]
		var unlock = data.get("unlock", {})
		if unlock.get("kind", "") == "dungeons" \
				and meta_dungeons_completed >= int(unlock.get("value", 999)) \
				and not (cid in unlocked_classes):
			unlock_class(cid)
	_save_meta()


func _init_stash_tabs() -> void:
	stash_tabs.clear()
	for _i in range(STASH_TAB_COUNT):
		var arr: Array[Item] = []
		stash_tabs.append(arr)


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
		loot_filter_min_rarity = int(parsed.get("loot_filter_min_rarity", 0))
		var uc = parsed.get("unlocked_classes", ["Guardian", "Mercenary"])
		if uc is Array:
			unlocked_classes = uc
		# Migrate forward — starter classes always present
		if not "Guardian" in unlocked_classes: unlocked_classes.append("Guardian")
		if not "Mercenary" in unlocked_classes: unlocked_classes.append("Mercenary")
		meta_dungeons_completed = int(parsed.get("meta_dungeons_completed", 0))


func _save_meta() -> void:
	var data := {
		"unlocked_difficulties": unlocked_difficulties,
		"loot_filter_min_rarity": loot_filter_min_rarity,
		"unlocked_classes": unlocked_classes,
		"meta_dungeons_completed": meta_dungeons_completed,
	}
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not open meta file for writing: " + META_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func set_loot_filter(min_rarity: int) -> void:
	loot_filter_min_rarity = clamp(min_rarity, 0, 4)
	_save_meta()


func unlock_difficulty(tier: String) -> bool:
	if tier in unlocked_difficulties:
		return false
	unlocked_difficulties.append(tier)
	_save_meta()
	return true


# --- Cross-character stash ----------------------------------------

func _load_stash() -> void:
	_init_stash_tabs()
	if not FileAccess.file_exists(STASH_PATH):
		return
	var f := FileAccess.open(STASH_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	# Legacy single-tab save: top-level Array. New format: {"tabs": [[...], ...]}.
	if parsed is Array:
		for entry in parsed:
			var item := _item_from_save_entry(entry)
			if item:
				stash_tabs[0].append(item)
		_save_stash()  # migrate to new format
		return
	if parsed is Dictionary:
		var tabs = parsed.get("tabs", [])
		if tabs is Array:
			for i in range(min(tabs.size(), STASH_TAB_COUNT)):
				var tab_entries = tabs[i]
				if not (tab_entries is Array):
					continue
				for entry in tab_entries:
					var item := _item_from_save_entry(entry)
					if item:
						stash_tabs[i].append(item)


func _save_stash() -> void:
	var data: Dictionary = {"tabs": []}
	for tab in stash_tabs:
		var arr: Array = []
		for item in tab:
			arr.append(_save_entry_for(item))
		data.tabs.append(arr)
	var f := FileAccess.open(STASH_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Add an item to the given stash tab. Defaults to tab 0 for back-compat
## with the old API.
func stash_add(item: Item, tab_index: int = 0) -> bool:
	if item == null:
		return false
	if tab_index < 0 or tab_index >= STASH_TAB_COUNT:
		return false
	if stash_tabs[tab_index].size() >= STASH_TAB_CAPACITY:
		return false
	stash_tabs[tab_index].append(item)
	_save_stash()
	return true


## Remove and return the item at (tab_index, index). Single-arg form
## (`stash_take(index)`) still pulls from tab 0.
func stash_take(arg0, arg1 = null) -> Item:
	var tab_index: int = 0
	var index: int = 0
	if arg1 == null:
		index = int(arg0)
	else:
		tab_index = int(arg0)
		index = int(arg1)
	if tab_index < 0 or tab_index >= STASH_TAB_COUNT:
		return null
	var tab: Array = stash_tabs[tab_index]
	if index < 0 or index >= tab.size():
		return null
	var item: Item = tab[index]
	tab.remove_at(index)
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
## a dict with {id, upgrade, sockets, gems}. Re-applies upgrade() and
## re-sockets stored gem ids so the item's stat scaling matches.
func _item_from_save_entry(entry) -> Item:
	var id: String = ""
	var upgrades: int = 0
	var sockets: int = 0
	var gems: Array = []
	if entry is Dictionary:
		id = String(entry.get("id", ""))
		upgrades = int(entry.get("upgrade", 0))
		sockets = int(entry.get("sockets", 0))
		var g = entry.get("gems", [])
		if g is Array:
			gems = g
	elif entry is String:
		id = entry
	if id == "":
		return null
	var item := ItemDatabase.create_by_id(id)
	if item == null:
		return null
	for _i in range(upgrades):
		item.upgrade()
	if sockets > 0:
		item.socket_count = sockets
		for gid in gems:
			var gem := ItemDatabase.create_by_id(String(gid))
			if gem:
				item.socket_gem(gem)
	if entry is Dictionary and entry.get("pinned", false):
		item.pinned = true
	return item


func _save_entry_for(item: Item) -> Dictionary:
	var d: Dictionary = {"id": item.item_id, "upgrade": item.upgrade_level}
	if item.socket_count > 0:
		d["sockets"] = item.socket_count
		d["gems"] = item.socketed_gems.duplicate()
	if item.pinned:
		d["pinned"] = true
	return d


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
			"skill_ranks": s.skill_ranks,
			"hardcore": s.hardcore,
			"active_skill_ids": s.active_skill_ids,
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
		# Save equipped items with their upgrade level + sockets so they survive reload
		for slot in Inventory.SLOTS:
			var item: Item = inv.equipment[slot]
			if item:
				data.equipment[slot] = _save_entry_for(item)
			else:
				data.equipment[slot] = ""
		for it in inv.items:
			data.inventory.append(_save_entry_for(it))
		data["potion_belt"] = []
		for belt_item in inv.potion_belt:
			if belt_item:
				data.potion_belt.append(_save_entry_for(belt_item))
			else:
				data.potion_belt.append("")
		data["glyph_slots"] = []
		for g in inv.glyph_slots:
			if g:
				data.glyph_slots.append(_save_entry_for(g))
			else:
				data.glyph_slots.append("")
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
	var sr = sd.get("skill_ranks", {})
	if sr is Dictionary:
		s.skill_ranks = sr.duplicate()
	else:
		s.skill_ranks = {}
	s.hardcore = bool(sd.get("hardcore", false))
	var ask = sd.get("active_skill_ids", [])
	s.active_skill_ids.clear()
	if ask is Array:
		for sid in ask:
			s.active_skill_ids.append(String(sid))
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
		# Potion belt — preserved across saves
		for i in range(Inventory.POTION_BELT_SIZE):
			inv.potion_belt[i] = null
		var belt_data = data.get("potion_belt", [])
		if belt_data is Array:
			for i in range(min(belt_data.size(), Inventory.POTION_BELT_SIZE)):
				var belt_item := _item_from_save_entry(belt_data[i])
				inv.potion_belt[i] = belt_item
		inv.belt_changed.emit()
		# Glyph slots — restore alongside the belt
		for i in range(Inventory.GLYPH_SLOT_COUNT):
			inv.glyph_slots[i] = null
		var glyph_data = data.get("glyph_slots", [])
		if glyph_data is Array:
			for i in range(min(glyph_data.size(), Inventory.GLYPH_SLOT_COUNT)):
				var g_item := _item_from_save_entry(glyph_data[i])
				inv.glyph_slots[i] = g_item
		inv.glyphs_changed.emit()
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
