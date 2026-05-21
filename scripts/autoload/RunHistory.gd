extends Node
## Records the player's last 20 runs (cleared or died) and exposes them to
## the Run History UI. Saved to user://run_history.json across sessions
## and characters.
##
## Entry shape:
##   {date, class, difficulty, modifiers, outcome, time, kills, bosses,
##    gold, items, level, killer}

const FILE_PATH: String = "user://run_history.json"
const MAX_ENTRIES: int = 20

var entries: Array = []


func _ready() -> void:
	_load()
	EventBus.dungeon_completed.connect(_on_dungeon_completed)


func _on_dungeon_completed(zone_id: String) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	_record_entry(players[0], "cleared", zone_id, "")


## Called by PlayerController on death (manual hook — there's no
## EventBus signal for player-death yet).
func record_death(player: Node, killer_name: String) -> void:
	_record_entry(player, "died", "", killer_name)


func _record_entry(player: Node, outcome: String, zone_id: String, killer: String) -> void:
	var stats = player.stats if "stats" in player else null
	var entry: Dictionary = {
		"date": Time.get_datetime_string_from_system(false, true),
		"class": stats.class_type if stats else "?",
		"level": stats.level if stats else 0,
		"difficulty": SaveSystem.current_run_difficulty,
		"modifiers": SaveSystem.active_modifiers.duplicate(),
		"outcome": outcome,
		"zone": zone_id,
		"time": GameState.run_delta("play_time_seconds"),
		"kills": int(GameState.run_delta("monsters_killed")),
		"bosses": int(GameState.run_delta("bosses_defeated")),
		"gold": int(GameState.run_delta("gold_earned_total")),
		"items": int(GameState.run_delta("items_collected")),
		"killer": killer,
	}
	entries.push_front(entry)
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	_save()


func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		entries = parsed


func _save() -> void:
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(entries, "\t"))
	f.close()
