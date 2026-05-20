extends Node
## Global game state singleton.
## Holds active character reference, current zone, run statistics.
## Use sparingly — prefer EventBus signals for cross-system communication.

signal game_paused(is_paused: bool)
signal zone_changed(new_zone_id: String)

var current_character = null
var current_zone_id: String = "test_arena"
var is_paused: bool = false

var run_stats: Dictionary = {
	"monsters_killed": 0,
	"bosses_defeated": 0,
	"deaths": 0,
	"gold_earned_total": 0,
	"items_collected": 0,
	"play_time_seconds": 0.0,
	"dungeons_completed": 0,
}

# Snapshot of run_stats at the start of the current dungeon, used by the
# Area Complete summary screen to compute deltas.
var _run_start_snapshot: Dictionary = {}
var _last_gold_total: int = 0


var _hit_stop_end_ms: float = 0.0


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.player_gold_changed.connect(_on_gold_changed)
	EventBus.request_hit_stop.connect(_apply_hit_stop)


func _apply_hit_stop(duration: float) -> void:
	# Wall-clock end time so the freeze isn't its own foot-shooting target
	var now_ms: float = Time.get_ticks_msec()
	_hit_stop_end_ms = max(_hit_stop_end_ms, now_ms + duration * 1000.0)
	Engine.time_scale = 0.05


func _process(delta: float) -> void:
	if not is_paused:
		run_stats.play_time_seconds += delta
	if _hit_stop_end_ms > 0.0 and Time.get_ticks_msec() >= _hit_stop_end_ms:
		Engine.time_scale = 1.0
		_hit_stop_end_ms = 0.0


func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)


func change_zone(zone_id: String) -> void:
	current_zone_id = zone_id
	zone_changed.emit(zone_id)


# --- Run tracking ----------------------------------------------------

func start_run() -> void:
	# Snapshot current stats so we can compute deltas at run end.
	_run_start_snapshot = run_stats.duplicate(true)
	_last_gold_total = 0


func run_delta(key: String) -> float:
	var current: float = run_stats.get(key, 0.0)
	var snap: float = _run_start_snapshot.get(key, 0.0)
	return current - snap


func _on_enemy_died(enemy: Node, _pos: Vector3) -> void:
	run_stats.monsters_killed += 1
	if enemy and "is_boss" in enemy and enemy.is_boss:
		run_stats.bosses_defeated += 1


func _on_item_picked_up(_item) -> void:
	run_stats.items_collected += 1


func _on_gold_changed(new_total: int) -> void:
	var diff: int = new_total - _last_gold_total
	if diff > 0:
		run_stats.gold_earned_total += diff
	_last_gold_total = new_total
