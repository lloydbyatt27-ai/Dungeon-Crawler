extends Node
## Tracks fastest boss kill times per boss species. Bosses post their
## elapsed lifetime when they die; this autoload keeps the per-species
## minimum across runs.
##
## Saved to user://boss_times.json so the leaderboard survives sessions.

const FILE_PATH: String = "user://boss_times.json"

# species_key -> best_seconds (float)
var best_times: Dictionary = {}
# species_key -> last_seconds (the most recent kill — shown alongside best)
var last_times: Dictionary = {}


func _ready() -> void:
	_load()


## Called by BaseEnemy._on_died for is_boss kills. Returns true if this
## kill set a new record.
func record_kill(species_key: String, display_name: String, seconds: float) -> bool:
	last_times[species_key] = seconds
	var prev: float = float(best_times.get(species_key, INF))
	if seconds < prev:
		best_times[species_key] = seconds
		_save()
		EventBus.show_floating_text.emit(
			"%s record: %s" % [display_name, format_time(seconds)],
			Vector3.ZERO,
			Color(1, 0.78, 0.35)
		)
		return true
	_save()
	return false


static func format_time(seconds: float) -> String:
	var s: int = int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func _load() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var bt = parsed.get("best_times", {})
		if bt is Dictionary:
			best_times = bt
		var lt = parsed.get("last_times", {})
		if lt is Dictionary:
			last_times = lt


func _save() -> void:
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"best_times": best_times, "last_times": last_times}, "\t"))
	f.close()
